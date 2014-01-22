#!/bin/bash

DARWIN_TOOLCHAIN=$1
TARGET_DESC=$2

if [ "${DARWIN_TOOLCHAIN}" == "" ] || [ "${TARGET_DESC}" == "" ]
then
  echo "Usage: <Darwin Toolchain Directory> <Target Descriptor>" >&2
  exit 1
fi

. "${TARGET_DESC}.shinc" || exit $?

PATH="${DARWIN_TOOLCHAIN}/bin:${PATH}"

WORKING_DIR="${PWD}"
BUILD_TMP_DIR="darwin-toolchain-build-temp-${TARGET_DESC}"

rm -rf "${BUILD_TMP_DIR}"
mkdir "${BUILD_TMP_DIR}"

cd "${BUILD_TMP_DIR}"

LINKER_VERSION=`darwin-ld -v 2>&1 | awk 'NR==1 { print $1 }'`
if [ "${LINKER_VERSION}" == "" ]
then
  exit 1
fi

CC="${TARGET_TRIPLE}-clang -isysroot ${DARWIN_SDK} -mlinker-version=${LINKER_VERSION}"
CXX="${TARGET_TRIPLE}-clang++ -isysroot ${DARWIN_SDK} -mlinker-version=${LINKER_VERSION}"

tar xzvf ../libpng-1.6.8.tar.gz || exit $?
cd libpng-1.6.8 || exit $?
./configure --host="${TARGET_TRIPLE}" --enable-static=yes --enable-shared=no --prefix="${PREFIX}" CC="${CC}" CXX="${CXX}" CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" || exit $?
make -j6 || exit $?
make install || exit $?
cd .. || exit $?

tar xzvf ../freetype-2.4.12.tar.gz || exit $?
cd freetype-2.4.12 || exit $?
./configure --host="${TARGET_TRIPLE}" --enable-static=yes --enable-shared=no --prefix="${PREFIX}" CC="${CC}" CXX="${CXX}" CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" || exit $?
make -j6 || exit $?
make install || exit $?
cd .. || exit $?

tar xzvf ../jpegsrc.v9.tar.gz || exit $?
cd jpeg-9 || exit $?
./configure --host="${TARGET_TRIPLE}" --enable-static=yes --enable-shared=no --prefix="${PREFIX}" CC="${CC}" CXX="${CXX}" CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" || exit $?
make -j6 || exit $?
make install || exit $?
cd .. || exit $?

tar xzvf ../gettext-0.18.3.tar.gz || exit $?
cd gettext-0.18.3 || exit $?
./configure --host="${TARGET_TRIPLE}" --enable-static=yes --enable-shared=no --prefix="${PREFIX}" CC="${CC}" CXX="${CXX}" CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" || exit $?
cd gettext-runtime/intl || exit $?
make -j6 || exit $?
make install || exit $?
cd ../../.. || exit $?

tar xzvf ../SDL2-2.0.1.tar.gz || exit $?
cd SDL2-2.0.1 || exit $?
if [ "${TARGET_TYPE}" == "osx" ]
then
  sed -i 's/-falign-loops=16//g' configure.in || exit $?
  ./autogen.sh || exit $?
fi
./configure --host="${TARGET_TRIPLE}" --enable-static=yes --enable-shared=no --prefix="${PREFIX}" CC="${CC}" CXX="${CXX}" CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" || exit $?
if [ "${TARGET_TYPE}" == "ios" ]
then
  cp include/SDL_config_iphoneos.h include/SDL_config.h || exit $?
fi
make -j6 || exit $?
make install || exit $?
cd .. || exit $?

if [ "${TARGET_TYPE}" == "osx" ]
then
  tar xzvf ../SDL-1.2.15.tar.gz || exit $?
  cd SDL-1.2.15 || exit $?
  ./configure --host="${TARGET_TRIPLE}" --enable-static=yes --enable-shared=no --prefix="${PREFIX}" CC="${CC}" CXX="${CXX}" CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" --enable-video-x11=no || exit $?
  make -j6 || exit $?
  make install || exit $?
  cd .. || exit $?
fi

cd "${WORKING_DIR}"
rm -rf "${BUILD_TMP_DIR}"

