//
//  FPEditsInProgressController.h
//  fuelpurchase
//
//  Created by Evans, Paul on 9/15/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <UIKit/UIKit.h>
#import <PEFuelPurchase-Model/FPUser.h>
#import <PEFuelPurchase-Model/FPCoordinatorDao.h>
#import <PEAppTransaction-Logger/TLTransactionManager.h>
#import <PEObjc-Commons/PEUIToolkit.h>
#import "FPScreenToolkit.h"

@interface FPEditsInProgressController : UIViewController

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(FPCoordinatorDao *)coordDao
                          user:(FPUser *)user
            transactionManager:(TLTransactionManager *)txnMgr
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(FPScreenToolkit *)screenToolkit;

@end
