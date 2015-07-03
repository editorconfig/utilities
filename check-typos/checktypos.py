#!/bin/env python

from __future__ import print_function

import sys
IS_PY3 = sys.version_info.major >= 3

permited_properties = (
    'charset',
    'end_of_line',
    'indent_size',
    'indent_style',
    'insert_final_newline',
    'max_line_length',
    'tab_width',
    'trim_trailing_whitespace'
)
def check_editorconfig(path):
    """
    check typos in a single .editorconfig file
    """
    if IS_PY3:
        from configparser import ConfigParser
        from io import StringIO
    else:
        from ConfigParser import ConfigParser
        from StringIO import StringIO

    cp = ConfigParser()
    with open(path) as f:
        import os
        cp.readfp(StringIO('[ROOT]' + os.linesep + f.read()))

    for section in cp.sections():
        for option in cp.options(section):
            p = None
            if section == 'ROOT':
                p = ['root']
            else:
                p = permited_properties
            if option not in p:
                print('Warning: Unrecognized property {} in {}'.format(option, path))
                continue

def check_dir(d):
    """
    check typos in all .editorconfig files in a dir (including subdir)
    """
    import os
    for root, subdirs, files in os.walk(d):
        if '.editorconfig' in files:
            check_editorconfig(os.path.join(root, '.editorconfig'))

import argparse

parser = argparse.ArgumentParser(description='Check typos in an EditorConfig configuration')
parser.add_argument('paths', metavar='path', type=str, nargs='+',
                   help='Paths to the directory containing .editorconfig, or path to .editorconfig')

args = parser.parse_args()

paths = args.paths

for path in paths:
    import os
    if os.path.isdir(path):
        check_dir(path)
    elif os.path.isfile(path):
        check_editorconfig(path)
    else:
        raise OSError("Unsupported file type {}".format(path))
