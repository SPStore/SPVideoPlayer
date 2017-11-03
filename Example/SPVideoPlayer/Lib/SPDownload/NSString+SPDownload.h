//
//  NSString+SPDownload.h
//  SPVideoPlayer
//
//  Created by Libo on 17/9/19.
//  Copyright © 2017年 iDress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (SPDownload)
/**
 *  在前面拼接caches文件夹
 */
- (NSString *)prependCaches;

/**
 *  生成MD5摘要
 */
- (NSString *)MD5;

/**
 *  文件大小
 */
- (NSInteger)fileSize;

/**
 *  生成编码后的URL
 */
- (NSString *)encodedURL;

/*
 * 计算在单位M\KB\B下的大小
 */
+ (double)calculateFileSizeInUnit:(unsigned long long)contentLength;

/*
 *  计算单位
 */
+ (NSString *)calculateUnit:(unsigned long long)contentLength;
@end
