//
//  FPStats.h
//  PEFuelPurchase-Model
//
//  Created by Paul Evans on 10/10/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

@import Foundation;

#import <PELocal-Data/PELMDefs.h>

@protocol FPLocalDao;
@class FPVehicle;
@class FPUser;
@class FPFuelStation;
@class FPFuelPurchaseLog;
@class FPEnvironmentLog;

@interface FPStats : NSObject

#pragma mark - Initializers

- (id)initWithLocalDao:(id<FPLocalDao>)localDao errorBlk:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Sinces since last odometer log

- (NSNumber *)daysSinceLastOdometerLogForUser:(FPUser *)user;

- (NSNumber *)daysSinceLastOdometerLogForVehicle:(FPVehicle *)vehicle;

#pragma mark - Average Reported MPH

- (NSDecimalNumber *)yearToDateAvgReportedMphForUser:(FPUser *)user;

- (NSArray *)yearToDateAvgReportedMphDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)lastYearAvgReportedMphForUser:(FPUser *)user;

- (NSArray *)lastYearAvgReportedMphDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)overallAvgReportedMphForUser:(FPUser *)user;

- (NSArray *)overallAvgReportedMphDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateAvgReportedMphForVehicle:(FPVehicle *)vehicle;

- (NSArray *)yearToDateAvgReportedMphDataSetForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)lastYearAvgReportedMphForVehicle:(FPVehicle *)vehicle;

- (NSArray *)lastYearAvgReportedMphDataSetForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallAvgReportedMphForVehicle:(FPVehicle *)vehicle;

- (NSArray *)overallAvgReportedMphDataSetForVehicle:(FPVehicle *)vehicle;

#pragma mark - Max Reported MPH

- (NSDecimalNumber *)yearToDateMaxReportedMphForUser:(FPUser *)user;

- (NSDecimalNumber *)lastYearMaxReportedMphForUser:(FPUser *)user;

- (NSDecimalNumber *)overallMaxReportedMphForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateMaxReportedMphForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)lastYearMaxReportedMphForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallMaxReportedMphForVehicle:(FPVehicle *)vehicle;

#pragma mark - Min Reported MPH

- (NSDecimalNumber *)yearToDateMinReportedMphForUser:(FPUser *)user;

- (NSDecimalNumber *)lastYearMinReportedMphForUser:(FPUser *)user;

- (NSDecimalNumber *)overallMinReportedMphForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateMinReportedMphForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)lastYearMinReportedMphForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallMinReportedMphForVehicle:(FPVehicle *)vehicle;

#pragma mark - Average Reported MPG

- (NSDecimalNumber *)yearToDateAvgReportedMpgForUser:(FPUser *)user;

- (NSArray *)yearToDateAvgReportedMpgDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)lastYearAvgReportedMpgForUser:(FPUser *)user;

- (NSArray *)lastYearAvgReportedMpgDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)overallAvgReportedMpgForUser:(FPUser *)user;

- (NSArray *)overallAvgReportedMpgDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateAvgReportedMpgForVehicle:(FPVehicle *)vehicle;

- (NSArray *)yearToDateAvgReportedMpgDataSetForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)lastYearAvgReportedMpgForVehicle:(FPVehicle *)vehicle;

- (NSArray *)lastYearAvgReportedMpgDataSetForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallAvgReportedMpgForVehicle:(FPVehicle *)vehicle;

- (NSArray *)overallAvgReportedMpgDataSetForVehicle:(FPVehicle *)vehicle;

#pragma mark - Max Reported MPG

- (NSDecimalNumber *)yearToDateMaxReportedMpgForUser:(FPUser *)user;

- (NSDecimalNumber *)lastYearMaxReportedMpgForUser:(FPUser *)user;

- (NSDecimalNumber *)overallMaxReportedMpgForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateMaxReportedMpgForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)lastYearMaxReportedMpgForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallMaxReportedMpgForVehicle:(FPVehicle *)vehicle;

#pragma mark - Min Reported MPG

- (NSDecimalNumber *)yearToDateMinReportedMpgForUser:(FPUser *)user;

- (NSDecimalNumber *)lastYearMinReportedMpgForUser:(FPUser *)user;

- (NSDecimalNumber *)overallMinReportedMpgForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateMinReportedMpgForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)lastYearMinReportedMpgForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallMinReportedMpgForVehicle:(FPVehicle *)vehicle;

