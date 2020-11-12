#!/bin/sh

NDK_ROOT=/Users/patch/Work/android-ndk-r16b

ANDROID_API_VERSION=19
NDK_TOOLCHAIN_ABI_VERSION=4.9

ABIS="armeabi-v7a arm64-v8a"

#路径定义
CWD=`pwd`
TOOLCHAINS=$CWD/"toolchains"
TOOLCHAINS_PREFIX="arm-linux-androideabi"
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
COMM_CFLAGS="${CFLAGS} --sysroot=${SYSROOT} -I${SYSROOT}/usr/include -I${TOOLCHAINS}/include -DANDROID -fPIC -O3"

LDFLAGS="${LDFLAGS} -L${SYSROOT}/usr/lib -L${TOOLCHAINS}/lib"

#X264
X264_INCLUDE=$EXTERNAL_PATH/x264/armeabi-v7a/include
X264_LIB=$EXTERNAL_PATH/x264/armeabi-v7a/lib
#FDK-AAC
FDK_INCLUDE=$EXTERNAL_PATH/fdk-aac/armeabi-v7a/include
FDK_LIB=$EXTERNAL_PATH/fdk-aac/armeabi-v7a/lib
#libmp3lame
LAME_INCLUDE=$EXTERNAL_PATH/lame/armeabi-v7a/include
LAME_LIB=$EXTERNAL_PATH/lame/armeabi-v7a/lib

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

    export CC=${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-clang
    export CXX=${TOOLCHAINS_PATH}/${TOOLCHAINS_PREFIX}-clang++

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
    echo "${FDK_INCLUDE}"
    echo "${FDK_LIB}"
    

    $CWD/$SOURCE/configure \
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
            --enable-jni \
            --enable-static \
            --enable-cross-compile \
            --disable-bsfs \
            --enable-bsf=aac_adtstoasc \
            --enable-bsf=mp3_header_decompress \
            --enable-bsf=h264_mp4toannexb \
            --enable-bsf=h264_metadata \
            --disable-encoders \
            --enable-encoder=flv \
            --enable-encoder=pcm_s16le \
            --enable-encoder=libx264 \
            --enable-encoder=libfdk_aac \
            --enable-encoder=aac \
            --enable-encoder=libmp3lame \
            --enable-encoder=mjpeg \
            --enable-encoder=mpeg4 \
            --enable-encoder=rawvideo \
            --enable-encoder=png \
            --enable-encoder=gif \
            --disable-decoders \
            --enable-decoder=rawvideo \
            --enable-decoder=mjpeg \
            --enable-decoder=mpeg4 \
            --enable-decoder=h264 \
            --enable-decoder=aac \
            --enable-decoder=mp3 \
            --enable-decoder=aac_latm \
            --enable-decoder=gif \
            --enable-decoder=png \
            --enable-decoder=pcm_f16le \
            --enable-decoder=pcm_f24le \
            --enable-decoder=pcm_f32be \
            --enable-decoder=pcm_f32le \
            --enable-decoder=pcm_f64be \
            --enable-decoder=pcm_f64le \
            --enable-decoder=libfdk_aac \
            --disable-parsers \
            --enable-parser=aac \
            --enable-parser=h264 \
            --enable-parser=mpeg4video \
            --enable-parser=mjpeg \
            --enable-parser=ac3 \
            --enable-parser=png \
            --enable-parser=mpegaudio \
            --disable-filters \
            --enable-filter=aresample \
            --enable-filter=asetpts \
            --enable-filter=setpts \
            --enable-filter=ass \
            --enable-filter=scale \
            --enable-filter=concat \
            --enable-filter=atempo \
            --enable-filter=movie \
            --enable-filter=overlay \
            --enable-filter=rotate \
            --enable-filter=transpose \
            --enable-filter=hflip \
            --enable-filter=amix \
            --enable-filter=fade \
            --enable-filter=afade \
            --enable-filter=areverse \
            --enable-filter=volume \
            --enable-filter=aevalsrc \
            --enable-filter=adelay \
            --disable-muxers \
            --enable-muxer=mov \
            --enable-muxer=mp4 \
            --enable-muxer=mp3 \
            --enable-muxer=h264 \
            --enable-muxer=mpjpeg \
            --enable-muxer=rawvideo \
            --enable-muxer=wav \
            --enable-muxer=mpegts \
            --enable-muxer=dts \
            --enable-muxer=gif \
            --enable-muxer=flv \
            --disable-demuxers \
            --enable-demuxer=mov \
            --enable-demuxer=h264 \
            --enable-demuxer=aac \
            --enable-demuxer=mp3 \
            --enable-demuxer=rawvideo \
            --enable-demuxer=avi \
            --enable-demuxer=wav \
            --enable-demuxer=flv \
            --enable-demuxer=gif \
            --enable-demuxer=ogg \
            --enable-demuxer=dts \
            --enable-demuxer=m4v \
            --enable-demuxer=concat \
            --enable-demuxer=mpegts \
            --enable-demuxer=mjpeg \
            --disable-protocols \
            --enable-protocol=rtmp \
            --enable-protocol=file \
            --enable-libx264 \
            --enable-libfdk-aac \
            --enable-libmp3lame \
            --target-os=android \
            --sysroot="$SYSROOT" \
            --extra-cflags="$CFLAGS -I$LAME_INCLUDE -I$FDK_INCLUDE -I$X264_INCLUDE" \
            --extra-ldflags="$LDFLAGS -L$LAME_LIB -L$FDK_LIB -L$X264_LIB" \
            --arch="$TOOLCHAINS_PREFIX" \
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
        CFLAGS="${COMM_CFLAGS} -march=armv5 -mfloat-abi=softfp -mfpu=neon -D__ANDROID_API__=19"
        TOOLCHAINS_PREFIX=arm-linux-androideabi
        TOOLCHAINS_CLANG_PREFIX=arm-linux-androideabi
        X264_INCLUDE=$EXTERNAL_PATH/x264/$ARCH_PREFIX/include
        X264_LIB=$EXTERNAL_PATH/x264/$ARCH_PREFIX/lib
        FDK_INCLUDE=$EXTERNAL_PATH/fdk-aac/$ARCH_PREFIX/include
        FDK_LIB=$EXTERNAL_PATH/fdk-aac/$ARCH_PREFIX/lib
        LAME_INCLUDE=$EXTERNAL_PATH/lame/$ARCH_PREFIX/include
        LAME_LIB=$EXTERNAL_PATH/lame/$ARCH_PREFIX/lib
        make_standalone_toolchain arm $ANDROID_API_VERSION ${TOOLCHAINS}
        export_vars
        configure_make_install
    elif [ $ABI = "armeabi-v7a" ]
    then
        ARCH_PREFIX=$ABI
        ANDROID_API_VERSION=19
        CFLAGS="${COMM_CFLAGS} -march=armv7-a -mfloat-abi=softfp -mfpu=neon -D__ANDROID_API__=19"
        TOOLCHAINS_PREFIX=arm-linux-androideabi
        X264_INCLUDE=$EXTERNAL_PATH/x264/$ARCH_PREFIX/include
        X264_LIB=$EXTERNAL_PATH/x264/$ARCH_PREFIX/lib
        FDK_INCLUDE=$EXTERNAL_PATH/fdk-aac/$ARCH_PREFIX/include
        FDK_LIB=$EXTERNAL_PATH/fdk-aac/$ARCH_PREFIX/lib
        LAME_INCLUDE=$EXTERNAL_PATH/lame/$ARCH_PREFIX/include
        LAME_LIB=$EXTERNAL_PATH/lame/$ARCH_PREFIX/lib
        make_standalone_toolchain arm $ANDROID_API_VERSION ${TOOLCHAINS}
        export_vars
        configure_make_install
    elif [ $ABI = "arm64-v8a" ]
    then
        ARCH_PREFIX=$ABI
        ANDROID_API_VERSION=21
        CFLAGS="${COMM_CFLAGS} -march=armv8-a -D__ANDROID_API__=21"
        TOOLCHAINS_PREFIX=aarch64-linux-android
        X264_INCLUDE=$EXTERNAL_PATH/x264/$ARCH_PREFIX/include
        X264_LIB=$EXTERNAL_PATH/x264/$ARCH_PREFIX/lib
        FDK_INCLUDE=$EXTERNAL_PATH/fdk-aac/$ARCH_PREFIX/include
        FDK_LIB=$EXTERNAL_PATH/fdk-aac/$ARCH_PREFIX/lib
        LAME_INCLUDE=$EXTERNAL_PATH/lame/$ARCH_PREFIX/include
        LAME_LIB=$EXTERNAL_PATH/lame/$ARCH_PREFIX/lib
        make_standalone_toolchain arm64 $ANDROID_API_VERSION ${TOOLCHAINS}
        export_vars
        configure_make_install
    elif [ $ABI = "x86" ]
    then
        ARCH_PREFIX=$ABI
        ANDROID_API_VERSION=19
        CFLAGS="${COMM_CFLAGS} -D__ANDROID_API__=19"
        CPPFLAGS="${CFLAGS}"
        TOOLCHAINS_PREFIX=i686-linux-android
        X264_INCLUDE=$EXTERNAL_PATH/x264/$ARCH_PREFIX/include
        X264_LIB=$EXTERNAL_PATH/x264/$ARCH_PREFIX/lib
        FDK_INCLUDE=$EXTERNAL_PATH/fdk-aac/$ARCH_PREFIX/include
        FDK_LIB=$EXTERNAL_PATH/fdk-aac/$ARCH_PREFIX/lib
        LAME_INCLUDE=$EXTERNAL_PATH/lame/$ARCH_PREFIX/include
        LAME_LIB=$EXTERNAL_PATH/lame/$ARCH_PREFIX/lib
        make_standalone_toolchain x86 $ANDROID_API_VERSION ${TOOLCHAINS}
        export_vars
        configure_make_install
    elif [ $ABI = "x86_64" ]
    then
        ARCH_PREFIX=$ABI
        ANDROID_API_VERSION=21
        CFLAGS="${COMM_CFLAGS} -D__ANDROID_API__=21"
        TOOLCHAINS_PREFIX=x86_64-linux-android
        X264_INCLUDE=$EXTERNAL_PATH/x264/$ARCH_PREFIX/include
        X264_LIB=$EXTERNAL_PATH/x264/$ARCH_PREFIX/lib
        FDK_INCLUDE=$EXTERNAL_PATH/fdk-aac/$ARCH_PREFIX/include
        FDK_LIB=$EXTERNAL_PATH/fdk-aac/$ARCH_PREFIX/lib
        LAME_INCLUDE=$EXTERNAL_PATH/lame/$ARCH_PREFIX/include
        LAME_LIB=$EXTERNAL_PATH/lame/$ARCH_PREFIX/lib
        make_standalone_toolchain x86_64 $ANDROID_API_VERSION ${TOOLCHAINS}
        export_vars
        configure_make_install
    else
        echo $ABI
    fi

    cd $CWD

done


