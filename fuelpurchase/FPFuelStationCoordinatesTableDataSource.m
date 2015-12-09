//
//  FPFuelStationCoordinatesTableDataSource.m
//  fuelpurchase
//
//  Created by Evans, Paul on 10/6/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPFuelStationCoordinatesTableDataSource.h"
#import <PEObjc-Commons/PEUtils.h>

@implementation FPFuelStationCoordinatesTableDataSource

#pragma mark - Initializers

- (id)initWithFuelStationLatitude:(NSDecimalNumber *)latitude
                        longitude:(NSDecimalNumber *)longitude {
  self = [super init];
  if (self) {
    _latitude = latitude;
    _longitude = longitude;
  }
  return self;
}

#pragma mark - Helpers

- (NSString *)descriptionForCoordinate:(NSDecimalNumber *)coordinate {
  if (![PEUtils isNil:coordinate]) {
    if (![coordinate isEqualToNumber:[NSDecimalNumber notANumber]]) {
      return [coordinate description];
    }
  }
  return @"";
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section {
  return @"Location Coordinates";
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
  return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
  [cell setUserInteractionEnabled:NO];
  switch ([indexPath row]) {
    case 0:
      [[cell textLabel] setText:@"Latitude"];
      [[cell detailTextLabel] setText:[self descriptionForCoordinate:_latitude]];
      break;
    default:
      [[cell textLabel] setText:@"Longitude"];
      [[cell detailTextLabel] setText:[self descriptionForCoordinate:_longitude]];
      break;
  }
  return cell;
}

@end
