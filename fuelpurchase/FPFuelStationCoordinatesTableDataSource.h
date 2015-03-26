//
//  FPFuelStationCoordinatesTableDataSource.h
//  fuelpurchase
//
//  Created by Evans, Paul on 10/6/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FPFuelStationCoordinatesTableDataSource : NSObject <UITableViewDataSource>

#pragma mark - Initializers

- (id)initWithFuelStationLatitude:(NSDecimalNumber *)latitude
                        longitude:(NSDecimalNumber *)longitude;

#pragma mark - Properties

@property (nonatomic) NSDecimalNumber *latitude;

@property (nonatomic) NSDecimalNumber *longitude;

@end
