#!/usr/bin/env python
# Copyright (c) 2017-2018 Icinga Development Team <info@icinga.com>
#               2017-2018 Markus Frosch <markus.frosch@icinga.com>
#
# Replacement for "old" update-rpms.rb
#
# This should work on a fileformat that "update-rpms.rb" ignores (no dash in upload path)
#
import argparse
import os
from os.path import join, basename, getmtime, exists, isfile, relpath
import sys
from time import time
from fnmatch import fnmatch
import re
from subprocess import check_output, CalledProcessError, STDOUT
import json
import shutil
from hashlib import sha1

import requests

aptly_home = os.environ.get('APLY_HOME', '/var/lib/aptly')
aptly_api = os.environ.get('APLY_API', 'http://127.0.0.1:8080/api')

parser = argparse.ArgumentParser(description='Processing RPM uploads from Aptly')
parser.add_argument('--upload', help='upload spool directory', default=('%s/upload' % aptly_home))
parser.add_argument('--public', help='Public repository base', default=('%s/public' % aptly_home))
parser.add_argument('--cleanup', help='cleanup stale directories', action='store_true')
parser.add_argument('--cleanup-grace-time', metavar='SECONDS', help='Time needed for dirs to be considered stale',
                    type=int, default=300)
parser.add_argument('--force', action='store_true', help='Overwrite files in repository')
parser.add_argument('--api', help='APTLY API (local without auth)', default=aptly_api)
parser.add_argument('--noop', action='store_true', help='No operating mode')

args = parser.parse_args()

REFRESH_REPOS = []
REMOVE_UPLOAD = []

def rpm_query(file, format):
    cmd = ['rpm', '-qp', '--queryformat=' + format, file]
    try:
        return check_output(cmd, stderr=sys.stderr)
    except StandardError, e:
        raise StandardError('Failure during rpm_query: ' + (e.message or str(e)))

def sha1_file(path):
    h = sha1()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(4096), b""):
            h.update(chunk)
    return h.hexdigest()

def sign_rpm(file):
    if args.noop:
        print "Would sign RPM %s" % file
    else:
        print "Signing RPM %s" % file
        try:
            check_output(['aptly-rpmsign', file], stderr=STDOUT)
        except CalledProcessError as _e:
            print "Running rpmsign failed: " + _e.output
            raise

def install_rpm(file, source, dest):
    if not exists(dest) and not args.noop:
        os.makedirs(dest)

    source_file = join(source, file)
    dest_file = join(dest, file)

    # TODO: if checksums will be checked, file changes here!!
    sign_rpm(source_file)

    if exists(dest_file) and not args.force:
        if not isfile(dest_file) or sha1_file(source_file) != sha1_file(dest_file):
            raise StandardError, 'Target file already exists and is not identical to source: ' + dest_file

    if args.noop:
        print "Would copy %s to %s" % (source_file, dest_file)
    else:
        shutil.copyfile(source_file, dest_file)

def delete_upload(path):
    if not path.startswith(args.upload):
        raise StandardError, 'Path to be deleted is not below %s' % (args.upload)

    if args.noop:
        print "Would delete path " + path
    else:
        print "Deleting path " + path
        for root, dirs, files in os.walk(path, topdown=False):
            for name in files:
                os.remove(join(root, name))
            for name in dirs:
                os.rmdir(join(root, name))
        os.rmdir(path)

def createrepo(path):
    if args.noop:
        print "Would update repodata for %s" % (path)
    else:
        print "Updating repodata for %s" % (path)
        check_output(['createrepo', path])

    repo_xml = join(path, 'repodata', 'repomd.xml')
    repo_signature = repo_xml + '.asc'

    if args.noop:
        print "Would sign repo metadata %s" % repo_xml
    else:
        if exists(repo_signature):
            os.remove(repo_signature)

        print "Signing repo metadata"
        check_output(['gpg', '--detach-sign', '--armor', '--batch', '--no-tty', repo_xml])

def process_upload(path, files):
    print 'Reading upload metadata from %s' % (basename(path))
    with open(join(path, 'upload.json'), 'r') as f:
        upload_meta = json.loads(f.read())

    target = upload_meta['target']
    release = upload_meta['release']
    upload_type = upload_meta['type']
    #checksums = upload_meta['checksums']

    if upload_type == 'RPM':
        return process_upload_rpm(path, files, target, release)
    elif upload_type == 'DEB':
        return process_upload_deb(path, files, upload_meta)
    else:
        raise StandardError, 'Unknown upload type "%s"!' % upload_type

def aptly_safe_string(string):
    return re.sub(r'\W+', '-', string)

