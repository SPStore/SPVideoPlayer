//
//  SPVideoPopView.m
//  SPVideoPlayer
//
//  Created by leshengping on 17/8/28.  （https://github.com/SPStore/SPVideoPlayer
//  Copyright © 2017年 leshengping. All rights reserved.
//

#import "SPVideoPopView.h"
#import "SPVideoPlayer.h"

NSNotificationName const SPVideoPopViewWillShowNSNotification = @"SPVideoPopViewWillShowNSNotification";
NSNotificationName const SPVideoPopViewWillHideNSNotification = @"SPVideoPopViewWillHideNSNotification";

@interface SPVideoPopView()
@property (nonatomic, strong) SPVideoPopContentView *contentView;
@property (nonatomic, strong) UIView *customView;
@property (nonatomic, strong) UIButton *selectedButton;
@end

@implementation SPVideoPopView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
    }
    return self;
}

+ (instancetype)showVideoPopViewToView:(UIView *)view customView:(UIView *)customView {
    if (view == nil) {
        NSAssert(view, @"resolutionView的父视图为nil");
        return nil;
    }
    if (customView == nil) {
        NSAssert(customView, @"customView为nil");
        return nil;
    }
    
    SPVideoPopView *videoPopView = [[SPVideoPopView alloc] init];
    videoPopView.frame = CGRectMake(0, 0, view.bounds.size.width, view.bounds.size.height);
    videoPopView.backgroundColor = [UIColor clearColor];
    [view addSubview:videoPopView];
    
    SPVideoPopContentView *contentView = [[SPVideoPopContentView alloc] init];
    contentView.frame = customView.frame;
    [contentView addSubview:customView];
    [videoPopView addSubview:contentView];
    videoPopView.contentView = contentView;
    videoPopView.customView = customView;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SPVideoPopViewWillShowNSNotification object:nil];
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect contentViewFrame = contentView.frame;
        contentViewFrame.origin.x = videoPopView.bounds.size.width-contentView.bounds.size.width;
        contentView.frame = contentViewFrame;
    } completion:^(BOOL finished) {
    }];
    
    return videoPopView;
}

+ (void)hideVideoPopViewForView:(UIView *)view {
    
    SPVideoPopView *videoPopView = [self findVideoPopViewOnView:view];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SPVideoPopViewWillHideNSNotification object:nil];
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        CGRect contentViewFrame = videoPopView.contentView.frame;
        contentViewFrame.origin.x = videoPopView.bounds.size.width;
        videoPopView.contentView.frame = contentViewFrame;
    } completion:^(BOOL finished) {
        [videoPopView removeFromSuperview];
    }];
}


+ (instancetype)findVideoPopViewOnView:(UIView *)view {
    // 逆序枚举
    NSEnumerator *subviewsEnum = [view.subviews reverseObjectEnumerator];
    for (UIView *subview in subviewsEnum) {
        if ([subview isKindOfClass:self]) {
            return (SPVideoPopView *)subview;
        }
    }
    return nil;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    // 隐藏
    [SPVideoPopView hideVideoPopViewForView:self.superview];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.customView.frame = self.contentView.bounds;
}

@end

@implementation SPVideoPopContentView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    [self addSubview:self.backgroundImageView];
}

- (UIImageView *)backgroundImageView {
    
    if (!_backgroundImageView) {
        _backgroundImageView = [[UIImageView alloc] init];
        _backgroundImageView.image = SPPlayerImage(@"dolby_bubblebg_iphone_35x32_");
    }
    return _backgroundImageView;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.backgroundImageView.frame = self.bounds;
}


@end

