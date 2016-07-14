//
//  FPCoordinatorDao.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/17/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

@import CoreLocation;

#import <CocoaLumberjack/DDLog.h>
#import <PEObjc-Commons/PEUtils.h>
#import <PEHateoas-Client/HCRelation.h>
#import <PEHateoas-Client/HCMediaType.h>

#import <PELocal-Data/PELMUtils.h>
#import <PELocal-Data/PELMNotificationUtils.h>
#import <PELocal-Data/PEUserCoordinatorDaoImpl.h>
#import <PELocal-Data/PEResendVerificationEmailSerializer.h>
#import <PELocal-Data/PEPasswordResetSerializer.h>
#import <PELocal-Data/PEChangelogSerializer.h>
#import <PELocal-Data/PEUserSerializer.h>
#import <PELocal-Data/PELoginSerializer.h>
#import <PELocal-Data/PELogoutSerializer.h>

#import "FPUser.h"
#import "FPVehicle.h"
#import "FPFuelStation.h"
#import "FPFuelPurchaseLog.h"
#import "FPEnvironmentLog.h"
#import "FPCoordinatorDaoImpl.h"
#import "FPErrorDomainsAndCodes.h"
#import "FPLocalDaoImpl.h"
#import "FPRestRemoteMasterDao.h"
#import "FPRemoteDaoErrorDomains.h"
#import "FPKnownMediaTypes.h"
#import "FPLogging.h"
#import "FPChangelog.h"
#import "FPVehicleSerializer.h"
#import "FPFuelStationSerializer.h"
#import "FPFuelPurchaseLogSerializer.h"
#import "FPEnvironmentLogSerializer.h"
#import "FPPriceEventStreamSerializer.h"

@implementation FPCoordinatorDaoImpl {
  id<FPRemoteMasterDao> _remoteMasterDao;
  NSInteger _timeout;
  NSString *_authScheme;
  NSString *_authTokenParamName;
  NSString *_apiResMtVersion;
  NSString *_changelogResMtVersion;
  NSString *_userResMtVersion;
  NSString *_vehicleResMtVersion;
  NSString *_fuelStationResMtVersion;
  NSString *_fuelPurchaseLogResMtVersion;
  NSString *_environmentLogResMtVersion;
  NSString *_priceEventStreamResMtVersion;
  id<PEUserCoordinatorDao> _userCoordDao;
}

#pragma mark - Initializers

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
                 apiResMtVersion:(NSString *)apiResMtVersion
           changelogResMtVersion:(NSString *)changelogResMtVersion
                userResMtVersion:(NSString *)userResMtVersion
             vehicleResMtVersion:(NSString *)vehicleResMtVersion
         fuelStationResMtVersion:(NSString *)fuelStationResMtVersion
     fuelPurchaseLogResMtVersion:(NSString *)fuelPurchaseLogResMtVersion
      environmentLogResMtVersion:(NSString *)environmentLogResMtVersion
    priceEventStreamResMtVersion:(NSString *)priceEventStreamResMtVersion
               authTokenDelegate:(id<PEAuthTokenDelegate>)authTokenDelegate
        allowInvalidCertificates:(BOOL)allowInvalidCertificates {
  self = [super initWithSqliteDataFilePath:sqliteDataFilePath];
  if (self) {
    _timeout = timeout;
    _authScheme = authScheme;
    _authTokenParamName = authTokenParamName;
    _apiResMtVersion = apiResMtVersion;
    _changelogResMtVersion = changelogResMtVersion;
    _userResMtVersion = userResMtVersion;
    _vehicleResMtVersion = vehicleResMtVersion;
    _fuelStationResMtVersion = fuelStationResMtVersion;
    _fuelPurchaseLogResMtVersion = fuelPurchaseLogResMtVersion;
    _environmentLogResMtVersion = environmentLogResMtVersion;
    _priceEventStreamResMtVersion = priceEventStreamResMtVersion;

    FPPriceEventStreamSerializer *priceEventStreamSerializer = [self priceEventStreamSerializerForCharset:acceptCharset error:errorBlk];
    FPEnvironmentLogSerializer *environmentLogSerializer = [self environmentLogSerializerForCharset:acceptCharset];
    FPFuelPurchaseLogSerializer *fuelPurchaseLogSerializer = [self fuelPurchaseLogSerializerForCharset:acceptCharset];
    FPVehicleSerializer *vehicleSerializer = [self vehicleSerializerForCharset:acceptCharset];
    FPFuelStationSerializer *fuelStationSerializer = [self fuelStationSerializerForCharset:acceptCharset error:errorBlk];
    PEUserSerializer *userSerializer = [self userSerializerForCharset:acceptCharset
                                                    vehicleSerializer:vehicleSerializer
                                                fuelStationSerializer:fuelStationSerializer
                                            fuelPurchaseLogSerializer:fuelPurchaseLogSerializer
                                             environmentLogSerializer:environmentLogSerializer];
    PEChangelogSerializer *changelogSerializer = [self changelogSerializerForCharset:acceptCharset
                                                                      userSerializer:userSerializer
                                                                   vehicleSerializer:vehicleSerializer
                                                               fuelStationSerializer:fuelStationSerializer
                                                           fuelPurchaseLogSerializer:fuelPurchaseLogSerializer
                                                            environmentLogSerializer:environmentLogSerializer];
    PELoginSerializer *loginSerializer = [[PELoginSerializer alloc] initWithMediaType:[FPKnownMediaTypes userMediaTypeWithVersion:_userResMtVersion]
                                                                              charset:acceptCharset
                                                                       userSerializer:userSerializer];
    PELogoutSerializer *logoutSerializer = [self logoutSerializerForCharset:acceptCharset];
    PEResendVerificationEmailSerializer *resendVerificationEmailSerializer = [self resendVerificationEmailSerializerForCharset:acceptCharset];
    PEPasswordResetSerializer *passwordResetSerializer = [self passwordResetSerializerForCharset:acceptCharset];
    _remoteMasterDao = [[FPRestRemoteMasterDao alloc] initWithAcceptCharset:acceptCharset
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
                                                          vehicleSerializer:vehicleSerializer
                                                      fuelStationSerializer:fuelStationSerializer
                                                  fuelPurchaseLogSerializer:fuelPurchaseLogSerializer
                                                   environmentLogSerializer:environmentLogSerializer
                                                 priceEventStreamSerializer:priceEventStreamSerializer
                                                   allowInvalidCertificates:allowInvalidCertificates];
    _userCoordDao = [[PEUserCoordinatorDaoImpl alloc] initWithRemoteMasterDao:_remoteMasterDao
                                                                     localDao:self
                                                                    userMaker:^PELMUser *(NSString *name, NSString *email, NSString *password) {
                                                                      return [FPUser userWithName:name
                                                                                            email:email
                                                                                         password:password
                                                                                        mediaType:[FPKnownMediaTypes userMediaTypeWithVersion:_userResMtVersion]];
                                                                    }
                                                      timeoutForMainThreadOps:timeout
                                                            authTokenDelegate:authTokenDelegate
                                                       userFaultedErrorDomain:FPUserFaultedErrorDomain
                                                     systemFaultedErrorDomain:FPSystemFaultedErrorDomain
                                                       connFaultedErrorDomain:FPConnFaultedErrorDomain
                                                           signInAnyIssuesBit:FPSignInAnyIssues
                                                        signInInvalidEmailBit:FPSignInInvalidEmail
                                                    signInEmailNotProvidedBit:FPSignInEmailNotProvided
                                                      signInPwdNotProvidedBit:FPSignInPasswordNotProvided
                                                  signInInvalidCredentialsBit:FPSignInInvalidCredentials
                                                     sendPwdResetAnyIssuesBit:FPSendPasswordResetAnyIssues
                                                  sendPwdResetUnknownEmailBit:FPSendPasswordResetUnknownEmail
                                                          saveUsrAnyIssuesBit:FPSaveUsrAnyIssues
                                                       saveUsrInvalidEmailBit:FPSaveUsrInvalidEmail
                                                   saveUsrEmailNotProvidedBit:FPSaveUsrEmailNotProvided
                                                     saveUsrPwdNotProvidedBit:FPSaveUsrPasswordNotProvided
                                             saveUsrEmailAlreadyRegisteredBit:FPSaveUsrEmailAlreadyRegistered
                                             saveUsrConfirmPwdOnlyProvidedBit:FPSaveUsrConfirmPasswordOnlyProvided
                                              saveUsrConfirmPwdNotProvidedBit:FPSaveUsrConfirmPasswordNotProvided
                                             saveUsrPwdConfirmPwdDontMatchBit:FPSaveUsrPasswordConfirmPasswordDontMatch
                                                            changeLogRelation:FPChangelogRelation];
  }
  return self;
}

#pragma mark - Helpers

