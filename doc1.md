最近在学习FFMPEG。在学习利用 FFMPEG Api 解复用媒体文件导出原始音视频数据，找相关学习资料的时候，发现完整的介绍 demuxing 整个流程的文章比较少，绝大部分都是只介绍了流程中的部分Api的使用，有些还是用的比较老版本的Api。最后，还是到官方比较给力，有完整例子提供参考，利用自己有限知识，参考官方API，学习理解了一番，在此做一下记录。话不多说，开始~~

####头文件引入

```
#include "stdio.h"
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libavutil/imgutils.h>
#include <libavutil/samplefmt.h>
#include <libavutil/timestamp.h>
```

####变量定义

```
// 格式上下文
static AVFormatContext *fmt_ctx = NULL;
// 解码器上下文
static AVCodecContext *video_dec_ctx = NULL, *audio_dec_ctx;
// 视频宽高
static int width, height;
// 视频帧格式
static enum AVPixelFormat pix_fmt;
// 视频流/音频流
static AVStream *video_stream = NULL, *audio_stream = NULL;
// 输入输出文件相关
static const char *src_filename = NULL;
static const char *video_dst_filename = NULL;
static const char *audio_dst_filename = NULL;
static FILE *video_dst_file = NULL;
static FILE *audio_dst_file = NULL;

// 用于保存视频图像数据的相关字段，其中:

// 保存图像通道的地址。如果是RGB，则前三个指针分别指向R,G,B的内存地址。第四个指针保留不用
static uint8_t *video_dst_data[4] = {NULL};
// 保存图像每个通道的内存对齐的步长，即一行的对齐内存的宽度，此值大小等于图像宽度。
static int      video_dst_linesize[4];
// 图像大小
static int video_dst_bufsize;

// 视频流音频流索引
static int video_stream_idx = -1, audio_stream_idx = -1;

// 音视频包
static AVFrame *frame = NULL;
static AVPacket pkt;

static int video_frame_count = 0;
static int audio_frame_count = 0;
```

####主要流程1-检测输入合法性


```
int ret = 0;
if (argc != 4) {
    fprintf(stderr, "usage: %s  input_file video_output_file audio_output_file……\n");
    exit(1);
}
src_filename = argv[1];
video_dst_filename = argv[2];
audio_dst_filename = argv[3];

/* open input file, and allocate format context */
if (avformat_open_input(&fmt_ctx, src_filename, NULL, NULL) < 0) {
    fprintf(stderr, "Could not open source file %s\n", src_filename);
    exit(1);
}

/* retrieve stream information */
if (avformat_find_stream_info(fmt_ctx, NULL) < 0) {
    fprintf(stderr, "Could not find stream information\n");
    exit(1);
}
```

首先要判断输入参数，本程序是输入一个媒体文件，输出一个.h264 的裸视频文件和.aac的音频文件，执行方式应该是:

```
./demuxing simple.mp4 simple.h264 simple.aac
```

因此 argc<4 就不符合规范，直接提示，退出即可。在参数合法的情况下，分别保存输入文件和输出文件的路径地址。 通过 *avformat_open_input* 打开对媒体文件获得 AVFormatContext 对象，媒体文件的所有流信息都会保存在其中。打开成功，则通过 *avformat_find_stream_info* 检查输入的文件是否包含合法的音视频流。

相关Api介绍:

```
    int avformat_open_input(AVFormatContext **ps, const char *url,AVInputFormat *fmt, AVDictionary **options)
```
参数：
- 用于接收 AVFormatContext 的指针对象
- 输入流URL（文件路径/链接地址）
- 指定输入流格式
- 可选，如果非空则会填充 AVFormatContext 的参数


```
int avformat_find_stream_info(AVFormatContext *ic, AVDictionary **options)
```
参数：
- AVFormatContext
- 如果为非NULL，则是指向字典的ic.nb_streams长指针数组，其中第i个成员包含对应于第i个流的编解码器选项。 返回时，每个字典将填充未找到的选项。


####主要流程2-打开音视频解码器，记录流索引

```
// 视频流
if (open_codec_context(&video_stream_idx, &video_dec_ctx, fmt_ctx, AVMEDIA_TYPE_VIDEO) >= 0) {
    video_stream = fmt_ctx->streams[video_stream_idx];

    video_dst_file = fopen(video_dst_filename, "wb");
    if (!video_dst_file) {
        fprintf(stderr, "Could not open destination file %s\n", video_dst_filename);
        ret = 1;
        goto end;
    }

    width = video_dec_ctx->width;
    height = video_dec_ctx->height;
    pix_fmt = video_dec_ctx->pix_fmt;
    ret = av_image_alloc(video_dst_data, video_dst_linesize,
                         width, height, pix_fmt, 1);
    if (ret < 0) {
        fprintf(stderr, "Could not allocate raw video buffer\n");
        goto end;
    }
    video_dst_bufsize = ret;
}

// 音频流
if (open_codec_context(&audio_stream_idx, &audio_dec_ctx, fmt_ctx, AVMEDIA_TYPE_AUDIO) >= 0) {
    audio_stream = fmt_ctx->streams[audio_stream_idx];
    audio_dst_file = fopen(audio_dst_filename, "wb");
    if (!audio_dst_file) {
        fprintf(stderr, "Could not open destination file %s\n", audio_dst_filename);
        ret = 1;
        goto end;
    }
}
```

