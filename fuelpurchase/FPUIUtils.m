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
#import <PEFuelPurchase-Model/FPFuelStation.h>
#import <PEFuelPurchase-Model/FPFuelStationType.h>

NSInteger const FPContentPanelTopPadding = 20.0;

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

#pragma mark - Table Cell Stylers

+ (PETableCellContentViewStyler)fsTypeTableCellStylerWithUitoolkit:(PEUIToolkit *)uitoolkit {
  NSInteger brandValueLabelTag = 1;
  return ^(UITableViewCell *cell, UIView *tableCellContentView, FPFuelStationType *fsType) {
    UILabel *brandValueLabel = (UILabel *)[tableCellContentView viewWithTag:brandValueLabelTag];
    if (brandValueLabel) { [brandValueLabel removeFromSuperview]; }
    brandValueLabel = [PEUIUtils labelWithKey:fsType.name
                                         font:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                              backgroundColor:[UIColor clearColor]
                                    textColor:[UIColor grayColor]
                          verticalTextPadding:3.0];
    [brandValueLabel setTag:brandValueLabelTag];
    [PEUIUtils placeView:brandValueLabel inMiddleOf:tableCellContentView withAlignment:PEUIHorizontalAlignmentTypeRight hpadding:15.0];
    UIImage *iconImg = [UIImage imageNamed:fsType.iconImgName];
    if (iconImg) {
      cell.imageView.image = iconImg;
    } else {
      cell.imageView.image = nil;
    }
  };
}

+ (void)addDistanceInfoToFsCellContentView:(UIView *)contentView
                   withHorizontalAlignment:(PEUIHorizontalAlignmentType)horizontalAlignment
                       withVerticalPadding:(CGFloat)verticalPadding
                         horizontalPadding:(CGFloat)horizontalPadding
                           withFuelstation:(FPFuelStation *)fuelstation
                                 uitoolkit:(PEUIToolkit *)uitoolkit {
  NSInteger distanceTag = 10;
  NSInteger unknownReasonTag = 11;
  [[contentView viewWithTag:distanceTag] removeFromSuperview];
  [[contentView viewWithTag:unknownReasonTag] removeFromSuperview];
  LabelMaker cellSubtitleMaker = [uitoolkit tableCellSubtitleMaker];
  CLLocation *fuelStationLocation = [fuelstation location];
  UILabel *distance = nil;
  if (fuelStationLocation) {
    CLLocation *latestCurrentLocation = [APP latestLocation];
    if (latestCurrentLocation) {
      CLLocationDistance distanceVal = [latestCurrentLocation distanceFromLocation:fuelStationLocation];
      NSString *distanceUom = @"m";
      BOOL isNearby = NO;
      if (distanceVal < 150.0) {
        isNearby = YES;
      }
      if (distanceVal > 1000) {
        distanceUom = @"km";
        distanceVal = distanceVal / 1000.0;
      }
      distance = cellSubtitleMaker([NSString stringWithFormat:@"%.1f %@", distanceVal, distanceUom],
                                   (0.5 * contentView.frame.size.width) - horizontalPadding);
      [distance setTag:distanceTag];
      if (isNearby) {
        [distance setTextColor:[UIColor greenSeaColor]];
      }
      [PEUIUtils placeView:distance
                atBottomOf:contentView
             withAlignment:PEUIHorizontalAlignmentTypeRight
                  vpadding:verticalPadding
                  hpadding:horizontalPadding];
    }
  }
}

