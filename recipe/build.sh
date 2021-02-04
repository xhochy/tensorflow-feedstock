#!/bin/bash

set -ex

export PATH="$PWD:$PATH"
export CC=$(basename $CC)
export CXX=$(basename $CXX)
export LIBDIR=$PREFIX/lib
export INCLUDEDIR=$PREFIX/include

export TF_SYSTEM_LIBS="llvm"

# do not build with MKL support
export TF_NEED_MKL=0
export BAZEL_MKL_OPT=""

mkdir -p ./bazel_output_base
export BAZEL_OPTS=""

# the following arguments are useful for debugging
#    --logging=6
#    --subcommands
# jobs can be used to limit parallel builds and reduce resource needs
#    --jobs=20
# Set compiler and linker flags as bazel does not account for CFLAGS,
# CXXFLAGS and LDFLAGS.
BUILD_OPTS="
--copt=-march=nocona
--copt=-mtune=haswell
--copt=-ftree-vectorize
--copt=-fPIC
--copt=-fstack-protector-strong
--copt=-O2
--cxxopt=-fvisibility-inlines-hidden
--cxxopt=-fmessage-length=0
--linkopt=-zrelro
--linkopt=-znow
--verbose_failures
${BAZEL_MKL_OPT}
--config=opt"
export TF_ENABLE_XLA=0
export BUILD_TARGET="//tensorflow/tools/pip_package:build_pip_package //tensorflow/tools/lib_package:libtensorflow //tensorflow:libtensorflow_cc.so"

# Python settings
export PYTHON_BIN_PATH=${PYTHON}
export PYTHON_LIB_PATH=${SP_DIR}
export USE_DEFAULT_PYTHON_LIB_PATH=1

# additional settings
export CC_OPT_FLAGS="-march=nocona -mtune=haswell"
export TF_NEED_OPENCL=0
export TF_NEED_OPENCL_SYCL=0
export TF_NEED_COMPUTECPP=0
export TF_NEED_CUDA=0
export TF_CUDA_CLANG=0
export TF_NEED_TENSORRT=0
export TF_NEED_ROCM=0
export TF_NEED_MPI=0
export TF_DOWNLOAD_CLANG=0
export TF_SET_ANDROID_WORKSPACE=0
./configure

# build using bazel
bazel ${BAZEL_OPTS} build ${BUILD_OPTS} ${BUILD_TARGET}

# build a whl file
mkdir -p $SRC_DIR/tensorflow_pkg
bazel-bin/tensorflow/tools/pip_package/build_pip_package $SRC_DIR/tensorflow_pkg

