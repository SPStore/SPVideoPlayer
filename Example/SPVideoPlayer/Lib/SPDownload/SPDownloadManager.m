//
//  SPDownloadManager.m
//  SPVideoPlayer
//
//  Created by Libo on 17/9/19.
//  Copyright © 2017年 iDress. All rights reserved.
//

#import "SPDownloadManager.h"
#import "NSString+SPDownload.h"
#import "SPDownloadConst.h"

/** 存放所有的文件大小 */
static NSMutableDictionary *_totalFileSizes;
/** 存放所有的文件大小的文件路径 */
static NSString *_totalFileSizesFile;

/** 根文件夹 */
static NSString * const SPDownloadRootDir = @"com_520it_www_SPdownload";

/** 默认manager的标识 */
static NSString * const SPDowndloadManagerDefaultIdentifier = @"com.520it.www.downloadmanager";

static int i = 0;

/****************** SPDownloadInfo Begin ******************/
@interface SPDownloadInfo()
{
    SPDownloadState _state;
    NSInteger _totalBytesWritten;
}
/******** Readonly Begin ********/
/** 速度 */
@property (copy,nonatomic) NSString *speedStr;
/** 剩余时间 */
@property (copy,nonatomic) NSString *remainingTimeStr;
/** 下载状态 */
@property (assign, nonatomic) SPDownloadState state;
/** 这次写入的数量 */
@property (assign, nonatomic) NSInteger bytesWritten;
/** 已下载的数量 */
@property (assign, nonatomic) NSInteger totalBytesWritten;
/** 文件的总大小 */
@property (assign, nonatomic) NSInteger totalBytesExpectedToWrite;
/** 文件名 */
@property (copy, nonatomic) NSString *filename;
/** 文件路径 */
@property (copy, nonatomic) NSString *file;
/** 文件url */
@property (copy, nonatomic) NSString *url;
/** 下载的错误信息 */
@property (strong, nonatomic) NSError *error;
/******** Readonly End ********/


/** 任务 */
@property (strong, nonatomic) NSURLSessionDataTask *task;
/** 文件流 */
@property (strong, nonatomic) NSOutputStream *stream;
/** 开始下载的时间 */
@property (nonatomic, strong) NSDate *startTime;
/** 1秒前文件的大小 */
@property (nonatomic, assign) NSInteger bytesBeforeOneSecond;
@end

@implementation SPDownloadInfo

- (NSString *)file
{
    if (!_file) {
        _file = [[NSString stringWithFormat:@"%@/%@", SPDownloadRootDir, self.filename] prependCaches];
    }
    // SPDownloadRootDir是一个文件夹，自定义文件夹必须手动创建
    if (_file && ![[NSFileManager defaultManager] fileExistsAtPath:_file]) {
        // 删除最后一个目录
        NSString *dir = [_file stringByDeletingLastPathComponent];
        // 新建SPDownloadRootDir文件夹
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return _file;
}

- (NSString *)filename
{
    if (_filename == nil) {
        NSString *pathExtension = self.url.pathExtension;
        if (pathExtension.length) {
            _filename = [NSString stringWithFormat:@"%@.%@", self.url.MD5, pathExtension];
        } else {
            _filename = self.url.MD5;
        }
    }
    return _filename;
}

- (NSOutputStream *)stream
{
    if (_stream == nil) {
        _stream = [NSOutputStream outputStreamToFileAtPath:self.file append:YES];
    }
    return _stream;
}

- (NSInteger)totalBytesWritten
{
    return self.file.fileSize;
}

- (NSInteger)totalBytesExpectedToWrite
{
    if (!_totalBytesExpectedToWrite) {
        _totalBytesExpectedToWrite = [_totalFileSizes[self.url] integerValue];
    }
    return _totalBytesExpectedToWrite;
}

- (SPDownloadState)state
{
    // 如果是下载完毕
    if (self.totalBytesExpectedToWrite && self.totalBytesWritten == self.totalBytesExpectedToWrite) {
        return SPDownloadStateCompleted;
    }
    
    // 这个if里面的条件是下载了一部分，然后退出程序，重新运行程序的意思，这个状态应该给暂停而不是闲置
    if (self.totalBytesExpectedToWrite && self.totalBytesWritten > 0 && self.totalBytesWritten < self.totalBytesExpectedToWrite && _state == SPDownloadStateNone) {
        return SPDownloadStateSuspened;
    }
    
    // 如果下载失败
    if (self.task.error) {
        return SPDownloadStateNone;
    }
    
    return _state;
}

/**
 *  初始化任务
 */
- (void)setupTask:(NSURLSession *)session
{
    if (self.task) return;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.url]];
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-", self.totalBytesWritten];
    [request setValue:range forHTTPHeaderField:@"Range"];
    
    self.task = [session dataTaskWithRequest:request];
    // 设置描述
    self.task.taskDescription = self.url;
}

