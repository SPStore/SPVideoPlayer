    //
//  MoviePlayerViewController.m
//
// Copyright (c) 2017年 leshengping
// 

#import "MoviePlayerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "SPVideoPlayer.h"
#import "UINavigationController+FDFullscreenPopGesture.h"
#import "SPDownload.h"
#import "SPVideoModel.h"

@interface MoviePlayerViewController () <SPVideoPlayerDelegate>
/** 播放器View的父视图*/
@property (strong, nonatomic)  UIView *playerFatherView;
@property (strong, nonatomic)  SPVideoPlayerView *playerView;
/** 离开页面时候是否在播放 */
@property (nonatomic, assign) BOOL isPlaying;
/** 播放模型 */
@property (nonatomic, strong) SPVideoItem *videoItem;
/** 播放模型数组 */
@property (nonatomic, strong) NSMutableArray<SPVideoItem *> *videoItems;
@property (weak, nonatomic) IBOutlet UIButton *backBtn;

@end

@implementation MoviePlayerViewController

- (void)dealloc {
    NSLog(@"%@释放了",self.class);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // pop回来时候是否自动播放
    if (self.navigationController.viewControllers.count == 2 && self.playerView && self.isPlaying) {
        self.isPlaying = NO;
        self.playerView.playerPushedOrPresented = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // push出下一级页面时候暂停
    if (self.navigationController.viewControllers.count == 3 && self.playerView && !self.playerView.isPauseByUser)
    {
        self.isPlaying = YES;
        self.playerView.playerPushedOrPresented = YES;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.fd_prefersNavigationBarHidden = YES;
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.playerFatherView];
    // 开始播放，默认不开始播放
    [self.playerView startPlay];

}

// 返回值要必须为NO
- (BOOL)shouldAutorotate {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {

    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    return SPPlayerShared.isStatusBarHidden;
}

#pragma mark - Getter

- (UIView *)playerFatherView {
    
    if (!_playerFatherView) {
        _playerFatherView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth,  ScreenWidth*ScreenWidth/ScreenHeight)];
    }
    return _playerFatherView;
}


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

- (SPVideoPlayerView *)playerView {
    if (!_playerView) {
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

// 下面两个方法在播放多个视频时才有用
- (NSMutableArray *)videoItems {
    if (!_videoItems) {
        _videoItems = [NSMutableArray array];
    }
    return _videoItems;
}

- (void)setVideoModels:(NSArray *)videoModels {
    _videoModels = videoModels;
    for (int i = 0; i < videoModels.count; i++) {
        SPVideoModel *videoModel = videoModels[i];
        SPVideoItem *videoItem = [[SPVideoItem alloc] init];
        videoItem.title            = videoModel.title;
        videoItem.videoURL         = [NSURL URLWithString:videoModel.playUrl];
        videoItem.placeholderImage = [UIImage imageNamed:@"qyplayer_aura2_background_normal_iphone_375x211_"];
        videoItem.fatherView       = self.playerFatherView;
        [self.videoItems addObject:videoItem];
    }
}

#pragma mark - SPVideoPlayerDelegate

- (void)sp_playerBackAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSString *)sp_playerDownload:(NSString *)url {
    
    NSLog(@"开始下载");
    
    // 开启下载
    SPDownloadInfo *info = [[SPDownloadManager defaultManager] download:url];
    
    // 谓词搜索(在字典数组中搜索出与当前下载的url一致的字典,之所以不在模型数组中搜索是因为模型不好存储)
    NSDictionary *dic = [self.videoList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"playUrl==%@", url]].firstObject;
    
    // 将正在下载的url对应的字典存入数组，再保存到本地
    // 先从本地中取出来(解档)
    NSMutableArray *dicArr = [NSKeyedUnarchiver unarchiveObjectWithFile:downloadURLPath];
    // 如果本地还未存储任何数据，则新建数组
    if (dicArr.count == 0) {
        NSMutableArray *myDicArr = [NSMutableArray array];
        [myDicArr addObject:dic];
        // 归档
        [NSKeyedArchiver archiveRootObject:myDicArr toFile:downloadURLPath];
    } else { // 本地已经有了，无需新建数组
        if (![dicArr containsObject:dic]) { // 不存在才添加,防止重复添加
            [dicArr addObject:dic];
            // 归档
            [NSKeyedArchiver archiveRootObject:dicArr toFile:downloadURLPath];
        }
    }
    return info.file;
}

- (void)sp_playerControlViewWillShow:(UIView *)controlView isFullscreen:(BOOL)fullscreen {
    //    self.backBtn.hidden = YES;
    [UIView animateWithDuration:0.25 animations:^{
        self.backBtn.alpha = 0;
    }];
}

- (void)sp_playerControlViewWillHidden:(UIView *)controlView isFullscreen:(BOOL)fullscreen {
    //    self.backBtn.hidden = fullscreen;
    [UIView animateWithDuration:0.25 animations:^{
        self.backBtn.alpha = !fullscreen;
    }];
}

@end
