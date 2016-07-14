//
//  FPStats.m
//  PEFuelPurchase-Model
//
//  Created by Paul Evans on 10/10/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "FPStats.h"

#import <PEObjc-Commons/PEUtils.h>

#import "FPFuelPurchaseLog.h"
#import "FPEnvironmentLog.h"
#import "FPLocalDao.h"

typedef id (^FPValueBlock)(void);

@implementation FPStats {
  id<FPLocalDao> _localDao;
  PELMDaoErrorBlk _errorBlk;
}

#pragma mark - Initializers

- (id)initWithLocalDao:(id<FPLocalDao>)localDao errorBlk:(PELMDaoErrorBlk)errorBlk {
  self = [super init];
  if (self) {
    _localDao = localDao;
    _errorBlk = errorBlk;
  }
  return self;
}

#pragma mark - Helpers

- (NSDecimalNumber *)avgValueForItems:(NSArray *)items
                        itemValidator:(BOOL(^)(id))itemValidator
                          accumulator:(NSDecimalNumber *(^)(id))accumulator {
  NSInteger itemsCount = [items count];
  if (itemsCount > 0) {
    NSInteger numRelevantItems = 0;
    NSDecimalNumber *total = [NSDecimalNumber zero];
    for (id item in items) {
      if (itemValidator(item)) {
        NSDecimalNumber *val = accumulator(item);
        if (val) {
          numRelevantItems++;
          total = [total decimalNumberByAdding:val];
        }
      }
    }
    if (numRelevantItems > 0) {
      return [total decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithInteger:numRelevantItems]];
    }
  }
  return nil;
}

- (NSDecimalNumber *)avgValueForDataset:(NSArray *)dataset
                            accumulator:(NSDecimalNumber *(^)(id))accumulator {
  return [self avgValueForItems:dataset
                  itemValidator:^(NSArray *dp){return YES;}
                    accumulator:^(NSArray *dp){return accumulator(dp[1]);}];
}

- (NSDecimalNumber *)avgValueForIntegerDataset:(NSArray *)dataset {
  return [self avgValueForDataset:dataset
                      accumulator:^(NSNumber *val) {return [[NSDecimalNumber alloc] initWithInteger:val.integerValue];}];
}

- (NSDecimalNumber *)avgValueForDecimalDataset:(NSArray *)dataset {
  return [self avgValueForDataset:dataset accumulator:^(NSDecimalNumber *val) {return val;}];
}

- (NSDecimalNumber *)minMaxValueForDataset:(NSArray *)dataset
                                comparator:(NSComparisonResult(^)(NSArray *, NSArray *))comparator {
  NSInteger count = [dataset count];
  if (count > 1) {
    NSArray *sortedDataset = [dataset sortedArrayUsingComparator:comparator];
    return sortedDataset[0][1];
  } else if (count == 1) {
    return dataset[0][1];
  }
  return nil;
}

- (NSDecimalNumber *)minValueForDataset:(NSArray *)dataset {
  return [self minMaxValueForDataset:dataset comparator:^NSComparisonResult(NSArray *dp1, NSArray *dp2) {
    return [dp1[1] compare:dp2[1]];
  }];
}

- (NSDecimalNumber *)maxValueForDataset:(NSArray *)dataset {
  return [self minMaxValueForDataset:dataset comparator:^NSComparisonResult(NSArray *dp1, NSArray *dp2) {
    return [dp2[1] compare:dp1[1]];
  }];
}

- (NSDecimalNumber *)totalSpentFromFplogs:(NSArray *)fplogs {
  if (fplogs.count > 0) {
    NSDecimalNumber *total = [NSDecimalNumber zero];
    for (FPFuelPurchaseLog *fplog in fplogs) {
      if (![PEUtils isNil:fplog.numGallons] && ![PEUtils isNil:fplog.gallonPrice]) {
        total = [total decimalNumberByAdding:[fplog.numGallons decimalNumberByMultiplyingBy:fplog.gallonPrice]];
      }
    }
    return total;
  }
  return nil;
}

- (NSDate *)oneYearAgoFromDate:(NSDate *)fromDate {
  return [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitYear value:-1 toDate:fromDate options:0];
}

- (NSDate *)oneYearAgoFromNow {
  return [self oneYearAgoFromDate:[NSDate date]];
}

- (NSArray *)dataSetForEntity:(id)entity
                     valueBlk:(id(^)(NSDate *, NSDate *))valueBlk
                         year:(NSInteger)year
                   startMonth:(NSInteger)startMonth
                     endMonth:(NSInteger)endMonth
                     calendar:(NSCalendar *)calendar
                   beforeDate:(NSDate *)beforeDate {
  NSMutableArray *dataset = [NSMutableArray array];
  for (NSInteger i = startMonth; i <= endMonth; i++) {
    NSDate *firstDayOfMonth = [PEUtils firstDayOfYear:year month:i calendar:calendar];
    if ([firstDayOfMonth compare:beforeDate] == NSOrderedAscending) {
      NSDate *firstDateOfNextMonth = [calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:firstDayOfMonth options:0];
      id value = valueBlk(firstDateOfNextMonth, firstDayOfMonth);
      if (value) {
        [dataset addObject:@[firstDayOfMonth, value]];
      }
    }
  }
  return dataset;
}

- (NSArray *)dataSetForEntity:(id)entity
               monthOfDataBlk:(NSArray *(^)(NSInteger, NSInteger, NSInteger, NSCalendar *))monthOfDataBlk
                   beforeDate:(NSDate *)beforeDate
                onOrAfterDate:(NSDate *)onOrAfterDate {
  NSMutableArray *dataset = [NSMutableArray array];
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDateComponents *beforeDateComps = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:beforeDate];
  NSDateComponents *onOrAfterDateComps = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:onOrAfterDate];
  NSInteger startYear = onOrAfterDateComps.year;
  NSInteger endYear = beforeDateComps.year;
  for (NSInteger i = startYear; i <= endYear; i++) {
    NSInteger startMonth;
    if (i == startYear) {
      startMonth = onOrAfterDateComps.month;
    } else {
      startMonth = 1;
    }
    NSInteger endMonth;
    if (i == endYear) {
      endMonth = beforeDateComps.month;
    } else {
      endMonth = 12;
    }
    NSDate *startMonthDate = [PEUtils dateFromCalendar:calendar day:1 month:startMonth year:i];
    if ([startMonthDate compare:beforeDate] == NSOrderedAscending) {
      [dataset addObjectsFromArray:monthOfDataBlk(i, startMonth, endMonth, calendar)];
    }
  }
  return dataset;
}

- (NSDecimalNumber *)avgReportedMphFromEnvlogs:(NSArray *)envlogs {
  return [self avgValueForItems:envlogs
                  itemValidator:^BOOL(FPEnvironmentLog *envlog) { return ![PEUtils isNil:envlog.reportedAvgMph]; }
                    accumulator:^NSDecimalNumber *(FPEnvironmentLog *envlog) { return envlog.reportedAvgMph; }];
}

- (NSDecimalNumber *)avgReportedMpgFromEnvlogs:(NSArray *)envlogs {
  return [self avgValueForItems:envlogs
                  itemValidator:^BOOL(FPEnvironmentLog *envlog) { return ![PEUtils isNil:envlog.reportedAvgMpg]; }
                    accumulator:^NSDecimalNumber *(FPEnvironmentLog *envlog) { return envlog.reportedAvgMpg; }];
}

- (NSDecimalNumber *)avgGallonPriceFromFplogs:(NSArray *)fplogs {
  return [self avgValueForItems:fplogs
                  itemValidator:^BOOL(FPFuelPurchaseLog *fplog) { return ![PEUtils isNil:fplog.gallonPrice]; }
                    accumulator:^NSDecimalNumber *(FPFuelPurchaseLog *fplog) { return fplog.gallonPrice; }];
}

- (NSDecimalNumber *)avgGasCostPerMileForUser:(FPUser *)user
                                   beforeDate:(NSDate *)beforeDate
                                onOrAfterDate:(NSDate *)onOrAfterDate {
  return [self avgValueForItems:[_localDao vehiclesForUser:user error:_errorBlk]
                  itemValidator:^BOOL(FPVehicle *vehicle) { return YES; }
                    accumulator:^NSDecimalNumber *(FPVehicle *vehicle) {
                      return [self avgGasCostPerMileForVehicle:vehicle beforeDate:beforeDate onOrAfterDate:onOrAfterDate];
                    }];
}

- (NSDecimalNumber *)avgGasCostPerMileForVehicle:(FPVehicle *)vehicle
                                      beforeDate:(NSDate *)beforeDate
                                   onOrAfterDate:(NSDate *)onOrAfterDate {
  FPEnvironmentLog *firstOdometerLog = [_localDao firstOdometerLogForVehicle:vehicle
                                                                  beforeDate:beforeDate
                                                               onOrAfterDate:onOrAfterDate
                                                                       error:_errorBlk];
  if (firstOdometerLog) {
    NSDecimalNumber *milesDriven = [self milesRecordedForVehicle:vehicle
                                                      beforeDate:beforeDate
                                                   onOrAfterDate:onOrAfterDate];
    NSDecimalNumber *totalSpentOnGas = [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                                                      beforeDate:beforeDate
                                                                                                       afterDate:firstOdometerLog.logDate
                                                                                                           error:_errorBlk]];
    return [self costPerMileForMilesDriven:milesDriven totalSpentOnGas:totalSpentOnGas];
  }
  return nil;
}

- (NSArray *)mergeDataSetsForUser:(FPUser *)user
                 childEntitiesBlk:(NSArray *(^)(void))childEntitiesBlk
         datasetForChildEntityBlk:(NSArray *(^)(id))datasetForChildEntityBlk
          entityDatapointValueBlk:(NSDecimalNumber *(^)(id))entityDatapointValueBlk {
  NSMutableDictionary *allEntitiesDatapointsDict = [NSMutableDictionary dictionary];
  NSArray *entities = childEntitiesBlk();
  if (entities.count > 0) {
    for (FPVehicle *entity in entities) {
      NSArray *entityDatapoints = datasetForChildEntityBlk(entity);
      for (NSArray *entityDatapoint in entityDatapoints) {
        NSDate *entityDatapointDate = entityDatapoint[0];
        NSDecimalNumber *allEntitiesDatapointVal = allEntitiesDatapointsDict[entityDatapointDate];
        if (allEntitiesDatapointVal != nil) {
          NSDecimalNumber *entityDatapointVal = entityDatapointValueBlk(entityDatapoint[1]);
          NSDecimalNumber *tmpTotalDatapointVal = [allEntitiesDatapointVal decimalNumberByAdding:entityDatapointVal];
          allEntitiesDatapointsDict[entityDatapointDate] = [tmpTotalDatapointVal decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithInteger:2]];
        } else {
          allEntitiesDatapointsDict[entityDatapointDate] = entityDatapointValueBlk(entityDatapoint[1]);
        }
      }
    }
    NSArray *keys = [allEntitiesDatapointsDict allKeys];
    NSMutableArray *allEntitiesDataSet = [NSMutableArray arrayWithCapacity:keys.count];
    for (NSDate *entryDate in keys) {
      [allEntitiesDataSet addObject:@[entryDate, allEntitiesDatapointsDict[entryDate]]];
    }
    return [allEntitiesDataSet sortedArrayUsingComparator:^NSComparisonResult(NSArray *dp1, NSArray *dp2) {
      return [dp1[0] compare:dp2[0]];
    }];
  }
  return @[];
}

- (NSArray *)daysBetweenFillupsDataSetForUser:(FPUser *)user
                                   beforeDate:(NSDate *)beforeDate
                                onOrAfterDate:(NSDate *)onOrAfterDate
                                     calendar:(NSCalendar *)calendar {
  return [self mergeDataSetsForUser:user
                   childEntitiesBlk:^{ return [_localDao vehiclesForUser:user error:_errorBlk]; }
           datasetForChildEntityBlk:^(FPVehicle *vehicle) { return [self daysBetweenFillupsDataSetForVehicle:vehicle
                                                                                                  beforeDate:beforeDate
                                                                                               onOrAfterDate:onOrAfterDate
                                                                                                    calendar:calendar]; }
            entityDatapointValueBlk:^(NSNumber *numDays) {return [[NSDecimalNumber alloc] initWithInteger:numDays.integerValue];}];
}

- (NSArray *)daysBetweenFillupsDataSetForVehicle:(FPVehicle *)vehicle
                                      beforeDate:(NSDate *)beforeDate
                                   onOrAfterDate:(NSDate *)onOrAfterDate
                                        calendar:(NSCalendar *)calendar {
  NSArray *fplogs = [_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                        beforeDate:beforeDate
                                                     onOrAfterDate:onOrAfterDate
                                                             error:_errorBlk];
  fplogs = [fplogs sortedArrayUsingComparator:^NSComparisonResult(FPFuelPurchaseLog *fplog1, FPFuelPurchaseLog *fplog2) {
    return [fplog1.purchasedAt compare:fplog2.purchasedAt];
  }];
  NSMutableArray *dataset = [NSMutableArray array];
  NSInteger numFplogs = [fplogs count];
  if (numFplogs > 0) {
    for (NSInteger i = 0; i < numFplogs; i++) {
      if (i + 1 < numFplogs) {
        FPFuelPurchaseLog *log1 = fplogs[i];
        FPFuelPurchaseLog *log2 = fplogs[i+1];
        NSDateComponents *components = [calendar components:NSCalendarUnitDay fromDate:log1.purchasedAt toDate:log2.purchasedAt options:0];
        [dataset addObject:@[log2.purchasedAt, @([components day])]];
      }
    }
  }
  return dataset;
}

