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

#import <ReactiveCocoa/UITextField+RACSignalSupport.h>
#import <ReactiveCocoa/RACSubscriptingAssignmentTrampoline.h>
#import <ReactiveCocoa/RACSignal+Operations.h>
#import <PEObjc-Commons/PEUIUtils.h>
#import <PEFuelPurchase-Model/FPErrorDomainsAndCodes.h>
#import "FPCreateAccountController.h"
#import "FPAuthenticationAssertionSerializer.h"
#import "FPUserSerializer.h"
#import "FPAuthenticationAssertion.h"
#import "FPQuickActionMenuController.h"
#import "FPUtils.h"
#import "NSObject+appdelegate.h"
#import "FPAppNotificationNames.h"
#import "FPNames.h"

#ifdef FP_DEV
  #import <PEDev-Console/UIViewController+PEDevConsole.h>
#endif

@interface FPCreateAccountController ()
@property (nonatomic) NSUInteger formStateMaskForAcctCreation;
@end

@implementation FPCreateAccountController {
  FPCoordinatorDao *_coordDao;
  UITextField *_caFullNameTf;
  UITextField *_caEmailOrUsernameTf;
  UITextField *_caPasswordTf;
  CGFloat animatedDistance;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  FPUser *_localUser;
  NSNumber *_preserveExistingLocalEntities;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(FPCoordinatorDao *)coordDao
                     localUser:(FPUser *)localUser
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(FPScreenToolkit *)screenToolkit {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _coordDao = coordDao;
    _localUser = localUser;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
  }
  return self;
}

#pragma mark - View Controller Lifecyle

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [_caFullNameTf becomeFirstResponder];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  #ifdef FP_DEV
    [self pdvDevEnable];
  #endif
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  [PEUIUtils placeView:[self panelForAccountCreation]
               atTopOf:[self view]
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:100.0
              hpadding:0.0];
  UINavigationItem *navItem = [self navigationItem];
  [navItem setTitle:@"Create Account"];
  [navItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                               target:self
                                                                               action:@selector(handleAccountCreation)]];
}

#pragma mark - GUI construction (making panels)

- (UIView *)panelForAccountCreation {
  UIView *createAcctPnl = [PEUIUtils panelWithWidthOf:1.0
                                          andHeightOf:1.0
                                       relativeToView:[self view]];
  [PEUIUtils setFrameHeightOfView:createAcctPnl ofHeight:0.5 relativeTo:[self view]];
  TextfieldMaker tfMaker =
    [_uitoolkit textfieldMakerForWidthOf:1.0 relativeTo:createAcctPnl];
  _caFullNameTf = tfMaker(@"unauth.start.ca.fullnametf.pht");
  [PEUIUtils placeView:_caFullNameTf
               atTopOf:createAcctPnl
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:0.0
              hpadding:0.0];
  _caEmailOrUsernameTf = tfMaker(@"unauth.start.ca.emailorusernametf.pht");
  [PEUIUtils placeView:_caEmailOrUsernameTf
                 below:_caFullNameTf
                  onto:createAcctPnl
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:5
              hpadding:0];
  _caPasswordTf = tfMaker(@"unauth.start.ca.pwdtf.pht");
  [_caPasswordTf setSecureTextEntry:YES];
  [PEUIUtils placeView:_caPasswordTf
                 below:_caEmailOrUsernameTf
                  onto:createAcctPnl
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:5
              hpadding:0];
  RAC(self, formStateMaskForAcctCreation) =
    [RACSignal combineLatest:@[_caFullNameTf.rac_textSignal,
                               _caEmailOrUsernameTf.rac_textSignal,
                               _caPasswordTf.rac_textSignal]
                      reduce:^(NSString *fullName,
                               NSString *emailOrUsername,
                               NSString *password) {
        NSUInteger createUsrErrMask = 0;
        if ([emailOrUsername length] == 0) {
          createUsrErrMask = createUsrErrMask | FPSaveUsrUsernameAndEmailNotProvided
              | FPSaveUsrAnyIssues;
        }
        if ([password length] == 0) {
          createUsrErrMask = createUsrErrMask | FPSaveUsrPasswordNotProvided |
              FPSaveUsrAnyIssues;
        }
        return @(createUsrErrMask);
      }];
  return createAcctPnl;
}

#pragma mark - Event handling

