//
//  FPUser.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 7/26/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <PELocal-Data/PELMUser.h>

@class FPVehicle;
@class FPFuelStation;
@class FPFuelPurchaseLog;
@class FPEnvironmentLog;

FOUNDATION_EXPORT NSString * const FPChangelogRelation;
FOUNDATION_EXPORT NSString * const FPVehiclesRelation;
FOUNDATION_EXPORT NSString * const FPFuelStationsRelation;
FOUNDATION_EXPORT NSString * const FPFuelPurchaseLogsRelation;
FOUNDATION_EXPORT NSString * const FPEnvironmentLogsRelation;

FOUNDATION_EXPORT NSString * const FPUserNameField;
FOUNDATION_EXPORT NSString * const FPUserEmailField;
FOUNDATION_EXPORT NSString * const FPUserVerifiedAtField;

@interface FPUser : PELMUser <NSCopying>

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
                             name:(NSString *)name
                            email:(NSString *)email
                         password:(NSString *)password
                       verifiedAt:(NSDate *)verifiedAt;

#pragma mark - Creation Functions

+ (FPUser *)userWithName:(NSString *)name
                   email:(NSString *)email
                password:(NSString *)password
               mediaType:(HCMediaType *)mediaType;

+ (FPUser *)userWithName:(NSString *)name
                   email:(NSString *)email
                password:(NSString *)password
              verifiedAt:(NSDate *)verifiedAt
        globalIdentifier:(NSString *)globalIdentifier
               mediaType:(HCMediaType *)mediaType
               relations:(NSDictionary *)relations
               createdAt:(NSDate *)createdAt
               deletedAt:(NSDate *)deletedAt
               updatedAt:(NSDate *)updatedAt;

#pragma mark - Merging

+ (NSDictionary *)mergeRemoteUser:(FPUser *)remoteUser
                    withLocalUser:(FPUser *)localUser
                  localMasterUser:(FPUser *)localMasterUser;

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(FPUser *)user;

- (void)overwrite:(FPUser *)user;

#pragma mark - Methods

- (void)addVehicle:(FPVehicle *)vehicle;

- (void)addFuelStation:(FPFuelStation *)fuelStation;

- (void)addFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog;

- (void)addEnvironmentLog:(FPEnvironmentLog *)environmentLog;

- (NSArray *)vehicles;

- (NSArray *)fuelStations;

- (NSArray *)fuelPurchaseLogs;

- (NSArray *)environmentLogs;

#pragma mark - Known Relation Names

+ (NSString *)vehiclesRelation;

+ (NSString *)fuelStationsRelation;

@end
