// Copyright (C) 2013 Paul Evans
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

#import <FlatUIKit/UIColor+FlatUI.h>
#import <PEObjc-Commons/PEUIUtils.h>
#import <PEObjc-Commons/UIImage+PEAdditions.h>
#import <PEObjc-Commons/UIView+PERoundify.h>
#import <PEObjc-Commons/PEUtils.h>
#import "UIColor+FPAdditions.h"
#import "FPHomeController.h"
#import "FPScreenToolkit.h"
#import "FPUtils.h"
#import "FPNames.h"
#import "JBLineChartFooterView.h"
#import "JBChartTooltipTipView.h"
#import "JBChartTooltipView.h"
#import "JBChartHeaderView.h"
#import "FPUtils.h"
#import "FPUIUtils.h"
#import <JBChartView/JBLineChartView.h>
#import <BlocksKit/UIControl+BlocksKit.h>

NSString * const FPHomeTextIfNilStat = @"---";

NSInteger const FPHomeDaysBetweenFillupsChartTag      = 1;
NSInteger const FPHomeDaysBetweenFillupsChartTitleTag = 2;
NSInteger const FPHomeDaysBetweenFillupsTableDataTag  = 3;

NSInteger const FPHomePriceOfGasChartTag              = 4;
NSInteger const FPHomePriceOfGasChartTitleTag         = 5;
NSInteger const FPHomePriceOfGasTableDataTag          = 6;

NSInteger const FPHomeSpentOnGasChartTag              = 7;
NSInteger const FPHomeSpentOnGasChartTitleTag         = 8;
NSInteger const FPHomeSpentOnGasTableDataTag          = 9;

NSInteger const FPHomeGasCostPerMileChartTag          = 10;
NSInteger const FPHomeGasCostPerMileChartTitleTag     = 11;
NSInteger const FPHomeGasCostPerMileTableDataTag      = 12;

typedef NS_ENUM(NSInteger, FPHomeState) {
  FPHomeStateNoVehicles,
  FPHomeStateNoLogs,
  FPHomeStateHasLogs
};

