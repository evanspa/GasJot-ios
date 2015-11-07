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
  NSArray *_dataset;
  NSDateFormatter *_dateFormatter;
  JBChartTooltipView *_tooltipView;
  JBChartTooltipTipView *_tooltipTipView;
  BOOL _tooltipVisible;
  NSString *_screenTitle;
  NSString *_entityTypeLabelText;
  FPEntityNameBlk _entityNameBlk;
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
  FPValueFormatter _valueFormatter;
  //UIScrollView *_contentView;
  UIView *_contentView;
}

#pragma mark - Initializers

- (id)initWithScreenTitle:(NSString *)screenTitle
      entityTypeLabelText:(NSString *)entityTypeLabelText
            entityNameBlk:(FPEntityNameBlk)entityNameBlk
                   entity:(id)entity
     aggregatesHeaderText:(NSString *)aggregatesHeaderText
   compareButtonTitleText:(NSString *)compareButtonTitleText
      alltimeAggregateBlk:(FPAlltimeAggregate)alltimeAggregateBlk
   yearToDateAggregateBlk:(FPYearToDateAggregate)yearToDateAggregateBlk
     lastYearAggregateBlk:(FPLastYearAggregate)lastYearAggregateBlk
          siblingCountBlk:(FPSiblingEntityCount)siblingCountBlk
 comparisonScreenMakerBlk:(FPComparisonScreenMaker)comparisonScreenMakerBlk
        valueFormatterBlk:(FPValueFormatter)valueFormatterBlk
                uitoolkit:(PEUIToolkit *)uitoolkit {
  return [self initWithScreenTitle:screenTitle
               entityTypeLabelText:entityTypeLabelText
                     entityNameBlk:entityNameBlk
                            entity:entity
              aggregatesHeaderText:aggregatesHeaderText
            compareButtonTitleText:compareButtonTitleText
               alltimeAggregateBlk:alltimeAggregateBlk
            yearToDateAggregateBlk:yearToDateAggregateBlk
              lastYearAggregateBlk:lastYearAggregateBlk
                 alltimeDatasetBlk:nil
              yearToDateDatasetBlk:nil
                lastYearDatasetBlk:nil
                   siblingCountBlk:siblingCountBlk
          comparisonScreenMakerBlk:comparisonScreenMakerBlk
                 valueFormatterBlk:valueFormatterBlk
                         uitoolkit:uitoolkit];
}

- (id)initWithScreenTitle:(NSString *)screenTitle
      entityTypeLabelText:(NSString *)entityTypeLabelText
            entityNameBlk:(FPEntityNameBlk)entityNameBlk
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
        valueFormatterBlk:(FPValueFormatter)valueFormatterBlk
                uitoolkit:(PEUIToolkit *)uitoolkit {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _screenTitle = screenTitle;
    _entityTypeLabelText = entityTypeLabelText;
    _entityNameBlk = entityNameBlk;
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
    _valueFormatter = valueFormatterBlk;
    _uitoolkit = uitoolkit;
    _currentYear = [PEUtils currentYear];
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"MMM-yyyy"];
  }
  return self;
}

#pragma mark - JBLineChartViewDelegate

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex {
  NSArray *dataPoint = _dataset[horizontalIndex];
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
  /*if (_dataset.count > 50) {
    return 0.0;
  }
  return 1.0;*/
  return 0.0;
}

- (BOOL)lineChartView:(JBLineChartView *)lineChartView smoothLineAtLineIndex:(NSUInteger)lineIndex {
  return YES;
}

