//
//  FPCoordinator.h
//  Gas Jot Model
//
//  Created by Paul Evans on 12/12/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import <PELocal-Data/PELMDefs.h>

@protocol FPLocalDao;
@protocol PEAuthTokenDelegate;
@protocol PEUserCoordinatorDao;

@class HCCharset;
@class FPUser;
@class FPVehicle;
@class FPFuelStationType;
@class FPFuelStation;
@class FPFuelPurchaseLog;
@class FPEnvironmentLog;

@protocol FPCoordinatorDao <FPLocalDao>

#pragma mark - Initializers

/**
 @param authScheme When interacting with the remote master store, in an
 authenticated context, the user's authentication material (an auth token), is
 communicated via the standard "Authorization" HTTP request header.  The value
 of this header will be of the form: "SCHEME PARAM=VALUE".  This parameter serves
 as the "SCHEME" part.
 @param authTokenParamName As per the explanation on the authScheme param, this
 param serves as the "PARAM" part.
 @param authToken As per the explanation on the authScheme param, this param
 serves as the "VALUE" part.  If the user of this class happens to have their
 hands on an existing authentication token (perhaps they yanked one from the
 app's keychain), then they would provide it on this param; otherwise, nil can
 be passed.
 @param authTokenResponseHeaderName Upon establishing an authenticated session,
 the authentication token value will travel back to the client as a custom
 HTTP response header.  This param serves as the name of the header.
 @param authTokenDelegate
 */
- (id)initWithSqliteDataFilePath:(NSString *)sqliteDataFilePath
      localDatabaseCreationError:(PELMDaoErrorBlk)errorBlk
  timeoutForMainThreadOperations:(NSInteger)timeout
                   acceptCharset:(HCCharset *)acceptCharset
                  acceptLanguage:(NSString *)acceptLanguage
              contentTypeCharset:(HCCharset *)contentTypeCharset
                      authScheme:(NSString *)authScheme
              authTokenParamName:(NSString *)authTokenParamName
                       authToken:(NSString *)authToken
             errorMaskHeaderName:(NSString *)errorMaskHeaderName
      establishSessionHeaderName:(NSString *)establishHeaderSessionName
     authTokenResponseHeaderName:(NSString *)authTokenHeaderName
       ifModifiedSinceHeaderName:(NSString *)ifModifiedSinceHeaderName
     ifUnmodifiedSinceHeaderName:(NSString *)ifUnmodifiedSinceHeaderName
     loginFailedReasonHeaderName:(NSString *)loginFailedReasonHeaderName
   accountClosedReasonHeaderName:(NSString *)accountClosedReasonHeaderName
    bundleHoldingApiJsonResource:(NSBundle *)bundle
       nameOfApiJsonResourceFile:(NSString *)apiResourceFileName
                 apiResMtVersion:(NSString *)apiResourceMediaTypeVersion
           changelogResMtVersion:(NSString *)changelogResMtVersion
                userResMtVersion:(NSString *)userResMtVersion
             vehicleResMtVersion:(NSString *)vehicleResMtVersion
         fuelStationResMtVersion:(NSString *)fuelStationResMtVersion
     fuelPurchaseLogResMtVersion:(NSString *)fuelPurchaseLogResMtVersion
      environmentLogResMtVersion:(NSString *)environmentLogResMtVersion
    priceEventStreamResMtVersion:(NSString *)priceEventStreamResMtVersion
               authTokenDelegate:(id<PEAuthTokenDelegate>)authTokenDelegate
        allowInvalidCertificates:(BOOL)allowInvalidCertifications;

#pragma mark - Getters

- (id<PEUserCoordinatorDao>)userCoordinatorDao;

#pragma mark - Flushing All Unsynced Edits to Remote Master

- (NSInteger)flushAllUnsyncedEditsToRemoteForUser:(FPUser *)user
                                entityNotFoundBlk:(void(^)(float))entityNotFoundBlk
                                       successBlk:(void(^)(float))successBlk
                               remoteStoreBusyBlk:(void(^)(float, NSDate *))remoteStoreBusyBlk
                               tempRemoteErrorBlk:(void(^)(float))tempRemoteErrorBlk
                                   remoteErrorBlk:(void(^)(float, NSInteger))remoteErrorBlk
                                      conflictBlk:(void(^)(float, id))conflictBlk
                                  authRequiredBlk:(void(^)(float))authRequiredBlk
                                          allDone:(void(^)(void))allDoneBlk
                                            error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Unsynced Entities Check

