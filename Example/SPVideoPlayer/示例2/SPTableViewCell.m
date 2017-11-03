//
//  SPTableViewCell.m
//  SPVideoPlayer
//
//  Created by leshengping on 17/8/23.
//  Copyright © 2017年 leshengping. All rights reserved.
//

#import "SPTableViewCell.h"
#import "SPVideoModel.h"
#import "UIImageView+WebCache.h"

@implementation SPTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self layoutIfNeeded];
    [self cutRoundView:self.avatarImageView];
    
    // 设置imageView的tag，在PlayerView中取（建议设置100以上）
    self.videoContentView.tag = 101;

}

- (void)setModel:(SPVideoModel *)model {
    _model = model;

    [self.videoImageView sd_setImageWithURL:[NSURL URLWithString:model.coverForFeed] placeholderImage:[UIImage imageNamed:@"SPVideoPlayer.bundle/qyplayer_aura2_background_normal_iphone_375x211_"]];
    self.titleLabel.text = model.title;
    self.timeLabel.text = [self timestampSwitchTime:[model.date doubleValue]];
    self.descLabel.text = model.video_description;
    
}

- (IBAction)play:(UIButton *)sender {
    if (self.playBlock) {
        self.playBlock(sender);
    }
}

// 切圆角
- (void)cutRoundView:(UIImageView *)imageView {
    CGFloat corner = imageView.bounds.size.width * 0.5;
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:imageView.bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(corner, corner)];
    shapeLayer.path = path.CGPath;
    imageView.layer.mask = shapeLayer;
}

// 将时间戳转化成 时间
- (NSString *)timestampSwitchTime:(double)timestamp{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"]; // hh与HH的区别:分别表示12小时制,24小时制
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"Asia/Beijing"];
    [formatter setTimeZone:timeZone];
    NSDate *confromTimesp = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSString *confromTimespStr = [formatter stringFromDate:confromTimesp];
    return confromTimespStr;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
