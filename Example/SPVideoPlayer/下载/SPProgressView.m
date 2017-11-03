//
//  SPProgressView.m
//  SPVideoPlayer
//
//  Created by Libo on 17/9/4.
//  Copyright © 2017年 iDress. All rights reserved.
//

#import "SPProgressView.h"

@implementation SPProgressView

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [[UIColor redColor] set];
    UIRectFill(CGRectMake(0, 0, self.progress * rect.size.width, rect.size.height));
}


@end
