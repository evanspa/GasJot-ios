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
  //UIScrollView *_doesHaveAuthTokenPanel;
  UIView *_doesHaveAuthTokenPanel;
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
  [self setAutomaticallyAdjustsScrollViewInsets:NO]; // http://stackoverflow.com/questions/6523205/uiscrollview-adjusts-contentoffset-when-contentsize-changes
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [_notLoggedInPanel removeFromSuperview];
  [_doesHaveAuthTokenPanel removeFromSuperview];
  if ([APP isUserLoggedIn]) {
    [PEUIUtils placeView:_doesHaveAuthTokenPanel
                 atTopOf:[self view]
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0.0];
  } else {
    [PEUIUtils placeView:_notLoggedInPanel
                 atTopOf:[self view]
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0.0];
  }
}

#pragma mark - Helpers

- (UIView *)leftPaddingMessageWithText:(NSString *)text {
  CGFloat leftPadding = 8.0;
  UILabel *label = [PEUIUtils labelWithKey:text
                                      font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                           backgroundColor:[UIColor clearColor]
                                 textColor:[UIColor darkGrayColor]
                       verticalTextPadding:3.0
                                fitToWidth:self.view.frame.size.width - (leftPadding + 5.0)];
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

#pragma mark - Panel Makers

- (void)makeDoesHaveAuthTokenPanel {
  /*CGFloat dividerHeight = (1.0 / [UIScreen mainScreen].scale);
  UIView *(^makeDivider)(CGFloat) = ^ UIView * (CGFloat widthOf) {
    UIView *divider = [PEUIUtils panelWithWidthOf:widthOf relativeToView:_doesHaveAuthTokenPanel fixedHeight:dividerHeight];
    [divider setBackgroundColor:[UIColor darkGrayColor]];
    return divider;
  };*/
  /*_doesHaveAuthTokenPanel = [[UIScrollView alloc] initWithFrame:self.view.frame];
  [_doesHaveAuthTokenPanel setContentSize:CGSizeMake(self.view.frame.size.width,
                                                     1.19 * self.view.frame.size.height)];
  [_doesHaveAuthTokenPanel setBounces:NO];*/
  CGFloat labelLeftPadding = 8.0;
  _doesHaveAuthTokenPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:[self view]];
  UIView *changelogMsgPanel = [PEUIUtils leftPadView:[PEUIUtils labelWithKey:@"\
Keeps your device synchronized with \
your remote account in case you've made edits \
and deletions on other devices."
                                                                        font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                                             backgroundColor:[UIColor clearColor]
                                                                   textColor:[UIColor darkGrayColor]
                                                         verticalTextPadding:3.0
                                                                  fitToWidth:_doesHaveAuthTokenPanel.frame.size.width - 15.0]
                                             padding:labelLeftPadding];
  
  
  UIButton *changelogBtn = [_uitoolkit systemButtonMaker](@"Download All Changes", nil, nil);
  [PEUIUtils placeView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"download-icon"]] inMiddleOf:changelogBtn withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:15.0];
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
                                [PEUIUtils showInfoAlertWithTitle:@"Already up-to-date."
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
  /*NSString *offlineModeLabelText = @"\
Offline mode.  Enables fast \
saving (adds / edits only) in \
poor connection environments.";
  NSMutableAttributedString *offlineModeLabelAttrText =
    [[NSMutableAttributedString alloc] initWithString:offlineModeLabelText];
  NSDictionary *attrs = @{ NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle),
                           NSForegroundColorAttributeName : [UIColor blueColor]};
  [offlineModeLabelAttrText setAttributes:attrs range:NSMakeRange(0, 12)];*/
  UISwitch *offlineModeSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  [offlineModeSwitch setOn:[APP offlineMode]];
  [offlineModeSwitch bk_addEventHandler:^(id sender) {
    [APP setOfflineMode:offlineModeSwitch.on];
  } forControlEvents:UIControlEventTouchUpInside];
  //CGFloat switchPadding = 30.0;
  /*UILabel *offlineModeDescLabel = [PEUIUtils labelWithAttributeText:offlineModeLabelAttrText
                                                               font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                                    backgroundColor:[UIColor clearColor]
                                                          textColor:[UIColor darkGrayColor]
                                                verticalTextPadding:3.0
                                                         fitToWidth:_doesHaveAuthTokenPanel.frame.size.width];  //(_doesHaveAuthTokenPanel.frame.size.width - labelLeftPadding - offlineModeSwitch.frame.size.width - switchPadding)];
  [offlineModeDescLabel setUserInteractionEnabled:YES];
  UITapGestureRecognizer *tapGesture =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(displayOfflineModeInfoAlert)];
  [offlineModeDescLabel addGestureRecognizer:tapGesture];*/
  UILabel *offlineModeDescLabel = [PEUIUtils labelWithKey:@"\
Offline mode prevents upload attempts to \
the server, keeping all saves local-only and very fast.\n\n\
Enable offline mode if you are making \
many saves and you want them done \
instantly and you have a poor internet connection.  Later, you can bulk-upload your edits \
from the 'Records' screen."
                                                     font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                          backgroundColor:[UIColor clearColor]
                                                textColor:[UIColor darkGrayColor]
                                      verticalTextPadding:3.0
                                               fitToWidth:_doesHaveAuthTokenPanel.frame.size.width - 15.0];
  UIView *offlineModeDescPanelWithPad = [PEUIUtils leftPadView:offlineModeDescLabel padding:labelLeftPadding];
  
  UIView *offlineModeSwitchPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:_doesHaveAuthTokenPanel fixedHeight:40.0];
  [offlineModeSwitchPanel setBackgroundColor:[UIColor whiteColor]];
  UILabel *offlineModeLabel = [PEUIUtils labelWithKey:@"Offline mode"
                                                 font:[UIFont systemFontOfSize:16.0]
                                      backgroundColor:[UIColor clearColor]
                                            textColor:[UIColor blackColor]
                                  verticalTextPadding:3.0];
  [PEUIUtils placeView:offlineModeLabel inMiddleOf:offlineModeSwitchPanel withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:15.0];
  [PEUIUtils placeView:offlineModeSwitch inMiddleOf:offlineModeSwitchPanel withAlignment:PEUIHorizontalAlignmentTypeRight hpadding:15.0];
  [PEUIUtils placeView:offlineModeSwitchPanel atTopOf:_doesHaveAuthTokenPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:90.0 hpadding:0.0];
  [PEUIUtils placeView:offlineModeDescPanelWithPad below:offlineModeSwitchPanel onto:_doesHaveAuthTokenPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:7.0 hpadding:0.0];
  
  [PEUIUtils placeView:changelogBtn atBottomOf:_doesHaveAuthTokenPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:_doesHaveAuthTokenPanel.frame.size.height * 0.275 hpadding:0.0];
  [PEUIUtils placeView:changelogMsgPanel below:changelogBtn onto:_doesHaveAuthTokenPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:7.0 hpadding:0.0];
}

