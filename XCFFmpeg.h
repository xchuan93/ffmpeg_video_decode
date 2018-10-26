//
//  XCFFmpeg.h
//  XCFFmpeg
//
//  Created by Apple on 2018/10/26.
//  Copyright © 2018年 XC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <OpenGLES/gltypes.h>
#include "avformat.h"
#include "avcodec.h"
#include "imgutils.h"
#include "swscale.h"
#include "swresample.h"
#include "frame.h"

typedef void(^ShowYUVData)(AVFrame *data);

typedef void(^ShowImg)(UIImage *img);

@interface XCFFmpeg : NSObject


@property (nonatomic, copy) ShowYUVData yuvblock;
@property (nonatomic, strong) ShowImg showImg;

//视频解码
- (void)ffmepgVideoDecode:(NSString*)inFilePath outFilePath:(NSString*)outFilePath;

@end
