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
  UIView *badge = [PEUIUtils panelWithFixedWidth:label.frame.size.width + widthPadding
                                     fixedHeight:label.frame.size.height * heightFactor];
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

+ (NSString *)labelTextForRecordCount:(NSInteger)recordCount {
  NSString *trailerForLabel = @"";
  if (recordCount > 1 || recordCount == 0) {
    trailerForLabel = @"s";
  }
  return [NSString stringWithFormat:@"%ld record%@", (long)recordCount, trailerForLabel];
}

+ (UILabel *)labelForRecordCount:(NSInteger)recordCount {
  return [PEUIUtils labelWithKey:[FPUIUtils labelTextForRecordCount:recordCount]
                            font:[UIFont systemFontOfSize:10]
                 backgroundColor:[UIColor clearColor]
                       textColor:[UIColor darkGrayColor]
             verticalTextPadding:0.0];
}

+ (void)placeRecordCountLabel:(UILabel *)recordCountLabel
                   ontoButton:(UIButton *)button {
  [PEUIUtils placeView:recordCountLabel
            atBottomOf:button
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:5.0
              hpadding:6.0];
}

+ (void)refreshRecordCountLabelOnButton:(UIButton *)button
                    recordCountLabelTag:(NSInteger)recordCountLabelTag
                            recordCount:(NSInteger)recordCount {
  UILabel *recordCountLabel = (UILabel *)[button viewWithTag:recordCountLabelTag];
  [PEUIUtils setTextAndResize:[FPUIUtils labelTextForRecordCount:recordCount] forLabel:recordCountLabel];
}

+ (UIButton *)buttonWithLabel:(NSString *)labelText
                 tagForButton:(NSNumber *)tagForButton
                  recordCount:(NSInteger)recordCount
       tagForRecordCountLabel:(NSNumber *)tagForRecordCountLabel
            addDisclosureIcon:(BOOL)addDisclosureIcon
                      handler:(void(^)(void))handler
                    uitoolkit:(PEUIToolkit *)uitoolkit
               relativeToView:(UIView *)relativeToView {
  UIButton *button = [uitoolkit systemButtonMaker](labelText, nil, nil);
  if (tagForButton) {
    [button setTag:[tagForButton integerValue]];
  }
  [[button layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:button ofWidth:1.0 relativeTo:relativeToView];
  if (addDisclosureIcon) {
    [PEUIUtils addDisclosureIndicatorToButton:button];
  }
  [button bk_addEventHandler:^(id sender) {
    handler();
  } forControlEvents:UIControlEventTouchUpInside];
  UILabel *recordCountLabel = [FPUIUtils labelForRecordCount:recordCount];
  if (tagForRecordCountLabel) {
    [recordCountLabel setTag:[tagForRecordCountLabel integerValue]];
  }
  [FPUIUtils placeRecordCountLabel:recordCountLabel ontoButton:button];
  return button;
}

+ (UIButton *)buttonWithLabel:(NSString *)labelText
                     badgeNum:(NSInteger)badgeNum
                   badgeColor:(UIColor *)badgeColor
               badgeTextColor:(UIColor *)badgeTextColor
            addDisclosureIcon:(BOOL)addDisclosureIcon
                      handler:(void(^)(void))handler
                    uitoolkit:(PEUIToolkit *)uitoolkit
               relativeToView:(UIView *)relativeToView {
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