/**
 *  通知进度改变
 */
- (void)notifyProgressChange
{
    !self.progressChangeBlock ? : self.progressChangeBlock(self.bytesWritten, self.totalBytesWritten, self.totalBytesExpectedToWrite);
    dispatch_async(dispatch_get_main_queue(), ^{
        [SPDownloadNoteCenter postNotificationName:SPDownloadProgressDidChangeNotification
                                            object:self
                                          userInfo:@{SPDownloadInfoKey : self}];
    });
}

/**
 *  通知下载完毕
 */
- (void)notifyStateChange
{
    NSLog(@"---- %zd",self.state);
    !self.stateChangeBlock ? : self.stateChangeBlock(self.state, self.file, self.error);
    dispatch_async(dispatch_get_main_queue(), ^{
        [SPDownloadNoteCenter postNotificationName:SPDownloadStateDidChangeNotification
                                            object:self
                                          userInfo:@{SPDownloadInfoKey : self}];
    });
}

#pragma mark - 状态控制
- (void)setState:(SPDownloadState)state
{
    SPDownloadState oldState = _state;
    if (state == oldState) return;
    
    _state = state;
    
    if (state == SPDownloadStateSuspened) {
        i = 0;
        self.bytesBeforeOneSecond = self.totalBytesWritten;
    }
    
    // 发通知
    [self notifyStateChange];
}

/**
 *  取消
 */
- (void)cancel
{
    if (self.state == SPDownloadStateCompleted || self.state == SPDownloadStateNone) return;
    
    [self.task cancel];
    self.state = SPDownloadStateNone;
}

/**
 *  恢复
 */
- (void)resume
{
    if (self.state == SPDownloadStateCompleted || self.state == SPDownloadStateResumed) return;
    
    self.startTime = [NSDate date];
    
    [self.task resume];
    self.state = SPDownloadStateResumed;
}

/**
 * 等待下载
 */
- (void)willResume
{
    if (self.state == SPDownloadStateCompleted || self.state == SPDownloadStateWillResume) return;
    
    self.state = SPDownloadStateWillResume;
}

/**
 *  暂停
 */
- (void)suspend
{
    if (self.state == SPDownloadStateCompleted || self.state == SPDownloadStateSuspened) return;
    
    if (self.state == SPDownloadStateResumed) { // 如果是正在下载
        [self.task suspend];
        self.state = SPDownloadStateSuspened;
    } else { // 如果是等待下载
        self.state = SPDownloadStateNone;
    }
}

#pragma mark - 代理方法处理
- (void)didReceiveResponse:(NSHTTPURLResponse *)response
{
    // 获得文件总长度
    if (!self.totalBytesExpectedToWrite) {
        self.totalBytesExpectedToWrite = [response.allHeaderFields[@"Content-Length"] integerValue] + self.totalBytesWritten;
        // 存储文件总长度
        _totalFileSizes[self.url] = @(self.totalBytesExpectedToWrite);
        [_totalFileSizes writeToFile:_totalFileSizesFile atomically:YES];
    }
    
    // 打开流
    [self.stream open];
    
    // 清空错误
    self.error = nil;
}

- (void)didReceiveData:(NSData *)data
{
    // 写数据
    NSInteger result = [self.stream write:data.bytes maxLength:data.length];
    
    if (result == -1) {
        self.error = self.stream.streamError;
        [self.task cancel]; // 取消请求
    }else{
        
        // 计算下载速度和剩余时间
        [self calculateDownloadSpeedAndRemainingTime:data.length];
        
        self.bytesWritten = data.length;
        [self notifyProgressChange]; // 通知进度改变
        
    }
}

- (void)didCompleteWithError:(NSError *)error
{
    // 关闭流
    [self.stream close];
    self.bytesWritten = 0;
    self.stream = nil;
    self.task = nil;
    
    // 错误(避免nil的error覆盖掉之前设置的self.error)
    self.error = error ? error : self.error;
    
    // 通知(如果下载完毕 或者 下载出错了)
    if (self.state == SPDownloadStateCompleted || error) {
        // 设置状态
        self.state = error ? SPDownloadStateNone : SPDownloadStateCompleted;
    }
}

