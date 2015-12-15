//
//  FPSettingsController.h
//  fuelpurchase
//
//  Created by Evans, Paul on 9/15/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PEFuelPurchase-Model/FPUser.h>
#import <PEFuelPurchase-Model/FPCoordinatorDao.h>
#import <PEObjc-Commons/PEUIToolkit.h>
#import "FPScreenToolkit.h"
#import "PECustomController.h"

@interface FPSettingsController : PECustomController <MBProgressHUDDelegate>

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<FPCoordinatorDao>)coordDao
                          user:(FPUser *)user
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(FPScreenToolkit *)screenToolkit;

@end
