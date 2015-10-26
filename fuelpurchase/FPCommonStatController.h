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

typedef NSDecimalNumber *(^FPAlltimeAggregate)(id);
typedef NSDecimalNumber *(^FPYearToDateAggregate)(id);
typedef NSDecimalNumber *(^FPLastYearAggregate)(id);

typedef NSArray *(^FPAlltimeDataset)(id);
typedef NSArray *(^FPYearToDateDataset)(id);
typedef NSArray *(^FPLastYearDataset)(id);

typedef NSInteger(^FPSiblingEntityCount)(void);
typedef UIViewController *(^FPComparisonScreenMaker)(void);

@interface FPCommonStatController : UIViewController <JBLineChartViewDelegate, JBLineChartViewDataSource>

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
                uitoolkit:(PEUIToolkit *)uitoolkit;

@end
