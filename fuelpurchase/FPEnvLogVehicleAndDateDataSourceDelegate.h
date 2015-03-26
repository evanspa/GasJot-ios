//
//  FPEnvLogVehicleAndDateDataSourceDelegate.h
//  fuelpurchase
//
//  Created by Evans, Paul on 10/13/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <iFuelPurchase-Core/FPCoordinatorDao.h>
#import "FPScreenToolkit.h"

@interface FPEnvLogVehicleAndDateDataSourceDelegate : NSObject
<UITableViewDataSource, UITableViewDelegate>

#pragma mark - Initializers

- (id)initWithControllerCtx:(UIViewController *)controllerCtx
     defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle
             defaultLogDate:(NSDate *)defaultLogDate
      vehicleSelectedAction:(PEItemSelectedAction)vehicleSelectedAction
        logDatePickedAction:(void(^)(NSDate *))logDatePickedAction
             coordinatorDao:(FPCoordinatorDao *)coordDao
                       user:(FPUser *)user
              screenToolkit:(FPScreenToolkit *)screenToolkit
                      error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Properties

@property (nonatomic) FPVehicle *selectedVehicle;

@property (nonatomic) NSDate *pickedLogDate;

@end
