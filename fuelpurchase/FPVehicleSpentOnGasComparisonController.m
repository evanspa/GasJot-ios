//
//  FPVehicleSpentOnGasComparisonController.m
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 10/20/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "FPVehicleSpentOnGasComparisonController.h"
#import <PEFuelPurchase-Model/FPStats.h>
#import <PEObjc-Commons/PEUtils.h>
#import <PEObjc-Commons/PEUIUtils.h>
#import <BlocksKit/UIControl+BlocksKit.h>
#import "FPUtils.h"
#import "FPUIUtils.h"
#import "UIColor+FPAdditions.h"

NSString * const FPVehicleSpentOnGasComparisonTextIfNilStat = @"---";

@implementation FPVehicleSpentOnGasComparisonController {
  FPCoordinatorDao *_coordDao;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  FPUser *_user;
  FPVehicle *_vehicle;
  FPStats *_stats;
  UIView *_spentOnGasComparisonTable;
  NSInteger _currentYear;
  NSNumberFormatter *_currencyFormatter;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(FPCoordinatorDao *)coordDao
                          user:(FPUser *)user
                       vehicle:(FPVehicle *)vehicle
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(FPScreenToolkit *)screenToolkit {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _user = user;
    _vehicle = vehicle;
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
    _stats = [[FPStats alloc] initWithLocalDao:_coordDao.localDao errorBlk:[FPUtils localFetchErrorHandlerMaker]()];
    _currentYear = [PEUtils currentYear];
    _currencyFormatter = [PEUtils currencyFormatter];
  }
  return self;
}

#pragma mark - Helpers

- (UIView *)spentOnGasComparisonTable {
  NSMutableArray *rowData = [NSMutableArray array];
  NSMutableArray *nilRowData = [NSMutableArray array];
  NSArray *vehicles = [_coordDao vehiclesForUser:_user error:[FPUtils localFetchErrorHandlerMaker]()];
  for (FPVehicle *vehicle in vehicles) {
    NSDecimalNumber *spentOnGas = [_stats totalSpentOnGasForVehicle:vehicle];
    id vehicleName;
    if ([vehicle isEqualToVehicle:_vehicle]) {
      vehicleName = [PEUIUtils attributedTextWithTemplate:@"%@"
                                             textToAccent:vehicle.name
                                           accentTextFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]
                                          accentTextColor:[UIColor fpAppBlue]];
    } else {
      vehicleName = vehicle.name;
    }
    if (spentOnGas) {
      [rowData addObject:@[vehicleName, [_currencyFormatter stringFromNumber:spentOnGas]]];
    } else {
      [nilRowData addObject:@[vehicleName, FPVehicleSpentOnGasComparisonTextIfNilStat]];
    }
  }
  [rowData sortUsingComparator:^NSComparisonResult(NSArray *o1, NSArray *o2) {
    NSDecimalNumber *v1 = o1[1];
    NSDecimalNumber *v2 = o2[1];
    return [v1 compare:v2];
  }];
  return [PEUIUtils tablePanelWithRowData:[rowData arrayByAddingObjectsFromArray:nilRowData]
                                uitoolkit:_uitoolkit
                               parentView:self.view];
}

#pragma mark - View controller lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  [[self navigationItem] setTitleView:[PEUIUtils labelWithKey:@"Amount Spent on Gas Comparison"
                                                         font:[UIFont systemFontOfSize:14.0]
                                              backgroundColor:[UIColor clearColor]
                                                    textColor:[UIColor blackColor]
                                          verticalTextPadding:0.0]];
  UIView *gasCostPerMileHeader = [FPUIUtils headerPanelWithText:@"TOTAL SPENT ON GAS (All time)" relativeToView:self.view];
  _spentOnGasComparisonTable = [self spentOnGasComparisonTable];
  
  // place the views
  [PEUIUtils placeView:gasCostPerMileHeader atTopOf:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:80.0 hpadding:8.0];
  [PEUIUtils placeView:_spentOnGasComparisonTable
                 below:gasCostPerMileHeader
                  onto:self.view
         withAlignment:PEUIHorizontalAlignmentTypeLeft
  alignmentRelativeToView:self.view
              vpadding:8.0
              hpadding:0.0];
  
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  // remove the views
  CGRect spentOnGasTableFrame = _spentOnGasComparisonTable.frame;
  [_spentOnGasComparisonTable removeFromSuperview];
  
  // refresh their data
  _spentOnGasComparisonTable = [self spentOnGasComparisonTable];
  
  // re-add them
  _spentOnGasComparisonTable.frame = spentOnGasTableFrame;
  [self.view addSubview:_spentOnGasComparisonTable];
}

@end
