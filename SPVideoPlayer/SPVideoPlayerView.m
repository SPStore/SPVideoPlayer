//
//  SPVideoPlayerView.m
//  SPVideoPlayer
//
//  Created by leshengping on 17/7/12.  （https://github.com/SPStore/SPVideoPlayer）
//  Copyright © 2017年 leshengping. All rights reserved.
//

#import "SPVideoPlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "UIView+CustomControlView.h"
#import "SPVideoPlayerView.h"
#import "SPNetworkReachabilityManager.h"

NSNotificationName const SPVideoPlayerStateChangedNSNotification = @"SPVideoPlayerStateChangedNSNotification";
NSNotificationName const SPVideoPlayerProgressValueChangedNSNotification = @"SPVideoPlayerProgressValueChangedNSNotification";
NSNotificationName const SPVideoPlayerWillJumpNSNotification = @"SPVideoPlayerWillJumpNSNotification";
NSNotificationName const SPVideoPlayerDidJumpedNSNotification = @"SPVideoPlayerDidJumpedNSNotification";
NSNotificationName const SPVideoPlayerCutVideoFinishedNSNotification = @"SPVideoPlayerCutVideoFinishedNSNotification";
NSNotificationName const SPVideoPlayerLoadStatusDidChangedNotification = @"SPVideoPlayerLoadStatusDidChangedNotification";
NSNotificationName const SPVideoPlayerBufferProgressValueChangedNSNotification = @"SPVideoPlayerBufferProgressValueChangedNSNotification";
NSNotificationName const SPVideoPlayerBrightnessOrVolumeDidChangedNotification = @"SPVideoPlayerBrightnessOrVolumeDidChangedNotification";

// 忽略编译器的警告
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"

// 如果是本地文件，key值是url的最后目录的md5加密，如果不是本地文件，key值是url的md5加密;key要与videoItem有关联
// 之所以本地文件要加一个lastPathComponent，是因为本地文件的url在iOS8以后会发生变化，本地的url实际上就是文件路径,iOS8以后只要重新运行程序该路径就会发生变化，系统会删除之前的，然后建立新的路径，并把原数据存到新的路径
#define SPSeekTimeKey [self.videoItem.videoURL.scheme isEqualToString:@"file"] ? (self.videoItem.videoURL.absoluteString.lastPathComponent.md5String) : (self.videoItem.videoURL.absoluteString.md5String)

// url的key值，套了2层3目运算符,此key值在数组有元素的情况下应该与数组相关联
#define SPURLKey self.videoItems.count ? (([self.videoItems.firstObject.videoURL.scheme isEqualToString:@"file"]) ? (self.videoItems.firstObject.videoURL.absoluteString.lastPathComponent) : (self.videoItems.firstObject.videoURL.absoluteString)) : [self.videoItem.videoURL.scheme isEqualToString:@"file"] ? (self.videoItem.videoURL.absoluteString.lastPathComponent) : (self.videoItem.videoURL.absoluteString)

// 枚举值，包含水平移动方向和垂直移动方向
typedef NS_ENUM(NSInteger, PanDirection){
    PanDirectionHorizontalMoved, // 横向移动
    PanDirectionVerticalMoved    // 纵向移动
};

@interface SPVideoPlayerView () <UIGestureRecognizerDelegate,UIAlertViewDelegate>

/** 播放属性 */
@property (nonatomic, strong) AVPlayer               *player;
@property (nonatomic, strong) AVPlayerItem           *playerItem;
@property (nonatomic, strong) AVURLAsset             *urlAsset;
@property (nonatomic, strong) AVAssetImageGenerator  *imageGenerator;
@property (nonatomic, strong) AVPlayerLayer          *playerLayer;
/** 播放进度的观察者 */
@property (nonatomic, strong) id                     timeObserve;
/** 滑杆 */
@property (nonatomic, strong) UISlider               *volumeViewSlider;
/** 用来保存快进的总时长 */
@property (nonatomic, assign) CGFloat                sumTime;
/** 平移方向 */
@property (nonatomic, assign) PanDirection           panDirection;
/** 播发器的状态 */
@property (nonatomic, assign) SPVideoPlayerPlayState          playState;
/** 是否为全屏 */
@property (nonatomic, assign) BOOL                   isFullScreen;
/** 是否锁定屏幕方向 */
@property (nonatomic, assign) BOOL                   isLocked;
/** 是否在调节音量*/
@property (nonatomic, assign) BOOL                   isVolume;
/** 是否被用户暂停 */
@property (nonatomic, assign) BOOL                   isPauseByUser;
/** 是否播放本地文件 */
@property (nonatomic, assign) BOOL                   isLocalVideo;
/** slider上次的值 */
@property (nonatomic, assign) CGFloat                sliderLastValue;
/** 是否再次设置URL播放视频 */
@property (nonatomic, assign) BOOL                   repeatToPlay;
/** 是否播放完了*/
@property (nonatomic, assign) BOOL                   playDidEnd;
/** 是否进入了后台*/
@property (nonatomic, assign) BOOL                   didEnterBackground;
/** 是否自动播放 */
@property (nonatomic, assign) BOOL                   isAutoPlay;
/** 单击手势 */
@property (nonatomic, strong) UITapGestureRecognizer *singleTap;
/** 双击手势 */
@property (nonatomic, strong) UITapGestureRecognizer *doubleTap;
/** 视频URL的数组 */
@property (nonatomic, strong) NSArray                *videoURLArray;
/** 预览图,快进快退且全屏时会显示 */
@property (nonatomic, strong) UIImage                *thumbImg;
/** 亮度view */
@property (nonatomic, strong) SPBrightnessView       *brightnessView;
/** 视频填充模式 */
@property (nonatomic, copy) NSString                 *videoGravity;

#pragma mark - Cell PlayerView

/** 指tableView或collectionView */
@property (nonatomic, strong) UIScrollView           *scrollView;
/** player所在cell的indexPath */
@property (nonatomic, strong) NSIndexPath            *indexPath;
/** ViewController中页面是否消失 */
@property (nonatomic, assign) BOOL                   viewDisappear;
/** 是否在cell上播放video */
@property (nonatomic, assign) BOOL                   isCellVideo;
/** 是否缩小视频在底部 */
@property (nonatomic, assign) BOOL                   isBottomVideo;
/** 是否切换分辨率*/
@property (nonatomic, assign) BOOL                   isChangeResolution;
/** 是否正在拖拽 */
@property (nonatomic, assign) BOOL                   isDragged;
/** 小窗口距屏幕右边和下边的距离 */
@property (nonatomic, assign) CGPoint                shrinkRightBottomPoint;
/** 小屏播放时，可以平移小屏到屏幕任意位置 */
@property (nonatomic, strong) UIPanGestureRecognizer *shrinkPanGesture;

/** 控件View，就是展示播放暂停，滑动条，当前时间总时间等的view */
@property (nonatomic, strong) UIView                 *controlView;
/** 模型，播放资源都来自此模型 */
@property (nonatomic, strong) SPVideoItem            *videoItem;
/** 模型数组 */
@property (nonatomic, strong) NSArray<SPVideoItem *> *videoItems;
/** 记录播放到哪里的时间 */
@property (nonatomic, assign) CGFloat                seekTime;
/** 视频url */
@property (nonatomic, strong) NSURL                  *videoURL;
/** 分辨率字典 */
@property (nonatomic, strong) NSDictionary           *resolutionDic;
// 标记下一集按钮被点击了
@property (nonatomic, assign) BOOL                    nextBtnClicked;
// 标记当前播放进程有没有退出
@property (nonatomic, assign, getter=isProcessTerminaed) BOOL processTerminaed;

@property (nonatomic, assign) BOOL canPlay;
@property (nonatomic, assign) double dragedSeconds;

@end

@implementation SPVideoPlayerView

#pragma mark - 系统的方法

/**
 *  代码初始化调用此方法
 */
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) { [self initializeThePlayer]; }
    return self;
}

/**
 *  xib、storyboard初始化调用此方法
 */
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initializeThePlayer];
        
        
        }
    return self;
}

/**
 *  初始化
 */
- (void)initializeThePlayer {
    self.requirePreviewView = YES;
    self.cellPlayerOnCenter = YES;
    self.stopPlayWhenPlayerHalfInvisable = YES;
    self.resumePlayFromLastStopPoint = YES;

}

- (void)dealloc {
    NSLog(@"%s",__func__);
    // 保存当前播放的时间点
    [self saveLastVideoPlayInfo];
    self.playerItem = nil;
    self.scrollView  = nil;
    _processTerminaed = YES;
    SPPlayerShared.isLockScreen = NO;
    // 移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    // 移除time观察者
    if (self.timeObserve) {
        [self.player removeTimeObserver:self.timeObserve];
        self.timeObserve = nil;
    }
    [self.player removeObserver:self forKeyPath:@"rate"];
    
    [[SPNetworkReachabilityManager sharedManager] stopMonitoring];
}

#pragma mark - 公开的方法

/**
 *  单例，用于列表cell上多个视频
 *
 *  @return SPPlayer
 */
+ (instancetype)sharedPlayerView {
    static SPVideoPlayerView *playerView = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        playerView = [[SPVideoPlayerView alloc] init];
    });
    return playerView;
}

/** 设置控件层和模型 */
- (void)configureControlView:(UIView *)controlView videoItem:(SPVideoItem *)videoItem {
    // 如果playerView是一个单例,那么self.controlView就会一直存在，与单例共存亡，所以为单例的时候不需要重新创建controlView
    if (!controlView && !self.controlView) {
        // 指定默认控制层
        SPVideoPlayerControlView *defaultControlView = [[SPVideoPlayerControlView alloc] init];
        self.controlView = defaultControlView;
    } else {
        self.controlView = controlView;
    }
    self.videoItem = videoItem;
}

/**
 *  使用自带的控制层时候可使用此API
 */
- (void)configureVideoItem:(SPVideoItem *)videoItem {
    [self configureControlView:nil videoItem:videoItem];
}