#pragma mark - 私有
- (void)calculateDownloadSpeedAndRemainingTime:(NSInteger)dataLength {
    // 从创建时间开始，到此时共花的时间
    NSTimeInterval downloadTime = -1 * [self.startTime timeIntervalSinceNow];
    
    // 大于1秒才去更新速度和剩余时间（这个1秒是约等于）,目的是不想让速度更新过快
    if (downloadTime >= 1) {
        i = 1;
        // 需要初始化时间,否则时间一直递增
        self.startTime = [NSDate date];
        // 速度 = 这1秒内返回的数据总和 / 时间
        double speed = (double) (self.totalBytesWritten-self.bytesBeforeOneSecond) / downloadTime;
        // 转成M\KB\B单位下的大小
        double speedSec = [NSString calculateFileSizeInUnit:(unsigned long long)speed];
        // 获取单位M\KB\B
        NSString *unit = [NSString calculateUnit:(unsigned long long)speed];
        NSString *speedStr = [NSString stringWithFormat:@"%.1f%@/S",speedSec,unit];
        self.speedStr = speedStr;
        
        // 剩余下载时间
        NSMutableString *remainingTimeStr = [[NSMutableString alloc] init];
        NSUInteger remainingContentLength = self.totalBytesExpectedToWrite - self.totalBytesWritten;
        double remainingTime = (double)(remainingContentLength / speed);
        NSInteger hours = remainingTime / 3600;
        NSInteger minutes = (remainingTime - hours * 3600) / 60;
        double seconds = remainingTime - hours * 3600 - minutes * 60;
        
        if (hours > 0)   {[remainingTimeStr appendFormat:@"%zd小时 ",hours];}
        if (minutes > 0) {[remainingTimeStr appendFormat:@"%zd分 ",minutes];}
        if (seconds > 0) {[remainingTimeStr appendFormat:@"%.0f秒",seconds];}
        self.remainingTimeStr = remainingTimeStr;
        
        if (self.state == SPDownloadStateResumed) {
            !self.speedChangeBlock ? : self.speedChangeBlock(speedStr,remainingTimeStr);
        }
        self.bytesBeforeOneSecond = self.totalBytesWritten;
    }
    // 如果是第一次来或者暂停后又恢复下载，应该立即回调，否则要等大约1秒才去更新速度
    if ( i == 0 ) {
        if (self.speedStr == nil) { self.speedStr = @"0KB/S";}
        if (self.remainingTimeStr == nil) { self.remainingTimeStr = @"0S";}
        if (self.state == SPDownloadStateResumed) {
            !self.speedChangeBlock ? : self.speedChangeBlock(self.speedStr,self.remainingTimeStr);
        }
        self.bytesBeforeOneSecond = self.totalBytesWritten;
    }
    
}


@end
/****************** SPDownloadInfo End ******************/


/****************** SPDownloadManager Begin ******************/
@interface SPDownloadManager() <NSURLSessionDataDelegate>
/** session */
@property (strong, nonatomic) NSURLSession *session;
/** 存放所有文件的下载信息 */
@property (strong, nonatomic) NSMutableArray *downloadInfoArray;
/** 是否正在批量处理 */
@property (assign, nonatomic, getter=isBatching) BOOL batching;
@end

@implementation SPDownloadManager

/** 存放所有的manager */
static NSMutableDictionary *_managers;
/** 锁 */
static NSRecursiveLock *_lock;

+ (void)initialize
{
    _totalFileSizesFile = [[NSString stringWithFormat:@"%@/%@", SPDownloadRootDir, @"SPDownloadFileSizes.plist".MD5] prependCaches];
    
    _totalFileSizes = [NSMutableDictionary dictionaryWithContentsOfFile:_totalFileSizesFile];
    if (_totalFileSizes == nil) {
        _totalFileSizes = [NSMutableDictionary dictionary];
    }
    
    _managers = [NSMutableDictionary dictionary];
    
    _lock = [[NSRecursiveLock alloc] init];
}

+ (instancetype)defaultManager
{
    return [self managerWithIdentifier:SPDowndloadManagerDefaultIdentifier];
}

+ (instancetype)manager
{
    return [[self alloc] init];
}

+ (instancetype)managerWithIdentifier:(NSString *)identifier
{
    if (identifier == nil) return [self manager];
    
    SPDownloadManager *mgr = _managers[identifier];
    if (!mgr) {
        mgr = [self manager];
        _managers[identifier] = mgr;
    }
    return mgr;
}

