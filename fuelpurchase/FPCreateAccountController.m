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
#import "FPCreateAccountController.h"
#import "FPUtils.h"
#import "FPAppNotificationNames.h"
#import "FPNames.h"
#import <PEObjc-Commons/JGActionSheet.h>
#import "FPUIUtils.h"

#ifdef FP_DEV
  #import <PEDev-Console/UIViewController+PEDevConsole.h>
#endif

@interface FPCreateAccountController ()
@property (nonatomic) NSUInteger formStateMaskForAcctCreation;
@end

@implementation FPCreateAccountController {
  FPCoordinatorDao *_coordDao;
  UITextField *_caFullNameTf;
  UITextField *_caEmailTf;
  UITextField *_caPasswordTf;
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
              vpadding:75.0
              hpadding:0.0];
  UINavigationItem *navItem = [self navigationItem];
  [navItem setTitle:@"Create Account"];
  [navItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                              target:self
                                                                              action:@selector(handleCancel)]];
  [navItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                               target:self
                                                                               action:@selector(handleAccountCreation)]];
}

- (UIView *)parentViewForAlerts {
  if (self.tabBarController) {
    return self.tabBarController.view;
  }
  return self.view;
}

#pragma mark - GUI construction (making panels)

- (UIView *)panelForAccountCreation {
  UIView *createAcctPnl = [PEUIUtils panelWithWidthOf:1.0
                                          andHeightOf:1.0
                                       relativeToView:[self view]];
  [PEUIUtils setFrameHeightOfView:createAcctPnl ofHeight:0.5 relativeTo:[self view]];
  CGFloat leftPadding = 8.0;
  UILabel *createAccountMsgLabel = [PEUIUtils labelWithKey:@"From here you can create a remote Gas Jot account. This will \
enable your data records to be synced to Gas Jot's central server so you can access them from your other devices."
                                               font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                    backgroundColor:[UIColor clearColor]
                                          textColor:[UIColor darkGrayColor]
                                verticalTextPadding:3.0
                                         fitToWidth:(createAcctPnl.frame.size.width - leftPadding - 10.0)];
  UIView *createAccountMsgPanel = [PEUIUtils leftPadView:createAccountMsgLabel padding:leftPadding];
  
  TextfieldMaker tfMaker =
    [_uitoolkit textfieldMakerForWidthOf:1.0 relativeTo:createAcctPnl];
  _caFullNameTf = tfMaker(@"unauth.start.ca.fullnametf.pht");
  _caEmailTf = tfMaker(@"unauth.start.ca.emailtf.pht");
  _caPasswordTf = tfMaker(@"unauth.start.ca.pwdtf.pht");
  [_caPasswordTf setSecureTextEntry:YES];
  
  // place views
  [PEUIUtils placeView:createAccountMsgPanel
               atTopOf:createAcctPnl
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:0.0
              hpadding:0.0];
  [PEUIUtils placeView:_caFullNameTf
                 below:createAccountMsgPanel
                  onto:createAcctPnl
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:7.0
              hpadding:0];
  [PEUIUtils placeView:_caEmailTf
                 below:_caFullNameTf
                  onto:createAcctPnl
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:5
              hpadding:0];
  [PEUIUtils placeView:_caPasswordTf
                 below:_caEmailTf
                  onto:createAcctPnl
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:5
              hpadding:0];
  UILabel *instructionLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:@"Fill out the form and tap %@."
                                                                                         textToAccent:@"Done"
                                                                                       accentTextFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]]
                                                           font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                                backgroundColor:[UIColor clearColor]
                                                      textColor:[UIColor darkGrayColor]
                                            verticalTextPadding:3.0];
  [PEUIUtils setFrameWidthOfView:instructionLabel ofWidth:1.05 relativeTo:instructionLabel];
  UIView *instructionPanel = [PEUIUtils leftPadView:instructionLabel padding:leftPadding];
  [PEUIUtils placeView:instructionPanel
                 below:_caPasswordTf
                  onto:createAcctPnl
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  
  RAC(self, formStateMaskForAcctCreation) =
    [RACSignal combineLatest:@[_caFullNameTf.rac_textSignal,
                               _caEmailTf.rac_textSignal,
                               _caPasswordTf.rac_textSignal]
                      reduce:^(NSString *fullName,
                               NSString *email,
                               NSString *password) {
        NSUInteger createUsrErrMask = 0;
        if ([email length] == 0) {
          createUsrErrMask = createUsrErrMask | FPSaveUsrEmailNotProvided
              | FPSaveUsrAnyIssues;
        } else if (![PEUtils validateEmailWithString:email]) {
          createUsrErrMask = createUsrErrMask | FPSaveUsrInvalidEmail | FPSaveUsrAnyIssues;
        }
        if ([password length] == 0) {
          createUsrErrMask = createUsrErrMask | FPSaveUsrPasswordNotProvided |
              FPSaveUsrAnyIssues;
        }
        return @(createUsrErrMask);
      }];
  return createAcctPnl;
}

