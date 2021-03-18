#!/bin/bash

set -ex

export PATH="$PWD:$PATH"
export CC=$(basename $CC)
export CXX=$(basename $CXX)
export LIBDIR=$PREFIX/lib
export INCLUDEDIR=$PREFIX/include

# Needs a bazel build:
# com_google_absl
# Build failures in tensorflow/core/platform/s3/aws_crypto.cc
# boringssl (i.e. system openssl)
# Most importantly: Write a patch that uses system LLVM libs for sure as well as MLIR and oneDNN/mkldnn
# TODO(check):
# absl_py
# com_github_googleapis_googleapis
# com_github_googlecloudplatform_google_cloud_cpp

# The possible values are specified in third_party/systemlibs/syslibs_configure.bzl
# The versions for them can be found in tensorflow/workspace.bzl
export TF_SYSTEM_LIBS="
  astor_archive
  astunparse_archive
  com_github_grpc_grpc
  com_google_protobuf
  com_googlesource_code_re2
  curl
  cython
  dill_archive
  gif
  libjpeg_turbo
  llvm
  snappy
  zlib
  "
python ./third_party/systemlibs/generate_llvm_build.py > third_party/systemlibs/llvm.BUILD

# do not build with MKL support
export TF_NEED_MKL=0
export BAZEL_MKL_OPT=""

mkdir -p ./bazel_output_base
export BAZEL_OPTS=""

# Quick debug:
# cp -r ${RECIPE_DIR}/build.sh . && bazel clean && bash -x build.sh --logging=6 | tee log.txt
# Dependency graph:
# bazel query 'deps(//tensorflow/tools/lib_package:libtensorflow)' --output graph > graph.in
if [[ "${target_platform}" == osx-* ]]; then
  # set up bazel config file for conda provided clang toolchain
  cp -r ${RECIPE_DIR}/custom_clang_toolchain .
  pushd custom_clang_toolchain
    sed -e "s:\${CLANG}:${CLANG}:" \
        -e "s:\${INSTALL_NAME_TOOL}:${INSTALL_NAME_TOOL}:" \
        -e "s:\${CONDA_BUILD_SYSROOT}:${CONDA_BUILD_SYSROOT}:" \
        cc_wrapper.sh.template > cc_wrapper.sh
    chmod +x cc_wrapper.sh
    sed -i "" "s:\${PREFIX}:${PREFIX}:" cc_toolchain_config.bzl
    sed -i "" "s:\${BUILD_PREFIX}:${BUILD_PREFIX}:" cc_toolchain_config.bzl
    sed -i "" "s:\${CONDA_BUILD_SYSROOT}:${CONDA_BUILD_SYSROOT}:" cc_toolchain_config.bzl
    sed -i "" "s:\${LD}:${LD}:" cc_toolchain_config.bzl
    sed -i "" "s:\${NM}:${NM}:" cc_toolchain_config.bzl
    sed -i "" "s:\${STRIP}:${STRIP}:" cc_toolchain_config.bzl
    sed -i "" "s:\${AR}:${LIBTOOL}:" cc_toolchain_config.bzl
    sed -i "" "s:\${LIBTOOL}:${LIBTOOL}:" cc_toolchain_config.bzl
  popd

  # set build arguments
  export  BAZEL_USE_CPP_ONLY_TOOLCHAIN=1
  BUILD_OPTS="
      --crosstool_top=//custom_clang_toolchain:toolchain
      --verbose_failures
      --linkopt=-lz
      ${BAZEL_MKL_OPT}
      --config=opt"
else
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
fi
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
export TF_CONFIGURE_IOS=0
./configure

# build using bazel
bazel ${BAZEL_OPTS} build ${BUILD_OPTS} ${BUILD_TARGET}

# build a whl file
mkdir -p $SRC_DIR/tensorflow_pkg
bash -x bazel-bin/tensorflow/tools/pip_package/build_pip_package $SRC_DIR/tensorflow_pkg