- (BOOL)doesUserHaveAnyUnsyncedEntities:(FPUser *)user;

#pragma mark - Price Stream Operations

- (void)fetchPriceStreamSortedByPriceDistanceNearLat:(NSDecimalNumber *)latitude
                                                long:(NSDecimalNumber *)longitude
                                      distanceWithin:(NSInteger)distanceWithin
                                          maxResults:(NSInteger)maxResults
                                 notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                          successBlk:(void(^)(NSArray *))successBlk
                                  remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                                  tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk;

- (void)fetchPriceStreamSortedByDistancePriceNearLat:(NSDecimalNumber *)latitude
                                                long:(NSDecimalNumber *)longitude
                                      distanceWithin:(NSInteger)distanceWithin
                                          maxResults:(NSInteger)maxResults
                                 notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                          successBlk:(void(^)(NSArray *))successBlk
                                  remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                                  tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk;

#pragma mark - Vehicle

- (FPVehicle *)vehicleWithName:(NSString *)name
                 defaultOctane:(NSNumber *)defaultOctane
                  fuelCapacity:(NSDecimalNumber *)fuelCapacity
                      isDiesel:(BOOL)isDiesel
                 hasDteReadout:(BOOL)hasDteReadout
                 hasMpgReadout:(BOOL)hasMpgReadout
                 hasMphReadout:(BOOL)hasMphReadout
         hasOutsideTempReadout:(BOOL)hasOutsideTempReadout
                           vin:(NSString *)vin
                         plate:(NSString *)plate;

- (void)saveNewAndSyncImmediateVehicle:(FPVehicle *)vehicle
                               forUser:(FPUser *)user
                   notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                        addlSuccessBlk:(void(^)(void))addlSuccessBlk
                addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                    addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                       addlConflictBlk:(void(^)(id))addlConflictBlk
                   addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                 error:(PELMDaoErrorBlk)errorBlk;

- (void)flushUnsyncedChangesToVehicle:(FPVehicle *)vehicle
                              forUser:(FPUser *)user
                  notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                       addlSuccessBlk:(void(^)(void))addlSuccessBlk
               addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
               addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                   addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                      addlConflictBlk:(void(^)(FPVehicle *))addlConflictBlk
                  addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingAndSyncVehicleImmediate:(FPVehicle *)vehicle
                                         forUser:(FPUser *)user
                             notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                  addlSuccessBlk:(void(^)(void))addlSuccessBlk
                          addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                          addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                              addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                                 addlConflictBlk:(void(^)(FPVehicle *))addlConflictBlk
                             addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                           error:(PELMDaoErrorBlk)errorBlk;

- (void)deleteVehicle:(FPVehicle *)vehicle
              forUser:(FPUser *)user
  notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
       addlSuccessBlk:(void(^)(void))addlSuccessBlk
   remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
   tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
       remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
          conflictBlk:(void(^)(FPVehicle *))conflictBlk
  addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                error:(PELMDaoErrorBlk)errorBlk;

- (void)fetchVehicleWithGlobalId:(NSString *)globalIdentifier
                 ifModifiedSince:(NSDate *)ifModifiedSince
                         forUser:(FPUser *)user
             notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                      successBlk:(void(^)(FPVehicle *))successBlk
              remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
              tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
             addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk;

- (void)fetchAndSaveNewVehicleWithGlobalId:(NSString *)globalIdentifier
                                   forUser:(FPUser *)user
                       notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                            addlSuccessBlk:(void(^)(FPVehicle *))addlSuccessBlk
                        remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                        tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                       addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                     error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Fuel Station

- (FPFuelStation *)fuelStationWithName:(NSString *)name
                                  type:(FPFuelStationType *)type
                                street:(NSString *)street
                                  city:(NSString *)city
                                 state:(NSString *)state
                                   zip:(NSString *)zip
                              latitude:(NSDecimalNumber *)latitude
                             longitude:(NSDecimalNumber *)longitude;

