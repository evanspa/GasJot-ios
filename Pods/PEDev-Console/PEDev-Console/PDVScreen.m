//
//  PDVScreen.m
//  dev-console
//
//  Created by Evans, Paul on 6/18/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "PDVScreen.h"

@implementation PDVScreen

#pragma mark - Initializers

- (id)initWithDisplayName:(NSString *)displayName
              description:(NSString *)screenDescription
      viewControllerMaker:(UIViewController *(^)(void))viewControllerMaker {
  self = [super init];
  if (self) {
    _displayName = displayName;
    _screenDescription = screenDescription;
    _viewControllerMaker = viewControllerMaker;
  }
  return self;
}

@end
