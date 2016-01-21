//
//  FPCommonStatController.h
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 10/20/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PEObjc-Commons/PEUIToolkit.h>
#import "FPScreenToolkit.h"
#import <JBChartView/JBLineChartView.h>
#import "FPCommonStatControllerConstants.h"
#import <PELocal-DataUI/PELocalDataBaseController.h>

typedef NSUInteger(^FPSiblingEntityCount)(void);
typedef UIViewController *(^FPComparisonScreenMaker)(void);

@interface FPCommonStatController : PELocalDataBaseController <JBLineChartViewDelegate, JBLineChartViewDataSource>

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
                uitoolkit:(PEUIToolkit *)uitoolkit;

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
                uitoolkit:(PEUIToolkit *)uitoolkit;

@end
