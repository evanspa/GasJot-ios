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

#import <BlocksKit/UIControl+BlocksKit.h>
#import <ReactiveCocoa/UITextField+RACSignalSupport.h>
#import <ReactiveCocoa/RACSubscriptingAssignmentTrampoline.h>
#import <ReactiveCocoa/RACSignal+Operations.h>
#import <ReactiveCocoa/RACDisposable.h>
#import <PEObjc-Commons/PEUIUtils.h>
#import <PEObjc-Commons/PEUtils.h>
#import <PEFuelPurchase-Model/FPErrorDomainsAndCodes.h>
#import "FPAccountLoginController.h"
#import "FPUtils.h"
#import "FPAppNotificationNames.h"
#import "FPNames.h"
#import "FPUIUtils.h"
#import <FlatUIKit/UIColor+FlatUI.h>
#import "FPPanelToolkit.h"

#ifdef FP_DEV
  #import <PEDev-Console/UIViewController+PEDevConsole.h>
#endif

typedef NS_ENUM (NSInteger, FPLoginTag) {
  FPLoginTagEmail = 1,
  FPloginTagPassword
};

@interface FPAccountLoginController ()
@property (nonatomic) NSUInteger formStateMaskForSignIn;
@end

@implementation FPAccountLoginController {
  FPCoordinatorDao *_coordDao;
  UITextField *_emailTf;
  UITextField *_passwordTf;
  UIButton *_signInBtn;
  CGFloat animatedDistance;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  FPUser *_localUser;
  NSNumber *_preserveExistingLocalEntities;
  BOOL _receivedAuthReqdErrorOnSyncAttempt;
  RACDisposable *_disposable;
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
  UINavigationItem *navItem = [self navigationItem];
  [navItem setTitle:@"Account Log In"];
  [navItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                              target:self
                                                                              action:@selector(handleCancel)]];
  [navItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Log In"
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(handleSignIn)]];
  _preserveExistingLocalEntities = nil;
  [_emailTf becomeFirstResponder];
}

#pragma mark - GUI helpers

- (UIView *)parentViewForAlerts {
  if (self.tabBarController) {
    return self.tabBarController.view;
  }
  return self.view;
}

