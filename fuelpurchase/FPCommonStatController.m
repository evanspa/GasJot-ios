//
//  FPCommonStatController.m
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 10/20/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "FPCommonStatController.h"
#import <PEFuelPurchase-Model/FPStats.h>
#import <PEObjc-Commons/PEUtils.h>
#import <PEObjc-Commons/PEUIUtils.h>
#import <BlocksKit/UIControl+BlocksKit.h>
#import "FPUtils.h"
#import "FPUIUtils.h"
#import "UIColor+FPAdditions.h"
#import <HMSegmentedControl/HMSegmentedControl.h>
#import "JBLineChartFooterView.h"
#import "JBChartTooltipTipView.h"
#import "JBChartTooltipView.h"
#import "JBChartHeaderView.h"

NSString * const FPTextIfNilStat = @"---";

NSInteger const FPChartAllTimeIndex      = 0;
NSInteger const FPChartYTDIndex          = 1;
NSInteger const FPChartPreviousYearIndex = 2;

@implementation FPCommonStatController {
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  UIView *_aggregatesTable;
  UIView *_lineChartPanel;
  NSInteger _currentYear;
  NSNumberFormatter *_currencyFormatter;
  NSArray *_dataset;
  NSDateFormatter *_dateFormatter;
  JBChartTooltipView *_tooltipView;
  JBChartTooltipTipView *_tooltipTipView;
  BOOL _tooltipVisible;
  NSString *_screenTitle;
  NSString *_entityTypeLabelText;
  NSString *_entityName;
  id _entity;
  NSString *_aggregatesHeaderText;
  NSString *_compareButtonTitleText;
  FPAlltimeAggregate _alltimeAggregateBlk;
  FPYearToDateAggregate _yearToDateAggregateBlk;
  FPLastYearAggregate _lastYearAggregateBlk;
  FPAlltimeDataset _alltimeDatasetBlk;
  FPYearToDateDataset _yearToDateDatasetBlk;
  FPLastYearDataset _lastYearDatasetBlk;
  FPSiblingEntityCount _siblingCountBlk;
  FPComparisonScreenMaker _comparisonScreenMakerBlk;
}

#pragma mark - Initializers

- (id)initWithScreenTitle:(NSString *)screenTitle
      entityTypeLabelText:(NSString *)entityTypeLabelText
               entityName:(NSString *)entityName
                   entity:(id)entity
     aggregatesHeaderText:(NSString *)aggregatesHeaderText
   compareButtonTitleText:(NSString *)compareButtonTitleText
      alltimeAggregateBlk:(FPAlltimeAggregate)alltimeAggregateBlk
   yearToDateAggregateBlk:(FPYearToDateAggregate)yearToDateAggregateBlk
     lastYearAggregateBlk:(FPLastYearAggregate)lastYearAggregateBlk
        alltimeDatasetBlk:(FPAlltimeDataset)alltimeDatasetBlk
     yearToDateDatasetBlk:(FPYearToDateDataset)yearToDateDatasetBlk
       lastYearDatasetBlk:(FPLastYearDataset)lastYearDatasetBlk
          siblingCountBlk:(FPSiblingEntityCount)siblingCountBlk
 comparisonScreenMakerBlk:(FPComparisonScreenMaker)comparisonScreenMakerBlk
                uitoolkit:(PEUIToolkit *)uitoolkit {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _screenTitle = screenTitle;
    _entityTypeLabelText = entityTypeLabelText;
    _entityName = entityName;
    _entity = entity;
    _aggregatesHeaderText = aggregatesHeaderText;
    _compareButtonTitleText = compareButtonTitleText;
    _alltimeAggregateBlk = alltimeAggregateBlk;
    _yearToDateAggregateBlk = yearToDateAggregateBlk;
    _lastYearAggregateBlk = lastYearAggregateBlk;
    _alltimeDatasetBlk = alltimeDatasetBlk;
    _yearToDateDatasetBlk = yearToDateDatasetBlk;
    _lastYearDatasetBlk = lastYearDatasetBlk;
    _siblingCountBlk = siblingCountBlk;
    _comparisonScreenMakerBlk = comparisonScreenMakerBlk;
    _uitoolkit = uitoolkit;
    _currentYear = [PEUtils currentYear];
    _currencyFormatter = [PEUtils currencyFormatter];
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"MMM-yy"];
  }
  return self;
}

