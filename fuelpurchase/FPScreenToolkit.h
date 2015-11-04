//
//  FPScreenToolkit.h
//  fuelpurchase
//
//  Created by Evans, Paul on 9/17/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PEFuelPurchase-Model/FPCoordinatorDao.h>
#import <PEObjc-Commons/PEUIToolkit.h>
#import "PEListViewController.h"
#import "PEAddViewEditController.h"
#import <PEObjc-Commons/PEUIUtils.h>

typedef UIViewController * (^FPUnauthScreenMaker)(void);

typedef UIViewController * (^FPAuthScreenMaker)(id);

@interface FPScreenToolkit : NSObject

#pragma mark - Initializers

- (id)initWithCoordinatorDao:(FPCoordinatorDao *)coordDao
                   uitoolkit:(PEUIToolkit *)uitoolkit
                       error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Properties

@property (readonly, nonatomic) PEUIToolkit *uitoolkit;

#pragma mark - Generic Screens

- (FPAuthScreenMaker)newDatePickerScreenMakerWithTitle:(NSString *)title
                                   initialSelectedDate:(NSDate *)date
                                   logDatePickedAction:(void(^)(NSDate *))logDatePickedAction;

#pragma mark - Drafts Screens

- (FPAuthScreenMaker)newViewUnsyncedEditsScreenMaker;

#pragma mark - Settings Screens

- (FPAuthScreenMaker)newViewSettingsScreenMaker;

#pragma mark - User Account Screens

- (FPAuthScreenMaker)newUserAccountDetailScreenMaker;

#pragma mark - User Stat Screens

- (FPAuthScreenMaker)newUserStatsLaunchScreenMaker;

- (FPAuthScreenMaker)newAvgDaysBetweenFillupsStatsScreenMaker;

- (FPAuthScreenMaker)newAvgPricePerGallonStatsScreenMakerWithOctane:(NSNumber *)octane;

- (FPAuthScreenMaker)newSpentOnGasStatsScreenMaker;

- (FPAuthScreenMaker)newGasCostPerMileStatsScreenMaker;

#pragma mark - Vehicle Screens

- (FPAuthScreenMaker)newViewVehiclesScreenMaker;

- (FPAuthScreenMaker)newViewUnsyncedVehiclesScreenMaker;

- (FPAuthScreenMaker)newVehiclesForSelectionScreenMakerWithItemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                                                       initialSelectedVehicle:(FPVehicle *)initialSelectedVehicle;

- (FPAuthScreenMaker)newAddVehicleScreenMakerWithDelegate:(PEItemAddedBlk)itemAddedBlk
                                       listViewController:(PEListViewController *)listViewController;

- (FPAuthScreenMaker)newVehicleDetailScreenMakerWithVehicle:(FPVehicle *)vehicle
                                           vehicleIndexPath:(NSIndexPath *)vehicleIndexPath
                                             itemChangedBlk:(PEItemChangedBlk)itemChangedBlk
                                         listViewController:(PEListViewController *)listViewController;

#pragma mark - Vehicle Stat Screens

- (FPAuthScreenMaker)newVehicleStatsLaunchScreenMakerWithVehicle:(FPVehicle *)vehicle;

- (FPAuthScreenMaker)newVehicleAvgDaysBetweenFillupsStatsScreenMakerWithVehicle:(FPVehicle *)vehicle;

- (FPAuthScreenMaker)newVehicleAvgPricePerGallonStatsScreenMakerWithVehicle:(FPVehicle *)vehicle
                                                                     octane:(NSNumber *)octane;

- (FPAuthScreenMaker)newVehicleCompareAvgPricePerGallonStatsScreenMakerWithVehicleInCtx:(FPVehicle *)vehicle
                                                                                 octane:(NSNumber *)octane;

- (FPAuthScreenMaker)newVehicleGasCostPerMileStatsScreenMakerWithVehicle:(FPVehicle *)vehicle;

- (FPAuthScreenMaker)newVehicleCompareGasCostPerMileStatsScreenMakerWithVehicleInCtx:(FPVehicle *)vehicle;

- (FPAuthScreenMaker)newVehicleCompareGasCostPerMileStatsScreenMaker;

- (FPAuthScreenMaker)newVehicleSpentOnGasStatsScreenMakerWithVehicle:(FPVehicle *)vehicle;

- (FPAuthScreenMaker)newVehicleCompareSpentOnGasStatsScreenMakerWithVehicleInCtx:(FPVehicle *)vehicle;

- (FPAuthScreenMaker)newVehicleCompareSpentOnGasStatsScreenMaker;

#pragma mark - Fuel Station Screens

