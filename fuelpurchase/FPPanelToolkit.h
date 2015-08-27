//
//  FPPanelToolkit.h
//  fuelpurchase
//
//  Created by Evans, Paul on 10/1/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PEObjc-Commons/PEUIToolkit.h>
#import "PEAddViewEditController.h"
#import <PEFuelPurchase-Model/FPCoordinatorDao.h>
#import "FPScreenToolkit.h"

typedef NS_ENUM (NSInteger, FPUserTag) {
  FPUserTagName = 1,
  FPUserTagEmail = 2,
  FPUserTagUsername = 3,
  FPUserTagPassword = 4,
  FPUserTagConfirmPassword = 5
};

typedef NS_ENUM (NSInteger, FPVehicleTag) {
  FPVehicleTagName = 1,
  FPVehicleTagDefaultOctane = 2,
  FPVehicleTagFuelCapacity = 3
};

typedef NS_ENUM (NSInteger, FPFuelStationTag) {
  FPFuelStationTagName = 4,
  FPFuelStationTagStreet,
  FPFuelStationTagCity,
  FPFuelStationTagState,
  FPFuelStationTagZip,
  FPFuelStationTagLocationCoordinates,
  FPFuelStationTagUseCurrentLocation,
  FPFuelStationTagRecomputeCoordinates
};

typedef NS_ENUM (NSInteger, FPFpEnvLogCompositeTag) {
  FPFpEnvLogCompositeTagPreFillupReportedDte = 12,
  FPFpEnvLogCompositeTagPostFillupReportedDte
};

typedef NS_ENUM (NSInteger, FPFpLogTag) {
  FPFpLogTagVehicleFuelStationAndDate = 14,
  FPFpLogTagNumGallons,
  FPFpLogTagPricePerGallon,
  FPFpLogTagOctane,
  FPFpLogTagCarWashPanel,
  FPFpLogTagCarWashPerGallonDiscount,
  FPFpLogTagGotCarWash
};

typedef NS_ENUM (NSInteger, FPEnvLogTag) {
  FPEnvLogTagVehicleAndDate = 21,
  FPEnvLogTagOdometer,
  FPEnvLogTagReportedAvgMpg,
  FPEnvLogTagReportedAvgMph,
  FPEnvLogTagReportedOutsideTemp,
  FPEnvLogTagReportedDte,
  FPEnvLogTagVehicle, // used for conflict-merging
  FPEnvLogTagLogDate, // used for conflict-merging
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

#pragma mark - User Account Panel

- (PEEntityViewPanelMakerBlk)userAccountViewPanelMaker;

- (PEEntityPanelMakerBlk)userAccountFormPanelMaker;

- (PEPanelToEntityBinderBlk)userFormPanelToUserBinder;

- (PEEntityToPanelBinderBlk)userToUserPanelBinder;

- (PEEnableDisablePanelBlk)userFormPanelEnablerDisabler;

#pragma mark - Vehicle Panel

- (PEEntityViewPanelMakerBlk)vehicleViewPanelMaker;

- (PEEntityPanelMakerBlk)vehicleFormPanelMaker;

- (PEPanelToEntityBinderBlk)vehicleFormPanelToVehicleBinder;

- (PEEntityToPanelBinderBlk)vehicleToVehiclePanelBinder;

- (PEEnableDisablePanelBlk)vehicleFormPanelEnablerDisabler;

- (PEEntityMakerBlk)vehicleMaker;

#pragma mark - Fuel Station Panel

- (PEEntityViewPanelMakerBlk)fuelstationViewPanelMaker;

- (PEEntityPanelMakerBlk)fuelstationFormPanelMaker;

- (PEPanelToEntityBinderBlk)fuelstationFormPanelToFuelstationBinder;

- (PEEntityToPanelBinderBlk)fuelstationToFuelstationPanelBinder;

- (PEEnableDisablePanelBlk)fuelstationFormPanelEnablerDisabler;

- (PEEntityMakerBlk)fuelstationMaker;

#pragma mark - Fuel Purchase / Environment Log Composite Panel (Add only)

- (PEEntityPanelMakerBlk)fpEnvLogCompositeFormPanelMakerWithUser:(FPUser *)user
                                      defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle
                                  defaultSelectedFuelStation:(FPFuelStation *)defaultSelectedFuelStation
                                        defaultPickedLogDate:(NSDate *)defaultPickedLogDate;

- (PEPanelToEntityBinderBlk)fpEnvLogCompositeFormPanelToFpEnvLogCompositeBinder;

- (PEEntityToPanelBinderBlk)fpEnvLogCompositeToFpEnvLogCompositePanelBinder;

- (PEEntityMakerBlk)fpEnvLogCompositeMaker;

#pragma mark - Fuel Purchase Log Panel (Edit only)

- (PEEntityViewPanelMakerBlk)fplogViewPanelMakerWithUser:(FPUser *)user;

- (PEEntityPanelMakerBlk)fplogFormPanelMakerWithUser:(FPUser *)user                          
                              defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle
                          defaultSelectedFuelStation:(FPFuelStation *)defaultSelectedFuelStation
                                defaultPickedLogDate:(NSDate *)defaultPickedLogDate;

- (PEPanelToEntityBinderBlk)fplogFormPanelToFplogBinder;

- (PEEntityToPanelBinderBlk)fplogToFplogPanelBinder;

- (PEEnableDisablePanelBlk)fplogFormPanelEnablerDisabler;

#pragma mark - Environment Log Panel

- (PEEntityViewPanelMakerBlk)envlogViewPanelMakerWithUser:(FPUser *)user;

- (PEEntityPanelMakerBlk)envlogFormPanelMakerWithUser:(FPUser *)user
                                   defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle
                                     defaultPickedLogDate:(NSDate *)defaultPickedLogDate;

- (PEPanelToEntityBinderBlk)envlogFormPanelToEnvlogBinder;

- (PEEntityToPanelBinderBlk)envlogToEnvlogPanelBinder;

- (PEEnableDisablePanelBlk)envlogFormPanelEnablerDisabler;

- (PEEntityMakerBlk)envlogMaker;

@end
