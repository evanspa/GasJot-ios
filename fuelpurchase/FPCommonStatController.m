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
  if (![PEUtils isNil:value]) {
    return _valueFormatter(value);
  } else {
    return FPTextIfNilStat;
  }
}

- (UIView *)aggregatesTableWithValues:(NSArray *)values {
  return [PEUIUtils tablePanelWithRowData:@[@[@"All time", [self formattedValueForValue:values[0]]],
                                            @[[NSString stringWithFormat:@"%ld YTD", (long)_currentYear], [self formattedValueForValue:values[1]]],
                                            @[[NSString stringWithFormat:@"%ld", (long)_currentYear-1], [self formattedValueForValue:values[2]]]]
                                uitoolkit:_uitoolkit
                               parentView:self.view];
}

- (void)refreshFooterOfChart:(JBLineChartView *)chart {
  JBLineChartFooterView *footerView = (JBLineChartFooterView *)chart.footerView;
  [footerView setSectionCount:_dataset.count];
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
}

- (NSArray *)makeLineChartSection {
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
                                           NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]};
  segmentedControl.selectedTitleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor],
                                                   NSFontAttributeName : [PEUIUtils boldFontForTextStyle:UIFontTextStyleBody]};
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
  [lineChartView setFooterView:footerView];
  
  [segmentedControl setIndexChangeBlock:^(NSInteger index) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
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
      dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self refreshFooterOfChart:lineChartView];
        [lineChartView reloadData];
      });
    });
  }];
  UILabel *trendLabel = [PEUIUtils labelWithKey:@"TREND"
                                           font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                backgroundColor:[UIColor clearColor]
                                      textColor:[UIColor darkGrayColor]
                            verticalTextPadding:3.0];
  [PEUIUtils placeView:trendLabel atTopOf:panel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:8.0];
  [PEUIUtils placeView:segmentedControl below:trendLabel onto:panel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:self.view vpadding:4.0 hpadding:0.0];
  [PEUIUtils placeView:lineChartView below:segmentedControl onto:panel withAlignment:PEUIHorizontalAlignmentTypeCenter alignmentRelativeToView:self.view vpadding:10.0 hpadding:0.0];
  [PEUIUtils setFrameHeight:(trendLabel.frame.size.height + segmentedControl.frame.size.height + lineChartView.frame.size.height + 4.0 + 10.0) ofView:panel];
  return @[panel, lineChartView];
}

#pragma mark - Make Content

- (NSArray *)makeContent {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:self.view fixedHeight:0.0];
  UILabel *entityLabel = nil;
  if (_entityTypeLabelText && _entityNameBlk && _entity) {
    NSString *entityName = [FPUtils truncatedText:_entityNameBlk(_entity) maxLength:27];
    NSAttributedString *entityHeaderText = [PEUIUtils attributedTextWithTemplate:[[NSString stringWithFormat:@"%@: ", _entityTypeLabelText] stringByAppendingString:@"%@"]
                                                                    textToAccent:entityName
                                                                  accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]
                                                                 accentTextColor:[UIColor fpAppBlue]];
    entityLabel = [PEUIUtils labelWithAttributeText:entityHeaderText
                                               font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                           fontForHeightCalculation:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]
                                    backgroundColor:[UIColor clearColor]
                                          textColor:[UIColor darkGrayColor]
                                verticalTextPadding:3.0
                                         fitToWidth:self.view.frame.size.width - 15.0];
  } else if (_entityTypeLabelText) {
    entityLabel = [PEUIUtils labelWithKey:_entityTypeLabelText
                                     font:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]
                          backgroundColor:[UIColor clearColor]
                                textColor:[UIColor fpAppBlue]
                      verticalTextPadding:3.0
                               fitToWidth:self.view.frame.size.width - 15.0];
  }
  _aggregatesTable = [self aggregatesTableWithValues:@[[NSNull null], [NSNull null], [NSNull null]]];
  UIView *lineChartPanel = nil;
  if (_alltimeDatasetBlk) {
    NSArray *section = [self makeLineChartSection];
    lineChartPanel = section[0];
    JBLineChartView *chart = section[1];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
      _dataset = _alltimeDatasetBlk(_entity);
      dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self refreshFooterOfChart:chart];
        [chart reloadData];
      });
    });
  }
  // place the views
  CGFloat totalHeight = 0.0;
  if (entityLabel) {
    [PEUIUtils placeView:entityLabel
                 atTopOf:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:FPContentPanelTopPadding
                hpadding:8.0];
    totalHeight += entityLabel.frame.size.height + FPContentPanelTopPadding;
    [PEUIUtils placeView:_aggregatesTable
                   below:entityLabel
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:4.0
                hpadding:0.0];
    totalHeight += _aggregatesTable.frame.size.height + 4.0;
  } else {
    [PEUIUtils placeView:_aggregatesTable
                 atTopOf:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:FPContentPanelTopPadding
                hpadding:0.0];
    totalHeight += _aggregatesTable.frame.size.height + FPContentPanelTopPadding;
  }
  UIView *aboveView = _aggregatesTable;
  if (lineChartPanel) {
    aboveView = lineChartPanel;
    [PEUIUtils placeView:lineChartPanel
                   below:_aggregatesTable
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:self.view
                vpadding:10.0
                hpadding:0.0];
    totalHeight += lineChartPanel.frame.size.height + 10.0;
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
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:8.0
                hpadding:0.0];
    totalHeight += compareBtn.frame.size.height + 8.0;
  }
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(NO)];
}

#pragma mark - View controller lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  [self setTitle:_screenTitle];
  
  _tooltipView = [[JBChartTooltipView alloc] init];
  _tooltipTipView = [[JBChartTooltipTipView alloc] init];
  [_tooltipView setBackgroundColor:[UIColor blackColor]];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  void (^refreshRowValue)(NSInteger, id) = ^(NSInteger tag, id value) {
    UILabel *valueLabel = (UILabel *)[_aggregatesTable viewWithTag:tag];
    CGFloat currentWidth = valueLabel.frame.size.width;
    NSString *valueText = [self formattedValueForValue:value];
    [valueLabel setText:valueText];
    CGSize newSize = [PEUIUtils sizeOfText:valueText withFont:valueLabel.font];
    [PEUIUtils setFrameWidth:newSize.width ofView:valueLabel];
    [PEUIUtils setFrameX:(valueLabel.frame.origin.x + (currentWidth - newSize.width)) ofView:valueLabel];
  };
  
  // refresh the table data
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
    id alltimeVal = _alltimeAggregateBlk(_entity);
    id yearToDateVal = _yearToDateAggregateBlk(_entity);
    id lastYearVal = _lastYearAggregateBlk(_entity);
    dispatch_async(dispatch_get_main_queue(), ^(void) {
      refreshRowValue(1, alltimeVal);
      refreshRowValue(2, yearToDateVal);
      refreshRowValue(3, lastYearVal);
    });
  });
}

@end
