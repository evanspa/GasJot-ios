//
//  FPLocalDao.h
//  Gas Jot Model
//
//  Created by Paul Evans on 12/12/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import <PELocal-Data/PELMDefs.h>

@class CLLocation;
@protocol PELocalDao;
@class FPUser;
@class FPVehicle;
@class FPFuelStation;
@class FPFuelStationType;
@class FPFuelPurchaseLog;
@class FPEnvironmentLog;

@protocol FPLocalDao <PELocalDao>

#pragma mark - Initializers

- (id)initWithSqliteDataFilePath:(NSString *)sqliteDataFilePath;

#pragma mark - Initialize Database

- (void)initializeDatabaseWithError:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Export

- (void)exportWithPathToVehiclesFile:(NSString *)vehiclesPath
                     gasStationsFile:(NSString *)gasStationsFile
                         gasLogsFile:(NSString *)gasLogsFile
                    odometerLogsFile:(NSString *)odometerLogsFile
                                user:(FPUser *)user
                               error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Unsynced and Sync-Needed Counts

- (NSInteger)numUnsyncedVehiclesForUser:(FPUser *)user;

- (NSInteger)numUnsyncedFuelStationsForUser:(FPUser *)user;

- (NSInteger)numUnsyncedFuelPurchaseLogsForUser:(FPUser *)user;

- (NSInteger)numUnsyncedEnvironmentLogsForUser:(FPUser *)user;

- (NSInteger)totalNumUnsyncedEntitiesForUser:(FPUser *)user;

- (NSInteger)numSyncNeededVehiclesForUser:(FPUser *)user;

- (NSInteger)numSyncNeededFuelStationsForUser:(FPUser *)user;

- (NSInteger)numSyncNeededFuelPurchaseLogsForUser:(FPUser *)user;

- (NSInteger)numSyncNeededEnvironmentLogsForUser:(FPUser *)user;

- (NSInteger)totalNumSyncNeededEntitiesForUser:(FPUser *)user;

#pragma mark - Vehicle

- (FPVehicle *)masterVehicleWithId:(NSNumber *)vehicleId error:(PELMDaoErrorBlk)errorBlk;

- (FPVehicle *)masterVehicleWithGlobalId:(NSString *)globalId error:(PELMDaoErrorBlk)errorBlk;

- (void)deleteVehicle:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk;

- (void)copyVehicleToMaster:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numVehiclesForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)vehiclesForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)dieselVehiclesForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unsyncedVehiclesForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (FPUser *)userForVehicle:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk;

- (void)persistDeepVehicleFromRemoteMaster:(FPVehicle *)vehicle
                                   forUser:(FPUser *)user
                                     error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewVehicle:(FPVehicle *)vehicle forUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewAndSyncImmediateVehicle:(FPVehicle *)vehicle
                               forUser:(FPUser *)user
                                 error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)prepareVehicleForEdit:(FPVehicle *)vehicle
                      forUser:(FPUser *)user
                        error:(PELMDaoErrorBlk)errorBlk;

- (void)saveVehicle:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingVehicle:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingImmediateSyncVehicle:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk;

- (void)reloadVehicle:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelEditOfVehicle:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)markVehiclesAsSyncInProgressForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelSyncForVehicle:(FPVehicle *)vehicle
                httpRespCode:(NSNumber *)httpRespCode
                   errorMask:(NSNumber *)errorMask
                     retryAt:(NSDate *)retryAt
                       error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewMasterVehicle:(FPVehicle *)vehicle
                     forUser:(FPUser *)user
                       error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)saveMasterVehicle:(FPVehicle *)vehicle
                  forUser:(FPUser *)user
                    error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForNewVehicle:(FPVehicle *)vehicle
                                forUser:(FPUser *)user
                                  error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForUpdatedVehicle:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk;

- (FPVehicle *)vehicleWithMostRecentLogForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Fuel Station

- (FPFuelStation *)masterFuelstationWithId:(NSNumber *)fuelstationId error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelStation *)masterFuelstationWithGlobalId:(NSString *)globalId error:(PELMDaoErrorBlk)errorBlk;

