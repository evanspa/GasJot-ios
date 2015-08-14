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
#import "FPUtils.h"

#ifdef FP_DEV
  #import <PEDev-Console/UIViewController+PEDevConsole.h>
#endif

@implementation FPEditsInProgressController {
  FPCoordinatorDao *_coordDao;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  FPUser *_user;
  UIView *_eipsMessagePanel;
  UIView *_noEipsMessagePanel;
  UIView *_syncAllMessage;
  // buttons
  UIButton *_vehiclesButton;
  UIButton *_fuelStationsButton;
  UIButton *_envlogsButton;
  UIButton *_fplogsButton;
  UIButton *_syncAllButton;
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
  UILabel *infoMsgLabel = [PEUIUtils labelWithKey:@"\
From here you can drill into all of your items\n\
that have unsynced edits, are edit-in-progress\n\
or have known problems."
                                             font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                  backgroundColor:[UIColor clearColor]
                                        textColor:[UIColor darkGrayColor]
                              verticalTextPadding:3.0];
  return [PEUIUtils leftPadView:infoMsgLabel padding:8.0];
}

- (UIView *)syncAllInfoMessage {
  UILabel *infoMsgLabel = [PEUIUtils labelWithKey:@"\
This action will attempt to sync all 'sync-able'\n\
edits.  This include items that don't have\n\
known problems or are not in edit-in-progress\n\
mode."
                                             font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                  backgroundColor:[UIColor clearColor]
                                        textColor:[UIColor darkGrayColor]
                              verticalTextPadding:3.0];
  return [PEUIUtils leftPadView:infoMsgLabel padding:8.0];
}

- (UIView *)paddedNoEipsInfoMessage {
  UILabel *infoMsgLabel = [PEUIUtils labelWithKey:@"\
You currently have no unsynced items."
                                             font:[UIFont boldSystemFontOfSize:16.0]
                                  backgroundColor:[UIColor clearColor]
                                        textColor:[UIColor darkGrayColor]
                              verticalTextPadding:3.0];
  return [PEUIUtils leftPadView:infoMsgLabel padding:8.0];
}

- (UIView *)badgeForNum:(NSInteger)num
                  color:(UIColor *)color
         badgeTextColor:(UIColor *)badgeTextColor {
  if (num == 0) {
    return nil;
  }
  CGFloat widthPadding = 30.0;
  CGFloat heightFactor = 1.45;
  CGFloat fontSize = [UIFont systemFontSize];
  NSString *labelText;
  if (num > 9999) {
    fontSize = 10.0;
    widthPadding = 10.0;
    heightFactor = 1.95;
    labelText = @"a plethora";
  } else {
    labelText = [NSString stringWithFormat:@"%ld", (long)num];
  }
  UILabel *label = [PEUIUtils labelWithKey:labelText
                                      font:[UIFont boldSystemFontOfSize:fontSize]
                           backgroundColor:[UIColor clearColor]
                                 textColor:badgeTextColor
                       verticalTextPadding:0.0];
  UIView *badge = [PEUIUtils panelWithFixedWidth:label.frame.size.width + widthPadding fixedHeight:label.frame.size.height * heightFactor];
  [badge addRoundedCorners:UIRectCornerAllCorners
                 withRadii:CGSizeMake(20.0, 20.0)];
  badge.alpha = 0.8;
  badge.backgroundColor = color;
  [PEUIUtils placeView:label
            inMiddleOf:badge
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              hpadding:0.0];
  return badge;
}

