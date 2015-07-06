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

#import "FPUtils.h"
#import <PEObjc-Commons/PEUIUtils.h>
#import <PEFuelPurchase-Model/FPErrorDomainsAndCodes.h>
#import <PEHateoas-Client/HCRelation.h>
#import <PEHateoas-Client/HCResource.h>
#import "FPLogging.h"
#import "FPNames.h"

@implementation FPUtils

#pragma mark - User Helpers

+ (NSArray *)computeSignInErrMsgs:(NSUInteger)signInErrMask {
  NSMutableArray *errMsgs = [NSMutableArray arrayWithCapacity:1];
  if (signInErrMask & FPSignInUsernameOrEmailNotProvided) {
    [errMsgs addObject:LS(@"signin.username-or-email-notprovided")];
  }
  if (signInErrMask & FPSignInPasswordNotProvided) {
    [errMsgs addObject:LS(@"signin.password-notprovided")];
  }
  if (signInErrMask & FPSignInInvalidCredentials) {
    [errMsgs addObject:LS(@"signin.credentials-invalid")];
  }
  return errMsgs;
}

+ (NSArray *)computeSaveUsrErrMsgs:(NSInteger)saveUsrErrMask {
  NSMutableArray *errMsgs = [NSMutableArray array];
  if (saveUsrErrMask & FPSaveUsrInvalidEmail) {
    [errMsgs addObject:LS(@"saveusr.email-invalid")];
  }
  if (saveUsrErrMask & FPSaveUsrUsernameAndEmailNotProvided) {
    [errMsgs addObject:LS(@"saveusr.username-and-email-notprovided")];
  }
  if (saveUsrErrMask & FPSaveUsrUsernameAlreadyRegistered) {
    [errMsgs addObject:LS(@"saveusr.username-already-registered")];
  }
  if (saveUsrErrMask & FPSaveUsrPasswordNotProvided) {
    [errMsgs addObject:LS(@"saveusr.password-notprovided")];
  }
  if (saveUsrErrMask & FPSaveUsrEmailAlreadyRegistered) {
    [errMsgs addObject:LS(@"saveusr.email-already-registered")];
  }
  return errMsgs;
}

#pragma mark - Vehicle Helpers

+ (NSArray *)computeSaveVehicleErrMsgs:(NSInteger)saveVehicleErrMask {
  NSMutableArray *errMsgs = [NSMutableArray array];
  if (saveVehicleErrMask & FPSaveVehicleNameNotProvided) {
    [errMsgs addObject:LS(@"savevehicle.name-notprovided")];
  }
  if (saveVehicleErrMask & FPSaveVehicleVehicleAlreadyExists) {
    [errMsgs addObject:LS(@"savevehicle.vehicle-already-exists")];
  }
  if (saveVehicleErrMask & FPSaveVehicleNameContainsPurple) {
    [errMsgs addObject:LS(@"savevehicle.vehicle-contains-purple")];
  }
  if (saveVehicleErrMask & FPSaveVehicleNameContainsRed) {
    [errMsgs addObject:LS(@"savevehicle.vehicle-contains-red")];
  }
  return errMsgs;
}

#pragma mark - Fuel Station Helpers

+ (NSArray *)computeSaveFuelStationErrMsgs:(NSInteger)saveFuelStationErrMask {
  NSMutableArray *errMsgs = [NSMutableArray array];
  if (saveFuelStationErrMask & FPSaveFuelStationNameNotProvided) {
    [errMsgs addObject:LS(@"savefuelstation.name-notprovided")];
  }
  return errMsgs;
}

