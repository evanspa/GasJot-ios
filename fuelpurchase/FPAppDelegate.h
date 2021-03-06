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

@import UIKit;
@import CoreLocation;

#import <MBProgressHUD/MBProgressHUD.h>
#import <PELocal-Data/PEAuthTokenDelegate.h>
#import <PEObjc-Commons/PEUIToolkit.h>

#import "FPCoordinatorDao.h"

#ifdef FP_DEV
  #import <PEDev-Console/PDVDevEnabled.h>
#endif

FOUNDATION_EXPORT NSInteger const FPJotButtonTag;

/**
  Application delegate.
 */
@interface FPAppDelegate : UIResponder <UIApplicationDelegate,
  CLLocationManagerDelegate,
  MBProgressHUDDelegate,
  PEAuthTokenDelegate,
  UITabBarControllerDelegate
#ifdef FP_DEV
  ,PDVDevEnabled
#endif
>

#pragma mark - Security and User-related

- (void)clearKeychain;

- (BOOL)isUserLoggedIn;

- (BOOL)doesUserHaveValidAuthToken;

#pragma mark - Total Num Unsynced Entities Refresher

- (void)refreshTabs;

#pragma mark - Resetting the user interface and tab bar delegate

- (void)resetUserInterface;

#pragma mark - Properties

@property (nonatomic) BOOL offlineMode;

@property (nonatomic, readonly) CLLocationManager *locationManager;

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic) NSArray *signInErrMessages;

@property (nonatomic) NSArray *saveUserErrMessages;

@property (nonatomic) NSArray *saveVehicleErrMessages;

@property (nonatomic) NSArray *saveFuelstationErrMessages;

@property (nonatomic) NSArray *saveFplogErrMessages;

@property (nonatomic) NSArray *saveEnvlogErrMessages;

#pragma mark - Methods

- (void)enableJotButton:(BOOL)enableJotButton;

- (CGFloat)jotButtonHeight;

- (void)setUser:(FPUser *)user tabBarController:(UITabBarController *)tabBarController;

- (CLLocation *)latestLocation;

- (NSDate *)changelogUpdatedAt;

- (void)setChangelogUpdatedAt:(NSDate *)updatedAt;

- (BOOL)hasBeenAskedToEnableLocationServices;

- (void)setHasBeenAskedToEnableLocationServices:(BOOL)beenAsked;

- (BOOL)locationServicesAuthorized;

- (BOOL)locationServicesDenied;

- (NSInteger)priceSearchDistanceWithin;

- (NSInteger)priceSearchMaxResults;

@end