- (FPEnableUserInteractionBlk)makeUserEnabledBlock {
  return ^(BOOL enable) {
    [APP enableJotButton:enable];
    [[[self navigationItem] leftBarButtonItem] setEnabled:enable];
    [[[self navigationItem] rightBarButtonItem] setEnabled:enable];
    [[[self tabBarController] tabBar] setUserInteractionEnabled:enable];
  };
}

#pragma mark - Event handling

- (void)handleCancel {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleAccountCreation {
  NSLog(@"inside handleAccountCreation");
  FPEnableUserInteractionBlk enableUserInteraction = [self makeUserEnabledBlock];
  [[self view] endEditing:YES];
  if (!([self formStateMaskForAcctCreation] & FPSaveUsrAnyIssues)) {
    [_localUser setName:[_caFullNameTf text]];
    [_localUser setEmail:[_caEmailTf text]];
    [_localUser setPassword:[_caPasswordTf text]];
    __block MBProgressHUD *HUD;    
    void (^nonLocalSyncSuccessBlk)(FPUser *) = ^(FPUser *user){
      dispatch_async(dispatch_get_main_queue(), ^{
        [HUD hide:YES];
        [PEUIUtils showSuccessAlertWithMsgs:nil
                                      title:@"Success."
                           alertDescription:[[NSAttributedString alloc] initWithString:@"\
Your account has been created successfully.\n\nFrom this point on, any new records that you create \
will be saved on your device AND the Gas Jot central server.\n\nAn account verification link has been \
emailed to you."]
                                   topInset:70.0
                                buttonTitle:@"Okay."
                               buttonAction:^{
                                 enableUserInteraction(YES);
                                 [[NSNotificationCenter defaultCenter] postNotificationName:FPAppAccountCreationNotification
                                                                                     object:nil
                                                                                   userInfo:nil];
                                 //[[self navigationController] popViewControllerAnimated:YES];
                                 [self dismissViewControllerAnimated:YES completion:nil];
                               }
                             relativeToView:[self parentViewForAlerts]];
      });
    };
    ErrMsgsMaker errMsgsMaker = ^ NSArray * (NSInteger errCode) {
      return [FPUtils computeSaveUsrErrMsgs:errCode];
    };
    void (^doAccountCreation)(BOOL) = ^ (BOOL syncLocalEntities) {
      _receivedAuthReqdErrorOnSyncAttempt = NO; // reset
      void (^successBlk)(FPUser *) = nil;
      if (syncLocalEntities) {
        successBlk = ^(FPUser *remoteUser) {
          HUD.labelText = @"Account creation success!";
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
                                                        [PEUIUtils showSuccessAlertWithTitle:@"Account creation & sync\nsuccess."
                                                                            alertDescription:[[NSAttributedString alloc] initWithString:@"\
Your remote account has been created and \
your local edits have been synced.\n\n\
Your account is now connected to this \
device.  Any Gas Jot data that \
you create and save will be synced to your \
remote account."]
                                                                                    topInset:70.0
                                                                                 buttonTitle:@"Okay."
                                                                                buttonAction:^{
                                                                                  enableUserInteraction(YES);
                                                                                  [[NSNotificationCenter defaultCenter] postNotificationName:FPAppAccountCreationNotification
                                                                                                                                      object:nil
                                                                                                                                    userInfo:nil];
                                                                                  //[[self navigationController] popViewControllerAnimated:YES];
                                                                                  [self dismissViewControllerAnimated:YES completion:nil];
                                                                                  [APP refreshTabs];
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
                                                          [PEUIUtils attributedTextWithTemplate:@"This is awkward.  While syncing your local edits, the Gas Jot server \
is asking for you to authenticate again.  Sorry about that. To authenticate, tap the %@ button."
                                                                                   textToAccent:@"Re-authenticate"
                                                                                 accentTextFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]];
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
                                                          enableUserInteraction(YES);
                                                          [sheet dismissAnimated:YES];
                                                          //[[self navigationController] popViewControllerAnimated:YES];
                                                          [self dismissViewControllerAnimated:YES completion:nil];
                                                        }];
                                                        [alertSheet showInView:[self parentViewForAlerts] animated:YES];
                                                        [APP refreshTabs];
                                                      });
                                                    }
                                                  }
                                                    error:^(NSError *err, int code, NSString *desc) {
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                        [FPUtils localDatabaseErrorHudHandlerMaker](HUD, [self parentViewForAlerts])(err, code, desc);
                                                      });
                                                    }];
        };
      } else {
        successBlk = nonLocalSyncSuccessBlk;
      }
      HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      enableUserInteraction(NO);
      HUD.delegate = self;
      HUD.labelText = @"Creating account...";
      [_coordDao establishRemoteAccountForLocalUser:_localUser
                      preserveExistingLocalEntities:syncLocalEntities
                                    remoteStoreBusy:[FPUtils serverBusyHandlerMakerForUI](HUD, [self parentViewForAlerts])
                                  completionHandler:^(FPUser *user, NSError *err) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                    [FPUtils synchUnitOfWorkHandlerMakerWithErrMsgsMaker:errMsgsMaker](HUD,
                                                                                                       successBlk,
                                                                                                       ^{ enableUserInteraction(YES); },
                                                                                                       [self parentViewForAlerts])(user, err);
                                    DDLogDebug(@"in FPCreateAccountController/handleAccountCreation, calling [APP setChangelogUpdatedAt:(%@)", [PEUtils millisecondsFromDate:user.updatedAt]);
                                    [APP setChangelogUpdatedAt:[user updatedAt]];
                                    });
                                  }
                                                   
                              localSaveErrorHandler:[FPUtils localDatabaseErrorHudHandlerMaker](HUD, [self parentViewForAlerts])];
    };
    if (_preserveExistingLocalEntities == nil) { // first time asked
      if ([_coordDao doesUserHaveAnyUnsyncedEntities:_localUser]) {
        NSString *msg = @"It seems you've edited some records locally. Would you like them to be synced to your \
remote account upon account creation, or would you like them to be deleted?";
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
              doAccountCreation(YES);
              break;
            case 1:  // delete them
              _preserveExistingLocalEntities = [NSNumber numberWithBool:NO];
              doAccountCreation(NO);
              break;
          }
          [sheet dismissAnimated:YES];
        }];
        [alertSheet showInView:[self parentViewForAlerts] animated:YES];
      } else {
        _preserveExistingLocalEntities = [NSNumber numberWithBool:NO];
        doAccountCreation(NO);
      }
    } else {
      doAccountCreation([_preserveExistingLocalEntities boolValue]);
    }
  } else {
    NSArray *errMsgs = [FPUtils computeSaveUsrErrMsgs:_formStateMaskForAcctCreation];
    [PEUIUtils showWarningAlertWithMsgs:errMsgs
                                  title:@"Oops"
                       alertDescription:[[NSAttributedString alloc] initWithString:@"There are some validation errors:"]
                               topInset:70.0
                            buttonTitle:@"Okay."
                           buttonAction:nil
                         relativeToView:[self parentViewForAlerts]];
  }
}

@end