- (void)deleteFuelstation:(FPFuelStation *)fuelstation error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numFuelStationsForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)fuelStationsForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unsyncedFuelStationsForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (FPUser *)userForFuelStation:(FPFuelStation *)fuelStation error:(PELMDaoErrorBlk)errorBlk;

- (void)persistDeepFuelStationFromRemoteMaster:(FPFuelStation *)fuelStation
                                       forUser:(FPUser *)user
                                         error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewFuelStation:(FPFuelStation *)fuelStation
                   forUser:(FPUser *)user
                     error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewAndSyncImmediateFuelStation:(FPFuelStation *)fuelStation
                                   forUser:(FPUser *)user
                                     error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)prepareFuelStationForEdit:(FPFuelStation *)fuelStation
                          forUser:(FPUser *)user
                            error:(PELMDaoErrorBlk)errorBlk;

- (void)saveFuelStation:(FPFuelStation *)fuelStation
                  error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingFuelStation:(FPFuelStation *)fuelStation
                               error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingImmediateSyncFuelStation:(FPFuelStation *)fuelStation
                                            error:(PELMDaoErrorBlk)errorBlk;

- (void)reloadFuelStation:(FPFuelStation *)fuelStation
                    error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelEditOfFuelStation:(FPFuelStation *)fuelStation
                          error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)markFuelStationsAsSyncInProgressForUser:(FPUser *)user
                                               error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelSyncForFuelStation:(FPFuelStation *)fuelStation
                    httpRespCode:(NSNumber *)httpRespCode
                       errorMask:(NSNumber *)errorMask
                         retryAt:(NSDate *)retryAt
                           error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewMasterFuelstation:(FPFuelStation *)fuelstation
                         forUser:(FPUser *)user
                           error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)saveMasterFuelstation:(FPFuelStation *)fuelstation
                      forUser:(FPUser *)user
                        error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForNewFuelStation:(FPFuelStation *)fuelStation
                                    forUser:(FPUser *)user
                                      error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForUpdatedFuelStation:(FPFuelStation *)fuelStation error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelStationType *)fuelstationTypeForIdentifier:(NSNumber *)identifier error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)fuelstationTypesWithError:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Fuel Purchase Log

