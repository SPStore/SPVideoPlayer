//
//  SPPlayerControlView.m
//
//  Created by leshengping on 17/7/12.  （https://github.com/SPStore/SPVideoPlayer
//  Copyright © 2017年 leshengping. All rights reserved.
//

#import "SPVideoPlayerControlView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "UIView+CustomControlView.h"
#import "SPVideoPlayer.h"
#import "SPVideoCutView.h"
#import "SPVideoPopView.h"
#import "SPLoadingHUD.h"
#import "UIImageView+WebCache.h"

#define kTopViewH 50
#define kBottomViewH 60

#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"

// 几秒后隐藏
static const CGFloat SPPlayerAnimationTimeInterval             = 7.0f;
// 显示controlView的动画时间
static const CGFloat SPPlayerControlBarAutoFadeOutTimeInterval = 0.35f;

@interface SPVideoPlayerControlView () <UIGestureRecognizerDelegate,SPVideoCutViewDelegate>
/** 占位图 */
@property (nonatomic, strong) SPPlaceholderView             *placeholderView;
/** 顶部view */
@property (nonatomic, strong) SPVideoPlayerTopControlView *topView;
/** 底部view */
@property (nonatomic, strong) SPVideoPlayerBottomControlView *bottomView;
/** 快进快退View*/
@property (nonatomic, strong) SPVideoPlayerFastView   *fastView;
/** 锁定屏幕方向按钮 */
@property (nonatomic, strong) UIButton                *lockBtn;
/** 视频截图按钮 */
@property (nonatomic, strong) UIButton                *cutBtn;
/** 关闭按钮*/
@property (nonatomic, strong) UIButton                *closeBtn;
/** 重播按钮 */
@property (nonatomic, strong) UIButton                *repeatBtn;
/** 选中的分辨率按钮 */
@property (nonatomic, strong) UIButton                *selectedResolutionButton;
/** 控制层消失时候在底部显示的播放进度progress */
@property (nonatomic, strong) UIProgressView          *bottomProgressView;
/** 播放资源模型 */
@property (nonatomic, strong) SPVideoItem      *videoItem;
/** 正在播放的视频url */
@property (nonatomic, copy) NSString *playingUrlString;

/** 显示控制层 */
@property (nonatomic, assign, getter=isShowing) BOOL  showing;
/** cell上播放player不可见时的小屏播放 */
@property (nonatomic, assign, getter=isShrink ) BOOL  shrink;
/** 在cell上播放 */
@property (nonatomic, assign, getter=isCellVideo)BOOL cellVideo;
/** 是否拖拽slider控制播放进度 */
@property (nonatomic, assign, getter=isDraggedBySlider) BOOL  draggedBySlider;
/** 是否播放结束 */
@property (nonatomic, assign, getter=isPlayEnd) BOOL  playeEnd;
/** 是否全屏播放 */
@property (nonatomic, assign,getter=isFullScreenMode) BOOL fullScreenMode;
/** 是否是截图之后才暂停的播放 */
@property (nonatomic, assign) BOOL pauseAfterCutting;

@property (nonatomic, strong) SPLoadingHUD *hud;
@end

@implementation SPVideoPlayerControlView

- (instancetype)init {
    self = [super init];
    if (self) {
                
        [self addSubview:self.placeholderView];
        [self addSubview:self.topView];
        [self addSubview:self.bottomView];
        [self addSubview:self.lockBtn];
        [self addSubview:self.cutBtn];
        [self addSubview:self.repeatBtn];
        [self addSubview:self.fastView];
        [self addSubview:self.closeBtn];
        [self addSubview:self.bottomProgressView];
        
        // 初始化时重置controlView
        [self sp_playerResetControlView];
        
        // 监听通知
        [self addNotifications];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

// 这个方法是当前自定义的view将要添加到新的视图上时调用，如果newSuperView为空，说明父视图为空
- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    // 如果newSuperview为空(self从旧的父视图中移除是newSuperview为空的原因之一)
    if (!newSuperview) {
        // 取消延时隐藏,如果不取消，当控制层是显示状态时，SPPlayerAnimationTimeInterval秒后会自动隐藏，如果还没到SPPlayerAnimationTimeInterval秒就直接退出了，程序会崩溃，所以在即将退出之时取消延时隐藏,不能在dealloc里面取消，因在在走dealloc之前就开始崩了
        [self sp_playerCancelAutoFadeOutControlView];
    }
}

- (void)addNotifications {
    // 监听播放状态的改变
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlayerStateChanged:) name:SPVideoPlayerStateChangedNSNotification object:nil];
    // 监听播放进度的改变
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlayerProgressValueChanged:) name:SPVideoPlayerProgressValueChangedNSNotification object:nil];
    // 视频播放进度将要跳转
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlayerWillJump:) name:SPVideoPlayerWillJumpNSNotification object:nil];
    // 视频播放进度条转完毕
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlayerDidJumped:) name:SPVideoPlayerDidJumpedNSNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlyerBufferProgressValueChanged:) name:SPVideoPlayerBufferProgressValueChangedNSNotification object:nil];
    // 监听视频截图
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cutVideoFinished:) name:SPVideoPlayerCutVideoFinishedNSNotification object:nil];
    // 监听媒体网络加载状态
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadStatusDidChanged:) name:SPVideoPlayerLoadStatusDidChangedNotification object:nil];
    // 监听videoPopView将要显示
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPopViewWillShow) name:SPVideoPopViewWillShowNSNotification object:nil];
    // 监听videoPopView将要隐藏
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPopViewWillHide) name:SPVideoPopViewWillHideNSNotification object:nil];
    // app退到后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
    // app进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayground) name:UIApplicationDidBecomeActiveNotification object:nil];
    // 监听设备旋转
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

#pragma mark - 通知方法
/** 播放状态发生了改变 */
- (void)videoPlayerStateChanged:(NSNotification *)notification {
    
    SPVideoPlayerPlayState state = [notification.userInfo[@"playState"] integerValue];
    // 上次停止播放的时间点(单位:s)
    CGFloat seekTime = [notification.userInfo[@"seekTime"] floatValue];
    // 转化为分钟
    double minutesElapsed = floorf(fmod(seekTime, 60.0*60.0)/60.0) ;
    
    switch (state) {
        case SPVideoPlayerPlayStateReadyToPlay:    // 准备播放
            self.placeholderView.alpha = 1;
            if (seekTime && minutesElapsed >= 1) {
                [self.placeholderView setPromptLabelTitle:[NSString stringWithFormat:@"上次观看至%.0f分钟,正在续播",minutesElapsed]];
            } else {
                [self.placeholderView setPromptLabelTitle:@"即将播放"];
                
            }
            break;
        case SPVideoPlayerPlayStatePlaying:        // 正在播放
        {
            [self hideHUD];
            self.placeholderView.alpha = 0;
            self.bottomView.playOrPauseButton.selected = YES;
            [self sp_playerCancelAutoFadeOutControlView];
            // 先取消原来的延迟隐藏，再重新显示延迟隐藏
            if (self.showing) {
                [self sp_playerShowControlView];
            }
        }
            break;
        case SPVideoPlayerPlayStatePause:          // 暂停播放
            self.bottomView.playOrPauseButton.selected = NO;
            [self sp_playerCancelAutoFadeOutControlView];
            break;
        case SPVideoPlayerPlayStateBuffering:      // 缓冲中
            self.placeholderView.alpha = 0;
            // 显示加载指示器
            [self showHUDWithTitle:@"正在全力加载..."];
            break;
        case SPVideoPlayerPlayStateBufferSuccessed: // 缓冲成功
            //[self hideHUD];
            break;
        case SPVideoPlayerPlayStateEndedPlay:      // 播放结束
        {
            [self hideHUD];
            self.repeatBtn.hidden = NO;
            self.playeEnd         = YES;
            self.showing          = NO;
            // 隐藏controlView
            [self hideControlView];
            self.backgroundColor  = RGBA(0, 0, 0, .3);
            SPPlayerShared.isStatusBarHidden = NO;
            self.bottomProgressView.alpha = 0;
        }
            break;
        default:
            break;
    }
}

