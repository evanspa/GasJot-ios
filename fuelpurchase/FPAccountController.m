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

#ifdef FP_DEV
#import <PEDev-Console/UIViewController+PEDevConsole.h>
#endif

NSInteger const kAccountStatusPanelTag = 12;

@implementation FPAccountController {
  FPCoordinatorDao *_coordDao;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  FPUser *_user;
  //UIScrollView *_doesHaveAuthTokenPanel;
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
  [self makeNotLoggedInPanel];
  [self makeDoesHaveAuthTokenPanel];
  [self makeDoesNotHaveAuthTokenPanel];
  //[self setAutomaticallyAdjustsScrollViewInsets:NO]; // http://stackoverflow.com/questions/6523205/uiscrollview-adjusts-contentoffset-when-contentsize-changes
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  UINavigationItem *navItem = [self navigationItem];
  [_notLoggedInPanel removeFromSuperview];
  [_doesHaveAuthTokenPanel removeFromSuperview];
  [_doesNotHaveAuthTokenPanel removeFromSuperview];
  if ([APP isUserLoggedIn]) {
    if ([APP doesUserHaveValidAuthToken]) {
      [navItem setTitle:@"User Account"];
      [PEUIUtils placeView:_doesHaveAuthTokenPanel
                   atTopOf:[self view]
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:0.0
                  hpadding:0.0];
      [FPPanelToolkit refreshAccountStatusPanelForUser:_user
                                              panelTag:@(kAccountStatusPanelTag)
                                  includeRefreshButton:YES
                                        coordinatorDao:_coordDao
                                             uitoolkit:_uitoolkit
                                        relativeToView:_doesHaveAuthTokenPanel
                                            controller:self];
    } else {
      [navItem setTitle:@"User Account (auth required)"];
      [PEUIUtils placeView:_doesNotHaveAuthTokenPanel
                   atTopOf:[self view]
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:0.0
                  hpadding:0.0];
    }
  } else {
    [navItem setTitle:@"Log in or create account"];
    [PEUIUtils placeView:_notLoggedInPanel
                 atTopOf:[self view]
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0.0];
  }
}

#pragma mark - Helpers

- (UIView *)leftPaddingMessageWithText:(NSString *)text {
  return [self leftPaddingMessageWithAttributedText:[[NSAttributedString alloc] initWithString:text]];
}

- (UIView *)leftPaddingMessageWithAttributedText:(NSAttributedString *)attrText {
  CGFloat leftPadding = 8.0;
  UILabel *label = [PEUIUtils labelWithAttributeText:attrText
                                                font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                     backgroundColor:[UIColor clearColor]
                                           textColor:[UIColor darkGrayColor]
                                 verticalTextPadding:3.0
                                          fitToWidth:self.view.frame.size.width - (leftPadding + 5.0)];
  return [PEUIUtils leftPadView:label padding:leftPadding];
}

