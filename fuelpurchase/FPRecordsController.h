//
//  FPRecordsController.h
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 9/13/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PEFuelPurchase-Model/FPUser.h>
#import <PEFuelPurchase-Model/FPCoordinatorDao.h>
#import <PEObjc-Commons/PEUIToolkit.h>
#import "FPScreenToolkit.h"

@interface FPRecordsController : UIViewController

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(FPCoordinatorDao *)coordDao
                          user:(FPUser *)user
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(FPScreenToolkit *)screenToolkit;

@end
