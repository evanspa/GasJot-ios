//
//  FPRaisedCenterTabController.h
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 9/13/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FPRaisedCenterTabController : UITabBarController

#pragma mark - Methods

// Create a view controller and setup it's tab bar item with a title and image
- (UIViewController*)viewControllerWithTabTitle:(NSString*)title
                                          image:(UIImage*)image;

// Create a custom UIButton and add it to the center of our tab bar
- (void)addCenterButtonWithImage:(UIImage*)buttonImage
                  highlightImage:(UIImage*)highlightImage
                    buttonAction:(void(^)(void))buttonAction;

@end
