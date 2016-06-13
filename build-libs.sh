#!/bin/bash

. versions.inc

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

TOOLS_DIR="${PREFIX}/tools"
CLANG_WRAPPER_FILE="${TOOLS_DIR}/cc"
CLANGXX_WRAPPER_FILE="${TOOLS_DIR}/c++"
CMAKE_TOOLCHAIN_FILE="${TOOLS_DIR}/toolchain.cmake"

mkdir -p ${TOOLS_DIR} || exit $?

echo \#!/bin/bash > ${CLANG_WRAPPER_FILE} || exit $?
if [ $BUILD_ON_DARWIN -eq 1 ]
then
  echo clang -target ${TARGET_TRIPLE} -arch ${TARGET_ARCH} -isysroot ${DARWIN_SDK} \$@ >> ${CLANG_WRAPPER_FILE} || exit $?
else
  echo ${DARWIN_TOOLCHAIN}/bin/${TARGET_TRIPLE}-clang -arch ${TARGET_ARCH} -isysroot ${DARWIN_SDK} \$@ >> ${CLANG_WRAPPER_FILE} || exit $?
fi
chmod +x ${CLANG_WRAPPER_FILE} || exit $?

echo \#!/bin/bash > ${CLANGXX_WRAPPER_FILE} || exit $?
if [ $BUILD_ON_DARWIN -eq 1 ]
then
  echo clang++ -target ${TARGET_TRIPLE} -arch ${TARGET_ARCH} -isysroot ${DARWIN_SDK} \$@ >> ${CLANGXX_WRAPPER_FILE} || exit $?
else
  echo ${DARWIN_TOOLCHAIN}/bin/${TARGET_TRIPLE}-clang++ -arch ${TARGET_ARCH} -isysroot ${DARWIN_SDK} \$@ >> ${CLANGXX_WRAPPER_FILE} || exit $?
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

if [ ${BUILD_LIBPNG} == true ]
then
  tar xzvf ../libpng-${LIB_VERSION_LIBPNG}.tar.gz || exit $?
  cd libpng-${LIB_VERSION_LIBPNG} || exit $?
  ./configure --host="${TARGET_TRIPLE}" --enable-static=yes --enable-shared=no --prefix="${PREFIX}" CC="${CC}" CXX="${CXX}" CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" || exit $?
  make -j6 || exit $?
  make install || exit $?
  cd .. || exit $?
fi

if [ ${BUILD_FREETYPE} == true ]
then
  tar xzvf ../freetype-${LIB_VERSION_FREETYPE}.tar.gz || exit $?
  cd freetype-${LIB_VERSION_FREETYPE} || exit $?
  ./configure --host="${TARGET_TRIPLE}" --enable-static=yes --enable-shared=no --prefix="${PREFIX}" --with-png=no --with-harfbuzz=no CC="${CC}" CXX="${CXX}" CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" || exit $?
  make -j6 || exit $?
  make install || exit $?
  if [ $BUILD_ON_DARWIN -eq 1 ]
  then
    sed -i "" "s/zlib,//g" "${PREFIX}/lib/pkgconfig/freetype2.pc" || exit $?
    sed -i "" "s/zlib//g" "${PREFIX}/lib/pkgconfig/freetype2.pc" || exit $?
  else
    sed -i "s/zlib,//g" "${PREFIX}/lib/pkgconfig/freetype2.pc" || exit $?
    sed -i "s/zlib//g" "${PREFIX}/lib/pkgconfig/freetype2.pc" || exit $?
  fi
  cd .. || exit $?
fi

if [ ${BUILD_LIBJPEG_TURBO} == true ]
then
  tar xzvf ../libjpeg-turbo-${LIB_VERSION_LIBJPEG_TURBO}.tar.gz || exit $?
  cd libjpeg-turbo-${LIB_VERSION_LIBJPEG_TURBO} || exit $?
  cp ../libpng-${LIB_VERSION_LIBPNG}/config.sub . || exit $?
  ./configure --host="${TARGET_TRIPLE}" --enable-static=yes --enable-shared=no --prefix="${PREFIX}" CC="${CC}" CXX="${CXX}" CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" || exit $?
  make -j6 || exit $?
  make install || exit $?
  cd .. || exit $?
fi

