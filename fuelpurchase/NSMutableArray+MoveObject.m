//
//  NSMutableArray+MoveObject.m
//  fuelpurchase
//
//  Created by Evans, Paul on 1/21/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import "NSMutableArray+MoveObject.h"

@implementation NSMutableArray (MoveObject)

- (void)moveObjectFromIndex:(NSUInteger)from toIndex:(NSUInteger)to {
  if (to != from) {
    id obj = [self objectAtIndex:from];
    [self removeObjectAtIndex:from];
    if (to >= [self count]) {
      [self addObject:obj];
    } else {
      [self insertObject:obj atIndex:to];
    }
  }
}

@end