- (FPEnvironmentLogSerializer *)environmentLogSerializerForCharset:(HCCharset *)charset {
  return [[FPEnvironmentLogSerializer alloc] initWithMediaType:[FPKnownMediaTypes environmentLogMediaTypeWithVersion:_environmentLogResMtVersion]
                                                       charset:charset
                               serializersForEmbeddedResources:@{}
                                   actionsForEmbeddedResources:@{}];
}

- (FPFuelPurchaseLogSerializer *)fuelPurchaseLogSerializerForCharset:(HCCharset *)charset {
  return [[FPFuelPurchaseLogSerializer alloc] initWithMediaType:[FPKnownMediaTypes fuelPurchaseLogMediaTypeWithVersion:_fuelPurchaseLogResMtVersion]
                                                        charset:charset
                                serializersForEmbeddedResources:@{}
                                    actionsForEmbeddedResources:@{}];
}

- (FPFuelStationSerializer *)fuelStationSerializerForCharset:(HCCharset *)charset
                                                       error:(PELMDaoErrorBlk)errorBlk {
  return [[FPFuelStationSerializer alloc] initWithMediaType:[FPKnownMediaTypes fuelStationMediaTypeWithVersion:_fuelStationResMtVersion]
                                                    charset:charset
                            serializersForEmbeddedResources:@{}
                                actionsForEmbeddedResources:@{}
                                             coordinatorDao:self
                                                      error:errorBlk];
}

- (FPPriceEventStreamSerializer *)priceEventStreamSerializerForCharset:(HCCharset *)charset
                                                                 error:(PELMDaoErrorBlk)errorBlk {
  return [[FPPriceEventStreamSerializer alloc] initWithMediaType:[FPKnownMediaTypes priceStreamMediaTypeWithVersion:_priceEventStreamResMtVersion]
                                                         charset:charset
                                 serializersForEmbeddedResources:@{}
                                     actionsForEmbeddedResources:@{}
                                                  coordinatorDao:self
                                                           error:errorBlk];
}

- (FPVehicleSerializer *)vehicleSerializerForCharset:(HCCharset *)charset {
  return [[FPVehicleSerializer alloc] initWithMediaType:[FPKnownMediaTypes vehicleMediaTypeWithVersion:_vehicleResMtVersion]
                                                charset:charset
                        serializersForEmbeddedResources:@{}
                            actionsForEmbeddedResources:@{}];
}

- (PELogoutSerializer *)logoutSerializerForCharset:(HCCharset *)charset {
  return [[PELogoutSerializer alloc] initWithMediaType:[FPKnownMediaTypes userMediaTypeWithVersion:_userResMtVersion]
                                               charset:charset
                            serializersForEmbeddedResources:@{}
                                actionsForEmbeddedResources:@{}];
}

- (PEResendVerificationEmailSerializer *)resendVerificationEmailSerializerForCharset:(HCCharset *)charset {
  return [[PEResendVerificationEmailSerializer alloc] initWithMediaType:[FPKnownMediaTypes userMediaTypeWithVersion:_userResMtVersion]
                                                                charset:charset
                                        serializersForEmbeddedResources:@{}
                                            actionsForEmbeddedResources:@{}];
}

- (PEPasswordResetSerializer *)passwordResetSerializerForCharset:(HCCharset *)charset {
  return [[PEPasswordResetSerializer alloc] initWithMediaType:[FPKnownMediaTypes userMediaTypeWithVersion:_userResMtVersion]
                                                      charset:charset
                              serializersForEmbeddedResources:@{}
                                  actionsForEmbeddedResources:@{}];
}

- (PEChangelogSerializer *)changelogSerializerForCharset:(HCCharset *)charset
                                          userSerializer:(PEUserSerializer *)userSerializer
                                       vehicleSerializer:(FPVehicleSerializer *)vehicleSerializer
                                   fuelStationSerializer:(FPFuelStationSerializer *)fuelStationSerializer
                               fuelPurchaseLogSerializer:(FPFuelPurchaseLogSerializer *)fuelPurchaseLogSerializer
                                environmentLogSerializer:(FPEnvironmentLogSerializer *)environmentLogSerializer {
  HCActionForEmbeddedResource actionForEmbeddedUser = ^(FPChangelog *changelog, id embeddedUser) {
    [changelog setUser:embeddedUser];
  };
  HCActionForEmbeddedResource actionForEmbeddedVehicle = ^(FPChangelog *changelog, id embeddedVehicle) {
    [changelog addVehicle:embeddedVehicle];
  };
  HCActionForEmbeddedResource actionForEmbeddedFuelStation = ^(FPChangelog *changelog, id embeddedFuelStation) {
    [changelog addFuelStation:embeddedFuelStation];
  };
  HCActionForEmbeddedResource actionForEmbeddedFuelPurchaseLog = ^(FPChangelog *changelog, id embeddedFuelPurchaseLog) {
    [changelog addFuelPurchaseLog:embeddedFuelPurchaseLog];
  };
  HCActionForEmbeddedResource actionForEmbeddedEnvironmentLog = ^(FPChangelog *changelog, id embeddedEnvironmentLog) {
    [changelog addEnvironmentLog:embeddedEnvironmentLog];
  };
  return [[PEChangelogSerializer alloc] initWithMediaType:[FPKnownMediaTypes changelogMediaTypeWithVersion:_changelogResMtVersion]
                                                  charset:charset
                          serializersForEmbeddedResources:@{[[userSerializer mediaType] description] : userSerializer,
                                                            [[vehicleSerializer mediaType] description] : vehicleSerializer,
                                                            [[fuelStationSerializer mediaType] description] : fuelStationSerializer,
                                                            [[fuelPurchaseLogSerializer mediaType] description] : fuelPurchaseLogSerializer,
                                                            [[environmentLogSerializer mediaType] description] : environmentLogSerializer}
                              actionsForEmbeddedResources:@{[[userSerializer mediaType] description] : actionForEmbeddedUser,
                                                            [[vehicleSerializer mediaType] description] : actionForEmbeddedVehicle,
                                                            [[fuelStationSerializer mediaType] description] : actionForEmbeddedFuelStation,
                                                            [[fuelPurchaseLogSerializer mediaType] description] : actionForEmbeddedFuelPurchaseLog,
                                                            [[environmentLogSerializer mediaType] description] : actionForEmbeddedEnvironmentLog}
                                           changelogClass:[FPChangelog class]];
}

- (PEUserSerializer *)userSerializerForCharset:(HCCharset *)charset
                             vehicleSerializer:(FPVehicleSerializer *)vehicleSerializer
                         fuelStationSerializer:(FPFuelStationSerializer *)fuelStationSerializer
                     fuelPurchaseLogSerializer:(FPFuelPurchaseLogSerializer *)fuelPurchaseLogSerializer
                      environmentLogSerializer:(FPEnvironmentLogSerializer *)environmentLogSerializer {
  HCActionForEmbeddedResource actionForEmbeddedVehicle = ^(id user, id embeddedVehicle) {
    [(FPUser *)user addVehicle:embeddedVehicle];
  };
  HCActionForEmbeddedResource actionForEmbeddedFuelStation = ^(id user, id embeddedFuelStation) {
    [(FPUser *)user addFuelStation:embeddedFuelStation];
  };
  HCActionForEmbeddedResource actionForEmbeddedFuelPurchaseLog = ^(id user, id embeddedFuelPurchaseLog) {
    [(FPUser *)user addFuelPurchaseLog:embeddedFuelPurchaseLog];
  };
  HCActionForEmbeddedResource actionForEmbeddedEnvironmentLog = ^(id user, id embeddedEnvironmentLog) {
    [(FPUser *)user addEnvironmentLog:embeddedEnvironmentLog];
  };
  return [[PEUserSerializer alloc] initWithMediaType:[FPKnownMediaTypes userMediaTypeWithVersion:_userResMtVersion]
                                             charset:charset
                     serializersForEmbeddedResources:@{[[vehicleSerializer mediaType] description] : vehicleSerializer,
                                                       [[fuelStationSerializer mediaType] description] : fuelStationSerializer,
                                                       [[fuelPurchaseLogSerializer mediaType] description] : fuelPurchaseLogSerializer,
                                                       [[environmentLogSerializer mediaType] description] : environmentLogSerializer}
                         actionsForEmbeddedResources:@{[[vehicleSerializer mediaType] description] : actionForEmbeddedVehicle,
                                                       [[fuelStationSerializer mediaType] description] : actionForEmbeddedFuelStation,
                                                       [[fuelPurchaseLogSerializer mediaType] description] : actionForEmbeddedFuelPurchaseLog,
                                                       [[environmentLogSerializer mediaType] description] : actionForEmbeddedEnvironmentLog}
                                           userClass:[FPUser class]];
}

