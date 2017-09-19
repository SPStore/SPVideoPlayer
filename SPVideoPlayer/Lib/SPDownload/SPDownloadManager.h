//
//  SPDownloadManager.h
//  SPVideoPlayer
//
//  Created by Libo on 17/9/19.
//  Copyright © 2017年 iDress. All rights reserved.
//
#import <Foundation/Foundation.h>

@class SPDownloadInfo;

/****************** 数据类型 Begin ******************/
/** 下载状态 */
typedef NS_ENUM(NSInteger, SPDownloadState) {
    SPDownloadStateNone = 0,     // 闲置状态（除后面几种状态以外的其他状态）
    SPDownloadStateWillResume,   // 即将下载（等待下载）
    SPDownloadStateResumed,      // 下载中
    SPDownloadStateSuspened,     // 暂停中
    SPDownloadStateCompleted     // 已经完全下载完毕
} NS_ENUM_AVAILABLE_IOS(2_0);

/**
 *  跟踪下载进度的Block回调
 *
 *  @param bytesWritten              【这次回调】写入的数据量
 *  @param totalBytesWritten         【目前总共】写入的数据量
 *  @param totalBytesExpectedToWrite 【最终需要】写入的数据量
 */
typedef void (^SPDownloadProgressChangeBlock)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite);

/**
 *  状态改变的Block回调
 *
 *  @param file 文件的下载路径
 *  @param error    失败的描述信息
 */
typedef void (^SPDownloadStateChangeBlock)(SPDownloadState state, NSString *file, NSError *error);
/**
 *  速度改变的回调
 *
 *  @param speed 速度(1秒内的平均速度)
 *  @param remainingTime 剩余时间,这个剩余时间，你看到的可能不是连续递减，可能有长有短，这是因为时间是根据当前那一刻的速度而预估的剩余时间，而速度是不稳定的，速度有快有慢，时间就会有长有短，但整体上，剩余时间肯定是缩减的
 */
typedef void (^SPDownloadSpeedChangeBlock)(NSString *speed, NSString *remainingTime);
/****************** 数据类型 End ******************/


/****************** SPDownloadInfo Begin ******************/
/**
 *  下载的描述信息
 */
@interface  SPDownloadInfo : NSObject
/** 下载状态 */
@property (assign, nonatomic, readonly) SPDownloadState state;
/** 这次写入的数量,单位：字节 */
@property (assign, nonatomic, readonly) NSInteger bytesWritten;
/** 已下载的数量,单位：字节 */
@property (assign, nonatomic, readonly) NSInteger totalBytesWritten;
/** 文件的总大小, 单位：字节 */
@property (assign, nonatomic, readonly) NSInteger totalBytesExpectedToWrite;
/** 文件名 */
@property (copy, nonatomic, readonly) NSString *filename;
/** 文件路径 */
@property (copy, nonatomic, readonly) NSString *file;
/** 文件url */
@property (copy, nonatomic, readonly) NSString *url;
/** 下载的错误信息 */
@property (strong, nonatomic, readonly) NSError *error;

/** 下载进度改变回调 */
@property (copy, nonatomic) SPDownloadProgressChangeBlock progressChangeBlock;
/** 下载状态改变回调 */
@property (copy, nonatomic) SPDownloadStateChangeBlock stateChangeBlock;
/** 速度改变的block */
@property (copy, nonatomic) SPDownloadSpeedChangeBlock speedChangeBlock;

@end
/****************** SPDownloadInfo End ******************/


/****************** SPDownloadManager Begin ******************/
/**
 *  文件下载管理者，管理所有文件的下载操作
 *  - 管理文件下载操作
 *  - 获得文件下载操作
 */
@interface SPDownloadManager : NSObject
/** 回调的队列 */
@property (strong, nonatomic) NSOperationQueue *queue;
/** 最大同时下载数,大于5之后强制为5 */
@property (assign, nonatomic) int maxDownloadingCount;

+ (instancetype)defaultManager;
+ (instancetype)manager;
+ (instancetype)managerWithIdentifier:(NSString *)identifier;

/**
 *  获得某个文件的下载信息
 *
 *  @param url 文件的URL
 */
- (SPDownloadInfo *)downloadInfoForURL:(NSString *)url;

/**
 *  下载一个文件
 *
 *  @param url  文件的URL路径,默认存放到caches文件夹
 *
 *  @return YES代表文件已经下载完毕
 */
- (SPDownloadInfo *)download:(NSString *)url;

/**
 *  下载一个文件
 *
 *  @param url                文件的URL路径
 *  @param destinationPath    文件的存放路径
 *
 *  @return YES代表文件已经下载完毕
 */
- (SPDownloadInfo *)download:(NSString *)url toDestinationPath:(NSString *)destinationPath;

/**
 *  下载一个文件
 *
 *  @param url      文件的URL路径
 *  @param state    状态改变的回调
 *
 *  @return YES代表文件已经下载完毕
 */
- (SPDownloadInfo *)download:(NSString *)url state:(SPDownloadStateChangeBlock)state;

/**
 *  下载一个文件
 *
 *  @param url          文件的URL路径
 *  @param progress     下载进度的回调
 *  @param state        状态改变的回调
 *
 *  @return YES代表文件已经下载完毕
 */
- (SPDownloadInfo *)download:(NSString *)url progress:(SPDownloadProgressChangeBlock)progress state:(SPDownloadStateChangeBlock)state;

/**
 *  下载一个文件
 *
 *  @param url              文件的URL路径
 *  @param destinationPath  文件的存放路径
 *  @param progress         下载进度的回调
 *  @param state            状态改变的回调
 *
 *  @return YES代表文件已经下载完毕
 */
- (SPDownloadInfo *)download:(NSString *)url toDestinationPath:(NSString *)destinationPath progress:(SPDownloadProgressChangeBlock)progress state:(SPDownloadStateChangeBlock)state;

/**
 *  全部文件取消下载(一旦被取消了，需要重新调用download方法)
 */
- (void)cancelAll;
/**
 *  全部文件取消下载(一旦被取消了，需要重新调用download方法)
 */
+ (void)cancelAll;

/**
 *  取消下载某个文件(一旦被取消了，需要重新调用download方法)
 */
- (void)cancel:(NSString *)url;

/**
 *  全部文件暂停下载
 */
- (void)suspendAll;
/**
 *  全部文件暂停下载
 */
+ (void)suspendAll;

/**
 *  暂停下载某个文件
 */
- (void)suspend:(NSString *)url;

/**
 * 全部文件开始\继续下载
 */
- (void)resumeAll;
/**
 * 全部文件开始\继续下载
 */
+ (void)resumeAll;

/**
 *  开始\继续下载某个文件
 */
- (void)resume:(NSString *)url;


// --------------------  移除 -----------------
/**
 *  移除所有开始了下载但是未下载完成的文件
 */
- (void)removeAllDownloadUncompletedFile;
/**
 *  移除所有开始了下载但是未下载完成的文件
 */
+ (void)removeAllDownloadUncompletedFile;

/**
 *  移除所有下载完成了的文件
 */
- (void)removeAllDownloadCompletedFile;
/**
 *  移除所有下载完成了的文件
 */
+ (void)removeAllDownloadCompletedFile;

/**
 *  移除所有文件
 */
- (void)removeAllFile;
/**
 *  移除所有文件
 */
+ (void)removeAllFile;

/**
 *  移除一个文件
 */
- (void)removeFileForURL:(NSString *)url;

@end
/****************** SPDownloadManager End ******************/
