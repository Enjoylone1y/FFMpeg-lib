# Automatically generated by configure - do not modify!
shared=
build_suffix=
prefix=/Users/patch/Work/ffmpeg/thin-ffmpeg/x86_64
libdir=${prefix}/lib
incdir=${prefix}/include
rpath=
source_path=.
LIBPREF=lib
LIBSUF=.a
extralibs_avutil="-pthread -lm"
extralibs_avcodec="-pthread -lm"
extralibs_avformat="-lm -lz"
extralibs_avdevice="-lm"
extralibs_avfilter="-pthread -lm"
extralibs_avresample="-lm"
extralibs_postproc="-lm"
extralibs_swscale="-lm"
extralibs_swresample="-lm"
avdevice_deps="avformat avcodec avutil"
avfilter_deps="swscale avformat avcodec swresample avutil"
swscale_deps="avutil"
postproc_deps="avutil"
avformat_deps="avcodec avutil"
avcodec_deps="avutil"
swresample_deps="avutil"
avresample_deps="avutil"
avutil_deps=""