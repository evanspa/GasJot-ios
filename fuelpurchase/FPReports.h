//
//  FPReport.h
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 10/10/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JGActionSheet/JGActionSheet.h>
#import <PEFuelPurchase-Model/FPLocalDao.h>

typedef JGActionSheetSection *(^FPFunFact)(id, FPUser *, UIView *);

@interface FPReports : NSObject

#pragma mark - Initializers

- (id)initWithLocalDao:(FPLocalDao *)localDao;

#pragma mark - Odometer Log Fun Fact Definitions

- (NSDecimalNumber *)milesDrivenSinceLastOdometerLogAndLog:(FPEnvironmentLog *)odometerLog
                                                      user:(FPUser *)user;

- (NSNumber *)daysSinceLastOdometerLogAndLog:(FPEnvironmentLog *)odometerLog
                                        user:(FPUser *)user;

- (NSNumber *)temperatureLastYearFromLog:(FPEnvironmentLog *)odometerLog
                                    user:(FPUser *)user;

#pragma mark - 'Next' Fun Fact

- (NSInteger)numOdometerFunFacts;

- (FPFunFact)nextOdometerFunFact;

@end