// this goes away in refactored design...
+ (void)invokeErrorBlocksForHttpStatusCode:(NSNumber *)httpStatusCode
                                     error:(NSError *)err
                        tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                            remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk {
  if (httpStatusCode) {
    if ([[err domain] isEqualToString:FPUserFaultedErrorDomain]) {
      if ([err code] > 0) {
        if (remoteErrorBlk) remoteErrorBlk([err code]);
      } else {
        if (tempRemoteErrorBlk) tempRemoteErrorBlk();
      }
    } else {
      if (tempRemoteErrorBlk) tempRemoteErrorBlk();
    }
  } else {
    // if no http status code, then it was a connection failure, and that by nature is temporary
    if (tempRemoteErrorBlk) tempRemoteErrorBlk();
  }
}

#pragma mark - Getters

- (NSString *)authToken {
  return [_userCoordDao authToken];
}

- (id<PEUserCoordinatorDao>)userCoordinatorDao {
  return _userCoordDao;
}

#pragma mark - Flushing All Unsynced Edits to Remote Master

- (void)flushUnsyncedChangesToEntities:(NSArray *)entitiesToSync
                                syncer:(void(^)(PELMMainSupport *))syncerBlk {
  for (PELMMainSupport *entity in entitiesToSync) {
    if ([entity syncInProgress]) {
      syncerBlk(entity);
    }
  }
}

- (NSInteger)flushAllUnsyncedEditsToRemoteForUser:(FPUser *)user
                                entityNotFoundBlk:(void(^)(float))entityNotFoundBlk
                                       successBlk:(void(^)(float))successBlk
                               remoteStoreBusyBlk:(void(^)(float, NSDate *))remoteStoreBusyBlk
                               tempRemoteErrorBlk:(void(^)(float))tempRemoteErrorBlk
                                   remoteErrorBlk:(void(^)(float, NSInteger))remoteErrorBlk
                                      conflictBlk:(void(^)(float, id))conflictBlk
                                  authRequiredBlk:(void(^)(float))authRequiredBlk
                                          allDone:(void(^)(void))allDoneBlk
                                            error:(PELMDaoErrorBlk)errorBlk {
  NSArray *vehiclesToSync = [self markVehiclesAsSyncInProgressForUser:user error:errorBlk];
  NSArray *fuelStationsToSync = [self markFuelStationsAsSyncInProgressForUser:user error:errorBlk];
  NSArray *fpLogsToSync = [self markFuelPurchaseLogsAsSyncInProgressForUser:user error:errorBlk];
  NSArray *envLogsToSync = [self markEnvironmentLogsAsSyncInProgressForUser:user error:errorBlk];
  NSInteger totalNumToSync = [vehiclesToSync count] + [fuelStationsToSync count] + [fpLogsToSync count] + [envLogsToSync count];
  if (totalNumToSync == 0) {
    allDoneBlk();
    return 0;
  }
  NSDecimalNumber *individualEntitySyncProgress = [[NSDecimalNumber one] decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%ld", (long)totalNumToSync]]];
  __block NSInteger totalSyncAttempted = 0;
  void (^incrementSyncAttemptedAndCheckDoneness)(void) = ^{
    totalSyncAttempted++;
    if (totalSyncAttempted == totalNumToSync) {
      allDoneBlk();
    }
  };
  void (^commonEntityNotFoundBlk)(void) = ^{
    if (entityNotFoundBlk) entityNotFoundBlk([individualEntitySyncProgress floatValue]);
    incrementSyncAttemptedAndCheckDoneness();
  };
  void (^commonConflictBlk)(id) = ^(id latestEntity) {
    if (conflictBlk) conflictBlk([individualEntitySyncProgress floatValue], latestEntity);
    incrementSyncAttemptedAndCheckDoneness();
  };
  void (^commonSuccessBlk)(void) = ^{
    if (successBlk) successBlk([individualEntitySyncProgress floatValue]);
    incrementSyncAttemptedAndCheckDoneness();
  };
  void (^commonRemoteStoreyBusyBlk)(NSDate *) = ^(NSDate *retryAfter) {
    if (remoteStoreBusyBlk) remoteStoreBusyBlk([individualEntitySyncProgress floatValue], retryAfter);
    incrementSyncAttemptedAndCheckDoneness();
  };
  void (^commonTempRemoteErrorBlk)(void) = ^{
    if (tempRemoteErrorBlk) tempRemoteErrorBlk([individualEntitySyncProgress floatValue]);
    incrementSyncAttemptedAndCheckDoneness();
  };
  void (^commonRemoteErrorBlk)(NSInteger) = ^(NSInteger errMask) {
    if (remoteErrorBlk) remoteErrorBlk([individualEntitySyncProgress floatValue], errMask);
    incrementSyncAttemptedAndCheckDoneness();
  };
  void (^commonAuthReqdBlk)(void) = ^{
    if (authRequiredBlk) authRequiredBlk([individualEntitySyncProgress floatValue]);
    allDoneBlk();
  };
  void (^commonSyncSkippedBlk)(void) = ^{
    incrementSyncAttemptedAndCheckDoneness();
  };
  void (^syncFpLogs)(void) = ^{
    [self flushUnsyncedChangesToEntities:fpLogsToSync
                                  syncer:^(PELMMainSupport *entity){[self flushUnsyncedChangesToFuelPurchaseLog:(FPFuelPurchaseLog *)entity
                                                                                                        forUser:user
                                                                                            notFoundOnServerBlk:^{ commonEntityNotFoundBlk(); }
                                                                                                 addlSuccessBlk:^{ commonSuccessBlk(); }
                                                                                         addlRemoteStoreBusyBlk:^(NSDate *d) {commonRemoteStoreyBusyBlk(d); }
                                                                                         addlTempRemoteErrorBlk:^{ commonTempRemoteErrorBlk(); }
                                                                                             addlRemoteErrorBlk:^(NSInteger m) {commonRemoteErrorBlk(m);}
                                                                                                addlConflictBlk:^(id e) { commonConflictBlk(e); }
                                                                                            addlAuthRequiredBlk:^{ commonAuthReqdBlk(); }
                                                                                   skippedDueToVehicleNotSynced:^{ commonSyncSkippedBlk(); }
                                                                               skippedDueToFuelStationNotSynced:^{ commonSyncSkippedBlk(); }
                                                                                                          error:errorBlk];}];
  };
  void (^syncEnvLogs)(void) = ^{
    [self flushUnsyncedChangesToEntities:envLogsToSync
                                  syncer:^(PELMMainSupport *entity){[self flushUnsyncedChangesToEnvironmentLog:(FPEnvironmentLog *)entity
                                                                                                       forUser:user
                                                                                           notFoundOnServerBlk:^{ commonEntityNotFoundBlk(); }
                                                                                                addlSuccessBlk:^{ commonSuccessBlk(); }
                                                                                        addlRemoteStoreBusyBlk:^(NSDate *d) {commonRemoteStoreyBusyBlk(d); }
                                                                                        addlTempRemoteErrorBlk:^{ commonTempRemoteErrorBlk(); }
                                                                                            addlRemoteErrorBlk:^(NSInteger m) {commonRemoteErrorBlk(m);}
                                                                                               addlConflictBlk:^(id e) { commonConflictBlk(e); }
                                                                                           addlAuthRequiredBlk:^{ commonAuthReqdBlk(); }
                                                                                  skippedDueToVehicleNotSynced:^{ commonSyncSkippedBlk(); }
                                                                                                         error:errorBlk];}];
  };
  __block NSInteger totalVehiclesSyncAttempted = 0;
  __block NSInteger totalFuelStationsSynced = 0;
  NSInteger totalNumVehiclesToSync = [vehiclesToSync count];
  NSInteger totalNumFuelStationsToSync = [fuelStationsToSync count];
  __block BOOL haveSyncedFpLogs = NO;
  // FYI, we won't have a concurrency issue with the inner-most calls to syncFpLogs
  // because all completion blocks associated with network calls execute in a serial
  // queue.  This is a guarantee made by our remote store DAO.  So, in the case where
  // we have vehicles, fuelstations and fp logs to sync, we're guaranteed that syncFpLogs
  // will only get invoked once.
  if (totalNumVehiclesToSync > 0) {
    void (^vehicleSyncAttempted)(void) = ^{
      totalVehiclesSyncAttempted++;
      if (totalVehiclesSyncAttempted == totalNumVehiclesToSync) {
        syncEnvLogs();
        if (totalNumFuelStationsToSync > 0) {
          if (totalFuelStationsSynced == totalNumFuelStationsToSync) {
            if (!haveSyncedFpLogs) {
              haveSyncedFpLogs = YES;
              syncFpLogs();
            }
          }
        } else {
          syncFpLogs();
        }
      }
    };
    [self flushUnsyncedChangesToEntities:vehiclesToSync
                                  syncer:^(PELMMainSupport *entity){[self flushUnsyncedChangesToVehicle:(FPVehicle *)entity
                                                                                                forUser:user
                                                                                    notFoundOnServerBlk:^{ commonEntityNotFoundBlk(); }
                                                                                         addlSuccessBlk:^{ commonSuccessBlk(); vehicleSyncAttempted(); }
                                                                                 addlRemoteStoreBusyBlk:^(NSDate *d) { commonRemoteStoreyBusyBlk(d); vehicleSyncAttempted(); }
                                                                                 addlTempRemoteErrorBlk:^{ commonTempRemoteErrorBlk(); vehicleSyncAttempted(); }
                                                                                     addlRemoteErrorBlk:^(NSInteger mask) { commonRemoteErrorBlk(mask); vehicleSyncAttempted(); }
                                                                                        addlConflictBlk:^(id e) { commonConflictBlk(e); }
                                                                                    addlAuthRequiredBlk:commonAuthReqdBlk
                                                                                                  error:errorBlk];}];
  } else {
    syncEnvLogs();
  }
  if (totalNumFuelStationsToSync > 0) {
    void (^fuelStationSyncAttempted)(void) = ^{
      totalFuelStationsSynced++;
      if (totalFuelStationsSynced == totalNumFuelStationsToSync) {
        if (totalNumVehiclesToSync > 0) {
          if (totalVehiclesSyncAttempted == totalNumVehiclesToSync) {
            if (!haveSyncedFpLogs) {
              haveSyncedFpLogs = YES;
              syncFpLogs();
            }
          }
        } else {
          syncFpLogs();
        }
      }
    };
    [self flushUnsyncedChangesToEntities:fuelStationsToSync
                                  syncer:^(PELMMainSupport *entity){[self flushUnsyncedChangesToFuelStation:(FPFuelStation *)entity
                                                                                                    forUser:user
                                                                                        notFoundOnServerBlk:^{ commonEntityNotFoundBlk(); }
                                                                                             addlSuccessBlk:^{ commonSuccessBlk(); fuelStationSyncAttempted(); }
                                                                                     addlRemoteStoreBusyBlk:^(NSDate *d) { commonRemoteStoreyBusyBlk(d); fuelStationSyncAttempted(); }
                                                                                     addlTempRemoteErrorBlk:^{ commonTempRemoteErrorBlk(); fuelStationSyncAttempted(); }
                                                                                         addlRemoteErrorBlk:^(NSInteger mask) { commonRemoteErrorBlk(mask); fuelStationSyncAttempted(); }
                                                                                            addlConflictBlk:^(id e) { commonConflictBlk(e); }
                                                                                        addlAuthRequiredBlk:commonAuthReqdBlk
                                                                                                      error:errorBlk];}];
  }
  if ((totalNumVehiclesToSync == 0) && (totalNumFuelStationsToSync == 0)) {
    syncFpLogs();
  }
  return totalNumToSync;
}

#pragma mark - Unsynced Entities Check

- (BOOL)doesUserHaveAnyUnsyncedEntities:(FPUser *)user {
  return ([self totalNumUnsyncedEntitiesForUser:user] > 0);
}

#pragma mark - Price Stream Operations

- (void)fetchPriceStreamSortedByPriceDistanceNearLat:(NSDecimalNumber *)latitude
                                                long:(NSDecimalNumber *)longitude
                                      distanceWithin:(NSInteger)distanceWithin
                                          maxResults:(NSInteger)maxResults
                                 notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                          successBlk:(void(^)(NSArray *))successBlk
                                  remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                                  tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
  ^(NSString *newAuthTkn, NSString *relativeGlobalId, id resourceModel, NSDictionary *rels,
    NSDate *lastModified, BOOL isConflict, BOOL gone, BOOL notFound, BOOL movedPermanently,
    BOOL notModified, NSError *err, NSHTTPURLResponse *httpResp) {
    if (movedPermanently) {
      // ?
    } else if (gone || notFound) {
      notFoundOnServerBlk();
    } else if (err) {
      tempRemoteErrorBlk();
    } else {
      successBlk(resourceModel);
    }
  };
  [_remoteMasterDao fetchPriceStreamSortedByPriceDistanceNearLat:latitude
                                                            long:longitude
                                                  distanceWithin:distanceWithin
                                                      maxResults:maxResults
                                                         timeout:_timeout
                                                 remoteStoreBusy:^(NSDate *retryAfter){if (remoteStoreBusyBlk) {remoteStoreBusyBlk(retryAfter);}}
                                               completionHandler:remoteStoreComplHandler];
}

