//
//  SPVideoPlayerView.h
//  SPVideoPlayer
//
//  Created by leshengping on 17/7/12. （https://github.com/SPStore/SPVideoPlayer
//  Copyright © 2017年 leshengping. All rights reserved.
//  播放层

#import <UIKit/UIKit.h>
#import "SPVideoPlayerControlView.h"
#import "SPVideoItem.h"
#import "SPVideoPlayerControlViewDelegate.h"

/** 播放状态发生了改变的通知名称 */
UIKIT_EXTERN NSNotificationName const SPVideoPlayerStateChangedNSNotification;
/** 进度值发生了改变的通知名称 */
/** 当在快进快退的时候，视频的播放进度并未发生真实的改变(仍然处于自然播放状态)，只有快进快退结束时，视频播放进度才开始发生真实跳转 */
UIKIT_EXTERN NSNotificationName const SPVideoPlayerProgressValueChangedNSNotification;
/** 将要跳转到哪一时间进行播放的通知名称 */
UIKIT_EXTERN NSNotificationName const SPVideoPlayerWillJumpNSNotification;
/** 跳转完毕的通知名称 */
UIKIT_EXTERN NSNotificationName const SPVideoPlayerDidJumpedNSNotification;
/** 缓冲进度发生了改变的通知名称 */
UIKIT_EXTERN NSNotificationName const SPVideoPlayerBufferProgressValueChangedNSNotification;
/** 视频截图完成了的通知名称 */
UIKIT_EXTERN NSNotificationName const SPVideoPlayerCutVideoFinishedNSNotification;
/** 媒体网络加载状态发生了改变的通知名称 */
UIKIT_EXTERN NSNotificationName const SPVideoPlayerLoadStatusDidChangedNotification;
/** 亮度或音量发生了改变的通知名称 */
UIKIT_EXTERN NSNotificationName const SPVideoPlayerBrightnessOrVolumeDidChangedNotification;

// 播放器的几种状态
typedef NS_ENUM(NSInteger, SPVideoPlayerPlayState) {
    SPVideoPlayerPlayStateReadyToPlay,       // 准备播放
    SPVideoPlayerPlayStatePlaying,           // 播放中
    SPVideoPlayerPlayStatePause,             // 暂停播放
    SPVideoPlayerPlayStateBuffering,         // 缓冲中
    SPVideoPlayerPlayStateBufferSuccessed,   // 缓冲成功
    SPVideoPlayerPlayStateEndedPlay,         // 结束播放
    SPVideoPlayerPlayStateFailed,            // 播放失败
};

// 播放进度状态
typedef NS_ENUM(NSInteger,SPVideoPlayerPlayProgressState) {
    SPVideoPlayerPlayProgressStateFastBackForward=-1,  // 快退状态
    SPVideoPlayerPlayProgressStateNomal,               // 自然状态
    SPVideoPlayerPlayProgressStateFastForward,         // 快进状态
};

// playerLayer的填充模式（默认：等比例填充，直到一个维度到达区域边界）
typedef NS_ENUM(NSInteger, SPPlayerLayerGravity) {
    SPPlayerLayerGravityResize,           // 非均匀模式，两个维度完全填充至整个视图区域
    SPPlayerLayerGravityResizeAspect,     // 等比例填充，直到一个维度到达区域边界
    SPPlayerLayerGravityResizeAspectFill  // 等比例填充，直到填充满整个视图区域，其中一个维度的部分区域会被裁剪
};

// 媒体网络加载状态
typedef NS_ENUM(NSInteger,SPVideoPlayerLoadStatus) {
    SPVideoPlayerLoadStatusUnknown = -1,                 // 未知
    SPVideoPlayerLoadStatusNotReachable = 0,             // 无网络
    SPVideoPlayerLoadStatusReachableViaWWAN = 1,         // 手机流量
    SPVideoPlayerLoadStatusReachableViaWiFi = 2,         // WiFi
    SPVideoPlayerLoadStatusAbnormal = 3,                 // 网络异常
};

