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

@implementation FPCommonStatComparisonController {
  FPCoordinatorDao *_coordDao;
  PEUIToolkit *_uitoolkit;
  NSString *_screenTitle;
  FPEntityNameBlk _entityName;
  id _entity;
  UIView *_comparisonTable;
  NSString *_headerText;
  FPEntitiesToCompareBlk _entitiesToCompareBlk;
  FPAlltimeAggregate _alltimeAggregateBlk;
  FPValueFormatter _valueFormatterBlk;
}

#pragma mark - Initializers

- (id)initWithScreenTitle:(NSString *)screenTitle
               headerText:(NSString *)headerText
            entityNameBlk:(FPEntityNameBlk)entityNameBlk
                   entity:(id)entity
     entitiesToCompareBlk:(FPEntitiesToCompareBlk)entitiesToCompareBlk
      alltimeAggregateBlk:(FPAlltimeAggregate)alltimeAggregateBlk
        valueFormatterBlk:(FPValueFormatter)valueFormatterBlk
                uitoolkit:(PEUIToolkit *)uitoolkit {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _screenTitle = screenTitle;
    _headerText = headerText;
    _entityName = entityNameBlk;
    _entity = entity;
    _entitiesToCompareBlk = entitiesToCompareBlk;
    _alltimeAggregateBlk = alltimeAggregateBlk;
    _valueFormatterBlk = valueFormatterBlk;
    _uitoolkit = uitoolkit;
  }
  return self;
}


#pragma mark - Helpers

- (UIView *)makeComparisonTable {
  NSMutableArray *rowData = [NSMutableArray array];
  NSMutableArray *nilRowData = [NSMutableArray array];
  NSArray *entities = _entitiesToCompareBlk();
  for (id entity in entities) {
    NSDecimalNumber *statValue = _alltimeAggregateBlk(entity);
    id entityName;
    if (_entity && [entity isEqual:_entity]) {
      entityName = [PEUIUtils attributedTextWithTemplate:@"%@"
                                             textToAccent:_entityName(entity)
                                           accentTextFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]
                                          accentTextColor:[UIColor fpAppBlue]];
    } else {
      entityName = _entityName(entity);
    }
    if (statValue) {
      [rowData addObject:@[entityName, _valueFormatterBlk(statValue)]];
    } else {
      [nilRowData addObject:@[entityName, FPCommonStatComparisonTextIfNilStat]];
    }
  }
  [rowData sortUsingComparator:^NSComparisonResult(NSArray *o1, NSArray *o2) {
    NSDecimalNumber *v1 = o1[1];
    NSDecimalNumber *v2 = o2[1];
    return [v1 compare:v2];
  }];
  return [PEUIUtils tablePanelWithRowData:[rowData arrayByAddingObjectsFromArray:nilRowData]
                                uitoolkit:_uitoolkit
                               parentView:self.view];
}

#pragma mark - View controller lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  [[self navigationItem] setTitleView:[PEUIUtils labelWithKey:_screenTitle
                                                         font:[UIFont systemFontOfSize:14.0]
                                              backgroundColor:[UIColor clearColor]
                                                    textColor:[UIColor blackColor]
                                          verticalTextPadding:0.0]];
  UIView *header = [FPUIUtils headerPanelWithText:_headerText relativeToView:self.view];
  _comparisonTable = [self makeComparisonTable];
  
  // place the views
  [PEUIUtils placeView:header atTopOf:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:80.0 hpadding:8.0];
  [PEUIUtils placeView:_comparisonTable
                 below:header
                  onto:self.view
         withAlignment:PEUIHorizontalAlignmentTypeLeft
  alignmentRelativeToView:self.view
              vpadding:8.0
              hpadding:0.0];
  
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  // remove the views
  CGRect comparisonTableFrame = _comparisonTable.frame;
  [_comparisonTable removeFromSuperview];
  
  // refresh their data
  _comparisonTable = [self makeComparisonTable];
  
  // re-add them
  _comparisonTable.frame = comparisonTableFrame;
  [self.view addSubview:_comparisonTable];
}

@end
