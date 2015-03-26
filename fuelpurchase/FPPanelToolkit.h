//
//  FPPanelToolkit.h
//  fuelpurchase
//
//  Created by Evans, Paul on 10/1/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc-commons/PEUIToolkit.h>
#import "PEAddViewEditController.h"
#import <iFuelPurchase-Core/FPCoordinatorDao.h>
#import "FPScreenToolkit.h"

typedef NS_ENUM (NSInteger, FPVehicleTag) {
  FPVehicleTagName = 1
};

typedef NS_ENUM (NSInteger, FPFuelStationTag) {
  FPFuelStationTagName = 2,
  FPFuelStationTagStreet,
  FPFuelStationTagCity,
  FPFuelStationTagState,
  FPFuelStationTagZip,
  FPFuelStationTagLocationCoordinates,
  FPFuelStationTagUseCurrentLocation,
  FPFuelStationTagRecomputeCoordinates
};

typedef NS_ENUM (NSInteger, FPFpEnvLogCompositeTag) {
  FPFpEnvLogCompositeTagPreFillupReportedDte = 10,
  FPFpEnvLogCompositeTagPostFillupReportedDte
};

typedef NS_ENUM (NSInteger, FPFpLogTag) {
  FPFpLogTagVehicleFuelStationAndDate = 12,
  FPFpLogTagNumGallons,
  FPFpLogTagPricePerGallon,
  FPFpLogTagOctane,
  FPFpLogTagCarWashPanel,
  FPFpLogTagCarWashPerGallonDiscount,
  FPFpLogTagGotCarWash
};

typedef NS_ENUM (NSInteger, FPEnvLogTag) {
  FPEnvLogTagVehicleAndDate = 19,
  FPEnvLogTagOdometer,
  FPEnvLogTagReportedAvgMpg,
  FPEnvLogTagReportedAvgMph,
  FPEnvLogTagReportedOutsideTemp,
  FPEnvLogTagReportedDte
};

FOUNDATION_EXPORT NSString * const FPFpLogEntityMakerFpLogEntry;
FOUNDATION_EXPORT NSString * const FPFpLogEntityMakerVehicleEntry;
FOUNDATION_EXPORT NSString * const FPFpLogEntityMakerFuelStationEntry;

@interface FPPanelToolkit : NSObject

#pragma mark - Initializers

- (id)initWithCoordinatorDao:(FPCoordinatorDao *)coordDao
               screenToolkit:(FPScreenToolkit *)screenToolkit
                   uitoolkit:(PEUIToolkit *)uitoolkit
                       error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Vehicle Panel

- (PEEntityPanelMakerBlk)vehiclePanelMaker;

- (PEPanelToEntityBinderBlk)vehiclePanelToVehicleBinder;

- (PEEntityToPanelBinderBlk)vehicleToVehiclePanelBinder;

- (PEEnableDisablePanelBlk)vehiclePanelEnablerDisabler;

- (PEEntityMakerBlk)vehicleMaker;

#pragma mark - Fuel Station Panel

- (PEEntityPanelMakerBlk)fuelStationPanelMaker;

- (PEPanelToEntityBinderBlk)fuelStationPanelToFuelStationBinder;

- (PEEntityToPanelBinderBlk)fuelStationToFuelStationPanelBinder;

- (PEEnableDisablePanelBlk)fuelStationPanelEnablerDisabler;

- (PEEntityMakerBlk)fuelStationMaker;

#pragma mark - Fuel Purchase / Environment Log Composite Panel (Add only)

- (PEEntityPanelMakerBlk)fpEnvLogCompositePanelMakerWithUser:(FPUser *)user
                                      defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle
                                  defaultSelectedFuelStation:(FPFuelStation *)defaultSelectedFuelStation
                                        defaultPickedLogDate:(NSDate *)defaultPickedLogDate;

- (PEPanelToEntityBinderBlk)fpEnvLogCompositePanelToFpEnvLogCompositeBinder;

- (PEEntityToPanelBinderBlk)fpEnvLogCompositeToFpEnvLogCompositePanelBinder;

- (PEEntityMakerBlk)fpEnvLogCompositeMaker;

#pragma mark - Fuel Purchase Log Panel (Edit only)

- (PEEntityPanelMakerBlk)fuelPurchaseLogPanelMakerWithUser:(FPUser *)user
                                    defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle
                                defaultSelectedFuelStation:(FPFuelStation *)defaultSelectedFuelStation
                                      defaultPickedLogDate:(NSDate *)defaultPickedLogDate;

- (PEPanelToEntityBinderBlk)fuelPurchaseLogPanelToFuelPurchaseLogBinder;

- (PEEntityToPanelBinderBlk)fuelPurchaseLogToFuelPurchaseLogPanelBinder;

- (PEEnableDisablePanelBlk)fuelPurchaseLogPanelEnablerDisabler;

#pragma mark - Environment Log Panel

- (PEEntityPanelMakerBlk)environmentLogPanelMakerWithUser:(FPUser *)user
                                   defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle
                                     defaultPickedLogDate:(NSDate *)defaultPickedLogDate;

- (PEPanelToEntityBinderBlk)environmentLogPanelToEnvironmentLogBinder;

- (PEEntityToPanelBinderBlk)environmentLogToEnvironmentLogPanelBinder;

- (PEEnableDisablePanelBlk)environmentLogPanelEnablerDisabler;

- (PEEntityMakerBlk)environmentLogMaker;

@end