- (NSArray *)distinctOctanesForUser:(FPUser *)user
                              error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)hasDieselLogsForUser:(FPUser *)user
                       error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)distinctOctanesForVehicle:(FPVehicle *)vehicle
                                 error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)hasDieselLogsForVehicle:(FPVehicle *)vehicle
                          error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)distinctOctanesForFuelstation:(FPFuelStation *)fuelstation
                                     error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)hasDieselLogsForFuelstation:(FPFuelStation *)fuelstation
                              error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForFuelstation:(FPFuelStation *)fuelstation
                                               error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForFuelstation:(FPFuelStation *)fuelstation
                                          beforeDate:(NSDate *)beforeDate
                                       onOrAfterDate:(NSDate *)onOrAfterDate
                                               error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForFuelstation:(FPFuelStation *)fuelstation
                                          beforeDate:(NSDate *)beforeDate
                                       onOrAfterDate:(NSDate *)onOrAfterDate
                                              octane:(NSNumber *)octane
                                               error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedDieselFuelPurchaseLogsForFuelstation:(FPFuelStation *)fuelstation
                                                beforeDate:(NSDate *)beforeDate
                                             onOrAfterDate:(NSDate *)onOrAfterDate
                                                     error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForFuelstation:(FPFuelStation *)fuelstation
                                              octane:(NSNumber *)octane
                                               error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedDieselFuelPurchaseLogsForFuelstation:(FPFuelStation *)fuelstation
                                                     error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                    beforeDate:(NSDate *)beforeDate
                                                 onOrAfterDate:(NSDate *)onOrAfterDate
                                                        octane:(NSNumber *)octane
                                                         error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                    beforeDate:(NSDate *)beforeDate
                                                 onOrAfterDate:(NSDate *)onOrAfterDate
                                                         error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)maxGallonPriceDieselFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                          beforeDate:(NSDate *)beforeDate
                                                       onOrAfterDate:(NSDate *)onOrAfterDate
                                                               error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                    beforeDate:(NSDate *)beforeDate
                                                 onOrAfterDate:(NSDate *)onOrAfterDate
                                                        octane:(NSNumber *)octane
                                                         error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                    beforeDate:(NSDate *)beforeDate
                                                 onOrAfterDate:(NSDate *)onOrAfterDate
                                                         error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)minGallonPriceDieselFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                          beforeDate:(NSDate *)beforeDate
                                                       onOrAfterDate:(NSDate *)onOrAfterDate
                                                               error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                        octane:(NSNumber *)octane
                                                         error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                         error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)maxGallonPriceDieselFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                               error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                        octane:(NSNumber *)octane
                                                         error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                         error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)minGallonPriceDieselFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                               error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                        beforeDate:(NSDate *)beforeDate
                                                     onOrAfterDate:(NSDate *)onOrAfterDate
                                                            octane:(NSNumber *)octane
                                                             error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                        beforeDate:(NSDate *)beforeDate
                                                     onOrAfterDate:(NSDate *)onOrAfterDate
                                                             error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)maxGallonPriceDieselFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                              beforeDate:(NSDate *)beforeDate
                                                           onOrAfterDate:(NSDate *)onOrAfterDate
                                                                   error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                        beforeDate:(NSDate *)beforeDate
                                                     onOrAfterDate:(NSDate *)onOrAfterDate
                                                            octane:(NSNumber *)octane
                                                             error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                        beforeDate:(NSDate *)beforeDate
                                                     onOrAfterDate:(NSDate *)onOrAfterDate
                                                             error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)minGallonPriceDieselFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                              beforeDate:(NSDate *)beforeDate
                                                           onOrAfterDate:(NSDate *)onOrAfterDate
                                                                   error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                            octane:(NSNumber *)octane
                                                             error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                             error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)maxGallonPriceDieselFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                                   error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                            octane:(NSNumber *)octane
                                                             error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                             error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)minGallonPriceDieselFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                                   error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                           error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                      beforeDate:(NSDate *)beforeDate
                                   onOrAfterDate:(NSDate *)onOrAfterDate
                                           error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                      beforeDate:(NSDate *)beforeDate
                                       afterDate:(NSDate *)afterDate
                                           error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                      beforeDate:(NSDate *)beforeDate
                                   onOrAfterDate:(NSDate *)onOrAfterDate
                                          octane:(NSNumber *)octane
                                           error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedDieselFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                            beforeDate:(NSDate *)beforeDate
                                         onOrAfterDate:(NSDate *)onOrAfterDate
                                                 error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                      beforeDate:(NSDate *)beforeDate
                                       afterDate:(NSDate *)afterDate
                                          octane:(NSNumber *)octane
                                           error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedDieselFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                            beforeDate:(NSDate *)beforeDate
                                             afterDate:(NSDate *)afterDate
                                                 error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                          octane:(NSNumber *)octane
                                           error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedDieselFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                                 error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForUser:(FPUser *)user
                                        error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForUser:(FPUser *)user
                                   beforeDate:(NSDate *)beforeDate
                                onOrAfterDate:(NSDate *)onOrAfterDate
                                        error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForUser:(FPUser *)user
                                   beforeDate:(NSDate *)beforeDate
                                onOrAfterDate:(NSDate *)onOrAfterDate
                                       octane:(NSNumber *)octane
                                        error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedDieselFuelPurchaseLogsForUser:(FPUser *)user
                                         beforeDate:(NSDate *)beforeDate
                                      onOrAfterDate:(NSDate *)onOrAfterDate
                                              error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForUser:(FPUser *)user
                                       octane:(NSNumber *)octane
                                        error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedDieselFuelPurchaseLogsForUser:(FPUser *)user
                                              error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)firstGasLogForUser:(FPUser *)user
                                    error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)firstGasLogForUser:(FPUser *)user
                                   octane:(NSNumber *)octane
                                    error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)firstDieselGasLogForUser:(FPUser *)user
                                          error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)firstGasLogForVehicle:(FPVehicle *)vehicle
                                       error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)firstGasLogForVehicle:(FPVehicle *)vehicle
                                      octane:(NSNumber *)octane
                                       error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)firstDieselGasLogForVehicle:(FPVehicle *)vehicle
                                             error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)firstGasLogForVehicle:(FPVehicle *)vehicle
                                  beforeDate:(NSDate *)beforeDate
                               onOrAfterDate:(NSDate *)onOrAfterDate
                                       error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)firstGasLogForFuelstation:(FPFuelStation *)fuelstation
                                           error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)firstGasLogForFuelstation:(FPFuelStation *)fuelstation
                                          octane:(NSNumber *)octane
                                           error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)firstDieselGasLogForFuelstation:(FPFuelStation *)fuelstation
                                                 error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)lastGasLogForUser:(FPUser *)user
                                   error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)lastGasLogForUser:(FPUser *)user
                                  octane:(NSNumber *)octane
                                   error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)lastDieselGasLogForUser:(FPUser *)user
                                         error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)lastGasLogForVehicle:(FPVehicle *)vehicle
                                      error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)lastGasLogForVehicle:(FPVehicle *)vehicle
                                     octane:(NSNumber *)octane
                                      error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)lastDieselGasLogForVehicle:(FPVehicle *)vehicle
                                            error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)lastGasLogForVehicle:(FPVehicle *)vehicle
                                 beforeDate:(NSDate *)beforeDate
                              onOrAfterDate:(NSDate *)onOrAfterDate
                                      error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)lastGasLogForFuelstation:(FPFuelStation *)fuelstation
                                          error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)lastGasLogForFuelstation:(FPFuelStation *)fuelstation
                                         octane:(NSNumber *)octane
                                          error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)lastDieselGasLogForFuelstation:(FPFuelStation *)fuelstation
                                                error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)gasLogNearestToDate:(NSDate *)date
                      forVehicle:(FPVehicle *)vehicle
                           error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)gasLogNearestToDate:(NSDate *)date
                         forUser:(FPUser *)user
                          octane:(NSNumber *)octane
                           error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)dieselGasLogNearestToDate:(NSDate *)date
                               forUser:(FPUser *)user
                                 error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForUser:(FPUser *)user
                                                 beforeDate:(NSDate *)beforeDate
                                              onOrAfterDate:(NSDate *)onOrAfterDate
                                                     octane:(NSNumber *)octane
                                                      error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForUser:(FPUser *)user
                                                 beforeDate:(NSDate *)beforeDate
                                              onOrAfterDate:(NSDate *)onOrAfterDate
                                                      error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)maxGallonPriceDieselFuelPurchaseLogForUser:(FPUser *)user
                                                       beforeDate:(NSDate *)beforeDate
                                                    onOrAfterDate:(NSDate *)onOrAfterDate
                                                            error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForUser:(FPUser *)user
                                                 beforeDate:(NSDate *)beforeDate
                                              onOrAfterDate:(NSDate *)onOrAfterDate
                                                     octane:(NSNumber *)octane
                                                      error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForUser:(FPUser *)user
                                                 beforeDate:(NSDate *)beforeDate
                                              onOrAfterDate:(NSDate *)onOrAfterDate
                                                      error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)minGallonPriceDieselFuelPurchaseLogForUser:(FPUser *)user
                                                       beforeDate:(NSDate *)beforeDate
                                                    onOrAfterDate:(NSDate *)onOrAfterDate
                                                            error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForUser:(FPUser *)user
                                                     octane:(NSNumber *)octane
                                                      error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForUser:(FPUser *)user
                                                      error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)maxGallonPriceDieselFuelPurchaseLogForUser:(FPUser *)user
                                                            error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForUser:(FPUser *)user
                                                     octane:(NSNumber *)octane
                                                      error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForUser:(FPUser *)user
                                                      error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)minGallonPriceDieselFuelPurchaseLogForUser:(FPUser *)user
                                                            error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)masterFplogWithId:(NSNumber *)fplogId
                                   error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)masterFplogWithGlobalId:(NSString *)globalId
                                         error:(PELMDaoErrorBlk)errorBlk;

