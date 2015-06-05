// Copyright (C) 2013 Paul Evans
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

#import <PEObjc-Commons/PEUIUtils.h>
#import <PEObjc-Commons/PEUtils.h>
#import <FlatUIKit/UIColor+FlatUI.h>
#import <PEFuelPurchase-Model/FPCoordinatorDao.h>
#import <UICKeyChainStore/UICKeyChainStore.h>
#import "FPAppDelegate.h"
#import <PEFuelPurchase-Model/FPUser.h>
#import "FPUnauthStartController.h"
#import "FPQuickActionMenuController.h"
#import "UIColor+FuelPurchase.h"  // TODO - get rid of this
#import <IQKeyboardManager/IQKeyboardManager.h>
#import <PEObjc-Commons/PEUIToolkit.h>
#import "FPUtils.h"
#import "FPSettingsController.h"
#import "FPEditsInProgressController.h"
#import "FPScreenToolkit.h"
#import "FPEditActors.h"
#import "FPLogging.h"

#ifdef FP_DEV
  #import <PEDev-Console/PDVScreen.h>
  #import <PEDev-Console/PDVScreenGroup.h>
  #import <PEDev-Console/PDVNotificationNames.h>
  #import <PEDev-Console/PDVUtils.h>
  #import <PEDev-Console/PDVUIWindow.h>
  #import <PEFuelPurchase-Model/FPUser.h>
#endif

id (^bundleVal)(NSString *) = ^(NSString *key) {
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:key];
};

int (^intBundleVal)(NSString *) = ^(NSString *key) {
  return [(NSNumber *)bundleVal(key) intValue];
};

// Keys in app plist
NSString * const FPRestServiceTimeoutKey        = @"timeout";
NSString * const FPRestServicePreferredCharset  = @"FP REST service preferred charset";
NSString * const FPRestServicePreferredLanguage = @"FP REST service preferred language";
NSString * const FPRestServicePreferredFormat   = @"FP REST service preferred format";
NSString * const FPRestServiceMtVersion         = @"FP REST service mt-version";
NSString * const FPTxnsRestServiceMtBaseSubtype = @"FP Txns REST service mt-base-subtype";
NSString * const FPTxnsRestServiceMtVersion     = @"FP Txns REST service mt-version";
NSString * const FPTxnsRestServiceMtSubtypePrefix = @"FP Txns REST service mt-subtype-prefix";
NSString * const FPAuthenticationScheme         = @"FP Authentication scheme";
NSString * const FPAuthenticationTokenName      = @"FP Authentication token param name";
NSString * const FPErrorMaskHeaderNameKey       = @"FP error mask header name";
NSString * const FPTransactionIdHeaderNameKey   = @"FP transaction id header name";
NSString * const FPEstablishSessionHeaderNameKey = @"FP establish session header name";
NSString * const FPUserAgentDeviceMakeHeaderNameKey = @"FP user agent device make header name";
NSString * const FPUserAgentDeviceOsHeaderNameKey = @"FP user agent device os header name";
NSString * const FPUserAgentDeviceOsVersionHeaderNameKey = @"FP user agent device os version header name";
NSString * const FPAuthTokenResponseHeaderNameKey = @"FP auth token response header name";
NSString * const FPTimeoutForCoordDaoMainThreadOps = @"FP timeout for main thread coordinator dao operations";
NSString * const FPTimeIntervalForFlushToRemoteMaster = @"FP time interval for flush to remote master";

#ifdef FP_DEV
  NSString * const FPAPIResourceFileName             = @"fpapi-resource.localdev";
#else
  NSString * const FPAPIResourceFileName             = @"fpapi-resource";
#endif
NSString * const FPDataFileExtension               = @"data";
NSString * const FPLocalSqlLiteDataFileName        = @"local-sqlite-datafile";

// Keychain service names
NSString * const FPAppKeychainService = @"fp-app";

