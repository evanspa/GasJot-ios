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
#import "FPEditActors.h"
#import "FPNames.h"
#import "FPUtils.h"
#import <PEFuelPurchase-Model/PELMNotificationUtils.h>
#import <PEObjc-Commons/PEUtils.h>
#import <PEFuelPurchase-Model/FPNotificationNames.h>

#ifdef FP_DEV
  #import <PEDev-Console/UIViewController+PEDevConsole.h>
#endif

@implementation FPSettingsController {
  FPCoordinatorDao *_coordDao;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  FPUser *_user;
  UIButton *_accountSettingsBtn;
  PESyncViewStyler _syncViewStyler;
  UIView *_accountSettingsBtnOverlay;
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
  [self makeMainPanel];
  
  /* Setup Notification observing */
  /*[PEUtils observeIfNotNilNotificationName:FPUserSyncInitiated
                                  observer:self
                                  selector:@selector(dataObjectSyncInitiated:)];
  [PEUtils observeIfNotNilNotificationName:FPUserSynced
                                  observer:self
                                  selector:@selector(dataObjectSynced:)];
  [PEUtils observeIfNotNilNotificationName:FPUserSyncFailed
                                  observer:self
                                  selector:@selector(dataObjectSyncFailed:)];*/
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  _user = [_coordDao userWithError:[FPUtils localFetchErrorHandlerMaker]()];
  _syncViewStyler(_accountSettingsBtnOverlay, _user);
}

#pragma mark - Notification Observing

/*- (void)dataObjectSyncInitiated:(NSNotification *)notification {
  NSNumber *indexOfNotifEntity =
  [PELMNotificationUtils indexOfEntityRef:_user notification:notification];
  if (indexOfNotifEntity) {
    [PEUIUtils displayTempNotification:@"Sync initiated for this record."
                         forController:self
                             uitoolkit:_uitoolkit];
    _user = [_coordDao userWithError:[FPUtils localFetchErrorHandlerMaker]()];
    _syncViewStyler(_accountSettingsBtnOverlay, _user);
  }
}

- (void)dataObjectSynced:(NSNotification *)notification {
  NSNumber *indexOfNotifEntity =
  [PELMNotificationUtils indexOfEntityRef:_user notification:notification];
  if (indexOfNotifEntity) {
    [PEUIUtils displayTempNotification:@"Sync complete for this record."
                         forController:self
                             uitoolkit:_uitoolkit];
    _user = [_coordDao userWithError:[FPUtils localFetchErrorHandlerMaker]()];
    _syncViewStyler(_accountSettingsBtnOverlay, _user);
  }
}

- (void)dataObjectSyncFailed:(NSNotification *)notification {
  NSNumber *indexOfNotifEntity =
  [PELMNotificationUtils indexOfEntityRef:_user notification:notification];
  if (indexOfNotifEntity) {
    [PEUIUtils displayTempNotification:@"Sync failed for this record."
                         forController:self
                             uitoolkit:_uitoolkit];
    _user = [_coordDao userWithError:[FPUtils localFetchErrorHandlerMaker]()];
    _syncViewStyler(_accountSettingsBtnOverlay, _user);
  }
}*/

#pragma mark - Panels

- (void)makeMainPanel {
  ButtonMaker buttonMaker = [_uitoolkit systemButtonMaker];
  _accountSettingsBtn = [_uitoolkit systemButtonMaker](@"Account Settings", nil, nil);
  [[_accountSettingsBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:_accountSettingsBtn ofWidth:1.0 relativeTo:[self view]];
  _accountSettingsBtnOverlay = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:_accountSettingsBtn];
  [_accountSettingsBtnOverlay setUserInteractionEnabled:NO];
  [PEUIUtils addDisclosureIndicatorToButton:_accountSettingsBtn];
  [_accountSettingsBtn bk_addEventHandler:^(id sender) {
    [PEUIUtils displayController:[_screenToolkit newUserAccountDetailScreenMaker](_user) fromController:self animated:YES];
  } forControlEvents:UIControlEventTouchUpInside];
  _syncViewStyler = [PELMUIUtils syncViewStylerWithUitoolkit:_uitoolkit
                                           foregroundActorId:FPForegroundActorId
                                        subtitleLeftHPadding:4.0];
  [_accountSettingsBtn addSubview:_accountSettingsBtnOverlay];
  [PEUIUtils placeView:_accountSettingsBtn
               atTopOf:[self view]
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:100
              hpadding:0];
  
  UIButton *logoutBtn = buttonMaker(@"Log Out", self, @selector(logout));
  [[logoutBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:logoutBtn ofWidth:1.0 relativeTo:[self view]];
  [PEUIUtils placeView:logoutBtn
            atBottomOf:[self view]
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:100.0
              hpadding:0.0];
}

#pragma mark - Logout

- (void)logout {  
  // TODO - check to see if there are any unsynced records in main_* tables, and
  // if any exist, alert the user, as a logout would blow them away, and his/her
  // edits would be lost  
  
  [APP logoutUser:_user];
}

#pragma mark - Edit Mode

- (void)putInEditMode {
}

@end