- (void)fetchPriceStreamSortedByDistancePriceNearLat:(NSDecimalNumber *)latitude
                                                long:(NSDecimalNumber *)longitude
                                      distanceWithin:(NSInteger)distanceWithin
                                          maxResults:(NSInteger)maxResults
                                 notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                          successBlk:(void(^)(NSArray *))successBlk
                                  remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                                  tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
  ^(NSString *newAuthTkn, NSString *relativeGlobalId, id resourceModel, NSDictionary *rels,
    NSDate *lastModified, BOOL isConflict, BOOL gone, BOOL notFound, BOOL movedPermanently,
    BOOL notModified, NSError *err, NSHTTPURLResponse *httpResp) {
    if (movedPermanently) {
      // ?
    } else if (gone || notFound) {
      notFoundOnServerBlk();
    } else if (err) {
      tempRemoteErrorBlk();
    } else {
      successBlk(resourceModel);
    }
  };
  [_remoteMasterDao fetchPriceStreamSortedByDistancePriceNearLat:latitude
                                                            long:longitude
                                                  distanceWithin:distanceWithin
                                                      maxResults:maxResults
                                                         timeout:_timeout
                                                 remoteStoreBusy:^(NSDate *retryAfter){if (remoteStoreBusyBlk) {remoteStoreBusyBlk(retryAfter);}}
                                               completionHandler:remoteStoreComplHandler];
}

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
                         plate:(NSString *)plate {
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
                          mediaType:[FPKnownMediaTypes vehicleMediaTypeWithVersion:_vehicleResMtVersion]];
}

- (void)saveNewAndSyncImmediateVehicle:(FPVehicle *)vehicle
                               forUser:(FPUser *)user
                   notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                        addlSuccessBlk:(void(^)(void))addlSuccessBlk
                addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                    addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                       addlConflictBlk:(void(^)(id))addlConflictBlk
                   addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                 error:(PELMDaoErrorBlk)errorBlk {
  [self saveNewAndSyncImmediateVehicle:vehicle forUser:user error:errorBlk];
  [self flushUnsyncedChangesToVehicle:vehicle
                              forUser:user
                  notFoundOnServerBlk:notFoundOnServerBlk
                       addlSuccessBlk:addlSuccessBlk
               addlRemoteStoreBusyBlk:addlRemoteStoreBusyBlk
               addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                   addlRemoteErrorBlk:addlRemoteErrorBlk
                      addlConflictBlk:addlConflictBlk
                  addlAuthRequiredBlk:addlAuthRequiredBlk
                                error:errorBlk];
}

- (void)flushUnsyncedChangesToVehicle:(FPVehicle *)vehicle
                              forUser:(FPUser *)user
                  notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                       addlSuccessBlk:(void(^)(void))addlSuccessBlk
               addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
               addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                   addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                      addlConflictBlk:(void(^)(FPVehicle *))addlConflictBlk
                  addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                error:(PELMDaoErrorBlk)errorBlk {
  if ([vehicle synced]) {
    return;
  }
  PELMRemoteMasterCompletionHandler complHandler =
    [PELMUtils complHandlerToFlushUnsyncedChangesToEntity:vehicle
                                      remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                                        [self cancelSyncForVehicle:vehicle httpRespCode:httpStatusCode errorMask:@([err code]) retryAt:nil error:errorBlk];
                                        [FPCoordinatorDaoImpl invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                                       error:err
                                                                      tempRemoteErrorBlk:addlTempRemoteErrorBlk
                                                                          remoteErrorBlk:addlRemoteErrorBlk];
                                      }
                                        entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                                        markAsConflictBlk:^(FPVehicle *latestVehicle) {
                                          [self cancelSyncForVehicle:vehicle httpRespCode:@(409) errorMask:nil retryAt:nil error:errorBlk];
                                          if (addlConflictBlk) { addlConflictBlk(latestVehicle); }
                                        }
                        markAsSyncCompleteForNewEntityBlk:^{
                          [self markAsSyncCompleteForNewVehicle:vehicle forUser:user error:errorBlk];
                          if (addlSuccessBlk) { addlSuccessBlk(); }
                        }
                   markAsSyncCompleteForExistingEntityBlk:^{
                     [self markAsSyncCompleteForUpdatedVehicle:vehicle error:errorBlk];
                     if (addlSuccessBlk) { addlSuccessBlk(); }
                   }
                                          newAuthTokenBlk:^(NSString *newAuthTkn){[_userCoordDao processNewAuthToken:newAuthTkn forUser:user];}];
  PELMRemoteMasterBusyBlk remoteStoreBusyBlk = ^(NSDate *retryAt) {
    [self cancelSyncForVehicle:vehicle httpRespCode:@(503) errorMask:nil retryAt:retryAt error:errorBlk];
    if (addlRemoteStoreBusyBlk) { addlRemoteStoreBusyBlk(retryAt); }
  };
  PELMRemoteMasterAuthReqdBlk authRequiredBlk = ^(HCAuthentication *auth) {
    [_userCoordDao authReqdBlk](auth);
    [self cancelSyncForVehicle:vehicle httpRespCode:@(401) errorMask:nil retryAt:nil error:errorBlk];
    if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
  };  
  if ([vehicle globalIdentifier]) {
    [_remoteMasterDao saveExistingVehicle:vehicle
                                  timeout:_timeout
                          remoteStoreBusy:remoteStoreBusyBlk
                             authRequired:authRequiredBlk
                        completionHandler:complHandler];
  } else {
    [_remoteMasterDao saveNewVehicle:vehicle
                             forUser:user
                             timeout:_timeout
                     remoteStoreBusy:remoteStoreBusyBlk
                        authRequired:authRequiredBlk
                   completionHandler:complHandler];
  }
}

