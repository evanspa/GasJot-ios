//
//  FPAccountController.m
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 9/14/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import "FPAccountController.h"
#import <PEObjc-Commons/PEUIUtils.h>
#import <BlocksKit/UIControl+BlocksKit.h>
#import <BlocksKit/UIView+BlocksKit.h>
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
#import "FPPanelToolkit.h"
#import <FlatUIKit/UIColor+FlatUI.h>
#import "FPUIUtils.h"

#ifdef FP_DEV
#import <PEDev-Console/UIViewController+PEDevConsole.h>
#endif

NSInteger const kAccountStatusPanelTag = 12;

@implementation FPAccountController {
  id<FPCoordinatorDao> _coordDao;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  FPUser *_user;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<FPCoordinatorDao>)coordDao
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

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  if ([APP isUserLoggedIn]) {
    if ([APP doesUserHaveValidAuthToken]) {
      NSArray *content = [self makeDoesHaveAuthTokenContent];
      UIView *contentPanel = content[0];
      [FPPanelToolkit refreshAccountStatusPanelForUser:_user
                                              panelTag:@(kAccountStatusPanelTag)
                                  includeRefreshButton:YES
                                        coordinatorDao:_coordDao
                                             uitoolkit:_uitoolkit
                                        relativeToView:contentPanel
                                            controller:self];
      return content;
    } else {
      return [self makeDoesNotHaveAuthTokenContent];
    }
  } else {
    return [self makeNotLoggedInContent];
  }
}

#pragma mark - View Controller Lifecyle

- (void)viewDidLoad {
  [super viewDidLoad];
#ifdef FP_DEV
  [self pdvDevEnable];
#endif
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  UINavigationItem *navItem = [self navigationItem];
  if ([APP isUserLoggedIn]) {
    if ([APP doesUserHaveValidAuthToken]) {
      [navItem setTitle:@"Your Gas Jot Account"];
    } else {
      [navItem setTitle:@"Your Gas Jot Account"];
    }
  } else {
    [navItem setTitle:@"Log In or Create Account"];
  }
}

#pragma mark - Helpers

- (UIView *)leftPaddingMessageWithText:(NSString *)text {
  return [self leftPaddingMessageWithAttributedText:[[NSAttributedString alloc] initWithString:text]];
}

- (UIView *)leftPaddingMessageWithAttributedText:(NSAttributedString *)attrText {
  CGFloat leftPadding = 8.0;
  UILabel *label = [PEUIUtils labelWithAttributeText:attrText
                                                font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                     backgroundColor:[UIColor clearColor]
                                           textColor:[UIColor darkGrayColor]
                                 verticalTextPadding:3.0
                                          fitToWidth:self.view.frame.size.width - (leftPadding + 5.0)];
  return [PEUIUtils leftPadView:label padding:leftPadding];
}

- (UIView *)logoutPaddedMessage {
  NSString *logoutMsg = @"\
Logging out will disconnect this device from your remote account and remove your Gas Jot data.";
  return [self leftPaddingMessageWithText:logoutMsg];
}

- (UIView *)messagePanelWithMessage:(NSString *)message
                          iconImage:(UIImage *)iconImage
                     relativeToView:(UIView *)relativeToView {
  CGFloat iconLeftPadding = 10.0;
  CGFloat paddingBetweenIconAndLabel = 3.0;
  CGFloat labelLeftPadding = 8.0;
  UIImageView *iconImageView = [[UIImageView alloc] initWithImage:iconImage];
  UILabel *messageLabel = [PEUIUtils labelWithKey:message
                                             font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                  backgroundColor:[UIColor clearColor]
                                        textColor:[UIColor darkGrayColor]
                              verticalTextPadding:3.0
                                       fitToWidth:(relativeToView.frame.size.width - (labelLeftPadding + iconImageView.frame.size.width + iconLeftPadding + paddingBetweenIconAndLabel))];
  UIView *messageLabelWithPad = [PEUIUtils leftPadView:messageLabel padding:labelLeftPadding];
  UIView *messagePanel = [PEUIUtils panelWithWidthOf:1.0
                                      relativeToView:relativeToView
                                         fixedHeight:messageLabelWithPad.frame.size.height];
  [PEUIUtils placeView:iconImageView
            inMiddleOf:messagePanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              hpadding:iconLeftPadding];
  [PEUIUtils placeView:messageLabelWithPad
          toTheRightOf:iconImageView
                  onto:messagePanel
         withAlignment:PEUIVerticalAlignmentTypeMiddle
              hpadding:paddingBetweenIconAndLabel];
  return messagePanel;
}