/** 播放进度发生了改变 */
- (void)videoPlayerProgressValueChanged:(NSNotification *)notification {
    // 当前时间
    CGFloat currentTime = [notification.userInfo[@"currentTime"] floatValue];
    // 总时间
    CGFloat totalTime = [notification.userInfo[@"totalTime"] floatValue];
    // 当前时间与总时间之比
    CGFloat value = [notification.userInfo[@"value"] floatValue];
    // 进度状态，分为自然状态、快进状态、快退状态
    SPVideoPlayerPlayProgressState playProgressState = [notification.userInfo[@"playProgressState"] integerValue];
    // 是否要求显示快进快退时的预览图
    BOOL requirePreviewView = [notification.userInfo[@"requirePreviewView"] integerValue];
    
    // 秒数转时分秒
    double current_hours = floorf(currentTime/(60.0*60.0));
    double current_minutes = floorf(fmod(currentTime, 60.0*60.0)/60.0);
    double current_seconds = fmod(currentTime, 60.0);
    
    double total_hours = floorf(totalTime/(60.0*60.0));
    double total_minutes = floorf(fmod(totalTime, 60.0*60.0)/60.0);;
    double total_seconds = fmod(totalTime, 60.0);
    
    NSString *currentTimeString;
    // 更新slider
    if (!self.draggedBySlider) { // 如果是因为滑动slider而导致的快进或快退，则可以不用更新slider的值，如果不加判断,当滑动slider时，就更新了2次slider()。如果2次更新在同一线程上，可以不用加此判断，如果在不同线程上，不加判断slider的跟踪按钮会有小小的闪跳(这里可不加，加了更好)
        self.bottomView.videoSlider.value       = value;
        self.bottomProgressView.progress = value;
    }
    
    // 更新slider
    if (current_hours > 0) {
        if (current_hours < 1) {
            current_hours = 0.00;
        }
        currentTimeString = [NSString stringWithFormat:@"%02.0f:%02.0f:%02.0f", current_hours, current_minutes, current_seconds];
    } else {
        
        if (current_minutes < 1) {
            current_minutes = 0.00;
        }
        currentTimeString = [NSString stringWithFormat:@"%02.0f:%02.0f", current_minutes, current_seconds];
    }
    
    NSString *totalTimeString;
    if (total_hours > 0) {
        if (total_hours < 1) {
            total_hours = 0.00;
        }
        totalTimeString = [NSString stringWithFormat:@"%02.0f:%02.0f:%02.0f", total_hours, total_minutes, total_seconds];
    } else {
        if (total_minutes < 1) {
            total_minutes = 0.00;
        }
        totalTimeString = [NSString stringWithFormat:@"%02.0f:%02.0f", total_minutes, total_seconds];
    }
    
    if (!self.fullScreenMode) { // 非全屏
        // 更新当前播放时间
        self.bottomView.currentTimeLabel.text       = currentTimeString;
        // 更新总时间
        self.bottomView.totalTimeLabel.text = totalTimeString;
    } else { // 全屏
        if (currentTimeString) {
            self.bottomView.timeLabel.text = [NSString stringWithFormat:@"%@/%@",currentTimeString,totalTimeString];
        }
    }
    
    if (playProgressState != SPVideoPlayerPlayProgressStateNomal) { // 快进或快退状态
        // 隐藏"菊花"指示器
        [self hideHUD];
        self.fastView.fastProgressView.progress = value;
        // 是否要求显示快进快退的view
        self.fastView.hidden = !requirePreviewView;
        [self sp_playerCancelAutoFadeOutControlView];
        if (self.showing) {
            [self showControlView];
        }
        NSMutableAttributedString *timeAttString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@/%@",currentTimeString,totalTimeString]];
        [timeAttString addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:NSMakeRange(0, currentTimeString.length)];
        self.fastView.fastTimeLabel.attributedText = timeAttString;
        if (playProgressState == SPVideoPlayerPlayProgressStateFastForward) { // 快进
            self.fastView.fastIconView.image = SPPlayerImage(@"player_progress_r_full_iphone_45x45_");
        } else { // 快退
            self.fastView.fastIconView.image = SPPlayerImage(@"player_progress_l_full_iphone_45x45_");
        }
        // 设置快进快退时滑动条高亮
        if (self.fullScreenMode) {
            self.bottomView.videoSlider.thumbBackgroundImage = SPPlayerImage(@"qyplayer_aura2_full_sliderHalo_iphone_108x108_");
        } else {
            self.bottomView.videoSlider.thumbBackgroundImage = SPPlayerImage(@"qyplayer_aura2_mini_sliderHalo_iphone_85x85_");

        }
    }
}

/** 视频播放进度将要发生真实跳转，此时也正是快进快退刚结束 */
- (void)videoPlayerWillJump:(NSNotification *)noti {
    // 隐藏快进快退的view
    self.fastView.hidden = YES;
}

/** 视频播放进度结束跳转 */
- (void)videoPlayerDidJumped:(NSNotification *)noti {
    
    // 滑动结束延时隐藏controlView
    [self autoFadeOutControlView];
    
    self.bottomView.videoSlider.thumbBackgroundImage = nil;
}

/** 缓冲进度发生了改变 */
- (void)videoPlyerBufferProgressValueChanged:(NSNotification *)noti {
    CGFloat bufferProgress = [noti.userInfo[@"bufferProgress"] floatValue];
    [self.bottomView.progressView setProgress:bufferProgress];
}

/** 监听视频截图 */
- (void)cutVideoFinished:(NSNotification *)noti {
    UIImage *image = noti.object;
    if (self.bottomView.playOrPauseButton.selected) { // 说明是播放状态
        [self playOrPauseButtonAction:self.bottomView.playOrPauseButton]; // 暂停
        // 截图之后才暂停的标识
        self.pauseAfterCutting = YES;
    }
    [self sp_playerHideControlView];
    
    SPVideoCutView *cutView = [[SPVideoCutView alloc] init];
    cutView.delegate = self;
    cutView.frame = self.bounds;
    [self addSubview:cutView];
    
    UIImageWriteToSavedPhotosAlbum(image,nil, nil,nil);
    
    [cutView setCutImage:image];
    [cutView setText:@"已保存到系统相册"];
}

/** 监听媒体网络加载状态 */
- (void)loadStatusDidChanged:(NSNotification *)noti {
    SPVideoPlayerLoadStatus status = [noti.userInfo[@"loadStatus"] integerValue];
    BOOL bufferEmpty = [noti.userInfo[@"bufferEmpty"] boolValue];
    switch (status) {
        case SPVideoPlayerLoadStatusNotReachable:
            NSLog(@"无网络");
            if (bufferEmpty) { // 无网络且缓存为空
                [self hideHUD];
                [self.placeholderView setPromptLabelTitle:@"网络未连接，请检查网络设置"];
                [self.placeholderView setRefreshbuttonTitle:@"刷新重试" image:SPPlayerImage(@"play_rePlay_mini_12x12_")];
                self.placeholderView.alpha = 1;
                [self hideControlView];
            }
            break;
        case SPVideoPlayerLoadStatusReachableViaWWAN:{
            
            NSLog(@"手机流量");
        }
            break;
        case SPVideoPlayerLoadStatusReachableViaWiFi:{
            
             //self.placeholderView.alpha = 0;
            
        }
            NSLog(@"WiFi");
            break;
        case SPVideoPlayerLoadStatusUnknown:
            NSLog(@"未知");
            break;
        case SPVideoPlayerLoadStatusAbnormal:
            [self hideHUD];
            [self.placeholderView setPromptLabelTitle:@"网络异常，请检查网络连接"];
            self.placeholderView.alpha = 1;
            NSLog(@"网络异常");
            break;
            
        default:
            break;
    }
}

/**
 *  应用退到后台
 */
- (void)appDidEnterBackground {
    [self sp_playerCancelAutoFadeOutControlView];
}

/**
 *  应用进入前台
 */
- (void)appDidEnterPlayground {
    if (!self.isShrink && (self.placeholderView.alpha<0.01 || self.placeholderView.hidden == YES)){
        [self sp_playerShowControlView];
    }
}

/**
 *  屏幕方向发生变化会调用这里
 */
- (void)onDeviceOrientationChange {
    [self setNeedsLayout];
    if (SPPlayerShared.isLockScreen) { return; }
    self.lockBtn.hidden         = !self.isFullScreenMode;
    self.cutBtn.hidden          = !self.isFullScreenMode;
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIDeviceOrientation currentOrientation = (UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation;
    if (orientation == currentOrientation || orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown || orientation == UIDeviceOrientationPortraitUpsideDown) { return; }
    if (!self.isShrink && !self.isPlayEnd && self.showing) {
        [self sp_playerCancelAutoFadeOutControlView];
        // 隐藏控制层
        [self sp_playerHideControlView];
    }
}

/**
 *  分辨率的view将要显示
 */
- (void)videoPopViewWillShow {
    self.bottomView.resolutionBtn.selected = YES;
    [self hideControlView];
}

/**
 *  分辨率的view将要隐藏
 */
- (void)videoPopViewWillHide {
    self.bottomView.resolutionBtn.selected = NO;
    [self sp_playerShowControlView];
}

#pragma mark - 控制层上的各个控件的事件触发方法

// 播放或暂停按钮的触发方法
- (void)playOrPauseButtonAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if ([self.delegate respondsToSelector:@selector(sp_controlViePlayOrPauseButtonClicked:)]) {
        [self.delegate sp_controlViePlayOrPauseButtonClicked:sender];
    }
    // 取消延时隐藏controlView,如果在这里不取消，则SPPlayerAnimationTimeInterval秒后controlView会自动隐藏，而我要的效果是点击了播放暂停按钮后，永远不隐藏
    [self sp_playerCancelAutoFadeOutControlView];
}

// 下一个视频按钮的触发方法
- (void)nextButtonAction:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(sp_controlViewNextButtonClicked:)]) {
        [self.delegate sp_controlViewNextButtonClicked:sender];
    }
}

