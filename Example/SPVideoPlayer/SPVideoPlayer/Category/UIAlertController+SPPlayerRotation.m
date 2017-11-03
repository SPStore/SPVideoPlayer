//
//  UIAlertController+SPPlayerRotation.m
//  SPVideoPlayer
//
//  Created by leshengping on 17/8/29.
//  Copyright © 2017年 leshengping. All rights reserved.
//

#import "UIAlertController+SPPlayerRotation.h"

@implementation UIAlertController (SPPlayerRotation)
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)supportedInterfaceOrientations; {
    return UIInterfaceOrientationMaskAll;
}
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}
#endif
@end
