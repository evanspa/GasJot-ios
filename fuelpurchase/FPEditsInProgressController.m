//
//  FPEditsInProgressController.m
//  fuelpurchase
//
//  Created by Evans, Paul on 9/15/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPEditsInProgressController.h"
#import <BlocksKit/UIControl+BlocksKit.h>
#import <PEObjc-Commons/UIView+PERoundify.h>
#import <FlatUIKit/UIColor+FlatUI.h>
#import "FPUIUtils.h"
#import "FPUtils.h"
#import "UIColor+FPAdditions.h"

#ifdef FP_DEV
  #import <PEDev-Console/UIViewController+PEDevConsole.h>
#endif

@implementation FPEditsInProgressController {
  FPCoordinatorDao *_coordDao;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  FPUser *_user;
  UIScrollView *_scrollView;
  UIView *_eipsMessagePanel;
  UIView *_noEipsMessagePanel;
  UIView *_syncAllMessage;
  // buttons
  UIButton *_vehiclesButton;
  UIButton *_fuelStationsButton;
  UIButton *_envlogsButton;
  UIButton *_fplogsButton;
  UIButton *_syncAllButton;
  CGPoint _scrollContentOffset;
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

#pragma mark - Helpers

- (UIView *)paddedEipsInfoMessage {
  CGFloat leftPadding = 8.0;
  UILabel *infoMsgLabel = [PEUIUtils labelWithKey:@"\
From here you can drill into all of your items \
that have unsynced edits, are edit-in-progress \
or have known problems."
                                             font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                  backgroundColor:[UIColor clearColor]
                                        textColor:[UIColor darkGrayColor]
                              verticalTextPadding:3.0
                                       fitToWidth:self.view.frame.size.width - (leftPadding + 3.0)];
  return [PEUIUtils leftPadView:infoMsgLabel padding:leftPadding];
}

- (UIView *)syncAllInfoMessage {
  CGFloat leftPadding = 8.0;
  UILabel *infoMsgLabel = [PEUIUtils labelWithKey:@"\
This action will attempt to upload all 'sync-able' \
edits.  This include items that don't have \
known problems or are not in edit-in-progress \
mode."
                                             font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                  backgroundColor:[UIColor clearColor]
                                        textColor:[UIColor darkGrayColor]
                              verticalTextPadding:3.0
                                       fitToWidth:self.view.frame.size.width - (leftPadding + 3.0)];
  return [PEUIUtils leftPadView:infoMsgLabel padding:leftPadding];
}

- (UIView *)paddedNoEipsInfoMessage {
  CGFloat leftPadding = 8.0;
  UILabel *infoMsgLabel = [PEUIUtils labelWithKey:@"You currently have no unsynced items."
                                             font:[PEUIUtils boldFontForTextStyle:UIFontTextStyleTitle1] //[UIFont boldSystemFontOfSize:16.0]
                                  backgroundColor:[UIColor clearColor]
                                        textColor:[UIColor darkGrayColor]
                              verticalTextPadding:3.0
                                       fitToWidth:self.view.frame.size.width - (leftPadding + 3.0)];
  return [PEUIUtils leftPadView:infoMsgLabel padding:leftPadding];
}

- (void)makeContentPanel {
  _eipsMessagePanel = [self paddedEipsInfoMessage];
  _noEipsMessagePanel = [self paddedNoEipsInfoMessage];
  _syncAllMessage = [self syncAllInfoMessage];
  
  // get the EIP numbers
  NSInteger numEipVehicles = [_coordDao numUnsyncedVehiclesForUser:_user];
  NSInteger numEipFuelStations = [_coordDao numUnsyncedFuelStationsForUser:_user];
  NSInteger numEipFpLogs = [_coordDao numUnsyncedFuelPurchaseLogsForUser:_user];
  NSInteger numEipEnvLogs = [_coordDao numUnsyncedEnvironmentLogsForUser:_user];
  NSInteger totalNumEips = numEipVehicles + numEipFuelStations + numEipFpLogs + numEipEnvLogs;
  NSInteger totalNumSyncNeeded = [_coordDao totalNumSyncNeededEntitiesForUser:_user];
  UIColor *eipBadgeColor = [UIColor orangeColor];
  UIColor *eipBadgeTextColor = [UIColor blackColor];
  _vehiclesButton = nil;
  if (numEipVehicles > 0) {
    _vehiclesButton = [PEUIUtils buttonWithLabel:@"Vehicles"
                                        badgeNum:numEipVehicles
                                      badgeColor:eipBadgeColor
                                  badgeTextColor:eipBadgeTextColor
                               addDisclosureIcon:YES
                                         handler:^{
                                           _scrollContentOffset = _scrollView.contentOffset;
                                           [PEUIUtils displayController:[_screenToolkit newViewUnsyncedVehiclesScreenMaker](_user)
                                                         fromController:self
                                                               animated:YES]; }
                                       uitoolkit:_uitoolkit
                                  relativeToView:self.view];
  }
  _fuelStationsButton = nil;
  if (numEipFuelStations > 0) {
    _fuelStationsButton = [PEUIUtils buttonWithLabel:@"Gas Stations"
                                            badgeNum:numEipFuelStations
                                          badgeColor:eipBadgeColor
                                      badgeTextColor:eipBadgeTextColor
                                   addDisclosureIcon:YES
                                             handler:^{
                                               _scrollContentOffset = _scrollView.contentOffset;
                                               [PEUIUtils displayController:[_screenToolkit newViewUnsyncedFuelStationsScreenMaker](_user)
                                                             fromController:self
                                                                   animated:YES]; }
                                           uitoolkit:_uitoolkit
                                      relativeToView:self.view];
  }
  _fplogsButton = nil;
  if (numEipFpLogs > 0) {
    _fplogsButton = [PEUIUtils buttonWithLabel:@"Gas Logs"
                                      badgeNum:numEipFpLogs
                                    badgeColor:eipBadgeColor
                                badgeTextColor:eipBadgeTextColor
                             addDisclosureIcon:YES
                                       handler:^{
                                         _scrollContentOffset = _scrollView.contentOffset;
                                         [PEUIUtils displayController:[_screenToolkit newViewUnsyncedFuelPurchaseLogsScreenMaker](_user)
                                                       fromController:self
                                                             animated:YES]; }
                                     uitoolkit:_uitoolkit
                                relativeToView:self.view];
  }
  _envlogsButton = nil;
  if (numEipEnvLogs > 0) {
    _envlogsButton = [PEUIUtils buttonWithLabel:@"Odometer Logs"
                                       badgeNum:numEipEnvLogs
                                     badgeColor:eipBadgeColor
                                 badgeTextColor:eipBadgeTextColor
                              addDisclosureIcon:YES
                                        handler:^{
                                          _scrollContentOffset = _scrollView.contentOffset;
                                          [PEUIUtils displayController:[_screenToolkit newViewUnsyncedEnvironmentLogsScreenMaker](_user)
                                                        fromController:self
                                                              animated:YES]; }
                                      uitoolkit:_uitoolkit
                                 relativeToView:self.view];
  }
  _syncAllButton = nil;
  if (totalNumSyncNeeded > 0) {
    _syncAllButton = [PEUIUtils buttonWithLabel:@"Upload All"
                                       badgeNum:totalNumSyncNeeded
                                     badgeColor:[UIColor fpAppBlue]
                                 badgeTextColor:[UIColor whiteColor]
                              addDisclosureIcon:NO
                                        handler:^{
                                          [self syncAll];
                                        }
                                      uitoolkit:_uitoolkit
                                 relativeToView:self.view];
  }
  // place the views
  UIView *messagePanel;
  if (totalNumEips > 0) {
    messagePanel = _eipsMessagePanel;
  } else {
    messagePanel = _noEipsMessagePanel;
  }
  _scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
  [PEUIUtils placeView:messagePanel
               atTopOf:_scrollView //self.view
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:75.0
              hpadding:0.0];
  CGFloat totalHeight = messagePanel.frame.size.height + 75.0;
  UIView *topView = messagePanel;
  if (_vehiclesButton) {
    [PEUIUtils placeView:_vehiclesButton
                   below:topView
                    onto:_scrollView //self.view
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:7.0
                hpadding:0.0];
    topView = _vehiclesButton;
    totalHeight += _vehiclesButton.frame.size.height + 7.0;
  }
  if (_fuelStationsButton) {
    [PEUIUtils placeView:_fuelStationsButton
                   below:topView
                    onto:_scrollView //self.view
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:7.0
                hpadding:0.0];
    topView = _fuelStationsButton;
    totalHeight += _fuelStationsButton.frame.size.height + 7.0;
  }
  if (_fplogsButton) {
    [PEUIUtils placeView:_fplogsButton
                   below:topView
                    onto:_scrollView //self.view
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:7.0
                hpadding:0.0];
    topView = _fplogsButton;
    totalHeight += _fplogsButton.frame.size.height + 7.0;
  }
  if (_envlogsButton) {
    [PEUIUtils placeView:_envlogsButton
                   below:topView
                    onto:_scrollView //self.view
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:7.0
                hpadding:0.0];
    topView = _envlogsButton;
    totalHeight += _envlogsButton.frame.size.height + 7.0;
  }
  if (totalNumSyncNeeded > 0 && [APP doesUserHaveValidAuthToken]) {
    CGFloat vpadding = self.view.frame.size.height * 0.3;
    [PEUIUtils placeView:_syncAllButton
              atBottomOf:_scrollView //self.view
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:vpadding
                hpadding:0.0];
    totalHeight += _syncAllButton.frame.size.height + vpadding;
    [PEUIUtils placeView:_syncAllMessage
                   below:_syncAllButton
                    onto:_scrollView //self.view
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    topView = _syncAllButton;
    totalHeight += _syncAllMessage.frame.size.height + 5.0;
  }
  if (totalHeight <= self.view.frame.size.height) {
    [PEUIUtils setFrameHeight:self.view.frame.size.height ofView:_scrollView];
     [_scrollView setContentSize:CGSizeMake(self.view.frame.size.width, 1.3 * _scrollView.frame.size.height)];
  } else {
    [PEUIUtils setFrameHeight:totalHeight ofView:_scrollView];
     [_scrollView setContentSize:CGSizeMake(self.view.frame.size.width, 1.6 * _scrollView.frame.size.height)];
  }
  [_scrollView setDelaysContentTouches:NO];
  [_scrollView setBounces:YES];
  [PEUIUtils placeView:_scrollView atTopOf:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];  
}

#pragma mark - Dynamic Type Support

- (void)changeTextSize:(NSNotification *)notification {
  [self viewDidAppear:YES];
}

#pragma mark - View Controller Lifecyle

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:YES];
  [_eipsMessagePanel removeFromSuperview];
  [_noEipsMessagePanel removeFromSuperview];
  [_vehiclesButton removeFromSuperview];
  [_fuelStationsButton removeFromSuperview];
  [_fplogsButton removeFromSuperview];
  [_envlogsButton removeFromSuperview];
  [_syncAllMessage removeFromSuperview];
  [_syncAllButton removeFromSuperview];
  [_scrollView removeFromSuperview];
  [self makeContentPanel];
  [_scrollView setContentOffset:_scrollContentOffset animated:NO];
}

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
  [navItem setTitle:@"Unsynced Edits"];
  [self setAutomaticallyAdjustsScrollViewInsets:NO];
  [self makeContentPanel];
  [PEUIUtils placeView:_scrollView atTopOf:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
  _scrollContentOffset = _scrollView.contentOffset;
}

