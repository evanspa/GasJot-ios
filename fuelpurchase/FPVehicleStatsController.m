//
//  FPVehicleStatsController.m
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 10/18/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "FPVehicleStatsController.h"
#import <PEFuelPurchase-Model/FPStats.h>
#import <PEObjc-Commons/PEUtils.h>
#import <PEObjc-Commons/PEUIUtils.h>
#import "FPUtils.h"
#import "FPUIUtils.h"
#import <BlocksKit/UIControl+BlocksKit.h>
#import "FPVehicleSpentOnGasController.h"
#import "UIColor+FPAdditions.h"

@implementation FPVehicleStatsController {
  FPCoordinatorDao *_coordDao;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  FPUser *_user;
  FPVehicle *_vehicle;
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
  }
  return self;
}

#pragma mark - View controller lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  [self setTitle:@"Vehicle Stats & Trends"];  
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
  UIButton *gasCostPerMileBtn = [_uitoolkit systemButtonMaker](@"Gas cost per mile", nil, nil);
  [PEUIUtils setFrameWidthOfView:gasCostPerMileBtn ofWidth:1.0 relativeTo:self.view];
  [PEUIUtils addDisclosureIndicatorToButton:gasCostPerMileBtn];
  [gasCostPerMileBtn bk_addEventHandler:^(id sender) {
    UIViewController *gasCostPerMileScreen = [_screenToolkit newVehicleGasCostPerMileStatsScreenMakerWithVehicle:_vehicle](_user);
    [self.navigationController pushViewController:gasCostPerMileScreen animated:YES];
  } forControlEvents:UIControlEventTouchUpInside];
  UILabel *gasCostPerMileMsg = [PEUIUtils labelWithKey:@"Stats and trend information on the average cost of a mile.  \
The cost of a mile is calculated by dividing the total amount spent on gas by the total number of recorded miles driven (from odometer logs)."
                                                  font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                       backgroundColor:[UIColor clearColor]
                                             textColor:[UIColor darkGrayColor]
                                   verticalTextPadding:3.0
                                            fitToWidth:self.view.frame.size.width - 15.0];
  
  UIButton *spentOnGasBtn = [_uitoolkit systemButtonMaker](@"Amount spent on gas", nil, nil);
  [PEUIUtils setFrameWidthOfView:spentOnGasBtn ofWidth:1.0 relativeTo:self.view];
  [PEUIUtils addDisclosureIndicatorToButton:spentOnGasBtn];
  [spentOnGasBtn bk_addEventHandler:^(id sender) {
    FPVehicleSpentOnGasController *spentOnGasScreen =
    [[FPVehicleSpentOnGasController alloc] initWithStoreCoordinator:_coordDao
                                                               user:_user
                                                            vehicle:_vehicle
                                                          uitoolkit:_uitoolkit
                                                      screenToolkit:_screenToolkit];
    [self.navigationController pushViewController:spentOnGasScreen animated:YES];
  } forControlEvents:UIControlEventTouchUpInside];
  NSAttributedString *spentOnGasMsgText = [PEUIUtils attributedTextWithTemplate:@"Stats and trend information on the total amount spent on gas:\n(per price gallon %@ number of gallons)."
                                                                   textToAccent:@"x"
                                                                 accentTextFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]];
  UILabel *spentOnGasMsg = [PEUIUtils labelWithAttributeText:spentOnGasMsgText
                                                        font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                    fontForHeightCalculation:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]
                                             backgroundColor:[UIColor clearColor]
                                                   textColor:[UIColor darkGrayColor]
                                         verticalTextPadding:3.0
                                                  fitToWidth:self.view.frame.size.width - 15.0];
  
  // place the views
  [PEUIUtils placeView:vehicleLabel atTopOf:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:80.0 hpadding:8.0];
  [PEUIUtils placeView:gasCostPerMileBtn below:vehicleLabel onto:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:self.view vpadding:20.0 hpadding:0.0];
  [PEUIUtils placeView:gasCostPerMileMsg below:gasCostPerMileBtn onto:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:4.0 hpadding:8.0];
  [PEUIUtils placeView:spentOnGasBtn below:gasCostPerMileMsg onto:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:self.view vpadding:20.0 hpadding:0.0];
  [PEUIUtils placeView:spentOnGasMsg below:spentOnGasBtn onto:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:4.0 hpadding:8.0];
}

@end
