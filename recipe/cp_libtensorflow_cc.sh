mkdir -p $PREFIX/lib
# copy library
cp -d bazel-bin/tensorflow/libtensorflow_cc.so* $PREFIX/lib/
cp -d bazel-bin/tensorflow/libtensorflow_framework.so* $PREFIX/lib/
cp -d $PREFIX/lib/libtensorflow_framework.so.2 $PREFIX/lib/libtensorflow_framework.so
# Make writable so patchelf can do its magic
chmod u+w $PREFIX/lib/libtensorflow*

mkdir -p $PREFIX/include
mkdir -p $PREFIX/include/tensorflow
# copy headers
rsync -avzh --exclude '_virtual_includes/' --exclude 'pip_package/' --exclude 'lib_package/' --include '*/' --include '*.h' --include '*.inc' --exclude '*' bazel-bin/ $PREFIX/include/
rsync -avzh --include '*/' --include '*.h' --include '*.inc' --exclude '*' tensorflow/cc $PREFIX/include/tensorflow/
rsync -avzh --include '*/' --include '*.h' --include '*.inc' --exclude '*' tensorflow/core $PREFIX/include/tensorflow/
rsync -avzh --include '*/' --include '*' --exclude '*.cc' third_party/ $PREFIX/include/third_party/
rsync -avzh --include '*/' --include '*' --exclude '*.txt' bazel-work/external/eigen_archive/Eigen/ $PREFIX/include/Eigen/
rsync -avzh --include '*/' --include '*' --exclude '*.txt' bazel-work/external/eigen_archive/unsupported/ $PREFIX/include/unsupported/
#rsync -avzh --include '*/' --include '*.h' --include '*.inc' --exclude '*' bazel-work/external/com_google_protobuf/src/google/ $PREFIX/include/google/
#rsync -avzh --include '*/' --include '*.h' --include '*.inc' --exclude '*' bazel-work/external/com_google_absl/absl/ $PREFIX/include/absl/