- (NSArray *)avgDaysBetweenFillupsDataSetForVehicle:(FPVehicle *)vehicle
                                         beforeDate:(NSDate *)beforeDate
                                      onOrAfterDate:(NSDate *)onOrAfterDate
                                           calendar:(NSCalendar *)calendar {
  NSMutableDictionary *monthlyData = [NSMutableDictionary dictionary];
  NSArray *dataset = [self daysBetweenFillupsDataSetForVehicle:vehicle beforeDate:beforeDate onOrAfterDate:onOrAfterDate calendar:calendar];
  for (NSArray *dp in dataset) {
    NSDate *date = dp[0];
    NSDateComponents *comps = [calendar components:NSCalendarUnitMonth|NSCalendarUnitYear fromDate:date];
    comps.day = 1;
    NSDate *startOfMonth = [calendar dateFromComponents:comps];
    NSMutableArray *datapoints = monthlyData[startOfMonth];
    if (datapoints == nil) {
      datapoints = [NSMutableArray array];
      monthlyData[startOfMonth] = datapoints;
    }
    [datapoints addObject:dp[1]];
  }
  NSArray *keys = [monthlyData allKeys];
  NSMutableArray *avgDaysBetweenFillups = [NSMutableArray arrayWithCapacity:keys.count];
  for (NSDate *startOfMonth in keys) {
    NSArray *numDaysValues = monthlyData[startOfMonth];
    NSDecimalNumber *total = [NSDecimalNumber zero];
    for (NSNumber *numDaysVal in numDaysValues) {
      total = [total decimalNumberByAdding:[[NSDecimalNumber alloc] initWithInteger:numDaysVal.integerValue]];
    }
    [avgDaysBetweenFillups addObject:@[startOfMonth, [total decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithInteger:numDaysValues.count]]]];
  }
  return [avgDaysBetweenFillups sortedArrayUsingComparator:^NSComparisonResult(NSArray *obj1, NSArray *obj2) {
    return [obj1[0] compare:obj2[0]];
  }];
}

- (NSArray *)avgDaysBetweenFillupsDataSetForUser:(FPUser *)user
                                      beforeDate:(NSDate *)beforeDate
                                   onOrAfterDate:(NSDate *)onOrAfterDate
                                        calendar:(NSCalendar *)calendar {
  return [self mergeDataSetsForUser:user
                   childEntitiesBlk:^{ return [_localDao vehiclesForUser:user error:_errorBlk]; }
           datasetForChildEntityBlk:^(FPVehicle *vehicle) { return [self avgDaysBetweenFillupsDataSetForVehicle:vehicle
                                                                                                     beforeDate:beforeDate
                                                                                                  onOrAfterDate:onOrAfterDate
                                                                                                       calendar:calendar]; }
            entityDatapointValueBlk:^(NSDecimalNumber *avgNumDays) {return avgNumDays;}];
}

- (NSArray *)avgGasCostPerMileDataSetForUser:(FPUser *)user
                                  beforeDate:(NSDate *)beforeDate
                               onOrAfterDate:(NSDate *)onOrAfterDate {
  return [self mergeDataSetsForUser:user
                   childEntitiesBlk:^{ return [_localDao vehiclesForUser:user error:_errorBlk]; }
           datasetForChildEntityBlk:^(FPVehicle *vehicle) { return [self avgGasCostPerMileDataSetForVehicle:vehicle
                                                                                                 beforeDate:beforeDate
                                                                                              onOrAfterDate:onOrAfterDate]; }
            entityDatapointValueBlk:^(NSDecimalNumber *gasCostPerMile) {return gasCostPerMile;}];
}

- (NSArray *)avgGasCostPerMileDataSetForVehicle:(FPVehicle *)vehicle
                                     beforeDate:(NSDate *)beforeDate
                                  onOrAfterDate:(NSDate *)onOrAfterDate {
  return [self dataSetForEntity:vehicle
                 monthOfDataBlk:^NSArray *(NSInteger year, NSInteger startMonth, NSInteger endMonth, NSCalendar *cal) {
                   return [self dataSetForEntity:vehicle
                                        valueBlk:^id(NSDate *firstDateOfNextMonth, NSDate *firstDayOfMonth) {
                                          return [self avgGasCostPerMileForVehicle:vehicle beforeDate:firstDateOfNextMonth onOrAfterDate:firstDayOfMonth];
                                        }
                                            year:year
                                      startMonth:startMonth
                                        endMonth:endMonth
                                        calendar:cal
                                      beforeDate:beforeDate];
                 }
                     beforeDate:beforeDate
                  onOrAfterDate:onOrAfterDate];
}

- (NSArray *)spentOnGasDataSetForUser:(FPUser *)user
                           beforeDate:(NSDate *)beforeDate
                        onOrAfterDate:(NSDate *)onOrAfterDate {
  return [self dataSetForEntity:user
                 monthOfDataBlk:^NSArray *(NSInteger year, NSInteger startMonth, NSInteger endMonth, NSCalendar *cal) {
                   return [self dataSetForEntity:user
                                        valueBlk:^id(NSDate *firstDateOfNextMonth, NSDate *firstDayOfMonth) {
                                          return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user
                                                                                                             beforeDate:firstDateOfNextMonth
                                                                                                          onOrAfterDate:firstDayOfMonth
                                                                                                                  error:_errorBlk]];
                                        }
                                            year:year
                                      startMonth:startMonth
                                        endMonth:endMonth
                                        calendar:cal
                                      beforeDate:beforeDate];
                 }
                     beforeDate:beforeDate
                  onOrAfterDate:onOrAfterDate];
}

- (NSArray *)spentOnGasDataSetForVehicle:(FPVehicle *)vehicle
                              beforeDate:(NSDate *)beforeDate
                           onOrAfterDate:(NSDate *)onOrAfterDate {
  return [self dataSetForEntity:vehicle
                 monthOfDataBlk:^NSArray *(NSInteger year, NSInteger startMonth, NSInteger endMonth, NSCalendar *cal) {
                   return [self dataSetForEntity:vehicle
                                        valueBlk:^id(NSDate *firstDateOfNextMonth, NSDate *firstDayOfMonth) {
                                          return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                                                                beforeDate:firstDateOfNextMonth
                                                                                                             onOrAfterDate:firstDayOfMonth
                                                                                                                     error:_errorBlk]];
                                        }
                                            year:year
                                      startMonth:startMonth
                                        endMonth:endMonth
                                        calendar:cal
                                      beforeDate:beforeDate];
                 }
                     beforeDate:beforeDate
                  onOrAfterDate:onOrAfterDate];
}

- (NSArray *)spentOnGasDataSetForFuelstation:(FPFuelStation *)fuelstation
                                  beforeDate:(NSDate *)beforeDate
                               onOrAfterDate:(NSDate *)onOrAfterDate {
  return [self dataSetForEntity:fuelstation
                 monthOfDataBlk:^NSArray *(NSInteger year, NSInteger startMonth, NSInteger endMonth, NSCalendar *cal) {
                   return [self dataSetForEntity:fuelstation
                                        valueBlk:^id(NSDate *firstDateOfNextMonth, NSDate *firstDayOfMonth) {
                                          return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation
                                                                                                                    beforeDate:firstDateOfNextMonth
                                                                                                                 onOrAfterDate:firstDayOfMonth
                                                                                                                         error:_errorBlk]];
                                        }
                                            year:year
                                      startMonth:startMonth
                                        endMonth:endMonth
                                        calendar:cal
                                      beforeDate:beforeDate];
                 }
                     beforeDate:beforeDate
                  onOrAfterDate:onOrAfterDate];
}

- (NSArray *)avgReportedMphDataSetForUser:(FPUser *)user
                               beforeDate:(NSDate *)beforeDate
                            onOrAfterDate:(NSDate *)onOrAfterDate {
  return [self mergeDataSetsForUser:user
                   childEntitiesBlk:^{ return [_localDao vehiclesForUser:user error:_errorBlk]; }
           datasetForChildEntityBlk:^(FPVehicle *vehicle) { return [self avgReportedMphDataSetForVehicle:vehicle
                                                                                              beforeDate:beforeDate
                                                                                           onOrAfterDate:onOrAfterDate]; }
            entityDatapointValueBlk:^(NSDecimalNumber *avgReportedMph) {return avgReportedMph;}];
}

- (NSArray *)avgReportedMphDataSetForVehicle:(FPVehicle *)vehicle
                                  beforeDate:(NSDate *)beforeDate
                               onOrAfterDate:(NSDate *)onOrAfterDate {
  return [self dataSetForEntity:vehicle
                 monthOfDataBlk:^NSArray *(NSInteger year, NSInteger startMonth, NSInteger endMonth, NSCalendar *cal) {
                   return [self dataSetForEntity:vehicle
                                        valueBlk:^id(NSDate *firstDateOfNextMonth, NSDate *firstDayOfMonth) {
                                          return [self avgReportedMphFromEnvlogs:[_localDao unorderedEnvironmentLogsForVehicle:vehicle
                                                                                                                    beforeDate:firstDateOfNextMonth
                                                                                                                 onOrAfterDate:firstDayOfMonth
                                                                                                                         error:_errorBlk]];
                                        }
                                            year:year
                                      startMonth:startMonth
                                        endMonth:endMonth
                                        calendar:cal
                                      beforeDate:beforeDate];
                 }
                     beforeDate:beforeDate
                  onOrAfterDate:onOrAfterDate];
}

- (NSArray *)avgReportedMpgDataSetForUser:(FPUser *)user
                               beforeDate:(NSDate *)beforeDate
                            onOrAfterDate:(NSDate *)onOrAfterDate {
  return [self mergeDataSetsForUser:user
                   childEntitiesBlk:^{ return [_localDao vehiclesForUser:user error:_errorBlk]; }
           datasetForChildEntityBlk:^(FPVehicle *vehicle) { return [self avgReportedMpgDataSetForVehicle:vehicle
                                                                                              beforeDate:beforeDate
                                                                                           onOrAfterDate:onOrAfterDate]; }
            entityDatapointValueBlk:^(NSDecimalNumber *avgReportedMpg) {return avgReportedMpg;}];
}

- (NSArray *)avgReportedMpgDataSetForVehicle:(FPVehicle *)vehicle
                                  beforeDate:(NSDate *)beforeDate
                               onOrAfterDate:(NSDate *)onOrAfterDate {
  return [self dataSetForEntity:vehicle
                 monthOfDataBlk:^NSArray *(NSInteger year, NSInteger startMonth, NSInteger endMonth, NSCalendar *cal) {
                   return [self dataSetForEntity:vehicle
                                        valueBlk:^id(NSDate *firstDateOfNextMonth, NSDate *firstDayOfMonth) {
                                          return [self avgReportedMpgFromEnvlogs:[_localDao unorderedEnvironmentLogsForVehicle:vehicle
                                                                                                                    beforeDate:firstDateOfNextMonth
                                                                                                                 onOrAfterDate:firstDayOfMonth
                                                                                                                         error:_errorBlk]];
                                        }
                                            year:year
                                      startMonth:startMonth
                                        endMonth:endMonth
                                        calendar:cal
                                      beforeDate:beforeDate];
                 }
                     beforeDate:beforeDate
                  onOrAfterDate:onOrAfterDate];
}

- (NSArray *)avgPricePerGallonDataSetWithEntity:(id)entity
                                     beforeDate:(NSDate *)beforeDate
                                  onOrAfterDate:(NSDate *)onOrAfterDate
                                   logsFetchBlk:(NSArray *(^)(NSDate *, NSDate *))logsFetchBlk {
  return [self dataSetForEntity:entity
                 monthOfDataBlk:^NSArray *(NSInteger year, NSInteger startMonth, NSInteger endMonth, NSCalendar *cal) {
                   return [self dataSetForEntity:entity
                                        valueBlk:^id(NSDate *firstDateOfNextMonth, NSDate *firstDayOfMonth) {
                                          return [self avgGallonPriceFromFplogs:logsFetchBlk(firstDateOfNextMonth, firstDayOfMonth)];
                                        }
                                            year:year
                                      startMonth:startMonth
                                        endMonth:endMonth
                                        calendar:cal
                                      beforeDate:beforeDate];
                 }
                     beforeDate:beforeDate
                  onOrAfterDate:onOrAfterDate];
}

- (NSArray *)avgPricePerGallonDataSetForUser:(FPUser *)user
                                  beforeDate:(NSDate *)beforeDate
                               onOrAfterDate:(NSDate *)onOrAfterDate
                                      octane:(NSNumber *)octane {
  return [self avgPricePerGallonDataSetWithEntity:user
                                       beforeDate:beforeDate
                                    onOrAfterDate:onOrAfterDate
                                     logsFetchBlk:^NSArray *(NSDate *firstDateOfNextMonth, NSDate *firstDayOfMonth) {
                                       return [_localDao unorderedFuelPurchaseLogsForUser:user
                                                                               beforeDate:firstDateOfNextMonth
                                                                            onOrAfterDate:firstDayOfMonth
                                                                                   octane:octane
                                                                                    error:_errorBlk];
                                     }];
}

- (NSArray *)avgPricePerGallonDataSetForUser:(FPUser *)user
                                  beforeDate:(NSDate *)beforeDate
                               onOrAfterDate:(NSDate *)onOrAfterDate {
  return [self avgPricePerGallonDataSetWithEntity:user
                                       beforeDate:beforeDate
                                    onOrAfterDate:onOrAfterDate
                                     logsFetchBlk:^NSArray *(NSDate *firstDateOfNextMonth, NSDate *firstDayOfMonth) {
                                       return [_localDao unorderedFuelPurchaseLogsForUser:user
                                                                               beforeDate:firstDateOfNextMonth
                                                                            onOrAfterDate:firstDayOfMonth
                                                                                    error:_errorBlk];
                                     }];
}

- (NSArray *)avgPricePerGallonDataSetForVehicle:(FPVehicle *)vehicle
                                     beforeDate:(NSDate *)beforeDate
                                  onOrAfterDate:(NSDate *)onOrAfterDate
                                         octane:(NSNumber *)octane {
  return [self avgPricePerGallonDataSetWithEntity:vehicle
                                       beforeDate:beforeDate
                                    onOrAfterDate:onOrAfterDate
                                     logsFetchBlk:^NSArray *(NSDate *firstDateOfNextMonth, NSDate *firstDayOfMonth) {
                                       return [_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                                  beforeDate:firstDateOfNextMonth
                                                                               onOrAfterDate:firstDayOfMonth
                                                                                      octane:octane
                                                                                       error:_errorBlk];
                                     }];
}

