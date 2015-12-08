//
//  FPCommonStatsLaunchController.h
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 10/18/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PEObjc-Commons/PEUIToolkit.h>
#import "FPScreenToolkit.h"
#import "FPCommonStatControllerConstants.h"
#import "PECustomController.h"

@interface FPCommonStatsLaunchController : PECustomController

#pragma mark - Initializers

- (id)initWithScreenTitle:(NSString *)screenTitle
      entityTypeLabelText:(NSString *)entityTypeLabelText
            entityNameBlk:(FPEntityNameBlk)entityNameBlk
                   entity:(id)entity
     statLaunchButtonsBlk:(NSArray *(^)(void))statLaunchButtonsBlk
                uitoolkit:(PEUIToolkit *)uitoolkit;

@end