@implementation FPHomeController {
  FPCoordinatorDao *_coordDao;
  PEUIToolkit *_uitoolkit;
  FPUser *_user;
  FPStats *_stats;
  FPScreenToolkit *_screenToolkit;
  NSDateFormatter *_dateFormatter;
  NSNumberFormatter *_generalFormatter;
  NSNumberFormatter *_currencyFormatter;
  //UIScrollView *_scrollView;
  JBChartTooltipView *_tooltipView;
  JBChartTooltipTipView *_tooltipTipView;
  //UIButton *_allStatsBtn;
  FPHomeState _currentlyRenderedState;
  UIView *_currentContentPanel;
  dispatch_queue_t _serialQueue;
  
  JBLineChartView *_spentOnGasChart;
  NSMutableArray *_spentOnGasDataSet;
  
  JBLineChartView *_priceOfGasChart;
  NSMutableArray *_priceOfGasDataSet;
  
  JBLineChartView *_daysBetweenFillupsChart;
  NSMutableArray *_daysBetweenFillupsDataSet;
  
  JBLineChartView *_gasCostPerMileChart;
  NSMutableArray *_gasCostPerMileDataSet;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(FPCoordinatorDao *)coordDao
                          user:(FPUser *)user
                         stats:(FPStats *)stats
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(FPScreenToolkit *)screenToolkit {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _user = user;
    _stats = stats;
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"MMM-yyyy"];
    _currencyFormatter = [PEUtils currencyFormatter];
    _generalFormatter = [[NSNumberFormatter alloc] init];
    [_generalFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [_generalFormatter setMaximumFractionDigits:1];
    _spentOnGasDataSet = [NSMutableArray array];
    _priceOfGasDataSet = [NSMutableArray array];
    _daysBetweenFillupsDataSet = [NSMutableArray array];
    _gasCostPerMileDataSet = [NSMutableArray array];
    _serialQueue = dispatch_queue_create("com.jotyourself.gasjot.home.queue", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

#pragma mark - JBLineChartViewDelegate

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex {
  NSArray *dataPoint = nil;
  switch (lineChartView.tag) {
    case FPHomeDaysBetweenFillupsChartTag: {
      dataPoint = _daysBetweenFillupsDataSet[horizontalIndex];
      break;
    }
    case FPHomePriceOfGasChartTag: {
      dataPoint = _priceOfGasDataSet[horizontalIndex];
      break;
    }
    case FPHomeSpentOnGasChartTag: {
      dataPoint = _spentOnGasDataSet[horizontalIndex];
      break;
    }
    case FPHomeGasCostPerMileChartTag: {
      dataPoint = _gasCostPerMileDataSet[horizontalIndex];
      break;
    }    
  }
  if (dataPoint) {
    if ([dataPoint count] == 2) {
      if ([dataPoint[1] floatValue] >= 0.0) {
        return [dataPoint[1] floatValue];
      }
    }
  }
  return NAN;
}

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView widthForLineAtLineIndex:(NSUInteger)lineIndex {
  return 1.25;
}

- (UIColor *)lineChartView:(JBLineChartView *)lineChartView colorForLineAtLineIndex:(NSUInteger)lineIndex {
  return [UIColor fpAppBlue];
}

- (UIColor *)lineChartView:(JBLineChartView *)lineChartView selectionColorForLineAtLineIndex:(NSUInteger)lineIndex {
  return [UIColor fpAppBlue];
}

- (UIColor *)lineChartView:(JBLineChartView *)lineChartView verticalSelectionColorForLineAtLineIndex:(NSUInteger)lineIndex {
  return [UIColor lightGrayColor];
}

- (BOOL)lineChartView:(JBLineChartView *)lineChartView showsDotsForLineAtLineIndex:(NSUInteger)lineIndex {
  return YES;
}

- (UIColor *)lineChartView:(JBLineChartView *)lineChartView colorForDotAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex {
  return [UIColor fpAppBlue];
}

- (UIColor *)lineChartView:(JBLineChartView *)lineChartView selectionColorForDotAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex {
  return [UIColor blackColor];
}

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView dotRadiusForDotAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex {
  return 0.0;
}

- (BOOL)lineChartView:(JBLineChartView *)lineChartView smoothLineAtLineIndex:(NSUInteger)lineIndex {
  return YES;
}

- (void)lineChartView:(JBLineChartView *)lineChartView didSelectLineAtIndex:(NSUInteger)lineIndex horizontalIndex:(NSUInteger)horizontalIndex touchPoint:(CGPoint)touchPoint {
  switch (lineChartView.tag) {
    case FPHomeDaysBetweenFillupsChartTag: {
      NSArray *dataPoint = _daysBetweenFillupsDataSet[horizontalIndex];
      NSDecimalNumber *value = dataPoint[1];
      [FPUIUtils setTooltipVisible:YES
                       tooltipView:_tooltipView
                    tooltipTipView:_tooltipTipView
                          animated:YES
                      atTouchPoint:touchPoint
                         chartView:lineChartView
                    controllerView:self.view];
      [_tooltipView setAttributedText:[PEUIUtils attributedTextWithTemplate:@"%@"
                                                               textToAccent:[NSString stringWithFormat:@"%@: %@ days", [_dateFormatter stringFromDate:dataPoint[0]], [_generalFormatter stringFromNumber:value]]
                                                             accentTextFont:nil
                                                            accentTextColor:[UIColor whiteColor]]];
      break;
    }
    case FPHomePriceOfGasChartTag: {
      NSArray *dataPoint = _priceOfGasDataSet[horizontalIndex];
      NSDecimalNumber *value = dataPoint[1];
      [FPUIUtils setTooltipVisible:YES
                       tooltipView:_tooltipView
                    tooltipTipView:_tooltipTipView
                          animated:YES
                      atTouchPoint:touchPoint
                         chartView:lineChartView
                    controllerView:self.view];
      [_tooltipView setAttributedText:[PEUIUtils attributedTextWithTemplate:@"%@"
                                                               textToAccent:[NSString stringWithFormat:@"%@: %@", [_dateFormatter stringFromDate:dataPoint[0]], [_currencyFormatter stringFromNumber:value]]
                                                             accentTextFont:nil
                                                            accentTextColor:[UIColor whiteColor]]];
      break;
    }
    case FPHomeSpentOnGasChartTag: {
      NSArray *dataPoint = _spentOnGasDataSet[horizontalIndex];
      NSDecimalNumber *value = dataPoint[1];
      [FPUIUtils setTooltipVisible:YES
                       tooltipView:_tooltipView
                    tooltipTipView:_tooltipTipView
                          animated:YES
                      atTouchPoint:touchPoint
                         chartView:lineChartView
                    controllerView:self.view];
      [_tooltipView setAttributedText:[PEUIUtils attributedTextWithTemplate:@"%@"
                                                               textToAccent:[NSString stringWithFormat:@"%@: %@", [_dateFormatter stringFromDate:dataPoint[0]], [_currencyFormatter stringFromNumber:value]]
                                                             accentTextFont:nil
                                                            accentTextColor:[UIColor whiteColor]]];
      break;
    }
    case FPHomeGasCostPerMileChartTag: {
      NSArray *dataPoint = _gasCostPerMileDataSet[horizontalIndex];
      NSDecimalNumber *value = dataPoint[1];
      [FPUIUtils setTooltipVisible:YES
                       tooltipView:_tooltipView
                    tooltipTipView:_tooltipTipView
                          animated:YES
                      atTouchPoint:touchPoint
                         chartView:lineChartView
                    controllerView:self.view];
      [_tooltipView setAttributedText:[PEUIUtils attributedTextWithTemplate:@"%@"
                                                               textToAccent:[NSString stringWithFormat:@"%@: %@", [_dateFormatter stringFromDate:dataPoint[0]], [_currencyFormatter stringFromNumber:value]]
                                                             accentTextFont:nil
                                                            accentTextColor:[UIColor whiteColor]]];
      break;
    }
  }
}

- (void)didDeselectLineInLineChartView:(JBLineChartView *)lineChartView {
  [FPUIUtils setTooltipVisible:NO
                   tooltipView:_tooltipView
                tooltipTipView:_tooltipTipView
                      animated:YES
                     chartView:lineChartView
                controllerView:self.view];
}

#pragma mark - JBLineChartViewDataSource

- (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView {
  return 1;
}

- (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex {
  switch (lineChartView.tag) {
    case FPHomeDaysBetweenFillupsChartTag:
      return [_daysBetweenFillupsDataSet count];
    case FPHomePriceOfGasChartTag:
      return [_priceOfGasDataSet count];
    case FPHomeSpentOnGasChartTag:
      return [_spentOnGasDataSet count];
    case FPHomeGasCostPerMileChartTag:
      return [_gasCostPerMileDataSet count];
  }
  return 0; //[_dataset count];
}

#pragma mark - Helpers

- (UIButton *)makeAllStatsButton {
  UIButton *allStatsBtn = [PEUIUtils buttonWithKey:@"all stats"
                                              font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                   backgroundColor:[UIColor grayColor]
                                         textColor:[UIColor whiteColor]
                      disabledStateBackgroundColor:nil
                            disabledStateTextColor:nil
                                   verticalPadding:10.0
                                 horizontalPadding:50.0
                                      cornerRadius:3.0
                                            target:nil
                                            action:nil];
  [PEUIUtils addDisclosureIndicatorToButton:allStatsBtn];
  [allStatsBtn bk_addEventHandler:^(id sender) {
    [[self navigationController] pushViewController:[_screenToolkit newUserStatsLaunchScreenMakerWithParentController:self](_user)
                                           animated:YES];
  } forControlEvents:UIControlEventTouchUpInside];
  return allStatsBtn;
}

- (JBLineChartView *)makeLineChartWithTag:(NSInteger)tag {
  JBLineChartView *lineChartView = [[JBLineChartView alloc] init];
  [lineChartView setTag:tag];
  [lineChartView setDelegate:self];
  [lineChartView setDataSource:self];
  [PEUIUtils setFrameWidthOfView:lineChartView ofWidth:.975 relativeTo:self.view];
  [PEUIUtils setFrameHeight:115.0 ofView:lineChartView];
  JBLineChartFooterView *footerView = [[JBLineChartFooterView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  footerView.footerSeparatorColor = [UIColor darkGrayColor];
  [PEUIUtils setFrameWidthOfView:footerView ofWidth:1.0 relativeTo:self.view];
  [PEUIUtils setFrameHeight:25.0 ofView:footerView];
  [lineChartView setFooterView:footerView];
  footerView.leftLabel.textColor = [UIColor fpAppBlue];
  return lineChartView;
}

- (void)makeLineChartSectionWithTitle:(NSString *)title
                             chartTag:(NSInteger)chartTag
                        chartTitleTag:(NSInteger)chartTitleTag
                    addlLabelsViewBlk:(UIView *(^)(void))addlLabelsViewBlk
              moreButtonControllerBlk:(UIViewController *(^)(void))moreButtonControllerBlk
                            resultBlk:(void(^)(NSArray *))resultBlk {
  UIView *panel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:self.view];
  [panel setBackgroundColor:[UIColor whiteColor]];
  UILabel *chartHeader = [PEUIUtils labelWithKey:title
                                            font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                 backgroundColor:[UIColor clearColor]
                                       textColor:[UIColor darkGrayColor]
                             verticalTextPadding:3.0];
  [chartHeader setTextAlignment:NSTextAlignmentCenter];
  [chartHeader setTag:chartTitleTag];
  JBLineChartView *chart = [self makeLineChartWithTag:chartTag];
  UIButton *moreBtn = [PEUIUtils buttonWithKey:@"more"
                                          font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                               backgroundColor:[UIColor grayColor]
                                     textColor:[UIColor whiteColor]
                  disabledStateBackgroundColor:nil
                        disabledStateTextColor:nil
                               verticalPadding:10.0
                             horizontalPadding:55.0
                                  cornerRadius:3.0
                                        target:nil
                                        action:nil];
  [PEUIUtils addDisclosureIndicatorToButton:moreBtn];
  [moreBtn bk_addEventHandler:^(id sender) {
    [[self navigationController] pushViewController:moreButtonControllerBlk()
                                           animated:YES];
  } forControlEvents:UIControlEventTouchUpInside];
  [PEUIUtils placeView:chartHeader
               atTopOf:panel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:3.0
              hpadding:0.0];
  [PEUIUtils placeView:chart
                 below:chartHeader
                  onto:panel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:self.view
              vpadding:4.0
              hpadding:0.0];
  UIView *addlLabelsView = nil;
  if (addlLabelsViewBlk) {
    addlLabelsView = addlLabelsViewBlk();
    [PEUIUtils placeView:addlLabelsView
                   below:chart
                    onto:panel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:panel
                vpadding:0.0
                hpadding:5.0];
  }
  [PEUIUtils placeView:moreBtn
                 below:chart
                  onto:panel
         withAlignment:PEUIHorizontalAlignmentTypeRight
alignmentRelativeToView:chart
              vpadding:5.0
              hpadding:5.0];
  CGFloat moreBtnHeight = moreBtn.frame.size.height;
  CGFloat addlLabelsPanelHeight = 0.0;
  if (addlLabelsView != nil) {
    addlLabelsPanelHeight = addlLabelsView.frame.size.height;
  }
  CGFloat addlHeight = moreBtnHeight > addlLabelsPanelHeight ? (moreBtnHeight + 3.0) : addlLabelsPanelHeight;
  [PEUIUtils setFrameHeight:(chartHeader.frame.size.height +
                             3.0 +
                             chart.frame.size.height +
                             0.0 +
                             addlHeight +
                             5.0 +
                             7.5)
                     ofView:panel];
  resultBlk(@[panel, chart]);
}

- (UIView *)makeDataTableWithRows:(NSArray *)rows
                              tag:(NSInteger)tag
                         maxWidth:(CGFloat)maxWidth {
  UIView *tablePanel = [PEUIUtils tablePanelWithRowData:rows
                                         withCellHeight:15.0
                                      labelLeftHPadding:5.0
                                     valueRightHPadding:10.0
                                         labelTextStyle:UIFontTextStyleCaption1
                                         valueTextStyle:UIFontTextStyleCaption1
                                         labelTextColor:[UIColor blackColor]
                                         valueTextColor:[UIColor grayColor]
                         minPaddingBetweenLabelAndValue:1.0
                                      includeTopDivider:NO
                                   includeBottomDivider:NO
                                   includeInnerDividers:NO
                                innerDividerWidthFactor:0.0
                                         dividerPadding:0.0
                                rowPanelBackgroundColor:[UIColor whiteColor]
                                   panelBackgroundColor:[_uitoolkit colorForWindows]
                                           dividerColor:nil
                                   footerAttributedText:nil
                         footerFontForHeightCalculation:nil
                                  footerVerticalPadding:0.0
                                               maxWidth:maxWidth
                                         relativeToView:self.view];
  [tablePanel setTag:tag];
  return tablePanel;
}

- (UIView *)makeDaysBetweenFillupsDataTableWithValues:(NSArray *)values {
  UIView *panel = [PEUIUtils panelWithColumnOfViews:@[[self makeDataTableWithRows:@[@[@"Avg:", [self formattedValueForValue:values[0] formatter:^(NSNumber *val){return [_generalFormatter stringFromNumber:val];}]],
                                                                                    @[@"Max:", [self formattedValueForValue:values[1] formatter:^(NSNumber *val){return [_generalFormatter stringFromNumber:val];}]]]
                                                                              tag:0
                                                                         maxWidth:205],
                                                      [self makeDataTableWithRows:@[@[@"Days since last fill-up:", [self formattedValueForValue:values[2] formatter:^(NSNumber *val){return [_generalFormatter stringFromNumber:val];}]]]
                                                                              tag:0
                                                                         maxWidth:205]]
                        verticalPaddingBetweenViews:0.0
                                     viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
  [panel setTag:FPHomeDaysBetweenFillupsTableDataTag];
  return panel;
}

- (UIView *)makePricePerGallonDataTableWithValues:(NSArray *)values {
  return [self makeDataTableWithRows:@[@[@"Avg:", [self formattedValueForValue:values[0] formatter:^(NSNumber *val){return [_currencyFormatter stringFromNumber:val];}]],
                                       @[@"Min:", [self formattedValueForValue:values[1] formatter:^(NSNumber *val){return [_currencyFormatter stringFromNumber:val];}]],
                                       @[@"Max:", [self formattedValueForValue:values[2] formatter:^(NSNumber *val){return [_currencyFormatter stringFromNumber:val];}]]]
                                 tag:FPHomePriceOfGasTableDataTag
                            maxWidth:205];
}

- (UIView *)makeSpentOnGasDataTableWithValues:(NSArray *)values {
  UIView *panel = [PEUIUtils panelWithColumnOfViews:@[[self makeDataTableWithRows:@[@[@"Avg:", [self formattedValueForValue:values[0] formatter:^(NSNumber *val){return [_currencyFormatter stringFromNumber:val];}]],
                                                                                    @[@"Min:", [self formattedValueForValue:values[1] formatter:^(NSNumber *val){return [_currencyFormatter stringFromNumber:val];}]],
                                                                                    @[@"Max:", [self formattedValueForValue:values[2] formatter:^(NSNumber *val){return [_currencyFormatter stringFromNumber:val];}]]]
                                                                              tag:0
                                                                         maxWidth:205],
                                                      [self makeDataTableWithRows:@[@[@"Spent this month:", [self formattedValueForValue:values[3] formatter:^(NSNumber *val){return [_currencyFormatter stringFromNumber:val];}]],
                                                                                    @[@"Spent last month:", [self formattedValueForValue:values[4] formatter:^(NSNumber *val){return [_currencyFormatter stringFromNumber:val];}]]]
                                                                              tag:0
                                                                         maxWidth:205]]
                        verticalPaddingBetweenViews:0.0
                                     viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
  [panel setTag:FPHomeSpentOnGasTableDataTag];
  return panel;
}

- (UIView *)makeAvgGasCostPerMileDataTableWithValues:(NSArray *)values {
  return [self makeDataTableWithRows:@[@[@"Avg:", [self formattedValueForValue:values[0] formatter:^(NSNumber *val){return [_currencyFormatter stringFromNumber:val];}]]]
                                 tag:FPHomeGasCostPerMileTableDataTag
                            maxWidth:205];
}

- (NSNumber *)octaneOfLastVehicleInCtxGasLog {
  FPVehicle *vehicle = [_coordDao vehicleForMostRecentFuelPurchaseLogForUser:_user error:[FPUtils localFetchErrorHandlerMaker]()];
  FPFuelPurchaseLog *fplog = [_coordDao.localDao lastGasLogForVehicle:vehicle error:[FPUtils localFetchErrorHandlerMaker]()];
  if (fplog) {
    return fplog.octane;
  }
  return nil;
}

- (FPFuelPurchaseLog *)lastFplogOfLastVehicleInCtxGasLog {
  FPVehicle *vehicle = [_coordDao vehicleForMostRecentFuelPurchaseLogForUser:_user error:[FPUtils localFetchErrorHandlerMaker]()];
  return [_coordDao.localDao lastGasLogForVehicle:vehicle error:[FPUtils localFetchErrorHandlerMaker]()];
}

- (NSString *)formattedValueForValue:(id)value formatter:(NSString *(^)(id))formatter {
  if (![PEUtils isNil:value]) {
    return formatter(value);
  } else {
    return FPHomeTextIfNilStat;
  }
}

- (void)refreshViewWithTag:(NSInteger)tag
            valuesMakerBlk:(NSArray *(^)(void))valuesMakeBlk
              viewMakerBlk:(UIView *(^)(NSArray *))viewMakerBlk {
  dispatch_async(_serialQueue, ^(void) {
    NSArray *values = valuesMakeBlk();
    dispatch_async(dispatch_get_main_queue(), ^(void) {
      UIView *view = [self.view viewWithTag:tag];
      UIView *superView = [view superview];
      CGRect frame = view.frame;
      [view removeFromSuperview];
      view = viewMakerBlk(values);
      [PEUIUtils setFrameX:frame.origin.x ofView:view];
      [PEUIUtils setFrameY:frame.origin.y ofView:view];
      [superView addSubview:view];
    });
  });
}

- (void)refreshChart:(JBLineChartView *)chart
          chartTitle:(NSString *)chartTitle
             dataset:(NSMutableArray *)dataset
          datasetBlk:(NSArray *(^)(void))datasetBlk {
  dispatch_async(_serialQueue, ^(void) {
    [dataset removeAllObjects];
    [dataset addObjectsFromArray:datasetBlk()];
    dispatch_async(dispatch_get_main_queue(), ^(void) {
      JBLineChartFooterView *footerView = (JBLineChartFooterView *)chart.footerView;
      [footerView setSectionCount:dataset.count];
      [chart setFooterView:footerView];
      if (dataset.count > 0) {
        NSArray *dp = dataset[0];
        footerView.leftLabel.text = [_dateFormatter stringFromDate:dp[0]];
      } else {
        footerView.leftLabel.text = @"NOT ENOUGH DATA TO RENDER PLOT.";
        footerView.rightLabel.text = @"";
      }
      footerView.leftLabel.textColor = [UIColor fpAppBlue];
      if (dataset.count > 1) {
        NSArray *dp = dataset[dataset.count - 1];
        footerView.rightLabel.text = [_dateFormatter stringFromDate:dp[0]];
        footerView.rightLabel.textColor = [UIColor fpAppBlue];
      }
      if (chartTitle) {
        UILabel *chartHeader = [self.view viewWithTag:FPHomePriceOfGasChartTitleTag];
        [PEUIUtils setTextAndResize:chartTitle forLabel:chartHeader];
      }
      [chart reloadData];
    });
  });
}

- (NSString *)avgPriceChartTitleForFplog:(FPFuelPurchaseLog *)fplog {
  NSString *chartTitle;
  if (![PEUtils isNil:fplog.octane]) {
    chartTitle = [NSString stringWithFormat:@"AVG PRICE OF %@ OCTANE\n(all gas stations, all time)", fplog.octane];
  } else if (fplog.isDiesel) {
    chartTitle = @"AVG PRICE OF DIESEL\n(all gas stations, all time)";
  } else {
    chartTitle = @"AVG PRICE\n(all gas stations, all time)";
  }
  return chartTitle;
}

- (UIScrollView *)makeScrollView {
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
  [scrollView setDelaysContentTouches:NO];
  [scrollView setBounces:YES];
  [scrollView setBackgroundColor:[_uitoolkit colorForWindows]];
  __block CGFloat totalHeightOfViews = 60.0; // initial bump for padding
  UIButton *allStatsBtn = [self makeAllStatsButton];
  [PEUIUtils placeView:allStatsBtn
               atTopOf:scrollView
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:12.5
              hpadding:8.0];
  __block UIView *daysBetweenFillupPanel;
  __block UIView *pricePerGallonPanel;
  __block UIView *gasCostPerMilePanel;
  __block UIView *spentOnGasPanel;
  NSArray *dummyVals = @[[NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null]];
  [self makeLineChartSectionWithTitle:@"AVG DAYS BETWEEN FILL-UPS\n(all vehicles, all time)"
                             chartTag:FPHomeDaysBetweenFillupsChartTag
                        chartTitleTag:FPHomeDaysBetweenFillupsChartTitleTag
                    addlLabelsViewBlk:^{ return [self makeDaysBetweenFillupsDataTableWithValues:dummyVals];}
              moreButtonControllerBlk:^UIViewController *{ return [_screenToolkit newAvgDaysBetweenFillupsStatsScreenMaker](_user);}
                            resultBlk:^(NSArray *section) {
                              daysBetweenFillupPanel = section[0];
                              _daysBetweenFillupsChart = section[1];
                              totalHeightOfViews += allStatsBtn.frame.size.height + 4.0 +
                              daysBetweenFillupPanel.frame.size.height + 10.0;
                            }];
  //NSNumber *octane = [self octaneOfLastVehicleInCtxGasLog];
  FPFuelPurchaseLog *fplog = [self lastFplogOfLastVehicleInCtxGasLog];
  UIViewController *(^moreBtnCtrlBlk)(void);
  NSString *chartTitle = [self avgPriceChartTitleForFplog:fplog];
  if (![PEUtils isNil:fplog.octane]) {
    //chartTitle = [NSString stringWithFormat:@"AVG PRICE OF %@ OCTANE\n  (all gas stations, all time)", fplog.octane];
    moreBtnCtrlBlk = ^UIViewController *{ return [_screenToolkit newAvgPricePerGallonStatsScreenMakerWithOctane:fplog.octane](_user);};
  } else if (fplog.isDiesel) {
    //chartTitle = @"AVG PRICE OF DIESEL\n  (all gas stations, all time)";
    moreBtnCtrlBlk = ^UIViewController *{ return [_screenToolkit newAvgPricePerDieselGallonStatsScreenMaker](_user);};
  } else {
    //chartTitle = @"AVG PRICE\n  (all gas stations, all time)";
    moreBtnCtrlBlk = ^UIViewController *{ return [_screenToolkit newAvgPricePerGallonStatsScreenMaker](_user);};
  }
  [self makeLineChartSectionWithTitle:chartTitle
                             chartTag:FPHomePriceOfGasChartTag
                        chartTitleTag:FPHomePriceOfGasChartTitleTag
                    addlLabelsViewBlk:^UIView *(void) { return [self makePricePerGallonDataTableWithValues:dummyVals];}
              moreButtonControllerBlk:moreBtnCtrlBlk
                            resultBlk:^(NSArray *section) {
                              pricePerGallonPanel = section[0];
                              _priceOfGasChart = section[1];
                              totalHeightOfViews += pricePerGallonPanel.frame.size.height + 10.0;
                            }];
  [self makeLineChartSectionWithTitle:@"AVG GAS COST PER MILE\n(all vehicles, all time)"
                             chartTag:FPHomeGasCostPerMileChartTag
                        chartTitleTag:FPHomeGasCostPerMileChartTitleTag
                    addlLabelsViewBlk:^UIView *(void) { return [self makeAvgGasCostPerMileDataTableWithValues:dummyVals];}
              moreButtonControllerBlk:^UIViewController *{ return [_screenToolkit newAvgGasCostPerMileStatsScreenMaker](_user); }
                            resultBlk:^(NSArray *section) {
                              gasCostPerMilePanel = section[0];
                              _gasCostPerMileChart = section[1];
                              totalHeightOfViews += gasCostPerMilePanel.frame.size.height + 10.0;
                            }];
  [self makeLineChartSectionWithTitle:@"MONTHLY SPEND\n(all vehicles, all time)"
                             chartTag:FPHomeSpentOnGasChartTag
                        chartTitleTag:FPHomeSpentOnGasChartTitleTag
                    addlLabelsViewBlk:^UIView *(void) { return [self makeSpentOnGasDataTableWithValues:dummyVals];}
              moreButtonControllerBlk:^UIViewController *{ return [_screenToolkit newSpentOnGasStatsScreenMaker](_user); }
                            resultBlk:^(NSArray *section) {
                              spentOnGasPanel = section[0];
                              _spentOnGasChart = section[1];
                              totalHeightOfViews += spentOnGasPanel.frame.size.height + 10.0;
                            }];
  [PEUIUtils placeView:daysBetweenFillupPanel
                 below:allStatsBtn
                  onto:scrollView
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:self.view
              vpadding:10.0
              hpadding:0.0];
  [PEUIUtils placeView:pricePerGallonPanel
                 below:daysBetweenFillupPanel
                  onto:scrollView
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:self.view
              vpadding:10.0
              hpadding:0.0];
  [PEUIUtils placeView:gasCostPerMilePanel
                 below:pricePerGallonPanel
                  onto:scrollView
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:self.view
              vpadding:10.0
              hpadding:0.0];
  [PEUIUtils placeView:spentOnGasPanel
                 below:gasCostPerMilePanel
                  onto:scrollView
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:self.view
              vpadding:10.0
              hpadding:0.0];
  [scrollView setContentSize:CGSizeMake(scrollView.frame.size.width, 1.20 * totalHeightOfViews)];
  return scrollView;
}

- (UIView *)noLogsYetPanel {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:self.view];
  UILabel *msgLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:@"%@ Create Logs"
                                                                                 textToAccent:@"Next:"
                                                                               accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleTitle3] //[UIFont boldSystemFontOfSize:22.0]
                                                                              accentTextColor:[UIColor blackColor]]
                                                        font:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle3] //[UIFont systemFontOfSize:22.0]
                                    fontForHeightCalculation:[PEUIUtils boldFontForTextStyle:UIFontTextStyleTitle3] //[UIFont boldSystemFontOfSize:22.0]
                                             backgroundColor:[UIColor clearColor]
                                                   textColor:[UIColor fpAppBlue]
                                         verticalTextPadding:3.0
                                                  fitToWidth:(0.90 * self.view.frame.size.width)];
  [msgLabel setTextAlignment:NSTextAlignmentCenter];
  UILabel *msgLabel2 = [PEUIUtils labelWithKey:@"You have at least one vehicle saved.  You're now ready to start logging gas purchases and odometer info.\n\nOnce you have enough logs saved, this screen (your Home screen) will display a set of charts."
                                               font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline] //[UIFont systemFontOfSize:18.0]
                                    backgroundColor:[UIColor clearColor]
                                          textColor:[UIColor fpAppBlue]
                                verticalTextPadding:3.0
                                         fitToWidth:(0.90 * self.view.frame.size.width)];
  [msgLabel2 setTextAlignment:NSTextAlignmentCenter];
  UIButton *gasLogBtn = [PEUIUtils buttonWithKey:@"Create Gas Log"
                                            font:[PEUIUtils boldFontForTextStyle:UIFontTextStyleTitle3] //[UIFont boldSystemFontOfSize:20.0]
                                 backgroundColor:[UIColor peterRiverColor]
                                       textColor:[UIColor whiteColor]
                    disabledStateBackgroundColor:nil
                          disabledStateTextColor:nil
                                 verticalPadding:12.0
                               horizontalPadding:12.0
                                    cornerRadius:5.0
                                          target:nil
                                          action:nil];
  [PEUIUtils setFrameWidthOfView:gasLogBtn ofWidth:0.85 relativeTo:self.view];
  PEItemAddedBlk itemAddedBlk = ^(PEAddViewEditController *addViewEditCtrl, id record) {
    [[addViewEditCtrl navigationController] dismissViewControllerAnimated:YES completion:nil];
  };
  [gasLogBtn bk_addEventHandler:^(id sender) {
    UIViewController *addFplogController = [_screenToolkit newAddFuelPurchaseLogScreenMakerWithBlk:itemAddedBlk
                                                                            defaultSelectedVehicle:[_coordDao vehicleForMostRecentFuelPurchaseLogForUser:_user
                                                                                                                                                   error:[FPUtils localFetchErrorHandlerMaker]()]
                                                                        defaultSelectedFuelStation:[_coordDao defaultFuelStationForNewFuelPurchaseLogForUser:_user
                                                                                                                                             currentLocation:[APP latestLocation]
                                                                                                                                                       error:[FPUtils localFetchErrorHandlerMaker]()]
                                                                                listViewController:nil](_user);
    [[self navigationController] presentViewController:[PEUIUtils navigationControllerWithController:addFplogController
                                                                                 navigationBarHidden:NO]
                                              animated:YES
                                            completion:nil];
  } forControlEvents:UIControlEventTouchUpInside];
  UIButton *odometerLogBtn = [PEUIUtils buttonWithKey:@"Create Odometer Log"
                                                 font:[PEUIUtils boldFontForTextStyle:UIFontTextStyleTitle3] //[UIFont boldSystemFontOfSize:20.0]
                                      backgroundColor:[UIColor peterRiverColor]
                                            textColor:[UIColor whiteColor]
                         disabledStateBackgroundColor:nil
                               disabledStateTextColor:nil
                                      verticalPadding:12.0 //18.0
                                    horizontalPadding:12.0
                                         cornerRadius:5.0
                                               target:nil
                                               action:nil];
  [PEUIUtils setFrameWidthOfView:odometerLogBtn ofWidth:0.85 relativeTo:self.view];
  [odometerLogBtn bk_addEventHandler:^(id sender) {
    UIViewController *addEnvlogController = [_screenToolkit newAddEnvironmentLogScreenMakerWithBlk:itemAddedBlk
                                                                            defaultSelectedVehicle:[_coordDao defaultVehicleForNewEnvironmentLogForUser:_user error:[FPUtils localFetchErrorHandlerMaker]()]
                                                                                listViewController:nil](_user);
    [[self navigationController] presentViewController:[PEUIUtils navigationControllerWithController:addEnvlogController
                                                                                 navigationBarHidden:NO]
                                              animated:YES
                                            completion:nil];
  } forControlEvents:UIControlEventTouchUpInside];
  UIView *panel = [PEUIUtils panelWithColumnOfViews:@[msgLabel, msgLabel2, gasLogBtn, odometerLogBtn]
                        verticalPaddingBetweenViews:12.5
                                     viewsAlignment:PEUIHorizontalAlignmentTypeCenter];
  [PEUIUtils placeView:panel
            inMiddleOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              hpadding:0.0];
  [PEUIUtils adjustYOfView:panel withValue:(self.tabBarController.tabBar.frame.size.height / 2) * -1];
  return contentPanel;
}

- (UIView *)noVehiclesYetPanel {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:self.view];
  UILabel *introMsgLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:@"%@ Create a Vehicle"
                                                                                      textToAccent:@"Step 1:"
                                                                                    accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleTitle3] //[UIFont boldSystemFontOfSize:22.0]
                                                                                   accentTextColor:[UIColor blackColor]]
                                                        font:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle3] //[UIFont systemFontOfSize:22.0]
                                    fontForHeightCalculation:[PEUIUtils boldFontForTextStyle:UIFontTextStyleTitle3] //[UIFont boldSystemFontOfSize:22.0]
                                             backgroundColor:[UIColor clearColor]
                                                   textColor:[UIColor fpAppBlue]
                                         verticalTextPadding:3.0
                                                  fitToWidth:(0.90 * self.view.frame.size.width)];
  [introMsgLabel setTextAlignment:NSTextAlignmentCenter];
  UILabel *intro2MsgLabel = [PEUIUtils labelWithKey:@"Create a vehicle and you'll be able to create gas and odometer logs against it."
                                               font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline] //[UIFont systemFontOfSize:18.0]
                                    backgroundColor:[UIColor clearColor]
                                          textColor:[UIColor fpAppBlue]
                                verticalTextPadding:3.0
                                         fitToWidth:(0.90 * self.view.frame.size.width)];
  [intro2MsgLabel setTextAlignment:NSTextAlignmentCenter];
  UIButton *createVehicleBtn = [PEUIUtils buttonWithKey:@"Create Vehicle"
                                                   font:[PEUIUtils boldFontForTextStyle:UIFontTextStyleTitle3] //[UIFont boldSystemFontOfSize:22.0]
                                        backgroundColor:[UIColor peterRiverColor]
                                              textColor:[UIColor whiteColor]
                           disabledStateBackgroundColor:nil
                                 disabledStateTextColor:nil
                                        verticalPadding:22.5
                                      horizontalPadding:10.0
                                           cornerRadius:5.0
                                                 target:nil
                                                 action:nil];
  [PEUIUtils setFrameWidthOfView:createVehicleBtn ofWidth:0.85 relativeTo:self.view];
  [createVehicleBtn bk_addEventHandler:^(id sender) {
    PEItemAddedBlk itemAddedBlk = ^(PEAddViewEditController *addViewEditCtrl, id record) {
      [[addViewEditCtrl navigationController] dismissViewControllerAnimated:YES completion:nil];
    };
    [[self navigationController] presentViewController:[PEUIUtils navigationControllerWithController:[_screenToolkit newAddVehicleScreenMakerWithDelegate:itemAddedBlk listViewController:nil](_user)
                                                                                 navigationBarHidden:NO]
                                              animated:YES completion:nil];
  } forControlEvents:UIControlEventTouchUpInside];
  UIView *panel = [PEUIUtils panelWithColumnOfViews:@[introMsgLabel, intro2MsgLabel, createVehicleBtn]
                        verticalPaddingBetweenViews:15.0 //17.5
                                     viewsAlignment:PEUIHorizontalAlignmentTypeCenter];
  CGFloat vpadding = self.view.frame.size.height * .075;
  
  [PEUIUtils placeView:panel atTopOf:contentPanel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:vpadding hpadding:0.0];
  UIView * (^createAndPlaceLoginMsgPanel)(CGFloat) = ^ UIView * (CGFloat fitToWidthFactor) {
    UILabel *loginMsgLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:@"Tap the %@ tab to access your Gas Jot account." //@"If you already have a Gas Jot account and want to log in, tap the %@ tab."
                                                                                        textToAccent:@"Account"
                                                                                      accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleCaption1] //[UIFont boldSystemFontOfSize:16.0]
                                                                                     accentTextColor:[UIColor darkTextColor]]
                                                          font:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1] //[UIFont systemFontOfSize:16.0]
                                      fontForHeightCalculation:[PEUIUtils boldFontForTextStyle:UIFontTextStyleCaption1] //[UIFont boldSystemFontOfSize:16.0]
                                               backgroundColor:[UIColor clearColor]
                                                     textColor:[UIColor fpAppBlue]
                                           verticalTextPadding:3.0
                                                    fitToWidth:(fitToWidthFactor * self.view.frame.size.width)];
    UIView *loginMsgPanel = [PEUIUtils panelWithWidthOf:fitToWidthFactor andHeightOf:0.0 relativeToView:self.view];
    [PEUIUtils setFrameHeight:loginMsgLabel.frame.size.height + 10 ofView:loginMsgPanel];
    [loginMsgPanel setBackgroundColor:[UIColor cloudsColor]];
    [[loginMsgPanel layer] setCornerRadius:5.0];
    [PEUIUtils placeView:loginMsgLabel inMiddleOf:loginMsgPanel withAlignment:PEUIHorizontalAlignmentTypeCenter hpadding:0.0];
    [PEUIUtils placeView:loginMsgPanel atBottomOf:contentPanel withAlignment:PEUIHorizontalAlignmentTypeRight vpadding:175.0 hpadding:12.0];
    return loginMsgPanel;
  };
  UIView *loginMsgPanel = createAndPlaceLoginMsgPanel(0.70);
  if (loginMsgPanel.frame.origin.y <= (panel.frame.origin.y + panel.frame.size.height)) {
    [loginMsgPanel removeFromSuperview];
    loginMsgPanel = createAndPlaceLoginMsgPanel(0.85);
  }
  UIImageView *loginArrowImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow-1"]];
  [PEUIUtils placeView:loginArrowImgView below:loginMsgPanel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeRight vpadding:2.0 hpadding:15.0];
  UILabel *jotBtnMsgLabel = [PEUIUtils labelWithKey:@"You can create any type of record from the Jot button at any time."
                                               font:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1] //[UIFont systemFontOfSize:16.0]
                                    backgroundColor:[UIColor clearColor]
                                          textColor:[UIColor fpAppBlue]
                                verticalTextPadding:3.0
                                         fitToWidth:(0.70 * self.view.frame.size.width)];
  UIView *jotBtnMsgPanel = [PEUIUtils panelWithWidthOf:0.75 andHeightOf:0.0 relativeToView:self.view];
  [PEUIUtils setFrameHeight:jotBtnMsgLabel.frame.size.height + 10 ofView:jotBtnMsgPanel];
  [jotBtnMsgPanel setBackgroundColor:[UIColor cloudsColor]];
  [[jotBtnMsgPanel layer] setCornerRadius:5.0];
  [PEUIUtils placeView:jotBtnMsgLabel inMiddleOf:jotBtnMsgPanel withAlignment:PEUIHorizontalAlignmentTypeCenter hpadding:0.0];
  [PEUIUtils placeView:jotBtnMsgPanel atBottomOf:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:85.0 hpadding:10.0];
  UIImageView *jotBtnArrowImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow-2"]];
  [PEUIUtils placeView:jotBtnArrowImgView below:jotBtnMsgPanel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeRight vpadding:2.0 hpadding:90.0];
  return contentPanel;
}

