# install the whl using pip
pip install --no-deps *.whl

# The tensorboard package has the proper entrypoint
rm -f ${PREFIX}/bin/tensorboard
