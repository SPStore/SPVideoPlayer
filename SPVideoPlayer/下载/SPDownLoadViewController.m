//
//  SPDownLoadViewController.m
//  SPVideoPlayer
//
//  Created by leshengping on 17/8/23.
//  Copyright © 2017年 leshengping. All rights reserved.
//

#import "SPDownLoadViewController.h"
#import "SPDownLoadingCell.h"
#import "SPVideoModel.h"
#import "SPDownload.h"
#import "SPDownLoadModel.h"
#import "MoviePlayerViewController.h"

@interface SPDownLoadViewController () <UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dicArray;
@property (nonatomic, strong) NSMutableArray *downLoadingModels;

@end

@implementation SPDownLoadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
        
    //self.tableView.editing = YES;
    
    //[SPDownloadManager defaultManager].maxDownloadingCount = 1;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 获取所有正在下载的数据，数组中存的是字典
    self.dicArray = [NSKeyedUnarchiver unarchiveObjectWithFile:downloadURLPath];
    
    // 字典转模型
    self.downLoadingModels = [SPVideoModel modelForDictArray:self.dicArray];
    
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.downLoadingModels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SPDownLoadingCell *cell = [tableView dequeueReusableCellWithIdentifier:@"downLoadingCell" forIndexPath:indexPath];
    cell.videoModel = self.downLoadingModels[indexPath.row];

    return cell;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SPVideoModel *videoModel = self.downLoadingModels[indexPath.row];
    SPDownloadInfo *info = [[SPDownloadManager defaultManager] downloadInfoForURL:videoModel.playUrl];
    
    if (info.state == SPDownloadStateCompleted) {
        MoviePlayerViewController *movieVc = [[MoviePlayerViewController alloc] init];
        videoModel.playUrl = info.file;
        // info.file就是视频存储的本地路径
        movieVc.videoModel = videoModel;
        movieVc.videoList = self.dicArray;
        movieVc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:movieVc animated:YES];
    } else if (info.state == SPDownloadStateResumed) { // 如果在下载就暂停下载
        [[SPDownloadManager defaultManager] suspend:info.url];
    } else { // 恢复下载
        [[SPDownloadManager defaultManager] resume:info.url];
        [self.tableView reloadData];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"删除";
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    SPVideoModel *videoModel = self.downLoadingModels[indexPath.row];
    NSDictionary *dic        = self.dicArray[indexPath.row];
    // 删除数组中的模型
    [self.downLoadingModels removeObject:videoModel];
    // 删除字典
    [self.dicArray removeObject:dic];
    // 删除下载到本地的视频
    [[SPDownloadManager defaultManager] removeFileForURL:videoModel.playUrl];
    
    // 删除保存在本地的url
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadURLPath]) {
        NSMutableArray *dicArr = [NSKeyedUnarchiver unarchiveObjectWithFile:downloadURLPath];
        [dicArr removeObject:dic];
        [NSKeyedArchiver archiveRootObject:dicArr toFile:downloadURLPath];
    }
    // 删除cell
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationBottom];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    NSLog(@"内存警告");
}


@end
