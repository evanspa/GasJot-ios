//
//  FPUser.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 7/26/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPUser.h"
#import <PEObjc-Commons/PEUtils.h>
#import "FPDDLUtils.h"

NSString * const FPChangelogRelation = @"changelog";
NSString * const FPVehiclesRelation = @"vehicles";
NSString * const FPFuelStationsRelation = @"fuelstations";
NSString * const FPFuelPurchaseLogsRelation = @"fuelpurchase-logs";
NSString * const FPEnvironmentLogsRelation = @"environment-logs";

NSString * const FPUserNameField = @"FPUserNameField";
NSString * const FPUserEmailField = @"FPUserEmailField";
NSString * const FPUserVerifiedAtField = @"FPUserVerifiedAtField";

@implementation FPUser {
  NSMutableArray *_vehicles;
  NSMutableArray *_fuelStations;
  NSMutableArray *_fuelPurchaseLogs;
  NSMutableArray *_environmentLogs;
}

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
                       verifiedAt:(NSDate *)verifiedAt {
  self = [super initWithLocalMainIdentifier:localMainIdentifier
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
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
                                syncRetryAt:syncRetryAt
                                       name:name
                                      email:email
                                   password:password
                                 verifiedAt:verifiedAt];
  if (self) {
    _vehicles = [NSMutableArray array];
    _fuelStations = [NSMutableArray array];
    _fuelPurchaseLogs = [NSMutableArray array];
    _environmentLogs = [NSMutableArray array];
  }
  return self;
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone {
  FPUser *copy = [[FPUser alloc] initWithLocalMainIdentifier:[self localMainIdentifier]
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
                                                        name:[self name]
                                                       email:[self email]
                                                    password:[self password]
                                                  verifiedAt:[self verifiedAt]];
  return copy;
}

#pragma mark - Creation Functions

+ (FPUser *)userWithName:(NSString *)name
                   email:(NSString *)email
                password:(NSString *)password
               mediaType:(HCMediaType *)mediaType {
  return (FPUser *)[PELMUser userOfClass:[FPUser class]
                                withName:name
                                   email:email
                                password:password
                               mediaType:mediaType];
}

+ (FPUser *)userWithName:(NSString *)name
                   email:(NSString *)email
                password:(NSString *)password
              verifiedAt:(NSDate *)verifiedAt
        globalIdentifier:(NSString *)globalIdentifier
               mediaType:(HCMediaType *)mediaType
               relations:(NSDictionary *)relations
               createdAt:(NSDate *)createdAt
               deletedAt:(NSDate *)deletedAt
               updatedAt:(NSDate *)updatedAt {
  return (FPUser *)[PELMUser userOfClass:[FPUser class]
                                withName:name
                                   email:email
                                password:password
                              verifiedAt:verifiedAt
                        globalIdentifier:globalIdentifier
                               mediaType:mediaType
                               relations:relations
                               createdAt:createdAt
                               deletedAt:deletedAt
                               updatedAt:updatedAt];
}

#pragma mark - Merging

+ (NSDictionary *)mergeRemoteUser:(FPUser *)remoteUser
                    withLocalUser:(FPUser *)localUser
                  localMasterUser:(FPUser *)localMasterUser {
  return [PEUtils mergeRemoteObject:remoteUser
                    withLocalObject:localUser
                previousLocalObject:localMasterUser
        getterSetterKeysComparators:@[@[[NSValue valueWithPointer:@selector(name)],
                                        [NSValue valueWithPointer:@selector(setName:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isStringProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPUser * localObject, FPUser * remoteObject) {[localObject setName:[remoteObject name]];},
                                        FPUserNameField],
                                      @[[NSValue valueWithPointer:@selector(email)],
                                        [NSValue valueWithPointer:@selector(setEmail:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isStringProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPUser * localObject, FPUser * remoteObject) {[localObject setEmail:[remoteObject email]];},
                                        FPUserEmailField]]];
}

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(FPUser *)user {
  [super overwriteDomainProperties:user];
  [self setEmail:[user email]];
  [self setName:[user name]];
  [self setVerifiedAt:[user verifiedAt]];
}

- (void)overwrite:(FPUser *)user {
  [super overwrite:user];
  [self overwriteDomainProperties:user];
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

#pragma mark - Known Relation Names

+ (NSString *)vehiclesRelation {
  return FPVehiclesRelation;
}

+ (NSString *)fuelStationsRelation {
  return FPFuelStationsRelation;
}

@end
