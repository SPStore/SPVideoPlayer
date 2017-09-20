//
//  ZFTableViewController.m
//
//  Created by leshengping on 17/8/23.
//  Copyright © 2017年 leshengping. All rights reserved.
//

#import "SPTableViewController.h"
#import "SPTableViewCell.h"
#import "SPVideoModel.h"
#import "SPVideoResolution.h"
#import "SPVideoPlayer.h"
#import "SPDownload.h"

@interface SPTableViewController () <SPVideoPlayerDelegate>

@property (nonatomic, strong) NSMutableArray      *dataSource;
@property (nonatomic, strong) NSMutableArray      *dicArray;
@property (nonatomic, strong) SPVideoPlayerView        *playerView;
@property (nonatomic, strong) SPVideoPlayerControlView *controlView;

@end

@implementation SPTableViewController

#pragma mark - life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.estimatedRowHeight = 379.0f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, CGFLOAT_MIN)];
    self.tableView.tableHeaderView = view;
    self.tableView.tableFooterView = view;
    self.tableView.sectionFooterHeight = CGFLOAT_MIN;
    
    [self requestData];
}

// 页面消失时候
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.playerView stop];
}

- (void)dealloc {
    self.playerView = nil;
}

- (void)requestData {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"videoData" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *rootDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    self.dataSource = @[].mutableCopy;
    self.dicArray = [rootDict objectForKey:@"videoList"];
    
    // 字典转模型
    self.dataSource = [SPVideoModel modelForDictArray:self.dicArray];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    // 这里设置横竖屏不同颜色的statusbar
    if (SPPlayerShared.isLandscape) {
        return UIStatusBarStyleLightContent;
    }
    return UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden {
    return SPPlayerShared.isStatusBarHidden;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataSource.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *identifier        = @"playerTableViewCell";
    SPTableViewCell *cell                 = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    // 取到对应cell的model
    __block SPVideoModel *model        = self.dataSource[indexPath.section];
    // 赋值model
    cell.model                         = model;
    __block NSIndexPath *weakIndexPath = indexPath;
    __block SPTableViewCell *weakCell  = cell;
    __weak typeof(self)  weakSelf      = self;
    // 点击播放的回调
    cell.playBlock = ^(UIButton *btn){
        
        // 分辨率字典（key:分辨率名称，value：分辨率url)
        NSMutableDictionary *dic = @{}.mutableCopy;
        for (SPVideoResolution * resolution in model.playInfo) {
            [dic setValue:resolution.url forKey:resolution.name];
        }
        
        SPVideoItem *videoItem = [[SPVideoItem alloc] init];
        videoItem.title            = model.title;
        videoItem.videoURL         = [NSURL URLWithString:model.playUrl];
        // 取出所有开启了下载的数据字典
        NSMutableArray *dicArr = [NSKeyedUnarchiver unarchiveObjectWithFile:downloadURLPath];
        for (NSDictionary *dic in dicArr) {
            if ([dic.allValues containsObject:model.playUrl]) { // 说明该模型的playUrl正处于下载队列
                SPDownloadInfo *info = [[SPDownloadManager defaultManager] downloadInfoForURL:model.playUrl];
                if (info.state == SPDownloadStateCompleted) { // 如果下载完成了
                    // 修改网络视频为本地视频
                    videoItem.videoURL = [NSURL fileURLWithPath:info.file];
                }
            }
        }
    
        videoItem.scrollView       = weakSelf.tableView;
        videoItem.indexPath        = weakIndexPath;
        // 赋值分辨率字典
        videoItem.resolutionDic    = dic;
        // player的父视图tag
        videoItem.fatherViewTag    = weakCell.videoContentView.tag;
        
        // 设置播放控制层和model
        [weakSelf.playerView configureControlView:nil videoItem:videoItem];
        // 下载功能
        weakSelf.playerView.hasDownload = YES;
        // 自动播放
        [weakSelf.playerView startPlay];
    };
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"didSelectRowAtIndexPath---%zd",indexPath.section);
}

- (SPVideoPlayerView *)playerView {
    if (!_playerView) {
        _playerView = [SPVideoPlayerView sharedPlayerView];
        _playerView.delegate = self;
        // 当cell播放视频由全屏变为小屏时候，不回到中间位置
        _playerView.cellPlayerOnCenter = NO;
        //_playerView.stopPlayWhenPlayerWholeInvisable = YES;
        _playerView.switchToSmallScreenPlayWhenPlayerInvisable = YES;
        
        // 静音
        // _playerView.mute = YES;
    }
    return _playerView;
}


#pragma mark - SPVideoPlayerDelegate

- (NSString *)sp_playerDownload:(NSString *)url {
    
    
    NSLog(@"tableView- 开始下载了");
    
    // 开启下载
    SPDownloadInfo *info = [[SPDownloadManager defaultManager] download:url];
    
    // 谓词搜索(在字典数组中搜索出与当前下载的url一致的字典)
    NSDictionary *dic = [self.dicArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"playUrl==%@", url]].firstObject;
    
    // 将正在下载的url对应的字典存入数组，再保存到本地,之所以存储字典不存储模型，是因为模型存起来挺麻烦，存储模型必须遵守NSCoding协议，而且要实现- (void)encodeWithCoder:(NSCoder *)aCoder;- (id)initWithCoder:(NSCoder *)aDecoder;这2个方法;如果模型中有数组，数组中又是模型，那此模型也得遵守NSCoding协议和实现那2个方法,如果模型中含有非基本类型的属性，如NSError，也无法存储
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


@end