- (UIView *)logoutPaddedMessage {
  NSString *logoutMsg = @"\
Logging out will disconnect this device from \
your remote account.  This will remove your \
gas jot data from this device only.";
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
                                             font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
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

#pragma mark - Panel Makers

- (void)makeDoesHaveAuthTokenPanel {
  /*CGFloat dividerHeight = (1.0 / [UIScreen mainScreen].scale);
  UIView *(^makeDivider)(CGFloat) = ^ UIView * (CGFloat widthOf) {
    UIView *divider = [PEUIUtils panelWithWidthOf:widthOf relativeToView:_doesHaveAuthTokenPanel fixedHeight:dividerHeight];
    [divider setBackgroundColor:[UIColor darkGrayColor]];
    return divider;
  };*/
  ButtonMaker buttonMaker = [_uitoolkit systemButtonMaker];
  _doesHaveAuthTokenPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:[self view]];
  //_doesHaveAuthTokenPanel = [[UIScrollView alloc] initWithFrame:self.view.frame];
  //[_doesHaveAuthTokenPanel setContentSize:CGSizeMake(self.view.frame.size.width,
  //                                                   1.19 * self.view.frame.size.height)];
  //[_doesHaveAuthTokenPanel setBounces:NO];
  NSAttributedString *attrMessage = [PEUIUtils attributedTextWithTemplate:@"%@.  From here you can view and edit your remote account details."
                                                             textToAccent:@"You are currently logged in"
                                                           accentTextFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]
                                                          accentTextColor:[UIColor greenSeaColor]];
  UIView *accountSettingsMsgPanel = [self leftPaddingMessageWithAttributedText:attrMessage];
  UIButton *accountSettingsBtn = [_uitoolkit systemButtonMaker](@"Remote account details", nil, nil);
  [[accountSettingsBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:accountSettingsBtn ofWidth:1.0 relativeTo:_doesHaveAuthTokenPanel];
  [PEUIUtils addDisclosureIndicatorToButton:accountSettingsBtn];
  [accountSettingsBtn bk_addEventHandler:^(id sender) {
    [PEUIUtils displayController:[_screenToolkit newUserAccountDetailScreenMaker](_user) fromController:self animated:YES];
  } forControlEvents:UIControlEventTouchUpInside];
  UIView *accountStatusPanel = [FPPanelToolkit accountStatusPanelForUser:_user
                                                                panelTag:@(kAccountStatusPanelTag)
                                                    includeRefreshButton:YES
                                                          coordinatorDao:_coordDao
                                                               uitoolkit:_uitoolkit
                                                          relativeToView:_doesHaveAuthTokenPanel
                                                              controller:self];
  [accountStatusPanel setBackgroundColor:[UIColor whiteColor]];
  UIView *logoutMsgLabelWithPad = [self logoutPaddedMessage];
  UIButton *logoutBtn = buttonMaker(@"Log Out", self, @selector(logout));
  [logoutBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
  [[logoutBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:logoutBtn ofWidth:1.0 relativeTo:_doesHaveAuthTokenPanel];
  // place views onto panel
  [PEUIUtils placeView:accountSettingsBtn
               atTopOf:_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:90
              hpadding:0.0];
  [PEUIUtils placeView:accountSettingsMsgPanel
                 below:accountSettingsBtn
                  onto:_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  [PEUIUtils placeView:accountStatusPanel
                 below:accountSettingsMsgPanel
                  onto:_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:35.0
              hpadding:0.0];
  /*UIView *divider = makeDivider(1.0);
  [PEUIUtils placeView:divider
                 below:accountSettingsBtn
                  onto:_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:20.0
              hpadding:0.0];*/
  /*[PEUIUtils placeView:logoutMsgLabelWithPad
                 below:divider
                  onto:_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:20.0
              hpadding:0.0];*/
  
  /*[PEUIUtils placeView:logoutBtn
            atBottomOf:_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:_doesHaveAuthTokenPanel.frame.size.height * 0.275
              hpadding:0.0];
  [PEUIUtils placeView:logoutMsgLabelWithPad
                 below:logoutBtn
                  onto:_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];*/
  [PEUIUtils placeView:logoutMsgLabelWithPad
            atBottomOf:_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:(10.0 + [APP jotButtonHeight])
              hpadding:0.0];
  [PEUIUtils placeView:logoutBtn
                 above:logoutMsgLabelWithPad
                  onto:_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
}

- (void)makeDoesNotHaveAuthTokenPanel {
  ButtonMaker buttonMaker = [_uitoolkit systemButtonMaker];
  _doesNotHaveAuthTokenPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:[self view]];
  NSString *message = @"\
For security reasons, we need you to \
re-authenticate against your remote \
account.";
  UIView *messagePanel = [self leftPaddingMessageWithText:message];
  UIButton *reauthenticateBtn = [_uitoolkit systemButtonMaker](@"Re-authenticate", nil, nil);
  [[reauthenticateBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:reauthenticateBtn ofWidth:1.0 relativeTo:_doesNotHaveAuthTokenPanel];
  [PEUIUtils addDisclosureIndicatorToButton:reauthenticateBtn];
  [reauthenticateBtn bk_addEventHandler:^(id sender) {
    [self presentReauthenticateScreen];
  } forControlEvents:UIControlEventTouchUpInside];
  UIView *logoutMsgLabelWithPad = [self logoutPaddedMessage];
  UIButton *logoutBtn = buttonMaker(@"Log Out", self, @selector(logout));
  [logoutBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
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
  [PEUIUtils placeView:reauthenticateBtn
               atTopOf:_doesNotHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:90.0
              hpadding:0];
  [PEUIUtils placeView:messagePanel
                 below:reauthenticateBtn
                  onto:_doesNotHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  /*[PEUIUtils placeView:logoutBtn
            atBottomOf:_doesNotHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:_doesHaveAuthTokenPanel.frame.size.height * 0.275
              hpadding:0.0];
  [PEUIUtils placeView:logoutMsgLabelWithPad
                 below:logoutBtn
                  onto:_doesNotHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];*/
  [PEUIUtils placeView:logoutMsgLabelWithPad
            atBottomOf:_doesNotHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:(10.0 + [APP jotButtonHeight])
              hpadding:0.0];
  [PEUIUtils placeView:logoutBtn
                 above:logoutMsgLabelWithPad
                  onto:_doesNotHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
}

- (void)makeNotLoggedInPanel {
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
  
  // place views onto panel
  [PEUIUtils placeView:loginBtn
               atTopOf:_notLoggedInPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:90.0
              hpadding:0];
  [PEUIUtils placeView:createAccountBtn
                 below:loginBtn
                  onto:_notLoggedInPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:10.0
              hpadding:0.0];
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
  __block MBProgressHUD *HUD;
  void (^postAuthTokenNoMatterWhat)(void) = ^{
    dispatch_async(dispatch_get_main_queue(), ^{
      [HUD hide:YES];
      [APP clearKeychain];
      [_coordDao resetAsLocalUser:_user error:[FPUtils localSaveErrorHandlerMaker]()];
      [[NSNotificationCenter defaultCenter] postNotificationName:FPAppLogoutNotification
                                                          object:nil
                                                        userInfo:nil];
      NSString *msg = @"\
You have been logged out successfully. \
Your remote account is no longer connected \
to this device and your fuel purchase data \
has been removed.\n\n\
You can still use the app.  Your data will \
simply be saved locally.";
      [PEUIUtils showSuccessAlertWithMsgs:nil
                                    title:@"Logout successful."
                         alertDescription:[[NSAttributedString alloc] initWithString:msg]
                                 topInset:70.0
                              buttonTitle:@"Okay."
                             buttonAction:^{
                               [APP enableJotButton:YES];
                               [[[self tabBarController] tabBar] setUserInteractionEnabled:YES];
                               dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                 [self viewDidAppear:YES];
                               });
                             }
                           relativeToView:self.tabBarController.view];
    });
  };
  void (^doLogout)(void) = ^{
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [APP enableJotButton:NO];
    [[[self tabBarController] tabBar] setUserInteractionEnabled:NO];
    HUD.delegate = self;
    HUD.labelText = @"Logging out...";
    // even if the logout fails, we don't care; we'll still
    // tell the user that logout was successful.  The server should have the smarts to eventually delete
    // the token from its database based on a set of rules anyway (e.g., natural expiration date, or,
    // invalidation after N-amount of inactivity, etc)
    [_coordDao logoutUser:_user
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
                                       topInset:70.0
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