- (UIView *)statsAndTrendsPanel {
  UIView *panel = [PEUIUtils panelWithFixedWidth:self.view.frame.size.width fixedHeight:1.0];
  UIButton *statsBtn = [_uitoolkit systemButtonMaker](@"Stats & Trends", nil, nil);
  [[statsBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:statsBtn ofWidth:1.0 relativeTo:panel];
  [PEUIUtils addDisclosureIndicatorToButton:statsBtn];
  [statsBtn bk_addEventHandler:^(id sender) {
    [[self navigationController] pushViewController:[_screenToolkit newUserStatsLaunchScreenMakerWithParentController:self](_user)
                                           animated:YES];
  } forControlEvents:UIControlEventTouchUpInside];
  UIView *statsMsgPanel = [PEUIUtils leftPadView:[PEUIUtils labelWithKey:@"From here you can drill into various stats and trends associated with your data records."
                                                                    font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                                         backgroundColor:[UIColor clearColor]
                                                               textColor:[UIColor darkGrayColor]
                                                     verticalTextPadding:3.0
                                                              fitToWidth:panel.frame.size.width - 15.0]
                                         padding:8.0];
  [PEUIUtils placeView:statsBtn atTopOf:panel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
  [PEUIUtils placeView:statsMsgPanel
                 below:statsBtn
                  onto:panel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  [PEUIUtils setFrameHeight:(statsBtn.frame.size.height + statsMsgPanel.frame.size.height + 4.0)
                     ofView:panel];
  return panel;
}

#pragma mark - Content Makers

- (NSArray *)makeDoesHaveAuthTokenContent {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:self.view fixedHeight:0];
  ButtonMaker buttonMaker = [_uitoolkit systemButtonMaker];
  NSAttributedString *attrMessage = [PEUIUtils attributedTextWithTemplate:@"%@.  From here you can view and edit your remote account details."
                                                             textToAccent:@"You are currently logged in"
                                                           accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]
                                                          accentTextColor:[UIColor greenSeaColor]];
  UIView *accountSettingsMsgPanel = [self leftPaddingMessageWithAttributedText:attrMessage];
  UIButton *accountSettingsBtn = [_uitoolkit systemButtonMaker](@"Remote account details", nil, nil);
  [[accountSettingsBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:accountSettingsBtn ofWidth:1.0 relativeTo:contentPanel];
  [PEUIUtils addDisclosureIndicatorToButton:accountSettingsBtn];
  [accountSettingsBtn bk_addEventHandler:^(id sender) {
    [PEUIUtils displayController:[_screenToolkit newUserAccountDetailScreenMaker](_user) fromController:self animated:YES];
  } forControlEvents:UIControlEventTouchUpInside];
  UIView *accountStatusPanel = [FPPanelToolkit accountStatusPanelForUser:_user
                                                                panelTag:@(kAccountStatusPanelTag)
                                                    includeRefreshButton:YES
                                                          coordinatorDao:_coordDao
                                                               uitoolkit:_uitoolkit
                                                          relativeToView:contentPanel
                                                              controller:self];
  [accountStatusPanel setBackgroundColor:[UIColor whiteColor]];
  UIView *logoutMsgLabelWithPad = [self logoutPaddedMessage];
  UIButton *logoutBtn = buttonMaker(@"Log Out", self, @selector(logout));
  [logoutBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
  [[logoutBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:logoutBtn ofWidth:1.0 relativeTo:contentPanel];
  
  // place views onto panel
  [PEUIUtils placeView:accountSettingsBtn
               atTopOf:contentPanel //_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:FPContentPanelTopPadding
              hpadding:0.0];
  CGFloat totalHeight = accountSettingsBtn.frame.size.height + FPContentPanelTopPadding;
  [PEUIUtils placeView:accountSettingsMsgPanel
                 below:accountSettingsBtn
                  onto:contentPanel //_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  totalHeight += accountSettingsMsgPanel.frame.size.height + 4.0;
  UIView *statsAndTrendsPanel = [self statsAndTrendsPanel];
  [PEUIUtils placeView:statsAndTrendsPanel
                 below:accountSettingsMsgPanel
                  onto:contentPanel //_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:30.0
              hpadding:0.0];
  totalHeight += statsAndTrendsPanel.frame.size.height + 30.0;
  [PEUIUtils placeView:accountStatusPanel
                 below:statsAndTrendsPanel
                  onto:contentPanel //_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:30.0
              hpadding:0.0];
  totalHeight += accountStatusPanel.frame.size.height + 30.0;
  [PEUIUtils placeView:logoutBtn
                 below:accountStatusPanel
                  onto:contentPanel //_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:30.0
              hpadding:0.0];
  totalHeight += logoutBtn.frame.size.height + 30.0;
  [PEUIUtils placeView:logoutMsgLabelWithPad
                 below:logoutBtn
                  onto:contentPanel //_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  totalHeight += logoutBtn.frame.size.height + 4.0;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(NO)];
}

- (NSArray *)makeDoesNotHaveAuthTokenContent {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:self.view fixedHeight:0];
  ButtonMaker buttonMaker = [_uitoolkit systemButtonMaker];
  NSString *message = @"For security reasons, we need you to re-authenticate against your remote account.";
  UIView *messagePanel = [self leftPaddingMessageWithText:message];
  UIButton *reauthenticateBtn = [_uitoolkit systemButtonMaker](@"Re-authenticate", nil, nil);
  [[reauthenticateBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:reauthenticateBtn ofWidth:1.0 relativeTo:contentPanel];
  [PEUIUtils addDisclosureIndicatorToButton:reauthenticateBtn];
  [reauthenticateBtn bk_addEventHandler:^(id sender) {
    [self presentReauthenticateScreen];
  } forControlEvents:UIControlEventTouchUpInside];
  UIView *logoutMsgLabelWithPad = [self logoutPaddedMessage];
  UIButton *logoutBtn = buttonMaker(@"Log Out", self, @selector(logout));
  [logoutBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
  [[logoutBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:logoutBtn ofWidth:1.0 relativeTo:contentPanel];
  UIView *exclamationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
  exclamationView.layer.cornerRadius = 10;
  exclamationView.backgroundColor = [UIColor redColor];
  [PEUIUtils placeView:[PEUIUtils labelWithKey:@"!"
                                          font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
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
  [PEUIUtils placeView:reauthenticateBtn
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:FPContentPanelTopPadding
              hpadding:0];
  CGFloat totalHeight = reauthenticateBtn.frame.size.height + FPContentPanelTopPadding;
  [PEUIUtils placeView:messagePanel
                 below:reauthenticateBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  totalHeight += messagePanel.frame.size.height + 4.0;
  [PEUIUtils placeView:logoutBtn
                 below:messagePanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:35.0
              hpadding:0.0];
  totalHeight += logoutBtn.frame.size.height + 35.0;
  [PEUIUtils placeView:logoutMsgLabelWithPad
                 below:logoutBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  totalHeight += logoutMsgLabelWithPad.frame.size.height + 4.0;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(NO)];
}

- (NSArray *)makeNotLoggedInContent {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:self.view fixedHeight:0];
  UIButton *loginBtn = [PEUIUtils buttonWithKey:@"Log In"
                                           font:[PEUIUtils boldFontForTextStyle:UIFontTextStyleTitle2]
                                backgroundColor:[UIColor turquoiseColor]
                                      textColor:[UIColor whiteColor]
                   disabledStateBackgroundColor:nil
                         disabledStateTextColor:nil
                                verticalPadding:22.5
                              horizontalPadding:10.0
                                   cornerRadius:5.0
                                         target:nil
                                         action:nil];
  [PEUIUtils setFrameWidthOfView:loginBtn ofWidth:0.85 relativeTo:contentPanel];
  [loginBtn bk_addEventHandler:^(id sender) {
    [self presentLoginScreen];
  } forControlEvents:UIControlEventTouchUpInside];
  NSString *msgText = @"Already have a Gas Jot account?  Log in here.";
  UILabel *loginMsgLbl = [PEUIUtils labelWithAttributeText:[[NSAttributedString alloc] initWithString:msgText]
                                                           font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                                backgroundColor:[UIColor clearColor]
                                                      textColor:[UIColor darkGrayColor]
                                            verticalTextPadding:3.0
                                                     fitToWidth:self.view.frame.size.width - (8.0 + 5.0)];
  [loginMsgLbl setTextAlignment:NSTextAlignmentCenter];
  UIButton *createAccountBtn = [PEUIUtils buttonWithKey:@"Sign Up"
                                                   font:[PEUIUtils boldFontForTextStyle:UIFontTextStyleTitle2]
                                        backgroundColor:[UIColor peterRiverColor]
                                              textColor:[UIColor whiteColor]
                           disabledStateBackgroundColor:nil
                                 disabledStateTextColor:nil
                                        verticalPadding:22.5
                                      horizontalPadding:10.0
                                           cornerRadius:5.0
                                                 target:nil
                                                 action:nil];
  [PEUIUtils setFrameWidthOfView:createAccountBtn ofWidth:0.85 relativeTo:contentPanel];
  [createAccountBtn bk_addEventHandler:^(id sender) {
    [self presentSetupRemoteAccountScreen];
  } forControlEvents:UIControlEventTouchUpInside];
  msgText = @"Creating a Gas Jot account will enable your records to be saved to the Gas Jot server so you can access them from other devices.";
  UILabel *createAcctMsgLbl = [PEUIUtils labelWithAttributeText:[[NSAttributedString alloc] initWithString:msgText]
                                                           font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                                backgroundColor:[UIColor clearColor]
                                                      textColor:[UIColor darkGrayColor]
                                            verticalTextPadding:3.0
                                                     fitToWidth:self.view.frame.size.width - (8.0 + 5.0)];
  [createAcctMsgLbl setTextAlignment:NSTextAlignmentCenter];
  
  // place views onto panel
  [PEUIUtils placeView:loginBtn
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:FPContentPanelTopPadding
              hpadding:0.0];
  CGFloat totalHeight = loginBtn.frame.size.height + FPContentPanelTopPadding;
  [PEUIUtils placeView:loginMsgLbl
                 below:loginBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:8.0
              hpadding:0.0];
  totalHeight += loginMsgLbl.frame.size.height + 8.0;
  [PEUIUtils placeView:createAccountBtn
                 below:loginMsgLbl
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:contentPanel
              vpadding:35.0
              hpadding:0.0];
  totalHeight += createAccountBtn.frame.size.height + 35.0;
  [PEUIUtils placeView:createAcctMsgLbl
                 below:createAccountBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:contentPanel
              vpadding:8.0
              hpadding:0.0];
  totalHeight += createAcctMsgLbl.frame.size.height + 8.0;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(NO), @(YES)];
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
  //[[self navigationController] pushViewController:loginController
    //                                     animated:YES];
  [[self navigationController] presentViewController:[PEUIUtils navigationControllerWithController:loginController
                                                                               navigationBarHidden:NO]
                                            animated:YES
                                          completion:nil];
}

#pragma mark - Present Account Creation screen

- (void)presentSetupRemoteAccountScreen {
  UIViewController *createAccountController =
  [[FPCreateAccountController alloc] initWithStoreCoordinator:_coordDao
                                                    localUser:_user
                                                    uitoolkit:_uitoolkit
                                                screenToolkit:_screenToolkit];
  [[self navigationController] presentViewController:[PEUIUtils navigationControllerWithController:createAccountController
                                                                               navigationBarHidden:NO]
                                            animated:YES
                                          completion:nil];
}

#pragma mark - Logout

- (void)logout {
  FPEnableUserInteractionBlk enableUserInteraction = [FPUIUtils makeUserEnabledBlockForController:self];
  __block MBProgressHUD *HUD;
  void (^postAuthTokenNoMatterWhat)(void) = ^{
    dispatch_async(dispatch_get_main_queue(), ^{
      [HUD hide:YES];
      [APP clearKeychain];
      [_coordDao.userCoordinatorDao resetAsLocalUser:_user error:[FPUtils localSaveErrorHandlerMaker]()];
      [[NSNotificationCenter defaultCenter] postNotificationName:FPAppLogoutNotification
                                                          object:nil
                                                        userInfo:nil];
      NSString *msg = @"\
You have been logged out successfully. \
Your remote account is no longer connected \
to this device and your Gas Jot data \
has been removed.\n\n\
You can still use the app.  Your data will \
simply be saved locally.";
      [PEUIUtils showSuccessAlertWithMsgs:nil
                                    title:@"Logout successful."
                         alertDescription:[[NSAttributedString alloc] initWithString:msg]
                                 topInset:[PEUIUtils topInsetForAlertsWithController:self]
                              buttonTitle:@"Okay."
                             buttonAction:^{
                               dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                 enableUserInteraction(YES);
                                 [self viewDidAppear:YES];
                               });
                             }
                           relativeToView:self.tabBarController.view];
    });
  };
  void (^doLogout)(void) = ^{
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    enableUserInteraction(NO);
    HUD.delegate = self;
    HUD.labelText = @"Logging out...";
    // even if the logout fails, we don't care; we'll still
    // tell the user that logout was successful.  The server should have the smarts to eventually delete
    // the token from its database based on a set of rules anyway (e.g., natural expiration date, or,
    // invalidation after N-amount of inactivity, etc)
    [_coordDao.userCoordinatorDao logoutUser:_user
                          remoteStoreBusyBlk:^(NSDate *retryAfter) { postAuthTokenNoMatterWhat(); }
                           addlCompletionBlk:^{ postAuthTokenNoMatterWhat(); }
                       localSaveErrorHandler:[FPUtils localSaveErrorHandlerMaker]()];
  };
  NSInteger numUnsyncedEdits = [_coordDao totalNumUnsyncedEntitiesForUser:_user];
  if (numUnsyncedEdits > 0) {
    [PEUIUtils showWarningConfirmAlertWithTitle:@"You have unsynced edits."
                               alertDescription:[[NSAttributedString alloc] initWithString:@"\
You have unsynced edits.  If you log out, \
they will be permanently deleted.\n\n\
Are you sure you want to do continue?"]
                                       topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                okayButtonTitle:@"Yes.  Log me out."
                               okayButtonAction:^{ doLogout(); }
                              cancelButtonTitle:@"Cancel."
                             cancelButtonAction:^{ }
                                 relativeToView:self.tabBarController.view];
  } else {
    doLogout();
  }
}

@end
