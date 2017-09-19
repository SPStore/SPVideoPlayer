//
//  SecondViewController.m
//
// Copyright (c) 2017年 leshengping
//

#import "SPVideoListViewController.h"
#import "MoviePlayerViewController.h"
#import "SPVideoModel.h"

// 屏幕的宽
#define kScreenWidth                         [[UIScreen mainScreen] bounds].size.width
// 屏幕的高
#define kScreenHeight                        [[UIScreen mainScreen] bounds].size.height

@interface SPVideoListViewController () <UITableViewDataSource,UITableViewDelegate>
@property (strong, nonatomic  ) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *videList;
@property (nonatomic, strong) NSMutableArray *dataSource;
@end

@implementation SPVideoListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.tableView];
    
    
    self.videList = @[
                          @{@"title":@"网络视频1",
                            @"playUrl":@"http://7xqhmn.media1.z0.glb.clouddn.com/femorning-20161106.mp4"},
                          @{@"title":@"网络视频2",
                            @"playUrl":@"http://wvideo.spriteapp.cn/video/2016/0328/56f8ec01d9bfe_wpd.mp4"},
                          @{@"title":@"网络视频3",
                            @"playUrl":@"http://baobab.wdjcdn.com/1456117847747a_x264.mp4"},
                          @{@"title":@"网络视频4",
                            @"playUrl":@"http://baobab.wdjcdn.com/14525705791193.mp4"},
                          @{@"title":@"网络视频5",
                            @"playUrl":@"http://baobab.wdjcdn.com/1456459181808howtoloseweight_x264.mp4"},
                          @{@"title":@"网络视频6",
                            @"playUrl":@"http://baobab.wdjcdn.com/1455968234865481297704.mp4"},
                          @{@"title":@"网络视频7",
                            @"playUrl":@"http://baobab.wdjcdn.com/1455782903700jy.mp4"},
                          @{@"title":@"网络视频8",
                            @"playUrl":@"http://baobab.wdjcdn.com/14564977406580.mp4"},
                          @{@"title":@"网络视频9",
                            @"playUrl":@"http://baobab.wdjcdn.com/1456316686552The.mp4"},
                          @{@"title":@"网络视频10",
                            @"playUrl":@"http://baobab.wdjcdn.com/1456480115661mtl.mp4"},
                          @{@"title":@"网络视频11",
                            @"playUrl":@"http://baobab.wdjcdn.com/1456665467509qingshu.mp4"},
                          @{@"title":@"网络视频12",
                            @"playUrl":@"http://baobab.wdjcdn.com/1455614108256t(2).mp4"},
                          @{@"title":@"网络视频13",
                            @"playUrl":@"http://baobab.wdjcdn.com/1456317490140jiyiyuetai_x264.mp4"},
                          @{@"title":@"网络视频14",
                            @"playUrl":@"http://baobab.wdjcdn.com/1455888619273255747085_x264.mp4"},
                          @{@"title":@"网络视频15",
                            @"playUrl":@"http://baobab.wdjcdn.com/1456734464766B(13).mp4"},
                          @{@"title":@"网络视频16",
                            @"playUrl":@"http://baobab.wdjcdn.com/1456653443902B.mp4"},
                          @{@"title":@"网络视频17",
                            @"playUrl":@"http://baobab.wdjcdn.com/1456231710844S(24).mp4"},
          ];
    for (int i = 0; i < self.videList.count; i++) {
        SPVideoModel *videoModel = [[SPVideoModel alloc] init];
        NSDictionary *dic = self.videList[i];
        [videoModel setValuesForKeysWithDictionary:dic];
        [self.dataSource addObject:videoModel];
    }

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"netListCell"];
    
}


// 必须支持转屏，但只是只支持竖屏，否则横屏启动起来页面是横的
- (BOOL)shouldAutorotate {
    return YES;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"netListCell"];
    SPVideoModel *videoModel = self.dataSource[indexPath.row];
    cell.textLabel.text   = videoModel.title;
    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MoviePlayerViewController *movie = [[MoviePlayerViewController alloc] init];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    SPVideoModel *videoModel         = self.dataSource[indexPath.row];
    movie.videoModel                 = videoModel;
    //movie.videoModels                = self.dataSource;
    movie.videoList                  = self.videList;

    movie.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:movie animated:YES];
}

- (UITableView *)tableView {
    
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight) style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        
    }
    return _tableView;
}

- (NSMutableArray *)dataSource {
    
    if (!_dataSource) {
        _dataSource = [NSMutableArray array];
        
    }
    return _dataSource;
}


@end