+ (NSArray *)sortFuelstations:(NSArray *)fuelstations
     inAscOrderByDistanceFrom:(CLLocation *)location {
  return [fuelstations sortedArrayUsingComparator:^NSComparisonResult(FPFuelStation *fs1, FPFuelStation *fs2) {
    CLLocation *latestCurrentLocation = [APP latestLocation];
    CLLocation *fs1Location = [fs1 location];
    CLLocation *fs2Location = [fs2 location];
    if (!fs1Location && !fs2Location) {
      return NSOrderedSame;
    }
    if (fs1Location && !fs2Location) {
      return NSOrderedAscending;
    }
    if (fs2Location && !fs1Location) {
      return NSOrderedDescending;
    }
    if (latestCurrentLocation) {
      CLLocationDistance fs1Distance = [latestCurrentLocation distanceFromLocation:fs1Location];
      CLLocationDistance fs2Distance = [latestCurrentLocation distanceFromLocation:fs2Location];
      if (fs1Distance < fs2Distance) {
        return NSOrderedAscending;
      } else {
        return NSOrderedDescending;
      }
    }
    return NSOrderedSame; // should never get here
  }];
}

#pragma mark - Fuel Purchase Log Helpers

+ (NSArray *)computeFpLogErrMsgs:(NSInteger)saveFpLogErrMask {
  NSMutableArray *errMsgs = [NSMutableArray array];  
  if (saveFpLogErrMask & FPSaveFuelPurchaseLogPurchaseDateNotProvided) {
    [errMsgs addObject:LS(@"savefplog.purchasedate-notprovided")];
  }
  if (saveFpLogErrMask & FPSaveFuelPurchaseLogNumGallonsNotProvided) {
    [errMsgs addObject:LS(@"savefplog.numgallons-notprovided")];
  }
  if (saveFpLogErrMask & FPSaveFuelPurchaseLogOctaneNotProvided) {
    [errMsgs addObject:LS(@"savefplog.octane-notprovided")];
  }
  if (saveFpLogErrMask & FPSaveFuelPurchaseLogGallonPriceNotProvided) {
    [errMsgs addObject:LS(@"savefplog.gallonprice-notprovided")];
  }
  if (saveFpLogErrMask & FPSaveFuelPurchaseLogNumGallonsNegative) {
    [errMsgs addObject:LS(@"savefplog.numgallons-negative")];
  }
  if (saveFpLogErrMask & FPSaveFuelPurchaseLogOctaneNegative) {
    [errMsgs addObject:LS(@"savefplog.octane-negative")];
  }
  if (saveFpLogErrMask & FPSaveFuelPurchaseLogGallonPriceNegative) {
    [errMsgs addObject:LS(@"savefplog.gallonprice-negative")];
  }
  return errMsgs;
}

#pragma mark - Environment Log Helpers

+ (NSArray *)computeEnvLogErrMsgs:(NSInteger)saveEnvLogErrMask {
  NSMutableArray *errMsgs = [NSMutableArray array];
  if (saveEnvLogErrMask & FPSaveEnvironmentLogDateNotProvided) {
    [errMsgs addObject:LS(@"savenvlog.logdate-notprovided")];
  }
  if (saveEnvLogErrMask & FPSaveEnvironmentLogOdometerNotProvided) {
    [errMsgs addObject:LS(@"savenvlog.odometer-notprovided")];
  }
  if (saveEnvLogErrMask & FPSaveEnvironmentLogOutsideTempNotProvided) {
    [errMsgs addObject:LS(@"savenvlog.outside-temp-notprovided")];
  }
  if (saveEnvLogErrMask & FPSaveEnvironmentLogOdometerNegative) {
    [errMsgs addObject:LS(@"savenvlog.odometer-negative")];
  }
  return errMsgs;
}

#pragma mark - Various Error Handler Helpers

+ (ServerBusyHandlerMaker)serverBusyHandlerMakerForUI {
  return ^(MBProgressHUD *HUD) {
    return (^(NSDate *retryAfter) {
        [HUD hide:YES];
        [PEUIUtils
          showAlertWithMsgs:@[[NSString stringWithFormat:@"The server is \
busy, and asks that you try again at date: %@.", retryAfter]]
                      title:@"Server Busy"
                buttonTitle:@"okayMsg"];
    });
  };
}