- (void)handleAccountCreation {
  [[self view] endEditing:YES];
  if (!([self formStateMaskForAcctCreation] & FPSaveUsrAnyIssues)) {
    NSString *emailOrUsername = [_caEmailOrUsernameTf text];
    NSString *email = nil;
    NSString *username = nil;
    if ([emailOrUsername containsString:@"@"]) {
      email = emailOrUsername;
    } else {
      username = emailOrUsername;
    }
    [_localUser setName:[_caFullNameTf text]];
    [_localUser setEmail:email];
    [_localUser setUsername:username];
    [_localUser setPassword:[_caPasswordTf text]];
    __block MBProgressHUD *HUD;    
    void (^nonLocalSyncSuccessBlk)(FPUser *) = ^(FPUser *user){
      dispatch_async(dispatch_get_main_queue(), ^{
        [HUD hide:YES];
        NSString *msg = @"You're account has been successfully created.";
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success"
                                                                       message:msg
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okay = [UIAlertAction actionWithTitle:@"Okay."
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                       [[NSNotificationCenter defaultCenter] postNotificationName:FPAppAccountCreationNotification
                                                                                                           object:nil
                                                                                                         userInfo:nil];
                                                       [[self navigationController] popViewControllerAnimated:YES];
                                                     }];
        [alert addAction:okay];
        [self presentViewController:alert animated:YES completion:nil];
      });
    };
    ErrMsgsMaker errMsgsMaker = ^ NSArray * (NSInteger errCode) {
      return [FPUtils computeSaveUsrErrMsgs:errCode];
    };
    void (^doAccountCreation)(BOOL) = ^ (BOOL syncLocalEntities) {
      void (^successBlk)(FPUser *) = nil;
      if (syncLocalEntities) {
        successBlk = ^(FPUser *remoteUser) {
          [[NSNotificationCenter defaultCenter] postNotificationName:FPAppAccountCreationNotification
                                                              object:nil
                                                            userInfo:nil];
          dispatch_async(dispatch_get_main_queue(), ^{
            HUD.labelText = @"Account Creation Success!";
            HUD.detailsLabelText = @"Proceeding to sync records...";
            HUD.mode = MBProgressHUDModeDeterminate;
          });
          __block NSInteger numEntitiesSynced = 0;
          __block NSInteger syncAttemptErrors = 0;
          __block float overallSyncProgress = 0.0;
          [_coordDao flushAllUnsyncedEditsToRemoteForUser:_localUser
                                               successBlk:^(float progress) {
                                                 numEntitiesSynced++;
                                                 overallSyncProgress += progress;
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                   [HUD setProgress:overallSyncProgress];
                                                 });
                                               }
                                       remoteStoreBusyBlk:^(float progress, NSDate *retryAfter) {
                                         syncAttemptErrors++;
                                         overallSyncProgress += progress;
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                           [HUD setProgress:overallSyncProgress];
                                         });
                                       }
                                       tempRemoteErrorBlk:^(float progress) {
                                         syncAttemptErrors++;
                                         overallSyncProgress += progress;
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                           [HUD setProgress:overallSyncProgress];
                                         });
                                       }
                                           remoteErrorBlk:^(float progress, NSInteger errMask) {
                                             syncAttemptErrors++;
                                             overallSyncProgress += progress;
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                               [HUD setProgress:overallSyncProgress];
                                             });
                                           }
                                          authRequiredBlk:^(float progress) {
                                            syncAttemptErrors++;
                                            overallSyncProgress += progress;
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                              [HUD setProgress:overallSyncProgress];
                                            });
                                          }
                                                  allDone:^{
                                                    if (syncAttemptErrors == 0) {
                                                      // 100% sync success
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                        UIImage *image = [UIImage imageNamed:@"hud-complete"];
                                                        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
                                                        [HUD setCustomView:imageView];
                                                        HUD.mode = MBProgressHUDModeCustomView;
                                                        HUD.labelText = @"Sync complete!";
                                                        HUD.detailsLabelText = @"";
                                                        [HUD hide:YES afterDelay:1.30];
                                                      });
                                                      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.3 * NSEC_PER_SEC),
                                                                     dispatch_get_main_queue(), ^{
                                                        [[self navigationController] popViewControllerAnimated:YES];
                                                      });
                                                    } else {
                                                      // TODO NOT 100% success (some error(s))
                                                    }
                                                  }
                                                    error:[FPUtils localDatabaseErrorHudHandlerMaker](HUD)];
        };
      } else {
        successBlk = nonLocalSyncSuccessBlk;
      }
      HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      HUD.delegate = self;
      HUD.labelText = @"Creating account...";
      [_coordDao establishRemoteAccountForLocalUser:_localUser
                      preserveExistingLocalEntities:syncLocalEntities
                                    remoteStoreBusy:[FPUtils serverBusyHandlerMakerForUI](HUD)
                                  completionHandler:[FPUtils synchUnitOfWorkHandlerMakerWithErrMsgsMaker:errMsgsMaker](HUD, successBlk)
                              localSaveErrorHandler:[FPUtils localDatabaseErrorHudHandlerMaker](HUD)];
    };
    if (_preserveExistingLocalEntities == nil) { // first time asked
      if ([_coordDao doesUserHaveAnyUnsyncedEntities:_localUser]) {
        NSString *msg = @"It seems you've edited some records locally.  Would you like them to be synced to your remote account upon account creation, or would you like them to be deleted?";
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Locally Created Records"
                                                                       message:msg
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *synced = [UIAlertAction actionWithTitle:@"Sync them to my remote account."
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                                                         _preserveExistingLocalEntities = [NSNumber numberWithBool:YES];
                                                         doAccountCreation(YES);
                                                       }];
        UIAlertAction *delete = [UIAlertAction actionWithTitle:@"Nah.  Just delete them."
                                                         style:UIAlertActionStyleDestructive
                                                       handler:^(UIAlertAction *action) {
                                                         _preserveExistingLocalEntities = [NSNumber numberWithBool:NO];
                                                         doAccountCreation(NO);
                                                       }];
        [alert addAction:synced];
        [alert addAction:delete];
        [self presentViewController:alert animated:YES completion:nil];
      } else {
        _preserveExistingLocalEntities = [NSNumber numberWithBool:NO];
        doAccountCreation(NO);
      }
    } else {
      doAccountCreation([_preserveExistingLocalEntities boolValue]);
    }
  } else {
    NSArray *errMsgs = [FPUtils computeSaveUsrErrMsgs:_formStateMaskForAcctCreation];
    [PEUIUtils showAlertWithMsgs:errMsgs title:@"oopsMsg" buttonTitle:@"okayMsg"];
  }
}

@end
