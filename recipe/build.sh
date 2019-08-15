#!/bin/bash

set -ex

if [[ "$target_platform" == "osx-64" ]]; then
  export CC=clang
  export CXX=clang++
fi

export PATH="$PWD:$PATH"
export CC=$(basename $CC)
export CXX=$(basename $CXX)
export LIBDIR=$PREFIX/lib
export INCLUDEDIR=$PREFIX/include

echo "#!/bin/bash"                                > compiler-wrapper
echo "export C_INCLUDE_PATH=$PREFIX/include"     >> compiler-wrapper
echo "export CPLUS_INCLUDE_PATH=$PREFIX/include" >> compiler-wrapper
echo "export CONDA_BUILD_SYSROOT=$CONDA_BUILD_SYSROOT"  >> compiler-wrapper
chmod +x "compiler-wrapper"
cp compiler-wrapper $CC
cp compiler-wrapper $CXX
echo "exec $BUILD_PREFIX/bin/$CC -L$PREFIX/lib \"\$@\""   >> $CC
echo "exec $BUILD_PREFIX/bin/$CXX -L$PREFIX/lib \"\$@\""  >> $CXX

export TF_SYSTEM_LIBS="llvm,zlib_archive,com_google_protobuf,com_google_protobuf_cc,png_archive,curl"

# do not build with MKL support
export TF_NEED_MKL=0
export BAZEL_MKL_OPT=""

mkdir -p ./bazel_output_base
export BAZEL_OPTS="--batch "

# Linux
# the following arguments are useful for debugging
#    --logging=6
#    --subcommands

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

export TF_ENABLE_XLA=1

# Python settings
export PYTHON_BIN_PATH=${PYTHON}
export PYTHON_LIB_PATH=${SP_DIR}
export USE_DEFAULT_PYTHON_LIB_PATH=1

# additional settings
export CC_OPT_FLAGS="-march=nocona -mtune=haswell"
export TF_NEED_IGNITE=1
export TF_NEED_OPENCL=0
export TF_NEED_OPENCL_SYCL=0
export TF_NEED_CUDA=0
export TF_NEED_ROCM=0
export TF_NEED_MPI=0
export TF_DOWNLOAD_CLANG=0
export TF_SET_ANDROID_WORKSPACE=0
./configure

# build using bazel
bazel ${BAZEL_OPTS} build ${BUILD_OPTS} //tensorflow/tools/pip_package:build_pip_package

# build a whl file
mkdir -p $SRC_DIR/tensorflow_pkg
bazel-bin/tensorflow/tools/pip_package/build_pip_package $SRC_DIR/tensorflow_pkg

# install the whl using pip
pip install --no-deps $SRC_DIR/tensorflow_pkg/*.whl

# The tensorboard package has the proper entrypoint
rm -f ${PREFIX}/bin/tensorboard
