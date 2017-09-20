## 功能
1. 支持横竖屏切换
2. 支持从上一次终止播放的地方继续播放
3. 支持水平滑动屏幕和使用滑动条快进快退,并在横屏模式下有预览图
4. 支持音量调节(右半屏幕垂直滑动)和亮度调节(左半屏幕垂直滑动)
5. 支持网络视频和本地视频播放
6. 支持多视频播放，可播放下一集
7. 支持cell上播放，并可设置当cell(整个cell或一半cell)滑出屏幕时终止播放、可设置小屏播放
8. 提供锁屏、截图功能
9. 支持分辨率切换
10. 含有视频下载功能
11. 含有网络监听
12. 可自定义播放界面(即控制层，默认的控制层是SPVideoPlayerControlView)

## 如何使用
```
// 创建视频播放的模型
- (SPVideoItem *)videoItem {
    if (!_videoItem) {
        _videoItem                  = [[SPVideoItem alloc] init];
        _videoItem.title            = @"视频标题";
        _videoItem.videoURL         = [NSURL URLWithString:_videoModel.playUrl];
        _videoItem.placeholderImage = [UIImage imageNamed:@"qyplayer_aura2_background_normal_iphone_375x211_"];
        // playerView的父视图
        _videoItem.fatherView       = self.playerFatherView;
    }
    return _videoItem;
}
```
