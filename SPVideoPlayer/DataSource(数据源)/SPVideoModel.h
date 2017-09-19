//
//  SPVideoModel.h
//  SPVideoPlayer
//
//  Created by Libo on 17/9/2.
//  Copyright © 2017年 iDress. All rights reserved.
//

#import <Foundation/Foundation.h>

// 正在下载的文件url缓存路径
#define downloadURLPath [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) firstObject] stringByAppendingPathComponent:@"sp_videoURL.plist"]


@interface SPVideoModel : NSObject
/** 标题 */
@property (nonatomic, copy) NSString *title;
/** 时间 */
@property (nonatomic, copy) NSString *date;
/** 描述 */
@property (nonatomic, copy) NSString *video_description;
/** 视频地址 */
@property (nonatomic, copy) NSString *playUrl;
/** 封面图 */
@property (nonatomic, copy) NSString *coverForFeed;
/** 视频分辨率的数组 */
@property (nonatomic, strong) NSMutableArray *playInfo;

+ (NSMutableArray *)modelForDictArray:(NSArray *)dictArray;

@end
