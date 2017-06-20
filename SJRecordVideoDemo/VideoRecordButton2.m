//
//  VideoRecordButton2.m
//  TaQu
//
//  Created by Soldier on 2017/5/12.
//  Copyright © 2017年 厦门海豹信息技术. All rights reserved.
//

#import "VideoRecordButton2.h"
#import "Constant.h"
#import "UIView+Extension.h"

static CGFloat kLineWidth = 2;

@interface VideoRecordButton2 ()<CAAnimationDelegate>

@property (nonatomic, strong) CAShapeLayer *inCircleLayer;
@property (nonatomic, strong) CAShapeLayer *circleBorder;

@end




@implementation VideoRecordButton2

/**
 * UIButton,但是使用 initWithFrame初始化
 */
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialView];
    }
    return self;
}

- (void)initialView {
    //边框
    _circleBorder = [CAShapeLayer layer];
    _circleBorder.frame = self.bounds;
//    _circleBorder = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.width / 2, self.height / 2) radius:self.width / 2 startAngle:0 endAngle:M_PI * 2 clockwise:NO].CGPath;
    _circleBorder.borderWidth = kLineWidth;
    _circleBorder.borderColor = RGBACOLOR(255, 255, 255, 0.95).CGColor;
    _circleBorder.cornerRadius = self.width * 0.5;
    [self.layer addSublayer:_circleBorder];
    
    //内部圆形
    self.inCircleLayer = [CAShapeLayer layer];
//    _inCircleLayer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.width / 2, self.height/ 2) radius:(self.width - kLineWidth) / 2 - 5 startAngle:0 endAngle:M_PI * 2 clockwise:NO].CGPath;
    _inCircleLayer.frame = CGRectMake(kLineWidth + 2, kLineWidth + 2, self.width - (kLineWidth + 2) * 2, self.height - (kLineWidth + 2) * 2);
    _inCircleLayer.cornerRadius = _inCircleLayer.frame.size.width * 0.5;
    _inCircleLayer.backgroundColor = RGBACOLOR(255, 255, 255, 0.95).CGColor;
    [self.layer addSublayer:_inCircleLayer];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    float duration = 0.3;
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    NSMutableArray *values = [NSMutableArray array];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.9, 0.9, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.1, 1.1, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)]];
    animation.values = values;
    animation.duration = 0.3;
    [_circleBorder addAnimation:animation forKey:@"transform"];
    
    
    CABasicAnimation *animationRadius = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    animationRadius.fromValue = @(self.inCircleLayer.cornerRadius);
    
    CABasicAnimation *animationBounds = [CABasicAnimation animationWithKeyPath:@"bounds"];
    CGRect bounds = self.inCircleLayer.bounds;
    animationBounds.fromValue = [NSValue valueWithCGRect:bounds];
    animationBounds.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    animationRadius.duration = animationBounds.duration = duration;

    if(selected){
        animationRadius.toValue = @(5);
        
        bounds.size.width = self.bounds.size.width * 0.36;
        bounds.size.height = self.bounds.size.height * 0.36;
        animationBounds.toValue = [NSValue valueWithCGRect:bounds];
        
        self.inCircleLayer.cornerRadius = 5.0f;
        self.inCircleLayer.bounds = bounds;
        self.inCircleLayer.backgroundColor = [UIColor redColor].CGColor;
    } else {
        bounds.size.width = self.width - (kLineWidth + 2) * 2;
        bounds.size.height = self.height - (kLineWidth + 2) * 2;
        animationBounds.toValue = [NSValue valueWithCGRect:bounds];
        
        animationRadius.toValue = @(bounds.size.width / 2);
        
        self.inCircleLayer.cornerRadius = bounds.size.width * 0.5;
        self.inCircleLayer.bounds = bounds;
        self.inCircleLayer.backgroundColor = RGBACOLOR(255, 255, 255, 0.95).CGColor;
    }
    [self.inCircleLayer addAnimation:animationRadius forKey:@"cornerRadius"];
    [self.inCircleLayer addAnimation:animationBounds forKey:@"bounds"];
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.duration = duration;
    group.delegate = self;
    group.removedOnCompletion = YES;
    group.animations = @[animationBounds, animationRadius];
    [self.inCircleLayer addAnimation:group forKey:@"group"];
}

@end
