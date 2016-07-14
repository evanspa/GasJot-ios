//
//  FPFuelStationType.h
//  Gas Jot Model
//
//  Created by Paul Evans on 12/20/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

@import Foundation;

#import <PELocal-Data/PELMIdentifiable.h>

@interface FPFuelStationType : NSObject<PELMIdentifiable>

#pragma mark - Initializers

- (id)initWithIdentifier:(NSNumber *)identifier
                    name:(NSString *)name
             iconImgName:(NSString *)iconImgName;

#pragma mark - Properties

@property (nonatomic, readonly) NSNumber *identifier;

@property (nonatomic, readonly) NSString *name;

@property (nonatomic) NSString *iconImgName;

#pragma mark - Equality

- (BOOL)isEqualToFuelStationType:(FPFuelStationType *)fuelStationType;

@end
