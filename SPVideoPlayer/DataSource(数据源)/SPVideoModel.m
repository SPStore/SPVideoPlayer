//
//  SPVideoModel.m
//  SPVideoPlayer
//
//  Created by Libo on 17/9/2.
//  Copyright © 2017年 iDress. All rights reserved.
//

#import "SPVideoModel.h"
#import <objc/runtime.h>
#import "SPVideoResolution.h"


@implementation SPVideoModel
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    // 转换系统关键字description
    if ([key isEqualToString:@"description"]) {
        self.video_description = [NSString stringWithFormat:@"%@",value];
    }
}

+ (NSMutableArray *)modelForDictArray:(NSArray *)dictArray {
    
    NSMutableArray *modelArray = [NSMutableArray array];
    for (NSDictionary *dataDic in dictArray) {
        SPVideoModel *model = [[SPVideoModel alloc] init];
        [model setValuesForKeysWithDictionary:dataDic];
        
        NSMutableArray *playInfoArray = [NSMutableArray array];
        for (NSDictionary *smallDic in dataDic[@"playInfo"]) {
            SPVideoResolution *resolution = [[SPVideoResolution alloc] init];
            [resolution setValuesForKeysWithDictionary:smallDic];
            [playInfoArray addObject:resolution];
            model.playInfo = playInfoArray;
        }
        [modelArray addObject:model];
    }
    return modelArray;
}


@end