/** 设置控件层和模型 */
- (void)configureControlView:(UIView *)controlView videoItems:(NSArray<SPVideoItem *> *)videoItems {
    if (videoItems == nil || videoItems.count == 0) {
        return;
    }
    _videoItems = videoItems;
    if (!controlView) {
        // 指定默认控制层
        SPVideoPlayerControlView *defaultControlView = [[SPVideoPlayerControlView alloc] init];
        self.controlView = defaultControlView;
    } else {
        self.controlView = controlView;
    }
    
    if (SPURLKey) {
        NSString *cacheUrl = [[NSUserDefaults standardUserDefaults] objectForKey:SPURLKey];
        if (cacheUrl) {
            // 来到这个if语句，说明此视频是上一次未播放完的，那么此次继续播放此url
            SPVideoItem *videoItem = [videoItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"videoURL==%@", [NSURL URLWithString:cacheUrl]]].lastObject;
            self.videoItem = videoItem;
        } else {
            self.videoItem = videoItems.firstObject;
        }
    }

}

/**
 *  自动播放，默认不自动播放
 */
- (void)startPlay {
    // 设置Player相关参数
    [self configSPPlayer];
}

/**
 *  重置player
 */
- (void)resetPlayer {
    // 改为未播放完
    self.playDidEnd         = NO;
    self.playerItem         = nil;
    self.didEnterBackground = NO;
    self.isAutoPlay         = NO;
    if (self.timeObserve) {
        [self.player removeTimeObserver:self.timeObserve];
        self.timeObserve = nil;
    }
    // 移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // 暂停
    [self pause];
    // 移除原来的layer
    [self.playerLayer removeFromSuperlayer];
    // 替换PlayerItem为nil
    [self.player replaceCurrentItemWithPlayerItem:nil];
    // 把player置为nil
    self.imageGenerator = nil;
    self.player         = nil;
    if (!self.isChangeResolution) { // 重置控制层View
        [self.controlView sp_playerResetControlView];
    }
    if (!self.nextBtnClicked) {
        self.controlView   = nil;
    }
    
    // 非重播时，移除当前playerView
    if (!self.repeatToPlay) { [self removeFromSuperview]; }
    // 底部播放video改为NO
    self.isBottomVideo = NO;
    // cell上播放视频 && 不是重播时
    if (self.isCellVideo && !self.repeatToPlay) {
        // vicontroller中页面消失
        self.viewDisappear = YES;
        self.isCellVideo   = YES;
        self.scrollView     = nil;
        self.indexPath     = nil;
    }
}

/**
 *  在当前页面，设置新的视频时候调用此方法
 */
- (void)resetToPlayNewVideo:(SPVideoItem *)videoItem {
    // 移除上一次保存的时间点,保证播放新视频时都从0开始播放，比如播放下一集时，都是从0开始播放
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SPSeekTimeKey];
    // 移除上一次保存在本地的url
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SPURLKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.repeatToPlay = YES;
    [self resetPlayer];
    [self setVideoItem:videoItem];
    [self configSPPlayer];
}

/**
 *  播放
 */
- (void)play {
    
    _isPauseByUser = NO;
    [_player play];
}

/**
 * 暂停
 */
- (void)pause {

    _isPauseByUser = YES;
    [_player pause];
}

/**
 *  停止播放
 */
- (void)stop {
    [self resetPlayer];
}

/**
 *  在当前页面，设置新的Player的URL调用此方法
 */
- (void)resetToPlayNewURL {
    self.repeatToPlay = YES;
    [self resetPlayer];
}

#pragma mark - 私有方法

/**
 *  设置Player相关参数
 */
- (void)configSPPlayer {
    
    _processTerminaed = NO;

    // 准备播放状态
    if (!self.isChangeResolution) {
        [self updatePlayState:SPVideoPlayerPlayStateReadyToPlay];
    }
    // 30秒后触发timeOut
    //[self performSelector:@selector(timeOut) withObject:nil afterDelay:30];

    self.urlAsset = [AVURLAsset URLAssetWithURL:self.videoURL options:nil];
    NSString *tracksKey = @"tracks";
    // 异步加载
    __weak typeof(self) weakSelf = self;

    [self.urlAsset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler:^{
        // 主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            // 因为这是异步操作，有可能执行到这儿的时候程序已经退出,必须要确保当前播放进程没有退出
            if (!_processTerminaed) {
                [weakSelf prepareToPlayAsset:weakSelf.urlAsset withKey:tracksKey];
            }
        });
    }];
    
}

// 播放前准备
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKey:(NSString *)tracksKey{
    NSError *error;
    AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];
    if (status == AVKeyValueStatusLoaded) {
        // 初始化playerItem,playerItem的setter方法中有监听一系列属性变化，如播放状态
        self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
        // 每次都重新创建Player，替换replaceCurrentItemWithPlayerItem:，该方法阻塞线程
        self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
        
        // 初始化playerLayer
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        
        self.backgroundColor = [UIColor blackColor];
        
        // 此处为默认视频填充模式
        self.playerLayer.videoGravity = self.videoGravity;
        
        // 自动播放
        self.isAutoPlay = YES;
        
        // 添加播放进度计时器
        [self createTimer];
        
        // 获取系统音量
        [self configureVolume];
        
        // 本地文件不设置SPVideoPlayerPlayStateBuffering状态
        if ([self.videoURL.scheme isEqualToString:@"file"]) {
            self.isLocalVideo = YES;
            [self.controlView sp_playerDownloadBtnState:NO];
        } else {
            self.isLocalVideo = NO;
            [self.controlView sp_playerDownloadBtnState:YES];
        }
        // 开始播放
        [self.player play];
        
        _isPauseByUser = NO;
    } else {
        NSLog(@"error=%@",error);
        if (error.domain == NSURLErrorDomain && error.code == -1009) {
            self.loadStatus = SPVideoPlayerLoadStatusNotReachable;
        }
        // code == -1001,domain==kCFErrorDomainCFNetwork,请求超时4分钟
    }
}

// 超时
- (void)timeOut {

    if (!self.canPlay) { // 30秒后来到这里，如果还是没开始播放则报网络异常
        [self.urlAsset cancelLoading];
        self.loadStatus = SPVideoPlayerLoadStatusAbnormal;
    }
}

/**
 *  从xx秒开始播放视频跳转
 *
 *  @param dragedSeconds 视频跳转的秒数
 */
- (void)seekToTime:(double)dragedSeconds completionHandler:(void (^)(BOOL finished))completionHandler {
    self.dragedSeconds = dragedSeconds;
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        
        [self.player pause];
        // 如果self.seekTime有值(不能判断dragedSeconds，因为dragedSeconds可能是快进快退时的目标时间)，说明是从上一次播放的时间点续播或者切换分辨率
        if (self.seekTime && !self.isChangeResolution) { // 续播等待状态
            [self updatePlayState:SPVideoPlayerPlayStateReadyToPlay];
        } else { // 没有值说明是快进快退
            // 发出将要真实跳转的通知
            [[NSNotificationCenter defaultCenter] postNotificationName:SPVideoPlayerWillJumpNSNotification object:nil];
        }
        // seekTime:completionHandler:不能精确定位
        // 如果需要精确定位，可以使用seekToTime:toleranceBefore:toleranceAfter:completionHandler:
        // 转换成CMTime才能给player来控制播放进度
        CMTime dragedCMTime = CMTimeMake(dragedSeconds, 1); //kCMTimeZero
        __weak typeof(self) weakSelf = self;
        [self.player seekToTime:dragedCMTime toleranceBefore:CMTimeMake(1,1) toleranceAfter:CMTimeMake(1,1) completionHandler:^(BOOL finished) {
            // 跳转完毕的通知
            [[NSNotificationCenter defaultCenter] postNotificationName:SPVideoPlayerDidJumpedNSNotification object:nil];
            // 视频跳转回调
            if (completionHandler) { completionHandler(finished); }
            _isPauseByUser = NO;
            weakSelf.seekTime = 0;
            weakSelf.isDragged = NO;
            weakSelf.isChangeResolution = NO;
            [weakSelf.player play];
        }];
    }
}

/**
 *  保存视频播放的信息，如播放的当前时间点等
 */
- (void)saveLastVideoPlayInfo {
    // 将当前时间存储到沙盒,下次进来的时候，就从该时间点继续播放,注意key值是每个url的md5加密,因为每一个url都有自己的当前时间，key值不能定死
    CGFloat currentTime = CMTimeGetSeconds([self.player currentTime]);
    [[NSUserDefaults standardUserDefaults] setFloat:currentTime forKey:SPSeekTimeKey];
    
    // 保存url
    [[NSUserDefaults standardUserDefaults] setObject:self.videoURL.absoluteString forKey:SPURLKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/**
 *  player添加到fatherView上
 */
- (void)addPlayerToFatherView:(UIView *)view {
    [view layoutIfNeeded];
    // 这里应该添加判断，因为view有可能为空，当view为空时[view addSubview:self]会crash
    if (view) {
        if (!self.nextBtnClicked) {
            [self removeFromSuperview];
            [view addSubview:self];
            self.frame = view.bounds;
            self.controlView.frame = self.bounds;
        }
    }
}

/**
 *  用于cell上播放player
 *
 *  @param scrollView tableView
 *  @param indexPath indexPath
 */
- (void)cellVideoWithScrollView:(UIScrollView *)scrollView
                    AtIndexPath:(NSIndexPath *)indexPath {
    // 如果页面没有消失，并且playerItem有值，需要重置player(其实就是点击播放其他视频时候)
    if (!self.viewDisappear && self.playerItem) {
        [self resetPlayer];
    }
    // 在cell上播放视频
    self.isCellVideo      = YES;
    // viewDisappear改为NO
    self.viewDisappear    = NO;
    // 设置tableview
    self.scrollView       = scrollView;
    // 设置indexPath
    self.indexPath        = indexPath;
    // 在cell播放
    [self.controlView sp_playerCellPlay];
    
    self.shrinkPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(shrikPanAction:)];
    self.shrinkPanGesture.delegate = self;
    [self addGestureRecognizer:self.shrinkPanGesture];
}

/** 在tableViewCell上通过fatherViewTag寻找fatherView */
- (UIView *)lookforFatherViewInTableViewcell:(UITableViewCell *)cell {
    UIView *fatherView = [cell.contentView viewWithTag:self.videoItem.fatherViewTag];
    // 有些开发者可能会不小心或者习惯把子控件加在cell上而不是cell.contentView上，如果cell.contentView上找不到，就去cell上找，如果还找不到就说明fatherView真的不存在
    if (fatherView == nil) {
        fatherView = [cell viewWithTag:self.videoItem.fatherViewTag];
    }
    return fatherView;
}

/** 在collectionViewCell上通过fatherViewTag寻找fatherView */
- (UIView *)lookforFatherViewInCollectionViewcell:(UICollectionViewCell *)cell {
    UIView *fatherView = [cell.contentView viewWithTag:self.videoItem.fatherViewTag];
    // 有些开发者可能会不小心或者习惯把子控件加在cell上而不是cell.contentView上，如果cell.contentView上找不到，就去cell上找，如果还找不到就说明fatherView真的不存在
    if (fatherView == nil) {
        fatherView = [cell viewWithTag:self.videoItem.fatherViewTag];
    }
    return fatherView;
}

/**
 *  创建手势
 */
- (void)createGesture {
    // 单击
    self.singleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(singleTapAction:)];
    self.singleTap.delegate                = self;
    self.singleTap.numberOfTouchesRequired = 1; //手指数
    self.singleTap.numberOfTapsRequired    = 1;
    [self addGestureRecognizer:self.singleTap];
    
    // 双击(播放/暂停)
    self.doubleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTapAction:)];
    self.doubleTap.delegate                = self;
    self.doubleTap.numberOfTouchesRequired = 1; //手指数
    self.doubleTap.numberOfTapsRequired    = 2;
    [self addGestureRecognizer:self.doubleTap];
    
    // 解决点击当前view时候响应其他控件事件
    [self.singleTap setDelaysTouchesBegan:YES];
    [self.doubleTap setDelaysTouchesBegan:YES];
    // 双击失败响应单击事件
    [self.singleTap requireGestureRecognizerToFail:self.doubleTap];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.isAutoPlay) {
        UITouch *touch = [touches anyObject];
        if(touch.tapCount == 1) {
            [self performSelector:@selector(singleTapAction:) withObject:@(NO) ];
        } else if (touch.tapCount == 2) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(singleTapAction:) object:nil];
            [self doubleTapAction:touch.gestureRecognizers.lastObject];
        }
    }
}

