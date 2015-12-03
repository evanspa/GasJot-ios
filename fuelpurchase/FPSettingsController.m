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
#import "FPSplashController.h"
#import <FlatUIKit/UIColor+FlatUI.h>

#ifdef FP_DEV
  #import <PEDev-Console/UIViewController+PEDevConsole.h>
#endif

@implementation FPSettingsController {
  FPCoordinatorDao *_coordDao;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  FPUser *_user;
  UIScrollView *_doesHaveAuthTokenPanel;
  //UIView *_doesHaveAuthTokenPanel;
  //UIView *_notLoggedInPanel;
  UIScrollView *_notLoggedInPanel;
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

#pragma mark - Dynamic Type Support

- (void)changeTextSize:(NSNotification *)notification {
  [self viewDidAppear:YES];
}

#pragma mark - View Controller Lifecyle

- (void)viewDidLoad {
  [super viewDidLoad];
#ifdef FP_DEV
  [self pdvDevEnable];
#endif
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeTextSize:)
                                               name:UIContentSizeCategoryDidChangeNotification
                                             object:nil];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  UINavigationItem *navItem = [self navigationItem];
  [navItem setTitle:@"Settings"];
  [self setAutomaticallyAdjustsScrollViewInsets:NO]; // http://stackoverflow.com/questions/6523205/uiscrollview-adjusts-contentoffset-when-contentsize-changes
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [[self.navigationController navigationBar] setHidden:NO];
  [_notLoggedInPanel removeFromSuperview];
  [_doesHaveAuthTokenPanel removeFromSuperview];
  if ([APP isUserLoggedIn]) {
    [self makeDoesHaveAuthTokenPanel];
    [PEUIUtils placeView:_doesHaveAuthTokenPanel
                 atTopOf:[self view]
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0.0];
  } else {
    [self makeNotLoggedInPanel];
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
                                      font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
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

- (UIButton *)makeExportButton {
  UIButton *exportBtn = [_uitoolkit systemButtonMaker](@"Export", nil, nil);
  [PEUIUtils setFrameWidthOfView:exportBtn ofWidth:1.0 relativeTo:self.view];
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"yyyy-MM-dd"];
  NSDate *now = [NSDate date];
  [exportBtn bk_addEventHandler:^(id sender) {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
      NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
      NSString *docsDir = [paths objectAtIndex:0];
      NSString *vehiclesFileName = [NSString stringWithFormat:@"%@-vehicles.csv", [dateFormatter stringFromDate:now]];
      NSString *gasStationsFileName = [NSString stringWithFormat:@"%@-gas-stations.csv", [dateFormatter stringFromDate:now]];
       NSString *gasLogsFileName = [NSString stringWithFormat:@"%@-gas-logs.csv", [dateFormatter stringFromDate:now]];
       NSString *odometerLogsFileName = [NSString stringWithFormat:@"%@-odometer-logs.csv", [dateFormatter stringFromDate:now]];
      [_coordDao.localDao exportWithPathToVehiclesFile:[docsDir stringByAppendingPathComponent:vehiclesFileName]
                                       gasStationsFile:[docsDir stringByAppendingPathComponent:gasStationsFileName]
                                           gasLogsFile:[docsDir stringByAppendingPathComponent:gasLogsFileName]
                                      odometerLogsFile:[docsDir stringByAppendingPathComponent:odometerLogsFileName]
                                                  user:_user
                                                 error:[FPUtils localFetchErrorHandlerMaker]()];
      dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [PEUIUtils showSuccessAlertWithMsgs:@[vehiclesFileName, gasStationsFileName, gasLogsFileName, odometerLogsFileName]
                                      title:@"Export Complete."
                           alertDescription:[[NSAttributedString alloc] initWithString:@"Your Gas Jot data has been exported to the following CSV files."]
                   additionalContentSection:[PEUIUtils infoAlertSectionWithTitle:@"Tip"
                                                                alertDescription:[[NSAttributedString alloc] initWithString:@"To download these files to your computer, connect your device to iTunes, \
click on your device, navigate to 'Apps' and scroll down to the 'File Sharing' section.  You'll see Gas Jot listed.  Click on Gas Jot, and you'll be able to see and download your data files."]
                                                                  relativeToView:self.tabBarController.view]
                                   topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                buttonTitle:@"Okay."
                               buttonAction:^{}
                             relativeToView:self.tabBarController.view];
      });
    });
  } forControlEvents:UIControlEventTouchUpInside];
  return exportBtn;
}

#pragma mark - Panel Makers

