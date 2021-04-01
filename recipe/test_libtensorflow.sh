#!/bin/bash

set -euxo pipefail

$CC -o test_c -L${PREFIX}/lib/ -ltensorflow -I${PREFIX}/include/ test_c.c
./test_c
