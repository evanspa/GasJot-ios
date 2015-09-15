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

- (UIViewController*)viewControllerWithTabTitle:(NSString*)title
                                          image:(UIImage*)image;

- (UIButton *)addCenterButtonWithImage:(UIImage*)buttonImage
                        highlightImage:(UIImage*)highlightImage
                          buttonAction:(void(^)(id))buttonAction;

@end
