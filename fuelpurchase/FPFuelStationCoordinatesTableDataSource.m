//
//  FPFuelStationCoordinatesTableDataSource.m
//  fuelpurchase
//
//  Created by Evans, Paul on 10/6/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPFuelStationCoordinatesTableDataSource.h"

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
      [[cell detailTextLabel] setText:(_latitude ? [_latitude description] : @"")];
      break;
    default:
      [[cell textLabel] setText:@"Longitude"];
      [[cell detailTextLabel] setText:(_longitude ? [_longitude description] : @"")];
      break;
  }
  return cell;
}

@end