- (NSArray *)avgPricePerGallonDataSetForVehicle:(FPVehicle *)vehicle
                                     beforeDate:(NSDate *)beforeDate
                                  onOrAfterDate:(NSDate *)onOrAfterDate {
  return [self avgPricePerGallonDataSetWithEntity:vehicle
                                       beforeDate:beforeDate
                                    onOrAfterDate:onOrAfterDate
                                     logsFetchBlk:^NSArray *(NSDate *firstDateOfNextMonth, NSDate *firstDayOfMonth) {
                                       return [_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                                  beforeDate:firstDateOfNextMonth
                                                                               onOrAfterDate:firstDayOfMonth
                                                                                       error:_errorBlk];
                                     }];
}

- (NSArray *)avgPricePerGallonDataSetForFuelstation:(FPFuelStation *)fuelstation
                                         beforeDate:(NSDate *)beforeDate
                                      onOrAfterDate:(NSDate *)onOrAfterDate
                                             octane:(NSNumber *)octane {
  return [self avgPricePerGallonDataSetWithEntity:fuelstation
                                       beforeDate:beforeDate
                                    onOrAfterDate:onOrAfterDate
                                     logsFetchBlk:^NSArray *(NSDate *firstDateOfNextMonth, NSDate *firstDayOfMonth) {
                                       return [_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation
                                                                                      beforeDate:firstDateOfNextMonth
                                                                                   onOrAfterDate:firstDayOfMonth
                                                                                          octane:octane
                                                                                           error:_errorBlk];
                                     }];
}

- (NSArray *)avgPricePerGallonDataSetForFuelstation:(FPFuelStation *)fuelstation
                                         beforeDate:(NSDate *)beforeDate
                                      onOrAfterDate:(NSDate *)onOrAfterDate {
  return [self avgPricePerGallonDataSetWithEntity:fuelstation
                                       beforeDate:beforeDate
                                    onOrAfterDate:onOrAfterDate
                                     logsFetchBlk:^NSArray *(NSDate *firstDateOfNextMonth, NSDate *firstDayOfMonth) {
                                       return [_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation
                                                                                      beforeDate:firstDateOfNextMonth
                                                                                   onOrAfterDate:firstDayOfMonth
                                                                                           error:_errorBlk];
                                     }];
}

- (NSArray *)avgPricePerDieselGallonDataSetForUser:(FPUser *)user
                                        beforeDate:(NSDate *)beforeDate
                                     onOrAfterDate:(NSDate *)onOrAfterDate {
  return [self avgPricePerGallonDataSetWithEntity:user
                                       beforeDate:beforeDate
                                    onOrAfterDate:onOrAfterDate
                                     logsFetchBlk:^NSArray *(NSDate *firstDateOfNextMonth, NSDate *firstDayOfMonth) {
                                       return [_localDao unorderedDieselFuelPurchaseLogsForUser:user
                                                                                     beforeDate:firstDateOfNextMonth
                                                                                  onOrAfterDate:firstDayOfMonth
                                                                                          error:_errorBlk];
                                     }];
}

- (NSArray *)avgPricePerDieselGallonDataSetForVehicle:(FPVehicle *)vehicle
                                           beforeDate:(NSDate *)beforeDate
                                        onOrAfterDate:(NSDate *)onOrAfterDate {
  return [self avgPricePerGallonDataSetWithEntity:vehicle
                                       beforeDate:beforeDate
                                    onOrAfterDate:onOrAfterDate
                                     logsFetchBlk:^NSArray *(NSDate *firstDateOfNextMonth, NSDate *firstDayOfMonth) {
                                       return [_localDao unorderedDieselFuelPurchaseLogsForVehicle:vehicle
                                                                                        beforeDate:firstDateOfNextMonth
                                                                                     onOrAfterDate:firstDayOfMonth
                                                                                             error:_errorBlk];
                                     }];
}

- (NSArray *)avgPricePerDieselGallonDataSetForFuelstation:(FPFuelStation *)fuelstation
                                               beforeDate:(NSDate *)beforeDate
                                            onOrAfterDate:(NSDate *)onOrAfterDate {
  return [self avgPricePerGallonDataSetWithEntity:fuelstation
                                       beforeDate:beforeDate
                                    onOrAfterDate:onOrAfterDate
                                     logsFetchBlk:^NSArray *(NSDate *firstDateOfNextMonth, NSDate *firstDayOfMonth) {
                                       return [_localDao unorderedDieselFuelPurchaseLogsForFuelstation:fuelstation
                                                                                            beforeDate:firstDateOfNextMonth
                                                                                         onOrAfterDate:firstDayOfMonth
                                                                                                 error:_errorBlk];
                                     }];
}

- (NSDecimalNumber *)costPerMileForMilesDriven:(NSDecimalNumber *)milesDriven
                               totalSpentOnGas:(NSDecimalNumber *)totalSpentOnGas {
  if ([milesDriven compare:[NSDecimalNumber zero]] == NSOrderedSame) {
    // this means that the user has only 1 odometer log recorded, and thus
    // we can't do this computation
    return nil;
  } else {
    if ([totalSpentOnGas compare:[NSDecimalNumber zero]] == NSOrderedSame) {
      // we have odometer logs, but no gas logs
      return nil;
    }
  }
  return [totalSpentOnGas decimalNumberByDividingBy:milesDriven];
}

- (NSNumber *)daysSinceDate:(NSDate *)date {
  if (date) {
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return @([calendar components:NSCalendarUnitDay fromDate:date toDate:now options:0].day);
  }
  return nil;
}

- (NSNumber *)daysSinceGasLog:(FPFuelPurchaseLog *)gasLog {
  return [self daysSinceDate:gasLog.purchasedAt];
}

- (NSNumber *)daysSinceOdometerLog:(FPEnvironmentLog *)odometerLog {
  return [self daysSinceDate:odometerLog.logDate];
}

- (NSArray *)spentOnGasExcludingPartialMonthsDataSetWithStartDate:(NSDate *)startDate
                                                       datasetBlk:(NSArray *(^)(NSDate *, NSDate *))datasetBlk {
  if (startDate) {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSDateComponents *components = [calendar components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:now];
    [components setDay:1];
    NSDate *firstDayOfCurrentMonth = [calendar dateFromComponents:components];
    
    NSDate *startMonth;
    components = [calendar components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:startDate];
    if (components.day < 10) {
      startMonth = startDate;
    } else {
      [components setDay:1];
      [components setMonth:(components.month + 1)];
      startMonth = [calendar dateFromComponents:components];
    }
    return datasetBlk(startMonth, firstDayOfCurrentMonth);
  }
  return @[];
}

#pragma mark - Sinces since last odometer log

- (NSNumber *)daysSinceLastOdometerLogForUser:(FPUser *)user {
  return [self daysSinceOdometerLog:[_localDao lastOdometerLogForUser:user error:_errorBlk]];
}

- (NSNumber *)daysSinceLastOdometerLogForVehicle:(FPVehicle *)vehicle {
  return [self daysSinceOdometerLog:[_localDao lastOdometerLogForVehicle:vehicle error:_errorBlk]];
}

#pragma mark - Average Reported MPH

- (NSDecimalNumber *)yearToDateAvgReportedMphForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  return [self avgReportedMphFromEnvlogs:[_localDao unorderedEnvironmentLogsForUser:user
                                                                         beforeDate:now
                                                                      onOrAfterDate:firstDayOfCurrentYear
                                                                              error:_errorBlk]];
}

- (NSArray *)yearToDateAvgReportedMphDataSetForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  return [self avgReportedMphDataSetForUser:user beforeDate:now onOrAfterDate:firstDayOfCurrentYear];
}

- (NSDecimalNumber *)lastYearAvgReportedMphForUser:(FPUser *)user {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgReportedMphFromEnvlogs:[_localDao unorderedEnvironmentLogsForUser:user
                                                                         beforeDate:lastYearRange[1]
                                                                      onOrAfterDate:lastYearRange[0]
                                                                              error:_errorBlk]];
}

- (NSArray *)lastYearAvgReportedMphDataSetForUser:(FPUser *)user {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgReportedMphDataSetForUser:user beforeDate:lastYearRange[1] onOrAfterDate:lastYearRange[0]];
}

- (NSDecimalNumber *)overallAvgReportedMphForUser:(FPUser *)user {
  return [self avgReportedMphFromEnvlogs:[_localDao unorderedEnvironmentLogsForUser:user error:_errorBlk]];
}

- (NSArray *)overallAvgReportedMphDataSetForUser:(FPUser *)user {
  FPEnvironmentLog *firstOdometerLog = [_localDao firstOdometerLogForUser:user error:_errorBlk];
  if (firstOdometerLog) {
    FPEnvironmentLog *lastOdometerLog = [_localDao lastOdometerLogForUser:user error:_errorBlk];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [self avgReportedMphDataSetForUser:user
                                   beforeDate:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:lastOdometerLog.logDate options:0]
                                onOrAfterDate:firstOdometerLog.logDate];
  }
  return @[];
}

- (NSDecimalNumber *)yearToDateAvgReportedMphForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  return [self avgReportedMphFromEnvlogs:[_localDao unorderedEnvironmentLogsForVehicle:vehicle
                                                                            beforeDate:now
                                                                         onOrAfterDate:firstDayOfCurrentYear
                                                                                 error:_errorBlk]];
}

- (NSArray *)yearToDateAvgReportedMphDataSetForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  return [self avgReportedMphDataSetForVehicle:vehicle beforeDate:now onOrAfterDate:firstDayOfCurrentYear];
}

- (NSDecimalNumber *)lastYearAvgReportedMphForVehicle:(FPVehicle *)vehicle {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgReportedMphFromEnvlogs:[_localDao unorderedEnvironmentLogsForVehicle:vehicle
                                                                            beforeDate:lastYearRange[1]
                                                                         onOrAfterDate:lastYearRange[0]
                                                                                 error:_errorBlk]];
}

- (NSArray *)lastYearAvgReportedMphDataSetForVehicle:(FPVehicle *)vehicle {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgReportedMphDataSetForVehicle:vehicle beforeDate:lastYearRange[1] onOrAfterDate:lastYearRange[0]];
}

- (NSDecimalNumber *)overallAvgReportedMphForVehicle:(FPVehicle *)vehicle {
  return [self avgReportedMphFromEnvlogs:[_localDao unorderedEnvironmentLogsForVehicle:vehicle error:_errorBlk]];
}

- (NSArray *)overallAvgReportedMphDataSetForVehicle:(FPVehicle *)vehicle {
  FPEnvironmentLog *firstOdometerLog = [_localDao firstOdometerLogForVehicle:vehicle error:_errorBlk];
  if (firstOdometerLog) {
    FPEnvironmentLog *lastOdometerLog = [_localDao lastOdometerLogForVehicle:vehicle error:_errorBlk];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [self avgReportedMphDataSetForVehicle:vehicle
                                      beforeDate:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:lastOdometerLog.logDate options:0]
                                   onOrAfterDate:firstOdometerLog.logDate];
  }
  return @[];
}

#pragma mark - Max Reported MPH

- (NSDecimalNumber *)yearToDateMaxReportedMphForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  return [_localDao maxReportedMphOdometerLogForUser:user
                                          beforeDate:now
                                       onOrAfterDate:firstDayOfCurrentYear
                                               error:_errorBlk].reportedAvgMph;
}

- (NSDecimalNumber *)lastYearMaxReportedMphForUser:(FPUser *)user {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao maxReportedMphOdometerLogForUser:user
                                          beforeDate:lastYearRange[1]
                                       onOrAfterDate:lastYearRange[0]
                                               error:_errorBlk].reportedAvgMph;
}

- (NSDecimalNumber *)overallMaxReportedMphForUser:(FPUser *)user {
  return [_localDao maxReportedMphOdometerLogForUser:user error:_errorBlk].reportedAvgMph;
}

- (NSDecimalNumber *)yearToDateMaxReportedMphForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  return [_localDao maxReportedMphOdometerLogForVehicle:vehicle
                                             beforeDate:now
                                          onOrAfterDate:firstDayOfCurrentYear
                                                  error:_errorBlk].reportedAvgMph;
}

- (NSDecimalNumber *)lastYearMaxReportedMphForVehicle:(FPVehicle *)vehicle {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao maxReportedMphOdometerLogForVehicle:vehicle
                                             beforeDate:lastYearRange[1]
                                          onOrAfterDate:lastYearRange[0]
                                                  error:_errorBlk].reportedAvgMph;
}

- (NSDecimalNumber *)overallMaxReportedMphForVehicle:(FPVehicle *)vehicle {
  return [_localDao maxReportedMphOdometerLogForVehicle:vehicle error:_errorBlk].reportedAvgMph;
}

#pragma mark - Min Reported MPH

- (NSDecimalNumber *)yearToDateMinReportedMphForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  return [_localDao minReportedMphOdometerLogForUser:user
                                          beforeDate:now
                                       onOrAfterDate:firstDayOfCurrentYear
                                               error:_errorBlk].reportedAvgMph;
}

- (NSDecimalNumber *)lastYearMinReportedMphForUser:(FPUser *)user {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao minReportedMphOdometerLogForUser:user
                                          beforeDate:lastYearRange[1]
                                       onOrAfterDate:lastYearRange[0]
                                               error:_errorBlk].reportedAvgMph;
}

- (NSDecimalNumber *)overallMinReportedMphForUser:(FPUser *)user {
  return [_localDao minReportedMphOdometerLogForUser:user error:_errorBlk].reportedAvgMph;
}

- (NSDecimalNumber *)yearToDateMinReportedMphForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  return [_localDao minReportedMphOdometerLogForVehicle:vehicle
                                             beforeDate:now
                                          onOrAfterDate:firstDayOfCurrentYear
                                                  error:_errorBlk].reportedAvgMph;
}

- (NSDecimalNumber *)lastYearMinReportedMphForVehicle:(FPVehicle *)vehicle {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao minReportedMphOdometerLogForVehicle:vehicle
                                             beforeDate:lastYearRange[1]
                                          onOrAfterDate:lastYearRange[0]
                                                  error:_errorBlk].reportedAvgMph;
}

- (NSDecimalNumber *)overallMinReportedMphForVehicle:(FPVehicle *)vehicle {
  return [_localDao minReportedMphOdometerLogForVehicle:vehicle error:_errorBlk].reportedAvgMph;
}

