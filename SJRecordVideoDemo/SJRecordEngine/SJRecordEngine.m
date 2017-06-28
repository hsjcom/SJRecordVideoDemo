//
//  SJRecordEngine.m
//  SJRecordVideoDemo
//
//  Created by Soldier on 2017/6/19.
//  Copyright © 2017年 Shaojie Hong. All rights reserved.
//

#import "SJRecordEngine.h"
#import "SJRecordEncoder.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <AVKit/AVKit.h>
#import <UIKit/UIKit.h>

@interface SJRecordEngine ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate, CAAnimationDelegate> {
    CMTime _timeOffset;//录制的偏移CMTime
    CMTime _lastVideo;//记录上一次视频数据文件的CMTime
    CMTime _lastAudio;//记录上一次音频数据文件的CMTime
    
    NSInteger _width;//视频分辨的宽
    NSInteger _height;//视频分辨的高
    int _channels;//音频通道
    Float64 _samplerate;//音频采样率
}

@property (nonatomic, strong) SJRecordEncoder *recordEncoder;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;//捕获到的视频呈现的layer
@property (nonatomic, strong) AVCaptureSession *recordSession;//捕获视频的会话
//Input
@property (nonatomic, strong) AVCaptureDeviceInput *backCameraInput;//后置摄像头输入
@property (nonatomic, strong) AVCaptureDeviceInput *frontCameraInput;//前置摄像头输入
@property (nonatomic, strong) AVCaptureDeviceInput *audioMicInput;//麦克风输入
//Connection
@property (nonatomic, strong) AVCaptureConnection *audioConnection;//音频录制连接
@property (nonatomic, strong) AVCaptureConnection *videoConnection;//视频录制连接
//Output
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;//视频输出
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioOutput;//音频输出

@property (nonatomic,   copy) dispatch_queue_t captureQueue;//录制的队列

@property (nonatomic, assign) BOOL discont;//是否中断
@property (nonatomic, assign) CMTime startTime;//开始录制的时间
@property (nonatomic, assign) BOOL isCapturing;//正在录制
@property (nonatomic, assign) BOOL isPaused;//是否暂停
@property (nonatomic, assign) CGFloat currentRecordTime;//当前录制时间

@end




@implementation SJRecordEngine

- (void)dealloc {
    [_recordSession stopRunning];
    _captureQueue = nil;
    _recordSession = nil;
    _previewLayer = nil;
    _backCameraInput = nil;
    _frontCameraInput = nil;
    _audioOutput = nil;
    _videoOutput = nil;
    _audioConnection = nil;
    _videoConnection = nil;
    _recordEncoder = nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.maxRecordTime = 60.0f;
    }
    return self;
}

#pragma mark - 公开的方法

/**
 启动录制功能
 */
- (void)startUp {
//    NSLog(@"启动录制功能");
    self.startTime = CMTimeMake(0, 0);
    self.isCapturing = NO;
    self.isPaused = NO;
    self.discont = NO;
    [self.recordSession startRunning];
}

/**
 关闭录制功能
 */
- (void)shutdown {
    _startTime = CMTimeMake(0, 0);
    if (_recordSession) {
        [_recordSession stopRunning];
    }
    [_recordEncoder finishWithCompletionHandler:^{
//        NSLog(@"录制完成");
    }];
}

/**
 开始录制
 */
- (void)startCapture {
    //限制在一个线程执行
    @synchronized(self) {
        if (!self.isCapturing) {
//            NSLog(@"开始录制");
            self.recordEncoder = nil;
            self.isPaused = NO;
            self.discont = NO;
            _timeOffset = CMTimeMake(0, 0);
            self.isCapturing = YES;
        }
    }
}

/**
 暂停录制
 */
- (void)pauseCapture {
    @synchronized(self) {
        if (self.isCapturing) {
//            NSLog(@"暂停录制");
            self.isPaused = YES;
            self.discont = YES;
        }
    }
}

/**
 继续录制
 */
- (void)resumeCapture {
    @synchronized(self) {
        if (self.isPaused) {
//            NSLog(@"继续录制");
            self.isPaused = NO;
        }
    }
}

/**
 停止录制
 */
