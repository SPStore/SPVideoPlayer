//
//  SPLoadingHUD.h
//  SPHUD
//
//  Created by leshengping on 17/8/8. （https://github.com/SPStore/SPVideoPlayer
//  Copyright © 2017年 leshengping. All rights reserved.
//  一个简单的加载指示器,支持iOS8或iOS8以上版本, 实现原理参考了MBProgressHUD框架

#import <UIKit/UIKit.h>

@class SPLoadingHUD;
@class SPBezelView;
@protocol SPLoadingHUDDelegate <NSObject>

@optional;
// 隐藏后回调
- (void)hudWasHidden:(SPLoadingHUD *)hud;

@end
typedef NS_ENUM(NSInteger,SPActivityIndicatorPosition) {
    SPActivityIndicatorPositionTop,  // "菊花"在顶部
    SPActivityIndicatorPositionLeft, // "菊花"在左边
    SPActivityIndicatorPositionNone  // 没有"菊花"
};

typedef NS_ENUM(NSInteger,SPActivityIndicatorStyle) {
    SPActivityIndicatorStyleWhiteLarge,  // 白色大号
    SPActivityIndicatorStyleWhite,       // 白色小号
    SPActivityIndicatorStyleGray         // 灰色
};

typedef NS_ENUM(NSInteger, SPLoadingHUDBackgroundStyle) {
    /// Solid color background
    SPLoadingHUDBackgroundStyleSolidColor,
    /// UIVisualEffectView background view
    SPLoadingHUDBackgroundStyleBlur
};

typedef NS_ENUM(NSInteger, SPLoadingHUDAppearance) {
    SPLoadingHUDAppearanceRound,   // 圆角，圆角半径为5
    SPLoadingHUDAppearanceCircle,  // 圆，正方形时为圆,如果是矩形,形似操场状(两边半圆，中间矩形)
    SPLoadingHUDAppearanceRect     // 矩形
};

typedef void(^SPLoadingHUDCompletionBlock)();

@interface SPLoadingHUD : UIView

// 注：如果以类方法显示和隐藏，内部设置了removeFromSuperViewOnHide，隐藏HUD会自动从父View中移除，外界无法修改removeFromSuperViewOnHide; 如果以对象方法显示和隐藏,默认会在隐藏后从父view中移除，外界可以修改removeFromSuperViewOnHide

// ----------------------------- 显示 --------------------------------------

// 显示HUD，默认不带文字，只有一朵"菊花",显示在window上
+ (instancetype)showHUDWithAnimated:(BOOL)animated;

// 显示HUD，有"菊花"和文字，如果文字为空则只显示"菊花",显示在window上
+ (instancetype)showHUDWithTitle:(NSString *)title animated:(BOOL)animated;

// 显示HUD，有"菊花"和文字，如果文字为空则只显示"菊花",显示在指定的view上
+ (instancetype)showHUDWithTitle:(NSString *)title toView:(UIView *)view animated:(BOOL)animated;

// 显示HUD，有"菊花"和文字，如果文字为空则只显示"菊花",显示在指定的view上，并可设置"菊花"的位置
+ (instancetype)showHUDWithTitle:(NSString *)title toView:(UIView *)view position:(SPActivityIndicatorPosition)position animated:(BOOL)animated;

// 显示HUD,对象方法
- (void)showAnimated:(BOOL)animated;

// ----------------------------- 隐藏 --------------------------------------

// 注意使用的时候隐藏的方法要和显示的方法相互对应，比如显示的时候指定了view，隐藏时也要指定同样的view

// 隐藏HUD
+ (BOOL)hideHUDWithAnimated:(BOOL)animated;

// 隐藏指定view上的HUD
+ (BOOL)hideHUDForView:(UIView *)view animated:(BOOL)animated;

// 隐藏HUD,对象方法
- (void)hideAnimated:(BOOL)animated;

// 多长时间后隐藏,对象方法
- (void)hideHUDWithAnimated:(BOOL)animated afterDelay:(NSTimeInterval)delay;

// 背景
@property (nonatomic, strong, readonly) UIView *backgroundView;
// 挡板，上面添加"菊花"指示器和label
@property (nonatomic, strong, readonly) SPBezelView *bezelView;

// "菊花"的位置,如果为SPActivityIndicatorPositionNone则不显示"菊花"
@property (nonatomic, assign) SPActivityIndicatorPosition activityIndicatorPosition;
// "菊花"样式
@property (nonatomic, assign) SPActivityIndicatorStyle activityIndicatorStyle;

// 内容颜色("菊花"和label)
@property (nonatomic, strong) UIColor *contentColor;
// label颜色
@property (nonatomic, strong) UIColor *labelColor;
// "菊花"指示器的颜色
@property (nonatomic, strong) UIColor *indicatorColor;
// label
@property (nonatomic, strong, readonly) UILabel *textLabel;
// 调整HUD在垂直方向的位置,默认是居中显示
@property (nonatomic, assign) CGPoint offset;
// 内容的四周边距
@property (nonatomic, assign) CGFloat margin;
// 最小size
@property (nonatomic, assign) CGSize minSize;

// 是否强制等宽等高
@property (nonatomic, assign, getter=isSquare) BOOL square;

// 隐藏后是否从父view中移除,默认为YES
@property (assign, nonatomic) BOOL removeFromSuperViewOnHide;

// 隐藏后回调
@property (nonatomic, copy) SPLoadingHUDCompletionBlock completionBlock;
@property (weak, nonatomic) id<SPLoadingHUDDelegate> delegate;

// 是否默认视觉效果
@property (assign, nonatomic, getter=areDefaultMotionEffectsEnabled) BOOL defaultMotionEffectsEnabled UI_APPEARANCE_SELECTOR;
@end


@interface SPBezelView : UIView

// HUD的填充样式，分为纯颜色和毛玻璃 (默认是毛玻璃)
@property (nonatomic, assign) SPLoadingHUDBackgroundStyle style;
// HUD的外观样式,分为圆角，圆和矩形  (默认为圆角，圆角半径为5)
@property (nonatomic, assign) SPLoadingHUDAppearance appearance;

@end




