//
//  SPBrightnessView.m
//  SPBrightnessView
//
//  Created by leshengping on 17/7/12.  （https://github.com/SPStore/SPVideoPlayer
//  Copyright © 2017年 leshengping. All rights reserved.
//

#import "SPBrightnessView.h"
#import "SPVideoPlayer.h"

@interface SPBrightnessView ()

@property (nonatomic, strong) UIImageView		*backImage;
@property (nonatomic, strong) UILabel			*title;
@property (nonatomic, strong) UIView			*longView;
@property (nonatomic, strong) NSMutableArray	*tipArray;
@property (nonatomic, assign) BOOL				orientationDidChange;

@end

@implementation SPBrightnessView

+ (instancetype)sharedBrightnessView {
    static SPBrightnessView *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SPBrightnessView alloc] init];
        [[UIApplication sharedApplication].keyWindow addSubview:instance];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.frame = CGRectMake(ScreenWidth * 0.5, ScreenHeight * 0.5, 155, 155);
        
        self.layer.cornerRadius  = 10;
        self.layer.masksToBounds = YES;
        
        // 使用UIToolbar实现毛玻璃效果，简单粗暴，支持iOS7+
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:self.bounds];
        toolbar.alpha = 0.97;
        [self addSubview:toolbar];
        
        self.backImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 79, 76)];
        self.backImage.image        = SPPlayerImage(@"player_brightness");
        [self addSubview:self.backImage];
        
        self.title      = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, self.bounds.size.width, 30)];
        self.title.font          = [UIFont boldSystemFontOfSize:16];
        self.title.textColor     = [UIColor colorWithRed:0.25f green:0.22f blue:0.21f alpha:1.00f];
        self.title.textAlignment = NSTextAlignmentCenter;
        self.title.text          = @"亮度";
        [self addSubview:self.title];
        
        self.longView         = [[UIView alloc]initWithFrame:CGRectMake(13, 132, self.bounds.size.width - 26, 7)];
        self.longView.backgroundColor = [UIColor colorWithRed:0.25f green:0.22f blue:0.21f alpha:1.00f];
        [self addSubview:self.longView];
        
        [self createTips];
        [self addNotification];
        [self addObserver];
        
        self.alpha = 0.0;
    }
    return self;
}

// 创建 Tips
- (void)createTips {
    
    self.tipArray = [NSMutableArray arrayWithCapacity:16];
    
    CGFloat tipW = (self.longView.bounds.size.width - 17) / 16;
    CGFloat tipH = 5;
    CGFloat tipY = 1;
    
    for (int i = 0; i < 16; i++) {
        CGFloat tipX          = i * (tipW + 1) + 1;
        UIImageView *image    = [[UIImageView alloc] init];
        image.backgroundColor = [UIColor whiteColor];
        image.frame           = CGRectMake(tipX, tipY, tipW, tipH);
        [self.longView addSubview:image];
        [self.tipArray addObject:image];
    }
    [self updateLongView:[UIScreen mainScreen].brightness];
}

#pragma makr - 通知 KVO

- (void)addNotification {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateLayer:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)addObserver {
    
    [[UIScreen mainScreen] addObserver:self
                            forKeyPath:@"brightness"
                               options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    CGFloat sound = [change[@"new"] floatValue];
    [self appearSoundView];
    [self updateLongView:sound];
}

- (void)updateLayer:(NSNotification *)notify {
    self.orientationDidChange = YES;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - Methond

- (void)appearSoundView {
    if (self.alpha == 0.0) {
        self.orientationDidChange = NO;
        self.alpha = 1.0;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self disAppearSoundView];
        });
    }
}

- (void)disAppearSoundView {
    
    if (self.alpha == 1.0) {
        [UIView animateWithDuration:0.8 animations:^{
            self.alpha = 0.0;
        }];
    }
}

#pragma mark - Update View

- (void)updateLongView:(CGFloat)sound {
    CGFloat stage = 1 / 15.0;
    NSInteger level = sound / stage;
    
    for (int i = 0; i < self.tipArray.count; i++) {
        UIImageView *img = self.tipArray[i];
        
        if (i <= level) {
            img.hidden = NO;
        } else {
            img.hidden = YES;
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.backImage.center = CGPointMake(155 * 0.5, 155 * 0.5);
    self.center = CGPointMake(ScreenWidth * 0.5, ScreenHeight * 0.5);
}

- (void)dealloc {
    [[UIScreen mainScreen] removeObserver:self forKeyPath:@"brightness"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setIsStatusBarHidden:(BOOL)isStatusBarHidden {
    _isStatusBarHidden = isStatusBarHidden;
    [[UIWindow sp_currentViewController] setNeedsStatusBarAppearanceUpdate];
}

- (void)setIsLandscape:(BOOL)isLandscape {
    _isLandscape = isLandscape;
    [[UIWindow sp_currentViewController] setNeedsStatusBarAppearanceUpdate];
}

@end