- (UIButton *)buttonWithLabel:(NSString *)labelText
                     badgeNum:(NSInteger)badgeNum
                   badgeColor:(UIColor *)badgeColor
               badgeTextColor:(UIColor *)badgeTextColor
            addDisclosureIcon:(BOOL)addDisclosureIcon
                      handler:(void(^)(void))handler {
  if (badgeNum == 0) {
    return nil;
  }
  UIButton *button = [_uitoolkit systemButtonMaker](labelText, nil, nil);
  [[button layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:button ofWidth:1.0 relativeTo:self.view];
  if (addDisclosureIcon) {
    [PEUIUtils addDisclosureIndicatorToButton:button];
  }
  [button bk_addEventHandler:^(id sender) {
    handler();
  } forControlEvents:UIControlEventTouchUpInside];
  UIView *badge = [self badgeForNum:badgeNum color:badgeColor badgeTextColor:badgeTextColor];
  [PEUIUtils placeView:badge
            inMiddleOf:button
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              hpadding:15.0];
  return button;
}

#pragma mark - View Controller Lifecyle

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:YES];
  
  // remove stale message panels
  [_eipsMessagePanel removeFromSuperview];
  [_noEipsMessagePanel removeFromSuperview];
  
  // remove stale buttons
  [_vehiclesButton removeFromSuperview];
  [_fuelStationsButton removeFromSuperview];
  [_fplogsButton removeFromSuperview];
  [_envlogsButton removeFromSuperview];
  [_syncAllMessage removeFromSuperview];
  [_syncAllButton removeFromSuperview];
  
  // get the EIP numbers
  NSInteger numEipVehicles = [_coordDao numUnsyncedVehiclesForUser:_user];
  NSInteger numEipFuelStations = [_coordDao numUnsyncedFuelStationsForUser:_user];
  NSInteger numEipFpLogs = [_coordDao numUnsyncedFuelPurchaseLogsForUser:_user];
  NSInteger numEipEnvLogs = [_coordDao numUnsyncedEnvironmentLogsForUser:_user];
  NSInteger totalNumEips = numEipVehicles + numEipFuelStations + numEipFpLogs + numEipEnvLogs;
  NSInteger totalNumSyncNeeded = [_coordDao totalNumSyncNeededEntitiesForUser:_user];
  UIColor *eipBadgeColor = [UIColor orangeColor];
  UIColor *eipBadgeTextColor = [UIColor blackColor];
  _vehiclesButton = [self buttonWithLabel:@"Vehicles"
                                 badgeNum:numEipVehicles
                               badgeColor:eipBadgeColor
                           badgeTextColor:eipBadgeTextColor
                        addDisclosureIcon:YES
                                  handler:^{
                                    [PEUIUtils displayController:[_screenToolkit newViewUnsyncedVehiclesScreenMaker](_user)
                                                  fromController:self
                                                        animated:YES]; }];
  _fuelStationsButton = [self buttonWithLabel:@"Fuel Stations"
                                     badgeNum:numEipFuelStations
                                   badgeColor:eipBadgeColor
                               badgeTextColor:eipBadgeTextColor
                            addDisclosureIcon:YES
                                      handler:^{
                                        [PEUIUtils displayController:[_screenToolkit newViewUnsyncedFuelStationsScreenMaker](_user)
                                                      fromController:self
                                                            animated:YES]; }];
  _fplogsButton = [self buttonWithLabel:@"Fuel Purchase Logs"
                              badgeNum:numEipFpLogs
                             badgeColor:eipBadgeColor
                         badgeTextColor:eipBadgeTextColor
                      addDisclosureIcon:YES
                                handler:^{
                                  [PEUIUtils displayController:[_screenToolkit newViewUnsyncedFuelPurchaseLogsScreenMaker](_user)
                                                fromController:self
                                                      animated:YES]; }];
  _envlogsButton = [self buttonWithLabel:@"Environment Logs"
                                badgeNum:numEipEnvLogs
                              badgeColor:eipBadgeColor
                          badgeTextColor:eipBadgeTextColor
                       addDisclosureIcon:YES
                                 handler:^{
                                   [PEUIUtils displayController:[_screenToolkit newViewUnsyncedEnvironmentLogsScreenMaker](_user)
                                                 fromController:self
                                                       animated:YES]; }];
  _syncAllButton = [self buttonWithLabel:@"Sync All"
                                badgeNum:totalNumSyncNeeded
                              badgeColor:[UIColor blueColor]
                          badgeTextColor:[UIColor whiteColor]
                       addDisclosureIcon:NO
                                 handler:^{
                                   [self syncAll];
                                 }];
  // place the views
  UIView *messagePanel;
  if (totalNumEips > 0) {
    messagePanel = _eipsMessagePanel;
  } else {
    messagePanel = _noEipsMessagePanel;
  }
  [PEUIUtils placeView:messagePanel
               atTopOf:self.view
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:80.0
              hpadding:0.0];
  UIView *topView = messagePanel;
  if (_vehiclesButton) {
    [PEUIUtils placeView:_vehiclesButton
                   below:topView
                    onto:self.view
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:7.0
                hpadding:0.0];
    topView = _vehiclesButton;
  }
  if (_fuelStationsButton) {
    [PEUIUtils placeView:_fuelStationsButton
                   below:topView
                    onto:self.view
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:7.0
                hpadding:0.0];
    topView = _fuelStationsButton;
  }
  if (_fplogsButton) {
    [PEUIUtils placeView:_fplogsButton
                   below:topView
                    onto:self.view
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:7.0
                hpadding:0.0];
    topView = _fplogsButton;
  }
  if (_envlogsButton) {
    [PEUIUtils placeView:_envlogsButton
                   below:topView
                    onto:self.view
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:7.0
                hpadding:0.0];
    topView = _envlogsButton;
  }
  if (totalNumSyncNeeded > 0) {
    [PEUIUtils placeView:_syncAllMessage
                   below:topView
                    onto:self.view
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:15.0
                hpadding:0.0];
    [PEUIUtils placeView:_syncAllButton
                   below:_syncAllMessage
                    onto:self.view
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    topView = _syncAllButton;
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
#ifdef FP_DEV
  [self pdvDevEnable];
#endif
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  UINavigationItem *navItem = [self navigationItem];
  [navItem setTitle:@"Unsynced Edits"];
  
  // make the button (and message panel) views
  _eipsMessagePanel = [self paddedEipsInfoMessage];
  _noEipsMessagePanel = [self paddedNoEipsInfoMessage];
  
  _syncAllMessage = [self syncAllInfoMessage];
}

- (void)syncAll {
  MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  HUD.labelText = @"Syncing records...";
  HUD.mode = MBProgressHUDModeDeterminate;
  __block NSInteger numEntitiesSynced = 0;
  __block BOOL receivedUnauthedError = NO;
  __block NSInteger syncAttemptErrors = 0;
  __block float overallSyncProgress = 0.0;
  [_coordDao flushAllUnsyncedEditsToRemoteForUser:_user
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
                                      conflictBlk:^(float progress, id e) {
                                        syncAttemptErrors++;
                                        overallSyncProgress += progress;
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                          [HUD setProgress:overallSyncProgress];
                                        });
                                      }
                                  authRequiredBlk:^(float progress) {
                                    overallSyncProgress += progress;
                                    receivedUnauthedError = YES;
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                      [HUD setProgress:overallSyncProgress];
                                    });
                                  }
                                          allDone:^{
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                              [APP refreshTabs];
                                              if (syncAttemptErrors == 0 && !receivedUnauthedError) {
                                                // 100% sync success
                                                [HUD hide:YES];
                                                [PEUIUtils showSuccessAlertWithMsgs:nil
                                                                              title:@"Sync Complete."
                                                                   alertDescription:[[NSAttributedString alloc] initWithString:@"\
Your records have been synced."]
                                                                        buttonTitle:@"Okay."
                                                                       buttonAction:^{ [self viewWillAppear:YES]; }
                                                                     relativeToView:self.tabBarController.view];
                                              } else {
                                                [HUD hide:YES];
                                                NSMutableArray *sections = [NSMutableArray array];
                                                JGActionSheetSection *becameUnauthSection = nil;
                                                if (receivedUnauthedError) {
                                                  NSString *becameUnauthMessage = @"\
This is awkward.  While syncing your local\n\
edits, the server is asking for you to\n\
authenticate.  Sorry about that.\n\
To authenticate, tap the Re-authenticate\n\
button.";
                                                  NSDictionary *unauthMessageAttrs = @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0] };
                                                  NSMutableAttributedString *attrBecameUnauthMessage = [[NSMutableAttributedString alloc] initWithString:becameUnauthMessage];
                                                  NSRange unauthMsgAttrsRange = NSMakeRange(146, 15); // 'Re-authenticate'
                                                  [attrBecameUnauthMessage setAttributes:unauthMessageAttrs range:unauthMsgAttrsRange];
                                                  becameUnauthSection = [PEUIUtils warningAlertSectionWithMsgs:nil
                                                                                                         title:@"Authentication Failure."
                                                                                              alertDescription:attrBecameUnauthMessage
                                                                                                relativeToView:self.tabBarController.view];
                                                }
                                                NSString *title;
                                                NSString *message;
                                                if (numEntitiesSynced == 0) {
                                                  // none synced
                                                  title = @"Sync problems.";
                                                  message = @"\
There were problems syncing your local\n\
edits.";

                                                } else {
                                                  // some synced
                                                  title = @"Some sync problems.";
                                                  message = @"\
There were problems syncing some of your\n\
local edits.";

                                                }
                                                JGActionSheetSection *mainSection = [PEUIUtils warningAlertSectionWithMsgs:nil
                                                                                                                     title:title
                                                                                                          alertDescription:[[NSAttributedString alloc] initWithString:message]
                                                                                                            relativeToView:self.tabBarController.view];
                                                JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                                                                      message:nil
                                                                                                                 buttonTitles:@[@"Okay."]
                                                                                                                  buttonStyle:JGActionSheetButtonStyleDefault];
                                                
                                                [sections addObject:mainSection];
                                                if (becameUnauthSection) {
                                                  [sections addObject:becameUnauthSection];
                                                }
                                                [sections addObject:buttonsSection];
                                                JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:sections];
                                                [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
                                                  [sheet dismissAnimated:YES];
                                                  [self viewWillAppear:YES];
                                                }];
                                                [alertSheet showInView:self.tabBarController.view animated:YES];
                                              }
                                            });
                                          }
                                            error:[FPUtils localDatabaseErrorHudHandlerMaker](HUD, self.tabBarController.view)];
}

@end
