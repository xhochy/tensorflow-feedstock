# copy libraries
mkdir -p ${PREFIX}/lib
cp bazel-bin/tensorflow/*.so ${PREFIX}/lib/

# copy includes
mkdir -p ${PREFIX}/include/tensorflow/c
cp -R tensorflow/c/* ${PREFIX}/include/tensorflow/c/.
mkdir -p ${PREFIX}/include/tensorflow/core/platform/
cp tensorflow/core/platform/*.h ${PREFIX}/include/tensorflow/core/platform/