- (void)makeNotLoggedInPanel {
  ButtonMaker buttonMaker = [_uitoolkit systemButtonMaker];
  _notLoggedInPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:[self view]];
  NSString *message = @"\
This action will permanently delete your \
fuel purchase data from this device.";
  /*UIView *messagePanel = [self messagePanelWithMessage:message
                                             iconImage:[UIImage imageNamed:@"red-exclamation-icon"]
                                        relativeToView:_notLoggedInPanel];*/
  UIView *messagePanel = [self leftPaddingMessageWithText:message];
  UIButton *deleteAllDataBtn = buttonMaker(@"Delete All Data", self, @selector(clearAllData));
  [[deleteAllDataBtn layer] setCornerRadius:0.0];
  [deleteAllDataBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
  [PEUIUtils placeView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"red-exclamation-icon"]] inMiddleOf:deleteAllDataBtn withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:15.0];
  [PEUIUtils setFrameWidthOfView:deleteAllDataBtn ofWidth:1.0 relativeTo:_notLoggedInPanel];
  
  // place views onto panel
  [PEUIUtils placeView:deleteAllDataBtn
               atTopOf:_notLoggedInPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:90.0
              hpadding:0];
  [PEUIUtils placeView:messagePanel
                 below:deleteAllDataBtn
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