- (void)stopCaptureHandler:(void (^)(UIImage *movieImage))handler {
    @synchronized(self) {
        if (self.isCapturing) {
            NSString *path = self.recordEncoder.path;
            NSURL *url = [NSURL fileURLWithPath:path];
            self.isCapturing = NO;
            dispatch_async(_captureQueue, ^{
                [self.recordEncoder finishWithCompletionHandler:^{
                    self.isCapturing = NO;
                    self.recordEncoder = nil;
                    self.startTime = CMTimeMake(0, 0);
                    self.currentRecordTime = 0;
                    if ([self.delegate respondsToSelector:@selector(recordProgress:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate recordProgress:self.currentRecordTime / self.maxRecordTime];
                        });
                    }
                    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
                    } completionHandler:^(BOOL success, NSError * _Nullable error) {
                        NSLog(@"保存成功");
                    }];
                    [self movieToImageHandler:handler];
                }];
            });
        }
    }
}

/**
 获取视频第一帧的图片
 */
- (void)movieToImageHandler:(void (^)(UIImage *movieImage))handler {
    NSURL *url = [NSURL fileURLWithPath:self.videoPath];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = TRUE;
    CMTime thumbTime = CMTimeMakeWithSeconds(0, 60);
    generator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    AVAssetImageGeneratorCompletionHandler generatorHandler =
    ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        if (result == AVAssetImageGeneratorSucceeded) {
            UIImage *thumbImg = [UIImage imageWithCGImage:im];
            if (handler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(thumbImg);
                });
            }
        }
    };
    [generator generateCGImagesAsynchronouslyForTimes:
     [NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:generatorHandler];
}

#pragma mark - setter & getter
#pragma mark recordSession

/**
 捕获视频的会话
 */
- (AVCaptureSession *)recordSession {
    //作为协调输入与输出的中心,第一步需要创建一个Session
    if (!_recordSession) {
        _recordSession = [[AVCaptureSession alloc] init];
        
        //使用AVCaptureDeviceInput来让设备添加到session中, AVCaptureDeviceInput负责管理设备端口
        //添加后置摄像头的输入 （前置摄像头切换时添加）
        if ([_recordSession canAddInput:self.backCameraInput]) {
            [_recordSession addInput:self.backCameraInput];
        }
        //添加麦克风的输入
        if ([_recordSession canAddInput:self.audioMicInput]) {
            [_recordSession addInput:self.audioMicInput];
        }
        
        //添加AVCaptureOutput以从session中取得数据
        //添加视频输出
        if ([_recordSession canAddOutput:self.videoOutput]) {
            [_recordSession addOutput:self.videoOutput];
            //设置视频的分辨率
            _width = 720;
            _height = 1280;
        }
        //添加音频输出
        if ([_recordSession canAddOutput:self.audioOutput]) {
            [_recordSession addOutput:self.audioOutput];
        }
        
        //设置视频录制的方向
        self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    return _recordSession;
}

/**
 后置摄像头输入
 */
- (AVCaptureDeviceInput *)backCameraInput {
    if (_backCameraInput == nil) {
        NSError *error;
        _backCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backCamera] error:&error];
        if (error) {
            NSLog(@"获取后置摄像头失败~");
        }
    }
    return _backCameraInput;
}

/**
 前置摄像头输入
 */
- (AVCaptureDeviceInput *)frontCameraInput {
    if (!_frontCameraInput) {
        NSError *error;
        _frontCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontCamera] error:&error];
        if (error) {
            NSLog(@"获取前置摄像头失败~");
        }
    }
    return _frontCameraInput;
}

/**
 麦克风输入
 */
- (AVCaptureDeviceInput *)audioMicInput {
    if (!_audioMicInput) {
        AVCaptureDevice *mic = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        NSError *error;
        _audioMicInput = [AVCaptureDeviceInput deviceInputWithDevice:mic error:&error];
        if (error) {
            NSLog(@"获取麦克风失败~");
        }
    }
    return _audioMicInput;
}

/**
 视频输出
 使用哪种视频的格式，取决于初始化相机时设置的视频输出格式。
 设置为kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange时，表示输出的视频格式为NV12；
 设置为kCVPixelFormatType_420YpCbCr8Planar时，表示使用I420。
 GPUImage设置相机输出数据时，使用的就是NV12.
 */
