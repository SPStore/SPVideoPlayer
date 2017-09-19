//
//  SPDownLoadingCell.m
//  SPVideoPlayer
//
//  Created by Libo on 17/9/2.
//  Copyright © 2017年 iDress. All rights reserved.
//

#import "SPDownLoadingCell.h"
#import "SPDownload.h"
#import "SPVideoModel.h"
#import "SPDownLoadModel.h"
#import "UIImageView+WebCache.h"
#import "SPProgressView.h"
#import "SPTimerManager.h"

@interface SPDownLoadingCell()
@property (weak, nonatomic) IBOutlet UIImageView *coverImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet SPProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (nonatomic, assign) NSInteger totalBytesWritten;

@end

@implementation SPDownLoadingCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}


- (void)setVideoModel:(SPVideoModel *)videoModel {
    _videoModel = videoModel;
    
    [self.coverImageView sd_setImageWithURL:[NSURL URLWithString:videoModel.coverForFeed] placeholderImage:[UIImage imageNamed:@"qyplayer_aura2_background_normal_iphone_375x211_"]];
    self.titleLabel.text = videoModel.title;
    
    __weak SPDownloadInfo *info = [[SPDownloadManager defaultManager] downloadInfoForURL:videoModel.playUrl];
    self.sizeLabel.text = [NSString stringWithFormat:@"%ldM",(long)info.totalBytesExpectedToWrite/(1000*1000)];
    
    if (info.state == SPDownloadStateCompleted) {
        self.progressView.hidden = YES;
        self.speedLabel.text = @"下载完成";
    } else if (info.state == SPDownloadStateSuspened) {
        self.progressView.hidden = NO;
        self.speedLabel.text = @"已暂停";
        
    } else if (info.state == SPDownloadStateWillResume) {
        self.progressView.hidden = NO;
        self.speedLabel.text = @"等待中";
    } else {
        self.progressView.hidden = NO;
        if (info.totalBytesExpectedToWrite) {
            // 进度回调
            info.progressChangeBlock = ^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
                // 更新UI一定要在主线程
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.progressView.progress = 1.0 * info.totalBytesWritten / info.totalBytesExpectedToWrite;
                    
                });
            };
            
            info.speedChangeBlock = ^(NSString *speed,NSString *remainingTime) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if (info.state == SPDownloadStateCompleted) {
                    } else {
                        self.speedLabel.text = speed;
                    }
                });
            };
            
            info.stateChangeBlock = ^(SPDownloadState state, NSString *file, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (state == SPDownloadStateCompleted) {
                        // 更新UI一定要在主线程
                        self.speedLabel.text = @"下载完成";
                        self.progressView.hidden = YES;
                    } else if (state == SPDownloadStateSuspened) {
                        self.speedLabel.text = @"已暂停";
                        self.progressView.hidden = NO;
                    } else if (info.state == SPDownloadStateWillResume) {
                        self.progressView.hidden = NO;
                        self.speedLabel.text = @"等待中";
                    } else if (info.state == SPDownloadStateResumed) {
                        self.speedLabel.text = @"";
                    }
                });
            };
            
        } else {
            self.progressView.progress = 0.0;
        }
    }
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
    
}

@end
