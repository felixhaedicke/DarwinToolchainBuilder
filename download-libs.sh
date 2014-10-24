#!/bin/bash

. versions.inc

curl -L -O http://download.savannah.gnu.org/releases/freetype/freetype-${LIB_VERSION_FREETYPE}.tar.gz || exit $?
curl -L -O http://sourceforge.net/projects/libjpeg-turbo/files/${LIB_VERSION_LIBJPEG_TURBO}/libjpeg-turbo-${LIB_VERSION_LIBJPEG_TURBO}.tar.gz || exit $?
curl -L -O http://www.libsdl.org/release/SDL-${LIB_VERSION_SDL}.tar.gz || exit $?
curl -L -O http://libsdl.org/release/SDL2-${LIB_VERSION_SDL2}.tar.gz || exit $?
curl -L -O http://www.libsdl.org/projects/SDL_mixer/release/SDL2_mixer-${LIB_VERSION_SDL2_MIXER}.tar.gz || exit $?
curl -L -O http://www.libsdl.org/projects/SDL_net/release/SDL2_net-${LIB_VERSION_SDL2_NET}.tar.gz || exit $?
curl -L -O http://curl.haxx.se/download/curl-${LIB_VERSION_CURL}.tar.gz || exit $?
curl -L -O http://sourceforge.net/projects/libpng/files/libpng16/${LIB_VERSION_LIBPNG}/libpng-${LIB_VERSION_LIBPNG}.tar.gz || exit $?
curl -L -O http://sourceforge.net/projects/ogl-math/files/glm-${LIB_VERSION_GLM}/glm-${LIB_VERSION_GLM}.zip || exit $?

