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
  UIButton *_accountSettingsBtn;
  UIButton *_logoutBtn;
  UIButton *_loginBtn;
  UIButton *_reauthenticateBtn;
  UIButton *_createAccountBtn;
  UIButton *_deleteAllDataBtn;
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
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [_accountSettingsBtn removeFromSuperview];
  [_reauthenticateBtn removeFromSuperview];
  [_logoutBtn removeFromSuperview];
  [_loginBtn removeFromSuperview];
  [_createAccountBtn removeFromSuperview];
  [_deleteAllDataBtn removeFromSuperview];
  if ([APP isUserLoggedIn]) {
    if ([APP doesUserHaveValidAuthToken]) {
      [PEUIUtils placeView:_accountSettingsBtn
                   atTopOf:[self view]
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:100
                  hpadding:0];
    } else {
      [PEUIUtils placeView:_reauthenticateBtn
                   atTopOf:[self view]
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:100
                  hpadding:0];
    }
    [PEUIUtils placeView:_logoutBtn
              atBottomOf:[self view]
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:100.0
                hpadding:0.0];
  } else {
    [PEUIUtils placeView:_loginBtn
                 atTopOf:[self view]
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:100
                hpadding:0];
    [PEUIUtils placeView:_createAccountBtn
                   below:_loginBtn
                    onto:[self view]
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:10.0
                hpadding:0.0];
    [PEUIUtils placeView:_deleteAllDataBtn
              atBottomOf:[self view]
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:100.0
                hpadding:0.0];
  }
}

#pragma mark - Panels

- (void)makeMainPanel {
  ButtonMaker buttonMaker = [_uitoolkit systemButtonMaker];
  _accountSettingsBtn = [_uitoolkit systemButtonMaker](@"Account Settings", nil, nil);
  [[_accountSettingsBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:_accountSettingsBtn ofWidth:1.0 relativeTo:[self view]];
  [PEUIUtils addDisclosureIndicatorToButton:_accountSettingsBtn];
  [_accountSettingsBtn bk_addEventHandler:^(id sender) {
    [PEUIUtils displayController:[_screenToolkit newUserAccountDetailScreenMaker](_user) fromController:self animated:YES];
  } forControlEvents:UIControlEventTouchUpInside];
  _reauthenticateBtn = [_uitoolkit systemButtonMaker](@"Re-authenticate", nil, nil);
  [[_reauthenticateBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:_reauthenticateBtn ofWidth:1.0 relativeTo:[self view]];
  [PEUIUtils addDisclosureIndicatorToButton:_reauthenticateBtn];
  [_reauthenticateBtn bk_addEventHandler:^(id sender) {
    [self presentReauthenticateScreen];
  } forControlEvents:UIControlEventTouchUpInside];
  _logoutBtn = buttonMaker(@"Log Out", self, @selector(logout));
  [[_logoutBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:_logoutBtn ofWidth:1.0 relativeTo:[self view]];
  _loginBtn = [_uitoolkit systemButtonMaker](@"Log In", nil, nil);
  [[_loginBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:_loginBtn ofWidth:1.0 relativeTo:[self view]];
  [PEUIUtils addDisclosureIndicatorToButton:_loginBtn];
  [_loginBtn bk_addEventHandler:^(id sender) {
    [self presentLoginScreen];
  } forControlEvents:UIControlEventTouchUpInside];
  _createAccountBtn = [_uitoolkit systemButtonMaker](@"Create Account", nil, nil);
  [[_createAccountBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:_createAccountBtn ofWidth:1.0 relativeTo:[self view]];
  [PEUIUtils addDisclosureIndicatorToButton:_createAccountBtn];
  [_createAccountBtn bk_addEventHandler:^(id sender) {
    [self presentSetupRemoteAccountScreen];
  } forControlEvents:UIControlEventTouchUpInside];
  _deleteAllDataBtn = buttonMaker(@"Delete All Data", self, @selector(clearAllData));
  [[_deleteAllDataBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:_deleteAllDataBtn ofWidth:1.0 relativeTo:[self view]];
}

#pragma mark - Clear All Data

- (void)clearAllData {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Are you sure?"
                                                                 message:@"This will permanently delete all your data."
                                                          preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel."
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *action) {}];
  UIAlertAction *okay = [UIAlertAction actionWithTitle:@"Yes.  Delete my data."
                                                 style:UIAlertActionStyleDestructive
                                               handler:^(UIAlertAction *action) {
                                                 [_coordDao resetAsLocalUser:_user error:[FPUtils localSaveErrorHandlerMaker]()];
                                                 [[NSNotificationCenter defaultCenter] postNotificationName:FPAppDeleteAllDataNotification
                                                                                                     object:nil
                                                                                                   userInfo:nil];
                                                 MBProgressHUD *_HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                                 _HUD.delegate = self;
                                                 [_HUD setLabelText:@"Data deleted successfully."];
                                                 UIImage *image = [UIImage imageNamed:@"hud-complete"];
                                                 UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
                                                 [_HUD setCustomView:imageView];
                                                 _HUD.mode = MBProgressHUDModeCustomView;
                                                 [_HUD hide:YES afterDelay:1.30];
                                               }];
  [alert addAction:cancel];
  [alert addAction:okay];
  [self presentViewController:alert animated:YES completion:nil];
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
  // TODO - check to see if there are any unsynced records in main_* tables, and
  // if any exist, alert the user, as a logout would blow them away, and his/her
  // edits would be lost
  
  void (^postAuthTokenNoMatterWhat)(void) = ^{
    dispatch_async(dispatch_get_main_queue(), ^{
      [APP clearKeychain];
      [_coordDao resetAsLocalUser:_user error:[FPUtils localSaveErrorHandlerMaker]()];
      [[NSNotificationCenter defaultCenter] postNotificationName:FPAppLogoutNotification
                                                          object:nil
                                                        userInfo:nil];
      UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Logout Successful"
                                                                     message:@"You have been logged out succesfully.  All of your data has been removed from this device.  If you log in, your data will be re-downloaded."
                                                              preferredStyle:UIAlertControllerStyleAlert];
      UIAlertAction *okay = [UIAlertAction actionWithTitle:@"Okay."
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                     [self viewDidAppear:YES];
                                                   }];
      [alert addAction:okay];
      [self presentViewController:alert animated:YES completion:nil];
    });
  };
  // even if the remote authentication token deletion fails, we don't care; we'll still
  // tell the user that logout was successful.  The server should have the smarts to eventually delete
  // the token from its database based on a set of rules anyway (e.g., natural expiration date, or,
  // invalidation after N-amount of inactivity, etc)
  [_coordDao deleteRemoteAuthenticationTokenWithRemoteStoreBusy:^(NSDate *retryAfter) {
    postAuthTokenNoMatterWhat();
  } addlCompletionHandler:^{ postAuthTokenNoMatterWhat(); }];
}

#pragma mark - Edit Mode

- (void)putInEditMode {
}

@end
