//
//  SPCollectionViewCell.m
//  SPVideoPlayer
//
//  Created by leshengping on 17/8/23.
//  Copyright © 2017年 leshengping. All rights reserved.
//

#import "SPCollectionViewCell.h"
#import "SPVideoModel.h"
#import "UIImageView+WebCache.h"

@implementation SPCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.videoContentView.tag = 102;
}

- (void)setModel:(SPVideoModel *)model {
    _model = model;
    [self.topicImageView sd_setImageWithURL:[NSURL URLWithString:model.coverForFeed] placeholderImage:[UIImage imageNamed:@"SPVideoPlayer.bundle/qyplayer_aura2_background_normal_iphone_375x211_"]];
    self.titleLabel.text = model.title;
}

- (IBAction)play:(UIButton *)sender {
    if (self.playBlock) {
        self.playBlock(sender);
    }
    
}

@end
