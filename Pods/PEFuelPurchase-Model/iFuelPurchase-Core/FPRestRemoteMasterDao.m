//
//  FPRestRemoteMasterDao.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/18/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPRestRemoteMasterDao.h"

#import <PEObjc-Commons/PEUtils.h>
#import <PEObjc-Commons/NSMutableDictionary+PEAdditions.h>

#import <PEHateoas-Client/HCRelationExecutor.h>
#import <PEHateoas-Client/HCUtils.h>
#import <PEHateoas-Client/HCRelation.h>
#import <PEHateoas-Client/HCAuthentication.h>
#import <PEHateoas-Client/HCMediaType.h>
#import <PEHateoas-Client/HCCharset.h>

#import <PELocal-Data/PELMLoginUser.h>
#import <PELocal-Data/PERemoteMasterDao.h>
#import <PELocal-Data/PEChangelogSerializer.h>
#import <PELocal-Data/PEUserSerializer.h>
#import <PELocal-Data/PELoginSerializer.h>
#import <PELocal-Data/PELogoutSerializer.h>
#import <PELocal-Data/PEResendVerificationEmailSerializer.h>
#import <PELocal-Data/PEPasswordResetSerializer.h>

#import "FPErrorDomainsAndCodes.h"
#import "FPRemoteDaoErrorDomains.h"
#import "FPKnownMediaTypes.h"
#import "FPChangelog.h"
#import "FPUser.h"
#import "FPVehicle.h"
#import "FPFuelStation.h"
#import "FPFuelPurchaseLog.h"
#import "FPEnvironmentLog.h"
#import "FPPriceStreamFilterCriteria.h"

#import "FPVehicleSerializer.h"
#import "FPFuelStationSerializer.h"
#import "FPFuelPurchaseLogSerializer.h"
#import "FPEnvironmentLogSerializer.h"
#import "FPPriceEventStreamSerializer.h"

NSString * const FPPriceEventStreamRelation = @"price-event-stream";

@implementation FPRestRemoteMasterDao {
  FPVehicleSerializer *_vehicleSerializer;
  FPFuelStationSerializer *_fuelStationSerializer;
  FPFuelPurchaseLogSerializer *_fuelPurchaseLogSerializer;
  FPEnvironmentLogSerializer *_environmentLogSerializer;
  FPPriceEventStreamSerializer *_priceEventStreamSerializer;
}

#pragma mark - Initializers

- (id)initWithAcceptCharset:(HCCharset *)acceptCharset
             acceptLanguage:(NSString *)acceptLanguage
         contentTypeCharset:(HCCharset *)contentTypeCharset
                 authScheme:(NSString *)authScheme
         authTokenParamName:(NSString *)authTokenParamName
                  authToken:(NSString *)authToken
        errorMaskHeaderName:(NSString *)errorMaskHeaderName
 establishSessionHeaderName:(NSString *)establishHeaderSessionName
        authTokenHeaderName:(NSString *)authTokenHeaderName
  ifModifiedSinceHeaderName:(NSString *)ifModifiedSinceHeaderName
ifUnmodifiedSinceHeaderName:(NSString *)ifUnmodifiedSinceHeaderName
loginFailedReasonHeaderName:(NSString *)loginFailedReasonHeaderName
accountClosedReasonHeaderName:(NSString *)accountClosedReasonHeaderName
bundleHoldingApiJsonResource:(NSBundle *)bundle
  nameOfApiJsonResourceFile:(NSString *)apiResourceFileName
            apiResMtVersion:(NSString *)apiResMtVersion
             userSerializer:(PEUserSerializer *)userSerializer
        changelogSerializer:(PEChangelogSerializer *)changelogSerializer
            loginSerializer:(PELoginSerializer *)loginSerializer
           logoutSerializer:(PELogoutSerializer *)logoutSerializer
