//
//  UIWindow+CurrentViewController.h
//  Player
//
//  Created by leshengping on 17/7/12.
//  Copyright © 2017年 leshengping. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIWindow (CurrentViewController)

/*!
 @method currentViewController
 
 @return Returns the topViewController in stack of topMostController.
 */
+ (UIViewController*)sp_currentViewController;
@end
