//
//  FPSplashController.h
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 9/10/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PEFuelPurchase-Model/FPCoordinatorDao.h>
#import <PEObjc-Commons/PEUIToolkit.h>
#import "FPScreenToolkit.h"
#import "iCarousel.h"
#import <PELocal-DataUI/PECustomController.h>

@interface FPSplashController : PECustomController <iCarouselDataSource, iCarouselDelegate>

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<FPCoordinatorDao>)coordDao
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(FPScreenToolkit *)screenToolkit
           letsGoButtonEnabled:(BOOL)letsGoButtonEnabled;

@end