def process_upload_deb(path, files, upload_meta):
    target = upload_meta['target']
    release = upload_meta['release']

    if 'architectures' in upload_meta:
        architectures = list(upload_meta['architectures'])
    else:
        architectures = ['i386', 'amd64']

    if 'repo' in upload_meta:
        aptly_repo = upload_meta['repo']
    else:
        # remove icinga- prefix
        _short = re.sub('^icinga-', '', release)
        aptly_repo = 'icinga-%s-%s' % (aptly_safe_string(target), aptly_safe_string(_short))

    aptly_target = re.sub('/', '_', re.sub('_', '__', target))
    upload = basename(path)

    print "Checking if repository '%s' exists" % aptly_repo
    r = requests.get(args.api + '/repos/%s' % aptly_repo)
    if r.status_code != requests.codes.ok:
        if args.noop:
            print "Would create repository '%s'" % aptly_repo
        else:
            r = requests.post(args.api + '/repos', json={
                "Name": aptly_repo
            })
            if r.status_code != requests.codes.created:
                raise StandardError, "Could not create Aptly repository '%s'" % aptly_repo

    if args.noop:
        print "Would add upload '%s' to repo '%s'" % (upload, aptly_repo)
    else:
        print "Adding upload '%s' to repo '%s'" % (upload, aptly_repo)
        r = requests.post(args.api + '/repos/%s/file/%s' % (aptly_repo, upload), data={})
        if r.status_code not in [requests.codes.ok, requests.codes.created]:
            raise StandardError, "Adding upload to repo '%s' failed: %s" % (aptly_repo, r.content)

    if args.noop:
        print "Would publish repo '%s' to '%s' with dist '%s'" % (aptly_repo, target, release)
    else:
        print "Publising repo '%s' to '%s'" % (aptly_repo, target)
        r = requests.put(args.api + '/publish/%s/%s' % (aptly_target, release), data={})
        if r.status_code == requests.codes.ok:
            print "Publish successful!"
        elif r.status_code == requests.codes.not_found:
            if args.noop:
                print "Would publish a new repository '%s' to '%s'" % (aptly_repo, target)
            else:
                print "Publishing a new repository '%s' to '%s'" % (aptly_repo, target)

                _arch = architectures
                _arch.append('source')

                payload = {}
                payload['SourceKind'] = 'local'
                payload['Sources'] = [{'Name': aptly_repo}]
                payload['Architectures'] = _arch
                payload['Distribution'] = release

                r = requests.post(args.api + '/publish/%s' % (aptly_target), json=payload)
                if r.status_code in [requests.codes.ok, requests.codes.created]:
                    print "Publish sucessful!"
                else:
                    raise StandardError, "Publising repo '%s' failed: %s" % (aptly_repo, r.content)
        else:
            raise StandardError, "Publising repo '%s' failed: %s" % (aptly_repo, r.content)

    delete_upload(path)

def process_upload_rpm(path, files, target, release):
    source_rpm = None
    rpms = []

    # reading files from dir
    for file in files:
        if fnmatch(file, '*.src.rpm'):
            if source_rpm:
                raise StandardError, 'Found more than one source_rpm: %s %s' % (source_rpm, file)
            source_rpm = file
        elif fnmatch(file, '*.rpm'):
            rpms.append(file)
        else:
            # ignore other files
            pass

    if not source_rpm:
        raise StandardError, 'No source RPM found!'

    # TODO: validate checksums?

    source_name = rpm_query(join(path, source_rpm), '%{name}')

    # the full path to install to
    target_path = join(args.public, target, release)
    repodata_path = join(target_path, 'repodata')
    source_path = join(target_path, 'src', source_name)

    # check this is an RPM repository...
    if exists(target_path):
        if not exists(repodata_path):
            raise StandardError, 'Install location %s exists and is not an RPM repository!' % (target_path)
    else:
        # making it an empty RPM repository
        # this will avoid errors in this check if we abort later
        if args.noop:
            print "Would create repository under %s" % repodata_path
        else:
            print "Would create repository under %s" % repodata_path
            os.makedirs(repodata_path)

    print "Installing source RPM %s into target %s" % (source_rpm, relpath(source_path, args.public))
    install_rpm(source_rpm, path, source_path)

    for rpm in rpms:
        arch = rpm_query(join(path, source_rpm), '%{arch}')
        binary_path = join(target_path, arch, source_name)
        print "Installing RPM %s into target %s" % (rpm, relpath(binary_path, args.public))
        install_rpm(rpm, path, binary_path)

    # schedule repo for refreshing
    global REFRESH_REPOS
    if target_path not in REFRESH_REPOS:
        REFRESH_REPOS.append(target_path)

    # delete upload
    delete_upload(path)

for root, dirs, files in os.walk(args.upload, topdown=False):
    if root == args.upload:
        continue

    # cleanup old empty dirs
    if (args.cleanup and not dirs and not files and args.cleanup_grace_time > 0 and
            getmtime(root) < (time() - args.cleanup_grace_time)):
        if args.noop:
            print "Would cleanup empty directory: %s" % root
        else:
            print "Cleanup empty directory: %s" % root
            os.rmdir(root)

    # only process directory that contain an upload file
    if 'upload.json' not in files:
        continue

    try:
        process_upload(root, files)
    except StandardError, e:
        print >> sys.stderr, "Encountered an error during processing upload %s: %s" % (basename(root), e.message or e)
        raise

for repo in REFRESH_REPOS:
    createrepo(repo)