resendVerificationEmailSerializer:(PEResendVerificationEmailSerializer *)resendVerificationEmailSerializer
passwordResetSerializer:(PEPasswordResetSerializer *)passwordResetSerializer
          vehicleSerializer:(FPVehicleSerializer *)vehicleSerializer
      fuelStationSerializer:(FPFuelStationSerializer *)fuelStationSerializer
  fuelPurchaseLogSerializer:(FPFuelPurchaseLogSerializer *)fuelPurchaseLogSerializer
   environmentLogSerializer:(FPEnvironmentLogSerializer *)environmentLogSerializer
 priceEventStreamSerializer:(FPPriceEventStreamSerializer *)priceEventStreamSerializer
   allowInvalidCertificates:(BOOL)allowInvalidCertificates {
  self = [super initWithAcceptCharset:acceptCharset
                       acceptLanguage:acceptLanguage
                   contentTypeCharset:contentTypeCharset
                           authScheme:authScheme
                   authTokenParamName:authTokenParamName
                            authToken:authToken
                  errorMaskHeaderName:errorMaskHeaderName
           establishSessionHeaderName:establishHeaderSessionName
                  authTokenHeaderName:authTokenHeaderName
            ifModifiedSinceHeaderName:ifModifiedSinceHeaderName
          ifUnmodifiedSinceHeaderName:ifUnmodifiedSinceHeaderName
          loginFailedReasonHeaderName:loginFailedReasonHeaderName
        accountClosedReasonHeaderName:accountClosedReasonHeaderName
         bundleHoldingApiJsonResource:bundle
            nameOfApiJsonResourceFile:apiResourceFileName
                      apiResMtVersion:apiResMtVersion
                       userSerializer:userSerializer
                  changelogSerializer:changelogSerializer
                      loginSerializer:loginSerializer
                     logoutSerializer:logoutSerializer
    resendVerificationEmailSerializer:resendVerificationEmailSerializer
              passwordResetSerializer:passwordResetSerializer
             allowInvalidCertificates:allowInvalidCertificates
             clientFaultedErrorDomain:FPClientFaultedErrorDomain
               userFaultedErrorDomain:FPUserFaultedErrorDomain
             systemFaultedErrorDomain:FPSystemFaultedErrorDomain
               connFaultedErrorDomain:FPConnFaultedErrorDomain
                     restApiRelations:[HCUtils relsFromLocalHalJsonResource:bundle
                                                                   fileName:apiResourceFileName
                                                       resourceApiMediaType:[FPKnownMediaTypes apiMediaTypeWithVersion:apiResMtVersion]]];
  if (self) {
    _vehicleSerializer = vehicleSerializer;
    _fuelStationSerializer = fuelStationSerializer;
    _fuelPurchaseLogSerializer = fuelPurchaseLogSerializer;
    _environmentLogSerializer = environmentLogSerializer;
    _priceEventStreamSerializer = priceEventStreamSerializer;
  }
  return self;
}

#pragma mark - Price Stream Helpers

- (void)fetchPriceStreamNearLat:(NSDecimalNumber *)latitude
                           long:(NSDecimalNumber *)longitude
                 distanceWithin:(NSInteger)distanceWithin
                     maxResults:(NSInteger)maxResults
                         sortBy:(NSString *)sortBy
                        timeout:(NSInteger)timeout
                remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
              completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  HCRelation *priceStreamRealtion = self.restApiRelations[FPPriceEventStreamRelation];
  FPPriceStreamFilterCriteria *filterCriteria =
  [[FPPriceStreamFilterCriteria alloc] initWithNearLatitude:latitude
                                              nearLongitude:longitude
                                             distanceWithin:distanceWithin
                                                 maxResults:maxResults
                                                     sortBy:sortBy];
  [self doPostToRelation:priceStreamRealtion
      resourceModelParam:filterCriteria
              serializer:_priceEventStreamSerializer
                 timeout:timeout
         remoteStoreBusy:busyHandler
            authRequired:nil
       completionHandler:complHandler
            otherHeaders:@{}];
}

