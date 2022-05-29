#!/bin/bash

set -ex

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
export BUILD_TARGET="
  //tensorflow/core/kernels:libtfkernel_conv_ops.so
"
# This is heavily dependent on MLIR-generated kernel code.
# It should probably be its own build with the other MLIR-based ops.
# We could split out the MLIR-based ones into individual ones once we can use a prebuilt MLIR.
#  //tensorflow/core/kernels:libtfkernel_cwise_op.so
#  //tensorflow/core/kernels:libtfkernel_unique_op.so
#  //tensorflow/core/kernels:libtfkernel_dynamic_partition_op.so
#  //tensorflow/core/kernels:libtfkernel_dynamic_stitch_op.so
#  //tensorflow/core/kernels:libtfkernel_strided_slice_op.so

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

cp -RP bazel-bin/tensorflow/core/kernels/libtfkernel_conv_ops.so ${PREFIX}/lib/libtfkernel_conv_ops${SHLIB_EXT}
# cp -RP bazel-bin/tensorflow/core/kernels/libtfkernel_cwise_op.so ${PREFIX}/lib/libtfkernel_cwise_op${SHLIB_EXT}
# cp -RP bazel-bin/tensorflow/core/kernels/libtfkernel_unique_op.so ${PREFIX}/lib/libtfkernel_unique_op${SHLIB_EXT}
# cp -RP bazel-bin/tensorflow/core/kernels/libtfkernel_dynamic_partition_op.so ${PREFIX}/lib/libtfkernel_dynamic_partition_op${SHLIB_EXT}
# cp -RP bazel-bin/tensorflow/core/kernels/libtfkernel_dynamic_stitch_op.so ${PREFIX}/lib/libtfkernek_dynamic_stitch_op${SHLIB_EXT}
# cp -RP bazel-bin/tensorflow/core/kernels/libtfkernel_strided_slice_op.so ${PREFIX}/lib/libtfkernel_strided_slice_op${SHLIB_EXT}

bazel clean
