//
//  FPLocateNearbyGasController.h
//  Gas Jot
//
//  Created by Paul Evans on 12/31/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

@import UIKit;
@import CoreLocation;

#import <PEFuelPurchase-Model/FPCoordinatorDao.h>
#import <PEObjc-Commons/PEUIToolkit.h>
#import "FPScreenToolkit.h"
#import "PECustomController.h"

@interface FPLocateNearbyGasController : PECustomController <MBProgressHUDDelegate>

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<FPCoordinatorDao>)coordDao
               currentLocation:(CLLocation *)currentLocation
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(FPScreenToolkit *)screenToolkit;

@end
