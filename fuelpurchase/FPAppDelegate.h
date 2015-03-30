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

#import <UIKit/UIKit.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <PEFuelPurchase-Common/FPAuthTokenDelegate.h>
#import <PEFuelPurchase-Model/FPRemoteStoreSyncConflictDelegate.h>
#import <PEFuelPurchase-Model/FPCoordinatorDao.h>
#import <PEAppTransaction-Logger/TLTransactionManager.h>
#import <PEObjc-Commons/PEUIToolkit.h>

#ifdef FP_DEV
  #import <PEDev-Console/PDVDevEnabled.h>
#endif

/**
  Application delegate.
 */
@interface FPAppDelegate : UIResponder <UIApplicationDelegate,
  CLLocationManagerDelegate,
  MBProgressHUDDelegate,
  FPAuthTokenDelegate,
  FPRemoteStoreSyncConflictDelegate
#ifdef FP_DEV
  ,PDVDevEnabled
#endif
>

#pragma mark - Properties

/** The application window. */
@property (strong, nonatomic) UIWindow *window;

#pragma mark - Methods

- (CLLocation *)latestLocation;

@end
