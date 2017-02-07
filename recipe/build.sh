#!/bin/bash

# install using pip from the whl file provided by Google
# TODO use wheels from PyPI for all platforms and supported Python versions.

if [ `uname` == Darwin ]; then
    if [ "$PY_VER" == "2.7" ]; then
        pip install --no-deps https://storage.googleapis.com/tensorflow/mac/cpu/tensorflow-${PKG_VERSION}-py2-none-any.whl
    elif [ "$PY_VER" == "3.4" ]; then
        pip install --no-deps https://storage.googleapis.com/tensorflow/mac/cpu/tensorflow-${PKG_VERSION}-py3-none-any.whl
    elif [ "$PY_VER" == "3.5" ]; then
        pip install --no-deps https://storage.googleapis.com/tensorflow/mac/cpu/tensorflow-${PKG_VERSION}-py3-none-any.whl
    elif [ "$PY_VER" == "3.6" ]; then
        pip install --no-deps https://files.pythonhosted.org/packages/91/7c/98b25b74241194d4312a7e230c85a77b254224191dbf17b484811f8a9f61/tensorflow-0.12.1-cp36-cp36m-macosx_10_11_x86_64.whl
    fi
fi

if [ `uname` == Linux ]; then
    if [ "$PY_VER" == "2.7" ]; then
        pip install --no-deps https://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-${PKG_VERSION}-cp27-none-linux_x86_64.whl
    elif [ "$PY_VER" == "3.4" ]; then
        pip install --no-deps https://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-${PKG_VERSION}-cp34-cp34m-linux_x86_64.whl
    elif [ "$PY_VER" == "3.5" ]; then
        pip install --no-deps https://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-${PKG_VERSION}-cp35-cp35m-linux_x86_64.whl
    elif [ "$PY_VER" == "3.6" ]; then
        pip install --no-deps https://files.pythonhosted.org/packages/e9/a5/45b172f20e2fabd19c7f18a44570fc82acc4c628ec9bc4b313de39c4fe37/tensorflow-0.12.1-cp36-cp36m-manylinux1_x86_64.whl
    fi
fi
