//
//  FPEnvironmentLog.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 9/4/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <PEObjc-Commons/PEUtils.h>
#import "FPEnvironmentLog.h"
#import "FPDDLUtils.h"

NSString * const FPEnvlogOdometerField = @"FPEnvlogOdometerField";
NSString * const FPEnvlogReportedAvgMpgField = @"FPEnvlogReportedAvgMpgField";
NSString * const FPEnvlogReportedAvgMphField = @"FPEnvlogReportedAvgMphField";
NSString * const FPEnvlogReportedOutsideTempField = @"FPEnvlogReportedOutsideTempField";
NSString * const FPEnvlogLogDateField = @"FPEnvlogLogDateField";
NSString * const FPEnvlogReportedDteField = @"FPEnvlogReportedDteField";
NSString * const FPEnvlogVehicleGlobalIdField = @"FPEnvlogVehicleGlobalIdField";

@implementation FPEnvironmentLog

#pragma mark - Initializers

- (id)initWithLocalMainIdentifier:(NSNumber *)localMainIdentifier
            localMasterIdentifier:(NSNumber *)localMasterIdentifier
                 globalIdentifier:(NSString *)globalIdentifier
                        mediaType:(HCMediaType *)mediaType
                        relations:(NSDictionary *)relations
                        createdAt:(NSDate *)createdAt
                        deletedAt:(NSDate *)deletedAt
                        updatedAt:(NSDate *)updatedAt
             dateCopiedFromMaster:(NSDate *)dateCopiedFromMaster
                   editInProgress:(BOOL)editInProgress
                   syncInProgress:(BOOL)syncInProgress
                           synced:(BOOL)synced
                        editCount:(NSUInteger)editCount
                 syncHttpRespCode:(NSNumber *)syncHttpRespCode
                      syncErrMask:(NSNumber *)syncErrMask
                      syncRetryAt:(NSDate *)syncRetryAt
            vehicleMainIdentifier:(NSNumber *)vehicleMainIdentifier
                         odometer:(NSDecimalNumber *)odometer
                   reportedAvgMpg:(NSDecimalNumber *)reportedAvgMpg
                   reportedAvgMph:(NSDecimalNumber *)reportedAvgMph
              reportedOutsideTemp:(NSNumber *)reportedOutsideTemp
                          logDate:(NSDate *)logDate
                      reportedDte:(NSNumber *)reportedDte {
  self = [super initWithLocalMainIdentifier:localMainIdentifier
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
                            mainEntityTable:TBL_MAIN_ENV_LOG
                          masterEntityTable:TBL_MASTER_ENV_LOG
                                  mediaType:mediaType
                                  relations:relations
                                  createdAt:createdAt
                                  deletedAt:deletedAt
                                  updatedAt:updatedAt
                       dateCopiedFromMaster:dateCopiedFromMaster
                             editInProgress:editInProgress
                             syncInProgress:syncInProgress
                                     synced:synced
                                  editCount:editCount
                           syncHttpRespCode:syncHttpRespCode
                                syncErrMask:syncErrMask
                                syncRetryAt:syncRetryAt];
  if (self) {
    _vehicleMainIdentifier = vehicleMainIdentifier;
    _odometer = odometer;
    _reportedAvgMpg = reportedAvgMpg;
    _reportedAvgMph = reportedAvgMph;
    _reportedOutsideTemp = reportedOutsideTemp;
    _logDate = logDate;
    _reportedDte = reportedDte;
  }
  return self;
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone {
  FPEnvironmentLog *copy = [[FPEnvironmentLog alloc] initWithLocalMainIdentifier:[self localMainIdentifier]
                                                           localMasterIdentifier:[self localMasterIdentifier]
                                                                globalIdentifier:[self globalIdentifier]
                                                                       mediaType:[self mediaType]
                                                                       relations:[self relations]
                                                                       createdAt:[self createdAt]
                                                                       deletedAt:[self deletedAt]
                                                                       updatedAt:[self updatedAt]
                                                            dateCopiedFromMaster:[self dateCopiedFromMaster]
                                                                  editInProgress:[self editInProgress]
                                                                  syncInProgress:[self syncInProgress]
                                                                          synced:[self synced]
                                                                       editCount:[self editCount]
                                                                syncHttpRespCode:[self syncHttpRespCode]
                                                                     syncErrMask:[self syncErrMask]
                                                                     syncRetryAt:[self syncRetryAt]
                                                           vehicleMainIdentifier:_vehicleMainIdentifier
                                                                        odometer:_odometer
                                                                  reportedAvgMpg:_reportedAvgMpg
                                                                  reportedAvgMph:_reportedAvgMph
                                                             reportedOutsideTemp:_reportedOutsideTemp
                                                                         logDate:_logDate
                                                                     reportedDte:_reportedDte];
  return copy;
}

#pragma mark - Creation Functions

+ (FPEnvironmentLog *)envLogWithOdometer:(NSDecimalNumber *)odometer
                          reportedAvgMpg:(NSDecimalNumber *)reportedAvgMpg
                          reportedAvgMph:(NSDecimalNumber *)reportedAvgMph
                     reportedOutsideTemp:(NSNumber *)reportedOutsideTemp
                                 logDate:(NSDate *)logDate
                             reportedDte:(NSNumber *)reportedDte
                               mediaType:(HCMediaType *)mediaType {
  return [FPEnvironmentLog envLogWithOdometer:odometer
                               reportedAvgMpg:reportedAvgMpg
                               reportedAvgMph:reportedAvgMph
                          reportedOutsideTemp:reportedOutsideTemp
                                      logDate:logDate
                                  reportedDte:reportedDte
                             globalIdentifier:nil
                                    mediaType:mediaType
                                    relations:nil
                                    createdAt:nil
                                    deletedAt:nil
                                    updatedAt:nil];
}

+ (FPEnvironmentLog *)envLogWithOdometer:(NSDecimalNumber *)odometer
                          reportedAvgMpg:(NSDecimalNumber *)reportedAvgMpg
                          reportedAvgMph:(NSDecimalNumber *)reportedAvgMph
                     reportedOutsideTemp:(NSNumber *)reportedOutsideTemp
                                 logDate:(NSDate *)logDate
                             reportedDte:(NSNumber *)reportedDte
                        globalIdentifier:(NSString *)globalIdentifier
                               mediaType:(HCMediaType *)mediaType
                               relations:(NSDictionary *)relations
                               createdAt:(NSDate *)createdAt
                               deletedAt:(NSDate *)deletedAt
                               updatedAt:(NSDate *)updatedAt {
  return [[FPEnvironmentLog alloc] initWithLocalMainIdentifier:nil
                                         localMasterIdentifier:nil
                                              globalIdentifier:globalIdentifier
                                                     mediaType:mediaType
                                                     relations:relations
                                                     createdAt:createdAt
                                                     deletedAt:deletedAt
                                                     updatedAt:updatedAt
                                          dateCopiedFromMaster:nil
                                                editInProgress:NO
                                                syncInProgress:NO
                                                        synced:NO
                                                     editCount:0
                                              syncHttpRespCode:nil
                                                   syncErrMask:nil
                                                   syncRetryAt:nil
                                         vehicleMainIdentifier:nil
                                                      odometer:odometer
                                                reportedAvgMpg:reportedAvgMpg
                                                reportedAvgMph:reportedAvgMph
                                           reportedOutsideTemp:reportedOutsideTemp
                                                       logDate:logDate
                                                   reportedDte:reportedDte];
}

#pragma mark - Merging

+ (NSDictionary *)mergeRemoteEnvlog:(FPEnvironmentLog *)remoteEnvlog
                    withLocalEnvlog:(FPEnvironmentLog *)localEnvlog
                  localMasterEnvlog:(FPEnvironmentLog *)localMasterEnvlog {
  return [PEUtils mergeRemoteObject:remoteEnvlog
                    withLocalObject:localEnvlog
                previousLocalObject:localMasterEnvlog
        getterSetterKeysComparators:@[@[[NSValue valueWithPointer:@selector(odometer)],
                                        [NSValue valueWithPointer:@selector(setOdometer:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isNumProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPEnvironmentLog * localObject, FPEnvironmentLog * remoteObject) {[localObject setOdometer:[remoteObject odometer]];},
                                        FPEnvlogOdometerField],
                                      @[[NSValue valueWithPointer:@selector(reportedAvgMpg)],
                                        [NSValue valueWithPointer:@selector(setReportedAvgMpg:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isNumProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPEnvironmentLog * localObject, FPEnvironmentLog * remoteObject) {[localObject setReportedAvgMpg:[remoteObject reportedAvgMpg]];},
                                        FPEnvlogReportedAvgMpgField],
                                      @[[NSValue valueWithPointer:@selector(reportedAvgMph)],
                                        [NSValue valueWithPointer:@selector(setReportedAvgMph:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isNumProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPEnvironmentLog * localObject, FPEnvironmentLog * remoteObject) { [localObject setReportedAvgMph:[remoteObject reportedAvgMph]];},
                                        FPEnvlogReportedAvgMphField],
                                      @[[NSValue valueWithPointer:@selector(logDate)],
                                        [NSValue valueWithPointer:@selector(setLogDate:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isDateProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPEnvironmentLog * localObject, FPEnvironmentLog * remoteObject) { [localObject setLogDate:[remoteObject logDate]];},
                                        FPEnvlogLogDateField],
                                      @[[NSValue valueWithPointer:@selector(reportedOutsideTemp)],
                                        [NSValue valueWithPointer:@selector(setReportedOutsideTemp:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isNumProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPEnvironmentLog * localObject, FPEnvironmentLog * remoteObject) { [localObject setReportedOutsideTemp:[remoteObject reportedOutsideTemp]];},
                                        FPEnvlogReportedOutsideTempField],
                                      @[[NSValue valueWithPointer:@selector(reportedDte)],
                                        [NSValue valueWithPointer:@selector(setReportedDte:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isNumProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPEnvironmentLog * localObject, FPEnvironmentLog * remoteObject) { [localObject setReportedDte:[remoteObject reportedDte]];},
                                        FPEnvlogReportedDteField],
                                      @[[NSValue valueWithPointer:@selector(vehicleGlobalIdentifier)],
                                        [NSValue valueWithPointer:@selector(setVehicleGlobalIdentifier:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isStringProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPEnvironmentLog * localObject, FPEnvironmentLog * remoteObject) { [localObject setVehicleGlobalIdentifier:[remoteObject vehicleGlobalIdentifier]];},
                                        FPEnvlogVehicleGlobalIdField]]];
}

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(FPEnvironmentLog *)envlog {
  [super overwriteDomainProperties:envlog];
  [self setOdometer:[envlog odometer]];
  [self setReportedAvgMpg:[envlog reportedAvgMpg]];
  [self setReportedAvgMph:[envlog reportedAvgMph]];
  [self setReportedOutsideTemp:[envlog reportedOutsideTemp]];
  [self setLogDate:[envlog logDate]];
  [self setReportedDte:[envlog reportedDte]];
}

- (void)overwrite:(FPEnvironmentLog *)envlog {
  [super overwrite:envlog];
  [self overwriteDomainProperties:envlog];
}

#pragma mark - Equality

- (BOOL)isEqualToEnvironmentLog:(FPEnvironmentLog *)envLog {
  if (!envLog) { return NO; }
  if ([super isEqualToMainSupport:envLog]) {
    return [PEUtils isNumProperty:@selector(odometer) equalFor:self and:envLog] &&
      [PEUtils isNumProperty:@selector(reportedAvgMpg) equalFor:self and:envLog] &&
      [PEUtils isNumProperty:@selector(reportedAvgMph) equalFor:self and:envLog] &&
      [PEUtils isNumProperty:@selector(reportedOutsideTemp) equalFor:self and:envLog] &&
      [PEUtils isNumProperty:@selector(reportedDte) equalFor:self and:envLog] &&
      [PEUtils isDate:[self logDate] msprecisionEqualTo:[envLog logDate]];
  }
  return NO;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[FPEnvironmentLog class]]) { return NO; }
  return [self isEqualToEnvironmentLog:object];
}

- (NSUInteger)hash {
  return [super hash] ^
  [[self odometer] hash] ^
  [[self reportedAvgMpg] hash] ^
  [[self reportedAvgMph] hash] ^
  [[self reportedOutsideTemp] hash] ^
  [[self reportedDte] hash] ^
  [[self logDate] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, odometer: [%@], reported avg mpg: [%@], \
          reported avg mph: [%@], reported outside temp: [%@], \
          log date: [%@], reported DTE: [%@]", [super description],
          _odometer,
          _reportedAvgMpg,
          _reportedAvgMph,
          _reportedOutsideTemp,
          _logDate,
          _reportedDte];
}

@end
