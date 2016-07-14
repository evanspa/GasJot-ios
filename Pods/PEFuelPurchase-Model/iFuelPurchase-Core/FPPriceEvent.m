//
//  FPPriceEvent.m
//  Gas Jot Model
//
//  Created by Paul Evans on 12/29/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "FPPriceEvent.h"

@implementation FPPriceEvent

#pragma mark - Initializers

- (instancetype)initWithFuelstationType:(FPFuelStationType *)fsType
                               fsStreet:(NSString *)fsStreet
                                 fsCity:(NSString *)fsCity
                                fsState:(NSString *)fsState
                                  fsZip:(NSString *)fsZip
                             fsLatitude:(NSDecimalNumber *)fsLatitude
                            fsLongitude:(NSDecimalNumber *)fsLongitude
                             fsDistance:(NSDecimalNumber *)fsDistance
                                  price:(NSDecimalNumber *)price
                                 octane:(NSNumber *)octane
                               isDiesel:(BOOL)isDiesel
                                   date:(NSDate *)date {
  self = [super init];
  if (self) {
    _fsType = fsType;
    _fsStreet = fsStreet;
    _fsCity = fsCity;
    _fsState = fsState;
    _fsZip = fsZip;
    _fsLatitude = fsLatitude;
    _fsLongitude = fsLongitude;
    _fsDistance = fsDistance;
    _price = price;
    _octane = octane;
    _isDiesel = isDiesel;
    _date = date;
  }
  return self;
}

@end
