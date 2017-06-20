//
//  SJRecordEncoder.h
//  SJRecordVideoDemo
//
//  Created by Soldier on 2017/6/19.
//  Copyright © 2017年 Shaojie Hong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class SJRecordEngine;

/**
 写入并编码视频的的类
 */

@interface SJRecordEncoder : NSObject

@property (nonatomic, readonly) NSString *path;

/**
 WCLRecordEncoder遍历构造器的
 
 @param path 媒体存发路径
 @param cy   视频分辨率的高
 @param cx   视频分辨率的宽
 @param ch   音频通道
 @param rate 音频的采样比率

 @return SJRecordEncoder的实体
 */
+ (SJRecordEncoder *)encoderForPath:(NSString*)path
                             height:(NSInteger)cy
                              width:(NSInteger)cx
                           channels:(int)ch
                            samples:(Float64)rate;

/**
 初始化方法
 
 @param path 媒体存发路径
 @param cy   视频分辨率的高
 @param cx   视频分辨率的宽
 @param ch   音频通道
 @param rate 音频的采样率
 
 @return WCLRecordEncoder的实体
 */
- (instancetype)initPath:(NSString *)path
                  height:(NSInteger)cy
                   width:(NSInteger)cx
                channels:(int)ch
                 samples:(Float64)rate;

/**
 完成视频录制时调用

 @param handler 完成的回掉block
 */
- (void)finishWithCompletionHandler:(void (^)(void))handler;

/**
 通过这个方法写入数据

 @param sampleBuffer 写入的数据
 @param isVideo      是否写入的是视频
 
 @return 写入是否成功
 */
- (BOOL)encodeFrame:(CMSampleBufferRef)sampleBuffer isVideo:(BOOL)isVideo;

@end