#pragma mark - 懒加载
- (NSURLSession *)session
{
    if (!_session) {
        // 配置
        NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
        // session
        self.session = [NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:self.queue];
    }
    return _session;
}

- (NSOperationQueue *)queue
{
    if (!_queue) {
        self.queue = [[NSOperationQueue alloc] init];
        self.queue.maxConcurrentOperationCount = 1;
    }
    return _queue;
}

- (NSMutableArray *)downloadInfoArray
{
    if (!_downloadInfoArray) {
        self.downloadInfoArray = [NSMutableArray array];
    }
    return _downloadInfoArray;
}

#pragma mark - setter
- (void)setMaxDownloadingCount:(int)maxDownloadingCount {
    if (maxDownloadingCount > 5) {
        maxDownloadingCount = 5;
    }
    _maxDownloadingCount = maxDownloadingCount;
}

#pragma mark - 私有方法

#pragma mark - 公共方法
- (SPDownloadInfo *)download:(NSString *)url toDestinationPath:(NSString *)destinationPath progress:(SPDownloadProgressChangeBlock)progress state:(SPDownloadStateChangeBlock)state
{
    if (url == nil) return nil;
    
    // 下载信息
    SPDownloadInfo *info = [self downloadInfoForURL:url];
    
    // 设置block
    info.progressChangeBlock = progress;
    info.stateChangeBlock = state;
    
    // 设置文件路径
    if (destinationPath) {
        info.file = destinationPath;
        info.filename = [destinationPath lastPathComponent];
    }
    
    // 如果已经下载完毕
    if (info.state == SPDownloadStateCompleted) {
        // 完毕
        [info notifyStateChange];
        return info;
    } else if (info.state == SPDownloadStateResumed) {
        return info;
    }
    
    // 创建任务
    [info setupTask:self.session];
    
    // 开始任务
    [self resume:url];
    
    return info;
}

- (SPDownloadInfo *)download:(NSString *)url progress:(SPDownloadProgressChangeBlock)progress state:(SPDownloadStateChangeBlock)state
{
    return [self download:url toDestinationPath:nil progress:progress state:state];
}

- (SPDownloadInfo *)download:(NSString *)url state:(SPDownloadStateChangeBlock)state
{
    return [self download:url toDestinationPath:nil progress:nil state:state];
}

- (SPDownloadInfo *)download:(NSString *)url toDestinationPath:(NSString *)destinationPath {
    return [self download:url toDestinationPath:destinationPath progress:nil state:nil];
}

- (SPDownloadInfo *)download:(NSString *)url
{
    return [self download:url toDestinationPath:nil progress:nil state:nil];
}

#pragma mark - 文件操作
/**
 * 让第一个等待下载的文件开始下载
 */
- (void)resumeFirstWillResume
{
    if (self.isBatching) return;
    
    SPDownloadInfo *willInfo = [self.downloadInfoArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"state==%d", SPDownloadStateWillResume]].firstObject;
    [self resume:willInfo.url];
}

- (void)cancelAll
{
    [self.downloadInfoArray enumerateObjectsUsingBlock:^(SPDownloadInfo *info, NSUInteger idx, BOOL *stop) {
        [self cancel:info.url];
    }];
}

+ (void)cancelAll
{
    [_managers.allValues makeObjectsPerformSelector:@selector(cancelAll)];
}

- (void)suspendAll
{
    self.batching = YES;
    [self.downloadInfoArray enumerateObjectsUsingBlock:^(SPDownloadInfo *info, NSUInteger idx, BOOL *stop) {
        [self suspend:info.url];
    }];
    self.batching = NO;
}

+ (void)suspendAll
{
    [_managers.allValues makeObjectsPerformSelector:@selector(suspendAll)];
}

- (void)resumeAll
{
    [self.downloadInfoArray enumerateObjectsUsingBlock:^(SPDownloadInfo *info, NSUInteger idx, BOOL *stop) {
        [self resume:info.url];
    }];
}

+ (void)resumeAll
{
    [_managers.allValues makeObjectsPerformSelector:@selector(resumeAll)];
}

- (void)cancel:(NSString *)url
{
    if (url == nil) return;
    
    // 取消
    [[self downloadInfoForURL:url] cancel];
    
    // 这里不需要取出第一个等待下载的，因为调用cancel会触发-URLSession:task:didCompleteWithError:
    //    [self resumeFirstWillResume];
}

