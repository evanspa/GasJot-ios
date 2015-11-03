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

NSInteger const FPHomeDaysBetweenFillupsChartTag     = 1;
NSInteger const FPHomeDaysBetweenFillupsTableDataTag = 2;

NSInteger const FPHomePriceOfGasChartTag             = 3;
NSInteger const FPHomePriceOfGasTableDataTag         = 4;

NSInteger const FPHomeSpentOnGasChartTag             = 5;
NSInteger const FPHomeSpentOnGasTableDataTag         = 6;

@implementation FPHomeController {
  FPCoordinatorDao *_coordDao;
  PEUIToolkit *_uitoolkit;
  FPUser *_user;
  FPStats *_stats;
  FPScreenToolkit *_screenToolkit;
  NSDateFormatter *_dateFormatter;
  NSNumberFormatter *_generalFormatter;
  NSNumberFormatter *_currencyFormatter;
  FPVehicle *_vehicleInCtx;
  UIScrollView *_scrollView;
  JBChartTooltipView *_tooltipView;
  JBChartTooltipTipView *_tooltipTipView;
  UILabel *_vehicleLabel;
  UIButton *_vehicleAllStatsBtn;
  
  JBLineChartView *_spentOnGasChart;
  NSArray *_spentOnGasDataSet;
  
  JBLineChartView *_priceOfGasChart;
  NSArray *_priceOfGasDataSet;
  
  JBLineChartView *_daysBetweenFillupsChart;
  NSArray *_daysBetweenFillupsDataSet;
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
  }
  return self;
}

#pragma mark - JBLineChartViewDelegate

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex {
  switch (lineChartView.tag) {
    case FPHomeDaysBetweenFillupsChartTag: {
      NSArray *dataPoint = _daysBetweenFillupsDataSet[horizontalIndex];
      return [dataPoint[1] floatValue];
    }
    case FPHomePriceOfGasChartTag: {
      NSArray *dataPoint = _priceOfGasDataSet[horizontalIndex];
      return [dataPoint[1] floatValue];
    }
    case FPHomeSpentOnGasChartTag: {
      NSArray *dataPoint = _spentOnGasDataSet[horizontalIndex];
      return [dataPoint[1] floatValue];
    }
  }
  return 0.0;
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
  return 1.5;
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
  }
  return 0; //[_dataset count];
}

#pragma mark - Helpers

- (void)refreshFooterForChart:(JBLineChartView *)chart dataset:(NSArray *)dataset {
  JBLineChartFooterView *footerView = (JBLineChartFooterView *)chart.footerView;
  [footerView setSectionCount:dataset.count];
  [chart setFooterView:footerView];
  if (dataset.count > 0) {
    NSArray *dp = dataset[0];
    footerView.leftLabel.text = [_dateFormatter stringFromDate:dp[0]];
  } else {
    footerView.leftLabel.text = @"NO (OR NOT ENOUGH) DATA.";
    footerView.rightLabel.text = @"";
  }
  footerView.leftLabel.textColor = [UIColor fpAppBlue];
  if (dataset.count > 1) {
    NSArray *dp = dataset[dataset.count - 1];
    footerView.rightLabel.text = [_dateFormatter stringFromDate:dp[0]];
    footerView.rightLabel.textColor = [UIColor fpAppBlue];
  }
}

- (UIButton *)makeAllStatsButtonForVehicle:(FPVehicle *)vehicle {
  UIButton *allStatsBtn = [PEUIUtils buttonWithKey:@"all vehicle stats"
                                              font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                   backgroundColor:[UIColor grayColor]
                                         textColor:[UIColor whiteColor]
                      disabledStateBackgroundColor:nil
                            disabledStateTextColor:nil
                                   verticalPadding:7.0
                                 horizontalPadding:50.0
                                      cornerRadius:3.0
                                            target:nil
                                            action:nil];
  [PEUIUtils addDisclosureIndicatorToButton:allStatsBtn];
  [allStatsBtn bk_addEventHandler:^(id sender) {
    [[self navigationController] pushViewController:[_screenToolkit newVehicleStatsLaunchScreenMakerWithVehicle:_vehicleInCtx](_user)
                                           animated:YES];
  } forControlEvents:UIControlEventTouchUpInside];
  return allStatsBtn;
}