- (AVCaptureVideoDataOutput *)videoOutput {
    if (!_videoOutput) {
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoOutput setSampleBufferDelegate:self queue:self.captureQueue];
        /**
         除了设置代理以外，还需要设置一个serial queue来供代理调用，这里必须使用serial queue来保证传给delegate的帧数据的顺序正确。我们可以使用这个 queue 来分发和处理视频帧
         */
        NSDictionary *setcapSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], kCVPixelBufferPixelFormatTypeKey,
                                        nil];
        _videoOutput.videoSettings = setcapSettings;
        
        /** default YES 来确保晚到的帧会被丢掉来避免延迟。
         如果不介意延迟，而更想要处理更多的帧，那就设置这个值为 NO，但是这并不意味着不会丢帧，只是不会被那么早或那么高效的丢掉。
         */
        _videoOutput.alwaysDiscardsLateVideoFrames = YES;
    }
    return _videoOutput;
}

/**
 音频输出
 */
- (AVCaptureAudioDataOutput *)audioOutput {
    if (!_audioOutput) {
        _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        [_audioOutput setSampleBufferDelegate:self queue:self.captureQueue];
    }
    return _audioOutput;
}

/**
 视频连接
 */
- (AVCaptureConnection *)videoConnection {
    if (!_videoConnection) {
        _videoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    }
    return _videoConnection;
}

/**
 音频连接
 */
- (AVCaptureConnection *)audioConnection {
    if (!_audioConnection) {
        _audioConnection = [self.audioOutput connectionWithMediaType:AVMediaTypeAudio];
    }
    return _audioConnection;
}

/**
 捕获到的视频呈现的layer
 */
- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (!_previewLayer) {
        //通过AVCaptureSession初始化
        AVCaptureVideoPreviewLayer *preview = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.recordSession];
        //设置比例为铺满全屏
        preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _previewLayer = preview;
    }
    return _previewLayer;
}

/**
 录制的队列
 */
- (dispatch_queue_t)captureQueue {
    if (_captureQueue == nil) {
        _captureQueue = dispatch_queue_create("SJRecordEngine", DISPATCH_QUEUE_SERIAL);
    }
    return _captureQueue;
}

#pragma mark - 切换动画

- (void)changeCameraAnimation {
    CATransition *changeAnimation = [CATransition animation];
    changeAnimation.delegate = self;
    changeAnimation.duration = 0.45;
    changeAnimation.type = @"oglFlip";
    changeAnimation.subtype = kCATransitionFromRight;
    changeAnimation.timingFunction = UIViewAnimationCurveEaseInOut;
    [self.previewLayer addAnimation:changeAnimation forKey:@"changeAnimation"];
}

- (void)animationDidStart:(CAAnimation *)anim {
    self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    [self.recordSession startRunning];
}

#pragma - mark 将mov文件转为MP4文件

- (void)changeMovToMp4:(NSURL *)mediaURL dataBlock:(void (^)(UIImage *movieImage))handler {
    AVAsset *video = [AVAsset assetWithURL:mediaURL];
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:video presetName:AVAssetExportPreset1280x720];
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.outputFileType = AVFileTypeMPEG4;
    NSString *basePath = [self getVideoCachePath];
    
    self.videoPath = [basePath stringByAppendingPathComponent:[self getUploadFileType:@"video" fileType:@"mp4"]];
    exportSession.outputURL = [NSURL fileURLWithPath:self.videoPath];
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        [self movieToImageHandler:handler];
    }];
}

#pragma mark - 视频相关

/**
 返回前置摄像头
 */
- (AVCaptureDevice *)frontCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

/**
 返回后置摄像头
 */
- (AVCaptureDevice *)backCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

/**
 切换前后置摄像头
 */
- (void)changeCameraInputDeviceisFront:(BOOL)isFront {
    if (isFront) {
        [self.recordSession stopRunning];
        [self.recordSession removeInput:self.backCameraInput];
        if ([self.recordSession canAddInput:self.frontCameraInput]) {
            [self changeCameraAnimation];
            [self.recordSession addInput:self.frontCameraInput];
        }
    }else {
        [self.recordSession stopRunning];
        [self.recordSession removeInput:self.frontCameraInput];
        if ([self.recordSession canAddInput:self.backCameraInput]) {
            [self changeCameraAnimation];
            [self.recordSession addInput:self.backCameraInput];
        }
    }
    
    /** 平滑切换
    [self.recordSession beginConfiguration];
    
    [self.recordSession removeInput:self.frontCameraInput];
    if ([self.recordSession canAddInput:self.backCameraInput]) {
        [self.recordSession addInput:self.backCameraInput];
    }

    [self.recordSession commitConfiguration];
     */
}