// 全屏按钮的触发方法
- (void)fullScreenButtonAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if ([self.delegate respondsToSelector:@selector(sp_controlViewFullScreenButtonClicked:)]) {
        [self.delegate sp_controlViewFullScreenButtonClicked:sender];
    }
}

// bottomView上的分辨率按钮的触发方法
- (void)resolutionButtonAction:(UIButton *)sender {
    
    if (!sender.selected) {
        static UIView *buttonView = nil;
        if (buttonView == nil) {
            buttonView = [[UIView alloc] init];
            // x值给屏幕的宽度，这样显示的时候才会从右边弹出
            buttonView.frame = CGRectMake(self.bounds.size.width, 0, self.bounds.size.width*0.45, self.bounds.size.height);
            
            NSDictionary *resolutionDic = self.videoItem.resolutionDic;
            
            CGFloat padding = 10;
            CGFloat buttonX = 30;
            CGFloat buttonW = buttonView.bounds.size.width-2*buttonX;
            CGFloat buttonH = 30;
            CGFloat buttonY = (buttonView.bounds.size.height-(resolutionDic.count*buttonH+(resolutionDic.count-1)*buttonH))*0.5;
            NSInteger count = resolutionDic.count;
            for (int i = 0; i < count; i++) {
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                button.frame = CGRectMake(buttonX, buttonY+(buttonH+padding)*i, buttonW, buttonH);
                [button setTitle:resolutionDic.allKeys[i] forState:UIControlStateNormal];
                button.titleLabel.font = [UIFont systemFontOfSize:15];
                [button setTitleColor:[UIColor greenColor] forState:UIControlStateHighlighted];
                [button setTitleColor:[UIColor greenColor] forState:UIControlStateSelected];
                button.titleLabel.textAlignment = NSTextAlignmentCenter;
                button.tag = i + 200;
                [button addTarget:self action:@selector(resolutionCategoryButtonAction:) forControlEvents:UIControlEventTouchUpInside];
                [buttonView addSubview:button];
            }
            // 获取模型中的url在分辨率字典中的下标
            NSInteger idx = [self.videoItem.resolutionDic.allValues indexOfObject:self.playingUrlString];
            // 默认选中哪个按钮
            UIButton *defaultSelectedButton = buttonView.subviews[idx];
            defaultSelectedButton.selected = YES;
            self.selectedResolutionButton = defaultSelectedButton;
        } else {
            // x值给屏幕的宽度，这样显示的时候才会从右边弹出
            buttonView.frame = CGRectMake(self.bounds.size.width, 0, self.bounds.size.width*0.45, self.bounds.size.height);
        }
        // 该方法会把SPVideoPopView添加到self上，把buttonView添加到SPVideoPopView上
        [SPVideoPopView showVideoPopViewToView:self customView:buttonView];
        
    } else {
        // 隐藏SPVideoPopView
        [SPVideoPopView hideVideoPopViewForView:self];
    }
    sender.selected = !sender.selected;
}

// SPVideoPopView上的分辨率按钮的触发方法，如高清,标清,1080P等
- (void)resolutionCategoryButtonAction:(UIButton *)sender {
    [self.bottomView.resolutionBtn setTitle:sender.titleLabel.text forState:UIControlStateNormal];
    // 选中按钮设置颜色
    self.selectedResolutionButton.selected = NO;
    sender.selected = YES;
    self.selectedResolutionButton = sender;
    // 隐藏videwPopView
    [SPVideoPopView hideVideoPopViewForView:self];
    // 执行代理方法
    if ([self.delegate respondsToSelector:@selector(sp_controlViewSwitchResolutionWithUrl:)]) {
        [self.delegate sp_controlViewSwitchResolutionWithUrl:self.videoItem.resolutionDic.allValues[sender.tag-200]];
    }
}

// 滑动条开始滑动
- (void)videoSliderTouchBegan:(UISlider *)sender {
    [self sp_playerCancelAutoFadeOutControlView];
    if ([self.delegate respondsToSelector:@selector(sp_controlViewSliderTouchBegan:)]) {
        [self.delegate sp_controlViewSliderTouchBegan:sender];
    }
}

// 滑动条正在滑动
- (void)videoSliderValueChanged:(UISlider *)sender {
    
    self.draggedBySlider = YES;
    
    if ([self.delegate respondsToSelector:@selector(sp_controlViewSliderValueChanged:)]) {
        [self.delegate sp_controlViewSliderValueChanged:sender];
    }
}

// 滑动条滑动结束
- (void)videoSliderTouchEnded:(UISlider *)sender {
    self.showing = YES;
    self.draggedBySlider = NO;
    if ([self.delegate respondsToSelector:@selector(sp_controlViewSliderTouchEnded:)]) {
        [self.delegate sp_controlViewSliderTouchEnded:sender];
    }
}

// 单击滑动条，点哪儿就播放哪儿
- (void)tapSliderAction:(UITapGestureRecognizer *)tap {
    if ([tap.view isKindOfClass:[UISlider class]]) {
        UISlider *slider = (UISlider *)tap.view;
        CGPoint point = [tap locationInView:slider];
        CGFloat length = slider.frame.size.width;
        // 视频跳转的value
        CGFloat tapValue = point.x / length;
        if ([self.delegate respondsToSelector:@selector(sp_controlViewSliderTaped:)]) {
            [self.delegate sp_controlViewSliderTaped:tapValue];
        }
    }
}

// 不做处理，只是为了滑动slider其他地方不响应其他手势
- (void)panRecognizer:(UIPanGestureRecognizer *)sender {}

// 返回按钮的触发方法
- (void)backButtonAction:(UIButton *)sender {
    // 状态条的方向旋转的方向,来判断当前屏幕的方向
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    // 在cell上并且是竖屏时候响应关闭事件
    if (self.isCellVideo && orientation == UIInterfaceOrientationPortrait) {
        if ([self.delegate respondsToSelector:@selector(sp_controlViewCloseButtonClicked:)]) {
            [self.delegate sp_controlViewCloseButtonClicked:sender];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(sp_controlViewBackButtonClicked:)]) {
            [self.delegate sp_controlViewBackButtonClicked:sender];
        }
    }
}

// 下载按钮的触发方法
- (void)downloadButtonAction:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(sp_controlViewDownloadButtonClicked:)]) {
        [self.delegate sp_controlViewDownloadButtonClicked:sender];
    }
}


// 锁屏按钮的触发方法
- (void)lockScrrenButtonAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.showing = NO;
    [self sp_playerShowControlView];
    if ([self.delegate respondsToSelector:@selector(sp_controlViewLockScreenButtonClicked:)]) {
        [self.delegate sp_controlViewLockScreenButtonClicked:sender];
    }
}

// 截图的按钮触发方法
- (void)cutButtonAction:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(sp_controlViewCutButtonClicked:)]) {
        [self.delegate sp_controlViewCutButtonClicked:sender];
    }
}

// 关闭按钮的触发方法（就是cell上播放视频时，小屏播放时右上角的小叉叉）
- (void)closeButtonAction:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(sp_controlViewCloseButtonClicked:)]) {
        [self.delegate sp_controlViewCloseButtonClicked:sender];
    }
}

// 重播按钮的触发方法
- (void)repeatButtonnAction:(UIButton *)sender {
    // 重置控制层View
    [self sp_playerResetControlView];
    [self sp_playerShowControlView];
    if ([self.delegate respondsToSelector:@selector(sp_controlViewRepeatButtonClicked:)]) {
        [self.delegate sp_controlViewRepeatButtonClicked:sender];
    }
}

// 刷新重试
- (void)refreshButtonAction:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(sp_controlViewRefreshButtonClicked:)]) {
        [self.delegate sp_controlViewRefreshButtonClicked:sender];
    }
}

#pragma mark - 显示和隐藏控制层

// 显示控制层,不含动画
- (void)showControlView {
    self.showing = YES;
    if (self.lockBtn.isSelected) {

        self.topView.alpha = 0;
        self.bottomView.alpha = 0;
        self.cutBtn.alpha = 0;
        
    } else {
        self.topView.alpha = 1;
        self.bottomView.alpha = 1;
        if (self.isFullScreenMode) {
          self.cutBtn.alpha = 1;
        }
    }
    self.lockBtn.alpha             = 1;
    if (self.isCellVideo) {
        self.shrink                = NO;
    }
    self.bottomProgressView.alpha  = 0;
    SPPlayerShared.isStatusBarHidden = NO;
}

// 隐藏控制层，不含动画
- (void)hideControlView {
    self.showing = NO;
    self.topView.alpha       = self.playeEnd;
    self.bottomView.alpha    = 0;
    self.lockBtn.alpha       = 0;
    self.cutBtn.alpha        = 0;
    self.bottomProgressView.alpha = 1;
    if (self.isFullScreenMode && !self.playeEnd && !self.isShrink) {
        SPPlayerShared.isStatusBarHidden = YES;
    }
}

// SPPlayerAnimationTimeInterval秒后自动隐藏
- (void)autoFadeOutControlView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sp_playerHideControlView) object:nil];
    [self performSelector:@selector(sp_playerHideControlView) withObject:nil afterDelay:SPPlayerAnimationTimeInterval];
}

