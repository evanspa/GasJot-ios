//
//  FPEnvLogVehicleAndDateDataSourceDelegate.m
//  fuelpurchase
//
//  Created by Evans, Paul on 10/13/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPEnvLogVehicleAndDateDataSourceDelegate.h"
#import <PEObjc-Commons/PEUIUtils.h>
#import <PEObjc-Commons/PEUtils.h>
#import <PEFuelPurchase-Model/PELMNotificationUtils.h>

@implementation FPEnvLogVehicleAndDateDataSourceDelegate {
  id<FPCoordinatorDao> _coordDao;
  FPScreenToolkit *_screenToolkit;
  PEUIToolkit *_uitoolkit;
  FPUser *_user;
  UIViewController *_controllerCtx;
  PEItemSelectedAction _vehicleSelectedAction;
  void(^_logDatePickedAction)(NSDate *);
  BOOL _displayDisclosureIndicators;
}

#pragma mark - Initializers

- (id)initWithControllerCtx:(UIViewController *)controllerCtx
                    vehicle:(FPVehicle *)vehicle
                    logDate:(NSDate *)logDate
      vehicleSelectedAction:(PEItemSelectedAction)vehicleSelectedAction
        logDatePickedAction:(void(^)(NSDate *))logDatePickedAction
displayDisclosureIndicators:(BOOL)displayDisclosureIndicators
             coordinatorDao:(id<FPCoordinatorDao>)coordDao
                       user:(FPUser *)user
              screenToolkit:(FPScreenToolkit *)screenToolkit
                      error:(PELMDaoErrorBlk)errorBlk {
  self = [super init];
  if (self) {
    _controllerCtx = controllerCtx;
    _coordDao = coordDao;
    _selectedVehicle = vehicle;
    _pickedLogDate = logDate;
    _displayDisclosureIndicators = displayDisclosureIndicators;
    _user = user;
    _screenToolkit = screenToolkit;
    _uitoolkit = [screenToolkit uitoolkit];
    __weak FPEnvLogVehicleAndDateDataSourceDelegate *weakSelf = self;
    _vehicleSelectedAction = ^(FPVehicle *selectedVehicle, NSIndexPath *indexPath, UIViewController *selectionController) {
      [weakSelf setSelectedVehicle:selectedVehicle];
      vehicleSelectedAction(selectedVehicle, indexPath, selectionController);
    };
    _logDatePickedAction = ^(NSDate *pickedDate) {
      [weakSelf setPickedLogDate:pickedDate];
      logDatePickedAction(pickedDate);
    };
  }
  return self;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  switch ([indexPath section]) {
    case 0:
      [PEUIUtils displayController:[_screenToolkit
                                      newVehiclesForSelectionScreenMakerWithItemSelectedAction:_vehicleSelectedAction
                                                                        initialSelectedVehicle:_selectedVehicle](_user)
                    fromController:_controllerCtx
                          animated:YES];
      break;
    default:
      [PEUIUtils displayController:[_screenToolkit
                                    newDatePickerScreenMakerWithTitle:@"Log Date" initialSelectedDate:_pickedLogDate logDatePickedAction:_logDatePickedAction](_user)
                    fromController:_controllerCtx
                          animated:YES];
      break;
  }
}

- (CGFloat)tableView:(UITableView *)tableView
heightForHeaderInSection:(NSInteger)section {
  if (section == 0) {
    return 15;
  }
  return 0;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  switch ([indexPath section]) {
    case 0:  // vehicle
      //return 50;
      return [PEUIUtils sizeOfText:@""
                          withFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleBody]].height +
      _uitoolkit.verticalPaddingForButtons + 15.0;
      break;
    default: // log date
      //return 45;
      return [PEUIUtils sizeOfText:@""
                          withFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleBody]].height +
      _uitoolkit.verticalPaddingForButtons + 15.0;
      break;
  }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
  return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell =
    [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                           reuseIdentifier:nil];
  switch ([indexPath section]) {
    case 0:
      [[cell textLabel] setText:@"Vehicle"];
      [[cell detailTextLabel] setText:(_selectedVehicle ? [_selectedVehicle name] : @"(create vehicle)")];
      break;
    default:
      [[cell textLabel] setText:@"Log date"];
      [[cell detailTextLabel] setText:[PEUtils stringFromDate:_pickedLogDate withPattern:@"MM/dd/YYYY"]];
      break;
  }
  if (_displayDisclosureIndicators) {
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
  } else {
    [cell setAccessoryType:UITableViewCellAccessoryNone];
  }
  return cell;
}

@end
