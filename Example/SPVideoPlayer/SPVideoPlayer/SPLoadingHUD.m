//
//  SPLoadingHUD.m
//  SPHUD
//
//  Created by leshengping on 17/8/8.  （https://github.com/SPStore/SPVideoPlayer
//  Copyright © 2017年 leshengping. All rights reserved.
//  一个简单的加载指示器

#import "SPLoadingHUD.h"

typedef NS_ENUM(NSInteger, SPProgressHUDAnimation) {
    /// Opacity animation
    SPProgressHUDAnimationFade,
    /// Opacity + scale animation (zoom in when appearing zoom out when disappearing)
    SPProgressHUDAnimationZoom,
    /// Opacity + scale animation (zoom out style)
    SPProgressHUDAnimationZoomOut,
    /// Opacity + scale animation (zoom in style)
    SPProgressHUDAnimationZoomIn
};

#define  SPMainThreadAssert() NSAssert([NSThread isMainThread], @"SPLoadingHUD需要在主线程.");


@interface SPLoadingHUD()
// "菊花"指示器
@property (nonatomic, strong) UIActivityIndicatorView *indicator;
// label
@property (nonatomic, strong) UILabel *textLabel;
// 下面这2个view提高了bezelView约束的灵活性，保证了bezelView的内容的顶部间距和底部间距可以自由伸缩(>=margin),如果直接设置顶部和底部约束，则只能用“(==margin)”,这样上下间距就固定死了，当bezelView的高度强制改变后，bezelView里面的内容(尤其是label)就会随高度伸缩，这不是我们想要的
// 充当顶部或左边间距的view
@property (nonatomic, strong) UIView *topLeftSpacer;
// 充当底部或右边间距的view
@property (nonatomic, strong) UIView *bottomRightSpacer;
@property (nonatomic, strong) NSArray *bezelConstraints;
@property (nonatomic, strong) UIFont *labelFont;
// "菊花"和"label"之间的间距
@property (nonatomic, assign) CGFloat padding;

@property (assign, nonatomic) SPProgressHUDAnimation animationType UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) NSDate *showStarted;
@property (nonatomic, assign, getter=hasFinished) BOOL finished;
@property (nonatomic, assign) CGFloat opacity;
@end

@implementation SPLoadingHUD

+ (SPLoadingHUD *)showHUDWithAnimated:(BOOL)animated {
    return [self showHUDWithTitle:nil animated:animated];
}

+ (SPLoadingHUD *)showHUDWithTitle:(NSString *)title animated:(BOOL)animated{
    
    return [self showHUDWithTitle:title toView:nil animated:animated];
    
}

+ (SPLoadingHUD *)showHUDWithTitle:(NSString *)title toView:(UIView *)view animated:(BOOL)animated {
    return [self showHUDWithTitle:title toView:view position:SPActivityIndicatorPositionTop animated:animated];
}

+ (SPLoadingHUD *)showHUDWithTitle:(NSString *)title toView:(UIView *)view position:(SPActivityIndicatorPosition)position animated:(BOOL)animated{
    if (view == nil) {
        view = [[UIApplication sharedApplication].windows lastObject];
    }
    NSAssert(view, @"View must not be nil.");
    SPLoadingHUD *hud = [[SPLoadingHUD alloc] initWithView:view];
    hud.activityIndicatorPosition = position;
    hud.removeFromSuperViewOnHide = YES;
    if (![self isBlankString:title]) { // 如果title不为空
        hud.textLabel.text = title;
    }
    [view addSubview:hud];
    [hud showAnimated:animated];
    return hud;
}

+ (BOOL)hideHUDWithAnimated:(BOOL)animated {
    return [self hideHUDForView:nil animated:animated];
}

+ (BOOL)hideHUDForView:(UIView *)view animated:(BOOL)animated {
    if (view == nil) {
        view = [[UIApplication sharedApplication].windows lastObject];
    }
    SPLoadingHUD *hud = [self HUDForView:view];
    hud.removeFromSuperViewOnHide = YES;
    if (hud != nil) {
        [hud hideAnimated:animated];
        return YES;
    }
    return NO;
}