- (void)deleteFuelPurchaseLog:(FPFuelPurchaseLog *)fplog
                        error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numFuelPurchaseLogsForUser:(FPUser *)user
                                  error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numFuelPurchaseLogsForUser:(FPUser *)user
                              newerThan:(NSDate *)newerThan
                                  error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)fuelPurchaseLogsForUser:(FPUser *)user
                            pageSize:(NSInteger)pageSize
                               error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unsyncedFuelPurchaseLogsForUser:(FPUser *)user
                                       error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)fuelPurchaseLogsForUser:(FPUser *)user
                            pageSize:(NSInteger)pageSize
                    beforeDateLogged:(NSDate *)beforeDateLogged
                               error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                     error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                 newerThan:(NSDate *)newerThan
                                     error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)fuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                               pageSize:(NSInteger)pageSize
                                  error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)fuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                               pageSize:(NSInteger)pageSize
                       beforeDateLogged:(NSDate *)beforeDateLogged
                                  error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numFuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                         error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numFuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                     newerThan:(NSDate *)newerThan
                                         error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)fuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                   pageSize:(NSInteger)pageSize
                                      error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)fuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                   pageSize:(NSInteger)pageSize
                           beforeDateLogged:(NSDate *)beforeDateLogged
                                      error:(PELMDaoErrorBlk)errorBlk;

