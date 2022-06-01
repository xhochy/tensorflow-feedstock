#!/bin/bash

set -ex

# Use pre-built LLVM and MLIR
cp -r $PREFIX/share/llvm_for_tf llvm-project
# See https://github.com/tensorflow/tensorflow/blob/3f878cff5b698b82eea85db2b60d65a2e320850e/third_party/llvm/setup.bzl#L6
echo 'llvm_targets = ["AArch64", "AMDGPU", "ARM", "NVPTX", "PowerPC", "RISCV", "SystemZ", "X86"]' > llvm-project/llvm/targets.bzl

source ${PREFIX}/etc/tensorflow/tf_environment.sh

source ${RECIPE_DIR}/gen-bazel-toolchain.sh

if [[ "${target_platform}" == "osx-64" ]]; then
  # Tensorflow doesn't cope yet with an explicit architecture (darwin_x86_64) on osx-64 yet.
  TARGET_CPU=darwin
fi

# If you really want to see what is executed, add --subcommands
BUILD_OPTS="
    --crosstool_top=//custom_toolchain:toolchain
    --logging=6
    --verbose_failures
    --config=opt
    --define=PREFIX=${PREFIX}
    --define=PROTOBUF_INCLUDE_PATH=${PREFIX}/include
    --config=noaws
    --cpu=${TARGET_CPU}
    --local_cpu_resources=${CPU_COUNT}"

if [[ "${target_platform}" == "osx-arm64" ]]; then
  BUILD_OPTS="${BUILD_OPTS} --config=macos_arm64"
fi
# These ops are heavily dependent on MLIR-generated kernel code.
# We could split out the MLIR-based ones into individual ones once we can use a prebuilt MLIR.
export BUILD_TARGET="
  //tensorflow/core/kernels:libtfkernel_cwise_op.so
"

# Python settings
export PYTHON_BIN_PATH=${BUILD_PREFIX}/bin/python
export PYTHON_LIB_PATH=$(python -c 'import site; print(site.getsitepackages()[0])')
export USE_DEFAULT_PYTHON_LIB_PATH=1

# Get rid of unwanted defaults
sed -i -e "/PROTOBUF_INCLUDE_PATH/c\ " .bazelrc
sed -i -e "/PREFIX/c\ " .bazelrc


bazel clean --expunge
bazel shutdown

./configure

# build using bazel
bazel ${BAZEL_OPTS} build ${BUILD_OPTS} ${BUILD_TARGET}

cp -RP bazel-bin/tensorflow/core/kernels/libtfkernel_cwise_op.so ${PREFIX}/lib/libtfkernel_cwise_op${SHLIB_EXT}

bazel clean
