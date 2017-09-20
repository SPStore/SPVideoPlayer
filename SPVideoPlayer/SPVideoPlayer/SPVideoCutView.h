//
//  SPVideoCutView.h
//  SPVideoPlayer
//
//  Created by leshengping on 17/8/2.  （https://github.com/SPStore/SPVideoPlayer
//  Copyright © 2017年 leshengping. All rights reserved.
//  截图的view

#import <UIKit/UIKit.h>

@protocol SPVideoCutViewDelegate <NSObject>

@optional;
- (void)cutViewCancelButtonClicked:(UIButton *)button;

@end

@interface SPVideoCutView : UIView

@property (nonatomic, weak) id<SPVideoCutViewDelegate> delegate;

- (void)setCutImage:(UIImage *)image;
- (void)setText:(NSString *)text;

@end