#pragma mark - Average Reported MPG

- (NSDecimalNumber *)yearToDateAvgReportedMpgForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  return [self avgReportedMpgFromEnvlogs:[_localDao unorderedEnvironmentLogsForUser:user
                                                                         beforeDate:now
                                                                      onOrAfterDate:firstDayOfCurrentYear
                                                                              error:_errorBlk]];
}

- (NSArray *)yearToDateAvgReportedMpgDataSetForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  return [self avgReportedMpgDataSetForUser:user beforeDate:now onOrAfterDate:firstDayOfCurrentYear];
}

- (NSDecimalNumber *)lastYearAvgReportedMpgForUser:(FPUser *)user {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgReportedMpgFromEnvlogs:[_localDao unorderedEnvironmentLogsForUser:user
                                                                         beforeDate:lastYearRange[1]
                                                                      onOrAfterDate:lastYearRange[0]
                                                                              error:_errorBlk]];
}

- (NSArray *)lastYearAvgReportedMpgDataSetForUser:(FPUser *)user {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgReportedMpgDataSetForUser:user beforeDate:lastYearRange[1] onOrAfterDate:lastYearRange[0]];
}

- (NSDecimalNumber *)overallAvgReportedMpgForUser:(FPUser *)user {
  return [self avgReportedMpgFromEnvlogs:[_localDao unorderedEnvironmentLogsForUser:user error:_errorBlk]];
}

- (NSArray *)overallAvgReportedMpgDataSetForUser:(FPUser *)user {
  FPEnvironmentLog *firstOdometerLog = [_localDao firstOdometerLogForUser:user error:_errorBlk];
  if (firstOdometerLog) {
    FPEnvironmentLog *lastOdometerLog = [_localDao lastOdometerLogForUser:user error:_errorBlk];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [self avgReportedMpgDataSetForUser:user
                                   beforeDate:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:lastOdometerLog.logDate options:0]
                                onOrAfterDate:firstOdometerLog.logDate];
  }
  return @[];
}

- (NSDecimalNumber *)yearToDateAvgReportedMpgForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  return [self avgReportedMpgFromEnvlogs:[_localDao unorderedEnvironmentLogsForVehicle:vehicle
                                                                            beforeDate:now
                                                                         onOrAfterDate:firstDayOfCurrentYear
                                                                                 error:_errorBlk]];
}

- (NSArray *)yearToDateAvgReportedMpgDataSetForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  return [self avgReportedMpgDataSetForVehicle:vehicle beforeDate:now onOrAfterDate:firstDayOfCurrentYear];
}

- (NSDecimalNumber *)lastYearAvgReportedMpgForVehicle:(FPVehicle *)vehicle {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgReportedMpgFromEnvlogs:[_localDao unorderedEnvironmentLogsForVehicle:vehicle
                                                                            beforeDate:lastYearRange[1]
                                                                         onOrAfterDate:lastYearRange[0]
                                                                                 error:_errorBlk]];
}

- (NSArray *)lastYearAvgReportedMpgDataSetForVehicle:(FPVehicle *)vehicle {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgReportedMpgDataSetForVehicle:vehicle beforeDate:lastYearRange[1] onOrAfterDate:lastYearRange[0]];
}

- (NSDecimalNumber *)overallAvgReportedMpgForVehicle:(FPVehicle *)vehicle {
  return [self avgReportedMpgFromEnvlogs:[_localDao unorderedEnvironmentLogsForVehicle:vehicle error:_errorBlk]];
}

- (NSArray *)overallAvgReportedMpgDataSetForVehicle:(FPVehicle *)vehicle {
  FPEnvironmentLog *firstOdometerLog = [_localDao firstOdometerLogForVehicle:vehicle error:_errorBlk];
  if (firstOdometerLog) {
    FPEnvironmentLog *lastOdometerLog = [_localDao lastOdometerLogForVehicle:vehicle error:_errorBlk];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [self avgReportedMpgDataSetForVehicle:vehicle
                                      beforeDate:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:lastOdometerLog.logDate options:0]
                                   onOrAfterDate:firstOdometerLog.logDate];
  }
  return @[];
}

#pragma mark - Max Reported MPG

- (NSDecimalNumber *)yearToDateMaxReportedMpgForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  return [_localDao maxReportedMpgOdometerLogForUser:user
                                          beforeDate:now
                                       onOrAfterDate:firstDayOfCurrentYear
                                               error:_errorBlk].reportedAvgMpg;
}

- (NSDecimalNumber *)lastYearMaxReportedMpgForUser:(FPUser *)user {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao maxReportedMpgOdometerLogForUser:user
                                          beforeDate:lastYearRange[1]
                                       onOrAfterDate:lastYearRange[0]
                                               error:_errorBlk].reportedAvgMpg;
}

- (NSDecimalNumber *)overallMaxReportedMpgForUser:(FPUser *)user {
  return [_localDao maxReportedMpgOdometerLogForUser:user error:_errorBlk].reportedAvgMpg;
}

- (NSDecimalNumber *)yearToDateMaxReportedMpgForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  return [_localDao maxReportedMpgOdometerLogForVehicle:vehicle
                                             beforeDate:now
                                          onOrAfterDate:firstDayOfCurrentYear
                                                  error:_errorBlk].reportedAvgMpg;
}

- (NSDecimalNumber *)lastYearMaxReportedMpgForVehicle:(FPVehicle *)vehicle {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao maxReportedMpgOdometerLogForVehicle:vehicle
                                             beforeDate:lastYearRange[1]
                                          onOrAfterDate:lastYearRange[0]
                                                  error:_errorBlk].reportedAvgMpg;
}

- (NSDecimalNumber *)overallMaxReportedMpgForVehicle:(FPVehicle *)vehicle {
  return [_localDao maxReportedMpgOdometerLogForVehicle:vehicle error:_errorBlk].reportedAvgMpg;
}

#pragma mark - Min Reported MPG

- (NSDecimalNumber *)yearToDateMinReportedMpgForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  return [_localDao minReportedMpgOdometerLogForUser:user
                                          beforeDate:now
                                       onOrAfterDate:firstDayOfCurrentYear
                                               error:_errorBlk].reportedAvgMpg;
}

- (NSDecimalNumber *)lastYearMinReportedMpgForUser:(FPUser *)user {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao minReportedMpgOdometerLogForUser:user
                                          beforeDate:lastYearRange[1]
                                       onOrAfterDate:lastYearRange[0]
                                               error:_errorBlk].reportedAvgMpg;
}

- (NSDecimalNumber *)overallMinReportedMpgForUser:(FPUser *)user {
  return [_localDao minReportedMpgOdometerLogForUser:user error:_errorBlk].reportedAvgMpg;
}

- (NSDecimalNumber *)yearToDateMinReportedMpgForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  return [_localDao minReportedMpgOdometerLogForVehicle:vehicle
                                             beforeDate:now
                                          onOrAfterDate:firstDayOfCurrentYear
                                                  error:_errorBlk].reportedAvgMpg;
}

- (NSDecimalNumber *)lastYearMinReportedMpgForVehicle:(FPVehicle *)vehicle {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao minReportedMpgOdometerLogForVehicle:vehicle
                                             beforeDate:lastYearRange[1]
                                          onOrAfterDate:lastYearRange[0]
                                                  error:_errorBlk].reportedAvgMpg;
}

- (NSDecimalNumber *)overallMinReportedMpgForVehicle:(FPVehicle *)vehicle {
  return [_localDao minReportedMpgOdometerLogForVehicle:vehicle error:_errorBlk].reportedAvgMpg;
}

#pragma mark - Days Between Fill-ups

- (NSNumber *)daysSinceLastGasLogForUser:(FPUser *)user {
  return [self daysSinceGasLog:[_localDao lastGasLogForUser:user error:_errorBlk]];
}

- (NSNumber *)daysSinceLastGasLogForVehicle:(FPVehicle *)vehicle {
  return [self daysSinceGasLog:[_localDao lastGasLogForVehicle:vehicle error:_errorBlk]];
}

- (NSNumber *)daysSinceLastGasLogForGasStation:(FPFuelStation *)gasStation {
  return [self daysSinceGasLog:[_localDao lastGasLogForFuelstation:gasStation error:_errorBlk]];
}

- (NSDecimalNumber *)yearToDateAvgDaysBetweenFillupsForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  NSArray *dataset = [self daysBetweenFillupsDataSetForUser:user
                                                 beforeDate:now
                                              onOrAfterDate:firstDayOfCurrentYear
                                                   calendar:calendar];
  return [self avgValueForIntegerDataset:dataset];
}

- (NSNumber *)yearToDateMaxDaysBetweenFillupsForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  NSArray *dataset = [self daysBetweenFillupsDataSetForUser:user
                                                 beforeDate:now
                                              onOrAfterDate:firstDayOfCurrentYear
                                                   calendar:calendar];
  return [self maxValueForDataset:dataset];
}

- (NSArray *)yearToDateDaysBetweenFillupsDataSetForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  return [self daysBetweenFillupsDataSetForUser:user
                                     beforeDate:now
                                  onOrAfterDate:firstDayOfCurrentYear
                                       calendar:calendar];
}

- (NSArray *)yearToDateAvgDaysBetweenFillupsDataSetForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  return [self avgDaysBetweenFillupsDataSetForUser:user
                                        beforeDate:now
                                     onOrAfterDate:firstDayOfCurrentYear
                                          calendar:calendar];
}

- (NSDecimalNumber *)lastYearAvgDaysBetweenFillupsForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:calendar];
  NSArray *dataset = [self daysBetweenFillupsDataSetForUser:user
                                                 beforeDate:lastYearRange[1]
                                              onOrAfterDate:lastYearRange[0]
                                                   calendar:calendar];
  return [self avgValueForIntegerDataset:dataset];
}

- (NSNumber *)lastYearMaxDaysBetweenFillupsForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:calendar];
  NSArray *dataset = [self daysBetweenFillupsDataSetForUser:user
                                                 beforeDate:lastYearRange[1]
                                              onOrAfterDate:lastYearRange[0]
                                                   calendar:calendar];
  return [self maxValueForDataset:dataset];
}

- (NSArray *)lastYearDaysBetweenFillupsDataSetForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:calendar];
  return [self daysBetweenFillupsDataSetForUser:user
                                     beforeDate:lastYearRange[1]
                                  onOrAfterDate:lastYearRange[0]
                                       calendar:calendar];
}

- (NSArray *)lastYearAvgDaysBetweenFillupsDataSetForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:calendar];
  return [self avgDaysBetweenFillupsDataSetForUser:user
                                        beforeDate:lastYearRange[1]
                                     onOrAfterDate:lastYearRange[0]
                                          calendar:calendar];
}

- (NSDecimalNumber *)overallAvgDaysBetweenFillupsForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForUser:user error:_errorBlk];
  if (firstGasLog) {
    NSDate *now = [NSDate date];
    NSArray *dataset = [self daysBetweenFillupsDataSetForUser:user
                                                   beforeDate:now
                                                onOrAfterDate:firstGasLog.purchasedAt
                                                     calendar:calendar];
    return [self avgValueForIntegerDataset:dataset];
  }
  return nil;
}

- (NSNumber *)overallMaxDaysBetweenFillupsForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForUser:user error:_errorBlk];
  if (firstGasLog) {
    NSDate *now = [NSDate date];
    NSArray *dataset = [self daysBetweenFillupsDataSetForUser:user
                                                   beforeDate:now
                                                onOrAfterDate:firstGasLog.purchasedAt
                                                     calendar:calendar];
    return [self maxValueForDataset:dataset];
  }
  return nil;
}

- (NSArray *)overallDaysBetweenFillupsDataSetForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForUser:user error:_errorBlk];
  if (firstGasLog) {
    NSDate *now = [NSDate date];
    return [self daysBetweenFillupsDataSetForUser:user
                                       beforeDate:now
                                    onOrAfterDate:firstGasLog.purchasedAt
                                         calendar:calendar];
  }
  return @[];
}

- (NSArray *)overallAvgDaysBetweenFillupsDataSetForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForUser:user error:_errorBlk];
  if (firstGasLog) {
    NSDate *now = [NSDate date];
    return [self avgDaysBetweenFillupsDataSetForUser:user
                                          beforeDate:now
                                       onOrAfterDate:firstGasLog.purchasedAt
                                            calendar:calendar];
  }
  return @[];
}

- (NSDecimalNumber *)yearToDateAvgDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  NSArray *dataset = [self daysBetweenFillupsDataSetForVehicle:vehicle
                                                    beforeDate:now
                                                 onOrAfterDate:firstDayOfCurrentYear
                                                      calendar:calendar];
  return [self avgValueForIntegerDataset:dataset];
}

- (NSNumber *)yearToDateMaxDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  NSArray *dataset = [self daysBetweenFillupsDataSetForVehicle:vehicle
                                                    beforeDate:now
                                                 onOrAfterDate:firstDayOfCurrentYear
                                                      calendar:calendar];
  return [self maxValueForDataset:dataset];
}

- (NSArray *)yearToDateDaysBetweenFillupsDataSetForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  return [self daysBetweenFillupsDataSetForVehicle:vehicle
                                        beforeDate:now
                                     onOrAfterDate:firstDayOfCurrentYear
                                          calendar:calendar];
}

- (NSArray *)yearToDateAvgDaysBetweenFillupsDataSetForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  return [self avgDaysBetweenFillupsDataSetForVehicle:vehicle
                                           beforeDate:now
                                        onOrAfterDate:firstDayOfCurrentYear
                                             calendar:calendar];
}

- (NSDecimalNumber *)lastYearAvgDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:calendar];
  NSArray *dataset = [self daysBetweenFillupsDataSetForVehicle:vehicle
                                                    beforeDate:lastYearRange[1]
                                                 onOrAfterDate:lastYearRange[0]
                                                      calendar:calendar];
  return [self avgValueForIntegerDataset:dataset];
}

- (NSNumber *)lastYearMaxDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:calendar];
  NSArray *dataset = [self daysBetweenFillupsDataSetForVehicle:vehicle
                                                    beforeDate:lastYearRange[1]
                                                 onOrAfterDate:lastYearRange[0]
                                                      calendar:calendar];
  return [self maxValueForDataset:dataset];
}