- (UILabel *)makeLabelForVehicle:(FPVehicle *)vehicle {
  NSAttributedString *vehicleHeaderText = [PEUIUtils attributedTextWithTemplate:@"VEHICLE: %@"
                                                                   textToAccent:[FPUtils truncatedText:vehicle.name maxLength:27]
                                                                 accentTextFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]
                                                                accentTextColor:[UIColor fpAppBlue]];
  return [PEUIUtils labelWithAttributeText:vehicleHeaderText
                                      font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                  fontForHeightCalculation:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]
                           backgroundColor:[UIColor clearColor]
                                 textColor:[UIColor darkGrayColor]
                       verticalTextPadding:3.0
                                fitToWidth:self.view.frame.size.width - 15.0];
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

- (NSArray *)makeLineChartSectionWithTitle:(NSString *)title
                                  chartTag:(NSInteger)chartTag
                         addlLabelsViewBlk:(UIView *(^)(void))addlLabelsViewBlk
                   moreButtonControllerBlk:(UIViewController *(^)(void))moreButtonControllerBlk {
  UIView *panel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:self.view];
  [panel setBackgroundColor:[UIColor whiteColor]];
  UILabel *chartHeader = [PEUIUtils labelWithKey:title
                                            font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                 backgroundColor:[UIColor clearColor]
                                       textColor:[UIColor darkGrayColor]
                             verticalTextPadding:3.0];
  JBLineChartView *chart = [self makeLineChartWithTag:chartTag];
  UIButton *moreBtn = [PEUIUtils buttonWithKey:@"more"
                                          font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
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
  [PEUIUtils setFrameHeight:(chartHeader.frame.size.height +
                             3.0 +
                             chart.frame.size.height +
                             0.0 +
                             (addlLabelsView != nil ? addlLabelsView.frame.size.height : (moreBtn.frame.size.height + 3)) +
                             5.0 +
                             7.5)
                     ofView:panel];
  return @[panel, chart];
}

- (UIView *)makeDataTableWithRows:(NSArray *)rows
                              tag:(NSInteger)tag
                         maxWidth:(CGFloat)maxWidth {
  UIView *tablePanel =
  [PEUIUtils tablePanelWithRowData:rows
                    withCellHeight:15.0
                 labelLeftHPadding:5.0
                valueRightHPadding:10.0
                         labelFont:[UIFont systemFontOfSize:12]
                         valueFont:[UIFont systemFontOfSize:12]
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
                    relativeToView:_scrollView];
  [tablePanel setTag:tag];
  [PEUIUtils applyBorderToView:tablePanel withColor:[UIColor purpleColor]];
  return tablePanel;
}

- (UIView *)makeDaysBetweenFillupsDataTable {
  return [self makeDataTableWithRows:@[@[@"Avg:", [self formattedValueForValue:[_stats overallAvgDaysBetweenFillupsForVehicle:_vehicleInCtx] formatter:^(NSNumber *val){return [_generalFormatter stringFromNumber:val];}]],
                                       @[@"Max:", [self formattedValueForValue:[_stats overallMaxDaysBetweenFillupsForVehicle:_vehicleInCtx] formatter:^(NSNumber *val){return [_generalFormatter stringFromNumber:val];}]]]
                                 tag:FPHomeDaysBetweenFillupsTableDataTag
                            maxWidth:205];
}

- (UIView *)makePricePerGallonDataTable {
  NSNumber *octane = [self octaneOfLastVehicleInCtxGasLog];
  return [self makeDataTableWithRows:@[@[@"Avg:", [self formattedValueForValue:[_stats overallAvgPricePerGallonForUser:_user octane:octane] formatter:^(NSNumber *val){return [_currencyFormatter stringFromNumber:val];}]],
                                       @[@"Min:", [self formattedValueForValue:[_stats overallMinPricePerGallonForUser:_user octane:octane] formatter:^(NSNumber *val){return [_currencyFormatter stringFromNumber:val];}]],
                                       @[@"Max:", [self formattedValueForValue:[_stats overallMaxPricePerGallonForUser:_user octane:octane] formatter:^(NSNumber *val){return [_currencyFormatter stringFromNumber:val];}]]]
                                 tag:FPHomePriceOfGasTableDataTag
                            maxWidth:205];
}

