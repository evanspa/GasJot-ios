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

#ifdef FP_DEV
  #import <PEDev-Console/UIViewController+PEDevConsole.h>
#endif

@implementation FPSettingsController {
  FPCoordinatorDao *_coordDao;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  FPUser *_user;
  UIScrollView *_doesHaveAuthTokenPanel;
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
  [self setAutomaticallyAdjustsScrollViewInsets:NO]; // http://stackoverflow.com/questions/6523205/uiscrollview-adjusts-contentoffset-when-contentsize-changes
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
  NSString *logoutMsg = @"\
Logging out will disconnect this device from \
your remote account.  This will remove your \
fuel purchase data from this device only.";
  CGFloat leftPadding = 8.0;
  UILabel *label = [PEUIUtils labelWithKey:logoutMsg
                                      font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                           backgroundColor:[UIColor clearColor]
                                 textColor:[UIColor darkGrayColor]
                       verticalTextPadding:3.0
                                fitToWidth:_doesHaveAuthTokenPanel.frame.size.width - (leftPadding + 5.0)];
  return [PEUIUtils leftPadView:label padding:leftPadding];
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

- (void)displayOfflineModeInfoAlert {
  [PEUIUtils showInfoAlertWithTitle:@"Offline mode."
                   alertDescription:[[NSAttributedString alloc] initWithString:@"\
Offline mode prevents upload attempts to \
the server, keeping all saves local-only.\n\n\
Enable offline mode if you are making \
many saves and you want them done \
instantly.  Or enable offline mode if you \
are making saves and you know you have a \
poor internet connection.\n\n\
Later, you can bulk-upload your edits via:\n\n\
'Unsynced Edits' \u2794 'Sync All'"]
                           topInset:70.0 buttonTitle:@"Okay."
                       buttonAction:^{}
                     relativeToView:self.tabBarController.view];
}

#pragma mark - Panel Makers

- (void)makeDoesHaveAuthTokenPanel {
  CGFloat dividerHeight = (1.0 / [UIScreen mainScreen].scale);
  UIView *(^makeDivider)(CGFloat) = ^ UIView * (CGFloat widthOf) {
    UIView *divider = [PEUIUtils panelWithWidthOf:widthOf relativeToView:_doesHaveAuthTokenPanel fixedHeight:dividerHeight];
    [divider setBackgroundColor:[UIColor darkGrayColor]];
    return divider;
  };
  ButtonMaker buttonMaker = [_uitoolkit systemButtonMaker];
  _doesHaveAuthTokenPanel = [[UIScrollView alloc] initWithFrame:self.view.frame];
  [_doesHaveAuthTokenPanel setContentSize:CGSizeMake(self.view.frame.size.width,
                                                     1.19 * self.view.frame.size.height)];
  [_doesHaveAuthTokenPanel setBounces:NO];
  
  NSString *accountSettingsMessage = @"\
You are currently logged in.  From here \
you can view and edit your account \
information and settings.";
  UIView *accountSettingsMsgPanel = [self messagePanelWithMessage:accountSettingsMessage
                                                        iconImage:[UIImage syncable]
                                                   relativeToView:_doesHaveAuthTokenPanel];
  UIButton *accountSettingsBtn = [_uitoolkit systemButtonMaker](@"Account Settings", nil, nil);
  [[accountSettingsBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:accountSettingsBtn ofWidth:1.0 relativeTo:_doesHaveAuthTokenPanel];
  [PEUIUtils addDisclosureIndicatorToButton:accountSettingsBtn];
  [accountSettingsBtn bk_addEventHandler:^(id sender) {
    [PEUIUtils displayController:[_screenToolkit newUserAccountDetailScreenMaker](_user) fromController:self animated:YES];
  } forControlEvents:UIControlEventTouchUpInside];
  
  NSString *changelogMessage = @"\
Keeps your device synchronized with \
your account in case you've made edits \
and deletions on other devices.";
  UIView *changelogMsgPanel = [self messagePanelWithMessage:changelogMessage
                                                  iconImage:[UIImage imageNamed:@"download"]
                                             relativeToView:_doesHaveAuthTokenPanel];
  UIButton *changelogBtn = [_uitoolkit systemButtonMaker](@"Synchronize All", nil, nil);
  [[changelogBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:changelogBtn ofWidth:1.0 relativeTo:_doesHaveAuthTokenPanel];
  [changelogBtn bk_addEventHandler:^(id sender) {
    MBProgressHUD *changelogHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    changelogHud.delegate = self;
    DDLogDebug(@"in FPSettingsController, proceeding to download changelog, ifModifiedSince: [%@]", [PEUtils millisecondsFromDate:[APP changelogUpdatedAt]]);
    [changelogHud setLabelText:@"Synchronizing with server..."];
    void (^displayUnexpectedErrorAlert)(void) = ^{
      [PEUIUtils showErrorAlertWithMsgs:nil
                                  title:@"Error."
                       alertDescription:[[NSAttributedString alloc] initWithString:@"\
We're sorry, but an unexpected error has \
occurred.  Please try this again later."]
                               topInset:70.0
                            buttonTitle:@"Okay."
                           buttonAction:^{}
                         relativeToView:self.tabBarController.view];
    };
    [_coordDao fetchChangelogForUser:_user
                     ifModifiedSince:[APP changelogUpdatedAt]
                 notFoundOnServerBlk:^{
                   dispatch_async(dispatch_get_main_queue(), ^{
                     [changelogHud hide:YES];
                     displayUnexpectedErrorAlert();
                   });
                 }
                          successBlk:^(FPChangelog *changelog) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                              [changelogHud hide:YES];
                              void (^displayAlreadySynchronizedAlert)(void) = ^{
                                [PEUIUtils showInfoAlertWithTitle:@"Already synchronized."
                                                 alertDescription:[[NSAttributedString alloc] initWithString:@"\
Your device is already fully synchronized \
with your account."]
                                                         topInset:70.0
                                                      buttonTitle:@"Okay."
                                                     buttonAction:^{ }
                                                   relativeToView:self.tabBarController.view];
                              };
                              if (changelog) {
                                DDLogDebug(@"in FPSettingsController/fetchChangelog success, calling [APP setChangelogUpdatedAt:(%@)", [PEUtils millisecondsFromDate:changelog.updatedAt]);
                                [APP setChangelogUpdatedAt:changelog.updatedAt];
                                NSArray *report = [_coordDao saveChangelog:changelog forUser:_user error:[FPUtils localSaveErrorHandlerMaker]()];
                                NSInteger numDeletes = [report[0] integerValue];
                                NSInteger numUpdates = [report[1] integerValue];
                                NSInteger numInserts = [report[2] integerValue];
                                if ((numDeletes + numUpdates + numInserts) > 0) {
                                  NSMutableArray *msgs = [NSMutableArray array];
                                  void (^addMessage)(NSInteger, NSString *) = ^(NSInteger value, NSString *desc) {
                                    if (value == 1) {
                                      [msgs addObject:[NSString stringWithFormat:@"%ld record %@.", (long)value, desc]];
                                    } else if (value > 1) {
                                      [msgs addObject:[NSString stringWithFormat:@"%ld records %@.", (long)value, desc]];
                                    }
                                  };
                                  addMessage(numDeletes, @"removed");
                                  addMessage(numUpdates, @"updated");
                                  addMessage(numInserts, @"added");
                                  [PEUIUtils showSuccessAlertWithMsgs:msgs
                                                                title:@"Synchronized."
                                                     alertDescription:[[NSAttributedString alloc] initWithString:@"\
You have successfully synchronized your \
account to this device, incorporating the following changes:"]
                                                             topInset:70.0
                                                          buttonTitle:@"Okay."
                                                         buttonAction:^{
                                                            [APP refreshTabs];
                                                            [APP resetUserInterface];
                                                          }
                                                       relativeToView:self.tabBarController.view];
                                } else {
                                  displayAlreadySynchronizedAlert();
                                }
                              } else {
                                displayAlreadySynchronizedAlert();
                              }
                            });
                          }
                  remoteStoreBusyBlk:^(NSDate *retryAfter) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                      [changelogHud hide:YES];
                      [PEUIUtils showWaitAlertWithMsgs:nil
                                                 title:@"Server is busy."
                                      alertDescription:[[NSAttributedString alloc] initWithString:@"\
The server is currently busy at the moment. \
Please try this again later."]
                                              topInset:70.0
                                           buttonTitle:@"Okay."
                                          buttonAction:^{}
                                        relativeToView:self.tabBarController.view];
                    });
                  }
                  tempRemoteErrorBlk:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                      [changelogHud hide:YES];
                      displayUnexpectedErrorAlert();
                    });
                  }
                 addlAuthRequiredBlk:^{
                   dispatch_async(dispatch_get_main_queue(), ^{
                     [changelogHud hide:YES];
                     [APP refreshTabs];
                     NSString *becameUnauthMessage = @"\
Well this is awkward.  While syncing \
your account, the server is asking for you \
to re-authenticate.\n\n\
To authenticate, tap the Re-authenticate \
button.";
                     NSDictionary *unauthMessageAttrs = @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0] };
                     NSMutableAttributedString *attrBecameUnauthMessage = [[NSMutableAttributedString alloc] initWithString:becameUnauthMessage];
                     NSRange unauthMsgAttrsRange = NSMakeRange(126, 15); // 'Re-authenticate'
                     [attrBecameUnauthMessage setAttributes:unauthMessageAttrs range:unauthMsgAttrsRange];
                     [PEUIUtils showWarningAlertWithMsgs:nil
                                                   title:@"Authentication Failure."
                                        alertDescription:attrBecameUnauthMessage
                                                topInset:70.0
                                             buttonTitle:@"Okay."
                                            buttonAction:^{
                                              [APP refreshTabs];
                                              [self viewDidAppear:YES];
                                            }
                                          relativeToView:self.tabBarController.view];
                   });
                 }];
  } forControlEvents:UIControlEventTouchUpInside];
  NSString *offlineModeLabelText = @"\
Offline mode.  Enables fast \
saving (adds / edits only) in \
poor connection environments.";
  NSMutableAttributedString *offlineModeLabelAttrText =
    [[NSMutableAttributedString alloc] initWithString:offlineModeLabelText];
  NSDictionary *attrs = @{ NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle),
                           NSForegroundColorAttributeName : [UIColor blueColor]};
  [offlineModeLabelAttrText setAttributes:attrs range:NSMakeRange(0, 12)];
  UISwitch *offlineModeSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  [offlineModeSwitch setOn:[APP offlineMode]];
  [offlineModeSwitch bk_addEventHandler:^(id sender) {
    [APP setOfflineMode:offlineModeSwitch.on];
  } forControlEvents:UIControlEventTouchUpInside];
  CGFloat labelLeftPadding = 8.0;
  CGFloat switchPadding = 30.0;
  UILabel *offlineModeLabel = [PEUIUtils labelWithAttributeText:offlineModeLabelAttrText
                                                           font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                                backgroundColor:[UIColor clearColor]
                                                      textColor:[UIColor darkGrayColor]
                                            verticalTextPadding:3.0
                                                     fitToWidth:(_doesHaveAuthTokenPanel.frame.size.width - labelLeftPadding - offlineModeSwitch.frame.size.width - switchPadding)];
  [offlineModeLabel setUserInteractionEnabled:YES];
  UITapGestureRecognizer *tapGesture =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(displayOfflineModeInfoAlert)];
  [offlineModeLabel addGestureRecognizer:tapGesture];
  UIView *offlineModeLabelPanelWithPad = [PEUIUtils leftPadView:offlineModeLabel padding:labelLeftPadding];
  UIView *logoutMsgLabelWithPad = [self logoutPaddedMessage];
  UIButton *logoutBtn = buttonMaker(@"Log Out", self, @selector(logout));
  [logoutBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
  [[logoutBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:logoutBtn ofWidth:1.0 relativeTo:_doesHaveAuthTokenPanel];
  // place views onto panel
  [PEUIUtils placeView:accountSettingsMsgPanel
               atTopOf:_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:80
              hpadding:0.0];
  [PEUIUtils placeView:accountSettingsBtn
                 below:accountSettingsMsgPanel
                  onto:_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:7.0
              hpadding:0.0];
  UIView *divider = makeDivider(1.0);
  [PEUIUtils placeView:divider below:accountSettingsBtn
                  onto:_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:20.0
              hpadding:0.0];
  [PEUIUtils placeView:offlineModeLabelPanelWithPad
                 below:divider
                  onto:_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:20.0
              hpadding:0.0];
  [PEUIUtils placeView:offlineModeSwitch
          toTheRightOf:offlineModeLabelPanelWithPad
                  onto:_doesHaveAuthTokenPanel
         withAlignment:PEUIVerticalAlignmentTypeMiddle
              hpadding:switchPadding];
  divider = makeDivider(1.0);
  [PEUIUtils placeView:divider
                 below:offlineModeLabelPanelWithPad
                  onto:_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:20.0
              hpadding:0.0];
  [PEUIUtils placeView:changelogMsgPanel
                 below:divider
                  onto:_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:20.0
              hpadding:0.0];
  [PEUIUtils placeView:changelogBtn
                 below:changelogMsgPanel
                  onto:_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:7.0
              hpadding:0.0];
  divider = makeDivider(1.0);
  [PEUIUtils placeView:divider
                 below:changelogBtn
                  onto:_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:20.0
              hpadding:0.0];
  [PEUIUtils placeView:logoutMsgLabelWithPad
                 below:divider
                  onto:_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:20.0
              hpadding:0.0];
  [PEUIUtils placeView:logoutBtn
                 below:logoutMsgLabelWithPad
                  onto:_doesHaveAuthTokenPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:7.0
              hpadding:0.0];
}

- (void)makeDoesNotHaveAuthTokenPanel {
  ButtonMaker buttonMaker = [_uitoolkit systemButtonMaker];
  _doesNotHaveAuthTokenPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:[self view]];
  NSString *message = @"\
For security reasons, we need you to \
re-authenticate against your remote \
account.";
  UIView *messagePanel = [self messagePanelWithMessage:message
                                             iconImage:[UIImage unsyncable]
                                        relativeToView:_doesNotHaveAuthTokenPanel];
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
  ButtonMaker buttonMaker = [_uitoolkit systemButtonMaker];
  _notLoggedInPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:[self view]];
  NSString *message = @"\
This action will permanently delete your \
fuel purchase data from this device.";
  UIView *messagePanel = [self messagePanelWithMessage:message
                                             iconImage:[UIImage imageNamed:@"red-exclamation-icon"]
                                        relativeToView:_notLoggedInPanel];
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
  [deleteAllDataBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
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
This will permanently delete your fuel \
purchase data from this device and cannot \
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
                               dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                 [self viewDidAppear:YES];
                               });
                             }
                           relativeToView:self.tabBarController.view];
    });
  };
  void (^doLogout)(void) = ^{
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
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
