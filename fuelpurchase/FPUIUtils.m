//
//  FPUIUtils.m
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 9/14/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import "FPUIUtils.h"
#import <BlocksKit/UIControl+BlocksKit.h>
#import <PEObjc-Commons/PEUIUtils.h>
#import <PEObjc-Commons/PEUtils.h>
#import <PEObjc-Commons/UIView+PERoundify.h>
#import <FlatUIKit/UIColor+FlatUI.h>

@implementation FPUIUtils

#pragma mark - Helpers

+ (UIView *)headerPanelWithText:(NSString *)headerText relativeToView:(UIView *)relativeToView {
  return [PEUIUtils leftPadView:[PEUIUtils labelWithKey:headerText
                                                   font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                        backgroundColor:[UIColor clearColor]
                                              textColor:[UIColor darkGrayColor]
                                    verticalTextPadding:3.0
                                             fitToWidth:relativeToView.frame.size.width - 15.0]
                        padding:8.0];
}

+ (FPEnableUserInteractionBlk)makeUserEnabledBlockForController:(UIViewController *)controller {
  return ^(BOOL enable) {
    [APP enableJotButton:enable];
    [[[controller navigationItem] leftBarButtonItem] setEnabled:enable];
    [[[controller navigationItem] rightBarButtonItem] setEnabled:enable];
    [[[controller tabBarController] tabBar] setUserInteractionEnabled:enable];
    [controller.navigationItem setHidesBackButton:!enable animated:YES];
  };
}

@end
