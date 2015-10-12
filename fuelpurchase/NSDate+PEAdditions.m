//
//  NSDate+PEAdditions.m
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 10/11/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "NSDate+PEAdditions.h"

@implementation NSDate (PEAdditions)

- (NSInteger)daysFromDate:(NSDate *)date {
  NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  NSInteger startDay = [calendar ordinalityOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitEra forDate:self];
  NSInteger endDay = [calendar ordinalityOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitEra forDate:date];
  return labs(endDay - startDay);
}

@end
