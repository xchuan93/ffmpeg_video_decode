# ffmpeg_video_decode

### 1 ：初始化AVFormatContext
### 2 ：使用avformat_find_stream_info将文件和AVFormatContext关联起来
### 3 ：使用av_find_best_stream查找音视频id （4.3之后）
### 4 ：4.3之后使用avcodec_parameters_to_context初始化AVCodecContext
### 5 ： avcodec_find_decoder初始化AVCodec
### 6 ：avcodec_open2打开编解码器
### 7 ： 生产sws_getContext结构体用于转换数据类型
### 8 ： avcodec_send_packet，avcodec_receive_frame 视频数据解码（4.3之后）
### 9 ： 便利AVFrame数据得到bufferData
                      for (i = 0; i < av_codec_ctx->height; i++) {
                    memcpy(video_decode_buf+av_codec_ctx->width * i, avFrame_in->data[0]+avFrame_in->linesize[0]*i, av_codec_ctx->width);
                }
                for (j = 0; j < av_codec_ctx->height / 2; j ++) {
                    memcpy(video_decode_buf+av_codec_ctx->width * i+av_codec_ctx->width/2 *j, avFrame_in->data[1]+avFrame_in->linesize[1]*j, av_codec_ctx->width/2);
                }
                for (k = 0; k < av_codec_ctx->height / 2; k ++) {
                    memcpy(video_decode_buf+av_codec_ctx->width * i+av_codec_ctx->width/2 *j + av_codec_ctx->width/2*k, avFrame_in->data[2]+avFrame_in->linesize[2]*k, av_codec_ctx->width/2);
                }

### 10 ：[self YUVtoUIImage:av_codec_ctx->width h:av_codec_ctx->height buffer:video_decode_buf] yuv420p数据转UIImage显示
