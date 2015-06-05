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
#import <PEFuelPurchase-Common/FPTransactionCodes.h>
#import <PEFuelPurchase-Model/FPErrorDomainsAndCodes.h>
#import "FPUnauthStartController.h"
#import "FPAuthenticationAssertionSerializer.h"
#import "FPUserSerializer.h"
#import "FPAuthenticationAssertion.h"
#import "FPQuickActionMenuController.h"
#import "FPUtils.h"
#import "NSObject+appdelegate.h"
#import "FPNames.h"

#ifdef FP_DEV
  #import <PEDev-Console/UIViewController+PEDevConsole.h>
#endif

@interface FPUnauthStartController ()
@property (nonatomic) NSUInteger formStateMaskForAcctCreation;
@property (nonatomic) NSUInteger formStateMaskForSignIn;
@end

@implementation FPUnauthStartController {
  NSString *_notificationMsgOrKey;
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
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(FPCoordinatorDao *)coordDao
              tempNotification:(NSString *)notificationMsgOrKey
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(FPScreenToolkit *)screenToolkit {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _coordDao = coordDao;
    _notificationMsgOrKey = notificationMsgOrKey;
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
  UIView *mainPnl =
    [PEUIUtils panelWithColumnOfViews:@[[self panelForSignIn],
                                        [self panelForAccountCreation]]
          verticalPaddingBetweenViews:20
                       viewsAlignment:PEUIHorizontalAlignmentTypeCenter];
  [PEUIUtils placeView:mainPnl
            inMiddleOf:[self view]
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              hpadding:0];
  [PEUIUtils displayTempNotification:_notificationMsgOrKey
                       forController:self
                           uitoolkit:_uitoolkit];
}

#pragma mark - GUI construction (making panels)

- (UIView *)panelForSignIn {
  PanelMaker pnlMaker = [_uitoolkit contentPanelMakerRelativeTo:[self view]];
  ButtonMaker btnMaker = [_uitoolkit primaryButtonMaker];
  LabelMaker hdr1Maker = [_uitoolkit header1Maker];
  UIView *signInPnl = pnlMaker(.95);
  TextfieldMaker tfMaker =
    [_uitoolkit textfieldMakerForWidthOf:0.8 relativeTo:signInPnl];
  UILabel *hdr = hdr1Maker(@"unauth.start.signin.hdr");
  UIView *hdrPnl = [PEUIUtils panelWithViews:@[hdr]
                                     ofWidth:1.0
                        vertAlignmentOfViews:PEUIVerticalAlignmentTypeCenter
                         horAlignmentOfViews:PEUIHorizontalAlignmentTypeCenter
                                  relativeTo:signInPnl
                                    vpadding:0
                                    hpadding:0];
  [PEUIUtils placeView:hdrPnl
               atTopOf:signInPnl
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:[_uitoolkit topBottomPaddingForContentPanels]
              hpadding:0];
  _siUsernameOrEmailTf = tfMaker(@"unauth.start.signin.emailusernmtf.pht");
  [PEUIUtils placeView:_siUsernameOrEmailTf
                 below:hdrPnl
                  onto:signInPnl
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:10
              hpadding:10];
  _siPasswordTf = tfMaker(@"unauth.start.signin.pwdtf.pht");
  [_siPasswordTf setSecureTextEntry:YES];
  [PEUIUtils placeView:_siPasswordTf
                 below:_siUsernameOrEmailTf
                  onto:signInPnl
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:5
              hpadding:0];
  _siDoSignInBtn =
    btnMaker(@"unauth.start.signin.btn.txt", self, @selector(handleSignIn));
  [PEUIUtils placeView:_siDoSignInBtn
                 below:_siPasswordTf
                  onto:signInPnl
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:15
              hpadding:0];
  [_uitoolkit adjustHeightToFitSubviewsForContentPanel:signInPnl];
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

- (UIView *)panelForAccountCreation {
  PanelMaker pnlMaker = [_uitoolkit contentPanelMakerRelativeTo:[self view]];
  ButtonMaker btnMaker = [_uitoolkit primaryButtonMaker];
  LabelMaker hdr1Maker = [_uitoolkit header1Maker];
  LabelMaker hdr2Maker = [_uitoolkit header2Maker];
  UIView *createAcctPnl = pnlMaker(.95);
  TextfieldMaker tfMaker =
    [_uitoolkit textfieldMakerForWidthOf:0.8 relativeTo:createAcctPnl];
  UILabel *signUpHdrLbl1 = hdr1Maker(@"unauth.start.ca.hdr1");
  UILabel *signUpHdrLbl2 = hdr2Maker(@"unauth.start.ca.hdr2");
  PanelMaker accentPnlMakerForHdr2 =
    [_uitoolkit accentPanelMakerRelativeTo:signUpHdrLbl2];
  UIView *signUpAccentPnl = accentPnlMakerForHdr2(1.2);
  [PEUIUtils setFrameHeightOfView:signUpAccentPnl ofHeight:1 relativeTo:signUpHdrLbl1];
  [PEUIUtils placeView:signUpHdrLbl2
            inMiddleOf:signUpAccentPnl
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              hpadding:0];
  UIView *hdrPanel = [PEUIUtils panelWithViews:@[signUpHdrLbl1, signUpAccentPnl]
                                       ofWidth:1.0
                          vertAlignmentOfViews:PEUIVerticalAlignmentTypeCenter
                           horAlignmentOfViews:PEUIHorizontalAlignmentTypeCenter
                                    relativeTo:createAcctPnl
                                      vpadding:0
                                      hpadding:3];
  [PEUIUtils placeView:hdrPanel
               atTopOf:createAcctPnl
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:[_uitoolkit topBottomPaddingForContentPanels]
              hpadding:0];
  _caFullNameTf = tfMaker(@"unauth.start.ca.fullnametf.pht");
  [PEUIUtils placeView:_caFullNameTf
                 below:hdrPanel
                  onto:createAcctPnl
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:10
              hpadding:0];
  _caEmailTf = tfMaker(@"unauth.start.ca.emailtf.pht");
  [PEUIUtils placeView:_caEmailTf
                 below:_caFullNameTf
                  onto:createAcctPnl
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:5
              hpadding:0];
  _caPasswordTf = tfMaker(@"unauth.start.ca.pwdtf.pht");
  [_caPasswordTf setSecureTextEntry:YES];
  [PEUIUtils placeView:_caPasswordTf
                 below:_caEmailTf
                  onto:createAcctPnl
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:5
              hpadding:0];
  _caDoCreateAcctBtn =
    btnMaker(@"unauth.start.ca.btn.txt", self, @selector(handleAccountCreation));
  [PEUIUtils placeView:_caDoCreateAcctBtn
                 below:_caPasswordTf
                  onto:createAcctPnl
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:15
              hpadding:0];
  [_uitoolkit adjustHeightToFitSubviewsForContentPanel:createAcctPnl];
  RAC(self, formStateMaskForAcctCreation) =
    [RACSignal combineLatest:@[_caFullNameTf.rac_textSignal,
                               _caEmailTf.rac_textSignal,
                               _caPasswordTf.rac_textSignal]
                      reduce:^(NSString *fullName,
                               NSString *email,
                               NSString *password) {
        NSUInteger createUsrErrMask = 0;
        if ([fullName length] == 0) {
          createUsrErrMask = FPSaveUsrNameNotProvided | FPSaveUsrAnyIssues;
        }
        if ([email length] == 0) {
          createUsrErrMask = createUsrErrMask | FPSaveUsrIdentifierNotProvided
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

#pragma mark - Helpers

- (NSArray *)computeCreateUsrErrMsgs:(NSUInteger)createUsrErrMask {
  NSMutableArray *errMsgs = [NSMutableArray arrayWithCapacity:1];
  if (createUsrErrMask & FPSaveUsrNameNotProvided) {
    [errMsgs addObject:LS(@"createusr.name-notprovided")];
  }
  if (createUsrErrMask & FPSaveUsrInvalidName) {
    [errMsgs addObject:LS(@"createusr.name-invalid")];
  }
  if (createUsrErrMask & FPSaveUsrInvalidEmail) {
    [errMsgs addObject:LS(@"createusr.email-invalid")];
  }
  if (createUsrErrMask & FPSaveUsrInvalidUsername) {
    [errMsgs addObject:LS(@"createusr.username-invalid")];
  }
  if (createUsrErrMask & FPSaveUsrIdentifierNotProvided) {
    [errMsgs addObject:LS(@"createusr.identifier-notprovided.email")];
  }
  if (createUsrErrMask & FPSaveUsrPasswordNotProvided) {
    [errMsgs addObject:LS(@"createusr.password-notprovided")];
  }
  if (createUsrErrMask & FPSaveUsrEmailAlreadyRegistered) {
    [errMsgs addObject:LS(@"createusr.email-already-registered")];
  }
  return errMsgs;
}

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
    _HUD.labelText = @"Authenticating...";
    void (^successBlock)(FPUser *) = ^(FPUser *user){
      [PEUIUtils displayController:[_screenToolkit newTabBarAuthHomeLandingScreenMakerWithTempNotification:@"Login Successful"](user)
                    fromController:self
                          animated:YES];
    };
    ErrMsgsMaker errMsgsMaker = ^ NSArray * (NSInteger errCode) {
      return [self computeSignInErrMsgs:errCode];
    };
    [_coordDao loginWithUsernameOrEmail:[_siUsernameOrEmailTf text]
                               password:[_siPasswordTf text]
                        remoteStoreBusy:[FPUtils serverBusyHandlerMakerForUI](_HUD)
                      completionHandler:[FPUtils synchUnitOfWorkHandlerMakerWithErrMsgsMaker:errMsgsMaker](_HUD,successBlock)
                  localSaveErrorHandler:[FPUtils localDatabaseErrorHudHandlerMaker](_HUD)];
  } else {
    NSArray *errMsgs = [self computeSignInErrMsgs:_formStateMaskForSignIn];
    [PEUIUtils showAlertWithMsgs:errMsgs title:@"oopsMsg" buttonTitle:@"okayMsg"];
  }
}

- (void)handleAccountCreation {
  [[self view] endEditing:YES];
  if (!([self formStateMaskForAcctCreation] & FPSaveUsrAnyIssues)) {
    _HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _HUD.delegate = self;
    _HUD.labelText = @"Creating Account...";
    FPUser *user = [_coordDao userWithName:[_caFullNameTf text]
                                     email:[_caEmailTf text]
                                  username:nil
                                  password:[_caPasswordTf text]];
    void (^successBlock)(FPUser *) = ^(FPUser *newUser){
      [PEUIUtils displayController:[_screenToolkit newTabBarAuthHomeLandingScreenMakerWithTempNotification:@"Account Creation Successful"](newUser)
                    fromController:self
                          animated:YES];
    };
    ErrMsgsMaker errMsgsMaker = ^ NSArray * (NSInteger errCode) {
      return [self computeCreateUsrErrMsgs:errCode];
    };
    [_coordDao
      immediateRemoteSyncSaveNewUser:user
                     remoteStoreBusy:[FPUtils serverBusyHandlerMakerForUI](_HUD)
                   completionHandler:[FPUtils synchUnitOfWorkHandlerMakerWithErrMsgsMaker:errMsgsMaker](_HUD, successBlock)
               localSaveErrorHandler:[FPUtils localDatabaseErrorHudHandlerMaker](_HUD)];
  } else {
    NSArray *errMsgs =
      [self computeCreateUsrErrMsgs:_formStateMaskForAcctCreation];
    [PEUIUtils showAlertWithMsgs:errMsgs title:@"oopsMsg" buttonTitle:@"okayMsg"];
  }
}

#pragma mark - UIViewController overrides

-(NSUInteger)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait;
}

@end
