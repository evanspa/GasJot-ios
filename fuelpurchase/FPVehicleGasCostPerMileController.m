//
//  FPVehicleGasCostPerMileController.m
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 10/20/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "FPVehicleGasCostPerMileController.h"
#import <PEFuelPurchase-Model/FPStats.h>
#import <PEObjc-Commons/PEUtils.h>
#import <PEObjc-Commons/PEUIUtils.h>
#import <BlocksKit/UIControl+BlocksKit.h>
#import "FPUtils.h"
#import "FPUIUtils.h"
#import "FPVehicleGasCostPerMileComparisonController.h"
#import "UIColor+FPAdditions.h"
#import <HMSegmentedControl/HMSegmentedControl.h>
#import "JBLineChartFooterView.h"
#import "JBChartTooltipTipView.h"
#import "JBChartTooltipView.h"
#import "JBChartHeaderView.h"

NSString * const FPVehicleGasCostPerMileTextIfNilStat = @"---";

CGFloat const kJBBaseChartViewControllerAnimationDuration = 0.25f;

NSInteger const FPGasCostPerMileChartYTDIndex          = 0;
NSInteger const FPGasCostPerMileChartPreviousYearIndex = 1;
NSInteger const FPGasCostPerMileChartAllTimeIndex      = 2;

#define ARC4RANDOM_MAX 0x100000000

@implementation FPVehicleGasCostPerMileController {
  FPCoordinatorDao *_coordDao;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  FPUser *_user;
  FPVehicle *_vehicle;
  FPStats *_stats;
  UIView *_gasCostPerMileTable;
  UIView *_gasCostPerMileLineChartPanel;
  NSInteger _currentYear;
  NSNumberFormatter *_currencyFormatter;
  NSArray *_gasCostPerMileDataSet;
  NSDateFormatter *_dateFormatter;
  JBChartTooltipView *_tooltipView;
  JBChartTooltipTipView *_tooltipTipView;
  BOOL _tooltipVisible;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(FPCoordinatorDao *)coordDao
                          user:(FPUser *)user
                       vehicle:(FPVehicle *)vehicle
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(FPScreenToolkit *)screenToolkit {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _user = user;
    _vehicle = vehicle;
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
    _stats = [[FPStats alloc] initWithLocalDao:_coordDao.localDao errorBlk:[FPUtils localFetchErrorHandlerMaker]()];
    _currentYear = [PEUtils currentYear];
    _currencyFormatter = [PEUtils currencyFormatter];
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"MMM-yy"];
  }
  return self;
}

#pragma mark - JBLineChartViewDelegate

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex {
  NSArray *dataPoint = _gasCostPerMileDataSet[horizontalIndex];
  NSDecimalNumber *value = dataPoint[1];
  return [value floatValue];
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
  return 2.0;
}

- (BOOL)lineChartView:(JBLineChartView *)lineChartView smoothLineAtLineIndex:(NSUInteger)lineIndex {
  return YES;
}

- (void)lineChartView:(JBLineChartView *)lineChartView didSelectLineAtIndex:(NSUInteger)lineIndex horizontalIndex:(NSUInteger)horizontalIndex touchPoint:(CGPoint)touchPoint {
  NSArray *dataPoint = _gasCostPerMileDataSet[horizontalIndex];
  NSDecimalNumber *value = dataPoint[1];
  [self setTooltipVisible:YES animated:YES atTouchPoint:touchPoint chartView:lineChartView];
  [_tooltipView setAttributedText:[PEUIUtils attributedTextWithTemplate:[[NSString stringWithFormat:@"%@: ", [_dateFormatter stringFromDate:dataPoint[0]]] stringByAppendingString:@"%@"]
                                                           textToAccent:[_currencyFormatter stringFromNumber:value]
                                                         accentTextFont:nil
                                                        accentTextColor:[UIColor grayColor]]];
}

- (void)didDeselectLineInLineChartView:(JBLineChartView *)lineChartView {
  [self setTooltipVisible:NO animated:YES chartView:lineChartView];
}

#pragma mark - JBLineChartViewDataSource

