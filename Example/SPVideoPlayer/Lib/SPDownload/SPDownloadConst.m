//
//  SPDownloadConst.m
//  SPVideoPlayer
//
//  Created by Libo on 17/9/19.
//  Copyright © 2017年 iDress. All rights reserved.
//
#import <Foundation/Foundation.h>

/******** 通知 Begin ********/
/** 下载进度发生改变的通知 */
NSString * const SPDownloadProgressDidChangeNotification = @"SPDownloadProgressDidChangeNotification";
/** 下载状态发生改变的通知 */
NSString * const SPDownloadStateDidChangeNotification = @"SPDownloadStateDidChangeNotification";
/** 利用这个key从通知中取出对应的SPDownloadInfo对象 */
NSString * const SPDownloadInfoKey = @"SPDownloadInfoKey";
/******** 通知 End ********/


