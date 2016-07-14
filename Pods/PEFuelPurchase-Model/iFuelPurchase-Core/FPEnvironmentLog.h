//
//  FPEnvironmentLog.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 9/4/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <PELocal-Data/PELMMainSupport.h>

FOUNDATION_EXPORT NSString * const FPEnvlogOdometerField;
FOUNDATION_EXPORT NSString * const FPEnvlogReportedAvgMpgField;
FOUNDATION_EXPORT NSString * const FPEnvlogReportedAvgMphField;
FOUNDATION_EXPORT NSString * const FPEnvlogReportedOutsideTempField;
FOUNDATION_EXPORT NSString * const FPEnvlogLogDateField;
FOUNDATION_EXPORT NSString * const FPEnvlogReportedDteField;
FOUNDATION_EXPORT NSString * const FPEnvlogVehicleGlobalIdField;

@interface FPEnvironmentLog : PELMMainSupport <NSCopying>

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
                      reportedDte:(NSNumber *)reportedDte;

#pragma mark - Creation Functions

+ (FPEnvironmentLog *)envLogWithOdometer:(NSDecimalNumber *)odometer
                          reportedAvgMpg:(NSDecimalNumber *)reportedAvgMpg
                          reportedAvgMph:(NSDecimalNumber *)reportedAvgMph
                     reportedOutsideTemp:(NSNumber *)reportedOutsideTemp
                                 logDate:(NSDate *)logDate
                             reportedDte:(NSNumber *)reportedDte
                               mediaType:(HCMediaType *)mediaType;

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
                               updatedAt:(NSDate *)updatedAt;

#pragma mark - Merging

+ (NSDictionary *)mergeRemoteEnvlog:(FPEnvironmentLog *)remoteEnvlog
                    withLocalEnvlog:(FPEnvironmentLog *)localEnvlog
                  localMasterEnvlog:(FPEnvironmentLog *)localMasterEnvlog;

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(FPEnvironmentLog *)envlog;

- (void)overwrite:(FPEnvironmentLog *)envLog;

#pragma mark - Properties

@property (nonatomic) NSNumber *vehicleMainIdentifier;

@property (nonatomic) NSString *vehicleGlobalIdentifier;

@property (nonatomic) NSDecimalNumber *odometer;

@property (nonatomic) NSDecimalNumber *reportedAvgMpg;

@property (nonatomic) NSDecimalNumber *reportedAvgMph;

@property (nonatomic) NSNumber *reportedOutsideTemp;

@property (nonatomic) NSDate *logDate;

@property (nonatomic) NSNumber *reportedDte;

#pragma mark - Equality

- (BOOL)isEqualToEnvironmentLog:(FPEnvironmentLog *)envLog;

@end