- (FPVehicle *)vehicleForFuelPurchaseLog:(FPFuelPurchaseLog *)fpLog
                                   error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelStation *)fuelStationForFuelPurchaseLog:(FPFuelPurchaseLog *)fpLog
                                           error:(PELMDaoErrorBlk)errorBlk;


- (FPVehicle *)masterVehicleForMasterFpLog:(FPFuelPurchaseLog *)fplog
                                     error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelStation *)masterFuelstationForMasterFpLog:(FPFuelPurchaseLog *)fplog
                                             error:(PELMDaoErrorBlk)errorBlk;

- (FPVehicle *)vehicleForMostRecentFuelPurchaseLogForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelStation *)defaultFuelStationForNewFuelPurchaseLogForUser:(FPUser *)user
                                                  currentLocation:(CLLocation *)currentLocation
                                                            error:(PELMDaoErrorBlk)errorBlk;

- (void)persistDeepFuelPurchaseLogFromRemoteMaster:(FPFuelPurchaseLog *)fuelPurchaseLog
                                           forUser:(FPUser *)user
                                             error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                       forUser:(FPUser *)user
                       vehicle:vehicle
                   fuelStation:fuelStation
                         error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewAndSyncImmediateFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                       forUser:(FPUser *)user
                                       vehicle:vehicle
                                   fuelStation:fuelStation
                                         error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)prepareFuelPurchaseLogForEdit:(FPFuelPurchaseLog *)fuelPurchaseLog
                              forUser:(FPUser *)user
                                error:(PELMDaoErrorBlk)errorBlk;

- (void)saveFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                    forUser:(FPUser *)user
                    vehicle:(FPVehicle *)vehicle
                fuelStation:(FPFuelStation *)fuelStation
                      error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                   error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingImmediateSyncFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                                error:(PELMDaoErrorBlk)errorBlk;

- (void)reloadFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                        error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelEditOfFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                              error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)markFuelPurchaseLogsAsSyncInProgressForUser:(FPUser *)user
                                                   error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelSyncForFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                        httpRespCode:(NSNumber *)httpRespCode
                           errorMask:(NSNumber *)errorMask
                             retryAt:(NSDate *)retryAt
                               error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)saveMasterFuelPurchaseLog:(FPFuelPurchaseLog *)fplog
                       forVehicle:(FPVehicle *)vehicle
                   forFuelstation:(FPFuelStation *)fuelstation
                          forUser:(FPUser *)user
                            error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForNewFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                        forUser:(FPUser *)user
                                          error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForUpdatedFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                              error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Environment Log