- (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView {
  return 1;
}

- (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex {
  return [_gasCostPerMileDataSet count];
}

#pragma mark - Helpers

- (void)setTooltipVisible:(BOOL)tooltipVisible animated:(BOOL)animated atTouchPoint:(CGPoint)touchPoint chartView:(JBChartView *)chartView {
  UIView *chartViewPanel = [chartView superview];
  _tooltipVisible = tooltipVisible;
  if (!_tooltipView) {
    _tooltipView = [[JBChartTooltipView alloc] init];
    _tooltipView.alpha = 0.0;
    [chartViewPanel addSubview:_tooltipView];
  }
  
  [chartViewPanel bringSubviewToFront:_tooltipView];
  
  if (!_tooltipTipView) {
    _tooltipTipView = [[JBChartTooltipTipView alloc] init];
    _tooltipTipView.alpha = 0.0;
    [chartViewPanel addSubview:_tooltipTipView];
  }
  
  [chartViewPanel bringSubviewToFront:_tooltipTipView];
  
  dispatch_block_t adjustTooltipPosition = ^{
    CGPoint originalTouchPoint = [self.view convertPoint:touchPoint fromView:chartView];
    CGPoint convertedTouchPoint = originalTouchPoint; // modified
    CGFloat minChartX = (chartView.frame.origin.x + ceil(_tooltipView.frame.size.width * 0.5));
    if (convertedTouchPoint.x < minChartX) {
      convertedTouchPoint.x = minChartX;
    }
    CGFloat maxChartX = (chartView.frame.origin.x + chartView.frame.size.width - ceil(_tooltipView.frame.size.width * 0.5));
    if (convertedTouchPoint.x > maxChartX) {
      convertedTouchPoint.x = maxChartX;
    }
    _tooltipView.frame = CGRectMake(convertedTouchPoint.x - ceil(_tooltipView.frame.size.width * 0.5),
                                    chartView.frame.origin.y - _tooltipView.frame.size.height, //CGRectGetMaxY(chartView.headerView.frame),
                                    _tooltipView.frame.size.width,
                                    _tooltipView.frame.size.height);
    CGFloat minTipX = (chartView.frame.origin.x + _tooltipTipView.frame.size.width);
    if (originalTouchPoint.x < minTipX) {
      originalTouchPoint.x = minTipX;
    }
    CGFloat maxTipX = (chartView.frame.origin.x + chartView.frame.size.width - _tooltipTipView.frame.size.width);
    if (originalTouchPoint.x > maxTipX) {
      originalTouchPoint.x = maxTipX;
    }
    _tooltipTipView.frame = CGRectMake(originalTouchPoint.x - ceil(_tooltipTipView.frame.size.width * 0.5), CGRectGetMaxY(_tooltipView.frame), _tooltipTipView.frame.size.width, _tooltipTipView.frame.size.height);
  };
  
  dispatch_block_t adjustTooltipVisibility = ^{
    _tooltipView.alpha = _tooltipVisible ? 1.0 : 0.0;
    _tooltipTipView.alpha = _tooltipVisible ? 1.0 : 0.0;
  };
  
  if (tooltipVisible) {
    adjustTooltipPosition();
  }
  
  if (animated) {
    [UIView animateWithDuration:kJBBaseChartViewControllerAnimationDuration animations:^{
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

- (void)setTooltipVisible:(BOOL)tooltipVisible animated:(BOOL)animated chartView:(JBChartView *)chartView {
  [self setTooltipVisible:tooltipVisible animated:animated atTouchPoint:CGPointZero chartView:chartView];
}

- (void)setTooltipVisible:(BOOL)tooltipVisible chartView:(JBChartView *)chartView {
  [self setTooltipVisible:tooltipVisible animated:NO chartView:chartView];
}

- (UIView *)gasCostPerMileTable {
  return [PEUIUtils tablePanelWithRowData:@[@[[NSString stringWithFormat:@"%ld YTD", (long)_currentYear], [PEUtils textForDecimal:[_stats yearToDateGasCostPerMileForVehicle:_vehicle]
                                                                                                                        formatter:_currencyFormatter
                                                                                                                        textIfNil:FPVehicleGasCostPerMileTextIfNilStat]],
                                            @[[NSString stringWithFormat:@"%ld", (long)_currentYear-1], [PEUtils textForDecimal:[_stats lastYearGasCostPerMileForVehicle:_vehicle]
                                                                                                                      formatter:_currencyFormatter
                                                                                                                      textIfNil:FPVehicleGasCostPerMileTextIfNilStat]],
                                            @[@"All time", [PEUtils textForDecimal:[_stats overallGasCostPerMileForVehicle:_vehicle]
                                                                         formatter:_currencyFormatter
                                                                         textIfNil:FPVehicleGasCostPerMileTextIfNilStat]]]
                                uitoolkit:_uitoolkit
                               parentView:self.view];
}

- (UIView *)gasCostPerMileLineChartPanel {
  UIView *panel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:0.30 relativeToView:self.view];
  HMSegmentedControl *segmentedControl = [[HMSegmentedControl alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  [PEUIUtils setFrameWidthOfView:segmentedControl ofWidth:1.0 relativeTo:panel];
  [PEUIUtils setFrameHeightOfView:segmentedControl ofHeight:0.2 relativeTo:panel];
  
  segmentedControl.sectionTitles = @[[NSString stringWithFormat:@"%ld YTD", (long)_currentYear], [NSString stringWithFormat:@"%ld", (long)_currentYear-1], @"All time"];
  segmentedControl.selectedSegmentIndex = 0;
  segmentedControl.backgroundColor = [UIColor lightGrayColor];
  segmentedControl.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor darkGrayColor],
                                           NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]]};
  segmentedControl.selectedTitleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor],
                                                   NSFontAttributeName : [UIFont boldSystemFontOfSize:16.0]};
  segmentedControl.selectionIndicatorColor = [UIColor fpAppBlue];
  segmentedControl.selectionIndicatorBoxOpacity = 0.0;
  segmentedControl.selectionStyle = HMSegmentedControlSelectionStyleBox;
  segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationUp;
  
  JBLineChartView *lineChartView = [[JBLineChartView alloc] init];
  [lineChartView setDelegate:self];
  [lineChartView setDataSource:self];
  [PEUIUtils setFrameWidthOfView:lineChartView ofWidth:.975 relativeTo:panel];
  [PEUIUtils setFrameHeightOfView:lineChartView ofHeight:0.720 relativeTo:panel];
  JBLineChartFooterView *footerView = [[JBLineChartFooterView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  [PEUIUtils setFrameWidthOfView:footerView ofWidth:1.0 relativeTo:panel];
  [PEUIUtils setFrameHeightOfView:footerView ofHeight:0.1 relativeTo:panel];
  
  void (^configureFooter)(void) = ^{
    [footerView setSectionCount:_gasCostPerMileDataSet.count];
    [lineChartView setFooterView:footerView];
    if (_gasCostPerMileDataSet.count > 0) {
      NSArray *dp = _gasCostPerMileDataSet[0];
      footerView.leftLabel.text = [_dateFormatter stringFromDate:dp[0]];
      footerView.leftLabel.textColor = [UIColor fpAppBlue];
    }
    if (_gasCostPerMileDataSet.count > 1) {
      NSArray *dp = _gasCostPerMileDataSet[_gasCostPerMileDataSet.count - 1];
      footerView.rightLabel.text = [_dateFormatter stringFromDate:dp[0]];
      footerView.rightLabel.textColor = [UIColor fpAppBlue];
    }
  };
  configureFooter();
  [lineChartView reloadData];
  [segmentedControl setIndexChangeBlock:^(NSInteger index) {
    switch (index) {
      case FPGasCostPerMileChartYTDIndex:
        _gasCostPerMileDataSet = [_stats gasCostPerMileDataSetForVehicle:_vehicle year:_currentYear];
        break;
      case FPGasCostPerMileChartPreviousYearIndex:
        _gasCostPerMileDataSet = [_stats lastYearGasCostPerMileDataSetForVehicle:_vehicle];
        break;
      case FPGasCostPerMileChartAllTimeIndex:
        _gasCostPerMileDataSet = [_stats overallGasCostPerMileDataSetForVehicle:_vehicle];
        break;
    }
    configureFooter();
    [lineChartView reloadData];
  }];
  
  [PEUIUtils placeView:segmentedControl atTopOf:panel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
  [PEUIUtils placeView:lineChartView below:segmentedControl onto:panel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:10.0 hpadding:0.0];
  
  //[PEUIUtils applyBorderToView:panel withColor:[UIColor redColor]];
  //[PEUIUtils applyBorderToView:lineChartView withColor:[UIColor greenColor]];
  return panel;
}

#pragma mark - View controller lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  _gasCostPerMileDataSet = [_stats gasCostPerMileDataSetForVehicle:_vehicle year:_currentYear];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  [self setTitle:@"Gas Cost per Mile"];
  NSAttributedString *vehicleHeaderText = [PEUIUtils attributedTextWithTemplate:@"(vehicle: %@)"
                                                                   textToAccent:_vehicle.name
                                                                 accentTextFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]
                                                                accentTextColor:[UIColor fpAppBlue]];
  UILabel *vehicleLabel = [PEUIUtils labelWithAttributeText:vehicleHeaderText
                                                       font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                   fontForHeightCalculation:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]
                                            backgroundColor:[UIColor clearColor]
                                                  textColor:[UIColor darkGrayColor]
                                        verticalTextPadding:3.0
                                                 fitToWidth:self.view.frame.size.width - 15.0];
  UIView *gasCostPerMileHeader = [FPUIUtils headerPanelWithText:@"GAS COST PER MILE AGGREGATES" relativeToView:self.view];
  _gasCostPerMileTable = [self gasCostPerMileTable];
  _gasCostPerMileLineChartPanel = [self gasCostPerMileLineChartPanel];
  
  // place the views
  [PEUIUtils placeView:vehicleLabel atTopOf:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:75.0 hpadding:8.0];
  [PEUIUtils placeView:gasCostPerMileHeader
                 below:vehicleLabel
                  onto:self.view
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:self.view
              vpadding:12.0
              hpadding:0.0];
  [PEUIUtils placeView:_gasCostPerMileTable
                 below:gasCostPerMileHeader
                  onto:self.view
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  [PEUIUtils placeView:_gasCostPerMileLineChartPanel
                 below:_gasCostPerMileTable
                  onto:self.view
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:self.view
              vpadding:20.0
              hpadding:0.0];
  if ([_coordDao vehiclesForUser:_user error:[FPUtils localFetchErrorHandlerMaker]()].count > 1) {
    UIButton *vehicleCompareBtn = [_uitoolkit systemButtonMaker](@"Compare vehicles", nil, nil);
    [PEUIUtils setFrameWidthOfView:vehicleCompareBtn ofWidth:1.0 relativeTo:self.view];
    [PEUIUtils addDisclosureIndicatorToButton:vehicleCompareBtn];
    [vehicleCompareBtn bk_addEventHandler:^(id sender) {
      FPVehicleGasCostPerMileComparisonController *comparisonScreen =
      [[FPVehicleGasCostPerMileComparisonController alloc] initWithStoreCoordinator:_coordDao
                                                                               user:_user
                                                                            vehicle:_vehicle
                                                                          uitoolkit:_uitoolkit
                                                                      screenToolkit:_screenToolkit];
      [[self navigationController] pushViewController:comparisonScreen animated:YES];
    } forControlEvents:UIControlEventTouchUpInside];
    [PEUIUtils placeView:vehicleCompareBtn
                   below:_gasCostPerMileLineChartPanel
                    onto:self.view
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:20.0
                hpadding:0.0];
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  // remove the views
  CGRect gasCostPerMileTableFrame = _gasCostPerMileTable.frame;
  CGRect gasCostPerMileLineChartFrame = _gasCostPerMileLineChartPanel.frame;
  
  [_gasCostPerMileTable removeFromSuperview];
  [_gasCostPerMileLineChartPanel removeFromSuperview];
  
  // refresh their data
  _gasCostPerMileTable = [self gasCostPerMileTable];
  _gasCostPerMileLineChartPanel = [self gasCostPerMileLineChartPanel];
  
  // re-add them
  _gasCostPerMileTable.frame = gasCostPerMileTableFrame;
  _gasCostPerMileLineChartPanel.frame = gasCostPerMileLineChartFrame;
  [self.view addSubview:_gasCostPerMileTable];
  [self.view addSubview:_gasCostPerMileLineChartPanel];
}

@end
