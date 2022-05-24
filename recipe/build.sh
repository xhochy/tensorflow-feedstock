#!/bin/bash

set -exuo pipefail

# Quick debug:
# cp -r ${RECIPE_DIR}/build.sh . && bazel clean && bash -x build.sh --logging=6 | tee log.txt
# Dependency graph:
# bazel query 'deps(//tensorflow/tools/lib_package:libtensorflow)' --output graph > graph.in

mkdir -p ./bazel_output_base

# Ensure we persist the setting across multiple tensorflow artefacts.
mkdir -p ${PREFIX}/etc/tensorflow
cp ${RECIPE_DIR}/tf_environment.sh ${RECIPE_DIR}/tf_settings.sh ${PREFIX}/etc/tensorflow
source ${RECIPE_DIR}/tf_environment.sh

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
export BUILD_TARGET="//tensorflow:libtensorflow_framework_import_lib //tensorflow:libtensorflow_framework${SHLIB_EXT} //tensorflow/core/common_runtime:libtensorflow_core_cpu${SHLIB_EXT}"

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

cp -RP bazel-bin/tensorflow/libtensorflow_framework.* ${PREFIX}/lib/
cp -RP bazel-bin/tensorflow/core/common_runtime/libtensorflow_core_cpu${SHLIB_EXT} ${PREFIX}/lib/

bazel clean