#pragma mark - Price Stream Operations

- (void)fetchPriceStreamSortedByPriceDistanceNearLat:(NSDecimalNumber *)latitude
                                                long:(NSDecimalNumber *)longitude
                                      distanceWithin:(NSInteger)distanceWithin
                                          maxResults:(NSInteger)maxResults
                                             timeout:(NSInteger)timeout
                                     remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                                   completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self fetchPriceStreamNearLat:latitude
                           long:longitude
                 distanceWithin:distanceWithin
                     maxResults:maxResults
                         sortBy:@"price"
                        timeout:timeout
                remoteStoreBusy:busyHandler
              completionHandler:complHandler];
}

- (void)fetchPriceStreamSortedByDistancePriceNearLat:(NSDecimalNumber *)latitude
                                                long:(NSDecimalNumber *)longitude
                                      distanceWithin:(NSInteger)distanceWithin
                                          maxResults:(NSInteger)maxResults
                                             timeout:(NSInteger)timeout
                                     remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                                   completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self fetchPriceStreamNearLat:latitude
                           long:longitude
                 distanceWithin:distanceWithin
                     maxResults:maxResults
                         sortBy:@"distance"
                        timeout:timeout
                remoteStoreBusy:busyHandler
              completionHandler:complHandler];
}

#pragma mark - Vehicle Operations

- (void)saveNewVehicle:(FPVehicle *)vehicle
               forUser:(FPUser *)user
               timeout:(NSInteger)timeout
       remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
          authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
     completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self doPostToRelation:[[user relations] objectForKey:FPVehiclesRelation]
      resourceModelParam:vehicle
              serializer:_vehicleSerializer
                 timeout:timeout
         remoteStoreBusy:busyHandler
            authRequired:authRequired
       completionHandler:complHandler
            otherHeaders:@{}];
}

- (void)saveExistingVehicle:(FPVehicle *)vehicle
                    timeout:(NSInteger)timeout
            remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
               authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
          completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self.relationExecutor doPutForTargetResource:[FPRestRemoteMasterDao resourceFromModel:vehicle]
                               targetSerializer:_vehicleSerializer
                                   asynchronous:YES
                                completionQueue:self.serialQueue
                                  authorization:[self authorization]
                                        success:[self newPutSuccessBlk:complHandler]
                                    redirection:[self newRedirectionBlk:complHandler]
                                    clientError:[self newClientErrBlk:complHandler]
                         authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                                    serverError:[self newServerErrBlk:complHandler]
                               unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                                       conflict:[self newConflictBlk:complHandler]
                              connectionFailure:[self newConnFailureBlk:complHandler]
                                        timeout:timeout
                                   otherHeaders:[self addFpIfUnmodifiedSinceHeaderToHeader:@{} entity:vehicle]];
}

- (void)deleteVehicle:(FPVehicle *)vehicle
              timeout:(NSInteger)timeout
      remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
         authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
    completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self.relationExecutor doDeleteOfTargetResource:[FPRestRemoteMasterDao resourceFromModel:vehicle]
                          wouldBeTargetSerializer:_vehicleSerializer
                                     asynchronous:YES
                                  completionQueue:self.serialQueue
                                    authorization:[self authorization]
                                          success:[self newDeleteSuccessBlk:complHandler]
                                      redirection:[self newRedirectionBlk:complHandler]
                                      clientError:[self newClientErrBlk:complHandler]
                           authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                                      serverError:[self newServerErrBlk:complHandler]
                                 unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                                         conflict:[self newConflictBlk:complHandler]
                                connectionFailure:[self newConnFailureBlk:complHandler]
                                          timeout:timeout
                                     otherHeaders:[self addFpIfUnmodifiedSinceHeaderToHeader:@{} entity:vehicle]];
}