- (void)lineChartView:(JBLineChartView *)lineChartView didSelectLineAtIndex:(NSUInteger)lineIndex horizontalIndex:(NSUInteger)horizontalIndex touchPoint:(CGPoint)touchPoint {
  NSArray *dataPoint = _dataset[horizontalIndex];
  NSDecimalNumber *value = dataPoint[1];
  
  //[self setTooltipVisible:YES animated:YES atTouchPoint:touchPoint chartView:lineChartView];
  [FPUIUtils setTooltipVisible:YES
                   tooltipView:_tooltipView
                tooltipTipView:_tooltipTipView
                      animated:YES
                  atTouchPoint:touchPoint
                     chartView:lineChartView
                controllerView:self.view];
  
  [_tooltipView setAttributedText:[PEUIUtils attributedTextWithTemplate:@"%@"
                                                           textToAccent:[NSString stringWithFormat:@"%@: %@", [_dateFormatter stringFromDate:dataPoint[0]], _valueFormatter(value)]
                                                         accentTextFont:nil
                                                        accentTextColor:[UIColor whiteColor]]];
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
  return [_dataset count];
}

#pragma mark - Helpers

- (NSString *)formattedValueForValue:(id)value {
  if (value) {
    return _valueFormatter(value);
  } else {
    return FPTextIfNilStat;
  }
}

- (UIView *)aggregatesTable {
  return [PEUIUtils tablePanelWithRowData:@[@[@"All time", [self formattedValueForValue:_alltimeAggregateBlk(_entity)]],
                                            @[[NSString stringWithFormat:@"%ld YTD", (long)_currentYear], [self formattedValueForValue:_yearToDateAggregateBlk(_entity)]],
                                            @[[NSString stringWithFormat:@"%ld", (long)_currentYear-1], [self formattedValueForValue:_lastYearAggregateBlk(_entity)]]]
                                uitoolkit:_uitoolkit
                               parentView:self.view];
}

