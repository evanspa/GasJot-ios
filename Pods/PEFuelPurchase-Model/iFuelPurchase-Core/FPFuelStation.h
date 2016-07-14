//
//  FPFuelStation.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 9/4/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <PELocal-Data/PELMMainSupport.h>

@class CLLocation;
@class FPFuelStationType;

FOUNDATION_EXPORT NSString * const FPFuelstationNameField;
FOUNDATION_EXPORT NSString * const FPFuelstationTypeField;
FOUNDATION_EXPORT NSString * const FPFuelstationStreetField;
FOUNDATION_EXPORT NSString * const FPFuelstationCityField;
FOUNDATION_EXPORT NSString * const FPFuelstationStateField;
FOUNDATION_EXPORT NSString * const FPFuelstationZipField;
FOUNDATION_EXPORT NSString * const FPFuelstationLatitudeField;
FOUNDATION_EXPORT NSString * const FPFuelstationLongitudeField;

@interface FPFuelStation : PELMMainSupport <NSCopying>

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
                             type:(FPFuelStationType *)type
                           street:(NSString *)street
                             city:(NSString *)city
                            state:(NSString *)state
                              zip:(NSString *)zip
                         latitude:(NSDecimalNumber *)latitude
                        longitude:(NSDecimalNumber *)longitude;

#pragma mark - Creation Functions

+ (FPFuelStation *)fuelStationWithName:(NSString *)name
                                  type:(FPFuelStationType *)type
                                street:(NSString *)street
                                  city:(NSString *)city
                                 state:(NSString *)state
                                   zip:(NSString *)zip
                              latitude:(NSDecimalNumber *)latitude
                             longitude:(NSDecimalNumber *)longitude
                             mediaType:(HCMediaType *)mediaType;

+ (FPFuelStation *)fuelStationWithName:(NSString *)name
                                  type:(FPFuelStationType *)type
                                street:(NSString *)street
                                  city:(NSString *)city
                                 state:(NSString *)state
                                   zip:(NSString *)zip
                              latitude:(NSDecimalNumber *)latitude
                             longitude:(NSDecimalNumber *)longitude
                      globalIdentifier:(NSString *)globalIdentifier
                             mediaType:(HCMediaType *)mediaType
                             relations:(NSDictionary *)relations
                             createdAt:(NSDate *)createdAt
                             deletedAt:(NSDate *)deletedAt
                             updatedAt:(NSDate *)updatedAt;

+ (FPFuelStation *)fuelStationWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier;

#pragma mark - Merging

+ (NSDictionary *)mergeRemoteFuelstation:(FPFuelStation *)remoteFuelstation
                    withLocalFuelstation:(FPFuelStation *)localFuelstation
                  localMasterFuelstation:(FPFuelStation *)localMasterFuelstation;

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(FPFuelStation *)fuelstation;

- (void)overwrite:(FPFuelStation *)fuelstation;

#pragma mark - Methods

- (CLLocation *)location;

#pragma mark - Properties

@property (nonatomic) NSString *name;

@property (nonatomic) FPFuelStationType *type;

@property (nonatomic) NSString *street;

@property (nonatomic) NSString *city;

@property (nonatomic) NSString *state;

@property (nonatomic) NSString *zip;

@property (nonatomic) NSDecimalNumber *latitude;

@property (nonatomic) NSDecimalNumber *longitude;

#pragma mark - Equality

- (BOOL)isEqualToFuelStation:(FPFuelStation *)fuelStation;

@end
