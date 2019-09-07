# copy libraries
mkdir ${PREFIX}/lib
cp bazel-bin/tensorflow/libtensorflow_cc.so ${PREFIX}/lib/
cp bazel-bin/tensorflow/libtensorflow_framework.so ${PREFIX}/lib/

# remove cc files
find bazel-genfiles/ -name "*.cc" -type f -delete
find tensorflow/cc -name "*.cc" -type f -delete
find tensorflow/core -name "*.cc" -type f -delete
find third_party -name "*.cc" -type f -delete

# copy includes
mkdir -p ${PREFIX}/include/tensorflow
cp -r bazel-genfiles/* ${PREFIX}/include/
cp -r tensorflow/cc ${PREFIX}/include/tensorflow
cp -r tensorflow/core ${PREFIX}/include/tensorflow
cp -r third_party ${PREFIX}/include

cp -r bazel-bin/external/com_google_absl/absl ${PREFIX}/include
cp -r third_party/eigen3/Eigen ${PREFIX}/include
cp -r third_party/eigen3/unsupported ${PREFIX}/include
