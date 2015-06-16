#!/bin/sh

# This script tests the CMake build by:
# - builds the main CMakeLists.txt
# - builds shell.c again in a separate build tree so
#   the config-module will also be tested

# Set the environment variable BUILD_SHARED_LIBS=1 to test the shared build

set -ex

cmake -H. -Bout/build/sqlite3 -DCMAKE_INSTALL_PREFIX=${PWD}/out/install -DCMAKE_BUILD_TYPE=Debug -DBUILD_SHARED_LIBS=$BUILD_SHARED_LIBS
cmake --build out/build/sqlite3 --target install --config Debug --clean-first
cmake -DCMAKE_BUILD_TYPE=Release out/build/sqlite3
cmake --build out/build/sqlite3 --target install --config Release --clean-first

cmake -Hcmake-testbuild -Bout/build/cmake-testbuild -DCMAKE_INSTALL_PREFIX=${PWD}/out/install -DCMAKE_PREFIX_PATH=${PWD}/out/install -DCMAKE_BUILD_TYPE=Release
cmake --build out/build/cmake-testbuild --target install --config Release

export LD_LIBRARY_PATH=./out/lib:$LD_LIBRARY_PATH

