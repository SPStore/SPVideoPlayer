//
//  SPPlayerControlViewDelegate.h
//
// Copyright (c) 2017年 leshengping  （https://github.com/SPStore/SPVideoPlayer
//

#ifndef SPPlayerControlViewDelegate_h
#define SPPlayerControlViewDelegate_h


#endif /* SPPlayerControlViewDelegate_h */

@protocol SPVideoPlayerControlViewDelegate <NSObject>

@optional
/** 播放或暂停按钮事件 */
- (void)sp_controlViePlayOrPauseButtonClicked:(UIButton *)sender;
/** 下一个视频的按钮事件 */
- (void)sp_controlViewNextButtonClicked:(UIButton *)sender;
/** 上一个视频的按钮事件 */
- (void)sp_controlViewLastButtonClicked:(UIButton *)sender;
/** 全屏按钮事件 */
- (void)sp_controlViewFullScreenButtonClicked:(UIButton *)sender;
/** 切换分辨率按钮事件 */
- (void)sp_controlViewSwitchResolutionWithUrl:(NSString *)urlString;
/** 开始触摸slider */
- (void)sp_controlViewSliderTouchBegan:(UISlider *)slider;
/** slider触摸中 */
- (void)sp_controlViewSliderValueChanged:(UISlider *)slider;
/** slider触摸结束 */
- (void)sp_controlViewSliderTouchEnded:(UISlider *)slider;
/** slider的单击事件（点击slider播放指定位置） */
- (void)sp_controlViewSliderTaped:(CGFloat)value;
/** 快进 */
- (void)sp_controlViewFast_forward;
/** 快退 */
- (void)sp_controlViewFast_backward;

/** 返回按钮事件 */
- (void)sp_controlViewBackButtonClicked:(UIButton *)sender;
/** 下载按钮事件 */
- (void)sp_controlViewDownloadButtonClicked:(UIButton *)sender;


/** 锁定屏幕方向按钮事件 */
- (void)sp_controlViewLockScreenButtonClicked:(UIButton *)sender;
/** 视频截图的按钮事件 */
- (void)sp_controlViewCutButtonClicked:(UIButton *)sender;
/** 重播按钮事件 */
- (void)sp_controlViewRepeatButtonClicked:(UIButton *)sender;
/** 刷新重试 */
- (void)sp_controlViewRefreshButtonClicked:(UIButton *)sender;
/** cell播放中小屏状态 关闭按钮事件 */
- (void)sp_controlViewCloseButtonClicked:(UIButton *)sender;


/** 控制层即将显示 */
- (void)sp_controlViewWillShow:(UIView *)controlView isFullscreen:(BOOL)fullscreen;
/** 控制层即将隐藏 */
- (void)sp_controlViewWillHidden:(UIView *)controlView isFullscreen:(BOOL)fullscreen;

@end
