//
//  SPCollectionViewCell.h
//  SPVideoPlayer
//
//  Created by leshengping on 17/8/23.
//  Copyright © 2017年 leshengping. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SPVideoModel;

@interface SPCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIView *videoContentView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *topicImageView;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
/** model */
@property (nonatomic, strong) SPVideoModel *model;
/** 播放按钮block */
@property (nonatomic, copy  ) void(^playBlock)(UIButton *);

@end
