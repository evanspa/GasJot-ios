//
//  NSObject+appdelegate.m
//  fuelpurchase
//
//  Created by Paul Evans on 6/29/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "NSObject+appdelegate.h"

@implementation NSObject (appdelegate)

- (FPAppDelegate *)appDelegate {
  return (FPAppDelegate *)[[UIApplication sharedApplication] delegate];
}

@end
