//
//  FPRemoteMasterDao.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/18/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

@import Foundation;
#import <PELocal-Data/PELMDefs.h>

@class HCAuthentication;
@protocol PERemoteMasterDao;
@class FPChangelog;
@class FPUser;
@class FPVehicle;
@class FPFuelStation;
@class FPFuelPurchaseLog;
@class FPEnvironmentLog;
@class FPPriceEvent;

@protocol FPRemoteMasterDao <PERemoteMasterDao>

#pragma mark - Price Stream Operations

- (void)fetchPriceStreamSortedByPriceDistanceNearLat:(NSDecimalNumber *)latitude
                                                long:(NSDecimalNumber *)longitude
                                      distanceWithin:(NSInteger)distanceWithin
                                          maxResults:(NSInteger)maxResults
                                             timeout:(NSInteger)timeout
                                     remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                                   completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)fetchPriceStreamSortedByDistancePriceNearLat:(NSDecimalNumber *)latitude
                                                long:(NSDecimalNumber *)longitude
                                      distanceWithin:(NSInteger)distanceWithin
                                          maxResults:(NSInteger)maxResults
                                             timeout:(NSInteger)timeout
                                     remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                                   completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

#pragma mark - Vehicle Operations

- (void)saveNewVehicle:(FPVehicle *)vehicle
               forUser:(FPUser *)user
               timeout:(NSInteger)timeout
       remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
          authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
     completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)saveExistingVehicle:(FPVehicle *)vehicle
                    timeout:(NSInteger)timeout
            remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
               authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
          completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)deleteVehicle:(FPVehicle *)vehicle
              timeout:(NSInteger)timeout
      remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
         authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
    completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)fetchVehicleWithGlobalId:(NSString *)globalId
                 ifModifiedSince:(NSDate *)ifModifiedSince
                         timeout:(NSInteger)timeout
                 remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                    authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
               completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

#pragma mark - Fuel Station Operations

- (void)saveNewFuelStation:(FPFuelStation *)fuelStation
                   forUser:(FPUser *)user
                   timeout:(NSInteger)timeout
           remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
              authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
         completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)saveExistingFuelStation:(FPFuelStation *)fuelStation
                        timeout:(NSInteger)timeout
                remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                   authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
              completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)deleteFuelStation:(FPFuelStation *)fuelStation
                  timeout:(NSInteger)timeout
          remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
             authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
        completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)fetchFuelstationWithGlobalId:(NSString *)globalId
                     ifModifiedSince:(NSDate *)ifModifiedSince
                             timeout:(NSInteger)timeout
                     remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                        authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                   completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

#pragma mark - Fuel Purchase Log Operations

- (void)saveNewFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                       forUser:(FPUser *)user
                       timeout:(NSInteger)timeout
               remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                  authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
             completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)saveExistingFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                            timeout:(NSInteger)timeout
                    remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                       authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                  completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)deleteFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                      timeout:(NSInteger)timeout
              remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                 authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
            completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)fetchFuelPurchaseLogWithGlobalId:(NSString *)globalId
                         ifModifiedSince:(NSDate *)ifModifiedSince
                                 timeout:(NSInteger)timeout
                         remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                            authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                       completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

#pragma mark - Environment Log Operations

- (void)saveNewEnvironmentLog:(FPEnvironmentLog *)fuelPurchaseLog
                      forUser:(FPUser *)user
                      timeout:(NSInteger)timeout
              remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                 authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
            completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)saveExistingEnvironmentLog:(FPEnvironmentLog *)fuelPurchaseLog
                           timeout:(NSInteger)timeout
                   remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                      authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                 completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)deleteEnvironmentLog:(FPEnvironmentLog *)fuelPurchaseLog
                     timeout:(NSInteger)timeout
             remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
           completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)fetchEnvironmentLogWithGlobalId:(NSString *)globalId
                        ifModifiedSince:(NSDate *)ifModifiedSince
                                timeout:(NSInteger)timeout
                        remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                           authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                      completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

@end
