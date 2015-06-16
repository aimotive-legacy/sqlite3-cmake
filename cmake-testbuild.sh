#!/bin/sh

# This script tests the CMake build by:
# - builds the main CMakeLists.txt
# - builds shell.c again in a separate build tree so
#   the config-module will also be tested

# Set the environment variable BUILD_SHARED_LIBS=1 to test the shared build

set -ex

cmake -H. -Bout/build/libsqlite3 -DCMAKE_INSTALL_PREFIX=${PWD}/out -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=$BUILD_SHARED_LIBS -DSQLITE_BUILD_SHELL=0
cmake --build out/build/libsqlite3 --target install --config Release

cmake -H. -Bout/build/shell -DCMAKE_INSTALL_PREFIX=${PWD}/out -DCMAKE_PREFIX_PATH=${PWD}/out -DCMAKE_BUILD_TYPE=Release -DSQLITE_BUILD_LIB=0
cmake --build out/build/shell --target install --config Release

export LD_LIBRARY_PATH=./out/lib:$LD_LIBRARY_PATH

