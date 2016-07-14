//
//  PDVScreenGroup.m
//  dev-console
//
//  Created by Evans, Paul on 6/18/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "PDVScreenGroup.h"

@implementation PDVScreenGroup {
  //NSArray *_screens;
}

#pragma mark - Initializers

- (id)initWithName:(NSString *)name screens:(NSArray *)screens {
  self = [super init];
  if (self) {
    _name = name;
    _screens = screens;
  }
  return self;
}

#pragma mark - Methods

- (NSUInteger)count {
  return [_screens count];
}

- (PDVScreen *)screenAtIndex:(NSInteger)index {
  return [_screens objectAtIndex:index];
}

@end
