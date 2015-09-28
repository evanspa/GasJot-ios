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
  FPUserTagEmail,
  FPUserTagPassword,
  FPUserTagConfirmPassword
};

typedef NS_ENUM (NSInteger, FPVehicleTag) {
  FPVehicleTagName = 1,
  FPVehicleTagDefaultOctane,
  FPVehicleTagFuelCapacity,
  FPVehicleTagViewFplogsBtn,
  FPVehicleTagViewFplogsBtnRecordCount,
  FPVehicleTagViewEnvlogsBtn,
  FPVehicleTagViewEnvlogsBtnRecordCount
};

typedef NS_ENUM (NSInteger, FPFuelStationTag) {
  FPFuelStationTagName = 6,
  FPFuelStationTagStreet,
  FPFuelStationTagCity,
  FPFuelStationTagState,
  FPFuelStationTagZip,
  FPFuelStationTagLocationCoordinates,
  FPFuelStationTagUseCurrentLocation,
  FPFuelStationTagRecomputeCoordinates,
  FPFuelStationTagViewFplogsBtn,
  FPFuelStationTagViewFplogsBtnRecordCount
};

typedef NS_ENUM (NSInteger, FPFpEnvLogCompositeTag) {
  FPFpEnvLogCompositeTagPreFillupReportedDte = 15,
  FPFpEnvLogCompositeTagPostFillupReportedDte
};

typedef NS_ENUM (NSInteger, FPFpLogTag) {
  FPFpLogTagVehicleFuelStationAndDate = 17,
  FPFpLogTagNumGallons,
  FPFpLogTagPricePerGallon,
  FPFpLogTagOctane,
  FPFpLogTagCarWashPanel,
  FPFpLogTagCarWashPerGallonDiscount,
  FPFpLogTagGotCarWash,
  FPFpLogTagVehicle,      // used for conflict-merging
  FPFpLogTagFuelstation,  // used for conflict-merging
  FPFpLogTagPurchasedDate // used for conflict-merging
};

typedef NS_ENUM (NSInteger, FPEnvLogTag) {
  FPEnvLogTagVehicleAndDate = 30,
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

#pragma mark - User Account Panels

- (PEEntityViewPanelMakerBlk)userAccountViewPanelMakerWithAccountStatusLabelTag:(NSInteger)accountStatusLabelTag;

- (PEEntityPanelMakerBlk)userAccountFormPanelMaker;

- (PEPanelToEntityBinderBlk)userFormPanelToUserBinder;

- (PEEntityToPanelBinderBlk)userToUserPanelBinder;

- (PEEnableDisablePanelBlk)userFormPanelEnablerDisabler;

+ (UIView *)accountStatusPanelForUser:(FPUser *)user
                        valueLabelTag:(NSNumber *)valueLabelTag
                            uitoolkit:(PEUIToolkit *)uitoolkit
                       relativeToView:(UIView *)relativeToView;

+ (void)refreshAccountStatusPanelForUser:(FPUser *)user
                           valueLabelTag:(NSNumber *)valueLabelTag
                          relativeToView:(UIView *)relativeToView;

#pragma mark - Vehicle Panel

- (PEEntityViewPanelMakerBlk)vehicleViewPanelMaker;

- (PEEntityPanelMakerBlk)vehicleFormPanelMakerIncludeLogButtons:(BOOL)includeLogButtons;

- (PEPanelToEntityBinderBlk)vehicleFormPanelToVehicleBinder;

- (PEEntityToPanelBinderBlk)vehicleToVehiclePanelBinder;

- (PEEnableDisablePanelBlk)vehicleFormPanelEnablerDisabler;

- (PEEntityMakerBlk)vehicleMaker;

#pragma mark - Fuel Station Panel

- (PEEntityViewPanelMakerBlk)fuelstationViewPanelMaker;

- (PEEntityPanelMakerBlk)fuelstationFormPanelMakerIncludeLogButton:(BOOL)includeLogButton;

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
                              defaultSelectedVehicle:(FPVehicle *(^)(void))defaultSelectedVehicle
                          defaultSelectedFuelStation:(FPFuelStation *(^)(void))defaultSelectedFuelStation
                                defaultPickedLogDate:(NSDate *)defaultPickedLogDate;

- (PEPanelToEntityBinderBlk)fplogFormPanelToFplogBinder;

- (PEEntityToPanelBinderBlk)fplogToFplogPanelBinder;

- (PEEnableDisablePanelBlk)fplogFormPanelEnablerDisabler;

#pragma mark - Environment Log Panel

- (PEEntityViewPanelMakerBlk)envlogViewPanelMakerWithUser:(FPUser *)user;

- (PEEntityPanelMakerBlk)envlogFormPanelMakerWithUser:(FPUser *)user
                               defaultSelectedVehicle:(FPVehicle *(^)(void))defaultSelectedVehicle
                                 defaultPickedLogDate:(NSDate *)defaultPickedLogDate;

- (PEPanelToEntityBinderBlk)envlogFormPanelToEnvlogBinder;

- (PEEntityToPanelBinderBlk)envlogToEnvlogPanelBinder;

- (PEEnableDisablePanelBlk)envlogFormPanelEnablerDisabler;

- (PEEntityMakerBlk)envlogMaker;

@end
