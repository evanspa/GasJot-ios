//
//  FPReportViews.h
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 10/10/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PEObjc-Commons/JGActionSheet.h>
#import <PEFuelPurchase-Model/FPLocalDao.h>
#import <PEFuelPurchase-Model/FPReports.h>

typedef JGActionSheetSection *(^FPFunFact)(id, FPUser *, UIView *);

@interface FPReportViews : NSObject

#pragma mark - Initializers

- (id)initWithReports:(FPReports *)reports;

#pragma mark - Gas Log Fun Facts

- (FPFunFact)overallAvgPricePerGallonForFuelstationFunFact;

- (FPFunFact)overallAvgPricePerGallonForUserFunFact;

- (FPFunFact)yearToDateAvgPricePerGallonForFuelstationFunFact;

- (FPFunFact)yearToDateAvgPricePerGallonForUserFunFact;

- (FPFunFact)totalSpentOnGasForFuelStationFunFact;

- (FPFunFact)totalSpentOnGasForVehicleFunFact;

- (FPFunFact)totalSpentOnGasForUserFunFact;

- (FPFunFact)yearToDateSpentOnGasForFuelstationFunFact;

- (FPFunFact)yearToDateSpentOnGasForVehicleFunFact;

- (FPFunFact)yearToDateSpentOnGasForUserFunFact;

#pragma mark - Odometer Log Fun Facts

- (FPFunFact)milesDrivenSinceLastOdometerLogAndLogFunFact;

- (FPFunFact)daysSinceLastOdometerLogAndLogFunFact;

- (FPFunFact)temperatureLastYearFromLogFunFact;

#pragma mark - Odometer Log Fun Fact Iteration

- (NSInteger)numOdometerFunFacts;

- (FPFunFact)nextOdometerFunFact;

#pragma mark - Gas Log Fun Fact Iteration

- (NSInteger)numGasFunFacts;

- (FPFunFact)nextGasFunFact;

@end
