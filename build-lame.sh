#!/bin/sh

NDK_ROOT=/Users/patch/Library/Android/android-ndk-r16b

ANDROID_API_VERSION=19
NDK_TOOLCHAIN_ABI_VERSION=4.9

ABIS="armeabi-v7a arm64-v8a x86 x86_64"

CWD=`pwd`

TOOLCHAINS=$CWD/"toolchains"
TOOLCHAINS_PREFIX="arm-linux-androideabi"
TOOLCHAINS_PATH=${TOOLCHAINS}/bin
SYSROOT=${TOOLCHAINS}/sysroot

CFLAGS="${CFLAGS} --sysroot=${SYSROOT} -I${SYSROOT}/usr/include -I${TOOLCHAINS}/include"
CPPFLAGS="${CFLAGS}"
LDFLAGS="${LDFLAGS} -L${SYSROOT}/usr/lib -L${TOOLCHAINS}/lib"


# directories
SOURCE="lame-3.99.5"
FAT="fat-lame"
SCRATCH="scratch-lame"

# must be an absolute path
THIN=$CWD/"libs/lame"

ARCH_PREFIX="armeabi-v7a"

function make_standalone_toolchain()
{
  echo "make standalone toolchain --arch=$1 --platform=$2 --install-dir=$3"
  rm -rf ${TOOLCHAINS}

  sh $NDK_ROOT/build/tools/make-standalone-toolchain.sh \
  --arch=$1 \
  --platform=$2 \
  --install-dir=$3
}

function export_vars()
{
    export TOOLCHAINS
    export TOOLCHAINS_PREFIX
    export TOOLCHAINS_PATH
    export SYSROOT

    export CC=${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-gcc
    export CXX=${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-g++

    export CPP=${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-cpp
    export AR=${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-ar
    export AS=${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-as
    export NM=${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-nm
    export LD=${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-ld
    export RANLIB=${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-ranlib
    export STRIP=${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-strip
    export OBJDUMP=${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-objdump
    export OBJCOPY=${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-objcopy
    export ADDR2LINE=${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-addr2line
    export READELF=${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-readelf
    export SIZE=${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-size
    export STRINGS=${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-strings
    export ELFEDIT=${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-elfedit
    export GCOV=${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-gcov
    export GDB=${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-gdb
    export GPROF=${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-gprof
    
    # Don't mix up .pc files from your host and build target
    export PKG_CONFIG_PATH=${TOOLCHAINS}/lib/pkgconfig
    
    export CFLAGS
    export CPPFLAGS
    export LDFLAGS
}

function configure_make_install()
{

    echo "${TOOLCHAINS_PREFIX}"
    echo "${TOOLCHAINS_CLANG_PREFIX}"
    echo "${CFLAGS}"
    echo "${LDFLAGS}"

    cd "$CWD/$SOURCE"
    ./configure \
	    --enable-static \
        --disable-shared \
        --disable-frontend \
        --host=$TOOLCHAINS_PREFIX \
	    --prefix="$THIN/$ARCH_PREFIX"
        
    make clean
    make -j8 
    make install
}
for ABI in $ABIS
do
    echo "building $ABI..."
    mkdir -p "$SCRATCH/$ABI"
    cd "$SCRATCH/$ABI"

    if [ $ABI = "armeabi" ]
    then
        ANDROID_API_VERSION=19
        ARCH_PREFIX=$ABI
        TOOLCHAINS_PREFIX=arm-linux-androideabi
        make_standalone_toolchain arm android-$ANDROID_API_VERSION ${TOOLCHAINS}
        export_vars
        configure_make_install
    elif [ $ABI = "armeabi-v7a" ]
    then
        ANDROID_API_VERSION=19
        ARCH_PREFIX=$ABI
        TOOLCHAINS_PREFIX=arm-linux-androideabi
        make_standalone_toolchain arm $ANDROID_API_VERSION ${TOOLCHAINS}
        export_vars
        configure_make_install
    elif [ $ABI = "arm64-v8a" ]
    then
        ANDROID_API_VERSION=21
        ARCH_PREFIX=$ABI
        TOOLCHAINS_PREFIX=aarch64-linux-android
        make_standalone_toolchain arm64 $ANDROID_API_VERSION ${TOOLCHAINS}
        export_vars
        configure_make_install
    elif [ $ABI = "x86" ]
    then
        ANDROID_API_VERSION=19
        ARCH_PREFIX=$ABI
        TOOLCHAINS_PREFIX=i686-linux-android
        make_standalone_toolchain x86 $ANDROID_API_VERSION ${TOOLCHAINS}
        export_vars
        configure_make_install
    elif [ $ABI = "x86_64" ]
    then
        ANDROID_API_VERSION=21
        ARCH_PREFIX=$ABI
        TOOLCHAINS_PREFIX=x86_64-linux-android
        make_standalone_toolchain x86_64 $ANDROID_API_VERSION ${TOOLCHAINS}
        export_vars
        configure_make_install
    else
        echo $ABI
    fi

    cd $CWD

done


