//
//  FPFuelStationType.m
//  Gas Jot Model
//
//  Created by Paul Evans on 12/20/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "FPFuelStationType.h"

@implementation FPFuelStationType

#pragma mark - Initializers

- (id)initWithIdentifier:(NSNumber *)identifier
                    name:(NSString *)name
             iconImgName:(NSString *)iconImgName {
  self = [super init];
  if (self) {
    _identifier = identifier;
    _name = name;
    _iconImgName = iconImgName;
  }
  return self;
}

#pragma mark - PELMIdentifiable Protocol

- (BOOL)doesHaveEqualIdentifiers:(id<PELMIdentifiable>)entity {
  return [_identifier isEqualToNumber:[((FPFuelStationType *)entity) identifier]];
}

#pragma mark - Equality

- (BOOL)isEqualToFuelStationType:(FPFuelStationType *)fuelStationType {
  if (!fuelStationType) { return NO; }
  return [_identifier isEqualToNumber:fuelStationType.identifier];
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[FPFuelStationType class]]) { return NO; }
  return [self isEqualToFuelStationType:object];
}

- (NSUInteger)hash {
  return [super hash] ^ [[self identifier] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"identifier: %@, name: %@, iconImgName: %@", _identifier, _name, _iconImgName];
}

@end
