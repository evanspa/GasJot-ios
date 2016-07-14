//
//  FPPriceEvent.h
//  Gas Jot Model
//
//  Created by Paul Evans on 12/29/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FPFuelStationType;

@interface FPPriceEvent : NSObject

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
                                   date:(NSDate *)date;

#pragma mark - Properties

@property (nonatomic, readonly) FPFuelStationType *fsType;

@property (nonatomic, readonly) NSString *fsStreet;

@property (nonatomic, readonly) NSString *fsCity;

@property (nonatomic, readonly) NSString *fsState;

@property (nonatomic, readonly) NSString *fsZip;

@property (nonatomic, readonly) NSDecimalNumber *fsLatitude;

@property (nonatomic, readonly) NSDecimalNumber *fsLongitude;

@property (nonatomic, readonly) NSDecimalNumber *fsDistance;

@property (nonatomic, readonly) NSDecimalNumber *price;

@property (nonatomic, readonly) NSNumber *octane;

@property (nonatomic, readonly) BOOL isDiesel;

@property (nonatomic, readonly) NSDate *date;

@end
