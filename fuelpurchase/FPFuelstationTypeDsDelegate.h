//
//  FPFuelstationTypeDsDelegate.h
//  Gas Jot
//
//  Created by Paul Evans on 12/22/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PELocal-Data/PELMDefs.h>
#import "PEUIDefs.h"

@class FPFuelStationType;
@class FPScreenToolkit;

@interface FPFuelstationTypeDsDelegate : NSObject <UITableViewDataSource, UITableViewDelegate>

#pragma mark - Initializers

- (id)initWithControllerCtx:(UIViewController *)controllerCtx
                     fsType:(FPFuelStationType *)fsType
       fsTypeSelectedAction:(PEItemSelectedAction)fsTypeSelectedAction
displayDisclosureIndicators:(BOOL)displayDisclosureIndicators
             coordinatorDao:(id<FPCoordinatorDao>)coordDao
                       user:(FPUser *)user
              screenToolkit:(FPScreenToolkit *)screenToolkit
                      error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Properties

@property (nonatomic) FPFuelStationType *selectedFsType;

@end