打开响应的音视频流解码器成功后，通过系统文件Api *fopen* 打开输出文件获取文件句柄，用于后续把音视频包写入输出文件。而对于视频流，在获取到解码器后，可以通过解码器获取视频帧的width、height、pixelFormat，从而通过 *av_image_alloc* 计算和分配视频帧的大小。

相关Api介绍：

```
av_image_alloc(uint8_t *pointers[4], int linesizes[4],int w, int h, enum AVPixelFormat pix_fmt, int align)
```
参数：
- 保存图像通道的地址。如果是RGB，则前三个指针分别指向R,G,B的内存地址。第四个指针保留不用
- 保存图像每个通道的内存对齐的步长，即一行的对齐内存的宽度，此值大小等于图像宽度
- 视频帧宽度
- 视频帧高度
- 视频帧像素格式
- 用于内存对齐的值



*open_codec_context* 是我们封装的函数:

```
static int open_codec_context(int *stream_idx,
                              AVCodecContext **dec_ctx, AVFormatContext *fmt_ctx, enum AVMediaType type)
{
    int ret, stream_index;
    AVStream *st;
    AVCodec *dec = NULL;
    AVDictionary *opts = NULL;

    ret = av_find_best_stream(fmt_ctx, type, -1, -1, NULL, 0);
    if (ret < 0) {
        fprintf(stderr, "Could not find %s stream in input file '%s'\n",
                av_get_media_type_string(type), src_filename);
        return ret;
    } else {
        stream_index = ret;
        st = fmt_ctx->streams[stream_index];

        /* find decoder for the stream */
        dec = avcodec_find_decoder(st->codecpar->codec_id);
        if (!dec) {
            fprintf(stderr, "Failed to find %s codec\n",
                    av_get_media_type_string(type));
            return AVERROR(EINVAL);
        }

        /* Allocate a codec context for the decoder */
        *dec_ctx = avcodec_alloc_context3(dec);
        if (!*dec_ctx) {
            fprintf(stderr, "Failed to allocate the %s codec context\n",
                    av_get_media_type_string(type));
            return AVERROR(ENOMEM);
        }

        /* Copy codec parameters from input stream to output codec context */
        if ((ret = avcodec_parameters_to_context(*dec_ctx, st->codecpar)) < 0) {
            fprintf(stderr, "Failed to copy %s codec parameters to decoder context\n",
                    av_get_media_type_string(type));
            return ret;
        }

        /* Init the decoders */
        if ((ret = avcodec_open2(*dec_ctx, dec, &opts)) < 0) {
            fprintf(stderr, "Failed to open %s codec\n",
                    av_get_media_type_string(type));
            return ret;
        }
        
        *stream_idx = stream_index;
    }

    return 0;
}
```

函数内部流程其实也比较清晰：
1. 通过 *av_find_best_stream* 从 FormatContext 中寻找对应流 AVStream ，该对象的 codecpar->codec_id 记录流所使用的编解码器ID；
2. 通过 *avcodec_find_decoder* 在FFMPeg中寻找对应的解码器；
3. 通过 *avcodec_alloc_context3* 初始化解码器上下文AVCodecContext；
4. 通过 *avcodec_parameters_to_context* 拷贝解码器参数；
5. 通过 *avcodec_open2* 打开解码器即可。


相关Api介绍:

```
av_find_best_stream (AVFormatContext *ic,enum AVMediaType type,int wanted_stream_nb,
int  related_stream,
AVCodec **decoder_ret,
int flags 
)   
```
参数：
- 上下文 AVFormatContext
- 想要找的流的媒体类型，eg. AVMEDIA_TYPE_VIDEO / AVMEDIA_TYPE_AUDIO
- 指定流的索引，如果传-1，则由函数自动搜索对应类型的流
- 相关的流ID。比如我已知一个流索引，且希望函数返回的流是和我已知的这路流相关的，那就要已知流的索引传入
- 接收编解码器指针对象，用于直接获取流的编解码器（如果找到流的话）
- flags，一般传0即可。



####主要流程3-遍历输入流Packet

