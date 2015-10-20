//
//  FPVehicleSpentOnGasController.m
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 10/18/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "FPVehicleSpentOnGasController.h"
#import <PEFuelPurchase-Model/FPStats.h>
#import <PEObjc-Commons/PEUtils.h>
#import <PEObjc-Commons/PEUIUtils.h>
#import "FPUtils.h"
#import "FPUIUtils.h"

NSString * const FPVehicleSpentOnGasTextIfNilStat = @"---";

@implementation FPVehicleSpentOnGasController {
  FPCoordinatorDao *_coordDao;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  FPUser *_user;
  FPVehicle *_vehicle;
  FPStats *_stats;
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
    _currentYear = [PEUtils currentYear];
    _currencyFormatter = [PEUtils currencyFormatter];
  }
  return self;
}

#pragma mark - Helpers

- (UIView *)spentOnGasTable {
  return [PEUIUtils tablePanelWithRowData:@[@[[NSString stringWithFormat:@"%ld YTD", (long)_currentYear], [PEUtils textForDecimal:[_stats yearToDateSpentOnGasForVehicle:_vehicle]
                                                                                                                         formatter:_currencyFormatter
                                                                                                                         textIfNil:FPVehicleSpentOnGasTextIfNilStat]],
                                           @[[NSString stringWithFormat:@"%ld", (long)_currentYear-1], [PEUtils textForDecimal:[_stats lastYearSpentOnGasForVehicle:_vehicle]
                                                                                                                       formatter:_currencyFormatter
                                                                                                                       textIfNil:FPVehicleSpentOnGasTextIfNilStat]],
                                           @[@"All time", [PEUtils textForDecimal:[_stats totalSpentOnGasForVehicle:_vehicle]
                                                                          formatter:_currencyFormatter
                                                                          textIfNil:FPVehicleSpentOnGasTextIfNilStat]]]
                               uitoolkit:_uitoolkit
                              parentView:self.view];
}

#pragma mark - View controller lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  [self setTitle:@"Vehicle Stats & Trends"];  
  NSAttributedString *vehicleHeaderText = [PEUIUtils attributedTextWithTemplate:@"(vehicle: %@)"
                                                                   textToAccent:_vehicle.name
                                                                 accentTextFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]];
  UILabel *vehicleLabel = [PEUIUtils labelWithAttributeText:vehicleHeaderText
                                                       font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                   fontForHeightCalculation:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]
                                            backgroundColor:[UIColor clearColor]
                                                  textColor:[UIColor darkGrayColor]
                                        verticalTextPadding:3.0
                                                 fitToWidth:self.view.frame.size.width - 15.0];
  UIView *vehicleLabelPanel = [PEUIUtils leftPadView:vehicleLabel padding:8.0];
  [PEUIUtils setFrameWidthOfView:vehicleLabelPanel ofWidth:1.0 relativeTo:self.view];
  UIView *spentOnHeader = [FPUIUtils headerPanelWithText:@"TOTAL SPENT ON GAS" relativeToView:self.view];
  _spentOnGasTable = [self spentOnGasTable];
  // place the views
  [PEUIUtils placeView:vehicleLabelPanel atTopOf:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:75.0 hpadding:0.0];
  [PEUIUtils placeView:spentOnHeader below:vehicleLabelPanel onto:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:20.0 hpadding:0.0];
  [PEUIUtils placeView:_spentOnGasTable below:spentOnHeader onto:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:4.0 hpadding:0.0];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  // remove the views
  CGRect spentOnGasTableFrame = _spentOnGasTable.frame;
  [_spentOnGasTable removeFromSuperview];
  
  // refresh their data
  _spentOnGasTable = [self spentOnGasTable];
  
  // re-add them
  _spentOnGasTable.frame = spentOnGasTableFrame;
  [self.view addSubview:_spentOnGasTable];
}

@end
