//
//  FPPriceStreamFilterCriteria.m
//  Gas Jot Model
//
//  Created by Paul Evans on 1/6/16.
//  Copyright © 2016 Paul Evans. All rights reserved.
//

#import "FPPriceStreamFilterCriteria.h"

@implementation FPPriceStreamFilterCriteria

#pragma mark - Initializers

- (instancetype)initWithNearLatitude:(NSDecimalNumber *)latitude
                       nearLongitude:(NSDecimalNumber *)longitude
                      distanceWithin:(NSInteger)distanceWithin
                          maxResults:(NSInteger)maxResults
                              sortBy:(NSString *)sortBy {
  self = [super init];
  if (self) {
    _latitude = latitude;
    _longitude = longitude;
    _distanceWithin = distanceWithin;
    _maxResults = maxResults;
    _sortBy = sortBy;
  }
  return self;
}

@end
