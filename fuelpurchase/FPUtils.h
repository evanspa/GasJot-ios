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

#import <Foundation/Foundation.h>
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <PEFuelPurchase-Model/FPUser.h>
#import <PEFuelPurchase-Model/PELMUtils.h>

typedef NSArray * (^ErrMsgsMaker)(NSInteger errCode);

typedef void (^(^ServerBusyHandlerMaker)(MBProgressHUD *))(NSDate *);

typedef void (^(^SynchUnitOfWorkHandlerMaker)(MBProgressHUD *, void (^)(FPUser *)))(FPUser *, NSError *);

typedef void (^(^LocalDatabaseErrorHandlerMakerWithHUD)(MBProgressHUD *))(NSError *, int, NSString *);

typedef void (^(^LocalDatabaseErrorHandlerMaker)(void))(NSError *, int, NSString *);

/**
 A set of (usually) context-agnostic helper functions.
 */
@interface FPUtils : NSObject

#pragma mark - User Helpers

+ (NSArray *)computeSignInErrMsgs:(NSUInteger)signInErrMask;

+ (NSArray *)computeSaveUsrErrMsgs:(NSInteger)saveUsrErrMask;

#pragma mark - Vehicle Helpers

+ (NSArray *)computeSaveVehicleErrMsgs:(NSInteger)saveVehicleErrMask;

#pragma mark - Fuel Station Helpers

+ (NSArray *)computeSaveFuelStationErrMsgs:(NSInteger)saveFuelStationErrMask;

+ (NSArray *)sortFuelstations:(NSArray *)fuelstations
     inAscOrderByDistanceFrom:(CLLocation *)location;

#pragma mark - Various Error Handler Helpers

+ (ServerBusyHandlerMaker)serverBusyHandlerMakerForUI;

+ (SynchUnitOfWorkHandlerMaker)synchUnitOfWorkHandlerMakerWithErrMsgsMaker:(ErrMsgsMaker)errMsgsMaker;

+ (LocalDatabaseErrorHandlerMakerWithHUD)localDatabaseErrorHudHandlerMaker;

+ (LocalDatabaseErrorHandlerMaker)localSaveErrorHandlerMaker;

+ (LocalDatabaseErrorHandlerMaker)localFetchErrorHandlerMaker;

+ (LocalDatabaseErrorHandlerMaker)localErrorHandlerForBackgroundProcessingMaker;

+ (LocalDatabaseErrorHandlerMaker)localDatabaseCreationErrorHandlerMaker;

@end
