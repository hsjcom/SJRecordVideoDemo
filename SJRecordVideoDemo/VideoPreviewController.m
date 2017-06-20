//
//  VideoPreviewController.m
//  SJRecordVideoDemo
//
//  Created by Soldier on 2017/6/20.
//  Copyright © 2017年 Shaojie Hong. All rights reserved.
//

#import "VideoPreviewController.h"
#import "Constant.h"
#import "UIView+Extension.h"
@import AVFoundation;

@interface VideoPreviewController ()

@property (nonatomic, strong) NSString *fileUrl;
@property (nonatomic, strong) AVPlayer *avPlayer;
@property (nonatomic, strong) AVPlayerLayer *avPlayerLayer;
@property (nonatomic, strong) UIButton *backBtn;

@end


@implementation VideoPreviewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [self removePlayer];
}

- (id)initWithQuery:(NSDictionary *)query {
    self = [super init];
    if (self) {
        self.fileUrl = [query objectForKey:@"url"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    [self initialAvPlayer];
    [self constructBaseView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.avPlayer play];
}

- (void)initialAvPlayer {
    self.avPlayer = [AVPlayer playerWithURL:[NSURL fileURLWithPath:self.fileUrl]];
    self.avPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    
    self.avPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
    self.avPlayerLayer.frame = CGRectMake(0, 0, self.view.width, self.view.height);
    self.avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;//全屏
    [self.view.layer addSublayer:self.avPlayerLayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[self.avPlayer currentItem]];
}

- (void)removePlayer {
    if (_avPlayer) {
        [_avPlayer pause];
        _avPlayer = nil;
    }
    if (_avPlayerLayer) {
        [_avPlayerLayer removeFromSuperlayer];
        _avPlayerLayer = nil;
    }
}

- (void)constructBaseView {
    _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_backBtn setImage:[UIImage imageNamed:@"videoRCCloseBtn"] forState:UIControlStateNormal];
    [_backBtn addTarget:self action:@selector(backView) forControlEvents:UIControlEventTouchUpInside];
    _backBtn.frame = CGRectMake(0, 20, 50, 50);
    [self.view addSubview:_backBtn];
}

- (void)backView {
    [self removePlayer];
    [self.navigationController popViewControllerAnimated:YES];
    NSDictionary *itemDic = [NSDictionary dictionaryWithObjectsAndKeys:self.fileUrl, @"url", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VideoRecordDoneNotification" object:nil userInfo:itemDic];
}

- (void)playerDidReachEnd:(NSNotification *)notification {
    //重复播放
    AVPlayerItem *playItem = [notification object];
    [playItem seekToTime:kCMTimeZero];
}


@end