- (void)fetchVehicleWithGlobalId:(NSString *)globalId
                 ifModifiedSince:(NSDate *)ifModifiedSince
                         timeout:(NSInteger)timeout
                 remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                    authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
               completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self.relationExecutor doGetForURLString:globalId
                                parameters:nil
                           ifModifiedSince:nil
                          targetSerializer:_vehicleSerializer
                              asynchronous:YES
                           completionQueue:self.serialQueue
                             authorization:[self authorization]
                                   success:[self newGetSuccessBlk:complHandler]
                               redirection:[self newRedirectionBlk:complHandler]
                               clientError:[self newClientErrBlk:complHandler]
                    authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                               serverError:[self newServerErrBlk:complHandler]
                          unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                         connectionFailure:[self newConnFailureBlk:complHandler]
                                   timeout:timeout
                               cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                              otherHeaders:[self addDateHeaderToHeaders:@{}
                                                             headerName:self.ifModifiedSinceHeaderName
                                                                  value:ifModifiedSince]];
}

#pragma mark - Fuel Station Operations

- (void)saveNewFuelStation:(FPFuelStation *)fuelStation
                   forUser:(FPUser *)user
                   timeout:(NSInteger)timeout
           remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
              authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
         completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self doPostToRelation:[[user relations] objectForKey:FPFuelStationsRelation]
      resourceModelParam:fuelStation
              serializer:_fuelStationSerializer
                 timeout:timeout
         remoteStoreBusy:busyHandler
            authRequired:authRequired
       completionHandler:complHandler
            otherHeaders:@{}];
}

- (void)saveExistingFuelStation:(FPFuelStation *)fuelStation
                        timeout:(NSInteger)timeout
                remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                   authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
              completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self.relationExecutor doPutForTargetResource:[FPRestRemoteMasterDao resourceFromModel:fuelStation]
                               targetSerializer:_fuelStationSerializer
                                   asynchronous:YES
                                completionQueue:self.serialQueue
                                  authorization:[self authorization]
                                        success:[self newPutSuccessBlk:complHandler]
                                    redirection:[self newRedirectionBlk:complHandler]
                                    clientError:[self newClientErrBlk:complHandler]
                         authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                                    serverError:[self newServerErrBlk:complHandler]
                               unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                                       conflict:[self newConflictBlk:complHandler]
                              connectionFailure:[self newConnFailureBlk:complHandler]
                                        timeout:timeout
                                   otherHeaders:[self addFpIfUnmodifiedSinceHeaderToHeader:@{} entity:fuelStation]];
}

- (void)deleteFuelStation:(FPFuelStation *)fuelStation
                  timeout:(NSInteger)timeout
          remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
             authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
        completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self.relationExecutor doDeleteOfTargetResource:[FPRestRemoteMasterDao resourceFromModel:fuelStation]
                          wouldBeTargetSerializer:_fuelStationSerializer
                                     asynchronous:YES
                                  completionQueue:self.serialQueue
                                    authorization:[self authorization]
                                          success:[self newDeleteSuccessBlk:complHandler]
                                      redirection:[self newRedirectionBlk:complHandler]
                                      clientError:[self newClientErrBlk:complHandler]
                           authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                                      serverError:[self newServerErrBlk:complHandler]
                                 unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                                         conflict:[self newConflictBlk:complHandler]
                                connectionFailure:[self newConnFailureBlk:complHandler]
                                          timeout:timeout
                                     otherHeaders:[self addFpIfUnmodifiedSinceHeaderToHeader:@{} entity:fuelStation]];
}

