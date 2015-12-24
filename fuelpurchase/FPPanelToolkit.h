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
  FPVehicleTagName = 5,
  FPVehicleTagTakesDieselSwitch,
  FPVehicleTagTakesDieselPanel,
  FPVehicleTagDefaultOctane,
  FPVehicleTagFuelCapacity,
  FPVehicleTagViewFplogsBtn,
  FPVehicleTagViewFplogsBtnRecordCount,
  FPVehicleTagViewEnvlogsBtn,
  FPVehicleTagViewEnvlogsBtnRecordCount,
  FPVehicleTagVin,
  FPVehicleTagPlate,
  FPVehicleTagTopPanel,
  FPVehicleTagBottomPanel,
  FPVehicleTagHasDteReadoutSwitch,
  FPVehicleTagHasDteReadoutPanel,
  FPVehicleTagHasMpgReadoutSwitch,
  FPVehicleTagHasMpgReadoutPanel,
  FPVehicleTagHasMphReadoutSwitch,
  FPVehicleTagHasMphReadoutPanel,
  FPVehicleTagHasOutsideTempReadoutSwitch,
  FPVehicleTagHasOutsideTempReadoutPanel
};

typedef NS_ENUM (NSInteger, FPFuelStationTag) {
  FPFuelStationTagType = 26,
  FPFuelStationTagName,
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
  FPFpEnvLogCompositeTagPreFillupReportedDte = 37,
  FPFpEnvLogCompositeTagPostFillupReportedDte
};

typedef NS_ENUM (NSInteger, FPFpLogTag) {
  FPFpLogTagVehicleFuelStationAndDate = 39,
  FPFpLogTagNumGallons,
  FPFpLogTagPricePerGallon,
  FPFpLogTagDieselSwitch,
  FPFpLogTagDieselPanel,
  FPFpLogTagOctane,
  FPFplogTagOdometer,
  FPFpLogTagCarWashPanel,
  FPFpLogTagCarWashPerGallonDiscount,
  FPFpLogTagGotCarWash,
  FPFpLogTagVehicle,      // used for conflict-merging
  FPFpLogTagFuelstation,  // used for conflict-merging
  FPFpLogTagPurchasedDate // used for conflict-merging
};

typedef NS_ENUM (NSInteger, FPEnvLogTag) {
  FPEnvLogTagVehicleAndDate = 52,
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

- (id)initWithCoordinatorDao:(id<FPCoordinatorDao>)coordDao
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
                             panelTag:(NSNumber *)panelTag
                 includeRefreshButton:(BOOL)includeRefreshButton
                       coordinatorDao:(id<FPCoordinatorDao>)coordDao
                            uitoolkit:(PEUIToolkit *)uitoolkit
                       relativeToView:(UIView *)relativeToView
                           controller:(UIViewController *)controller;

+ (void)refreshAccountStatusPanelForUser:(FPUser *)user
                                panelTag:(NSNumber *)panelTag
                    includeRefreshButton:(BOOL)includeRefreshButton
                          coordinatorDao:(id<FPCoordinatorDao>)coordDao
                               uitoolkit:(PEUIToolkit *)uitoolkit
                          relativeToView:(UIView *)relativeToView
                              controller:(UIViewController *)controller;

+ (UIButton *)forgotPasswordButtonForUser:(FPUser *)user
                           coordinatorDao:(id<FPCoordinatorDao>)coordDao
                                uitoolkit:(PEUIToolkit *)uitoolkit
                               controller:(UIViewController *)controller;

#pragma mark - Vehicle Panel

- (PEEntityViewPanelMakerBlk)vehicleViewPanelMaker;

- (PEEntityPanelMakerBlk)vehicleFormPanelMaker;

- (PEPanelToEntityBinderBlk)vehicleFormPanelToVehicleBinder;

- (PEEntityToPanelBinderBlk)vehicleToVehiclePanelBinder;

- (PEEnableDisablePanelBlk)vehicleFormPanelEnablerDisabler;

- (PEEntityMakerBlk)vehicleMaker;

#pragma mark - Fuel Station Panel

- (PEEntityViewPanelMakerBlk)fuelstationViewPanelMaker;

- (PEEntityPanelMakerBlk)fuelstationFormPanelMakerWithUser:(FPUser *)user
                                          defaultFsTypeBlk:(FPFuelStationType *(^)(void))defaultFsTypeBlk;

- (PEPanelToEntityBinderBlk)fuelstationFormPanelToFuelstationBinder;

- (PEEntityToPanelBinderBlk)fuelstationToFuelstationPanelBinder;

- (PEEnableDisablePanelBlk)fuelstationFormPanelEnablerDisabler;

- (PEEntityMakerBlk)fuelstationMaker;

#pragma mark - Fuel Purchase / Environment Log Composite Panel (Add only)

- (PEEntityPanelMakerBlk)fpEnvLogCompositeFormPanelMakerWithUser:(FPUser *)user
                                                  defaultVehicle:(FPVehicle *)defaultVehicle
                                              defaultFuelstation:(FPFuelStation *)defaultFuelstation
                                                         logDate:(NSDate *)logDate;

- (PEPanelToEntityBinderBlk)fpEnvLogCompositeFormPanelToFpEnvLogCompositeBinder;

- (PEEntityToPanelBinderBlk)fpEnvLogCompositeToFpEnvLogCompositePanelBinder;

- (PEEntityMakerBlk)fpEnvLogCompositeMaker;

#pragma mark - Fuel Purchase Log Panel (Edit only)

- (PEEntityViewPanelMakerBlk)fplogViewPanelMakerWithUser:(FPUser *)user;

- (PEEntityPanelMakerBlk)fplogFormPanelMakerWithUser:(FPUser *)user
                                   defaultVehicleBlk:(FPVehicle *(^)(void))defaultVehicleBlk
                               defaultFuelstationBlk:(FPFuelStation *(^)(void))defaultFuelstationBlk
                                             logDate:(NSDate *)logDate;

- (PEPanelToEntityBinderBlk)fplogFormPanelToFplogBinder;

- (PEEntityToPanelBinderBlk)fplogToFplogPanelBinder;

- (PEEnableDisablePanelBlk)fplogFormPanelEnablerDisabler;

#pragma mark - Environment Log Panel

- (PEEntityViewPanelMakerBlk)envlogViewPanelMakerWithUser:(FPUser *)user;

- (PEEntityPanelMakerBlk)envlogFormPanelMakerWithUser:(FPUser *)user
                                    defaultVehicleBlk:(FPVehicle *(^)(void))defaultVehicleBlk
                                              logDate:(NSDate *)logDate;

- (PEPanelToEntityBinderBlk)envlogFormPanelToEnvlogBinder;

- (PEEntityToPanelBinderBlk)envlogToEnvlogPanelBinder;

- (PEEnableDisablePanelBlk)envlogFormPanelEnablerDisabler;

- (PEEntityMakerBlk)envlogMaker;

@end
