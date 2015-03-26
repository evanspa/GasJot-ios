//
//  FPScreenToolkit.h
//  fuelpurchase
//
//  Created by Evans, Paul on 9/17/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <iFuelPurchase-Core/FPCoordinatorDao.h>
#import <transaction-logger/TLTransactionManager.h>
#import <objc-commons/PEUIToolkit.h>
#import "PEListViewController.h"
#import "PEAddViewEditController.h"

typedef UIViewController * (^FPUnauthScreenMaker)(void);

typedef UIViewController * (^FPAuthScreenMaker)(id);

typedef UIViewController * (^FPAuthScreenMakerWithTempNotification)(id, NSString *);

@interface FPScreenToolkit : NSObject

#pragma mark - Initializers

- (id)initWithCoordinatorDao:(FPCoordinatorDao *)coordDao
          transactionManager:(TLTransactionManager *)txnMgr
                   uitoolkit:(PEUIToolkit *)uitoolkit
                       error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Properties

@property (readonly, nonatomic) PEUIToolkit *uitoolkit;

#pragma mark - Generic Screens

- (FPAuthScreenMaker)newDatePickerScreenMakerWithTitle:(NSString *)title
                                   initialSelectedDate:(NSDate *)date
                                   logDatePickedAction:(void(^)(NSDate *))logDatePickedAction;

#pragma mark - Drafts Screens

- (FPAuthScreenMaker)newViewDraftsScreenMaker;

#pragma mark - Settings Screens

- (FPAuthScreenMaker)newViewSettingsScreenMaker;

#pragma mark - Vehicle Screens

- (FPAuthScreenMaker)newViewVehiclesScreenMaker;

- (FPAuthScreenMaker)newVehiclesForSelectionScreenMakerWithItemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                                                       initialSelectedVehicle:(FPVehicle *)initialSelectedVehicle;

- (FPAuthScreenMaker)newAddVehicleScreenMakerWithDelegate:(PEItemAddedBlk)itemAddedBlk
                                       listViewController:(PEListViewController *)listViewController;

- (FPAuthScreenMaker)newVehicleDetailScreenMakerWithVehicle:(FPVehicle *)vehicle
                                           vehicleIndexPath:(NSIndexPath *)vehicleIndexPath
                                             itemChangedBlk:(PEItemChangedBlk)itemChangedBlk
                                         listViewController:(PEListViewController *)listViewController;

#pragma mark - Fuel Station Screens

- (FPAuthScreenMaker)newViewFuelStationsScreenMaker;

- (FPAuthScreenMaker)newFuelStationsForSelectionScreenMakerWithItemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                                                       initialSelectedFuelStation:(FPFuelStation *)initialSelectedFuelStation;

- (FPAuthScreenMaker)newAddFuelStationScreenMakerWithBlk:(PEItemAddedBlk)itemAddedBlk
                                      listViewController:(PEListViewController *)listViewController;

- (FPAuthScreenMaker)newFuelStationDetailScreenMakerWithFuelStation:(FPFuelStation *)fuelStation
                                               fuelStationIndexPath:(NSIndexPath *)fuelStationIndexPath
                                                     itemChangedBlk:(PEItemChangedBlk)itemChangedBlk
                                                 listViewController:(PEListViewController *)listViewController;

#pragma mark - Fuel Purchase Log Screens

- (FPAuthScreenMaker)newAddFuelPurchaseLogScreenMakerWithBlk:(PEItemAddedBlk)itemAddedBlk
                                      defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle
                                  defaultSelectedFuelStation:(FPFuelStation *)defaultSelectedFuelStation
                                          listViewController:(PEListViewController *)listViewController;

- (FPAuthScreenMaker)newViewFuelPurchaseLogsScreenMakerForVehicleInCtx;

- (FPAuthScreenMaker)newViewFuelPurchaseLogsScreenMakerForFuelStationInCtx;

#pragma mark - Environment Log Screens

- (FPAuthScreenMaker)newAddEnvironmentLogScreenMakerWithBlk:(PEItemAddedBlk)itemAddedBlk
                                     defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle
                                         listViewController:(PEListViewController *)listViewController;

//- (FPAuthScreenMaker)newViewEnvironmentLogsScreenMaker;

- (FPAuthScreenMaker)newViewEnvironmentLogsScreenMakerForVehicleInCtx;

#pragma mark - Quick Action Screen

- (FPAuthScreenMakerWithTempNotification)newQuickActionMenuScreenMaker;

#pragma mark - Unauthenticated Landing Screen

- (FPUnauthScreenMaker)newUnauthLandingScreenMakerWithTempNotification:(NSString *)msgOrKey;

#pragma mark - Tab-bar Authenticated Landing Screen

- (FPAuthScreenMaker)newTabBarAuthHomeLandingScreenMakerWithTempNotification:(NSString *)msgOrKey;

@end