- (void)fetchFuelstationWithGlobalId:(NSString *)globalId
                     ifModifiedSince:(NSDate *)ifModifiedSince
                             timeout:(NSInteger)timeout
                     remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                        authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                   completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self.relationExecutor doGetForURLString:globalId
                                parameters:nil
                           ifModifiedSince:nil
                          targetSerializer:_fuelStationSerializer
                              asynchronous:YES
                           completionQueue:self.serialQueue
                             authorization:[self authorization]
                                   success:[self newGetSuccessBlk:complHandler]
                               redirection:[self newRedirectionBlk:complHandler]
                               clientError:[self newClientErrBlk:complHandler]
                    authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                               serverError:[self newServerErrBlk:complHandler]
                          unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                         connectionFailure:[self newConnFailureBlk:complHandler]
                                   timeout:timeout
                               cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                              otherHeaders:[self addDateHeaderToHeaders:@{} headerName:self.ifModifiedSinceHeaderName value:ifModifiedSince]];
}

#pragma mark - Fuel Purchase Log Operations

- (void)saveNewFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                       forUser:(FPUser *)user
                       timeout:(NSInteger)timeout
               remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                  authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
             completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self doPostToRelation:[[user relations] objectForKey:FPFuelPurchaseLogsRelation]
      resourceModelParam:fuelPurchaseLog
              serializer:_fuelPurchaseLogSerializer
                 timeout:timeout
         remoteStoreBusy:busyHandler
            authRequired:authRequired
       completionHandler:complHandler
            otherHeaders:@{}];
}

- (void)saveExistingFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                            timeout:(NSInteger)timeout
                    remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                       authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                  completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self.relationExecutor doPutForTargetResource:[FPRestRemoteMasterDao resourceFromModel:fuelPurchaseLog]
                               targetSerializer:_fuelPurchaseLogSerializer
                                   asynchronous:YES
                                completionQueue:self.serialQueue
                                  authorization:[self authorization]
                                        success:[self newPutSuccessBlk:complHandler]
                                    redirection:[self newRedirectionBlk:complHandler]
                                    clientError:[self newClientErrBlk:complHandler]
                         authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                                    serverError:[self newServerErrBlk:complHandler]
                               unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                                       conflict:[self newConflictBlk:complHandler]
                              connectionFailure:[self newConnFailureBlk:complHandler]
                                        timeout:timeout
                                   otherHeaders:[self addFpIfUnmodifiedSinceHeaderToHeader:@{} entity:fuelPurchaseLog]];
}

- (void)deleteFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                      timeout:(NSInteger)timeout
              remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                 authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
            completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self.relationExecutor doDeleteOfTargetResource:[FPRestRemoteMasterDao resourceFromModel:fuelPurchaseLog]
                          wouldBeTargetSerializer:_fuelPurchaseLogSerializer
                                     asynchronous:YES
                                  completionQueue:self.serialQueue
                                    authorization:[self authorization]
                                          success:[self newDeleteSuccessBlk:complHandler]
                                      redirection:[self newRedirectionBlk:complHandler]
                                      clientError:[self newClientErrBlk:complHandler]
                           authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                                      serverError:[self newServerErrBlk:complHandler]
                                 unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                                         conflict:[self newConflictBlk:complHandler]
                                connectionFailure:[self newConnFailureBlk:complHandler]
                                          timeout:timeout
                                     otherHeaders:[self addFpIfUnmodifiedSinceHeaderToHeader:@{} entity:fuelPurchaseLog]];
}

- (void)fetchFuelPurchaseLogWithGlobalId:(NSString *)globalId
                         ifModifiedSince:(NSDate *)ifModifiedSince
                                 timeout:(NSInteger)timeout
                         remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                            authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                       completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self.relationExecutor doGetForURLString:globalId
                                parameters:nil
                           ifModifiedSince:nil
                          targetSerializer:_fuelPurchaseLogSerializer
                              asynchronous:YES
                           completionQueue:self.serialQueue
                             authorization:[self authorization]
                                   success:[self newGetSuccessBlk:complHandler]
                               redirection:[self newRedirectionBlk:complHandler]
                               clientError:[self newClientErrBlk:complHandler]
                    authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                               serverError:[self newServerErrBlk:complHandler]
                          unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                         connectionFailure:[self newConnFailureBlk:complHandler]
                                   timeout:timeout
                               cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                              otherHeaders:[self addDateHeaderToHeaders:@{} headerName:self.ifModifiedSinceHeaderName value:ifModifiedSince]];
}