- (void)hideHUDWithAnimated:(BOOL)animated afterDelay:(NSTimeInterval)delay {
    NSTimer *timer = [NSTimer timerWithTimeInterval:delay target:self selector:@selector(handleHideTimer:) userInfo:@(animated) repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

+ (SPLoadingHUD *)HUDForView:(UIView *)view {
    // 逆序枚举
    NSEnumerator *subviewsEnum = [view.subviews reverseObjectEnumerator];
    for (UIView *subview in subviewsEnum) {
        if ([subview isKindOfClass:self]) {
            return (SPLoadingHUD *)subview;
        }
    }
    return nil;
}

- (void)handleHideTimer:(NSTimer *)timer {
    [self hideAnimated:[timer.userInfo boolValue]];
}

- (instancetype)initWithView:(UIView *)view {
    // 给self(self就是hud)设置尺寸
    return [self initWithFrame:view.bounds];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    return self;
}

// 初始化操作
- (void)commonInit {
    _animationType = SPProgressHUDAnimationFade;
    // 默认"菊花"在顶部
    self.activityIndicatorPosition = SPActivityIndicatorPositionTop;
    _contentColor = [UIColor colorWithWhite:1.f alpha:0.7f];
    _labelFont = [UIFont systemFontOfSize:16];
    _margin = 20.f;
    _opacity = 1.f;
    _defaultMotionEffectsEnabled = YES;

    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [self setupViews];
}

- (void)setupViews {
    UIView *backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    backgroundView.backgroundColor = [UIColor clearColor];
    [self addSubview:backgroundView];
    _backgroundView = backgroundView;
    
    SPBezelView *bezelView = [SPBezelView new];
    bezelView.translatesAutoresizingMaskIntoConstraints = NO;
    bezelView.appearance = SPLoadingHUDAppearanceRound;
    [self addSubview:bezelView];
    _bezelView = bezelView;
    [self updateBezelMotionEffects];
    
    UIView *topLeftSpacer = [UIView new];
    topLeftSpacer.translatesAutoresizingMaskIntoConstraints = NO;
    topLeftSpacer.hidden = YES;
    [bezelView addSubview:topLeftSpacer];
    _topLeftSpacer = topLeftSpacer;
    
    UIView *bottomRightSpacer = [UIView new];
    bottomRightSpacer.translatesAutoresizingMaskIntoConstraints = NO;
    bottomRightSpacer.hidden = YES;
    [bezelView addSubview:bottomRightSpacer];
    _bottomRightSpacer = bottomRightSpacer;

    UILabel *textLabel = [UILabel new];
    textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    // 设置抗压缩优先级,优先级越高越不容易被压缩,默认的优先级是750
    [textLabel setContentCompressionResistancePriority:998.f forAxis:UILayoutConstraintAxisHorizontal];
    [textLabel setContentCompressionResistancePriority:998.f forAxis:UILayoutConstraintAxisVertical];
    textLabel.adjustsFontSizeToFitWidth = NO;
    textLabel.textAlignment = NSTextAlignmentCenter;
    textLabel.textColor = self.contentColor;
    textLabel.font = self.labelFont;
    textLabel.opaque = NO;
    [bezelView addSubview:textLabel];
    _textLabel = textLabel;

}

// 字符串是否为空
+ (BOOL)isBlankString:(NSString *)string {
    if (string == nil || string == NULL) {
        return YES;
    }
    if ([string isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0) {
        return YES;
    }
    return NO;
}

- (void)showAnimated:(BOOL)animated {
    // 需要在主线程
    SPMainThreadAssert();
    
    [self.bezelView.layer removeAllAnimations];
    [self.backgroundView.layer removeAllAnimations];
    
    self.finished = NO;
    self.showStarted = [NSDate date];
    self.alpha = 1.f;
    
    if (animated) {
        [self animateIn:YES withType:self.animationType completion:NULL];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        self.bezelView.alpha = self.opacity;
#pragma clang diagnostic pop
        self.backgroundView.alpha = 1.f;
    }
}

- (void)hideAnimated:(BOOL)animated {
    // 需要在主线程
    SPMainThreadAssert()
    
    self.finished = YES;
    
    if (animated && self.showStarted) {
        self.showStarted = nil;
        [self animateIn:NO withType:self.animationType completion:^(BOOL finished) {
            [self done];
        }];
    } else {
        self.showStarted = nil;
        self.bezelView.alpha = 0.f;
        self.backgroundView.alpha = 1.f;
        [self done];
    }
}

- (void)animateIn:(BOOL)animatingIn withType:(SPProgressHUDAnimation)type completion:(void(^)(BOOL finished))completion {
    // Automatically determine the correct zoom animation type
    if (type == SPProgressHUDAnimationZoom) {
        type = animatingIn ? SPProgressHUDAnimationZoomIn : SPProgressHUDAnimationZoomOut;
    }
    
    CGAffineTransform small = CGAffineTransformMakeScale(0.5f, 0.5f);
    CGAffineTransform large = CGAffineTransformMakeScale(1.5f, 1.5f);
    
    // Set starting state
    UIView *bezelView = self.bezelView;
    if (animatingIn && bezelView.alpha == 0.f && type == SPProgressHUDAnimationZoomIn) {
        bezelView.transform = small;
    } else if (animatingIn && bezelView.alpha == 0.f && type == SPProgressHUDAnimationZoomOut) {
        bezelView.transform = large;
    }
    
    // Perform animations
    dispatch_block_t animations = ^{
        if (animatingIn) {
            bezelView.transform = CGAffineTransformIdentity;
        } else if (!animatingIn && type == SPProgressHUDAnimationZoomIn) {
            bezelView.transform = large;
        } else if (!animatingIn && type == SPProgressHUDAnimationZoomOut) {
            bezelView.transform = small;
        }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        bezelView.alpha = animatingIn ? self.opacity : 0.f;
#pragma clang diagnostic pop
        self.backgroundView.alpha = animatingIn ? 1.f : 0.f;
    };
    
    [UIView animateWithDuration:0.3 delay:0. options:UIViewAnimationOptionBeginFromCurrentState animations:animations completion:completion];
}

- (void)done {
    
    if (self.hasFinished) {
        self.alpha = 0.0f;
        if (self.removeFromSuperViewOnHide) {
            [self removeFromSuperview];
        }
    }
    SPLoadingHUDCompletionBlock completionBlock = self.completionBlock;
    if (completionBlock) {
        completionBlock();
    }
    id<SPLoadingHUDDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(hudWasHidden:)]) {
        [delegate performSelector:@selector(hudWasHidden:) withObject:self];
    }
}


#pragma mark - Properties

- (void)setContentColor:(UIColor *)contentColor {
    if (contentColor != _contentColor) {
        self.indicator.color = contentColor;
        self.textLabel.textColor = contentColor;
    }
}

- (void)setLabelColor:(UIColor *)labelColor {
    if (labelColor != _labelColor) {
        self.textLabel.textColor = labelColor;
    }
}

- (void)setIndicatorColor:(UIColor *)indicatorColor {
    if (indicatorColor != _indicatorColor) {
        _indicatorColor = indicatorColor;
        UIActivityIndicatorView *indicator = self.indicator;
        if ([indicator isKindOfClass:[UIActivityIndicatorView class]]) {
            [indicator setColor:indicatorColor];
        }
    }
}

- (void)setLabelFont:(UIFont *)labelFont {
    if (labelFont != _labelFont) {
        _labelFont = labelFont;
        self.textLabel.font = labelFont;
        [self setNeedsUpdateConstraints];
    }
}

- (void)setOffset:(CGPoint)offset {
    if (!CGPointEqualToPoint(offset, _offset)) {
        _offset = offset;
        [self setNeedsUpdateConstraints];
    }
}

- (void)setMargin:(CGFloat)margin {
    if (margin != _margin) {
        _margin = margin;
        [self setNeedsUpdateConstraints];
    }
}

- (void)setPadding:(CGFloat)padding {
    if (padding != _padding) {
        _padding = padding;
        [self setNeedsUpdateConstraints];
    }
}

- (void)setMinSize:(CGSize)minSize {
    if (!CGSizeEqualToSize(minSize, _minSize)) {
        _minSize = minSize;
        [self setNeedsUpdateConstraints];
    }
}

- (void)setActivityIndicatorPosition:(SPActivityIndicatorPosition)activityIndicatorPosition {
    
    _activityIndicatorPosition = activityIndicatorPosition;
    [_indicator removeFromSuperview];
    _indicator = nil;
    if (activityIndicatorPosition != SPActivityIndicatorPositionNone) {
        // 创建"菊花"
        UIActivityIndicatorView *indicator = [UIActivityIndicatorView new];
        indicator.translatesAutoresizingMaskIntoConstraints = NO;
        [indicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
        indicator.color = self.contentColor;
        [indicator startAnimating];
        [_bezelView addSubview:indicator];
        _indicator = indicator;
        if (activityIndicatorPosition == SPActivityIndicatorPositionTop) {
            _padding = 0.f;
            _margin = 20.f;
            self.labelFont = [UIFont systemFontOfSize:16];
            [self.indicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
        } else {
            _padding = 5.f;
            _margin = 10.f;
            self.labelFont = [UIFont systemFontOfSize:14];
            [self.indicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
        }
    } else {
        _padding = 0.f;
        _margin = 20.f;
        self.labelFont = [UIFont systemFontOfSize:16];
    }
    [self setNeedsUpdateConstraints];
}

- (void)setActivityIndicatorStyle:(SPActivityIndicatorStyle)activityIndicatorStyle {
    _activityIndicatorStyle = activityIndicatorStyle;
    switch (activityIndicatorStyle) {
        case SPActivityIndicatorStyleWhiteLarge:{
            [self.indicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
        }
            break;
        case SPActivityIndicatorStyleWhite:{
            [self.indicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
        }
            break;
        case SPActivityIndicatorStyleGray:{
            [self.indicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
        }
            break;
        default:
            break;
    }
}

- (void)setDefaultMotionEffectsEnabled:(BOOL)defaultMotionEffectsEnabled {
    if (defaultMotionEffectsEnabled != _defaultMotionEffectsEnabled) {
        _defaultMotionEffectsEnabled = defaultMotionEffectsEnabled;
        [self updateBezelMotionEffects];
    }
}

#pragma mark - UI   (VFL语言布局)

- (void)updateConstraints {

    UIView *bezel = self.bezelView;
    UIView *topLeftSpacer = self.topLeftSpacer;
    UIView *bottomRightSpacer = self.bottomRightSpacer;
    CGFloat margin = self.margin;
    NSMutableArray *bezelConstraints = [NSMutableArray array];
    NSDictionary *metrics = @{@"margin": @(margin)};

    // 移除存在的约束
    [self removeConstraints:self.constraints];
    [topLeftSpacer removeConstraints:topLeftSpacer.constraints];
    [bottomRightSpacer removeConstraints:bottomRightSpacer.constraints];
    if (self.bezelConstraints) {
        [bezel removeConstraints:self.bezelConstraints];
        self.bezelConstraints = nil;
    }
    
    CGPoint offset = self.offset;
    NSMutableArray *centeringConstraints = [NSMutableArray array];
    // bezel水平居中
    [centeringConstraints addObject:[NSLayoutConstraint constraintWithItem:bezel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.f constant:offset.x]];
    // bezel垂直居中
    [centeringConstraints addObject:[NSLayoutConstraint constraintWithItem:bezel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.f constant:offset.y]];
    [self applyPriority:998.f toConstraints:centeringConstraints];
    [self addConstraints:centeringConstraints];
    
    NSMutableArray *sideConstraints = [NSMutableArray array];
    // bezel上下左右间距大于等于20
    [sideConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=margin)-[bezel]-(>=margin)-|" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(bezel)]];
    [sideConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=margin)-[bezel]-(>=margin)-|" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(bezel)]];
    [self applyPriority:999.f toConstraints:sideConstraints];
    [self addConstraints:sideConstraints];
    
    CGSize minimumSize = self.minSize;
    if (!CGSizeEqualToSize(minimumSize, CGSizeZero)) {
        NSMutableArray *minSizeConstraints = [NSMutableArray array];
        [minSizeConstraints addObject:[NSLayoutConstraint constraintWithItem:bezel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:minimumSize.width]];
        [minSizeConstraints addObject:[NSLayoutConstraint constraintWithItem:bezel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:minimumSize.height]];
        [self applyPriority:997.f toConstraints:minSizeConstraints];
        [bezelConstraints addObjectsFromArray:minSizeConstraints];
    }
    
    if (self.square) {
        NSLayoutConstraint *square = [NSLayoutConstraint constraintWithItem:bezel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:bezel attribute:NSLayoutAttributeWidth multiplier:1.f constant:0];
        square.priority = 997.f;
        [bezelConstraints addObject:square];
    }
    
    NSLayoutAttribute layoutAttributeCenterXY;
    NSString *ruleString;
    NSLayoutAttribute layoutAttributeTopLeft;
    NSLayoutAttribute layoutAttributeBottomRight;
    NSLayoutAttribute layoutAttributeWidthHeight;
    
    if (self.activityIndicatorPosition == SPActivityIndicatorPositionTop || self.activityIndicatorPosition == SPActivityIndicatorPositionNone) {
        layoutAttributeCenterXY = NSLayoutAttributeCenterX;
        ruleString = @"H:";
        layoutAttributeTopLeft = NSLayoutAttributeTop;
        layoutAttributeBottomRight = NSLayoutAttributeBottom;
        layoutAttributeWidthHeight = NSLayoutAttributeHeight;
        
    } else if (self.activityIndicatorPosition == SPActivityIndicatorPositionLeft) {
        layoutAttributeCenterXY = NSLayoutAttributeCenterY;
        ruleString = @"V:";
        layoutAttributeTopLeft = NSLayoutAttributeLeft;
        layoutAttributeBottomRight = NSLayoutAttributeRight;
        layoutAttributeWidthHeight = NSLayoutAttributeWidth;
    }
    
    // 顶部(左边)间距大于或等于20
    [topLeftSpacer addConstraint:[NSLayoutConstraint constraintWithItem:topLeftSpacer attribute:layoutAttributeWidthHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:margin]];
    // 底部(右边)间距大于或等于20
    [bottomRightSpacer addConstraint:[NSLayoutConstraint constraintWithItem:bottomRightSpacer attribute:layoutAttributeWidthHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:margin]];
    // 顶部(左边)间距和底部(右边)间距相等
    [bezelConstraints addObject:[NSLayoutConstraint constraintWithItem:topLeftSpacer attribute:layoutAttributeWidthHeight relatedBy:NSLayoutRelationEqual toItem:bottomRightSpacer attribute:layoutAttributeWidthHeight multiplier:1.f constant:0.f]];
    
    NSMutableArray *subviews = [NSMutableArray arrayWithObjects:self.topLeftSpacer, self.textLabel, self.bottomRightSpacer, nil];
    if (self.indicator) {
        [subviews insertObject:self.indicator atIndex:1];
    }
    NSMutableArray *paddingConstraints = [NSMutableArray new];
    [subviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        // bezel内部的每个子控件都水平居中
        [bezelConstraints addObject:[NSLayoutConstraint constraintWithItem:view attribute:layoutAttributeCenterXY relatedBy:NSLayoutRelationEqual toItem:bezel attribute:layoutAttributeCenterXY multiplier:1.f constant:0.f]];
        // bezel内部的每个子控件的左右间距最大于等于margin
        [bezelConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"%@|-(>=margin)-[view]-(>=margin)-|",ruleString] options:0 metrics:metrics views:NSDictionaryOfVariableBindings(view)]];
        // 元素间距
        if (idx == 0) {
            // 第一个子控件顶部间距为0
            [bezelConstraints addObject:[NSLayoutConstraint constraintWithItem:view attribute:layoutAttributeTopLeft relatedBy:NSLayoutRelationEqual toItem:bezel attribute:layoutAttributeTopLeft multiplier:1.f constant:0.f]];
        } else if (idx == subviews.count - 1) {
            // 最后一个子控件底部间距为0
            [bezelConstraints addObject:[NSLayoutConstraint constraintWithItem:view attribute:layoutAttributeBottomRight relatedBy:NSLayoutRelationEqual toItem:bezel attribute:layoutAttributeBottomRight multiplier:1.f constant:-0.f]];
        }
        if (idx > 0) {
            // 子控件之间的垂直间距为0
            NSLayoutConstraint *padding = [NSLayoutConstraint constraintWithItem:view attribute:layoutAttributeTopLeft relatedBy:NSLayoutRelationEqual toItem:subviews[idx - 1] attribute:layoutAttributeBottomRight multiplier:1.f constant:_padding];
            [bezelConstraints addObject:padding];
            [paddingConstraints addObject:padding];
        }
    }];
    [bezel addConstraints:bezelConstraints];
    self.bezelConstraints = [bezelConstraints copy];
    
    [super updateConstraints];
}

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (void)updateBezelMotionEffects {
    SPBezelView *bezelView = self.bezelView;
    if (![bezelView respondsToSelector:@selector(addMotionEffect:)]) return;
    
    if (self.defaultMotionEffectsEnabled) {
        CGFloat effectOffset = 10.f;
        UIInterpolatingMotionEffect *effectX = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        effectX.maximumRelativeValue = @(effectOffset);
        effectX.minimumRelativeValue = @(-effectOffset);
        
        UIInterpolatingMotionEffect *effectY = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        effectY.maximumRelativeValue = @(effectOffset);
        effectY.minimumRelativeValue = @(-effectOffset);
        
        UIMotionEffectGroup *group = [[UIMotionEffectGroup alloc] init];
        group.motionEffects = @[effectX, effectY];
        
        [bezelView addMotionEffect:group];
    } else {
        NSArray *effects = [bezelView motionEffects];
        for (UIMotionEffect *effect in effects) {
            [bezelView removeMotionEffect:effect];
        }
    }
}

// 设置优先级
- (void)applyPriority:(UILayoutPriority)priority toConstraints:(NSArray *)constraints {
    for (NSLayoutConstraint *constraint in constraints) {
        constraint.priority = priority;
    }
}


@end

@interface SPBezelView()

@property UIVisualEffectView *effectView;

@end

@implementation SPBezelView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {

        _style = SPLoadingHUDBackgroundStyleBlur;

        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.65];
        self.clipsToBounds = YES;
        
        [self updateForBackgroundStyle];
    }
    return self;
}

#pragma mark - Layout

// 内容大小设置为0，在对SPBezelView设置约束时便可以自适应内容大小
- (CGSize)intrinsicContentSize {
    // Smallest size possible. Content pushes against this.
    return CGSizeZero;
}

#pragma mark - Appearance

- (void)setStyle:(SPLoadingHUDBackgroundStyle)style {
    if (_style != style) {
        _style = style;
        [self updateForBackgroundStyle];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Views

- (void)updateForBackgroundStyle {
    SPLoadingHUDBackgroundStyle style = self.style;
    if (style == SPLoadingHUDBackgroundStyleBlur) {
        if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0) {
            UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
            UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
            [self addSubview:effectView];
            effectView.frame = self.bounds;
            effectView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            self.layer.allowsGroupOpacity = NO;
            self.effectView = effectView;
        }
    } else {
        if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0) {
            [self.effectView removeFromSuperview];
            self.effectView = nil;
        }
    }
}

- (void)setAppearance:(SPLoadingHUDAppearance)appearance {
    _appearance = appearance;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    UIBezierPath *bezierPath;
    switch (_appearance) {
        case SPLoadingHUDAppearanceRound:
            bezierPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:5.f];
            break;
        case SPLoadingHUDAppearanceCircle:
            bezierPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:MIN(rect.size.width, rect.size.height)*0.5];
            break;
        case SPLoadingHUDAppearanceRect:
            bezierPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:0.f];
            break;
        default:
            break;
    }
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.frame = CGRectMake(0, 0, rect.size.width, rect.size.height);
    shapeLayer.path = bezierPath.CGPath;
    self.layer.mask = shapeLayer;
}

@end




