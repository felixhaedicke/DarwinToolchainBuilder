#!/bin/bash

svn export http://llvm.org/svn/llvm-project/libcxxabi/trunk@201497 libcxxabi-rev201497
tar czvf libcxxabi-rev201497.tar.gz libcxxabi-rev201497
rm -rf libcxxabi-rev201497

wget http://llvm.org/releases/3.4/libcxx-3.4.src.tar.gz
wget http://sourceforge.net/projects/libpng/files/libpng16/1.6.8/libpng-1.6.8.tar.gz
wget http://download.savannah.gnu.org/releases/freetype/freetype-2.4.12.tar.gz
wget http://ijg.org/files/jpegsrc.v9.tar.gz
wget http://libsdl.org/release/SDL2-2.0.2.tar.gz
wget http://www.libsdl.org/projects/SDL_mixer/release/SDL2_mixer-2.0.0.tar.gz
wget http://www.libsdl.org/projects/SDL_net/release/SDL2_net-2.0.0.tar.gz
wget http://www.libsdl.org/release/SDL-1.2.15.tar.gz
wget http://ftp.gnu.org/gnu/gettext/gettext-0.18.3.tar.gz
wget http://sourceforge.net/projects/libpng/files/zlib/1.2.8/zlib-1.2.8.tar.gz
wget http://downloads.sourceforge.net/project/libpng/libpng16/1.6.9/libpng-1.6.9.tar.gz

