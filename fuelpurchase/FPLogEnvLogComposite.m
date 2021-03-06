//
//  FPLogEnvLogComposite.m
//  fuelpurchase
//
//  Created by Evans, Paul on 1/27/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import "FPLogEnvLogComposite.h"

@implementation FPLogEnvLogComposite

- (id)initWithNumGallons:(NSDecimalNumber *)numGallons
                isDiesel:(BOOL)isDiesel
                  octane:(NSNumber *)octane
             gallonPrice:(NSDecimalNumber *)gallonPrice
              gotCarWash:(BOOL)gotCarWash
carWashPerGallonDiscount:(NSDecimalNumber *)carWashPerGallonDiscount
                odometer:(NSDecimalNumber *)odometer
          reportedAvgMpg:(NSDecimalNumber *)reportedAvgMpg
          reportedAvgMph:(NSDecimalNumber *)reportedAvgMph
     reportedOutsideTemp:(NSNumber *)reportedOutsideTemp
    preFillupReportedDte:(NSNumber *)preFillupReportedDte
   postFillupReportedDte:(NSNumber *)postFillupReportedDte
                 logDate:(NSDate *)logDate
                coordDao:(id<FPCoordinatorDao>)coordDao {
  self = [super init];
  if (self) {
    _fpLog = [coordDao fuelPurchaseLogWithNumGallons:numGallons
                                              octane:octane
                                            odometer:odometer
                                         gallonPrice:gallonPrice
                                          gotCarWash:gotCarWash
                            carWashPerGallonDiscount:carWashPerGallonDiscount
                                             logDate:logDate
                                            isDiesel:isDiesel];
    _preFillupEnvLog = [coordDao environmentLogWithOdometer:odometer
                                             reportedAvgMpg:reportedAvgMpg
                                             reportedAvgMph:reportedAvgMph
                                        reportedOutsideTemp:reportedOutsideTemp
                                                    logDate:logDate
                                                reportedDte:preFillupReportedDte];
    _postFillupEnvLog = [coordDao environmentLogWithOdometer:odometer
                                              reportedAvgMpg:reportedAvgMpg
                                              reportedAvgMph:reportedAvgMph
                                         reportedOutsideTemp:reportedOutsideTemp
                                                     logDate:logDate
                                                 reportedDte:postFillupReportedDte];
  }
  return self;
}

@end
