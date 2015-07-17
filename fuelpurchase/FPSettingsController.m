//
//  FPSettingsController.m
//  fuelpurchase
//
//  Created by Evans, Paul on 9/15/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPSettingsController.h"
#import <PEObjc-Commons/PEUIUtils.h>
#import <BlocksKit/UIControl+BlocksKit.h>
#import "PELMUIUtils.h"
#import "FPNames.h"
#import "FPUtils.h"
#import <PEFuelPurchase-Model/PELMNotificationUtils.h>
#import <PEObjc-Commons/PEUtils.h>
#import <PEObjc-Commons/UIImage+PEAdditions.h>
#import <PEObjc-Commons/UIView+PERoundify.h>
#import "FPAppNotificationNames.h"
#import "FPCreateAccountController.h"
#import "FPAccountLoginController.h"
#import "FPReauthenticateController.h"

#ifdef FP_DEV
  #import <PEDev-Console/UIViewController+PEDevConsole.h>
#endif

@implementation FPSettingsController {
  FPCoordinatorDao *_coordDao;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  FPUser *_user;
  UIView *_doesHaveAuthTokenPanel;
  UIView *_doesNotHaveAuthTokenPanel;
  UIView *_notLoggedInPanel;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(FPCoordinatorDao *)coordDao
                          user:(FPUser *)user
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(FPScreenToolkit *)screenToolkit {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _user = user;
    _coordDao = coordDao;
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
  [navItem setTitle:@"Settings"];
  [self makeNotLoggedInPanel];
  [self makeDoesHaveAuthTokenPanel];
  [self makeDoesNotHaveAuthTokenPanel];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [_notLoggedInPanel removeFromSuperview];
  [_doesHaveAuthTokenPanel removeFromSuperview];
  [_doesNotHaveAuthTokenPanel removeFromSuperview];
  if ([APP isUserLoggedIn]) {
    if ([APP doesUserHaveValidAuthToken]) {
      [PEUIUtils placeView:_doesHaveAuthTokenPanel
                   atTopOf:[self view]
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:0.0
                  hpadding:0.0];
    } else {
      [PEUIUtils placeView:_doesNotHaveAuthTokenPanel
                   atTopOf:[self view]
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:0.0
                  hpadding:0.0];
    }
  } else {
    [PEUIUtils placeView:_notLoggedInPanel
                 atTopOf:[self view]
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0.0];
  }
}

#pragma mark - Helpers

- (UIView *)logoutPaddedMessage {
  UILabel *logoutMsgLabel = [PEUIUtils labelWithKey:@"\
Logging out will disconnect this device from\n\
your remote account.  This will remove your\n\
fuel purchase data from this device only."
                                               font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                    backgroundColor:[UIColor clearColor]
                                          textColor:[UIColor darkGrayColor]
                                verticalTextPadding:3.0];
  return [PEUIUtils leftPadView:logoutMsgLabel padding:8.0];
}

- (UIView *)messagePanelWithMessage:(NSString *)message iconImage:(UIImage *)iconImage {
  UIImageView *iconImageView = [[UIImageView alloc] initWithImage:iconImage];
  UILabel *messageLabel = [PEUIUtils labelWithKey:message
                                             font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                  backgroundColor:[UIColor clearColor]
                                        textColor:[UIColor darkGrayColor]
                              verticalTextPadding:3.0];
  UIView *messageLabelWithPad = [PEUIUtils leftPadView:messageLabel padding:8.0];
  UIView *messagePanel = [PEUIUtils panelWithWidthOf:1.0
                                      relativeToView:_doesHaveAuthTokenPanel
                                         fixedHeight:messageLabelWithPad.frame.size.height];
  [PEUIUtils placeView:iconImageView
            inMiddleOf:messagePanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              hpadding:10.0];
  [PEUIUtils placeView:messageLabelWithPad
          toTheRightOf:iconImageView
                  onto:messagePanel
         withAlignment:PEUIVerticalAlignmentTypeMiddle
              hpadding:3.0];
  return messagePanel;
}

#pragma mark - Panel Makers

- (void)makeDoesHaveAuthTokenPanel {
  NSString *message = @"\
You are currently logged in.  From here\n\
you can view and edit your account\n\
information and settings.";
  UIView *messagePanel = [self messagePanelWithMessage:message iconImage:[UIImage syncable]];
  ButtonMaker buttonMaker = [_uitoolkit systemButtonMaker];
  _doesHaveAuthTokenPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:[self view]];
  UIButton *accountSettingsBtn = [_uitoolkit systemButtonMaker](@"Account Settings", nil, nil);
  [[accountSettingsBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:accountSettingsBtn ofWidth:1.0 relativeTo:_doesHaveAuthTokenPanel];
  [PEUIUtils addDisclosureIndicatorToButton:accountSettingsBtn];
  [accountSettingsBtn bk_addEventHandler:^(id sender) {
    [PEUIUtils displayController:[_screenToolkit newUserAccountDetailScreenMaker](_user) fromController:self animated:YES];
  } forControlEvents:UIControlEventTouchUpInside];
  UIView *logoutMsgLabelWithPad = [self logoutPaddedMessage];
  UIButton *logoutBtn = buttonMaker(@"Log Out", self, @selector(logout));
  [[logoutBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:logoutBtn ofWidth:1.0 relativeTo:_doesHaveAuthTokenPanel];
  
  // place views onto panel
  [PEUIUtils placeView:messagePanel
               atTopOf:_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:100
              hpadding:0.0];
  [PEUIUtils placeView:accountSettingsBtn
                 below:messagePanel
                  onto:_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:7.0
              hpadding:0.0];
  [PEUIUtils placeView:logoutMsgLabelWithPad
            atBottomOf:_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:175.0
              hpadding:0.0];
  [PEUIUtils placeView:logoutBtn
                 below:logoutMsgLabelWithPad
                  onto:_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:7.0
              hpadding:0.0];
}

- (void)makeDoesNotHaveAuthTokenPanel {
  NSString *message = @"\
For security reasons, we need you to\n\
re-authenticate against your remote\n\
account.";
  UIView *messagePanel = [self messagePanelWithMessage:message iconImage:[UIImage unsyncable]];
  ButtonMaker buttonMaker = [_uitoolkit systemButtonMaker];
  _doesNotHaveAuthTokenPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:[self view]];
  UIButton *reauthenticateBtn = [_uitoolkit systemButtonMaker](@"Re-authenticate", nil, nil);
  [[reauthenticateBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:reauthenticateBtn ofWidth:1.0 relativeTo:_doesNotHaveAuthTokenPanel];
  [PEUIUtils addDisclosureIndicatorToButton:reauthenticateBtn];
  [reauthenticateBtn bk_addEventHandler:^(id sender) {
    [self presentReauthenticateScreen];
  } forControlEvents:UIControlEventTouchUpInside];
  UIView *logoutMsgLabelWithPad = [self logoutPaddedMessage];
  UIButton *logoutBtn = buttonMaker(@"Log Out", self, @selector(logout));
  [[logoutBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:logoutBtn ofWidth:1.0 relativeTo:_doesNotHaveAuthTokenPanel];    
  UIView *exclamationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
  exclamationView.layer.cornerRadius = 10;
  exclamationView.backgroundColor = [UIColor redColor];
  [PEUIUtils placeView:[PEUIUtils labelWithKey:@"!"
                                          font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                               backgroundColor:[UIColor clearColor]
                                     textColor:[UIColor whiteColor]
                           verticalTextPadding:0.0]
            inMiddleOf:exclamationView
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              hpadding:0.0];
  [PEUIUtils placeView:exclamationView
            inMiddleOf:reauthenticateBtn
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              hpadding:15.0];
  
  // place views onto panel
  [PEUIUtils placeView:messagePanel
               atTopOf:_doesNotHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:100
              hpadding:0];
  [PEUIUtils placeView:reauthenticateBtn
                 below:messagePanel
                  onto:_doesNotHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:7.0
              hpadding:0.0];
  [PEUIUtils placeView:logoutMsgLabelWithPad
            atBottomOf:_doesNotHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:175.0
              hpadding:0.0];
  [PEUIUtils placeView:logoutBtn
                 below:logoutMsgLabelWithPad
                  onto:_doesNotHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:7.0
              hpadding:0.0];
}

- (void)makeNotLoggedInPanel {
  NSString *message = @"\
This action will permanently delete your\n\
fuel purchase data from this device.";
  UIView *messagePanel = [self messagePanelWithMessage:message iconImage:[UIImage imageNamed:@"red-exclamation-icon"]];
  ButtonMaker buttonMaker = [_uitoolkit systemButtonMaker];
  _notLoggedInPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:[self view]];
  UIButton *loginBtn = [_uitoolkit systemButtonMaker](@"Log In", nil, nil);
  [[loginBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:loginBtn ofWidth:1.0 relativeTo:_notLoggedInPanel];
  [PEUIUtils addDisclosureIndicatorToButton:loginBtn];
  [loginBtn bk_addEventHandler:^(id sender) {
    [self presentLoginScreen];
  } forControlEvents:UIControlEventTouchUpInside];
  UIButton *createAccountBtn = [_uitoolkit systemButtonMaker](@"Create Account", nil, nil);
  [[createAccountBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:createAccountBtn ofWidth:1.0 relativeTo:_notLoggedInPanel];
  [PEUIUtils addDisclosureIndicatorToButton:createAccountBtn];
  [createAccountBtn bk_addEventHandler:^(id sender) {
    [self presentSetupRemoteAccountScreen];
  } forControlEvents:UIControlEventTouchUpInside];
  UIButton *deleteAllDataBtn = buttonMaker(@"Delete All Data", self, @selector(clearAllData));
  [[deleteAllDataBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:deleteAllDataBtn ofWidth:1.0 relativeTo:_notLoggedInPanel];
  
  // place views onto panel
  [PEUIUtils placeView:loginBtn
               atTopOf:_notLoggedInPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:100
              hpadding:0];
  [PEUIUtils placeView:createAccountBtn
                 below:loginBtn
                  onto:_notLoggedInPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:10.0
              hpadding:0.0];
  [PEUIUtils placeView:messagePanel
            atBottomOf:_notLoggedInPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:175.0
              hpadding:0.0];
  [PEUIUtils placeView:deleteAllDataBtn
                 below:messagePanel
                  onto:_notLoggedInPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:7.0
              hpadding:0.0];
}

#pragma mark - Clear All Data

- (void)clearAllData {
  NSString *msg = @"\
This will permanently delete your fuel\n\
purchase data from this device and cannot\n\
be undone.";
  JGActionSheetSection *contentSection = [PEUIUtils dangerAlertSectionWithTitle:@"Are you absolutely sure?"
                                                                alertDescription:[[NSAttributedString alloc] initWithString:msg]
                                                                  relativeToView:self.tabBarController.view];
  JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                        message:nil
                                                                   buttonTitles:@[@"No.  Cancel.", @"Yes.  Delete my data."]
                                                                    buttonStyle:JGActionSheetButtonStyleDefault];
  [buttonsSection setButtonStyle:JGActionSheetButtonStyleRed forButtonAtIndex:1];
  JGActionSheet *sheet = [JGActionSheet actionSheetWithSections:@[contentSection, buttonsSection]];
  [sheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
    switch ([indexPath row]) {
      case 0: // cancel
        [sheet dismissAnimated:YES];
        break;
      case 1: // delete
        [sheet dismissAnimated:YES];
        [_coordDao resetAsLocalUser:_user error:[FPUtils localSaveErrorHandlerMaker]()];
        [[NSNotificationCenter defaultCenter] postNotificationName:FPAppDeleteAllDataNotification
                                                            object:nil
                                                          userInfo:nil];
        MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        HUD.delegate = self;
        [HUD setLabelText:@"You're data has been deleted."];
        UIImage *image = [UIImage imageNamed:@"hud-complete"];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        [HUD setCustomView:imageView];
        HUD.mode = MBProgressHUDModeCustomView;
        [HUD hide:YES afterDelay:1.50];
        break;
    };}];
  [sheet showInView:self.tabBarController.view animated:YES];
}

#pragma mark - Re-authenticate screen

- (void)presentReauthenticateScreen {
  UIViewController *reauthController =
  [[FPReauthenticateController alloc] initWithStoreCoordinator:_coordDao
                                                          user:_user
                                                     uitoolkit:_uitoolkit
                                                 screenToolkit:_screenToolkit];
  [[self navigationController] pushViewController:reauthController
                                         animated:YES];
}

#pragma mark - Present Log In screen

- (void)presentLoginScreen {
  UIViewController *loginController =
  [[FPAccountLoginController alloc] initWithStoreCoordinator:_coordDao
                                                   localUser:_user
                                                   uitoolkit:_uitoolkit
                                               screenToolkit:_screenToolkit];
  [[self navigationController] pushViewController:loginController
                                         animated:YES];
}

#pragma mark - Present Account Creation screen

- (void)presentSetupRemoteAccountScreen {
  UIViewController *createAccountController =
  [[FPCreateAccountController alloc] initWithStoreCoordinator:_coordDao
                                                    localUser:_user
                                                    uitoolkit:_uitoolkit
                                                screenToolkit:_screenToolkit];
  [[self navigationController] pushViewController:createAccountController
                                         animated:YES];
}

#pragma mark - Logout

- (void)logout {
  void (^postAuthTokenNoMatterWhat)(void) = ^{
    dispatch_async(dispatch_get_main_queue(), ^{
      [APP clearKeychain];
      [_coordDao resetAsLocalUser:_user error:[FPUtils localSaveErrorHandlerMaker]()];
      [[NSNotificationCenter defaultCenter] postNotificationName:FPAppLogoutNotification
                                                          object:nil
                                                        userInfo:nil];
      NSString *msg = @"\
You have been logged out successfully.\n\
Your remote account is no longer connected\n\
to this device and your fuel purchase data\n\
has been removed.\n\n\
You can still use the app.  Your data will\n\
simply be saved locally.";
      [PEUIUtils showSuccessAlertWithMsgs:nil
                                    title:@"Logout successful."
                         alertDescription:[[NSAttributedString alloc] initWithString:msg]
                              buttonTitle:@"Okay."
                             buttonAction:^{
                               dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                 [self viewDidAppear:YES];
                               });
                             }
                           relativeToView:self.tabBarController.view];
    });
  };
  void (^doLogout)(void) = ^{
    // even if the remote authentication token deletion fails, we don't care; we'll still
    // tell the user that logout was successful.  The server should have the smarts to eventually delete
    // the token from its database based on a set of rules anyway (e.g., natural expiration date, or,
    // invalidation after N-amount of inactivity, etc)
    [_coordDao deleteRemoteAuthenticationTokenWithRemoteStoreBusy:^(NSDate *retryAfter) {
      postAuthTokenNoMatterWhat();
    } addlCompletionHandler:^{ postAuthTokenNoMatterWhat(); }];
  };
  NSInteger numUnsyncedEdits = [_coordDao totalNumUnsyncedEntitiesForUser:_user];
  if (numUnsyncedEdits > 0) {
    [PEUIUtils showWarningConfirmAlertWithTitle:@"You have unsynced edits."
                               alertDescription:[[NSAttributedString alloc] initWithString:@"\
You have unsynced edits.  If you log out,\n\
they will be permanently deleted.\n\n\
Are you sure you want to do continue?"]
                                okaybuttonTitle:@"Yes.  Log me out."
                               okaybuttonAction:^{ doLogout(); }
                              cancelbuttonTitle:@"Cancel."
                             cancelbuttonAction:^{ }
                                 relativeToView:self.tabBarController.view];
  } else {
    doLogout();
  }
}

#pragma mark - Edit Mode

- (void)putInEditMode {
}

@end
