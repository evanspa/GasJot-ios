//
//  FPDDLUtils.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 7/26/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

@import Foundation;

//##############################################################################
// Shared columns
//##############################################################################
// ----Columns common to both main and master entities--------------------------
FOUNDATION_EXPORT NSString * const COL_MAIN_VEHICLE_ID;
FOUNDATION_EXPORT NSString * const COL_MASTER_VEHICLE_ID;
FOUNDATION_EXPORT NSString * const COL_MAIN_FUELSTATION_ID;
FOUNDATION_EXPORT NSString * const COL_MASTER_FUELSTATION_ID;

//##############################################################################
// Vehicle Entity (main and master)
//##############################################################################
// ----Table names--------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_MASTER_VEHICLE;
FOUNDATION_EXPORT NSString * const TBL_MAIN_VEHICLE;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_VEH_NAME;
FOUNDATION_EXPORT NSString * const COL_VEH_DEFAULT_OCTANE;
FOUNDATION_EXPORT NSString * const COL_VEH_FUEL_CAPACITY;
FOUNDATION_EXPORT NSString * const COL_VEH_IS_DIESEL;
FOUNDATION_EXPORT NSString * const COL_VEH_HAS_DTE_READOUT;
FOUNDATION_EXPORT NSString * const COL_VEH_HAS_MPG_READOUT;
FOUNDATION_EXPORT NSString * const COL_VEH_HAS_MPH_READOUT;
FOUNDATION_EXPORT NSString * const COL_VEH_HAS_OUTSIDE_TEMP_READOUT;
FOUNDATION_EXPORT NSString * const COL_VEH_VIN;
FOUNDATION_EXPORT NSString * const COL_VEH_PLATE;

//##############################################################################
// Fuel Station Type
//##############################################################################
// ----Table names--------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_FUEL_STATION_TYPE;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_FUELSTTYP_ID;
FOUNDATION_EXPORT NSString * const COL_FUELSTTYP_NAME;
FOUNDATION_EXPORT NSString * const COL_FUELSTTYP_ICON_IMG_NAME;
FOUNDATION_EXPORT NSString * const COL_FUELSTTYP_SORT_ORDER;

//##############################################################################
// Fuel Station Entity (main and master)
//##############################################################################
// ----Table names--------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_MASTER_FUEL_STATION;
FOUNDATION_EXPORT NSString * const TBL_MAIN_FUEL_STATION;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_FUELST_NAME;
FOUNDATION_EXPORT NSString * const COL_FUELST_TYPE_ID;
FOUNDATION_EXPORT NSString * const COL_FUELST_STREET;
FOUNDATION_EXPORT NSString * const COL_FUELST_CITY;
FOUNDATION_EXPORT NSString * const COL_FUELST_STATE;
FOUNDATION_EXPORT NSString * const COL_FUELST_ZIP;
FOUNDATION_EXPORT NSString * const COL_FUELST_LATITUDE;
FOUNDATION_EXPORT NSString * const COL_FUELST_LONGITUDE;

//##############################################################################
// Fuel Purchase Log Entity (main and master)
//##############################################################################
// ----Table names--------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_MASTER_FUELPURCHASE_LOG;
FOUNDATION_EXPORT NSString * const TBL_MAIN_FUELPURCHASE_LOG;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_FUELPL_NUM_GALLONS;
FOUNDATION_EXPORT NSString * const COL_FUELPL_PRICE_PER_GALLON;
FOUNDATION_EXPORT NSString * const COL_FUELPL_OCTANE;
FOUNDATION_EXPORT NSString * const COL_FUELPL_ODOMETER;
FOUNDATION_EXPORT NSString * const COL_FUELPL_GOT_CAR_WASH;
FOUNDATION_EXPORT NSString * const COL_FUELPL_CAR_WASH_PER_GALLON_DISCOUNT;
FOUNDATION_EXPORT NSString * const COL_FUELPL_PURCHASED_AT;
FOUNDATION_EXPORT NSString * const COL_FUELPL_IS_DIESEL;

//##############################################################################
// Environment Log Entity (main and master)
//##############################################################################
// ----Table names--------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_MASTER_ENV_LOG;
FOUNDATION_EXPORT NSString * const TBL_MAIN_ENV_LOG;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_ENVL_ODOMETER_READING;
FOUNDATION_EXPORT NSString * const COL_ENVL_MPG_READING;
FOUNDATION_EXPORT NSString * const COL_ENVL_MPH_READING;
FOUNDATION_EXPORT NSString * const COL_ENVL_OUTSIDE_TEMP_READING;
FOUNDATION_EXPORT NSString * const COL_ENVL_LOG_DT;
FOUNDATION_EXPORT NSString * const COL_ENVL_DTE;

@interface FPDDLUtils : NSObject

#pragma mark - Master and Main Environment Log entities

+ (NSString *)masterEnvironmentLogDDL;

+ (NSString *)mainEnvironmentDDL;

#pragma mark - Master and Main Fuel Purchase Log entities

+ (NSString *)masterFuelPurchaseLogDDL;

+ (NSString *)mainFuelPurchaseLogDDL;

#pragma mark - Fuel Station Type entity

+ (NSString *)fuelStationTypeDDL;

#pragma mark - Master and Main Fuel Station entities

+ (NSString *)masterFuelStationDDL;

+ (NSString *)mainFuelStationDDL;

#pragma mark - Master and Main Vehicle entities

+ (NSString *)masterVehicleDDL;

+ (NSString *)masterVehicleUniqueIndex1;

+ (NSString *)mainVehicleDDL;

+ (NSString *)mainVehicleUniqueIndex1;

# pragma mark - Master and Main User entities

+ (NSString *)masterUserDDL;

+ (NSString *)mainUserDDL;

+ (NSString *)mainUserUniqueIndex1;

@end