if [ ${BUILD_CURL} == true ]
then
  tar xzvf ../curl-${LIB_VERSION_CURL}.tar.gz || exit $?
  cd curl-${LIB_VERSION_CURL} || exit $?
  ./configure --host="${TARGET_TRIPLE}" --enable-static=yes --enable-shared=no --enable-ipv6 --prefix="${PREFIX}" CC="${CC}" CXX="${CXX}" CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" || exit $?
  make -j6 || exit $?
  make install || exit $?
  cd .. || exit $?
fi

if [ ${BUILD_SDL2} == true ]
then
  tar xzvf ../SDL2-${LIB_VERSION_SDL2}.tar.gz || exit $?
  cd SDL2-${LIB_VERSION_SDL2} || exit $?
  if [ "${TARGET_TYPE}" == "ios" ]
  then
    if [ $BUILD_ON_DARWIN -eq 1 ]
    then
      sed -i "" "s/arm\*-apple-darwin\*)/${TARGET_TRIPLE}\*)/g" configure || exit $?
    else
      sed -i "s/arm\*-apple-darwin\*)/${TARGET_TRIPLE}\*)/g" configure || exit $?
    fi
  fi
  ./configure --host="${TARGET_TRIPLE}" --enable-static=yes --enable-shared=no --prefix="${PREFIX}" --enable-video-x11=no CC="${CC}" CXX="${CXX}" CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" || exit $?
  if [ "${TARGET_TYPE}" == "ios" ]
  then
    cp include/SDL_config_iphoneos.h include/SDL_config.h || exit $?
  fi
  if [ "${TARGET_TYPE}" == "ios" ]
  then
    sed -i "s/${CFLAGS}/${CFLAGS} -x objective-c -fobjc-arc/g" Makefile || exit $?
  fi
  make -j6 || exit $?
  make install || exit $?
  cd .. || exit $?
fi

if [ ${BUILD_SDL2_MIXER} == true ]
then
  tar xzvf ../SDL2_mixer-${LIB_VERSION_SDL2_MIXER}.tar.gz || exit $?
  cd SDL2_mixer-${LIB_VERSION_SDL2_MIXER} || exit $?
  cd external/libmodplug-${LIB_VERSION_SDL2_MIXER_LIBMODPLUG} || exit $?
  ./configure --host="${TARGET_TRIPLE}" --enable-static=yes --enable-shared=no --prefix="${PREFIX}" CC="${CC}" CXX="${CXX}" CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" || exit $?
  make -j6 || exit $?
  make install || exit $?
  cd ../../ || exit $?
  PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" ./configure --host="${TARGET_TRIPLE}" --enable-static=yes --enable-shared=no --prefix="${PREFIX}" --with-sdl-prefix="${PREFIX}" --enable-music-midi-native=no CC="${CC}" CXX="${CXX}" CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" || exit $?
  make LDFLAGS="-lstdc++" -j6 || exit $?
  make install || exit $?
  if [ $BUILD_ON_DARWIN -eq 1 ]
  then
    sed -i "" "s/Requires:/Requires: libmodplug/g" "${PREFIX}/lib/pkgconfig/SDL2_mixer.pc" || exit $?
  else
    sed -i "s/Requires:/Requires: libmodplug/g" "${PREFIX}/lib/pkgconfig/SDL2_mixer.pc" || exit $?
  fi
  rm -rf "${PREFIX}/lib/pkgconfig"/*.bak || exit $?
  cd .. || exit $?
fi


if [ ${BUILD_SDL2_NET} == true ]
then
  tar xzvf ../SDL2_net-${LIB_VERSION_SDL2_NET}.tar.gz || exit $?
  cd SDL2_net-${LIB_VERSION_SDL2_NET} || exit $?
  ./configure --host="${TARGET_TRIPLE}" --enable-static=yes --enable-shared=no --prefix="${PREFIX}" --with-sdl-prefix="${PREFIX}" CC="${CC}" CXX="${CXX}" CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" || exit $?
  make -j6 || exit $?
  make install || exit $?
  cd .. || exit $?
fi

if [ ${BUILD_GLM} == true ]
then
  unzip ../glm-${LIB_VERSION_GLM}.zip || exit $?
  cd glm || exit $?
  cp -r glm "${PREFIX}/include" || exit $?
  rm -rf "${PREFIX}/include"/*.txt || exit $?
  cd .. || exit $?
fi

cd "${WORKING_DIR}"
rm -rf "${BUILD_TMP_DIR}"