- (NSArray *)lastYearDaysBetweenFillupsDataSetForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:calendar];
  return [self daysBetweenFillupsDataSetForVehicle:vehicle
                                        beforeDate:lastYearRange[1]
                                     onOrAfterDate:lastYearRange[0]
                                          calendar:calendar];
}

- (NSArray *)lastYearAvgDaysBetweenFillupsDataSetForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:calendar];
  return [self avgDaysBetweenFillupsDataSetForVehicle:vehicle
                                           beforeDate:lastYearRange[1]
                                        onOrAfterDate:lastYearRange[0]
                                             calendar:calendar];
}

- (NSDecimalNumber *)overallAvgDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForVehicle:vehicle error:_errorBlk];
  if (firstGasLog) {
    NSDate *now = [NSDate date];
    NSArray *dataset = [self daysBetweenFillupsDataSetForVehicle:vehicle
                                                      beforeDate:now
                                                   onOrAfterDate:firstGasLog.purchasedAt
                                                        calendar:calendar];
    return [self avgValueForIntegerDataset:dataset];
  }
  return nil;
}

- (NSNumber *)overallMaxDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForVehicle:vehicle error:_errorBlk];
  if (firstGasLog) {
    NSDate *now = [NSDate date];
    NSArray *dataset = [self daysBetweenFillupsDataSetForVehicle:vehicle
                                                      beforeDate:now
                                                   onOrAfterDate:firstGasLog.purchasedAt
                                                        calendar:calendar];
    return [self maxValueForDataset:dataset];
  }
  return nil;
}

- (NSArray *)overallDaysBetweenFillupsDataSetForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForVehicle:vehicle error:_errorBlk];
  if (firstGasLog) {
    NSDate *now = [NSDate date];
    return [self daysBetweenFillupsDataSetForVehicle:vehicle
                                          beforeDate:now
                                       onOrAfterDate:firstGasLog.purchasedAt
                                            calendar:calendar];
  }
  return @[];
}

- (NSArray *)overallAvgDaysBetweenFillupsDataSetForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForVehicle:vehicle error:_errorBlk];
  if (firstGasLog) {
    NSDate *now = [NSDate date];
    return [self avgDaysBetweenFillupsDataSetForVehicle:vehicle
                                             beforeDate:now
                                          onOrAfterDate:firstGasLog.purchasedAt
                                               calendar:calendar];
  }
  return @[];
}

#pragma mark - Gas Cost Per Mile

- (NSDecimalNumber *)yearToDateAvgGasCostPerMileForUser:(FPUser *)user {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgGasCostPerMileForUser:user beforeDate:now onOrAfterDate:firstDayOfCurrentYear];
}

- (NSArray *)yearToDateAvgGasCostPerMileDataSetForUser:(FPUser *)user {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgGasCostPerMileDataSetForUser:user beforeDate:now onOrAfterDate:firstDayOfCurrentYear];
}

- (NSDecimalNumber *)avgGasCostPerMileForUser:(FPUser *)user year:(NSInteger)year {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *yearAsDate = [PEUtils firstDayOfYear:year month:1 calendar:calendar];
  NSDate *firstDayOfNextYear = [PEUtils firstDayOfYear:year + 1 month:1 calendar:calendar];
  return [self avgGasCostPerMileForUser:user beforeDate:firstDayOfNextYear onOrAfterDate:yearAsDate];
}

- (NSArray *)avgGasCostPerMileDataSetForUser:(FPUser *)user year:(NSInteger)year {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *yearAsDate = [PEUtils firstDayOfYear:year month:1 calendar:calendar];
  NSDate *firstDayOfNextYear = [PEUtils firstDayOfYear:year + 1 month:1 calendar:calendar];
  return [self avgGasCostPerMileDataSetForUser:user beforeDate:firstDayOfNextYear onOrAfterDate:yearAsDate];
}

- (NSDecimalNumber *)lastYearAvgGasCostPerMileForUser:(FPUser *)user {
  return [self avgGasCostPerMileForUser:user year:[PEUtils currentYear] - 1];
}

- (NSArray *)lastYearAvgGasCostPerMileDataSetForUser:(FPUser *)user {
  return [self avgGasCostPerMileDataSetForUser:user year:[PEUtils currentYear] - 1];
}

- (NSDecimalNumber *)overallAvgGasCostPerMileForUser:(FPUser *)user {
  FPEnvironmentLog *firstOdometerLog = [_localDao firstOdometerLogForUser:user error:_errorBlk];
  if (firstOdometerLog) {
    NSDate *now = [NSDate date];
    return [self avgGasCostPerMileForUser:user beforeDate:now onOrAfterDate:firstOdometerLog.logDate];
  }
  return nil;
}

- (NSArray *)overallAvgGasCostPerMileDataSetForUser:(FPUser *)user {
  FPEnvironmentLog *firstOdometerLog = [_localDao firstOdometerLogForUser:user error:_errorBlk];
  if (firstOdometerLog) {
    NSDate *now = [NSDate date];
    return [self avgGasCostPerMileDataSetForUser:user beforeDate:now onOrAfterDate:firstOdometerLog.logDate];
  }
  return @[];
}

- (NSDecimalNumber *)yearToDateAvgGasCostPerMileForVehicle:(FPVehicle *)vehicle {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgGasCostPerMileForVehicle:vehicle beforeDate:now onOrAfterDate:firstDayOfCurrentYear];
}

- (NSArray *)yearToDateAvgGasCostPerMileDataSetForVehicle:(FPVehicle *)vehicle {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgGasCostPerMileDataSetForVehicle:vehicle beforeDate:now onOrAfterDate:firstDayOfCurrentYear];
}

- (NSDecimalNumber *)avgGasCostPerMileForVehicle:(FPVehicle *)vehicle year:(NSInteger)year {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *yearAsDate = [PEUtils firstDayOfYear:year month:1 calendar:calendar];
  NSDate *firstDayOfNextYear = [PEUtils firstDayOfYear:year + 1 month:1 calendar:calendar];
  return [self avgGasCostPerMileForVehicle:vehicle beforeDate:firstDayOfNextYear onOrAfterDate:yearAsDate];
}

- (NSArray *)avgGasCostPerMileDataSetForVehicle:(FPVehicle *)vehicle year:(NSInteger)year {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *yearAsDate = [PEUtils firstDayOfYear:year month:1 calendar:calendar];
  NSDate *firstDayOfNextYear = [PEUtils firstDayOfYear:year + 1 month:1 calendar:calendar];
  return [self avgGasCostPerMileDataSetForVehicle:vehicle beforeDate:firstDayOfNextYear onOrAfterDate:yearAsDate];
}

- (NSDecimalNumber *)lastYearAvgGasCostPerMileForVehicle:(FPVehicle *)vehicle {
  return [self avgGasCostPerMileForVehicle:vehicle year:[PEUtils currentYear] - 1];
}

- (NSArray *)lastYearAvgGasCostPerMileDataSetForVehicle:(FPVehicle *)vehicle {
  return [self avgGasCostPerMileDataSetForVehicle:vehicle year:[PEUtils currentYear] - 1];
}

- (NSDecimalNumber *)overallAvgGasCostPerMileForVehicle:(FPVehicle *)vehicle {
  FPEnvironmentLog *firstOdometerLog = [_localDao firstOdometerLogForVehicle:vehicle error:_errorBlk];
  if (firstOdometerLog) {
    NSDate *now = [NSDate date];
    return [self avgGasCostPerMileForVehicle:vehicle beforeDate:now onOrAfterDate:firstOdometerLog.logDate];
  }
  return nil;
}

- (NSArray *)overallAvgGasCostPerMileDataSetForVehicle:(FPVehicle *)vehicle {
  FPEnvironmentLog *firstOdometerLog = [_localDao firstOdometerLogForVehicle:vehicle error:_errorBlk];
  if (firstOdometerLog) {
    NSDate *now = [NSDate date];
    return [self avgGasCostPerMileDataSetForVehicle:vehicle beforeDate:now onOrAfterDate:firstOdometerLog.logDate];
  }
  return @[];
}

#pragma mark - Amount Spent on Gas

- (NSDecimalNumber *)thisMonthSpentOnGasForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDateComponents *components = [calendar components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:now];
  [components setDay:1];
  NSDate *firstDayOfCurrentMonth = [calendar dateFromComponents:components];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user
                                                                     beforeDate:now
                                                                  onOrAfterDate:firstDayOfCurrentMonth
                                                                          error:_errorBlk]];
}

- (NSDecimalNumber *)lastMonthSpentOnGasForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDateComponents *components = [calendar components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:now];
  [components setDay:1];
  NSDate *firstDayOfCurrentMonth = [calendar dateFromComponents:components];
  [components setMonth:(components.month - 1)];
  NSDate *firstDayOfPreviousMonth = [calendar dateFromComponents:components];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user
                                                                     beforeDate:firstDayOfCurrentMonth
                                                                  onOrAfterDate:firstDayOfPreviousMonth
                                                                          error:_errorBlk]];
}

- (NSDecimalNumber *)yearToDateSpentOnGasForUser:(FPUser *)user {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user
                                                                     beforeDate:now
                                                                  onOrAfterDate:firstDayOfCurrentYear
                                                                          error:_errorBlk]];
}

- (NSArray *)yearToDateSpentOnGasDataSetForUser:(FPUser *)user {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self spentOnGasDataSetForUser:user beforeDate:now onOrAfterDate:firstDayOfCurrentYear];
}

- (NSArray *)yearToDateSpentOnGasExcludingPartialMonthsDataSetForUser:(FPUser *)user {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self spentOnGasExcludingPartialMonthsDataSetWithStartDate:firstDayOfCurrentYear
                                                         datasetBlk:^(NSDate *startMonth, NSDate *firstDayOfCurrentMonth) {
                                                           return [self spentOnGasDataSetForUser:user
                                                                                      beforeDate:firstDayOfCurrentMonth
                                                                                   onOrAfterDate:startMonth];
                                                         }];
}

- (NSDecimalNumber *)lastYearSpentOnGasForUser:(FPUser *)user {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user
                                                                     beforeDate:lastYearRange[1]
                                                                  onOrAfterDate:lastYearRange[0]
                                                                          error:_errorBlk]];
}

- (NSDecimalNumber *)yearToDateAvgSpentOnGasForUser:(FPUser *)user {
  return [self avgValueForDecimalDataset:[self yearToDateSpentOnGasExcludingPartialMonthsDataSetForUser:user]];
}

- (NSDecimalNumber *)yearToDateMinSpentOnGasForUser:(FPUser *)user {
  return [self minValueForDataset:[self yearToDateSpentOnGasExcludingPartialMonthsDataSetForUser:user]];
}

- (NSDecimalNumber *)yearToDateMaxSpentOnGasForUser:(FPUser *)user {
  return [self maxValueForDataset:[self yearToDateSpentOnGasDataSetForUser:user]];
}

- (NSArray *)lastYearSpentOnGasDataSetForUser:(FPUser *)user {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self spentOnGasDataSetForUser:user beforeDate:lastYearRange[1] onOrAfterDate:lastYearRange[0]];
}

- (NSDecimalNumber *)lastYearAvgSpentOnGasForUser:(FPUser *)user {
  return [self avgValueForDecimalDataset:[self lastYearSpentOnGasDataSetForUser:user]];
}

- (NSDecimalNumber *)lastYearMinSpentOnGasForUser:(FPUser *)user {
  return [self minValueForDataset:[self lastYearSpentOnGasDataSetForUser:user]];
}

- (NSDecimalNumber *)lastYearMaxSpentOnGasForUser:(FPUser *)user {
  return [self maxValueForDataset:[self lastYearSpentOnGasDataSetForUser:user]];
}

- (NSDecimalNumber *)overallSpentOnGasForUser:(FPUser *)user {
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user error:_errorBlk]];
}

- (NSArray *)overallSpentOnGasDataSetForUser:(FPUser *)user {
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForUser:user error:_errorBlk];
  if (firstGasLog) {
    FPFuelPurchaseLog *lastGasLog = [_localDao lastGasLogForUser:user error:_errorBlk];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [self spentOnGasDataSetForUser:user
                               beforeDate:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:lastGasLog.purchasedAt options:0]
                            onOrAfterDate:firstGasLog.purchasedAt];
  }
  return @[];
}

- (NSArray *)overallSpentOnGasExcludingPartialMonthsDataSetForUser:(FPUser *)user {
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForUser:user error:_errorBlk];
  return [self spentOnGasExcludingPartialMonthsDataSetWithStartDate:firstGasLog.purchasedAt
                                                         datasetBlk:^(NSDate *startMonth, NSDate *firstDayOfCurrentMonth) {
                                                           return [self spentOnGasDataSetForUser:user
                                                                                      beforeDate:firstDayOfCurrentMonth
                                                                                   onOrAfterDate:startMonth];
                                                         }];
}

- (NSDecimalNumber *)overallAvgSpentOnGasForUser:(FPUser *)user {
  return [self avgValueForDecimalDataset:[self overallSpentOnGasExcludingPartialMonthsDataSetForUser:user]];
}

- (NSDecimalNumber *)overallMinSpentOnGasForUser:(FPUser *)user {
  return [self minValueForDataset:[self overallSpentOnGasExcludingPartialMonthsDataSetForUser:user]];
}

- (NSDecimalNumber *)overallMaxSpentOnGasForUser:(FPUser *)user {
  return [self maxValueForDataset:[self overallSpentOnGasDataSetForUser:user]];
}

- (NSDecimalNumber *)thisMonthSpentOnGasForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDateComponents *components = [calendar components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:now];
  [components setDay:1];
  NSDate *firstDayOfCurrentMonth = [calendar dateFromComponents:components];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                        beforeDate:now
                                                                     onOrAfterDate:firstDayOfCurrentMonth
                                                                             error:_errorBlk]];
}