- (void)syncAll {
  FPEnableUserInteractionBlk enableUserInteraction = [FPUIUtils makeUserEnabledBlockForController:self];
  enableUserInteraction(NO);
  MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  HUD.labelText = @"Uploading records...";
  HUD.mode = MBProgressHUDModeDeterminate;
  __block NSInteger numEntitiesSynced = 0;
  __block NSInteger syncAttemptErrors = 0;
  __block float overallSyncProgress = 0.0;
  __block NSNumber *gotErrMask = nil;
  __block BOOL gotServerBusy = NO;
  __block BOOL gotNotFoundError = NO;
  __block BOOL gotConflictError = NO;
  __block BOOL gotUnauthedError = NO;
  __block BOOL gotTempError = NO;
  [_coordDao flushAllUnsyncedEditsToRemoteForUser:_user
                                entityNotFoundBlk:^(float progress) {
                                  syncAttemptErrors++;
                                  gotNotFoundError = YES;
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
                                 gotServerBusy = YES;
                                 overallSyncProgress += progress;
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                   [HUD setProgress:overallSyncProgress];
                                 });
                               }
                               tempRemoteErrorBlk:^(float progress) {
                                 syncAttemptErrors++;
                                 gotTempError = YES;
                                 overallSyncProgress += progress;
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                   [HUD setProgress:overallSyncProgress];
                                 });
                               }
                                   remoteErrorBlk:^(float progress, NSInteger errMask) {
                                     syncAttemptErrors++;
                                     gotErrMask = [NSNumber numberWithInteger:errMask];
                                     overallSyncProgress += progress;
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                       [HUD setProgress:overallSyncProgress];
                                     });
                                   }
                                      conflictBlk:^(float progress, id e) {
                                        syncAttemptErrors++;
                                        gotConflictError = YES;
                                        overallSyncProgress += progress;
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                          [HUD setProgress:overallSyncProgress];
                                        });
                                      }
                                  authRequiredBlk:^(float progress) {
                                    overallSyncProgress += progress;
                                    gotUnauthedError = YES;
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                      [HUD setProgress:overallSyncProgress];
                                    });
                                  }
                                          allDone:^{
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                              [APP refreshTabs];
                                              if (syncAttemptErrors == 0 && !gotUnauthedError) {
                                                // 100% sync success
                                                NSString *msg;
                                                if (numEntitiesSynced == 1) {
                                                  msg = @"Your record has been uploaded.";
                                                } else {
                                                  msg = @"Your records have been uploaded.";
                                                }
                                                [HUD hide:YES];
                                                [PEUIUtils showSuccessAlertWithMsgs:nil
                                                                              title:@"Upload complete."
                                                                   alertDescription:[[NSAttributedString alloc] initWithString:msg]
                                                                           topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                                        buttonTitle:@"Okay."
                                                                       buttonAction:^{
                                                                         enableUserInteraction(YES);
                                                                         [self viewWillAppear:YES];
                                                                       }
                                                                     relativeToView:self.tabBarController.view];
                                              } else {
                                                [HUD hide:YES];
                                                NSMutableArray *sections = [NSMutableArray array];
                                                JGActionSheetSection *(^successSection)(NSString *, NSString *) = ^JGActionSheetSection *(NSString *title, NSString *msg) {
                                                  return [PEUIUtils successAlertSectionWithTitle:title
                                                                                alertDescription:[[NSAttributedString alloc] initWithString:msg]
                                                                                  relativeToView:self.tabBarController.view];
                                                };
                                                JGActionSheetSection *(^conflictSection)(NSString *, NSString *) = ^JGActionSheetSection *(NSString *title, NSString *msg) {
                                                  return [PEUIUtils conflictAlertSectionWithTitle:title
                                                                                 alertDescription:[[NSAttributedString alloc] initWithString:msg]
                                                                                   relativeToView:self.tabBarController.view];
                                                };
                                                JGActionSheetSection *(^errSection)(NSString *, NSString *) = ^JGActionSheetSection *(NSString *title, NSString *msg) {
                                                  return [PEUIUtils errorAlertSectionWithMsgs:nil
                                                                                        title:title
                                                                              alertDescription:[[NSAttributedString alloc] initWithString:msg]
                                                                                relativeToView:self.tabBarController.view];
                                                };
                                                JGActionSheetSection *(^waitSection)(NSString *) = ^JGActionSheetSection *(NSString *msg) {
                                                  return [PEUIUtils waitAlertSectionWithMsgs:nil
                                                                                       title:@"Busy with maintenance."
                                                                            alertDescription:[[NSAttributedString alloc] initWithString:msg]
                                                                              relativeToView:self.view];
                                                };
                                                JGActionSheetSection *(^authErrSection)(NSString *) = ^JGActionSheetSection *(NSString *msg) {
                                                  return [PEUIUtils warningAlertSectionWithMsgs:nil
                                                                                          title:@"Authentication failure."
                                                                               alertDescription:[[NSAttributedString alloc] initWithString:msg]
                                                                                 relativeToView:self.tabBarController.view];
                                                };
// ------------------------------------------------------------------------------------------
                                                NSString *theRecordNotFoundMsg = @"\
It would appear your record no longer \
exists and was probably deleted on \
a different device.\n\n\
Drill into its detail screen to delete \
it from this device.";
                                                NSString *aRecordNotFoundMSg = @"\
At least one your records no longer exists \
on the server and was probably deleted on \
a different device.";
                                                NSString *oneRecordNotFoundMsg = @"\
One of your records no longer exists on \
the server and was probably deleted on a \
different device.";
// ------------------------------------------------------------------------------------------
                                                NSString *theRecordConflictMsg = @"\
The remote copy of your record has been \
updated since you last downloaded it.\n\n\
Drill into its detail screen to resolve \
it.";
                                                NSString *aRecordConflictMsg = @"\
At least one of your records has been \
updated since you last downloaded it.";
                                                NSString *oneRecordConflictMsg = @"\
One of your records has been updated \
since you last downloaded it.";
// ------------------------------------------------------------------------------------------
                                                NSString *theRecordValidationErrMsg = @"\
There are problem(s) with your record.\n\n\
Drill into its detail screen to fix it.";
                                                NSString *aRecordValidationErrMSg = @"\
At least one of your records has problem(s) \
with it.";
                                                NSString *oneRecordValidationErrMsg = @"\
One of your records has problem(s) with it. \
Drill into its detail screen to fix it.";
// ------------------------------------------------------------------------------------------
                                                NSString *theRecordWaitMsg = @"\
While attempting to sync your record, the \
Gas Jot server reported that it is busy undergoing \
maintenance.  Try syncing it later.";
                                                NSString *aRecordWaitMsg = @"\
While attempting to sync at least one your \
records, the Gas Jot server reported it is busy \
undergoing maintenance.  Try syncing \
your edits later.";
                                                NSString *oneRecordWaitMsg = @"\
While attempting to sync one of your records, \
the Gas Jot server reported it is busy undergoing \
maintenance.  Try syncing it later.";
// ------------------------------------------------------------------------------------------
                                                NSString *theRecordUnauthMsg = @"\
While attempting to sync your record, the \
Gas Jot server has asked for you to re-authenticate.";
                                                NSString *aRecordUnauthMsg = @"\
While attempting to sync at least one one \
your records, the Gas Jot server has asked for you to \
re-authenticate.";
                                                NSString *oneRecordUnauthMsg = @"\
While attempting to sync one your records, \
the Gas Jot server has asked for you to \
re-authenticate.";
// ------------------------------------------------------------------------------------------
                                                NSString *theRecordTempErrMsg = @"\
There was an error attempting to upload \
your record.  Try syncing it later.";
                                                NSString *aRecordTempErrMsg = @"\
There was an error attempting to upload \
at least one of your records.  Try syncing \
them again later.";
                                                NSString *oneRecordTempErrMsg = @"\
There was an error attempting to upload \
one of your records.  Try syncing it later.";
// ------------------------------------------------------------------------------------------
                                                void (^aRecordError)(void) = ^{
                                                  if (gotNotFoundError) { [sections addObject:errSection(@"Record not found.", aRecordNotFoundMSg)]; }
                                                  if (gotConflictError) { [sections addObject:conflictSection(@"Conflict.", aRecordConflictMsg)]; }
                                                  if (gotErrMask) { [sections addObject:errSection(@"Validation error.", aRecordValidationErrMSg)]; }
                                                  if (gotServerBusy) { [sections addObject:waitSection(aRecordWaitMsg)]; }
                                                  if (gotUnauthedError) { [sections addObject:authErrSection(aRecordUnauthMsg)]; }
                                                  if (gotTempError) { [sections addObject:errSection(@"Temporary error.", aRecordTempErrMsg)]; }
                                                };
                                                void (^oneRecordError)(void) = ^{
                                                  if (gotNotFoundError) { [sections addObject:errSection(@"Record not found.", oneRecordNotFoundMsg)]; }
                                                  if (gotConflictError) { [sections addObject:conflictSection(@"Conflict.", oneRecordConflictMsg)]; }
                                                  if (gotErrMask) { [sections addObject:errSection(@"Validation error.", oneRecordValidationErrMsg)]; }
                                                  if (gotServerBusy) { [sections addObject:waitSection(oneRecordWaitMsg)]; }
                                                  if (gotUnauthedError) { [sections addObject:authErrSection(oneRecordUnauthMsg)]; }
                                                  if (gotTempError) { [sections addObject:errSection(@"Temporary error.", oneRecordTempErrMsg)]; }
                                                };
                                                if (numEntitiesSynced == 0) { // none synced
                                                  if (syncAttemptErrors == 1) { // only 1 entity to sync, and it err'd
                                                    if (gotNotFoundError) {
                                                      [sections addObject:errSection(@"Record not found.", theRecordNotFoundMsg)];
                                                    } else if (gotConflictError) {
                                                      [sections addObject:conflictSection(@"Conflict.", theRecordConflictMsg)];
                                                    } else if (gotErrMask) {
                                                      [sections addObject:errSection(@"Validation error.", theRecordValidationErrMsg)];
                                                    } else if (gotServerBusy) {
                                                      [sections addObject:waitSection(theRecordWaitMsg)];
                                                    } else if (gotUnauthedError) {
                                                      [sections addObject:authErrSection(theRecordUnauthMsg)];
                                                    } else { // got temp error
                                                      [sections addObject:errSection(@"Temporary error.", theRecordTempErrMsg)];
                                                    }
                                                  } else { // multiple entities to sync, and they ALL err'd
                                                    aRecordError();
                                                  }
                                                } else if (numEntitiesSynced == 1) { // 1 entity successfully synced
                                                  if (syncAttemptErrors == 1) { // only 1 entity err'd
                                                    oneRecordError();
                                                  } else { // multiple entities err'd
                                                    aRecordError();
                                                  }
                                                  [sections addObject:successSection(@"1 record synced.", @"One of your records successfully synced.")];
                                                } else { // multiple entities successfully synced
                                                  if (syncAttemptErrors == 1) { // only 1 entity err'd
                                                    oneRecordError();
                                                  } else { // multiple entities err'd
                                                    aRecordError();
                                                  }
                                                  [sections addObject:successSection(@"Some records synced.", @"Some of your records successfully synced.")];
                                                }
                                                JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                                                                      message:nil
                                                                                                                 buttonTitles:@[@"Okay."]
                                                                                                                  buttonStyle:JGActionSheetButtonStyleDefault];
                                                [sections addObject:buttonsSection];
                                                JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:sections];
                                                [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
                                                  enableUserInteraction(YES);
                                                  [sheet dismissAnimated:YES];
                                                  [self viewWillAppear:YES];
                                                }];
                                                [alertSheet showInView:self.tabBarController.view animated:YES];
                                              }
                                            });
                                          }
                                            error:[FPUtils localDatabaseErrorHudHandlerMaker](HUD, self, self.tabBarController.view)];
}

@end