- (UIView *)makeLineChartPanel {
  UIView *panel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:self.view]; // will resize height later
  [panel setBackgroundColor:[UIColor whiteColor]];
  HMSegmentedControl *segmentedControl = [[HMSegmentedControl alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  [PEUIUtils setFrameWidthOfView:segmentedControl ofWidth:1.0 relativeTo:panel];
  [PEUIUtils setFrameHeight:35.0 ofView:segmentedControl];
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
  [PEUIUtils setFrameHeight:115.0 ofView:lineChartView];
  JBLineChartFooterView *footerView = [[JBLineChartFooterView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  footerView.footerSeparatorColor = [UIColor darkGrayColor];
  [PEUIUtils setFrameWidthOfView:footerView ofWidth:1.0 relativeTo:panel];
  [PEUIUtils setFrameHeight:25.0 ofView:footerView];
  
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
  UILabel *trendLabel = [PEUIUtils labelWithKey:@"TREND"
                                           font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                backgroundColor:[UIColor clearColor]
                                      textColor:[UIColor darkGrayColor]
                            verticalTextPadding:3.0];
  [PEUIUtils placeView:trendLabel atTopOf:panel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:8.0];
  [PEUIUtils placeView:segmentedControl below:trendLabel onto:panel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:self.view vpadding:4.0 hpadding:0.0];
  [PEUIUtils placeView:lineChartView below:segmentedControl onto:panel withAlignment:PEUIHorizontalAlignmentTypeCenter alignmentRelativeToView:self.view vpadding:10.0 hpadding:0.0];
  [PEUIUtils setFrameHeight:(trendLabel.frame.size.height + segmentedControl.frame.size.height + lineChartView.frame.size.height + 4.0 + 10.0) ofView:panel];
  return panel;
}

#pragma mark - View controller lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  
  _tooltipView = [[JBChartTooltipView alloc] init];
  _tooltipTipView = [[JBChartTooltipTipView alloc] init];
  [_tooltipView setBackgroundColor:[UIColor blackColor]];
  
  //_contentView = [[UIScrollView alloc] initWithFrame:self.view.frame];
  //[_contentView setContentSize:CGSizeMake(self.view.frame.size.width, 1.01 * self.view.frame.size.height)];
  //[_contentView setBounces:NO];
  _contentView = [PEUIUtils panelWithFixedWidth:self.view.frame.size.width fixedHeight:self.view.frame.size.height];
  if (_alltimeDatasetBlk) {
    _dataset = _alltimeDatasetBlk(_entity);
  }
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  [self setTitle:_screenTitle];
  UILabel *entityLabel = nil;
  if (_entityTypeLabelText && _entityNameBlk && _entity) {
    NSString *entityName = [FPUtils truncatedText:_entityNameBlk(_entity) maxLength:27];
    NSAttributedString *entityHeaderText = [PEUIUtils attributedTextWithTemplate:[[NSString stringWithFormat:@"%@: ", _entityTypeLabelText] stringByAppendingString:@"%@"]
                                                                    textToAccent:entityName
                                                                  accentTextFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]
                                                                 accentTextColor:[UIColor fpAppBlue]];
    entityLabel = [PEUIUtils labelWithAttributeText:entityHeaderText
                                               font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                           fontForHeightCalculation:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]
                                    backgroundColor:[UIColor clearColor]
                                          textColor:[UIColor darkGrayColor]
                                verticalTextPadding:3.0
                                         fitToWidth:self.view.frame.size.width - 15.0];
  }
  _aggregatesTable = [self aggregatesTable];
  if (_alltimeDatasetBlk) {
    _lineChartPanel = [self makeLineChartPanel];
  }
  // place the views
  if (entityLabel) {
    [PEUIUtils placeView:entityLabel
                 atTopOf:_contentView
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:75.0 //13.0 (use '13.0' when _contentView is a scroll view); use 75.0 when not a scroll view
                hpadding:8.0];
    [PEUIUtils placeView:_aggregatesTable
                   below:entityLabel
                    onto:_contentView
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:_contentView
                vpadding:4.0
                hpadding:0.0];
  } else {
    [PEUIUtils placeView:_aggregatesTable
                 atTopOf:_contentView
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:75.0 //13.0 (use '13.0' when _contentView is a scroll view); use 75.0 when not a scroll view
                hpadding:0.0];
  }
  UIView *aboveView = _aggregatesTable;
  if (_lineChartPanel) {
    aboveView = _lineChartPanel;
    [PEUIUtils placeView:_lineChartPanel
                   below:_aggregatesTable
                    onto:_contentView
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:self.view
                vpadding:10.0
                hpadding:0.0];
  }
  if (_siblingCountBlk && _siblingCountBlk() > 1) {
    UIButton *compareBtn = [_uitoolkit systemButtonMaker](_compareButtonTitleText, nil, nil);
    [PEUIUtils setFrameWidthOfView:compareBtn ofWidth:1.0 relativeTo:self.view];
    [PEUIUtils addDisclosureIndicatorToButton:compareBtn];
    [compareBtn bk_addEventHandler:^(id sender) {
      UIViewController *comparisonScreen = _comparisonScreenMakerBlk();
      [[self navigationController] pushViewController:comparisonScreen animated:YES];
    } forControlEvents:UIControlEventTouchUpInside];
    [PEUIUtils placeView:compareBtn
                   below:aboveView
                    onto:_contentView
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:8.0
                hpadding:0.0];
  }
  [PEUIUtils placeView:_contentView atTopOf:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  // remove the views
  CGRect aggregatesTableFrame = _aggregatesTable.frame;
  CGRect lineChartFrame;
  if (_lineChartPanel) {
    lineChartFrame = _lineChartPanel.frame;
  }
  
  [_aggregatesTable removeFromSuperview];
  if (_lineChartPanel) {
    [_lineChartPanel removeFromSuperview];
  }
  
  // refresh their data
  _aggregatesTable = [self aggregatesTable];
  if (_lineChartPanel) {
    _lineChartPanel = [self makeLineChartPanel];
  }
  
  // re-add them
  _aggregatesTable.frame = aggregatesTableFrame;
  if (_lineChartPanel) {
    _lineChartPanel.frame = lineChartFrame;
  }
  [_contentView addSubview:_aggregatesTable];
  if (_lineChartPanel) {
    [_contentView addSubview:_lineChartPanel];
  }
}

@end
