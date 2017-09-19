//
//  SPVideoPlayer.h
//  SPVideoPlayer
//
//  Created by leshengping on 17/7/12.
//  Copyright © 2017年 leshengping. All rights reserved.
//

// 监听TableView的contentOffset
#define kSPPlayerViewContentOffset          @"contentOffset"
// player的单例
#define SPPlayerShared                      [SPBrightnessView sharedBrightnessView]
// 屏幕的宽
#define ScreenWidth                         [[UIScreen mainScreen] bounds].size.width
// 屏幕的高
#define ScreenHeight                        [[UIScreen mainScreen] bounds].size.height
// 颜色值RGB
#define RGBA(r,g,b,a)                       [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]

// 图片路径
#define SPPlayerSrcName(file)               [@"SPVideoPlayer.bundle" stringByAppendingPathComponent:file]

#define SPPlayerImage(file)                 [UIImage imageNamed:SPPlayerSrcName(file)]

#define SPPlayerOrientationIsLandscape      UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)

#define SPPlayerOrientationIsPortrait       UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation)

#import "SPVideoPlayerView.h"
#import "SPVideoItem.h"
#import "SPVideoPlayerControlView.h"
#import "UITabBarController+SPPlayerRotation.h"
#import "UIViewController+SPPlayerRotation.h"
#import "UINavigationController+SPPlayerRotation.h"
#import "UIWindow+CurrentViewController.h"
#import "SPBrightnessView.h"
#import "SPVideoPlayerControlViewDelegate.h"



