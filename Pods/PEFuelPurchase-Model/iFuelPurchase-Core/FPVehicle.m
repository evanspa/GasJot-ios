//
//  FPVehicle.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 7/29/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPVehicle.h"
#import <PEObjc-Commons/PEUtils.h>
#import "FPDDLUtils.h"

NSString * const FPVehicleNameField = @"FPVehicleNameField";
NSString * const FPVehicleDefaultOctaneField = @"FPVehicleDefaultOctaneField";
NSString * const FPVehicleFuelCapacityField = @"FPVehicleFuelCapacityField";
NSString * const FPVehicleIsDieselField = @"FPVehicleIsDieselField";
NSString * const FPVehicleHasDteReadoutField = @"FPVehicleHasDteReadoutField";
NSString * const FPVehicleHasMpgReadoutField = @"FPVehicleHasMpgReadoutField";
NSString * const FPVehicleHasMphReadoutField = @"FPVehicleHasMphReadoutField";
NSString * const FPVehicleHasOutsideTempReadoutField = @"FPVehicleHasOutsideTempReadoutField";
NSString * const FPVehicleVinField = @"FPVehicleVinField";
NSString * const FPVehiclePlateField = @"FPVehiclePlateField";

@implementation FPVehicle

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
                            plate:(NSString *)plate {
  self = [super initWithLocalMainIdentifier:localMainIdentifier
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
                            mainEntityTable:TBL_MAIN_VEHICLE
                          masterEntityTable:TBL_MASTER_VEHICLE
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
    _name = name;
    _defaultOctane = defaultOctane;
    _fuelCapacity = fuelCapacity;
    _isDiesel = isDiesel;
    _hasDteReadout = hasDteReadout;
    _hasMpgReadout = hasMpgReadout;
    _hasMphReadout = hasMphReadout;
    _hasOutsideTempReadout = hasOutsideTempReadout;
    _vin = vin;
    _plate = plate;
  }
  return self;
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone {
  FPVehicle *copy = [[FPVehicle alloc] initWithLocalMainIdentifier:[self localMainIdentifier]
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
                                                              name:_name
                                                     defaultOctane:_defaultOctane
                                                      fuelCapacity:_fuelCapacity
                                                          isDiesel:_isDiesel
                                                     hasDteReadout:_hasDteReadout
                                                     hasMpgReadout:_hasMpgReadout
                                                     hasMphReadout:_hasMphReadout
                                             hasOutsideTempReadout:_hasOutsideTempReadout
                                                               vin:_vin
                                                             plate:_plate];
  return copy;
}

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
                     mediaType:(HCMediaType *)mediaType {
  return [FPVehicle vehicleWithName:name
                      defaultOctane:defaultOctane
                       fuelCapacity:fuelCapacity
                           isDiesel:isDiesel
                      hasDteReadout:hasDteReadout
                      hasMpgReadout:hasMpgReadout
                      hasMphReadout:hasMphReadout
              hasOutsideTempReadout:hasOutsideTempReadout
                                vin:vin
                              plate:plate
                   globalIdentifier:nil
                          mediaType:mediaType
                          relations:nil
                          createdAt:nil
                          deletedAt:nil
                          updatedAt:nil];
}

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
                     updatedAt:(NSDate *)updatedAt {
  return [[FPVehicle alloc] initWithLocalMainIdentifier:nil
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
                                                   name:name
                                          defaultOctane:defaultOctane
                                           fuelCapacity:fuelCapacity
                                               isDiesel:isDiesel
                                          hasDteReadout:hasDteReadout
                                          hasMpgReadout:hasMpgReadout
                                          hasMphReadout:hasMphReadout
                                  hasOutsideTempReadout:hasOutsideTempReadout
                                                    vin:vin
                                                  plate:plate];
}

+ (FPVehicle *)vehicleWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier {
  return [[FPVehicle alloc] initWithLocalMainIdentifier:nil
                                  localMasterIdentifier:localMasterIdentifier
                                       globalIdentifier:nil
                                              mediaType:nil
                                              relations:nil
                                              createdAt:nil
                                              deletedAt:nil
                                              updatedAt:nil
                                   dateCopiedFromMaster:nil
                                         editInProgress:NO
                                         syncInProgress:NO
                                                 synced:NO
                                              editCount:0
                                       syncHttpRespCode:nil
                                            syncErrMask:nil
                                            syncRetryAt:nil
                                                   name:nil
                                          defaultOctane:nil
                                           fuelCapacity:nil
                                               isDiesel:NO
                                          hasDteReadout:NO
                                          hasMpgReadout:NO
                                          hasMphReadout:NO
                                  hasOutsideTempReadout:NO
                                                    vin:nil
                                                  plate:nil];
}

#pragma mark - Merging

+ (NSDictionary *)mergeRemoteVehicle:(FPVehicle *)remoteVehicle
                    withLocalVehicle:(FPVehicle *)localVehicle
                  localMasterVehicle:(FPVehicle *)localMasterVehicle {
  return [PEUtils mergeRemoteObject:remoteVehicle
                    withLocalObject:localVehicle
                previousLocalObject:localMasterVehicle
        getterSetterKeysComparators:@[@[[NSValue valueWithPointer:@selector(name)],
                                        [NSValue valueWithPointer:@selector(setName:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isStringProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPVehicle * localObject, FPVehicle * remoteObject) {[localObject setName:[remoteObject name]];},
                                        FPVehicleNameField],
                                      @[[NSValue valueWithPointer:@selector(defaultOctane)],
                                        [NSValue valueWithPointer:@selector(setDefaultOctane:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isNumProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPVehicle * localObject, FPVehicle * remoteObject) {[localObject setDefaultOctane:[remoteObject defaultOctane]];},
                                        FPVehicleDefaultOctaneField],
                                      @[[NSValue valueWithPointer:@selector(fuelCapacity)],
                                        [NSValue valueWithPointer:@selector(setFuelCapacity:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isNumProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPVehicle * localObject, FPVehicle * remoteObject) { [localObject setFuelCapacity:[remoteObject fuelCapacity]];},
                                        FPVehicleFuelCapacityField],
                                      @[[NSValue valueWithPointer:@selector(isDiesel)],
                                        [NSValue valueWithPointer:@selector(setIsDiesel:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isBoolProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPVehicle * localObject, FPVehicle * remoteObject) { [localObject setIsDiesel:[remoteObject isDiesel]];},
                                        FPVehicleIsDieselField],
                                      @[[NSValue valueWithPointer:@selector(hasDteReadout)],
                                        [NSValue valueWithPointer:@selector(setHasDteReadout:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isBoolProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPVehicle * localObject, FPVehicle * remoteObject) { [localObject setHasDteReadout:[remoteObject hasDteReadout]];},
                                        FPVehicleHasDteReadoutField],
                                      @[[NSValue valueWithPointer:@selector(hasMpgReadout)],
                                        [NSValue valueWithPointer:@selector(setHasMpgReadout:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isBoolProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPVehicle * localObject, FPVehicle * remoteObject) { [localObject setHasMpgReadout:[remoteObject hasMpgReadout]];},
                                        FPVehicleHasMpgReadoutField],
                                      @[[NSValue valueWithPointer:@selector(hasMphReadout)],
                                        [NSValue valueWithPointer:@selector(setHasMphReadout:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isBoolProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPVehicle * localObject, FPVehicle * remoteObject) { [localObject setHasMphReadout:[remoteObject hasMphReadout]];},
                                        FPVehicleHasMphReadoutField],
                                      @[[NSValue valueWithPointer:@selector(hasOutsideTempReadout)],
                                        [NSValue valueWithPointer:@selector(setHasOutsideTempReadout:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isBoolProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPVehicle * localObject, FPVehicle * remoteObject) { [localObject setHasOutsideTempReadout:[remoteObject hasOutsideTempReadout]];},
                                        FPVehicleHasOutsideTempReadoutField],
                                      @[[NSValue valueWithPointer:@selector(vin)],
                                        [NSValue valueWithPointer:@selector(setVin:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isStringProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPVehicle * localObject, FPVehicle * remoteObject) {[localObject setVin:[remoteObject vin]];},
                                        FPVehicleVinField],
                                      @[[NSValue valueWithPointer:@selector(plate)],
                                        [NSValue valueWithPointer:@selector(setPlate:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isStringProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPVehicle * localObject, FPVehicle * remoteObject) {[localObject setPlate:[remoteObject plate]];},
                                        FPVehiclePlateField]]];
}

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(FPVehicle *)vehicle {
  [super overwriteDomainProperties:vehicle];
  [self setName:[vehicle name]];
  [self setDefaultOctane:[vehicle defaultOctane]];
  [self setFuelCapacity:[vehicle fuelCapacity]];
  [self setIsDiesel:[vehicle isDiesel]];
  [self setHasDteReadout:[vehicle hasDteReadout]];
  [self setHasMpgReadout:[vehicle hasMpgReadout]];
  [self setHasMphReadout:[vehicle hasMphReadout]];
  [self setHasOutsideTempReadout:[vehicle hasOutsideTempReadout]];
  [self setVin:[vehicle vin]];
  [self setPlate:[vehicle plate]];
}

- (void)overwrite:(FPVehicle *)vehicle {
  [super overwrite:vehicle];
  [self overwriteDomainProperties:vehicle];
}

#pragma mark - Equality

- (BOOL)isEqualToVehicle:(FPVehicle *)vehicle {
  if (!vehicle) { return NO; }
  if ([super isEqualToMainSupport:vehicle]) {
    return [PEUtils isString:[self name] equalTo:[vehicle name]] &&
      [PEUtils isNumProperty:@selector(defaultOctane) equalFor:self and:vehicle] &&
      [PEUtils isNumProperty:@selector(fuelCapacity) equalFor:self and:vehicle] &&
      [PEUtils isBoolProperty:@selector(isDiesel) equalFor:self and:vehicle] &&
      [PEUtils isBoolProperty:@selector(hasDteReadout) equalFor:self and:vehicle] &&
      [PEUtils isBoolProperty:@selector(hasMpgReadout) equalFor:self and:vehicle] &&
      [PEUtils isBoolProperty:@selector(hasMphReadout) equalFor:self and:vehicle] &&
      [PEUtils isBoolProperty:@selector(hasOutsideTempReadout) equalFor:self and:vehicle] &&
      [PEUtils isString:[self vin] equalTo:[vehicle vin]] &&
      [PEUtils isString:[self plate] equalTo:[vehicle plate]];
  }
  return NO;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[FPVehicle class]]) { return NO; }
  return [self isEqualToVehicle:object];
}

- (NSUInteger)hash {
  return [super hash] ^
  [[self name] hash] ^
  [[self defaultOctane] hash] ^
  [[self fuelCapacity] hash] ^
  [[self vin] hash] ^
  [[self plate] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, name: [%@], default octane: [%@], fuel capacity: [%@], \
is diesel? [%d], has dte readout?: [%d], has mpg readout? [%d], has mph readout? [%d], \
has outside temp readout? [%d], vin: [%@], plate: [%@]",
          [super description],
          _name,
          _defaultOctane,
          _fuelCapacity,
          _isDiesel,
          _hasDteReadout,
          _hasMpgReadout,
          _hasMphReadout,
          _hasOutsideTempReadout,
          _vin,
          _plate];
}

@end
