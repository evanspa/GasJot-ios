//
//  FPLogging.m
//  PEFuelPurchase-Model
//
//  Created by Paul Evans on 3/10/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import "FPLogging.h"
#import <CocoaLumberjack/DDLog.h>

#ifdef __OBJC__
  #ifdef DEBUG
    const int ddLogLevel = LOG_LEVEL_DEBUG;
  #else
    const int ddLogLevel = LOG_LEVEL_INFO;
  #endif
#endif
