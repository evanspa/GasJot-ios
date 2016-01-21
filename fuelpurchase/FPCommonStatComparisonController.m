//
//  FPCommonStatComparisonController.m
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 10/20/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "FPCommonStatComparisonController.h"
#import <PEFuelPurchase-Model/FPStats.h>
#import <PEObjc-Commons/PEUtils.h>
#import <PEObjc-Commons/PEUIUtils.h>
#import <BlocksKit/UIControl+BlocksKit.h>
#import "FPUtils.h"
#import "FPUIUtils.h"
#import "UIColor+FPAdditions.h"

NSString * const FPCommonStatComparisonTextIfNilStat = @"---";
NSString * const FPStatComparisonCellIdentifier = @"FPStatComparisonCellIdentifier";

@implementation FPCommonStatComparisonController {
  id<FPCoordinatorDao> _coordDao;
  PEUIToolkit *_uitoolkit;
  NSString *_screenTitle;
  FPEntityNameBlk _entityName;
  id _entity;
  UIView *_comparisonTable;
  NSString *_headerText;
  FPEntitiesToCompareBlk _entitiesToCompareBlk;
  FPAlltimeAggregate _alltimeAggregateBlk;
  FPValueFormatter _valueFormatterBlk;
  NSComparisonResult(^_comparator)(NSArray *, NSArray *);
}

#pragma mark - Initializers

- (id)initWithScreenTitle:(NSString *)screenTitle
               headerText:(NSString *)headerText
            entityNameBlk:(FPEntityNameBlk)entityNameBlk
                   entity:(id)entity
     entitiesToCompareBlk:(FPEntitiesToCompareBlk)entitiesToCompareBlk
      alltimeAggregateBlk:(FPAlltimeAggregate)alltimeAggregateBlk
        valueFormatterBlk:(FPValueFormatter)valueFormatterBlk
               comparator:(NSComparisonResult(^)(NSArray *, NSArray *))comparator
                uitoolkit:(PEUIToolkit *)uitoolkit {
  self = [super initWithRequireRepaintNotifications:nil];
  if (self) {
    _screenTitle = screenTitle;
    _headerText = headerText;
    _entityName = entityNameBlk;
    _entity = entity;
    _entitiesToCompareBlk = entitiesToCompareBlk;
    _alltimeAggregateBlk = alltimeAggregateBlk;
    _valueFormatterBlk = valueFormatterBlk;
    _comparator = comparator;
    _uitoolkit = uitoolkit;
  }
  return self;
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  NSMutableArray *rowData = [NSMutableArray array];
  NSMutableArray *nilRowData = [NSMutableArray array];
  NSArray *entities = _entitiesToCompareBlk();
  NSString *(^truncatedEntityName)(id) = ^NSString *(id entity) { // kinda hacky
    NSString *entityNameStr = _entityName(entity);
    NSInteger maxLength = 25;
    if (entityNameStr.length > maxLength) {
      entityNameStr = [[entityNameStr substringToIndex:maxLength-3] stringByAppendingString:@"..."];
    }
    return entityNameStr;
  };
  for (id entity in entities) {
    NSNumber *statValue = _alltimeAggregateBlk(entity);
    id entityName;
    if (_entity && entity && [entity isEqual:_entity]) {
      entityName = [PEUIUtils attributedTextWithTemplate:@"%@"
                                            textToAccent:truncatedEntityName(entity)
                                          accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleBody]
                                         accentTextColor:[UIColor fpAppBlue]];
    } else {
      entityName = truncatedEntityName(entity);
    }
    if (statValue) {
      [rowData addObject:@[entityName, _valueFormatterBlk(statValue), statValue]];
    } else {
      [nilRowData addObject:@[entityName, FPCommonStatComparisonTextIfNilStat, [NSDecimalNumber notANumber]]];
    }
  }
  [rowData sortUsingComparator:_comparator];
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:self.view fixedHeight:0.0];
  UIView *header = [FPUIUtils headerPanelWithText:_headerText relativeToView:self.view];
  UIView *tablePanel = [PEUIUtils tablePanelWithRowData:[rowData arrayByAddingObjectsFromArray:nilRowData]
                                              uitoolkit:_uitoolkit
                                             parentView:self.view];
  // place the views
  [PEUIUtils placeView:header atTopOf:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:FPContentPanelTopPadding hpadding:0.0];
  CGFloat totalHeight = header.frame.size.height + FPContentPanelTopPadding;
  [PEUIUtils placeView:tablePanel below:header onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:8.0 hpadding:0.0];
  totalHeight += tablePanel.frame.size.height + 8.0;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(NO)];
}

#pragma mark - View controller lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  [[self navigationItem] setTitleView:[PEUIUtils labelWithKey:_screenTitle
                                                         font:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]
                                              backgroundColor:[UIColor clearColor]
                                                    textColor:[UIColor blackColor]
                                          verticalTextPadding:0.0]];
}

@end
