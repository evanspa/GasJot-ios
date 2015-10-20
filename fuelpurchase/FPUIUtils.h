//
//  FPUIUtils.h
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 9/14/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^FPEnableUserInteractionBlk)(BOOL);

@interface FPUIUtils : NSObject

#pragma mark - Helpers

+ (UIView *)headerPanelWithText:(NSString *)headerText relativeToView:(UIView *)relativeToView;

+ (FPEnableUserInteractionBlk)makeUserEnabledBlockForController:(UIViewController *)controller;

@end