- (void)createTimer {
    __weak typeof(self) weakSelf = self;
    // 每1秒执行一次
    self.timeObserve = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time){
        AVPlayerItem *currentItem = weakSelf.playerItem;
        
        NSArray *loadedRanges = currentItem.seekableTimeRanges;
        if (loadedRanges.count > 0 && currentItem.duration.timescale != 0) {
            CGFloat currentTime = CMTimeGetSeconds([currentItem currentTime]);
            // 这个判断是解决当手滑屏幕快进或者使用滑动条快进时，当前秒回弹问题，比如滑到第7秒，然后滑动结束来到此方法时可能当前时间只是6秒，这时会有个回弹现象，不过只有总时间比较小的时候比较明显
            if (currentTime <= self.dragedSeconds) {
                currentTime = self.dragedSeconds;
            }
            CGFloat totalTime     = (CGFloat)currentItem.duration.value / currentItem.duration.timescale;
            CGFloat value         = currentTime / totalTime;
            if (!weakSelf.isDragged) {
                // 发出播放进度在改变的通知
                [[NSNotificationCenter defaultCenter] postNotificationName:SPVideoPlayerProgressValueChangedNSNotification object:nil userInfo:@{@"currentTime":@(currentTime),@"totalTime":@(totalTime),@"value":@(value),@"playProgressState":@(SPVideoPlayerPlayProgressStateNomal),@"requirePreviewView":@(weakSelf.requirePreviewView)}];
            }
        }
    }];
}

/**
 *  获取系统音量
 */
- (void)configureVolume {
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    _volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            _volumeViewSlider = (UISlider *)view;
            break;
        }
    }
    
    // 使用这个category的应用不会随着手机静音键打开而静音，可在手机静音下播放声音
    NSError *setCategoryError = nil;
    BOOL success = [[AVAudioSession sharedInstance]
                    setCategory: AVAudioSessionCategoryPlayback
                    error: &setCategoryError];
    
    if (!success) { /* handle the error in setCategoryError */ }
    
}

#pragma mark - 观察者、通知

/**
 *  添加观察者、通知
 */
- (void)addNotifications {
    // app退到后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
    // app进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayground) name:UIApplicationDidBecomeActiveNotification object:nil];
    // app将要被"杀死"
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate) name:UIApplicationWillTerminateNotification object:nil];

    
    // 监听耳机插入和拔掉通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:) name:AVAudioSessionRouteChangeNotification object:nil];
    
    if (self.videoItem.shouldAutorotate) {
        // 监测设备方向
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDeviceOrientationChange)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
        // 检测状态栏方向
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onStatusBarOrientationChange)
                                                     name:UIApplicationDidChangeStatusBarOrientationNotification
                                                   object:nil];
    }
    
    // 监听网络
    __weak typeof(self) weakSelf = self;
    [[SPNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(SPNetworkReachabilityStatus status) {
        // 一共有四种状态
        switch (status) {
            case SPNetworkReachabilityStatusNotReachable:
                weakSelf.loadStatus = SPVideoPlayerLoadStatusNotReachable;
                break;
            case SPNetworkReachabilityStatusReachableViaWWAN:
                weakSelf.loadStatus = SPVideoPlayerLoadStatusReachableViaWWAN;
                break;
            case SPNetworkReachabilityStatusReachableViaWiFi:
                weakSelf.loadStatus = SPVideoPlayerLoadStatusReachableViaWiFi;
                break;
            case SPNetworkReachabilityStatusUnknown:
            default:
                weakSelf.loadStatus = SPVideoPlayerLoadStatusUnknown;
                break;
        }
    }];
    [[SPNetworkReachabilityManager sharedManager] startMonitoring];
}

#pragma mark - 通知方法

/**
 *  耳机插入、拔出事件
 */
- (void)audioRouteChangeListenerCallback:(NSNotification*)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (routeChangeReason) {
            
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            // 耳机插入
            break;
            
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
        {
            // 耳机拔掉
            // 拔掉耳机继续播放
            [self play];
        }
            break;
            
        case AVAudioSessionRouteChangeReasonCategoryChange:
            // called at start - also when other audio wants to play
            NSLog(@"AVAudioSessionRouteChangeReasonCategoryChange");
            break;
    }
}

/**
 *  播放完了
 *
 *  @param notification 通知
 */
- (void)moviePlayDidEnd:(NSNotification *)notification {
    [self updatePlayState:SPVideoPlayerPlayStateEndedPlay];
    // 播放结束时，更新seekTime在沙盒中的值为0，等下次播放时就可以从0开始播放，否则下次播放会从结束时开始播，然后立刻结束
    [[NSUserDefaults standardUserDefaults] setObject:@(0.0f) forKey:SPSeekTimeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (self.isBottomVideo && !self.isFullScreen) { // 播放完了，如果是在小屏模式 && 在bottom位置，直接关闭播放器
        self.repeatToPlay = NO;
        self.playDidEnd   = NO;
        [self resetPlayer];
    } else {
        if (!self.isDragged) { // 如果不是拖拽中，直接结束播放
            self.playDidEnd = YES;
            [self updatePlayState:SPVideoPlayerPlayStateEndedPlay];
        }
    }
}

/**
 *  应用退到后台
 */
- (void)appDidEnterBackground {
    
    // 关闭网络监听
    [[SPNetworkReachabilityManager sharedManager] stopMonitoring];
    
    self.didEnterBackground     = YES;
    // 退到后台锁定屏幕方向
    SPPlayerShared.isLockScreen = YES;
    [_player pause];
    
}

/**
 *  应用进入前台
 */
- (void)appDidEnterPlayground {
    
    // 开启网络监听
    [[SPNetworkReachabilityManager sharedManager] startMonitoring];
    
    self.didEnterBackground     = NO;
    // 根据是否锁定屏幕方向 来恢复单例里锁定屏幕的方向
    SPPlayerShared.isLockScreen = self.isLocked;
    if (!_isPauseByUser) {
        _isPauseByUser = NO;
        [self play];
    }
    if (!self.player) {
        self.isAutoPlay = YES;
        [self configSPPlayer];
    }
    
}

/**
 *  app被“杀死”
 */
- (void)applicationWillTerminate {
    // 保存当前播放的时间点
    [self saveLastVideoPlayInfo];
}

#pragma mark - 旋转相关

/**
 *  屏幕方向发生变化会调用这里
 */
- (void)onDeviceOrientationChange {
    if (!self.urlAsset) { return; }
    if (SPPlayerShared.isLockScreen) { return; }
    if (self.didEnterBackground) { return; };
    if (self.playerPushedOrPresented) { return; }
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown ) { return; }
    
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortraitUpsideDown:{
        }
            break;
        case UIInterfaceOrientationPortrait:{
            if (self.isFullScreen) {
                [self toOrientation:UIInterfaceOrientationPortrait];
            }
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:{
            if (self.isFullScreen == NO) {
                [self toOrientation:UIInterfaceOrientationLandscapeLeft];
                self.isFullScreen = YES;
            } else {
                [self toOrientation:UIInterfaceOrientationLandscapeLeft];
            }
        }
            break;
        case UIInterfaceOrientationLandscapeRight:{
            if (self.isFullScreen == NO) {
                [self toOrientation:UIInterfaceOrientationLandscapeRight];
                self.isFullScreen = YES;
            } else {
                [self toOrientation:UIInterfaceOrientationLandscapeRight];
            }
        }
            break;
        default:
            break;
    }
}

/**
 *  设置横屏的frame
 */
- (void)setOrientationLandscapeConstraint:(UIInterfaceOrientation)orientation {
    self.scrollView.scrollsToTop = NO;
    [self toOrientation:orientation];
    self.isFullScreen = YES;
}

/**
 *  设置竖屏的frame
 */