- (void)markAsDoneEditingAndSyncVehicleImmediate:(FPVehicle *)vehicle
                                         forUser:(FPUser *)user
                             notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                      addlSuccessBlk:(void(^)(void))successBlk
                              addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                              addlTempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                                  addlRemoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                                     addlConflictBlk:(void(^)(FPVehicle *))conflictBlk
                                 addlAuthRequiredBlk:(void(^)(void))authRequiredBlk
                                           error:(PELMDaoErrorBlk)errorBlk {
  [self markAsDoneEditingImmediateSyncVehicle:vehicle error:errorBlk];
  [self flushUnsyncedChangesToVehicle:vehicle
                              forUser:user
                  notFoundOnServerBlk:notFoundOnServerBlk
                       addlSuccessBlk:successBlk
               addlRemoteStoreBusyBlk:remoteStoreBusyBlk
               addlTempRemoteErrorBlk:tempRemoteErrorBlk
                   addlRemoteErrorBlk:remoteErrorBlk
                      addlConflictBlk:conflictBlk
                  addlAuthRequiredBlk:authRequiredBlk
                                error:errorBlk];
}

- (void)deleteVehicle:(FPVehicle *)vehicle
              forUser:(FPUser *)user
  notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
       addlSuccessBlk:(void(^)(void))addlSuccessBlk
   remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
   tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
       remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
          conflictBlk:(void(^)(FPVehicle *))addlConflictBlk
  addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                error:(PELMDaoErrorBlk)errorBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
    [PELMUtils complHandlerToDeleteEntity:vehicle
                      remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                        [FPCoordinatorDaoImpl invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                       error:err
                                                      tempRemoteErrorBlk:tempRemoteErrorBlk
                                                          remoteErrorBlk:remoteErrorBlk];
                      }
                        entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                        markAsConflictBlk:^(FPVehicle *serverVehicle) { if (addlConflictBlk) { addlConflictBlk(serverVehicle); } }
                         deleteSuccessBlk:^{
                           [self deleteVehicle:vehicle error:errorBlk];
                           if (addlSuccessBlk) { addlSuccessBlk(); }
                         }
                          newAuthTokenBlk:^(NSString *newAuthTkn){[_userCoordDao processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao deleteVehicle:vehicle
                          timeout:_timeout
                  remoteStoreBusy:^(NSDate *retryAfter) { if (remoteStoreBusyBlk) { remoteStoreBusyBlk(retryAfter); } }
                     authRequired:^(HCAuthentication *auth) {
                       [_userCoordDao authReqdBlk](auth);
                       if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                     }
                completionHandler:remoteStoreComplHandler];
}

- (void)fetchVehicleWithGlobalId:(NSString *)globalIdentifier
                 ifModifiedSince:(NSDate *)ifModifiedSince
                         forUser:(FPUser *)user
             notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                      successBlk:(void(^)(FPVehicle *))successBlk
              remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
              tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
             addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
  [PELMUtils complHandlerToFetchEntityWithGlobalId:globalIdentifier
                               remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) { if (tempRemoteErrorBlk) { tempRemoteErrorBlk(); } }
                                 entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                                  fetchCompleteBlk:^(FPVehicle *fetchedVehicle) {
                                    if (successBlk) { successBlk(fetchedVehicle); }
                                  }
                                   newAuthTokenBlk:^(NSString *newAuthTkn){[_userCoordDao processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao fetchVehicleWithGlobalId:globalIdentifier
                             ifModifiedSince:ifModifiedSince
                                     timeout:_timeout
                             remoteStoreBusy:^(NSDate *retryAfter) { if (remoteStoreBusyBlk) { remoteStoreBusyBlk(retryAfter); } }
                                authRequired:^(HCAuthentication *auth) {
                                  [_userCoordDao authReqdBlk](auth);
                                  if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                                }
                           completionHandler:remoteStoreComplHandler];
}

- (void)fetchAndSaveNewVehicleWithGlobalId:(NSString *)globalIdentifier
                                   forUser:(FPUser *)user
                       notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                            addlSuccessBlk:(void(^)(FPVehicle *))addlSuccessBlk
                        remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                        tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                       addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                     error:(PELMDaoErrorBlk)errorBlk {
  [self fetchVehicleWithGlobalId:globalIdentifier
                 ifModifiedSince:nil
                         forUser:user
             notFoundOnServerBlk:notFoundOnServerBlk
                      successBlk:^(FPVehicle *fetchedVehicle) {
                        [self saveNewMasterVehicle:fetchedVehicle forUser:user error:errorBlk];
                        if (addlSuccessBlk) { addlSuccessBlk(fetchedVehicle); }
                      }
              remoteStoreBusyBlk:remoteStoreBusyBlk
              tempRemoteErrorBlk:tempRemoteErrorBlk
             addlAuthRequiredBlk:addlAuthRequiredBlk];
}

#pragma mark - Fuel Station

- (FPFuelStation *)fuelStationWithName:(NSString *)name
                                  type:(FPFuelStationType *)type
                                street:(NSString *)street
                                  city:(NSString *)city
                                 state:(NSString *)state
                                   zip:(NSString *)zip
                              latitude:(NSDecimalNumber *)latitude
                             longitude:(NSDecimalNumber *)longitude {
  return [FPFuelStation fuelStationWithName:name
                                       type:type
                                     street:street
                                       city:city
                                      state:state
                                        zip:zip
                                   latitude:latitude
                                  longitude:longitude
                                  mediaType:[FPKnownMediaTypes fuelStationMediaTypeWithVersion:_fuelStationResMtVersion]];
}

- (void)saveNewAndSyncImmediateFuelStation:(FPFuelStation *)fuelStation
                                   forUser:(FPUser *)user
                       notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                            addlSuccessBlk:(void(^)(void))addlSuccessBlk
                    addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                    addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                        addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                           addlConflictBlk:(void(^)(id))addlConflictBlk
                       addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                     error:(PELMDaoErrorBlk)errorBlk {
  [self saveNewAndSyncImmediateFuelStation:fuelStation forUser:user error:errorBlk];
  [self flushUnsyncedChangesToFuelStation:fuelStation
                                  forUser:user
                      notFoundOnServerBlk:notFoundOnServerBlk
                           addlSuccessBlk:addlSuccessBlk
                   addlRemoteStoreBusyBlk:addlRemoteStoreBusyBlk
                   addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                       addlRemoteErrorBlk:addlRemoteErrorBlk
                          addlConflictBlk:addlConflictBlk
                      addlAuthRequiredBlk:addlAuthRequiredBlk
                                    error:errorBlk];
}

