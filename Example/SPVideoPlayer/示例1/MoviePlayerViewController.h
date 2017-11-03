//
//  MoviePlayerViewController.h
//
// Copyright (c) 2017年 leshengping
//


#import <UIKit/UIKit.h>

@class SPVideoModel;

@interface MoviePlayerViewController : UIViewController
/** 视频模型 */
@property (nonatomic, strong) SPVideoModel *videoModel;
/** 视频模型数组 */
@property (nonatomic, strong) NSArray *videoModels;
/** 存储所有视频的字典，因为下载的时候需要通过这个字典找到正在下载的那个数据，然后保存到本地 */
@property (nonatomic, strong) NSArray<NSDictionary *> *videoList;

@end