- (void)setOrientationPortraitConstraint {
    self.scrollView.scrollsToTop = YES;
    if (self.isCellVideo) { // cell上播放
        if ([self.scrollView isKindOfClass:[UITableView class]]) {
            UITableView *tableView = (UITableView *)self.scrollView;
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:self.indexPath];
            self.isBottomVideo = NO;
            UIView *fatherView = [self lookforFatherViewInTableViewcell:cell];
            // 转换坐标系
            CGRect rectInWindow = [fatherView convertRect:fatherView.bounds toView:nil];
            
            // 如果cell不在可见的cell数组中
            if (![tableView.visibleCells containsObject:cell]) {
                if ([self isPlayerWholeInvisable:rectInWindow]) {
                    [self updatePlayerViewToBottom];
                } else {
                    [self addPlayerToFatherView:fatherView];
                }
                
            } else {
                if (![self isPlayerWholeInvisable:rectInWindow]) {
                    [self addPlayerToFatherView:fatherView];
                } else {
                    [self updatePlayerViewToBottom];
                }
            }
        } else if ([self.scrollView isKindOfClass:[UICollectionView class]]) {
            UICollectionView *collectionView = (UICollectionView *)self.scrollView;
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:self.indexPath];
            self.isBottomVideo = NO;
            if (![collectionView.visibleCells containsObject:cell]) {
                [self updatePlayerViewToBottom];
            } else {
                UIView *fatherView = [self lookforFatherViewInCollectionViewcell:cell];
                [self addPlayerToFatherView:fatherView];
            }
        }
    } else {
        [self addPlayerToFatherView:self.videoItem.fatherView];
    }
    
    [self toOrientation:UIInterfaceOrientationPortrait];
    self.isFullScreen = NO;
}

- (void)toOrientation:(UIInterfaceOrientation)orientation {
    // 获取到当前状态条的方向
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    // 判断如果当前方向和要旋转的方向一致,那么不做任何操作
    if (currentOrientation == orientation) { return; }
    
    // 根据要旋转的方向,重新修改限制
    if (orientation != UIInterfaceOrientationPortrait) {//
        // 这个地方加判断是为了从全屏的一侧,直接到全屏的另一侧不用修改限制,否则会出错;
        if (currentOrientation == UIInterfaceOrientationPortrait) {
            // 移除，因为马上要切换父视图
            [self removeFromSuperview];
            SPBrightnessView *brightnessView = [SPBrightnessView sharedBrightnessView];
            [[UIApplication sharedApplication].keyWindow insertSubview:self belowSubview:brightnessView];
            
            CGRect self_Frame = self.frame;
            self_Frame.size = CGSizeMake(ScreenHeight, ScreenWidth);
            self.frame = self_Frame;
            
            self.center = [UIApplication sharedApplication].keyWindow.center;
            
        }
    }
    // iOS6.0之后,设置状态条的方法能使用的前提是shouldAutorotate为NO,也就是说这个视图控制器内,旋转要关掉;
    // 也就是说在实现这个方法的时候-(BOOL)shouldAutorotate返回值要为NO
    [[UIApplication sharedApplication] setStatusBarOrientation:orientation animated:NO];
    // 获取旋转状态条需要的时间:
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    // 更改了状态条的方向,但是设备方向UIInterfaceOrientation还是正方向的,这就要设置给你播放视频的视图的方向设置旋转
    // 给你的播放视频的view视图设置旋转
    self.transform = CGAffineTransformIdentity;
    self.transform = [self getTransformRotationAngle];
    // 开始旋转
    [UIView commitAnimations];
}

/**
 * 获取变换的旋转角度
 *
 * @return 角度
 */
- (CGAffineTransform)getTransformRotationAngle {
    // 状态条的方向已经设置过,所以这个就是你想要旋转的方向
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    // 根据要进行旋转的方向来计算旋转的角度
    if (orientation == UIInterfaceOrientationPortrait) {
        return CGAffineTransformIdentity;
    } else if (orientation == UIInterfaceOrientationLandscapeLeft){
        return CGAffineTransformMakeRotation(-M_PI_2);
    } else if(orientation == UIInterfaceOrientationLandscapeRight){
        return CGAffineTransformMakeRotation(M_PI_2);
    }
    return CGAffineTransformIdentity;
}

/**
 *  屏幕转屏
 *
 *  @param orientation 屏幕方向
 */
- (void)interfaceOrientation:(UIInterfaceOrientation)orientation {
    if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft) {
        // 设置横屏
        [self setOrientationLandscapeConstraint:orientation];
    } else if (orientation == UIInterfaceOrientationPortrait) {
        // 设置竖屏
        [self setOrientationPortraitConstraint];
    }
}

// 状态条变化通知（在前台播放才去处理）
- (void)onStatusBarOrientationChange {
    if (!self.didEnterBackground) {
        // 获取到当前状态条的方向
        UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
        if (currentOrientation == UIInterfaceOrientationPortrait) {
            [self setOrientationPortraitConstraint];
            if (self.cellPlayerOnCenter) {
                if ([self.scrollView isKindOfClass:[UITableView class]]) {
                    UITableView *tableView = (UITableView *)self.scrollView;
                    [tableView scrollToRowAtIndexPath:self.indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
                    
                } else if ([self.scrollView isKindOfClass:[UICollectionView class]]) {
                    UICollectionView *collectionView = (UICollectionView *)self.scrollView;
                    [collectionView scrollToItemAtIndexPath:self.indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
                }
            }
            [self.brightnessView removeFromSuperview];
            [[UIApplication sharedApplication].keyWindow addSubview:self.brightnessView];
            self.brightnessView.frame = CGRectMake((ScreenWidth-155)/2, (ScreenHeight-155)/2, 155, 155);
        } else {
            if (currentOrientation == UIInterfaceOrientationLandscapeRight) {
                [self toOrientation:UIInterfaceOrientationLandscapeRight];
            } else if (currentOrientation == UIDeviceOrientationLandscapeLeft){
                [self toOrientation:UIInterfaceOrientationLandscapeLeft];
            }
            [self.brightnessView removeFromSuperview];
            [self addSubview:self.brightnessView];
            self.brightnessView.frame = CGRectMake((self.frame.size.width-155)/2, (self.frame.size.height-155)/2, 155, 155);
        }
    }
}

#pragma mark - 布局

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!self.isFullScreen) {
        if (self.isCellVideo) {
            if (!self.isBottomVideo) { // 不是小屏
                if ([self.scrollView isKindOfClass:[UITableView class]]) {
                    UITableView *tableView = (UITableView *)self.scrollView;
                    UITableViewCell *cell = [tableView cellForRowAtIndexPath:self.indexPath];
                    self.frame = [self lookforFatherViewInTableViewcell:cell].bounds;
                } else if ([self.scrollView isKindOfClass:[UICollectionView class]]) {
                    UICollectionView *collectionView = (UICollectionView *)self.scrollView;
                    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:self.indexPath];
                    self.frame = [self lookforFatherViewInCollectionViewcell:cell].bounds;
                }
            } else { // 小屏
                CGFloat width = ScreenWidth*0.5-20;
                CGFloat height = width*(ScreenWidth / ScreenHeight);
                CGRect selfFrame = self.frame;
                selfFrame.size.width = width;
                selfFrame.size.height = height;
                selfFrame.origin.x = ScreenWidth-width-_shrinkRightBottomPoint.x;
                selfFrame.origin.y = ScreenHeight-height-_shrinkRightBottomPoint.y;
                self.frame = selfFrame;
            }
        } else {
            self.frame = self.videoItem.fatherView.bounds;
        }
    }
    self.playerLayer.frame = self.bounds;
    self.controlView.frame = self.bounds;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (object == self.player.currentItem) {
        if ([keyPath isEqualToString:@"status"]) {
                        
            if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
                
                self.canPlay = YES;
                
                [self setNeedsLayout];
                [self layoutIfNeeded];
                // 添加playerLayer到self.layer
                [self.layer insertSublayer:self.playerLayer atIndex:0];
                // 如果在前台
                if (!self.didEnterBackground) {
                    // 跳到xx秒播放
                    if (self.seekTime) {
                        [self seekToTime:self.seekTime completionHandler:nil];
                    }
                } else {
                    self.didEnterBackground = NO;
                }
                // 加载完成后，再添加平移手势
                // 添加平移手势，用来控制音量、亮度、快进快退
                UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panDirection:)];
                panRecognizer.delegate = self;
                [panRecognizer setMaximumNumberOfTouches:1];
                [panRecognizer setDelaysTouchesBegan:YES];
                [panRecognizer setDelaysTouchesEnded:YES];
                [panRecognizer setCancelsTouchesInView:YES];
                [self addGestureRecognizer:panRecognizer];
                
                self.player.muted = self.mute;
            } else if (self.player.currentItem.status == AVPlayerItemStatusFailed) {
                // 播放失败状态
                [self updatePlayState:SPVideoPlayerPlayStateFailed];
            }
        } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
            
            // 计算缓冲进度
            NSTimeInterval timeInterval = [self availableDuration];
            CMTime duration             = self.playerItem.duration;
            CGFloat totalDuration       = CMTimeGetSeconds(duration);
            // 发出缓冲进度改变的通知
            [[NSNotificationCenter defaultCenter] postNotificationName:SPVideoPlayerBufferProgressValueChangedNSNotification object:nil userInfo:@{@"bufferProgress":@(timeInterval/totalDuration)}];
            
        } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
            // 当缓冲是空的时候
            if (self.playerItem.playbackBufferEmpty) {
                // 继续缓冲一段时间
                [self bufferingSomeSecond];
            }
  
        } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
            // 当缓冲好的时候
            if (self.playerItem.playbackLikelyToKeepUp && self.playState == SPVideoPlayerPlayStateBuffering){
                [[SPNetworkReachabilityManager sharedManager] stopMonitoring];
                [self updatePlayState:SPVideoPlayerPlayStateBufferSuccessed];
            }
        }
    } else if (object == self.player) {
        if ([keyPath isEqualToString:@"rate"]) {
            /**
             *  暂停分两种：一个是用户暂停
             *  另一种就是网络不好加载卡住了暂停。
             */
            if (self.player.rate == 0) {
                // 缓冲不够导致的暂停(缓冲不够在某种程度上讲就是网络不好或者无网络)
                if (!_isPauseByUser && !self.didEnterBackground) {
                    // 准备播放的过程实际上也在缓存，二者不可共存
                    if (self.playState != SPVideoPlayerPlayStateReadyToPlay && !self.seekTime) {
                        [self updatePlayState:SPVideoPlayerPlayStateBuffering];
                    }
                }
                // 正常情况下导致的暂停 
                else{
                    [self updatePlayState:SPVideoPlayerPlayStatePause];
                }
            }
            // 播放
            if (self.player.rate > 0) {
                _isPauseByUser = NO;
                    [[SPNetworkReachabilityManager sharedManager] stopMonitoring];
                if (!self.seekTime) { // 有值说明是续播，此时虽然rate=1,但是马上会seekToTime，seekToTime前会有一个准备播放的阶段
                    [self updatePlayState:SPVideoPlayerPlayStatePlaying];
                }
            }
        }
    } else if (object == self.scrollView) {
        if ([keyPath isEqualToString:kSPPlayerViewContentOffset]) {
            if (self.isFullScreen && !self.isCellVideo) { return; }
            // 当tableview滚动时处理playerView的位置
            [self handleScrollOffsetWithDict:change];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

/**
 *  缓冲较差时候会调这里
 */
- (void)bufferingSomeSecond {
    
    if (self.playState != SPVideoPlayerPlayStateReadyToPlay && !self.seekTime) {
        [self updatePlayState:SPVideoPlayerPlayStateBuffering];
    }
    // playbackBufferEmpty会反复进入，因此在bufferingOneSecond延时播放执行完之前再调用bufferingSomeSecond都忽略
    __block BOOL isBuffering = NO;
    if (isBuffering) {
        return;
    }
    isBuffering = YES;
    
    // 需要先暂停一小会之后再播放，否则网络状况不好的时候时间在走，声音播放不出来
    [self.player pause];
    
    static int i = 0;
    static int j = 0;
    // 每隔一秒再次缓存一次
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 如果此时用户已经暂停了，则不再需要开启播放了
        if (_isPauseByUser) {
            isBuffering = NO;
            return;
        }
        [self play];
        // 如果执行了play还是没有播放则说明还没有缓冲好，则再次缓冲一段时间
        isBuffering = NO;

        if (!self.playerItem.playbackLikelyToKeepUp) { // 未缓冲成功
            if (i > 5) { // 如果缓存了5次(5次就是5秒)仍然没有缓存好，则开始监听网络
                // 开始监听网络
                [[SPNetworkReachabilityManager sharedManager] startMonitoring];
                // 如果无网络就不再继续缓冲了，controlView此时可以弹出提示框提示检查网络设置
                if (self.loadStatus == SPVideoPlayerLoadStatusNotReachable || self.loadStatus == SPVideoPlayerLoadStatusUnknown) {
                    i = 0;
                } else { // 有网络
                    if (j > 30) { // 30秒后直接报网络异常
                        [[SPNetworkReachabilityManager sharedManager] stopMonitoring];
                        self.loadStatus = SPVideoPlayerLoadStatusAbnormal; // 网络异常状态,这是我强制的网络异常，并非是监听到的
                        [self.player pause];
                    } else { // 30秒内每隔一秒继续缓冲
                        [self bufferingSomeSecond]; // 继续缓冲
                        i = 0;
                        j++;
                    }
                }
            } else {
                [self bufferingSomeSecond]; // 继续缓冲
                i++;
                j++;
            }
        } else { // 缓冲成功了
            i = 0;
            j = 0;
        }
    });
}

