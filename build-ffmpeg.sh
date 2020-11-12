#!/bin/sh

NDK_ROOT=/Users/patch/Work/android-ndk-r19c

ANDROID_API_VERSION=19
NDK_TOOLCHAIN_ABI_VERSION=4.9

ABIS="armeabi-v7a arm64-v8a x86 x86_64"

#路径定义
CWD=`pwd`
TOOLCHAINS=$CWD/"toolchains"
TOOLCHAINS_PREFIX="arm-linux-androideabi"
TOOLCHAINS_CLANG_PREFIX="arm-linux-androideabi"
TOOLCHAINS_PATH=${TOOLCHAINS}/bin
SYSROOT=${TOOLCHAINS}/sysroot
EXTERNAL_PATH=$CWD/"libs"

# directories
SOURCE="ffmpeg-4.3.1"
FAT="fat-ffmpeg"
SCRATCH="scratch-ffmpeg"

# must be an absolute path
THIN=$CWD/"thin-ffmpeg"

ARCH_PREFIX="armeabi-v7a"

#编译标志位定义
COMM_CFLAGS="${CFLAGS} --sysroot=${SYSROOT} -I${SYSROOT}/usr/include -I${TOOLCHAINS}/include"
COMM_CPPFLAGS="${COMM_CFLAGS}"
COMM_LDFLAGS="${LDFLAGS} -L${SYSROOT}/usr/lib -L${TOOLCHAINS}/lib"


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

    export CC=${TOOLCHAINS_PATH}/${TOOLCHAINS_CLANG_PREFIX}-clang
    export CXX=${TOOLCHAINS_PATH}/${TOOLCHAINS_CLANG_PREFIX}-clang++

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


# --enable-libx264
# --enable-libmp3lame
# --enable-libfdk-aac
            

