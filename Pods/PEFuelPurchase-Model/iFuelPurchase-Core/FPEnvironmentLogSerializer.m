//
//  FPEnvironmentLogSerializer.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 10/24/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPEnvironmentLogSerializer.h"
#import "FPEnvironmentLog.h"
#import <PEObjc-Commons/NSMutableDictionary+PEAdditions.h>
#import <PEObjc-Commons/NSDictionary+PEAdditions.h>
#import <PEHateoas-Client/HCUtils.h>
#import <PEObjc-Commons/PEUtils.h>

NSString * const FPEnvironmentLogVehicleGlobalIdKey     = @"envlog/vehicle";
NSString * const FPEnvironmentLogOdometerKey            = @"envlog/odometer";
NSString * const FPEnvironmentLogReportedAvgMpgKey      = @"envlog/reported-avg-mpg";
NSString * const FPEnvironmentLogReportedAvgMphKey      = @"envlog/reported-avg-mph";
NSString * const FPEnvironmentLogReportedOutsideTempKey = @"envlog/reported-outside-temp";
NSString * const FPEnvironmentLogLogDateKey             = @"envlog/logged-at";
NSString * const FPEnvironmentLogReportedDteKey         = @"envlog/dte";
NSString * const FPEnvironmentLogCreatedAtKey           = @"envlog/created-at";
NSString * const FPEnvironmentLogUpdatedAtKey           = @"envlog/updated-at";
NSString * const FPEnvironmentLogDeletedAtKey           = @"envlog/deleted-at";

@implementation FPEnvironmentLogSerializer

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  FPEnvironmentLog *environmentLog = (FPEnvironmentLog *)resourceModel;
  NSMutableDictionary *environmentLogDict = [NSMutableDictionary dictionary];
  [environmentLogDict nullSafeSetObject:[environmentLog vehicleGlobalIdentifier] forKey:FPEnvironmentLogVehicleGlobalIdKey];
  [environmentLogDict nullSafeSetObject:[environmentLog odometer] forKey:FPEnvironmentLogOdometerKey];
  [environmentLogDict nullSafeSetObject:[environmentLog reportedDte] forKey:FPEnvironmentLogReportedDteKey];
  [environmentLogDict nullSafeSetObject:[environmentLog reportedAvgMpg] forKey:FPEnvironmentLogReportedAvgMpgKey];
  [environmentLogDict nullSafeSetObject:[environmentLog reportedAvgMph] forKey:FPEnvironmentLogReportedAvgMphKey];
  [environmentLogDict nullSafeSetObject:[environmentLog reportedOutsideTemp] forKey:FPEnvironmentLogReportedOutsideTempKey];
  [environmentLogDict setMillisecondsSince1970FromDate:[environmentLog logDate]
                                                forKey:FPEnvironmentLogLogDateKey];
  return environmentLogDict;
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                        mediaType:(HCMediaType *)mediaType
                         location:(NSString *)location
                     lastModified:(NSDate *)lastModified {
  FPEnvironmentLog *envlog = [FPEnvironmentLog envLogWithOdometer:[PEUtils nullSafeDecimalNumberFromString:[resDict[FPEnvironmentLogOdometerKey] description]]
                                                   reportedAvgMpg:[PEUtils nullSafeDecimalNumberFromString:[resDict[FPEnvironmentLogReportedAvgMpgKey] description]]
                                                   reportedAvgMph:[PEUtils nullSafeDecimalNumberFromString:[resDict[FPEnvironmentLogReportedAvgMphKey] description]]
                                              reportedOutsideTemp:resDict[FPEnvironmentLogReportedOutsideTempKey]
                                                          logDate:[resDict dateSince1970ForKey:FPEnvironmentLogLogDateKey]
                                                      reportedDte:resDict[FPEnvironmentLogReportedDteKey]
                                                 globalIdentifier:location
                                                        mediaType:mediaType
                                                        relations:relations
                                                        createdAt:[resDict dateSince1970ForKey:FPEnvironmentLogCreatedAtKey]
                                                        deletedAt:[resDict dateSince1970ForKey:FPEnvironmentLogDeletedAtKey]
                                                        updatedAt:[resDict dateSince1970ForKey:FPEnvironmentLogUpdatedAtKey]];
  [envlog setVehicleGlobalIdentifier:resDict[FPEnvironmentLogVehicleGlobalIdKey]];
  return envlog;
}

@end