```
frame = av_frame_alloc();
if (!frame) {
    fprintf(stderr, "Could not allocate frame\n");
    ret = AVERROR(ENOMEM);
    goto end;
}

/* initialize packet, set data to NULL, let the demuxer fill it */
av_init_packet(&pkt);
pkt.data = NULL;
pkt.size = 0;

/* read frames from the file */
while (av_read_frame(fmt_ctx, &pkt) >= 0) {
    // check if the packet belongs to a stream we are interested in, otherwise skip it
    if (pkt.stream_index == video_stream_idx)
        ret = decode_packet(video_dec_ctx, &pkt);
    else if (pkt.stream_index == audio_stream_idx)
        ret = decode_packet(audio_dec_ctx, &pkt);

    av_packet_unref(&pkt);
    if (ret < 0)
        break;
}

/* flush the decoders */
if (video_dec_ctx)
    decode_packet(video_dec_ctx, NULL);
if (audio_dec_ctx)
    decode_packet(audio_dec_ctx, NULL);
```

首先初始化一个 AVFrame 和 AVPacket 用于后续解析过程保存音视频帧和Packet。通过 while 循环从 formatContext 中遍历读取每一个 Packet。一般来说，一个媒体文件中，可能会包含一路视频流，多路音频流，多路字幕流。而我们是对整个文件进行读取，所以读取到的 Packet 可能是视频，也可能是音频或者是字幕的包。前面我们打开编解码的时候分别记录我们关心的音频和视频流索引，通过判断包体的索引就可以做对应的包解析。
注意每一个Packet在使用完毕后，要使用 *av_packet_unref* 解除引用从而让系统可以在合适的时期释放掉避免内存泄漏。
另外要说明的是，读取packet函数是 *av_read_frame* 其实是历史遗留问题。


*decode_packet* 是我们封装的函数：

```
static int decode_packet(AVCodecContext *dec, const AVPacket *pkt)
{
    int ret = 0;

    // submit the packet to the decoder
    ret = avcodec_send_packet(dec, pkt);
    if (ret < 0) {
        fprintf(stderr, "Error submitting a packet for decoding (%s)\n", av_err2str(ret));
        return ret;
    }

    // get all the available frames from the decoder
    while (ret >= 0) {
        ret = avcodec_receive_frame(dec, frame);
        if (ret < 0) {
            // those two return values are special and mean there is no output
            // frame available, but there were no errors during decoding
            if (ret == AVERROR_EOF || ret == AVERROR(EAGAIN))
                return 0;

            fprintf(stderr, "Error during decoding (%s)\n", av_err2str(ret));
            return ret;
        }

        // write the frame data to output file
        if (dec->codec->type == AVMEDIA_TYPE_VIDEO)
            ret = output_video_frame(frame);
        else
            ret = output_audio_frame(frame);

        av_frame_unref(frame);
        if (ret < 0)
            return ret;
    }

    return 0;
}
```

函数的流程其实也和很简单，对于传入的每一个 AVPacket，调用 *avcodec_send_packet* 将其发给解码器解码，然后调用 *avcodec_receive_frame* 从解码器接收解码后的AVFrame，再根据帧的类型（Video/Audio）分别调用 *output_video_frame* 和 *output_audio_frame* 处理即可。和AVPacket同理，对于没有AVFrame，我们在处理完成后，需要使用 *av_frame_unref* 解除引用让系统自行判断和销毁。
从函数流程不难看出，一个AVPacket中，特别是低于音频的Packet来说，其实是可能包含多个AVFrame的，因此我们这里执行一次 *avcodec_send_packet* 后接的是由一个while循环引导的多次调用 *avcodec_receive_frame* 的过程。并且可以看到的是，*avcodec_receive_frame* 有很多种返回值，具体我们待会看Api介绍部分会说到。


相关Api介绍:

```
int avcodec_send_packet (AVCodecContext *avctx,const AVPacket * avpkt)   
```

参数：
- 解码器上下文
- 输入AVPacket。 通常，这将是单个视频帧或几个完整的音频帧。与旧版API不同，此数据包始终被完全消耗，并且如果它包含多个帧（例如某些音频编解码器），将要求您此后多次调用 *avcodec_receive_frame()* 取出所有帧后才能发送新数据包。该参数可以传NULL，(或者 data=NULL且size = 0的AVPacket) 在这种情况下，它被视为刷新数据包，它指示流的结束。 发送第一个刷新数据包将返回成功。 随后都返回AVERROR_EOF。


```
int avcodec_receive_frame(AVCodecContext *avctx, AVFrame *frame)
```

参数：
- 解码器上下文
- 输出AVFrame。