- (FPHomeState)currentState {
  NSArray *vehicles = [_coordDao vehiclesForUser:_user error:[FPUtils localFetchErrorHandlerMaker]()];
  if (vehicles.count > 0) {
    FPFuelPurchaseLog *fplog = [_coordDao.localDao firstGasLogForUser:_user error:[FPUtils localFetchErrorHandlerMaker]()];
    if (fplog) {
      return FPHomeStateHasLogs;
    } else {
      FPEnvironmentLog *envlog = [_coordDao.localDao firstOdometerLogForUser:_user error:[FPUtils localFetchErrorHandlerMaker]()];
      if (envlog) {
        return FPHomeStateHasLogs;
      } else {
        return FPHomeStateNoLogs;
      }
    }
  } else {
    return FPHomeStateNoVehicles;
  }
}

- (void)reloadChartsAndTables {
  PEOrNil orNil = [PEUtils orNilMaker];
  //refresh the 'days between fillups' views
  [self refreshViewWithTag:FPHomeDaysBetweenFillupsTableDataTag
            valuesMakerBlk:^{
              return @[orNil([_stats overallAvgDaysBetweenFillupsForUser:_user]),
                       orNil([_stats overallMaxDaysBetweenFillupsForUser:_user]),
                       orNil([_stats daysSinceLastGasLogForUser:_user])];
            }
              viewMakerBlk:^(NSArray *values) { return [self makeDaysBetweenFillupsDataTableWithValues:values]; }];
  
  [self refreshChart:_daysBetweenFillupsChart
          chartTitle:nil
             dataset:_daysBetweenFillupsDataSet
          datasetBlk:^NSArray *{
            return [_stats overallAvgDaysBetweenFillupsDataSetForUser:_user];
          }];
  
  //refresh the 'price per gallon' views
  FPFuelPurchaseLog *fplog = [self lastFplogOfLastVehicleInCtxGasLog];
  NSArray *(^valuesMakerBlk)(void);
  NSArray *(^datasetBlk)(void);
  if (![PEUtils isNil:fplog.octane]) {
    valuesMakerBlk = ^ NSArray * {
      return @[orNil([_stats overallAvgPricePerGallonForUser:_user octane:fplog.octane]),
               orNil([_stats overallMinPricePerGallonForUser:_user octane:fplog.octane]),
               orNil([_stats overallMaxPricePerGallonForUser:_user octane:fplog.octane])];
    };
    datasetBlk = ^NSArray *{
      return [_stats overallAvgPricePerGallonDataSetForUser:_user octane:fplog.octane];
    };
  } else if (fplog.isDiesel) {
    valuesMakerBlk = ^ NSArray * {
      return @[orNil([_stats overallAvgPricePerDieselGallonForUser:_user]),
               orNil([_stats overallMinPricePerDieselGallonForUser:_user]),
               orNil([_stats overallMaxPricePerDieselGallonForUser:_user])];
    };
    datasetBlk = ^NSArray *{
      return [_stats overallAvgPricePerDieselGallonDataSetForUser:_user];
    };
  } else {
    valuesMakerBlk = ^ NSArray * {
      return @[orNil([_stats overallAvgPricePerGallonForUser:_user]),
               orNil([_stats overallMinPricePerGallonForUser:_user]),
               orNil([_stats overallMaxPricePerGallonForUser:_user])];
    };
    datasetBlk = ^NSArray *{
      return [_stats overallAvgPricePerGallonDataSetForUser:_user];
    };
  }
  [self refreshViewWithTag:FPHomePriceOfGasTableDataTag
            valuesMakerBlk:valuesMakerBlk
              viewMakerBlk:^(NSArray *values) { return [self makePricePerGallonDataTableWithValues:values]; }];
  [self refreshChart:_priceOfGasChart
          chartTitle:[self avgPriceChartTitleForFplog:fplog]
             dataset:_priceOfGasDataSet
          datasetBlk:datasetBlk];
  
  //refresh the 'spent on gas' views
  [self refreshViewWithTag:FPHomeSpentOnGasTableDataTag
            valuesMakerBlk:^{
              return @[orNil([_stats overallAvgSpentOnGasForUser:_user]),
                       orNil([_stats overallMinSpentOnGasForUser:_user]),
                       orNil([_stats overallMaxSpentOnGasForUser:_user]),
                       orNil([_stats thisMonthSpentOnGasForUser:_user]),
                       orNil([_stats lastMonthSpentOnGasForUser:_user])];
            }
              viewMakerBlk:^(NSArray *values){ return [self makeSpentOnGasDataTableWithValues:values]; }];
  [self refreshChart:_spentOnGasChart
          chartTitle:nil
             dataset:_spentOnGasDataSet
          datasetBlk:^NSArray *{
            return [_stats overallSpentOnGasDataSetForUser:_user];
          }];
  
  //refresh the 'gas cost per mile' views
  [self refreshViewWithTag:FPHomeGasCostPerMileTableDataTag
            valuesMakerBlk:^{
              return @[orNil([_stats overallAvgGasCostPerMileForUser:_user])];
            }
              viewMakerBlk:^(NSArray *values){ return [self makeAvgGasCostPerMileDataTableWithValues:values]; }];
  [self refreshChart:_gasCostPerMileChart
          chartTitle:nil
             dataset:_gasCostPerMileDataSet
          datasetBlk:^NSArray *{
            return [_stats overallAvgGasCostPerMileDataSetForUser:_user];
          }];
}

