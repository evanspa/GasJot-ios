//
//  FPChangelog.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 7/26/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPChangelog.h"

@implementation FPChangelog {
  NSMutableArray *_vehicles;
  NSMutableArray *_fuelStations;
  NSMutableArray *_fuelPurchaseLogs;
  NSMutableArray *_environmentLogs;
}

#pragma mark - Initializers

- (id)initWithUpdatedAt:(NSDate *)updatedAt {
  self = [super initWithUpdatedAt:updatedAt];
  if (self) {
    _vehicles = [NSMutableArray array];
    _fuelStations = [NSMutableArray array];
    _fuelPurchaseLogs = [NSMutableArray array];
    _environmentLogs = [NSMutableArray array];
  }
  return self;
}

#pragma mark - Methods

- (void)addVehicle:(FPVehicle *)vehicle {
  [_vehicles addObject:vehicle];
}

- (void)addFuelStation:(FPFuelStation *)fuelStation {
  [_fuelStations addObject:fuelStation];
}

- (void)addFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog {
  [_fuelPurchaseLogs addObject:fuelPurchaseLog];
}

- (void)addEnvironmentLog:(FPEnvironmentLog *)environmentLog {
  [_environmentLogs addObject:environmentLog];
}

- (NSArray *)vehicles {
  return _vehicles;
}

- (NSArray *)fuelStations {
  return _fuelStations;
}

- (NSArray *)fuelPurchaseLogs {
  return _fuelPurchaseLogs;
}

- (NSArray *)environmentLogs {
  return _environmentLogs;
}

@end
