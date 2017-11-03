//
//  SPVideoPopView.h
//  SPVideoPlayer
//
//  Created by leshengping on 17/8/28.  （https://github.com/SPStore/SPVideoPlayer
//  Copyright © 2017年 leshengping. All rights reserved.
//  仅针对该视频播放器封装的一个从右边弹出来的popView，如显示分辨率列表，选集列表等

#import <UIKit/UIKit.h>

UIKIT_EXTERN NSNotificationName const SPVideoPopViewWillShowNSNotification;
UIKIT_EXTERN NSNotificationName const SPVideoPopViewWillHideNSNotification;

@interface SPVideoPopView : UIView

/**
 * 显示SPVideoPopView
 * @param view 准备把SPVideoPopView添加到哪个view上
 * @param customView 自定义的view;外界创建好一个自定义的view并给定frame，传给customView,该方法内部会自动把你的customView添加到SPVideoPopView(实际上是SPVideoPopContentView)上去,并以动画的形式从左(右)边弹出,如果是想从右边弹出，那customView的x值就必须是屏幕的宽度
 */
+ (instancetype)showVideoPopViewToView:(UIView *)view customView:(UIView *)customView;

/**
 * 隐藏SPVideoPopView
 * @param view 添加SPVideoPopView的那个view
 */
+ (void)hideVideoPopViewForView:(UIView *)view;

@end

@interface SPVideoPopContentView : UIView
@property (nonatomic, strong) UIImageView *backgroundImageView;
@end
