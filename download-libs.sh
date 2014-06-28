#!/bin/bash

svn export http://llvm.org/svn/llvm-project/libcxxabi/trunk@201497 libcxxabi-rev201497 || exit $?
tar czvf libcxxabi-rev201497.tar.gz libcxxabi-rev201497 || exit $?
rm -rf libcxxabi-rev201497 || exit $?

curl -L -O http://llvm.org/releases/3.4.2/libcxx-3.4.2.src.tar.gz || exit $?
curl -L -O http://download.savannah.gnu.org/releases/freetype/freetype-2.4.12.tar.gz || exit $?
curl -L -O http://sourceforge.net/projects/libjpeg-turbo/files/1.3.1/libjpeg-turbo-1.3.1.tar.gz || exit $?
curl -L -O http://www.libsdl.org/release/SDL-1.2.15.tar.gz || exit $?
curl -L http://ftp.cc.uoc.gr/mirrors/macports/release/ports/devel/libsdl/files/no-CGDirectPaletteRef.patch > SDL-1.2.15_compile_fix.diff || exit $?
curl -L -O http://libsdl.org/release/SDL2-2.0.3.tar.gz || exit $?
curl -L -O http://www.libsdl.org/projects/SDL_mixer/release/SDL2_mixer-2.0.0.tar.gz || exit $?
curl -L -O http://www.libsdl.org/projects/SDL_net/release/SDL2_net-2.0.0.tar.gz || exit $?
curl -L -O http://ftp.gnu.org/gnu/gettext/gettext-0.19.1.tar.gz || exit $?
curl -L -O http://curl.haxx.se/download/curl-7.37.0.tar.gz || exit $?
curl -L -O http://sourceforge.net/projects/libpng/files/zlib/1.2.8/zlib-1.2.8.tar.gz || exit $?
curl -L -O http://sourceforge.net/projects/libpng/files/libpng16/1.6.12/libpng-1.6.12.tar.gz || exit $?
curl -L -O http://sourceforge.net/projects/ogl-math/files/glm-0.9.5.4/glm-0.9.5.4.zip || exit $?

