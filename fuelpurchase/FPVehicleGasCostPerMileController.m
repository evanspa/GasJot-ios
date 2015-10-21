//
//  FPVehicleGasCostPerMileController.m
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 10/20/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "FPVehicleGasCostPerMileController.h"
#import <PEFuelPurchase-Model/FPStats.h>
#import <PEObjc-Commons/PEUtils.h>
#import <PEObjc-Commons/PEUIUtils.h>
#import <BlocksKit/UIControl+BlocksKit.h>
#import "FPUtils.h"
#import "FPUIUtils.h"
#import "FPVehicleGasCostPerMileComparisonController.h"
#import "UIColor+FPAdditions.h"

NSString * const FPVehicleGasCostPerMileTextIfNilStat = @"---";

@implementation FPVehicleGasCostPerMileController {
  FPCoordinatorDao *_coordDao;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  FPUser *_user;
  FPVehicle *_vehicle;
  FPStats *_stats;
  UIView *_gasCostPerMileTable;
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

- (UIView *)gasCostPerMileTable {
  return [PEUIUtils tablePanelWithRowData:@[@[[NSString stringWithFormat:@"%ld YTD", (long)_currentYear], [PEUtils textForDecimal:[_stats yearToDateGasCostPerMileForVehicle:_vehicle]
                                                                                                                        formatter:_currencyFormatter
                                                                                                                        textIfNil:FPVehicleGasCostPerMileTextIfNilStat]],
                                            @[[NSString stringWithFormat:@"%ld", (long)_currentYear-1], [PEUtils textForDecimal:[_stats lastYearGasCostPerMileForVehicle:_vehicle]
                                                                                                                      formatter:_currencyFormatter
                                                                                                                      textIfNil:FPVehicleGasCostPerMileTextIfNilStat]],
                                            @[@"All time", [PEUtils textForDecimal:[_stats overallGasCostPerMileForVehicle:_vehicle]
                                                                         formatter:_currencyFormatter
                                                                         textIfNil:FPVehicleGasCostPerMileTextIfNilStat]]]
                                uitoolkit:_uitoolkit
                               parentView:self.view];
}

#pragma mark - View controller lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  [self setTitle:@"Gas Cost per Mile"];
  NSAttributedString *vehicleHeaderText = [PEUIUtils attributedTextWithTemplate:@"(vehicle: %@)"
                                                                   textToAccent:_vehicle.name
                                                                 accentTextFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]
                                                                accentTextColor:[UIColor fpAppBlue]];
  UILabel *vehicleLabel = [PEUIUtils labelWithAttributeText:vehicleHeaderText
                                                       font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                   fontForHeightCalculation:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]
                                            backgroundColor:[UIColor clearColor]
                                                  textColor:[UIColor darkGrayColor]
                                        verticalTextPadding:3.0
                                                 fitToWidth:self.view.frame.size.width - 15.0];
  UIView *gasCostPerMileHeader = [FPUIUtils headerPanelWithText:@"GAS COST PER MILE" relativeToView:self.view];
  _gasCostPerMileTable = [self gasCostPerMileTable];
  
  // place the views
  [PEUIUtils placeView:vehicleLabel atTopOf:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:75.0 hpadding:8.0];
  [PEUIUtils placeView:gasCostPerMileHeader below:vehicleLabel onto:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:self.view vpadding:12.0 hpadding:0.0];
  [PEUIUtils placeView:_gasCostPerMileTable
                 below:gasCostPerMileHeader
                  onto:self.view
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  if ([_coordDao vehiclesForUser:_user error:[FPUtils localFetchErrorHandlerMaker]()].count > 1) {
    UIButton *vehicleCompareBtn = [_uitoolkit systemButtonMaker](@"Compare vehicles", nil, nil);
    [PEUIUtils setFrameWidthOfView:vehicleCompareBtn ofWidth:1.0 relativeTo:self.view];
    [PEUIUtils addDisclosureIndicatorToButton:vehicleCompareBtn];
    [vehicleCompareBtn bk_addEventHandler:^(id sender) {
      FPVehicleGasCostPerMileComparisonController *comparisonScreen =
      [[FPVehicleGasCostPerMileComparisonController alloc] initWithStoreCoordinator:_coordDao
                                                                               user:_user
                                                                            vehicle:_vehicle
                                                                          uitoolkit:_uitoolkit
                                                                      screenToolkit:_screenToolkit];
      [[self navigationController] pushViewController:comparisonScreen animated:YES];
    } forControlEvents:UIControlEventTouchUpInside];
    [PEUIUtils placeView:vehicleCompareBtn
                   below:_gasCostPerMileTable
                    onto:self.view
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:20.0
                hpadding:0.0];
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  // remove the views
  CGRect gasCostPerMileTableFrame = _gasCostPerMileTable.frame;
  [_gasCostPerMileTable removeFromSuperview];
  
  // refresh their data
  _gasCostPerMileTable = [self gasCostPerMileTable];
  
  // re-add them
  _gasCostPerMileTable.frame = gasCostPerMileTableFrame;
  [self.view addSubview:_gasCostPerMileTable];
}

@end
