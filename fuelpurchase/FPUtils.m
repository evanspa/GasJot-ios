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

@implementation FPUtils

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
      [hud hide:YES];
      if (error) {
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
      } else {
        successBlock(newUser);
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
