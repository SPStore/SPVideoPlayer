//
//  SPBrightnessView.h
//  SPBrightnessView
//
//  Created by leshengping on 17/7/12.  （https://github.com/SPStore/SPVideoPlayer
//  Copyright © 2017年 leshengping. All rights reserved.
//  亮度view

#import <UIKit/UIKit.h>

@interface SPBrightnessView : UIView

/** 调用单例记录播放状态是否锁定屏幕方向*/
@property (nonatomic, assign) BOOL     isLockScreen;
/** 是否允许横屏,来控制只有竖屏的状态*/
@property (nonatomic, assign) BOOL     isAllowLandscape;
@property (nonatomic, assign) BOOL     isStatusBarHidden;
/** 是否是横屏状态 */
@property (nonatomic, assign) BOOL     isLandscape;
+ (instancetype)sharedBrightnessView;

@end
