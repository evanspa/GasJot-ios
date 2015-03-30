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
#import "FPQuickActionMenuController.h"
#import "FPScreenToolkit.h"
#import "FPEditActors.h"
#import "FPUtils.h"

#ifdef FP_DEV
  #import <PEDev-Console/UIViewController+devconsole.h>
#endif

@implementation FPQuickActionMenuController {
  FPCoordinatorDao *_coordDao;
  PEUIToolkit *_uitoolkit;
  TLTransactionManager *_txnMgr;
  NSString *_notificationMsgOrKey;
  FPUser *_user;
  FPScreenToolkit *_screenToolkit;
  dispatch_queue_t _junkQueue;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(FPCoordinatorDao *)coordDao
                          user:(FPUser *)user
              tempNotification:(NSString *)notificationMsgOrKey
            transactionManager:(TLTransactionManager *)txnMgr
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(FPScreenToolkit *)screenToolkit {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _user = user;
    _notificationMsgOrKey = notificationMsgOrKey;
    _coordDao = coordDao;
    _txnMgr = txnMgr;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
    _junkQueue = dispatch_queue_create("name.paulevans.fuelpurchase.debug.computecoord",
                                                       DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

#pragma mark - View Controller Lifecycle

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
    ,btnMaker(@"Remote Sync", self, @selector(remoteSync)),
    btnMaker(@"Txn Flush", self, @selector(txnFlush)),
    btnMaker(@"System Prune", self, @selector(systemPrune))
#endif
  ];
  NSArray *rtBtns = @[
    btnMaker(LS(@"auth.start.reports.btn.txt"), self, @selector(presentReportsSelection)),
    btnMaker(LS(@"auth.start.randreport.btn.txt"), self, @selector(presentRandomReport)),
    btnMaker(LS(@"auth.start.vehicles.btn.txt"), self, @selector(presentVehicles))
#ifdef FP_DEV
    ,btnMaker(@"Geo Coord\nCompute", self, @selector(geoCoordCompute))
#endif
  ];
  UIView *btnsView =
    [PEUIUtils twoColumnViewCluster:leftBtns
                    withRightColumn:rtBtns
        verticalPaddingBetweenViews:5
    horizontalPaddingBetweenColumns:8];
  [PEUIUtils placeView:btnsView
            inMiddleOf:[self view]
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              hpadding:0];
  [PEUIUtils displayTempNotification:_notificationMsgOrKey
                       forController:self
                           uitoolkit:_uitoolkit];
}

#pragma mark - Button Event Handlers

- (void)txnFlush {
  [_txnMgr synchronousFlushTxnsToRemoteStoreWithRemoteStoreBusyBlock:nil];
  [PEUIUtils displayTempNotification:@"Txn flush to remote done." forController:self uitoolkit:_uitoolkit];
}

- (void)geoCoordCompute {
  dispatch_async(_junkQueue, ^{
    [_coordDao computeOfFuelStationCoordsWithEditActorId:@(FPBackgroundActorId)
                                                   error:[FPUtils localDatabaseErrorHudHandlerMaker](nil)];
  });
  [PEUIUtils displayTempNotification:@"Geo coordinate compute started." forController:self uitoolkit:_uitoolkit];
}

- (void)remoteSync {
  [_coordDao flushToRemoteMasterWithEditActorId:@(FPBackgroundActorId)
                             remoteStoreBusyBlk:[FPUtils serverBusyHandlerMakerForUI](nil)
                                          error:[FPUtils localDatabaseErrorHudHandlerMaker](nil)];
  [PEUIUtils displayTempNotification:@"Flush to remote master done." forController:self uitoolkit:_uitoolkit];
}

- (void)systemPrune {
  [_coordDao pruneAllSyncedEntitiesWithError:[FPUtils localDatabaseErrorHudHandlerMaker](nil)];
  [PEUIUtils displayTempNotification:@"System prune done."
                       forController:self
                           uitoolkit:_uitoolkit];
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
    [[addViewEditCtrl navigationController] dismissViewControllerAnimated:YES completion:^{
      [PEUIUtils displayTempNotification:@"Fuel Purchase Log Saved Locally"
                           forController:self
                               uitoolkit:_uitoolkit];
    }];
  };
  UIViewController *addFpLogCtrl =
    [_screenToolkit newAddFuelPurchaseLogScreenMakerWithBlk:itemAddedBlk
                                     defaultSelectedVehicle:[_coordDao defaultVehicleForNewFuelPurchaseLogForUser:_user error:[FPUtils localFetchErrorHandlerMaker]()]
                                 defaultSelectedFuelStation:[_coordDao defaultFuelStationForNewFuelPurchaseLogForUser:_user currentLocation:[APP latestLocation] error:[FPUtils localFetchErrorHandlerMaker]()]
                                         listViewController:nil](_user);
  [self presentViewController:[PEUIUtils navigationControllerWithController:addFpLogCtrl
                                                        navigationBarHidden:NO]
                     animated:YES
                   completion:nil];
}

- (void)presentLogEnvInput {
  PEItemAddedBlk itemAddedBlk = ^(PEAddViewEditController *addViewEditCtrl, FPEnvironmentLog *envLog) {
    [[addViewEditCtrl navigationController] dismissViewControllerAnimated:YES completion:^{
      [PEUIUtils displayTempNotification:@"Environment Log Saved Locally"
                           forController:self
                               uitoolkit:_uitoolkit];
    }];
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