/**
 *  计算缓冲进度
 *
 *  @return 缓冲进度
 */
- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[_player currentItem] loadedTimeRanges];
    CMTimeRange timeRange     = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds        = CMTimeGetSeconds(timeRange.start);
    float durationSeconds     = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result     = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}


/**
 *  更新播放状态
 *
 *  @param state void
 */
- (void)updatePlayState:(SPVideoPlayerPlayState)state {
    // 记录播放状态
    _playState = state;
    // 发出通知,告诉外面播放状态改变了
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[@"playState"] = @(state);
    userInfo[@"seekTime"] = @(self.seekTime);
    [[NSNotificationCenter defaultCenter] postNotificationName:SPVideoPlayerStateChangedNSNotification object:nil userInfo:userInfo];
}

/**
 *  KVO TableViewContentOffset
 *
 *  @param dict void
 */
- (void)handleScrollOffsetWithDict:(NSDictionary*)dict {
    if ([self.scrollView isKindOfClass:[UITableView class]]) {
        UITableView *tableView = (UITableView *)self.scrollView;
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:self.indexPath];
        NSArray *visableCells = tableView.visibleCells;
        
        if ([visableCells containsObject:cell]) {
            UIView *fatherView = [self lookforFatherViewInTableViewcell:cell];
            [self setupPlayForm:fatherView];
        }
    } else if ([self.scrollView isKindOfClass:[UICollectionView class]]) {
        UICollectionView *collectionView = (UICollectionView *)self.scrollView;
        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:self.indexPath];
        NSArray *visableCells = collectionView.visibleCells;

        if ([visableCells containsObject:cell]) {
            UIView *fatherView = [self lookforFatherViewInCollectionViewcell:cell];
            [self setupPlayForm:fatherView];
        }
    }
}

/** scrollView(tableView,collectionView)在滑动的时候，设置player的播放形态,或停止播放，或小屏播放 */
- (void)setupPlayForm:(UIView *)fatherView {
    // 转换坐标系,之所以转换fatherView的坐标系而不转换self的坐标系，是因为self有可能是小屏播放，小屏状态时frame改变了，只有fatherView的frame是不变的
    CGPoint centerInWindow = [fatherView.superview convertPoint:fatherView.center toView:nil];
    CGRect rectInWindow = [fatherView convertRect:fatherView.bounds toView:nil];
    
    if (self.stopPlayWhenPlayerHalfInvisable) { // 如果设置了playerView一半不可见
        if ([self isPlayerHalfInvisable:centerInWindow]) { // 满足一半不可见
            [self stop];
        }
    } else if (self.stopPlayWhenPlayerWholeInvisable) { // playerView整个不可见
        if ([self isPlayerWholeInvisable:rectInWindow]) { // 满足整个playerView不可见
            [self stop]; // 停止播放
        }
    } else if (self.switchToSmallScreenPlayWhenPlayerInvisable) { // 设置了切换到小屏
        if ([self isPlayerWholeInvisable:rectInWindow]) { // 满足整个playerView不可见
            if (self.playerItem.status == AVPlayerItemStatusReadyToPlay && (self.loadStatus == SPVideoPlayerLoadStatusReachableViaWiFi || self.loadStatus == SPVideoPlayerLoadStatusReachableViaWWAN)) {
                [self updatePlayerViewToBottom]; // 小屏播放
            }
        } else {
            if (self.isBottomVideo) {
                [self updatePlayerViewToCell:fatherView]; // 回到cell上播放
            }
        }
    }

}

/**
 *  是否一半不可见
 */
- (BOOL)isPlayerHalfInvisable:(CGPoint)centerInWindow {
    return (centerInWindow.y < self.scrollView.frame.origin.y + self.scrollView.contentInset.top || centerInWindow.y > ScreenHeight-self.scrollView.contentInset.bottom-self.scrollView.frame.origin.y);
}

/**
 *  是否整个不可见
 */
- (BOOL)isPlayerWholeInvisable:(CGRect)rectInWindow {
    return (CGRectGetMaxY(rectInWindow) < self.scrollView.frame.origin.y + self.scrollView.contentInset.top || CGRectGetMinY(rectInWindow) > ScreenHeight-self.scrollView.contentInset.bottom-self.scrollView.frame.origin.y);
}

/**
 *  缩小到底部，显示小视频
 */
- (void)updatePlayerViewToBottom {
    if (self.isBottomVideo) { return; }
    self.isBottomVideo = YES;
    if (self.playDidEnd) { // 如果播放完了，滑动到小屏bottom位置时，直接resetPlayer
        self.repeatToPlay = NO;
        self.playDidEnd   = NO;
        [self resetPlayer];
        return;
    }
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    
    if (CGPointEqualToPoint(self.shrinkRightBottomPoint, CGPointZero)) { // 没有初始值
        self.shrinkRightBottomPoint = CGPointMake(10, self.scrollView.contentInset.bottom+10);
    } else {
        [self setShrinkRightBottomPoint:self.shrinkRightBottomPoint];
    }
    // 告诉控件层切换到了小屏播放
    [self.controlView sp_playerBottomShrinkPlay];
}

/**
 *  回到cell显示
 */
- (void)updatePlayerViewToCell:(UIView *)fatherView {
    if (!self.isBottomVideo) { return; }
    self.isBottomVideo = NO;
    [self addPlayerToFatherView:fatherView];
    [self.controlView sp_playerCellPlay];
}

#pragma mark - 单击手势

/**
 *   轻拍方法
 *
 *  @param gesture UITapGestureRecognizer
 */
- (void)singleTapAction:(UIGestureRecognizer *)gesture {
    // 小屏播放时单击全屏
    if ([gesture isKindOfClass:[NSNumber class]] && ![(id)gesture boolValue]) {
        if (self.isBottomVideo) {
            [self _fullScreenAction];
        }
        return;
    }
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        if (self.isBottomVideo && !self.isFullScreen) {
            [self _fullScreenAction];
        }
        else {
            [self.controlView sp_playerShowOrHideControlView];
        }
    }
}

#pragma mark - 双击手势

/**
 *  双击播放/暂停
 *
 *  @param gesture UITapGestureRecognizer
 */
- (void)doubleTapAction:(UIGestureRecognizer *)gesture {
    if (_isPauseByUser) { [self play]; }
    else { [self pause]; }
    if (!self.isAutoPlay) {
        self.isAutoPlay = YES;
        [self configSPPlayer];
    }

}

