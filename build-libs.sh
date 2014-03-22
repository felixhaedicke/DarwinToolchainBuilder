#!/bin/bash

DARWIN_TOOLCHAIN=$1
TARGET_DESC=$2

if [ "${DARWIN_TOOLCHAIN}" == "" ] || [ "${TARGET_DESC}" == "" ]
then
  echo "Usage: <Darwin Toolchain Directory> <Target Descriptor>" >&2
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
  DARWIN_SDK=${DARWIN_TOOLCHAIN}/lib/SDKs/MacOSX${DARWIN_SDK_VERSION}.sdk
elif [ "${TARGET_TYPE}" == "ios" ]
then
  DARWIN_SDK=${DARWIN_TOOLCHAIN}/lib/SDKs/iPhoneOS${DARWIN_SDK_VERSION}.sdk
else
  echo "Unsupported target type \"${TARGET_TYPE}\". Valid types are osx and ios" >&2
  exit 1
fi
echo $DARWIN_SDK

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

TOOLS_DIR="${PREFIX}/tools"
CLANG_WRAPPER_FILE="${TOOLS_DIR}/cc"
CLANGXX_WRAPPER_FILE="${TOOLS_DIR}/c++"
CMAKE_TOOLCHAIN_FILE="${TOOLS_DIR}/toolchain.cmake"

mkdir -p ${TOOLS_DIR} || exit $?

echo \#!/bin/bash > ${CLANG_WRAPPER_FILE} || exit $?
echo ${DARWIN_TOOLCHAIN}/bin/${TARGET_TRIPLE}-clang -isysroot ${DARWIN_SDK} -mlinker-version=${LINKER_VERSION} \$@ >> ${CLANG_WRAPPER_FILE} || exit $?
chmod +x ${CLANG_WRAPPER_FILE} || exit $?

echo \#!/bin/bash > ${CLANGXX_WRAPPER_FILE} || exit $?
echo ${DARWIN_TOOLCHAIN}/bin/${TARGET_TRIPLE}-clang++ -isysroot ${DARWIN_SDK} -mlinker-version=${LINKER_VERSION} \$@ >> ${CLANGXX_WRAPPER_FILE} || exit $?
chmod +x ${CLANGXX_WRAPPER_FILE} || exit $?

CC="${CLANG_WRAPPER_FILE}"
CXX="${CLANGXX_WRAPPER_FILE}"

if [ -f ${CMAKE_TOOLCHAIN_FILE} ]
then
  rm ${CMAKE_TOOLCHAIN_FILE} || exit $?
fi
echo set\(CMAKE_SYSTEM_NAME Generic\) >> ${CMAKE_TOOLCHAIN_FILE} || exit $?
echo set\(CMAKE_C_COMPILER \"${CLANG_WRAPPER_FILE}\"\) >> ${CMAKE_TOOLCHAIN_FILE} || exit $?
echo set\(CMAKE_CXX_COMPILER \"${CLANGXX_WRAPPER_FILE}\"\) >> ${CMAKE_TOOLCHAIN_FILE} || exit $?
echo set\(CMAKE_AR \"${DARWIN_TOOLCHAIN}/bin/${TARGET_TRIPLE}-ar\" CACHE FILEPATH \"Archiver\"\) >> ${CMAKE_TOOLCHAIN_FILE} || exit $?
echo set\(CMAKE_RANLIB \"${DARWIN_TOOLCHAIN}/bin/${TARGET_TRIPLE}-ranlib\"\) >> ${CMAKE_TOOLCHAIN_FILE} || exit $?

if [ $BUILD_LIBCXX -eq 1 ]
then
  tar xzvf ../libcxx-3.4.src.tar.gz || exit $?
  tar xzvf ../libcxxabi-rev201497.tar.gz || exit $?
  mkdir libcxxabi-build || exit $?
  cd libcxxabi-build || exit $?
  for src in ../libcxxabi-rev201497/src/*.cpp
  do
    echo CXX ${src}
    $CXX ${CXXFLAGS} ${src} -I../libcxxabi-rev201497/include -I../libcxx-3.4/include -fstrict-aliasing -std=c++11 -c -o `basename ${src}`.o || exit $?
  done
  echo AR libc++abi.a
  ${TARGET_TRIPLE}-ar rcs libc++abi.a *.o || exit $?
  mkdir -p "${PREFIX}/lib" || exit $?
  cp libc++abi.a "${PREFIX}/lib" || exit $?
  mkdir -p "${PREFIX}/include/libcxxabi" || exit $?
  cp -r ../libcxxabi-rev201497/include/* "${PREFIX}/include/libcxxabi" || exit $?
  cd .. || exit $?

  mkdir libcxx-build || exit $?
  cd libcxx-build || exit $?
  cmake ../libcxx-3.4 "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}" -DLIBCXX_CXX_ABI=libcxxabi "-DLIBCXX_LIBCXXABI_INCLUDE_PATHS=${PREFIX}/include/libcxxabi" -DCMAKE_BUILD_TYPE=Release -DLIBCXX_ENABLE_SHARED=false -DLIBCXX_TARGET_TRIPLE=${TARGET_TRIPLE} "-DCMAKE_INSTALL_PREFIX=${PREFIX}" || exit $?
  make -j6 || exit $?
  make install || exit $?
  cd .. || exit $?
fi

if [ $BUILD_ZLIB -eq 1 ]
then
  tar xzvf ../zlib-1.2.8.tar.gz || exit $?
  cd zlib-1.2.8 || exit $?
  ./configure --static "--prefix=${PREFIX}" || exit $?
  make "CC=$CC" "CFLAGS=${CFLAGS}" AR=${TARGET_TRIPLE}-ar RANLIB=${TARGET_TRIPLE}-ranlib install || exit $?
  cd .. || exit $?
fi

tar xzvf ../libpng-1.6.9.tar.gz || exit $?
cd libpng-1.6.9 || exit $?
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

tar xzvf ../libjpeg-turbo-1.3.0.tar.gz || exit $?
cd libjpeg-turbo-1.3.0 || exit $?
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

tar xzvf ../SDL2-2.0.3.tar.gz || exit $?
cd SDL2-2.0.3 || exit $?
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
sed -i "s/Requires:/Requires: libmodplug/g" "${PREFIX}/lib/pkgconfig/SDL2_mixer.pc" || exit $?
cd .. || exit $?

tar xzvf ../SDL2_net-2.0.0.tar.gz || exit $?
cd SDL2_net-2.0.0 || exit $?
./configure --host="${TARGET_TRIPLE}" --enable-static=yes --enable-shared=no --prefix="${PREFIX}" --with-sdl-prefix="${PREFIX}" CC="${CC}" CXX="${CXX}" CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" || exit $?
make -j6 || exit $?
make install || exit $?
cd .. || exit $?

cd "${WORKING_DIR}"
rm -rf "${BUILD_TMP_DIR}"

