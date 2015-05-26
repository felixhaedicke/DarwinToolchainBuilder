DarwinToolchainBuilder
======================

Scripts for creating a simple, lightweight Clang based toolchain for iOS and Mac OS X

Overview
--------
This tool set contains the following shell scripts:
* build-toolchain.sh: Builds a lighweight LLVM/Clang based toolchain. Does not build a new LLVM toolchain, but uses the tools which you already have on your system. Builds a few tools including the ld64 linker and creates a few required symlinks. This can be used on Linux and probably on other Unix-like operating systems. Not required for building on Mac OS X, of course.
* build-libs.sh: Builds a set of static libraries, for example SDL, libjpeg-turbo, libpng, freetype and libcurl. This script can be used on a system with a toolchain built with build-toolchain.sh and on Mac OS X using the tools included in Xcode.
* download-libs.sh: Download the library source tarballs for build-libs.sh.
* extract_apple_sdks.sh: Extract a Mac OS X / iOS SDK from an Xcode installation.

Just execute the scripts without any parameters to see a short parameter description. download-libs.sh is the only script which does not take a command line parameter.

Installation guide for Mac OS X users
-------------------------------------
Install Xcode 5.1

Install a recent NASM (required for building libjpeg-turbo for x86_64)

Clone this repository

Download the source tarballs by executing ./download-libs.sh

Execute the build-libs.sh script for the library sets you want to build, for example

    ./build-libs.sh $HOME/libs/i386-MacOSX-10.7-SDK10.10 i386-MacOSX-10.7-SDK10.10
    ./build-libs.sh $HOME/libs/x86_64-MacOSX-10.7-SDK10.10 x86_64-MacOSX-10.7-SDK10.10
    ./build-libs.sh $HOME/libs/armv7-iOS-5.1-SDK8.3 armv7-iOS-5.1-SDK8.3
    ./build-libs.sh $HOME/libs/arm64-iOS-7.0-SDK8.3 arm64-iOS-7.0-SDK8.3

This will build the library sets for iOS / armv7 and install them to $HOME/libs/armv7-iOS-5.1-SDK7.1, the Mac OS x86 libraries to $HOME/libs/i386-MacOSX-10.7-SDK10.9 and the Mac OS X x86_64 libraries to $HOME/libs/x86_64-MacOSX-10.7-SDK10.9

Installation guide for Debian / Ubuntu users
--------------------------------------------
Install required packages:

    apt-get install build-essential clang libclang-dev llvm llvm-dev nasm libc++-dev git autotools-dev autoconf automake libtool libssl-dev uuid-dev subversion

Clone this repository

Build the toolchain, for example to $HOME/darwin-toolchain:

    ./build-toolchain.sh $HOME/darwin-toolchain

Install the required SDKs (which can be extracted using extract_apple_sdks.sh) to the lib/SDKs subfolder

    mkdir -p $HOME/darwin-toolchain/lib/SDKs
    cd $HOME/darwin-toolchain/lib/SDKs
    tar xzvf iPhoneOS8.3.sdk.tar.gz
    tar xzvf MacOSX10.10.sdk.tar.gz

Download the source tarballs by executing ./download-libs.sh

Execute the build-libs.sh script for the library sets you want to build, for example

    ./build-libs.sh $HOME/darwin-toolchain i386-MacOSX-10.7-SDK10.10
    ./build-libs.sh $HOME/darwin-toolchain x86_64-MacOSX-10.7-SDK10.10
    ./build-libs.sh $HOME/darwin-toolchain armv7-iOS-5.1-SDK8.3
    ./build-libs.sh $HOME/darwin-toolchain arm64-iOS-7.0-SDK8.3

The libraries will be installed the libraries in $HOME/darwin-toolchain/lib/<target descriptors>

