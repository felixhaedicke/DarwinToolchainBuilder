#!/bin/bash

PREFIX=$1

if [ "${PREFIX}" == "" ]
then
  echo "Usage: <Installation Directory>" >&2
  exit 1
fi

WORKING_DIR="${PWD}"
BUILD_TMP_DIR="darwin-toolchain-build-temp"

rm -rf "${BUILD_TMP_DIR}"
mkdir "${BUILD_TMP_DIR}"

cd "${BUILD_TMP_DIR}"

git clone https://github.com/felixhaedicke/cctools-port.git
cd cctools-port/cctools
./autogen.sh
./configure "--prefix=${PREFIX}" --program-prefix=darwin-
make PROGRAM_PREFIX=darwin- -j6
make install

git clone git://git.saurik.com/ldid.git
cd ldid
git submodule init
git submodule update
clang++ -o "${PREFIX}/bin/ldid" ldid.cpp -I. -x c lookup2.c sha1.c

cd "${PREFIX}/bin"
ln -s darwin-codesign_allocate codesign_allocate
for triple in powerpc-apple-darwin9 i386-apple-darwin9 x86_64-apple-darwin9 armv6-apple-darwin9 armv7-apple-darwin9
do
  ln -s `which clang` $triple-clang
  ln -s `which clang++` $triple-clang++
  ln -s darwin-as $triple-as
  ln -s darwin-nm $triple-nm
  ln -s darwin-ranlib $triple-ranlib
  ln -s darwin-ar $triple-ar
  ln -s darwin-ld $triple-ld
  ln -s darwin-strip $triple-strip
  ln -s darwin-libtool $triple-libtool
done

cd "${WORKING_DIR}"
rm -rf "${BUILD_TMP_DIR}"

