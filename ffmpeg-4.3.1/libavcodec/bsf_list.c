static const AVBitStreamFilter * const bitstream_filters[] = {
    &ff_aac_adtstoasc_bsf,
    &ff_h264_metadata_bsf,
    &ff_h264_mp4toannexb_bsf,
    &ff_mp3_header_decompress_bsf,
    &ff_null_bsf,
    &ff_vp9_superframe_bsf,
    NULL };