- (UIView *)makeSpentOnGasDataTable {
  return [self makeDataTableWithRows:@[@[@"Avg:", [self formattedValueForValue:[_stats overallAvgSpentOnGasForUser:_user] formatter:^(NSNumber *val){return [_currencyFormatter stringFromNumber:val];}]],
                                       @[@"Min:", [self formattedValueForValue:[_stats overallMinSpentOnGasForUser:_user] formatter:^(NSNumber *val){return [_currencyFormatter stringFromNumber:val];}]],
                                       @[@"Max:", [self formattedValueForValue:[_stats overallMaxSpentOnGasForUser:_user] formatter:^(NSNumber *val){return [_currencyFormatter stringFromNumber:val];}]]]
                                 tag:FPHomeSpentOnGasTableDataTag
                            maxWidth:205];
}

- (void)refreshViewWithTag:(NSInteger)tag viewMaker:(UIView *(^)(void))viewMaker {
  UIView *view = [self.view viewWithTag:tag];
  UIView *superView = [view superview];
  CGRect frame = view.frame;
  [view removeFromSuperview];
  view = viewMaker();
  [PEUIUtils setFrameX:frame.origin.x ofView:view];
  [PEUIUtils setFrameY:frame.origin.y ofView:view];
  [superView addSubview:view];
}

- (NSNumber *)octaneOfLastVehicleInCtxGasLog {
  FPFuelPurchaseLog *fplog = [_coordDao.localDao lastGasLogForVehicle:_vehicleInCtx error:[FPUtils localFetchErrorHandlerMaker]()];
  if (fplog) {
    return fplog.octane;
  }
  return nil;
}

