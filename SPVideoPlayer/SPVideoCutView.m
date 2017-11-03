//
//  SPVideoCutView.m
//  SPVideoPlayer
//
//  Created by leshengping on 17/8/2.  （https://github.com/SPStore/SPVideoPlayer
//  Copyright © 2017年 leshengping. All rights reserved.
//

#import "SPVideoCutView.h"
#import "SPVideoPlayer.h"

#define kScale 0.5
#define kLabelH 17
#define kPadding 5

@interface SPVideoCutView()
@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIImageView *cutImageView; // 截图imageView
@property (nonatomic, strong) UIImageView *cutSuccessIconView; // 截图成功了的小图标
@property (nonatomic, strong) UILabel *textLabel;
@end

@implementation SPVideoCutView

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
    [self addSubview:self.maskView];
    [self addSubview:self.cancelButton];
    [self addSubview:self.cutSuccessIconView];
    [self addSubview:self.textLabel];
    [self addSubview:self.cutImageView];
}

- (void)cancelButtonClicked:(UIButton *)button {
    if ([self.delegate respondsToSelector:@selector(cutViewCancelButtonClicked:)]) {
        [self.delegate cutViewCancelButtonClicked:button];
    }
}

- (void)setCutImage:(UIImage *)image {
    self.cutImageView.image = image;
    [UIView animateWithDuration:0.5 animations:^{
        self.cutImageView.transform = CGAffineTransformMakeScale(kScale, kScale);
    }];
}

- (void)setText:(NSString *)text {
    self.textLabel.text = text;
}

// 蒙板
- (UIView *)maskView {
    if (!_maskView) {
        _maskView = [[UIView alloc] init];
        _maskView.alpha = 0.618;
        _maskView.backgroundColor = [UIColor blackColor];
    }
    return _maskView;
}

// 截图imageView
- (UIImageView *)cutImageView {
    
    if (!_cutImageView) {
        _cutImageView = [[UIImageView alloc] init];
        _cutImageView.backgroundColor = [UIColor blackColor];
        _cutImageView.contentMode = UIViewContentModeScaleAspectFit;
        CGFloat cutImageViewH = ScreenHeight-kLabelH;
        CGFloat cutImageViewW = cutImageViewH*ScreenWidth/ScreenHeight;
        CGFloat cutImageViewX = (ScreenWidth-cutImageViewW)*0.5;
        CGFloat cutImageViewY = (ScreenHeight-cutImageViewH-kLabelH-kPadding)*0.5;
        _cutImageView.frame = CGRectMake(cutImageViewX, cutImageViewY, cutImageViewW, cutImageViewH);
    }
    return _cutImageView;
}

// 截图成功的小图标
- (UIImageView *)cutSuccessIconView {
    
    if (!_cutSuccessIconView) {
        _cutSuccessIconView = [[UIImageView alloc] init];
        _cutSuccessIconView.image = SPPlayerImage(@"VideoCutSuccess_17x17_");
    }
    return _cutSuccessIconView;
}


// 文字label
- (UILabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] init];
        _textLabel.font = [UIFont systemFontOfSize:13];
        _textLabel.textColor = [UIColor whiteColor];
    }
    return _textLabel;
}

// 取消按钮
- (UIButton *)cancelButton {
    
    if (!_cancelButton) {
        _cancelButton = [[UIButton alloc] init];
        [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
        _cancelButton.titleLabel.font = [UIFont systemFontOfSize:13];
        [_cancelButton addTarget:self action:@selector(cancelButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _cancelButton;
}


- (void)layoutSubviews {
    [super layoutSubviews];

    self.maskView.frame = self.bounds;
    
    CGFloat cutSuccessIconX = self.cutImageView.frame.origin.x;
    CGFloat cutSuccessIconY = CGRectGetMaxY(self.cutImageView.frame)+kPadding;
    CGFloat cutSuccessIconW = 17;
    CGFloat cutSuccessIconH = 17;
    self.cutSuccessIconView.frame = CGRectMake(cutSuccessIconX, cutSuccessIconY, cutSuccessIconW, cutSuccessIconH);
    
    CGFloat textLabelX = CGRectGetMaxX(self.cutSuccessIconView.frame)+3;
    CGFloat textLabelY = cutSuccessIconY;
    CGFloat textLabelW = 200;
    CGFloat textLabelH = kLabelH;
    self.textLabel.frame = CGRectMake(textLabelX, textLabelY, textLabelW, textLabelH);
    
    CGFloat cancelBtnX = 15;
    CGFloat cancelBtnY = 15;
    CGFloat cancelBtnW = 60;
    CGFloat cancelBtnH = 25;
    self.cancelButton.frame = CGRectMake(cancelBtnX, cancelBtnY, cancelBtnW, cancelBtnH);
    
}

@end