返回值：0：成功，返回了帧。
AVERROR（EAGAIN）：在此状态下输出不可用--用户必须尝试发送新的输入。
AVERROR_EOF：解码器已被完全刷新，并且将不再有输出帧
AVERROR（EINVAL）： 编解码器未打开，或者是编码器
其他负值：合法的解码错误



####主要流程4-处理和保存解码后的音视频帧


```
static int output_video_frame(AVFrame *frame)
{
    if (frame->width != width || frame->height != height ||
        frame->format != pix_fmt) {
        /* To handle this change, one could call av_image_alloc again and
         * decode the following frames into another rawvideo file. */
        fprintf(stderr, "Error: Width, height and pixel format have to be "
                "constant in a rawvideo file, but the width, height or "
                "pixel format of the input video changed:\n"
                "old: width = %d, height = %d, format = %s\n"
                "new: width = %d, height = %d, format = %s\n",
                width, height, av_get_pix_fmt_name(pix_fmt),
                frame->width, frame->height,
                av_get_pix_fmt_name(frame->format));
        return -1;
    }


    /* copy decoded frame to destination buffer:
     * this is required since rawvideo expects non aligned data */
    av_image_copy(video_dst_data, video_dst_linesize,
                  (const uint8_t **)(frame->data), frame->linesize,
                  pix_fmt, width, height);

    /* write to rawvideo file */
    fwrite(video_dst_data[0], 1, video_dst_bufsize, video_dst_file);
    return 0;
}
```

对于视频帧，这里做了下判断。在前面的 流程2-打开音视频解码时，我们在打开视频解码器后，从解码器获取到视频帧的宽高和像素格式，这里会和真正解码处理的帧的对应参数做一下比较，如果不相干，那就说明是有问题的。而如果一切正常的情况下，我们通过 *av_image_copy* 函数将视频帧数据 即*frame->data* 拷贝到 video_dst_data 中，然后把数据写入输出文件即可。关于前两个参数 video_dst_data 和 video_dst_linesize 在前面流程2时已经介绍过了，分别是用于存储视频帧各通过数据和通道长度，且前面已经通过 *av_image_allc* 分配好了内存空间。


```
static int output_audio_frame(AVFrame *frame)
{
    size_t unpadded_linesize = frame->nb_samples * av_get_bytes_per_sample(frame->format);
    printf("audio_frame n:%d nb_samples:%d pts:%s\n",
           audio_frame_count++, frame->nb_samples,
           av_ts2timestr(frame->pts, &audio_dec_ctx->time_base));

    /* Write the raw audio data samples of the first plane. This works
     * fine for packed formats (e.g. AV_SAMPLE_FMT_S16). However,
     * most audio decoders output planar audio, which uses a separate
     * plane of audio samples for each channel (e.g. AV_SAMPLE_FMT_S16P).
     * In other words, this code will write only the first audio channel
     * in these cases.
     * You should use libswresample or libavfilter to convert the frame
     * to packed data. */
    fwrite(frame->extended_data[0], 1, unpadded_linesize, audio_dst_file);

    return 0;
}
```

对于音频帧AVFrame:
frame->nb_samples 值等于**每个通道**的音频采样数，函数 *av_get_bytes_per_sample* 可以获取到每个simple的大小。两者相乘得到的是**一个通道**的数据大小。
frame->extended_data 每一个channel分别存储，即frame->extended_data[0]指向的是channel 1的数据，以此类推。而每个通道的对应数据大小，存储在 frame->linesize[0] 中，且对于每一个音频的AVFrame，即使可以有多个channel，但是每个channel的size 是相等的，都是取 frame->linesize[0]。而上面的注释已经写清楚了，本例子只取单通道数据，如果要取多通道数据（如果有的话）需要做进一步处理。


至此，经过上述步骤，我们就可以使用FFMpeg Api从媒体文件导出音视频裸数据了，需要注意的是，这样导出的数据是纯裸数据，.h264文件中没有包含特征码和SPS/PPS，因此使用ffplay 进行播放的时候，是指定相应参数的。这里也给出播放方式,像素格式和视频宽高在打开解码器的时候就已经知道，打印出来即可。

```
ffplay -f rawvideo -pix_fmt [pix_format] -video_size [width]x[height] simple.h264 
```

同理，.aac文件中也没有 pts/bts 数据，也是需要自己声明的。

```
ffplay -f [simple_format] -ac 1 -ar [sample_rate] simple.aac
```


程序完整代码请移步FFMpeg仓库：(https://github.com/FFmpeg/FFmpeg/blob/master/doc/examples/demuxing_decoding.c)
对API有疑问，请移步FFMpeg官方文档：(https://ffmpeg.org/doxygen/4.1/index.html)





本文是个人学习的理解记录，如果有理解有误的地方，欢饮各位大佬评论区指正。非常感谢~~