@implementation FPAppDelegate {
  CGFloat _userAuthenticationStrength;
  MBProgressHUD *_HUD;
  NSString *_authToken;
  FPCoordinatorDao *_coordDao;
  PEUIToolkit *_uitoolkit;
  NSTimer *_timerForRemoteMasterFlush;
  NSTimer * (^_startRemoteMasterFlushTimer)(FPCoordinatorDao *, NSTimer *);
  FPScreenToolkit *_screenToolkit;
  CLLocationManager *_locationManager;
  NSMutableArray *_locations;

  #ifdef FP_DEV
    PDVUtils *_pdvUtils;
  #endif
}

#pragma mark - Methods

- (CLLocation *)latestLocation {
  if ([_locations count] > 0) {
    return [_locations lastObject];
  }
  return nil;
}

#pragma mark - Location Manager Delegate

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations {
  DDLogDebug(@"current locations: [%@]", locations);
  [_locations removeAllObjects]; // discard old entries
  [_locations addObjectsFromArray:locations];
}

- (void)locationManager:(CLLocationManager *)manager
didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
  BOOL authorized = NO;
  switch (status) {
    case kCLAuthorizationStatusNotDetermined:
      DDLogDebug(@"locationManager auth status: Not Determined");
      break;
    case kCLAuthorizationStatusRestricted:
      DDLogDebug(@"locationManager auth status: Restricted");
      break;
    case kCLAuthorizationStatusDenied:
      DDLogDebug(@"locationManager auth status: Denied");
      break;
    case kCLAuthorizationStatusAuthorizedAlways:
      authorized = YES;
      DDLogDebug(@"locationManager auth status: Always Authorized");
      break;
    case kCLAuthorizationStatusAuthorizedWhenInUse:
      authorized = YES;
      DDLogDebug(@"locationManager auth status: When-in-use Authorized");
      break;
  }
  if (authorized) {
    [_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    [_locationManager setDistanceFilter:500]; // 500 meters
    [_locationManager startUpdatingLocation];
  }
}