/** 小屏播放时的平移手势，拖动playerView到屏幕任意位置 */
- (void)shrikPanAction:(UIPanGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:[UIApplication sharedApplication].keyWindow];
    SPVideoPlayerView *view = (SPVideoPlayerView *)gesture.view;
    const CGFloat width = view.frame.size.width;
    const CGFloat height = view.frame.size.height;
    const CGFloat distance = 10;  // 离四周的最小边距
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        // x轴的的移动
        if (point.x < width/2) {
            point.x = width/2 + distance;
        } else if (point.x > ScreenWidth - width/2) {
            point.x = ScreenWidth - width/2 - distance;
        }
        // y轴的移动
        if (point.y < height/2) {
            point.y = height/2 + distance;
        } else if (point.y > ScreenHeight - height/2) {
            point.y = ScreenHeight - height/2 - distance;
        }
        
        [UIView animateWithDuration:0.5 animations:^{
            view.center = point;
            self.shrinkRightBottomPoint = CGPointMake(ScreenWidth - view.frame.origin.x - width, ScreenHeight - view.frame.origin.y - height);
        }];
        
    } else {
        view.center = point;
        self.shrinkRightBottomPoint = CGPointMake(ScreenWidth - view.frame.origin.x- view.frame.size.width, ScreenHeight - view.frame.origin.y-view.frame.size.height);
    }
}

/** 全屏 */
- (void)_fullScreenAction {
    if (SPPlayerShared.isLockScreen) {
        [self unLockTheScreen];
        return;
    }
    if (self.isFullScreen) {
        [self interfaceOrientation:UIInterfaceOrientationPortrait];
        self.isFullScreen = NO;
        return;
    } else {
        UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
        if (orientation == UIDeviceOrientationLandscapeRight) {
            [self interfaceOrientation:UIInterfaceOrientationLandscapeLeft];
        } else {
            [self interfaceOrientation:UIInterfaceOrientationLandscapeRight];
        }
        self.isFullScreen = YES;
    }
}

/**
 *  解锁屏幕方向锁定
 */
- (void)unLockTheScreen {
    // 调用AppDelegate单例记录播放状态是否锁屏
    SPPlayerShared.isLockScreen = NO;
    [self.controlView sp_playerLockBtnState:NO];
    self.isLocked = NO;
    [self interfaceOrientation:UIInterfaceOrientationPortrait];
}

#pragma mark - 平移手势

/**
 *  pan手势事件
 *
 *  @param pan UIPanGestureRecognizer
 */
