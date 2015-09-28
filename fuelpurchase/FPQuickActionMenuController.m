// Copyright (C) 2013 Paul Evans
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

#import <FlatUIKit/UIColor+FlatUI.h>
#import <PEObjc-Commons/PEUIUtils.h>
#import <PEObjc-Commons/UIImage+PEAdditions.h>
#import <PEObjc-Commons/UIView+PERoundify.h>
#import "FPQuickActionMenuController.h"
#import "FPScreenToolkit.h"
#import "FPUtils.h"
#import "FPNames.h"

#ifdef FP_DEV
  #import <PEDev-Console/UIViewController+PEDevConsole.h>
#endif

@implementation FPQuickActionMenuController {
  FPCoordinatorDao *_coordDao;
  PEUIToolkit *_uitoolkit;
  FPUser *_user;
  FPScreenToolkit *_screenToolkit;
  UIButton *_syncedStatusButton;
  UIButton *_unsyncedStatusButton;
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

#pragma mark - View Controller Lifecycle

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [_syncedStatusButton removeFromSuperview];
  [_unsyncedStatusButton removeFromSuperview];
  if ([APP isUserLoggedIn]) {
    if ([APP doesUserHaveValidAuthToken]) {
      [PEUIUtils placeView:_syncedStatusButton
                   atTopOf:self.view
             withAlignment:PEUIHorizontalAlignmentTypeRight
                  vpadding:80.0
                  hpadding:0.0];
    } else {
      [PEUIUtils placeView:_unsyncedStatusButton
                   atTopOf:self.view
             withAlignment:PEUIHorizontalAlignmentTypeRight
                  vpadding:80.0
                  hpadding:0.0];
    }
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  #ifdef FP_DEV
    [self pdvDevEnable];
  #endif
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  UINavigationItem *navItem = [self navigationItem];
  [navItem setTitle:LS(@"auth.start.title.txt")];
  ButtonMaker btnMaker = [_uitoolkit primaryButtonMaker];
  NSArray *leftBtns = @[
    btnMaker(LS(@"auth.start.log-fp.btn.txt"), self, @selector(presentLogFPInput)),
    btnMaker(LS(@"auth.start.log-env.btn.txt"), self, @selector(presentLogEnvInput)),
    btnMaker(LS(@"auth.start.fuelstations.btn.txt"), self, @selector(presentFuelStations))
#ifdef FP_DEV
    ,btnMaker(@"Clear Keychain", self, @selector(clearKeychain))
#endif
  ];
  NSArray *rtBtns = @[
    btnMaker(LS(@"auth.start.reports.btn.txt"), self, @selector(presentReportsSelection)),
    btnMaker(LS(@"auth.start.randreport.btn.txt"), self, @selector(presentRandomReport)),
    btnMaker(LS(@"auth.start.vehicles.btn.txt"), self, @selector(presentVehicles))
#ifdef FP_DEV
    ,btnMaker(@"System Prune", self, @selector(systemPrune))
#endif
  ];
  UIView *btnsView = [PEUIUtils twoColumnViewCluster:leftBtns
                                     withRightColumn:rtBtns
                         verticalPaddingBetweenViews:5
                     horizontalPaddingBetweenColumns:8];
  [PEUIUtils placeView:btnsView
            inMiddleOf:[self view]
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              hpadding:0];
  _syncedStatusButton = [self syncStatusButtonWithImage:[UIImage syncableIcon]
                                                 action:@selector(synchronziationStatusInfo)];
  _unsyncedStatusButton = [self syncStatusButtonWithImage:[UIImage unsyncableIcon]
                                                   action:@selector(unsynchronizationStatusInfo)];
}

#pragma mark - Helpers

- (UIButton *)syncStatusButtonWithImage:(UIImage *)image
                                 action:(SEL)action {
  UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 45.0, 35.0)];
  [button setBackgroundColor:[UIColor whiteColor]];
  [button addRoundedCorners:UIRectCornerTopLeft|UIRectCornerBottomLeft
                  withRadii:CGSizeMake(5.0, 5.0)];
  [button setImage:image forState:UIControlStateNormal];
  [button addTarget:self
             action:action
   forControlEvents:UIControlEventTouchUpInside];
  return button;
}

