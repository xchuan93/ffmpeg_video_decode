//
//  XCFFmpeg.m
//  XCFFmpeg
//
//  Created by Apple on 2018/10/26.
//  Copyright © 2018年 XC. All rights reserved.
//

#import "XCFFmpeg.h"


@implementation XCFFmpeg

//视频解码
- (void)ffmepgVideoDecode:(NSString*)inFilePath outFilePath:(NSString*)outFilePath{

    av_register_all();
    AVFormatContext *av_ctx = avformat_alloc_context();
    const char *url = [inFilePath UTF8String];
    int ret = avformat_open_input(&av_ctx, url, NULL, NULL);
    if (ret != 0) {
        NSLog(@"打开文件失败");
        return ;
    }
    ret = avformat_find_stream_info(av_ctx, NULL);
    if (ret < 0) {
        NSLog(@"查找失败");
        return ;
    }

    AVCodec *inputCodec = NULL;
    int video_stream_index = av_find_best_stream(av_ctx, AVMEDIA_TYPE_VIDEO, -1, -1, &inputCodec, 0);
    if (video_stream_index == -1) {
        NSLog(@"没有找到视频流index");
        return ;
    }
    AVCodecContext *av_codec_ctx = avcodec_alloc_context3(NULL);
    if (avcodec_parameters_to_context(av_codec_ctx, av_ctx->streams[video_stream_index]->codecpar) < 0){
            return ;
    }
    AVCodec *av_codec = avcodec_find_decoder(av_codec_ctx->codec_id);
    NSLog(@"解码器名称 -- %s",av_codec->name);
    if (avcodec_open2(av_codec_ctx, av_codec, NULL) != 0) {
        NSLog(@"打开解码器失败");
    }

    AVPacket *packet = (AVPacket *)av_malloc(sizeof(AVPacket));
    AVFrame *avFrame_in = av_frame_alloc();
    int decode_result = 0;

    struct SwsContext *swsctx = sws_getContext(av_codec_ctx->width, av_codec_ctx->height, av_codec_ctx->pix_fmt, av_codec_ctx->width, av_codec_ctx->height, AV_PIX_FMT_YUV420P, SWS_BICUBIC, NULL, NULL, NULL);
    AVFrame *avFrame_yuv420p = av_frame_alloc();
    int bufer_size = av_image_get_buffer_size(AV_PIX_FMT_YUV420P, av_codec_ctx->width, av_codec_ctx->height, 1);
    uint8_t *out_buffer = (uint8_t *)malloc(bufer_size);
    av_image_fill_arrays(avFrame_yuv420p->data, avFrame_yuv420p->linesize, out_buffer, AV_PIX_FMT_YUV420P, av_codec_ctx->width, av_codec_ctx->height, 1);

    int y_size,u_size,v_size;
    const char *outfile = [outFilePath UTF8String];
    FILE *file_yuv420p = fopen(outfile, "wb+");
    if (file_yuv420p == NULL) {
        NSLog(@"打开文件失败");
        return ;
    }
    int current_index = 0;
    while (av_read_frame(av_ctx, packet) >= 0) {
        if (packet->stream_index == video_stream_index) {
            avcodec_send_packet(av_codec_ctx, packet);
            decode_result = avcodec_receive_frame(av_codec_ctx, avFrame_in);
            if (decode_result == 0) {
                sws_scale(swsctx,(const uint8_t *const *)avFrame_in->data, avFrame_in->linesize, avFrame_in->width, avFrame_in->height, avFrame_yuv420p->data, avFrame_yuv420p->linesize);
                y_size = av_codec_ctx->width * av_codec_ctx->height;
                u_size = y_size / 4;
                v_size = y_size / 4;
                
                int i,j,k;
                int video_decode_size = avpicture_get_size(av_codec_ctx->pix_fmt, av_codec_ctx->width,av_codec_ctx->height);
                uint8_t * video_decode_buf =( uint8_t *)calloc(1,video_decode_size * 3 * sizeof(char));
                for (i = 0; i < av_codec_ctx->height; i++) {
                    memcpy(video_decode_buf+av_codec_ctx->width * i, avFrame_in->data[0]+avFrame_in->linesize[0]*i, av_codec_ctx->width);
                }
                for (j = 0; j < av_codec_ctx->height / 2; j ++) {
                    memcpy(video_decode_buf+av_codec_ctx->width * i+av_codec_ctx->width/2 *j, avFrame_in->data[1]+avFrame_in->linesize[1]*j, av_codec_ctx->width/2);
                }
                for (k = 0; k < av_codec_ctx->height / 2; k ++) {
                    memcpy(video_decode_buf+av_codec_ctx->width * i+av_codec_ctx->width/2 *j + av_codec_ctx->width/2*k, avFrame_in->data[2]+avFrame_in->linesize[2]*k, av_codec_ctx->width/2);
                }
                
//                NSData *data = [NSData dataWithBytes:video_decode_buf length:video_decode_size * 3 * sizeof(char)];
//                CIImage *ciimage = [CIImage imageWithCVPixelBuffer:CFBridgingRetain(data)];
//                UIImage *img = [UIImage imageWithCIImage:ciimage];
//
//                UIImage *img1 = [UIImage imageWithData:data];
                
//                char *data = (char *)malloc(avFrame_in->linesize[0] * 300);
//                memcpy(data, avFrame_in->data, avFrame_in->linesize[0] *300);
                
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [[NSNotificationCenter defaultCenter] postNotificationName:@"yuv" object:data];
//                });
//                self.yuvblock(<#AVFrame *data#>)
                
                UIImage *img = [self YUVtoUIImage:av_codec_ctx->width h:av_codec_ctx->height buffer:video_decode_buf];
                self.showImg(img);
                
                fwrite(avFrame_yuv420p->data[0], 1, y_size, file_yuv420p);
                fwrite(avFrame_yuv420p->data[1], 1, u_size, file_yuv420p);
                fwrite(avFrame_yuv420p->data[2], 1, v_size, file_yuv420p);

                current_index ++;
                NSLog(@"解码第几帧   %d",current_index);
                
                
            }
            break ;
        }
    }
    av_packet_free(&packet);
    fclose(file_yuv420p);
    av_frame_free(&avFrame_in);
    av_frame_free(&avFrame_yuv420p);
    free(out_buffer);
    avcodec_close(av_codec_ctx);
    avformat_free_context(av_ctx);
}