- (UIView *)makeSplashScreenPanelFitSubtitleToWidth:(CGFloat)fitSubtitleToWidth {
  CGFloat labelLeftPadding = 8.0;
  UIButton *viewSplashScreenBtn = [_uitoolkit systemButtonMaker](@"View splash screen", nil, nil);
  [PEUIUtils setFrameWidthOfView:viewSplashScreenBtn ofWidth:1.0 relativeTo:self.view];
  [PEUIUtils addDisclosureIndicatorToButton:viewSplashScreenBtn];
  UIView *viewSplashScreenMsgPanel = [PEUIUtils leftPadView:[PEUIUtils labelWithKey:@"Care to see Gas Jot's splash screen again?"
                                                                               font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                                                    backgroundColor:[UIColor clearColor]
                                                                          textColor:[UIColor darkGrayColor]
                                                                verticalTextPadding:3.0
                                                                         fitToWidth:fitSubtitleToWidth]
                                             padding:labelLeftPadding];
  [viewSplashScreenBtn bk_addEventHandler:^(id sender) {
    FPSplashController *splashController =
      [[FPSplashController alloc] initWithStoreCoordinator:_coordDao
                                                 uitoolkit:_uitoolkit
                                             screenToolkit:_screenToolkit
                                       letsGoButtonEnabled:NO];
    [self.navigationController pushViewController:splashController animated:YES];
  } forControlEvents:UIControlEventTouchUpInside];
  return [PEUIUtils panelWithColumnOfViews:@[viewSplashScreenBtn, viewSplashScreenMsgPanel]
               verticalPaddingBetweenViews:4.0
                            viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
}

- (void)makeDoesHaveAuthTokenPanel {
  CGFloat labelLeftPadding = 8.0;
  _doesHaveAuthTokenPanel = [[UIScrollView alloc] initWithFrame:self.view.frame];
  UIView *changelogMsgPanel = [PEUIUtils leftPadView:[PEUIUtils labelWithKey:@"\
Keeps your device synchronized with your remote account in case you've made edits \
and deletions on other devices."
                                                                        font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                                             backgroundColor:[UIColor clearColor]
                                                                   textColor:[UIColor darkGrayColor]
                                                         verticalTextPadding:3.0
                                                                  fitToWidth:_doesHaveAuthTokenPanel.frame.size.width - 15.0]
                                             padding:labelLeftPadding];
  UIButton *changelogBtn = [_uitoolkit systemButtonMaker](@"Download all changes", nil, nil);
  [PEUIUtils placeView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"download-icon"]]
            inMiddleOf:changelogBtn
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              hpadding:15.0];
  [[changelogBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:changelogBtn ofWidth:1.0 relativeTo:_doesHaveAuthTokenPanel];
  UIFont* boldDescFont = [PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline];
  [changelogBtn bk_addEventHandler:^(id sender) {
    MBProgressHUD *changelogHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    changelogHud.delegate = self;
    DDLogDebug(@"in FPSettingsController, proceeding to download changelog, ifModifiedSince: [%@]", [PEUtils millisecondsFromDate:[APP changelogUpdatedAt]]);
    [changelogHud setLabelText:@"Synchronizing with server..."];
    void (^displayUnexpectedErrorAlert)(void) = ^{
      [PEUIUtils showErrorAlertWithMsgs:nil
                                  title:@"Error."
                       alertDescription:[[NSAttributedString alloc] initWithString:@"We're sorry, but an unexpected error has occurred.  Please try this again later."]
                               topInset:[PEUIUtils topInsetForAlertsWithController:self]
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
                                                 alertDescription:[[NSAttributedString alloc] initWithString:@"Your device is already fully synchronized with your account."]
                                                         topInset:[PEUIUtils topInsetForAlertsWithController:self]
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
You have successfully synchronized your account to this device, incorporating the following changes:"]
                                                             topInset:[PEUIUtils topInsetForAlertsWithController:self]
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
The server is currently busy at the moment. Please try this again later."]
                                              topInset:[PEUIUtils topInsetForAlertsWithController:self]
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
                     NSAttributedString *attrBecameUnauthMessage =
                     [PEUIUtils attributedTextWithTemplate:@"Re-authenticate"
                                              textToAccent:@"Well this is awkward.  While syncing your account, the server is asking for you \
to re-authenticate.\n\nTo authenticate, tap the %@ button."
                                            accentTextFont:boldDescFont];
                     [PEUIUtils showWarningAlertWithMsgs:nil
                                                   title:@"Authentication Failure."
                                        alertDescription:attrBecameUnauthMessage
                                                topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                             buttonTitle:@"Okay."
                                            buttonAction:^{
                                              [APP refreshTabs];
                                              [self viewDidAppear:YES];
                                            }
                                          relativeToView:self.tabBarController.view];
                   });
                 }];
  } forControlEvents:UIControlEventTouchUpInside];
  UISwitch *offlineModeSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  [offlineModeSwitch setOn:[APP offlineMode]];
  [offlineModeSwitch bk_addEventHandler:^(id sender) {
    [APP setOfflineMode:offlineModeSwitch.on];
    if (offlineModeSwitch.on) {
      [PEUIUtils applyBorderToView:[APP window] withColor:[UIColor carrotColor] width:2.25];
    } else {
      [APP window].layer.borderColor = [UIColor clearColor].CGColor;
      [APP window].layer.borderWidth = 0.0;
    }
  } forControlEvents:UIControlEventTouchUpInside];
  NSMutableAttributedString *offlineDesc = [[NSMutableAttributedString alloc] initWithString:@"\
Offline mode prevents upload attempts to the server, keeping all saves local-only and thus very fast.  \
Enable offline mode if you are making many saves and you want them done instantly and you have a poor internet connection.  "];
  NSAttributedString *offlineDescPart2 = [PEUIUtils attributedTextWithTemplate:@"Later, you can bulk-upload your edits from the %@ screen.\n\n"
                                                                  textToAccent:@"Records"
                                                                accentTextFont:boldDescFont];
  NSAttributedString *offlineDescPart3 = [PEUIUtils attributedTextWithTemplate:@"When offline mode is enabled, an %@ will appear to remind you it's enabled."
                                                                  textToAccent:@"orange border"
                                                                accentTextFont:boldDescFont
                                                               accentTextColor:[UIColor carrotColor]];
  [offlineDesc appendAttributedString:offlineDescPart2];
  [offlineDesc appendAttributedString:offlineDescPart3];
  UILabel *offlineModeDescLabel = [PEUIUtils labelWithAttributeText:offlineDesc
                                                               font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                                    backgroundColor:[UIColor clearColor]
                                                          textColor:[UIColor darkGrayColor]
                                                verticalTextPadding:3.0
                                                         fitToWidth:_doesHaveAuthTokenPanel.frame.size.width - 15.0];
  UIView *offlineModeDescPanelWithPad = [PEUIUtils leftPadView:offlineModeDescLabel padding:labelLeftPadding];
  UILabel *offlineModeLabel = [PEUIUtils labelWithKey:@"Offline mode"
                                                 font:[_uitoolkit fontForButtonsBlk]()
                                      backgroundColor:[UIColor clearColor]
                                            textColor:[UIColor blackColor]
                                  verticalTextPadding:3.0];
  UIView *offlineModeSwitchPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:_doesHaveAuthTokenPanel fixedHeight:(offlineModeLabel.frame.size.height + [_uitoolkit verticalPaddingForButtons])];
  [offlineModeSwitchPanel setBackgroundColor:[UIColor whiteColor]];
  [PEUIUtils placeView:offlineModeLabel inMiddleOf:offlineModeSwitchPanel withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:15.0];
  [PEUIUtils placeView:offlineModeSwitch inMiddleOf:offlineModeSwitchPanel withAlignment:PEUIHorizontalAlignmentTypeRight hpadding:15.0];
  
  [PEUIUtils placeView:offlineModeSwitchPanel atTopOf:_doesHaveAuthTokenPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:90.0 hpadding:0.0];
  CGFloat totalHeight = offlineModeSwitchPanel.frame.size.height + 90;
  [PEUIUtils placeView:offlineModeDescPanelWithPad below:offlineModeSwitchPanel onto:_doesHaveAuthTokenPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:4.0 hpadding:0.0];
  totalHeight += offlineModeDescPanelWithPad.frame.size.height + 4.0;
  [PEUIUtils placeView:changelogBtn below:offlineModeDescPanelWithPad onto:_doesHaveAuthTokenPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:30.0 hpadding:0.0];
  totalHeight += changelogBtn.frame.size.height + 30.0;
  [PEUIUtils placeView:changelogMsgPanel below:changelogBtn onto:_doesHaveAuthTokenPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:4.0 hpadding:0.0];
  totalHeight += changelogMsgPanel.frame.size.height + 4.0;
  UIButton *exportBtn = [self makeExportButton];
  [PEUIUtils placeView:exportBtn below:changelogMsgPanel onto:_doesHaveAuthTokenPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:30.0 hpadding:0.0];
  totalHeight += exportBtn.frame.size.height + 30.0;
  UILabel *exportMsgLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:@"From here you can export your Gas Jot data to files which you can then download from iTunes to your computer.\n\nTip: Before exporting, use the %@ button to \
ensure this device has your latest Gas Jot data."
                                                                                       textToAccent:@"Download all changes"
                                                                                     accentTextFont:boldDescFont]
                                                         font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                     fontForHeightCalculation:boldDescFont
                                              backgroundColor:[UIColor clearColor]
                                                    textColor:[UIColor darkGrayColor]
                                          verticalTextPadding:3.0
                                                   fitToWidth:_doesHaveAuthTokenPanel.frame.size.width - 15.0];
  [PEUIUtils placeView:exportMsgLabel below:exportBtn onto:_doesHaveAuthTokenPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:_doesHaveAuthTokenPanel vpadding:4.0 hpadding:8.0];
  totalHeight += exportMsgLabel.frame.size.height + 4.0;
  UIView *splashScreenPanel = [self makeSplashScreenPanelFitSubtitleToWidth:(_doesHaveAuthTokenPanel.frame.size.width - 15.0)];
  [PEUIUtils placeView:splashScreenPanel below:exportMsgLabel onto:_doesHaveAuthTokenPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:_doesHaveAuthTokenPanel vpadding:35.0 hpadding:0.0];
  totalHeight += splashScreenPanel.frame.size.height + 35.0;
  [PEUIUtils setFrameHeight:totalHeight ofView:_doesHaveAuthTokenPanel];
  [_doesHaveAuthTokenPanel setDelaysContentTouches:NO];
  [_doesHaveAuthTokenPanel setContentSize:CGSizeMake(self.view.frame.size.width, 1.7 * _doesHaveAuthTokenPanel.frame.size.height)];
  [_doesHaveAuthTokenPanel setBounces:YES];
}

