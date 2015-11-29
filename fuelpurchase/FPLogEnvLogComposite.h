//
//  FPLogEnvLogComposite.h
//  fuelpurchase
//
//  Created by Evans, Paul on 1/27/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PEFuelPurchase-Model/FPFuelPurchaseLog.h>
#import <PEFuelPurchase-Model/FPEnvironmentLog.h>
#import <PEFuelPurchase-Model/FPCoordinatorDao.h>

@interface FPLogEnvLogComposite : NSObject

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
                coordDao:(FPCoordinatorDao *)coordDao;

@property (nonatomic, readonly) FPFuelPurchaseLog *fpLog;
@property (nonatomic, readonly) FPEnvironmentLog *preFillupEnvLog;
@property (nonatomic, readonly) FPEnvironmentLog *postFillupEnvLog;

@end
