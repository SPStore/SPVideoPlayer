## 功能
* 支持横竖屏切换
* 支持从上一次终止播放的地方继续播放
* 支持水平滑动屏幕和使用滑动条快进快退,并在横屏模式下有预览图
* 支持音量调节(右半屏幕垂直滑动)和亮度调节(左半屏幕垂直滑动)
* 支持网络视频和本地视频播放
* 支持多视频播放，可播放下一集
* 支持cell上播放，并可设置当cell(整个cell或一半cell)滑出屏幕时终止播放、可设置小屏播放
* 提供锁屏、截图功能
* 支持分辨率切换
* 含有视频下载功能
* 含有网络监听
* 可自定义播放界面(即控制层，默认的控制层是SPVideoPlayerControlView)

## 如何使用
```C
// 创建视频播放的模型
- (SPVideoItem *)videoItem { 
    if (!_videoItem) {
        _videoItem                  = [[SPVideoItem alloc] init];
        _videoItem.title            = @"视频标题";
        _videoItem.videoURL         = [NSURL URLWithString:_videoModel.playUrl];
        _videoItem.placeholderImage = [UIImage imageNamed:@"qyplayer_aura2_background_normal_iphone_375x211_"];
        // playerView的父视图
        _videoItem.fatherView       = self.playerFatherView;
    }
    return _videoItem;
}

// 创建播放器对象
- (SPVideoPlayerView *)playerView {
    if (!_playerView) {
        // 创建，如果是cell上播放，用sharedPlayerView单例创建
        _playerView = [[SPVideoPlayerView alloc] init];
       // 这一步非常重要，这一步相当于设置了控制层和视频模型,如果控制层传nil，则默认自带的的控制层
        [_playerView configureControlView:nil videoItem:self.videoItem]; 
        // 如果有多个视频需要播放，如电视剧有很多集，则用这个方法
        //[_playerView configureControlView:nil videoItems:self.videoItems];
        // 设置代理
        _playerView.delegate = self;
        // 打开下载功能（默认没有这个功能）
        _playerView.hasDownload    = YES;
        // 打开预览图,默认是打开的
        _playerView.requirePreviewView = YES;
    }
    return _playerView;
}
注：您无需手动添加playerView，[_playerView configureControlView:nil videoItem:self.videoItem];这一步内部会自动将playerView添加到模型中指定的fatherView上去
``` 
```
// 开始播放，只有调用startPlay才会开始播放
[self.playerView startPlay];
```

## 如何自定义播放界面 
```
[self.playerView configureControlView:这里传你自定义的界面 videoItem:这里传视频模型];
```
你搭建完界面之后，必然会有很多控件，如播放暂停按钮，滑动条，全屏按钮，返回按钮，下载按钮等，那么这些控件触发的方法该如何实现呢，这个非常简单,你不需要去关心怎么做，这些事情全都交给代理去做，代理就是播放层SPVideoPlayerView,代理方法详见框架中的SPVideoPlayerControlViewDelegate
例：
```
// 下一集按钮的触发方法
- (void)nextButtonAction:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(sp_controlViewNextButtonClicked:)]) {
        [self.delegate sp_controlViewNextButtonClicked:sender];
    }
}
```
播放层有一些事件发生了变化，控制层也需要发生变化，如正在水平滑动屏幕进行快进快退，那控制层的滑动条就需要跟随这个进度，这里你自定义的控制层就需要监听播放层所发出的通知，如：
```
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
```


另外还有几个方法值得你关心,这些方法(见框架中的分类文件夹里头的“UIView+CustomControlView”)如下：(这些方法的具体实现可以参考框架中的SPVideoPlayerControlView.m)
```
/** 
 *  实现此方法，控制层可以得到播放模型以及正在播放的视频url，正在播放的url并不一定是模型中的url，有可能是分辨率字典中的某一个
 */
- (void)sp_setPlayerItem:(SPVideoItem *)videoItem playingUrlString:(NSString *)playingUrlString;

/**
 *  实现此方法，单击播放器时可以显示或隐藏控制层
 */
- (void)sp_playerShowOrHideControlView;

/** 
 *  实现此方法，重置ControlView，如播放新的视频，播放结束等都需要重置
 */
- (void)sp_playerResetControlView;

/**
 *  实现此方法，可以设置快进快退时的预览视图
 */
- (void)sp_playerDraggedWithThumbImage:(UIImage *)thumbImage;

/** 
 *  实现此方法，可以决定是否要下载按钮
 */
- (void)sp_playerHasDownloadFunction:(BOOL)sender;

/**
 *  实现此方法，可以设置下载按钮的状态，如可下载状态和不可下载状态
 */
- (void)sp_playerDownloadBtnState:(BOOL)state;

/** 
 *  实现此方法, 可以设置锁定屏幕方向按钮的状态，如选中状态和未选中状态
 */
- (void)sp_playerLockBtnState:(BOOL)state;

/**
 *  实现此方法，可以设置在cell上播放时，控制层的相关设置
 */
- (void)sp_playerCellPlay;

/**
 *  实现此方法，可以设置小屏播放时，控制层的相关设置
 */
- (void)sp_playerBottomShrinkPlay;
```