- (FPEnvironmentLog *)maxReportedMphOdometerLogForUser:(FPUser *)user
                                            beforeDate:(NSDate *)beforeDate
                                         onOrAfterDate:(NSDate *)onOrAfterDate
                                                 error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)maxReportedMphOdometerLogForVehicle:(FPVehicle *)vehicle
                                               beforeDate:(NSDate *)beforeDate
                                            onOrAfterDate:(NSDate *)onOrAfterDate
                                                    error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)minReportedMphOdometerLogForUser:(FPUser *)user
                                            beforeDate:(NSDate *)beforeDate
                                         onOrAfterDate:(NSDate *)onOrAfterDate
                                                 error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)minReportedMphOdometerLogForVehicle:(FPVehicle *)vehicle
                                               beforeDate:(NSDate *)beforeDate
                                            onOrAfterDate:(NSDate *)onOrAfterDate
                                                    error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)maxReportedMphOdometerLogForUser:(FPUser *)user
                                                 error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)maxReportedMphOdometerLogForVehicle:(FPVehicle *)vehicle
                                                    error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)minReportedMphOdometerLogForUser:(FPUser *)user
                                                 error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)minReportedMphOdometerLogForVehicle:(FPVehicle *)vehicle
                                                    error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)maxReportedMpgOdometerLogForUser:(FPUser *)user
                                            beforeDate:(NSDate *)beforeDate
                                         onOrAfterDate:(NSDate *)onOrAfterDate
                                                 error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)maxReportedMpgOdometerLogForVehicle:(FPVehicle *)vehicle
                                               beforeDate:(NSDate *)beforeDate
                                            onOrAfterDate:(NSDate *)onOrAfterDate
                                                    error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)minReportedMpgOdometerLogForUser:(FPUser *)user
                                            beforeDate:(NSDate *)beforeDate
                                         onOrAfterDate:(NSDate *)onOrAfterDate
                                                 error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)minReportedMpgOdometerLogForVehicle:(FPVehicle *)vehicle
                                               beforeDate:(NSDate *)beforeDate
                                            onOrAfterDate:(NSDate *)onOrAfterDate
                                                    error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)maxReportedMpgOdometerLogForUser:(FPUser *)user
                                                 error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)maxReportedMpgOdometerLogForVehicle:(FPVehicle *)vehicle
                                                    error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)minReportedMpgOdometerLogForUser:(FPUser *)user
                                                 error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)minReportedMpgOdometerLogForVehicle:(FPVehicle *)vehicle
                                                    error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedEnvironmentLogsForVehicle:(FPVehicle *)vehicle
                                          error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedEnvironmentLogsForVehicle:(FPVehicle *)vehicle
                                     beforeDate:(NSDate *)beforeDate
                                  onOrAfterDate:(NSDate *)onOrAfterDate
                                          error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedEnvironmentLogsForVehicle:(FPVehicle *)vehicle
                                     beforeDate:(NSDate *)beforeDate
                                      afterDate:(NSDate *)afterDate
                                          error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedEnvironmentLogsForUser:(FPUser *)user
                                       error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedEnvironmentLogsForUser:(FPUser *)user
                                  beforeDate:(NSDate *)beforeDate
                               onOrAfterDate:(NSDate *)onOrAfterDate
                                       error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)odometerLogNearestToDate:(NSDate *)date
                           forVehicle:(FPVehicle *)vehicle
                                error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)odometerLogNearestToDate:(NSDate *)date
                              forUser:(FPUser *)user
                                error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)odometerLogWithNonNilTemperatureNearestToDate:(NSDate *)date
                                                   forUser:(FPUser *)user
                                                     error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)firstOdometerLogForVehicle:(FPVehicle *)vehicle
                                      beforeDate:(NSDate *)onOrBeforeDate
                                   onOrAfterDate:(NSDate *)onOrAfterDate
                                           error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)lastOdometerLogForVehicle:(FPVehicle *)vehicle
                                     beforeDate:(NSDate *)beforeDate
                                  onOrAfterDate:(NSDate *)onOrAfterDate
                                          error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)firstOdometerLogForUser:(FPUser *)user
                                        error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)firstOdometerLogForVehicle:(FPVehicle *)vehicle
                                           error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)lastOdometerLogForUser:(FPUser *)user
                                       error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)lastOdometerLogForVehicle:(FPVehicle *)vehicle
                                          error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)masterEnvlogWithId:(NSNumber *)envlogId
                                   error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)masterEnvlogWithGlobalId:(NSString *)globalId
                                         error:(PELMDaoErrorBlk)errorBlk;