#pragma mark - Application Lifecycle

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [self initializeLocationTracking];
  [FPLogging initializeLogging];
  [self initializeStoreCoordinator];
  [_coordDao pruneAllSyncedEntitiesWithError:[FPUtils localSaveErrorHandlerMaker]()];
  FPUser *user = [_coordDao userWithError:[FPUtils localFetchErrorHandlerMaker]()];
  _authToken = [FPAppDelegate storedAuthenticationTokenForUser:user];
  _uitoolkit = [FPAppDelegate defaultUIToolkit];
  _screenToolkit = [[FPScreenToolkit alloc] initWithCoordinatorDao:_coordDao
                                                         uitoolkit:_uitoolkit
                                                             error:[FPUtils localFetchErrorHandlerMaker]()];
  _startRemoteMasterFlushTimer = ^ NSTimer * (FPCoordinatorDao *coordDao, NSTimer *oldTimer) {
    return [PEUtils startNewTimerWithTargetObject:coordDao
                                         selector:@selector(asynchronousWork:)
                                         interval:intBundleVal(FPTimeIntervalForFlushToRemoteMaster)
                                         oldTimer:oldTimer];
  };
  #ifdef FP_DEV
    self.window =
      [[PDVUIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _pdvUtils = [[PDVUtils alloc] initWithBaseResourceFolderOfSimulations:@"simulation/application-screens"
                                                             screenGroups:[self screenGroups]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(devShake:)
                                                 name:PdvShakeGesture
                                               object:nil];
  #else
    self.window =
      [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  #endif
  if (_authToken) {
    DDLogVerbose(@"User is authenticated.");
    [_coordDao setAuthToken:_authToken];
    [[self window] setRootViewController:[_screenToolkit newTabBarAuthHomeLandingScreenMakerWithTempNotification:@"Welcome Back"](user)];
  } else {
    DDLogVerbose(@"User is NOT authenticated.");
    [[self window] setRootViewController:[_screenToolkit newUnauthLandingScreenMakerWithTempNotification:nil]()];
  }
  [_coordDao globalCancelSyncInProgressWithError:[FPUtils localSaveErrorHandlerMaker]()];
  _timerForRemoteMasterFlush = _startRemoteMasterFlushTimer(_coordDao, _timerForRemoteMasterFlush);
  [self.window setBackgroundColor:[UIColor whiteColor]];
  [self.window makeKeyAndVisible];
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
  DDLogDebug(@"Will resign active. Stopping remote-master flush timer.");
  [PEUtils stopTimer:_timerForRemoteMasterFlush];
  [_locationManager stopUpdatingLocation];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  DDLogDebug(@"Did enter background. Stopping remote-master flush timer.");
  [PEUtils stopTimer:_timerForRemoteMasterFlush];
  [_locationManager stopUpdatingLocation];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  DDLogDebug(@"Will enter foreground. Starting remote-master flush timer.");
  _timerForRemoteMasterFlush = _startRemoteMasterFlushTimer(_coordDao, _timerForRemoteMasterFlush);
  [_locationManager startUpdatingLocation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  DDLogDebug(@"Did become active. Starting remote-master flush timer.");
  _timerForRemoteMasterFlush = _startRemoteMasterFlushTimer(_coordDao, _timerForRemoteMasterFlush);
  [_locationManager startUpdatingLocation];
}

- (void)applicationWillTerminate:(UIApplication *)application {
  DDLogDebug(@"Will terminate. Stopping remote-master flush timer.  Performing system prune.");
  [_coordDao pruneAllSyncedEntitiesWithError:[FPUtils localSaveErrorHandlerMaker]()];
  [PEUtils stopTimer:_timerForRemoteMasterFlush];
  [_locationManager stopUpdatingLocation];
}

#pragma mark - Handle Dev Shake

#ifdef FP_DEV
  - (void)devShake:(NSNotification *)shakeNotification {
    [_coordDao flushToRemoteMasterWithEditActorId:@(FPBackgroundActorId)
                               remoteStoreBusyBlk:[FPUtils serverBusyHandlerMakerForUI](nil)
                                            error:[FPUtils localDatabaseErrorHudHandlerMaker](nil)];
    DDLogDebug(@"Flush to remote master done.");
  }
#endif

#pragma mark - Initialization helpers

- (void)initializeLocationTracking {
  _locations = [NSMutableArray array];
  _locationManager = [[CLLocationManager alloc] init];
  [_locationManager setDelegate:self];
  [_locationManager requestWhenInUseAuthorization];
}

+ (NSString *)language {
  return bundleVal(FPRestServicePreferredLanguage);
}

+ (HCCharset *)charset {
  return [[HCCharset alloc] initWithEncoding:NSUTF8StringEncoding
                                 description:@"UTF-8"];
}

- (void)initializeStoreCoordinator {
  NSBundle *mainBundle = [NSBundle mainBundle];
  NSFileManager *fileMgr = [NSFileManager defaultManager];
  NSURL *localSqlLiteDataFileUrl =
      [[fileMgr URLForDirectory:NSLibraryDirectory
                       inDomain:NSUserDomainMask
              appropriateForURL:nil
                         create:YES
                          error:nil]
        URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",
                                     FPLocalSqlLiteDataFileName,
                                     FPDataFileExtension]];
  DDLogDebug(@"About to load local database from: [%@]", [localSqlLiteDataFileUrl absoluteString]);
  _coordDao =
    [[FPCoordinatorDao alloc]
      initWithSqliteDataFilePath:[localSqlLiteDataFileUrl absoluteString]
      localDatabaseCreationError:[FPUtils localDatabaseCreationErrorHandlerMaker]()
  timeoutForMainThreadOperations:intBundleVal(FPTimeoutForCoordDaoMainThreadOps)
                   acceptCharset:[HCCharset UTF8]
                  acceptLanguage:[FPAppDelegate language]
              contentTypeCharset:[HCCharset UTF8]
                      authScheme:bundleVal(FPAuthenticationScheme)
              authTokenParamName:bundleVal(FPAuthenticationTokenName)
                       authToken:nil
             errorMaskHeaderName:bundleVal(FPErrorMaskHeaderNameKey)
      establishSessionHeaderName:bundleVal(FPEstablishSessionHeaderNameKey)
     authTokenResponseHeaderName:bundleVal(FPAuthTokenResponseHeaderNameKey)
    bundleHoldingApiJsonResource:mainBundle
       nameOfApiJsonResourceFile:FPAPIResourceFileName
                 apiResMtVersion:bundleVal(FPRestServiceMtVersion)
                userResMtVersion:bundleVal(FPRestServiceMtVersion)
             vehicleResMtVersion:bundleVal(FPRestServiceMtVersion)
         fuelStationResMtVersion:bundleVal(FPRestServiceMtVersion)
     fuelPurchaseLogResMtVersion:bundleVal(FPRestServiceMtVersion)
      environmentLogResMtVersion:bundleVal(FPRestServiceMtVersion)
      remoteSyncConflictDelegate:self
               authTokenDelegate:self
 errorBlkForBackgroundProcessing:[FPUtils localErrorHandlerForBackgroundProcessingMaker]()
                   bgEditActorId:@(FPBackgroundActorId)
        allowInvalidCertificates:YES];
  [_coordDao initializeLocalDatabaseWithError:[FPUtils localSaveErrorHandlerMaker]()];
}

#pragma mark - FPRemoteStoreSyncConflictDelegate protocol

- (void)remoteStoreVersionOfUser:(FPUser *)remoteStoreUser
         isNewerThanLocalVersion:(FPUser *)localUser {
  DDLogDebug(@"Sync conflict experienced for user instance.");
}

- (void)remoteStoreVersionOfVehicle:(FPVehicle *)remoteStoreVehicle
            isNewerThanLocalVersion:(FPVehicle *)localVehicle {
  DDLogDebug(@"Sync conflict experienced for vehicle instance.");
}

- (void)remoteStoreVersionOfFuelStation:(FPFuelStation *)remoteStoreFuelStation
                isNewerThanLocalVersion:(FPFuelStation *)localFuelStation {
  DDLogDebug(@"Sync conflict experienced for fuel station instance.");
}

- (void)remoteStoreVersionOfFuelPurchaseLog:(FPFuelPurchaseLog *)remoteStoreFuelPurchaseLog
                    isNewerThanLocalVersion:(FPFuelPurchaseLog *)localFuelPurchaseLog {
  DDLogDebug(@"Sync conflict experienced for fuel purchase log instance.");
}

- (void)remoteStoreVersionOfEnvironmentLog:(FPEnvironmentLog *)remoteStoreEnvironmentLog
                   isNewerThanLocalVersion:(FPEnvironmentLog *)localEnvironmentLog {
  DDLogDebug(@"Sync conflict experienced for environment log instance.");
}

#pragma mark - FPAuthTokenDelegate protocol

- (void)didReceiveNewAuthToken:(NSString *)authToken
            forUsernameOrEmail:(NSString *)usernameOrEmail {
  DDLogDebug(@"Received new authentication token: [%@].  About to store in \
keychain under key: [%@].",
             authToken, usernameOrEmail);
  [UICKeyChainStore setString:authToken forKey:usernameOrEmail];
  // FYI, the reason we don't set the authToken on our _coordDao object is because
  // it is doing it itself; i.e., because the auth token is received THROUGH the
  // _coordDao, the _coordDao updates itself as it arrives.
}

- (void)authRequired:(HCAuthentication *)authentication {
  // since we're being told that auth is required, then, we can deduce that IF
  // we currently have an auth token in the keychain, THEN, it must no longer
  // be valid (otherwise we'd never get this method invoked), THEREFORE we'll
  // blow away the token from the keychain.
  DDLogDebug(@"authRequired: invoked.  In response, I'm going to blow-away \
contents of keychain (thus deleting user's stale auth token)");
  [UICKeyChainStore removeAllItems]; // meh, we'll use a big stick, 'cause, why not?
}

-(void)invalidateTokenForUsernameOrEmail:(NSString *)usernameOrEmail {
  DDLogDebug(@"invalidateTokenForUsernameOrEmail: invoked for usernameOrEmail: \
[%@]", usernameOrEmail);
  [UICKeyChainStore removeItemForKey:usernameOrEmail];
}

#pragma mark - Security and User-related

+ (NSString *)storedAuthenticationTokenForUser:(FPUser *)user {
  NSString *usernameOrEmail = [user usernameOrEmail];
  NSString *authToken = nil;
  if (usernameOrEmail) {
    authToken = [UICKeyChainStore stringForKey:usernameOrEmail];
  }
  DDLogDebug(@"About to return authentication token: [%@] obtained from \
keystore under key: [%@]", authToken, usernameOrEmail);
  return authToken;
}

- (UIViewController *)goalEstablishingHeightenedAuthentication {
  return nil; // todo
}

#pragma mark - UI Toolkit maker

+ (PEUIToolkit *)defaultUIToolkit {
  return [[PEUIToolkit alloc]
           initWithColorForContentPanels:[UIColor colorFromHexCode:@"0E51A7"] // (blue-ish)
              colorForNotificationPanels:[UIColor orangeColor]
                         colorForWindows:[UIColor cloudsColor]
        topBottomPaddingForContentPanels:15
                             accentColor:[UIColor colorFromHexCode:@"FFBF40"]
                          fontForButtons:[UIFont systemFontOfSize:[UIFont buttonFontSize]]
                  cornerRadiusForButtons:3
               verticalPaddingForButtons:20
             horizontalPaddingForButtons:25
                bgColorForWarningButtons:[UIColor carrotColor]
              textColorForWarningButtons:[UIColor whiteColor]
                bgColorForPrimaryButtons:[UIColor colorFromHexCode:@"05326D"]
              textColorForPrimaryButtons:[UIColor whiteColor]
                 bgColorForDangerButtons:[UIColor alizarinColor]
               textColorForDangerButtons:[UIColor whiteColor]
                    fontForHeader1Labels:[UIFont boldSystemFontOfSize:24]
                   colorForHeader1Labels:[UIColor whiteColor]
                   fontForHeaders2Labels:[UIFont boldSystemFontOfSize:18]
                   colorForHeader2Labels:[UIColor whiteColor]
                       fontForTextfields:[UIFont systemFontOfSize:18]
                      colorForTextfields:[UIColor whiteColor]
               heightFactorForTextfields:1.7
            leftViewPaddingForTextfields:10
                  fontForTableCellTitles:[UIFont systemFontOfSize:16]
                 colorForTableCellTitles:[UIColor blackColor]
               fontForTableCellSubtitles:[UIFont systemFontOfSize:10]
              colorForTableCellSubtitles:[UIColor grayColor]
               durationForFrameAnimation:0.5
             durationForFadeOutAnimation:2.0
              downToYForFromTopAnimation:40];
}

#ifdef FP_DEV

#pragma mark - PDVDevEnabled protocol

- (NSDictionary *)screenNamesForViewControllers {
    return @{
    NSStringFromClass([FPQuickActionMenuController class]) : @"authenticated-landing-screen",
    NSStringFromClass([FPUnauthStartController class]) : @"unauthenticated-landing-screen"
  };
}

- (PDVUtils *)pdvUtils {
  return _pdvUtils;
}

#pragma mark - Dev

- (NSArray *)screenGroups {
  PDVScreenGroup *createAcctScreenGroup =
    [[PDVScreenGroup alloc]
      initWithName:@"Create Account"
           screens:@[
      // Create Account / Login screen
      [[PDVScreen alloc] initWithDisplayName:@"Create Account / Login"
                                 description:@"Create Account / Login screen."
                         viewControllerMaker:^{return [_screenToolkit newUnauthLandingScreenMakerWithTempNotification:nil]();}],
      // Authenticated landing screen
      [[PDVScreen alloc] initWithDisplayName:@"Authenticated Landing"
                                 description:@"Authenticated landing screen of pre-existing user \
with resident auth token."
                         viewControllerMaker:^{return [_screenToolkit newTabBarAuthHomeLandingScreenMakerWithTempNotification:@"Welcome Back"]([_coordDao userWithError:nil]);}],
      [[PDVScreen alloc] initWithDisplayName:@"Authenticated Landing"
                                 description:@"Authenticated landing screen which \
occurs when a user creates an account."
                         viewControllerMaker:^{return [_screenToolkit newTabBarAuthHomeLandingScreenMakerWithTempNotification:@"Account Creation Successful"]([_coordDao userWithError:nil]);}]]];
  return @[ createAcctScreenGroup ];
}

#endif

@end
