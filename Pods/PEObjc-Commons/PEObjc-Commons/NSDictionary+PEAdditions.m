//
//  NSDictionary+PEAdditions.m
//  PEObjc-Commons
//
//  Created by Paul Evans on 6/3/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import "NSDictionary+PEAdditions.h"
#import "PEUtils.h"

@implementation NSDictionary (PEAdditions)

- (NSDate *)dateSince1970ForKey:(NSString *)key {
  NSDate *date = nil;
  NSNumber *dateNum = [self objectForKey:key];
  if (![PEUtils isNil:dateNum]) {
    date = [NSDate dateWithTimeIntervalSince1970:([dateNum doubleValue] / 1000)];
  }
  return date;
}

- (BOOL)boolForKey:(NSString *)key {
  return [self boolForKey:key defaultBool:NO];
}

- (BOOL)boolForKey:(NSString *)key defaultBool:(BOOL)defaultBool {
  id object = [self objectForKey:key];
  if (![PEUtils isNil:object]) {
    return [object boolValue];
  }
  return defaultBool;
}

@end
