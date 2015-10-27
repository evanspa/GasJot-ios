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

@interface FPCommonStatsLaunchController : UIViewController

#pragma mark - Initializers

- (id)initWithScreenTitle:(NSString *)screenTitle
      entityTypeLabelText:(NSString *)entityTypeLabelText
            entityNameBlk:(FPEntityNameBlk)entityNameBlk
                   entity:(id)entity
        statLaunchButtons:(NSArray *)statLaunchButtons
                uitoolkit:(PEUIToolkit *)uitoolkit;

@end