// 显示控制层,SPPlayerAnimationTimeInterval秒后自动隐藏
- (void)sp_playerShowControlView {
    if ([self.delegate respondsToSelector:@selector(sp_controlViewWillShow:isFullscreen:)]) {
        [self.delegate sp_controlViewWillShow:self isFullscreen:self.isFullScreenMode];
    }
    [self sp_playerCancelAutoFadeOutControlView];
    [UIView animateWithDuration:SPPlayerControlBarAutoFadeOutTimeInterval animations:^{
        [self showControlView];
    } completion:^(BOOL finished) {
        self.showing = YES;
        [self autoFadeOutControlView];
    }];
}

// 隐藏控制层,含动画
- (void)sp_playerHideControlView {
    if ([self.delegate respondsToSelector:@selector(sp_controlViewWillHidden:isFullscreen:)]) {
        [self.delegate sp_controlViewWillHidden:self isFullscreen:self.isFullScreenMode];
    }
    [self sp_playerCancelAutoFadeOutControlView];
    [UIView animateWithDuration:SPPlayerControlBarAutoFadeOutTimeInterval animations:^{
        [self hideControlView];
    } completion:^(BOOL finished) {
        self.showing = NO;
    }];
}

// 取消延时隐藏controlView的方法
- (void)sp_playerCancelAutoFadeOutControlView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sp_playerHideControlView) object:nil];
}

#pragma mark - setter

- (void)setShrink:(BOOL)shrink {
    _shrink = shrink;
    self.closeBtn.hidden = !shrink;
    self.bottomProgressView.hidden = shrink;
}

- (void)setFullScreenMode:(BOOL)fullScreenMode {
    _fullScreenMode = fullScreenMode;
    SPPlayerShared.isLandscape = fullScreenMode;
}

#pragma mark - SPVideoCutViewDelegate

- (void)cutViewCancelButtonClicked:(UIButton *)button {
    // 如果是截图之后才暂停的，说明截图之前是播放状态
    if (self.pauseAfterCutting) {
        // 恢复截图之前的播放状态
        [self playOrPauseButtonAction:self.bottomView.playOrPauseButton];
    }
    self.pauseAfterCutting = NO;
    
    SPVideoCutView *cutView = (SPVideoCutView *)button.superview;
    [cutView removeFromSuperview];
    cutView = nil;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGRect rect = [self thumbRect];
    CGPoint point = [touch locationInView:self.bottomView.videoSlider];
    if ([touch.view isKindOfClass:[UISlider class]]) { // 如果在滑块上点击就不响应pan手势
        if (point.x <= rect.origin.x + rect.size.width && point.x >= rect.origin.x) { return NO; }
    }
    return YES;
}

// 获取滑动条的bounds
- (CGRect)thumbRect {
    return [self.bottomView.videoSlider thumbRectForBounds:self.bottomView.videoSlider.bounds
                                                 trackRect:[self.bottomView.videoSlider trackRectForBounds:self.bottomView.videoSlider.bounds]
                                                     value:self.bottomView.videoSlider.value];
}

/**
 *  显示加载指示器
 */
- (void)showHUDWithTitle:(NSString *)title {
    if (!self.hud) {
        SPLoadingHUD *hud = [SPLoadingHUD showHUDWithTitle:title toView:self animated:YES];
        hud.activityIndicatorPosition = SPActivityIndicatorPositionLeft;
        hud.bezelView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        hud.bezelView.style = SPLoadingHUDBackgroundStyleSolidColor;
        hud.bezelView.appearance = SPLoadingHUDAppearanceCircle;
        hud.minSize = CGSizeMake(170, 30);
        hud.contentColor = [UIColor whiteColor];
        // 在SPVideoPlayerView中设置了它里面的手势处于一切controlView的子控件中均屏蔽,所以点击HUD时无法触发SPVideoPlayerView的手势，解决办法是设置hud.userInteractionEnabled = NO;
        // 还有一个解决办法是在SPVideoPlayerView的-(BOOL)gestureRecognizer:shouldReceiveTouch:代理方法中特别指定如果手势的view是SPLoadingHUD，返回YES，但是不建议此方法，因为这样增强了SPVideoPlayerView和controlView的耦合性，这次用的是SPLoadingHUD，下次换一个指示器，又得改.
        hud.userInteractionEnabled = NO;
        self.hud = hud;
    }
    
}

/**
 *  隐藏指示器
 */
- (void)hideHUD {
    [SPLoadingHUD hideHUDForView:self animated:YES];
    self.hud = nil;
}

#pragma mark - 公共方法

/** 此方法可以得到播放模型 */
- (void)sp_setPlayerItem:(SPVideoItem *)videoItem playingUrlString:(NSString *)playingUrlString {
    
    self.videoItem = videoItem;
    self.playingUrlString = playingUrlString;
    
    if (videoItem.title) { self.topView.videoTitleLabel.text = videoItem.title; }
    [self.placeholderView setPlaceholderImage:videoItem.placeholderImage];
    self.bottomView.resolutionBtn.hidden = !videoItem.resolutionDic.count;
    // 显示分辨率按钮的标题
    [videoItem.resolutionDic.allValues enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:playingUrlString]) {
            [self.bottomView.resolutionBtn setTitle:videoItem.resolutionDic.allKeys[idx] forState:UIControlStateNormal];
        }
    }];
    
    if (!videoItem.shouldAutorotate) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    }
}

/** 重置ControlView,还原设置 */
- (void)sp_playerResetControlView {
    [self hideHUD];
    self.bottomView.videoSlider.value           = 0;
    self.bottomProgressView.progress = 0;
    self.bottomView.progressView.progress       = 0;
    self.bottomView.currentTimeLabel.text       = @"00:00";
    self.bottomView.totalTimeLabel.text         = @"00:00";
    self.fastView.hidden             = YES;
    self.repeatBtn.hidden            = YES;
    self.backgroundColor             = [UIColor clearColor];
    self.topView.downloadButton.enabled         = YES;
    self.shrink                      = NO;
    self.showing                     = NO;
    self.playeEnd                    = NO;
    self.lockBtn.hidden              = !self.isFullScreenMode;
    self.cutBtn.hidden               = !self.isFullScreenMode;
    self.placeholderView.alpha  = 1;
    // 默认隐藏controlView
    [self hideControlView];
}

/** 单击播放器显示还是隐藏控制层 */
- (void)sp_playerShowOrHideControlView {
    
    if (self.isShowing) {
        [self sp_playerHideControlView];
    } else {
        [self sp_playerShowControlView];
    }
}

/** 快进快退时的预览视图 */
- (void)sp_playerDraggedWithThumbImage:(UIImage *)thumbImage {
    self.fastView.fastVideoImageView.image = thumbImage;
}

/** 在cell播放 */
- (void)sp_playerCellPlay {
    self.cellVideo = YES;
    self.shrink    = NO;
    [self.topView.backButton setImage:SPPlayerImage(@"play_close_30x30_") forState:UIControlStateNormal];
    self.placeholderView.backButton.hidden = YES;
}

/** 小屏播放 */
- (void)sp_playerBottomShrinkPlay {
    self.shrink = YES;
    [self hideControlView];
}

/**
 是否有下载功能
 */
- (void)sp_playerHasDownloadFunction:(BOOL)sender {
    self.topView.downloadButton.hidden = !sender;
}

/** 下载按钮状态 */
- (void)sp_playerDownloadBtnState:(BOOL)state {
    self.topView.downloadButton.enabled = state;
}

/** 锁定屏幕方向按钮状态 */
- (void)sp_playerLockBtnState:(BOOL)state {
    self.lockBtn.selected = state;
}


#pragma mark - lazy

