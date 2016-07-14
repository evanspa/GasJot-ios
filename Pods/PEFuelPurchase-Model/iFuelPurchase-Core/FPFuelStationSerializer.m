//
//  FPFuelStationSerializer.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 9/3/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPFuelStationSerializer.h"
#import "FPFuelStation.h"
#import "FPFuelStationType.h"
#import <PEObjc-Commons/NSMutableDictionary+PEAdditions.h>
#import <PEObjc-Commons/NSDictionary+PEAdditions.h>
#import <PEHateoas-Client/HCUtils.h>
#import <PEObjc-Commons/PEUtils.h>
#import "FPCoordinatorDao.h"
#import "FPLocalDao.h"

NSString * const FPFuelStationNameKey      = @"fpfuelstation/name";
NSString * const FPFuelStationTypeIdKey    = @"fpfuelstation/type-id";
NSString * const FPFuelStationStreetKey    = @"fpfuelstation/street";
NSString * const FPFuelStationCityKey      = @"fpfuelstation/city";
NSString * const FPFuelStationStateKey     = @"fpfuelstation/state";
NSString * const FPFuelStationZipKey       = @"fpfuelstation/zip";
NSString * const FPFuelStationLatitudeKey  = @"fpfuelstation/latitude";
NSString * const FPFuelStationLongitudeKey = @"fpfuelstation/longitude";
NSString * const FPFuelStationCreatedAtKey = @"fpfuelstation/created-at";
NSString * const FPFuelStationUpdatedAtKey = @"fpfuelstation/updated-at";
NSString * const FPFuelStationDeletedAtKey = @"fpfuelstation/deleted-at";

@implementation FPFuelStationSerializer {
  id<FPCoordinatorDao> _coordDao;
  PELMDaoErrorBlk _errorBlk;
}

#pragma mark - Initializers

- (id)initWithMediaType:(HCMediaType *)mediaType
                charset:(HCCharset *)charset
serializersForEmbeddedResources:(NSDictionary *)embeddedSerializers
actionsForEmbeddedResources:(NSDictionary *)actions
         coordinatorDao:(id<FPCoordinatorDao>)coordinatorDao
                  error:(PELMDaoErrorBlk)errorBlk {
  self = [super initWithMediaType:mediaType
                          charset:charset
  serializersForEmbeddedResources:embeddedSerializers
      actionsForEmbeddedResources:actions];
  if (self) {
    _coordDao = coordinatorDao;
    _errorBlk = errorBlk;
  }
  return self;
}

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  FPFuelStation *fuelStation = (FPFuelStation *)resourceModel;
  NSMutableDictionary *fuelStationDict = [NSMutableDictionary dictionary];
  [fuelStationDict nullSafeSetObject:[fuelStation name] forKey:FPFuelStationNameKey];
  [fuelStationDict nullSafeSetObject:[fuelStation type].identifier forKey:FPFuelStationTypeIdKey];
  [fuelStationDict nullSafeSetObject:[fuelStation street] forKey:FPFuelStationStreetKey];
  [fuelStationDict nullSafeSetObject:[fuelStation city] forKey:FPFuelStationCityKey];
  [fuelStationDict nullSafeSetObject:[fuelStation state] forKey:FPFuelStationStateKey];
  [fuelStationDict nullSafeSetObject:[fuelStation zip] forKey:FPFuelStationZipKey];
  [fuelStationDict nullSafeSetObject:[fuelStation latitude] forKey:FPFuelStationLatitudeKey];
  [fuelStationDict nullSafeSetObject:[fuelStation longitude] forKey:FPFuelStationLongitudeKey];
  return fuelStationDict;
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                        mediaType:(HCMediaType *)mediaType
                         location:(NSString *)location
                     lastModified:(NSDate *)lastModified {
  NSNumber *fstypeIdentifier = [resDict objectForKey:FPFuelStationTypeIdKey];
  FPFuelStation *fuelstation =
  [FPFuelStation fuelStationWithName:[resDict objectForKey:FPFuelStationNameKey]
                                type:[_coordDao fuelstationTypeForIdentifier:fstypeIdentifier error:_errorBlk]
                              street:[resDict objectForKey:FPFuelStationStreetKey]
                                city:[resDict objectForKey:FPFuelStationCityKey]
                               state:[resDict objectForKey:FPFuelStationStateKey]
                                 zip:[resDict objectForKey:FPFuelStationZipKey]
                            latitude:[PEUtils nullSafeDecimalNumberFromString:[[resDict objectForKey:FPFuelStationLatitudeKey] description]]
                           longitude:[PEUtils nullSafeDecimalNumberFromString:[[resDict objectForKey:FPFuelStationLongitudeKey] description]]
                    globalIdentifier:location
                           mediaType:mediaType
                           relations:relations
                           createdAt:[resDict dateSince1970ForKey:FPFuelStationCreatedAtKey]
                           deletedAt:[resDict dateSince1970ForKey:FPFuelStationDeletedAtKey]
                           updatedAt:[resDict dateSince1970ForKey:FPFuelStationUpdatedAtKey]];
  return fuelstation;
}

@end
