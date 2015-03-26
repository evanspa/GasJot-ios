//
//  FPEnvLogVehicleAndDateDataSourceDelegate.m
//  fuelpurchase
//
//  Created by Evans, Paul on 10/13/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPEnvLogVehicleAndDateDataSourceDelegate.h"
#import <objc-commons/PEUIUtils.h>
#import <objc-commons/PEUtils.h>
#import <iFuelPurchase-Core/PELMNotificationUtils.h>
#import <iFuelPurchase-Core/FPNotificationNames.h>

@implementation FPEnvLogVehicleAndDateDataSourceDelegate {
  FPCoordinatorDao *_coordDao;
  FPScreenToolkit *_screenToolkit;
  FPUser *_user;
  UIViewController *_controllerCtx;
  PEItemSelectedAction _vehicleSelectedAction;
  void(^_logDatePickedAction)(NSDate *);
}

#pragma mark - Initializers

- (id)initWithControllerCtx:(UIViewController *)controllerCtx
     defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle
             defaultLogDate:(NSDate *)defaultLogDate
      vehicleSelectedAction:(PEItemSelectedAction)vehicleSelectedAction
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
    _pickedLogDate = defaultLogDate;
    _user = user;
    _screenToolkit = screenToolkit;
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
      [[cell detailTextLabel] setText:(_selectedVehicle ? [_selectedVehicle name] : @"(no vehicles found)")];
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