/**
 判断是否前置摄像头还是后置摄像头
 */
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position {
    //返回和视频录制相关的所有默认设备
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    //遍历这些设备返回跟position相关的设备
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

/**
 开启闪光灯
 */
- (void)openFlashLight {
    AVCaptureDevice *backCamera = [self backCamera];
    if (backCamera.torchMode == AVCaptureTorchModeOff) {
        [backCamera lockForConfiguration:nil]; //保证平滑的切换
        backCamera.torchMode = AVCaptureTorchModeOn;
        backCamera.flashMode = AVCaptureFlashModeOn;
        [backCamera unlockForConfiguration];
    }
}

/**
 关闭闪光灯
 */
- (void)closeFlashLight {
    AVCaptureDevice *backCamera = [self backCamera];
    if (backCamera.torchMode == AVCaptureTorchModeOn) {
        [backCamera lockForConfiguration:nil];
        backCamera.torchMode = AVCaptureTorchModeOff;
        backCamera.flashMode = AVCaptureTorchModeOff;
        [backCamera unlockForConfiguration];
    }
}

/**
 获取视频存放地址
 */
- (NSString *)getVideoCachePath {
    NSString *videoCache = [NSTemporaryDirectory() stringByAppendingPathComponent:@"videos"] ;
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:videoCache isDirectory:&isDir];
    if (!(isDir == YES && existed == YES)) {
        [fileManager createDirectoryAtPath:videoCache withIntermediateDirectories:YES attributes:nil error:nil];
    };
    return videoCache;
}

- (NSString *)getUploadFileType:(NSString *)type fileType:(NSString *)fileType {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HHmmss"];
    NSDate *NowDate = [NSDate dateWithTimeIntervalSince1970:now];
    ;
    NSString *timeStr = [formatter stringFromDate:NowDate];
    NSString *fileName = [NSString stringWithFormat:@"%@_%@.%@", type, timeStr, fileType];
    return fileName;
}

#pragma mark - 写入数据
#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate

/**
 CMSampleBuffer
 视频数据及其关联的元数据在 AVFoundation 中由 Core Media 框架中的对象表示。 Core Media 使用 CMSampleBuffer 表示视频数据。CMSampleBuffer 是一种 Core Foundation 风格的类型。CMSampleBuffer 的一个实例在对应的 Core Video pixel buffer 中包含了视频帧的数据
 */

