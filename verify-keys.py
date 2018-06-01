#!/usr/bin/env python3

import argparse
import logging

LOG = logging.getLogger('verify-keys')

def cleanup_keys(args):
    '''Cleanup and restore state'''
    delete_temp_dir()

def verify_keys(args):
    '''Manages looking up and verifying that we have keys that work'''
    temp = 


def parse_args():
    '''Parses supplied arguments'''
    parser = argparse.ArgumentParser()
    parser.add_argument("-v", "--verbose", action="store_true",
                        help="Enabled debug logging")
    parser.add_argument("-k", "--keys", required=True, 
                        help="Path to GPG key tarball")
    args = parser.parse_args()
    return args


def setup_logging(args):
    '''Configures logging'''
    ch = logging.StreamHandler()
    if args.verbose:
        LOG.setLevel(logging.DEBUG)
        ch.setLevel(logging.DEBUG)
    formatter = logging.Formatter(
        '%(asctime)s %(name)-12s %(levelname)-8s %(message)s')
    ch.setFormatter(formatter)
    LOG.addHandler(ch)


def main():
    args = parse_args()
    setup_logging(args)
    verify_keys(args)


if __name__ == '__main__':
    raise SystemExit(main())
