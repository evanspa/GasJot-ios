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
#import "FPAccountLoginController.h"
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

@interface FPAccountLoginController ()
@property (nonatomic) NSUInteger formStateMaskForAcctCreation;
@property (nonatomic) NSUInteger formStateMaskForSignIn;
@end

@implementation FPAccountLoginController {
  FPCoordinatorDao *_coordDao;
  UITextField *_siUsernameOrEmailTf;
  UITextField *_siPasswordTf;
  UIButton *_siDoSignInBtn;
  UITextField *_caFullNameTf;
  UITextField *_caEmailTf;
  UITextField *_caPasswordTf;
  UIButton *_caDoCreateAcctBtn;
  CGFloat animatedDistance;
  MBProgressHUD *_HUD;
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

- (void)viewDidLoad {
  [super viewDidLoad];
  #ifdef FP_DEV
    [self pdvDevEnable];
  #endif
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  [PEUIUtils placeView:[self panelForSignIn]
               atTopOf:[self view]
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:100.0
              hpadding:0.0];
  UINavigationItem *navItem = [self navigationItem];
  [navItem setTitle:@"Log In"];
  [navItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Log In"
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(handleSignIn)]];
  [_siUsernameOrEmailTf becomeFirstResponder];
  _preserveExistingLocalEntities = nil;
}

#pragma mark - GUI construction (making panels)

- (UIView *)panelForSignIn {
  PanelMaker pnlMaker = [_uitoolkit contentPanelMakerRelativeTo:[self view]];
  //ButtonMaker btnMaker = [_uitoolkit primaryButtonMaker];
  UIView *signInPnl = pnlMaker(1.0);
  TextfieldMaker tfMaker = [_uitoolkit textfieldMakerForWidthOf:1.0 relativeTo:signInPnl];
  _siUsernameOrEmailTf = tfMaker(@"unauth.start.signin.emailusernmtf.pht");
  [PEUIUtils placeView:_siUsernameOrEmailTf
               atTopOf:signInPnl
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:0.0
              hpadding:0.0];
  _siPasswordTf = tfMaker(@"unauth.start.signin.pwdtf.pht");
  [_siPasswordTf setSecureTextEntry:YES];
  [PEUIUtils placeView:_siPasswordTf
                 below:_siUsernameOrEmailTf
                  onto:signInPnl
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:5.0
              hpadding:0.0];
  /*_siDoSignInBtn =
    btnMaker(@"unauth.start.signin.btn.txt", self, @selector(handleSignIn));
  [PEUIUtils placeView:_siDoSignInBtn
                 below:_siPasswordTf
                  onto:signInPnl
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:15
              hpadding:0];*/
  RAC(self, formStateMaskForSignIn) =
    [RACSignal combineLatest:@[_siUsernameOrEmailTf.rac_textSignal,
                               _siPasswordTf.rac_textSignal]
                       reduce:^(NSString *usernameOrEmail,
                                NSString *password) {
        NSUInteger signInErrMask = 0;
        if ([usernameOrEmail length] == 0) {
          signInErrMask = FPSignInUsernameOrEmailNotProvided |
            FPSignInAnyIssues;
        }
        if ([password length] == 0) {
          signInErrMask = signInErrMask | FPSignInPasswordNotProvided |
            FPSignInAnyIssues;
        }
        return @(signInErrMask);
      }];
  return signInPnl;
}

#pragma mark - Helpers