#pragma mark - Days Between Fill-ups

- (NSNumber *)daysSinceLastGasLogForUser:(FPUser *)user;

- (NSNumber *)daysSinceLastGasLogForVehicle:(FPVehicle *)vehicle;

- (NSNumber *)daysSinceLastGasLogForGasStation:(FPFuelStation *)gasStation;

- (NSDecimalNumber *)yearToDateAvgDaysBetweenFillupsForUser:(FPUser *)user;

- (NSNumber *)yearToDateMaxDaysBetweenFillupsForUser:(FPUser *)user;

- (NSArray *)yearToDateDaysBetweenFillupsDataSetForUser:(FPUser *)user;

- (NSArray *)yearToDateAvgDaysBetweenFillupsDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)lastYearAvgDaysBetweenFillupsForUser:(FPUser *)user;

- (NSNumber *)lastYearMaxDaysBetweenFillupsForUser:(FPUser *)user;

- (NSArray *)lastYearDaysBetweenFillupsDataSetForUser:(FPUser *)user;

- (NSArray *)lastYearAvgDaysBetweenFillupsDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)overallAvgDaysBetweenFillupsForUser:(FPUser *)user;

- (NSNumber *)overallMaxDaysBetweenFillupsForUser:(FPUser *)user;

- (NSArray *)overallDaysBetweenFillupsDataSetForUser:(FPUser *)user;

- (NSArray *)overallAvgDaysBetweenFillupsDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateAvgDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle;

- (NSNumber *)yearToDateMaxDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle;

- (NSArray *)yearToDateDaysBetweenFillupsDataSetForVehicle:(FPVehicle *)vehicle;

- (NSArray *)yearToDateAvgDaysBetweenFillupsDataSetForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)lastYearAvgDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle;

- (NSNumber *)lastYearMaxDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle;

- (NSArray *)lastYearDaysBetweenFillupsDataSetForVehicle:(FPVehicle *)vehicle;

- (NSArray *)lastYearAvgDaysBetweenFillupsDataSetForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallAvgDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle;

- (NSNumber *)overallMaxDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle;

- (NSArray *)overallDaysBetweenFillupsDataSetForVehicle:(FPVehicle *)vehicle;

- (NSArray *)overallAvgDaysBetweenFillupsDataSetForVehicle:(FPVehicle *)vehicle;

#pragma mark - Gas Cost Per Mile

- (NSDecimalNumber *)yearToDateAvgGasCostPerMileForUser:(FPUser *)user;

- (NSArray *)yearToDateAvgGasCostPerMileDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)avgGasCostPerMileForUser:(FPUser *)user year:(NSInteger)year;

- (NSArray *)avgGasCostPerMileDataSetForUser:(FPUser *)user year:(NSInteger)year;

- (NSDecimalNumber *)lastYearAvgGasCostPerMileForUser:(FPUser *)user;

- (NSArray *)lastYearAvgGasCostPerMileDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)overallAvgGasCostPerMileForUser:(FPUser *)user;

- (NSArray *)overallAvgGasCostPerMileDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateAvgGasCostPerMileForVehicle:(FPVehicle *)vehicle;

- (NSArray *)yearToDateAvgGasCostPerMileDataSetForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)avgGasCostPerMileForVehicle:(FPVehicle *)vehicle year:(NSInteger)year;

- (NSArray *)avgGasCostPerMileDataSetForVehicle:(FPVehicle *)vehicle year:(NSInteger)year;

- (NSDecimalNumber *)lastYearAvgGasCostPerMileForVehicle:(FPVehicle *)vehicle;

- (NSArray *)lastYearAvgGasCostPerMileDataSetForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallAvgGasCostPerMileForVehicle:(FPVehicle *)vehicle;

- (NSArray *)overallAvgGasCostPerMileDataSetForVehicle:(FPVehicle *)vehicle;

#pragma mark - Amount Spent on Gas

- (NSDecimalNumber *)thisMonthSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)lastMonthSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateSpentOnGasForUser:(FPUser *)user;

- (NSArray *)yearToDateSpentOnGasDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateAvgSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateMinSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateMaxSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)lastYearSpentOnGasForUser:(FPUser *)user;

- (NSArray *)lastYearSpentOnGasDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)lastYearAvgSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)lastYearMinSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)lastYearMaxSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)overallSpentOnGasForUser:(FPUser *)user;

