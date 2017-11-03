//
//  SPDownloadConst.h
//  SPVideoPlayer
//
//  Created by Libo on 17/9/19.
//  Copyright © 2017年 iDress. All rights reserved.
//
#import <Foundation/Foundation.h>

/******** 通知 Begin ********/
/** 下载进度发生改变的通知 */
extern NSString * const SPDownloadProgressDidChangeNotification;
/** 下载状态发生改变的通知 */
extern NSString * const SPDownloadStateDidChangeNotification;
/** 利用这个key从通知中取出对应的SPDownloadInfo对象 */
extern NSString * const SPDownloadInfoKey;

#define SPDownloadNoteCenter [NSNotificationCenter defaultCenter]
/******** 通知 End ********/