+ (PETableCellContentViewStyler)fsTableCellStylerWithUitoolkit:(PEUIToolkit *)uitoolkit
                                                    isLoggedIn:(BOOL)isLoggedIn {
  NSInteger titleTag = 89;
  NSInteger subtitleTag = 90;
  NSInteger warningIconTag = 91;
  NSInteger iconImgTag = 92;
  CGFloat vpaddingForTopifiedTitleToFitNeedFixIcon = 5.0; //8.0;
  CGFloat vpaddingForTopifiedTitleToFitSubtitle = 8.0; //11.0;
  void (^removeView)(NSInteger, UIView *) = ^(NSInteger tag, UIView *view) {
    [[view viewWithTag:tag] removeFromSuperview];
  };
  return ^(UITableViewCell *cell, UIView *contentView, FPFuelStation *fs) {
    removeView(titleTag, contentView);
    removeView(subtitleTag, contentView);
    removeView(warningIconTag, contentView);
    removeView(iconImgTag, contentView);
    NSString *subTitleMsg = nil;
    BOOL syncWarningNeedsFix = NO;
    BOOL syncWarningTemporary = NO;
    CGFloat vpaddingForTopification = vpaddingForTopifiedTitleToFitSubtitle;
    if ([fs editInProgress]) {
      subTitleMsg = @"editing";
    } else if (isLoggedIn) {
      if ([fs syncInProgress]) {
        subTitleMsg = @"synching";
      } else if (![fs globalIdentifier] || ([fs editCount] > 0)) {
        if ([fs syncErrMask] && ([fs syncErrMask].integerValue > 0)) {
          syncWarningNeedsFix = YES;
          subTitleMsg = @"needs fixing";
          vpaddingForTopification = vpaddingForTopifiedTitleToFitNeedFixIcon;
        } else {
          subTitleMsg = @"sync needed";
        }
      }
    }
    
    // place title label
    CGFloat availableWidth;
    UIImage *iconImg = [UIImage imageNamed:fs.type.iconImgName];
    UIImageView *imgView = [[UIImageView alloc] initWithImage:iconImg];
    [imgView setTag:iconImgTag];
    if (subTitleMsg) {
      [PEUIUtils placeView:imgView atTopOf:contentView withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpaddingForTopification hpadding:15.0];
    } else {
      [PEUIUtils placeView:imgView inMiddleOf:contentView withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:15.0];
    }
    CGRect imgViewFrame = imgView.frame;
    availableWidth = contentView.frame.size.width - (imgViewFrame.origin.x + imgViewFrame.size.width + 30.0);
    UILabel *nickNameLabel = (UILabel *)[contentView viewWithTag:titleTag];
    if (nickNameLabel) { [nickNameLabel removeFromSuperview]; }
    NSString *fsName = [PEUIUtils truncatedTextForText:fs.name
                                                  font:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                        availableWidth:availableWidth];
    nickNameLabel = [PEUIUtils labelWithKey:fsName
                                       font:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                            backgroundColor:[UIColor clearColor]
                                  textColor:[UIColor grayColor]
                        verticalTextPadding:3.0];
    [nickNameLabel setTag:titleTag];
    [PEUIUtils placeView:nickNameLabel
              inMiddleOf:contentView
           withAlignment:PEUIHorizontalAlignmentTypeRight
                hpadding:10.0];
    [FPUIUtils addDistanceInfoToFsCellContentView:contentView
                          withHorizontalAlignment:PEUIHorizontalAlignmentTypeRight
                              withVerticalPadding:0.0
                                horizontalPadding:10.0
                                  withFuelstation:fs
                                        uitoolkit:uitoolkit];
    
    // place subtitle label
    if (subTitleMsg) {
      UIColor *textColor = [UIColor grayColor];
      UILabel *subtitleLabel;
      if (syncWarningNeedsFix) {
        textColor = [UIColor sunflowerColor];
        UIImage *syncWarningIcon = [UIImage imageNamed:@"warning-icon"];
        UIImageView *syncWarningIconView = [[UIImageView alloc] initWithImage:syncWarningIcon];
        [syncWarningIconView setTag:warningIconTag];
        [PEUIUtils placeView:syncWarningIconView
                  atBottomOf:contentView
               withAlignment:PEUIHorizontalAlignmentTypeLeft
                    vpadding:4.0
                    hpadding:10.0];
        subtitleLabel = [uitoolkit tableCellSubtitleMaker](subTitleMsg,
                                                           (1.0 * contentView.frame.size.width) - (syncWarningIconView.frame.size.width + 2.0));
        [PEUIUtils placeView:subtitleLabel
                toTheRightOf:syncWarningIconView
                        onto:contentView
               withAlignment:PEUIVerticalAlignmentTypeMiddle
                    hpadding:2.0];
      } else {
        if (syncWarningTemporary) {
          textColor = [UIColor sunflowerColor];
        }
        subtitleLabel = [uitoolkit tableCellSubtitleMaker](subTitleMsg, (1.0 * contentView.frame.size.width) - 15.0);
        [PEUIUtils placeView:subtitleLabel
                       below:imgView
                        onto:contentView
               withAlignment:PEUIHorizontalAlignmentTypeLeft
                    vpadding:2.0
                    hpadding:0.0];
      }
      [subtitleLabel setTextColor:textColor];
      [subtitleLabel setTag:subtitleTag];
    }
  };
}

#pragma mark - Helpers

+ (UIView *)headerPanelWithText:(NSString *)headerText relativeToView:(UIView *)relativeToView {
  return [PEUIUtils leftPadView:[PEUIUtils labelWithKey:headerText
                                                   font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
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
