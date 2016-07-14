//
//  FPFuelStation.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 9/4/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

@import CoreLocation;

#import <PEObjc-Commons/PEUtils.h>
#import "FPFuelStation.h"
#import "FPDDLUtils.h"
#import "FPFuelStationType.h"

NSString * const FPFuelstationNameField = @"FPFuelstationNameField";
NSString * const FPFuelstationTypeField = @"FPFuelstationTypeField";
NSString * const FPFuelstationStreetField = @"FPFuelstationStreetField";
NSString * const FPFuelstationCityField = @"FPFuelstationCityField";
NSString * const FPFuelstationStateField = @"FPFuelstationStateField";
NSString * const FPFuelstationZipField = @"FPFuelstationZipField";
NSString * const FPFuelstationLatitudeField = @"FPFuelstationLatitudeField";
NSString * const FPFuelstationLongitudeField = @"FPFuelstationLongitudeField";

@implementation FPFuelStation

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
                        longitude:(NSDecimalNumber *)longitude {
  self = [super initWithLocalMainIdentifier:localMainIdentifier
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
                            mainEntityTable:TBL_MAIN_FUEL_STATION
                          masterEntityTable:TBL_MASTER_FUEL_STATION
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
    _type = type;
    _street = street;
    _city = city;
    _state = state;
    _zip = zip;
    _latitude = latitude;
    _longitude = longitude;
  }
  return self;
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone {
  FPFuelStation *copy = [[FPFuelStation alloc] initWithLocalMainIdentifier:[self localMainIdentifier]
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
                                                                      type:_type
                                                                    street:_street
                                                                      city:_city
                                                                     state:_state
                                                                       zip:_zip
                                                                  latitude:_latitude
                                                                 longitude:_longitude];
  return copy;
}

#pragma mark - Creation Functions

+ (FPFuelStation *)fuelStationWithName:(NSString *)name
                                  type:(FPFuelStationType *)type
                                street:(NSString *)street
                                  city:(NSString *)city
                                 state:(NSString *)state
                                   zip:(NSString *)zip
                              latitude:(NSDecimalNumber *)latitude
                             longitude:(NSDecimalNumber *)longitude
                             mediaType:(HCMediaType *)mediaType {
  return [FPFuelStation fuelStationWithName:name
                                       type:type
                                     street:street
                                       city:city
                                      state:state
                                        zip:zip
                                   latitude:latitude
                                  longitude:longitude
                           globalIdentifier:nil
                                  mediaType:mediaType
                                  relations:nil
                                  createdAt:nil
                                  deletedAt:nil
                                  updatedAt:nil];
}

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
                             updatedAt:(NSDate *)updatedAt {
  return [[FPFuelStation alloc] initWithLocalMainIdentifier:nil
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
                                                       type:type
                                                     street:street
                                                       city:city
                                                      state:state
                                                        zip:zip
                                                   latitude:latitude
                                                  longitude:longitude];
}

+ (FPFuelStation *)fuelStationWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier {
  return [[FPFuelStation alloc] initWithLocalMainIdentifier:nil
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
                                                       type:nil
                                                     street:nil
                                                       city:nil
                                                      state:nil
                                                        zip:nil
                                                   latitude:nil
                                                  longitude:nil];
}

#pragma mark - Merging

+ (NSDictionary *)mergeRemoteFuelstation:(FPFuelStation *)remoteFuelstation
                    withLocalFuelstation:(FPFuelStation *)localFuelstation
                  localMasterFuelstation:(FPFuelStation *)localMasterFuelstation {
  return [PEUtils mergeRemoteObject:remoteFuelstation
                    withLocalObject:localFuelstation
                previousLocalObject:localMasterFuelstation
        getterSetterKeysComparators:@[@[[NSValue valueWithPointer:@selector(name)],
                                        [NSValue valueWithPointer:@selector(setName:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isStringProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPFuelStation * localObject, FPFuelStation * remoteObject) {[localObject setName:[remoteObject name]];},
                                        FPFuelstationNameField],
                                      @[[NSValue valueWithPointer:@selector(type)],
                                        [NSValue valueWithPointer:@selector(setType:)],
                                        ^(SEL getter, FPFuelStation *obj1, FPFuelStation *obj2) {return [obj1.type isEqualToFuelStationType:obj2.type];},
                                        ^(FPFuelStation * localObject, FPFuelStation * remoteObject) {[localObject setType:[remoteObject type]];},
                                        FPFuelstationTypeField],
                                      @[[NSValue valueWithPointer:@selector(street)],
                                        [NSValue valueWithPointer:@selector(setStreet:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isStringProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPFuelStation * localObject, FPFuelStation * remoteObject) {[localObject setStreet:[remoteObject street]];},
                                        FPFuelstationStreetField],
                                      @[[NSValue valueWithPointer:@selector(city)],
                                        [NSValue valueWithPointer:@selector(setCity:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isStringProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPFuelStation * localObject, FPFuelStation * remoteObject) {[localObject setCity:[remoteObject city]];},
                                        FPFuelstationCityField],
                                      @[[NSValue valueWithPointer:@selector(state)],
                                        [NSValue valueWithPointer:@selector(setState:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isStringProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPFuelStation * localObject, FPFuelStation * remoteObject) {[localObject setState:[remoteObject state]];},
                                        FPFuelstationStateField],
                                      @[[NSValue valueWithPointer:@selector(zip)],
                                        [NSValue valueWithPointer:@selector(setZip:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isStringProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPFuelStation * localObject, FPFuelStation * remoteObject) {[localObject setZip:[remoteObject zip]];},
                                        FPFuelstationZipField],
                                      @[[NSValue valueWithPointer:@selector(latitude)],
                                        [NSValue valueWithPointer:@selector(setLatitude:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isNumProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPFuelStation * localObject, FPFuelStation * remoteObject) {[localObject setLatitude:[remoteObject latitude]];},
                                        FPFuelstationLatitudeField],
                                      @[[NSValue valueWithPointer:@selector(longitude)],
                                        [NSValue valueWithPointer:@selector(setLongitude:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isNumProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPFuelStation * localObject, FPFuelStation * remoteObject) { [localObject setLongitude:[remoteObject longitude]];},
                                        FPFuelstationLongitudeField]]];
}

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(FPFuelStation *)fuelstation {
  [super overwriteDomainProperties:fuelstation];
  [self setName:[fuelstation name]];
  [self setType:[fuelstation type]];
  [self setStreet:[fuelstation street]];
  [self setCity:[fuelstation city]];
  [self setState:[fuelstation state]];
  [self setZip:[fuelstation zip]];
  [self setLatitude:[fuelstation latitude]];
  [self setLongitude:[fuelstation longitude]];
}

- (void)overwrite:(FPFuelStation *)fuelstation {
  [super overwrite:fuelstation];
  [self overwriteDomainProperties:fuelstation];
}

#pragma mark - Methods

- (CLLocation *)location {
  if ((_latitude && ![_latitude isEqual:[NSNull null]] && ![_latitude isEqual:[NSDecimalNumber notANumber]]) &&
      (_longitude && ![_longitude isEqual:[NSNull null]] && ![_longitude isEqual:[NSDecimalNumber notANumber]])) {
    return [[CLLocation alloc] initWithLatitude:[_latitude doubleValue] longitude:[_longitude doubleValue]];
  }
  return nil;
}

#pragma mark - Equality

- (BOOL)isEqualToFuelStation:(FPFuelStation *)fuelStation {
  if (!fuelStation) { return NO; }
  if ([super isEqualToMainSupport:fuelStation]) {
    return [PEUtils isString:[self name] equalTo:[fuelStation name]] &&
      [[self type] isEqualToFuelStationType:[fuelStation type]];
  }
  return NO;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[FPFuelStation class]]) { return NO; }
  return [self isEqualToFuelStation:object];
}

- (NSUInteger)hash {
  return [super hash] ^
  [[self name] hash] ^
  [[self type] hash] ^
  [[self street] hash] ^
  [[self city] hash] ^
  [[self state] hash] ^
  [[self zip] hash] ^
  [[self latitude] hash] ^
  [[self longitude] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, name: [%@], type: [%@], street: [%@], city: [%@], state: [%@], zip: [%@], latitude: [%@], \
longitude: [%@]]",
          [super description], _name, _type, _street, _city, _state, _zip, _latitude, _longitude];
}

@end
