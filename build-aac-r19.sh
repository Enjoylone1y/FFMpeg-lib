#!/bin/sh
NDK_ROOT=/Users/patch/Work/android-ndk-r19c

#default Android abi version
ANDROID_API_VERSION=19

ABIS="armeabi-v7a arm64-v8a x86 x86_64"

CWD=`pwd`

TOOLCHAINS=$NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64
TOOLCHAINS_PATH=$TOOLCHAINS/bin
SYSROOT=$TOOLCHAINS/sysroot


TOOLCHAINS_PREFIX="arm-linux-androideabi"
CLANG_PREFIX="armv7a-linux-androideabi"


CFLAGS="${CFLAGS} --sysroot=${SYSROOT} -I${SYSROOT}/usr/include -O2"
CPPFLAGS="${CFLAGS}"
LDFLAGS="${LDFLAGS} -L${SYSROOT}/usr/lib"

#build directory
SOURCE="fdk-aac"
FAT="fat-aac"
SCRATCH="scrath-aac"

#libs path,must absolute path
THIN=$CWD/libs/fdk-aac

ARCH_PREFIX="armeabi"


function export_vars()
{
    export TOOLCHAINS
    export TOOLCHAINS_PREFIX
    export TOOLCHAINS_PATH
    export SYSROOT
    
    # export CPP=${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-cpp
    export CC=${TOOLCHAINS_PATH}/${CLANG_PREFIX}${ANDROID_API_VERSION}-clang
    export CXX=-${TOOLCHAINS_PATH}/${CLANG_PREFIX}${ANDROID_API_VERSION}-clang++
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
    # export GCOV=${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-gcov
    # export GDB=${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-gdb
    export GPROF=${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-gprof
    
    # Don't mix up .pc files from your host and build target
    export PKG_CONFIG_PATH=${TOOLCHAINS}/lib/pkgconfig
    
    export CFLAGS
    export CPPFLAGS
    export LDFLAGS
}


function configure_make_install()
{
    cd "$CWD/$SOURCE"

    ./configure \
	    --enable-static \
        --enable-shared \
        --disable-frontend \
        --with-sysroot=$SYSROOT \
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
        CFLAGS="${CFLAGS} -mfloat-abi=softfp -mfpu=neon -D__ANDROID_API__=$ANDROID_API_VERSION"
        TOOLCHAINS_PREFIX="arm-linux-androideabi"
	    CLANG_PREFIX="armv7a-linux-androideabi"
        ARCH_PREFIX=$ABI
        export_vars
        configure_make_install
    elif [ $ABI = "armeabi-v7a" ]
    then
        CFLAGS="${CFLAGS} -mfloat-abi=softfp -mfpu=neon -D__ANDROID_API__=$ANDROID_API_VERSION"
        ARCH_PREFIX=$ABI
	    TOOLCHAINS_PREFIX="arm-linux-androideabi"
	    CLANG_PREFIX="armv7a-linux-androideabi"
        export_vars
        configure_make_install
    elif [ $ABI = "arm64-v8a" ]
    then
        ANDROID_API_VERSION=21
        CFLAGS="${CFLAGS} -D__ANDROID_API__=$ANDROID_API_VERSION"
        ARCH_PREFIX=$ABI
	    TOOLCHAINS_PREFIX="aarch64-linux-android"
	    CLANG_PREFIX="aarch64-linux-android"
        export_vars
        configure_make_install
    elif [ $ABI = "x86" ]
    then
        CFLAGS="${CFLAGS} -D__ANDROID_API__=$ANDROID_API_VERSION"
        ARCH_PREFIX=$ABI
	    TOOLCHAINS_PREFIX="i686-linux-android"
	    CLANG_PREFIX="i686-linux-android"
        export_vars
        configure_make_install
    elif [ $ABI = "x86_64" ]
    then
        ANDROID_API_VERSION=21
        CFLAGS="${CFLAGS} -D__ANDROID_API__=$ANDROID_API_VERSION"
       	TOOLCHAINS_PREFIX="x86_64-linux-android"
	    CLANG_PREFIX="x86_64-linux-android"
	    ARCH_PREFIX=$ABI
        export_vars
        configure_make_install
    else
        echo $ABI
    fi

    cd $CWD

done


