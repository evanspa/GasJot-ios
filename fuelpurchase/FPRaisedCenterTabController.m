//
//  FPRaisedCenterTabController.m
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 9/13/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import "FPRaisedCenterTabController.h"
#import <BlocksKit/UIControl+BlocksKit.h>
#import <BlocksKit/UIView+BlocksKit.h>

@implementation FPRaisedCenterTabController

#pragma mark - Methods

- (UIViewController*)viewControllerWithTabTitle:(NSString*) title image:(UIImage*)image {
  UIViewController* viewController = [[UIViewController alloc] init];
  viewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:title image:image tag:0];
  return viewController;
}

- (UIButton *)addCenterButtonWithImage:(UIImage*)buttonImage
                        highlightImage:(UIImage*)highlightImage
                          buttonAction:(void(^)(id))buttonAction {
  UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
  button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
  button.frame = CGRectMake(0.0, 0.0, buttonImage.size.width, buttonImage.size.height);
  [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
  [button setBackgroundImage:highlightImage forState:UIControlStateHighlighted];
  CGFloat heightDifference = buttonImage.size.height - self.tabBar.frame.size.height;
  if (heightDifference < 0) {
    button.center = self.tabBar.center;
  } else {
    CGPoint center = self.tabBar.center;
    center.y = center.y - heightDifference / 2.0;
    button.center = center;
  }
  [button bk_addEventHandler:buttonAction forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:button];
  return button;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return YES;
}

@end
