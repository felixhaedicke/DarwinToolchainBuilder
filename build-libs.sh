#!/bin/bash

BUILD_ON_DARWIN=0
if [ "`uname`" == "Darwin" ]
then
  BUILD_ON_DARWIN=1
fi

if [ $BUILD_ON_DARWIN -eq 1 ]
then
  PREFIX=$1
  TARGET_DESC=$2
else
  PREFIX=""
  DARWIN_TOOLCHAIN=$1
  TARGET_DESC=$2
fi

if [ $# -ne 2 ]
then
  if [ $BUILD_ON_DARWIN -eq 1 ]
  then
    echo "Usage: <installation prefix> <target descriptor>" >&2
  else
    echo "Usage: <Darwin Toolchain directory> <target descriptor>" >&2
  fi
  echo "Available target descriptors:" >&2
  for target_descriptor in target-descriptors/*
  do
    echo "  `basename ${target_descriptor}`" >&2
  done
  exit 1
fi

. "target-descriptors/${TARGET_DESC}" || exit $?

if [ "${TARGET_TYPE}" == "osx" ]
then
  if [ "${PREFIX}" == "" ]
  then
    PREFIX=${DARWIN_TOOLCHAIN}/lib/${TARGET_ARCH}-MacOSX-${OSX_MIN_SUPPORTED_VERSION}-SDK${DARWIN_SDK_VERSION}.sdk
  fi
  if [ $BUILD_ON_DARWIN -eq 1 ]
  then
    DARWIN_SDK=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX${DARWIN_SDK_VERSION}.sdk
  else
    DARWIN_SDK=${DARWIN_TOOLCHAIN}/lib/SDKs/MacOSX${DARWIN_SDK_VERSION}.sdk
  fi
elif [ "${TARGET_TYPE}" == "ios" ]
then
  if [ "${PREFIX}" == "" ]
  then
    PREFIX=${DARWIN_TOOLCHAIN}/lib/${TARGET_ARCH}-iOS-${IOS_MIN_SUPPORTED_VERSION}-SDK${DARWIN_SDK_VERSION}.sdk
  fi
  if [ $BUILD_ON_DARWIN -eq 1 ]
  then
    DARWIN_SDK=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${DARWIN_SDK_VERSION}.sdk
  else
    DARWIN_SDK=${DARWIN_TOOLCHAIN}/lib/SDKs/iPhoneOS${DARWIN_SDK_VERSION}.sdk
  fi
else
  echo "Unsupported target type \"${TARGET_TYPE}\". Valid types are osx and ios" >&2
  exit 1
fi
echo $DARWIN_SDK

if [ $BUILD_ON_DARWIN -eq 0 ]
then
  PATH="${DARWIN_TOOLCHAIN}/bin:${PATH}"
fi

WORKING_DIR="${PWD}"
BUILD_TMP_DIR="darwin-toolchain-build-temp-${TARGET_DESC}"

rm -rf "${BUILD_TMP_DIR}"
mkdir "${BUILD_TMP_DIR}"

cd "${BUILD_TMP_DIR}"

if [ $BUILD_ON_DARWIN -eq 0 ]
then
  darwin-ld -v || exit 1
  LINKER_VERSION=`darwin-ld -v 2>&1 | awk 'NR==1 { print $1 }'`
  if [ "${LINKER_VERSION}" == "" ]
  then
    exit 1
  fi
fi

TOOLS_DIR="${PREFIX}/tools"
CLANG_WRAPPER_FILE="${TOOLS_DIR}/cc"
CLANGXX_WRAPPER_FILE="${TOOLS_DIR}/c++"
CMAKE_TOOLCHAIN_FILE="${TOOLS_DIR}/toolchain.cmake"

mkdir -p ${TOOLS_DIR} || exit $?

echo \#!/bin/bash > ${CLANG_WRAPPER_FILE} || exit $?
if [ $BUILD_ON_DARWIN -eq 1 ]
then
  echo clang -target ${TARGET_TRIPLE} -isysroot ${DARWIN_SDK} \$@ >> ${CLANG_WRAPPER_FILE} || exit $?
else
  echo ${DARWIN_TOOLCHAIN}/bin/${TARGET_TRIPLE}-clang -isysroot ${DARWIN_SDK} -mlinker-version=${LINKER_VERSION} \$@ >> ${CLANG_WRAPPER_FILE} || exit $?
fi
chmod +x ${CLANG_WRAPPER_FILE} || exit $?

echo \#!/bin/bash > ${CLANGXX_WRAPPER_FILE} || exit $?
if [ $BUILD_ON_DARWIN -eq 1 ]
then
  echo clang++ -target ${TARGET_TRIPLE} -isysroot ${DARWIN_SDK} \$@ >> ${CLANGXX_WRAPPER_FILE} || exit $?
else
  echo ${DARWIN_TOOLCHAIN}/bin/${TARGET_TRIPLE}-clang++ -isysroot ${DARWIN_SDK} -mlinker-version=${LINKER_VERSION} \$@ >> ${CLANGXX_WRAPPER_FILE} || exit $?
fi
chmod +x ${CLANGXX_WRAPPER_FILE} || exit $?

CC="${CLANG_WRAPPER_FILE}"
CXX="${CLANGXX_WRAPPER_FILE}"
if [ $BUILD_ON_DARWIN -eq 1 ]
then
  AR="ar"
  RANLIB="ranlib"
else
  AR="${DARWIN_TOOLCHAIN}/bin/${TARGET_TRIPLE}-ar"
  RANLIB="${DARWIN_TOOLCHAIN}/bin/${TARGET_TRIPLE}-ranlib"
fi

if [ -f ${CMAKE_TOOLCHAIN_FILE} ]
then
  rm ${CMAKE_TOOLCHAIN_FILE} || exit $?
fi
echo set\(CMAKE_SYSTEM_NAME Generic\) >> ${CMAKE_TOOLCHAIN_FILE} || exit $?
echo set\(CMAKE_C_COMPILER \"${CLANG_WRAPPER_FILE}\"\) >> ${CMAKE_TOOLCHAIN_FILE} || exit $?
echo set\(CMAKE_CXX_COMPILER \"${CLANGXX_WRAPPER_FILE}\"\) >> ${CMAKE_TOOLCHAIN_FILE} || exit $?
echo set\(CMAKE_AR \"${AR}\" CACHE FILEPATH \"Archiver\"\) >> ${CMAKE_TOOLCHAIN_FILE} || exit $?
echo set\(CMAKE_RANLIB \"${RANLIB}\"\) >> ${CMAKE_TOOLCHAIN_FILE} || exit $?

tar xzvf ../libpng-1.6.14.tar.gz || exit $?
cd libpng-1.6.14 || exit $?
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

tar xzvf ../libjpeg-turbo-1.3.1.tar.gz || exit $?
cd libjpeg-turbo-1.3.1 || exit $?
./configure --host="${TARGET_TRIPLE}" --enable-static=yes --enable-shared=no --prefix="${PREFIX}" CC="${CC}" CXX="${CXX}" CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" || exit $?
make -j6 || exit $?
make install || exit $?
cd .. || exit $?

tar xzvf ../gettext-0.19.1.tar.gz || exit $?
cd gettext-0.19.1 || exit $?
./configure --host="${TARGET_TRIPLE}" --enable-static=yes --enable-shared=no --prefix="${PREFIX}" CC="${CC}" CXX="${CXX}" CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" || exit $?
cd gettext-runtime/intl || exit $?
make -j6 || exit $?
make install || exit $?
cd ../../.. || exit $?

if [ "${TARGET_TYPE}" == "ios" ]
then
  tar xzvf ../curl-7.37.0.tar.gz || exit $?
  cd curl-7.37.0 || exit $?
  ./configure --host="${TARGET_TRIPLE}" --enable-static=yes --enable-shared=no --enable-ipv6 --prefix="${PREFIX}" CC="${CC}" CXX="${CXX}" CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" || exit $?
  make -j6 || exit $?
  make install || exit $?
  cd .. || exit $?
fi

tar xzvf ../SDL2-2.0.3.tar.gz || exit $?
cd SDL2-2.0.3 || exit $?
./configure --host="${TARGET_TRIPLE}" --enable-static=yes --enable-shared=no --prefix="${PREFIX}" CC="${CC}" CXX="${CXX}" CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" || exit $?
if [ "${TARGET_TYPE}" == "ios" ]
then
  cp include/SDL_config_iphoneos.h include/SDL_config.h || exit $?
fi
make -j6 || exit $?
make install || exit $?
cd .. || exit $?

tar xzvf ../SDL2_mixer-2.0.0.tar.gz || exit $?
cd SDL2_mixer-2.0.0 || exit $?
cd external/libmodplug-0.8.8.4
./configure --host="${TARGET_TRIPLE}" --enable-static=yes --enable-shared=no --prefix="${PREFIX}" CC="${CC}" CXX="${CXX}" CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" || exit $?
make -j6 || exit $?
make install || exit $?
cd ../../ || exit $?
PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" ./configure --host="${TARGET_TRIPLE}" --enable-static=yes --enable-shared=no --prefix="${PREFIX}" --with-sdl-prefix="${PREFIX}" --enable-music-midi-native=no CC="${CC}" CXX="${CXX}" CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" || exit $?
make LDFLAGS="-lstdc++" -j6 || exit $?
make install || exit $?
sed -i".bak" "s/Requires:/Requires: libmodplug/g" "${PREFIX}/lib/pkgconfig/SDL2_mixer.pc" || exit $?
rm -rf "${PREFIX}/lib/pkgconfig"/*.bak || exit $?
cd .. || exit $?

tar xzvf ../SDL2_net-2.0.0.tar.gz || exit $?
cd SDL2_net-2.0.0 || exit $?
./configure --host="${TARGET_TRIPLE}" --enable-static=yes --enable-shared=no --prefix="${PREFIX}" --with-sdl-prefix="${PREFIX}" CC="${CC}" CXX="${CXX}" CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" || exit $?
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

unzip ../glm-0.9.5.4.zip || exit $?
cd glm || exit $?
cp -r glm "${PREFIX}/include" || exit $?
rm -rf "${PREFIX}/include"/*.txt || exit $?
cd .. || exit $?

cd "${WORKING_DIR}"
rm -rf "${BUILD_TMP_DIR}"