/**
 captureOutput:didOutputSampleBuffer:fromConnection:
 中处理视频帧的时间开销不要超过分配给一帧的处理时长。如果这里处理的太长，那么 AV Foundation 将会停止发送视频帧给代理，也会停止发给其他输出端，比如 preview layer。
 */

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    
    BOOL isVideo = YES;
    //限制在一个线程执行
    @synchronized(self) {
        if (!self.isCapturing || self.isPaused) {
            return;
        }
        if (captureOutput != self.videoOutput) {
            isVideo = NO;
        }
        //初始化编码器，当有音频和视频参数时创建编码器
        if ((self.recordEncoder == nil) && !isVideo) {
            CMFormatDescriptionRef fmt = CMSampleBufferGetFormatDescription(sampleBuffer); //格式信息 CMFormatDescription
            [self setAudioFormat:fmt];
            NSString *videoName = [self getUploadFileType:@"video" fileType:@"mp4"];
            self.videoPath = [[self getVideoCachePath] stringByAppendingPathComponent:videoName];
            self.recordEncoder = [SJRecordEncoder encoderForPath:self.videoPath
                                                          height:_height
                                                           width:_width
                                                        channels:_channels
                                                         samples:_samplerate];
        }
        //判断是否中断录制过
        if (self.discont) {
            if (isVideo) {
                return; //如果是暂停的时候，进来的buffer 全部丢弃
            }
            self.discont = NO;
            // 计算暂停的时间
            CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer); //原始演示时间的时间戳
            CMTime last = isVideo ? _lastVideo : _lastAudio;
            if (last.flags & kCMTimeFlags_Valid) {
                if (_timeOffset.flags & kCMTimeFlags_Valid) {
                    pts = CMTimeSubtract(pts, _timeOffset); //减法 pts - _timeOffset
                }
                // 取得现在的时间 和 上一次时间 的时间差
                CMTime offset = CMTimeSubtract(pts, last);
                if (_timeOffset.value == 0) {
                    _timeOffset = offset;
                } else {
                    _timeOffset = CMTimeAdd(_timeOffset, offset); //加法 _timeOffset + offset
                }
            }
            // 清空记录
            _lastVideo.flags = 0;
            _lastAudio.flags = 0;
        }
        
        // 增加sampleBuffer的引用计时,这样我们可以释放这个或修改这个数据，防止在修改时被释放
        CFRetain(sampleBuffer);
        
        if (_timeOffset.value > 0) {
            CFRelease(sampleBuffer);
            //根据得到的timeOffset调整
            sampleBuffer = [self adjustTime:sampleBuffer by:_timeOffset];
        }
        // 记录暂停上一次录制的时间
        CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        CMTime dur = CMSampleBufferGetDuration(sampleBuffer);
        if (dur.value > 0) {
            pts = CMTimeAdd(pts, dur);
        }
        if (isVideo) {
            _lastVideo = pts;
        } else {
            _lastAudio = pts;
        }
    }
    CMTime dur = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    if (self.startTime.value == 0) {
        self.startTime = dur;
    }
    CMTime sub = CMTimeSubtract(dur, self.startTime);
    self.currentRecordTime = CMTimeGetSeconds(sub); //获取秒数
    if (self.currentRecordTime > self.maxRecordTime) {
        if (self.currentRecordTime - self.maxRecordTime < 0.1) {
            if ([self.delegate respondsToSelector:@selector(recordProgress:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate recordProgress:self.currentRecordTime / self.maxRecordTime];
                });
            }
        }
        return;
    }
    if ([self.delegate respondsToSelector:@selector(recordProgress:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate recordProgress:self.currentRecordTime / self.maxRecordTime];
        });
    }
    
    // 进行数据编码
    [self.recordEncoder encodeFrame:sampleBuffer isVideo:isVideo];
    
    CFRelease(sampleBuffer);
}

/**
 设置音频格式
 
 AudioStreamBasicDescription:
 mSampleRate;       采样率, eg. 44100
 mFormatID;         格式, eg. kAudioFormatLinearPCM
 mFormatFlags;      标签格式, eg. kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
 mBytesPerPacket;   每个Packet的Bytes数量, eg. 2
 mFramesPerPacket;  每个Packet的帧数量, eg. 1
 mBytesPerFrame;    (mBitsPerChannel / 8 * mChannelsPerFrame) 每帧的Byte数, eg. 2
 mChannelsPerFrame; 1:单声道；2:立体声, eg. 1
 mBitsPerChannel;   语音每采样点占用位数[8/16/24/32], eg. 16
 mReserved;         保留
 
 */
- (void)setAudioFormat:(CMFormatDescriptionRef)fmt {
    const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmt);
    _samplerate = asbd -> mSampleRate; //采样率
    _channels = asbd -> mChannelsPerFrame; //声道
}

/**
 调整媒体数据的时间
 */
- (CMSampleBufferRef)adjustTime:(CMSampleBufferRef)sample by:(CMTime)offset {
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    CMSampleTimingInfo *pInfo = malloc(sizeof(CMSampleTimingInfo) *count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    for (CMItemCount i = 0; i < count; i++) {
        pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset);
        pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
    }
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
    free(pInfo);
    return sout;
}

/**
 视频暂停 多视频合成 流程
 1.点击暂停，就执行 stopRunning 方法。恢复录制的时候重新录制下一个。这样就录制了多个小视频。然后手动把他们拼接起来。
 2.点击暂停的时候，CMSampleBufferRef 不写入。恢复录制的时候，再继续写入。
 
 两种方法对应的功能点:
 多段视频的拼接
 时间偏移量（就是暂停的时候）的计算
 */

/**
 音视频中的时间 CMTime
 
 一个c结构体 ，包括：
 
 typedef int64_t CMTimeValue : 分子
 typedef int32_t CMTimeScale : 分母 (必须为正，vidio文件的推荐范围是movie files range from 600 to 90000)
 typedef int64_t CMTimeEpoch : 类似循环次数(eg, loop number)加减法必须在同一个 epoch内
 uint32_t, CMTimeFlags :标记位 (一个枚举值)
 second = value/timescale
 */

@end