- (void)suspend:(NSString *)url
{
    if (url == nil) return;
    
    // 暂停
    [[self downloadInfoForURL:url] suspend];
    
    // 取出第一个等待下载的
    [self resumeFirstWillResume];
}

- (void)resume:(NSString *)url
{
    if (url == nil) return;
    
    
    // 获得下载信息
    SPDownloadInfo *info = [self downloadInfoForURL:url];
    
    // 正在下载的
    NSArray *downloadingDownloadInfoArray = [self.downloadInfoArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"state==%d", SPDownloadStateResumed]];
    // 如果此时正在下载的数量等于最大下载数，那么本次下载置为等待下载
    if (self.maxDownloadingCount && downloadingDownloadInfoArray.count == self.maxDownloadingCount) {
        // 等待下载
        [info willResume];
    } else {
        if (!info.task || info.task.state == NSURLSessionTaskStateCanceling) {
            // 只有外界实现了progressChangeBlock和stateChangeBlock，这2个block才有值
            [self download:url toDestinationPath:info.file progress:info.progressChangeBlock state:info.stateChangeBlock];
        } else {
            // 继续
            [info resume];
        }
    }
}

- (void)removeFileForURL:(NSString *)url {
    SPDownloadInfo *info = [self downloadInfoForURL:url];
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:info.file]) {
        [self.downloadInfoArray removeObject:info];
        [manager removeItemAtPath:info.file error:nil];
    }
}

- (void)removeAllDownloadUncompletedFile {
    // 获取未下载完成的文件
    NSArray *downloadingDownloadInfoArray = [self.downloadInfoArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"state!=%d && state!=%d", SPDownloadStateCompleted,SPDownloadStateNone]];
    [downloadingDownloadInfoArray enumerateObjectsUsingBlock:^(SPDownloadInfo *info, NSUInteger idx, BOOL * _Nonnull stop) {
        [self removeFileForURL:info.url];
    }];
}

+ (void)removeAllDownloadUncompletedFile {
    [_managers.allValues makeObjectsPerformSelector:@selector(removeAllDownloadUncompletedFile)];
}

- (void)removeAllDownloadCompletedFile {
    // 获取下载完成的文件
    NSArray *downloadCompletedInfoArray = [self.downloadInfoArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"state==%d", SPDownloadStateCompleted]];
    [downloadCompletedInfoArray enumerateObjectsUsingBlock:^(SPDownloadInfo *info, NSUInteger idx, BOOL * _Nonnull stop) {
        [self removeFileForURL:info.url];
    }];
}

+ (void)removeAllDownloadCompletedFile {
    [_managers.allValues makeObjectsPerformSelector:@selector(removeAllDownloadCompletedFile)];
}

- (void)removeAllFile {
    [self.downloadInfoArray enumerateObjectsUsingBlock:^(SPDownloadInfo *info, NSUInteger idx, BOOL * _Nonnull stop) {
        [self removeFileForURL:info.url];
    }];
}

+ (void)removeAllFile {
    [_managers.allValues makeObjectsPerformSelector:@selector(removeAllFile)];
}

#pragma mark - 获得下载信息
- (SPDownloadInfo *)downloadInfoForURL:(NSString *)url
{
    if (url == nil) return nil;
    
    // 通过url在数组中找出info，如果存在直接返回，否则新增
    SPDownloadInfo *info = [self.downloadInfoArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"url==%@", url]].firstObject;
    if (info == nil) {
        info = [[SPDownloadInfo alloc] init];
        info.url = url; // 设置url
        [self.downloadInfoArray addObject:info];
    }
    return info;
}

#pragma mark - <NSURLSessionDataDelegate>
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    // 获得下载信息
    SPDownloadInfo *info = [self downloadInfoForURL:dataTask.taskDescription];
    
    // 处理响应
    [info didReceiveResponse:response];
    
    // 继续
    completionHandler(NSURLSessionResponseAllow);
    
}

// 调多次
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    // 获得下载信息
    SPDownloadInfo *info = [self downloadInfoForURL:dataTask.taskDescription];
    
    // 处理数据
    [info didReceiveData:data];
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    // 获得下载信息
    SPDownloadInfo *info = [self downloadInfoForURL:task.taskDescription];
    
    // 处理结束
    [info didCompleteWithError:error];
    
    // 恢复等待下载的
    [self resumeFirstWillResume];
}
@end
/****************** SPDownloadManager End ******************/
