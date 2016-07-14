//
//  PELocalDataBaseController.m
//  PELocal-DataUI
//
//  Created by Paul Evans on 12/4/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "PELocalDataBaseController.h"
#import <PELocal-Data/PELMNotificationNames.h>

@implementation PELocalDataBaseController

#pragma mark - Initializers

- (instancetype)initWithRequireRepaintNotifications:(NSArray *)notifications {
  NSMutableArray *repaintNotifications = [NSMutableArray array];
  if (notifications) {
    [repaintNotifications addObjectsFromArray:notifications];
  }
  [repaintNotifications addObject:PELMNotificationDbUpdate];
  return [super initWithRequireRepaintNotifications:repaintNotifications];
}

@end