- (void)deleteEnvironmentLog:(FPEnvironmentLog *)envlog
                       error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numEnvironmentLogsForUser:(FPUser *)user
                                 error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numEnvironmentLogsForUser:(FPUser *)user
                             newerThan:(NSDate *)newerThan
                                 error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)environmentLogsForUser:(FPUser *)user
                           pageSize:(NSInteger)pageSize
                              error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unsyncedEnvironmentLogsForUser:(FPUser *)user
                                      error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)environmentLogsForUser:(FPUser *)user
                           pageSize:(NSInteger)pageSize
                   beforeDateLogged:(NSDate *)beforeDateLogged
                              error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numEnvironmentLogsForVehicle:(FPVehicle *)vehicle
                                    error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numEnvironmentLogsForVehicle:(FPVehicle *)vehicle
                                newerThan:(NSDate *)newerThan
                                    error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)environmentLogsForVehicle:(FPVehicle *)vehicle
                              pageSize:(NSInteger)pageSize
                                 error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)environmentLogsForVehicle:(FPVehicle *)vehicle
                              pageSize:(NSInteger)pageSize
                      beforeDateLogged:(NSDate *)beforeDateLogged
                                 error:(PELMDaoErrorBlk)errorBlk;

- (FPVehicle *)masterVehicleForMasterEnvLog:(FPEnvironmentLog *)envlog
                                      error:(PELMDaoErrorBlk)errorBlk;

- (FPVehicle *)vehicleForEnvironmentLog:(FPEnvironmentLog *)envlog
                                  error:(PELMDaoErrorBlk)errorBlk;

- (FPVehicle *)defaultVehicleForNewEnvironmentLogForUser:(FPUser *)user
                                                   error:(PELMDaoErrorBlk)errorBlk;

- (void)persistDeepEnvironmentLogFromRemoteMaster:(FPEnvironmentLog *)environmentLog
                                          forUser:(FPUser *)user
                                            error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewEnvironmentLog:(FPEnvironmentLog *)environmentLog
                      forUser:(FPUser *)user
                      vehicle:vehicle
                        error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewAndSyncImmediateEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                      forUser:(FPUser *)user
                                      vehicle:vehicle
                                        error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)prepareEnvironmentLogForEdit:(FPEnvironmentLog *)environmentLog
                             forUser:(FPUser *)user
                               error:(PELMDaoErrorBlk)errorBlk;

- (void)saveEnvironmentLog:(FPEnvironmentLog *)environmentLog
                   forUser:(FPUser *)user
                   vehicle:(FPVehicle *)vehicle
                     error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                  error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingImmediateSyncEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                               error:(PELMDaoErrorBlk)errorBlk;

- (void)reloadEnvironmentLog:(FPEnvironmentLog *)environmentLog
                       error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelEditOfEnvironmentLog:(FPEnvironmentLog *)environmentLog
                             error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)markEnvironmentLogsAsSyncInProgressForUser:(FPUser *)user
                                                  error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelSyncForEnvironmentLog:(FPEnvironmentLog *)environmentLog
                       httpRespCode:(NSNumber *)httpRespCode
                          errorMask:(NSNumber *)errorMask
                            retryAt:(NSDate *)retryAt
                              error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)saveMasterEnvironmentLog:(FPEnvironmentLog *)envlog
                      forVehicle:(FPVehicle *)vehicle
                         forUser:(FPUser *)user
                           error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForNewEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                       forUser:(FPUser *)user
                                         error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForUpdatedEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                             error:(PELMDaoErrorBlk)errorBlk;

@end
