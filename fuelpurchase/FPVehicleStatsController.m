//
//  FPVehicleStatsController.m
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 10/18/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "FPVehicleStatsController.h"
#import <PEFuelPurchase-Model/FPStats.h>

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

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  [self setTitle:@"Vehicle Stats"];
  
  // remove the views
  
  // refresh their data
  
  // re-add them
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  // create the views and place them
}

@end
