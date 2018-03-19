#!/usr/bin/env python3

import os, sys


class BadFileException(Exception):
    pass


def checkdir(path):
    # source: https://stackoverflow.com/a/33232688/5132456
    for root, dirs, files in os.walk(path):
        for file in files + dirs:
            f = os.path.join(root, file)
            if not os.access(f, os.R_OK):
                raise BadFileException("file not readable: {}".format(os.path.realpath(f)))
            if os.path.islink(f):
                if not os.path.exists(f):
                    raise BadFileException("broken link: {} -> {}".format(f, os.path.realpath(f)))
                if not os.path.realpath(f).startswith(path):
                    if os.access(f, os.W_OK):
                        # todo: check if this still works in subdirs of the symlink
                        raise BadFileException("writeable external link: {} -> {}".format(f, os.path.realpath(f)))


has_error = False

for path in sys.argv[1:]:
    try:
        print("checking filesystem starting at: " + os.path.realpath(path))
        checkdir(path)
    except BadFileException as e:
        sys.stderr.write(str(e))
        has_error = True

if has_error:
    sys.exit(1)
