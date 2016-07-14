//
//  FPChangelog.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 7/26/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <PELocal-Data/PEChangelog.h>

@class FPUser;
@class FPVehicle;
@class FPFuelStation;
@class FPFuelPurchaseLog;
@class FPEnvironmentLog;

@interface FPChangelog : PEChangelog

#pragma mark - Initializers

- (id)initWithUpdatedAt:(NSDate *)updatedAt;

#pragma mark - Methods

- (void)addVehicle:(FPVehicle *)vehicle;

- (void)addFuelStation:(FPFuelStation *)fuelStation;

- (void)addFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog;

- (void)addEnvironmentLog:(FPEnvironmentLog *)environmentLog;

- (NSArray *)vehicles;

- (NSArray *)fuelStations;

- (NSArray *)fuelPurchaseLogs;

- (NSArray *)environmentLogs;

@end
