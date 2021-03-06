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
#import <PEFuelPurchase-Model/FPFuelStation.h>
#import <PEFuelPurchase-Model/FPFuelStationType.h>

@implementation FPUtils

#pragma mark - General Helpers

+ (NSString *)truncatedText:(NSString *)text maxLength:(NSInteger)maxLength {
  if ([text length] > maxLength) {
    return [[text substringToIndex:maxLength] stringByAppendingString:@"..."];
  }
  return text;
}

+ (NSArray *)computeErrMessagesWithErrMask:(NSUInteger)errMask
                               errMessages:(NSArray *)errMessages {
  NSMutableArray *computedErrMsgs = [NSMutableArray array];
  for (NSArray *errMsg in errMessages) {
    NSNumber *errTypeNumber = errMsg[0];
    NSUInteger errType = [errTypeNumber unsignedIntegerValue];
    NSString *localizedErrKey = errMsg[1];
    if (errMask & errType) {
      [computedErrMsgs addObject:LS(localizedErrKey)];
    }
  }
  return computedErrMsgs;
}

#pragma mark - User Helpers

+ (NSArray *)computeSignInErrMsgs:(NSUInteger)signInErrMask {
  return [FPUtils computeErrMessagesWithErrMask:signInErrMask
                                    errMessages:[APP signInErrMessages]];
}

+ (NSArray *)computeSaveUsrErrMsgs:(NSInteger)saveUsrErrMask {
  return [FPUtils computeErrMessagesWithErrMask:saveUsrErrMask
                                    errMessages:[APP saveUserErrMessages]];
}

#pragma mark - Vehicle Helpers

+ (NSArray *)computeSaveVehicleErrMsgs:(NSInteger)saveVehicleErrMask {
  return [FPUtils computeErrMessagesWithErrMask:saveVehicleErrMask
                                    errMessages:[APP saveVehicleErrMessages]];
}

#pragma mark - Fuel Station Helpers

+ (NSArray *)computeSaveFuelStationErrMsgs:(NSInteger)saveFuelStationErrMask {
  return [FPUtils computeErrMessagesWithErrMask:saveFuelStationErrMask
                                    errMessages:[APP saveFuelstationErrMessages]];
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
  return [FPUtils computeErrMessagesWithErrMask:saveFpLogErrMask
                                    errMessages:[APP saveFplogErrMessages]];
}

#pragma mark - Environment Log Helpers

+ (NSArray *)computeEnvLogErrMsgs:(NSInteger)saveEnvLogErrMask {
  return [FPUtils computeErrMessagesWithErrMask:saveEnvLogErrMask
                                    errMessages:[APP saveEnvlogErrMessages]];
}

#pragma mark - Various Error Handler Helpers

+ (ServerBusyHandlerMaker)serverBusyHandlerMakerForUI {
  return ^(MBProgressHUD *HUD, UIViewController *controller, UIView *relativeToView) {
    return (^(NSDate *retryAfter) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [HUD hide:YES];
        [PEUIUtils showWaitAlertWithMsgs:nil
                                   title:@"Server undergoing maintenance."
                        alertDescription:[[NSAttributedString alloc] initWithString:@"\
We apologize, but the server is currently busy undergoing maintenance.  Please re-try your request shortly."]
                                topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                             buttonTitle:@"Okay."
                            buttonAction:nil
                          relativeToView:relativeToView];
      });
    });
  };
}

+ (SynchUnitOfWorkHandlerMakerZeroArg)loginHandlerWithErrMsgsMaker:(ErrMsgsMaker)errMsgsMaker {
  return ^(MBProgressHUD *hud, void(^successBlock)(void), void(^notAuthedAlertAction)(void), UIViewController *controller, UIView *relativeToView) {
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
          NSString *message;
          if ([errMsgs count] > 1) {
            message = @"Messages from the server:";
          } else {
            message = @"Message from the server:";
          }
          [PEUIUtils showErrorAlertWithMsgs:errMsgs
                                      title:@"Authentication failure."
                           alertDescription:[[NSAttributedString alloc] initWithString:message]
                                   topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                buttonTitle:@"Okay."
                               buttonAction:notAuthedAlertAction
                             relativeToView:relativeToView];
        });
      } else {
        successBlock();        
      }
    });
  };
}

+ (SynchUnitOfWorkHandlerMaker)synchUnitOfWorkHandlerMakerWithErrMsgsMaker:(ErrMsgsMaker)errMsgsMaker {
  return ^(MBProgressHUD *hud, void (^successBlock)(FPUser *), void(^errAlertAction)(void), UIViewController *controller, UIView *relativeToView) {
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
          [PEUIUtils showErrorAlertWithMsgs:errMsgs
                                      title:@"Oops."
                           alertDescription:[[NSAttributedString alloc] initWithString:@"An error has occurred.  The details are as\n\
follows:"]
                                   topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                buttonTitle:@"Okay."
                               buttonAction:errAlertAction
                             relativeToView:relativeToView];
        });
      } else {
        successBlock(newUser);
      }
    });
  };
}

+ (SynchUnitOfWorkHandlerMakerZeroArg)synchUnitOfWorkZeroArgHandlerMakerWithErrMsgsMaker:(ErrMsgsMaker)errMsgsMaker {
  return ^(MBProgressHUD *hud, void(^successBlock)(void), void(^errAlertAction)(void), UIViewController *controller, UIView *relativeToView) {
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
          [PEUIUtils showErrorAlertWithMsgs:errMsgs
                                      title:@"Oops."
                           alertDescription:[[NSAttributedString alloc] initWithString:@"An error has occurred.  The details are as follows:"]
                                   topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                buttonTitle:@"Okay."
                               buttonAction:errAlertAction
                             relativeToView:relativeToView];
        });
      } else {
        successBlock();
      }
    });
  };
}

+ (LocalDatabaseErrorHandlerMakerWithHUD)localDatabaseErrorHudHandlerMaker {
  return ^(MBProgressHUD *hud, UIViewController *controller, UIView *relativeToView) {
    return (^(NSError *error, int code, NSString *msg) {
      [hud hide:YES];
      [PEUIUtils showErrorAlertWithMsgs:@[[error localizedDescription]]
                                  title:@"This is awkward."
                       alertDescription:[[NSAttributedString alloc] initWithString:@"An error has occurred attempting to talk\n\
to the local database.  The details are:"]
                               topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                            buttonTitle:@"Okay."
                           buttonAction:nil
                         relativeToView:relativeToView];
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