- (NSDecimalNumber *)lastMonthSpentOnGasForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDateComponents *components = [calendar components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:now];
  [components setDay:1];
  NSDate *firstDayOfCurrentMonth = [calendar dateFromComponents:components];
  [components setMonth:(components.month - 1)];
  NSDate *firstDayOfPreviousMonth = [calendar dateFromComponents:components];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                        beforeDate:firstDayOfCurrentMonth
                                                                     onOrAfterDate:firstDayOfPreviousMonth
                                                                             error:_errorBlk]];
}

- (NSDecimalNumber *)yearToDateSpentOnGasForVehicle:(FPVehicle *)vehicle {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                        beforeDate:now
                                                                     onOrAfterDate:firstDayOfCurrentYear
                                                                             error:_errorBlk]];
}

- (NSArray *)yearToDateSpentOnGasDataSetForVehicle:(FPVehicle *)vehicle {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self spentOnGasDataSetForVehicle:vehicle beforeDate:now onOrAfterDate:firstDayOfCurrentYear];
}

- (NSArray *)yearToDateSpentOnGasExcludingPartialMonthsDataSetForVehicle:(FPVehicle *)vehicle {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self spentOnGasExcludingPartialMonthsDataSetWithStartDate:firstDayOfCurrentYear
                                                         datasetBlk:^(NSDate *startMonth, NSDate *firstDayOfCurrentMonth) {
                                                           return [self spentOnGasDataSetForVehicle:vehicle
                                                                                         beforeDate:firstDayOfCurrentMonth
                                                                                      onOrAfterDate:startMonth];
                                                         }];
}

- (NSDecimalNumber *)yearToDateAvgSpentOnGasForVehicle:(FPVehicle *)vehicle {
  return [self avgValueForDecimalDataset:[self yearToDateSpentOnGasExcludingPartialMonthsDataSetForVehicle:vehicle]];
}

- (NSDecimalNumber *)yearToDateMinSpentOnGasForVehicle:(FPVehicle *)vehicle {
  return [self minValueForDataset:[self yearToDateSpentOnGasExcludingPartialMonthsDataSetForVehicle:vehicle]];
}

- (NSDecimalNumber *)yearToDateMaxSpentOnGasForVehicle:(FPVehicle *)vehicle {
  return [self maxValueForDataset:[self yearToDateSpentOnGasDataSetForVehicle:vehicle]];
}

- (NSDecimalNumber *)lastYearSpentOnGasForVehicle:(FPVehicle *)vehicle {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                        beforeDate:lastYearRange[1]
                                                                     onOrAfterDate:lastYearRange[0]
                                                                             error:_errorBlk]];
}

- (NSArray *)lastYearSpentOnGasDataSetForVehicle:(FPVehicle *)vehicle {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self spentOnGasDataSetForVehicle:vehicle beforeDate:lastYearRange[1] onOrAfterDate:lastYearRange[0]];
}

- (NSArray *)spentOnGasDataSetForVehicle:(FPVehicle *)vehicle year:(NSInteger)year {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *yearAsDate = [PEUtils firstDayOfYear:year month:1 calendar:calendar];
  NSDate *firstDayOfNextYear = [PEUtils firstDayOfYear:year + 1 month:1 calendar:calendar];
  return [self spentOnGasDataSetForVehicle:vehicle beforeDate:firstDayOfNextYear onOrAfterDate:yearAsDate];
}

- (NSDecimalNumber *)lastYearAvgSpentOnGasForVehicle:(FPVehicle *)vehicle {
  return [self avgValueForDecimalDataset:[self lastYearSpentOnGasDataSetForVehicle:vehicle]];
}

- (NSDecimalNumber *)lastYearMinSpentOnGasForVehicle:(FPVehicle *)vehicle {
  return [self minValueForDataset:[self lastYearSpentOnGasDataSetForVehicle:vehicle]];
}

- (NSDecimalNumber *)lastYearMaxSpentOnGasForVehicle:(FPVehicle *)vehicle {
  return [self maxValueForDataset:[self lastYearSpentOnGasDataSetForVehicle:vehicle]];
}

- (NSDecimalNumber *)overallSpentOnGasForVehicle:(FPVehicle *)vehicle {
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle error:_errorBlk]];
}

- (NSArray *)overallSpentOnGasDataSetForVehicle:(FPVehicle *)vehicle {
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForVehicle:vehicle error:_errorBlk];
  if (firstGasLog) {
    FPFuelPurchaseLog *lastGasLog = [_localDao lastGasLogForVehicle:vehicle error:_errorBlk];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [self spentOnGasDataSetForVehicle:vehicle
                                  beforeDate:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:lastGasLog.purchasedAt options:0]
                               onOrAfterDate:firstGasLog.purchasedAt];
  }
  return @[];
}

- (NSArray *)overallSpentOnGasExcludingPartialMonthsDataSetForVehicle:(FPVehicle *)vehicle {
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForVehicle:vehicle error:_errorBlk];
  return [self spentOnGasExcludingPartialMonthsDataSetWithStartDate:firstGasLog.purchasedAt
                                                         datasetBlk:^(NSDate *startMonth, NSDate *firstDayOfCurrentMonth) {
                                                           return [self spentOnGasDataSetForVehicle:vehicle
                                                                                         beforeDate:firstDayOfCurrentMonth
                                                                                      onOrAfterDate:startMonth];
                                                         }];
}

- (NSDecimalNumber *)overallAvgSpentOnGasForVehicle:(FPVehicle *)vehicle {
  return [self avgValueForDecimalDataset:[self overallSpentOnGasExcludingPartialMonthsDataSetForVehicle:vehicle]];
}

- (NSDecimalNumber *)overallMinSpentOnGasForVehicle:(FPVehicle *)vehicle {
  return [self minValueForDataset:[self overallSpentOnGasExcludingPartialMonthsDataSetForVehicle:vehicle]];
}

- (NSDecimalNumber *)overallMaxSpentOnGasForVehicle:(FPVehicle *)vehicle {
  return [self maxValueForDataset:[self overallSpentOnGasDataSetForVehicle:vehicle]];
}

- (NSDecimalNumber *)thisMonthSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDateComponents *components = [calendar components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:now];
  [components setDay:1];
  NSDate *firstDayOfCurrentMonth = [calendar dateFromComponents:components];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation
                                                                            beforeDate:now
                                                                         onOrAfterDate:firstDayOfCurrentMonth
                                                                                 error:_errorBlk]];
}

- (NSDecimalNumber *)lastMonthSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDateComponents *components = [calendar components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:now];
  [components setDay:1];
  NSDate *firstDayOfCurrentMonth = [calendar dateFromComponents:components];
  [components setMonth:(components.month - 1)];
  NSDate *firstDayOfPreviousMonth = [calendar dateFromComponents:components];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation
                                                                            beforeDate:firstDayOfCurrentMonth
                                                                         onOrAfterDate:firstDayOfPreviousMonth
                                                                                 error:_errorBlk]];
}

- (NSDecimalNumber *)yearToDateSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  NSDate *now = [NSDate date];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation
                                                                            beforeDate:now
                                                                         onOrAfterDate:[PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]]
                                                                                 error:_errorBlk]];
}

- (NSArray *)yearToDateSpentOnGasDataSetForFuelstation:(FPFuelStation *)fuelstation {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self spentOnGasDataSetForFuelstation:fuelstation beforeDate:now onOrAfterDate:firstDayOfCurrentYear];
}

- (NSArray *)yearToDateSpentOnGasExcludingPartialMonthsDataSetForFuelstation:(FPFuelStation *)fuelstation {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self spentOnGasExcludingPartialMonthsDataSetWithStartDate:firstDayOfCurrentYear
                                                         datasetBlk:^(NSDate *startMonth, NSDate *firstDayOfCurrentMonth) {
                                                           return [self spentOnGasDataSetForFuelstation:fuelstation
                                                                                             beforeDate:firstDayOfCurrentMonth
                                                                                          onOrAfterDate:startMonth];
                                                         }];
}

- (NSDecimalNumber *)yearToDateAvgSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  return [self avgValueForDecimalDataset:[self yearToDateSpentOnGasExcludingPartialMonthsDataSetForFuelstation:fuelstation]];
}

- (NSDecimalNumber *)yearToDateMinSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  return [self minValueForDataset:[self yearToDateSpentOnGasExcludingPartialMonthsDataSetForFuelstation:fuelstation]];
}

- (NSDecimalNumber *)yearToDateMaxSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  return [self maxValueForDataset:[self yearToDateSpentOnGasDataSetForFuelstation:fuelstation]];
}

- (NSDecimalNumber *)lastYearSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation
                                                                            beforeDate:lastYearRange[1]
                                                                         onOrAfterDate:lastYearRange[0]
                                                                                 error:_errorBlk]];
}

- (NSArray *)lastYearSpentOnGasDataSetForFuelstation:(FPFuelStation *)fuelstation {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self spentOnGasDataSetForFuelstation:fuelstation beforeDate:lastYearRange[1] onOrAfterDate:lastYearRange[0]];
}

- (NSDecimalNumber *)lastYearAvgSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  return [self avgValueForDecimalDataset:[self lastYearSpentOnGasDataSetForFuelstation:fuelstation]];
}

- (NSDecimalNumber *)lastYearMinSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  return [self minValueForDataset:[self lastYearSpentOnGasDataSetForFuelstation:fuelstation]];
}

- (NSDecimalNumber *)lastYearMaxSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  return [self maxValueForDataset:[self lastYearSpentOnGasDataSetForFuelstation:fuelstation]];
}

- (NSDecimalNumber *)overallSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation error:_errorBlk]];
}

- (NSArray *)overallSpentOnGasDataSetForFuelstation:(FPFuelStation *)fuelstation {
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForFuelstation:fuelstation error:_errorBlk];
  if (firstGasLog) {
    FPFuelPurchaseLog *lastGasLog = [_localDao lastGasLogForFuelstation:fuelstation error:_errorBlk];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [self spentOnGasDataSetForFuelstation:fuelstation
                                      beforeDate:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:lastGasLog.purchasedAt options:0]
                                   onOrAfterDate:firstGasLog.purchasedAt];
  }
  return @[];
}

- (NSArray *)overallSpentOnGasExcludingPartialMonthsDataSetForFuelstation:(FPFuelStation *)fuelstation {
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForFuelstation:fuelstation error:_errorBlk];
  return [self spentOnGasExcludingPartialMonthsDataSetWithStartDate:firstGasLog.purchasedAt
                                                         datasetBlk:^(NSDate *startMonth, NSDate *firstDayOfCurrentMonth) {
                                                           return [self spentOnGasDataSetForFuelstation:fuelstation
                                                                                             beforeDate:firstDayOfCurrentMonth
                                                                                          onOrAfterDate:startMonth];
                                                         }];
}

- (NSDecimalNumber *)overallAvgSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  return [self avgValueForDecimalDataset:[self overallSpentOnGasExcludingPartialMonthsDataSetForFuelstation:fuelstation]];
}

- (NSDecimalNumber *)overallMinSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  return [self minValueForDataset:[self overallSpentOnGasExcludingPartialMonthsDataSetForFuelstation:fuelstation]];
}

- (NSDecimalNumber *)overallMaxSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  return [self maxValueForDataset:[self overallSpentOnGasDataSetForFuelstation:fuelstation]];
}

#pragma mark - Average Price Per Gallon

- (NSDecimalNumber *)yearToDateAvgPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user
                                                                         beforeDate:now
                                                                      onOrAfterDate:firstDayOfCurrentYear
                                                                             octane:octane
                                                                              error:_errorBlk]];
}

- (NSArray *)yearToDateAvgPricePerGallonDataSetForUser:(FPUser *)user octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgPricePerGallonDataSetForUser:user beforeDate:now onOrAfterDate:firstDayOfCurrentYear octane:octane];
}

- (NSDecimalNumber *)lastYearAvgPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user
                                                                         beforeDate:lastYearRange[1]
                                                                      onOrAfterDate:lastYearRange[0]
                                                                             octane:octane
                                                                              error:_errorBlk]];
}

- (NSArray *)lastYearAvgPricePerGallonDataSetForUser:(FPUser *)user octane:(NSNumber *)octane {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgPricePerGallonDataSetForUser:user beforeDate:lastYearRange[1] onOrAfterDate:lastYearRange[0] octane:octane];
}

- (NSDecimalNumber *)overallAvgPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane {
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user
                                                                             octane:octane
                                                                              error:_errorBlk]];
}

- (NSArray *)overallAvgPricePerGallonDataSetForUser:(FPUser *)user octane:(NSNumber *)octane {
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForUser:user octane:octane error:_errorBlk];
  if (firstGasLog) {
    FPFuelPurchaseLog *lastGasLog = [_localDao lastGasLogForUser:user octane:octane error:_errorBlk];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [self avgPricePerGallonDataSetForUser:user
                                      beforeDate:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:lastGasLog.purchasedAt options:0]
                                   onOrAfterDate:firstGasLog.purchasedAt
                                          octane:octane];
  }
  return @[];
}



- (NSDecimalNumber *)yearToDateAvgPricePerGallonForUser:(FPUser *)user {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user
                                                                         beforeDate:now
                                                                      onOrAfterDate:firstDayOfCurrentYear
                                                                              error:_errorBlk]];
}

- (NSArray *)yearToDateAvgPricePerGallonDataSetForUser:(FPUser *)user {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgPricePerGallonDataSetForUser:user beforeDate:now onOrAfterDate:firstDayOfCurrentYear];
}

- (NSDecimalNumber *)lastYearAvgPricePerGallonForUser:(FPUser *)user {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user
                                                                         beforeDate:lastYearRange[1]
                                                                      onOrAfterDate:lastYearRange[0]
                                                                              error:_errorBlk]];
}

- (NSArray *)lastYearAvgPricePerGallonDataSetForUser:(FPUser *)user {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgPricePerGallonDataSetForUser:user beforeDate:lastYearRange[1] onOrAfterDate:lastYearRange[0]];
}

- (NSDecimalNumber *)overallAvgPricePerGallonForUser:(FPUser *)user {
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user
                                                                              error:_errorBlk]];
}

