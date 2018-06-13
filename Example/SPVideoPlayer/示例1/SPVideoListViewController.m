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
                            @"playUrl":@"http://mpv.videocc.net/cce50b4fd7/c/cce50b4fd7e8efa7c5ede662193fcb7c_2.mp4"},
                          @{@"title":@"网络视频2",
                            @"playUrl":@"http://mpv.videocc.net/cce50b4fd7/6/cce50b4fd7d4593af6dfb1d6a94b36c6_2.mp4"},
                          @{@"title":@"网络视频3",
                            @"playUrl":@"http://mpv.videocc.net/cce50b4fd7/9/cce50b4fd7a294e8a5e74156c9fd5939_2.mp4"},
                          @{@"title":@"网络视频4",
                            @"playUrl":@"http://mpv.videocc.net/cce50b4fd7/c/cce50b4fd7ace598cefa25cf78a1048c_2.mp4"},
                          @{@"title":@"网络视频5",
                            @"playUrl":@"http://mpv.videocc.net/cce50b4fd7/0/cce50b4fd760e06e3801df5e07bb8180_2.mp4"},
                          @{@"title":@"网络视频6",
                            @"playUrl":@"http://mpv.videocc.net/cce50b4fd7/c/cce50b4fd7be94b5c85ce65e2312d61c_2.mp4"},
                          @{@"title":@"网络视频7",
                            @"playUrl":@"http://mpv.videocc.net/cce50b4fd7/3/cce50b4fd7fc7851786f4839b2b64e23_2.mp4"},
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
