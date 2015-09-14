//
//  FPUIUtils.h
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 9/14/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FPUIUtils : NSObject

+ (UIView *)badgeForNum:(NSInteger)num
                  color:(UIColor *)color
         badgeTextColor:(UIColor *)badgeTextColor;

+ (UIButton *)buttonWithLabel:(NSString *)labelText
                     badgeNum:(NSInteger)badgeNum
                   badgeColor:(UIColor *)badgeColor
               badgeTextColor:(UIColor *)badgeTextColor
            addDisclosureIcon:(BOOL)addDisclosureIcon
                      handler:(void(^)(void))handler
                    uitoolkit:(PEUIToolkit *)uitoolkit
               relativeToView:(UIView *)relativeToView;

@end
