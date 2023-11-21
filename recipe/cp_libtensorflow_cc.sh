tar -C ${PREFIX} -xf $SRC_DIR/libtensorflow_cc_output.tar
mkdir -p ${PREFIX}/include/ml_dtypes/include/
cp float8.h ${PREFIX}/include/ml_dtypes/include/float8.h
cp int4.h ${PREFIX}/include/ml_dtypes/include/int4.h
rsync -av ${PREFIX}/include/external/local_tsl/tsl/ ${PREFIX}/include/tsl
