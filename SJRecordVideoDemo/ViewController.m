//
//  ViewController.m
//  SJRecordVideoDemo
//
//  Created by Soldier on 2017/6/19.
//  Copyright © 2017年 Shaojie Hong. All rights reserved.
//

#import "ViewController.h"
#import "SJRecordEngine.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <MediaPlayer/MediaPlayer.h>
#import "Constant.h"
#import "UIView+Extension.h"
#import "VideoRecordButton2.h"
#import "RecordProgressView.h"
#import "VideoPreviewController.h"

@interface ViewController ()<SJRecordEngineDelegate> {
    UIButton *_flashButton;
}

@property (nonatomic, strong) SJRecordEngine *recordEngine;
@property (nonatomic, strong) VideoRecordButton2 *recordButton;
@property (nonatomic, strong) RecordProgressView *progressView;
@property (nonatomic, strong) UIButton *okBtn;
@property (nonatomic, strong) UIView *playerView;

@end




@implementation ViewController

- (void)dealloc {
    _recordEngine = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"#define VideoRecordDoneNotification" object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self constructBaseView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backViewForNotify) name:@"VideoRecordDoneNotification" object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.recordEngine shutdown];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self configRecordEngine];
}

- (SJRecordEngine *)recordEngine {
    if (!_recordEngine) {
        _recordEngine = [[SJRecordEngine alloc] init];
        _recordEngine.delegate = self;
    }
    return _recordEngine;
}

- (void)configRecordEngine {
    if (!_recordEngine) {
        [self.recordEngine previewLayer].frame = self.view.bounds;
        [self.view.layer insertSublayer:[self.recordEngine previewLayer] atIndex:0];
    }
    [self.recordEngine startUp];
}

- (void)constructBaseView {
    // 切换摄像头
    UIButton *toggleCameraButton = [[UIButton alloc] init];
    toggleCameraButton.frame = CGRectMake(self.view.width - 13 - 30, 20 + 10, 30, 30);
    [toggleCameraButton setBackgroundImage:[UIImage imageNamed:@"videoRCTurnBtn"] forState:UIControlStateNormal];
    [toggleCameraButton setBackgroundImage:[UIImage imageNamed:@"videoRCTurnBtn2"] forState:UIControlStateSelected];
    [toggleCameraButton addTarget:self action:@selector(toggleCameraButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:toggleCameraButton];
    
    // 闪光灯
    _flashButton = [[UIButton alloc] init];
    _flashButton.frame = CGRectMake(toggleCameraButton.left - 36 - 30, toggleCameraButton.top, 30, 30);
    [_flashButton setBackgroundImage:[UIImage imageNamed:@"videoRCFlashBtn"] forState:UIControlStateNormal];
    [_flashButton setBackgroundImage:[UIImage imageNamed:@"videoRCFlashCloseBtn"] forState:UIControlStateSelected];
    [_flashButton addTarget:self action:@selector(flashButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_flashButton];
    
    // 录制按钮
    [self recordButton];
    
    self.okBtn.frame = CGRectMake(self.recordButton.right + 40, self.recordButton.top + 20, 40, 40);
}

- (UIButton *)okBtn {
    if (!_okBtn) {
        _okBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_okBtn setImage:[UIImage imageNamed:@"videoRecordDone"] forState:UIControlStateNormal];
        [_okBtn addTarget:self action:@selector(okBtnAction) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_okBtn];
    }
    return _okBtn;
}

- (VideoRecordButton2 *)recordButton {
    if (!_recordButton) {
        _recordButton = [[VideoRecordButton2 alloc] initWithFrame:CGRectMake(self.view.width * 0.5 - 75 * 0.5, self.view.height - 48 - 75, 75, 75)];
        [_recordButton addTarget:self action:@selector(recordButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_recordButton];
    }
    return _recordButton;
}

- (RecordProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[RecordProgressView alloc] initWithFrame:CGRectMake(0, self.view.height - 6, self.view.width, 6)];
        _progressView.progress = 0;
        _progressView.progressColor = COLOR_C1;
        _progressView.progressBgColor = [UIColor clearColor];
        _progressView.loadProgressColor = [UIColor colorWithWhite:0 alpha:0.7];
        [self.view addSubview:_progressView];
    }
    return _progressView;
}

#pragma mark - Func

// 切换前后置摄像头
- (void)toggleCameraButtonEvent:(id)sender {
    UIButton *btn = (UIButton *)sender;
    btn.selected = !btn.selected;
    if (btn.selected) { //前置摄像头
        [self.recordEngine closeFlashLight];
        [self.recordEngine changeCameraInputDeviceisFront:YES];
        
        _flashButton.hidden = YES;
    } else {//后置摄像头
        [self.recordEngine changeCameraInputDeviceisFront:NO];
        
        _flashButton.hidden = NO;
    }
}

// 打开／关闭闪光灯
- (void)flashButtonEvent:(id)sender {
    UIButton *button = (UIButton *)sender;
    button.selected = !button.selected;
    
    if (button.selected) {
        [self.recordEngine openFlashLight];
    } else {
        [self.recordEngine closeFlashLight];
    }
}

- (void)recordButtonAction {
    self.recordButton.selected = !self.recordButton.selected;
    
    if (self.recordButton.selected) {
        if (self.recordEngine.isCapturing) {
            [self.recordEngine resumeCapture];
        }else {
            [self.recordEngine startCapture];
        }
    } else {
        [self.recordEngine pauseCapture];
    }
}

- (void)okBtnAction {
    if ([self.recordEngine isCapturing]) {
        [self.recordEngine pauseCapture];
    }
    
    if (_recordEngine.videoPath.length > 0) {
        __weak typeof(self) weakSelf = self;
        [self.recordEngine stopCaptureHandler:^(UIImage *movieImage) {
            [weakSelf goToPlayView];
        }];
    } else {
        NSLog(@"请先录制视频~");
    }
}

#pragma mark - SJRecordEngineDelegate

- (void)recordProgress:(CGFloat)progress {
    NSLog(@"----- %f", progress);
    self.progressView.progress = progress;
}

#pragma mark - play

- (void)goToPlayView {
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:_recordEngine.videoPath, @"url", nil];
    
    VideoPreviewController *controller = [[VideoPreviewController alloc] initWithQuery:query];
    [self addChildViewController:controller];
    
    _playerView = controller.view;
    _playerView.frame = CGRectMake(0, 0, self.view.width, self.view.height);
    [self.view addSubview:_playerView];
}

- (void)removePlayer {
    if (_playerView) {
        RELEASE_VIEW_SAFELY(_playerView)
    }
}

- (void)backViewForNotify {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removePlayer];
//        [self.recordEngine shutdown];
        self.progressView.progress = 0.0;
        self.recordButton.selected = NO;
    });
}

@end