- (NSString *)formattedValueForValue:(id)value formatter:(NSString *(^)(id))formatter {
  if (value) {
    return formatter(value);
  } else {
    return FPHomeTextIfNilStat;
  }
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  [self setTitle:@"Home"];
  _vehicleInCtx = [_coordDao vehicleForMostRecentFuelPurchaseLogForUser:_user error:[FPUtils localFetchErrorHandlerMaker]()];
  if (_vehicleInCtx) {
    _tooltipView = [[JBChartTooltipView alloc] init];
    _tooltipTipView = [[JBChartTooltipTipView alloc] init];
    [_tooltipView setBackgroundColor:[UIColor blackColor]];
    _scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    [_scrollView setBounces:YES];
    CGFloat totalHeightOfViews = 0.0;
    _vehicleLabel = [self makeLabelForVehicle:_vehicleInCtx];
    _vehicleAllStatsBtn = [self makeAllStatsButtonForVehicle:_vehicleInCtx];
    
    [PEUIUtils placeView:_vehicleLabel
                 atTopOf:_scrollView
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:12.5
                hpadding:8.0];
    [PEUIUtils placeView:_vehicleAllStatsBtn
                   below:_vehicleLabel
                    onto:_scrollView
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:self.view
                vpadding:8.0
                hpadding:8.0];
    
    NSArray *daysBetweenFillupSection = [self makeLineChartSectionWithTitle:@"DAYS BETWEEN FILL-UPS (all time)"
                                                                   chartTag:FPHomeDaysBetweenFillupsChartTag
                                                          addlLabelsViewBlk:^UIView *{ return [self makeDaysBetweenFillupsDataTable];}
                                                    moreButtonControllerBlk:^UIViewController *{ return [_screenToolkit newVehicleAvgDaysBetweenFillupsStatsScreenMakerWithVehicle:_vehicleInCtx](_user);}];
    UIView *daysBetweenFillupPanel = daysBetweenFillupSection[0];
    _daysBetweenFillupsChart = daysBetweenFillupSection[1];
    [PEUIUtils placeView:daysBetweenFillupPanel
                   below:_vehicleAllStatsBtn
                    onto:_scrollView
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:self.view
                vpadding:10.0
                hpadding:0.0];
    totalHeightOfViews += _vehicleLabel.frame.size.height +
      _vehicleAllStatsBtn.frame.size.height + 4.0 +
      daysBetweenFillupPanel.frame.size.height + 10.0;
    
    NSNumber *octane = [self octaneOfLastVehicleInCtxGasLog];
    NSArray *priceOfGasSection = [self makeLineChartSectionWithTitle:[NSString stringWithFormat:@"AVG PRICE OF %@ OCTANE (all time)", octane]
                                                            chartTag:FPHomePriceOfGasChartTag
                                                   addlLabelsViewBlk:^UIView *{ return [self makePricePerGallonDataTable];}                                             moreButtonControllerBlk:^UIViewController *{ return [_screenToolkit newAvgPricePerGallonStatsScreenMakerWithOctane:[self octaneOfLastVehicleInCtxGasLog]](_user);}];
    UIView *pricePerGallonPanel = priceOfGasSection[0];
    _priceOfGasChart = priceOfGasSection[1];
    [PEUIUtils placeView:pricePerGallonPanel
                   below:daysBetweenFillupPanel
                    onto:_scrollView
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:self.view
                vpadding:10.0
                hpadding:0.0];
    totalHeightOfViews += pricePerGallonPanel.frame.size.height + 10.0;
    
    NSArray *spentOnGasSection = [self makeLineChartSectionWithTitle:@"MONTHLY SPEND ON GAS\n     (all vehicles, all time)"
                                                            chartTag:FPHomeSpentOnGasChartTag
                                                   addlLabelsViewBlk:^UIView *{ return [self makeSpentOnGasDataTable];}
                                             moreButtonControllerBlk:^UIViewController *{ return [_screenToolkit newSpentOnGasStatsScreenMaker](_user);}];
    UIView *spentOnGasPanel = spentOnGasSection[0];
    _spentOnGasChart = spentOnGasSection[1];
    [PEUIUtils placeView:spentOnGasPanel
                   below:pricePerGallonPanel
                    onto:_scrollView
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:self.view
                vpadding:10.0
                hpadding:0.0];
    totalHeightOfViews += spentOnGasPanel.frame.size.height + 10.0;
    
    // place the scroll view
    [PEUIUtils placeView:_scrollView
                 atTopOf:self.view
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0.0];
    
    [_scrollView setContentSize:CGSizeMake(_scrollView.frame.size.width, 1.125 * totalHeightOfViews)];
  } else {
    // add some sort of message label with a big shiny 'create your first vehicle' buton
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  _vehicleInCtx = [_coordDao vehicleForMostRecentFuelPurchaseLogForUser:_user error:[FPUtils localFetchErrorHandlerMaker]()];
  if (_vehicleInCtx) {
    
    // refresh the vehicle label
    CGRect vehicleLabelFrame = _vehicleLabel.frame;
    [_vehicleLabel removeFromSuperview];
    _vehicleLabel = [self makeLabelForVehicle:_vehicleInCtx];
    _vehicleLabel.frame = vehicleLabelFrame;
    [_scrollView addSubview:_vehicleLabel];
    
    //refresh the 'days between fillups' views
    _daysBetweenFillupsDataSet = [_stats overallDaysBetweenFillupsDataSetForVehicle:_vehicleInCtx];
    [self refreshViewWithTag:FPHomeDaysBetweenFillupsTableDataTag viewMaker:^{ return [self makeDaysBetweenFillupsDataTable]; }];
    [self refreshFooterForChart:_daysBetweenFillupsChart dataset:_daysBetweenFillupsDataSet];
    [_daysBetweenFillupsChart reloadData];
    
    //refresh the 'price per gallon' views
    NSNumber *octane = [self octaneOfLastVehicleInCtxGasLog];
    _priceOfGasDataSet = [_stats overallAvgPricePerGallonDataSetForUser:_user octane:octane];
    [self refreshViewWithTag:FPHomePriceOfGasTableDataTag viewMaker:^{ return [self makePricePerGallonDataTable]; }];
    [self refreshFooterForChart:_priceOfGasChart dataset:_priceOfGasDataSet];
    [_priceOfGasChart reloadData];
    
    //refresh the 'spent on gas' views
    _spentOnGasDataSet = [_stats overallSpentOnGasDataSetForUser:_user];
    [self refreshViewWithTag:FPHomeSpentOnGasTableDataTag viewMaker:^{ return [self makeSpentOnGasDataTable]; }];
    [self refreshFooterForChart:_spentOnGasChart dataset:_spentOnGasDataSet];
    [_spentOnGasChart reloadData];
  }
}

@end