#pragma mark - Make Content 

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:self.view fixedHeight:0.0];
  CGFloat leftPadding = 8.0;
  UILabel *signInMsgLabel = [PEUIUtils labelWithKey:@"From here you can log into your remote \
Gas Jot account, connecting this device to it.  Your Gas Jot data will be downloaded to this device."
                                               font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                    backgroundColor:[UIColor clearColor]
                                          textColor:[UIColor darkGrayColor]
                                verticalTextPadding:3.0
                                         fitToWidth:(contentPanel.frame.size.width - leftPadding - 10.0)];
  UIView *signInMsgPanel = [PEUIUtils leftPadView:signInMsgLabel padding:leftPadding];
  TextfieldMaker tfMaker = [_uitoolkit textfieldMakerForWidthOf:1.0 relativeTo:contentPanel];
  _emailTf = tfMaker(@"unauth.start.signin.emailtf.pht");
  [_emailTf setTag:FPLoginTagEmail];
  _passwordTf = tfMaker(@"unauth.start.signin.pwdtf.pht");
  [_passwordTf setSecureTextEntry:YES];
  [_passwordTf setTag:FPloginTagPassword];
  if (existingContentPanel) {
    [_emailTf setText:[(UITextField *)[existingContentPanel viewWithTag:FPLoginTagEmail] text]];
    [_passwordTf setText:[(UITextField *)[existingContentPanel viewWithTag:FPloginTagPassword] text]];
  }
  UILabel *instructionLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:@"Enter your credentials and tap %@."
                                                                                         textToAccent:@"Log In"
                                                                                       accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]]
                                                           font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                                backgroundColor:[UIColor clearColor]
                                                      textColor:[UIColor darkGrayColor]
                                            verticalTextPadding:3.0
                                                     fitToWidth:(contentPanel.frame.size.width - leftPadding - 10.0)];
  [PEUIUtils setFrameWidthOfView:instructionLabel ofWidth:1.05 relativeTo:instructionLabel];
  UIView *instructionPanel = [PEUIUtils leftPadView:instructionLabel padding:leftPadding];
  
  // place views
  [PEUIUtils placeView:signInMsgPanel
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:FPContentPanelTopPadding
              hpadding:0.0];
  CGFloat totalHeight = signInMsgPanel.frame.size.height + FPContentPanelTopPadding;
  [PEUIUtils placeView:_emailTf
                 below:signInMsgPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:7.0
              hpadding:0.0];
  totalHeight += _emailTf.frame.size.height + 7.0;
  [PEUIUtils placeView:_passwordTf
                 below:_emailTf
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:5.0
              hpadding:0.0];
  totalHeight += _passwordTf.frame.size.height + 5.0;
  [PEUIUtils placeView:instructionPanel
                 below:_passwordTf
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  totalHeight += instructionPanel.frame.size.height + 4.0;
  UIView *forgotPwdBtn = [FPPanelToolkit forgotPasswordButtonForUser:nil coordinatorDao:_coordDao uitoolkit:_uitoolkit controller:self];
  [PEUIUtils placeView:forgotPwdBtn
                 below:instructionPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:20.0
              hpadding:leftPadding];
  totalHeight += forgotPwdBtn.frame.size.height + 20.0;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  
  [_disposable dispose];
  RACSignal *signal = [RACSignal combineLatest:@[_emailTf.rac_textSignal,
                                                 _passwordTf.rac_textSignal]
                                        reduce:^(NSString *email,
                                                 NSString *password) {
                                          NSString *trimmedEmail = [email stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                          NSUInteger signInErrMask = 0;
                                          if ([trimmedEmail length] == 0) {
                                            signInErrMask = FPSignInEmailNotProvided | FPSignInAnyIssues;
                                          } else if (![PEUtils validateEmailWithString:trimmedEmail]) {
                                            signInErrMask = signInErrMask | FPSignInInvalidEmail | FPSignInAnyIssues;
                                          }
                                          if ([password length] == 0) {
                                            signInErrMask = signInErrMask | FPSignInPasswordNotProvided | FPSignInAnyIssues;
                                          }
                                          return @(signInErrMask);
                                        }];
  _disposable = [signal setKeyPath:@"formStateMaskForSignIn" onObject:self nilValue:nil];
  return @[contentPanel, @(YES), @(NO)];
}

- (FPEnableUserInteractionBlk)makeUserEnabledBlock {
  return ^(BOOL enable) {
    [APP enableJotButton:enable];
    [[[self navigationItem] leftBarButtonItem] setEnabled:enable];
    [[[self navigationItem] rightBarButtonItem] setEnabled:enable];
    [[[self tabBarController] tabBar] setUserInteractionEnabled:enable];
  };
}

#pragma mark - Login event handling

- (void)handleCancel {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleSignIn {
  FPEnableUserInteractionBlk enableUserInteraction = [self makeUserEnabledBlock];
  [[self view] endEditing:YES];
  void (^enableLocationServices)(void(^)(void)) = ^(void(^postAction)(void)) {
    if (![APP locationServicesAuthorized] && ![APP locationServicesDenied]) {
      [PEUIUtils showConfirmAlertWithTitle:@"Enable location services?"
                                titleImage:[PEUIUtils bundleImageWithName:@"question"]
                          alertDescription:[[NSAttributedString alloc] initWithString:@"\
By enabling location services, selecting a gas station becomes easier when logging \
gas purchases because the nearest gas station can be pre-selected.\n\n\
If you would like to enable location services, tap 'Allow' in the next pop-up."]
                                  topInset:[PEUIUtils topInsetForAlertsWithController:self]
                           okayButtonTitle:@"Okay."
                          okayButtonAction:^{
                            [[APP locationManager] requestWhenInUseAuthorization];
                            [APP setHasBeenAskedToEnableLocationServices:YES];
                            postAction();
                          }
                           okayButtonStyle:JGActionSheetButtonStyleBlue
                         cancelButtonTitle:@"No.  Not at this time."
                        cancelButtonAction:^{ postAction(); }
                          cancelButtonSyle:JGActionSheetButtonStyleDefault
                            relativeToView:[self parentViewForAlerts]];
    } else {
      postAction();
    }
  };
  if (!([self formStateMaskForSignIn] & FPSignInAnyIssues)) {
    __block MBProgressHUD *HUD;
    void (^nonLocalSyncSuccessBlk)(void) = ^{
      [HUD hide:YES];
      [PEUIUtils showSuccessAlertWithTitle:@"Login success."
                          alertDescription:[[NSAttributedString alloc] initWithString:@"\
You have been successfully logged in.\n\nYour remote account is now connected to this device.  \
Any Gas Jot data that you create and save will be synced to your remote account."]
                                   topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                buttonTitle:@"Okay."
                               buttonAction:^{
                                 enableLocationServices(^{
                                   enableUserInteraction(YES);
                                   [[NSNotificationCenter defaultCenter] postNotificationName:FPAppLoginNotification
                                                                                       object:nil
                                                                                     userInfo:nil];
                                   //[[self navigationController] popViewControllerAnimated:YES];
                                   [self dismissViewControllerAnimated:YES completion:nil];
                                 });
                               }
                            relativeToView:[self parentViewForAlerts]];
    };
    ErrMsgsMaker errMsgsMaker = ^ NSArray * (NSInteger errCode) {
      return [FPUtils computeSignInErrMsgs:errCode];
    };
    void (^doLogin)(BOOL) = ^ (BOOL syncLocalEntities) {
      _receivedAuthReqdErrorOnSyncAttempt = NO;
      void (^successBlk)(void) = nil;
      if (syncLocalEntities) {
        successBlk = ^{
          HUD.labelText = @"You're now logged in.";
          HUD.detailsLabelText = @"Proceeding to sync records...";
          HUD.mode = MBProgressHUDModeDeterminate;
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
                                                        [PEUIUtils showSuccessAlertWithTitle:@"Login & sync success."
                                                                            alertDescription:[[NSAttributedString alloc] initWithString:@"\
You have been successfully logged in and \
your local edits have been synced.\n\n\
Your remote account is now connected to \
this device.  Any gas jot data that \
you create and save will be synced to your \
remote account."]
                                                                                    topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                                                 buttonTitle:@"Okay."
                                                                                buttonAction:^{
                                                                                  enableLocationServices(^{
                                                                                    enableUserInteraction(YES);
                                                                                    [[NSNotificationCenter defaultCenter] postNotificationName:FPAppLoginNotification
                                                                                                                                        object:nil
                                                                                                                                      userInfo:nil];
                                                                                    //[[self navigationController] popViewControllerAnimated:YES];
                                                                                    [self dismissViewControllerAnimated:YES completion:nil];
                                                                                    [APP refreshTabs];
                                                                                  });
                                                                                }
                                                                              relativeToView:[self parentViewForAlerts]];
                                                      });
                                                    } else {
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                        [HUD hide:YES];
                                                        NSString *title = @"Sync problems.";
                                                        NSString *message = @"There were some problems syncing all of your local edits.  You can try syncing them later.";
                                                        JGActionSheetSection *becameUnauthSection = nil;
                                                        if (_receivedAuthReqdErrorOnSyncAttempt) {
                                                          NSAttributedString *attrBecameUnauthMessage =
                                                          [PEUIUtils attributedTextWithTemplate:@"This is awkward.  While syncing your local \
edits, the Gas Jot server is asking for you to authenticate again.  Sorry about that. To authenticate, tap the %@ button."
                                                                                   textToAccent:@"Re-authenticate"
                                                                                 accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]];
                                                          becameUnauthSection = [PEUIUtils warningAlertSectionWithMsgs:nil
                                                                                                                 title:@"Authentication Failure."
                                                                                                      alertDescription:attrBecameUnauthMessage
                                                                                                        relativeToView:[self parentViewForAlerts]];
                                                        }
                                                        JGActionSheetSection *contentSection = [PEUIUtils warningAlertSectionWithMsgs:nil
                                                                                                                                title:title
                                                                                                                     alertDescription:[[NSAttributedString alloc] initWithString:message]
                                                                                                                       relativeToView:[self parentViewForAlerts]];
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
                                                          enableLocationServices(^{
                                                            enableUserInteraction(YES);
                                                            [[NSNotificationCenter defaultCenter] postNotificationName:FPAppLoginNotification
                                                                                                                object:nil
                                                                                                              userInfo:nil];
                                                            //[[self navigationController] popViewControllerAnimated:YES];
                                                            [self dismissViewControllerAnimated:YES completion:nil];
                                                          });
                                                        }];
                                                        [[[self navigationItem] rightBarButtonItem] setEnabled:YES];
                                                        [alertSheet showInView:[self parentViewForAlerts] animated:YES];
                                                        [APP refreshTabs];
                                                      });
                                                    }
                                                  }
                                                    error:^(NSError *err, int code, NSString *desc) {
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                        [FPUtils localDatabaseErrorHudHandlerMaker](HUD, self, [self parentViewForAlerts])(err, code, desc);
                                                      });
                                                    }];
        };
      } else {
        successBlk = nonLocalSyncSuccessBlk;
      }
      HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      HUD.delegate = self;
      HUD.labelText = @"Logging in...";
      enableUserInteraction(NO);
      [_coordDao loginWithEmail:[[_emailTf text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
                       password:[_passwordTf text]
   andLinkRemoteUserToLocalUser:_localUser
  preserveExistingLocalEntities:syncLocalEntities
                remoteStoreBusy:^(NSDate *retryAfter) {
                  dispatch_async(dispatch_get_main_queue(), ^{
                    [HUD hide:YES];
                    [PEUIUtils showWaitAlertWithMsgs:nil
                                               title:@"Server Busy."
                                    alertDescription:[[NSAttributedString alloc] initWithString:@"We apologize, but the Gas Jot server is currently \
busy.  Please try logging in a little later."]
                                            topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                         buttonTitle:@"Okay."
                                        buttonAction:^{
                                          enableUserInteraction(YES);
                                        }
                                      relativeToView:[self parentViewForAlerts]];
                  });
                }
              completionHandler:^(FPUser *user, NSError *err) {
                dispatch_async(dispatch_get_main_queue(), ^{
                  [FPUtils loginHandlerWithErrMsgsMaker:errMsgsMaker](HUD,
                                                                      successBlk,
                                                                      ^{ enableUserInteraction(YES); },
                                                                      self,
                                                                      [self parentViewForAlerts])(err);
                  if (user) {
                    NSDate *mostRecentUpdatedAt =
                    [[_coordDao localDao] mostRecentMasterUpdateForUser:user
                                                                  error:[FPUtils localDatabaseErrorHudHandlerMaker](HUD, self, [self parentViewForAlerts])];
                    DDLogDebug(@"in FPAccountLoginController/handleSignIn, login success, mostRecentUpdatedAt: [%@](%@)", mostRecentUpdatedAt, [PEUtils millisecondsFromDate:mostRecentUpdatedAt]);
                    if (mostRecentUpdatedAt) {
                      [APP setChangelogUpdatedAt:mostRecentUpdatedAt];
                    }
                  }
                });
              }
          localSaveErrorHandler:[FPUtils localDatabaseErrorHudHandlerMaker](HUD, self, [self parentViewForAlerts])];
    };
    if (_preserveExistingLocalEntities == nil) { // first time asked
      if ([_coordDao doesUserHaveAnyUnsyncedEntities:_localUser]) {
        NSString *msg = @"\
It seems you've edited some records locally. \
Would you like them to be synced to your \
remote account upon logging in, or \
would you like them to be deleted?";
        JGActionSheetSection *contentSection = [PEUIUtils questionAlertSectionWithTitle:@"Locally created records."
                                                                       alertDescription:[[NSAttributedString alloc] initWithString:msg]
                                                                         relativeToView:[self parentViewForAlerts]];
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
        [alertSheet showInView:[self parentViewForAlerts] animated:YES];              
      } else {
        _preserveExistingLocalEntities = [NSNumber numberWithBool:NO];
        doLogin(NO);
      }
    } else {
      doLogin([_preserveExistingLocalEntities boolValue]);
    }
  } else {
    NSArray *errMsgs = [FPUtils computeSignInErrMsgs:_formStateMaskForSignIn];
    [PEUIUtils showWarningAlertWithMsgs:errMsgs
                                  title:@"Oops"
                       alertDescription:[[NSAttributedString alloc] initWithString:@"There are some validation errors:"]
                               topInset:[PEUIUtils topInsetForAlertsWithController:self]
                            buttonTitle:@"Okay."
                           buttonAction:nil
                         relativeToView:[self parentViewForAlerts]];
  }
}

@end
