//
//  SPVideoItem.m
//  SPVideoPlayer
//
//  Created by Libo on 17/9/1. （https://github.com/SPStore/SPVideoPlayer
//  Copyright © 2017年 iDress. All rights reserved.
//

#import "SPVideoItem.h"
#import "SPVideoPlayer.h"

@implementation SPVideoItem

- (instancetype)init {
    if (self = [super init]) {
        self.shouldAutorotate = YES;
    }
    return self;
}

- (UIImage *)placeholderImage {
    if (!_placeholderImage) {
        _placeholderImage = [UIImage imageNamed:@"qyplayer_aura2_background_normal_iphone_375x211_"];
    }
    return _placeholderImage;
}
@end
