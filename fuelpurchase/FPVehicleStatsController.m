//
//  FPVehicleStatsController.m
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 10/18/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "FPVehicleStatsController.h"
#import <PEFuelPurchase-Model/FPStats.h>
#import "FPUtils.h"
#import "FPUIUtils.h"

NSString * const FPVehicleStatsTextIfNilStat = @"---";

@implementation FPVehicleStatsController {
  FPCoordinatorDao *_coordDao;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  FPUser *_user;
  FPVehicle *_vehicle;
  FPStats *_stats;
  UIView *_gasCostPerMileTable;
  UIView *_spentOnGasTable;
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
    _currentYear = [FPUtils currentYear];
    _currencyFormatter = [FPUtils currencyFormatter];
  }
  return self;
}

#pragma mark - Helpers

- (UIView *)headerPanelWithText:(NSString *)headerText {
  return [PEUIUtils leftPadView:[PEUIUtils labelWithKey:headerText
                                                   font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                        backgroundColor:[UIColor clearColor]
                                              textColor:[UIColor darkGrayColor]
                                    verticalTextPadding:3.0
                                             fitToWidth:self.view.frame.size.width - 15.0]
                        padding:8.0];
}

- (UIView *)gasCostPerMileTable {
  return [FPUIUtils dataPanelWithRowData:@[@[[NSString stringWithFormat:@"%ld YTD", (long)_currentYear], [FPUIUtils textForDecimal:[_stats yearToDateGasCostPerMileForVehicle:_vehicle]
                                                                                                                        formatter:_currencyFormatter
                                                                                                                        textIfNil:FPVehicleStatsTextIfNilStat]],
                                           @[[NSString stringWithFormat:@"%ld", (long)_currentYear-1], [FPUIUtils textForDecimal:[_stats lastYearGasCostPerMileForVehicle:_vehicle]
                                                                                                                      formatter:_currencyFormatter
                                                                                                                      textIfNil:FPVehicleStatsTextIfNilStat]],
                                           @[@"All time", [FPUIUtils textForDecimal:[_stats overallGasCostPerMileForVehicle:_vehicle]
                                                                          formatter:_currencyFormatter
                                                                          textIfNil:FPVehicleStatsTextIfNilStat]]]
                               uitoolkit:_uitoolkit
                              parentView:self.view];
}

- (UIView *)spentOnGasTable {
  return [FPUIUtils dataPanelWithRowData:@[@[[NSString stringWithFormat:@"%ld YTD", (long)_currentYear], [FPUIUtils textForDecimal:[_stats yearToDateSpentOnGasForVehicle:_vehicle]
                                                                                                                         formatter:_currencyFormatter
                                                                                                                         textIfNil:FPVehicleStatsTextIfNilStat]],
                                           @[[NSString stringWithFormat:@"%ld", (long)_currentYear-1], [FPUIUtils textForDecimal:[_stats lastYearSpentOnGasForVehicle:_vehicle]
                                                                                                                       formatter:_currencyFormatter
                                                                                                                       textIfNil:FPVehicleStatsTextIfNilStat]],
                                           @[@"All time", [FPUIUtils textForDecimal:[_stats totalSpentOnGasForVehicle:_vehicle]
                                                                          formatter:_currencyFormatter
                                                                          textIfNil:FPVehicleStatsTextIfNilStat]]]
                               uitoolkit:_uitoolkit
                              parentView:self.view];
}

#pragma mark - View controller lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  [self setTitle:@"Vehicle Stats"];
  UIView *gasCostPerMileHeader = [self headerPanelWithText:@"GAS COST PER MILE"];
  _gasCostPerMileTable = [self gasCostPerMileTable];
  
  UIView *spentOnHeader = [self headerPanelWithText:@"TOTAL SPENT ON GAS"];
  _spentOnGasTable = [self spentOnGasTable];
  
  // place the views
  [PEUIUtils placeView:gasCostPerMileHeader atTopOf:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:90.0 hpadding:0.0];
  [PEUIUtils placeView:_gasCostPerMileTable below:gasCostPerMileHeader onto:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:4.0 hpadding:0.0];
  [PEUIUtils placeView:spentOnHeader below:_gasCostPerMileTable onto:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:20.0 hpadding:0.0];
  [PEUIUtils placeView:_spentOnGasTable below:spentOnHeader onto:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:4.0 hpadding:0.0];
}

- (void)viewDidAppear:(BOOL)animated {
  NSLog(@"viewDidAppear called");
  [super viewDidAppear:animated];
  // remove the views
  CGRect gasCostPerMileTableFrame = _gasCostPerMileTable.frame;
  CGRect spentOnGasTableFrame = _spentOnGasTable.frame;
  [_gasCostPerMileTable removeFromSuperview];
  [_spentOnGasTable removeFromSuperview];
  
  // refresh their data
  _gasCostPerMileTable = [self gasCostPerMileTable];
  _spentOnGasTable = [self spentOnGasTable];
  
  // re-add them
  _gasCostPerMileTable.frame = gasCostPerMileTableFrame;
  _spentOnGasTable.frame = spentOnGasTableFrame;
  [self.view addSubview:_gasCostPerMileTable];
  [self.view addSubview:_spentOnGasTable];
}

@end
