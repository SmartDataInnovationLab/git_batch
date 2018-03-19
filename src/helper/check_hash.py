#!/usr/bin/env python3

print("todo: check hash")

"""
1. find dirs, that need checking (note: this are already found in check_symlinks.py)
2. extract expected hash from dir-name
3. docker run -it -v (realpath .):/hash_this dirh
4. compare, return 1 on mismatch
"""