- (void)flushUnsyncedChangesToFuelStation:(FPFuelStation *)fuelStation
                                  forUser:(FPUser *)user
                      notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                           addlSuccessBlk:(void(^)(void))addlSuccessBlk
                   addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                   addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                       addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                          addlConflictBlk:(void(^)(FPFuelStation *))addlConflictBlk
                      addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                    error:(PELMDaoErrorBlk)errorBlk {
  if ([fuelStation synced]) {
    return;
  }
  PELMRemoteMasterCompletionHandler complHandler =
  [PELMUtils complHandlerToFlushUnsyncedChangesToEntity:fuelStation
                                    remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                                      [self cancelSyncForFuelStation:fuelStation httpRespCode:httpStatusCode errorMask:@([err code]) retryAt:nil error:errorBlk];
                                      [FPCoordinatorDaoImpl invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                                     error:err
                                                                    tempRemoteErrorBlk:addlTempRemoteErrorBlk
                                                                        remoteErrorBlk:addlRemoteErrorBlk];
                                    }
                                      entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                                      markAsConflictBlk:^(FPFuelStation *latestFuelStation) {
                                        [self cancelSyncForFuelStation:fuelStation httpRespCode:@(409) errorMask:nil retryAt:nil error:errorBlk];
                                        if (addlConflictBlk) { addlConflictBlk(latestFuelStation); }
                                      }
                      markAsSyncCompleteForNewEntityBlk:^{
                        [self markAsSyncCompleteForNewFuelStation:fuelStation forUser:user error:errorBlk];
                        if (addlSuccessBlk) { addlSuccessBlk(); }
                      }
                 markAsSyncCompleteForExistingEntityBlk:^{
                   [self markAsSyncCompleteForUpdatedFuelStation:fuelStation error:errorBlk];
                   if (addlSuccessBlk) { addlSuccessBlk(); }
                 }
                                        newAuthTokenBlk:^(NSString *newAuthTkn){[_userCoordDao processNewAuthToken:newAuthTkn forUser:user];}];
  PELMRemoteMasterBusyBlk remoteStoreBusyBlk = ^(NSDate *retryAt) {
    [self cancelSyncForFuelStation:fuelStation httpRespCode:@(503) errorMask:nil retryAt:retryAt error:errorBlk];
    if (addlRemoteStoreBusyBlk) { addlRemoteStoreBusyBlk(retryAt); }
  };
  PELMRemoteMasterAuthReqdBlk authRequiredBlk = ^(HCAuthentication *auth) {
    [_userCoordDao authReqdBlk](auth);
    [self cancelSyncForFuelStation:fuelStation httpRespCode:@(401) errorMask:nil retryAt:nil error:errorBlk];
    if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
  };
  if ([fuelStation globalIdentifier]) {
    [_remoteMasterDao saveExistingFuelStation:fuelStation
                                      timeout:_timeout
                              remoteStoreBusy:remoteStoreBusyBlk
                                 authRequired:authRequiredBlk
                            completionHandler:complHandler];
  } else {
    [_remoteMasterDao saveNewFuelStation:fuelStation
                                 forUser:user
                                 timeout:_timeout
                         remoteStoreBusy:remoteStoreBusyBlk
                            authRequired:authRequiredBlk
                       completionHandler:complHandler];
  }
}

- (void)markAsDoneEditingAndSyncFuelStationImmediate:(FPFuelStation *)fuelStation
                                             forUser:(FPUser *)user
                                 notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                      addlSuccessBlk:(void(^)(void))addlSuccessBlk
                              addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                              addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                                  addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                                     addlConflictBlk:(void(^)(FPFuelStation *))addlConflictBlk
                                 addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                               error:(PELMDaoErrorBlk)errorBlk {
  [self markAsDoneEditingImmediateSyncFuelStation:fuelStation error:errorBlk];
  [self flushUnsyncedChangesToFuelStation:fuelStation
                                  forUser:user
                      notFoundOnServerBlk:notFoundOnServerBlk
                           addlSuccessBlk:addlSuccessBlk
                   addlRemoteStoreBusyBlk:addlRemoteStoreBusyBlk
                   addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                       addlRemoteErrorBlk:addlRemoteErrorBlk
                          addlConflictBlk:addlConflictBlk
                      addlAuthRequiredBlk:addlAuthRequiredBlk
                                    error:errorBlk];
}

- (void)deleteFuelStation:(FPFuelStation *)fuelStation
                  forUser:(FPUser *)user
      notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
           addlSuccessBlk:(void(^)(void))addlSuccessBlk
       remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
       tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
           remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
              conflictBlk:(void(^)(FPFuelStation *))conflictBlk
      addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                    error:(PELMDaoErrorBlk)errorBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
    [PELMUtils complHandlerToDeleteEntity:fuelStation
                      remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                        [FPCoordinatorDaoImpl invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                       error:err
                                                      tempRemoteErrorBlk:tempRemoteErrorBlk
                                                          remoteErrorBlk:remoteErrorBlk];
                      }
                        entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                        markAsConflictBlk:^(FPFuelStation *serverFuelstation) { if (conflictBlk) { conflictBlk(serverFuelstation); } }
                         deleteSuccessBlk:^{
                           [self deleteFuelstation:fuelStation error:errorBlk];
                           if (addlSuccessBlk) { addlSuccessBlk(); }
                         }
                          newAuthTokenBlk:^(NSString *newAuthTkn){[_userCoordDao processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao deleteFuelStation:fuelStation
                              timeout:_timeout
                      remoteStoreBusy:^(NSDate *retryAfter) { if (remoteStoreBusyBlk) { remoteStoreBusyBlk(retryAfter); } }
                         authRequired:^(HCAuthentication *auth) {
                           [_userCoordDao authReqdBlk](auth);
                           if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                         }
                    completionHandler:remoteStoreComplHandler];
}

- (void)fetchFuelstationWithGlobalId:(NSString *)globalIdentifier
                     ifModifiedSince:(NSDate *)ifModifiedSince
                             forUser:(FPUser *)user
                 notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                          successBlk:(void(^)(FPFuelStation *))successBlk
                  remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                  tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                 addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
  [PELMUtils complHandlerToFetchEntityWithGlobalId:globalIdentifier
                               remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) { if (tempRemoteErrorBlk) { tempRemoteErrorBlk(); } }
                                 entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                                  fetchCompleteBlk:^(FPFuelStation *fetchedFuelstation) {
                                    if (successBlk) { successBlk(fetchedFuelstation); }
                                  }
                                   newAuthTokenBlk:^(NSString *newAuthTkn){[_userCoordDao processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao fetchFuelstationWithGlobalId:globalIdentifier
                                 ifModifiedSince:ifModifiedSince
                                         timeout:_timeout
                                 remoteStoreBusy:^(NSDate *retryAfter) { if (remoteStoreBusyBlk) { remoteStoreBusyBlk(retryAfter); } }
                                    authRequired:^(HCAuthentication *auth) {
                                      [_userCoordDao authReqdBlk](auth);
                                      if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                                    }
                               completionHandler:remoteStoreComplHandler];
}

- (void)fetchAndSaveNewFuelstationWithGlobalId:(NSString *)globalIdentifier
                                       forUser:(FPUser *)user
                           notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                addlSuccessBlk:(void(^)(FPFuelStation *))addlSuccessBlk
                            remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                            tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                           addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                         error:(PELMDaoErrorBlk)errorBlk {
  [self fetchFuelstationWithGlobalId:globalIdentifier
                     ifModifiedSince:nil
                             forUser:user
                 notFoundOnServerBlk:notFoundOnServerBlk
                          successBlk:^(FPFuelStation *fetchedFuelstation) {
                            [self saveNewMasterFuelstation:fetchedFuelstation forUser:user error:errorBlk];
                            if (addlSuccessBlk) addlSuccessBlk(fetchedFuelstation);
                          }
                  remoteStoreBusyBlk:remoteStoreBusyBlk
                  tempRemoteErrorBlk:tempRemoteErrorBlk
                 addlAuthRequiredBlk:addlAuthRequiredBlk];  
}

#pragma mark - Fuel Purchase Log

