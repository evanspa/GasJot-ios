//
//  FPCommonStatComparisonController.m
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 10/20/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PEObjc-Commons/PEUIToolkit.h>
#import "FPScreenToolkit.h"
#import "FPCommonStatControllerConstants.h"

typedef NSArray *(^FPEntitiesToCompareBlk)(void);

@interface FPCommonStatComparisonController : UIViewController

#pragma mark - Initializers

- (id)initWithScreenTitle:(NSString *)screenTitle
               headerText:(NSString *)headerText
            entityNameBlk:(FPEntityNameBlk)entityNameBlk
                   entity:(id)entity
     entitiesToCompareBlk:(FPEntitiesToCompareBlk)entitiesToCompareBlk
      alltimeAggregateBlk:(FPAlltimeAggregate)alltimeAggregateBlk
        valueFormatterBlk:(FPValueFormatter)valueFormatterBlk
                uitoolkit:(PEUIToolkit *)uitoolkit;

@end