function configure_make_install()
{

    echo "${TOOLCHAINS_PREFIX}"
    echo "${TOOLCHAINS_CLANG_PREFIX}"
    echo "${CFLAGS}"
    echo "${LDFLAGS}"

    cd "$CWD/$SOURCE"

    ./configure \
        --disable-stripping \
            --disable-ffmpeg \
            --disable-ffplay \
            --disable-ffprobe \
            --disable-debug \
            --disable-avdevice \
            --disable-devices \
            --disable-indevs \
            --disable-outdevs \
            --disable-asm \
            --disable-x86asm \
            --disable-doc \
            --disable-postproc \
            --enable-small \
            --enable-dct \
            --enable-dwt \
            --enable-lsp \
            --enable-mdct \
            --enable-rdft \
            --enable-fft \
            --enable-version3 \
            --enable-nonfree \
            --enable-gpl \
            --enable-static \
            --enable-cross-compile \
            --disable-bsfs \
            --enable-bsf=aac_adtstoasc \
            --enable-bsf=mp3_header_decompress \
            --enable-bsf=h264_mp4toannexb \
            --enable-bsf=h264_metadata \
            --disable-encoders \
            --enable-encoder=aac \
            --enable-encoder=flv \
            --enable-encoder=pcm_s16le \
            --enable-encoder=mpeg4 \
            --enable-encoder=gif \
            --disable-decoders \
            --enable-decoder=aac \
            --enable-decoder=h264 \
            --enable-decoder=mp3 \
            --enable-decoder=flv \
            --enable-decoder=gif \
            --enable-decoder=mpeg4 \
            --enable-decoder=pcm_s16le \
            --disable-parsers \
            --enable-parser=aac \
            --disable-muxers \
            --enable-muxer=flv \
            --enable-muxer=wav \
            --enable-muxer=adts \
            --enable-muxer=h264 \
            --enable-muxer=mp3 \
            --enable-muxer=mp4 \
            --disable-demuxers \
            --enable-demuxer=aac \
            --enable-demuxer=mp3 \
            --enable-demuxer=flv \
            --enable-demuxer=h264 \
            --enable-demuxer=wav \
            --enable-demuxer=gif \
            --disable-protocols \
            --enable-protocol=rtmp \
            --enable-protocol=file \
            --target-os=linux \
            --arch="${TOOLCHAINS_PREFIX}" \
            --cross-prefix="${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-"\
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
        ARCH_PREFIX=$ABI
        ANDROID_API_VERSION=19
        # CFLAGS="${COMM_CFLAGS} -I${EXTERNAL_PATH}/fdk-aac/armeabi/include -I${EXTERNAL_PATH}/lame/armeabi/include -I${EXTERNAL_PATH}/x264/armeabi/include"    
        # LDFLAGS="${COMM_LDFLAGS} -L${EXTERNAL_PATH}/fdk-aac/armeabi/lib -L${EXTERNAL_PATH}/lame/armeabi/lib -L${EXTERNAL_PATH}/x264/armeabi/lib"
        CFLAGS="${COMM_CFLAGS} -march=armv5 -mfloat-abi=softfp -mfpu=neon -D__ANDROID_API__=19"
        CPPFLAGS="${CFLAGS}"
        LDFLAGS="${COMM_LDFLAGS}"
        TOOLCHAINS_PREFIX=arm-linux-androideabi
        TOOLCHAINS_CLANG_PREFIX=arm-linux-androideabi
        make_standalone_toolchain arm android-$ANDROID_API_VERSION ${TOOLCHAINS}
        export_vars
        configure_make_install
    elif [ $ABI = "armeabi-v7a" ]
    then
        ARCH_PREFIX=$ABI
        ANDROID_API_VERSION=19
        # CFLAGS="${COMM_CFLAGS} -I${EXTERNAL_PATH}/fdk-aac/armeabi-v7a/include -I${EXTERNAL_PATH}/lame/armeabi-v7a/include -I${EXTERNAL_PATH}/x264/armeabi-v7a/include"   
        # LDFLAGS="${COMM_LDFLAGS} -L${EXTERNAL_PATH}/fdk-aac/armeabi-v7a/lib -L${EXTERNAL_PATH}/lame/armeabi-v7a/lib -L${EXTERNAL_PATH}/x264/armeabi-v7a/lib"
        CFLAGS="${COMM_CFLAGS} -march=armv7-a -mfloat-abi=softfp -mfpu=neon -D__ANDROID_API__=19"
        CPPFLAGS="${CFLAGS}"
        LDFLAGS="${COMM_LDFLAGS}"
        TOOLCHAINS_PREFIX=arm-linux-androideabi
        TOOLCHAINS_CLANG_PREFIX=armv7-linux-androideabi${ANDROID_API_VERSION}
        make_standalone_toolchain arm $ANDROID_API_VERSION ${TOOLCHAINS}
        export_vars
        configure_make_install
    elif [ $ABI = "arm64-v8a" ]
    then
        ARCH_PREFIX=$ABI
        ANDROID_API_VERSION=21
        # CFLAGS="${COMM_CFLAGS} -I${EXTERNAL_PATH}/fdk-aac/arm64-v8a/include -I${EXTERNAL_PATH}/lame/arm64-v8a/include -I${EXTERNAL_PATH}/x264/arm64-v8a/include"    
        # LDFLAGS="${COMM_LDFLAGS} -L${EXTERNAL_PATH}/fdk-aac/arm64-v8a/lib -L${EXTERNAL_PATH}/lame/arm64-v8a/lib -L${EXTERNAL_PATH}/x264/arm64-v8a/lib"
        CFLAGS="${COMM_CFLAGS} -march=armv8-a -D__ANDROID_API__=21"
        CPPFLAGS="${CFLAGS}"
        LDFLAGS="${COMM_LDFLAGS}"
        TOOLCHAINS_PREFIX=aarch64-linux-android
        TOOLCHAINS_CLANG_PREFIX=aarch64-linux-android${ANDROID_API_VERSION}
        make_standalone_toolchain arm64 $ANDROID_API_VERSION ${TOOLCHAINS}
        export_vars
        configure_make_install
    elif [ $ABI = "x86" ]
    then
        ARCH_PREFIX=$ABI
        ANDROID_API_VERSION=19
        # CFLAGS="${COMM_CFLAGS} -I${EXTERNAL_PATH}/fdk-aac/x86/include -I${EXTERNAL_PATH}/lame/x86/include -I${EXTERNAL_PATH}/x264/x86/include"  
        # LDFLAGS="${COMM_LDFLAGS} -L${EXTERNAL_PATH}/fdk-aac/x86/lib -L${EXTERNAL_PATH}/lame/x86/lib -L${EXTERNAL_PATH}/x264/x86/lib"
        CFLAGS="${COMM_CFLAGS} -D__ANDROID_API__=19"
        CPPFLAGS="${CFLAGS}"
        LDFLAGS="${COMM_LDFLAGS}"  
        TOOLCHAINS_PREFIX=i686-linux-android
        TOOLCHAINS_CLANG_PREFIX=i686-linux-android${ANDROID_API_VERSION}
        make_standalone_toolchain x86 $ANDROID_API_VERSION ${TOOLCHAINS}
        export_vars
        configure_make_install
    elif [ $ABI = "x86_64" ]
    then
        ARCH_PREFIX=$ABI
        ANDROID_API_VERSION=21
        # CFLAGS="${COMM_CFLAGS} -I${EXTERNAL_PATH}/fdk-aac/x86_64/include -I${EXTERNAL_PATH}/lame/x86_64/include -I${EXTERNAL_PATH}/x264/x86_64/include"  
        # LDFLAGS="${COMM_LDFLAGS} -L${EXTERNAL_PATH}/fdk-aac/x86_64/lib -L${EXTERNAL_PATH}/lame/x86_64/lib -L${EXTERNAL_PATH}/x264/x86_64/lib"
        # CPPFLAGS="${COMM_CFLAGS}"
        CFLAGS="${COMM_CFLAGS} -D__ANDROID_API__=21"
        CPPFLAGS="${CFLAGS}"
        LDFLAGS="${COMM_LDFLAGS}"
        TOOLCHAINS_PREFIX=x86_64-linux-android
        TOOLCHAINS_CLANG_PREFIX=x86_64-linux-android${ANDROID_API_VERSION}
        make_standalone_toolchain x86_64 $ANDROID_API_VERSION ${TOOLCHAINS}
        export_vars
        configure_make_install
    else
        echo $ABI
    fi

    cd $CWD

done