- (void)panDirection:(UIPanGestureRecognizer *)pan {
    //根据在view上Pan的位置，确定是调音量还是亮度
    CGPoint locationPoint = [pan locationInView:self];
    
    // 我们要响应水平移动和垂直移动
    // 根据上次和本次移动的位置，算出一个速率的point
    CGPoint veloctyPoint = [pan velocityInView:self];
    
    // 判断是垂直移动还是水平移动
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:{ // 开始移动
            // 使用绝对值来判断移动的方向
            CGFloat x = fabs(veloctyPoint.x);
            CGFloat y = fabs(veloctyPoint.y);
            if (x > y) { // 水平移动
                // 取消隐藏
                self.panDirection = PanDirectionHorizontalMoved;
                // 给sumTime初值
                CMTime time       = self.player.currentTime;
                self.sumTime      = time.value/time.timescale;
            }
            else if (x < y){ // 垂直移动
                self.panDirection = PanDirectionVerticalMoved;
                // 开始滑动的时候,状态改为正在控制音量
                if (locationPoint.x > self.bounds.size.width / 2) {
                    self.isVolume = YES;
                }else { // 状态改为显示亮度调节
                    self.isVolume = NO;
                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged:{ // 正在移动
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved:{
                    [self horizontalMoved:veloctyPoint.x]; // 水平移动的方法只要x方向的值
                    break;
                }
                case PanDirectionVerticalMoved:{
                    [self verticalMoved:veloctyPoint.y]; // 垂直移动方法只要y方向的值
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case UIGestureRecognizerStateEnded:{ // 移动停止
            // 移动结束也需要判断垂直或者平移
            // 比如水平移动结束时，要快进到指定位置，如果这里没有判断，当我们调节音量完之后，会出现屏幕跳动的bug
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved:{
                    _isPauseByUser = NO;
                    [self seekToTime:self.sumTime completionHandler:nil];
                    // 把sumTime滞空，不然会越加越多
                    self.sumTime = 0;
                    break;
                }
                case PanDirectionVerticalMoved:{
                    // 垂直移动结束后，把状态改为不再控制音量
                    self.isVolume = NO;
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}

/**
 *  pan垂直移动的方法
 *
 *  @param value void
 */
- (void)verticalMoved:(CGFloat)value {
    self.isVolume ? (self.volumeViewSlider.value -= value / 10000) : ([UIScreen mainScreen].brightness -= value / 10000);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SPVideoPlayerBrightnessOrVolumeDidChangedNotification object:nil userInfo:@{@"value":@(self.isVolume ? self.volumeViewSlider.value:[UIScreen mainScreen].brightness),@"isVolume":@(self.isVolume)}];
}

/**
 *  pan水平移动的方法
 *
 *  @param value void
 */
- (void)horizontalMoved:(CGFloat)value {
    self.isDragged = YES;
    
    // 每次滑动需要叠加时间
    self.sumTime += value / 200;
    //转换成CMTime才能给player来控制播放进度
    CMTime dragedCMTime   = CMTimeMake(self.sumTime, 1);
    // 需要限定sumTime的范围
    CMTime totalTime           = self.playerItem.duration;
    CGFloat totalMovieDuration = (CGFloat)totalTime.value/totalTime.timescale;
    if (self.sumTime > totalMovieDuration) { self.sumTime = totalMovieDuration;}
    if (self.sumTime < 0) { self.sumTime = 0; }
    
    if (value == 0) { return; }
    
    SPVideoPlayerPlayProgressState progressState;
    if (value > 0) {
        progressState = SPVideoPlayerPlayProgressStateFastForward; // 快进
    } else { // 否则就是小于0，等于0前面return了
        progressState = SPVideoPlayerPlayProgressStateFastBackForward; // 快退
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:SPVideoPlayerProgressValueChangedNSNotification object:nil userInfo:@{@"currentTime":@(self.sumTime),@"totalTime":@(totalMovieDuration),@"value":@(self.sumTime/totalMovieDuration),@"playProgressState":@(progressState),@"requirePreviewView":@(self.requirePreviewView)}];
    
    if (self.requirePreviewView && self.isFullScreen) {
        [self.imageGenerator cancelAllCGImageGeneration];
        self.imageGenerator.appliesPreferredTrackTransform = YES;
        //self.imageGenerator.maximumSize = CGSizeMake(100, 56);
        __weak typeof(self) weakSelf = self;
        AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef img, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
            if (img) {
                self.thumbImg = [UIImage imageWithCGImage:img];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [weakSelf.controlView sp_playerDraggedWithThumbImage:self.thumbImg];
            });
        };
        [self.imageGenerator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:dragedCMTime]] completionHandler:handler];
    }

}

/**
 *  根据时长求出字符串
 *
 *  @param time 时长
 *
 *  @return 时长字符串
 */
- (NSString *)durationStringWithTime:(int)time {
    // 获取分钟
    NSString *min = [NSString stringWithFormat:@"%02d",time / 60];
    // 获取秒数
    NSString *sec = [NSString stringWithFormat:@"%02d",time % 60];
    return [NSString stringWithFormat:@"%@:%@", min, sec];
}

#pragma mark - Setter

/**
 *  videoURL的setter方法
 *
 *  @param videoURL videoURL
 */
- (void)setVideoURL:(NSURL *)videoURL {
    _videoURL = videoURL;
    
    // 每次加载视频URL都设置重播为NO
    self.repeatToPlay = NO;
    self.playDidEnd   = NO;
    
    // 添加通知
    [self addNotifications];
    
    _isPauseByUser = YES;
    
    // 添加手势
    [self createGesture];
    
}

/**
 *  根据playerItem，来添加移除观察者
 *
 *  @param playerItem playerItem
 */
- (void)setPlayerItem:(AVPlayerItem *)playerItem {
    if (_playerItem == playerItem) {return;}
    
    if (_playerItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
        [_playerItem removeObserver:self forKeyPath:@"status"];
        [_playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [_playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [_playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    }
    _playerItem = playerItem;
    if (playerItem) {
        // 通知,监听播放结束
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];

        // KVO监听，播放状态
        [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        // KVO监听，缓冲区空了，需要等待数据
        [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
        // KVO监听,缓冲区有足够数据可以播放了
        [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    }
}

/**
 *  根据player，来添加移除观察者
 *
 *  @param player player
 */
- (void)setPlayer:(AVPlayer *)player {
    if (_player == player) {return;}
    if (_player) {
        [_player removeObserver:self forKeyPath:@"rate" context:nil];
    }
    _player = player;
    if (player) {
        [player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
    }
}

/**
 *  根据tableview的值来添加、移除观察者
 *
 *  @param scrollView tableView
 */
- (void)setScrollView:(UIScrollView *)scrollView {
    if (_scrollView == scrollView) { return; }
    if (_scrollView) {
        [_scrollView removeObserver:self forKeyPath:kSPPlayerViewContentOffset];
    }
    _scrollView = scrollView;
    if (scrollView) { [scrollView addObserver:self forKeyPath:kSPPlayerViewContentOffset options:NSKeyValueObservingOptionNew context:nil]; }
}

/**
 *  设置playerLayer的填充模式
 *
 *  @param playerLayerGravity playerLayerGravity
 */
- (void)setPlayerLayerGravity:(SPPlayerLayerGravity)playerLayerGravity {
    _playerLayerGravity = playerLayerGravity;
    switch (playerLayerGravity) {
        case SPPlayerLayerGravityResize:
            self.playerLayer.videoGravity = AVLayerVideoGravityResize;
            self.videoGravity = AVLayerVideoGravityResize;
            break;
        case SPPlayerLayerGravityResizeAspect:
            self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
            self.videoGravity = AVLayerVideoGravityResizeAspect;
            break;
        case SPPlayerLayerGravityResizeAspectFill:
            self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            self.videoGravity = AVLayerVideoGravityResizeAspectFill;
            break;
        default:
            break;
    }
}

- (void)setResumePlayFromLastStopPoint:(BOOL)resumePlayFromLastStopPoint {
    _resumePlayFromLastStopPoint = resumePlayFromLastStopPoint;
    if (self.videoItem.seekTime) {
        self.seekTime = self.videoItem.seekTime;
    } else {
        self.seekTime = 0;
    }
}

/**
 *  是否有下载功能
 */
- (void)setHasDownload:(BOOL)hasDownload {
    _hasDownload = hasDownload;
    [self.controlView sp_playerHasDownloadFunction:hasDownload];
}

/** 分辨率字典 */
- (void)setResolutionDic:(NSDictionary *)resolutionDic {
    _resolutionDic = resolutionDic;
    self.videoURLArray = [resolutionDic allValues];
}

/** 控件层 */
- (void)setControlView:(UIView *)controlView {
    if (_controlView) { return; }
    _controlView = controlView;
    controlView.delegate = self;
    if (controlView != nil) {
        [self addSubview:controlView];
    }
}

/** 模型 */
- (void)setVideoItem:(SPVideoItem *)videoItem {
    // 特加此判断提醒开发者视频地址要转为url
    if ([videoItem.videoURL isKindOfClass:[NSString class]]) {
        NSLog(@"您的视频地址是字符串类型，请转化为url");
        return;
    }
    _videoItem = videoItem;
    
    if (SPSeekTimeKey) {
        if (self.resumePlayFromLastStopPoint) {
            // 获取上一次停止播放的时间点
            self.seekTime = [[NSUserDefaults standardUserDefaults] floatForKey:SPSeekTimeKey];
            if (!self.seekTime) {
                self.seekTime = videoItem.seekTime;
            }
        } else {
            if (videoItem.seekTime) {
                self.seekTime = videoItem.seekTime;
            }
        }
    }
    
    // 分辨率
    if (videoItem.resolutionDic) {
        self.resolutionDic = videoItem.resolutionDic;
    }
    
    if (videoItem.scrollView && videoItem.indexPath && videoItem.videoURL) {
        NSCAssert(videoItem.fatherViewTag, @"请指定playerViews所在的faterViewTag");
        [self cellVideoWithScrollView:videoItem.scrollView AtIndexPath:videoItem.indexPath];
        if ([self.scrollView isKindOfClass:[UITableView class]]) {
            UITableView *tableView = (UITableView *)videoItem.scrollView;
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:videoItem.indexPath];
            // 在tableViewcell上寻找fatherView
            UIView *fatherView = [self lookforFatherViewInTableViewcell:cell];
            [self addPlayerToFatherView:fatherView];
        } else if ([self.scrollView isKindOfClass:[UICollectionView class]]) {
            UICollectionView *collectionView = (UICollectionView *)videoItem.scrollView;
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:videoItem.indexPath];
            // 在collectionViewcell上寻找fatherView
            UIView *fatherView = [self lookforFatherViewInCollectionViewcell:cell];
            [self addPlayerToFatherView:fatherView];
        }
    } else {
        NSCAssert(videoItem.fatherView, @"请指定playerView的faterView");
        [self addPlayerToFatherView:videoItem.fatherView];
    }
    // 先在沙盒中看有没有存储过url
    if (SPURLKey) {
        NSString *cacheUrl = [[NSUserDefaults standardUserDefaults] objectForKey:SPURLKey];
        if (cacheUrl) {
            self.videoURL = [NSURL URLWithString:cacheUrl];
        } else {
            self.videoURL = videoItem.videoURL;
        }
    } else {
        self.videoURL = videoItem.videoURL;
    }
    // 给控制层传递模型和当前正在播放的url，self.videoURL和playerItem.videoUR并一直是一样的，切换分辨率后self.videoURL会发生改变
    [self.controlView sp_setPlayerItem:videoItem playingUrlString:self.videoURL.absoluteString];

}

/** playerView一半不可见 */
- (void)setStopPlayWhenPlayerHalfInvisable:(BOOL)stopPlayWhenPlayerHalfInvisable {
    _stopPlayWhenPlayerHalfInvisable = stopPlayWhenPlayerHalfInvisable;
    _stopPlayWhenPlayerWholeInvisable = !_stopPlayWhenPlayerHalfInvisable;
    _switchToSmallScreenPlayWhenPlayerInvisable = !_stopPlayWhenPlayerHalfInvisable;
}

/** playerView整个不可见 */
- (void)setStopPlayWhenPlayerWholeInvisable:(BOOL)stopPlayWhenPlayerWholeInvisable {
    _stopPlayWhenPlayerWholeInvisable = stopPlayWhenPlayerWholeInvisable;
    _stopPlayWhenPlayerHalfInvisable = !_stopPlayWhenPlayerWholeInvisable;
    _switchToSmallScreenPlayWhenPlayerInvisable = !_stopPlayWhenPlayerWholeInvisable;
}

/** 切换到小屏 */
- (void)setSwitchToSmallScreenPlayWhenPlayerInvisable:(BOOL)switchToSmallScreenPlayWhenPlayerInvisable {
    _switchToSmallScreenPlayWhenPlayerInvisable = switchToSmallScreenPlayWhenPlayerInvisable;
    _stopPlayWhenPlayerHalfInvisable = !switchToSmallScreenPlayWhenPlayerInvisable;
    _stopPlayWhenPlayerWholeInvisable = !switchToSmallScreenPlayWhenPlayerInvisable;
}

/**  小屏播放时距离右边和底部的点  */
- (void)setShrinkRightBottomPoint:(CGPoint)shrinkRightBottomPoint {
    _shrinkRightBottomPoint = shrinkRightBottomPoint;
    if (!self.bounds.size.width) {
        return;
    }
    CGFloat width = ScreenWidth*0.5-20;
    CGFloat height = width*(self.bounds.size.height / self.bounds.size.width);
    CGRect selfFrame = self.frame;
    selfFrame.size.width = width;
    selfFrame.size.height = height;
    selfFrame.origin.x = ScreenWidth-width-_shrinkRightBottomPoint.x;
    selfFrame.origin.y = ScreenHeight-height-_shrinkRightBottomPoint.y;
    self.frame = selfFrame;
    [self layoutIfNeeded];
}

/** push还是present */
- (void)setPlayerPushedOrPresented:(BOOL)playerPushedOrPresented {
    _playerPushedOrPresented = playerPushedOrPresented;
    if (playerPushedOrPresented) {
        [self pause];
    } else {
        [self play];
    }
}

/** 媒体加载状态 */
- (void)setLoadStatus:(SPVideoPlayerLoadStatus)loadStatus {
    _loadStatus = loadStatus;
    // 发出网络状态改变的通知,通知里存储了网络状态和缓存是否为空的标识
    [[NSNotificationCenter defaultCenter] postNotificationName:SPVideoPlayerLoadStatusDidChangedNotification object:nil userInfo:@{@"loadStatus":@(loadStatus),@"bufferEmpty":@(!self.playerItem.playbackLikelyToKeepUp)}];

}

#pragma mark - Getter

- (AVAssetImageGenerator *)imageGenerator {
    if (!_imageGenerator) {
        _imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.urlAsset];
    }
    return _imageGenerator;
}

- (SPBrightnessView *)brightnessView {
    if (!_brightnessView) {
        _brightnessView = [SPBrightnessView sharedBrightnessView];
    }
    return _brightnessView;
}

- (NSString *)videoGravity {
    if (!_videoGravity) {
        _videoGravity = AVLayerVideoGravityResizeAspect;
    }
    return _videoGravity;
}

#pragma mark - UIGestureRecognizerDelegate(手势代理)

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    if (gestureRecognizer == self.shrinkPanGesture && self.isCellVideo) {
        if (!self.isBottomVideo || self.isFullScreen) {
            return NO;
        }
    }
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && gestureRecognizer != self.shrinkPanGesture) {
        // 在cell上播放且非全屏或者播放结束或者锁屏都不具有平移手势
        if ((self.isCellVideo && !self.isFullScreen) || self.isLocked){
            return NO;
        }
    }
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        if (self.isBottomVideo && !self.isFullScreen) {
            return NO;
        }
    }
    for (UIView *subView in self.controlView.subviews) {
        // 如果当前手势处于controlView的任何一个子控件之内，都屏蔽掉
        // 如果subView还有子控件，touch.view刚好作用在该子控件上，且subView是不可见状态，则按理说必然不会进入下面的if语句，但是值得注意的是：subView不可见(alpha<0.01)了，subView的子控件原理上被视为超出了父控件，于是subView的子控件不具有event，因此，假如在subView中重写了hitTest:withEvent:方法，并让subView的子控件超出父控件仍然有event,那么即便subView不可见了，subView的子控件仍然可以接收到它应有的event，所以在重写hitTest:withEvent:方法的时候要判断一下subView是不是不可见，只有可见时才让子控件超出父控件有事件
        if ([touch.view isDescendantOfView:subView]) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - SPPlayerControlViewDelegate(控件层的代理方法)

/** 点击播或放暂停按钮的代理方法 */
- (void)sp_controlViePlayOrPauseButtonClicked:(UIButton *)sender {
    _isPauseByUser = !_isPauseByUser;
    if (_isPauseByUser) {
        [self pause];
    } else {
        [self play];
    }
    
    if (!self.player) {
        [self configSPPlayer];
    }
}

/** 点击了下一个视频按钮的代理方法 */
- (void)sp_controlViewNextButtonClicked:(UIButton *)sender {
    self.dragedSeconds = 0;
    if (self.videoItems.count == 0) {
        // 如果数组没有值，则下一集就设置为重播
        // 没有播放完
        self.playDidEnd   = NO;
        // 重播改为NO
        self.repeatToPlay = NO;
        [self seekToTime:0 completionHandler:nil];
        
        return;
    }
    self.nextBtnClicked = YES;
    // 根据当前模型获取其在数组中的位置
    NSInteger index = [self.videoItems indexOfObject:self.videoItem];
    // 如果是最后一集的下一集，则从第一集开始播放
    if (index+1 > self.videoItems.count-1) {
        index = -1;
    }
    // 取出下一个视频模型进行播放
    SPVideoItem *videoItem = self.videoItems[index+1];
    // 播放新的视频
    [self resetToPlayNewVideo:videoItem];
    self.nextBtnClicked     = NO;
}

/** 点击了上一个视频按钮的代理方法 */
- (void)sp_controlViewLastButtonClicked:(UIButton *)sender {
    self.dragedSeconds = 0;
    // 根据当前模型获取其在数组中的位置
    NSInteger index = [self.videoItems indexOfObject:self.videoItem];
    if (self.videoItems.count == 0 ||index-1 < 0) {
        // 如果数组没有值，则下一集就设置为重播
        // 没有播放完
        self.playDidEnd   = NO;
        // 重播改为NO
        self.repeatToPlay = NO;
        [self seekToTime:0 completionHandler:nil];
        
        return;
    }
    // 实际上是标记上一个按钮被点击
    self.nextBtnClicked = YES;
    // 取出下一个视频模型进行播放
    SPVideoItem *videoItem = self.videoItems[index-1];
    // 播放新的视频
    [self resetToPlayNewVideo:videoItem];
    self.nextBtnClicked = NO;
}

/** 全屏按钮的代理方法 */
- (void)sp_controlViewFullScreenButtonClicked:(UIButton *)sender {
    [self _fullScreenAction];
}

/** 切换分辨率的代理方法 */
- (void)sp_controlViewSwitchResolutionWithUrl:(NSString *)urlString {
    
    // 记录切换分辨率的时刻
    NSInteger currentTime = (NSInteger)CMTimeGetSeconds([self.player currentTime]);
    NSURL *videoURL = [NSURL URLWithString:urlString];
    if ([videoURL isEqual:self.videoURL]) { return; }
    self.isChangeResolution = YES;
    // reset player
    [self resetToPlayNewURL];
    self.videoURL = videoURL;
    // 从xx秒播放
    self.seekTime = currentTime;
    // 切换完分辨率开始播放
    [self startPlay];

}

/** 拖动滑动条的代理方法 */
- (void)sp_controlViewSliderValueChanged:(UISlider *)slider {
    // 拖动改变视频播放进度
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        self.isDragged = YES;
        CGFloat value   = slider.value - self.sliderLastValue;
        
        if (value == 0) {return;}
        
        self.sliderLastValue  = slider.value;
        
        CGFloat totalTime     = (CGFloat)_playerItem.duration.value / _playerItem.duration.timescale;
        
        //计算出拖动的当前秒数
        CGFloat dragedSeconds = floorf(totalTime * slider.value);
        
        //转换成CMTime才能给player控制播放进度
        CMTime dragedCMTime   = CMTimeMake(dragedSeconds, 1);
        
        SPVideoPlayerPlayProgressState progressState;
        if (value > 0) {
            progressState = SPVideoPlayerPlayProgressStateFastForward; // 快进
        } else { // 否则就是小于0，等于0前面return了
            progressState = SPVideoPlayerPlayProgressStateFastBackForward; // 快退
        }
        // 发送通知
        [[NSNotificationCenter defaultCenter] postNotificationName:SPVideoPlayerProgressValueChangedNSNotification object:nil userInfo:@{@"currentTime":@(dragedSeconds),@"totalTime":@(totalTime),@"value":@(dragedSeconds/totalTime),@"playProgressState":@(progressState),@"requirePreviewView":@(self.requirePreviewView)}];
        
        if (totalTime > 0) { // 当总时长 > 0时候才能拖动slider
            
            if (self.requirePreviewView && self.isFullScreen) {
                [self.imageGenerator cancelAllCGImageGeneration];
                //截图的时候调整到正确的方向
                self.imageGenerator.appliesPreferredTrackTransform = YES;
                // 最大分辨率,设置之后分会较模糊
                //self.imageGenerator.maximumSize = CGSizeMake(100, 56);
                AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef img, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
                    if (img) {
                        self.thumbImg = [UIImage imageWithCGImage:img];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.controlView sp_playerDraggedWithThumbImage:self.thumbImg];
                    });
                };
                [self.imageGenerator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:dragedCMTime]] completionHandler:handler];
            }
        } else {
            // 此时设置slider值为0
            slider.value = 0;
        }
    }else { // player状态加载失败
        // 此时设置slider值为0
        slider.value = 0;
        
    }
    
}

