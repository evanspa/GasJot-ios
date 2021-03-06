//
//  FPFpLogVehicleFuelStationDateDataSourceAndDelegate.h
//  fuelpurchase
//
//  Created by Evans, Paul on 10/13/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PEFuelPurchase-Model/FPCoordinatorDao.h>
#import "FPScreenToolkit.h"

@interface FPFpLogVehicleFuelStationDateDataSourceAndDelegate : NSObject
<UITableViewDataSource, UITableViewDelegate>

#pragma mark - Initializers

- (id)initWithControllerCtx:(UIViewController *)controllerCtx
                    vehicle:(FPVehicle *)vehicle
                fuelstation:(FPFuelStation *)fuelstation
                    logDate:(NSDate *)logDate
      vehicleSelectedAction:(PEItemSelectedAction)vehicleSelectedAction
  fuelStationSelectedAction:(PEItemSelectedAction)fuelStationSelectedAction
        logDatePickedAction:(void(^)(NSDate *))logDatePickedAction
displayDisclosureIndicators:(BOOL)displayDisclosureIndicators
             coordinatorDao:(id<FPCoordinatorDao>)coordDao
                       user:(FPUser *)user
              screenToolkit:(FPScreenToolkit *)screenToolkit
                      error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Properties

@property (nonatomic) FPVehicle *selectedVehicle;

@property (nonatomic) FPFuelStation *selectedFuelStation;

@property (nonatomic) NSDate *pickedLogDate;

@end
