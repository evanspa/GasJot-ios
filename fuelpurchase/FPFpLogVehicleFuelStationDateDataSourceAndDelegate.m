//
//  FPFpLogVehicleFuelStationDateDataSourceAndDelegate.m
//  fuelpurchase
//
//  Created by Evans, Paul on 10/13/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPFpLogVehicleFuelStationDateDataSourceAndDelegate.h"
#import <PEObjc-Commons/PEUIUtils.h>
#import <PEObjc-Commons/PEUtils.h>
#import <PEFuelPurchase-Model/PELMNotificationUtils.h>
#import <PEFuelPurchase-Model/FPNotificationNames.h>
#import "FPNames.h"

@implementation FPFpLogVehicleFuelStationDateDataSourceAndDelegate {
  FPCoordinatorDao *_coordDao;
  FPScreenToolkit *_screenToolkit;
  PEUIToolkit *_uitoolkit;
  FPUser *_user;
  UIViewController *_controllerCtx;
  PEItemSelectedAction _vehicleSelectedAction;
  PEItemSelectedAction _fuelStationSelectedAction;
  void(^_logDatePickedAction)(NSDate *);
}

#pragma mark - Initializers

- (id)initWithControllerCtx:(UIViewController *)controllerCtx
     defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle
 defaultSelectedFuelStation:(FPFuelStation *)defaultSelectedFuelStation
             defaultLogDate:(NSDate *)defaultLogDate
      vehicleSelectedAction:(PEItemSelectedAction)vehicleSelectedAction
  fuelStationSelectedAction:(PEItemSelectedAction)fuelStationSelectedAction
        logDatePickedAction:(void(^)(NSDate *))logDatePickedAction
             coordinatorDao:(FPCoordinatorDao *)coordDao
                       user:(FPUser *)user
               screenToolkit:(FPScreenToolkit *)screenToolkit
                      error:(PELMDaoErrorBlk)errorBlk {
  self = [super init];
  if (self) {
    _controllerCtx = controllerCtx;
    _coordDao = coordDao;
    _selectedVehicle = defaultSelectedVehicle;
    _selectedFuelStation = defaultSelectedFuelStation;
    _pickedLogDate = defaultLogDate;
    _user = user;
    _screenToolkit = screenToolkit;
    _uitoolkit = [_screenToolkit uitoolkit];
    __weak FPFpLogVehicleFuelStationDateDataSourceAndDelegate *weakSelf = self;
    _vehicleSelectedAction = ^(FPVehicle *selectedVehicle, NSIndexPath *indexPath, UIViewController *selectionController) {
      [weakSelf setSelectedVehicle:selectedVehicle];
      vehicleSelectedAction(selectedVehicle, indexPath, selectionController);
    };
    _fuelStationSelectedAction = ^(FPFuelStation *selectedFuelStation, NSIndexPath *indexPath, UIViewController *selectionController) {
      [weakSelf setSelectedFuelStation:selectedFuelStation];
      fuelStationSelectedAction(selectedFuelStation, indexPath, selectionController);
    };
    _logDatePickedAction = ^(NSDate *pickedDate) {
      [weakSelf setPickedLogDate:pickedDate];
      logDatePickedAction(pickedDate);
    };
  }
  return self;
}

#pragma mark - Notification Observing

- (void)handleNotification:(NSNotification *)notification
   potentialMatchingEntity:(PELMMainSupport *)entity
          tempNotification:(NSString *)tempNotification {
  if (entity) {
    NSNumber *indexOfNotifEntity =
      [PELMNotificationUtils indexOfEntityRef:entity notification:notification];
    if (indexOfNotifEntity) {
      [PEUIUtils displayTempNotification:tempNotification
                           forController:_controllerCtx
                               uitoolkit:[_screenToolkit uitoolkit]];
    }
  }
}

- (void)vehicleObjectSyncInitiated:(NSNotification *)notification {
  [self handleNotification:notification
   potentialMatchingEntity:_selectedVehicle
          tempNotification:@"Sync initiated for selected vehicle."];
}

