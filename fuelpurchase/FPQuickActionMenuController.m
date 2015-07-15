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
  dispatch_queue_t _junkQueue;
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
    _junkQueue = dispatch_queue_create("name.paulevans.fuelpurchase.debug.computecoord",
                                                       DISPATCH_QUEUE_SERIAL);
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
                  vpadding:70.0
                  hpadding:5.0];
    } else {
      [PEUIUtils placeView:_unsyncedStatusButton
                   atTopOf:self.view
             withAlignment:PEUIHorizontalAlignmentTypeRight
                  vpadding:70.0
                  hpadding:5.0];
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
  UIImage *syncronizationIcon = [UIImage syncableIcon];
  UIImage *unsynchronizationIcon = [UIImage unsyncableIcon];
  CGFloat btnLength = 45.0;
  _syncedStatusButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, btnLength, btnLength)];
  [_syncedStatusButton setBackgroundColor:[UIColor clearColor]];
  [_syncedStatusButton setImage:syncronizationIcon forState:UIControlStateNormal];
  [_syncedStatusButton addTarget:self
                          action:@selector(synchronziationStatusInfo)
                forControlEvents:UIControlEventTouchUpInside];
  _unsyncedStatusButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, btnLength, btnLength)];
  [_unsyncedStatusButton setBackgroundColor:[UIColor clearColor]];
  [_unsyncedStatusButton setImage:unsynchronizationIcon forState:UIControlStateNormal];
  [_unsyncedStatusButton addTarget:self
                            action:@selector(unsynchronizationStatusInfo)
                  forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Button Event Handlers

- (void)synchronziationStatusInfo {
  [PEUIUtils showAlertWithTitle:@"You're logged in."
                     titleImage:[UIImage syncable]
               alertDescription:[[NSAttributedString alloc] initWithString:@"\
You are currently logged in, and this\n\
device is connected to your remote account."]
                    buttonTitle:@"Okay."
                   buttonAction:nil
                 relativeToView:self.tabBarController.view];
}

- (void)unsynchronizationStatusInfo {
  NSString *message = @"\
Although this device is connected to\n\
your remote account, your edits are\n\
not able to sync because you need to\n\
re-authenticate. To re-authenticate, go to:\n\n\
Settings \u2794 Re-authenticate.";
  NSDictionary *attrs = @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0] };
  NSMutableAttributedString *attrMessage = [[NSMutableAttributedString alloc] initWithString:message];
  [attrMessage setAttributes:attrs range:NSMakeRange(155, 26)];
  [PEUIUtils showAlertWithTitle:@"Unable to sync."
                     titleImage:[UIImage unsyncable]
               alertDescription:attrMessage
                    buttonTitle:@"Okay."
                   buttonAction:nil
                 relativeToView:self.tabBarController.view];
}

- (void)clearKeychain {
  [APP clearKeychain];
}

- (void)systemPrune {
  // TODO incorporate a HUD into this
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
