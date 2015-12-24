//
//  FPEnvLogVehicleAndDateDataSourceDelegate.h
//  fuelpurchase
//
//  Created by Evans, Paul on 10/13/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PELocal-Data/PELMDefs.h>
#import "PEUIDefs.h"

@class FPUser;
@class FPVehicle;
@class FPScreenToolkit;
@protocol FPCoordinatorDao;

@interface FPEnvLogVehicleAndDateDataSourceDelegate : NSObject
<UITableViewDataSource, UITableViewDelegate>

#pragma mark - Initializers

- (id)initWithControllerCtx:(UIViewController *)controllerCtx
                    vehicle:(FPVehicle *)vehicle
                    logDate:(NSDate *)logDate
      vehicleSelectedAction:(PEItemSelectedAction)vehicleSelectedAction
        logDatePickedAction:(void(^)(NSDate *))logDatePickedAction
displayDisclosureIndicators:(BOOL)displayDisclosureIndicators
             coordinatorDao:(id<FPCoordinatorDao>)coordDao
                       user:(FPUser *)user
              screenToolkit:(FPScreenToolkit *)screenToolkit
                      error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Properties

@property (nonatomic) FPVehicle *selectedVehicle;

@property (nonatomic) NSDate *pickedLogDate;

@end