+ (SynchUnitOfWorkHandlerMaker)synchUnitOfWorkHandlerMakerWithErrMsgsMaker:(ErrMsgsMaker)errMsgsMaker {
  return ^(MBProgressHUD *hud, void (^successBlock)(FPUser *)) {
    return (^(FPUser *newUser, NSError *error) {
      if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [hud hide:YES];
          NSString *errorDomain = [error domain];
          NSInteger errorCode = [error code];
          NSArray *errMsgs;
          if ([errorDomain isEqualToString:FPConnFaultedErrorDomain]) {
            NSString *localizedErrMsgKey =
              [errorDomain stringByAppendingFormat:@".%ld", (long)errorCode];
            errMsgs = @[NSLocalizedString(localizedErrMsgKey, nil)];
          } else if ([errorDomain isEqualToString:FPUserFaultedErrorDomain]) {
            errMsgs = errMsgsMaker(errorCode);
          } else {
            errMsgs = @[[error localizedDescription]];
          }
          [PEUIUtils showAlertWithMsgs:errMsgs
                                 title:@"Error"
                           buttonTitle:@"Okay"];
        });
      } else {
        successBlock(newUser);
      }
    });
  };
}

+ (SynchUnitOfWorkHandlerMakerZeroArg)synchUnitOfWorkZeroArgHandlerMakerWithErrMsgsMaker:(ErrMsgsMaker)errMsgsMaker {
  return ^(MBProgressHUD *hud, void (^successBlock)(void)) {
    return (^(NSError *error) {
      if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [hud hide:YES];
          NSString *errorDomain = [error domain];
          NSInteger errorCode = [error code];
          NSArray *errMsgs;
          if ([errorDomain isEqualToString:FPConnFaultedErrorDomain]) {
            NSString *localizedErrMsgKey =
            [errorDomain stringByAppendingFormat:@".%ld", (long)errorCode];
            errMsgs = @[NSLocalizedString(localizedErrMsgKey, nil)];
          } else if ([errorDomain isEqualToString:FPUserFaultedErrorDomain]) {
            errMsgs = errMsgsMaker(errorCode);
          } else {
            errMsgs = @[[error localizedDescription]];
          }
          [PEUIUtils showAlertWithMsgs:errMsgs
                                 title:@"Error"
                           buttonTitle:@"Okay"];
        });
      } else {
        successBlock();
      }
    });
  };
}

+ (LocalDatabaseErrorHandlerMakerWithHUD)localDatabaseErrorHudHandlerMaker {
  return ^(MBProgressHUD *hud) {
    return (^(NSError *error, int code, NSString *msg) {
      [hud hide:YES];
      [PEUIUtils
       showAlertWithMsgs:@[[NSString stringWithFormat:@"There was a problem interacting with the local database.  \
Error message: %@", [error localizedDescription]]]
                   title:@"Local Error"
             buttonTitle:@"okayMsg"];
    });
  };
}

+ (LocalDatabaseErrorHandlerMaker)localSaveErrorHandlerMaker {
  return ^{
    return (^(NSError *error, int code, NSString *msg) {
      DDLogError(@"There was a problem saving data to the local database.  Error message: %@", [error localizedDescription]);
    });
  };
}

+ (LocalDatabaseErrorHandlerMaker)localFetchErrorHandlerMaker {
  return ^{
    return (^(NSError *error, int code, NSString *msg) {
      DDLogError(@"There was a problem fetching data from the local database.  Error message: %@", [error localizedDescription]);
    });
  };
}

+ (LocalDatabaseErrorHandlerMaker)localErrorHandlerForBackgroundProcessingMaker {
  return ^{
    return (^(NSError *error, int code, NSString *msg) {
      DDLogError(@"There was a local database problem encountered while performing background processing.  Error message: %@", [error localizedDescription]);
    });
  };
}

+ (LocalDatabaseErrorHandlerMaker)localDatabaseCreationErrorHandlerMaker {
  return ^{
    return (^(NSError *error, int code, NSString *msg) {
      DDLogError(@"There was a problem attempting to create the local database.  Error message: %@", [error localizedDescription]);
    });
  };
}

@end