- (NSArray *)computeSignInErrMsgs:(NSUInteger)signInErrMask {
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

#pragma mark - Sign-in / Sign-up event handling

- (void)handleSignIn {
  [[self view] endEditing:YES];
  if (!([self formStateMaskForSignIn] & FPSignInAnyIssues)) {
    _HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _HUD.delegate = self;
    void (^nonLocalSyncSuccessBlk)(FPUser *) = ^(FPUser *user){
      dispatch_async(dispatch_get_main_queue(), ^{
        [_HUD hide:YES afterDelay:0];
        NSString *msg = @"You have been successfully signed in.";
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success"
                                                                       message:msg
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okay = [UIAlertAction actionWithTitle:@"Okay."
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                       [[NSNotificationCenter defaultCenter] postNotificationName:FPAppLoginNotification
                                                                                                           object:nil
                                                                                                         userInfo:nil];
                                                       [[self navigationController] popViewControllerAnimated:YES];
                                                     }];
        [alert addAction:okay];
        [self presentViewController:alert animated:YES completion:nil];
      });
    };
    ErrMsgsMaker errMsgsMaker = ^ NSArray * (NSInteger errCode) {
      return [self computeSignInErrMsgs:errCode];
    };
    void (^doLogin)(BOOL) = ^ (BOOL syncLocalEntities) {
      void (^successBlk)(FPUser *) = nil;
      if (syncLocalEntities) {
        successBlk = ^(FPUser *remoteUser) {
          dispatch_async(dispatch_get_main_queue(), ^{
            _HUD.labelText = @"Authentication Success!";
            _HUD.detailsLabelText = @"Proceeding to sync records...";
            _HUD.mode = MBProgressHUDModeDeterminate;
            
            __block NSInteger numEntitiesSynced = 0;
            __block NSInteger numEntitiesSyncAttempted = 0;
            __block float overallSyncProgress = 0.0;
            NSInteger numEntitiesToSync = 0;
            numEntitiesToSync = [_coordDao flushAllUnsyncedEditsToRemoteForUser:_localUser
                                                                     successBlk:^(float progress) {
                                                                       numEntitiesSyncAttempted++;
                                                                       numEntitiesSynced++;
                                                                       overallSyncProgress += progress;
                                                                       [_HUD setProgress:overallSyncProgress];
                                                                       if (numEntitiesSyncAttempted == numEntitiesToSync) {
                                                                         // Done syncing
                                                                         if (numEntitiesSynced == numEntitiesToSync) {
                                                                           // 100% sync success
                                                                           dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                                                             UIImage *image = [UIImage imageNamed:@"hud-complete"];
                                                                             UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
                                                                             [_HUD setCustomView:imageView];
                                                                             _HUD.mode = MBProgressHUDModeCustomView;
                                                                             _HUD.labelText = @"Sync complete!";
                                                                             _HUD.detailsLabelText = @"";
                                                                             [_HUD hide:YES afterDelay:1.30];                                                                             
                                                                           });
                                                                         } else {
                                                                           // NOT success (some error(s))
                                                                         }
                                                                       }
                                                                     }
                                                             remoteStoreBusyBlk:^(float progress, NSDate *retryAfter) {
                                                               numEntitiesSyncAttempted++;
                                                               overallSyncProgress += progress;
                                                               [_HUD setProgress:overallSyncProgress];
                                                               if (numEntitiesSyncAttempted == numEntitiesToSync) {
                                                                 // Done syncing with some error(s)
                                                               }
                                                             }
                                                             tempRemoteErrorBlk:^(float progress) {
                                                               numEntitiesSyncAttempted++;
                                                               overallSyncProgress += progress;
                                                               [_HUD setProgress:overallSyncProgress];
                                                               if (numEntitiesSyncAttempted == numEntitiesToSync) {
                                                                 // Done syncing with some error(s)
                                                               }
                                                             }
                                                                 remoteErrorBlk:^(float progress, NSInteger errMask) {
                                                                   numEntitiesSyncAttempted++;
                                                                   overallSyncProgress += progress;
                                                                   [_HUD setProgress:overallSyncProgress];
                                                                   if (numEntitiesSyncAttempted == numEntitiesToSync) {
                                                                     // Done syncing with some error(s)
                                                                   }
                                                                 }
                                                                authRequiredBlk:^(float progress) {
                                                                  numEntitiesSyncAttempted++;
                                                                  overallSyncProgress += progress;
                                                                  [_HUD setProgress:overallSyncProgress];
                                                                  if (numEntitiesSyncAttempted == numEntitiesToSync) {
                                                                    // Done syncing with some error(s)
                                                                  }
                                                                }
                                                                          error:[FPUtils localDatabaseErrorHudHandlerMaker](_HUD)];
          });
        };
      } else {
        successBlk = nonLocalSyncSuccessBlk;
      }
      [_coordDao loginWithUsernameOrEmail:[_siUsernameOrEmailTf text]
                                 password:[_siPasswordTf text]
             andLinkRemoteUserToLocalUser:_localUser
            preserveExistingLocalEntities:syncLocalEntities
                          remoteStoreBusy:[FPUtils serverBusyHandlerMakerForUI](_HUD)
                        completionHandler:[FPUtils synchUnitOfWorkHandlerMakerWithErrMsgsMaker:errMsgsMaker](_HUD, successBlk)
                    localSaveErrorHandler:[FPUtils localDatabaseErrorHudHandlerMaker](_HUD)];
    };
    if (_preserveExistingLocalEntities == nil) { // first time asked
      if ([_coordDao doesUserHaveAnyUnsyncedEntities:_localUser]) {
        NSString *msg = @"It seems you've created some records locally.  Would you like them to be synced to your remote account upon logging in, or would you like them to be deleted?";
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Locally Created Records"
                                                                       message:msg
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *synced = [UIAlertAction actionWithTitle:@"Sync them to my remote account."
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                                                         _preserveExistingLocalEntities = [NSNumber numberWithBool:YES];
                                                         _HUD.labelText = @"Proceeding to authenticate...";
                                                         doLogin(YES);
                                                       }];
        UIAlertAction *delete = [UIAlertAction actionWithTitle:@"Nah.  Just delete them."
                                                         style:UIAlertActionStyleDestructive
                                                       handler:^(UIAlertAction *action) {
                                                         _preserveExistingLocalEntities = [NSNumber numberWithBool:NO];
                                                         _HUD.labelText = @"Proceeding to authenticate...";
                                                         doLogin(NO);
                                                       }];
        [alert addAction:synced];
        [alert addAction:delete];
        [self presentViewController:alert animated:YES completion:nil];
      } else {
        _preserveExistingLocalEntities = [NSNumber numberWithBool:YES];
        _HUD.labelText = @"Authenticating...";
        doLogin(YES);
      }
    } else {
      _HUD.labelText = @"Authenticating...";
      doLogin([_preserveExistingLocalEntities boolValue]);
    }
  } else {
    NSArray *errMsgs = [self computeSignInErrMsgs:_formStateMaskForSignIn];
    [PEUIUtils showAlertWithMsgs:errMsgs title:@"oopsMsg" buttonTitle:@"okayMsg"];
  }
}

@end