- (UIImage *)YUVtoUIImage:(int)w h:(int)h buffer:(unsigned char *)buffer{
    //YUV(NV12)-->CIImage--->UIImage Conversion
    NSDictionary *pixelAttributes = @{(NSString*)kCVPixelBufferIOSurfacePropertiesKey:@{}};
    
    
    CVPixelBufferRef pixelBuffer = NULL;
    
    CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                          w,
                                          h,
                                          kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                                          (__bridge CFDictionaryRef)(pixelAttributes),
                                          &pixelBuffer);
    
    CVPixelBufferLockBaseAddress(pixelBuffer,0);
    unsigned char *yDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    
    unsigned char *y_ch0 = buffer;
    unsigned char *y_ch1 = buffer + w * h;
    memcpy(yDestPlane, y_ch0, w * h);
    unsigned char *uvDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    
    memcpy(uvDestPlane, y_ch1, w * h/2);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    if (result != kCVReturnSuccess) {
        NSLog(@"Unable to create cvpixelbuffer %d", result);
    }
    
    CIImage *coreImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    
    CIContext *MytemporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef MyvideoImage = [MytemporaryContext createCGImage:coreImage
                                                       fromRect:CGRectMake(0, 0, w, h)];
    
    UIImage *Mynnnimage = [[UIImage alloc] initWithCGImage:MyvideoImage
                                                     scale:1.0
                                               orientation:UIImageOrientationRight];
    
    CVPixelBufferRelease(pixelBuffer);
    CGImageRelease(MyvideoImage);
    
    return Mynnnimage;
}

@end
