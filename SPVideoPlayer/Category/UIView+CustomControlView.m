//
//  UIView+CustomControlView.m
//
//  Created by leshengping on 17/7/12.
//  Copyright © 2017年 leshengping. All rights reserved.
//

#import "UIView+CustomControlView.h"
#import <objc/runtime.h>

@implementation UIView (CustomControlView)

- (void)setDelegate:(id<SPVideoPlayerControlViewDelegate>)delegate {
    objc_setAssociatedObject(self, @selector(delegate), delegate, OBJC_ASSOCIATION_ASSIGN);
}

- (id<SPVideoPlayerControlViewDelegate>)delegate {
   return objc_getAssociatedObject(self, _cmd);
}

/**
 *  实现此方法，控制层可以得到播放模型以及正在播放的视频url，正在播放的url并不一定是模型中的url，有可能是分辨率字典中的某一个
 */
- (void)sp_setPlayerItem:(SPVideoItem *)videoItem playingUrlString:(NSString *)playingUrlString{};
/**
 *  实现此方法，单击播放器时可以显示或隐藏控制层
 */
- (void)sp_playerShowOrHideControlView{};

/**
 *  实现此方法，重置ControlView，如播放新的视频，播放结束等都需要重置
 */
- (void)sp_playerResetControlView{};

/**
 *  实现此方法，可以设置快进快退时的预览视图
 */
- (void)sp_playerDraggedWithThumbImage:(UIImage *)thumbImage{};

/**
 *  实现此方法，可以决定是否要下载按钮
 */
- (void)sp_playerHasDownloadFunction:(BOOL)sender{};

/**
 *  实现此方法，可以设置下载按钮的状态，如可下载状态和不可下载状态
 */
- (void)sp_playerDownloadBtnState:(BOOL)state{};

/**
 *  实现此方法, 可以设置锁定屏幕方向按钮的状态，如选中状态和未选中状态
 */
- (void)sp_playerLockBtnState:(BOOL)state{};

/**
 *  实现此方法，可以设置在cell上播放时，控制层的相关设置
 */
- (void)sp_playerCellPlay{};

/**
 *  实现此方法，可以设置小屏播放时，控制层的相关设置
 */
- (void)sp_playerBottomShrinkPlay{};

@end
