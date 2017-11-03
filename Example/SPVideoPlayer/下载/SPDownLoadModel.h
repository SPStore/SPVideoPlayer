//
//  SPDownLoadModel.h
//  SPVideoPlayer
//
//  Created by Libo on 17/9/2.
//  Copyright © 2017年 iDress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPVideoModel.h"
#import "SPDownload.h"

@interface SPDownLoadModel : NSObject

@property (nonatomic, strong) SPVideoModel *videoModel;
@property (nonatomic, strong) SPDownloadInfo *info;

@end