/** 滑动条滑动结束的代理方法 */
- (void)sp_controlViewSliderTouchEnded:(UISlider *)slider {
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        _isPauseByUser = NO;
        self.isDragged = NO;
        // 视频总时间长度
        CGFloat total           = (CGFloat)_playerItem.duration.value / _playerItem.duration.timescale;
        //计算出拖动的当前秒数
        double dragedSeconds = floorf(total * slider.value);
        [self seekToTime:dragedSeconds completionHandler:nil];
    }
}

/** 单击滑动条的代理方法 */
- (void)sp_controlViewSliderTaped:(CGFloat)value {
    // 视频总时间长度
    CGFloat total = (CGFloat)self.playerItem.duration.value / self.playerItem.duration.timescale;
    //计算出拖动的当前秒数
    NSInteger dragedSeconds = floorf(total * value);
    
    [self seekToTime:dragedSeconds completionHandler:^(BOOL finished) {}];
    
}

/** 快进的代理方法 */
- (void)sp_controlViewFast_forward {
    CGFloat currentTime = CMTimeGetSeconds([self.player currentTime]);
    CGFloat total = (CGFloat)self.playerItem.duration.value / self.playerItem.duration.timescale;
    currentTime += total/20;
    if (currentTime >= total) {
        currentTime = total;
    }
    [self seekToTime:currentTime completionHandler:^(BOOL finished) {}];
}

/** 快退的代理方法 */
- (void)sp_controlViewFast_backward {
    CGFloat currentTime = CMTimeGetSeconds([self.player currentTime]);
    CGFloat total = (CGFloat)self.playerItem.duration.value / self.playerItem.duration.timescale;
    currentTime -= total/20;
    if (currentTime <= 0) {
        currentTime = 0;
    }
    [self seekToTime:currentTime completionHandler:^(BOOL finished) {}];
}

/** 返回按钮的代理方法 */
- (void)sp_controlViewBackButtonClicked:(UIButton *)sender {
    if (SPPlayerShared.isLockScreen) {
        [self unLockTheScreen];
    } else {
        if (!self.isFullScreen) {
            // player加到控制器上，只有一个player时候
            [self pause];
            if ([self.delegate respondsToSelector:@selector(sp_playerBackAction)]) { [self.delegate sp_playerBackAction]; }
        } else {
            [self interfaceOrientation:UIInterfaceOrientationPortrait];
        }
    }
}

/** 锁定屏幕方向按钮的代理方法 */
- (void)sp_controlViewLockScreenButtonClicked:(UIButton *)sender {
    
    self.isLocked               = sender.selected;
    // 调用AppDelegate单例记录播放状态是否锁屏
    SPPlayerShared.isLockScreen = sender.selected;
}

/** 视频截图的代理方法 */
- (void)sp_controlViewCutButtonClicked:(UIButton *)sender {
    
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:self.urlAsset];
    imageGenerator.appliesPreferredTrackTransform = YES; // 截图的时候调整到正确的方向
    CMTime time = CMTimeMakeWithSeconds(CMTimeGetSeconds(self.playerItem.currentTime), 600); // 1.0为截取视频1.0秒处的图片，600为每秒600帧
    NSError *error = nil;
    CGImageRef cgImage = [imageGenerator copyCGImageAtTime:time actualTime:nil error:&error];
    
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    if (!image) {
        NSLog(@"截图失败");
        return;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SPVideoPlayerCutVideoFinishedNSNotification object:image];
}

/** 小屏播放时的关闭按钮的代理方法 */
- (void)sp_controlViewCloseButtonClicked:(UIButton *)sender {
    [self resetPlayer];
    [self removeFromSuperview];
}

/** 重播按钮的代理方法 */
- (void)sp_controlViewRepeatButtonClicked:(UIButton *)sender {
    // 没有播放完
    self.playDidEnd   = NO;
    // 重播改为NO
    self.repeatToPlay = NO;
    [self seekToTime:0 completionHandler:nil];
    
    [[SPNetworkReachabilityManager sharedManager] startMonitoring];
}

/** 下载按钮的代理方法 */
- (void)sp_controlViewDownloadButtonClicked:(UIButton *)sender {
    NSString *urlStr = self.videoURL.absoluteString;
    if ([self.delegate respondsToSelector:@selector(sp_playerDownload:)]) {
        NSString *filePath = [self.delegate sp_playerDownload:urlStr];
        // 删除上一次存储的时间，如果不删除，则删除下载的文件后重新下载，仍然可以拿到删除之前的文件存储的seekTime，我们要的是重新下载后应该从0开始播放,分辨率亦是如此
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:filePath.lastPathComponent.md5String];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:filePath.lastPathComponent];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

/** 刷新重试 */
- (void)sp_controlViewRefreshButtonClicked:(UIButton *)sender {
    // 开启网络监听
    [[SPNetworkReachabilityManager sharedManager] startMonitoring];
    
    if (!_isPauseByUser) {
        _isPauseByUser = NO;
        [self play];
    }
    if (!self.player) {
        self.isAutoPlay = YES;
        [self configSPPlayer];
    }
}

/** 控制层即将显示的代理方法 */
- (void)sp_controlViewWillShow:(UIView *)controlView isFullscreen:(BOOL)fullscreen {
    if ([self.delegate respondsToSelector:@selector(sp_playerControlViewWillShow:isFullscreen:)]) {
        [self.delegate sp_playerControlViewWillShow:controlView isFullscreen:fullscreen];
    }
}

/** 控制层即将隐藏的代理方法 */
- (void)sp_controlViewWillHidden:(UIView *)controlView isFullscreen:(BOOL)fullscreen {
    if ([self.delegate respondsToSelector:@selector(sp_playerControlViewWillHidden:isFullscreen:)]) {
        [self.delegate sp_playerControlViewWillHidden:controlView isFullscreen:fullscreen];
    }
}

#pragma clang diagnostic pop

@end


#import <CommonCrypto/CommonDigest.h>

@implementation NSString (MD5)

- (NSString *)md5String {
    
    const char *string = self.UTF8String;
    int length = (int)strlen(string);
    unsigned char bytes[CC_MD5_DIGEST_LENGTH];
    CC_MD5(string, length, bytes);
    return [self stringFromBytes:bytes length:CC_MD5_DIGEST_LENGTH];
}

- (NSString *)stringFromBytes:(unsigned char *)bytes length:(NSInteger)length {
    
    NSMutableString *mutableString = @"".mutableCopy;
    for (int i = 0; i < length; i++)
        [mutableString appendFormat:@"%02x", bytes[i]];
    return [NSString stringWithString:mutableString];
}

@end


