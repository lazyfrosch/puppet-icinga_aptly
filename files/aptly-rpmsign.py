#!/usr/bin/env python

import logging
import os
import subprocess
import sys
import threading

LOG_FORMAT = "[%(asctime)s] [%(levelname)s] %(message)s"

class SigningError(StandardError):
    pass

class RpmSigner(object):
    gpg_name = "Icinga Open Source Monitoring (Build server)"
    gpg_bin = "/usr/bin/gpg1"

    def __init__(self, file_name, **kwargs):
        self.file_name = file_name

        self.process = None
        self.returncode = None
        self.stdout = None
        self.stderr = None

        for key, value in kwargs.iteritems():
            setattr(self, key, value)

    def sign(self, timeout=10):
        thread = threading.Thread(target=self._sign)
        thread.start()

        thread.join(timeout)
        if thread.is_alive():
            self.process.terminate()
            thread.join()
            self.returncode = 1
            raise SigningError("Terminating RPM signing process after timeout (%d)" % (timeout))

        if self.returncode != 0:
            raise SigningError("RPM sign command for file '%s' failed:\n%s" % (self.file_name, self.stderr))

    def _sign(self):
        command = [
            'rpm',
            '-D', '%_gpg_name ' + self.gpg_name,
            '-D', '%__gpg ' + self.gpg_bin,
            '--addsign', self.file_name
        ]

        logging.debug("Running RPM addsign command: %s", command)
        self.process = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

        # TODO: wait for password input?
        (self.stdout, self.stderr) = self.process.communicate()

        if self.stdout:
            logging.debug("Process told us on stdout:\n%s", self.stdout.strip())
        if self.stderr:
            logging.warning("Process logged something on stderr:\n%s", self.stderr.strip())

        self.returncode = self.process.returncode

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
