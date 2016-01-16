//
//  FPUIUtils.h
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 9/14/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

@import CoreLocation;
@import Foundation;

#import <JBChartView/JBLineChartView.h>
#import "PEUIDefs.h"
#import "JBChartTooltipTipView.h"
#import "JBChartTooltipView.h"
#import <PEObjc-Commons/PEUIUtils.h>
#import <FormatterKit/TTTLocationFormatter.h>

typedef void (^FPEnableUserInteractionBlk)(BOOL);

FOUNDATION_EXPORT NSInteger const FPContentPanelTopPadding;

@interface FPUIUtils : NSObject

#pragma mark - Location Helpers

+ (void)actionWithCurrentLocationBlk:(void(^)(CLLocation *))currentLocationBlk
            locationNeededReasonText:(NSString *)locationNeededReasonText
                    parentController:(UIViewController *)parentController
                          parentView:(UIView *)parentView;

#pragma mark - Chart Helpers

+ (void)setTooltipVisible:(BOOL)tooltipVisible
              tooltipView:(JBChartTooltipView *)tooltipView
           tooltipTipView:(JBChartTooltipTipView *)tooltipTipView
                 animated:(BOOL)animated
             atTouchPoint:(CGPoint)touchPoint
                chartView:(JBChartView *)chartView
           controllerView:(UIView *)controllerView;

+ (void)setTooltipVisible:(BOOL)tooltipVisible
              tooltipView:(JBChartTooltipView *)tooltipView
           tooltipTipView:(JBChartTooltipTipView *)tooltipTipView
                 animated:(BOOL)animated
                chartView:(JBChartView *)chartView
           controllerView:(UIView *)controllerView;

#pragma mark - Table Cell Stylers

+ (PETableCellContentViewStyler)fsTypeTableCellStylerWithUitoolkit:(PEUIToolkit *)uitoolkit;

+ (void)addDistanceInfoToFsCellContentView:(UIView *)contentView
                   withHorizontalAlignment:(PEUIHorizontalAlignmentType)horizontalAlignment
                       withVerticalPadding:(CGFloat)verticalPadding
                         horizontalPadding:(CGFloat)horizontalPadding
                           withFuelstation:(FPFuelStation *)fuelstation
                                 uitoolkit:(PEUIToolkit *)uitoolkit
                         locationFormatter:(TTTLocationFormatter *)locationFormatter;

+ (PETableCellContentViewStyler)fsTableCellStylerWithUitoolkit:(PEUIToolkit *)uitoolkit
                                                    isLoggedIn:(BOOL)isLoggedIn
                                             locationFormatter:(TTTLocationFormatter *)locationFormatter;

#pragma mark - Helpers

+ (UIView *)headerPanelWithText:(NSString *)headerText relativeToView:(UIView *)relativeToView;

+ (FPEnableUserInteractionBlk)makeUserEnabledBlockForController:(UIViewController *)controller;

@end
