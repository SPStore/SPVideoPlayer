//
//  SPVideoPlayerControlView.h
//  SPVideoPlayer
//
//  Created by leshengping on 17/7/12.  （https://github.com/SPStore/SPVideoPlayer
//  Copyright © 2017年 leshengping. All rights reserved.
//  控件层，装载播放\暂停按钮，进度条,返回按钮等

#import <UIKit/UIKit.h>
#import "SPVideoSlider.h"

@interface SPVideoPlayerControlView : UIView


@end

//-------------------------------------------------------------------------------------------------------------------------------------------------------

// 顶部的view
@interface SPVideoPlayerTopControlView : UIView

@property (nonatomic, strong) UIImageView *backgroundImageView; // 背景图
@property (nonatomic, strong) UIButton *backButton;      // 返回按钮
@property (nonatomic, strong) UILabel  *videoTitleLabel; // 视频标题
@property (nonatomic, strong) UIButton *downloadButton;  // 下载按钮

@end

//-------------------------------------------------------------------------------------------------------------------------------------------------------

// 底部的view
@interface SPVideoPlayerBottomControlView : UIView
@property (nonatomic, strong) UIImageView *backgroundImageView; // 背景图
@property (nonatomic, strong) UIButton *playOrPauseButton;  // 播放\暂停按钮
@property (nonatomic, strong) UIButton *nextButton;         // 下一集按钮
@property (nonatomic, strong) UILabel  *timeLabel;          // 全屏时将当前时间和总时间的合并为一个label
@property (nonatomic, strong) UILabel  *currentTimeLabel;   // 当前时间Label，小屏时显示
@property (nonatomic, strong) UILabel  *totalTimeLabel;     // 总时间Label，小屏时显示 
@property (nonatomic, strong) UIProgressView *progressView; // 缓冲进度条
@property (nonatomic, strong) SPVideoSlider *videoSlider; // 滑杆
@property (nonatomic, strong) UIButton *resolutionBtn;  // 分辨率按钮 
@property (nonatomic, strong) UIButton *fullScreenButton;   // 全屏按钮

@end

//-------------------------------------------------------------------------------------------------------------------------------------------------------

// 快进快退的view,快进快退时显示在中间
@interface SPVideoPlayerFastView : UIView
@property (nonatomic, strong) UIImageView *backgroundImageView; // 背景图
@property (nonatomic, strong) UILabel *fastTimeLabel;          // 时间
@property (nonatomic, strong) UIImageView *fastIconView;       // 快进快退的图标
@property (nonatomic, strong) UIImageView *fastVideoImageView; // 快进快退的视频图,横屏时显示
@property (nonatomic, strong) UIProgressView *fastProgressView; // 进度条,竖屏时显示

@end

//-------------------------------------------------------------------------------------------------------------------------------------------------------
// 占位view，如播放前，网络出错等会显示此view
@interface SPPlaceholderView : UIView

// 背景占位图
@property (nonatomic, strong) UIImageView *placeholderImageView;
// 提示label，如展示网络未连接的提示
@property (nonatomic, strong) UILabel *promptLabel;
// 刷新重试按钮
@property (nonatomic, strong) UIButton *refreshbutton;
// 全屏按钮和返回按钮在controlView上已经有了，但是当隐藏topView和bottomView时，要单独去显示返回按钮和全屏按钮不方便，所以在该view上另加
// 全屏按钮
@property (nonatomic, strong) UIButton *fullScreenButton;
// 返回按钮
@property (nonatomic, strong) UIButton *backButton;

// 占位图片
- (void)setPlaceholderImage:(UIImage *)image;
// label提示文字
- (void)setPromptLabelTitle:(NSString *)title;
// 按钮标题
- (void)setRefreshbuttonTitle:(NSString *)title;
// 按钮标题和小图标
- (void)setRefreshbuttonTitle:(NSString *)title image:(UIImage *)image;

@end





