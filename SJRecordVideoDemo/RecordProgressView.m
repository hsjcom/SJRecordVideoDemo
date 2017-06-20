//
//  RecordProgressView.m
//  SJRecordVideoDemo
//
//  Created by Soldier on 2017/6/20.
//  Copyright © 2017年 Shaojie Hong. All rights reserved.
//

#import "RecordProgressView.h"

@implementation RecordProgressView

- (void)setProgress:(CGFloat)progress {
    _progress = progress;
    [self setNeedsDisplay];
}

- (void)setProgressBgColor:(UIColor *)progressBgColor {
    _progressBgColor = progressBgColor;
    [self setNeedsDisplay];
}

- (void)setloadProgressColor:(UIColor *)loadProgressColor {
    _loadProgressColor = loadProgressColor;
    [self setNeedsDisplay];
}

- (void)setLoadProgress:(CGFloat)loadProgress {
    _loadProgress = loadProgress;
    [self setNeedsDisplay];
}

- (void)setProgressColor:(UIColor *)progressColor {
    _progressColor = progressColor;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextAddRect(context, CGRectMake(0, 0, rect.size.width, rect.size.height));
    [self.progressBgColor set];
    CGContextSetAlpha(context, 0.5);
    CGContextDrawPath(context, kCGPathFill);
    CGContextAddRect(context, CGRectMake(0, 0, rect.size.width * self.loadProgress, rect.size.height));
    [self.progressBgColor set];
    CGContextSetAlpha(context, 1);
    CGContextDrawPath(context, kCGPathFill);
    CGContextAddRect(context, CGRectMake(0, 0, rect.size.width * self.progress, rect.size.height));
    [self.progressColor set];
    CGContextSetAlpha(context, 1);
    CGContextDrawPath(context, kCGPathFill);
}

@end