/** 背景图,在播放前会显示 */
- (SPPlaceholderView *)placeholderView {
    
    if (!_placeholderView) {
        _placeholderView = [[SPPlaceholderView alloc] init];
        _placeholderView.contentMode = UIViewContentModeScaleAspectFill;
        _placeholderView.layer.masksToBounds = YES;
        // 刷新重试
        [_placeholderView.refreshbutton addTarget:self action:@selector(refreshButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        // 返回
        [_placeholderView.backButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        // 全屏
        [_placeholderView.fullScreenButton addTarget:self action:@selector(fullScreenButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _placeholderView;
}


/** 顶部的view */
- (SPVideoPlayerTopControlView *)topView {
    
    if (!_topView) {
        _topView = [[SPVideoPlayerTopControlView alloc] init];
        [_topView.backButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [_topView.downloadButton addTarget:self action:@selector(downloadButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _topView;
}


/** 底部的view */
- (SPVideoPlayerBottomControlView *)bottomView {
    
    if (!_bottomView) {
        _bottomView = [[SPVideoPlayerBottomControlView alloc] init];
        [_bottomView.playOrPauseButton addTarget:self action:@selector(playOrPauseButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [_bottomView.nextButton addTarget:self action:@selector(nextButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        // slider开始滑动事件
        [_bottomView.videoSlider addTarget:self action:@selector(videoSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
        // slider滑动中事件
        [_bottomView.videoSlider addTarget:self action:@selector(videoSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        // slider结束滑动事件
        [_bottomView.videoSlider addTarget:self action:@selector(videoSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
        
        UITapGestureRecognizer *sliderTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSliderAction:)];
        [_bottomView.videoSlider addGestureRecognizer:sliderTap];
        
        UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panRecognizer:)];
        panRecognizer.delegate = self;
        [panRecognizer setMaximumNumberOfTouches:1];
        [panRecognizer setDelaysTouchesBegan:YES];
        [panRecognizer setDelaysTouchesEnded:YES];
        [panRecognizer setCancelsTouchesInView:YES];
        [_bottomView.videoSlider addGestureRecognizer:panRecognizer];
        
        [_bottomView.resolutionBtn addTarget:self action:@selector(resolutionButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        [_bottomView.fullScreenButton addTarget:self action:@selector(fullScreenButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _bottomView;
}

/** 快进快退的view */
- (SPVideoPlayerFastView *)fastView {
    if (!_fastView) {
        _fastView                     = [[SPVideoPlayerFastView alloc] init];
        _fastView.backgroundColor     = RGBA(0, 0, 0, 0.618);
        _fastView.layer.cornerRadius  = 10;
        _fastView.layer.masksToBounds = YES;
    }
    return _fastView;
}

/** 锁屏按钮 */
- (UIButton *)lockBtn {
    if (!_lockBtn) {
        _lockBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_lockBtn setImage:SPPlayerImage(@"player_lockScreen_off_iphone_44x44_") forState:UIControlStateNormal];
        [_lockBtn setImage:SPPlayerImage(@"player_lockScreen_on_iphone_44x44_") forState:UIControlStateSelected];
        [_lockBtn addTarget:self action:@selector(lockScrrenButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _lockBtn;
}

/** 截图视频按钮 */
- (UIButton *)cutBtn {
    if (!_cutBtn) {
        _cutBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cutBtn setImage:SPPlayerImage(@"player_full_videoCut_iphone_44x44_") forState:UIControlStateNormal];
        [_cutBtn setImage:SPPlayerImage(@"player_full_videoCut_h_iphone_44x44_") forState:UIControlStateSelected];
        [_cutBtn addTarget:self action:@selector(cutButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cutBtn;
}

/** 重播按钮 */
- (UIButton *)repeatBtn {
    if (!_repeatBtn) {
        _repeatBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_repeatBtn setBackgroundImage:SPPlayerImage(@"play_rePlay_mini_12x12_") forState:UIControlStateNormal];
        [_repeatBtn addTarget:self action:@selector(repeatButtonnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _repeatBtn;
}

/** 关闭按钮 */
- (UIButton *)closeBtn {
    if (!_closeBtn) {
        _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeBtn setImage:SPPlayerImage(@"play_close_30x30_") forState:UIControlStateNormal];
        [_closeBtn addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _closeBtn.hidden = YES;

    }
    return _closeBtn;
}

/** 最底部的进度条 */
- (UIProgressView *)bottomProgressView {
    if (!_bottomProgressView) {
        _bottomProgressView                   = [[UIProgressView alloc] init];
        _bottomProgressView.progressTintColor = [UIColor whiteColor];
        _bottomProgressView.trackTintColor    = [UIColor clearColor];
    }
    return _bottomProgressView;
}

/** 关闭按钮有一部分不在父控件之内，重写该方法让超出的那部分仍然能点击 */
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (view == nil) {
        CGPoint tempoint = [self.closeBtn convertPoint:point fromView:self];
        if (CGRectContainsPoint(self.closeBtn.bounds, tempoint))
        {
            if (self.alpha >= 0.01) {
                view = self.closeBtn;
            }
        }
    }
    return view;
}

#warning Todo 跳转结束后总是卡一下才正式播放；左滑返回时到一半就开始旋转有问题(正在滑动返回禁止旋转),网络请求超时30秒，(网络异常，请检查网络连接);考虑一下cell上播放时去掉即将播放的提示,改为准备播放;有时视频seekToTime后，block走完了，但是视频定住了，而且没走timeObserve的block..几个block不会调就退出的强引用问题.....定时器还没触发方法就开始退出的问题


#pragma mark - 布局

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat selfW = self.bounds.size.width;
    CGFloat selfH = self.bounds.size.height;
    
    self.placeholderView.frame = self.bounds;
    
    self.lockBtn.frame = CGRectMake(15, 0, 40, 40);
    CGPoint lockBtnCenter = self.lockBtn.center;
    lockBtnCenter.y = self.center.y;
    self.lockBtn.center = lockBtnCenter;
    
    self.cutBtn.frame = CGRectMake(selfW-55, 0, 40, 40);
    CGPoint cutBtnCenter = self.cutBtn.center;
    cutBtnCenter.y = self.center.y;
    self.cutBtn.center = cutBtnCenter;
    
    self.repeatBtn.frame = CGRectMake(0, 0, 30, 30);
    self.repeatBtn.center = CGPointMake(selfW*0.5, selfH*0.5);
    
    self.bottomProgressView.frame = CGRectMake(0, selfH-2, selfW, 2);

    self.closeBtn.frame = CGRectMake(0, 0, 20, 20);
    self.closeBtn.center = CGPointMake(selfW, 0);
    
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if (currentOrientation == UIDeviceOrientationPortrait) { // 竖屏
        
        self.topView.frame = CGRectMake(0, 0, selfW, 40);
        self.bottomView.frame = CGRectMake(0, selfH-50, selfW, 50);
        
        self.fastView.frame = CGRectMake(0, 0, 80*selfW/(selfH?selfH:320), 80);
        self.fastView.center = CGPointMake(selfW*0.5, selfH*0.5);
        
        self.bottomView.resolutionBtn.hidden = YES;
        self.fullScreenMode = NO;
        self.lockBtn.hidden         = !self.isFullScreenMode;
        if (self.isCellVideo) {
            [self.topView.backButton setImage:SPPlayerImage(@"play_close_30x30_") forState:UIControlStateNormal];
        } else {
            [self.topView.backButton setImage:SPPlayerImage(@"player_mini_back_iphone_20x20_") forState:UIControlStateNormal];
            [self.topView.backButton setImage:SPPlayerImage(@"player_mini_back_h_iphone_20x20_") forState:UIControlStateHighlighted];
        }
    } else { // 横屏
        
        self.topView.frame = CGRectMake(0, 0, selfW, kTopViewH);
        self.bottomView.frame = CGRectMake(0, selfH-60, selfW, kBottomViewH);
        
        // 200是self.fastView.fastVideoImageView的宽度＋20,高度是self.fastView.fastVideoImageView的高度加上50,50的含义是顶部label的高度25加上label的上下间距(分别为5)加上fastVideoImageView的底部间距10
        if (self.fastView.fastVideoImageView.image) {
            self.fastView.frame = CGRectMake(0, 0, 200, 180*ScreenHeight/ScreenWidth+50);
        } else {
            self.fastView.frame = CGRectMake(0, 0, 100*selfW/(selfH?selfH:320), 100);
        }
        self.fastView.center = CGPointMake(selfW*0.5, selfH*0.5);
        
        if (self.isCellVideo) {
            self.shrink = NO;
        }
        self.bottomView.resolutionBtn.hidden = !self.videoItem.resolutionDic.count;
        self.fullScreenMode = YES;
        self.lockBtn.hidden         = !self.isFullScreenMode;
        self.cutBtn.hidden          = !self.isFullScreenMode;
        if (self.isCellVideo) {
            [self.topView.backButton setImage:SPPlayerImage(@"play_back_half_20x20_") forState:UIControlStateNormal];
        } else {
            [self.topView.backButton setImage:SPPlayerImage(@"player_fullBack_iphone_20x40_") forState:UIControlStateNormal];
            [self.topView.backButton setImage:SPPlayerImage(@"player_fullBack_h_iphone_20x40_") forState:UIControlStateHighlighted];
        }
    }
}

#pragma clang diagnostic pop

@end

//-------------------------------------------------------------------------------------------------------------------------------------------------------

#pragma mark - 顶部的view

@implementation SPVideoPlayerTopControlView

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
    self.backgroundColor = [UIColor clearColor];
    [self addSubview:self.backgroundImageView];
    [self addSubview:self.backButton];
    [self addSubview:self.videoTitleLabel];
    [self addSubview:self.downloadButton];
}

- (UIImageView *)backgroundImageView {
    
    if (!_backgroundImageView) {
        _backgroundImageView = [[UIImageView alloc] init];
        _backgroundImageView.image = SPPlayerImage(@"playemini_shadow_top_iphone_10x120_@1x");
        
    }
    return _backgroundImageView;
}

- (UIButton *)backButton {
    
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    }
    return _backButton;
}

- (UILabel *)videoTitleLabel {
    
    if (!_videoTitleLabel) {
        _videoTitleLabel = [[UILabel alloc] init];
        _videoTitleLabel.textColor = [UIColor whiteColor];
        _videoTitleLabel.font = [UIFont systemFontOfSize:15];
        
    }
    return _videoTitleLabel;
}

- (UIButton *)downloadButton {
    
    if (!_downloadButton) {
        _downloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_downloadButton setImage:SPPlayerImage(@"player_down_iphone_40x49_") forState:UIControlStateNormal];
    }
    return _downloadButton;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat selfW = self.bounds.size.width;
    CGFloat selfH = self.bounds.size.height;
    
    self.backgroundImageView.frame = self.bounds;

    CGFloat backButtonW = 50;
    CGFloat backButtonH = selfH*(2.0/3.0);
    CGFloat backButtonX = 0;
    CGFloat backButtonY = ((selfH-20)-backButtonH)*0.5+20; // 20为状态栏的高度
    self.backButton.frame = CGRectMake(backButtonX, backButtonY, backButtonW, backButtonH);
    
    CGFloat videoTitleLabelX = CGRectGetMaxX(_backButton.frame)+5;
    CGFloat videoTitleLabelY = backButtonY;
    CGFloat videoTitleLabelW = ScreenWidth*0.5-videoTitleLabelX;
    CGFloat videoTitleLabelH = backButtonH;
    self.videoTitleLabel.frame = CGRectMake(videoTitleLabelX, videoTitleLabelY, videoTitleLabelW, videoTitleLabelH);
    
    CGFloat downLoadButtonH = 69;
    CGFloat downLoadButtonW = 60;
    CGFloat downLoadButtonX = selfW-downLoadButtonW-8;
    CGFloat downLoadButtonY = 0;
    self.downloadButton.frame = CGRectMake(downLoadButtonX, downLoadButtonY, downLoadButtonW, downLoadButtonH);
}

@end

//-------------------------------------------------------------------------------------------------------------------------------------------------------

#pragma mark - 底部的view


@implementation SPVideoPlayerBottomControlView

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
    self.backgroundColor = [UIColor clearColor];
    [self addSubview:self.backgroundImageView];
    [self addSubview:self.playOrPauseButton];
    [self addSubview:self.nextButton];
    [self addSubview:self.timeLabel];
    [self addSubview:self.currentTimeLabel];
    [self addSubview:self.totalTimeLabel];
    [self addSubview:self.progressView];
    [self addSubview:self.videoSlider];
    [self addSubview:self.resolutionBtn];
    [self addSubview:self.fullScreenButton];
}

// 由于videoSlider的垂直中心是与self的y值保持齐平的，这就导致videoSlider上面一半不在self的范围之内，为了使得超出父控件仍然可以点击，重写这个方法。
// 这个方法有很多陷阱，务必引起高度重视,我遇到的过的2个坑在这里点一下：
// 1.当父控件的alpha=0(<0.01)时，重写该方法后，”指定超出父控件仍然可以触发事件的那个子控件“依然有事件(比如这里self的alpha=0后，self.videoSlider仍然可以触发事件);
// 2. 当某个cell进入缓存池之后，”另一个cell“复用了这个缓存池里的cell，那么当触发“另一个cell”上的某个事件的时候，会发现接收这个事件的cell并非是“另一个cell”,而是缓存池里的cell
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (view == nil) {
        CGPoint tempoint = [self.videoSlider convertPoint:point fromView:self];
        if (CGRectContainsPoint(self.videoSlider.bounds, tempoint))
        {
            // 只有self显示的时候，才让超出父控件的子控件具有点击事件,如果不加此判断，那么当self的alpha=0时，滑动条仍然会触发事件
            if (self.alpha >= 0.01) {
                view = self.videoSlider;
            }
        }
    }
    return view;
}


- (UIImageView *)backgroundImageView {
    
    if (!_backgroundImageView) {
        _backgroundImageView = [[UIImageView alloc] init];
        _backgroundImageView.image = SPPlayerImage(@"playemini_shadow_iphone_6x66_");

    }
    return _backgroundImageView;
}


- (UIButton *)playOrPauseButton {
    
    if (!_playOrPauseButton) {
        _playOrPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    }
    return _playOrPauseButton;
}

- (UIButton *)nextButton {
    
    if (!_nextButton) {
        _nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    }
    return _nextButton;
}

- (UILabel *)timeLabel {
    
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.font = [UIFont systemFontOfSize:10];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        _timeLabel.textColor = [UIColor whiteColor];
        [_timeLabel sizeToFit];
    }
    return _timeLabel;
}


- (UILabel *)currentTimeLabel {
    
    if (!_currentTimeLabel) {
        _currentTimeLabel = [[UILabel alloc] init];
        _currentTimeLabel.font = [UIFont systemFontOfSize:10];
        _currentTimeLabel.textAlignment = NSTextAlignmentCenter;
        _currentTimeLabel.textColor = [UIColor whiteColor];
        
    }
    return _currentTimeLabel;
}

- (UILabel *)totalTimeLabel {
    
    if (!_totalTimeLabel) {
        _totalTimeLabel = [[UILabel alloc] init];
        _totalTimeLabel.font = self.currentTimeLabel.font;
        _totalTimeLabel.textAlignment = NSTextAlignmentCenter;
        _totalTimeLabel.textColor = [UIColor whiteColor];
        
    }
    return _totalTimeLabel;
}

- (UIProgressView *)progressView {
    if (!_progressView) {
        _progressView                   = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.progressTintColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
        _progressView.trackTintColor    = [UIColor clearColor];
    }
    return _progressView;
}

- (SPVideoSlider *)videoSlider {
    if (!_videoSlider) {
        _videoSlider                       = [[SPVideoSlider alloc] init];
        [_videoSlider setMinimumTrackImage:SPPlayerImage(@"pic_progressbar_n_171x3_") forState:UIControlStateNormal];
        //[_videoSlider setMaximumTrackImage:SPPlayerImage(@"freeprop_progressbar_iphone_40x2_"] forState:UIControlStateNormal];
        _videoSlider.maximumTrackTintColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
    }
    return _videoSlider;
}


- (UIButton *)resolutionBtn {
    if (!_resolutionBtn) {
        _resolutionBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _resolutionBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    }
    return _resolutionBtn;
}

- (UIButton *)fullScreenButton {
    
    if (!_fullScreenButton) {
        _fullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
    }
    return _fullScreenButton;
}

/** 根据横竖屏隐藏或显示某些控件,因为有些控件在横屏时需要，在竖屏时不需要 */
- (void)hideOrShowSomeControlWithOrientation:(UIInterfaceOrientation)rientation {
    if (rientation == UIDeviceOrientationPortrait) { // 竖屏
        self.nextButton.hidden          = YES;
        self.timeLabel.hidden           = YES;
        self.currentTimeLabel.hidden    = NO;
        self.totalTimeLabel.hidden      = NO;
        self.fullScreenButton.hidden    = NO;
    } else { // 横屏
        self.nextButton.hidden          = NO;
        self.timeLabel.hidden           = NO;
        self.currentTimeLabel.hidden    = YES;
        self.totalTimeLabel.hidden      = YES;
        self.fullScreenButton.hidden    = YES;
    }
}

/** 根据横竖屏设置某些控件的图片 */
- (void)configerImageForSomeControlWithOrientation:(UIInterfaceOrientation)rientation {
    if (rientation == UIDeviceOrientationPortrait) {
        [_playOrPauseButton setImage:SPPlayerImage(@"player_mini_pause_h_iphone_30x30_") forState:UIControlStateHighlighted];
        [_playOrPauseButton setImage:SPPlayerImage(@"player_mini_pause_iphone_30x30_") forState:UIControlStateNormal];
        [_playOrPauseButton setImage:SPPlayerImage(@"player_mini_play_h_iphone_30x30_") forState:UIControlStateHighlighted];
        [_playOrPauseButton setImage:SPPlayerImage(@"player_mini_play_iphone_30x30_") forState:UIControlStateSelected];

        [_videoSlider setThumbImage:SPPlayerImage(@"player_mini_slider_iphone_8x10_") forState:UIControlStateNormal];
        
        // 竖屏时下一集按钮被隐藏了
        [_nextButton setImage:SPPlayerImage(@"player_next_iphone_30x30_") forState:UIControlStateNormal];
        [_nextButton setImage:SPPlayerImage(@"player_next_h_iphone_30x30_") forState:UIControlStateHighlighted];
        [_fullScreenButton setImage:SPPlayerImage(@"play_full_iphone_40x40_") forState:UIControlStateNormal];
        [_fullScreenButton setImage:SPPlayerImage(@"play_full_h_iphone_40x40_") forState:UIControlStateHighlighted];
        
    } else {
        
        [_playOrPauseButton setImage:SPPlayerImage(@"player_full_pause_iphone_30x30_") forState:UIControlStateNormal];
        [_playOrPauseButton setImage:SPPlayerImage(@"player_full_play_iphone_30x30_") forState:UIControlStateSelected];
        [_playOrPauseButton setImage:SPPlayerImage(@"player_full_pause_h_iphone_30x30_") forState:UIControlStateHighlighted];
        [_playOrPauseButton setImage:SPPlayerImage(@"player_full_play_h_iphone_30x30_") forState:UIControlStateHighlighted];
        
        
        [_videoSlider setThumbImage:SPPlayerImage(@"player_full_slider_iphone_12x15_") forState:UIControlStateNormal];

        [_nextButton setImage:SPPlayerImage(@"player_full_next_iphone_30x30_") forState:UIControlStateNormal];
        [_nextButton setImage:SPPlayerImage(@"player_full_next_h_iphone_30x30_") forState:UIControlStateHighlighted];
        // 横屏时全屏按钮被隐藏了
        [_fullScreenButton setImage:SPPlayerImage(@"play_mini_iphone_80x80_@1x") forState:UIControlStateNormal];
        [_fullScreenButton setImage:SPPlayerImage(@"play_mini_h_iphone_80x80_@1x") forState:UIControlStateHighlighted];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat selfW = self.bounds.size.width;
    CGFloat selfH = self.bounds.size.height;
    
    self.backgroundImageView.frame = self.bounds;
    
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    // 根据横竖屏显示和隐藏某些控件
    [self hideOrShowSomeControlWithOrientation:currentOrientation];
    // 根据横竖屏设置某些控件的图片
    [self configerImageForSomeControlWithOrientation:currentOrientation];
    
    if (currentOrientation == UIDeviceOrientationPortrait) { // 竖屏

        // 根据横竖屏设置某些控件的图片
        [self configerImageForSomeControlWithOrientation:currentOrientation];
 
        CGFloat playOrPauseButtonH      = selfH*(2.0/3.0);
        CGFloat playOrPauseButtonW      = playOrPauseButtonH;
        CGFloat playOrPauseButtonX      = 0;
        CGFloat playOrPauseButtonY      = selfH-playOrPauseButtonH-3;
        self.playOrPauseButton.frame    = CGRectMake(playOrPauseButtonX, playOrPauseButtonY, playOrPauseButtonW, playOrPauseButtonH);
        
        CGFloat currentTimeLabelW       = 40;
        CGFloat currentTimeLabelH       = playOrPauseButtonH*0.5;
        CGFloat currentTimeLabelX       = CGRectGetMaxX(self.playOrPauseButton.frame);
        CGFloat currentTimeLabelY       = 0;
        self.currentTimeLabel.frame     = CGRectMake(currentTimeLabelX, currentTimeLabelY, currentTimeLabelW, currentTimeLabelH);
        CGPoint currentTimeLabelCenter  = self.currentTimeLabel.center;
        currentTimeLabelCenter.y        = self.playOrPauseButton.center.y;
        self.currentTimeLabel.center    = currentTimeLabelCenter;
        
        CGFloat videoSliderX            = CGRectGetMaxX(self.currentTimeLabel.frame);
        CGFloat videoSliderY            = playOrPauseButtonY;
        CGFloat videoSliderW            = selfW-videoSliderX*2;
        CGFloat videoSliderH            = playOrPauseButtonH;
        self.videoSlider.frame          = CGRectMake(videoSliderX, videoSliderY, videoSliderW, videoSliderH);
        CGPoint videoSliderCenter       = self.videoSlider.center;
        videoSliderCenter.y             = self.currentTimeLabel.center.y;
        self.videoSlider.center         = videoSliderCenter;
        
        CGFloat progressViewX           = videoSliderX+2;
        CGFloat progressViewY           = 0;
        CGFloat progressViewW           = selfW-2*progressViewX;
        CGFloat progressViewH           = selfH;
        self.progressView.frame         = CGRectMake(progressViewX, progressViewY, progressViewW, progressViewH);
        self.progressView.center        = self.videoSlider.center;
        
        CGFloat totalTimeLabelW         = currentTimeLabelW;
        CGFloat totalTimeLabelH         = currentTimeLabelH;
        CGFloat totalTimeLabelX         = CGRectGetMaxX(self.videoSlider.frame);
        CGFloat totalTimeLabelY         = 0;
        self.totalTimeLabel.frame       = CGRectMake(totalTimeLabelX, totalTimeLabelY, totalTimeLabelW, totalTimeLabelH);
        CGPoint totalTimeLabelCenter    = self.totalTimeLabel.center;
        totalTimeLabelCenter.y = self.currentTimeLabel.center.y;
        self.totalTimeLabel.center      = totalTimeLabelCenter;
        
        CGFloat fullScreenButtonW       = playOrPauseButtonW;
        CGFloat fullScreenButtonH       = fullScreenButtonW;
        CGFloat fullScreenButtonX       = selfW-fullScreenButtonW;
        CGFloat fullScreenButtonY       = playOrPauseButtonY;
        self.fullScreenButton.frame     = CGRectMake(fullScreenButtonX, fullScreenButtonY, fullScreenButtonW, fullScreenButtonH);
        
    } else { // 非竖屏,不一定是横屏
        
        CGFloat playOrPauseButtonH      = selfH*(2.0/3.0);
        CGFloat playOrPauseButtonW      = playOrPauseButtonH;
        CGFloat playOrPauseButtonX      = 5;
        CGFloat playOrPauseButtonY      = selfH-playOrPauseButtonH-3;
        self.playOrPauseButton.frame    = CGRectMake(playOrPauseButtonX, playOrPauseButtonY, playOrPauseButtonW, playOrPauseButtonH);
        
        CGFloat nextButtonX             = CGRectGetMaxX(self.playOrPauseButton.frame)+5;
        CGFloat nextButtonY             = playOrPauseButtonY;
        CGFloat nextButtonW             = playOrPauseButtonW;
        CGFloat nextButtonH             = playOrPauseButtonH;
        self.nextButton.frame           = CGRectMake(nextButtonX, nextButtonY, nextButtonW, nextButtonH);
        
        CGFloat timeLabelW              = 90;
        CGFloat timeLabelH              = nextButtonH*0.5;
        CGFloat timeLabelX              = CGRectGetMaxX(self.nextButton.frame)+5;
        CGFloat timeLabelY              = nextButtonY+(nextButtonH-timeLabelH)*0.5;
        self.timeLabel.frame            = CGRectMake(timeLabelX, timeLabelY, timeLabelW, timeLabelH);
        
        CGFloat videoSliderX            = 13;
        CGFloat videoSliderW            = selfW-2*videoSliderX;
        CGFloat videoSliderH            = 30;
        CGFloat videoSliderY            = 0-videoSliderH*0.5;
        self.videoSlider.frame          = CGRectMake(videoSliderX, videoSliderY, videoSliderW, videoSliderH);
        
        CGFloat progressViewX           = videoSliderX+2;
        CGFloat progressViewY           = 0;
        CGFloat progressViewW           = selfW-2*progressViewX;
        CGFloat progressViewH           = selfH;
        self.progressView.frame         = CGRectMake(progressViewX, progressViewY, progressViewW, progressViewH);
        self.progressView.center        = self.videoSlider.center;
        
        CGFloat resolutionBtnW          = 70;
        CGFloat resolutionBtnH          = playOrPauseButtonH;
        CGFloat resolutionBtnX          = selfW-resolutionBtnW-10;
        CGFloat resolutionBtnY          = playOrPauseButtonY;
        self.resolutionBtn.frame        = CGRectMake(resolutionBtnX, resolutionBtnY, resolutionBtnW, resolutionBtnH);
        
        CGFloat fullScreenButtonW       = playOrPauseButtonW;
        CGFloat fullScreenButtonH       = fullScreenButtonW;
        CGFloat fullScreenButtonX       = selfW-fullScreenButtonW;
        CGFloat fullScreenButtonY       = playOrPauseButtonY;
        self.fullScreenButton.frame     = CGRectMake(fullScreenButtonX, fullScreenButtonY, fullScreenButtonW, fullScreenButtonH);

    }
    
}

@end

//-------------------------------------------------------------------------------------------------------------------------------------------------------

#pragma mark - 快进的view

@implementation SPVideoPlayerFastView

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
    [self addSubview:self.fastIconView];
    [self addSubview:self.fastTimeLabel];
    [self addSubview:self.fastVideoImageView];
    [self addSubview:self.fastProgressView];
}

- (UIImageView *)fastIconView {
    
    if (!_fastIconView) {
        _fastIconView = [[UIImageView alloc] init];
        
    }
    return _fastIconView;
}

- (UILabel *)fastTimeLabel {
    if (!_fastTimeLabel) {
        _fastTimeLabel               = [[UILabel alloc] init];
        _fastTimeLabel.textColor     = [UIColor whiteColor];
        _fastTimeLabel.textAlignment = NSTextAlignmentCenter;
        _fastTimeLabel.font          = [UIFont systemFontOfSize:14.0];
    }
    return _fastTimeLabel;
}

- (UIImageView *)fastVideoImageView {
    if (!_fastVideoImageView) {
        _fastVideoImageView = [[UIImageView alloc] init];
        _fastVideoImageView.layer.cornerRadius = 6;
        _fastVideoImageView.layer.masksToBounds = YES;
        _fastVideoImageView.contentMode = UIViewContentModeScaleAspectFit;
        _fastVideoImageView.backgroundColor = [UIColor blackColor];
    }
    return _fastVideoImageView;
}

- (UIProgressView *)fastProgressView {
    if (!_fastProgressView) {
        _fastProgressView                   = [[UIProgressView alloc] init];
        _fastProgressView.progressTintColor = [UIColor greenColor];
        _fastProgressView.trackTintColor    = [[UIColor lightGrayColor] colorWithAlphaComponent:0.4];
    }
    return _fastProgressView;
}


- (UIImageView *)backgroundImageView {
    if (!_backgroundImageView) {
        _backgroundImageView = [[UIImageView alloc] init];
        _backgroundImageView.userInteractionEnabled = YES;
    }
    return _backgroundImageView;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat selfW = self.bounds.size.width;
    //CGFloat selfH = self.bounds.size.height;
    
    self.backgroundImageView.frame = self.bounds;
    
    CGFloat padding = 10;
    
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if (currentOrientation == UIDeviceOrientationPortrait || !self.fastVideoImageView.image) { // 竖屏
        
        self.fastProgressView.hidden = NO;
        self.fastVideoImageView.hidden = YES;
        
        CGFloat fastIconViewX = 0;
        CGFloat fastIconViewY = 5;
        CGFloat fastIconViewH = 30;
        CGFloat fastIconViewW = fastIconViewH;
        self.fastIconView.frame = CGRectMake(fastIconViewX, fastIconViewY, fastIconViewW, fastIconViewH);
        CGPoint fastIconViewCenter = self.fastIconView.center;
        fastIconViewCenter.x = selfW*0.5;
        self.fastIconView.center = fastIconViewCenter;
        
        CGFloat fastProgressViewX = padding;
        CGFloat fastProgressViewY = CGRectGetMaxY(self.fastIconView.frame)+5;
        CGFloat fastProgressViewW = selfW-2*fastProgressViewX;
        CGFloat fastProgressViewH = 20;
        self.fastProgressView.frame = CGRectMake(fastProgressViewX, fastProgressViewY, fastProgressViewW, fastProgressViewH);
        
        CGFloat fastTimeLabelX = padding;
        CGFloat fastTimeLabelY = CGRectGetMaxY(self.fastProgressView.frame)+5;
        CGFloat fastTimeLabelW = selfW-2*fastTimeLabelX;
        CGFloat fastTimeLabelH = fastIconViewH;
        self.fastTimeLabel.frame = CGRectMake(fastTimeLabelX, fastTimeLabelY, fastTimeLabelW, fastTimeLabelH);
        
    } else { // 横屏
        
        self.fastProgressView.hidden = YES;
        self.fastVideoImageView.hidden = NO;
        
        // 要与屏幕宽高成比例
        CGFloat fastVideoImageViewX = padding;
        CGFloat fastVideoImageViewW = 180;
        CGFloat fastVideoImageViewH = fastVideoImageViewW*ScreenHeight/ScreenWidth;
        CGFloat fastVideoImageViewY = 35;
        self.fastVideoImageView.frame = CGRectMake(fastVideoImageViewX, fastVideoImageViewY, fastVideoImageViewW, fastVideoImageViewH);
        
        CGFloat fastIconViewX = 20;
        CGFloat fastIconViewY = 5;
        CGFloat fastIconViewH = 30;
        CGFloat fastIconViewW = fastIconViewH;
        self.fastIconView.frame = CGRectMake(fastIconViewX, fastIconViewY, fastIconViewW, fastIconViewH);
        
        CGFloat fastTimeLabelX = CGRectGetMaxX(self.fastIconView.frame);
        CGFloat fastTimeLabelY = fastIconViewY;
        CGFloat fastTimeLabelW = 100;
        CGFloat fastTimeLabelH = fastIconViewH;
        self.fastTimeLabel.frame = CGRectMake(fastTimeLabelX, fastTimeLabelY, fastTimeLabelW, fastTimeLabelH);
    }
}

@end


@implementation SPPlaceholderView

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
    [self addSubview:self.placeholderImageView];
    [self addSubview:self.promptLabel];
    [self addSubview:self.refreshbutton];
    [self addSubview:self.backButton];
    [self addSubview:self.fullScreenButton];
}

- (void)setPlaceholderImage:(UIImage *)image {
    self.placeholderImageView.image = image;
}

- (void)setPromptLabelTitle:(NSString *)title {
    self.promptLabel.hidden = NO;
    self.promptLabel.text = title;
}

- (void)setRefreshbuttonTitle:(NSString *)title {
    [self.refreshbutton setTitle:title forState:UIControlStateNormal];
}

- (void)setRefreshbuttonTitle:(NSString *)title image:(UIImage *)image {
    self.refreshbutton.hidden = NO;
    [self.refreshbutton setTitle:title forState:UIControlStateNormal];
    [self.refreshbutton setImage:image forState:UIControlStateNormal];
    [self.refreshbutton setBackgroundImage:SPPlayerImage(@"sv_round_rect_72x25_") forState:UIControlStateNormal];
}

- (UIImageView *)placeholderImageView {
    
    if (!_placeholderImageView) {
        _placeholderImageView = [[UIImageView alloc] init];
        
    }
    return _placeholderImageView;
}

- (UILabel *)promptLabel {
    
    if (!_promptLabel) {
        _promptLabel = [[UILabel alloc] init];
        _promptLabel.font = [UIFont boldSystemFontOfSize:14];
        _promptLabel.textColor = [UIColor whiteColor];
        _promptLabel.textAlignment = NSTextAlignmentCenter;
        _promptLabel.numberOfLines = 0;
        _promptLabel.hidden = YES;
    }
    return _promptLabel;
}

- (UIButton *)refreshbutton {
    
    if (!_refreshbutton) {
        _refreshbutton = [[UIButton alloc] init];
        _refreshbutton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        _refreshbutton.layer.cornerRadius = 15;
        _refreshbutton.layer.masksToBounds = YES;
        [_refreshbutton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _refreshbutton.hidden = YES;
        
    }
    return _refreshbutton;
}

- (UIButton *)fullScreenButton {
    if (!_fullScreenButton) {
        _fullScreenButton = [[UIButton alloc] init];
    }
    return _fullScreenButton;
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [[UIButton alloc] init];
    }
    return _backButton;
}

/** 根据横竖屏设置某些控件的图片 */
- (void)configerImageForSomeControlWithOrientation:(UIInterfaceOrientation)rientation {
    if (rientation == UIDeviceOrientationPortrait) {
        [self.backButton setImage:SPPlayerImage(@"player_mini_back_iphone_20x20_") forState:UIControlStateNormal];
        [self.backButton setImage:SPPlayerImage(@"player_mini_back_h_iphone_20x20_") forState:UIControlStateHighlighted];

        [_fullScreenButton setImage:SPPlayerImage(@"play_full_iphone_40x40_") forState:UIControlStateNormal];
        [_fullScreenButton setImage:SPPlayerImage(@"play_full_h_iphone_40x40_") forState:UIControlStateHighlighted];
        
    } else {

        [self.backButton setImage:SPPlayerImage(@"player_fullBack_iphone_20x40_") forState:UIControlStateNormal];
        [self.backButton setImage:SPPlayerImage(@"player_fullBack_h_iphone_20x40_") forState:UIControlStateHighlighted];
        
        // 横屏时全屏按钮被隐藏了
        [_fullScreenButton setImage:SPPlayerImage(@"play_mini_iphone_80x80_@1x") forState:UIControlStateNormal];
        [_fullScreenButton setImage:SPPlayerImage(@"play_mini_h_iphone_80x80_@1x") forState:UIControlStateHighlighted];
    }
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat selfW = self.bounds.size.width;
    CGFloat selfH = self.bounds.size.height;
    
    self.placeholderImageView.frame = self.bounds;
    
    self.promptLabel.frame = CGRectMake(15, 0, selfW-30, 21);
    self.promptLabel.center = CGPointMake(selfW*0.5, selfH*0.5-21);
    
    self.refreshbutton.frame = CGRectMake(15, 0, 72*35/25, 35);
    self.refreshbutton.center = CGPointMake(selfW*0.5, selfH*0.5+21);
    
    CGFloat backButtonW = 50;
    CGFloat backButtonH = kTopViewH*(2.0/3.0);
    CGFloat backButtonX = 0;
    CGFloat backButtonY = ((kTopViewH-20)-backButtonH)*0.5+20; // 20为状态栏的高度
    self.backButton.frame = CGRectMake(backButtonX, backButtonY, backButtonW, backButtonH);
    
    CGFloat fullScreenButtonW       = kBottomViewH*2/3;
    CGFloat fullScreenButtonH       = fullScreenButtonW;
    CGFloat fullScreenButtonX       = selfW-fullScreenButtonW;
    CGFloat fullScreenButtonY       = selfH-fullScreenButtonH-3;
    self.fullScreenButton.frame     = CGRectMake(fullScreenButtonX, fullScreenButtonY, fullScreenButtonW, fullScreenButtonH);
    
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    // 根据横竖屏设置某些控件的图片
    [self configerImageForSomeControlWithOrientation:currentOrientation];
    
}

@end



