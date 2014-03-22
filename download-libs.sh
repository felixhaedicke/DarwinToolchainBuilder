#!/bin/bash

svn export http://llvm.org/svn/llvm-project/libcxxabi/trunk@201497 libcxxabi-rev201497 || exit $?
tar czvf libcxxabi-rev201497.tar.gz libcxxabi-rev201497 || exit $?
rm -rf libcxxabi-rev201497 || exit $?

curl -L -O http://llvm.org/releases/3.4/libcxx-3.4.src.tar.gz || exit $?
curl -L -O http://download.savannah.gnu.org/releases/freetype/freetype-2.4.12.tar.gz || exit $?
curl -L -O http://sourceforge.net/projects/libjpeg-turbo/files/1.3.0/libjpeg-turbo-1.3.0.tar.gz || exit $?
curl -L -O http://libsdl.org/release/SDL2-2.0.3.tar.gz || exit $?
curl -L -O http://www.libsdl.org/projects/SDL_mixer/release/SDL2_mixer-2.0.0.tar.gz || exit $?
curl -L -O http://www.libsdl.org/projects/SDL_net/release/SDL2_net-2.0.0.tar.gz || exit $?
curl -L -O http://ftp.gnu.org/gnu/gettext/gettext-0.18.3.tar.gz || exit $?
curl -L -O http://sourceforge.net/projects/libpng/files/zlib/1.2.8/zlib-1.2.8.tar.gz || exit $?
curl -L -O http://downloads.sourceforge.net/project/libpng/libpng16/1.6.9/libpng-1.6.9.tar.gz || exit $?

