#!/usr/bin/env python3

import nbformat
from nbconvert.preprocessors import ExecutePreprocessor
from nbconvert.preprocessors import CellExecutionError

import os
import shutil

notebook_path = "notebook/dummy.ipynb"
notebook_abspath = os.path.realpath(notebook_path)
notebook_filename = os.path.basename(notebook_abspath)
notebook_folder = os.path.dirname(notebook_abspath)

notebook_filename_out = notebook_abspath

with open(notebook_abspath) as f:
    nb = nbformat.read(f, as_version=4)

ep = ExecutePreprocessor(timeout=600, kernel_name='python3')

try:
    out = ep.preprocess(nb, {'metadata': {'path': notebook_folder}})
    # out = ep.preprocess(nb)
    print("notebook run successfully")
except CellExecutionError:
    out = None
    msg = 'Error executing the notebook "%s".\n\n' % notebook_filename
    msg += 'See notebook "%s" for the traceback.' % notebook_filename_out
    print(msg)
    raise
finally:
    with open(notebook_filename_out, mode='wt') as f:
        nbformat.write(nb, f)
