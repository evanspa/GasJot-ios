//
//  FPPriceStreamFilterCriteria.h
//  Gas Jot Model
//
//  Created by Paul Evans on 1/6/16.
//  Copyright © 2016 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FPPriceStreamFilterCriteria : NSObject

#pragma mark - Initializers

- (instancetype)initWithNearLatitude:(NSDecimalNumber *)latitude
                       nearLongitude:(NSDecimalNumber *)longitude
                      distanceWithin:(NSInteger)distanceWithin
                          maxResults:(NSInteger)maxResults
                              sortBy:(NSString *)sortBy;

#pragma mark - Properties

@property (nonatomic, readonly) NSDecimalNumber *latitude;

@property (nonatomic, readonly) NSDecimalNumber *longitude;

@property (nonatomic, readonly) NSInteger distanceWithin;

@property (nonatomic, readonly) NSInteger maxResults;

@property (nonatomic, readonly) NSString *sortBy;

@end
