//
//  RecordProgressView.h
//  SJRecordVideoDemo
//
//  Created by Soldier on 2017/6/20.
//  Copyright © 2017年 Shaojie Hong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecordProgressView : UIView

@property (nonatomic, assign) CGFloat progress;//当前进度
@property (nonatomic, strong) UIColor *progressBgColor;//进度条背景颜色
@property (nonatomic, strong) UIColor *progressColor;//进度条颜色
@property (nonatomic, assign) CGFloat loadProgress;//加载好的进度
@property (nonatomic, strong) UIColor *loadProgressColor;//已经加载好的进度颜色

@end