- (NSArray *)overallSpentOnGasDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)overallAvgSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)overallMinSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)overallMaxSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)thisMonthSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)lastMonthSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)yearToDateSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSArray *)yearToDateSpentOnGasDataSetForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)yearToDateAvgSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)yearToDateMinSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)yearToDateMaxSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)lastYearSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSArray *)lastYearSpentOnGasDataSetForVehicle:(FPVehicle *)vehicle;

- (NSArray *)spentOnGasDataSetForVehicle:(FPVehicle *)vehicle year:(NSInteger)year;

- (NSDecimalNumber *)lastYearAvgSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)lastYearMinSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)lastYearMaxSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSArray *)overallSpentOnGasDataSetForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallAvgSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallMinSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallMaxSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)thisMonthSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)lastMonthSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)yearToDateSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSArray *)yearToDateSpentOnGasDataSetForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)yearToDateAvgSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)yearToDateMinSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)yearToDateMaxSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)lastYearSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSArray *)lastYearSpentOnGasDataSetForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)lastYearAvgSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)lastYearMinSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)lastYearMaxSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)overallSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSArray *)overallSpentOnGasDataSetForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)overallAvgSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)overallMinSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)overallMaxSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

#pragma mark - Average Price Per Gallon

- (NSDecimalNumber *)yearToDateAvgPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSArray *)yearToDateAvgPricePerGallonDataSetForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)lastYearAvgPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSArray *)lastYearAvgPricePerGallonDataSetForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallAvgPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSArray *)overallAvgPricePerGallonDataSetForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)yearToDateAvgPricePerGallonForUser:(FPUser *)user;

- (NSArray *)yearToDateAvgPricePerGallonDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)lastYearAvgPricePerGallonForUser:(FPUser *)user;

- (NSArray *)lastYearAvgPricePerGallonDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)overallAvgPricePerGallonForUser:(FPUser *)user;

- (NSArray *)overallAvgPricePerGallonDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateAvgPricePerDieselGallonForUser:(FPUser *)user;

- (NSArray *)yearToDateAvgPricePerDieselGallonDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)lastYearAvgPricePerDieselGallonForUser:(FPUser *)user;

- (NSArray *)lastYearAvgPricePerDieselGallonDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)overallAvgPricePerDieselGallonForUser:(FPUser *)user;

- (NSArray *)overallAvgPricePerDieselGallonDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateAvgPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSArray *)yearToDateAvgPricePerGallonDataSetForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSDecimalNumber *)lastYearAvgPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSArray *)lastYearAvgPricePerGallonDataSetForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallAvgPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSArray *)overallAvgPricePerGallonDataSetForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSDecimalNumber *)yearToDateAvgPricePerGallonForVehicle:(FPVehicle *)vehicle;

- (NSArray *)yearToDateAvgPricePerGallonDataSetForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)lastYearAvgPricePerGallonForVehicle:(FPVehicle *)vehicle;

- (NSArray *)lastYearAvgPricePerGallonDataSetForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallAvgPricePerGallonForVehicle:(FPVehicle *)vehicle;

- (NSArray *)overallAvgPricePerGallonDataSetForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)yearToDateAvgPricePerDieselGallonForVehicle:(FPVehicle *)vehicle;

- (NSArray *)yearToDateAvgPricePerDieselGallonDataSetForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)lastYearAvgPricePerDieselGallonForVehicle:(FPVehicle *)vehicle;

- (NSArray *)lastYearAvgPricePerDieselGallonDataSetForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallAvgPricePerDieselGallonForVehicle:(FPVehicle *)vehicle;

- (NSArray *)overallAvgPricePerDieselGallonDataSetForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)yearToDateAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSArray *)yearToDateAvgPricePerGallonDataSetForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSDecimalNumber *)lastYearAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSArray *)lastYearAvgPricePerGallonDataSetForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSArray *)overallAvgPricePerGallonDataSetForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSDecimalNumber *)yearToDateAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation;

- (NSArray *)yearToDateAvgPricePerGallonDataSetForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)lastYearAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation;

- (NSArray *)lastYearAvgPricePerGallonDataSetForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)overallAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation;

- (NSArray *)overallAvgPricePerGallonDataSetForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)yearToDateAvgPricePerDieselGallonForFuelstation:(FPFuelStation *)fuelstation;

