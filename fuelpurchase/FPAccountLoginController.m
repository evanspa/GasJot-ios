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
#import <PEObjc-Commons/PEUtils.h>
#import <PEFuelPurchase-Model/FPErrorDomainsAndCodes.h>
#import "FPAccountLoginController.h"
#import "FPAuthenticationAssertionSerializer.h"
#import "FPUserSerializer.h"
#import "FPAuthenticationAssertion.h"
#import "FPQuickActionMenuController.h"
#import "FPUtils.h"
#import "FPAppNotificationNames.h"
#import "FPNames.h"

#ifdef FP_DEV
  #import <PEDev-Console/UIViewController+PEDevConsole.h>
#endif

@interface FPAccountLoginController ()
@property (nonatomic) NSUInteger formStateMaskForSignIn;
@end

@implementation FPAccountLoginController {
  FPCoordinatorDao *_coordDao;
  UITextField *_siUsernameOrEmailTf;
  UITextField *_siPasswordTf;
  UIButton *_siDoSignInBtn;
  CGFloat animatedDistance;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  FPUser *_localUser;
  NSNumber *_preserveExistingLocalEntities;
  BOOL _receivedAuthReqdErrorOnSyncAttempt;
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
  UIView *signInPnl = [PEUIUtils panelWithWidthOf:1.0
                                          andHeightOf:1.0
                                       relativeToView:[self view]];
  [PEUIUtils setFrameHeightOfView:signInPnl ofHeight:1.0 relativeTo:[self view]];
  UILabel *signInMsgLabel = [PEUIUtils labelWithKey:@"\
From here you can log into your remote\n\
account, connecting this device to it.  Your\n\
fuel purchase data will be downloaded to this\n\
device.\n\n\
Enter your credentials and tap 'Log In'."
                                               font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                    backgroundColor:[UIColor clearColor]
                                          textColor:[UIColor darkGrayColor]
                                verticalTextPadding:3.0];
  UIView *signInMsgPanel = [PEUIUtils leftPadView:signInMsgLabel padding:8.0];
  TextfieldMaker tfMaker = [_uitoolkit textfieldMakerForWidthOf:1.0 relativeTo:signInPnl];
  _siUsernameOrEmailTf = tfMaker(@"unauth.start.signin.emailusernmtf.pht");
  _siPasswordTf = tfMaker(@"unauth.start.signin.pwdtf.pht");
  [_siPasswordTf setSecureTextEntry:YES];
  
  // place views
  [PEUIUtils placeView:signInMsgPanel
               atTopOf:signInPnl
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:0.0
              hpadding:0.0];
  [PEUIUtils placeView:_siUsernameOrEmailTf
                 below:signInMsgPanel
                  onto:signInPnl
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:7.0
              hpadding:0.0];
  [PEUIUtils placeView:_siPasswordTf
                 below:_siUsernameOrEmailTf
                  onto:signInPnl
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:5.0
              hpadding:0.0];
  
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

#pragma mark - Login event handling

- (void)handleSignIn {
  [[self view] endEditing:YES];
  if (!([self formStateMaskForSignIn] & FPSignInAnyIssues)) {
    __block MBProgressHUD *HUD;
    void (^nonLocalSyncSuccessBlk)(void) = ^{
      dispatch_async(dispatch_get_main_queue(), ^{
        [HUD hide:YES];
        [PEUIUtils showLoginSuccessAlertWithTitle:@"Login success."
                                 alertDescription:[[NSAttributedString alloc] initWithString:@"\
You have been successfully logged in.\n\n\
Your remote account is now connected to\n\
this device.  Any fuel purchase data that\n\
you create and save will be synced to your\n\
remote account."]
                                  syncIconMessage:[[NSAttributedString alloc] initWithString:@"\
The following icon will appear in the app\n\
indicating that your are currently logged\n\
into your remote account:"]
                                         topInset:70.0
                                      buttonTitle:@"Okay."
                                     buttonAction:^{
                                         [[NSNotificationCenter defaultCenter] postNotificationName:FPAppLoginNotification
                                                                                             object:nil
                                                                                           userInfo:nil];
                                         [[self navigationController] popViewControllerAnimated:YES];
                                       }
                                   relativeToView:self.tabBarController.view];
      });
    };
    ErrMsgsMaker errMsgsMaker = ^ NSArray * (NSInteger errCode) {
      return [FPUtils computeSignInErrMsgs:errCode];
    };
    void (^doLogin)(BOOL) = ^ (BOOL syncLocalEntities) {
      _receivedAuthReqdErrorOnSyncAttempt = NO;
      void (^successBlk)(void) = nil;
      if (syncLocalEntities) {
        successBlk = ^{
          [[NSNotificationCenter defaultCenter] postNotificationName:FPAppLoginNotification
                                                              object:nil
                                                            userInfo:nil];
          dispatch_async(dispatch_get_main_queue(), ^{
            HUD.labelText = @"You're now logged in.";
            HUD.detailsLabelText = @"Proceeding to sync records...";
            HUD.mode = MBProgressHUDModeDeterminate;
          });
          __block NSInteger numEntitiesSynced = 0;
          __block NSInteger syncAttemptErrors = 0;
          __block float overallSyncProgress = 0.0;
          [_coordDao flushAllUnsyncedEditsToRemoteForUser:_localUser
                                        entityNotFoundBlk:^(float progress) {
                                          syncAttemptErrors++;
                                          overallSyncProgress += progress;
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                            [HUD setProgress:overallSyncProgress];
                                          });
                                        }
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
                                              conflictBlk:^(float progress, id latestEntity) {
                                                syncAttemptErrors++;
                                                overallSyncProgress += progress;
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                  [HUD setProgress:overallSyncProgress];
                                                });
                                              }
                                          authRequiredBlk:^(float progress) {
                                            syncAttemptErrors++;
                                            overallSyncProgress += progress;
                                            _receivedAuthReqdErrorOnSyncAttempt = YES;
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                              [HUD setProgress:overallSyncProgress];
                                            });
                                          }
                                                  allDone:^{
                                                    if (syncAttemptErrors == 0) {
                                                      // 100% sync success
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                        [HUD hide:YES];
                                                        [PEUIUtils showLoginSuccessAlertWithTitle:@"Login & sync success."
                                                                                 alertDescription:[[NSAttributedString alloc] initWithString:@"\
You have been successfully logged in and\n\
your local edits have been synced.\n\n\
Your remote account is now connected to\n\
this device.  Any fuel purchase data that\n\
you create and save will be synced to your\n\
remote account."]
                                                                                  syncIconMessage:[[NSAttributedString alloc] initWithString:@"\
The following icon will appear in the app\n\
indicating that your are currently logged\n\
into your remote account:"]
                                                                                         topInset:70.0
                                                                                      buttonTitle:@"Okay."
                                                                                     buttonAction:^{
                                                                                       [[NSNotificationCenter defaultCenter] postNotificationName:FPAppLoginNotification
                                                                                                                                           object:nil
                                                                                                                                         userInfo:nil];
                                                                                       [[self navigationController] popViewControllerAnimated:YES];
                                                                                       [APP refreshTabs];
                                                                                     }
                                                                                   relativeToView:self.tabBarController.view];
                                                      });
                                                    } else {
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                        [HUD hide:YES];
                                                        NSString *title = @"Sync problems.";
                                                        NSString *message = @"\
There were some problems syncing all of\n\
your local edits.  You can try syncing them\n\
later.";
                                                        JGActionSheetSection *becameUnauthSection = nil;
                                                        if (_receivedAuthReqdErrorOnSyncAttempt) {
                                                          NSString *becameUnauthMessage = @"\
This is awkward.  While syncing your local\n\
edits, the server is asking for you to\n\
authenticate again.  Sorry about that.\n\
To authenticate, tap the Re-authenticate\n\
button.";
                                                          NSDictionary *unauthMessageAttrs = @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0] };
                                                          NSMutableAttributedString *attrBecameUnauthMessage = [[NSMutableAttributedString alloc] initWithString:becameUnauthMessage];
                                                          NSRange unauthMsgAttrsRange = NSMakeRange(146, 15); // 'Re-authenticate'
                                                          [attrBecameUnauthMessage setAttributes:unauthMessageAttrs range:unauthMsgAttrsRange];
                                                          becameUnauthSection = [PEUIUtils warningAlertSectionWithMsgs:nil
                                                                                                                 title:@"Authentication Failure."
                                                                                                      alertDescription:attrBecameUnauthMessage
                                                                                                        relativeToView:self.tabBarController.view];
                                                        }
                                                        JGActionSheetSection *contentSection = [PEUIUtils warningAlertSectionWithMsgs:nil
                                                                                                                                title:title
                                                                                                                     alertDescription:[[NSAttributedString alloc] initWithString:message]
                                                                                                                       relativeToView:self.tabBarController.view];
                                                        JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                                                                              message:nil
                                                                                                                         buttonTitles:@[@"Okay."]
                                                                                                                          buttonStyle:JGActionSheetButtonStyleDefault];
                                                        JGActionSheet *alertSheet;
                                                        if (becameUnauthSection) {
                                                          alertSheet = [JGActionSheet actionSheetWithSections:@[contentSection, becameUnauthSection, buttonsSection]];
                                                        } else {
                                                          alertSheet = [JGActionSheet actionSheetWithSections:@[contentSection, buttonsSection]];
                                                        }
                                                        [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
                                                          [sheet dismissAnimated:YES];
                                                          [[self navigationController] popViewControllerAnimated:YES];
                                                        }];
                                                        [alertSheet showInView:self.tabBarController.view animated:YES];
                                                        [APP refreshTabs];
                                                      });
                                                    }
                                                  }
                                                    error:[FPUtils localDatabaseErrorHudHandlerMaker](HUD, self.tabBarController.view)];
        };
      } else {
        successBlk = nonLocalSyncSuccessBlk;
      }
      HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      HUD.delegate = self;
      HUD.labelText = @"Logging in...";
      [_coordDao loginWithUsernameOrEmail:[_siUsernameOrEmailTf text]
                                 password:[_siPasswordTf text]
             andLinkRemoteUserToLocalUser:_localUser
            preserveExistingLocalEntities:syncLocalEntities
                          remoteStoreBusy:[FPUtils serverBusyHandlerMakerForUI](HUD, self.tabBarController.view)
                        completionHandler:^(FPUser *user, NSError *err) {
                          [FPUtils loginHandlerWithErrMsgsMaker:errMsgsMaker](HUD, successBlk, self.tabBarController.view)(err);
                          NSDate *mostRecentUpdatedAt =
                            [[_coordDao localDao] mostRecentMasterUpdateForUser:user
                                                                          error:[FPUtils localDatabaseErrorHudHandlerMaker](HUD, self.tabBarController.view)];
                          DDLogDebug(@"in FPAccountLoginController/handleSignIn, login success, mostRecentUpdatedAt: [%@](%@)", mostRecentUpdatedAt, [PEUtils millisecondsFromDate:mostRecentUpdatedAt]);
                          if (mostRecentUpdatedAt) {
                            [APP setChangelogUpdatedAt:mostRecentUpdatedAt];
                          }
                        }
                    localSaveErrorHandler:[FPUtils localDatabaseErrorHudHandlerMaker](HUD, self.tabBarController.view)];
    };
    if (_preserveExistingLocalEntities == nil) { // first time asked
      if ([_coordDao doesUserHaveAnyUnsyncedEntities:_localUser]) {        
        NSString *msg = @"\
It seems you've edited some records locally.\n\
Would you like them to be synced to your\n\
remote account upon logging in, or\n\
would you like them to be deleted?";
        JGActionSheetSection *contentSection = [PEUIUtils questionAlertSectionWithTitle:@"Locally created records."
                                                                       alertDescription:[[NSAttributedString alloc] initWithString:msg]
                                                                         relativeToView:self.tabBarController.view];
        JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                              message:nil
                                                                         buttonTitles:@[@"Sync them to my remote account.",
                                                                                        @"Nah.  Just delete them."]
                                                                          buttonStyle:JGActionSheetButtonStyleDefault];
        [buttonsSection setButtonStyle:JGActionSheetButtonStyleRed forButtonAtIndex:1];
        JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:@[contentSection, buttonsSection]];
        [alertSheet setInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
        [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
          switch ([indexPath row]) {
            case 0:  // sync them
              _preserveExistingLocalEntities = [NSNumber numberWithBool:YES];
              doLogin(YES);
              break;
            case 1:  // delete them
              _preserveExistingLocalEntities = [NSNumber numberWithBool:NO];
              doLogin(NO);
              break;
          }
          [sheet dismissAnimated:YES];
        }];
        [alertSheet showInView:self.tabBarController.view animated:YES];              
      } else {
        _preserveExistingLocalEntities = [NSNumber numberWithBool:NO];
        doLogin(NO);
      }
    } else {
      doLogin([_preserveExistingLocalEntities boolValue]);
    }
  } else {
    NSArray *errMsgs = [FPUtils computeSaveUsrErrMsgs:_formStateMaskForSignIn];
    [PEUIUtils showWarningAlertWithMsgs:errMsgs
                                  title:@"Oops"
                       alertDescription:[[NSAttributedString alloc] initWithString:@"There are some validation errors:"]
                               topInset:70.0
                            buttonTitle:@"Okay."
                           buttonAction:nil
                         relativeToView:self.tabBarController.view];
  }
}

@end