#pragma mark - Dynamic Type Support

- (void)changeTextSize:(NSNotification *)notification {
  [self viewDidAppear:YES];
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeTextSize:)
                                               name:UIContentSizeCategoryDidChangeNotification
                                             object:nil];
  [[self view] setBackgroundColor:[UIColor whiteColor]];
  [[self navigationItem] setTitle:@"Gas Jot Home"];
  [self setAutomaticallyAdjustsScrollViewInsets:NO];
  
  _tooltipView = [[JBChartTooltipView alloc] init];
  _tooltipTipView = [[JBChartTooltipTipView alloc] init];
  [_tooltipView setBackgroundColor:[UIColor blackColor]];
  
  CGFloat vpadding = 0.0;
  FPHomeState state = [self currentState];
  switch (state) {
    case FPHomeStateNoVehicles:
      [[self.navigationController navigationBar] setHidden:YES];
      _currentContentPanel = [self noVehiclesYetPanel];
      break;
    case FPHomeStateNoLogs:
      [[self.navigationController navigationBar] setHidden:YES];
      _currentContentPanel = [self noLogsYetPanel];
      break;
    case FPHomeStateHasLogs:
      _currentContentPanel = [self makeScrollView];
      vpadding = 60.0;
      break;
  }
  [PEUIUtils placeView:_currentContentPanel atTopOf:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpadding hpadding:0.0];
  _currentlyRenderedState = state;
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  FPHomeState state = [self currentState];
  void (^doRedraw)(UIView *(^)(void), CGFloat) = ^(UIView *(^viewMaker)(void), CGFloat vpadding) {
    [_currentContentPanel removeFromSuperview];
    _currentContentPanel = viewMaker();
    [PEUIUtils placeView:_currentContentPanel atTopOf:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpadding hpadding:0.0];
    _currentlyRenderedState = state;
  };
  switch (state) {
    case FPHomeStateNoVehicles: {
      [[self.navigationController navigationBar] setHidden:YES];
      //if (_currentlyRenderedState != FPHomeStateNoVehicles) {
        doRedraw(^{ return [self noVehiclesYetPanel]; }, 0.0);
      //}
      break;
    }
    case FPHomeStateNoLogs: {
      [[self.navigationController navigationBar] setHidden:YES];
      //if (_currentlyRenderedState != FPHomeStateNoLogs) {
        doRedraw(^{ return [self noLogsYetPanel]; }, 0.0);
      //}
      break;
    }
    case FPHomeStateHasLogs: {
      [[self.navigationController navigationBar] setHidden:NO];
      //if (_currentlyRenderedState != FPHomeStateHasLogs) {
        doRedraw(^{ return [self makeScrollView]; }, 60.0);
      //}
      [self reloadChartsAndTables];
      break;
    }
  }
}

@end
