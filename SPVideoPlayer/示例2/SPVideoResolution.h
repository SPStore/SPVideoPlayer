//
//  SPVideoResolution.h
//  SPVideoPlayer
//
//  Created by leshengping on 17/8/23.
//  Copyright © 2017年 leshengping. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPVideoResolution : NSObject

@property (nonatomic, assign) NSInteger height;
@property (nonatomic, assign) NSInteger width;
@property (nonatomic, copy  ) NSString  *name;
@property (nonatomic, copy  ) NSString  *type;
@property (nonatomic, copy  ) NSString  *url;

@end
