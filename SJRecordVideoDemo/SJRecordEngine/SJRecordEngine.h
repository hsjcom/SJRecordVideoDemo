//
//  SJRecordEngine.h
//  SJRecordVideoDemo
//
//  Created by Soldier on 2017/6/19.
//  Copyright © 2017年 Shaojie Hong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVCaptureVideoPreviewLayer.h>


@protocol SJRecordEngineDelegate <NSObject>

- (void)recordProgress:(CGFloat)progress;

@end




@interface SJRecordEngine : NSObject

@property (nonatomic, weak) id<SJRecordEngineDelegate>delegate;
@property (nonatomic, assign, readonly) BOOL isCapturing;//正在录制
@property (nonatomic, assign, readonly) BOOL isPaused;//是否暂停
@property (nonatomic, assign, readonly) CGFloat currentRecordTime;//当前录制时间
@property (nonatomic, assign) CGFloat maxRecordTime;//最长录制时间
@property (nonatomic, copy) NSString *videoPath;//视频路径

/**
 捕获到的视频呈现的layer
 */
- (AVCaptureVideoPreviewLayer *)previewLayer;

/**
 启动录制功能
 */
- (void)startUp;

/**
 关闭录制功能
 */
- (void)shutdown;

/**
 开始录制
 */
- (void)startCapture;

/**
 暂停录制
 */
- (void)pauseCapture;

/**
 停止录制
 */
- (void)stopCaptureHandler:(void (^)(UIImage *movieImage))handler;

/**
 继续录制
 */
- (void)resumeCapture;

/**
 开启闪光灯
 */
- (void)openFlashLight;

/**
 关闭闪光灯
 */
- (void)closeFlashLight;

/**
 切换前后置摄像头
 */
- (void)changeCameraInputDeviceisFront:(BOOL)isFront;

/**
 将mov的视频转成mp4
 */
- (void)changeMovToMp4:(NSURL *)mediaURL dataBlock:(void (^)(UIImage *movieImage))handler;

@end
