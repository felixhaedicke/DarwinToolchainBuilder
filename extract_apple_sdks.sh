#!/bin/bash

if [ "$1" = "" ]
then
  echo Scanning for SDKs...
  found_sdk=0
  for i in /Applications `mount | awk '{print $3;}'`
  do
    osx_sdks_dir=$i/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs;
    ios_sdks_dir=$i/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs;

    if [ -d $ios_sdks_dir ]
    then
      for j in ${osx_sdks_dir}/MacOSX*.sdk
      do
        echo Found Mac OS X SDK in $j
        found_sdk=1
      done
    fi

    if [ -d $ios_sdks_dir ]
    then
      for j in ${ios_sdks_dir}/iPhoneOS*.sdk
      do
        echo Found iOS SDK in $j
        found_sdk=1
      done
    fi
  done
  if [ $found_sdk -eq 0 ]
  then
    echo No iOS / Mac OS X SDK found! >&2
  else
    echo To extract an SDK, type
    echo "  $0 <SDK directory>"
  fi
else
  sdk_dir=$1
  if [ -d $sdk_dir ]
  then
    sdk_dir_basename=`basename $sdk_dir`
    is_ios_sdk=0
    if [[ ${sdk_dir_basename} == iPhoneOS* ]]
    then
      is_ios_sdk=1
    fi
    
    cp -R $sdk_dir . || exit $?
    
    libcxx_headers_src_dir=${sdk_dir}/../../../../../Toolchains/XcodeDefault.xctoolchain/usr/lib/c++/v1
    libarc_src_dir=${sdk_dir}/../../../../../Toolchains/XcodeDefault.xctoolchain/usr/lib/arc
    libarc_src_filepath=${libarc_src_dir}/libarclite_macosx.a
    if [ $is_ios_sdk -eq 1 ]
    then
      libarc_src_filepath=${libarc_src_dir}/libarclite_iphoneos.a
    fi
    
    if [ -d "${libcxx_headers_src_dir}" ]
    then
      libcxx_headers_target_dir="${sdk_dir_basename}/usr/include/c++/v1"
      if [ ! -d "${libcxx_target_dir}" ]
      then
        cp -R "${libcxx_headers_src_dir}" "${libcxx_headers_target_dir}" || exit $?
      fi
    fi

    if [ -f "${libarc_src_filepath}" ]
    then
      arc_target_dir="${sdk_dir_basename}/usr/lib/arc"
      if [ ! -d "${arc_target_dir}" ]
      then
        mkdir "${arc_target_dir}" || exit $?
      fi
      cp "${libarc_src_filepath}" "${arc_target_dir}" || exit $?
    fi

    tar czf $sdk_dir_basename.tar.gz $sdk_dir_basename
    rm -rf $sdk_dir_basename
  else
    echo SDK directory $sdk_dir does not exist! >&2
    exit 1;
  fi
fi