- (void)makeNotLoggedInPanel {
  _notLoggedInPanel = [[UIScrollView alloc] initWithFrame:self.view.frame];
  ButtonMaker buttonMaker = [_uitoolkit systemButtonMaker];
  NSString *message = @"This action will permanently delete your Gas Jot data from this device.";
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
  CGFloat totalHeight = deleteAllDataBtn.frame.size.height + 90.0;
  [PEUIUtils placeView:messagePanel
                 below:deleteAllDataBtn
                  onto:_notLoggedInPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  totalHeight += messagePanel.frame.size.height + 4.0;
  UIButton *exportBtn = [self makeExportButton];
  [PEUIUtils placeView:exportBtn below:messagePanel onto:_notLoggedInPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:30.0 hpadding:0.0];
  totalHeight += exportBtn.frame.size.height + 30.0;
  UILabel *exportMsgLabel = [PEUIUtils labelWithAttributeText:[[NSAttributedString alloc] initWithString:@"From here you can export your Gas Jot data to files which you can then download from iTunes to your computer."]
                                                         font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                              backgroundColor:[UIColor clearColor]
                                                    textColor:[UIColor darkGrayColor]
                                          verticalTextPadding:3.0
                                                   fitToWidth:_notLoggedInPanel.frame.size.width - 15.0];
  [PEUIUtils placeView:exportMsgLabel below:exportBtn onto:_notLoggedInPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:_doesHaveAuthTokenPanel vpadding:4.0 hpadding:8.0];
  totalHeight += exportMsgLabel.frame.size.height + 4.0;
  UIView *splashScreenPanel = [self makeSplashScreenPanelFitSubtitleToWidth:(_notLoggedInPanel.frame.size.width - 15.0)];
  [PEUIUtils placeView:splashScreenPanel below:exportMsgLabel onto:_notLoggedInPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:_notLoggedInPanel vpadding:35.0 hpadding:0.0];
  totalHeight += splashScreenPanel.frame.size.height + 35.0;
  [PEUIUtils setFrameHeight:totalHeight ofView:_notLoggedInPanel];
  [_notLoggedInPanel setDelaysContentTouches:NO];
  [_notLoggedInPanel setContentSize:CGSizeMake(self.view.frame.size.width, 1.4 * _notLoggedInPanel.frame.size.height)];
  [_notLoggedInPanel setBounces:YES];
}

#pragma mark - Clear All Data

- (void)clearAllData {
  NSString *msg = @"This will permanently delete your Gas Jot data from this device and cannot be undone.";
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
                                 topInset:[PEUIUtils topInsetForAlertsWithController:self]
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