@protocol SPVideoPlayerDelegate <NSObject>
@optional
/** 返回按钮事件 */
- (void)sp_playerBackAction;
/** 下载视频,返回下载路径 */
- (NSString *)sp_playerDownload:(NSString *)url;
/** 控制层即将显示 */
- (void)sp_playerControlViewWillShow:(UIView *)controlView isFullscreen:(BOOL)fullscreen;
/** 控制层即将隐藏 */
- (void)sp_playerControlViewWillHidden:(UIView *)controlView isFullscreen:(BOOL)fullscreen;

@end

@interface SPVideoPlayerView : UIView <SPVideoPlayerControlViewDelegate>

/** 是否从上次停止的地方继续播放，默认是YES */
@property (nonatomic, assign) BOOL resumePlayFromLastStopPoint;
/** 设置playerLayer的填充模式 */
@property (nonatomic, assign) SPPlayerLayerGravity    playerLayerGravity;
/** 是否有下载功能(默认是关闭) */
@property (nonatomic, assign) BOOL                    hasDownload;
/** 是否要求预览图，全屏时默认为YES */
@property (nonatomic, assign) BOOL                    requirePreviewView;
/** 设置代理 */
@property (nonatomic, weak) id<SPVideoPlayerDelegate>      delegate;
/** 是否被用户暂停 */
@property (nonatomic, assign, readonly) BOOL          isPauseByUser;
/** 播发器的几种状态 */
@property (nonatomic, assign, readonly) SPVideoPlayerPlayState  playState;
/** 媒体网络的加载状态 */
@property (nonatomic, assign, readonly) SPVideoPlayerLoadStatus loadStatus;
/** 静音（默认为NO）*/
@property (nonatomic, assign) BOOL                    mute;
/** 当cell上的playerView有一半不可见的时候停止播放播放（默认为YES） */
@property (nonatomic, assign) BOOL                    stopPlayWhenPlayerHalfInvisable;
/** 当cell上的playerView整个不可见的时候停止播放(默认为NO) */
@property (nonatomic, assign) BOOL                    stopPlayWhenPlayerWholeInvisable;
/** 当cell上的playerView不可见时是否切换到小屏播放(默认为NO) */
@property (nonatomic, assign) BOOL switchToSmallScreenPlayWhenPlayerInvisable;
/** 当cell播放视频由全屏变为小屏时候，是否回到中间位置(默认YES) */
@property (nonatomic, assign) BOOL                    cellPlayerOnCenter;
/** player在栈上，即此时push或者模态了新控制器 */
@property (nonatomic, assign) BOOL                    playerPushedOrPresented;
/**
 *  单例，用于列表cell上多个视频
 *
 *  @return SPPlayer
 */
+ (instancetype)sharedPlayerView;

/**
 * 设置控件层和模型
 * 控制层传nil，默认使用SPPlayerControlView(如自定义可传自定义的控制层)
 * 此方法的主要作用有3个：
    1、添加playerView到模型中的fatherView或fatherViewTag指定的view上去
    2、添加控件层到playerView上
    3、获取播放资源
 */
- (void)configureControlView:(UIView *)controlView videoItem:(SPVideoItem *)videoItem;

/**
 *  相当于上面那个方法的controlView传nil
 */
- (void)configureVideoItem:(SPVideoItem *)videoItem;

/**
 * 指定播放的控制层和模型数组
 * 控制层传nil，默认使用SPPlayerControlView(如自定义可传自定义的控制层)
 * 此方法的主要作用有3个：
    1、添加playerView到模型中的fatherView或fatherViewTag指定的view上去
    2、添加控件层到playerView上
    3、获取播放资源
 */
- (void)configureControlView:(UIView *)controlView videoItems:(NSArray<SPVideoItem *> *)videoItems;

/**
 *  调此方法才会开始播放
 */
- (void)startPlay;

/**
 *  重置player
 */
- (void)resetPlayer;

/**
 *  在当前页面，设置新的视频时候调用此方法
 */
- (void)resetToPlayNewVideo:(SPVideoItem *)videoItem;

/**
 *  播放
 */
- (void)play;

/**
 *  暂停
 */
- (void)pause;

/** 
 *  停止播放,停止播放会将SPVideoPlayerView从父控件中移除
 */
- (void)stop;


@end


// -------- 对字符串进行md5加密的类 ----------
@interface NSString (MD5)

@property (nullable, nonatomic, readonly) NSString *md5String;

@end