- (NSArray *)overallAvgPricePerGallonDataSetForUser:(FPUser *)user {
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForUser:user error:_errorBlk];
  if (firstGasLog) {
    FPFuelPurchaseLog *lastGasLog = [_localDao lastGasLogForUser:user error:_errorBlk];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [self avgPricePerGallonDataSetForUser:user
                                      beforeDate:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:lastGasLog.purchasedAt options:0]
                                   onOrAfterDate:firstGasLog.purchasedAt];
  }
  return @[];
}




- (NSDecimalNumber *)yearToDateAvgPricePerDieselGallonForUser:(FPUser *)user {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedDieselFuelPurchaseLogsForUser:user
                                                                               beforeDate:now
                                                                            onOrAfterDate:firstDayOfCurrentYear
                                                                                    error:_errorBlk]];
}

- (NSArray *)yearToDateAvgPricePerDieselGallonDataSetForUser:(FPUser *)user {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgPricePerDieselGallonDataSetForUser:user beforeDate:now onOrAfterDate:firstDayOfCurrentYear];
}

- (NSDecimalNumber *)lastYearAvgPricePerDieselGallonForUser:(FPUser *)user {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedDieselFuelPurchaseLogsForUser:user
                                                                               beforeDate:lastYearRange[1]
                                                                            onOrAfterDate:lastYearRange[0]
                                                                                    error:_errorBlk]];
}

- (NSArray *)lastYearAvgPricePerDieselGallonDataSetForUser:(FPUser *)user {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgPricePerDieselGallonDataSetForUser:user beforeDate:lastYearRange[1] onOrAfterDate:lastYearRange[0]];
}

- (NSDecimalNumber *)overallAvgPricePerDieselGallonForUser:(FPUser *)user {
  return [self avgGallonPriceFromFplogs:[_localDao unorderedDieselFuelPurchaseLogsForUser:user
                                                                                    error:_errorBlk]];
}

- (NSArray *)overallAvgPricePerDieselGallonDataSetForUser:(FPUser *)user {
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForUser:user error:_errorBlk];
  if (firstGasLog) {
    FPFuelPurchaseLog *lastGasLog = [_localDao lastGasLogForUser:user error:_errorBlk];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [self avgPricePerDieselGallonDataSetForUser:user
                                            beforeDate:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:lastGasLog.purchasedAt options:0]
                                         onOrAfterDate:firstGasLog.purchasedAt];
  }
  return @[];
}

- (NSDecimalNumber *)yearToDateAvgPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                            beforeDate:now
                                                                         onOrAfterDate:firstDayOfCurrentYear
                                                                                octane:octane
                                                                                 error:_errorBlk]];
}

- (NSArray *)yearToDateAvgPricePerGallonDataSetForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgPricePerGallonDataSetForVehicle:vehicle
                                       beforeDate:now
                                    onOrAfterDate:firstDayOfCurrentYear
                                           octane:octane];
}

- (NSDecimalNumber *)lastYearAvgPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                            beforeDate:lastYearRange[1]
                                                                         onOrAfterDate:lastYearRange[0]
                                                                                octane:octane
                                                                                 error:_errorBlk]];
}

- (NSArray *)lastYearAvgPricePerGallonDataSetForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgPricePerGallonDataSetForVehicle:vehicle
                                       beforeDate:lastYearRange[1]
                                    onOrAfterDate:lastYearRange[0]
                                           octane:octane];
}

- (NSDecimalNumber *)overallAvgPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                                octane:octane
                                                                                 error:_errorBlk]];
}

- (NSArray *)overallAvgPricePerGallonDataSetForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForVehicle:vehicle octane:octane error:_errorBlk];
  if (firstGasLog) {
    FPFuelPurchaseLog *lastGasLog = [_localDao lastGasLogForVehicle:vehicle octane:octane error:_errorBlk];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [self avgPricePerGallonDataSetForVehicle:vehicle
                                         beforeDate:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:lastGasLog.purchasedAt options:0]
                                      onOrAfterDate:firstGasLog.purchasedAt
                                             octane:octane];
  }
  return @[];
}

- (NSDecimalNumber *)yearToDateAvgPricePerGallonForVehicle:(FPVehicle *)vehicle {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                            beforeDate:now
                                                                         onOrAfterDate:firstDayOfCurrentYear
                                                                                 error:_errorBlk]];
}

- (NSArray *)yearToDateAvgPricePerGallonDataSetForVehicle:(FPVehicle *)vehicle {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgPricePerGallonDataSetForVehicle:vehicle
                                       beforeDate:now
                                    onOrAfterDate:firstDayOfCurrentYear];
}

- (NSDecimalNumber *)lastYearAvgPricePerGallonForVehicle:(FPVehicle *)vehicle {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                            beforeDate:lastYearRange[1]
                                                                         onOrAfterDate:lastYearRange[0]
                                                                                 error:_errorBlk]];
}

- (NSArray *)lastYearAvgPricePerGallonDataSetForVehicle:(FPVehicle *)vehicle {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgPricePerGallonDataSetForVehicle:vehicle
                                       beforeDate:lastYearRange[1]
                                    onOrAfterDate:lastYearRange[0]];
}

- (NSDecimalNumber *)overallAvgPricePerGallonForVehicle:(FPVehicle *)vehicle {
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                                 error:_errorBlk]];
}

- (NSArray *)overallAvgPricePerGallonDataSetForVehicle:(FPVehicle *)vehicle {
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForVehicle:vehicle error:_errorBlk];
  if (firstGasLog) {
    FPFuelPurchaseLog *lastGasLog = [_localDao lastGasLogForVehicle:vehicle error:_errorBlk];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [self avgPricePerGallonDataSetForVehicle:vehicle
                                         beforeDate:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:lastGasLog.purchasedAt options:0]
                                      onOrAfterDate:firstGasLog.purchasedAt];
  }
  return @[];
}

- (NSDecimalNumber *)yearToDateAvgPricePerDieselGallonForVehicle:(FPVehicle *)vehicle {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedDieselFuelPurchaseLogsForVehicle:vehicle
                                                                                  beforeDate:now
                                                                               onOrAfterDate:firstDayOfCurrentYear
                                                                                       error:_errorBlk]];
}

- (NSArray *)yearToDateAvgPricePerDieselGallonDataSetForVehicle:(FPVehicle *)vehicle {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgPricePerDieselGallonDataSetForVehicle:vehicle
                                             beforeDate:now
                                          onOrAfterDate:firstDayOfCurrentYear];
}

- (NSDecimalNumber *)lastYearAvgPricePerDieselGallonForVehicle:(FPVehicle *)vehicle {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedDieselFuelPurchaseLogsForVehicle:vehicle
                                                                                  beforeDate:lastYearRange[1]
                                                                               onOrAfterDate:lastYearRange[0]
                                                                                       error:_errorBlk]];
}

- (NSArray *)lastYearAvgPricePerDieselGallonDataSetForVehicle:(FPVehicle *)vehicle {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgPricePerDieselGallonDataSetForVehicle:vehicle
                                             beforeDate:lastYearRange[1]
                                          onOrAfterDate:lastYearRange[0]];
}

- (NSDecimalNumber *)overallAvgPricePerDieselGallonForVehicle:(FPVehicle *)vehicle {
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                                 error:_errorBlk]];
}

- (NSArray *)overallAvgPricePerDieselGallonDataSetForVehicle:(FPVehicle *)vehicle {
  FPFuelPurchaseLog *firstGasLog = [_localDao firstDieselGasLogForVehicle:vehicle error:_errorBlk];
  if (firstGasLog) {
    FPFuelPurchaseLog *lastGasLog = [_localDao lastDieselGasLogForVehicle:vehicle error:_errorBlk];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [self avgPricePerDieselGallonDataSetForVehicle:vehicle
                                               beforeDate:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:lastGasLog.purchasedAt options:0]
                                            onOrAfterDate:firstGasLog.purchasedAt];
  }
  return @[];
}

- (NSDecimalNumber *)yearToDateAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation
                                                                                beforeDate:now
                                                                             onOrAfterDate:firstDayOfCurrentYear
                                                                                    octane:octane
                                                                                     error:_errorBlk]];
}

- (NSArray *)yearToDateAvgPricePerGallonDataSetForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgPricePerGallonDataSetForFuelstation:fuelstation beforeDate:now onOrAfterDate:firstDayOfCurrentYear octane:octane];
}

- (NSDecimalNumber *)lastYearAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation
                                                                                beforeDate:lastYearRange[1]
                                                                             onOrAfterDate:lastYearRange[0]
                                                                                    octane:octane
                                                                                     error:_errorBlk]];
}

- (NSArray *)lastYearAvgPricePerGallonDataSetForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgPricePerGallonDataSetForFuelstation:fuelstation
                                           beforeDate:lastYearRange[1]
                                        onOrAfterDate:lastYearRange[0]
                                               octane:octane];
}

- (NSDecimalNumber *)overallAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation
                                                                                    octane:octane
                                                                                     error:_errorBlk]];
}

- (NSArray *)overallAvgPricePerGallonDataSetForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForFuelstation:fuelstation octane:octane error:_errorBlk];
  if (firstGasLog) {
    FPFuelPurchaseLog *lastGasLog = [_localDao lastGasLogForFuelstation:fuelstation octane:octane error:_errorBlk];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [self avgPricePerGallonDataSetForFuelstation:fuelstation
                                             beforeDate:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:lastGasLog.purchasedAt options:0]
                                          onOrAfterDate:firstGasLog.purchasedAt
                                                 octane:octane];
  }
  return @[];
}

- (NSDecimalNumber *)yearToDateAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation
                                                                                beforeDate:now
                                                                             onOrAfterDate:firstDayOfCurrentYear
                                                                                     error:_errorBlk]];
}

- (NSArray *)yearToDateAvgPricePerGallonDataSetForFuelstation:(FPFuelStation *)fuelstation {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgPricePerGallonDataSetForFuelstation:fuelstation beforeDate:now onOrAfterDate:firstDayOfCurrentYear];
}

- (NSDecimalNumber *)lastYearAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation
                                                                                beforeDate:lastYearRange[1]
                                                                             onOrAfterDate:lastYearRange[0]
                                                                                     error:_errorBlk]];
}

- (NSArray *)lastYearAvgPricePerGallonDataSetForFuelstation:(FPFuelStation *)fuelstation {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgPricePerGallonDataSetForFuelstation:fuelstation
                                           beforeDate:lastYearRange[1]
                                        onOrAfterDate:lastYearRange[0]];
}

- (NSDecimalNumber *)overallAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation {
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation
                                                                                     error:_errorBlk]];
}

- (NSArray *)overallAvgPricePerGallonDataSetForFuelstation:(FPFuelStation *)fuelstation {
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForFuelstation:fuelstation error:_errorBlk];
  if (firstGasLog) {
    FPFuelPurchaseLog *lastGasLog = [_localDao lastGasLogForFuelstation:fuelstation error:_errorBlk];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [self avgPricePerGallonDataSetForFuelstation:fuelstation
                                             beforeDate:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:lastGasLog.purchasedAt options:0]
                                          onOrAfterDate:firstGasLog.purchasedAt];
  }
  return @[];
}

- (NSDecimalNumber *)yearToDateAvgPricePerDieselGallonForFuelstation:(FPFuelStation *)fuelstation {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedDieselFuelPurchaseLogsForFuelstation:fuelstation
                                                                                      beforeDate:now
                                                                                   onOrAfterDate:firstDayOfCurrentYear
                                                                                           error:_errorBlk]];
}

- (NSArray *)yearToDateAvgPricePerDieselGallonDataSetForFuelstation:(FPFuelStation *)fuelstation {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgPricePerDieselGallonDataSetForFuelstation:fuelstation beforeDate:now onOrAfterDate:firstDayOfCurrentYear];
}

- (NSDecimalNumber *)lastYearAvgPricePerDieselGallonForFuelstation:(FPFuelStation *)fuelstation {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedDieselFuelPurchaseLogsForFuelstation:fuelstation
                                                                                      beforeDate:lastYearRange[1]
                                                                                   onOrAfterDate:lastYearRange[0]
                                                                                           error:_errorBlk]];
}

- (NSArray *)lastYearAvgPricePerDieselGallonDataSetForFuelstation:(FPFuelStation *)fuelstation {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgPricePerDieselGallonDataSetForFuelstation:fuelstation
                                                 beforeDate:lastYearRange[1]
                                              onOrAfterDate:lastYearRange[0]];
}

- (NSDecimalNumber *)overallAvgPricePerDieselGallonForFuelstation:(FPFuelStation *)fuelstation {
  return [self avgGallonPriceFromFplogs:[_localDao unorderedDieselFuelPurchaseLogsForFuelstation:fuelstation
                                                                                           error:_errorBlk]];
}

- (NSArray *)overallAvgPricePerDieselGallonDataSetForFuelstation:(FPFuelStation *)fuelstation {
  FPFuelPurchaseLog *firstGasLog = [_localDao firstDieselGasLogForFuelstation:fuelstation error:_errorBlk];
  if (firstGasLog) {
    FPFuelPurchaseLog *lastGasLog = [_localDao lastDieselGasLogForFuelstation:fuelstation error:_errorBlk];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [self avgPricePerDieselGallonDataSetForFuelstation:fuelstation
                                                   beforeDate:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:lastGasLog.purchasedAt options:0]
                                                onOrAfterDate:firstGasLog.purchasedAt];
  }
  return @[];
}

#pragma mark - Max Price Per Gallon