#pragma mark - Environment Log Operations

- (void)saveNewEnvironmentLog:(FPEnvironmentLog *)environmentLog
                      forUser:(FPUser *)user
                      timeout:(NSInteger)timeout
              remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                 authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
            completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self doPostToRelation:[[user relations] objectForKey:FPEnvironmentLogsRelation]
      resourceModelParam:environmentLog
              serializer:_environmentLogSerializer
                 timeout:timeout
         remoteStoreBusy:busyHandler
            authRequired:authRequired
       completionHandler:complHandler
            otherHeaders:@{}];
}

- (void)saveExistingEnvironmentLog:(FPEnvironmentLog *)environmentLog
                           timeout:(NSInteger)timeout
                   remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                      authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                 completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self.relationExecutor doPutForTargetResource:[FPRestRemoteMasterDao resourceFromModel:environmentLog]
                               targetSerializer:_environmentLogSerializer
                                   asynchronous:YES
                                completionQueue:self.serialQueue
                                  authorization:[self authorization]
                                        success:[self newPutSuccessBlk:complHandler]
                                    redirection:[self newRedirectionBlk:complHandler]
                                    clientError:[self newClientErrBlk:complHandler]
                         authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                                    serverError:[self newServerErrBlk:complHandler]
                               unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                                       conflict:[self newConflictBlk:complHandler]
                              connectionFailure:[self newConnFailureBlk:complHandler]
                                        timeout:timeout
                                   otherHeaders:[self addFpIfUnmodifiedSinceHeaderToHeader:@{} entity:environmentLog]];
}

- (void)deleteEnvironmentLog:(FPEnvironmentLog *)environmentLog
                     timeout:(NSInteger)timeout
             remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
           completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self.relationExecutor doDeleteOfTargetResource:[FPRestRemoteMasterDao resourceFromModel:environmentLog]
                          wouldBeTargetSerializer:_environmentLogSerializer
                                     asynchronous:YES
                                  completionQueue:self.serialQueue
                                    authorization:[self authorization]
                                          success:[self newDeleteSuccessBlk:complHandler]
                                      redirection:[self newRedirectionBlk:complHandler]
                                      clientError:[self newClientErrBlk:complHandler]
                           authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                                      serverError:[self newServerErrBlk:complHandler]
                                 unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                                         conflict:[self newConflictBlk:complHandler]
                                connectionFailure:[self newConnFailureBlk:complHandler]
                                          timeout:timeout
                                     otherHeaders:[self addFpIfUnmodifiedSinceHeaderToHeader:@{} entity:environmentLog]];
}

- (void)fetchEnvironmentLogWithGlobalId:(NSString *)globalId
                        ifModifiedSince:(NSDate *)ifModifiedSince
                                timeout:(NSInteger)timeout
                        remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                           authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                      completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self.relationExecutor doGetForURLString:globalId
                                parameters:nil
                           ifModifiedSince:nil
                          targetSerializer:_environmentLogSerializer
                              asynchronous:YES
                           completionQueue:self.serialQueue
                             authorization:[self authorization]
                                   success:[self newGetSuccessBlk:complHandler]
                               redirection:[self newRedirectionBlk:complHandler]
                               clientError:[self newClientErrBlk:complHandler]
                    authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                               serverError:[self newServerErrBlk:complHandler]
                          unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                         connectionFailure:[self newConnFailureBlk:complHandler]
                                   timeout:timeout
                               cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                              otherHeaders:[self addDateHeaderToHeaders:@{} headerName:self.ifModifiedSinceHeaderName value:ifModifiedSince]];
}

@end
