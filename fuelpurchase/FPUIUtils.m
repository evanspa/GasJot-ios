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
#import <PEObjc-Commons/UIView+PERoundify.h>
#import <FlatUIKit/UIColor+FlatUI.h>

@implementation FPUIUtils

+ (UIView *)badgeForNum:(NSInteger)num
                  color:(UIColor *)color
         badgeTextColor:(UIColor *)badgeTextColor {
  if (num == 0) {
    return nil;
  }
  CGFloat widthPadding = 30.0;
  CGFloat heightFactor = 1.45;
  CGFloat fontSize = [UIFont systemFontSize];
  NSString *labelText;
  if (num > 9999) {
    fontSize = 10.0;
    widthPadding = 10.0;
    heightFactor = 1.95;
    labelText = @"a plethora";
  } else {
    labelText = [NSString stringWithFormat:@"%ld", (long)num];
  }
  UILabel *label = [PEUIUtils labelWithKey:labelText
                                      font:[UIFont boldSystemFontOfSize:fontSize]
                           backgroundColor:[UIColor clearColor]
                                 textColor:badgeTextColor
                       verticalTextPadding:0.0];
  UIView *badge = [PEUIUtils panelWithFixedWidth:label.frame.size.width + widthPadding fixedHeight:label.frame.size.height * heightFactor];
  [badge addRoundedCorners:UIRectCornerAllCorners
                 withRadii:CGSizeMake(20.0, 20.0)];
  badge.alpha = 0.8;
  badge.backgroundColor = color;
  [PEUIUtils placeView:label
            inMiddleOf:badge
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              hpadding:0.0];
  return badge;
}

+ (UIButton *)buttonWithLabel:(NSString *)labelText
                     badgeNum:(NSInteger)badgeNum
                   badgeColor:(UIColor *)badgeColor
               badgeTextColor:(UIColor *)badgeTextColor
            addDisclosureIcon:(BOOL)addDisclosureIcon
                      handler:(void(^)(void))handler
                    uitoolkit:(PEUIToolkit *)uitoolkit
               relativeToView:(UIView *)relativeToView {
  if (badgeNum == 0) {
    return nil;
  }
  UIButton *button = [uitoolkit systemButtonMaker](labelText, nil, nil);
  [[button layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:button ofWidth:1.0 relativeTo:relativeToView];
  if (addDisclosureIcon) {
    [PEUIUtils addDisclosureIndicatorToButton:button];
  }
  [button bk_addEventHandler:^(id sender) {
    handler();
  } forControlEvents:UIControlEventTouchUpInside];
  UIView *badge = [FPUIUtils badgeForNum:badgeNum color:badgeColor badgeTextColor:badgeTextColor];
  [PEUIUtils placeView:badge
            inMiddleOf:button
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              hpadding:15.0];
  return button;
}

@end