- (NSDecimalNumber *)yearToDateMaxPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [_localDao maxGallonPriceFuelPurchaseLogForUser:user
                                              beforeDate:now
                                           onOrAfterDate:firstDayOfCurrentYear
                                                  octane:octane
                                                   error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)lastYearMaxPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao maxGallonPriceFuelPurchaseLogForUser:user
                                              beforeDate:lastYearRange[1]
                                           onOrAfterDate:lastYearRange[0]
                                                  octane:octane
                                                   error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMaxPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane {
  return [_localDao maxGallonPriceFuelPurchaseLogForUser:user
                                                  octane:octane
                                                   error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)yearToDateMaxPricePerGallonForUser:(FPUser *)user {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [_localDao maxGallonPriceFuelPurchaseLogForUser:user
                                              beforeDate:now
                                           onOrAfterDate:firstDayOfCurrentYear
                                                   error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)lastYearMaxPricePerGallonForUser:(FPUser *)user {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao maxGallonPriceFuelPurchaseLogForUser:user
                                              beforeDate:lastYearRange[1]
                                           onOrAfterDate:lastYearRange[0]
                                                   error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMaxPricePerGallonForUser:(FPUser *)user {
  return [_localDao maxGallonPriceFuelPurchaseLogForUser:user
                                                   error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)yearToDateMaxPricePerDieselGallonForUser:(FPUser *)user {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [_localDao maxGallonPriceDieselFuelPurchaseLogForUser:user
                                                    beforeDate:now
                                                 onOrAfterDate:firstDayOfCurrentYear
                                                         error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)lastYearMaxPricePerDieselGallonForUser:(FPUser *)user {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao maxGallonPriceDieselFuelPurchaseLogForUser:user
                                                    beforeDate:lastYearRange[1]
                                                 onOrAfterDate:lastYearRange[0]
                                                         error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMaxPricePerDieselGallonForUser:(FPUser *)user {
  return [_localDao maxGallonPriceDieselFuelPurchaseLogForUser:user
                                                         error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)yearToDateMaxPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [_localDao maxGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                 beforeDate:now
                                              onOrAfterDate:firstDayOfCurrentYear
                                                     octane:octane
                                                      error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)lastYearMaxPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao maxGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                 beforeDate:lastYearRange[1]
                                              onOrAfterDate:lastYearRange[0]
                                                     octane:octane
                                                      error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMaxPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  return [_localDao maxGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                     octane:octane
                                                      error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)yearToDateMaxPricePerGallonForVehicle:(FPVehicle *)vehicle {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [_localDao maxGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                 beforeDate:now
                                              onOrAfterDate:firstDayOfCurrentYear
                                                      error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)lastYearMaxPricePerGallonForVehicle:(FPVehicle *)vehicle {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao maxGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                 beforeDate:lastYearRange[1]
                                              onOrAfterDate:lastYearRange[0]
                                                      error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMaxPricePerGallonForVehicle:(FPVehicle *)vehicle {
  return [_localDao maxGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                      error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)yearToDateMaxPricePerDieselGallonForVehicle:(FPVehicle *)vehicle {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [_localDao maxGallonPriceDieselFuelPurchaseLogForVehicle:vehicle
                                                       beforeDate:now
                                                    onOrAfterDate:firstDayOfCurrentYear
                                                            error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)lastYearMaxPricePerDieselGallonForVehicle:(FPVehicle *)vehicle {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao maxGallonPriceDieselFuelPurchaseLogForVehicle:vehicle
                                                       beforeDate:lastYearRange[1]
                                                    onOrAfterDate:lastYearRange[0]
                                                            error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMaxPricePerDieselGallonForVehicle:(FPVehicle *)vehicle {
  return [_localDao maxGallonPriceDieselFuelPurchaseLogForVehicle:vehicle
                                                            error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)yearToDateMaxPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [_localDao maxGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                     beforeDate:now
                                                  onOrAfterDate:firstDayOfCurrentYear
                                                         octane:octane
                                                          error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)lastYearMaxPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao maxGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                     beforeDate:lastYearRange[1]
                                                  onOrAfterDate:lastYearRange[0]
                                                         octane:octane
                                                          error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMaxPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  return [_localDao maxGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                         octane:octane
                                                          error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)yearToDateMaxPricePerGallonForFuelstation:(FPFuelStation *)fuelstation {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [_localDao maxGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                     beforeDate:now
                                                  onOrAfterDate:firstDayOfCurrentYear
                                                          error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)lastYearMaxPricePerGallonForFuelstation:(FPFuelStation *)fuelstation {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao maxGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                     beforeDate:lastYearRange[1]
                                                  onOrAfterDate:lastYearRange[0]
                                                          error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMaxPricePerGallonForFuelstation:(FPFuelStation *)fuelstation {
  return [_localDao maxGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                          error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)yearToDateMaxPricePerDieselGallonForFuelstation:(FPFuelStation *)fuelstation {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [_localDao maxGallonPriceDieselFuelPurchaseLogForFuelstation:fuelstation
                                                           beforeDate:now
                                                        onOrAfterDate:firstDayOfCurrentYear
                                                                error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)lastYearMaxPricePerDieselGallonForFuelstation:(FPFuelStation *)fuelstation {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao maxGallonPriceDieselFuelPurchaseLogForFuelstation:fuelstation
                                                           beforeDate:lastYearRange[1]
                                                        onOrAfterDate:lastYearRange[0]
                                                                error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMaxPricePerDieselGallonForFuelstation:(FPFuelStation *)fuelstation {
  return [_localDao maxGallonPriceDieselFuelPurchaseLogForFuelstation:fuelstation
                                                                error:_errorBlk].gallonPrice;
}

#pragma mark - Min Price Per Gallon

- (NSDecimalNumber *)yearToDateMinPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [_localDao minGallonPriceFuelPurchaseLogForUser:user
                                              beforeDate:now
                                           onOrAfterDate:firstDayOfCurrentYear
                                                  octane:octane
                                                   error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)lastYearMinPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao minGallonPriceFuelPurchaseLogForUser:user
                                              beforeDate:lastYearRange[1]
                                           onOrAfterDate:lastYearRange[0]
                                                  octane:octane
                                                   error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMinPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane {
  return [_localDao minGallonPriceFuelPurchaseLogForUser:user
                                                  octane:octane
                                                   error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)yearToDateMinPricePerGallonForUser:(FPUser *)user {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [_localDao minGallonPriceFuelPurchaseLogForUser:user
                                              beforeDate:now
                                           onOrAfterDate:firstDayOfCurrentYear
                                                   error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)lastYearMinPricePerGallonForUser:(FPUser *)user {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao minGallonPriceFuelPurchaseLogForUser:user
                                              beforeDate:lastYearRange[1]
                                           onOrAfterDate:lastYearRange[0]
                                                   error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMinPricePerGallonForUser:(FPUser *)user {
  return [_localDao minGallonPriceFuelPurchaseLogForUser:user
                                                   error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)yearToDateMinPricePerDieselGallonForUser:(FPUser *)user {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [_localDao minGallonPriceDieselFuelPurchaseLogForUser:user
                                                    beforeDate:now
                                                 onOrAfterDate:firstDayOfCurrentYear
                                                         error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)lastYearMinPricePerDieselGallonForUser:(FPUser *)user {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao minGallonPriceDieselFuelPurchaseLogForUser:user
                                                    beforeDate:lastYearRange[1]
                                                 onOrAfterDate:lastYearRange[0]
                                                         error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMinPricePerDieselGallonForUser:(FPUser *)user {
  return [_localDao minGallonPriceDieselFuelPurchaseLogForUser:user
                                                         error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)yearToDateMinPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [_localDao minGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                 beforeDate:now
                                              onOrAfterDate:firstDayOfCurrentYear
                                                     octane:octane
                                                      error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)lastYearMinPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao minGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                 beforeDate:lastYearRange[1]
                                              onOrAfterDate:lastYearRange[0]
                                                     octane:octane
                                                      error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMinPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  return [_localDao minGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                     octane:octane
                                                      error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)yearToDateMinPricePerGallonForVehicle:(FPVehicle *)vehicle {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [_localDao minGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                 beforeDate:now
                                              onOrAfterDate:firstDayOfCurrentYear
                                                      error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)lastYearMinPricePerGallonForVehicle:(FPVehicle *)vehicle {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao minGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                 beforeDate:lastYearRange[1]
                                              onOrAfterDate:lastYearRange[0]
                                                      error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMinPricePerGallonForVehicle:(FPVehicle *)vehicle {
  return [_localDao minGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                      error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)yearToDateMinPricePerDieselGallonForVehicle:(FPVehicle *)vehicle {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [_localDao minGallonPriceDieselFuelPurchaseLogForVehicle:vehicle
                                                       beforeDate:now
                                                    onOrAfterDate:firstDayOfCurrentYear
                                                            error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)lastYearMinPricePerDieselGallonForVehicle:(FPVehicle *)vehicle {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao minGallonPriceDieselFuelPurchaseLogForVehicle:vehicle
                                                       beforeDate:lastYearRange[1]
                                                    onOrAfterDate:lastYearRange[0]
                                                            error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMinPricePerDieselGallonForVehicle:(FPVehicle *)vehicle {
  return [_localDao minGallonPriceDieselFuelPurchaseLogForVehicle:vehicle
                                                            error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)yearToDateMinPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [_localDao minGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                     beforeDate:now
                                                  onOrAfterDate:firstDayOfCurrentYear
                                                         octane:octane
                                                          error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)lastYearMinPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao minGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                     beforeDate:lastYearRange[1]
                                                  onOrAfterDate:lastYearRange[0]
                                                         octane:octane
                                                          error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMinPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  return [_localDao minGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                         octane:octane
                                                          error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)yearToDateMinPricePerGallonForFuelstation:(FPFuelStation *)fuelstation {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [_localDao minGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                     beforeDate:now
                                                  onOrAfterDate:firstDayOfCurrentYear
                                                          error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)lastYearMinPricePerGallonForFuelstation:(FPFuelStation *)fuelstation {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao minGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                     beforeDate:lastYearRange[1]
                                                  onOrAfterDate:lastYearRange[0]
                                                          error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMinPricePerGallonForFuelstation:(FPFuelStation *)fuelstation {
  return [_localDao minGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                          error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)yearToDateMinPricePerDieselGallonForFuelstation:(FPFuelStation *)fuelstation {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [_localDao minGallonPriceDieselFuelPurchaseLogForFuelstation:fuelstation
                                                           beforeDate:now
                                                        onOrAfterDate:firstDayOfCurrentYear
                                                                error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)lastYearMinPricePerDieselGallonForFuelstation:(FPFuelStation *)fuelstation {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao minGallonPriceDieselFuelPurchaseLogForFuelstation:fuelstation
                                                           beforeDate:lastYearRange[1]
                                                        onOrAfterDate:lastYearRange[0]
                                                                error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMinPricePerDieselGallonForFuelstation:(FPFuelStation *)fuelstation {
  return [_localDao minGallonPriceDieselFuelPurchaseLogForFuelstation:fuelstation
                                                                error:_errorBlk].gallonPrice;
}

#pragma mark - Miles Recorded

- (NSDecimalNumber *)milesRecordedForVehicle:(FPVehicle *)vehicle {
  FPEnvironmentLog *firstOdometerLog = [_localDao firstOdometerLogForVehicle:vehicle error:_errorBlk];
  FPEnvironmentLog *lastOdometerLog = [_localDao lastOdometerLogForVehicle:vehicle error:_errorBlk];
  if (firstOdometerLog && lastOdometerLog) {
    return [lastOdometerLog.odometer decimalNumberBySubtracting:firstOdometerLog.odometer];
  }
  return [NSDecimalNumber zero];
}

- (NSDecimalNumber *)milesRecordedForVehicle:(FPVehicle *)vehicle
                                  beforeDate:(NSDate *)beforeDate
                               onOrAfterDate:(NSDate *)onOrAfterDate {
  FPEnvironmentLog *firstOdometerLog = [_localDao firstOdometerLogForVehicle:vehicle
                                                                  beforeDate:beforeDate
                                                               onOrAfterDate:onOrAfterDate
                                                                       error:_errorBlk];
  FPEnvironmentLog *lastOdometerLog = [_localDao lastOdometerLogForVehicle:vehicle
                                                                beforeDate:beforeDate
                                                             onOrAfterDate:onOrAfterDate
                                                                     error:_errorBlk];
  if (firstOdometerLog && lastOdometerLog) {
    return [lastOdometerLog.odometer decimalNumberBySubtracting:firstOdometerLog.odometer];
  }
  return [NSDecimalNumber zero];
}

- (NSDecimalNumber *)milesDrivenSinceLastOdometerLogAndLog:(FPEnvironmentLog *)odometerLog
                                                   vehicle:(FPVehicle *)vehicle {
  NSDecimalNumber *odometer = [odometerLog odometer];
  if (![PEUtils isNil:odometer]) {
    NSArray *odometerLogs =
    [_localDao environmentLogsForVehicle:vehicle pageSize:1 beforeDateLogged:[odometerLog logDate] error:_errorBlk];
    if ([odometerLogs count] > 0) {
      NSDecimalNumber *lastOdometer = [odometerLogs[0] odometer];
      if (![PEUtils isNil:lastOdometer]) {
        return [odometer decimalNumberBySubtracting:lastOdometer];
      }
    }
  }
  return nil;
}

#pragma mark - Duration Between Odometer Logs

- (NSNumber *)daysSinceLastOdometerLogAndLog:(FPEnvironmentLog *)odometerLog
                                     vehicle:(FPVehicle *)vehicle {
  NSArray *odometerLogs = [_localDao environmentLogsForVehicle:vehicle
                                                      pageSize:1
                                              beforeDateLogged:[odometerLog logDate]
                                                         error:_errorBlk];
  if ([odometerLogs count] > 0) {
    NSDate *dateOfLastLog = [odometerLogs[0] logDate];
    if (dateOfLastLog) {
      return @([PEUtils daysFromDate:dateOfLastLog toDate:[odometerLog logDate]]);
    }
  }
  return nil;
}

#pragma mark - Outside Temperature

- (NSNumber *)temperatureLastYearForUser:(FPUser *)user
                      withinDaysVariance:(NSInteger)daysVariance {
  return [self temperatureForUser:user oneYearAgoFromDate:[NSDate date] withinDaysVariance:daysVariance];
}

- (NSNumber *)temperatureForUser:(FPUser *)user
              oneYearAgoFromDate:(NSDate *)oneYearAgoFromDate
              withinDaysVariance:(NSInteger)daysVariance {
  NSArray *nearestOdometerLog = [_localDao odometerLogNearestToDate:[self oneYearAgoFromDate:oneYearAgoFromDate]
                                                            forUser:user
                                                              error:_errorBlk];
  if (nearestOdometerLog) {
    if ([nearestOdometerLog[1] integerValue] <= daysVariance) {
      return [nearestOdometerLog[0] reportedOutsideTemp];
    }
  }
  return nil;
}

@end
