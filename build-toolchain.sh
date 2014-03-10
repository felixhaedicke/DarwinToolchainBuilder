#!/bin/bash

PREFIX=$1

if [ "${PREFIX}" == "" ]
then
  echo "Usage: <Installation Directory>" >&2
  exit 1
fi

WORKING_DIR="${PWD}"
BUILD_TMP_DIR="darwin-toolchain-build-temp"

rm -rf "${BUILD_TMP_DIR}" || exit $?
mkdir "${BUILD_TMP_DIR}" || exit $?

cd "${BUILD_TMP_DIR}" || exit $?

git clone https://github.com/felixhaedicke/cctools-port.git || exit $?
cd cctools-port/cctools || exit $?
./autogen.sh || exit $?
./configure "--prefix=${PREFIX}" --program-prefix=darwin- || exit $?
make PROGRAM_PREFIX=darwin- -j6 || exit $?
make install || exit $?

cd "${PREFIX}/bin" || exit $?
ln -s `which clang` clang || exit $?
ln -s `which clang++` clang++ || exit $?
ln -s `which clang` cc || exit $?
ln -s `which clang++` c++ || exit $?
ln -s darwin-codesign_allocate codesign_allocate || exit $?
for triple in powerpc-apple-darwin9 i386-apple-darwin9 x86_64-apple-darwin9 armv6-apple-darwin9 armv7-apple-darwin9
do
  ln -s `which clang` $triple-clang || exit $?
  ln -s `which clang++` $triple-clang++ || exit $?
  ln -s darwin-as $triple-as || exit $?
  ln -s darwin-nm $triple-nm || exit $?
  ln -s darwin-ranlib $triple-ranlib || exit $?
  ln -s darwin-ar $triple-ar || exit $?
  ln -s darwin-ld $triple-ld || exit $?
  ln -s darwin-strip $triple-strip || exit $?
  ln -s darwin-libtool $triple-libtool || exit $?
done

cd "${WORKING_DIR}" || exit $?
rm -rf "${BUILD_TMP_DIR}" || exit $?