- (void)addDistanceInfoToTopOfCellContentView:(UIView *)contentView
                          withVerticalPadding:(CGFloat)verticalPadding
                            horizontalPadding:(CGFloat)horizontalPadding
                              withFuelstation:(FPFuelStation *)fuelstation;

- (void)addDistanceInfoToTopOfCellContentView:(UIView *)contentView
                      withHorizontalAlignment:(PEUIHorizontalAlignmentType)horizontalAlignment
                          withVerticalPadding:(CGFloat)verticalPadding
                            horizontalPadding:(CGFloat)horizontalPadding
                              withFuelstation:(FPFuelStation *)fuelstation;

- (FPAuthScreenMaker)newViewFuelStationsScreenMaker;

- (FPAuthScreenMaker)newViewUnsyncedFuelStationsScreenMaker;

- (FPAuthScreenMaker)newFuelStationsForSelectionScreenMakerWithItemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                                                       initialSelectedFuelStation:(FPFuelStation *)initialSelectedFuelStation;

- (FPAuthScreenMaker)newAddFuelStationScreenMakerWithBlk:(PEItemAddedBlk)itemAddedBlk
                                      listViewController:(PEListViewController *)listViewController;

- (FPAuthScreenMaker)newFuelStationDetailScreenMakerWithFuelStation:(FPFuelStation *)fuelStation
                                               fuelStationIndexPath:(NSIndexPath *)fuelStationIndexPath
                                                     itemChangedBlk:(PEItemChangedBlk)itemChangedBlk
                                                 listViewController:(PEListViewController *)listViewController;

#pragma mark - Fuel Station Stat Screens

- (FPAuthScreenMaker)newFuelStationStatsLaunchScreenMakerWithFuelstation:(FPFuelStation *)fuelstation;

- (FPAuthScreenMaker)newFuelStationAvgPricePerGallonStatsScreenMakerWithFuelstation:(FPFuelStation *)fuelstation
                                                                             octane:(NSNumber *)octane;

- (FPAuthScreenMaker)newFuelStationCompareAvgPricePerGallonStatsScreenMakerWithFuelstationInCtx:(FPFuelStation *)fuelstation
                                                                                         octane:(NSNumber *)octane;

- (FPAuthScreenMaker)newFuelStationSpentOnGasStatsScreenMakerWithFuelstation:(FPFuelStation *)fuelstation;

- (FPAuthScreenMaker)newFuelStationCompareSpentOnGasStatsScreenMakerWithFuelstationInCtx:(FPFuelStation *)fuelstation;

- (FPAuthScreenMaker)newFuelStationCompareSpentOnGasStatsScreenMaker;

#pragma mark - Fuel Purchase Log Screens

- (FPAuthScreenMaker)newAddFuelPurchaseLogScreenMakerWithBlk:(PEItemAddedBlk)itemAddedBlk
                                      defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle
                                  defaultSelectedFuelStation:(FPFuelStation *)defaultSelectedFuelStation
                                          listViewController:(PEListViewController *)listViewController;

- (FPAuthScreenMaker)newViewFuelPurchaseLogsScreenMaker;

- (FPAuthScreenMaker)newViewFuelPurchaseLogsScreenMakerForVehicleInCtx;

- (FPAuthScreenMaker)newViewFuelPurchaseLogsScreenMakerForFuelStationInCtx;

- (FPAuthScreenMaker)newViewUnsyncedFuelPurchaseLogsScreenMaker;

#pragma mark - Environment Log Screens

- (FPAuthScreenMaker)newAddEnvironmentLogScreenMakerWithBlk:(PEItemAddedBlk)itemAddedBlk
                                     defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle
                                         listViewController:(PEListViewController *)listViewController;

- (FPAuthScreenMaker)newViewEnvironmentLogsScreenMaker;

- (FPAuthScreenMaker)newViewEnvironmentLogsScreenMakerForVehicleInCtx;

- (FPAuthScreenMaker)newViewUnsyncedEnvironmentLogsScreenMaker;

#pragma mark - Home Screen

- (FPAuthScreenMaker)newHomeScreenMaker;

#pragma mark - Records Screen

- (FPAuthScreenMaker)newRecordsScreenMaker;

#pragma mark - Jot Screen

- (FPAuthScreenMaker)newJotScreenMaker;

#pragma mark - Tab-bar Authenticated Landing Screen

- (FPAuthScreenMaker)newTabBarHomeLandingScreenMakerIsLoggedIn:(BOOL)isLoggedIn
                                               tagForJotButton:(NSInteger)tagForJotButton;

- (UIViewController *)unsynedEditsViewControllerForUser:(FPUser *)user;

@end