- (FPFuelPurchaseLog *)fuelPurchaseLogWithNumGallons:(NSDecimalNumber *)numGallons
                                              octane:(NSNumber *)octane
                                            odometer:(NSDecimalNumber *)odometer
                                         gallonPrice:(NSDecimalNumber *)gallonPrice
                                          gotCarWash:(BOOL)gotCarWash
                            carWashPerGallonDiscount:(NSDecimalNumber *)carWashPerGallonDiscount
                                             logDate:(NSDate *)logDate
                                            isDiesel:(BOOL)isDiesel {
  return [FPFuelPurchaseLog fuelPurchaseLogWithNumGallons:numGallons
                                                   octane:octane
                                                 odometer:odometer
                                              gallonPrice:gallonPrice
                                               gotCarWash:gotCarWash
                                 carWashPerGallonDiscount:carWashPerGallonDiscount
                                              purchasedAt:logDate
                                                 isDiesel:isDiesel
                                                mediaType:[FPKnownMediaTypes fuelPurchaseLogMediaTypeWithVersion:_fuelPurchaseLogResMtVersion]];
}

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
                                         error:(PELMDaoErrorBlk)errorBlk {
  
  if ([vehicle globalIdentifier]) {
    if ([fuelStation globalIdentifier]) {
      [self saveNewAndSyncImmediateFuelPurchaseLog:fuelPurchaseLog
                                                forUser:user
                                                vehicle:vehicle
                                            fuelStation:fuelStation
                                                  error:errorBlk];
      [self flushUnsyncedChangesToFuelPurchaseLog:fuelPurchaseLog
                                          forUser:user
                              notFoundOnServerBlk:notFoundOnServerBlk
                                   addlSuccessBlk:addlSuccessBlk
                           addlRemoteStoreBusyBlk:addlRemoteStoreBusyBlk
                           addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                               addlRemoteErrorBlk:addlRemoteErrorBlk
                                  addlConflictBlk:addlConflictBlk
                              addlAuthRequiredBlk:addlAuthRequiredBlk
                     skippedDueToVehicleNotSynced:skippedDueToVehicleNotSynced
                 skippedDueToFuelStationNotSynced:skippedDueToFuelStationNotSynced
                                            error:errorBlk];
    } else {
      [self saveNewFuelPurchaseLog:fuelPurchaseLog
                           forUser:user
                           vehicle:vehicle
                       fuelStation:fuelStation
                             error:errorBlk];
      skippedDueToFuelStationNotSynced();
    }
  } else {
    [self saveNewFuelPurchaseLog:fuelPurchaseLog
                         forUser:user
                         vehicle:vehicle
                     fuelStation:fuelStation
                           error:errorBlk];
    skippedDueToVehicleNotSynced();
  }
}

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
                                        error:(PELMDaoErrorBlk)errorBlk {
  FPVehicle *vehicleForFpLog = [self vehicleForFuelPurchaseLog:fuelPurchaseLog error:errorBlk];
  FPFuelStation *fuelStationForFpLog = [self fuelStationForFuelPurchaseLog:fuelPurchaseLog error:errorBlk];
  [fuelPurchaseLog setVehicleGlobalIdentifier:[vehicleForFpLog globalIdentifier]];
  [fuelPurchaseLog setFuelStationGlobalIdentifier:[fuelStationForFpLog globalIdentifier]];
  if ([vehicleForFpLog globalIdentifier] == nil) {
    [self cancelSyncForFuelPurchaseLog:fuelPurchaseLog httpRespCode:nil errorMask:nil retryAt:nil error:errorBlk];
    skippedDueToVehicleNotSynced();
    return;
  }
  if ([fuelStationForFpLog globalIdentifier] == nil) {
    [self cancelSyncForFuelPurchaseLog:fuelPurchaseLog httpRespCode:nil errorMask:nil retryAt:nil error:errorBlk];
    skippedDueToFuelStationNotSynced();
    return;
  }
  if ([fuelPurchaseLog synced]) {
    return;
  }
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
  [PELMUtils complHandlerToFlushUnsyncedChangesToEntity:fuelPurchaseLog
                                    remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                                      [self cancelSyncForFuelPurchaseLog:fuelPurchaseLog httpRespCode:httpStatusCode errorMask:@([err code]) retryAt:nil error:errorBlk];
                                      [FPCoordinatorDaoImpl invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                                     error:err
                                                                    tempRemoteErrorBlk:addlTempRemoteErrorBlk
                                                                        remoteErrorBlk:addlRemoteErrorBlk];
                                    }
                                      entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                                      markAsConflictBlk:^(FPFuelPurchaseLog *latestFplog) {
                                        [self cancelSyncForFuelPurchaseLog:fuelPurchaseLog httpRespCode:@(409) errorMask:nil retryAt:nil error:errorBlk];
                                        if (addlConflictBlk) { addlConflictBlk(latestFplog); }
                                      }
                      markAsSyncCompleteForNewEntityBlk:^{
                        [self markAsSyncCompleteForNewFuelPurchaseLog:fuelPurchaseLog forUser:user error:errorBlk];
                        if (addlSuccessBlk) { addlSuccessBlk(); }
                      }
                 markAsSyncCompleteForExistingEntityBlk:^{
                   [self markAsSyncCompleteForUpdatedFuelPurchaseLog:fuelPurchaseLog error:errorBlk];
                   if (addlSuccessBlk) { addlSuccessBlk(); }
                 }
                                        newAuthTokenBlk:^(NSString *newAuthTkn){[_userCoordDao processNewAuthToken:newAuthTkn forUser:user];}];
  PELMRemoteMasterBusyBlk remoteStoreBusyBlk = ^(NSDate *retryAt) {
    [self cancelSyncForFuelPurchaseLog:fuelPurchaseLog httpRespCode:@(503) errorMask:nil retryAt:retryAt error:errorBlk];
    if (addlRemoteStoreBusyBlk) { addlRemoteStoreBusyBlk(retryAt); }
  };
  PELMRemoteMasterAuthReqdBlk authRequiredBlk = ^(HCAuthentication *auth) {
    [_userCoordDao authReqdBlk](auth);
    [self cancelSyncForFuelPurchaseLog:fuelPurchaseLog httpRespCode:@(401) errorMask:nil retryAt:nil error:errorBlk];
    if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
  };
  if ([fuelPurchaseLog globalIdentifier]) {
    [_remoteMasterDao saveExistingFuelPurchaseLog:fuelPurchaseLog
                                          timeout:_timeout
                                  remoteStoreBusy:remoteStoreBusyBlk
                                     authRequired:authRequiredBlk
                                completionHandler:remoteStoreComplHandler];
  } else {
    [_remoteMasterDao saveNewFuelPurchaseLog:fuelPurchaseLog
                                     forUser:user
                                     timeout:_timeout
                             remoteStoreBusy:remoteStoreBusyBlk
                                authRequired:authRequiredBlk
                           completionHandler:remoteStoreComplHandler];
  }
}

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
                                                   error:(PELMDaoErrorBlk)errorBlk {
  [self markAsDoneEditingImmediateSyncFuelPurchaseLog:fuelPurchaseLog error:errorBlk];
  [self flushUnsyncedChangesToFuelPurchaseLog:fuelPurchaseLog
                                      forUser:user
                          notFoundOnServerBlk:notFoundOnServerBlk
                               addlSuccessBlk:addlSuccessBlk
                       addlRemoteStoreBusyBlk:addlRemoteStoreBusyBlk
                       addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                           addlRemoteErrorBlk:addlRemoteErrorBlk
                              addlConflictBlk:addlConflictBlk
                          addlAuthRequiredBlk:addlAuthRequiredBlk
                 skippedDueToVehicleNotSynced:skippedDueToVehicleNotSynced
             skippedDueToFuelStationNotSynced:skippedDueToFuelStationNotSynced
                                        error:errorBlk];
}

- (void)deleteFuelPurchaseLog:(FPFuelPurchaseLog *)fplog
                      forUser:(FPUser *)user
          notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
               addlSuccessBlk:(void(^)(void))addlSuccessBlk
           remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
           tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
               remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                  conflictBlk:(void(^)(FPFuelPurchaseLog *))conflictBlk
          addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                        error:(PELMDaoErrorBlk)errorBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
    [PELMUtils complHandlerToDeleteEntity:fplog
                      remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                        [FPCoordinatorDaoImpl invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                       error:err
                                                          tempRemoteErrorBlk:tempRemoteErrorBlk
                                                              remoteErrorBlk:remoteErrorBlk];
                      }
                        entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                        markAsConflictBlk:^(FPFuelPurchaseLog *serverFplog) { if (conflictBlk) { conflictBlk(serverFplog); } }
                         deleteSuccessBlk:^{
                           [self deleteFuelPurchaseLog:fplog error:errorBlk];
                           if (addlSuccessBlk) { addlSuccessBlk(); }
                         }
                          newAuthTokenBlk:^(NSString *newAuthTkn){[_userCoordDao processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao deleteFuelPurchaseLog:fplog
                                  timeout:_timeout
                          remoteStoreBusy:^(NSDate *retryAfter) { if (remoteStoreBusyBlk) { remoteStoreBusyBlk(retryAfter); } }
                             authRequired:^(HCAuthentication *auth) {
                               [_userCoordDao authReqdBlk](auth);
                               if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                             }
                        completionHandler:remoteStoreComplHandler];
}

- (void)fetchFuelPurchaseLogWithGlobalId:(NSString *)globalIdentifier
                         ifModifiedSince:(NSDate *)ifModifiedSince
                                 forUser:(FPUser *)user
                     notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                              successBlk:(void(^)(FPFuelPurchaseLog *))successBlk
                      remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                      tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                     addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
  [PELMUtils complHandlerToFetchEntityWithGlobalId:globalIdentifier
                               remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) { if (tempRemoteErrorBlk) { tempRemoteErrorBlk(); } }
                                 entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                                  fetchCompleteBlk:^(FPFuelPurchaseLog *fetchedFplog) {
                                    if (successBlk) { successBlk(fetchedFplog); }
                                  }
                                   newAuthTokenBlk:^(NSString *newAuthTkn){[_userCoordDao processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao fetchFuelPurchaseLogWithGlobalId:globalIdentifier
                                     ifModifiedSince:ifModifiedSince
                                             timeout:_timeout
                                     remoteStoreBusy:^(NSDate *retryAfter) { if (remoteStoreBusyBlk) { remoteStoreBusyBlk(retryAfter); } }
                                        authRequired:^(HCAuthentication *auth) {
                                          [_userCoordDao authReqdBlk](auth);
                                          if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                                        }
                                   completionHandler:remoteStoreComplHandler];
}

#pragma mark - Environment Log