- (void)vehicleObjectSyncCompleted:(NSNotification *)notification {
  [self handleNotification:notification
   potentialMatchingEntity:_selectedVehicle
          tempNotification:@"Sync completed for selected vehicle."];
}

- (void)vehicleObjectSyncFailed:(NSNotification *)notification {
  [self handleNotification:notification
   potentialMatchingEntity:_selectedVehicle
          tempNotification:@"Sync failed for selected vehicle."];
}

- (void)fuelStationCoordinateComputeSuccess:(NSNotification *)notification {
  [self handleNotification:notification
   potentialMatchingEntity:_selectedFuelStation
          tempNotification:@"Coordinate compute succeeded\nfor selected fuel station."];
}

- (void)fuelStationObjectSyncInitiated:(NSNotification *)notification {
  [self handleNotification:notification
   potentialMatchingEntity:_selectedFuelStation
          tempNotification:@"Sync initiated for selected fuel station."];
}

- (void)fuelStationObjectSyncCompleted:(NSNotification *)notification {
  [self handleNotification:notification
   potentialMatchingEntity:_selectedFuelStation
          tempNotification:@"Sync completed for selected fuel station."];
}

- (void)fuelStationObjectSyncFailed:(NSNotification *)notification {
  [self handleNotification:notification
   potentialMatchingEntity:_selectedFuelStation
          tempNotification:@"Sync failed for selected fuel station."];
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  switch ([indexPath section]) {
    case 0:  // vehicle
      return 35;
      break;
    case 1:  // fuel station
      return 50;
      break;
    default: // log date
      return 35;
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
heightForFooterInSection:(NSInteger)section {
  return 0;
}

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
    case 1:
      [PEUIUtils displayController:[_screenToolkit
                                    newFuelStationsForSelectionScreenMakerWithItemSelectedAction:_fuelStationSelectedAction
                                    initialSelectedFuelStation:_selectedFuelStation](_user)
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 3;
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
      [[cell detailTextLabel] setText:(_selectedVehicle ? [_selectedVehicle name] : @"(no vehicles found)")];
      break;
    case 1:
      [[cell textLabel] setText:@"Fuel station"];
      if (_selectedFuelStation) {
        UIView *contentView = [cell contentView];
        LabelMaker cellTitleMaker = [_uitoolkit tableCellTitleMaker];
        NSString *name = [_selectedFuelStation name];
        if ([name length] > 20) {
          name = [[name substringToIndex:20] stringByAppendingString:@"..."];
        }
        UILabel *title = cellTitleMaker(name);
        CLLocation *fuelStationLocation = [_selectedFuelStation location];
        CGFloat distanceInfoVPadding = 2.0;
        if (fuelStationLocation) {
          CLLocation *latestCurrentLocation = [APP latestLocation];
          if (latestCurrentLocation) {
            distanceInfoVPadding = 7.0;
            [PEUIUtils placeView:title atTopOf:contentView withAlignment:PEUIHorizontalAlignmentTypeRight vpadding:7.0 hpadding:37.0];
          } else {
            [PEUIUtils placeView:title atTopOf:contentView withAlignment:PEUIHorizontalAlignmentTypeRight vpadding:2.0 hpadding:37.0];
          }
        } else {
          [PEUIUtils placeView:title atTopOf:contentView withAlignment:PEUIHorizontalAlignmentTypeRight vpadding:2.0 hpadding:37.0];
        }
        [_screenToolkit addDistanceInfoToTopOfCellContentView:contentView
                                          withVerticalPadding:(title.frame.size.height + distanceInfoVPadding)
                                            horizontalPadding:37.0
                                              withFuelstation:_selectedFuelStation];
      } else {
        [[cell detailTextLabel] setText:@"(no fuel stations found)"];
      }
      break;
    default:
      [[cell textLabel] setText:@"Log date"];
      [[cell detailTextLabel] setText:[PEUtils stringFromDate:_pickedLogDate withPattern:@"MM/dd/YYYY"]];
      break;
  }
  [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
  return cell;
}

@end