- (NSArray *)yearToDateAvgPricePerDieselGallonDataSetForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)lastYearAvgPricePerDieselGallonForFuelstation:(FPFuelStation *)fuelstation;

- (NSArray *)lastYearAvgPricePerDieselGallonDataSetForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)overallAvgPricePerDieselGallonForFuelstation:(FPFuelStation *)fuelstation;

- (NSArray *)overallAvgPricePerDieselGallonDataSetForFuelstation:(FPFuelStation *)fuelstation;

#pragma mark - Max Price Per Gallon

- (NSDecimalNumber *)yearToDateMaxPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)lastYearMaxPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallMaxPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)yearToDateMaxPricePerGallonForUser:(FPUser *)user;

- (NSDecimalNumber *)lastYearMaxPricePerGallonForUser:(FPUser *)user;

- (NSDecimalNumber *)overallMaxPricePerGallonForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateMaxPricePerDieselGallonForUser:(FPUser *)user;

- (NSDecimalNumber *)lastYearMaxPricePerDieselGallonForUser:(FPUser *)user;

- (NSDecimalNumber *)overallMaxPricePerDieselGallonForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateMaxPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSDecimalNumber *)lastYearMaxPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallMaxPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSDecimalNumber *)yearToDateMaxPricePerGallonForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)lastYearMaxPricePerGallonForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallMaxPricePerGallonForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)yearToDateMaxPricePerDieselGallonForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)lastYearMaxPricePerDieselGallonForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallMaxPricePerDieselGallonForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)yearToDateMaxPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSDecimalNumber *)lastYearMaxPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallMaxPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSDecimalNumber *)yearToDateMaxPricePerGallonForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)lastYearMaxPricePerGallonForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)overallMaxPricePerGallonForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)yearToDateMaxPricePerDieselGallonForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)lastYearMaxPricePerDieselGallonForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)overallMaxPricePerDieselGallonForFuelstation:(FPFuelStation *)fuelstation;

#pragma mark - Min Price Per Gallon

- (NSDecimalNumber *)yearToDateMinPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)lastYearMinPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallMinPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)yearToDateMinPricePerGallonForUser:(FPUser *)user;

- (NSDecimalNumber *)lastYearMinPricePerGallonForUser:(FPUser *)user;

- (NSDecimalNumber *)overallMinPricePerGallonForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateMinPricePerDieselGallonForUser:(FPUser *)user;

- (NSDecimalNumber *)lastYearMinPricePerDieselGallonForUser:(FPUser *)user;

- (NSDecimalNumber *)overallMinPricePerDieselGallonForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateMinPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSDecimalNumber *)lastYearMinPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallMinPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSDecimalNumber *)yearToDateMinPricePerGallonForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)lastYearMinPricePerGallonForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallMinPricePerGallonForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)yearToDateMinPricePerDieselGallonForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)lastYearMinPricePerDieselGallonForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallMinPricePerDieselGallonForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)yearToDateMinPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSDecimalNumber *)lastYearMinPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallMinPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSDecimalNumber *)yearToDateMinPricePerGallonForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)lastYearMinPricePerGallonForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)overallMinPricePerGallonForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)yearToDateMinPricePerDieselGallonForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)lastYearMinPricePerDieselGallonForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)overallMinPricePerDieselGallonForFuelstation:(FPFuelStation *)fuelstation;

#pragma mark - Miles Recorded

- (NSDecimalNumber *)milesRecordedForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)milesRecordedForVehicle:(FPVehicle *)vehicle
                                  beforeDate:(NSDate *)beforeDate
                               onOrAfterDate:(NSDate *)onOrAfterDate;

- (NSDecimalNumber *)milesDrivenSinceLastOdometerLogAndLog:(FPEnvironmentLog *)odometerLog vehicle:(FPVehicle *)vehicle;

#pragma mark - Duration Between Odometer Logs

- (NSNumber *)daysSinceLastOdometerLogAndLog:(FPEnvironmentLog *)odometerLog vehicle:(FPVehicle *)vehicle;

#pragma mark - Outside Temperature

- (NSNumber *)temperatureLastYearForUser:(FPUser *)user
                      withinDaysVariance:(NSInteger)daysVariance;

- (NSNumber *)temperatureForUser:(FPUser *)user
              oneYearAgoFromDate:(NSDate *)oneYearAgoFromDate
              withinDaysVariance:(NSInteger)daysVariance;

@end
