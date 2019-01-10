#!/usr/bin/env python

import logging
import os
import re
from subprocess import check_output
import sys

import pexpect

LOG_FORMAT = "[%(asctime)s] [%(levelname)s] %(message)s"

class SigningError(StandardError):
    pass

class RpmSigner(object):
    gpg_bin = "/usr/bin/gpg"

    def __init__(self, file_name, **kwargs):
        self.file_name = file_name

        self.process = None
        self.returncode = None
        self.stdout = None
        self.stderr = None

        self.gpg_name = None

        for key, value in kwargs.iteritems():
            setattr(self, key, value)

    def get_gpg_name(self):
        if not self.gpg_name:
            _out = check_output([self.gpg_bin, '-K', '--with-colon'])

            keys = re.split(r"\r?\n", _out.strip())
            if not keys:
                raise SigningError("Could not detect a GPG private key!")
            elif len(keys) > 1:
                raise SigningError("Found multiple private keys, you need to specify the key!")
            else:
                _parts = re.split(r":", keys[0])

            self.gpg_name = _parts[9]

        return self.gpg_name

    def sign(self, timeout=10):
        args = [
            '-D', '%_gpg_name ' + self.get_gpg_name(),
            '-D', '%__gpg ' + self.gpg_bin,
            '--addsign', self.file_name
        ]

        logging.debug("Executing signing with pexpect: %s", args)
        child = pexpect.spawn('rpm', args, timeout=timeout)

        child.expect('Enter pass phrase:')
        child.sendline('')
        child.expect(pexpect.EOF)

        if child.exitstatus:
            self.returncode = child.exitstatus
            raise SigningError("RPM sign command for file '%s' failed:\n%s" % (self.file_name, self.stderr))

def parse_args(argv=None):
    """Setup default CLI arguments"""
    import argparse
    parser = argparse.ArgumentParser(description='APTLY RPM signing helper',
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('-d', '--debug', action='store_true',
                        help='Enable debugging')
    parser.add_argument('file', type=str, help='RPM file to sign')

    if argv is None:
        argv = sys.argv[1:]

    return parser.parse_args(argv)

def main():
    """Main CLI action"""
    args = parse_args()

    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)
    else:
        logging.getLogger().setLevel(logging.INFO)

    logging.basicConfig(format=LOG_FORMAT)

    signer = RpmSigner(args.file)

    if "GPG_NAME" in os.environ:
        signer.gpg_name = os.environ["GPG_NAME"]
    if "GPG_BIN" in os.environ:
        signer.gpg_bin = os.environ["GPG_BIN"]

    try:
        signer.sign()
        logging.info("Signed successfully.")
        return 0
    except SigningError as _e:
        logging.fatal(_e)
        return 1

if __name__ == '__main__':
    sys.exit(main())