#pragma mark - JBLineChartViewDelegate

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex {
  NSArray *dataPoint = _dataset[horizontalIndex];
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
  NSArray *dataPoint = _dataset[horizontalIndex];
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
  return [_dataset count];
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

- (void)setTooltipVisible:(BOOL)tooltipVisible animated:(BOOL)animated chartView:(JBChartView *)chartView {
  [self setTooltipVisible:tooltipVisible animated:animated atTouchPoint:CGPointZero chartView:chartView];
}

- (void)setTooltipVisible:(BOOL)tooltipVisible chartView:(JBChartView *)chartView {
  [self setTooltipVisible:tooltipVisible animated:NO chartView:chartView];
}

- (UIView *)aggregatesTable {
  return [PEUIUtils tablePanelWithRowData:@[@[@"All time", [PEUtils textForDecimal:_alltimeAggregateBlk(_entity)
                                                                         formatter:_currencyFormatter
                                                                         textIfNil:FPTextIfNilStat]],
                                            @[[NSString stringWithFormat:@"%ld YTD", (long)_currentYear], [PEUtils textForDecimal:_yearToDateAggregateBlk(_entity)
                                                                                                                        formatter:_currencyFormatter
                                                                                                                        textIfNil:FPTextIfNilStat]],
                                            @[[NSString stringWithFormat:@"%ld", (long)_currentYear-1], [PEUtils textForDecimal:_lastYearAggregateBlk(_entity)
                                                                                                                      formatter:_currencyFormatter
                                                                                                                      textIfNil:FPTextIfNilStat]]]
                                uitoolkit:_uitoolkit
                               parentView:self.view];
}

- (UIView *)makeLineChartPanel {
  UIView *panel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:0.30 relativeToView:self.view];
  HMSegmentedControl *segmentedControl = [[HMSegmentedControl alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  [PEUIUtils setFrameWidthOfView:segmentedControl ofWidth:1.0 relativeTo:panel];
  [PEUIUtils setFrameHeightOfView:segmentedControl ofHeight:0.2 relativeTo:panel];
  segmentedControl.sectionTitles = @[@"All time",
                                     [NSString stringWithFormat:@"%ld YTD", (long)_currentYear],
                                     [NSString stringWithFormat:@"%ld", (long)_currentYear-1]];
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
    [footerView setSectionCount:_dataset.count];
    [lineChartView setFooterView:footerView];
    if (_dataset.count > 0) {
      NSArray *dp = _dataset[0];
      footerView.leftLabel.text = [_dateFormatter stringFromDate:dp[0]];
    } else {
      footerView.leftLabel.text = @"NO (OR NOT ENOUGH) DATA.";
      footerView.rightLabel.text = @"";
    }
    footerView.leftLabel.textColor = [UIColor fpAppBlue];
    if (_dataset.count > 1) {
      NSArray *dp = _dataset[_dataset.count - 1];
      footerView.rightLabel.text = [_dateFormatter stringFromDate:dp[0]];
      footerView.rightLabel.textColor = [UIColor fpAppBlue];
    }
  };
  configureFooter();
  [lineChartView reloadData];
  [segmentedControl setIndexChangeBlock:^(NSInteger index) {
    switch (index) {
      case FPChartAllTimeIndex:
        _dataset = _alltimeDatasetBlk(_entity);
        break;
      case FPChartYTDIndex:
        _dataset = _yearToDateDatasetBlk(_entity);
        break;
      case FPChartPreviousYearIndex:
        _dataset = _lastYearDatasetBlk(_entity);
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
  _dataset = _alltimeDatasetBlk(_entity);
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  [self setTitle:_screenTitle];
  NSAttributedString *entityHeaderText = [PEUIUtils attributedTextWithTemplate:[[NSString stringWithFormat:@"(%@: ", _entityTypeLabelText] stringByAppendingString:@"%@)"]
                                                                  textToAccent:_entityName
                                                                accentTextFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]
                                                               accentTextColor:[UIColor fpAppBlue]];
  UILabel *entityLabel = [PEUIUtils labelWithAttributeText:entityHeaderText
                                                      font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                  fontForHeightCalculation:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]
                                           backgroundColor:[UIColor clearColor]
                                                 textColor:[UIColor darkGrayColor]
                                       verticalTextPadding:3.0
                                                fitToWidth:self.view.frame.size.width - 15.0];
  UIView *aggregatesHeader = [FPUIUtils headerPanelWithText:_aggregatesHeaderText relativeToView:self.view];
  _aggregatesTable = [self aggregatesTable];
  _lineChartPanel = [self makeLineChartPanel];
  
  // place the views
  [PEUIUtils placeView:entityLabel atTopOf:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:75.0 hpadding:8.0];
  [PEUIUtils placeView:aggregatesHeader
                 below:entityLabel
                  onto:self.view
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:self.view
              vpadding:12.0
              hpadding:0.0];
  [PEUIUtils placeView:_aggregatesTable
                 below:aggregatesHeader
                  onto:self.view
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  [PEUIUtils placeView:_lineChartPanel
                 below:_aggregatesTable
                  onto:self.view
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:self.view
              vpadding:20.0
              hpadding:0.0];
  if (_siblingCountBlk() > 1) {
    UIButton *compareBtn = [_uitoolkit systemButtonMaker](_compareButtonTitleText, nil, nil);
    [PEUIUtils setFrameWidthOfView:compareBtn ofWidth:1.0 relativeTo:self.view];
    [PEUIUtils addDisclosureIndicatorToButton:compareBtn];
    [compareBtn bk_addEventHandler:^(id sender) {
      UIViewController *comparisonScreen = _comparisonScreenMakerBlk();
      [[self navigationController] pushViewController:comparisonScreen animated:YES];
    } forControlEvents:UIControlEventTouchUpInside];
    [PEUIUtils placeView:compareBtn
                   below:_lineChartPanel
                    onto:self.view
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:20.0
                hpadding:0.0];
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  // remove the views
  CGRect aggregatesTableFrame = _aggregatesTable.frame;
  CGRect lineChartFrame = _lineChartPanel.frame;
  
  [_aggregatesTable removeFromSuperview];
  [_lineChartPanel removeFromSuperview];
  
  // refresh their data
  _aggregatesTable = [self aggregatesTable];
  _lineChartPanel = [self makeLineChartPanel];
  
  // re-add them
  _aggregatesTable.frame = aggregatesTableFrame;
  _lineChartPanel.frame = lineChartFrame;
  [self.view addSubview:_aggregatesTable];
  [self.view addSubview:_lineChartPanel];
}

@end