- (FPEnvironmentLog *)environmentLogWithOdometer:(NSDecimalNumber *)odometer
                                  reportedAvgMpg:(NSDecimalNumber *)reportedAvgMpg
                                  reportedAvgMph:(NSDecimalNumber *)reportedAvgMph
                             reportedOutsideTemp:(NSNumber *)reportedOutsideTemp
                                         logDate:(NSDate *)logDate
                                     reportedDte:(NSNumber *)reportedDte {
  return [FPEnvironmentLog envLogWithOdometer:odometer
                               reportedAvgMpg:reportedAvgMpg
                               reportedAvgMph:reportedAvgMph
                          reportedOutsideTemp:reportedOutsideTemp
                                      logDate:logDate
                                  reportedDte:reportedDte
                                    mediaType:[FPKnownMediaTypes environmentLogMediaTypeWithVersion:_environmentLogResMtVersion]];
}

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
                                        error:(PELMDaoErrorBlk)errorBlk {
  if ([vehicle globalIdentifier]) {
    [self saveNewAndSyncImmediateEnvironmentLog:envLog forUser:user vehicle:vehicle error:errorBlk];
    [self flushUnsyncedChangesToEnvironmentLog:envLog
                                       forUser:user
                           notFoundOnServerBlk:notFoundOnServerBlk
                                addlSuccessBlk:addlSuccessBlk
                        addlRemoteStoreBusyBlk:addlRemoteStoreBusyBlk
                        addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                            addlRemoteErrorBlk:addlRemoteErrorBlk
                               addlConflictBlk:addlConflictBlk
                           addlAuthRequiredBlk:addlAuthRequiredBlk
                  skippedDueToVehicleNotSynced:skippedDueToVehicleNotSynced
                                         error:errorBlk];
  } else {
    [self saveNewEnvironmentLog:envLog forUser:user vehicle:vehicle error:errorBlk];
    skippedDueToVehicleNotSynced();
  }
}

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
                                       error:(PELMDaoErrorBlk)errorBlk {
  FPVehicle *vehicleForEnvLog = [self vehicleForEnvironmentLog:environmentLog error:errorBlk];
  [environmentLog setVehicleGlobalIdentifier:[vehicleForEnvLog globalIdentifier]];
  if ([vehicleForEnvLog globalIdentifier] == nil) {
    [self cancelSyncForEnvironmentLog:environmentLog httpRespCode:nil errorMask:nil retryAt:nil error:errorBlk];
    skippedDueToVehicleNotSynced();
    return;
  }
  if ([environmentLog synced]) {
    return;
  }
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
  [PELMUtils complHandlerToFlushUnsyncedChangesToEntity:environmentLog
                                    remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                                      [self cancelSyncForEnvironmentLog:environmentLog httpRespCode:httpStatusCode errorMask:@([err code]) retryAt:nil error:errorBlk];
                                      [FPCoordinatorDaoImpl invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                                     error:err
                                                                    tempRemoteErrorBlk:addlTempRemoteErrorBlk
                                                                        remoteErrorBlk:addlRemoteErrorBlk];
                                    }
                                      entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                                      markAsConflictBlk:^(FPEnvironmentLog *latestEnvlog) {
                                        [self cancelSyncForEnvironmentLog:environmentLog httpRespCode:@(409) errorMask:nil retryAt:nil error:errorBlk];
                                        if (addlConflictBlk) { addlConflictBlk(latestEnvlog); }
                                      }
                      markAsSyncCompleteForNewEntityBlk:^{
                        [self markAsSyncCompleteForNewEnvironmentLog:environmentLog forUser:user error:errorBlk];
                        if (addlSuccessBlk) { addlSuccessBlk(); }
                      }
                 markAsSyncCompleteForExistingEntityBlk:^{
                   [self markAsSyncCompleteForUpdatedEnvironmentLog:environmentLog error:errorBlk];
                   if (addlSuccessBlk) { addlSuccessBlk(); }
                 }
                                        newAuthTokenBlk:^(NSString *newAuthTkn){[_userCoordDao processNewAuthToken:newAuthTkn forUser:user];}];
  PELMRemoteMasterBusyBlk remoteStoreBusyBlk = ^(NSDate *retryAt) {
    [self cancelSyncForEnvironmentLog:environmentLog httpRespCode:@(503) errorMask:nil retryAt:retryAt error:errorBlk];
    if (addlRemoteStoreBusyBlk) { addlRemoteStoreBusyBlk(retryAt); }
  };
  PELMRemoteMasterAuthReqdBlk authRequiredBlk = ^(HCAuthentication *auth) {
    [_userCoordDao authReqdBlk](auth);
    [self cancelSyncForEnvironmentLog:environmentLog httpRespCode:@(401) errorMask:nil retryAt:nil error:errorBlk];
    if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
  };
  if ([environmentLog globalIdentifier]) {
    [_remoteMasterDao saveExistingEnvironmentLog:environmentLog
                                         timeout:_timeout
                                 remoteStoreBusy:remoteStoreBusyBlk
                                    authRequired:authRequiredBlk
                               completionHandler:remoteStoreComplHandler];
  } else {
    [_remoteMasterDao saveNewEnvironmentLog:environmentLog
                                    forUser:user
                                    timeout:_timeout
                            remoteStoreBusy:remoteStoreBusyBlk
                               authRequired:authRequiredBlk
                          completionHandler:remoteStoreComplHandler];
  }
}

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
                                                  error:(PELMDaoErrorBlk)errorBlk {
  [self markAsDoneEditingImmediateSyncEnvironmentLog:envLog error:errorBlk];
  [self flushUnsyncedChangesToEnvironmentLog:envLog
                                     forUser:user
                         notFoundOnServerBlk:notFoundOnServerBlk
                              addlSuccessBlk:addlSuccessBlk
                      addlRemoteStoreBusyBlk:addlRemoteStoreBusyBlk
                      addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                          addlRemoteErrorBlk:addlRemoteErrorBlk
                             addlConflictBlk:addlConflictBlk
                         addlAuthRequiredBlk:addlAuthRequiredBlk
                skippedDueToVehicleNotSynced:skippedDueToVehicleNotSynced
                                       error:errorBlk];
}

- (void)deleteEnvironmentLog:(FPEnvironmentLog *)envlog
                     forUser:(FPUser *)user
         notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
              addlSuccessBlk:(void(^)(void))addlSuccessBlk
          remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
          tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
              remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                 conflictBlk:(void(^)(FPEnvironmentLog *))conflictBlk
         addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                       error:(PELMDaoErrorBlk)errorBlk {
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
    [PELMUtils complHandlerToDeleteEntity:envlog
                      remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                        [FPCoordinatorDaoImpl invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                       error:err
                                                          tempRemoteErrorBlk:tempRemoteErrorBlk
                                                              remoteErrorBlk:remoteErrorBlk];
                      }
                        entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                        markAsConflictBlk:^(FPEnvironmentLog *serverEnvlog) { if (conflictBlk) { conflictBlk(serverEnvlog); } }
                         deleteSuccessBlk:^{
                           [self deleteEnvironmentLog:envlog error:errorBlk];
                           if (addlSuccessBlk) { addlSuccessBlk(); }
                         }
                          newAuthTokenBlk:^(NSString *newAuthTkn){[_userCoordDao processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao deleteEnvironmentLog:envlog
                                 timeout:_timeout
                         remoteStoreBusy:^(NSDate *retryAfter) { if (remoteStoreBusyBlk) { remoteStoreBusyBlk(retryAfter); } }
                            authRequired:^(HCAuthentication *auth) {
                              [_userCoordDao authReqdBlk](auth);
                              if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                            }
                       completionHandler:remoteStoreComplHandler];
}

- (void)fetchEnvironmentLogWithGlobalId:(NSString *)globalIdentifier
                        ifModifiedSince:(NSDate *)ifModifiedSince
                                forUser:(FPUser *)user
                    notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                             successBlk:(void(^)(FPEnvironmentLog *))successBlk
                     remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                     tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                    addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
  [PELMUtils complHandlerToFetchEntityWithGlobalId:globalIdentifier
                               remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) { if (tempRemoteErrorBlk) { tempRemoteErrorBlk(); } }
                                 entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                                  fetchCompleteBlk:^(FPEnvironmentLog *fetchedEnvlog) {
                                    if (successBlk) { successBlk(fetchedEnvlog); }
                                  }
                                   newAuthTokenBlk:^(NSString *newAuthTkn){[_userCoordDao processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao fetchEnvironmentLogWithGlobalId:globalIdentifier
                                    ifModifiedSince:ifModifiedSince
                                            timeout:_timeout
                                    remoteStoreBusy:^(NSDate *retryAfter) { if (remoteStoreBusyBlk) { remoteStoreBusyBlk(retryAfter); } }
                                       authRequired:^(HCAuthentication *auth) {
                                          [_userCoordDao authReqdBlk](auth);
                                          if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                                        }
                                  completionHandler:remoteStoreComplHandler];
}

@end
