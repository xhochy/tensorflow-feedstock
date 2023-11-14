tar -C ${PREFIX} -xf $SRC_DIR/libtensorflow_cc_output.tar
mkdir -p ${PREFIX}/include/tensorflow/tsl/platform/include
cp float8.h ${PREFIX}/include/tensorflow/tsl/platform/include