#pragma mark - Button Event Handlers

- (void)synchronziationStatusInfo {
  [PEUIUtils showAlertWithTitle:@"FYI you are logged in."
                     titleImage:[UIImage syncable]
               alertDescription:[[NSAttributedString alloc] initWithString:@"\
Just letting you know you're currently\n\
logged in, and that this device is\n\
connected to your remote account."]
                       topInset:70.0
                    buttonTitle:@"Okay."
                   buttonAction:nil
                 relativeToView:self.tabBarController.view];
}

- (void)unsynchronizationStatusInfo {
  NSString *instructionText = @"Account \u2794 Re-authenticate";
  NSString *message = [NSString stringWithFormat:@"\
Just letting you know that although this \
device is connected to your remote account, \
your edits are not able to sync because you \
need to re-authenticate. \
To re-authenticate, go to:\n\n\
%@.", instructionText];
  NSDictionary *attrs = @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:[UIFont systemFontSize]] };
  NSMutableAttributedString *attrMessage = [[NSMutableAttributedString alloc] initWithString:message];
  [attrMessage setAttributes:attrs range:[message rangeOfString:instructionText]];
  [PEUIUtils showAlertWithTitle:@"Heads up!  You are currently unable to sync."
                     titleImage:[UIImage unsyncable]
               alertDescription:attrMessage
                       topInset:70.0
                    buttonTitle:@"Okay."
                   buttonAction:nil
                 relativeToView:self.tabBarController.view];
}

- (void)clearKeychain {
  [APP clearKeychain];
}

- (void)systemPrune {
  [_coordDao pruneAllSyncedEntitiesWithError:[FPUtils localDatabaseErrorHudHandlerMaker](nil, self.view)];  
}

- (void)presentVehicles {
  [PEUIUtils displayController:[_screenToolkit newViewVehiclesScreenMaker](_user)
                fromController:self
                      animated:YES];
}

- (void)presentFuelStations {
  [PEUIUtils displayController:[_screenToolkit newViewFuelStationsScreenMaker](_user)
                fromController:self
                      animated:YES];
}

- (void)presentLogFPInput {
  PEItemAddedBlk itemAddedBlk = ^(PEAddViewEditController *addViewEditCtrl, FPFuelPurchaseLog *fpLog) {
    [[addViewEditCtrl navigationController] dismissViewControllerAnimated:YES completion:nil];
  };
  UIViewController *addFpLogCtrl =
    [_screenToolkit newAddFuelPurchaseLogScreenMakerWithBlk:itemAddedBlk
                                     defaultSelectedVehicle:[_coordDao defaultVehicleForNewFuelPurchaseLogForUser:_user
                                                                                                            error:[FPUtils localFetchErrorHandlerMaker]()]
                                 defaultSelectedFuelStation:[_coordDao defaultFuelStationForNewFuelPurchaseLogForUser:_user
                                                                                                      currentLocation:[APP latestLocation]
                                                                                                                error:[FPUtils localFetchErrorHandlerMaker]()]
                                         listViewController:nil](_user);
  [self presentViewController:[PEUIUtils navigationControllerWithController:addFpLogCtrl
                                                        navigationBarHidden:NO]
                     animated:YES
                   completion:nil];
}

- (void)presentLogEnvInput {
  PEItemAddedBlk itemAddedBlk = ^(PEAddViewEditController *addViewEditCtrl, FPEnvironmentLog *envLog) {
    [[addViewEditCtrl navigationController] dismissViewControllerAnimated:YES completion:nil];
  };
  UIViewController *addEnvLogCtrl =
    [_screenToolkit newAddEnvironmentLogScreenMakerWithBlk:itemAddedBlk
                                    defaultSelectedVehicle:[_coordDao defaultVehicleForNewEnvironmentLogForUser:_user error:[FPUtils localFetchErrorHandlerMaker]()]
                                        listViewController:nil](_user);
  [self presentViewController:[PEUIUtils navigationControllerWithController:addEnvLogCtrl
                                                        navigationBarHidden:NO]
                     animated:YES
                   completion:nil];
}

- (void)presentReportsSelection {
}

- (void)presentRandomReport {
}

@end
