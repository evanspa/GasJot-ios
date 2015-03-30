//
//  FPSettingsController.m
//  fuelpurchase
//
//  Created by Evans, Paul on 9/15/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPSettingsController.h"
#import <PEObjc-Commons/PEUIUtils.h>

#ifdef FP_DEV
  #import <PEDev-Console/UIViewController+devconsole.h>
#endif

@implementation FPSettingsController {
  FPCoordinatorDao *_coordDao;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  TLTransactionManager *_txnMgr;
  FPUser *_user;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(FPCoordinatorDao *)coordDao
                          user:(FPUser *)user
            transactionManager:(TLTransactionManager *)txnMgr
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(FPScreenToolkit *)screenToolkit {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _user = user;
    _coordDao = coordDao;
    _txnMgr = txnMgr;
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
  [navItem setRightBarButtonItem:[[UIBarButtonItem alloc]
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                       target:self
                                                       action:@selector(putInEditMode)]];
  [self makeMainPanel];
}

#pragma mark - Panels

- (void)makeMainPanel {
  ButtonMaker buttonMaker = [_uitoolkit systemButtonMaker];
  UIButton *logoutBtn = buttonMaker(@"Logout", self, @selector(logout));
  [[logoutBtn layer] setCornerRadius:0.0];
  [PEUIUtils placeView:logoutBtn
               atTopOf:[self view]
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:100
              hpadding:0];
    [PEUIUtils setFrameWidthOfView:logoutBtn ofWidth:1.0 relativeTo:[self view]];
}

#pragma mark - Logout

- (void)logout {
  
  // TODO - check to see if there are any unsynced records in main_* tables, and
  // if any exist, alert the user, as a logout would blow them away, and his/her
  // edits would be lost  
  
  __block BOOL wasError = NO;
  PELMDaoErrorBlk errorBlk = ^(NSError *err, int code, NSString *msg) {
    wasError = YES;
    [PEUIUtils showAlertWithMsgs:@[[err localizedDescription]]
                           title:@"Error Attempting to Logout"
                     buttonTitle:@"Cancel"];
  };
  [_coordDao logoutUser:_user error:errorBlk];
  [_txnMgr deleteAllTransactionsInTxnWithError:errorBlk];
  if (!wasError) {
    UIViewController *unauthHome =
      [_screenToolkit newUnauthLandingScreenMakerWithTempNotification:@"Logout Successful"]();
    [[[[UIApplication sharedApplication] delegate] window] setRootViewController:unauthHome];
  }
}

#pragma mark - Edit Mode

- (void)putInEditMode {
}

@end
