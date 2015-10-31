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

#pragma mark - Chart Helpers

+ (void)setTooltipVisible:(BOOL)tooltipVisible
              tooltipView:(JBChartTooltipView *)tooltipView
           tooltipTipView:(JBChartTooltipTipView *)tooltipTipView
                 animated:(BOOL)animated
             atTouchPoint:(CGPoint)touchPoint
                chartView:(JBChartView *)chartView
           controllerView:(UIView *)controllerView {
  UIView *chartViewPanel = [chartView superview];
  tooltipView.alpha = 0.0;
  [chartViewPanel addSubview:tooltipView];
  [chartViewPanel bringSubviewToFront:tooltipView];
  tooltipTipView.alpha = 0.0;
  [chartViewPanel addSubview:tooltipTipView];
  [chartViewPanel bringSubviewToFront:tooltipTipView];
  dispatch_block_t adjustTooltipPosition = ^{
    CGPoint originalTouchPoint = [controllerView convertPoint:touchPoint fromView:chartView];
    CGPoint convertedTouchPoint = originalTouchPoint; // modified
    CGFloat minChartX = (chartView.frame.origin.x + ceil(tooltipView.frame.size.width * 0.5));
    if (convertedTouchPoint.x < minChartX) {
      convertedTouchPoint.x = minChartX;
    }
    CGFloat maxChartX = (chartView.frame.origin.x + chartView.frame.size.width - ceil(tooltipView.frame.size.width * 0.5));
    if (convertedTouchPoint.x > maxChartX) {
      convertedTouchPoint.x = maxChartX;
    }
    tooltipView.frame = CGRectMake(convertedTouchPoint.x - ceil(tooltipView.frame.size.width * 0.5),
                                    chartView.frame.origin.y - tooltipView.frame.size.height,
                                    tooltipView.frame.size.width,
                                    tooltipView.frame.size.height);
    CGFloat minTipX = (chartView.frame.origin.x + tooltipTipView.frame.size.width);
    if (originalTouchPoint.x < minTipX) {
      originalTouchPoint.x = minTipX;
    }
    CGFloat maxTipX = (chartView.frame.origin.x + chartView.frame.size.width - tooltipTipView.frame.size.width);
    if (originalTouchPoint.x > maxTipX) {
      originalTouchPoint.x = maxTipX;
    }
    tooltipTipView.frame = CGRectMake(originalTouchPoint.x - ceil(tooltipTipView.frame.size.width * 0.5),
                                      CGRectGetMaxY(tooltipView.frame),
                                      tooltipTipView.frame.size.width,
                                      tooltipTipView.frame.size.height);
  };
  dispatch_block_t adjustTooltipVisibility = ^{
    tooltipView.alpha = tooltipVisible ? 1.0 : 0.0;
    tooltipTipView.alpha = tooltipVisible ? 1.0 : 0.0;
  };
  
  if (tooltipVisible) {
    adjustTooltipPosition();
  }
  
  if (animated) {
    [UIView animateWithDuration:0.25f animations:^{
      adjustTooltipVisibility();
    } completion:^(BOOL finished) {
      if (!tooltipVisible) {
        adjustTooltipPosition();
      }
    }];
  } else {
    adjustTooltipVisibility();
  }
}

+ (void)setTooltipVisible:(BOOL)tooltipVisible
              tooltipView:(JBChartTooltipView *)tooltipView
           tooltipTipView:(JBChartTooltipTipView *)tooltipTipView
                 animated:(BOOL)animated
                chartView:(JBChartView *)chartView
           controllerView:(UIView *)controllerView {
  [FPUIUtils setTooltipVisible:tooltipVisible
                   tooltipView:tooltipView
                tooltipTipView:tooltipTipView
                      animated:animated
                  atTouchPoint:CGPointZero
                     chartView:chartView
                controllerView:controllerView];
}

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
