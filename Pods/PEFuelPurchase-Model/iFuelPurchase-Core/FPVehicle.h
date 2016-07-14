//
//  FPVehicle.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 7/29/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <PELocal-Data/PELMMainSupport.h>

FOUNDATION_EXPORT NSString * const FPVehicleNameField;
FOUNDATION_EXPORT NSString * const FPVehicleDefaultOctaneField;
FOUNDATION_EXPORT NSString * const FPVehicleFuelCapacityField;
FOUNDATION_EXPORT NSString * const FPVehicleIsDieselField;
FOUNDATION_EXPORT NSString * const FPVehicleHasDteReadoutField;
FOUNDATION_EXPORT NSString * const FPVehicleHasMpgReadoutField;
FOUNDATION_EXPORT NSString * const FPVehicleHasMphReadoutField;
FOUNDATION_EXPORT NSString * const FPVehicleHasOutsideTempReadoutField;
FOUNDATION_EXPORT NSString * const FPVehicleVinField;
FOUNDATION_EXPORT NSString * const FPVehiclePlateField;

@interface FPVehicle : PELMMainSupport <NSCopying>

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
                    defaultOctane:(NSNumber *)defaultOctane
                     fuelCapacity:(NSDecimalNumber *)fuelCapacity
                         isDiesel:(BOOL)isDiesel
                    hasDteReadout:(BOOL)hasDteReadout
                    hasMpgReadout:(BOOL)hasMpgReadout
                    hasMphReadout:(BOOL)hasMphReadout
            hasOutsideTempReadout:(BOOL)hasOutsideTempReadout
                              vin:(NSString *)vin
                            plate:(NSString *)plate;

#pragma mark - Creation Functions

+ (FPVehicle *)vehicleWithName:(NSString *)name
                 defaultOctane:(NSNumber *)defaultOctane
                  fuelCapacity:(NSDecimalNumber *)fuelCapacity
                      isDiesel:(BOOL)isDiesel
                 hasDteReadout:(BOOL)hasDteReadout
                 hasMpgReadout:(BOOL)hasMpgReadout
                 hasMphReadout:(BOOL)hasMphReadout
         hasOutsideTempReadout:(BOOL)hasOutsideTempReadout
                           vin:(NSString *)vin
                         plate:(NSString *)plate
                     mediaType:(HCMediaType *)mediaType;

+ (FPVehicle *)vehicleWithName:(NSString *)name
                 defaultOctane:(NSNumber *)defaultOctane
                  fuelCapacity:(NSDecimalNumber *)fuelCapacity
                      isDiesel:(BOOL)isDiesel
                 hasDteReadout:(BOOL)hasDteReadout
                 hasMpgReadout:(BOOL)hasMpgReadout
                 hasMphReadout:(BOOL)hasMphReadout
         hasOutsideTempReadout:(BOOL)hasOutsideTempReadout
                           vin:(NSString *)vin
                         plate:(NSString *)plate
              globalIdentifier:(NSString *)globalIdentifier
                     mediaType:(HCMediaType *)mediaType
                     relations:(NSDictionary *)relations
                     createdAt:(NSDate *)createdAt
                     deletedAt:(NSDate *)deletedAt
                     updatedAt:(NSDate *)updatedAt;

+ (FPVehicle *)vehicleWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier;

#pragma mark - Merging

+ (NSDictionary *)mergeRemoteVehicle:(FPVehicle *)remoteVehicle
                    withLocalVehicle:(FPVehicle *)localVehicle
                  localMasterVehicle:(FPVehicle *)localMasterVehicle;

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(FPVehicle *)vehicle;

- (void)overwrite:(FPVehicle *)vehicle;

#pragma mark - Properties

@property (nonatomic) NSString *name;

@property (nonatomic) NSNumber *defaultOctane;

@property (nonatomic) NSDecimalNumber *fuelCapacity;

@property (nonatomic) BOOL isDiesel;

@property (nonatomic) BOOL hasDteReadout;

@property (nonatomic) BOOL hasMpgReadout;

@property (nonatomic) BOOL hasMphReadout;

@property (nonatomic) BOOL hasOutsideTempReadout;

@property (nonatomic) NSString *vin;

@property (nonatomic) NSString *plate;

#pragma mark - Equality

- (BOOL)isEqualToVehicle:(FPVehicle *)vehicle;

@end