- (void)saveNewAndSyncImmediateFuelStation:(FPFuelStation *)fuelStation
                                   forUser:(FPUser *)user
                       notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                            addlSuccessBlk:(void(^)(void))addlSuccessBlk
                    addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                    addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                        addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                           addlConflictBlk:(void(^)(id))addlConflictBlk
                       addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                     error:(PELMDaoErrorBlk)errorBlk;

- (void)flushUnsyncedChangesToFuelStation:(FPFuelStation *)fuelStation
                                  forUser:(FPUser *)user
                      notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                           addlSuccessBlk:(void(^)(void))addlSuccessBlk
                   addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                   addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                       addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                          addlConflictBlk:(void(^)(FPFuelStation *))addlConflictBlk
                      addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                    error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingAndSyncFuelStationImmediate:(FPFuelStation *)fuelStation
                                             forUser:(FPUser *)user
                                 notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                      addlSuccessBlk:(void(^)(void))addlSuccessBlk
                              addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                              addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                                  addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                                     addlConflictBlk:(void(^)(FPFuelStation *))addlConflictBlk
                                 addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                               error:(PELMDaoErrorBlk)errorBlk;

- (void)deleteFuelStation:(FPFuelStation *)fuelStation
                  forUser:(FPUser *)user
      notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
           addlSuccessBlk:(void(^)(void))addlSuccessBlk
       remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
       tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
           remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
              conflictBlk:(void(^)(FPFuelStation *))conflictBlk
      addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                    error:(PELMDaoErrorBlk)errorBlk;

- (void)fetchFuelstationWithGlobalId:(NSString *)globalIdentifier
                     ifModifiedSince:(NSDate *)ifModifiedSince
                             forUser:(FPUser *)user
                 notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                          successBlk:(void(^)(FPFuelStation *))successBlk
                  remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                  tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                 addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk;

- (void)fetchAndSaveNewFuelstationWithGlobalId:(NSString *)globalIdentifier
                                       forUser:(FPUser *)user
                           notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                addlSuccessBlk:(void(^)(FPFuelStation *))addlSuccessBlk
                            remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                            tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                           addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                         error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Fuel Purchase Log

- (FPFuelPurchaseLog *)fuelPurchaseLogWithNumGallons:(NSDecimalNumber *)numGallons
                                              octane:(NSNumber *)octane
                                            odometer:(NSDecimalNumber *)odometer
                                         gallonPrice:(NSDecimalNumber *)gallonPrice
                                          gotCarWash:(BOOL)gotCarWash
                            carWashPerGallonDiscount:(NSDecimalNumber *)carWashPerGallonDiscount
                                             logDate:(NSDate *)logDate
                                            isDiesel:(BOOL)isDiesel;

- (void)saveNewAndSyncImmediateFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                       forUser:(FPUser *)user
                                       vehicle:(FPVehicle *)vehicle
                                   fuelStation:(FPFuelStation *)fuelStation
                           notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                addlSuccessBlk:(void(^)(void))addlSuccessBlk
                        addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                        addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                            addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                               addlConflictBlk:(void(^)(id))addlConflictBlk
                           addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                  skippedDueToVehicleNotSynced:(void(^)(void))skippedDueToVehicleNotSynced
              skippedDueToFuelStationNotSynced:(void(^)(void))skippedDueToFuelStationNotSynced
                                         error:(PELMDaoErrorBlk)errorBlk;

- (void)flushUnsyncedChangesToFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                      forUser:(FPUser *)user
                          notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                               addlSuccessBlk:(void(^)(void))addlSuccessBlk
                       addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                       addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                           addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                              addlConflictBlk:(void(^)(FPFuelPurchaseLog *))addlConflictBlk
                          addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                 skippedDueToVehicleNotSynced:(void(^)(void))skippedDueToVehicleNotSynced
             skippedDueToFuelStationNotSynced:(void(^)(void))skippedDueToFuelStationNotSynced
                                        error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingAndSyncFuelPurchaseLogImmediate:(FPFuelPurchaseLog *)fuelPurchaseLog
                                                 forUser:(FPUser *)user
                                     notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                          addlSuccessBlk:(void(^)(void))addlSuccessBlk
                                  addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                                  addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                                      addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                                         addlConflictBlk:(void(^)(FPFuelPurchaseLog *))addlConflictBlk
                                     addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                            skippedDueToVehicleNotSynced:(void(^)(void))skippedDueToVehicleNotSynced
                        skippedDueToFuelStationNotSynced:(void(^)(void))skippedDueToFuelStationNotSynced
                                                   error:(PELMDaoErrorBlk)errorBlk;

- (void)deleteFuelPurchaseLog:(FPFuelPurchaseLog *)fplog
                      forUser:(FPUser *)user
          notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
               addlSuccessBlk:(void(^)(void))addlSuccessBlk
           remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
           tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
               remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                  conflictBlk:(void(^)(FPFuelPurchaseLog *))conflictBlk
          addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                        error:(PELMDaoErrorBlk)errorBlk;

- (void)fetchFuelPurchaseLogWithGlobalId:(NSString *)globalIdentifier
                         ifModifiedSince:(NSDate *)ifModifiedSince
                                 forUser:(FPUser *)user
                     notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                              successBlk:(void(^)(FPFuelPurchaseLog *))successBlk
                      remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                      tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                     addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk;

#pragma mark - Environment Log

- (FPEnvironmentLog *)environmentLogWithOdometer:(NSDecimalNumber *)odometer
                                  reportedAvgMpg:(NSDecimalNumber *)reportedAvgMpg
                                  reportedAvgMph:(NSDecimalNumber *)reportedAvgMph
                             reportedOutsideTemp:(NSNumber *)reportedOutsideTemp
                                         logDate:(NSDate *)logDate
                                     reportedDte:(NSNumber *)reportedDte;

- (void)saveNewAndSyncImmediateEnvironmentLog:(FPEnvironmentLog *)envLog
                                      forUser:(FPUser *)user
                                      vehicle:(FPVehicle *)vehicle
                          notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                               addlSuccessBlk:(void(^)(void))addlSuccessBlk
                       addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                       addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                           addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                              addlConflictBlk:(void(^)(id))addlConflictBlk
                          addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                 skippedDueToVehicleNotSynced:(void(^)(void))skippedDueToVehicleNotSynced
                                        error:(PELMDaoErrorBlk)errorBlk;

- (void)flushUnsyncedChangesToEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                     forUser:(FPUser *)user
                         notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                              addlSuccessBlk:(void(^)(void))addlSuccessBlk
                      addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                      addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                          addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                             addlConflictBlk:(void(^)(FPEnvironmentLog *))addlConflictBlk
                         addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                skippedDueToVehicleNotSynced:(void(^)(void))skippedDueToVehicleNotSynced
                                       error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingAndSyncEnvironmentLogImmediate:(FPEnvironmentLog *)envLog
                                                forUser:(FPUser *)user
                                    notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                         addlSuccessBlk:(void(^)(void))addlSuccessBlk
                                 addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                                 addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                                     addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                                        addlConflictBlk:(void(^)(FPEnvironmentLog *))addlConflictBlk
                                    addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                           skippedDueToVehicleNotSynced:(void(^)(void))skippedDueToVehicleNotSynced
                                                  error:(PELMDaoErrorBlk)errorBlk;

- (void)deleteEnvironmentLog:(FPEnvironmentLog *)envlog
                     forUser:(FPUser *)user
         notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
              addlSuccessBlk:(void(^)(void))addlSuccessBlk
          remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
          tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
              remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                 conflictBlk:(void(^)(FPEnvironmentLog *))conflictBlk
         addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                       error:(PELMDaoErrorBlk)errorBlk;

- (void)fetchEnvironmentLogWithGlobalId:(NSString *)globalIdentifier
                        ifModifiedSince:(NSDate *)ifModifiedSince
                                forUser:(FPUser *)user
                    notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                             successBlk:(void(^)(FPEnvironmentLog *))successBlk
                     remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                     tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                    addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk;

@end