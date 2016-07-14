//
//  FPLocalDao.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 7/27/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

@import CoreLocation;

#import <FMDB/FMDatabaseQueue.h>
#import <FMDB/FMDatabaseAdditions.h>
#import <FMDB/FMDatabase.h>
#import <FMDB/FMResultSet.h>
#import <CocoaLumberjack/DDLog.h>
#import <PEObjc-Commons/PEUtils.h>
#import <PEObjc-Commons/NSString+PEAdditions.h>
#import <CHCSVParser/CHCSVParser.h>
#import <PEHateoas-Client/HCMediaType.h>
#import <PELocal-Data/PELMDDL.h>
#import <PELocal-Data/PELMUtils.h>
#import <PELocal-Data/PELMDefs.h>
#import <PELocal-Data/PELMNotificationUtils.h>

#import "FPLocalDaoImpl.h"
#import "FPDDLUtils.h"
#import "FPChangelog.h"
#import "FPUser.h"
#import "FPVehicle.h"
#import "FPFuelStation.h"
#import "FPFuelStationType.h"
#import "FPEnvironmentLog.h"
#import "FPFuelPurchaseLog.h"
#import "FPLogging.h"

typedef void(^FPAddColumnBlk)(NSString *, NSString *, NSString *);

uint32_t const FP_REQUIRED_SCHEMA_VERSION = 4;

@implementation FPLocalDaoImpl {
  NSArray *_fuelstationTypeJoinTables;
}

#pragma mark - Initializers

- (id)initWithSqliteDataFilePath:(NSString *)sqliteDataFilePath {
  self = [super initWithSqliteDataFilePath:sqliteDataFilePath
                         concreteUserClass:[FPUser class]];
  if (self) {
    _fuelstationTypeJoinTables = @[@[@"typ", TBL_FUEL_STATION_TYPE, COL_FUELST_TYPE_ID, COL_FUELSTTYP_ID]];
  }
  return self;
}

#pragma mark - Schema Helpers

- (FPAddColumnBlk)makeAddColumnBlkWithDb:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  return ^(NSString *type, NSString *table, NSString *col) {
    [PELMUtils doUpdate:[NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ %@", table, col, type]
                     db:db
                  error:errorBlk];
  };
}

#pragma mark - Initialize Database

- (void)initializeDatabaseWithError:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    uint32_t currentSchemaVersion = [db userVersion];
    DDLogDebug(@"in FPLocalDao/initializeDatabaseWithError:, currentSchemaVersion: %d.  \
Required schema version: %d.", currentSchemaVersion, FP_REQUIRED_SCHEMA_VERSION);
    switch (currentSchemaVersion) {
      case 0: // will occur on very first startup of the app on user's device
        [self applyVersion0SchemaEditsWithDb:db error:errorBlk];
        DDLogDebug(@"in FPLocalDao/initializeDatabaseWithError:, applied schema updates for version 0 (initial).");
        // fall-through to apply "next" schema updates
      case 1:
        [self applyVersion1SchemaEditsWithDb:db error:errorBlk];
        DDLogDebug(@"in FPLocalDao/initializeDatabaseWithError:, applied schema updates for version 1.");
      case 2:
        [self applyVersion2SchemaEditsWithDb:db error:errorBlk];
        DDLogDebug(@"in FPLocalDao/initializeDatabaseWithError:, applied schema updates for version 2.");
      case 3:
        [self applyVersion3SchemaEditsWithDb:db error:errorBlk];
        DDLogDebug(@"in FPLocalDao/initializeDatabaseWithError:, applied schema updates for version 3.");
      case FP_REQUIRED_SCHEMA_VERSION:
        // great, nothing needed to do except update the db's schema version
        [db setUserVersion:FP_REQUIRED_SCHEMA_VERSION];
        break;
    }
  }];
}

#pragma mark - Schema version: FUTURE VERSION

#pragma mark - Schema version: version 3

- (void)applyVersion3SchemaEditsWithDb:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils doUpdate:[FPDDLUtils fuelStationTypeDDL] db:db error:errorBlk];
  [PELMUtils doUpdate:[NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ INTEGER REFERENCES %@(%@)",
                       TBL_MAIN_FUEL_STATION,
                       COL_FUELST_TYPE_ID,
                       TBL_FUEL_STATION_TYPE,
                       COL_FUELSTTYP_ID]
                   db:db
                error:errorBlk];
  [PELMUtils doUpdate:[NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ INTEGER REFERENCES %@(%@)",
                       TBL_MASTER_FUEL_STATION,
                       COL_FUELST_TYPE_ID,
                       TBL_FUEL_STATION_TYPE,
                       COL_FUELSTTYP_ID]
                   db:db
                error:errorBlk];
  void (^insertFSType)(NSInteger, NSString *, NSInteger) = ^(NSInteger identifierVal, NSString *name, NSInteger sortOrder) {
    NSNumber *identifier = @(identifierVal);
    NSString *insertStmt = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@, %@) values (?, ?, ?, ?)",
                            TBL_FUEL_STATION_TYPE,
                            COL_FUELSTTYP_ID,
                            COL_FUELSTTYP_NAME,
                            COL_FUELSTTYP_ICON_IMG_NAME,
                            COL_FUELSTTYP_SORT_ORDER];
    NSString *iconImgName = [NSString stringWithFormat:@"fstype-%@", identifier];
    [PELMUtils doUpdate:insertStmt argsArray:@[identifier, name, iconImgName, @(sortOrder)] db:db error:errorBlk];
  };
  insertFSType(0,  @"Other",             -1);
  insertFSType(5,  @"7-Eleven",          0);
  insertFSType(17, @"76",                1);
  insertFSType(38, @"ARCO",              2);
  insertFSType(12, @"BJ's",              3);
  insertFSType(4,  @"BP",                4);
  insertFSType(9,  @"CITGO",             5);
  insertFSType(6,  @"Chevron",           6);
  insertFSType(18, @"Circle K",          7);
  insertFSType(26, @"Clark",             8);
  insertFSType(13, @"Costco",            9);
  insertFSType(24, @"Cumberland Farms",  10);
  insertFSType(1,  @"Exxon",             11);
  insertFSType(21, @"Friendship Xpress", 12);
  insertFSType(19, @"Getty",             13);
  insertFSType(25, @"Go-Mart",           14);
  insertFSType(10, @"Gulf",              15);
  insertFSType(7,  @"Hess",              16);
  insertFSType(32, @"Kroger",            17);
  insertFSType(35, @"Kum & Go",          18);
  insertFSType(27, @"Kwik Trip",         19);
  insertFSType(30, @"Love's",            20);
  insertFSType(2,  @"Marathon",          21);
  insertFSType(36, @"Mobil",             22);
  insertFSType(22, @"Murphy USA",        23);
  insertFSType(29, @"Pilot",             25);
  insertFSType(20, @"QuikTrip",          26);
  insertFSType(31, @"Royal Farms",       27);
  insertFSType(33, @"Rutter's",          28);
  insertFSType(11, @"Sam's Club",        29);
  insertFSType(14, @"Sheetz",            30);
  insertFSType(3,  @"Shell",             31);
  insertFSType(28, @"Sinclair",          32);
  insertFSType(34, @"Speedway",          33);
  insertFSType(23, @"Stewart's",         34);
  insertFSType(8,  @"Sunoco",            35);
  insertFSType(15, @"Texaco",            36);
  insertFSType(16, @"Valero",            37);
  void (^setFuelstationType)(NSString *) = ^(NSString *fstable) {
    [PELMUtils doUpdate:[NSString stringWithFormat:@"UPDATE %@ SET %@ = ?", fstable, COL_FUELST_TYPE_ID]
              argsArray:@[@(0)] // 'Other' type-id
                     db:db
                  error:errorBlk];
  };
  setFuelstationType(TBL_MAIN_FUEL_STATION);
  setFuelstationType(TBL_MASTER_FUEL_STATION);
}

#pragma mark - Schema version: version 2

- (void)applyVersion2SchemaEditsWithDb:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  FPAddColumnBlk addColumn = [self makeAddColumnBlkWithDb:db error:errorBlk];
  addColumn(@"INTEGER", TBL_MAIN_VEHICLE, COL_VEH_IS_DIESEL);
  addColumn(@"INTEGER", TBL_MASTER_VEHICLE, COL_VEH_IS_DIESEL);

  addColumn(@"INTEGER", TBL_MAIN_FUELPURCHASE_LOG, COL_FUELPL_IS_DIESEL);
  addColumn(@"INTEGER", TBL_MASTER_FUELPURCHASE_LOG, COL_FUELPL_IS_DIESEL);

  addColumn(@"INTEGER", TBL_MAIN_VEHICLE, COL_VEH_HAS_DTE_READOUT);
  addColumn(@"INTEGER", TBL_MASTER_VEHICLE, COL_VEH_HAS_DTE_READOUT);

  addColumn(@"INTEGER", TBL_MAIN_VEHICLE, COL_VEH_HAS_MPG_READOUT);
  addColumn(@"INTEGER", TBL_MASTER_VEHICLE, COL_VEH_HAS_MPG_READOUT);

  addColumn(@"INTEGER", TBL_MAIN_VEHICLE, COL_VEH_HAS_MPH_READOUT);
  addColumn(@"INTEGER", TBL_MASTER_VEHICLE, COL_VEH_HAS_MPH_READOUT);

  addColumn(@"INTEGER", TBL_MAIN_VEHICLE, COL_VEH_HAS_OUTSIDE_TEMP_READOUT);
  addColumn(@"INTEGER", TBL_MASTER_VEHICLE, COL_VEH_HAS_OUTSIDE_TEMP_READOUT);

  addColumn(@"TEXT", TBL_MAIN_VEHICLE, COL_VEH_VIN);
  addColumn(@"TEXT", TBL_MASTER_VEHICLE, COL_VEH_VIN);

  addColumn(@"TEXT", TBL_MAIN_VEHICLE, COL_VEH_PLATE);
  addColumn(@"TEXT", TBL_MASTER_VEHICLE, COL_VEH_PLATE);
}

#pragma mark - Schema version: version 1

- (void)applyVersion1SchemaEditsWithDb:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  FPAddColumnBlk addColumn = [self makeAddColumnBlkWithDb:db error:errorBlk];
  addColumn(@"TEXT", TBL_MAIN_FUEL_STATION, COL_FUELST_STREET);
  addColumn(@"TEXT", TBL_MASTER_FUEL_STATION, COL_FUELST_STREET);
}

#pragma mark - Schema edits, version: 0 (initial schema version)

- (void)applyVersion0SchemaEditsWithDb:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  void (^applyDDL)(NSString *) = ^ (NSString *ddl) {
    [PELMUtils doUpdate:ddl db:db error:errorBlk];
  };
  void (^makeRelTable)(NSString *) = ^ (NSString *table) {
    applyDDL([PELMDDL relDDLForEntityTable:table]);
  };
  void (^makeIndex)(NSString *, NSString *, NSString *) = ^(NSString *entity, NSString *col, NSString *name) {
    applyDDL([PELMDDL indexDDLForEntity:entity unique:NO column:col indexName:name]);
  };

  // ###########################################################################
  // User DDL
  // ###########################################################################
  // ------- master user -------------------------------------------------------
  applyDDL([FPDDLUtils masterUserDDL]);
  makeRelTable(TBL_MASTER_USER);
  // ------- main vehicle ------------------------------------------------------
  applyDDL([FPDDLUtils mainUserDDL]);
  applyDDL([FPDDLUtils mainUserUniqueIndex1]);
  makeRelTable(TBL_MAIN_USER);

  // ###########################################################################
  // Vehicle DDL
  // ###########################################################################
  // ------- master vehicle ----------------------------------------------------
  applyDDL([FPDDLUtils masterVehicleDDL]);
  applyDDL([FPDDLUtils masterVehicleUniqueIndex1]);
  makeIndex(TBL_MASTER_VEHICLE, COL_MST_UPDATED_AT, @"idx_mstr_veh_dt_updated");
  makeRelTable(TBL_MASTER_VEHICLE);
  // ------- main vehicle ------------------------------------------------------
  applyDDL([FPDDLUtils mainVehicleDDL]);
  applyDDL([FPDDLUtils mainVehicleUniqueIndex1]);
  makeRelTable(TBL_MAIN_VEHICLE);

  // ###########################################################################
  // Fuel Station DDL
  // ###########################################################################
  // ------- master fuel station -----------------------------------------------
  applyDDL([FPDDLUtils masterFuelStationDDL]);
  makeIndex(TBL_MASTER_FUEL_STATION, COL_MST_UPDATED_AT, @"idx_mstr_fs_dt_updated");
  makeRelTable(TBL_MASTER_FUEL_STATION);
  // ------- main fuel station -------------------------------------------------
  applyDDL([FPDDLUtils mainFuelStationDDL]);
  makeRelTable(TBL_MAIN_FUEL_STATION);

  // ###########################################################################
  // Fuel Purchase Log DDL
  // ###########################################################################
  // ------- master fuel purchase log ------------------------------------------
  applyDDL([FPDDLUtils masterFuelPurchaseLogDDL]);
  makeIndex(TBL_MASTER_FUELPURCHASE_LOG, COL_FUELPL_PURCHASED_AT, @"idx_mstr_fplog_log_dt");
  makeIndex(TBL_MASTER_FUELPURCHASE_LOG, COL_FUELPL_OCTANE, @"idx_mstr_fplog_octane");
  makeRelTable(TBL_MASTER_FUELPURCHASE_LOG);
  // ------- main fuel purchase log ------------------------------------------
  applyDDL([FPDDLUtils mainFuelPurchaseLogDDL]);
  makeIndex(TBL_MAIN_FUELPURCHASE_LOG, COL_FUELPL_PURCHASED_AT, @"idx_man_fplog_log_dt");
  makeIndex(TBL_MAIN_FUELPURCHASE_LOG, COL_FUELPL_OCTANE, @"idx_man_fplog_octane");
  makeRelTable(TBL_MAIN_FUELPURCHASE_LOG);

  // ###########################################################################
  // Environment Log DDL
  // ###########################################################################
  // ------- master environment log --------------------------------------------
  applyDDL([FPDDLUtils masterEnvironmentLogDDL]);
  makeIndex(TBL_MASTER_ENV_LOG, COL_ENVL_LOG_DT, @"idx_mstr_envlog_log_dt");
  makeRelTable(TBL_MASTER_ENV_LOG);
  // ------- main environment log ----------------------------------------------
  applyDDL([FPDDLUtils mainEnvironmentDDL]);
  makeIndex(TBL_MAIN_ENV_LOG, COL_ENVL_LOG_DT, @"idx_man_envlog_log_dt");
  makeRelTable(TBL_MAIN_ENV_LOG);
}

#pragma mark - Export

- (void)exportWithPathToVehiclesFile:(NSString *)vehiclesPath
                     gasStationsFile:(NSString *)gasStationsFile
                         gasLogsFile:(NSString *)gasLogsFile
                    odometerLogsFile:(NSString *)odometerLogsFile
                                user:(FPUser *)user
                               error:(PELMDaoErrorBlk)errorBlk {
  NSString *(^emptyIfNil)(id) = ^NSString *(id val) {
    if ([PEUtils isNil:val]) {
      return @"";
    }
    return val;
  };
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    // First export the vehicles
    NSArray *records = [self vehiclesForUser:user db:db error:errorBlk];
    CHCSVWriter *csvWriter = [[CHCSVWriter alloc] initForWritingToCSVFile:vehiclesPath];
    [csvWriter writeField:@"Vehicle Name"];
    [csvWriter writeField:@"Default Octane"];
    [csvWriter writeField:@"Fuel Capacity"];
    [csvWriter writeField:@"Takes Diesel?"];
    [csvWriter writeField:@"VIN"];
    [csvWriter writeField:@"Plate"];
    [csvWriter writeField:@"Has Range Readout?"];
    [csvWriter writeField:@"Has MPG Readout?"];
    [csvWriter writeField:@"Has MPH Readout?"];
    [csvWriter writeField:@"Has Outside Temperature Readout?"];
    [csvWriter finishLine];
    for (FPVehicle *vehicle in records) {
      [csvWriter writeField:emptyIfNil(vehicle.name)];
      [csvWriter writeField:emptyIfNil(vehicle.defaultOctane)];
      [csvWriter writeField:emptyIfNil(vehicle.fuelCapacity)];
      [csvWriter writeField:[PEUtils yesNoFromBool:vehicle.isDiesel]];
      [csvWriter writeField:emptyIfNil(vehicle.vin)];
      [csvWriter writeField:emptyIfNil(vehicle.plate)];
      [csvWriter writeField:[PEUtils yesNoFromBool:vehicle.hasDteReadout]];
      [csvWriter writeField:[PEUtils yesNoFromBool:vehicle.hasMpgReadout]];
      [csvWriter writeField:[PEUtils yesNoFromBool:vehicle.hasMphReadout]];
      [csvWriter writeField:[PEUtils yesNoFromBool:vehicle.hasOutsideTempReadout]];
      [csvWriter finishLine];
    }
    [csvWriter closeStream];

    // Export the gas stations
    csvWriter = [[CHCSVWriter alloc] initForWritingToCSVFile:gasStationsFile];
    [csvWriter writeField:@"Gas Station Name"];
    [csvWriter writeField:@"Street"];
    [csvWriter writeField:@"City"];
    [csvWriter writeField:@"State"];
    [csvWriter writeField:@"ZIP"];
    [csvWriter writeField:@"Latitude"];
    [csvWriter writeField:@"Longitude"];
    [csvWriter finishLine];
    records = [self fuelStationsForUser:user db:db error:errorBlk];
    for (FPFuelStation *gasStation in records) {
      [csvWriter writeField:emptyIfNil(gasStation.name)];
      [csvWriter writeField:emptyIfNil(gasStation.street)];
      [csvWriter writeField:emptyIfNil(gasStation.city)];
      [csvWriter writeField:emptyIfNil(gasStation.state)];
      [csvWriter writeField:emptyIfNil(gasStation.zip)];
      [csvWriter writeField:emptyIfNil(gasStation.latitude)];
      [csvWriter writeField:emptyIfNil(gasStation.longitude)];
      [csvWriter finishLine];
    }
    [csvWriter closeStream];

    // Export gas logs
    csvWriter = [[CHCSVWriter alloc] initForWritingToCSVFile:gasLogsFile];
    [csvWriter writeField:@"Vehicle"];
    [csvWriter writeField:@"Gas Station"];
    [csvWriter writeField:@"Number of Gallons"];
    [csvWriter writeField:@"Octane"];
    [csvWriter writeField:@"Is Diesel?"];
    [csvWriter writeField:@"Odometer"];
    [csvWriter writeField:@"Gallon Price"];
    [csvWriter writeField:@"Got Car Wash?"];
    [csvWriter writeField:@"Car Wash per-gallon Discount"];
    [csvWriter writeField:@"Purchase Date"];
    [csvWriter finishLine];
    records = [self fuelPurchaseLogsForUser:user db:db error:errorBlk];
    for (FPFuelPurchaseLog *gasLog in records) {
      FPVehicle *vehicle = [self vehicleForFuelPurchaseLog:gasLog db:db error:errorBlk];
      FPFuelStation *gasStation = [self fuelStationForFuelPurchaseLog:gasLog db:db error:errorBlk];
      [csvWriter writeField:emptyIfNil(vehicle.name)];
      [csvWriter writeField:emptyIfNil(gasStation.name)];
      [csvWriter writeField:emptyIfNil(gasLog.numGallons)];
      [csvWriter writeField:emptyIfNil(gasLog.octane)];
      [csvWriter writeField:emptyIfNil([PEUtils yesNoFromBool:gasLog.isDiesel])];
      [csvWriter writeField:emptyIfNil(gasLog.odometer)];
      [csvWriter writeField:emptyIfNil(gasLog.gallonPrice)];
      [csvWriter writeField:emptyIfNil([PEUtils yesNoFromBool:gasLog.gotCarWash])];
      [csvWriter writeField:emptyIfNil(gasLog.carWashPerGallonDiscount)];
      [csvWriter writeField:emptyIfNil(gasLog.purchasedAt)];
      [csvWriter finishLine];
    }
    [csvWriter closeStream];

    // Export odometer logs
    csvWriter = [[CHCSVWriter alloc] initForWritingToCSVFile:odometerLogsFile];
    [csvWriter writeField:@"Vehicle"];
    [csvWriter writeField:@"Odometer"];
    [csvWriter writeField:@"Average MPG"];
    [csvWriter writeField:@"Average MPH"];
    [csvWriter writeField:@"Outside Temperature"];
    [csvWriter writeField:@"Range"];
    [csvWriter writeField:@"Log Date"];
    [csvWriter finishLine];
    records = [self environmentLogsForUser:user db:db error:errorBlk];
    for (FPEnvironmentLog *odometerLog in records) {
      FPVehicle *vehicle = [self vehicleForEnvironmentLog:odometerLog db:db error:errorBlk];
      [csvWriter writeField:emptyIfNil(vehicle.name)];
      [csvWriter writeField:emptyIfNil(odometerLog.odometer)];
      [csvWriter writeField:emptyIfNil(odometerLog.reportedAvgMpg)];
      [csvWriter writeField:emptyIfNil(odometerLog.reportedAvgMph)];
      [csvWriter writeField:emptyIfNil(odometerLog.reportedOutsideTemp)];
      [csvWriter writeField:emptyIfNil(odometerLog.reportedDte)];
      [csvWriter writeField:emptyIfNil(odometerLog.logDate)];
      [csvWriter finishLine];
    }
    [csvWriter closeStream];
  }];
}

#pragma mark - PELocalDaoImpl Overrides

- (NSArray *)masterEntityTableNames {
  return @[TBL_MASTER_VEHICLE,
           TBL_MASTER_FUEL_STATION,
           TBL_MASTER_FUELPURCHASE_LOG,
           TBL_MASTER_ENV_LOG];
}

- (PEUserDbOpBlk)preDeleteUserHook {
  return ^(PELMUser *user, FMDatabase *db, PELMDaoErrorBlk errorBlk) {
    [self deleteVehiclesOfUser:(FPUser *)user db:db error:errorBlk];
    [self deleteFuelstationsOfUser:(FPUser *)user db:db error:errorBlk];
  };
}

- (NSArray *)mainEntityTableNamesChildToParentOrder {
  return @[TBL_MAIN_ENV_LOG,
           TBL_MAIN_FUELPURCHASE_LOG,
           TBL_MAIN_FUEL_STATION,
           TBL_MAIN_VEHICLE];
}

- (PEUserDbOpBlk)postDeepSaveUserHook {
  return ^(PELMUser *user, FMDatabase *db, PELMDaoErrorBlk errorBlk) {
    FPUser *fpuser = (FPUser *)user;
    NSArray *vehicles = [fpuser vehicles];
    if (vehicles) {
      for (FPVehicle *vehicle in vehicles) {
        [self persistDeepVehicleFromRemoteMaster:vehicle
                                         forUser:fpuser
                                              db:db
                                           error:errorBlk];
      }
    }
    NSArray *fuelStations = [fpuser fuelStations];
    if (fuelStations) {
      for (FPFuelStation *fuelStation in fuelStations) {
        [self persistDeepFuelStationFromRemoteMaster:fuelStation
                                             forUser:fpuser
                                                  db:db
                                               error:errorBlk];
      }
    }
    NSArray *fpLogs = [fpuser fuelPurchaseLogs];
    if (fpLogs) {
      for (FPFuelPurchaseLog *fpLog in fpLogs) {
        [self persistDeepFuelPurchaseLogFromRemoteMaster:fpLog
                                                 forUser:fpuser
                                                      db:db
                                                   error:errorBlk];
      }
    }
    NSArray *envLogs = [fpuser environmentLogs];
    if (envLogs) {
      for (FPEnvironmentLog *envLog in envLogs) {
        [self persistDeepEnvironmentLogFromRemoteMaster:envLog
                                                forUser:fpuser
                                                     db:db
                                                  error:errorBlk];
      }
    }
  };
}

- (NSArray *)changelogProcessorsWithUser:(PELMUser *)user
                               changelog:(PEChangelog *)changelog
                                      db:(FMDatabase *)db
                         processingBlock:(PELMProcessChangelogEntitiesBlk)processingBlk
                                errorBlk:(PELMDaoErrorBlk)errorBlk {
  FPUser *fpuser = (FPUser *)user;
  FPChangelog *fpchangelog = (FPChangelog *)changelog;
  return @[^{processingBlk([fpchangelog vehicles],
                           TBL_MASTER_VEHICLE,
                           TBL_MAIN_VEHICLE,
                           ^(FPVehicle *vehicle) { [self deleteVehicle:vehicle db:db error:errorBlk]; },
                           ^(FPVehicle *vehicle) { return [self saveNewOrExistingMasterVehicle:vehicle forUser:fpuser db:db error:errorBlk]; });},
            ^{processingBlk([fpchangelog fuelStations],
                            TBL_MASTER_FUEL_STATION,
                            TBL_MAIN_FUEL_STATION,
                            ^(FPFuelStation *fuelstation) { [self deleteFuelstation:fuelstation db:db error:errorBlk]; },
                            ^(FPFuelStation *fuelstation) { return [self saveNewOrExistingMasterFuelstation:fuelstation forUser:fpuser db:db error:errorBlk]; });},
            ^{processingBlk([fpchangelog fuelPurchaseLogs],
                            TBL_MASTER_FUELPURCHASE_LOG,
                            TBL_MAIN_FUELPURCHASE_LOG,
                            ^(FPFuelPurchaseLog *fplog) { [self deleteFuelPurchaseLog:fplog db:db error:errorBlk]; },
                            ^(FPFuelPurchaseLog *fplog) { return [self saveNewOrExistingMasterFuelPurchaseLog:fplog forUser:fpuser db:db error:errorBlk]; });},
            ^{processingBlk([fpchangelog environmentLogs],
                            TBL_MASTER_ENV_LOG,
                            TBL_MAIN_ENV_LOG,
                            ^(FPEnvironmentLog *envlog) { [self deleteEnvironmentLog:envlog db:db error:errorBlk]; },
                            ^(FPEnvironmentLog *envlog) { return [self saveNewOrExistingMasterEnvironmentLog:envlog forUser:fpuser db:db error:errorBlk]; });}];
}

#pragma mark - Unsynced and Sync-Needed Counts

- (NSInteger)numUnsyncedVehiclesForUser:(FPUser *)user {
  return [self numUnsyncedEntitiesForUser:user mainEntityTable:TBL_MAIN_VEHICLE];
}

- (NSInteger)numUnsyncedFuelStationsForUser:(FPUser *)user {
  return [self numUnsyncedEntitiesForUser:user mainEntityTable:TBL_MAIN_FUEL_STATION];
}

- (NSInteger)numUnsyncedFuelPurchaseLogsForUser:(FPUser *)user {
  return [self numUnsyncedEntitiesForUser:user mainEntityTable:TBL_MAIN_FUELPURCHASE_LOG];
}

- (NSInteger)numUnsyncedEnvironmentLogsForUser:(FPUser *)user {
  return [self numUnsyncedEntitiesForUser:user mainEntityTable:TBL_MAIN_ENV_LOG];
}

- (NSInteger)totalNumUnsyncedEntitiesForUser:(FPUser *)user {
  return [self numUnsyncedVehiclesForUser:user] +
    [self numUnsyncedFuelStationsForUser:user] +
    [self numUnsyncedFuelPurchaseLogsForUser:user] +
    [self numUnsyncedEnvironmentLogsForUser:user];
}

- (NSInteger)numSyncNeededVehiclesForUser:(FPUser *)user {
  return [self numSyncNeededEntitiesForUser:user mainEntityTable:TBL_MAIN_VEHICLE];
}

- (NSInteger)numSyncNeededFuelStationsForUser:(FPUser *)user {
  return [self numSyncNeededEntitiesForUser:user mainEntityTable:TBL_MAIN_FUEL_STATION];
}

- (NSInteger)numSyncNeededFuelPurchaseLogsForUser:(FPUser *)user {
  return [self numSyncNeededEntitiesForUser:user mainEntityTable:TBL_MAIN_FUELPURCHASE_LOG];
}

- (NSInteger)numSyncNeededEnvironmentLogsForUser:(FPUser *)user {
  return [self numSyncNeededEntitiesForUser:user mainEntityTable:TBL_MAIN_ENV_LOG];
}

- (NSInteger)totalNumSyncNeededEntitiesForUser:(FPUser *)user {
  return [self numSyncNeededVehiclesForUser:user] +
    [self numSyncNeededFuelStationsForUser:user] +
    [self numSyncNeededFuelPurchaseLogsForUser:user] +
    [self numSyncNeededEnvironmentLogsForUser:user];
}

#pragma mark - Vehicle

- (void)deleteVehiclesOfUser:(FPUser *)user db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  NSArray *vehicles = [self vehiclesForUser:user db:db error:errorBlk];
  for (FPVehicle *vehicle in vehicles) {
    [self deleteVehicle:vehicle db:db error:errorBlk];
  }
}

- (FPVehicle *)masterVehicleWithId:(NSNumber *)vehicleId
                             error:(PELMDaoErrorBlk)errorBlk {
  NSString *vehicleTable = TBL_MASTER_VEHICLE;
  __block FPVehicle *vehicle = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    vehicle = [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", vehicleTable, COL_LOCAL_ID]
                             entityTable:vehicleTable
                           localIdGetter:^NSNumber *(PELMModelSupport *entity) { return [entity localMasterIdentifier]; }
                               argsArray:@[vehicleId]
                             rsConverter:^(FMResultSet *rs) { return [self masterVehicleFromResultSet:rs]; }
                                      db:db
                                   error:errorBlk];
    NSNumber *localMainId = [PELMUtils localMainIdentifierForEntity:vehicle mainTable:TBL_MAIN_VEHICLE db:db error:errorBlk];
    if (localMainId) {
      [vehicle setLocalMainIdentifier:localMainId];
    }
  }];
  return vehicle;
}

- (FPVehicle *)masterVehicleWithGlobalId:(NSString *)globalId
                                   error:(PELMDaoErrorBlk)errorBlk {
    __block FPVehicle *vehicle = nil;
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        vehicle = [self masterVehicleWithGlobalId:globalId db:db error:errorBlk];
    }];
    return vehicle;
}

- (FPVehicle *)masterVehicleWithGlobalId:(NSString *)globalId
                                      db:(FMDatabase *)db
                                   error:(PELMDaoErrorBlk)errorBlk {
    NSString *vehicleTable = TBL_MASTER_VEHICLE;
    FPVehicle *vehicle = nil;
    vehicle = [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", vehicleTable, COL_GLOBAL_ID]
                             entityTable:vehicleTable
                           localIdGetter:^NSNumber *(PELMModelSupport *entity) { return [entity localMasterIdentifier]; }
                               argsArray:@[globalId]
                             rsConverter:^(FMResultSet *rs) { return [self masterVehicleFromResultSet:rs]; }
                                      db:db
                                   error:errorBlk];
    NSNumber *localMainId = [PELMUtils localMainIdentifierForEntity:vehicle mainTable:TBL_MAIN_VEHICLE db:db error:errorBlk];
    if (localMainId) {
        [vehicle setLocalMainIdentifier:localMainId];
    }
    return vehicle;
}

- (void)deleteVehicle:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self deleteVehicle:vehicle db:db error:errorBlk];
  }];
}

- (void)deleteVehicle:(FPVehicle *)vehicle
                   db:(FMDatabase *)db
                error:(PELMDaoErrorBlk)errorBlk {
  NSArray *fplogs = [self fuelPurchaseLogsForVehicle:vehicle db:db error:errorBlk];
  for (FPFuelPurchaseLog *fplog in fplogs) {
    [self deleteFuelPurchaseLog:fplog db:db error:errorBlk];
  }
  NSArray *envlogs = [self environmentLogsForVehicle:vehicle db:db error:errorBlk];
  for (FPEnvironmentLog *envlog in envlogs) {
    [self deleteEnvironmentLog:envlog db:db error:errorBlk];
  }
  [PELMUtils deleteEntity:vehicle
          entityMainTable:TBL_MAIN_VEHICLE
        entityMasterTable:TBL_MASTER_VEHICLE
                       db:db
                    error:errorBlk];
}

- (void)copyVehicleToMaster:(FPVehicle *)vehicle
                      error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils copyMasterEntity:vehicle
                    toMainTable:TBL_MAIN_VEHICLE
           mainTableInserterBlk:nil
                             db:db
                          error:errorBlk];
  }];
}

- (NSInteger)numVehiclesForUser:(FPUser *)user
                          error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numVehicles = 0;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    numVehicles = [PELMUtils numEntitiesForParentEntity:user
                                  parentEntityMainTable:TBL_MAIN_USER
                         addlJoinParentEntityMainTables:nil
                            parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                             parentEntityMasterIdColumn:COL_MASTER_USER_ID
                               parentEntityMainIdColumn:COL_MAIN_USER_ID
                                      entityMasterTable:TBL_MASTER_VEHICLE
                             addlJoinEntityMasterTables:nil
                                        entityMainTable:TBL_MAIN_VEHICLE
                               addlJoinEntityMainTables:nil
                                                     db:db
                                                  error:errorBlk];
  }];
  return numVehicles;
}

- (NSArray *)vehiclesForUser:(FPUser *)user
                       error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *vehicles = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    vehicles = [self vehiclesForUser:user db:db error:errorBlk];
  }];
  return vehicles;
}

- (NSArray *)dieselVehiclesForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *vehicles = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    vehicles = [self dieselVehiclesForUser:user db:db error:errorBlk];
  }];
  return vehicles;
}

- (NSArray *)unsyncedVehiclesForUser:(FPUser *)user
                               error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *vehicles = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    vehicles = [self unsyncedVehiclesForUser:user db:db error:errorBlk];
  }];
  return vehicles;
}

- (NSArray *)unsyncedVehiclesForUser:(FPUser *)user
                                  db:(FMDatabase *)db
                               error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils unsyncedEntitiesForParentEntity:user
                              parentEntityMainTable:TBL_MAIN_USER
                     addlJoinParentEntityMainTables:nil
                        parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                         parentEntityMasterIdColumn:COL_MASTER_USER_ID
                           parentEntityMainIdColumn:COL_MAIN_USER_ID
                                           pageSize:nil
                                  entityMasterTable:TBL_MASTER_VEHICLE
                         addlJoinEntityMasterTables:nil
                     masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterVehicleFromResultSet:rs];}
                                    entityMainTable:TBL_MAIN_VEHICLE
                           addlJoinEntityMainTables:nil
                       mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                                  comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPVehicle *)o1 name] compare:[(FPVehicle *)o2 name]];}
                                orderByDomainColumn:COL_VEH_NAME
                       orderByDomainColumnDirection:@"ASC"
                                                 db:db
                                              error:errorBlk];
}

- (NSArray *)vehiclesForUser:(FPUser *)user
                          db:(FMDatabase *)db
                       error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesForParentEntity:user
                      parentEntityMainTable:TBL_MAIN_USER
             addlJoinParentEntityMainTables:nil
                parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                 parentEntityMasterIdColumn:COL_MASTER_USER_ID
                   parentEntityMainIdColumn:COL_MAIN_USER_ID
                                   pageSize:nil
                                   whereBlk:nil
                                  whereArgs:nil
                          entityMasterTable:TBL_MASTER_VEHICLE
                 addlJoinEntityMasterTables:nil
             masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterVehicleFromResultSet:rs];}
                            entityMainTable:TBL_MAIN_VEHICLE
                   addlJoinEntityMainTables:nil
               mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                          comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPVehicle *)o1 name] compare:[(FPVehicle *)o2 name]];}
                        orderByDomainColumn:COL_VEH_NAME
               orderByDomainColumnDirection:@"ASC"
                                         db:db
                                      error:errorBlk];
}

- (NSArray *)dieselVehiclesForUser:(FPUser *)user
                                db:(FMDatabase *)db
                             error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesForParentEntity:user
                      parentEntityMainTable:TBL_MAIN_USER
             addlJoinParentEntityMainTables:nil
                parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                 parentEntityMasterIdColumn:COL_MASTER_USER_ID
                   parentEntityMainIdColumn:COL_MAIN_USER_ID
                                   pageSize:nil
                                   whereBlk:^(NSString *colPrefix) {
                                     return [NSString stringWithFormat:@"%@%@ = 1",
                                             colPrefix,
                                             COL_VEH_IS_DIESEL];
                                   }
                                  whereArgs:nil
                          entityMasterTable:TBL_MASTER_VEHICLE
                 addlJoinEntityMasterTables:nil
             masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterVehicleFromResultSet:rs];}
                            entityMainTable:TBL_MAIN_VEHICLE
                   addlJoinEntityMainTables:nil
               mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                          comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPVehicle *)o1 name] compare:[(FPVehicle *)o2 name]];}
                        orderByDomainColumn:COL_VEH_NAME
               orderByDomainColumnDirection:@"ASC"
                                         db:db
                                      error:errorBlk];
}

- (FPUser *)userForVehicle:(FPVehicle *)vehicle
                     error:(PELMDaoErrorBlk)errorBlk {
  __block FPUser *user = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    user = [self userForVehicle:vehicle db:db error:errorBlk];
  }];
  return user;
}

- (FPUser *)userForVehicle:(FPVehicle *)vehicle
                        db:(FMDatabase *)db
                     error:(PELMDaoErrorBlk)errorBlk {
  return (FPUser *)
  [PELMUtils parentForChildEntity:vehicle
            parentEntityMainTable:TBL_MAIN_USER
   addlJoinParentEntityMainTables:nil
          parentEntityMasterTable:TBL_MASTER_USER
 addlJoinParentEntityMasterTables:nil
         parentEntityMainFkColumn:COL_MAIN_USER_ID
       parentEntityMasterFkColumn:COL_MASTER_USER_ID
      parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
    parentEntityMasterRsConverter:^(FMResultSet *rs){return [self masterUserFromResultSet:rs];}
             childEntityMainTable:TBL_MAIN_VEHICLE
    addlJoinChildEntityMainTables:nil
       childEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
           childEntityMasterTable:TBL_MASTER_VEHICLE
                               db:db
                            error:errorBlk];
}

- (void)persistDeepVehicleFromRemoteMaster:(FPVehicle *)vehicle
                                   forUser:(FPUser *)user
                                     error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self persistDeepVehicleFromRemoteMaster:vehicle forUser:user db:db error:errorBlk];
  }];
}

- (void)persistDeepVehicleFromRemoteMaster:(FPVehicle *)vehicle
                                   forUser:(FPUser *)user
                                        db:(FMDatabase *)db
                                     error:(PELMDaoErrorBlk)errorBlk {
  [self insertIntoMasterVehicle:vehicle forUser:user db:db error:errorBlk];
  [PELMUtils insertRelations:[vehicle relations]
                   forEntity:vehicle
                 entityTable:TBL_MASTER_VEHICLE
             localIdentifier:[vehicle localMasterIdentifier]
                          db:db
                       error:errorBlk];
}

- (void)saveNewVehicle:(FPVehicle *)vehicle
               forUser:(FPUser *)user
                 error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self saveNewVehicle:vehicle forUser:user db:db error:errorBlk];
  }];
}

- (void)saveNewAndSyncImmediateVehicle:(FPVehicle *)vehicle
                               forUser:(FPUser *)user
                                 error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [vehicle setSyncInProgress:YES];
    [self saveNewVehicle:vehicle forUser:user db:db error:errorBlk];
  }];
}

- (void)saveNewVehicle:(FPVehicle *)vehicle
               forUser:(FPUser *)user
                    db:(FMDatabase *)db
                 error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils copyMasterEntity:user
                  toMainTable:TBL_MAIN_USER
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainUser:(FPUser *)entity db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  [vehicle setEditCount:1];
  [self insertIntoMainVehicle:vehicle forUser:user db:db error:errorBlk];
}

- (BOOL)prepareVehicleForEdit:(FPVehicle *)vehicle
                      forUser:(FPUser *)user
                        error:(PELMDaoErrorBlk)errorBlk {
  __block BOOL returnVal;
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils copyMasterEntity:user
                    toMainTable:TBL_MAIN_USER
           mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainUser:(FPUser *)entity db:db error:errorBlk];}
                             db:db
                          error:errorBlk];
    returnVal = [PELMUtils prepareEntityForEdit:vehicle
                                             db:db
                                      mainTable:TBL_MAIN_VEHICLE
                       addlJoinEntityMainTables:nil
                            entityFromResultSet:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                             mainEntityInserter:^(PELMMainSupport *entity, FMDatabase *db, PELMDaoErrorBlk errorBlk) {
                               [self insertIntoMainVehicle:vehicle forUser:user db:db error:errorBlk];}
                              mainEntityUpdater:^(PELMMainSupport *entity, FMDatabase *db, PELMDaoErrorBlk errorBlk) {
                                [PELMUtils doUpdate:[self updateStmtForMainVehicle]
                                          argsArray:[self updateArgsForMainVehicle:vehicle]
                                                 db:db
                                              error:errorBlk];}
                                          error:errorBlk];
  }];
  return returnVal;
}

- (void)saveVehicle:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils saveEntity:vehicle
                     mainTable:TBL_MAIN_VEHICLE
                mainUpdateStmt:[self updateStmtForMainVehicle]
             mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainVehicle:(FPVehicle *)entity];}
                         error:errorBlk];
}

- (void)markAsDoneEditingVehicle:(FPVehicle *)vehicle
                           error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils markAsDoneEditingEntity:vehicle
                                  mainTable:TBL_MAIN_VEHICLE
                             mainUpdateStmt:[self updateStmtForMainVehicle]
                          mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainVehicle:(FPVehicle *)entity];}
                                      error:errorBlk];
}

- (void)markAsDoneEditingImmediateSyncVehicle:(FPVehicle *)vehicle
                                        error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils markAsDoneEditingImmediateSyncEntity:vehicle
                                               mainTable:TBL_MAIN_VEHICLE
                                          mainUpdateStmt:[self updateStmtForMainVehicle]
                                       mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainVehicle:(FPVehicle *)entity];}
                                                   error:errorBlk];
}

- (void)reloadVehicle:(FPVehicle *)vehicle
                error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils reloadEntity:vehicle
                       fromMainTable:TBL_MAIN_VEHICLE
                      addlJoinTables:nil
                         rsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                               error:errorBlk];
}

- (void)cancelEditOfVehicle:(FPVehicle *)vehicle
                      error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils cancelEditOfEntity:vehicle
                             mainTable:TBL_MAIN_VEHICLE
                        mainUpdateStmt:[self updateStmtForMainVehicle]
                     mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainVehicle:(FPVehicle *)entity];}
                           masterTable:TBL_MASTER_VEHICLE
                           rsConverter:^(FMResultSet *rs){return [self masterVehicleFromResultSet:rs];}
                                 error:errorBlk];
}

- (NSArray *)markVehiclesAsSyncInProgressForUser:(FPUser *)user
                                           error:(PELMDaoErrorBlk)errorBlk {
  return [self.localModelUtils markEntitiesAsSyncInProgressInMainTable:TBL_MAIN_VEHICLE
                                              addlJoinEntityMainTables:nil
                                                   entityFromResultSet:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                                                            updateStmt:[self updateStmtForMainVehicle]
                                                         updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainVehicle:(FPVehicle *)entity];}
                                                                 error:errorBlk];
}

- (void)cancelSyncForVehicle:(FPVehicle *)vehicle
                httpRespCode:(NSNumber *)httpRespCode
                   errorMask:(NSNumber *)errorMask
                     retryAt:(NSDate *)retryAt
                       error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils cancelSyncForEntity:vehicle
                           httpRespCode:httpRespCode
                              errorMask:errorMask
                                retryAt:retryAt
                         mainUpdateStmt:[self updateStmtForMainVehicle]
                      mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainVehicle:(FPVehicle *)entity];}
                                  error:errorBlk];
}

- (PELMSaveNewOrExistingCode)saveNewOrExistingMasterVehicle:(FPVehicle *)vehicle
                                                    forUser:(FPUser *)user
                                                         db:(FMDatabase *)db
                                                      error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils saveNewOrExistingMasterEntity:vehicle
                                      masterTable:TBL_MASTER_VEHICLE
                                  masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterVehicle:(FPVehicle *)entity forUser:user db:db error:errorBlk];}
                                 masterUpdateStmt:[self updateStmtForMasterVehicle]
                              masterUpdateArgsBlk:^NSArray * (FPVehicle *theVehicle) { return [self updateArgsForMasterVehicle:theVehicle]; }
                                        mainTable:TBL_MAIN_VEHICLE
                          mainEntityFromResultSet:^FPVehicle * (FMResultSet *rs) { return [self mainVehicleFromResultSet:rs]; }
                                   mainUpdateStmt:[self updateStmtForMainVehicle]
                                mainUpdateArgsBlk:^NSArray * (FPVehicle *theVehicle) { return [self updateArgsForMainVehicle:theVehicle]; }
                                               db:db
                                            error:errorBlk];
}

- (void)saveNewMasterVehicle:(FPVehicle *)vehicle
                     forUser:(FPUser *)user
                       error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils saveNewMasterEntity:vehicle
                            masterTable:TBL_MASTER_VEHICLE
                        masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterVehicle:(FPVehicle *)entity forUser:user db:db error:errorBlk];}
                                  error:errorBlk];
}

- (BOOL)saveMasterVehicle:(FPVehicle *)vehicle
                  forUser:(FPUser *)user
                    error:(PELMDaoErrorBlk)errorBlk {
  return [self.localModelUtils saveMasterEntity:vehicle
                                masterTable:TBL_MASTER_VEHICLE
                           masterUpdateStmt:[self updateStmtForMasterVehicle]
                        masterUpdateArgsBlk:^NSArray * (FPVehicle *theVehicle) { return [self updateArgsForMasterVehicle:theVehicle]; }
                                  mainTable:TBL_MAIN_VEHICLE
                    mainEntityFromResultSet:^FPVehicle * (FMResultSet *rs) { return [self mainVehicleFromResultSet:rs]; }
                             mainUpdateStmt:[self updateStmtForMainVehicle]
                          mainUpdateArgsBlk:^NSArray * (FPVehicle *theVehicle) { return [self updateArgsForMainVehicle:theVehicle]; }
                                      error:errorBlk];
}

- (void)markAsSyncCompleteForNewVehicle:(FPVehicle *)vehicle
                                forUser:(FPUser *)user
                                  error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils markAsSyncCompleteForNewEntity:vehicle
                                         mainTable:TBL_MAIN_VEHICLE
                                       masterTable:TBL_MASTER_VEHICLE
                                    mainUpdateStmt:[self updateStmtForMainVehicle]
                                 mainUpdateArgsBlk:^(id entity){return [self updateArgsForMainVehicle:(FPVehicle *)entity];}
                                   masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterVehicle:(FPVehicle *)entity forUser:user db:db error:errorBlk];}
                                             error:errorBlk];
}

- (void)markAsSyncCompleteForUpdatedVehicle:(FPVehicle *)vehicle
                                      error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils markAsSyncCompleteForUpdatedEntityInTxn:vehicle
                                                  mainTable:TBL_MAIN_VEHICLE
                                                masterTable:TBL_MASTER_VEHICLE
                                             mainUpdateStmt:[self updateStmtForMainVehicle]
                                          mainUpdateArgsBlk:^(id entity){return [self updateArgsForMainVehicle:(FPVehicle *)entity];}
                                           masterUpdateStmt:[self updateStmtForMasterVehicle]
                                        masterUpdateArgsBlk:^(id entity){return [self updateArgsForMasterVehicle:(FPVehicle *)entity];}
                                                      error:errorBlk];
}

- (FPVehicle *)vehicleWithMostRecentLogForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk {
  __block FPVehicle *vehicle = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    FPFuelPurchaseLog *fplog = [self mostRecentFuelPurchaseLogForUser:user db:db error:errorBlk];
    FPEnvironmentLog *envlog = [self mostRecentEnvironmentLogForUser:user db:db error:errorBlk];
    if (fplog && ![PEUtils isNil:fplog.purchasedAt]) {
      if (envlog && ![PEUtils isNil:envlog.logDate]) {
        NSComparisonResult compareResult = [fplog.purchasedAt compare:envlog.logDate];
        if ((compareResult == NSOrderedSame) || (compareResult == NSOrderedAscending)) {
          vehicle = [self vehicleForEnvironmentLog:envlog db:db error:errorBlk];
        } else {
          vehicle = [self vehicleForFuelPurchaseLog:fplog db:db error:errorBlk];
        }
      } else {
        vehicle = [self vehicleForFuelPurchaseLog:fplog db:db error:errorBlk];
      }
    } else if (envlog) {
      vehicle = [self vehicleForEnvironmentLog:envlog db:db error:errorBlk];
    } else {
      NSArray *vehicles = [self vehiclesForUser:user db:db error:errorBlk];
      if (vehicles.count >= 1) {
        vehicle = vehicles[0];
      }
    }
  }];
  return vehicle;
}

#pragma mark - Fuel Station

- (void)deleteFuelstationsOfUser:(FPUser *)user db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  NSArray *fuelstations = [self fuelStationsForUser:user db:db error:errorBlk];
  for (FPFuelStation *fuelstation in fuelstations) {
    [self deleteFuelstation:fuelstation db:db error:errorBlk];
  }
}

- (FPFuelStation *)masterFuelstationWithId:(NSNumber *)fuelstationId error:(PELMDaoErrorBlk)errorBlk {
  NSString *fuelstationTable = TBL_MASTER_FUEL_STATION;
  __block FPFuelStation *fuelstation = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    NSMutableString *selectClause = [NSMutableString stringWithString:@"SELECT mstr.*"];
    NSMutableString *fromClause   = [NSMutableString stringWithFormat:@" FROM %@ mstr", fuelstationTable];
    NSMutableString *whereClause  = [NSMutableString stringWithFormat:@" WHERE mstr.%@ = ?", COL_LOCAL_ID];
    [PELMUtils incorporateJoinTables:_fuelstationTypeJoinTables intoSelectClause:selectClause fromClause:fromClause whereClause:whereClause entityTablePrefix:@"mstr"];
    NSString *qry = [NSString stringWithFormat:@"%@%@%@", selectClause, fromClause, whereClause];
    fuelstation = [PELMUtils entityFromQuery:qry
                                 entityTable:fuelstationTable
                               localIdGetter:^NSNumber *(PELMModelSupport *entity) { return [entity localMasterIdentifier]; }
                                   argsArray:@[fuelstationId]
                                 rsConverter:^(FMResultSet *rs) { return [self masterFuelStationFromResultSet:rs]; }
                                          db:db
                                       error:errorBlk];
    NSNumber *localMainId = [PELMUtils localMainIdentifierForEntity:fuelstation mainTable:TBL_MAIN_FUEL_STATION db:db error:errorBlk];
    if (localMainId) {
      [fuelstation setLocalMainIdentifier:localMainId];
    }
  }];
  return fuelstation;
}

- (FPFuelStation *)masterFuelstationWithGlobalId:(NSString *)globalId error:(PELMDaoErrorBlk)errorBlk {
  __block FPFuelStation *fuelstation = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
      fuelstation = [self masterFuelstationWithGlobalId:globalId db:db error:errorBlk];
  }];
  return fuelstation;
}

- (FPFuelStation *)masterFuelstationWithGlobalId:(NSString *)globalId
                                              db:(FMDatabase *)db
                                           error:(PELMDaoErrorBlk)errorBlk {
    NSString *fuelstationTable = TBL_MASTER_FUEL_STATION;
    FPFuelStation *fuelstation = nil;
    NSMutableString *selectClause = [NSMutableString stringWithString:@"SELECT mstr.*"];
    NSMutableString *fromClause   = [NSMutableString stringWithFormat:@" FROM %@ mstr", fuelstationTable];
    NSMutableString *whereClause  = [NSMutableString stringWithFormat:@" WHERE mstr.%@ = ?", COL_GLOBAL_ID];
    [PELMUtils incorporateJoinTables:_fuelstationTypeJoinTables intoSelectClause:selectClause fromClause:fromClause whereClause:whereClause entityTablePrefix:@"mstr"];
    NSString *qry = [NSString stringWithFormat:@"%@%@%@", selectClause, fromClause, whereClause];
    fuelstation = [PELMUtils entityFromQuery:qry
                                 entityTable:fuelstationTable
                               localIdGetter:^NSNumber *(PELMModelSupport *entity) { return [entity localMasterIdentifier]; }
                                   argsArray:@[globalId]
                                 rsConverter:^(FMResultSet *rs) { return [self masterFuelStationFromResultSet:rs]; }
                                          db:db
                                       error:errorBlk];
    NSNumber *localMainId = [PELMUtils localMainIdentifierForEntity:fuelstation mainTable:TBL_MAIN_FUEL_STATION db:db error:errorBlk];
    if (localMainId) {
        [fuelstation setLocalMainIdentifier:localMainId];
    }
    return fuelstation;
}

- (void)deleteFuelstation:(FPFuelStation *)fuelstation error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self deleteFuelstation:fuelstation db:db error:errorBlk];
  }];
}

- (void)deleteFuelstation:(FPFuelStation *)fuelstation
                       db:(FMDatabase *)db
                    error:(PELMDaoErrorBlk)errorBlk {
  NSArray *fplogs = [self fuelPurchaseLogsForFuelStation:fuelstation db:db error:errorBlk];
  for (FPFuelPurchaseLog *fplog in fplogs) {
    [self deleteFuelPurchaseLog:fplog db:db error:errorBlk];
  }
  [PELMUtils deleteEntity:fuelstation
          entityMainTable:TBL_MAIN_FUEL_STATION
        entityMasterTable:TBL_MASTER_FUEL_STATION
                       db:db
                    error:errorBlk];
}

- (NSInteger)numFuelStationsForUser:(FPUser *)user
                              error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numFuelStations = 0;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    numFuelStations = [PELMUtils numEntitiesForParentEntity:user
                                      parentEntityMainTable:TBL_MAIN_USER
                             addlJoinParentEntityMainTables:nil
                                parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                                 parentEntityMasterIdColumn:COL_MASTER_USER_ID
                                   parentEntityMainIdColumn:COL_MAIN_USER_ID
                                          entityMasterTable:TBL_MASTER_FUEL_STATION
                                 addlJoinEntityMasterTables:_fuelstationTypeJoinTables
                                            entityMainTable:TBL_MAIN_FUEL_STATION
                                   addlJoinEntityMainTables:_fuelstationTypeJoinTables
                                                         db:db
                                                      error:errorBlk];
  }];
  return numFuelStations;
}

- (NSArray *)fuelStationsForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fuelStations = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fuelStations = [self fuelStationsForUser:user db:db error:errorBlk];
  }];
  return fuelStations;
}

- (NSArray *)fuelStationsForUser:(FPUser *)user
                              db:(FMDatabase *)db
                           error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesForParentEntity:user
                      parentEntityMainTable:TBL_MAIN_USER
             addlJoinParentEntityMainTables:nil
                parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                 parentEntityMasterIdColumn:COL_MASTER_USER_ID
                   parentEntityMainIdColumn:COL_MAIN_USER_ID
                                   pageSize:nil
                                   whereBlk:nil
                                  whereArgs:nil
                          entityMasterTable:TBL_MASTER_FUEL_STATION
                 addlJoinEntityMasterTables:_fuelstationTypeJoinTables
             masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelStationFromResultSet:rs];}
                            entityMainTable:TBL_MAIN_FUEL_STATION
                   addlJoinEntityMainTables:_fuelstationTypeJoinTables
               mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                          comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelStation *)o1 name] compare:[(FPFuelStation *)o2 name]];}
                        orderByDomainColumn:COL_FUELST_NAME
               orderByDomainColumnDirection:@"ASC"
                                         db:db
                                      error:errorBlk];
}

- (NSArray *)unsyncedFuelStationsForUser:(FPUser *)user
                                   error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fuelstations = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fuelstations = [self unsyncedFuelStationsForUser:user db:db error:errorBlk];
  }];
  return fuelstations;
}

- (NSArray *)unsyncedFuelStationsForUser:(FPUser *)user
                                      db:(FMDatabase *)db
                                   error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils unsyncedEntitiesForParentEntity:user
                              parentEntityMainTable:TBL_MAIN_USER
                     addlJoinParentEntityMainTables:nil
                        parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                         parentEntityMasterIdColumn:COL_MASTER_USER_ID
                           parentEntityMainIdColumn:COL_MAIN_USER_ID
                                           pageSize:nil
                                  entityMasterTable:TBL_MASTER_FUEL_STATION
                         addlJoinEntityMasterTables:_fuelstationTypeJoinTables
                     masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelStationFromResultSet:rs];}
                                    entityMainTable:TBL_MAIN_FUEL_STATION
                           addlJoinEntityMainTables:_fuelstationTypeJoinTables
                       mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                                  comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelStation *)o1 name] compare:[(FPFuelStation *)o2 name]];}
                                orderByDomainColumn:COL_FUELST_NAME
                       orderByDomainColumnDirection:@"ASC"
                                                 db:db
                                              error:errorBlk];
}

- (NSArray *)fuelStationsWithNonNilLocationForUser:(FPUser *)user
                                                db:(FMDatabase *)db
                                             error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesForParentEntity:user
                      parentEntityMainTable:TBL_MAIN_USER
             addlJoinParentEntityMainTables:nil
                parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                 parentEntityMasterIdColumn:COL_MASTER_USER_ID
                   parentEntityMainIdColumn:COL_MAIN_USER_ID
                                   pageSize:nil
                                   whereBlk:^(NSString *colPrefix) {
                                     return [NSString stringWithFormat:@"%@%@ IS NOT NULL AND %@%@ IS NOT NULL",
                                             colPrefix,
                                             COL_FUELST_LATITUDE,
                                             colPrefix,
                                             COL_FUELST_LONGITUDE];
                                   }
                                  whereArgs:nil
                          entityMasterTable:TBL_MASTER_FUEL_STATION
                 addlJoinEntityMasterTables:_fuelstationTypeJoinTables
             masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelStationFromResultSet:rs];}
                            entityMainTable:TBL_MAIN_FUEL_STATION
                   addlJoinEntityMainTables:_fuelstationTypeJoinTables
               mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                                         db:db
                                      error:errorBlk];
}

- (FPUser *)userForFuelStation:(FPFuelStation *)fuelStation error:(PELMDaoErrorBlk)errorBlk {
  __block FPUser *user = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    user = [self userForFuelStation:fuelStation db:db error:errorBlk];
  }];
  return user;
}

- (FPUser *)userForFuelStation:(FPFuelStation *)fuelStation
                            db:(FMDatabase *)db
                         error:(PELMDaoErrorBlk)errorBlk {
  return (FPUser *)
  [PELMUtils parentForChildEntity:fuelStation
            parentEntityMainTable:TBL_MAIN_USER
   addlJoinParentEntityMainTables:nil
          parentEntityMasterTable:TBL_MASTER_USER
 addlJoinParentEntityMasterTables:nil
         parentEntityMainFkColumn:COL_MAIN_USER_ID
       parentEntityMasterFkColumn:COL_MASTER_USER_ID
      parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
    parentEntityMasterRsConverter:^(FMResultSet *rs){return [self masterUserFromResultSet:rs];}
             childEntityMainTable:TBL_MAIN_FUEL_STATION
    addlJoinChildEntityMainTables:_fuelstationTypeJoinTables
       childEntityMainRsConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
           childEntityMasterTable:TBL_MASTER_FUEL_STATION
                               db:db
                            error:errorBlk];
}

- (void)persistDeepFuelStationFromRemoteMaster:(FPFuelStation *)fuelStation
                                       forUser:(FPUser *)user
                                         error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self persistDeepFuelStationFromRemoteMaster:fuelStation forUser:user db:db error:errorBlk];
  }];
}

- (void)persistDeepFuelStationFromRemoteMaster:(FPFuelStation *)fuelStation
                                       forUser:(FPUser *)user
                                            db:(FMDatabase *)db
                                         error:(PELMDaoErrorBlk)errorBlk {
  [self insertIntoMasterFuelStation:fuelStation forUser:user db:db error:errorBlk];
  [PELMUtils insertRelations:[fuelStation relations]
                   forEntity:fuelStation
                 entityTable:TBL_MASTER_FUEL_STATION
             localIdentifier:[fuelStation localMasterIdentifier]
                          db:db
                       error:errorBlk];
}

- (void)saveNewFuelStation:(FPFuelStation *)fuelStation
                   forUser:(FPUser *)user
                     error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self saveNewFuelStation:fuelStation forUser:user db:db error:errorBlk];
  }];
}

- (void)saveNewAndSyncImmediateFuelStation:(FPFuelStation *)fuelStation
                                   forUser:(FPUser *)user
                                     error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [fuelStation setSyncInProgress:YES];
    [self saveNewFuelStation:fuelStation forUser:user db:db error:errorBlk];
  }];
}

- (void)saveNewFuelStation:(FPFuelStation *)fuelStation
                   forUser:(FPUser *)user
                        db:(FMDatabase *)db
                     error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils copyMasterEntity:user
                  toMainTable:TBL_MAIN_USER
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainUser:(FPUser *)entity db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  [fuelStation setEditCount:1];
  [self insertIntoMainFuelStation:fuelStation forUser:user db:db error:errorBlk];
}

- (BOOL)prepareFuelStationForEdit:(FPFuelStation *)fuelStation
                          forUser:(FPUser *)user
                               db:(FMDatabase *)db
                            error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils copyMasterEntity:user
                  toMainTable:TBL_MAIN_USER
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainUser:(FPUser *)entity db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  return [PELMUtils prepareEntityForEdit:fuelStation
                                      db:db
                               mainTable:TBL_MAIN_FUEL_STATION
                addlJoinEntityMainTables:_fuelstationTypeJoinTables
                     entityFromResultSet:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                      mainEntityInserter:^(PELMMainSupport *entity, FMDatabase *db, PELMDaoErrorBlk errorBlk) {
                        [self insertIntoMainFuelStation:fuelStation forUser:user db:db error:errorBlk];}
                       mainEntityUpdater:^(PELMMainSupport *entity, FMDatabase *db, PELMDaoErrorBlk errorBlk) {
                         [PELMUtils doUpdate:[self updateStmtForMainFuelStation]
                                   argsArray:[self updateArgsForMainFuelStation:fuelStation]
                                          db:db
                                       error:errorBlk];}
                                   error:errorBlk];
}

- (BOOL)prepareFuelStationForEdit:(FPFuelStation *)fuelStation
                          forUser:(FPUser *)user
                            error:(PELMDaoErrorBlk)errorBlk {
  __block BOOL returnVal;
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    returnVal = [self prepareFuelStationForEdit:fuelStation
                                        forUser:user
                                             db:db
                                          error:errorBlk];
  }];
  return returnVal;
}

- (void)saveFuelStation:(FPFuelStation *)fuelStation
                  error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils saveEntity:fuelStation
                     mainTable:TBL_MAIN_FUEL_STATION
                mainUpdateStmt:[self updateStmtForMainFuelStation]
             mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainFuelStation:(FPFuelStation *)entity];}
                         error:errorBlk];
}

- (void)markAsDoneEditingFuelStation:(FPFuelStation *)fuelStation
                               error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils markAsDoneEditingEntity:fuelStation
                                  mainTable:TBL_MAIN_FUEL_STATION
                             mainUpdateStmt:[self updateStmtForMainFuelStation]
                          mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainFuelStation:(FPFuelStation *)entity];}
                                      error:errorBlk];
}

- (void)markAsDoneEditingImmediateSyncFuelStation:(FPFuelStation *)fuelStation
                                            error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils markAsDoneEditingImmediateSyncEntity:fuelStation
                                                  mainTable:TBL_MAIN_FUEL_STATION
                                             mainUpdateStmt:[self updateStmtForMainFuelStation]
                                          mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainFuelStation:(FPFuelStation *)entity];}
                                                      error:errorBlk];
}

- (void)reloadFuelStation:(FPFuelStation *)fuelStation
                    error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils reloadEntity:fuelStation
                       fromMainTable:TBL_MAIN_FUEL_STATION
                      addlJoinTables:_fuelstationTypeJoinTables
                         rsConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                               error:errorBlk];
}

- (void)cancelEditOfFuelStation:(FPFuelStation *)fuelStation
                          error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils cancelEditOfEntity:fuelStation
                                 mainTable:TBL_MAIN_FUEL_STATION
                            mainUpdateStmt:[self updateStmtForMainFuelStation]
                         mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainFuelStation:(FPFuelStation *)entity];}
                               masterTable:TBL_MASTER_FUEL_STATION
                               rsConverter:^(FMResultSet *rs){return [self masterFuelStationFromResultSet:rs];}
                                     error:errorBlk];
}

- (NSArray *)markFuelStationsAsSyncInProgressForUser:(FPUser *)user
                                               error:(PELMDaoErrorBlk)errorBlk {
  return [self.localModelUtils markEntitiesAsSyncInProgressInMainTable:TBL_MAIN_FUEL_STATION
                                              addlJoinEntityMainTables:_fuelstationTypeJoinTables
                                                   entityFromResultSet:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                                                            updateStmt:[self updateStmtForMainFuelStation]
                                                         updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainFuelStation:(FPFuelStation *)entity];}
                                                                 error:errorBlk];
}

- (void)cancelSyncForFuelStation:(FPFuelStation *)fuelStation
                    httpRespCode:(NSNumber *)httpRespCode
                       errorMask:(NSNumber *)errorMask
                         retryAt:(NSDate *)retryAt
                           error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils cancelSyncForEntity:fuelStation
                               httpRespCode:httpRespCode
                                  errorMask:errorMask
                                    retryAt:retryAt
                             mainUpdateStmt:[self updateStmtForMainFuelStation]
                          mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainFuelStation:(FPFuelStation *)entity];}
                                      error:errorBlk];
}

- (PELMSaveNewOrExistingCode)saveNewOrExistingMasterFuelstation:(FPFuelStation *)fuelstation
                                                        forUser:(FPUser *)user
                                                             db:(FMDatabase *)db
                                                          error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils saveNewOrExistingMasterEntity:fuelstation
                                      masterTable:TBL_MASTER_FUEL_STATION
                                  masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterFuelStation:(FPFuelStation *)entity forUser:user db:db error:errorBlk];}
                                 masterUpdateStmt:[self updateStmtForMasterFuelStation]
                              masterUpdateArgsBlk:^NSArray * (FPFuelStation *theFuelstation) { return [self updateArgsForMasterFuelStation:theFuelstation]; }
                                        mainTable:TBL_MAIN_FUEL_STATION
                          mainEntityFromResultSet:^FPFuelStation * (FMResultSet *rs) { return [self mainFuelStationFromResultSet:rs]; }
                                   mainUpdateStmt:[self updateStmtForMainFuelStation]
                                mainUpdateArgsBlk:^NSArray * (FPFuelStation *theFuelstation) { return [self updateArgsForMainFuelStation:theFuelstation]; }
                                               db:db
                                            error:errorBlk];
}

- (void)saveNewMasterFuelstation:(FPFuelStation *)fuelstation
                         forUser:(FPUser *)user
                           error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils saveNewMasterEntity:fuelstation
                                masterTable:TBL_MASTER_FUEL_STATION
                            masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterFuelStation:(FPFuelStation *)entity forUser:user db:db error:errorBlk];}
                                      error:errorBlk];
}

- (BOOL)saveMasterFuelstation:(FPFuelStation *)fuelstation
                      forUser:(FPUser *)user
                        error:(PELMDaoErrorBlk)errorBlk {
  return [self.localModelUtils saveMasterEntity:fuelstation
                                    masterTable:TBL_MASTER_FUEL_STATION
                               masterUpdateStmt:[self updateStmtForMasterFuelStation]
                            masterUpdateArgsBlk:^ NSArray * (FPFuelStation *theFuelstation) { return [self updateArgsForMasterFuelStation:theFuelstation]; }
                                      mainTable:TBL_MAIN_FUEL_STATION
                        mainEntityFromResultSet:^ FPFuelStation * (FMResultSet *rs) { return [self mainFuelStationFromResultSet:rs]; }
                                 mainUpdateStmt:[self updateStmtForMainFuelStation]
                              mainUpdateArgsBlk:^ NSArray * (FPFuelStation *theFuelstation) { return [self updateArgsForMainFuelStation:theFuelstation]; }
                                          error:errorBlk];
}

- (void)markAsSyncCompleteForNewFuelStation:(FPFuelStation *)fuelStation
                                    forUser:(FPUser *)user
                                      error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils markAsSyncCompleteForNewEntity:fuelStation
                                         mainTable:TBL_MAIN_FUEL_STATION
                                       masterTable:TBL_MASTER_FUEL_STATION
                                    mainUpdateStmt:[self updateStmtForMainFuelStation]
                                 mainUpdateArgsBlk:^(id entity){return [self updateArgsForMainFuelStation:(FPFuelStation *)entity];}
                                   masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterFuelStation:(FPFuelStation *)entity forUser:user db:db error:errorBlk];}
                                             error:errorBlk];
}

- (void)markAsSyncCompleteForUpdatedFuelStation:(FPFuelStation *)fuelStation error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils markAsSyncCompleteForUpdatedEntityInTxn:fuelStation
                                                  mainTable:TBL_MAIN_FUEL_STATION
                                                masterTable:TBL_MASTER_FUEL_STATION
                                             mainUpdateStmt:[self updateStmtForMainFuelStation]
                                          mainUpdateArgsBlk:^(id entity){return [self updateArgsForMainFuelStation:(FPFuelStation *)entity];}
                                           masterUpdateStmt:[self updateStmtForMasterFuelStation]
                                        masterUpdateArgsBlk:^(id entity){return [self updateArgsForMasterFuelStation:(FPFuelStation *)entity];}
                                                      error:errorBlk];
}

- (FPFuelStationType *)fuelstationTypeForIdentifier:(NSNumber *)identifier error:(PELMDaoErrorBlk)errorBlk {
  __block FPFuelStationType *fstype = nil;
  if (identifier) {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
      FMResultSet *rs = [PELMUtils doQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", TBL_FUEL_STATION_TYPE, COL_FUELSTTYP_ID]
                                 argsArray:@[identifier]
                                        db:db
                                     error:errorBlk];
      while ([rs next]) {
        fstype = [self fuelStationTypeFromResultSet:rs];
      }
      [rs close];
    }];
  }
  return fstype;
}

- (NSArray *)fuelstationTypesWithError:(PELMDaoErrorBlk)errorBlk {
  NSMutableArray *fsTypes = [NSMutableArray array];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    FMResultSet *rs = [PELMUtils doQuery:[NSString stringWithFormat:@"SELECT * FROM %@ ORDER BY %@ ASC", TBL_FUEL_STATION_TYPE, COL_FUELSTTYP_SORT_ORDER]
                               argsArray:@[]
                                      db:db
                                   error:errorBlk];
    while ([rs next]) {
      [fsTypes addObject:[self fuelStationTypeFromResultSet:rs]];
    }
    [rs close];
  }];
  return fsTypes;
}

#pragma mark - Fuel Purchase Log

- (NSArray *)distinctOctanesForLogsBlk:(NSArray *(^)(void))logsBlk {
  NSArray *fplogs = logsBlk();
  NSMutableDictionary *octanes = [NSMutableDictionary dictionary];
  for (FPFuelPurchaseLog *fplog in fplogs) {
    if (![PEUtils isNil:fplog.octane]) {
      [octanes setObject:fplog.octane forKey:fplog.octane];
    }
  }
  NSArray *distinctOctanes = [octanes allKeys];
  return [distinctOctanes sortedArrayUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
    return [obj1 compare:obj2];
  }];
}

- (NSArray *)distinctOctanesForUser:(FPUser *)user
                              error:(PELMDaoErrorBlk)errorBlk {
  return [self distinctOctanesForLogsBlk:^{return [self unorderedFuelPurchaseLogsForUser:user error:errorBlk];}];
}

- (BOOL)hasDieselLogsForUser:(FPUser *)user
                       error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fplogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplogs = [PELMUtils entitiesForParentEntity:user
                          parentEntityMainTable:TBL_MAIN_USER
                 addlJoinParentEntityMainTables:nil
                    parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                     parentEntityMasterIdColumn:COL_MASTER_USER_ID
                       parentEntityMainIdColumn:COL_MAIN_USER_ID
                                       pageSize:@(1)
                                       whereBlk:[self fpLogDieselWhereBlk]
                                      whereArgs:nil
                              entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                     addlJoinEntityMasterTables:nil
                 masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                       addlJoinEntityMainTables:nil
                   mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                             db:db
                                          error:errorBlk];
  }];
  return [fplogs count] >= 1;
}

- (NSArray *)distinctOctanesForVehicle:(FPVehicle *)vehicle
                                 error:(PELMDaoErrorBlk)errorBlk {
  return [self distinctOctanesForLogsBlk:^{return [self unorderedFuelPurchaseLogsForVehicle:vehicle error:errorBlk];}];
}

- (BOOL)hasDieselLogsForVehicle:(FPVehicle *)vehicle
                          error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fplogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplogs = [PELMUtils entitiesForParentEntity:vehicle
                          parentEntityMainTable:TBL_MAIN_VEHICLE
                 addlJoinParentEntityMainTables:nil
                    parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                     parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                       parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                       pageSize:@(1)
                                       whereBlk:[self fpLogDieselWhereBlk]
                                      whereArgs:nil
                              entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                     addlJoinEntityMasterTables:nil
                 masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                       addlJoinEntityMainTables:nil
                   mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                             db:db
                                          error:errorBlk];
  }];
  return [fplogs count] >= 1;
}

- (NSArray *)distinctOctanesForFuelstation:(FPFuelStation *)fuelstation
                                     error:(PELMDaoErrorBlk)errorBlk {
  return [self distinctOctanesForLogsBlk:^{return [self unorderedFuelPurchaseLogsForFuelstation:fuelstation error:errorBlk];}];
}

- (BOOL)hasDieselLogsForFuelstation:(FPFuelStation *)fuelstation
                              error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fplogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplogs = [PELMUtils entitiesForParentEntity:fuelstation
                          parentEntityMainTable:TBL_MAIN_FUEL_STATION
                 addlJoinParentEntityMainTables:_fuelstationTypeJoinTables
                    parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                     parentEntityMasterIdColumn:COL_MASTER_FUELSTATION_ID
                       parentEntityMainIdColumn:COL_MAIN_FUELSTATION_ID
                                       pageSize:@(1)
                                       whereBlk:[self fpLogDieselWhereBlk]
                                      whereArgs:nil
                              entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                     addlJoinEntityMasterTables:nil
                 masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                       addlJoinEntityMainTables:nil
                   mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                             db:db
                                          error:errorBlk];
  }];
  return [fplogs count] >= 1;
}

- (NSArray *)unorderedFuelPurchaseLogsForFuelstation:(FPFuelStation *)fuelstation
                                               error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fplogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplogs = [PELMUtils entitiesForParentEntity:fuelstation
                          parentEntityMainTable:TBL_MAIN_FUEL_STATION
                 addlJoinParentEntityMainTables:_fuelstationTypeJoinTables
                    parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                     parentEntityMasterIdColumn:COL_MASTER_FUELSTATION_ID
                       parentEntityMainIdColumn:COL_MAIN_FUELSTATION_ID
                                       pageSize:nil
                                       whereBlk:nil
                                      whereArgs:nil
                              entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                     addlJoinEntityMasterTables:nil
                 masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                       addlJoinEntityMainTables:nil
                   mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                             db:db
                                          error:errorBlk];
  }];
  return fplogs;
}

- (NSArray *)unorderedFuelPurchaseLogsForFuelstation:(FPFuelStation *)fuelstation
                                          beforeDate:(NSDate *)beforeDate
                                       onOrAfterDate:(NSDate *)onOrAfterDate
                                               error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fplogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplogs = [PELMUtils entitiesForParentEntity:fuelstation
                          parentEntityMainTable:TBL_MAIN_FUEL_STATION
                 addlJoinParentEntityMainTables:_fuelstationTypeJoinTables
                    parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                     parentEntityMasterIdColumn:COL_MASTER_FUELSTATION_ID
                       parentEntityMainIdColumn:COL_MAIN_FUELSTATION_ID
                                       pageSize:nil
                                       whereBlk:[self fpLogDateRangeWhereBlk]
                                      whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                  [PEUtils millisecondsFromDate:onOrAfterDate]]
                              entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                     addlJoinEntityMasterTables:nil
                 masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                       addlJoinEntityMainTables:nil
                   mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                             db:db
                                          error:errorBlk];
  }];
  return fplogs;
}

- (NSArray *)unorderedFuelPurchaseLogsForFuelstation:(FPFuelStation *)fuelstation
                                          beforeDate:(NSDate *)beforeDate
                                       onOrAfterDate:(NSDate *)onOrAfterDate
                                              octane:(NSNumber *)octane
                                               error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fplogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplogs = [PELMUtils entitiesForParentEntity:fuelstation
                          parentEntityMainTable:TBL_MAIN_FUEL_STATION
                 addlJoinParentEntityMainTables:_fuelstationTypeJoinTables
                    parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                     parentEntityMasterIdColumn:COL_MASTER_FUELSTATION_ID
                       parentEntityMainIdColumn:COL_MAIN_FUELSTATION_ID
                                       pageSize:nil
                                       whereBlk:[self fpLogDateRangeOctaneWhereBlk]
                                      whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                  [PEUtils millisecondsFromDate:onOrAfterDate],
                                                  octane]
                              entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                     addlJoinEntityMasterTables:nil
                 masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                       addlJoinEntityMainTables:nil
                   mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                             db:db
                                          error:errorBlk];
  }];
  return fplogs;
}

- (NSArray *)unorderedDieselFuelPurchaseLogsForFuelstation:(FPFuelStation *)fuelstation
                                                beforeDate:(NSDate *)beforeDate
                                             onOrAfterDate:(NSDate *)onOrAfterDate
                                                     error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fplogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplogs = [PELMUtils entitiesForParentEntity:fuelstation
                          parentEntityMainTable:TBL_MAIN_FUEL_STATION
                 addlJoinParentEntityMainTables:_fuelstationTypeJoinTables
                    parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                     parentEntityMasterIdColumn:COL_MASTER_FUELSTATION_ID
                       parentEntityMainIdColumn:COL_MAIN_FUELSTATION_ID
                                       pageSize:nil
                                       whereBlk:[self fpLogDateRangeDieselWhereBlk]
                                      whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                  [PEUtils millisecondsFromDate:onOrAfterDate]]
                              entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                     addlJoinEntityMasterTables:nil
                 masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                       addlJoinEntityMainTables:nil
                   mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                             db:db
                                          error:errorBlk];
  }];
  return fplogs;
}

- (NSArray *)unorderedFuelPurchaseLogsForFuelstation:(FPFuelStation *)fuelstation
                                              octane:(NSNumber *)octane
                                               error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fplogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplogs = [PELMUtils entitiesForParentEntity:fuelstation
                          parentEntityMainTable:TBL_MAIN_FUEL_STATION
                 addlJoinParentEntityMainTables:_fuelstationTypeJoinTables
                    parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                     parentEntityMasterIdColumn:COL_MASTER_FUELSTATION_ID
                       parentEntityMainIdColumn:COL_MAIN_FUELSTATION_ID
                                       pageSize:nil
                                       whereBlk:[self fpLogOctaneWhereBlk]
                                      whereArgs:@[octane]
                              entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                     addlJoinEntityMasterTables:nil
                 masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                       addlJoinEntityMainTables:nil
                   mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                             db:db
                                          error:errorBlk];
  }];
  return fplogs;
}

- (NSArray *)unorderedDieselFuelPurchaseLogsForFuelstation:(FPFuelStation *)fuelstation
                                                     error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fplogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplogs = [PELMUtils entitiesForParentEntity:fuelstation
                          parentEntityMainTable:TBL_MAIN_FUEL_STATION
                 addlJoinParentEntityMainTables:_fuelstationTypeJoinTables
                    parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                     parentEntityMasterIdColumn:COL_MASTER_FUELSTATION_ID
                       parentEntityMainIdColumn:COL_MAIN_FUELSTATION_ID
                                       pageSize:nil
                                       whereBlk:[self fpLogDieselWhereBlk]
                                      whereArgs:nil
                              entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                     addlJoinEntityMasterTables:nil
                 masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                       addlJoinEntityMainTables:nil
                   mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                             db:db
                                          error:errorBlk];
  }];
  return fplogs;
}

- (FPFuelPurchaseLog *)minMaxGallonPriceFuelPurchaseLogForUser:(FPUser *)user
                                                      whereBlk:(NSString *(^)(NSString *))whereBlk
                                                     whereArgs:(NSArray *)whereArgs
                                             comparatorForSort:(NSComparisonResult(^)(id, id))comparatorForSort
                                  orderByDomainColumnDirection:(NSString *)orderByDomainColumnDirection
                                                         error:(PELMDaoErrorBlk)errorBlk {
  return [self singleGasLogForUser:user
                          whereBlk:whereBlk
                         whereArgs:whereArgs
                 comparatorForSort:comparatorForSort
               orderByDomainColumn:COL_FUELPL_PRICE_PER_GALLON
      orderByDomainColumnDirection:orderByDomainColumnDirection
                             error:errorBlk];
}

- (FPFuelPurchaseLog *)minMaxGallonPriceFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                         whereBlk:(NSString *(^)(NSString *))whereBlk
                                                        whereArgs:(NSArray *)whereArgs
                                                comparatorForSort:(NSComparisonResult(^)(id, id))comparatorForSort
                                     orderByDomainColumnDirection:(NSString *)orderByDomainColumnDirection
                                                            error:(PELMDaoErrorBlk)errorBlk {
  return [self singleGasLogForVehicle:vehicle
                             whereBlk:whereBlk
                            whereArgs:whereArgs
                    comparatorForSort:comparatorForSort
                  orderByDomainColumn:COL_FUELPL_PRICE_PER_GALLON
         orderByDomainColumnDirection:orderByDomainColumnDirection
                                error:errorBlk];
}

- (FPFuelPurchaseLog *)minMaxGallonPriceFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                             whereBlk:(NSString *(^)(NSString *))whereBlk
                                                            whereArgs:(NSArray *)whereArgs
                                                    comparatorForSort:(NSComparisonResult(^)(id, id))comparatorForSort
                                         orderByDomainColumnDirection:(NSString *)orderByDomainColumnDirection
                                                                error:(PELMDaoErrorBlk)errorBlk {
  return [self singleGasLogForFuelstation:fuelstation
                                 whereBlk:whereBlk
                                whereArgs:whereArgs
                        comparatorForSort:comparatorForSort
                      orderByDomainColumn:COL_FUELPL_PRICE_PER_GALLON
             orderByDomainColumnDirection:orderByDomainColumnDirection
                                    error:errorBlk];
}

- (NSString *(^)(NSString *))fpLogDateRangeOctaneWhereBlk {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ < ? AND %@%@ >= ? AND %@%@ = ?",
            colPrefix,
            COL_FUELPL_PURCHASED_AT,
            colPrefix,
            COL_FUELPL_PURCHASED_AT,
            colPrefix,
            COL_FUELPL_OCTANE];
  };
}

- (NSString *(^)(NSString *))fpLogDateRangeDieselWhereBlk {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ < ? AND %@%@ >= ? AND %@%@ is null AND %@%@ = 1",
            colPrefix,
            COL_FUELPL_PURCHASED_AT,
            colPrefix,
            COL_FUELPL_PURCHASED_AT,
            colPrefix,
            COL_FUELPL_OCTANE,
            colPrefix,
            COL_FUELPL_IS_DIESEL];
  };
}

- (NSString *(^)(NSString *))fpLogDateRangeOctaneNonNilGallonPriceWhereBlk {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ < ? AND %@%@ >= ? AND %@%@ = ? AND %@%@ is not null",
            colPrefix,
            COL_FUELPL_PURCHASED_AT,
            colPrefix,
            COL_FUELPL_PURCHASED_AT,
            colPrefix,
            COL_FUELPL_OCTANE,
            colPrefix,
            COL_FUELPL_PRICE_PER_GALLON];
  };
}

- (NSString *(^)(NSString *))fpLogDateRangeNonNilGallonPriceWhereBlk {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ < ? AND %@%@ >= ? AND %@%@ is not null",
            colPrefix,
            COL_FUELPL_PURCHASED_AT,
            colPrefix,
            COL_FUELPL_PURCHASED_AT,
            colPrefix,
            COL_FUELPL_PRICE_PER_GALLON];
  };
}

- (NSString *(^)(NSString *))fpLogDateRangeDieselNonNilGallonPriceWhereBlk {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ < ? AND %@%@ >= ? AND %@%@ is null AND %@%@ is not null and %@%@ = 1",
            colPrefix,
            COL_FUELPL_PURCHASED_AT,
            colPrefix,
            COL_FUELPL_PURCHASED_AT,
            colPrefix,
            COL_FUELPL_OCTANE,
            colPrefix,
            COL_FUELPL_PRICE_PER_GALLON,
            colPrefix,
            COL_FUELPL_IS_DIESEL];
  };
}

- (NSString *(^)(NSString *))fpLogStrictDateRangeOctaneWhereBlk {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ < ? AND %@%@ > ? AND %@%@ = ?",
            colPrefix,
            COL_FUELPL_PURCHASED_AT,
            colPrefix,
            COL_FUELPL_PURCHASED_AT,
            colPrefix,
            COL_FUELPL_OCTANE];
  };
}

- (NSString *(^)(NSString *))fpLogStrictDateRangeDieselWhereBlk {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ < ? AND %@%@ > ? AND %@%@ = is null AND %@%@ = 1",
            colPrefix,
            COL_FUELPL_PURCHASED_AT,
            colPrefix,
            COL_FUELPL_PURCHASED_AT,
            colPrefix,
            COL_FUELPL_OCTANE,
            colPrefix,
            COL_FUELPL_IS_DIESEL];
  };
}

- (NSString *(^)(NSString *))fpLogDateRangeWhereBlk {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ < ? AND %@%@ >= ?",
            colPrefix,
            COL_FUELPL_PURCHASED_AT,
            colPrefix,
            COL_FUELPL_PURCHASED_AT];
  };
}

- (NSString *(^)(NSString *))fpLogStrictDateRangeWhereBlk {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ < ? AND %@%@ > ?",
            colPrefix,
            COL_FUELPL_PURCHASED_AT,
            colPrefix,
            COL_FUELPL_PURCHASED_AT];
  };
}

- (NSString *(^)(NSString *))fpLogOctaneWhereBlk {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ = ?",
            colPrefix,
            COL_FUELPL_OCTANE];
  };
}

- (NSString *(^)(NSString *))fpLogDieselWhereBlk {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ is null AND %@%@ = 1",
            colPrefix,
            COL_FUELPL_OCTANE,
            colPrefix,
            COL_FUELPL_IS_DIESEL];
  };
}

- (NSString *(^)(NSString *))fpLogOctaneNonNilGallonPriceWhereBlk {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ = ? AND %@%@ is not null",
            colPrefix,
            COL_FUELPL_OCTANE,
            colPrefix,
            COL_FUELPL_PRICE_PER_GALLON];
  };
}

- (NSString *(^)(NSString *))fpLogNonNilGallonPriceWhereBlk {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ is not null",
            colPrefix,
            COL_FUELPL_PRICE_PER_GALLON];
  };
}

- (NSString *(^)(NSString *))fpLogDieselNonNilGallonPriceWhereBlk {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ is null AND %@%@ is not null and %@%@ = 1",
            colPrefix,
            COL_FUELPL_OCTANE,
            colPrefix,
            COL_FUELPL_PRICE_PER_GALLON,
            colPrefix,
            COL_FUELPL_IS_DIESEL];
  };
}

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                    beforeDate:(NSDate *)beforeDate
                                                 onOrAfterDate:(NSDate *)onOrAfterDate
                                                        octane:(NSNumber *)octane
                                                         error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                 whereBlk:[self fpLogDateRangeOctaneNonNilGallonPriceWhereBlk]
                                                whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                            [PEUtils millisecondsFromDate:onOrAfterDate],
                                                            octane]
                                        comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 gallonPrice] compare:[(FPFuelPurchaseLog *)o1 gallonPrice]];}
                             orderByDomainColumnDirection:@"DESC"
                                                    error:errorBlk];
}

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                    beforeDate:(NSDate *)beforeDate
                                                 onOrAfterDate:(NSDate *)onOrAfterDate
                                                         error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                 whereBlk:[self fpLogDateRangeNonNilGallonPriceWhereBlk]
                                                whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                            [PEUtils millisecondsFromDate:onOrAfterDate]]
                                        comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 gallonPrice] compare:[(FPFuelPurchaseLog *)o1 gallonPrice]];}
                             orderByDomainColumnDirection:@"DESC"
                                                    error:errorBlk];
}

- (FPFuelPurchaseLog *)maxGallonPriceDieselFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                          beforeDate:(NSDate *)beforeDate
                                                       onOrAfterDate:(NSDate *)onOrAfterDate
                                                               error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                 whereBlk:[self fpLogDateRangeDieselNonNilGallonPriceWhereBlk]
                                                whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                            [PEUtils millisecondsFromDate:onOrAfterDate]]
                                        comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 gallonPrice] compare:[(FPFuelPurchaseLog *)o1 gallonPrice]];}
                             orderByDomainColumnDirection:@"DESC"
                                                    error:errorBlk];
}

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                    beforeDate:(NSDate *)beforeDate
                                                 onOrAfterDate:(NSDate *)onOrAfterDate
                                                        octane:(NSNumber *)octane
                                                         error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                 whereBlk:[self fpLogDateRangeOctaneNonNilGallonPriceWhereBlk]
                                                whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                            [PEUtils millisecondsFromDate:onOrAfterDate],
                                                            octane]
                                        comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 gallonPrice] compare:[(FPFuelPurchaseLog *)o2 gallonPrice]];}
                             orderByDomainColumnDirection:@"ASC"
                                                    error:errorBlk];
}

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                    beforeDate:(NSDate *)beforeDate
                                                 onOrAfterDate:(NSDate *)onOrAfterDate
                                                         error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                 whereBlk:[self fpLogDateRangeNonNilGallonPriceWhereBlk]
                                                whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                            [PEUtils millisecondsFromDate:onOrAfterDate]]
                                        comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 gallonPrice] compare:[(FPFuelPurchaseLog *)o2 gallonPrice]];}
                             orderByDomainColumnDirection:@"ASC"
                                                    error:errorBlk];
}

- (FPFuelPurchaseLog *)minGallonPriceDieselFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                          beforeDate:(NSDate *)beforeDate
                                                       onOrAfterDate:(NSDate *)onOrAfterDate
                                                               error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                 whereBlk:[self fpLogDateRangeDieselNonNilGallonPriceWhereBlk]
                                                whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                            [PEUtils millisecondsFromDate:onOrAfterDate]]
                                        comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 gallonPrice] compare:[(FPFuelPurchaseLog *)o2 gallonPrice]];}
                             orderByDomainColumnDirection:@"ASC"
                                                    error:errorBlk];
}

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                        octane:(NSNumber *)octane
                                                         error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                 whereBlk:[self fpLogOctaneNonNilGallonPriceWhereBlk]
                                                whereArgs:@[octane]
                                        comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 gallonPrice] compare:[(FPFuelPurchaseLog *)o1 gallonPrice]];}
                             orderByDomainColumnDirection:@"DESC"
                                                    error:errorBlk];
}

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                         error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                 whereBlk:[self fpLogNonNilGallonPriceWhereBlk]
                                                whereArgs:nil
                                        comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 gallonPrice] compare:[(FPFuelPurchaseLog *)o1 gallonPrice]];}
                             orderByDomainColumnDirection:@"DESC"
                                                    error:errorBlk];
}

- (FPFuelPurchaseLog *)maxGallonPriceDieselFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                               error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                 whereBlk:[self fpLogDieselNonNilGallonPriceWhereBlk]
                                                whereArgs:nil
                                        comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 gallonPrice] compare:[(FPFuelPurchaseLog *)o1 gallonPrice]];}
                             orderByDomainColumnDirection:@"DESC"
                                                    error:errorBlk];
}

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                        octane:(NSNumber *)octane
                                                         error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                 whereBlk:[self fpLogOctaneNonNilGallonPriceWhereBlk]
                                                whereArgs:@[octane]
                                        comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 gallonPrice] compare:[(FPFuelPurchaseLog *)o2 gallonPrice]];}
                             orderByDomainColumnDirection:@"ASC"
                                                    error:errorBlk];
}

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                         error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                 whereBlk:[self fpLogNonNilGallonPriceWhereBlk]
                                                whereArgs:nil
                                        comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 gallonPrice] compare:[(FPFuelPurchaseLog *)o2 gallonPrice]];}
                             orderByDomainColumnDirection:@"ASC"
                                                    error:errorBlk];
}

- (FPFuelPurchaseLog *)minGallonPriceDieselFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                               error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                 whereBlk:[self fpLogDieselNonNilGallonPriceWhereBlk]
                                                whereArgs:nil
                                        comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 gallonPrice] compare:[(FPFuelPurchaseLog *)o2 gallonPrice]];}
                             orderByDomainColumnDirection:@"ASC"
                                                    error:errorBlk];
}

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                        beforeDate:(NSDate *)beforeDate
                                                     onOrAfterDate:(NSDate *)onOrAfterDate
                                                            octane:(NSNumber *)octane
                                                             error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                     whereBlk:[self fpLogDateRangeOctaneNonNilGallonPriceWhereBlk]
                                                    whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                                [PEUtils millisecondsFromDate:onOrAfterDate],
                                                                octane]
                                            comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 gallonPrice] compare:[(FPFuelPurchaseLog *)o1 gallonPrice]];}
                                 orderByDomainColumnDirection:@"DESC"
                                                        error:errorBlk];
}

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                        beforeDate:(NSDate *)beforeDate
                                                     onOrAfterDate:(NSDate *)onOrAfterDate
                                                             error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                     whereBlk:[self fpLogDateRangeNonNilGallonPriceWhereBlk]
                                                    whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                                [PEUtils millisecondsFromDate:onOrAfterDate]]
                                            comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 gallonPrice] compare:[(FPFuelPurchaseLog *)o1 gallonPrice]];}
                                 orderByDomainColumnDirection:@"DESC"
                                                        error:errorBlk];
}

- (FPFuelPurchaseLog *)maxGallonPriceDieselFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                              beforeDate:(NSDate *)beforeDate
                                                           onOrAfterDate:(NSDate *)onOrAfterDate
                                                                   error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                     whereBlk:[self fpLogDateRangeDieselNonNilGallonPriceWhereBlk]
                                                    whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                                [PEUtils millisecondsFromDate:onOrAfterDate]]
                                            comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 gallonPrice] compare:[(FPFuelPurchaseLog *)o1 gallonPrice]];}
                                 orderByDomainColumnDirection:@"DESC"
                                                        error:errorBlk];
}

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                        beforeDate:(NSDate *)beforeDate
                                                     onOrAfterDate:(NSDate *)onOrAfterDate
                                                            octane:(NSNumber *)octane
                                                             error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                     whereBlk:[self fpLogDateRangeOctaneNonNilGallonPriceWhereBlk]
                                                    whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                                [PEUtils millisecondsFromDate:onOrAfterDate],
                                                                octane]
                                            comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 gallonPrice] compare:[(FPFuelPurchaseLog *)o2 gallonPrice]];}
                                 orderByDomainColumnDirection:@"ASC"
                                                        error:errorBlk];
}

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                        beforeDate:(NSDate *)beforeDate
                                                     onOrAfterDate:(NSDate *)onOrAfterDate
                                                             error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                     whereBlk:[self fpLogDateRangeOctaneNonNilGallonPriceWhereBlk]
                                                    whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                                [PEUtils millisecondsFromDate:onOrAfterDate]]
                                            comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 gallonPrice] compare:[(FPFuelPurchaseLog *)o2 gallonPrice]];}
                                 orderByDomainColumnDirection:@"ASC"
                                                        error:errorBlk];
}

- (FPFuelPurchaseLog *)minGallonPriceDieselFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                              beforeDate:(NSDate *)beforeDate
                                                           onOrAfterDate:(NSDate *)onOrAfterDate
                                                                   error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                     whereBlk:[self fpLogDateRangeDieselNonNilGallonPriceWhereBlk]
                                                    whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                                [PEUtils millisecondsFromDate:onOrAfterDate]]
                                            comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 gallonPrice] compare:[(FPFuelPurchaseLog *)o2 gallonPrice]];}
                                 orderByDomainColumnDirection:@"ASC"
                                                        error:errorBlk];
}

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                            octane:(NSNumber *)octane
                                                             error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                     whereBlk:[self fpLogOctaneNonNilGallonPriceWhereBlk]
                                                    whereArgs:@[octane]
                                            comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 gallonPrice] compare:[(FPFuelPurchaseLog *)o1 gallonPrice]];}
                                 orderByDomainColumnDirection:@"DESC"
                                                        error:errorBlk];
}

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                             error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                     whereBlk:[self fpLogNonNilGallonPriceWhereBlk]
                                                    whereArgs:nil
                                            comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 gallonPrice] compare:[(FPFuelPurchaseLog *)o1 gallonPrice]];}
                                 orderByDomainColumnDirection:@"DESC"
                                                        error:errorBlk];
}

- (FPFuelPurchaseLog *)maxGallonPriceDieselFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                                   error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                     whereBlk:[self fpLogDieselNonNilGallonPriceWhereBlk]
                                                    whereArgs:nil
                                            comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 gallonPrice] compare:[(FPFuelPurchaseLog *)o1 gallonPrice]];}
                                 orderByDomainColumnDirection:@"DESC"
                                                        error:errorBlk];
}

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                            octane:(NSNumber *)octane
                                                             error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                     whereBlk:[self fpLogOctaneNonNilGallonPriceWhereBlk]
                                                    whereArgs:@[octane]
                                            comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 gallonPrice] compare:[(FPFuelPurchaseLog *)o2 gallonPrice]];}
                                 orderByDomainColumnDirection:@"ASC"
                                                        error:errorBlk];
}

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                             error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                     whereBlk:[self fpLogNonNilGallonPriceWhereBlk]
                                                    whereArgs:nil
                                            comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 gallonPrice] compare:[(FPFuelPurchaseLog *)o2 gallonPrice]];}
                                 orderByDomainColumnDirection:@"ASC"
                                                        error:errorBlk];
}

- (FPFuelPurchaseLog *)minGallonPriceDieselFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                                   error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                     whereBlk:[self fpLogDieselNonNilGallonPriceWhereBlk]
                                                    whereArgs:nil
                                            comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 gallonPrice] compare:[(FPFuelPurchaseLog *)o2 gallonPrice]];}
                                 orderByDomainColumnDirection:@"ASC"
                                                        error:errorBlk];
}

- (NSArray *)unorderedFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                           error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fplogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplogs = [PELMUtils entitiesForParentEntity:vehicle
                          parentEntityMainTable:TBL_MAIN_VEHICLE
                 addlJoinParentEntityMainTables:nil
                    parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                     parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                       parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                       pageSize:nil
                                       whereBlk:nil
                                      whereArgs:nil
                              entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                     addlJoinEntityMasterTables:nil
                 masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                       addlJoinEntityMainTables:nil
                   mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                             db:db
                                          error:errorBlk];
  }];
  return fplogs;
}

- (NSArray *)unorderedFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                      beforeDate:(NSDate *)beforeDate
                                   onOrAfterDate:(NSDate *)onOrAfterDate
                                           error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fplogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplogs = [PELMUtils entitiesForParentEntity:vehicle
                          parentEntityMainTable:TBL_MAIN_VEHICLE
                 addlJoinParentEntityMainTables:nil
                    parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                     parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                       parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                       pageSize:nil
                                       whereBlk:[self fpLogDateRangeWhereBlk]
                                      whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                  [PEUtils millisecondsFromDate:onOrAfterDate]]
                              entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                     addlJoinEntityMasterTables:nil
                 masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                       addlJoinEntityMainTables:nil
                   mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                             db:db
                                          error:errorBlk];
  }];
  return fplogs;
}

- (NSArray *)unorderedFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                      beforeDate:(NSDate *)beforeDate
                                       afterDate:(NSDate *)afterDate
                                           error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fplogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplogs = [PELMUtils entitiesForParentEntity:vehicle
                          parentEntityMainTable:TBL_MAIN_VEHICLE
                 addlJoinParentEntityMainTables:nil
                    parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                     parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                       parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                       pageSize:nil
                                       whereBlk:[self fpLogStrictDateRangeWhereBlk]
                                      whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                  [PEUtils millisecondsFromDate:afterDate]]
                              entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                     addlJoinEntityMasterTables:nil
                 masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                       addlJoinEntityMainTables:nil
                   mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                             db:db
                                          error:errorBlk];
  }];
  return fplogs;
}

- (NSArray *)unorderedFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                      beforeDate:(NSDate *)beforeDate
                                   onOrAfterDate:(NSDate *)onOrAfterDate
                                          octane:(NSNumber *)octane
                                           error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fplogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplogs = [PELMUtils entitiesForParentEntity:vehicle
                          parentEntityMainTable:TBL_MAIN_VEHICLE
                 addlJoinParentEntityMainTables:nil
                    parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                     parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                       parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                       pageSize:nil
                                       whereBlk:[self fpLogDateRangeOctaneWhereBlk]
                                      whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                  [PEUtils millisecondsFromDate:onOrAfterDate],
                                                  octane]
                              entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                     addlJoinEntityMasterTables:nil
                 masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                       addlJoinEntityMainTables:nil
                   mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                             db:db
                                          error:errorBlk];
  }];
  return fplogs;
}

- (NSArray *)unorderedDieselFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                            beforeDate:(NSDate *)beforeDate
                                         onOrAfterDate:(NSDate *)onOrAfterDate
                                                 error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fplogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplogs = [PELMUtils entitiesForParentEntity:vehicle
                          parentEntityMainTable:TBL_MAIN_VEHICLE
                 addlJoinParentEntityMainTables:nil
                    parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                     parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                       parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                       pageSize:nil
                                       whereBlk:[self fpLogDateRangeDieselWhereBlk]
                                      whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                  [PEUtils millisecondsFromDate:onOrAfterDate]]
                              entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                     addlJoinEntityMasterTables:nil
                 masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                       addlJoinEntityMainTables:nil
                   mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                             db:db
                                          error:errorBlk];
  }];
  return fplogs;
}

- (NSArray *)unorderedFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                      beforeDate:(NSDate *)beforeDate
                                       afterDate:(NSDate *)afterDate
                                          octane:(NSNumber *)octane
                                           error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fplogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplogs = [PELMUtils entitiesForParentEntity:vehicle
                          parentEntityMainTable:TBL_MAIN_VEHICLE
                 addlJoinParentEntityMainTables:nil
                    parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                     parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                       parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                       pageSize:nil
                                       whereBlk:[self fpLogStrictDateRangeOctaneWhereBlk]
                                      whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                  [PEUtils millisecondsFromDate:afterDate],
                                                  octane]
                              entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                     addlJoinEntityMasterTables:nil
                 masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                       addlJoinEntityMainTables:nil
                   mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                             db:db
                                          error:errorBlk];
  }];
  return fplogs;
}

- (NSArray *)unorderedDieselFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                            beforeDate:(NSDate *)beforeDate
                                             afterDate:(NSDate *)afterDate
                                                 error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fplogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplogs = [PELMUtils entitiesForParentEntity:vehicle
                          parentEntityMainTable:TBL_MAIN_VEHICLE
                 addlJoinParentEntityMainTables:nil
                    parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                     parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                       parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                       pageSize:nil
                                       whereBlk:[self fpLogStrictDateRangeDieselWhereBlk]
                                      whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                  [PEUtils millisecondsFromDate:afterDate]]
                              entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                     addlJoinEntityMasterTables:nil
                 masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                       addlJoinEntityMainTables:nil
                   mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                             db:db
                                          error:errorBlk];
  }];
  return fplogs;
}

- (NSArray *)unorderedFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                          octane:(NSNumber *)octane
                                           error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fplogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplogs = [PELMUtils entitiesForParentEntity:vehicle
                          parentEntityMainTable:TBL_MAIN_VEHICLE
                 addlJoinParentEntityMainTables:nil
                    parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                     parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                       parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                       pageSize:nil
                                       whereBlk:[self fpLogOctaneWhereBlk]
                                      whereArgs:@[octane]
                              entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                     addlJoinEntityMasterTables:nil
                 masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                       addlJoinEntityMainTables:nil
                   mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                             db:db
                                          error:errorBlk];
  }];
  return fplogs;
}

- (NSArray *)unorderedDieselFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                                 error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fplogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplogs = [PELMUtils entitiesForParentEntity:vehicle
                          parentEntityMainTable:TBL_MAIN_VEHICLE
                 addlJoinParentEntityMainTables:nil
                    parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                     parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                       parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                       pageSize:nil
                                       whereBlk:[self fpLogDieselWhereBlk]
                                      whereArgs:nil
                              entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                     addlJoinEntityMasterTables:nil
                 masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                       addlJoinEntityMainTables:nil
                   mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                             db:db
                                          error:errorBlk];
  }];
  return fplogs;
}

- (NSArray *)unorderedFuelPurchaseLogsForUser:(FPUser *)user
                                        error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fplogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplogs = [PELMUtils entitiesForParentEntity:user
                          parentEntityMainTable:TBL_MAIN_USER
                 addlJoinParentEntityMainTables:nil
                    parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                     parentEntityMasterIdColumn:COL_MASTER_USER_ID
                       parentEntityMainIdColumn:COL_MAIN_USER_ID
                                       pageSize:nil
                                       whereBlk:nil
                                      whereArgs:nil
                              entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                     addlJoinEntityMasterTables:nil
                 masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                       addlJoinEntityMainTables:nil
                   mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                             db:db
                                          error:errorBlk];
  }];
  return fplogs;
}

- (NSArray *)unorderedFuelPurchaseLogsForUser:(FPUser *)user
                                   beforeDate:(NSDate *)beforeDate
                                onOrAfterDate:(NSDate *)onOrAfterDate
                                        error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fplogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplogs = [PELMUtils entitiesForParentEntity:user
                          parentEntityMainTable:TBL_MAIN_USER
                 addlJoinParentEntityMainTables:nil
                    parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                     parentEntityMasterIdColumn:COL_MASTER_USER_ID
                       parentEntityMainIdColumn:COL_MAIN_USER_ID
                                       pageSize:nil
                                       whereBlk:[self fpLogDateRangeWhereBlk]
                                      whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                  [PEUtils millisecondsFromDate:onOrAfterDate]]
                              entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                     addlJoinEntityMasterTables:nil
                 masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                       addlJoinEntityMainTables:nil
                   mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                             db:db
                                          error:errorBlk];
  }];
  return fplogs;
}

- (NSArray *)unorderedFuelPurchaseLogsForUser:(FPUser *)user
                                   beforeDate:(NSDate *)beforeDate
                                onOrAfterDate:(NSDate *)onOrAfterDate
                                       octane:(NSNumber *)octane
                                        error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fplogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplogs = [PELMUtils entitiesForParentEntity:user
                          parentEntityMainTable:TBL_MAIN_USER
                 addlJoinParentEntityMainTables:nil
                    parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                     parentEntityMasterIdColumn:COL_MASTER_USER_ID
                       parentEntityMainIdColumn:COL_MAIN_USER_ID
                                       pageSize:nil
                                       whereBlk:[self fpLogDateRangeOctaneWhereBlk]
                                      whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                  [PEUtils millisecondsFromDate:onOrAfterDate],
                                                  octane]
                              entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                     addlJoinEntityMasterTables:nil
                 masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                       addlJoinEntityMainTables:nil
                   mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                             db:db
                                          error:errorBlk];
  }];
  return fplogs;
}

- (NSArray *)unorderedDieselFuelPurchaseLogsForUser:(FPUser *)user
                                         beforeDate:(NSDate *)beforeDate
                                      onOrAfterDate:(NSDate *)onOrAfterDate
                                              error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fplogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplogs = [PELMUtils entitiesForParentEntity:user
                          parentEntityMainTable:TBL_MAIN_USER
                 addlJoinParentEntityMainTables:nil
                    parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                     parentEntityMasterIdColumn:COL_MASTER_USER_ID
                       parentEntityMainIdColumn:COL_MAIN_USER_ID
                                       pageSize:nil
                                       whereBlk:[self fpLogDateRangeDieselWhereBlk]
                                      whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                  [PEUtils millisecondsFromDate:onOrAfterDate]]
                              entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                     addlJoinEntityMasterTables:nil
                 masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                       addlJoinEntityMainTables:nil
                   mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                             db:db
                                          error:errorBlk];
  }];
  return fplogs;
}

- (NSArray *)unorderedFuelPurchaseLogsForUser:(FPUser *)user
                                       octane:(NSNumber *)octane
                                        error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fplogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplogs = [PELMUtils entitiesForParentEntity:user
                          parentEntityMainTable:TBL_MAIN_USER
                 addlJoinParentEntityMainTables:nil
                    parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                     parentEntityMasterIdColumn:COL_MASTER_USER_ID
                       parentEntityMainIdColumn:COL_MAIN_USER_ID
                                       pageSize:nil
                                       whereBlk:[self fpLogOctaneWhereBlk]
                                      whereArgs:@[octane]
                              entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                     addlJoinEntityMasterTables:nil
                 masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                       addlJoinEntityMainTables:nil
                   mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                             db:db
                                          error:errorBlk];
  }];
  return fplogs;
}

- (NSArray *)unorderedDieselFuelPurchaseLogsForUser:(FPUser *)user
                                              error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fplogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplogs = [PELMUtils entitiesForParentEntity:user
                          parentEntityMainTable:TBL_MAIN_USER
                 addlJoinParentEntityMainTables:nil
                    parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                     parentEntityMasterIdColumn:COL_MASTER_USER_ID
                       parentEntityMainIdColumn:COL_MAIN_USER_ID
                                       pageSize:nil
                                       whereBlk:[self fpLogDieselWhereBlk]
                                      whereArgs:nil
                              entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                     addlJoinEntityMasterTables:nil
                 masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                       addlJoinEntityMainTables:nil
                   mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                             db:db
                                          error:errorBlk];
  }];
  return fplogs;
}

- (FPFuelPurchaseLog *)singleGasLogForUser:(FPUser *)user
                                  whereBlk:(NSString *(^)(NSString *))whereBlk
                                 whereArgs:(NSArray *)whereArgs
                         comparatorForSort:(NSComparisonResult(^)(id, id))comparatorForSort
                       orderByDomainColumn:(NSString *)orderByDomainColumn
              orderByDomainColumnDirection:(NSString *)orderByDomainColumnDirection
                                     error:(PELMDaoErrorBlk)errorBlk {
  __block FPFuelPurchaseLog *fplog = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    NSArray *fplogs = [PELMUtils entitiesForParentEntity:user
                                   parentEntityMainTable:TBL_MAIN_USER
                          addlJoinParentEntityMainTables:nil
                             parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                              parentEntityMasterIdColumn:COL_MASTER_USER_ID
                                parentEntityMainIdColumn:COL_MAIN_USER_ID
                                                pageSize:@(1)
                                                whereBlk:whereBlk
                                               whereArgs:whereArgs
                                       entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                              addlJoinEntityMasterTables:nil
                          masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                         entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                                addlJoinEntityMainTables:nil
                            mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                       comparatorForSort:comparatorForSort
                                     orderByDomainColumn:orderByDomainColumn
                            orderByDomainColumnDirection:orderByDomainColumnDirection
                                                      db:db
                                                   error:errorBlk];

    if ([fplogs count] > 0) {
      fplog = fplogs[0];
    }
  }];
  return fplog;
}

- (FPFuelPurchaseLog *)singleGasLogForVehicle:(FPVehicle *)vehicle
                                     whereBlk:(NSString *(^)(NSString *))whereBlk
                                    whereArgs:(NSArray *)whereArgs
                            comparatorForSort:(NSComparisonResult(^)(id, id))comparatorForSort
                          orderByDomainColumn:(NSString *)orderByDomainColumn
                 orderByDomainColumnDirection:(NSString *)orderByDomainColumnDirection
                                        error:(PELMDaoErrorBlk)errorBlk {
  __block FPFuelPurchaseLog *fplog = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    NSArray *fplogs = [PELMUtils entitiesForParentEntity:vehicle
                                   parentEntityMainTable:TBL_MAIN_VEHICLE
                          addlJoinParentEntityMainTables:nil
                             parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                              parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                                parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                                pageSize:@(1)
                                                whereBlk:whereBlk
                                               whereArgs:whereArgs
                                       entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                              addlJoinEntityMasterTables:nil
                          masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                         entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                                addlJoinEntityMainTables:nil
                            mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                       comparatorForSort:comparatorForSort
                                     orderByDomainColumn:orderByDomainColumn
                            orderByDomainColumnDirection:orderByDomainColumnDirection
                                                      db:db
                                                   error:errorBlk];

    if ([fplogs count] > 0) {
      fplog = fplogs[0];
    }
  }];
  return fplog;
}

- (FPFuelPurchaseLog *)singleGasLogForFuelstation:(FPFuelStation *)fuelstation
                                         whereBlk:(NSString *(^)(NSString *))whereBlk
                                        whereArgs:(NSArray *)whereArgs
                                comparatorForSort:(NSComparisonResult(^)(id, id))comparatorForSort
                              orderByDomainColumn:(NSString *)orderByDomainColumn
                     orderByDomainColumnDirection:(NSString *)orderByDomainColumnDirection
                                            error:(PELMDaoErrorBlk)errorBlk {
  __block FPFuelPurchaseLog *fplog = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    NSArray *fplogs = [PELMUtils entitiesForParentEntity:fuelstation
                                   parentEntityMainTable:TBL_MAIN_FUEL_STATION
                          addlJoinParentEntityMainTables:_fuelstationTypeJoinTables
                             parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                              parentEntityMasterIdColumn:COL_MASTER_FUELSTATION_ID
                                parentEntityMainIdColumn:COL_MAIN_FUELSTATION_ID
                                                pageSize:@(1)
                                                whereBlk:whereBlk
                                               whereArgs:whereArgs
                                       entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                              addlJoinEntityMasterTables:nil
                          masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                         entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                                addlJoinEntityMainTables:nil
                            mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                       comparatorForSort:comparatorForSort
                                     orderByDomainColumn:orderByDomainColumn
                            orderByDomainColumnDirection:orderByDomainColumnDirection
                                                      db:db
                                                   error:errorBlk];

    if ([fplogs count] > 0) {
      fplog = fplogs[0];
    }
  }];
  return fplog;
}

- (NSString *(^)(NSString *))gasLogDateCompareWhereBlk:(NSString *)compareDirection {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ %@ ?", colPrefix, COL_FUELPL_PURCHASED_AT, compareDirection];
  };
}

- (NSString *(^)(NSString *))gasLogDateAndOctaneCompareWhereBlk:(NSString *)compareDirection {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ %@ ? and %@%@ = ?",
            colPrefix,
            COL_FUELPL_PURCHASED_AT,
            compareDirection,
            colPrefix,
            COL_FUELPL_OCTANE];
  };
}

- (NSString *(^)(NSString *))gasLogDateAndDieselCompareWhereBlk:(NSString *)compareDirection {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ %@ ? and %@%@ is null and %@%@ = 1",
            colPrefix,
            COL_FUELPL_PURCHASED_AT,
            compareDirection,
            colPrefix,
            COL_FUELPL_OCTANE,
            colPrefix,
            COL_FUELPL_IS_DIESEL];
  };
}

- (NSString *(^)(NSString *))gasLogDieselWhereBlk {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ is null AND %@%@ = 1",
            colPrefix,
            COL_FUELPL_OCTANE,
            colPrefix,
            COL_FUELPL_IS_DIESEL];
  };
}

- (FPFuelPurchaseLog *)firstGasLogForUser:(FPUser *)user
                                    error:(PELMDaoErrorBlk)errorBlk {
  return [self singleGasLogForUser:user
                          whereBlk:nil
                         whereArgs:nil
                 comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 purchasedAt] compare:[(FPFuelPurchaseLog *)o2 purchasedAt]];}
               orderByDomainColumn:COL_FUELPL_PURCHASED_AT
      orderByDomainColumnDirection:@"ASC"
                             error:errorBlk];
}

- (FPFuelPurchaseLog *)firstGasLogForUser:(FPUser *)user
                                   octane:(NSNumber *)octane
                                    error:(PELMDaoErrorBlk)errorBlk {
  return [self singleGasLogForUser:user
                          whereBlk:[self fpLogOctaneWhereBlk]
                         whereArgs:@[octane]
                 comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 purchasedAt] compare:[(FPFuelPurchaseLog *)o2 purchasedAt]];}
               orderByDomainColumn:COL_FUELPL_PURCHASED_AT
      orderByDomainColumnDirection:@"ASC"
                             error:errorBlk];
}

- (FPFuelPurchaseLog *)firstDieselGasLogForUser:(FPUser *)user
                                          error:(PELMDaoErrorBlk)errorBlk {
  return [self singleGasLogForUser:user
                          whereBlk:[self gasLogDieselWhereBlk]
                         whereArgs:nil
                 comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 purchasedAt] compare:[(FPFuelPurchaseLog *)o2 purchasedAt]];}
               orderByDomainColumn:COL_FUELPL_PURCHASED_AT
      orderByDomainColumnDirection:@"ASC"
                             error:errorBlk];
}

- (FPFuelPurchaseLog *)firstGasLogForVehicle:(FPVehicle *)vehicle
                                       error:(PELMDaoErrorBlk)errorBlk {
  return [self singleGasLogForVehicle:vehicle
                             whereBlk:nil
                            whereArgs:nil
                    comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 purchasedAt] compare:[(FPFuelPurchaseLog *)o2 purchasedAt]];}
                  orderByDomainColumn:COL_FUELPL_PURCHASED_AT
         orderByDomainColumnDirection:@"ASC"
                                error:errorBlk];
}

- (FPFuelPurchaseLog *)firstGasLogForVehicle:(FPVehicle *)vehicle
                                      octane:(NSNumber *)octane
                                       error:(PELMDaoErrorBlk)errorBlk {
  return [self singleGasLogForVehicle:vehicle
                             whereBlk:[self fpLogOctaneWhereBlk]
                            whereArgs:@[octane]
                    comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 purchasedAt] compare:[(FPFuelPurchaseLog *)o2 purchasedAt]];}
                  orderByDomainColumn:COL_FUELPL_PURCHASED_AT
         orderByDomainColumnDirection:@"ASC"
                                error:errorBlk];
}

- (FPFuelPurchaseLog *)firstDieselGasLogForVehicle:(FPVehicle *)vehicle
                                             error:(PELMDaoErrorBlk)errorBlk {
  return [self singleGasLogForVehicle:vehicle
                             whereBlk:[self gasLogDieselWhereBlk]
                            whereArgs:nil
                    comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 purchasedAt] compare:[(FPFuelPurchaseLog *)o2 purchasedAt]];}
                  orderByDomainColumn:COL_FUELPL_PURCHASED_AT
         orderByDomainColumnDirection:@"ASC"
                                error:errorBlk];
}

- (FPFuelPurchaseLog *)firstGasLogForVehicle:(FPVehicle *)vehicle
                                  beforeDate:(NSDate *)beforeDate
                               onOrAfterDate:(NSDate *)onOrAfterDate
                                       error:(PELMDaoErrorBlk)errorBlk {
  return [self singleGasLogForVehicle:vehicle
                             whereBlk:[self fpLogDateRangeWhereBlk]
                            whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                        [PEUtils millisecondsFromDate:onOrAfterDate]]
                    comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 purchasedAt] compare:[(FPFuelPurchaseLog *)o2 purchasedAt]];}
                  orderByDomainColumn:COL_FUELPL_PURCHASED_AT
         orderByDomainColumnDirection:@"ASC"
                                error:errorBlk];
}

- (FPFuelPurchaseLog *)firstGasLogForFuelstation:(FPFuelStation *)fuelstation
                                           error:(PELMDaoErrorBlk)errorBlk {
  return [self singleGasLogForFuelstation:fuelstation
                                 whereBlk:nil
                                whereArgs:nil
                        comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 purchasedAt] compare:[(FPFuelPurchaseLog *)o2 purchasedAt]];}
                      orderByDomainColumn:COL_FUELPL_PURCHASED_AT
             orderByDomainColumnDirection:@"ASC"
                                    error:errorBlk];
}

- (FPFuelPurchaseLog *)firstGasLogForFuelstation:(FPFuelStation *)fuelstation
                                          octane:(NSNumber *)octane
                                           error:(PELMDaoErrorBlk)errorBlk {
  return [self singleGasLogForFuelstation:fuelstation
                                 whereBlk:[self fpLogOctaneWhereBlk]
                                whereArgs:@[octane]
                        comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 purchasedAt] compare:[(FPFuelPurchaseLog *)o2 purchasedAt]];}
                      orderByDomainColumn:COL_FUELPL_PURCHASED_AT
             orderByDomainColumnDirection:@"ASC"
                                    error:errorBlk];
}

- (FPFuelPurchaseLog *)firstDieselGasLogForFuelstation:(FPFuelStation *)fuelstation
                                                 error:(PELMDaoErrorBlk)errorBlk {
  return [self singleGasLogForFuelstation:fuelstation
                                 whereBlk:[self gasLogDieselWhereBlk]
                                whereArgs:nil
                        comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 purchasedAt] compare:[(FPFuelPurchaseLog *)o2 purchasedAt]];}
                      orderByDomainColumn:COL_FUELPL_PURCHASED_AT
             orderByDomainColumnDirection:@"ASC"
                                    error:errorBlk];
}

- (FPFuelPurchaseLog *)lastGasLogForUser:(FPUser *)user
                                   error:(PELMDaoErrorBlk)errorBlk {
  return [self singleGasLogForUser:user
                          whereBlk:nil
                         whereArgs:nil
                 comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 purchasedAt] compare:[(FPFuelPurchaseLog *)o1 purchasedAt]];}
               orderByDomainColumn:COL_FUELPL_PURCHASED_AT
      orderByDomainColumnDirection:@"DESC"
                             error:errorBlk];
}

- (FPFuelPurchaseLog *)lastGasLogForUser:(FPUser *)user
                                  octane:(NSNumber *)octane
                                   error:(PELMDaoErrorBlk)errorBlk {
  return [self singleGasLogForUser:user
                          whereBlk:[self fpLogOctaneWhereBlk]
                         whereArgs:@[octane]
                 comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 purchasedAt] compare:[(FPFuelPurchaseLog *)o1 purchasedAt]];}
               orderByDomainColumn:COL_FUELPL_PURCHASED_AT
      orderByDomainColumnDirection:@"DESC"
                             error:errorBlk];
}

- (FPFuelPurchaseLog *)lastDieselGasLogForUser:(FPUser *)user
                                         error:(PELMDaoErrorBlk)errorBlk {
  return [self singleGasLogForUser:user
                          whereBlk:[self gasLogDieselWhereBlk]
                         whereArgs:nil
                 comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 purchasedAt] compare:[(FPFuelPurchaseLog *)o1 purchasedAt]];}
               orderByDomainColumn:COL_FUELPL_PURCHASED_AT
      orderByDomainColumnDirection:@"DESC"
                             error:errorBlk];
}

- (FPFuelPurchaseLog *)lastGasLogForVehicle:(FPVehicle *)vehicle
                                      error:(PELMDaoErrorBlk)errorBlk {
  return [self singleGasLogForVehicle:vehicle
                             whereBlk:nil
                            whereArgs:nil
                    comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 purchasedAt] compare:[(FPFuelPurchaseLog *)o1 purchasedAt]];}
                  orderByDomainColumn:COL_FUELPL_PURCHASED_AT
         orderByDomainColumnDirection:@"DESC"
                                error:errorBlk];
}

- (FPFuelPurchaseLog *)lastGasLogForVehicle:(FPVehicle *)vehicle
                                     octane:(NSNumber *)octane
                                      error:(PELMDaoErrorBlk)errorBlk {
  return [self singleGasLogForVehicle:vehicle
                             whereBlk:[self fpLogOctaneWhereBlk]
                            whereArgs:@[octane]
                    comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 purchasedAt] compare:[(FPFuelPurchaseLog *)o1 purchasedAt]];}
                  orderByDomainColumn:COL_FUELPL_PURCHASED_AT
         orderByDomainColumnDirection:@"DESC"
                                error:errorBlk];
}

- (FPFuelPurchaseLog *)lastDieselGasLogForVehicle:(FPVehicle *)vehicle
                                            error:(PELMDaoErrorBlk)errorBlk {
  return [self singleGasLogForVehicle:vehicle
                             whereBlk:[self gasLogDieselWhereBlk]
                            whereArgs:nil
                    comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 purchasedAt] compare:[(FPFuelPurchaseLog *)o1 purchasedAt]];}
                  orderByDomainColumn:COL_FUELPL_PURCHASED_AT
         orderByDomainColumnDirection:@"DESC"
                                error:errorBlk];
}

- (FPFuelPurchaseLog *)lastGasLogForVehicle:(FPVehicle *)vehicle
                                 beforeDate:(NSDate *)beforeDate
                              onOrAfterDate:(NSDate *)onOrAfterDate
                                      error:(PELMDaoErrorBlk)errorBlk {
  return [self singleGasLogForVehicle:vehicle
                             whereBlk:[self fpLogDateRangeWhereBlk]
                            whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                        [PEUtils millisecondsFromDate:onOrAfterDate]]
                    comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 purchasedAt] compare:[(FPFuelPurchaseLog *)o1 purchasedAt]];}
                  orderByDomainColumn:COL_FUELPL_PURCHASED_AT
         orderByDomainColumnDirection:@"DESC"
                                error:errorBlk];
}

- (FPFuelPurchaseLog *)lastGasLogForFuelstation:(FPFuelStation *)fuelstation
                                          error:(PELMDaoErrorBlk)errorBlk {
  return [self singleGasLogForFuelstation:fuelstation
                                 whereBlk:nil
                                whereArgs:nil
                        comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 purchasedAt] compare:[(FPFuelPurchaseLog *)o1 purchasedAt]];}
                      orderByDomainColumn:COL_FUELPL_PURCHASED_AT
             orderByDomainColumnDirection:@"DESC"
                                    error:errorBlk];
}

- (FPFuelPurchaseLog *)lastGasLogForFuelstation:(FPFuelStation *)fuelstation
                                         octane:(NSNumber *)octane
                                          error:(PELMDaoErrorBlk)errorBlk {
  return [self singleGasLogForFuelstation:fuelstation
                                 whereBlk:[self fpLogOctaneWhereBlk]
                                whereArgs:@[octane]
                        comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 purchasedAt] compare:[(FPFuelPurchaseLog *)o1 purchasedAt]];}
                      orderByDomainColumn:COL_FUELPL_PURCHASED_AT
             orderByDomainColumnDirection:@"DESC"
                                    error:errorBlk];
}

- (FPFuelPurchaseLog *)lastDieselGasLogForFuelstation:(FPFuelStation *)fuelstation
                                                error:(PELMDaoErrorBlk)errorBlk {
  return [self singleGasLogForFuelstation:fuelstation
                                 whereBlk:[self gasLogDieselWhereBlk]
                                whereArgs:nil
                        comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 purchasedAt] compare:[(FPFuelPurchaseLog *)o1 purchasedAt]];}
                      orderByDomainColumn:COL_FUELPL_PURCHASED_AT
             orderByDomainColumnDirection:@"DESC"
                                    error:errorBlk];
}

- (NSArray *)logNearestToDate:(NSDate *)date
                      forLog1:(id)log1
                     logdate1:(NSDate *)logdate1
                      forLog2:(id)log2
                     logdate2:(NSDate *)logdate2 {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  if (log1) {
    NSDateComponents *log1ComparisonComponents = [calendar components:NSCalendarUnitDay fromDate:logdate1 toDate:date options:0];
    NSInteger distanceOfLog1 = labs(log1ComparisonComponents.day);
    if (log2) {
      NSDateComponents *log2ComparisonComponents = [calendar components:NSCalendarUnitDay fromDate:date toDate:logdate2 options:0];
      NSInteger distanceOfLog2 = labs(log2ComparisonComponents.day);
      if (distanceOfLog2 < distanceOfLog1) {
        return @[log2, @(distanceOfLog2)];
      } else {
        return @[log1, @(distanceOfLog1)];
      }
    } else {
      return @[log1, @(distanceOfLog1)];
    }
  } else if (log2) {
    NSDateComponents *log2ComparisonComponents = [calendar components:NSCalendarUnitDay fromDate:date toDate:logdate2 options:0];
    NSInteger distanceOfLog2 = labs(log2ComparisonComponents.day);
    return @[log2, @(distanceOfLog2)];
  } else {
    return nil;
  }
}

- (NSArray *)gasLogNearestToDate:(NSDate *)date
                      forVehicle:(FPVehicle *)vehicle
                           error:(PELMDaoErrorBlk)errorBlk {
  FPFuelPurchaseLog *lessThanDateGasLog = [self singleGasLogForVehicle:vehicle
                                                              whereBlk:[self gasLogDateCompareWhereBlk:@"<="]
                                                             whereArgs:@[[PEUtils millisecondsFromDate:date]]
                                                     comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 purchasedAt] compare:[(FPFuelPurchaseLog *)o1 purchasedAt]];}
                                                   orderByDomainColumn:COL_FUELPL_PURCHASED_AT
                                          orderByDomainColumnDirection:@"DESC"
                                                                 error:errorBlk];
  FPFuelPurchaseLog *greaterThanDateGasLog = [self singleGasLogForVehicle:vehicle
                                                                 whereBlk:[self gasLogDateCompareWhereBlk:@">="]
                                                                whereArgs:@[[PEUtils millisecondsFromDate:date]]
                                                        comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 purchasedAt] compare:[(FPFuelPurchaseLog *)o2 purchasedAt]];}
                                                      orderByDomainColumn:COL_FUELPL_PURCHASED_AT
                                             orderByDomainColumnDirection:@"ASC"
                                                                    error:errorBlk];
  return [self logNearestToDate:date
                        forLog1:lessThanDateGasLog
                       logdate1:lessThanDateGasLog.purchasedAt
                        forLog2:greaterThanDateGasLog
                       logdate2:greaterThanDateGasLog.purchasedAt];
}

- (NSArray *)gasLogNearestToDate:(NSDate *)date
                         forUser:(FPUser *)user
                          octane:(NSNumber *)octane
                           error:(PELMDaoErrorBlk)errorBlk {
  FPFuelPurchaseLog *lessThanDateGasLog = [self singleGasLogForUser:user
                                                           whereBlk:[self gasLogDateAndOctaneCompareWhereBlk:@"<="]
                                                          whereArgs:@[[PEUtils millisecondsFromDate:date], octane]
                                                  comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 purchasedAt] compare:[(FPFuelPurchaseLog *)o1 purchasedAt]];}
                                                orderByDomainColumn:COL_FUELPL_PURCHASED_AT
                                       orderByDomainColumnDirection:@"DESC"
                                                              error:errorBlk];
  FPFuelPurchaseLog *greaterThanDateGasLog = [self singleGasLogForUser:user
                                                              whereBlk:[self gasLogDateAndOctaneCompareWhereBlk:@">="]
                                                             whereArgs:@[[PEUtils millisecondsFromDate:date], octane]
                                                     comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 purchasedAt] compare:[(FPFuelPurchaseLog *)o2 purchasedAt]];}
                                                   orderByDomainColumn:COL_FUELPL_PURCHASED_AT
                                          orderByDomainColumnDirection:@"ASC"
                                                                 error:errorBlk];
  return [self logNearestToDate:date
                        forLog1:lessThanDateGasLog
                       logdate1:lessThanDateGasLog.purchasedAt
                        forLog2:greaterThanDateGasLog
                       logdate2:greaterThanDateGasLog.purchasedAt];
}

- (NSArray *)dieselGasLogNearestToDate:(NSDate *)date
                               forUser:(FPUser *)user
                                 error:(PELMDaoErrorBlk)errorBlk {
  FPFuelPurchaseLog *lessThanDateGasLog = [self singleGasLogForUser:user
                                                           whereBlk:[self gasLogDateAndDieselCompareWhereBlk:@"<="]
                                                          whereArgs:@[[PEUtils millisecondsFromDate:date]]
                                                  comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 purchasedAt] compare:[(FPFuelPurchaseLog *)o1 purchasedAt]];}
                                                orderByDomainColumn:COL_FUELPL_PURCHASED_AT
                                       orderByDomainColumnDirection:@"DESC"
                                                              error:errorBlk];
  FPFuelPurchaseLog *greaterThanDateGasLog = [self singleGasLogForUser:user
                                                              whereBlk:[self gasLogDateAndDieselCompareWhereBlk:@">="]
                                                             whereArgs:@[[PEUtils millisecondsFromDate:date]]
                                                     comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 purchasedAt] compare:[(FPFuelPurchaseLog *)o2 purchasedAt]];}
                                                   orderByDomainColumn:COL_FUELPL_PURCHASED_AT
                                          orderByDomainColumnDirection:@"ASC"
                                                                 error:errorBlk];
  return [self logNearestToDate:date
                        forLog1:lessThanDateGasLog
                       logdate1:lessThanDateGasLog.purchasedAt
                        forLog2:greaterThanDateGasLog
                       logdate2:greaterThanDateGasLog.purchasedAt];
}

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForUser:(FPUser *)user
                                                 beforeDate:(NSDate *)beforeDate
                                              onOrAfterDate:(NSDate *)onOrAfterDate
                                                     octane:(NSNumber *)octane
                                                      error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForUser:user
                                              whereBlk:[self fpLogDateRangeOctaneNonNilGallonPriceWhereBlk]
                                             whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                         [PEUtils millisecondsFromDate:onOrAfterDate],
                                                         octane]
                                     comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 gallonPrice] compare:[(FPFuelPurchaseLog *)o1 gallonPrice]];}
                          orderByDomainColumnDirection:@"DESC"
                                                 error:errorBlk];
}

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForUser:(FPUser *)user
                                                 beforeDate:(NSDate *)beforeDate
                                              onOrAfterDate:(NSDate *)onOrAfterDate
                                                      error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForUser:user
                                              whereBlk:[self fpLogDateRangeNonNilGallonPriceWhereBlk]
                                             whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                         [PEUtils millisecondsFromDate:onOrAfterDate]]
                                     comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 gallonPrice] compare:[(FPFuelPurchaseLog *)o1 gallonPrice]];}
                          orderByDomainColumnDirection:@"DESC"
                                                 error:errorBlk];
}

- (FPFuelPurchaseLog *)maxGallonPriceDieselFuelPurchaseLogForUser:(FPUser *)user
                                                       beforeDate:(NSDate *)beforeDate
                                                    onOrAfterDate:(NSDate *)onOrAfterDate
                                                            error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForUser:user
                                              whereBlk:[self fpLogDateRangeDieselNonNilGallonPriceWhereBlk]
                                             whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                         [PEUtils millisecondsFromDate:onOrAfterDate]]
                                     comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 gallonPrice] compare:[(FPFuelPurchaseLog *)o1 gallonPrice]];}
                          orderByDomainColumnDirection:@"DESC"
                                                 error:errorBlk];
}

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForUser:(FPUser *)user
                                                 beforeDate:(NSDate *)beforeDate
                                              onOrAfterDate:(NSDate *)onOrAfterDate
                                                     octane:(NSNumber *)octane
                                                      error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForUser:user
                                              whereBlk:[self fpLogDateRangeOctaneNonNilGallonPriceWhereBlk]
                                             whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                         [PEUtils millisecondsFromDate:onOrAfterDate],
                                                         octane]
                                     comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 gallonPrice] compare:[(FPFuelPurchaseLog *)o2 gallonPrice]];}
                          orderByDomainColumnDirection:@"ASC"
                                                 error:errorBlk];
}

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForUser:(FPUser *)user
                                                 beforeDate:(NSDate *)beforeDate
                                              onOrAfterDate:(NSDate *)onOrAfterDate
                                                      error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForUser:user
                                              whereBlk:[self fpLogDateRangeNonNilGallonPriceWhereBlk]
                                             whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                         [PEUtils millisecondsFromDate:onOrAfterDate]]
                                     comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 gallonPrice] compare:[(FPFuelPurchaseLog *)o2 gallonPrice]];}
                          orderByDomainColumnDirection:@"ASC"
                                                 error:errorBlk];
}

- (FPFuelPurchaseLog *)minGallonPriceDieselFuelPurchaseLogForUser:(FPUser *)user
                                                       beforeDate:(NSDate *)beforeDate
                                                    onOrAfterDate:(NSDate *)onOrAfterDate
                                                            error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForUser:user
                                              whereBlk:[self fpLogDateRangeDieselNonNilGallonPriceWhereBlk]
                                             whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                         [PEUtils millisecondsFromDate:onOrAfterDate]]
                                     comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 gallonPrice] compare:[(FPFuelPurchaseLog *)o2 gallonPrice]];}
                          orderByDomainColumnDirection:@"ASC"
                                                 error:errorBlk];
}

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForUser:(FPUser *)user
                                                     octane:(NSNumber *)octane
                                                      error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForUser:user
                                              whereBlk:[self fpLogOctaneNonNilGallonPriceWhereBlk]
                                             whereArgs:@[octane]
                                     comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 gallonPrice] compare:[(FPFuelPurchaseLog *)o1 gallonPrice]];}
                          orderByDomainColumnDirection:@"DESC" error:errorBlk];
}

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForUser:(FPUser *)user
                                                      error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForUser:user
                                              whereBlk:[self fpLogNonNilGallonPriceWhereBlk]
                                             whereArgs:nil
                                     comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 gallonPrice] compare:[(FPFuelPurchaseLog *)o1 gallonPrice]];}
                          orderByDomainColumnDirection:@"DESC" error:errorBlk];
}

- (FPFuelPurchaseLog *)maxGallonPriceDieselFuelPurchaseLogForUser:(FPUser *)user
                                                            error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForUser:user
                                              whereBlk:[self fpLogDieselNonNilGallonPriceWhereBlk]
                                             whereArgs:nil
                                     comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 gallonPrice] compare:[(FPFuelPurchaseLog *)o1 gallonPrice]];}
                          orderByDomainColumnDirection:@"DESC" error:errorBlk];
}

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForUser:(FPUser *)user
                                                     octane:(NSNumber *)octane
                                                      error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForUser:user
                                              whereBlk:[self fpLogOctaneNonNilGallonPriceWhereBlk]
                                             whereArgs:@[octane]
                                     comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 gallonPrice] compare:[(FPFuelPurchaseLog *)o2 gallonPrice]];}
                          orderByDomainColumnDirection:@"ASC" error:errorBlk];
}

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForUser:(FPUser *)user
                                                      error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForUser:user
                                              whereBlk:[self fpLogNonNilGallonPriceWhereBlk]
                                             whereArgs:nil
                                     comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 gallonPrice] compare:[(FPFuelPurchaseLog *)o2 gallonPrice]];}
                          orderByDomainColumnDirection:@"ASC" error:errorBlk];
}

- (FPFuelPurchaseLog *)minGallonPriceDieselFuelPurchaseLogForUser:(FPUser *)user
                                                            error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxGallonPriceFuelPurchaseLogForUser:user
                                              whereBlk:[self fpLogDieselNonNilGallonPriceWhereBlk]
                                             whereArgs:nil
                                     comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o1 gallonPrice] compare:[(FPFuelPurchaseLog *)o2 gallonPrice]];}
                          orderByDomainColumnDirection:@"ASC" error:errorBlk];
}

- (FPFuelPurchaseLog *)masterFplogWithId:(NSNumber *)fplogId error:(PELMDaoErrorBlk)errorBlk {
  NSString *fplogTable = TBL_MASTER_FUELPURCHASE_LOG;
  __block FPFuelPurchaseLog *fplog = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplog = [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", fplogTable, COL_LOCAL_ID]
                           entityTable:fplogTable
                         localIdGetter:^NSNumber *(PELMModelSupport *entity) { return [entity localMasterIdentifier]; }
                             argsArray:@[fplogId]
                           rsConverter:^(FMResultSet *rs) { return [self masterFuelPurchaseLogFromResultSet:rs]; }
                                    db:db
                                 error:errorBlk];
    NSNumber *localMainId = [PELMUtils localMainIdentifierForEntity:fplog mainTable:TBL_MAIN_FUELPURCHASE_LOG db:db error:errorBlk];
    if (localMainId) {
      [fplog setLocalMainIdentifier:localMainId];
    }
  }];
  return fplog;
}

- (FPFuelPurchaseLog *)masterFplogWithGlobalId:(NSString *)globalId error:(PELMDaoErrorBlk)errorBlk {
  NSString *fplogTable = TBL_MASTER_FUELPURCHASE_LOG;
  __block FPFuelPurchaseLog *fplog = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fplog = [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", fplogTable, COL_GLOBAL_ID]
                           entityTable:fplogTable
                         localIdGetter:^NSNumber *(PELMModelSupport *entity) { return [entity localMasterIdentifier]; }
                             argsArray:@[globalId]
                           rsConverter:^(FMResultSet *rs) { return [self masterFuelPurchaseLogFromResultSet:rs]; }
                                    db:db
                                 error:errorBlk];
    NSNumber *localMainId = [PELMUtils localMainIdentifierForEntity:fplog mainTable:TBL_MAIN_FUELPURCHASE_LOG db:db error:errorBlk];
    if (localMainId) {
      [fplog setLocalMainIdentifier:localMainId];
    }
  }];
  return fplog;
}

- (void)deleteFuelPurchaseLog:(FPFuelPurchaseLog *)fplog
                        error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self deleteFuelPurchaseLog:fplog db:db error:errorBlk];
  }];
}

- (void)deleteFuelPurchaseLog:(FPFuelPurchaseLog *)fplog
                           db:(FMDatabase *)db
                        error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils deleteEntity:fplog
          entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
        entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                       db:db
                    error:errorBlk];
}

- (NSInteger)numFuelPurchaseLogsForUser:(FPUser *)user
                                  error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numEntities = 0;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    numEntities = [PELMUtils numEntitiesForParentEntity:user
                                  parentEntityMainTable:TBL_MAIN_USER
                         addlJoinParentEntityMainTables:nil
                            parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                             parentEntityMasterIdColumn:COL_MASTER_USER_ID
                               parentEntityMainIdColumn:COL_MAIN_USER_ID
                                      entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                             addlJoinEntityMasterTables:nil
                                        entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                               addlJoinEntityMainTables:nil
                                                     db:db
                                                  error:errorBlk];
  }];
  return numEntities;
}

- (NSInteger)numFuelPurchaseLogsForUser:(FPUser *)user
                              newerThan:(NSDate *)newerThan
                                  error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numEntities = 0;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    numEntities = [PELMUtils numEntitiesForParentEntity:user
                                  parentEntityMainTable:TBL_MAIN_USER
                         addlJoinParentEntityMainTables:nil
                            parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                             parentEntityMasterIdColumn:COL_MASTER_USER_ID
                               parentEntityMainIdColumn:COL_MAIN_USER_ID
                                      entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                             addlJoinEntityMasterTables:nil
                                        entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                               addlJoinEntityMainTables:nil
                                                  where:[NSString stringWithFormat:@"%@ > ?", COL_FUELPL_PURCHASED_AT]
                                               whereArg:@([newerThan timeIntervalSince1970] * 1000)
                                                     db:db
                                                  error:errorBlk];
  }];
  return numEntities;
}

- (NSArray *)fuelPurchaseLogsForUser:(FPUser *)user
                            pageSize:(NSInteger)pageSize
                               error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForUser:user
                              pageSize:pageSize
                      beforeDateLogged:nil
                                 error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForUser:(FPUser *)user
                            pageSize:(NSInteger)pageSize
                    beforeDateLogged:(NSDate *)beforeDateLogged
                               error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fpLogs = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fpLogs = [self fuelPurchaseLogsForUser:user
                                  pageSize:@(pageSize)
                          beforeDateLogged:beforeDateLogged
                                        db:db
                                     error:errorBlk];
  }];
  return fpLogs;
}

- (NSArray *)unsyncedFuelPurchaseLogsForUser:(FPUser *)user
                                       error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fpLogs = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fpLogs = [self unsyncedFuelPurchaseLogsForUser:user db:db error:errorBlk];
  }];
  return fpLogs;
}

- (NSArray *)unsyncedFuelPurchaseLogsForUser:(FPUser *)user
                                          db:(FMDatabase *)db
                                       error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils unsyncedEntitiesForParentEntity:user
                              parentEntityMainTable:TBL_MAIN_USER
                     addlJoinParentEntityMainTables:nil
                        parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                         parentEntityMasterIdColumn:COL_MASTER_USER_ID
                           parentEntityMainIdColumn:COL_MAIN_USER_ID
                                           pageSize:nil
                                  entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                         addlJoinEntityMasterTables:nil
                     masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                    entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                           addlJoinEntityMainTables:nil
                       mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                  comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 purchasedAt] compare:[(FPFuelPurchaseLog *)o1 purchasedAt]];}
                                orderByDomainColumn:COL_FUELPL_PURCHASED_AT
                       orderByDomainColumnDirection:@"DESC"
                                                 db:db
                                              error:errorBlk];
}

- (NSInteger)numFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                     error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numEntities = 0;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    numEntities = [PELMUtils numEntitiesForParentEntity:vehicle
                                  parentEntityMainTable:TBL_MAIN_VEHICLE
                         addlJoinParentEntityMainTables:nil
                            parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                             parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                               parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                      entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                             addlJoinEntityMasterTables:nil
                                        entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                               addlJoinEntityMainTables:nil
                                                     db:db
                                                  error:errorBlk];
  }];
  return numEntities;
}

- (NSInteger)numFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                 newerThan:(NSDate *)newerThan
                                     error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numEntities = 0;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    numEntities = [PELMUtils numEntitiesForParentEntity:vehicle
                                  parentEntityMainTable:TBL_MAIN_VEHICLE
                         addlJoinParentEntityMainTables:nil
                            parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                             parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                               parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                      entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                             addlJoinEntityMasterTables:nil
                                        entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                               addlJoinEntityMainTables:nil
                                                  where:[NSString stringWithFormat:@"%@ > ?", COL_FUELPL_PURCHASED_AT]
                                               whereArg:@([newerThan timeIntervalSince1970] * 1000)
                                                     db:db
                                                  error:errorBlk];
  }];
  return numEntities;
}

- (NSArray *)fuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                               pageSize:(NSInteger)pageSize
                                  error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForVehicle:vehicle
                                 pageSize:pageSize
                         beforeDateLogged:nil
                                    error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                               pageSize:(NSInteger)pageSize
                       beforeDateLogged:(NSDate *)beforeDateLogged
                                  error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fpLogs = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fpLogs = [self fuelPurchaseLogsForVehicle:vehicle
                                     pageSize:@(pageSize)
                             beforeDateLogged:beforeDateLogged
                                           db:db
                                        error:errorBlk];
  }];
  return fpLogs;
}

- (NSInteger)numFuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                         error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numEntities = 0;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    numEntities = [PELMUtils numEntitiesForParentEntity:fuelStation
                                  parentEntityMainTable:TBL_MAIN_FUEL_STATION
                         addlJoinParentEntityMainTables:_fuelstationTypeJoinTables
                            parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                             parentEntityMasterIdColumn:COL_MASTER_FUELSTATION_ID
                               parentEntityMainIdColumn:COL_MAIN_FUELSTATION_ID
                                      entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                             addlJoinEntityMasterTables:nil
                                        entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                               addlJoinEntityMainTables:nil
                                                     db:db
                                                  error:errorBlk];
  }];
  return numEntities;
}

- (NSInteger)numFuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                 newerThan:(NSDate *)newerThan
                                     error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numEntities = 0;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    numEntities = [PELMUtils numEntitiesForParentEntity:fuelStation
                                  parentEntityMainTable:TBL_MAIN_FUEL_STATION
                         addlJoinParentEntityMainTables:_fuelstationTypeJoinTables
                            parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                             parentEntityMasterIdColumn:COL_MASTER_FUELSTATION_ID
                               parentEntityMainIdColumn:COL_MAIN_FUELSTATION_ID
                                      entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                             addlJoinEntityMasterTables:nil
                                        entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                               addlJoinEntityMainTables:nil
                                                  where:[NSString stringWithFormat:@"%@ > ?", COL_FUELPL_PURCHASED_AT]
                                               whereArg:@([newerThan timeIntervalSince1970] * 1000)
                                                     db:db
                                                  error:errorBlk];
  }];
  return numEntities;
}

- (NSArray *)fuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                   pageSize:(NSInteger)pageSize
                                      error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForFuelStation:fuelStation
                                     pageSize:pageSize
                             beforeDateLogged:nil
                                        error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                   pageSize:(NSInteger)pageSize
                           beforeDateLogged:(NSDate *)beforeDateLogged
                                      error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fpLogs = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fpLogs = [self fuelPurchaseLogsForFuelStation:fuelStation
                                         pageSize:@(pageSize)
                                 beforeDateLogged:beforeDateLogged
                                               db:db
                                            error:errorBlk];
  }];
  return fpLogs;
}

- (NSArray *)fuelPurchaseLogsForUser:(FPUser *)user
                                  db:(FMDatabase *)db
                               error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForUser:user
                              pageSize:nil
                      beforeDateLogged:nil
                                    db:db
                                 error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForUser:(FPUser *)user
                            pageSize:(NSInteger)pageSize
                                  db:(FMDatabase *)db
                               error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForUser:user
                              pageSize:@(pageSize)
                      beforeDateLogged:nil
                                    db:db
                                 error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                               pageSize:(NSInteger)pageSize
                                     db:(FMDatabase *)db
                                  error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForVehicle:vehicle
                                 pageSize:@(pageSize)
                         beforeDateLogged:nil
                                       db:db
                                    error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                      db:(FMDatabase *)db
                                  error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForVehicle:vehicle
                                 pageSize:nil
                         beforeDateLogged:nil
                                       db:db
                                    error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                   pageSize:(NSInteger)pageSize
                                         db:(FMDatabase *)db
                                      error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForFuelStation:fuelStation
                                     pageSize:@(pageSize)
                             beforeDateLogged:nil
                                           db:db
                                        error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                         db:(FMDatabase *)db
                                      error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForFuelStation:fuelStation
                                     pageSize:nil
                             beforeDateLogged:nil
                                           db:db
                                        error:errorBlk];
}

- (FPFuelPurchaseLog *)mostRecentFuelPurchaseLogForUser:(FPUser *)user
                                                     db:(FMDatabase *)db
                                                  error:(PELMDaoErrorBlk)errorBlk {
  NSArray *fpLogs =
  [self fuelPurchaseLogsForUser:user pageSize:1 db:db error:errorBlk];
  if (fpLogs && ([fpLogs count] >= 1)) {
    return fpLogs[0];
  }
  return nil;
}

- (FPVehicle *)vehicleForFuelPurchaseLog:(FPFuelPurchaseLog *)fpLog
                                   error:(PELMDaoErrorBlk)errorBlk {
  __block FPVehicle *vehicle = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    vehicle = [self vehicleForFuelPurchaseLog:fpLog db:db error:errorBlk];
  }];
  return vehicle;
}

- (FPFuelStation *)fuelStationForFuelPurchaseLog:(FPFuelPurchaseLog *)fpLog
                                           error:(PELMDaoErrorBlk)errorBlk {
  __block FPFuelStation *fuelStation = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fuelStation = [self fuelStationForFuelPurchaseLog:fpLog db:db error:errorBlk];
  }];
  return fuelStation;
}

- (FPVehicle *)vehicleForFuelPurchaseLog:(FPFuelPurchaseLog *)fpLog
                                      db:(FMDatabase *)db
                                   error:(PELMDaoErrorBlk)errorBlk {
  return (FPVehicle *)[PELMUtils parentForChildEntity:fpLog
                                parentEntityMainTable:TBL_MAIN_VEHICLE
                       addlJoinParentEntityMainTables:nil
                              parentEntityMasterTable:TBL_MASTER_VEHICLE
                     addlJoinParentEntityMasterTables:nil
                             parentEntityMainFkColumn:COL_MAIN_VEHICLE_ID
                           parentEntityMasterFkColumn:COL_MASTER_VEHICLE_ID
                          parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                        parentEntityMasterRsConverter:^(FMResultSet *rs){return [self masterVehicleFromResultSet:rs];}
                                 childEntityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                        addlJoinChildEntityMainTables:nil
                           childEntityMainRsConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                               childEntityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                                                   db:db
                                                error:errorBlk];
}

- (FPFuelStation *)fuelStationForFuelPurchaseLog:(FPFuelPurchaseLog *)fpLog
                                              db:(FMDatabase *)db
                                           error:(PELMDaoErrorBlk)errorBlk {
  return (FPFuelStation *) [PELMUtils parentForChildEntity:fpLog
                                     parentEntityMainTable:TBL_MAIN_FUEL_STATION
                            addlJoinParentEntityMainTables:_fuelstationTypeJoinTables
                                   parentEntityMasterTable:TBL_MASTER_FUEL_STATION
                          addlJoinParentEntityMasterTables:_fuelstationTypeJoinTables
                                  parentEntityMainFkColumn:COL_MAIN_FUELSTATION_ID
                                parentEntityMasterFkColumn:COL_MASTER_FUELSTATION_ID
                               parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                             parentEntityMasterRsConverter:^(FMResultSet *rs){return [self masterFuelStationFromResultSet:rs];}
                                      childEntityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                             addlJoinChildEntityMainTables:nil
                                childEntityMainRsConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                    childEntityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                                                        db:db
                                                     error:errorBlk];
}

- (FPVehicle *)vehicleForMostRecentFuelPurchaseLogForUser:(FPUser *)user
                                                       db:(FMDatabase *)db
                                                    error:(PELMDaoErrorBlk)errorBlk {
  FPFuelPurchaseLog *mostRecentFpLog = [self mostRecentFuelPurchaseLogForUser:user db:db error:errorBlk];
  if (mostRecentFpLog) {
    return [self vehicleForFuelPurchaseLog:mostRecentFpLog db:db error:errorBlk];
  }
  return nil;
}

- (FPFuelStation *)fuelStationForMostRecentFuelPurchaseLogForUser:(FPUser *)user
                                                               db:(FMDatabase *)db
                                                            error:(PELMDaoErrorBlk)errorBlk {
  FPFuelPurchaseLog *mostRecentFpLog =
  [self mostRecentFuelPurchaseLogForUser:user db:db error:errorBlk];
  if (mostRecentFpLog) {
    return [self fuelStationForFuelPurchaseLog:mostRecentFpLog db:db error:errorBlk];
  }
  return nil;
}

- (FPVehicle *)masterVehicleForMasterFpLog:(FPFuelPurchaseLog *)fplog
                                     error:(PELMDaoErrorBlk)errorBlk {
  __block FPVehicle *vehicle = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    vehicle = [self masterVehicleForMasterFpLog:fplog db:db error:errorBlk];
  }];
  return vehicle;
}

- (FPVehicle *)masterVehicleForMasterFpLog:(FPFuelPurchaseLog *)fplog
                                        db:(FMDatabase *)db
                                     error:(PELMDaoErrorBlk)errorBlk {
  return (FPVehicle *) [PELMUtils masterParentForMasterChildEntity:fplog
                                           parentEntityMasterTable:TBL_MASTER_VEHICLE
                                  addlJoinParentEntityMasterTables:nil
                                        parentEntityMasterFkColumn:COL_MASTER_VEHICLE_ID
                                     parentEntityMasterRsConverter:^(FMResultSet *rs){return [self masterVehicleFromResultSet:rs];}
                                            childEntityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                                                                db:db
                                                             error:errorBlk];
}

- (FPFuelStation *)masterFuelstationForMasterFpLog:(FPFuelPurchaseLog *)fplog
                                             error:(PELMDaoErrorBlk)errorBlk {
  __block FPFuelStation *fuelstation = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    fuelstation = [self masterFuelstationForMasterFpLog:fplog db:db error:errorBlk];
  }];
  return fuelstation;
}

- (FPFuelStation *)masterFuelstationForMasterFpLog:(FPFuelPurchaseLog *)fplog
                                                db:(FMDatabase *)db
                                             error:(PELMDaoErrorBlk)errorBlk {
  return (FPFuelStation *)[PELMUtils masterParentForMasterChildEntity:fplog
                                              parentEntityMasterTable:TBL_MASTER_FUEL_STATION
                                     addlJoinParentEntityMasterTables:_fuelstationTypeJoinTables
                                           parentEntityMasterFkColumn:COL_MASTER_FUELSTATION_ID
                                        parentEntityMasterRsConverter:^(FMResultSet *rs){return [self masterFuelStationFromResultSet:rs];}
                                               childEntityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                                                                   db:db
                                                                error:errorBlk];
}

- (FPVehicle *)vehicleForMostRecentFuelPurchaseLogForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk {
  __block FPVehicle *vehicle = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    vehicle = [self vehicleForMostRecentFuelPurchaseLogForUser:user db:db error:errorBlk];
    if (!vehicle) {
      NSArray *vehicles = [self vehiclesForUser:user db:db error:errorBlk];
      if ([vehicles count] > 0) {
        vehicle = vehicles[0];
      }
    }
  }];
  return vehicle;
}

- (FPFuelStation *)defaultFuelStationForNewFuelPurchaseLogForUser:(FPUser *)user
                                                  currentLocation:(CLLocation *)currentLocation
                                                            error:(PELMDaoErrorBlk)errorBlk {
  __block FPFuelStation *fuelStation = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    FPFuelStation *(^fallbackIfNoLocation)(void) = ^ FPFuelStation * (void) {
      FPFuelStation *fs =
      [self fuelStationForMostRecentFuelPurchaseLogForUser:user db:db error:errorBlk];
      if (!fs) {
        NSArray *fuelStations =
        [self fuelStationsForUser:user db:db error:errorBlk];
        if ([fuelStations count] > 0) {
          fs = fuelStations[0];
        }
      }
      return fs;
    };
    if (currentLocation) {
      NSArray *fuelStations =
      [self fuelStationsWithNonNilLocationForUser:user db:db error:errorBlk];
      if (fuelStations && ([fuelStations count] > 0)) {
        fuelStation = fuelStations[0];
        CLLocationDistance closestDistance =
        [[fuelStation location] distanceFromLocation:currentLocation];
        for (FPFuelStation *loopfs in fuelStations) {
          CLLocationDistance distance =
          [[loopfs location] distanceFromLocation:currentLocation];
          if (distance < closestDistance) {
            closestDistance = distance;
            fuelStation = loopfs;
          }
        }
      }
    }
    if (!fuelStation) {
      fuelStation = fallbackIfNoLocation();
    }
  }];
  return fuelStation;
}

- (NSArray *)fuelPurchaseLogsForUser:(FPUser *)user
                            pageSize:(NSNumber *)pageSize
                    beforeDateLogged:(NSDate *)beforeDateLogged
                                  db:(FMDatabase *)db
                               error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForParentEntity:user
                         parentEntityMainTable:TBL_MAIN_USER
                   parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                    parentEntityMasterIdColumn:COL_MASTER_USER_ID
                      parentEntityMainIdColumn:COL_MAIN_USER_ID
                                      pageSize:pageSize
                              beforeDateLogged:beforeDateLogged
                                            db:db
                                         error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                               pageSize:(NSNumber *)pageSize
                       beforeDateLogged:(NSDate *)beforeDateLogged
                                     db:(FMDatabase *)db
                                  error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForParentEntity:vehicle
                         parentEntityMainTable:TBL_MAIN_VEHICLE
                   parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                    parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                      parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                      pageSize:pageSize
                              beforeDateLogged:beforeDateLogged
                                            db:db
                                         error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                   pageSize:(NSNumber *)pageSize
                           beforeDateLogged:(NSDate *)beforeDateLogged
                                         db:(FMDatabase *)db
                                      error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForParentEntity:fuelStation
                         parentEntityMainTable:TBL_MAIN_FUEL_STATION
                   parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                    parentEntityMasterIdColumn:COL_MASTER_FUELSTATION_ID
                      parentEntityMainIdColumn:COL_MAIN_FUELSTATION_ID
                                      pageSize:pageSize
                              beforeDateLogged:beforeDateLogged
                                            db:db
                                         error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForParentEntity:(PELMModelSupport *)parentEntity
                       parentEntityMainTable:(NSString *)parentEntityMainTable
                 parentEntityMainRsConverter:(PELMEntityFromResultSetBlk)parentEntityMainRsConverter
                  parentEntityMasterIdColumn:(NSString *)parentEntityMasterIdCol
                    parentEntityMainIdColumn:(NSString *)parentEntityMainIdCol
                                    pageSize:(NSNumber *)pageSize
                            beforeDateLogged:(NSDate *)beforeDateLogged
                                          db:(FMDatabase *)db
                                       error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesForParentEntity:parentEntity
                      parentEntityMainTable:parentEntityMainTable
             addlJoinParentEntityMainTables:nil
                parentEntityMainRsConverter:parentEntityMainRsConverter
                 parentEntityMasterIdColumn:parentEntityMasterIdCol
                   parentEntityMainIdColumn:parentEntityMainIdCol
                                   pageSize:pageSize
                          pageBoundaryWhere:[NSString stringWithFormat:@"%@ < ?", COL_FUELPL_PURCHASED_AT]
                            pageBoundaryArg:[PEUtils millisecondsFromDate:beforeDateLogged]
                          entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                 addlJoinEntityMasterTables:nil
             masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                            entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                   addlJoinEntityMainTables:nil
               mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                          comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 purchasedAt] compare:[(FPFuelPurchaseLog *)o1 purchasedAt]];}
                        orderByDomainColumn:COL_FUELPL_PURCHASED_AT
               orderByDomainColumnDirection:@"DESC"
                                         db:db
                                      error:errorBlk];
}

- (void)persistDeepFuelPurchaseLogFromRemoteMaster:(FPFuelPurchaseLog *)fuelPurchaseLog
                                           forUser:(FPUser *)user
                                             error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self persistDeepFuelPurchaseLogFromRemoteMaster:fuelPurchaseLog
                                             forUser:user
                                                  db:db
                                               error:errorBlk];
  }];
}

- (void)persistDeepFuelPurchaseLogFromRemoteMaster:(FPFuelPurchaseLog *)fuelPurchaseLog
                                           forUser:(FPUser *)user
                                                db:(FMDatabase *)db
                                             error:(PELMDaoErrorBlk)errorBlk {
  [self insertIntoMasterFuelPurchaseLog:fuelPurchaseLog
                                forUser:user
                                     db:db
                                  error:errorBlk];
  [PELMUtils insertRelations:[fuelPurchaseLog relations]
                   forEntity:fuelPurchaseLog
                 entityTable:TBL_MASTER_FUELPURCHASE_LOG
             localIdentifier:[fuelPurchaseLog localMasterIdentifier]
                          db:db
                       error:errorBlk];
}

- (void)saveNewFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                       forUser:(FPUser *)user
                       vehicle:vehicle
                   fuelStation:fuelStation
                         error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self saveNewFuelPurchaseLog:fuelPurchaseLog
                         forUser:user
                         vehicle:vehicle
                     fuelStation:fuelStation
                              db:db
                           error:errorBlk];
  }];
}

- (void)saveNewAndSyncImmediateFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                       forUser:(FPUser *)user
                                       vehicle:vehicle
                                   fuelStation:fuelStation
                                         error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [fuelPurchaseLog setSyncInProgress:YES];
    [self saveNewFuelPurchaseLog:fuelPurchaseLog
                         forUser:user
                         vehicle:vehicle
                     fuelStation:fuelStation
                              db:db
                           error:errorBlk];
  }];
}

- (void)saveNewFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                       forUser:(FPUser *)user
                       vehicle:(FPVehicle *)vehicle
                   fuelStation:(FPFuelStation *)fuelStation
                            db:(FMDatabase *)db
                         error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils copyMasterEntity:user
                  toMainTable:TBL_MAIN_USER
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainUser:(FPUser *)entity db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  [PELMUtils copyMasterEntity:vehicle
                  toMainTable:TBL_MAIN_VEHICLE
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainVehicle:(FPVehicle *)entity forUser:user db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  [PELMUtils copyMasterEntity:fuelStation
                  toMainTable:TBL_MAIN_FUEL_STATION
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainFuelStation:(FPFuelStation *)entity forUser:user db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  [fuelPurchaseLog setVehicleMainIdentifier:[vehicle localMainIdentifier]];
  [fuelPurchaseLog setFuelStationMainIdentifier:[fuelStation localMainIdentifier]];
  [fuelPurchaseLog setVehicleGlobalIdentifier:[vehicle globalIdentifier]];
  [fuelPurchaseLog setFuelStationGlobalIdentifier:[fuelStation globalIdentifier]];
  [fuelPurchaseLog setEditCount:1];
  [self insertIntoMainFuelPurchaseLog:fuelPurchaseLog
                              forUser:user
                              vehicle:vehicle
                          fuelStation:fuelStation
                                   db:db
                                error:errorBlk];
}

- (BOOL)prepareFuelPurchaseLogForEdit:(FPFuelPurchaseLog *)fuelPurchaseLog
                              forUser:(FPUser *)user
                                   db:(FMDatabase *)db
                                error:(PELMDaoErrorBlk)errorBlk {
  FPVehicle *vehicle = [self vehicleForFuelPurchaseLog:fuelPurchaseLog db:db error:errorBlk];
  FPFuelStation *fuelStation = [self fuelStationForFuelPurchaseLog:fuelPurchaseLog db:db error:errorBlk];
  [PELMUtils copyMasterEntity:user
                  toMainTable:TBL_MAIN_USER
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainUser:(FPUser *)entity db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  [PELMUtils copyMasterEntity:vehicle
                  toMainTable:TBL_MAIN_VEHICLE
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainVehicle:(FPVehicle *)entity forUser:user db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  [PELMUtils copyMasterEntity:fuelStation
                  toMainTable:TBL_MAIN_FUEL_STATION
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainFuelStation:(FPFuelStation *)entity forUser:user db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  [fuelPurchaseLog setVehicleGlobalIdentifier:[vehicle globalIdentifier]];
  [fuelPurchaseLog setVehicleMainIdentifier:[vehicle localMainIdentifier]];
  [fuelPurchaseLog setFuelStationGlobalIdentifier:[fuelStation globalIdentifier]];
  [fuelPurchaseLog setFuelStationMainIdentifier:[fuelStation localMainIdentifier]];
  return [PELMUtils prepareEntityForEdit:fuelPurchaseLog
                                      db:db
                               mainTable:TBL_MAIN_FUELPURCHASE_LOG
                addlJoinEntityMainTables:nil
                     entityFromResultSet:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                      mainEntityInserter:^(PELMMainSupport *entity, FMDatabase *db, PELMDaoErrorBlk errorBlk) {
                        [self insertIntoMainFuelPurchaseLog:fuelPurchaseLog
                                                    forUser:user
                                                    vehicle:vehicle
                                                fuelStation:fuelStation
                                                         db:db
                                                      error:errorBlk];}
                       mainEntityUpdater:^(PELMMainSupport *entity, FMDatabase *db, PELMDaoErrorBlk errorBlk) {
                         [PELMUtils doUpdate:[self updateStmtForMainFuelPurchaseLogSansVehicleFuelStationFks]
                                   argsArray:[self updateArgsForMainFuelPurchaseLog:fuelPurchaseLog]
                                          db:db
                                       error:errorBlk];}
                                   error:errorBlk];
}

- (BOOL)prepareFuelPurchaseLogForEdit:(FPFuelPurchaseLog *)fuelPurchaseLog
                              forUser:(FPUser *)user
                                error:(PELMDaoErrorBlk)errorBlk {
  __block BOOL returnVal;
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    returnVal = [self prepareFuelPurchaseLogForEdit:fuelPurchaseLog
                                            forUser:user
                                                 db:db
                                              error:errorBlk];
  }];
  return returnVal;
}

- (void)saveFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                    forUser:(FPUser *)user
                    vehicle:(FPVehicle *)vehicle
                fuelStation:(FPFuelStation *)fuelStation
                      error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils copyMasterEntity:user
                    toMainTable:TBL_MAIN_USER
           mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainUser:(FPUser *)entity db:db error:errorBlk];}
                             db:db
                          error:errorBlk];
    [PELMUtils copyMasterEntity:vehicle
                    toMainTable:TBL_MAIN_VEHICLE
           mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainVehicle:(FPVehicle *)entity forUser:user db:db error:errorBlk];}
                             db:db
                          error:errorBlk];
    [PELMUtils copyMasterEntity:fuelStation
                    toMainTable:TBL_MAIN_FUEL_STATION
           mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainFuelStation:(FPFuelStation *)entity forUser:user db:db error:errorBlk];}
                             db:db
                          error:errorBlk];
    [PELMUtils doUpdate:[self updateStmtForMainFuelPurchaseLog]
              argsArray:[self updateArgsForMainFuelPurchaseLog:fuelPurchaseLog vehicle:vehicle fuelStation:fuelStation]
                     db:db
                  error:errorBlk];
  }];
}

- (void)markAsDoneEditingFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                   error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils markAsDoneEditingEntity:fuelPurchaseLog
                                  mainTable:TBL_MAIN_FUELPURCHASE_LOG
                             mainUpdateStmt:[self updateStmtForMainFuelPurchaseLogSansVehicleFuelStationFks]
                          mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainFuelPurchaseLog:(FPFuelPurchaseLog *)entity];}
                                      error:errorBlk];
}

- (void)markAsDoneEditingImmediateSyncFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                                error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils markAsDoneEditingImmediateSyncEntity:fuelPurchaseLog
                                               mainTable:TBL_MAIN_FUELPURCHASE_LOG
                                          mainUpdateStmt:[self updateStmtForMainFuelPurchaseLogSansVehicleFuelStationFks]
                                       mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainFuelPurchaseLog:(FPFuelPurchaseLog *)entity];}
                                                   error:errorBlk];
}

- (void)reloadFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                        error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils reloadEntity:fuelPurchaseLog
                       fromMainTable:TBL_MAIN_FUELPURCHASE_LOG
                      addlJoinTables:nil
                         rsConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                               error:errorBlk];
}

- (void)cancelEditOfFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                              error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils cancelEditOfEntity:fuelPurchaseLog
                             mainTable:TBL_MAIN_FUELPURCHASE_LOG
                        mainUpdateStmt:[self updateStmtForMainFuelPurchaseLogSansVehicleFuelStationFks]
                     mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainFuelPurchaseLog:(FPFuelPurchaseLog *)entity];}
                           masterTable:TBL_MASTER_FUELPURCHASE_LOG
                           rsConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                 error:errorBlk];
}

- (NSArray *)markFuelPurchaseLogsAsSyncInProgressForUser:(FPUser *)user
                                                   error:(PELMDaoErrorBlk)errorBlk {
  return [self.localModelUtils markEntitiesAsSyncInProgressInMainTable:TBL_MAIN_FUELPURCHASE_LOG
                                              addlJoinEntityMainTables:nil
                                                   entityFromResultSet:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSetForSync:rs];}
                                                            updateStmt:[self updateStmtForMainFuelPurchaseLogSansVehicleFuelStationFks]
                                                         updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainFuelPurchaseLog:(FPFuelPurchaseLog *)entity];}
                                                                 error:errorBlk];
}

- (void)cancelSyncForFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                        httpRespCode:(NSNumber *)httpRespCode
                           errorMask:(NSNumber *)errorMask
                             retryAt:(NSDate *)retryAt
                               error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils cancelSyncForEntity:fuelPurchaseLog
                           httpRespCode:httpRespCode
                              errorMask:errorMask
                                retryAt:retryAt
                         mainUpdateStmt:[self updateStmtForMainFuelPurchaseLogSansVehicleFuelStationFks]
                      mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainFuelPurchaseLog:(FPFuelPurchaseLog *)entity];}
                                  error:errorBlk];
}

- (PELMSaveNewOrExistingCode)saveNewOrExistingMasterFuelPurchaseLog:(FPFuelPurchaseLog *)fplog
                                                            forUser:(FPUser *)user
                                                                 db:(FMDatabase *)db
                                                              error:(PELMDaoErrorBlk)errorBlk {
  FPVehicle *vehicle = [self masterVehicleWithGlobalId:fplog.vehicleGlobalIdentifier db:db error:errorBlk];
  FPFuelStation *fuelstation = [self masterFuelstationWithGlobalId:fplog.fuelStationGlobalIdentifier db:db error:errorBlk];
  return [PELMUtils saveNewOrExistingMasterEntity:fplog
                                      masterTable:TBL_MASTER_FUELPURCHASE_LOG
                                  masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterFuelPurchaseLog:(FPFuelPurchaseLog *)entity forUser:user db:db error:errorBlk];}
                                 masterUpdateStmt:[self updateStmtForMasterFuelPurchaseLog]
                              masterUpdateArgsBlk:^NSArray * (FPFuelPurchaseLog *theFplog) {return [self updateArgsForMasterFuelPurchaseLog:theFplog vehicle:vehicle fuelStation:fuelstation];}
                                        mainTable:TBL_MAIN_FUELPURCHASE_LOG
                          mainEntityFromResultSet:^FPFuelPurchaseLog * (FMResultSet *rs) {return [self mainFuelPurchaseLogFromResultSet:rs];}
                                   mainUpdateStmt:[self updateStmtForMainFuelPurchaseLog]
                                mainUpdateArgsBlk:^NSArray * (FPFuelPurchaseLog *theFplog) {return [self updateArgsForMainFuelPurchaseLog:theFplog vehicle:vehicle fuelStation:fuelstation];}
                                               db:db
                                            error:errorBlk];
}

- (BOOL)saveMasterFuelPurchaseLog:(FPFuelPurchaseLog *)fplog
                       forVehicle:(FPVehicle *)vehicle
                   forFuelstation:(FPFuelStation *)fuelstation
                          forUser:(FPUser *)user
                            error:(PELMDaoErrorBlk)errorBlk {
  return [self.localModelUtils saveMasterEntity:fplog
                                masterTable:TBL_MASTER_FUELPURCHASE_LOG
                           masterUpdateStmt:[self updateStmtForMasterFuelPurchaseLog]
                        masterUpdateArgsBlk:^ NSArray * (FPFuelPurchaseLog *theFplog) { return [self updateArgsForMasterFuelPurchaseLog:theFplog vehicle:vehicle fuelStation:fuelstation]; }
                                  mainTable:TBL_MAIN_FUELPURCHASE_LOG
                    mainEntityFromResultSet:^ FPFuelPurchaseLog * (FMResultSet *rs) { return [self mainFuelPurchaseLogFromResultSet:rs]; }
                             mainUpdateStmt:[self updateStmtForMainFuelPurchaseLog]
                          mainUpdateArgsBlk:^ NSArray * (FPFuelPurchaseLog *theFplog) { return [self updateArgsForMainFuelPurchaseLog:theFplog vehicle:vehicle fuelStation:fuelstation]; }
                                      error:errorBlk];
}

- (void)markAsSyncCompleteForNewFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                        forUser:(FPUser *)user
                                          error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils markAsSyncCompleteForNewEntity:fuelPurchaseLog
                                         mainTable:TBL_MAIN_FUELPURCHASE_LOG
                                       masterTable:TBL_MASTER_FUELPURCHASE_LOG
                                    mainUpdateStmt:[self updateStmtForMainFuelPurchaseLogSansVehicleFuelStationFks]
                                 mainUpdateArgsBlk:^(id entity){return [self updateArgsForMainFuelPurchaseLog:(FPFuelPurchaseLog *)entity];}
                                   masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterFuelPurchaseLog:(FPFuelPurchaseLog *)entity
                                                                                                              forUser:user
                                                                                                                   db:db
                                                                                                                error:errorBlk];}
                                             error:errorBlk];
}

- (void)markAsSyncCompleteForUpdatedFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                              error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    NSNumber *masterLocalIdentifier =
    [PELMUtils numberFromTable:TBL_MASTER_VEHICLE
                  selectColumn:COL_LOCAL_ID
                   whereColumn:COL_GLOBAL_ID
                    whereValue:[fuelPurchaseLog vehicleGlobalIdentifier]
                            db:db
                         error:errorBlk];
    FPVehicle *masterVehicle = [FPVehicle vehicleWithLocalMasterIdentifier:masterLocalIdentifier];
    masterLocalIdentifier =
    [PELMUtils numberFromTable:TBL_MASTER_FUEL_STATION
                  selectColumn:COL_LOCAL_ID
                   whereColumn:COL_GLOBAL_ID
                    whereValue:[fuelPurchaseLog fuelStationGlobalIdentifier]
                            db:db
                         error:errorBlk];
    FPFuelStation *masterFuelStation = [FPFuelStation fuelStationWithLocalMasterIdentifier:masterLocalIdentifier];
    [self.localModelUtils markAsSyncCompleteForUpdatedEntity:fuelPurchaseLog
                                               mainTable:TBL_MAIN_FUELPURCHASE_LOG
                                             masterTable:TBL_MASTER_FUELPURCHASE_LOG
                                          mainUpdateStmt:[self updateStmtForMainFuelPurchaseLogSansVehicleFuelStationFks]
                                       mainUpdateArgsBlk:^(id entity){return [self updateArgsForMainFuelPurchaseLog:(FPFuelPurchaseLog *)entity];}
                                        masterUpdateStmt:[self updateStmtForMasterFuelPurchaseLog]
                                     masterUpdateArgsBlk:^(id entity){return [self updateArgsForMasterFuelPurchaseLog:(FPFuelPurchaseLog *)entity
                                                                                                              vehicle:masterVehicle
                                                                                                          fuelStation:masterFuelStation];}
                                                      db:db
                                                   error:errorBlk];
  }];
}

#pragma mark - Environment Log

- (FPEnvironmentLog *)minMaxReportedMphOdometerLogForUser:(FPUser *)user
                                                 whereBlk:(NSString *(^)(NSString *))whereBlk
                                                whereArgs:(NSArray *)whereArgs
                                        comparatorForSort:(NSComparisonResult(^)(id, id))comparatorForSort
                             orderByDomainColumnDirection:(NSString *)orderByDomainColumnDirection
                                                    error:(PELMDaoErrorBlk)errorBlk {
  return [self singleOdometerLogForUser:user
                               whereBlk:whereBlk
                              whereArgs:whereArgs
                      comparatorForSort:comparatorForSort
                    orderByDomainColumn:COL_ENVL_MPH_READING
           orderByDomainColumnDirection:orderByDomainColumnDirection
                                  error:errorBlk];
}

- (FPEnvironmentLog *)minMaxReportedMphOdometerLogForVehicle:(FPVehicle *)vehicle
                                                    whereBlk:(NSString *(^)(NSString *))whereBlk
                                                   whereArgs:(NSArray *)whereArgs
                                           comparatorForSort:(NSComparisonResult(^)(id, id))comparatorForSort
                                orderByDomainColumnDirection:(NSString *)orderByDomainColumnDirection
                                                       error:(PELMDaoErrorBlk)errorBlk {
  return [self singleOdometerLogForVehicle:vehicle
                                  whereBlk:whereBlk
                                 whereArgs:whereArgs
                         comparatorForSort:comparatorForSort
                       orderByDomainColumn:COL_ENVL_MPH_READING
              orderByDomainColumnDirection:orderByDomainColumnDirection
                                     error:errorBlk];
}

- (NSString *(^)(NSString *))envlogDateRangeNonNilReportedMphWhereBlk {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ < ? AND %@%@ >= ? AND %@%@ is not null",
            colPrefix,
            COL_ENVL_LOG_DT,
            colPrefix,
            COL_ENVL_LOG_DT,
            colPrefix,
            COL_ENVL_MPH_READING];
  };
}

- (NSString *(^)(NSString *))envlogNonNilReportedMphWhereBlk {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ is not null",
            colPrefix,
            COL_ENVL_MPH_READING];
  };
}

- (FPEnvironmentLog *)maxReportedMphOdometerLogForUser:(FPUser *)user
                                            beforeDate:(NSDate *)beforeDate
                                         onOrAfterDate:(NSDate *)onOrAfterDate
                                                 error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxReportedMphOdometerLogForUser:user
                                          whereBlk:[self envlogDateRangeNonNilReportedMphWhereBlk]
                                         whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                     [PEUtils millisecondsFromDate:onOrAfterDate]]
                                 comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o2 reportedAvgMph] compare:[(FPEnvironmentLog *)o1 reportedAvgMph]];}
                      orderByDomainColumnDirection:@"DESC"
                                             error:errorBlk];
}

- (FPEnvironmentLog *)maxReportedMphOdometerLogForVehicle:(FPVehicle *)vehicle
                                               beforeDate:(NSDate *)beforeDate
                                            onOrAfterDate:(NSDate *)onOrAfterDate
                                                    error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxReportedMphOdometerLogForVehicle:vehicle
                                             whereBlk:[self envlogDateRangeNonNilReportedMphWhereBlk]
                                            whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                        [PEUtils millisecondsFromDate:onOrAfterDate]]
                                    comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o2 reportedAvgMph] compare:[(FPEnvironmentLog *)o1 reportedAvgMph]];}
                         orderByDomainColumnDirection:@"DESC"
                                                error:errorBlk];
}

- (FPEnvironmentLog *)minReportedMphOdometerLogForUser:(FPUser *)user
                                            beforeDate:(NSDate *)beforeDate
                                         onOrAfterDate:(NSDate *)onOrAfterDate
                                                 error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxReportedMphOdometerLogForUser:user
                                          whereBlk:[self envlogDateRangeNonNilReportedMphWhereBlk]
                                         whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                     [PEUtils millisecondsFromDate:onOrAfterDate]]
                                 comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o1 reportedAvgMph] compare:[(FPEnvironmentLog *)o2 reportedAvgMph]];}
                      orderByDomainColumnDirection:@"ASC"
                                             error:errorBlk];
}

- (FPEnvironmentLog *)minReportedMphOdometerLogForVehicle:(FPVehicle *)vehicle
                                               beforeDate:(NSDate *)beforeDate
                                            onOrAfterDate:(NSDate *)onOrAfterDate
                                                    error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxReportedMphOdometerLogForVehicle:vehicle
                                             whereBlk:[self envlogDateRangeNonNilReportedMphWhereBlk]
                                            whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                        [PEUtils millisecondsFromDate:onOrAfterDate]]
                                    comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o1 reportedAvgMph] compare:[(FPEnvironmentLog *)o2 reportedAvgMph]];}
                         orderByDomainColumnDirection:@"ASC"
                                                error:errorBlk];
}

- (FPEnvironmentLog *)maxReportedMphOdometerLogForUser:(FPUser *)user
                                                 error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxReportedMphOdometerLogForUser:user
                                          whereBlk:[self envlogNonNilReportedMphWhereBlk]
                                         whereArgs:nil
                                 comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o2 reportedAvgMph] compare:[(FPEnvironmentLog *)o1 reportedAvgMph]];}
                      orderByDomainColumnDirection:@"DESC" error:errorBlk];
}

- (FPEnvironmentLog *)maxReportedMphOdometerLogForVehicle:(FPVehicle *)vehicle
                                                    error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxReportedMphOdometerLogForVehicle:vehicle
                                             whereBlk:[self envlogNonNilReportedMphWhereBlk]
                                            whereArgs:nil
                                    comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o2 reportedAvgMph] compare:[(FPEnvironmentLog *)o1 reportedAvgMph]];}
                         orderByDomainColumnDirection:@"DESC" error:errorBlk];
}

- (FPEnvironmentLog *)minReportedMphOdometerLogForUser:(FPUser *)user
                                                 error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxReportedMphOdometerLogForUser:user
                                          whereBlk:[self envlogNonNilReportedMphWhereBlk]
                                         whereArgs:nil
                                 comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o1 reportedAvgMph] compare:[(FPEnvironmentLog *)o2 reportedAvgMph]];}
                      orderByDomainColumnDirection:@"ASC" error:errorBlk];
}

- (FPEnvironmentLog *)minReportedMphOdometerLogForVehicle:(FPVehicle *)vehicle
                                                    error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxReportedMphOdometerLogForVehicle:vehicle
                                             whereBlk:[self envlogNonNilReportedMphWhereBlk]
                                            whereArgs:nil
                                    comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o1 reportedAvgMph] compare:[(FPEnvironmentLog *)o2 reportedAvgMph]];}
                         orderByDomainColumnDirection:@"ASC" error:errorBlk];
}

- (FPEnvironmentLog *)minMaxReportedMpgOdometerLogForUser:(FPUser *)user
                                                 whereBlk:(NSString *(^)(NSString *))whereBlk
                                                whereArgs:(NSArray *)whereArgs
                                        comparatorForSort:(NSComparisonResult(^)(id, id))comparatorForSort
                             orderByDomainColumnDirection:(NSString *)orderByDomainColumnDirection
                                                    error:(PELMDaoErrorBlk)errorBlk {
  return [self singleOdometerLogForUser:user
                               whereBlk:whereBlk
                              whereArgs:whereArgs
                      comparatorForSort:comparatorForSort
                    orderByDomainColumn:COL_ENVL_MPG_READING
           orderByDomainColumnDirection:orderByDomainColumnDirection
                                  error:errorBlk];
}

- (FPEnvironmentLog *)minMaxReportedMpgOdometerLogForVehicle:(FPVehicle *)vehicle
                                                    whereBlk:(NSString *(^)(NSString *))whereBlk
                                                   whereArgs:(NSArray *)whereArgs
                                           comparatorForSort:(NSComparisonResult(^)(id, id))comparatorForSort
                                orderByDomainColumnDirection:(NSString *)orderByDomainColumnDirection
                                                       error:(PELMDaoErrorBlk)errorBlk {
  return [self singleOdometerLogForVehicle:vehicle
                                  whereBlk:whereBlk
                                 whereArgs:whereArgs
                         comparatorForSort:comparatorForSort
                       orderByDomainColumn:COL_ENVL_MPG_READING
              orderByDomainColumnDirection:orderByDomainColumnDirection
                                     error:errorBlk];
}

- (NSString *(^)(NSString *))envlogDateRangeNonNilReportedMpgWhereBlk {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ < ? AND %@%@ >= ? AND %@%@ is not null",
            colPrefix,
            COL_ENVL_LOG_DT,
            colPrefix,
            COL_ENVL_LOG_DT,
            colPrefix,
            COL_ENVL_MPG_READING];
  };
}

- (NSString *(^)(NSString *))envlogNonNilReportedMpgWhereBlk {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ is not null",
            colPrefix,
            COL_ENVL_MPG_READING];
  };
}

- (FPEnvironmentLog *)maxReportedMpgOdometerLogForUser:(FPUser *)user
                                            beforeDate:(NSDate *)beforeDate
                                         onOrAfterDate:(NSDate *)onOrAfterDate
                                                 error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxReportedMpgOdometerLogForUser:user
                                          whereBlk:[self envlogDateRangeNonNilReportedMpgWhereBlk]
                                         whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                     [PEUtils millisecondsFromDate:onOrAfterDate]]
                                 comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o2 reportedAvgMpg] compare:[(FPEnvironmentLog *)o1 reportedAvgMpg]];}
                      orderByDomainColumnDirection:@"DESC"
                                             error:errorBlk];
}

- (FPEnvironmentLog *)maxReportedMpgOdometerLogForVehicle:(FPVehicle *)vehicle
                                               beforeDate:(NSDate *)beforeDate
                                            onOrAfterDate:(NSDate *)onOrAfterDate
                                                    error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxReportedMpgOdometerLogForVehicle:vehicle
                                             whereBlk:[self envlogDateRangeNonNilReportedMpgWhereBlk]
                                            whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                        [PEUtils millisecondsFromDate:onOrAfterDate]]
                                    comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o2 reportedAvgMpg] compare:[(FPEnvironmentLog *)o1 reportedAvgMpg]];}
                         orderByDomainColumnDirection:@"DESC"
                                                error:errorBlk];
}

- (FPEnvironmentLog *)minReportedMpgOdometerLogForUser:(FPUser *)user
                                            beforeDate:(NSDate *)beforeDate
                                         onOrAfterDate:(NSDate *)onOrAfterDate
                                                 error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxReportedMpgOdometerLogForUser:user
                                          whereBlk:[self envlogDateRangeNonNilReportedMpgWhereBlk]
                                         whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                     [PEUtils millisecondsFromDate:onOrAfterDate]]
                                 comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o1 reportedAvgMpg] compare:[(FPEnvironmentLog *)o2 reportedAvgMpg]];}
                      orderByDomainColumnDirection:@"ASC"
                                             error:errorBlk];
}

- (FPEnvironmentLog *)minReportedMpgOdometerLogForVehicle:(FPVehicle *)vehicle
                                               beforeDate:(NSDate *)beforeDate
                                            onOrAfterDate:(NSDate *)onOrAfterDate
                                                    error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxReportedMpgOdometerLogForVehicle:vehicle
                                             whereBlk:[self envlogDateRangeNonNilReportedMpgWhereBlk]
                                            whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                        [PEUtils millisecondsFromDate:onOrAfterDate]]
                                    comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o1 reportedAvgMpg] compare:[(FPEnvironmentLog *)o2 reportedAvgMpg]];}
                         orderByDomainColumnDirection:@"ASC"
                                                error:errorBlk];
}

- (FPEnvironmentLog *)maxReportedMpgOdometerLogForUser:(FPUser *)user
                                                 error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxReportedMpgOdometerLogForUser:user
                                          whereBlk:[self envlogNonNilReportedMpgWhereBlk]
                                         whereArgs:nil
                                 comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o2 reportedAvgMpg] compare:[(FPEnvironmentLog *)o1 reportedAvgMpg]];}
                      orderByDomainColumnDirection:@"DESC" error:errorBlk];
}

- (FPEnvironmentLog *)maxReportedMpgOdometerLogForVehicle:(FPVehicle *)vehicle
                                                    error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxReportedMpgOdometerLogForVehicle:vehicle
                                             whereBlk:[self envlogNonNilReportedMpgWhereBlk]
                                            whereArgs:nil
                                    comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o2 reportedAvgMpg] compare:[(FPEnvironmentLog *)o1 reportedAvgMpg]];}
                         orderByDomainColumnDirection:@"DESC" error:errorBlk];
}

- (FPEnvironmentLog *)minReportedMpgOdometerLogForUser:(FPUser *)user
                                                 error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxReportedMpgOdometerLogForUser:user
                                          whereBlk:[self envlogNonNilReportedMpgWhereBlk]
                                         whereArgs:nil
                                 comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o1 reportedAvgMpg] compare:[(FPEnvironmentLog *)o2 reportedAvgMpg]];}
                      orderByDomainColumnDirection:@"ASC" error:errorBlk];
}

- (FPEnvironmentLog *)minReportedMpgOdometerLogForVehicle:(FPVehicle *)vehicle
                                                    error:(PELMDaoErrorBlk)errorBlk {
  return [self minMaxReportedMpgOdometerLogForVehicle:vehicle
                                             whereBlk:[self envlogNonNilReportedMpgWhereBlk]
                                            whereArgs:nil
                                    comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o1 reportedAvgMpg] compare:[(FPEnvironmentLog *)o2 reportedAvgMpg]];}
                         orderByDomainColumnDirection:@"ASC" error:errorBlk];
}

- (NSString *(^)(NSString *))envlogDateRangeWhereBlk {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ < ? AND %@%@ >= ?",
            colPrefix,
            COL_ENVL_LOG_DT,
            colPrefix,
            COL_ENVL_LOG_DT];
  };
}

- (NSString *(^)(NSString *))envlogStrictDateRangeWhereBlk {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ < ? AND %@%@ > ?",
            colPrefix,
            COL_ENVL_LOG_DT,
            colPrefix,
            COL_ENVL_LOG_DT];
  };
}

- (NSArray *)unorderedEnvironmentLogsForVehicle:(FPVehicle *)vehicle
                                          error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *envlogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    envlogs = [PELMUtils entitiesForParentEntity:vehicle
                           parentEntityMainTable:TBL_MAIN_VEHICLE
                  addlJoinParentEntityMainTables:nil
                     parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                      parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                        parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                        pageSize:nil
                                        whereBlk:nil
                                       whereArgs:nil
                               entityMasterTable:TBL_MASTER_ENV_LOG
                      addlJoinEntityMasterTables:nil
                  masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterEnvironmentLogFromResultSet:rs];}
                                 entityMainTable:TBL_MAIN_ENV_LOG
                        addlJoinEntityMainTables:nil
                    mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainEnvironmentLogFromResultSet:rs];}
                                              db:db
                                           error:errorBlk];
  }];
  return envlogs;
}

- (NSArray *)unorderedEnvironmentLogsForVehicle:(FPVehicle *)vehicle
                                     beforeDate:(NSDate *)beforeDate
                                  onOrAfterDate:(NSDate *)onOrAfterDate
                                          error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *envlogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    envlogs = [PELMUtils entitiesForParentEntity:vehicle
                           parentEntityMainTable:TBL_MAIN_VEHICLE
                  addlJoinParentEntityMainTables:nil
                     parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                      parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                        parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                        pageSize:nil
                                        whereBlk:[self envlogDateRangeWhereBlk]
                                       whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                   [PEUtils millisecondsFromDate:onOrAfterDate]]
                               entityMasterTable:TBL_MASTER_ENV_LOG
                      addlJoinEntityMasterTables:nil
                  masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterEnvironmentLogFromResultSet:rs];}
                                 entityMainTable:TBL_MAIN_ENV_LOG
                        addlJoinEntityMainTables:nil
                    mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainEnvironmentLogFromResultSet:rs];}
                                              db:db
                                           error:errorBlk];
  }];
  return envlogs;

}

- (NSArray *)unorderedEnvironmentLogsForVehicle:(FPVehicle *)vehicle
                                     beforeDate:(NSDate *)beforeDate
                                      afterDate:(NSDate *)afterDate
                                          error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *envlogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    envlogs = [PELMUtils entitiesForParentEntity:vehicle
                           parentEntityMainTable:TBL_MAIN_VEHICLE
                  addlJoinParentEntityMainTables:nil
                     parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                      parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                        parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                        pageSize:nil
                                        whereBlk:[self envlogStrictDateRangeWhereBlk]
                                       whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                   [PEUtils millisecondsFromDate:afterDate]]
                               entityMasterTable:TBL_MASTER_ENV_LOG
                      addlJoinEntityMasterTables:nil
                  masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterEnvironmentLogFromResultSet:rs];}
                                 entityMainTable:TBL_MAIN_ENV_LOG
                        addlJoinEntityMainTables:nil
                    mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainEnvironmentLogFromResultSet:rs];}
                                              db:db
                                           error:errorBlk];
  }];
  return envlogs;
}

- (NSArray *)unorderedEnvironmentLogsForUser:(FPUser *)user
                                       error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *envlogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    envlogs = [PELMUtils entitiesForParentEntity:user
                           parentEntityMainTable:TBL_MAIN_USER
                  addlJoinParentEntityMainTables:nil
                     parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                      parentEntityMasterIdColumn:COL_MASTER_USER_ID
                        parentEntityMainIdColumn:COL_MAIN_USER_ID
                                        pageSize:nil
                                        whereBlk:nil
                                       whereArgs:nil
                               entityMasterTable:TBL_MASTER_ENV_LOG
                      addlJoinEntityMasterTables:nil
                  masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterEnvironmentLogFromResultSet:rs];}
                                 entityMainTable:TBL_MAIN_ENV_LOG
                        addlJoinEntityMainTables:nil
                    mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainEnvironmentLogFromResultSet:rs];}
                                              db:db
                                           error:errorBlk];
  }];
  return envlogs;
}

- (NSArray *)unorderedEnvironmentLogsForUser:(FPUser *)user
                                  beforeDate:(NSDate *)beforeDate
                               onOrAfterDate:(NSDate *)onOrAfterDate
                                       error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *envlogs = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    envlogs = [PELMUtils entitiesForParentEntity:user
                           parentEntityMainTable:TBL_MAIN_USER
                  addlJoinParentEntityMainTables:nil
                     parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                      parentEntityMasterIdColumn:COL_MASTER_USER_ID
                        parentEntityMainIdColumn:COL_MAIN_USER_ID
                                        pageSize:nil
                                        whereBlk:[self envlogDateRangeWhereBlk]
                                       whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                                   [PEUtils millisecondsFromDate:onOrAfterDate]]
                               entityMasterTable:TBL_MASTER_ENV_LOG
                      addlJoinEntityMasterTables:nil
                  masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterEnvironmentLogFromResultSet:rs];}
                                 entityMainTable:TBL_MAIN_ENV_LOG
                        addlJoinEntityMainTables:nil
                    mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainEnvironmentLogFromResultSet:rs];}
                                              db:db
                                           error:errorBlk];
  }];
  return envlogs;
}

- (FPEnvironmentLog *)singleOdometerLogForUser:(FPUser *)user
                                      whereBlk:(NSString *(^)(NSString *))whereBlk
                                     whereArgs:(NSArray *)whereArgs
                             comparatorForSort:(NSComparisonResult(^)(id, id))comparatorForSort
                           orderByDomainColumn:(NSString *)orderByDomainColumn
                  orderByDomainColumnDirection:(NSString *)orderByDomainColumnDirection
                                         error:(PELMDaoErrorBlk)errorBlk {
  __block FPEnvironmentLog *envlog = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    NSArray *envlogs = [PELMUtils entitiesForParentEntity:user
                                    parentEntityMainTable:TBL_MAIN_USER
                           addlJoinParentEntityMainTables:nil
                              parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                               parentEntityMasterIdColumn:COL_MASTER_USER_ID
                                 parentEntityMainIdColumn:COL_MAIN_USER_ID
                                                 pageSize:@(1)
                                                 whereBlk:whereBlk
                                                whereArgs:whereArgs
                                        entityMasterTable:TBL_MASTER_ENV_LOG
                               addlJoinEntityMasterTables:nil
                           masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterEnvironmentLogFromResultSet:rs];}
                                          entityMainTable:TBL_MAIN_ENV_LOG
                                 addlJoinEntityMainTables:nil
                             mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainEnvironmentLogFromResultSet:rs];}
                                        comparatorForSort:comparatorForSort
                                      orderByDomainColumn:orderByDomainColumn
                             orderByDomainColumnDirection:orderByDomainColumnDirection
                                                       db:db
                                                    error:errorBlk];

    if ([envlogs count] > 0) {
      envlog = envlogs[0];
    }
  }];
  return envlog;
}

- (FPEnvironmentLog *)singleOdometerLogForVehicle:(FPVehicle *)vehicle
                                         whereBlk:(NSString *(^)(NSString *))whereBlk
                                        whereArgs:(NSArray *)whereArgs
                                comparatorForSort:(NSComparisonResult(^)(id, id))comparatorForSort
                              orderByDomainColumn:(NSString *)orderByDomainColumn
                     orderByDomainColumnDirection:(NSString *)orderByDomainColumnDirection
                                            error:(PELMDaoErrorBlk)errorBlk {
  __block FPEnvironmentLog *envlog = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    NSArray *envlogs = [PELMUtils entitiesForParentEntity:vehicle
                                    parentEntityMainTable:TBL_MAIN_VEHICLE
                           addlJoinParentEntityMainTables:nil
                              parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                               parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                                 parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                                 pageSize:@(1)
                                                 whereBlk:whereBlk
                                                whereArgs:whereArgs
                                        entityMasterTable:TBL_MASTER_ENV_LOG
                               addlJoinEntityMasterTables:nil
                           masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterEnvironmentLogFromResultSet:rs];}
                                          entityMainTable:TBL_MAIN_ENV_LOG
                                 addlJoinEntityMainTables:nil
                             mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainEnvironmentLogFromResultSet:rs];}
                                        comparatorForSort:comparatorForSort
                                      orderByDomainColumn:orderByDomainColumn
                             orderByDomainColumnDirection:orderByDomainColumnDirection
                                                       db:db
                                                    error:errorBlk];
    if ([envlogs count] > 0) {
      envlog = envlogs[0];
    }
  }];
  return envlog;
}

- (NSString *(^)(NSString *))odometerLogNonNilOdometerWhereBlk {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ is not null", colPrefix, COL_ENVL_ODOMETER_READING];
  };
}

- (NSString *(^)(NSString *))odometerLogDateRangeNonNilOdometerWhereBlk {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ < ? AND %@%@ >= ? AND %@%@ is not null",
            colPrefix,
            COL_ENVL_LOG_DT,
            colPrefix,
            COL_ENVL_LOG_DT,
            colPrefix,
            COL_ENVL_ODOMETER_READING];
  };
}

- (NSString *(^)(NSString *))odometerLogDateCompareNonNilOdometerWhereBlk:(NSString *)compareDirection {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ %@ ? AND %@%@ is not null",
            colPrefix,
            COL_ENVL_LOG_DT,
            compareDirection,
            colPrefix,
            COL_ENVL_ODOMETER_READING];
  };
}

- (NSString *(^)(NSString *))odometerLogDateCompareNonNilTemperatureWhereBlk:(NSString *)compareDirection {
  return ^(NSString *colPrefix) {
    return [NSString stringWithFormat:@"%@%@ %@ ? AND %@%@ is not null",
            colPrefix,
            COL_ENVL_LOG_DT,
            compareDirection,
            colPrefix,
            COL_ENVL_OUTSIDE_TEMP_READING];
  };
}

- (NSArray *)odometerLogNearestToDate:(NSDate *)date
                           forVehicle:(FPVehicle *)vehicle
                                error:(PELMDaoErrorBlk)errorBlk {
  FPEnvironmentLog *lessThanDateOdometerLog = [self singleOdometerLogForVehicle:vehicle
                                                                       whereBlk:[self odometerLogDateCompareNonNilOdometerWhereBlk:@"<="]
                                                                      whereArgs:@[[PEUtils millisecondsFromDate:date]]
                                                              comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o2 logDate] compare:[(FPEnvironmentLog *)o1 logDate]];}
                                                            orderByDomainColumn:COL_ENVL_LOG_DT
                                                   orderByDomainColumnDirection:@"DESC"
                                                                          error:errorBlk];
  FPEnvironmentLog *greaterThanDateOdometerLog = [self singleOdometerLogForVehicle:vehicle
                                                                          whereBlk:[self odometerLogDateCompareNonNilOdometerWhereBlk:@">="]
                                                                         whereArgs:@[[PEUtils millisecondsFromDate:date]]
                                                                 comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o1 logDate] compare:[(FPEnvironmentLog *)o2 logDate]];}
                                                               orderByDomainColumn:COL_ENVL_LOG_DT
                                                      orderByDomainColumnDirection:@"ASC"
                                                                             error:errorBlk];
  return [self logNearestToDate:date
                        forLog1:lessThanDateOdometerLog
                       logdate1:lessThanDateOdometerLog.logDate
                        forLog2:greaterThanDateOdometerLog
                       logdate2:greaterThanDateOdometerLog.logDate];
}

- (NSArray *)odometerLogNearestToDate:(NSDate *)date
                              forUser:(FPUser *)user
                                error:(PELMDaoErrorBlk)errorBlk {
  FPEnvironmentLog *lessThanDateOdometerLog = [self singleOdometerLogForUser:user
                                                                    whereBlk:[self odometerLogDateCompareNonNilOdometerWhereBlk:@"<="]
                                                                   whereArgs:@[[PEUtils millisecondsFromDate:date]]
                                                           comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o2 logDate] compare:[(FPEnvironmentLog *)o1 logDate]];}
                                                         orderByDomainColumn:COL_ENVL_LOG_DT
                                                orderByDomainColumnDirection:@"DESC"
                                                                       error:errorBlk];
  FPEnvironmentLog *greaterThanDateOdometerLog = [self singleOdometerLogForUser:user
                                                                       whereBlk:[self odometerLogDateCompareNonNilOdometerWhereBlk:@">="]
                                                                      whereArgs:@[[PEUtils millisecondsFromDate:date]]
                                                              comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o1 logDate] compare:[(FPEnvironmentLog *)o2 logDate]];}
                                                            orderByDomainColumn:COL_ENVL_LOG_DT
                                                   orderByDomainColumnDirection:@"ASC"
                                                                          error:errorBlk];
  return [self logNearestToDate:date
                        forLog1:lessThanDateOdometerLog
                       logdate1:lessThanDateOdometerLog.logDate
                        forLog2:greaterThanDateOdometerLog
                       logdate2:greaterThanDateOdometerLog.logDate];
}

- (NSArray *)odometerLogWithNonNilTemperatureNearestToDate:(NSDate *)date
                                                   forUser:(FPUser *)user
                                                     error:(PELMDaoErrorBlk)errorBlk {
  FPEnvironmentLog *lessThanDateOdometerLog = [self singleOdometerLogForUser:user
                                                                    whereBlk:[self odometerLogDateCompareNonNilTemperatureWhereBlk:@"<="]
                                                                   whereArgs:@[[PEUtils millisecondsFromDate:date]]
                                                           comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o2 logDate] compare:[(FPEnvironmentLog *)o1 logDate]];}
                                                         orderByDomainColumn:COL_ENVL_LOG_DT
                                                orderByDomainColumnDirection:@"DESC"
                                                                       error:errorBlk];
  FPEnvironmentLog *greaterThanDateOdometerLog = [self singleOdometerLogForUser:user
                                                                       whereBlk:[self odometerLogDateCompareNonNilTemperatureWhereBlk:@">="]
                                                                      whereArgs:@[[PEUtils millisecondsFromDate:date]]
                                                              comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o1 logDate] compare:[(FPEnvironmentLog *)o2 logDate]];}
                                                            orderByDomainColumn:COL_ENVL_LOG_DT
                                                   orderByDomainColumnDirection:@"ASC"
                                                                          error:errorBlk];
  return [self logNearestToDate:date
                        forLog1:lessThanDateOdometerLog
                       logdate1:lessThanDateOdometerLog.logDate
                        forLog2:greaterThanDateOdometerLog
                       logdate2:greaterThanDateOdometerLog.logDate];
}

- (FPEnvironmentLog *)firstOdometerLogForVehicle:(FPVehicle *)vehicle
                                      beforeDate:(NSDate *)beforeDate
                                   onOrAfterDate:(NSDate *)onOrAfterDate
                                           error:(PELMDaoErrorBlk)errorBlk {
  return [self singleOdometerLogForVehicle:vehicle
                                  whereBlk:[self odometerLogDateRangeNonNilOdometerWhereBlk]
                                 whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                             [PEUtils millisecondsFromDate:onOrAfterDate]]
                         comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o1 logDate] compare:[(FPEnvironmentLog *)o2 logDate]];}
                       orderByDomainColumn:COL_ENVL_LOG_DT
              orderByDomainColumnDirection:@"ASC"
                                     error:errorBlk];
}

- (FPEnvironmentLog *)lastOdometerLogForVehicle:(FPVehicle *)vehicle
                                     beforeDate:(NSDate *)beforeDate
                                  onOrAfterDate:(NSDate *)onOrAfterDate
                                          error:(PELMDaoErrorBlk)errorBlk {
  return [self singleOdometerLogForVehicle:vehicle
                                  whereBlk:[self odometerLogDateRangeNonNilOdometerWhereBlk]
                                 whereArgs:@[[PEUtils millisecondsFromDate:beforeDate],
                                             [PEUtils millisecondsFromDate:onOrAfterDate]]
                         comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o2 logDate] compare:[(FPEnvironmentLog *)o1 logDate]];}
                       orderByDomainColumn:COL_ENVL_LOG_DT
              orderByDomainColumnDirection:@"DESC"
                                     error:errorBlk];
}

- (FPEnvironmentLog *)firstOdometerLogForUser:(FPUser *)user
                                        error:(PELMDaoErrorBlk)errorBlk {
  return [self singleOdometerLogForUser:user
                               whereBlk:[self odometerLogNonNilOdometerWhereBlk]
                              whereArgs:nil
                      comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o1 logDate] compare:[(FPEnvironmentLog *)o2 logDate]];}
                    orderByDomainColumn:COL_ENVL_LOG_DT
           orderByDomainColumnDirection:@"ASC"
                                  error:errorBlk];
}

- (FPEnvironmentLog *)firstOdometerLogForVehicle:(FPVehicle *)vehicle
                                           error:(PELMDaoErrorBlk)errorBlk {
  return [self singleOdometerLogForVehicle:vehicle
                                  whereBlk:[self odometerLogNonNilOdometerWhereBlk]
                                 whereArgs:nil
                         comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o1 logDate] compare:[(FPEnvironmentLog *)o2 logDate]];}
                       orderByDomainColumn:COL_ENVL_LOG_DT
              orderByDomainColumnDirection:@"ASC"
                                     error:errorBlk];
}

- (FPEnvironmentLog *)lastOdometerLogForUser:(FPUser *)user
                                       error:(PELMDaoErrorBlk)errorBlk {
  return [self singleOdometerLogForUser:user
                               whereBlk:[self odometerLogNonNilOdometerWhereBlk]
                              whereArgs:nil
                      comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o2 logDate] compare:[(FPEnvironmentLog *)o1 logDate]];}
                    orderByDomainColumn:COL_ENVL_LOG_DT
           orderByDomainColumnDirection:@"DESC"
                                  error:errorBlk];
}

- (FPEnvironmentLog *)lastOdometerLogForVehicle:(FPVehicle *)vehicle
                                          error:(PELMDaoErrorBlk)errorBlk {
  return [self singleOdometerLogForVehicle:vehicle
                                  whereBlk:[self odometerLogNonNilOdometerWhereBlk]
                                 whereArgs:nil
                         comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o2 logDate] compare:[(FPEnvironmentLog *)o1 logDate]];}
                       orderByDomainColumn:COL_ENVL_LOG_DT
              orderByDomainColumnDirection:@"DESC"
                                     error:errorBlk];
}

- (FPEnvironmentLog *)masterEnvlogWithId:(NSNumber *)envlogId error:(PELMDaoErrorBlk)errorBlk {
  NSString *envlogTable = TBL_MASTER_ENV_LOG;
  __block FPEnvironmentLog *envlog = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    envlog = [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", envlogTable, COL_LOCAL_ID]
                            entityTable:envlogTable
                          localIdGetter:^NSNumber *(PELMModelSupport *entity) { return [entity localMasterIdentifier]; }
                              argsArray:@[envlogId]
                            rsConverter:^(FMResultSet *rs) { return [self masterEnvironmentLogFromResultSet:rs]; }
                                     db:db
                                  error:errorBlk];
    NSNumber *localMainId = [PELMUtils localMainIdentifierForEntity:envlog mainTable:TBL_MAIN_ENV_LOG db:db error:errorBlk];
    if (localMainId) {
      [envlog setLocalMainIdentifier:localMainId];
    }
  }];
  return envlog;
}

- (FPEnvironmentLog *)masterEnvlogWithGlobalId:(NSString *)globalId error:(PELMDaoErrorBlk)errorBlk {
  NSString *envlogTable = TBL_MASTER_ENV_LOG;
  __block FPEnvironmentLog *envlog = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    envlog = [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", envlogTable, COL_GLOBAL_ID]
                            entityTable:envlogTable
                          localIdGetter:^NSNumber *(PELMModelSupport *entity) { return [entity localMasterIdentifier]; }
                              argsArray:@[globalId]
                            rsConverter:^(FMResultSet *rs) { return [self masterEnvironmentLogFromResultSet:rs]; }
                                     db:db
                                  error:errorBlk];
    NSNumber *localMainId = [PELMUtils localMainIdentifierForEntity:envlog mainTable:TBL_MAIN_ENV_LOG db:db error:errorBlk];
    if (localMainId) {
      [envlog setLocalMainIdentifier:localMainId];
    }
  }];
  return envlog;
}

- (void)deleteEnvironmentLog:(FPEnvironmentLog *)envlog
                       error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self deleteEnvironmentLog:envlog db:db error:errorBlk];
  }];
}

- (void)deleteEnvironmentLog:(FPEnvironmentLog *)envlog
                          db:(FMDatabase *)db
                       error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils deleteEntity:envlog
          entityMainTable:TBL_MAIN_ENV_LOG
        entityMasterTable:TBL_MASTER_ENV_LOG
                       db:db
                    error:errorBlk];
}

- (NSInteger)numEnvironmentLogsForUser:(FPUser *)user
                                 error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numEntities = 0;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    numEntities = [PELMUtils numEntitiesForParentEntity:user
                                  parentEntityMainTable:TBL_MAIN_USER
                         addlJoinParentEntityMainTables:nil
                            parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                             parentEntityMasterIdColumn:COL_MASTER_USER_ID
                               parentEntityMainIdColumn:COL_MAIN_USER_ID
                                      entityMasterTable:TBL_MASTER_ENV_LOG
                             addlJoinEntityMasterTables:nil
                                        entityMainTable:TBL_MAIN_ENV_LOG
                               addlJoinEntityMainTables:nil
                                                     db:db
                                                  error:errorBlk];
  }];
  return numEntities;
}

- (NSInteger)numEnvironmentLogsForUser:(FPUser *)user
                             newerThan:(NSDate *)newerThan
                                 error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numEntities = 0;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    numEntities = [PELMUtils numEntitiesForParentEntity:user
                                  parentEntityMainTable:TBL_MAIN_USER
                         addlJoinParentEntityMainTables:nil
                            parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                             parentEntityMasterIdColumn:COL_MASTER_USER_ID
                               parentEntityMainIdColumn:COL_MAIN_USER_ID
                                      entityMasterTable:TBL_MASTER_ENV_LOG
                             addlJoinEntityMasterTables:nil
                                        entityMainTable:TBL_MAIN_ENV_LOG
                               addlJoinEntityMainTables:nil
                                                  where:[NSString stringWithFormat:@"%@ > ?", COL_ENVL_LOG_DT]
                                               whereArg:@([newerThan timeIntervalSince1970] * 1000)
                                                     db:db
                                                  error:errorBlk];
  }];
  return numEntities;
}

- (NSArray *)environmentLogsForUser:(FPUser *)user
                           pageSize:(NSInteger)pageSize
                              error:(PELMDaoErrorBlk)errorBlk {
  return [self environmentLogsForUser:user
                             pageSize:pageSize
                     beforeDateLogged:nil
                                error:errorBlk];
}

- (NSArray *)environmentLogsForUser:(FPUser *)user
                           pageSize:(NSInteger)pageSize
                   beforeDateLogged:(NSDate *)beforeDateLogged
                              error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *envLogs = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    envLogs = [self environmentLogsForUser:user
                                  pageSize:@(pageSize)
                          beforeDateLogged:beforeDateLogged
                                        db:db
                                     error:errorBlk];
  }];
  return envLogs;
}

- (NSArray *)unsyncedEnvironmentLogsForUser:(FPUser *)user
                                      error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *envLogs = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    envLogs = [self unsyncedEnvironmentLogsForUser:user db:db error:errorBlk];
  }];
  return envLogs;
}

- (NSArray *)unsyncedEnvironmentLogsForUser:(FPUser *)user
                                         db:(FMDatabase *)db
                                      error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils unsyncedEntitiesForParentEntity:user
                              parentEntityMainTable:TBL_MAIN_USER
                     addlJoinParentEntityMainTables:nil
                        parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                         parentEntityMasterIdColumn:COL_MASTER_USER_ID
                           parentEntityMainIdColumn:COL_MAIN_USER_ID
                                           pageSize:nil
                                  entityMasterTable:TBL_MASTER_ENV_LOG
                         addlJoinEntityMasterTables:nil
                     masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterEnvironmentLogFromResultSet:rs];}
                                    entityMainTable:TBL_MAIN_ENV_LOG
                           addlJoinEntityMainTables:nil
                       mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainEnvironmentLogFromResultSet:rs];}
                                  comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o2 logDate] compare:[(FPEnvironmentLog *)o1 logDate]];}
                                orderByDomainColumn:COL_ENVL_LOG_DT
                       orderByDomainColumnDirection:@"DESC"
                                                 db:db
                                              error:errorBlk];
}

- (NSInteger)numEnvironmentLogsForVehicle:(FPVehicle *)vehicle
                                    error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numEntities = 0;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    numEntities = [PELMUtils numEntitiesForParentEntity:vehicle
                                  parentEntityMainTable:TBL_MAIN_VEHICLE
                         addlJoinParentEntityMainTables:nil
                            parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                             parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                               parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                      entityMasterTable:TBL_MASTER_ENV_LOG
                             addlJoinEntityMasterTables:nil
                                        entityMainTable:TBL_MAIN_ENV_LOG
                               addlJoinEntityMainTables:nil
                                                     db:db
                                                  error:errorBlk];
  }];
  return numEntities;
}

- (NSInteger)numEnvironmentLogsForVehicle:(FPVehicle *)vehicle
                             newerThan:(NSDate *)newerThan
                                 error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numEntities = 0;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    numEntities = [PELMUtils numEntitiesForParentEntity:vehicle
                                  parentEntityMainTable:TBL_MAIN_VEHICLE
                         addlJoinParentEntityMainTables:nil
                            parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                             parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                               parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                      entityMasterTable:TBL_MASTER_ENV_LOG
                             addlJoinEntityMasterTables:nil
                                        entityMainTable:TBL_MAIN_ENV_LOG
                               addlJoinEntityMainTables:nil
                                                  where:[NSString stringWithFormat:@"%@ > ?", COL_ENVL_LOG_DT]
                                               whereArg:@([newerThan timeIntervalSince1970] * 1000)
                                                     db:db
                                                  error:errorBlk];
  }];
  return numEntities;
}

- (NSArray *)environmentLogsForVehicle:(FPVehicle *)vehicle
                              pageSize:(NSInteger)pageSize
                                 error:(PELMDaoErrorBlk)errorBlk {
  return [self environmentLogsForVehicle:vehicle
                                pageSize:pageSize
                        beforeDateLogged:nil
                                   error:errorBlk];
}

- (NSArray *)environmentLogsForVehicle:(FPVehicle *)vehicle
                              pageSize:(NSInteger)pageSize
                      beforeDateLogged:(NSDate *)beforeDateLogged
                                 error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *envLogs = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    envLogs = [self environmentLogsForVehicle:vehicle
                                     pageSize:@(pageSize)
                             beforeDateLogged:beforeDateLogged
                                           db:db
                                        error:errorBlk];
  }];
  return envLogs;
}

- (NSArray *)environmentLogsForUser:(FPUser *)user
                           pageSize:(NSInteger)pageSize
                                 db:(FMDatabase *)db
                              error:(PELMDaoErrorBlk)errorBlk {
  return [self environmentLogsForUser:user
                             pageSize:@(pageSize)
                     beforeDateLogged:nil
                                   db:db
                                error:errorBlk];
}

- (NSArray *)environmentLogsForVehicle:(FPVehicle *)vehicle
                              pageSize:(NSInteger)pageSize
                                    db:(FMDatabase *)db
                                 error:(PELMDaoErrorBlk)errorBlk {
  return [self environmentLogsForVehicle:vehicle
                                pageSize:@(pageSize)
                        beforeDateLogged:nil
                                      db:db
                                   error:errorBlk];
}

- (FPEnvironmentLog *)mostRecentEnvironmentLogForUser:(FPUser *)user
                                                   db:(FMDatabase *)db
                                                error:(PELMDaoErrorBlk)errorBlk {
  NSArray *envLogs =
  [self environmentLogsForUser:user pageSize:1 db:db error:errorBlk];
  if (envLogs && ([envLogs count] >= 1)) {
    return envLogs[0];
  }
  return nil;
}

- (FPVehicle *)masterVehicleForMasterEnvLog:(FPEnvironmentLog *)envlog
                                      error:(PELMDaoErrorBlk)errorBlk {
  __block FPVehicle *vehicle = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    vehicle = [self masterVehicleForMasterEnvLog:envlog db:db error:errorBlk];
  }];
  return vehicle;
}

- (FPVehicle *)masterVehicleForMasterEnvLog:(FPEnvironmentLog *)envlog
                                         db:(FMDatabase *)db
                                      error:(PELMDaoErrorBlk)errorBlk {
  return (FPVehicle *) [PELMUtils masterParentForMasterChildEntity:envlog
                                           parentEntityMasterTable:TBL_MASTER_VEHICLE
                                  addlJoinParentEntityMasterTables:nil
                                        parentEntityMasterFkColumn:COL_MASTER_VEHICLE_ID
                                     parentEntityMasterRsConverter:^(FMResultSet *rs){return [self masterVehicleFromResultSet:rs];}
                                            childEntityMasterTable:TBL_MASTER_ENV_LOG
                                                                db:db
                                                             error:errorBlk];
}

- (FPVehicle *)vehicleForEnvironmentLog:(FPEnvironmentLog *)envLog
                                  error:(PELMDaoErrorBlk)errorBlk {
  __block FPVehicle *vehicle = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    vehicle = [self vehicleForEnvironmentLog:envLog db:db error:errorBlk];
  }];
  return vehicle;
}

- (FPVehicle *)vehicleForEnvironmentLog:(FPEnvironmentLog *)envLog
                                     db:(FMDatabase *)db
                                  error:(PELMDaoErrorBlk)errorBlk {
  return (FPVehicle *) [PELMUtils parentForChildEntity:envLog
                                 parentEntityMainTable:TBL_MAIN_VEHICLE
                        addlJoinParentEntityMainTables:nil
                               parentEntityMasterTable:TBL_MASTER_VEHICLE
                      addlJoinParentEntityMasterTables:nil
                              parentEntityMainFkColumn:COL_MAIN_VEHICLE_ID
                            parentEntityMasterFkColumn:COL_MASTER_VEHICLE_ID
                           parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                         parentEntityMasterRsConverter:^(FMResultSet *rs){return [self masterVehicleFromResultSet:rs];}
                                  childEntityMainTable:TBL_MAIN_ENV_LOG
                         addlJoinChildEntityMainTables:nil
                            childEntityMainRsConverter:^(FMResultSet *rs){return [self mainEnvironmentLogFromResultSet:rs];}
                                childEntityMasterTable:TBL_MASTER_ENV_LOG
                                                    db:db
                                                 error:errorBlk];
}

- (FPVehicle *)vehicleForMostRecentEnvironmentLogForUser:(FPUser *)user
                                                      db:(FMDatabase *)db
                                                   error:(PELMDaoErrorBlk)errorBlk {
  FPEnvironmentLog *mostRecentFpLog =
  [self mostRecentEnvironmentLogForUser:user db:db error:errorBlk];
  if (mostRecentFpLog) {
    return [self vehicleForEnvironmentLog:mostRecentFpLog db:db error:errorBlk];
  }
  return nil;
}

- (FPVehicle *)defaultVehicleForNewEnvironmentLogForUser:(FPUser *)user
                                                   error:(PELMDaoErrorBlk)errorBlk {
  __block FPVehicle *vehicle = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    vehicle = [self vehicleForMostRecentEnvironmentLogForUser:user db:db error:errorBlk];
    if (!vehicle) {
      NSArray *vehicles = [self vehiclesForUser:user db:db error:errorBlk];
      if ([vehicles count] > 0) {
        vehicle = vehicles[0];
      }
    }
  }];
  return vehicle;
}

- (NSArray *)environmentLogsForUser:(FPUser *)user
                                 db:(FMDatabase *)db
                              error:(PELMDaoErrorBlk)errorBlk {
  return [self environmentLogsForUser:user
                             pageSize:nil
                     beforeDateLogged:nil
                                   db:db
                                error:errorBlk];
}

- (NSArray *)environmentLogsForUser:(FPUser *)user
                           pageSize:(NSNumber *)pageSize
                   beforeDateLogged:(NSDate *)beforeDateLogged
                                 db:(FMDatabase *)db
                              error:(PELMDaoErrorBlk)errorBlk {
  return [self environmentLogsForParentEntity:user
                        parentEntityMainTable:TBL_MAIN_USER
                  parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                   parentEntityMasterIdColumn:COL_MASTER_USER_ID
                     parentEntityMainIdColumn:COL_MAIN_USER_ID
                                     pageSize:pageSize
                             beforeDateLogged:beforeDateLogged
                                           db:db
                                        error:errorBlk];
}

- (NSArray *)environmentLogsForVehicle:(FPVehicle *)vehicle
                                    db:(FMDatabase *)db
                                 error:(PELMDaoErrorBlk)errorBlk {
  return [self environmentLogsForVehicle:vehicle
                                pageSize:nil
                        beforeDateLogged:nil
                                      db:db
                                   error:errorBlk];
}

- (NSArray *)environmentLogsForVehicle:(FPVehicle *)vehicle
                              pageSize:(NSNumber *)pageSize
                      beforeDateLogged:(NSDate *)beforeDateLogged
                                    db:(FMDatabase *)db
                                 error:(PELMDaoErrorBlk)errorBlk {
  return [self environmentLogsForParentEntity:vehicle
                        parentEntityMainTable:TBL_MAIN_VEHICLE
                  parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                   parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                     parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                     pageSize:pageSize
                             beforeDateLogged:beforeDateLogged
                                           db:db
                                        error:errorBlk];
}

- (NSArray *)environmentLogsForParentEntity:(PELMModelSupport *)parentEntity
                      parentEntityMainTable:(NSString *)parentEntityMainTable
                parentEntityMainRsConverter:(PELMEntityFromResultSetBlk)parentEntityMainRsConverter
                 parentEntityMasterIdColumn:(NSString *)parentEntityMasterIdCol
                   parentEntityMainIdColumn:(NSString *)parentEntityMainIdCol
                                   pageSize:(NSNumber *)pageSize
                           beforeDateLogged:(NSDate *)beforeDateLogged
                                         db:(FMDatabase *)db
                                      error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesForParentEntity:parentEntity
                      parentEntityMainTable:parentEntityMainTable
             addlJoinParentEntityMainTables:nil
                parentEntityMainRsConverter:parentEntityMainRsConverter
                 parentEntityMasterIdColumn:parentEntityMasterIdCol
                   parentEntityMainIdColumn:parentEntityMainIdCol
                                   pageSize:pageSize
                          pageBoundaryWhere:[NSString stringWithFormat:@"%@ < ?", COL_ENVL_LOG_DT]
                            pageBoundaryArg:[PEUtils millisecondsFromDate:beforeDateLogged]
                          entityMasterTable:TBL_MASTER_ENV_LOG
                 addlJoinEntityMasterTables:nil
             masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterEnvironmentLogFromResultSet:rs];}
                            entityMainTable:TBL_MAIN_ENV_LOG
                   addlJoinEntityMainTables:nil
               mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainEnvironmentLogFromResultSet:rs];}
                          comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o2 logDate] compare:[(FPEnvironmentLog *)o1 logDate]];}
                        orderByDomainColumn:COL_ENVL_LOG_DT
               orderByDomainColumnDirection:@"DESC"
                                         db:db
                                      error:errorBlk];
}

- (void)persistDeepEnvironmentLogFromRemoteMaster:(FPEnvironmentLog *)environmentLog
                                          forUser:(FPUser *)user
                                            error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self persistDeepEnvironmentLogFromRemoteMaster:environmentLog
                                            forUser:user
                                                 db:db
                                              error:errorBlk];
  }];
}

- (void)persistDeepEnvironmentLogFromRemoteMaster:(FPEnvironmentLog *)environmentLog
                                          forUser:(FPUser *)user
                                               db:(FMDatabase *)db
                                            error:(PELMDaoErrorBlk)errorBlk {
  [self insertIntoMasterEnvironmentLog:environmentLog
                               forUser:user
                                    db:db
                                 error:errorBlk];
  [PELMUtils insertRelations:[environmentLog relations]
                   forEntity:environmentLog
                 entityTable:TBL_MASTER_ENV_LOG
             localIdentifier:[environmentLog localMasterIdentifier]
                          db:db
                       error:errorBlk];
}

- (void)saveNewEnvironmentLog:(FPEnvironmentLog *)environmentLog
                      forUser:(FPUser *)user
                      vehicle:vehicle
                        error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self saveNewEnvironmentLog:environmentLog
                        forUser:user
                        vehicle:vehicle
                             db:db
                          error:errorBlk];
  }];
}

- (void)saveNewAndSyncImmediateEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                      forUser:(FPUser *)user
                                      vehicle:vehicle
                                        error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [environmentLog setSyncInProgress:YES];
    [self saveNewEnvironmentLog:environmentLog
                        forUser:user
                        vehicle:vehicle
                             db:db
                          error:errorBlk];
  }];
}

- (void)saveNewEnvironmentLog:(FPEnvironmentLog *)environmentLog
                      forUser:(FPUser *)user
                      vehicle:(FPVehicle *)vehicle
                           db:(FMDatabase *)db
                        error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils copyMasterEntity:user
                  toMainTable:TBL_MAIN_USER
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainUser:(FPUser *)entity db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  [PELMUtils copyMasterEntity:vehicle
                  toMainTable:TBL_MAIN_VEHICLE
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainVehicle:(FPVehicle *)entity forUser:user db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  [environmentLog setVehicleMainIdentifier:[vehicle localMainIdentifier]];
  [environmentLog setVehicleGlobalIdentifier:[vehicle globalIdentifier]];
  [environmentLog setEditCount:1];
  [self insertIntoMainEnvironmentLog:environmentLog
                             forUser:user
                             vehicle:vehicle
                                  db:db
                               error:errorBlk];
}

- (BOOL)prepareEnvironmentLogForEdit:(FPEnvironmentLog *)environmentLog
                             forUser:(FPUser *)user
                                  db:(FMDatabase *)db
                               error:(PELMDaoErrorBlk)errorBlk {
  FPVehicle *vehicle = [self vehicleForEnvironmentLog:environmentLog db:db error:errorBlk];
  [PELMUtils copyMasterEntity:user
                  toMainTable:TBL_MAIN_USER
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainUser:(FPUser *)entity db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  [PELMUtils copyMasterEntity:vehicle
                  toMainTable:TBL_MAIN_VEHICLE
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainVehicle:(FPVehicle *)entity forUser:user db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  [environmentLog setVehicleGlobalIdentifier:[vehicle globalIdentifier]];
  [environmentLog setVehicleMainIdentifier:[vehicle localMainIdentifier]];
  return [PELMUtils prepareEntityForEdit:environmentLog
                                      db:db
                               mainTable:TBL_MAIN_ENV_LOG
                addlJoinEntityMainTables:nil
                     entityFromResultSet:^(FMResultSet *rs){return [self mainEnvironmentLogFromResultSet:rs];}
                      mainEntityInserter:^(PELMMainSupport *entity, FMDatabase *db, PELMDaoErrorBlk errorBlk) {
                        [self insertIntoMainEnvironmentLog:environmentLog
                                                   forUser:user
                                                   vehicle:vehicle
                                                        db:db
                                                     error:errorBlk];}
                       mainEntityUpdater:^(PELMMainSupport *entity, FMDatabase *db, PELMDaoErrorBlk errorBlk) {
                         [PELMUtils doUpdate:[self updateStmtForMainEnvironmentLogSansVehicleFks]
                                   argsArray:[self updateArgsForMainEnvironmentLog:environmentLog]
                                          db:db
                                       error:errorBlk];}
                                   error:errorBlk];
}

- (BOOL)prepareEnvironmentLogForEdit:(FPEnvironmentLog *)environmentLog
                             forUser:(FPUser *)user
                               error:(PELMDaoErrorBlk)errorBlk {
  __block BOOL returnVal;
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    returnVal = [self prepareEnvironmentLogForEdit:environmentLog
                                           forUser:user
                                                db:db
                                             error:errorBlk];
  }];
  return returnVal;
}

- (void)saveEnvironmentLog:(FPEnvironmentLog *)environmentLog
                   forUser:(FPUser *)user
                   vehicle:(FPVehicle *)vehicle
                     error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils copyMasterEntity:user
                    toMainTable:TBL_MAIN_USER
           mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainUser:(FPUser *)entity db:db error:errorBlk];}
                             db:db
                          error:errorBlk];
    [PELMUtils copyMasterEntity:vehicle
                    toMainTable:TBL_MAIN_VEHICLE
           mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainVehicle:(FPVehicle *)entity forUser:user db:db error:errorBlk];}
                             db:db
                          error:errorBlk];
    [PELMUtils doUpdate:[self updateStmtForMainEnvironmentLog]
              argsArray:[self updateArgsForMainEnvironmentLog:environmentLog vehicle:vehicle]
                     db:db
                  error:errorBlk];
  }];
}

- (void)markAsDoneEditingEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                  error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils markAsDoneEditingEntity:environmentLog
                                  mainTable:TBL_MAIN_ENV_LOG
                             mainUpdateStmt:[self updateStmtForMainEnvironmentLogSansVehicleFks]
                          mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainEnvironmentLog:(FPEnvironmentLog *)entity];}
                                      error:errorBlk];
}

- (void)markAsDoneEditingImmediateSyncEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                               error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils markAsDoneEditingImmediateSyncEntity:environmentLog
                                               mainTable:TBL_MAIN_ENV_LOG
                                          mainUpdateStmt:[self updateStmtForMainEnvironmentLogSansVehicleFks]
                                       mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainEnvironmentLog:(FPEnvironmentLog *)entity];}
                                                   error:errorBlk];
}

- (void)reloadEnvironmentLog:(FPEnvironmentLog *)environmentLog
                       error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils reloadEntity:environmentLog
                       fromMainTable:TBL_MAIN_ENV_LOG
                      addlJoinTables:nil
                         rsConverter:^(FMResultSet *rs){return [self mainEnvironmentLogFromResultSet:rs];}
                               error:errorBlk];
}

- (void)cancelEditOfEnvironmentLog:(FPEnvironmentLog *)environmentLog
                             error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils cancelEditOfEntity:environmentLog
                             mainTable:TBL_MAIN_ENV_LOG
                        mainUpdateStmt:[self updateStmtForMainEnvironmentLogSansVehicleFks]
                     mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainEnvironmentLog:(FPEnvironmentLog *)entity];}
                           masterTable:TBL_MASTER_ENV_LOG
                           rsConverter:^(FMResultSet *rs){return [self masterEnvironmentLogFromResultSet:rs];}
                                 error:errorBlk];
}

- (NSArray *)markEnvironmentLogsAsSyncInProgressForUser:(FPUser *)user
                                                  error:(PELMDaoErrorBlk)errorBlk {
  return [self.localModelUtils markEntitiesAsSyncInProgressInMainTable:TBL_MAIN_ENV_LOG
                                              addlJoinEntityMainTables:nil
                                                   entityFromResultSet:^(FMResultSet *rs){return [self mainEnvironmentLogFromResultSet:rs];}
                                                            updateStmt:[self updateStmtForMainEnvironmentLogSansVehicleFks]
                                                         updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainEnvironmentLog:(FPEnvironmentLog *)entity];}
                                                                 error:errorBlk];
}

- (void)cancelSyncForEnvironmentLog:(FPEnvironmentLog *)environmentLog
                       httpRespCode:(NSNumber *)httpRespCode
                          errorMask:(NSNumber *)errorMask
                            retryAt:(NSDate *)retryAt
                              error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils cancelSyncForEntity:environmentLog
                           httpRespCode:httpRespCode
                              errorMask:errorMask
                                retryAt:retryAt
                         mainUpdateStmt:[self updateStmtForMainEnvironmentLogSansVehicleFks]
                      mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainEnvironmentLog:(FPEnvironmentLog *)entity];}
                                  error:errorBlk];
}

- (PELMSaveNewOrExistingCode)saveNewOrExistingMasterEnvironmentLog:(FPEnvironmentLog *)envlog
                                                           forUser:(FPUser *)user
                                                                db:(FMDatabase *)db
                                                             error:(PELMDaoErrorBlk)errorBlk {
  FPVehicle *vehicle = [self masterVehicleWithGlobalId:envlog.vehicleGlobalIdentifier db:db error:errorBlk];
  return [PELMUtils saveNewOrExistingMasterEntity:envlog
                                      masterTable:TBL_MASTER_ENV_LOG
                                  masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterEnvironmentLog:(FPEnvironmentLog *)entity forUser:user db:db error:errorBlk];}
                                 masterUpdateStmt:[self updateStmtForMasterEnvironmentLog]
                              masterUpdateArgsBlk:^NSArray * (FPEnvironmentLog *theEnvlog) {return [self updateArgsForMasterEnvironmentLog:theEnvlog vehicle:vehicle];}
                                        mainTable:TBL_MAIN_ENV_LOG
                          mainEntityFromResultSet:^FPEnvironmentLog * (FMResultSet *rs) {return [self mainEnvironmentLogFromResultSet:rs];}
                                   mainUpdateStmt:[self updateStmtForMainEnvironmentLog]
                                mainUpdateArgsBlk:^NSArray * (FPEnvironmentLog *theEnvlog) {return [self updateArgsForMainEnvironmentLog:theEnvlog vehicle:vehicle];}
                                               db:db
                                            error:errorBlk];
}

- (BOOL)saveMasterEnvironmentLog:(FPEnvironmentLog *)envlog
                      forVehicle:(FPVehicle *)vehicle
                         forUser:(FPUser *)user
                           error:(PELMDaoErrorBlk)errorBlk {
  return [self.localModelUtils saveMasterEntity:envlog
                                masterTable:TBL_MASTER_ENV_LOG
                           masterUpdateStmt:[self updateStmtForMasterEnvironmentLog]
                        masterUpdateArgsBlk:^ NSArray * (FPEnvironmentLog *theEnvlog) { return [self updateArgsForMasterEnvironmentLog:theEnvlog vehicle:vehicle]; }
                                  mainTable:TBL_MAIN_ENV_LOG
                    mainEntityFromResultSet:^ FPEnvironmentLog * (FMResultSet *rs) { return [self mainEnvironmentLogFromResultSet:rs]; }
                             mainUpdateStmt:[self updateStmtForMainEnvironmentLog]
                          mainUpdateArgsBlk:^ NSArray * (FPEnvironmentLog *theEnvlog) { return [self updateArgsForMainEnvironmentLog:theEnvlog vehicle:vehicle]; }
                                      error:errorBlk];
}

- (void)markAsSyncCompleteForNewEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                       forUser:(FPUser *)user
                                         error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils markAsSyncCompleteForNewEntity:environmentLog
                                         mainTable:TBL_MAIN_ENV_LOG
                                       masterTable:TBL_MASTER_ENV_LOG
                                    mainUpdateStmt:[self updateStmtForMainEnvironmentLogSansVehicleFks]
                                 mainUpdateArgsBlk:^(id entity){return [self updateArgsForMainEnvironmentLog:(FPEnvironmentLog *)entity];}
                                   masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterEnvironmentLog:(FPEnvironmentLog *)entity
                                                                                                             forUser:user
                                                                                                                  db:db
                                                                                                               error:errorBlk];}
                                             error:errorBlk];
}

- (void)markAsSyncCompleteForUpdatedEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                             error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    NSNumber *masterLocalIdentifier =
    [PELMUtils numberFromTable:TBL_MASTER_VEHICLE
                  selectColumn:COL_LOCAL_ID
                   whereColumn:COL_GLOBAL_ID
                    whereValue:[environmentLog vehicleGlobalIdentifier]
                            db:db
                         error:errorBlk];
    FPVehicle *masterVehicle = [FPVehicle vehicleWithLocalMasterIdentifier:masterLocalIdentifier];
    [self.localModelUtils markAsSyncCompleteForUpdatedEntity:environmentLog
                                               mainTable:TBL_MAIN_ENV_LOG
                                             masterTable:TBL_MASTER_ENV_LOG
                                          mainUpdateStmt:[self updateStmtForMainEnvironmentLogSansVehicleFks]
                                       mainUpdateArgsBlk:^(id entity){return [self updateArgsForMainEnvironmentLog:(FPEnvironmentLog *)entity];}
                                        masterUpdateStmt:[self updateStmtForMasterEnvironmentLog]
                                     masterUpdateArgsBlk:^(id entity){return [self updateArgsForMasterEnvironmentLog:(FPEnvironmentLog *)entity
                                                                                                             vehicle:masterVehicle];}
                                                      db:db
                                                   error:errorBlk];
  }];
}

#pragma mark - Result set -> Model helpers (private)

- (FPVehicle *)mainVehicleFromResultSet:(FMResultSet *)rs {
  return [[FPVehicle alloc] initWithLocalMainIdentifier:[rs objectForColumnName:COL_LOCAL_ID]
                                  localMasterIdentifier:nil // NA (this is a master store-only column)
                                       globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                              mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                              relations:nil
                                              createdAt:nil // NA (this is a master store-only column)
                                              deletedAt:nil // NA (this is a master store-only column)
                                              updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_MASTER_UPDATED_AT]
                                   dateCopiedFromMaster:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_DT_COPIED_DOWN_FROM_MASTER]
                                         editInProgress:[rs boolForColumn:COL_MAN_EDIT_IN_PROGRESS]
                                         syncInProgress:[rs boolForColumn:COL_MAN_SYNC_IN_PROGRESS]
                                                 synced:[rs boolForColumn:COL_MAN_SYNCED]
                                              editCount:[rs intForColumn:COL_MAN_EDIT_COUNT]
                                       syncHttpRespCode:[PELMUtils numberFromResultSet:rs columnName:COL_MAN_SYNC_HTTP_RESP_CODE]
                                            syncErrMask:[PELMUtils numberFromResultSet:rs columnName:COL_MAN_SYNC_ERR_MASK]
                                            syncRetryAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_SYNC_RETRY_AT]
                                                   name:[rs stringForColumn:COL_VEH_NAME]
                                          defaultOctane:[PELMUtils numberFromResultSet:rs columnName:COL_VEH_DEFAULT_OCTANE]
                                           fuelCapacity:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_VEH_FUEL_CAPACITY]
                                               isDiesel:[rs boolForColumn:COL_VEH_IS_DIESEL]
                                          hasDteReadout:[PELMUtils boolFromResultSet:rs columnName:COL_VEH_HAS_DTE_READOUT boolIfNull:YES]
                                          hasMpgReadout:[PELMUtils boolFromResultSet:rs columnName:COL_VEH_HAS_MPG_READOUT boolIfNull:YES]
                                          hasMphReadout:[PELMUtils boolFromResultSet:rs columnName:COL_VEH_HAS_MPH_READOUT boolIfNull:YES]
                                  hasOutsideTempReadout:[PELMUtils boolFromResultSet:rs columnName:COL_VEH_HAS_OUTSIDE_TEMP_READOUT boolIfNull:YES]
                                                    vin:[rs stringForColumn:COL_VEH_VIN]
                                                  plate:[rs stringForColumn:COL_VEH_PLATE]];
}

- (FPVehicle *)masterVehicleFromResultSet:(FMResultSet *)rs {
  return [[FPVehicle alloc] initWithLocalMainIdentifier:nil // NA (this is a main store-only column)
                                  localMasterIdentifier:[rs objectForColumnName:COL_LOCAL_ID]
                                       globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                              mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                              relations:nil
                                              createdAt:[PELMUtils dateFromResultSet:rs columnName:COL_MST_CREATED_AT]
                                              deletedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MST_DELETED_DT]
                                              updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MST_UPDATED_AT]
                                   dateCopiedFromMaster:nil // NA (this is a main store-only column)
                                         editInProgress:NO  // NA (this is a main store-only column)
                                         syncInProgress:NO  // NA (this is a main store-only column)
                                                 synced:NO  // NA (this is a main store-only column)
                                              editCount:0   // NA (this is a main store-only column)
                                       syncHttpRespCode:nil // NA (this is a main store-only column)
                                            syncErrMask:nil // NA (this is a main store-only column)
                                            syncRetryAt:nil // NA (this is a main store-only column)
                                                   name:[rs stringForColumn:COL_VEH_NAME]
                                          defaultOctane:[PELMUtils numberFromResultSet:rs columnName:COL_VEH_DEFAULT_OCTANE]
                                           fuelCapacity:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_VEH_FUEL_CAPACITY]
                                               isDiesel:[rs boolForColumn:COL_VEH_IS_DIESEL]
                                          hasDteReadout:[PELMUtils boolFromResultSet:rs columnName:COL_VEH_HAS_DTE_READOUT boolIfNull:YES]
                                          hasMpgReadout:[PELMUtils boolFromResultSet:rs columnName:COL_VEH_HAS_MPG_READOUT boolIfNull:YES]
                                          hasMphReadout:[PELMUtils boolFromResultSet:rs columnName:COL_VEH_HAS_MPH_READOUT boolIfNull:YES]
                                  hasOutsideTempReadout:[PELMUtils boolFromResultSet:rs columnName:COL_VEH_HAS_OUTSIDE_TEMP_READOUT boolIfNull:YES]
                                                    vin:[rs stringForColumn:COL_VEH_VIN]
                                                  plate:[rs stringForColumn:COL_VEH_PLATE]];
}

- (FPFuelStationType *)fuelStationTypeFromResultSet:(FMResultSet *)rs {
  return [[FPFuelStationType alloc] initWithIdentifier:[rs objectForColumnName:COL_FUELSTTYP_ID]
                                                  name:[rs stringForColumn:COL_FUELSTTYP_NAME]
                                           iconImgName:[rs stringForColumn:COL_FUELSTTYP_ICON_IMG_NAME]];
}

- (FPFuelStation *)mainFuelStationFromResultSet:(FMResultSet *)rs {
  return [[FPFuelStation alloc] initWithLocalMainIdentifier:[rs objectForColumnName:COL_LOCAL_ID]
                                      localMasterIdentifier:nil // NA (this is a master store-only column)
                                           globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                  mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                  relations:nil
                                                  createdAt:nil // NA (this is a master store-only column)
                                                  deletedAt:nil // NA (this is a master store-only column)
                                                  updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_MASTER_UPDATED_AT]
                                       dateCopiedFromMaster:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_DT_COPIED_DOWN_FROM_MASTER]
                                             editInProgress:[rs boolForColumn:COL_MAN_EDIT_IN_PROGRESS]
                                             syncInProgress:[rs boolForColumn:COL_MAN_SYNC_IN_PROGRESS]
                                                     synced:[rs boolForColumn:COL_MAN_SYNCED]
                                                  editCount:[rs intForColumn:COL_MAN_EDIT_COUNT]
                                           syncHttpRespCode:[PELMUtils numberFromResultSet:rs columnName:COL_MAN_SYNC_HTTP_RESP_CODE]
                                                syncErrMask:[PELMUtils numberFromResultSet:rs columnName:COL_MAN_SYNC_ERR_MASK]
                                                syncRetryAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_SYNC_RETRY_AT]
                                                       name:[rs stringForColumn:COL_FUELST_NAME]
                                                       type:[self fuelStationTypeFromResultSet:rs]
                                                     street:[rs stringForColumn:COL_FUELST_STREET]
                                                       city:[rs stringForColumn:COL_FUELST_CITY]
                                                      state:[rs stringForColumn:COL_FUELST_STATE]
                                                        zip:[rs stringForColumn:COL_FUELST_ZIP]
                                                   latitude:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELST_LATITUDE]
                                                  longitude:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELST_LONGITUDE]];
}

- (FPFuelStation *)masterFuelStationFromResultSet:(FMResultSet *)rs {
  return [[FPFuelStation alloc] initWithLocalMainIdentifier:nil // NA (this is a main store-only column)
                                      localMasterIdentifier:[rs objectForColumnName:COL_LOCAL_ID]
                                           globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                  mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                  relations:nil
                                                  createdAt:[PELMUtils dateFromResultSet:rs columnName:COL_MST_CREATED_AT]
                                                  deletedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MST_DELETED_DT]
                                                  updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MST_UPDATED_AT]
                                       dateCopiedFromMaster:nil // NA (this is a main store-only column)
                                             editInProgress:NO  // NA (this is a main store-only column)
                                             syncInProgress:NO  // NA (this is a main store-only column)
                                                     synced:NO  // NA (this is a main store-only column)
                                                  editCount:0   // NA (this is a main store-only column)
                                           syncHttpRespCode:nil // NA (this is a main store-only column)
                                                syncErrMask:nil // NA (this is a main store-only column)
                                                syncRetryAt:nil // NA (this is a main store-only column)
                                                       name:[rs stringForColumn:COL_FUELST_NAME]
                                                       type:[self fuelStationTypeFromResultSet:rs]
                                                     street:[rs stringForColumn:COL_FUELST_STREET]
                                                       city:[rs stringForColumn:COL_FUELST_CITY]
                                                      state:[rs stringForColumn:COL_FUELST_STATE]
                                                        zip:[rs stringForColumn:COL_FUELST_ZIP]
                                                   latitude:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELST_LATITUDE]
                                                  longitude:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELST_LONGITUDE]];
}

- (FPFuelPurchaseLog *)mainFuelPurchaseLogFromResultSetForSync:(FMResultSet *)rs {
  return [[FPFuelPurchaseLog alloc] initWithLocalMainIdentifier:[rs objectForColumnName:COL_LOCAL_ID]
                                          localMasterIdentifier:nil // NA (this is a master store-only column)
                                               globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                      mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                      relations:nil
                                                      createdAt:nil // NA (this is a master store-only column)
                                                      deletedAt:nil // NA (this is a master store-only column)
                                                      updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_MASTER_UPDATED_AT]
                                           dateCopiedFromMaster:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_DT_COPIED_DOWN_FROM_MASTER]
                                                 editInProgress:[rs boolForColumn:COL_MAN_EDIT_IN_PROGRESS]
                                                 syncInProgress:[rs boolForColumn:COL_MAN_SYNC_IN_PROGRESS]
                                                         synced:[rs boolForColumn:COL_MAN_SYNCED]
                                                      editCount:[rs intForColumn:COL_MAN_EDIT_COUNT]
                                               syncHttpRespCode:[PELMUtils numberFromResultSet:rs columnName:COL_MAN_SYNC_HTTP_RESP_CODE]
                                                    syncErrMask:[PELMUtils numberFromResultSet:rs columnName:COL_MAN_SYNC_ERR_MASK]
                                                    syncRetryAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_SYNC_RETRY_AT]
                                          vehicleMainIdentifier:[rs objectForColumnName:COL_MAIN_VEHICLE_ID]
                                      fuelStationMainIdentifier:[rs objectForColumnName:COL_MAIN_FUELSTATION_ID]
                                                     numGallons:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELPL_NUM_GALLONS]
                                                         octane:[PELMUtils numberFromResultSet:rs columnName:COL_FUELPL_OCTANE]
                                                       odometer:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELPL_ODOMETER]
                                                    gallonPrice:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELPL_PRICE_PER_GALLON]
                                                     gotCarWash:[rs boolForColumn:COL_FUELPL_GOT_CAR_WASH]
                                       carWashPerGallonDiscount:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELPL_CAR_WASH_PER_GALLON_DISCOUNT]
                                                    purchasedAt:[PELMUtils dateFromResultSet:rs columnName:COL_FUELPL_PURCHASED_AT]
                                                       isDiesel:[rs boolForColumn:COL_FUELPL_IS_DIESEL]];
}

- (FPFuelPurchaseLog *)mainFuelPurchaseLogFromResultSet:(FMResultSet *)rs {
  return [[FPFuelPurchaseLog alloc] initWithLocalMainIdentifier:[rs objectForColumnName:COL_LOCAL_ID]
                                          localMasterIdentifier:nil // NA (this is a master store-only column)
                                               globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                      mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                      relations:nil
                                                      createdAt:nil // NA (this is a master store-only column)
                                                      deletedAt:nil // NA (this is a master store-only column)
                                                      updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_MASTER_UPDATED_AT]
                                           dateCopiedFromMaster:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_DT_COPIED_DOWN_FROM_MASTER]
                                                 editInProgress:[rs boolForColumn:COL_MAN_EDIT_IN_PROGRESS]
                                                 syncInProgress:[rs boolForColumn:COL_MAN_SYNC_IN_PROGRESS]
                                                         synced:[rs boolForColumn:COL_MAN_SYNCED]
                                                      editCount:[rs intForColumn:COL_MAN_EDIT_COUNT]
                                               syncHttpRespCode:[PELMUtils numberFromResultSet:rs columnName:COL_MAN_SYNC_HTTP_RESP_CODE]
                                                    syncErrMask:[PELMUtils numberFromResultSet:rs columnName:COL_MAN_SYNC_ERR_MASK]
                                                    syncRetryAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_SYNC_RETRY_AT]
                                          vehicleMainIdentifier:nil
                                      fuelStationMainIdentifier:nil
                                                     numGallons:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELPL_NUM_GALLONS]
                                                         octane:[PELMUtils numberFromResultSet:rs columnName:COL_FUELPL_OCTANE]
                                                       odometer:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELPL_ODOMETER]
                                                    gallonPrice:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELPL_PRICE_PER_GALLON]
                                                     gotCarWash:[rs boolForColumn:COL_FUELPL_GOT_CAR_WASH]
                                       carWashPerGallonDiscount:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELPL_CAR_WASH_PER_GALLON_DISCOUNT]
                                                    purchasedAt:[PELMUtils dateFromResultSet:rs columnName:COL_FUELPL_PURCHASED_AT]
                                                       isDiesel:[rs boolForColumn:COL_FUELPL_IS_DIESEL]];
}

- (FPFuelPurchaseLog *)masterFuelPurchaseLogFromResultSet:(FMResultSet *)rs {
  return [[FPFuelPurchaseLog alloc] initWithLocalMainIdentifier:nil // NA (this is a main store-only column)
                                          localMasterIdentifier:[rs objectForColumnName:COL_LOCAL_ID]
                                               globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                      mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                      relations:nil
                                                      createdAt:[PELMUtils dateFromResultSet:rs columnName:COL_MST_CREATED_AT]
                                                      deletedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MST_DELETED_DT]
                                                      updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MST_UPDATED_AT]
                                           dateCopiedFromMaster:nil // NA (this is a main store-only column)
                                                 editInProgress:NO  // NA (this is a main store-only column)
                                                 syncInProgress:NO  // NA (this is a main store-only column)
                                                         synced:NO  // NA (this is a main store-only column)
                                                      editCount:0   // NA (this is a main store-only column)
                                               syncHttpRespCode:nil // NA (this is a main store-only column)
                                                    syncErrMask:nil // NA (this is a main store-only column)
                                                    syncRetryAt:nil // NA (this is a main store-only column)
                                          vehicleMainIdentifier:nil
                                      fuelStationMainIdentifier:nil
                                                     numGallons:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELPL_NUM_GALLONS]
                                                         octane:[PELMUtils numberFromResultSet:rs columnName:COL_FUELPL_OCTANE]
                                                       odometer:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELPL_ODOMETER]
                                                    gallonPrice:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELPL_PRICE_PER_GALLON]
                                                     gotCarWash:[rs boolForColumn:COL_FUELPL_GOT_CAR_WASH]
                                       carWashPerGallonDiscount:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELPL_CAR_WASH_PER_GALLON_DISCOUNT]
                                                    purchasedAt:[PELMUtils dateFromResultSet:rs columnName:COL_FUELPL_PURCHASED_AT]
                                                       isDiesel:[rs boolForColumn:COL_FUELPL_IS_DIESEL]];
}

- (FPEnvironmentLog *)mainEnvironmentLogFromResultSet:(FMResultSet *)rs {
  return [[FPEnvironmentLog alloc] initWithLocalMainIdentifier:[rs objectForColumnName:COL_LOCAL_ID]
                                         localMasterIdentifier:nil // NA (this is a master store-only column)
                                              globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                     mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                     relations:nil
                                                     createdAt:nil // NA (this is a master store-only column)
                                                     deletedAt:nil // NA (this is a master store-only column)
                                                     updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_MASTER_UPDATED_AT]
                                          dateCopiedFromMaster:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_DT_COPIED_DOWN_FROM_MASTER]
                                                editInProgress:[rs boolForColumn:COL_MAN_EDIT_IN_PROGRESS]
                                                syncInProgress:[rs boolForColumn:COL_MAN_SYNC_IN_PROGRESS]
                                                        synced:[rs boolForColumn:COL_MAN_SYNCED]
                                                     editCount:[rs intForColumn:COL_MAN_EDIT_COUNT]
                                              syncHttpRespCode:[PELMUtils numberFromResultSet:rs columnName:COL_MAN_SYNC_HTTP_RESP_CODE]
                                                   syncErrMask:[PELMUtils numberFromResultSet:rs columnName:COL_MAN_SYNC_ERR_MASK]
                                                   syncRetryAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_SYNC_RETRY_AT]
                                         vehicleMainIdentifier:[rs objectForColumnName:COL_MAIN_VEHICLE_ID]
                                                      odometer:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_ENVL_ODOMETER_READING]
                                                reportedAvgMpg:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_ENVL_MPG_READING]
                                                reportedAvgMph:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_ENVL_MPH_READING]
                                           reportedOutsideTemp:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_ENVL_OUTSIDE_TEMP_READING]
                                                       logDate:[PELMUtils dateFromResultSet:rs columnName:COL_ENVL_LOG_DT]
                                                   reportedDte:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_ENVL_DTE]];
}

- (FPEnvironmentLog *)masterEnvironmentLogFromResultSet:(FMResultSet *)rs {
  return [[FPEnvironmentLog alloc] initWithLocalMainIdentifier:nil // NA (this is a main store-only column)
                                         localMasterIdentifier:[rs objectForColumnName:COL_LOCAL_ID]
                                              globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                     mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                     relations:nil
                                                     createdAt:[PELMUtils dateFromResultSet:rs columnName:COL_MST_CREATED_AT]
                                                     deletedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MST_DELETED_DT]
                                                     updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MST_UPDATED_AT]
                                          dateCopiedFromMaster:nil // NA (this is a main store-only column)
                                                editInProgress:NO  // NA (this is a main store-only column)
                                                syncInProgress:NO  // NA (this is a main store-only column)
                                                        synced:NO  // NA (this is a main store-only column)
                                                     editCount:0   // NA (this is a main store-only column)
                                              syncHttpRespCode:nil // NA (this is a main store-only column)
                                                   syncErrMask:nil // NA (this is a main store-only column)
                                                   syncRetryAt:nil // NA (this is a main store-only column)
                                         vehicleMainIdentifier:nil
                                                      odometer:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_ENVL_ODOMETER_READING]
                                                reportedAvgMpg:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_ENVL_MPG_READING]
                                                reportedAvgMph:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_ENVL_MPH_READING]
                                           reportedOutsideTemp:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_ENVL_OUTSIDE_TEMP_READING]
                                                       logDate:[PELMUtils dateFromResultSet:rs columnName:COL_ENVL_LOG_DT]
                                                   reportedDte:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_ENVL_DTE]];
}

#pragma mark - Fuel Station data access helpers (private)

- (void)insertIntoMasterFuelStation:(FPFuelStation *)fuelStation
                            forUser:(FPUser *)user
                                 db:(FMDatabase *)db
                              error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@, \
%@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    TBL_MASTER_FUEL_STATION,
                    COL_MASTER_USER_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_MST_CREATED_AT,
                    COL_MST_UPDATED_AT,
                    COL_MST_DELETED_DT,
                    COL_FUELST_NAME,
                    COL_FUELST_TYPE_ID,
                    COL_FUELST_STREET,
                    COL_FUELST_CITY,
                    COL_FUELST_STATE,
                    COL_FUELST_ZIP,
                    COL_FUELST_LATITUDE,
                    COL_FUELST_LONGITUDE];
  [PELMUtils doMasterInsert:stmt
                  argsArray:@[PELMOrNil([user localMasterIdentifier]),
                              PELMOrNil([fuelStation globalIdentifier]),
                              PELMOrNil([[fuelStation mediaType] description]),
                              PELMOrNil([PEUtils millisecondsFromDate:[fuelStation createdAt]]),
                              PELMOrNil([PEUtils millisecondsFromDate:[fuelStation updatedAt]]),
                              PELMOrNil([PEUtils millisecondsFromDate:[fuelStation deletedAt]]),
                              PELMOrNil([fuelStation name]),
                              PELMOrNil([fuelStation type].identifier),
                              PELMOrNil([fuelStation street]),
                              PELMOrNil([fuelStation city]),
                              PELMOrNil([fuelStation state]),
                              PELMOrNil([fuelStation zip]),
                              PELMOrNil([fuelStation latitude]),
                              PELMOrNil([fuelStation longitude])]
                     entity:fuelStation
                         db:db
                      error:errorBlk];
}

- (void)insertIntoMainFuelStation:(FPFuelStation *)fuelStation
                          forUser:(FPUser *)user
                               db:(FMDatabase *)db
                            error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ \
                    (%@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@) VALUES \
                    (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    TBL_MAIN_FUEL_STATION,
                    COL_MAIN_USER_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_MAN_MASTER_UPDATED_AT,
                    COL_MAN_DT_COPIED_DOWN_FROM_MASTER,
                    COL_FUELST_NAME,
                    COL_FUELST_TYPE_ID,
                    COL_FUELST_STREET,
                    COL_FUELST_CITY,
                    COL_FUELST_STATE,
                    COL_FUELST_ZIP,
                    COL_FUELST_LATITUDE,
                    COL_FUELST_LONGITUDE,
                    COL_MAN_EDIT_IN_PROGRESS,
                    COL_MAN_SYNC_IN_PROGRESS,
                    COL_MAN_SYNCED,
                    COL_MAN_EDIT_COUNT,
                    COL_MAN_SYNC_HTTP_RESP_CODE,
                    COL_MAN_SYNC_ERR_MASK,
                    COL_MAN_SYNC_RETRY_AT];
  [PELMUtils doMainInsert:stmt
                argsArray:@[PELMOrNil([user localMainIdentifier]),
                            PELMOrNil([fuelStation globalIdentifier]),
                            PELMOrNil([[fuelStation mediaType] description]),
                            PELMOrNil([PEUtils millisecondsFromDate:[fuelStation updatedAt]]),
                            PELMOrNil([PEUtils millisecondsFromDate:[fuelStation dateCopiedFromMaster]]),
                            PELMOrNil([fuelStation name]),
                            PELMOrNil([fuelStation type].identifier),
                            PELMOrNil([fuelStation street]),
                            PELMOrNil([fuelStation city]),
                            PELMOrNil([fuelStation state]),
                            PELMOrNil([fuelStation zip]),
                            PELMOrNil([fuelStation latitude]),
                            PELMOrNil([fuelStation longitude]),
                            [NSNumber numberWithBool:[fuelStation editInProgress]],
                            [NSNumber numberWithBool:[fuelStation syncInProgress]],
                            [NSNumber numberWithBool:[fuelStation synced]],
                            [NSNumber numberWithInteger:[fuelStation editCount]],
                            PELMOrNil([fuelStation syncHttpRespCode]),
                            PELMOrNil([fuelStation syncErrMask]),
                            PELMOrNil([PEUtils millisecondsFromDate:[fuelStation syncRetryAt]])]
                   entity:fuelStation
                       db:db
                    error:errorBlk];
}

- (NSString *)updateStmtForMasterFuelStation {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MASTER_FUEL_STATION,// table
          COL_GLOBAL_ID,          // col1
          COL_MEDIA_TYPE,         // col2
          COL_MST_CREATED_AT,
          COL_MST_UPDATED_AT,  // col4
          COL_MST_DELETED_DT,     // col5
          COL_FUELST_NAME,        // col6
          COL_FUELST_TYPE_ID,
          COL_FUELST_STREET,
          COL_FUELST_CITY,
          COL_FUELST_STATE,
          COL_FUELST_ZIP,
          COL_FUELST_LATITUDE,
          COL_FUELST_LONGITUDE,
          COL_LOCAL_ID];          // where, col1
}

- (NSArray *)updateArgsForMasterFuelStation:(FPFuelStation *)fuelStation {
  return @[PELMOrNil([fuelStation globalIdentifier]),
           PELMOrNil([[fuelStation mediaType] description]),
           PELMOrNil([PEUtils millisecondsFromDate:[fuelStation createdAt]]),
           PELMOrNil([PEUtils millisecondsFromDate:[fuelStation updatedAt]]),
           PELMOrNil([PEUtils millisecondsFromDate:[fuelStation deletedAt]]),
           PELMOrNil([fuelStation name]),
           PELMOrNil([fuelStation type].identifier),
           PELMOrNil([fuelStation street]),
           PELMOrNil([fuelStation city]),
           PELMOrNil([fuelStation state]),
           PELMOrNil([fuelStation zip]),
           PELMOrNil([fuelStation latitude]),
           PELMOrNil([fuelStation longitude]),
           [fuelStation localMasterIdentifier]];
}

- (NSString *)updateStmtForMainFuelStation {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MAIN_FUEL_STATION,                   // table
          COL_GLOBAL_ID,                      // col1
          COL_MEDIA_TYPE,                     // col2
          COL_MAN_MASTER_UPDATED_AT,      // col3
          COL_MAN_DT_COPIED_DOWN_FROM_MASTER, // col4
          COL_FUELST_NAME,                       // col5
          COL_FUELST_TYPE_ID,
          COL_FUELST_STREET,
          COL_FUELST_CITY,
          COL_FUELST_STATE,
          COL_FUELST_ZIP,
          COL_FUELST_LATITUDE,
          COL_FUELST_LONGITUDE,
          COL_MAN_EDIT_IN_PROGRESS,           // col7
          COL_MAN_SYNC_IN_PROGRESS,           // col8
          COL_MAN_SYNCED,                     // col9
          COL_MAN_EDIT_COUNT,                 // col12
          COL_MAN_SYNC_HTTP_RESP_CODE,
          COL_MAN_SYNC_ERR_MASK,
          COL_MAN_SYNC_RETRY_AT,
          COL_LOCAL_ID];                      // where, col1
}

- (NSArray *)updateArgsForMainFuelStation:(FPFuelStation *)fuelStation {
  return @[PELMOrNil([fuelStation globalIdentifier]),
           PELMOrNil([[fuelStation mediaType] description]),
           PELMOrNil([PEUtils millisecondsFromDate:[fuelStation updatedAt]]),
           PELMOrNil([PEUtils millisecondsFromDate:[fuelStation dateCopiedFromMaster]]),
           PELMOrNil([fuelStation name]),
           PELMOrNil([fuelStation type].identifier),
           PELMOrNil([fuelStation street]),
           PELMOrNil([fuelStation city]),
           PELMOrNil([fuelStation state]),
           PELMOrNil([fuelStation zip]),
           PELMOrNil([fuelStation latitude]),
           PELMOrNil([fuelStation longitude]),
           [NSNumber numberWithBool:[fuelStation editInProgress]],
           [NSNumber numberWithBool:[fuelStation syncInProgress]],
           [NSNumber numberWithBool:[fuelStation synced]],
           [NSNumber numberWithInteger:[fuelStation editCount]],
           PELMOrNil([fuelStation syncHttpRespCode]),
           PELMOrNil([fuelStation syncErrMask]),
           PELMOrNil([PEUtils millisecondsFromDate:[fuelStation syncRetryAt]]),
           [fuelStation localMainIdentifier]];
}

#pragma mark - Vehicle data access helpers (private)

- (void)insertIntoMasterVehicle:(FPVehicle *)vehicle
                        forUser:(FPUser *)user
                             db:(FMDatabase *)db
                          error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@, \
%@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    TBL_MASTER_VEHICLE,
                    COL_MASTER_USER_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_MST_CREATED_AT,
                    COL_MST_UPDATED_AT,
                    COL_MST_DELETED_DT,
                    COL_VEH_NAME,
                    COL_VEH_DEFAULT_OCTANE,
                    COL_VEH_FUEL_CAPACITY,
                    COL_VEH_IS_DIESEL,
                    COL_VEH_HAS_DTE_READOUT,
                    COL_VEH_HAS_MPG_READOUT,
                    COL_VEH_HAS_MPH_READOUT,
                    COL_VEH_HAS_OUTSIDE_TEMP_READOUT,
                    COL_VEH_VIN,
                    COL_VEH_PLATE];
  [PELMUtils doMasterInsert:stmt
                  argsArray:@[PELMOrNil([user localMasterIdentifier]),
                              PELMOrNil([vehicle globalIdentifier]),
                              PELMOrNil([[vehicle mediaType] description]),
                              PELMOrNil([PEUtils millisecondsFromDate:[vehicle createdAt]]),
                              PELMOrNil([PEUtils millisecondsFromDate:[vehicle updatedAt]]),
                              PELMOrNil([PEUtils millisecondsFromDate:[vehicle deletedAt]]),
                              PELMOrNil([vehicle name]),
                              PELMOrNil([vehicle defaultOctane]),
                              PELMOrNil([vehicle fuelCapacity]),
                              [NSNumber numberWithBool:[vehicle isDiesel]],
                              [NSNumber numberWithBool:[vehicle hasDteReadout]],
                              [NSNumber numberWithBool:[vehicle hasMpgReadout]],
                              [NSNumber numberWithBool:[vehicle hasMphReadout]],
                              [NSNumber numberWithBool:[vehicle hasOutsideTempReadout]],
                              PELMOrNil([vehicle vin]),
                              PELMOrNil([vehicle plate])]
                     entity:vehicle
                         db:db
                      error:errorBlk];
}

- (void)insertIntoMainVehicle:(FPVehicle *)vehicle
                      forUser:(FPUser *)user
                           db:(FMDatabase *)db
                        error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@, %@, %@, %@, %@, %@, \
%@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    TBL_MAIN_VEHICLE,
                    COL_MAIN_USER_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_MAN_MASTER_UPDATED_AT,
                    COL_MAN_DT_COPIED_DOWN_FROM_MASTER,
                    COL_VEH_NAME,
                    COL_VEH_DEFAULT_OCTANE,
                    COL_VEH_FUEL_CAPACITY,
                    COL_VEH_IS_DIESEL,
                    COL_VEH_HAS_DTE_READOUT,
                    COL_VEH_HAS_MPG_READOUT,
                    COL_VEH_HAS_MPH_READOUT,
                    COL_VEH_HAS_OUTSIDE_TEMP_READOUT,
                    COL_VEH_VIN,
                    COL_VEH_PLATE,
                    COL_MAN_EDIT_IN_PROGRESS,
                    COL_MAN_SYNC_IN_PROGRESS,
                    COL_MAN_SYNCED,
                    COL_MAN_EDIT_COUNT,
                    COL_MAN_SYNC_HTTP_RESP_CODE,
                    COL_MAN_SYNC_ERR_MASK,
                    COL_MAN_SYNC_RETRY_AT];
  [PELMUtils doMainInsert:stmt
                argsArray:@[PELMOrNil([user localMainIdentifier]),
                            PELMOrNil([vehicle globalIdentifier]),
                            PELMOrNil([[vehicle mediaType] description]),
                            PELMOrNil([PEUtils millisecondsFromDate:[vehicle updatedAt]]),
                            PELMOrNil([PEUtils millisecondsFromDate:[vehicle dateCopiedFromMaster]]),
                            PELMOrNil([vehicle name]),
                            PELMOrNil([vehicle defaultOctane]),
                            PELMOrNil([vehicle fuelCapacity]),
                            [NSNumber numberWithBool:[vehicle isDiesel]],
                            [NSNumber numberWithBool:[vehicle hasDteReadout]],
                            [NSNumber numberWithBool:[vehicle hasMpgReadout]],
                            [NSNumber numberWithBool:[vehicle hasMphReadout]],
                            [NSNumber numberWithBool:[vehicle hasOutsideTempReadout]],
                            PELMOrNil([vehicle vin]),
                            PELMOrNil([vehicle plate]),
                            [NSNumber numberWithBool:[vehicle editInProgress]],
                            [NSNumber numberWithBool:[vehicle syncInProgress]],
                            [NSNumber numberWithBool:[vehicle synced]],
                            [NSNumber numberWithInteger:[vehicle editCount]],
                            PELMOrNil([vehicle syncHttpRespCode]),
                            PELMOrNil([vehicle syncErrMask]),
                            PELMOrNil([PEUtils millisecondsFromDate:[vehicle syncRetryAt]])]
                   entity:vehicle
                       db:db
                    error:errorBlk];
}

- (NSString *)updateStmtForMasterVehicle {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MASTER_VEHICLE,     // table
          COL_GLOBAL_ID,          // col1
          COL_MEDIA_TYPE,         // col2
          COL_MST_CREATED_AT,
          COL_MST_UPDATED_AT,  // col4
          COL_MST_DELETED_DT,     // col5
          COL_VEH_NAME,           // col6
          COL_VEH_DEFAULT_OCTANE,
          COL_VEH_FUEL_CAPACITY,
          COL_VEH_IS_DIESEL,
          COL_VEH_HAS_DTE_READOUT,
          COL_VEH_HAS_MPG_READOUT,
          COL_VEH_HAS_MPH_READOUT,
          COL_VEH_HAS_OUTSIDE_TEMP_READOUT,
          COL_VEH_VIN,
          COL_VEH_PLATE,
          COL_LOCAL_ID];          // where, col1
}

- (NSArray *)updateArgsForMasterVehicle:(FPVehicle *)vehicle {
  return @[PELMOrNil([vehicle globalIdentifier]),
           PELMOrNil([[vehicle mediaType] description]),
           PELMOrNil([PEUtils millisecondsFromDate:[vehicle createdAt]]),
           PELMOrNil([PEUtils millisecondsFromDate:[vehicle updatedAt]]),
           PELMOrNil([PEUtils millisecondsFromDate:[vehicle deletedAt]]),
           PELMOrNil([vehicle name]),
           PELMOrNil([vehicle defaultOctane]),
           PELMOrNil([vehicle fuelCapacity]),
           [NSNumber numberWithBool:[vehicle isDiesel]],
           [NSNumber numberWithBool:[vehicle hasDteReadout]],
           [NSNumber numberWithBool:[vehicle hasMpgReadout]],
           [NSNumber numberWithBool:[vehicle hasMphReadout]],
           [NSNumber numberWithBool:[vehicle hasOutsideTempReadout]],
           PELMOrNil([vehicle vin]),
           PELMOrNil([vehicle plate]),
           [vehicle localMasterIdentifier]];
}

- (NSString *)updateStmtForMainVehicle {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MAIN_VEHICLE,                   // table
          COL_GLOBAL_ID,                      // col1
          COL_MEDIA_TYPE,                     // col2
          COL_MAN_MASTER_UPDATED_AT,      // col3
          COL_MAN_DT_COPIED_DOWN_FROM_MASTER, // col4
          COL_VEH_NAME,                       // col5
          COL_VEH_DEFAULT_OCTANE,
          COL_VEH_FUEL_CAPACITY,
          COL_VEH_IS_DIESEL,
          COL_VEH_HAS_DTE_READOUT,
          COL_VEH_HAS_MPG_READOUT,
          COL_VEH_HAS_MPH_READOUT,
          COL_VEH_HAS_OUTSIDE_TEMP_READOUT,
          COL_VEH_VIN,
          COL_VEH_PLATE,
          COL_MAN_EDIT_IN_PROGRESS,           // col7
          COL_MAN_SYNC_IN_PROGRESS,           // col8
          COL_MAN_SYNCED,                     // col9
          COL_MAN_EDIT_COUNT,                 // col12
          COL_MAN_SYNC_HTTP_RESP_CODE,
          COL_MAN_SYNC_ERR_MASK,
          COL_MAN_SYNC_RETRY_AT,
          COL_LOCAL_ID];                      // where, col1
}

- (NSArray *)updateArgsForMainVehicle:(FPVehicle *)vehicle {
  return @[PELMOrNil([vehicle globalIdentifier]),
           PELMOrNil([[vehicle mediaType] description]),
           PELMOrNil([PEUtils millisecondsFromDate:[vehicle updatedAt]]),
           PELMOrNil([PEUtils millisecondsFromDate:[vehicle dateCopiedFromMaster]]),
           PELMOrNil([vehicle name]),
           PELMOrNil([vehicle defaultOctane]),
           PELMOrNil([vehicle fuelCapacity]),
           [NSNumber numberWithBool:[vehicle isDiesel]],
           [NSNumber numberWithBool:[vehicle hasDteReadout]],
           [NSNumber numberWithBool:[vehicle hasMpgReadout]],
           [NSNumber numberWithBool:[vehicle hasMphReadout]],
           [NSNumber numberWithBool:[vehicle hasOutsideTempReadout]],
           PELMOrNil([vehicle vin]),
           PELMOrNil([vehicle plate]),
           [NSNumber numberWithBool:[vehicle editInProgress]],
           [NSNumber numberWithBool:[vehicle syncInProgress]],
           [NSNumber numberWithBool:[vehicle synced]],
           [NSNumber numberWithInteger:[vehicle editCount]],
           PELMOrNil([vehicle syncHttpRespCode]),
           PELMOrNil([vehicle syncErrMask]),
           PELMOrNil([PEUtils millisecondsFromDate:[vehicle syncRetryAt]]),
           [vehicle localMainIdentifier]];
}

#pragma mark - Fuel Purchase Log data access helpers (private)

- (void)insertIntoMasterFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                forUser:(FPUser *)user
                                     db:(FMDatabase *)db
                                  error:(PELMDaoErrorBlk)errorBlk {
  NSString *vehicleGlobalId = [fuelPurchaseLog vehicleGlobalIdentifier];
  if (!vehicleGlobalId && [fuelPurchaseLog vehicleMainIdentifier]) {
    vehicleGlobalId = [PELMUtils stringFromTable:TBL_MAIN_VEHICLE
                                    selectColumn:COL_GLOBAL_ID
                                     whereColumn:COL_LOCAL_ID
                                      whereValue:[fuelPurchaseLog vehicleMainIdentifier]
                                              db:db
                                           error:errorBlk];
  }
  NSString *fuelStationGlobalId = [fuelPurchaseLog fuelStationGlobalIdentifier];
  if (!fuelStationGlobalId && [fuelPurchaseLog fuelStationMainIdentifier]) {
    fuelStationGlobalId = [PELMUtils stringFromTable:TBL_MAIN_FUEL_STATION
                                        selectColumn:COL_GLOBAL_ID
                                         whereColumn:COL_LOCAL_ID
                                          whereValue:[fuelPurchaseLog fuelStationMainIdentifier]
                                                  db:db
                                               error:errorBlk];
  }
  NSAssert(vehicleGlobalId, @"Fuel purchase log's vehicle global ID is nil");
  NSAssert(fuelStationGlobalId, @"Fuel purchase log's fuel station global ID is nil");
  FPVehicle *vehicle =
  (FPVehicle *)[PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", TBL_MASTER_VEHICLE, COL_GLOBAL_ID]
                              entityTable:TBL_MASTER_VEHICLE
                            localIdGetter:^NSNumber *(PELMModelSupport *entity){return [entity localMasterIdentifier];}
                                argsArray:@[vehicleGlobalId]
                              rsConverter:^(FMResultSet *rs){return [self masterVehicleFromResultSet:rs];}
                                       db:db
                                    error:errorBlk];
  FPFuelStation *fuelStation =
  (FPFuelStation *)[PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", TBL_MASTER_FUEL_STATION, COL_GLOBAL_ID]
                                  entityTable:TBL_MASTER_FUEL_STATION
                                localIdGetter:^NSNumber *(PELMModelSupport *entity){return [entity localMasterIdentifier];}
                                    argsArray:@[fuelStationGlobalId] //[fuelPurchaseLog fuelStationMainIdentifier]]
                                  rsConverter:^(FMResultSet *rs){return [self masterFuelStationFromResultSet:rs];}
                                           db:db
                                        error:errorBlk];
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@, \
%@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    TBL_MASTER_FUELPURCHASE_LOG,
                    COL_MASTER_USER_ID,
                    COL_MASTER_VEHICLE_ID,
                    COL_MASTER_FUELSTATION_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_MST_CREATED_AT,
                    COL_MST_UPDATED_AT,
                    COL_MST_DELETED_DT,
                    COL_FUELPL_NUM_GALLONS,
                    COL_FUELPL_OCTANE,
                    COL_FUELPL_ODOMETER,
                    COL_FUELPL_PRICE_PER_GALLON,
                    COL_FUELPL_CAR_WASH_PER_GALLON_DISCOUNT,
                    COL_FUELPL_GOT_CAR_WASH,
                    COL_FUELPL_PURCHASED_AT,
                    COL_FUELPL_IS_DIESEL];
  [PELMUtils doMasterInsert:stmt
                  argsArray:@[PELMOrNil([user localMasterIdentifier]),
                              PELMOrNil([vehicle localMasterIdentifier]),
                              PELMOrNil([fuelStation localMasterIdentifier]),
                              PELMOrNil([fuelPurchaseLog globalIdentifier]),
                              PELMOrNil([[fuelPurchaseLog mediaType] description]),
                              PELMOrNil([PEUtils millisecondsFromDate:[fuelPurchaseLog createdAt]]),
                              PELMOrNil([PEUtils millisecondsFromDate:[fuelPurchaseLog updatedAt]]),
                              PELMOrNil([PEUtils millisecondsFromDate:[fuelPurchaseLog deletedAt]]),
                              PELMOrNil([fuelPurchaseLog numGallons]),
                              PELMOrNil([fuelPurchaseLog octane]),
                              PELMOrNil([fuelPurchaseLog odometer]),
                              PELMOrNil([fuelPurchaseLog gallonPrice]),
                              PELMOrNil([fuelPurchaseLog carWashPerGallonDiscount]),
                              [NSNumber numberWithBool:[fuelPurchaseLog gotCarWash]],
                              PELMOrNil([PEUtils millisecondsFromDate:[fuelPurchaseLog purchasedAt]]),
                              [NSNumber numberWithBool:[fuelPurchaseLog isDiesel]]]
                     entity:fuelPurchaseLog
                         db:db
                      error:errorBlk];
}

- (void)insertIntoMainFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                              forUser:(FPUser *)user
                              vehicle:(FPVehicle *)vehicle
                          fuelStation:(FPFuelStation *)fuelStation
                                   db:(FMDatabase *)db
                                error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ \
(%@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@) VALUES \
(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    TBL_MAIN_FUELPURCHASE_LOG,
                    COL_MAIN_USER_ID,
                    COL_MAIN_VEHICLE_ID,
                    COL_MAIN_FUELSTATION_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_MAN_MASTER_UPDATED_AT,
                    COL_MAN_DT_COPIED_DOWN_FROM_MASTER,
                    COL_FUELPL_NUM_GALLONS,
                    COL_FUELPL_OCTANE,
                    COL_FUELPL_ODOMETER,
                    COL_FUELPL_PRICE_PER_GALLON,
                    COL_FUELPL_CAR_WASH_PER_GALLON_DISCOUNT,
                    COL_FUELPL_GOT_CAR_WASH,
                    COL_FUELPL_PURCHASED_AT,
                    COL_FUELPL_IS_DIESEL,
                    COL_MAN_EDIT_IN_PROGRESS,
                    COL_MAN_SYNC_IN_PROGRESS,
                    COL_MAN_SYNCED,
                    COL_MAN_EDIT_COUNT,
                    COL_MAN_SYNC_HTTP_RESP_CODE,
                    COL_MAN_SYNC_ERR_MASK,
                    COL_MAN_SYNC_RETRY_AT];
  [PELMUtils doMainInsert:stmt
                argsArray:@[PELMOrNil([user localMainIdentifier]),
                            PELMOrNil([vehicle localMainIdentifier]),
                            PELMOrNil([fuelStation localMainIdentifier]),
                            PELMOrNil([fuelPurchaseLog globalIdentifier]),
                            PELMOrNil([[fuelPurchaseLog mediaType] description]),
                            PELMOrNil([PEUtils millisecondsFromDate:[fuelPurchaseLog updatedAt]]),
                            PELMOrNil([PEUtils millisecondsFromDate:[fuelPurchaseLog dateCopiedFromMaster]]),
                            PELMOrNil([fuelPurchaseLog numGallons]),
                            PELMOrNil([fuelPurchaseLog octane]),
                            PELMOrNil([fuelPurchaseLog odometer]),
                            PELMOrNil([fuelPurchaseLog gallonPrice]),
                            PELMOrNil([fuelPurchaseLog carWashPerGallonDiscount]),
                            [NSNumber numberWithBool:[fuelPurchaseLog gotCarWash]],
                            PELMOrNil([PEUtils millisecondsFromDate:[fuelPurchaseLog purchasedAt]]),
                            [NSNumber numberWithBool:[fuelPurchaseLog isDiesel]],
                            [NSNumber numberWithBool:[fuelPurchaseLog editInProgress]],
                            [NSNumber numberWithBool:[fuelPurchaseLog syncInProgress]],
                            [NSNumber numberWithBool:[fuelPurchaseLog synced]],
                            [NSNumber numberWithInteger:[fuelPurchaseLog editCount]],
                            PELMOrNil([fuelPurchaseLog syncHttpRespCode]),
                            PELMOrNil([fuelPurchaseLog syncErrMask]),
                            PELMOrNil([PEUtils millisecondsFromDate:[fuelPurchaseLog syncRetryAt]])]
                   entity:fuelPurchaseLog
                       db:db
                    error:errorBlk];
}

- (NSString *)updateStmtForMasterFuelPurchaseLog {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ? \
WHERE %@ = ?",
          TBL_MASTER_FUELPURCHASE_LOG, // table
          COL_MASTER_VEHICLE_ID,
          COL_MASTER_FUELSTATION_ID,
          COL_GLOBAL_ID,          // col1
          COL_MEDIA_TYPE,         // col2
          COL_MST_CREATED_AT,
          COL_MST_UPDATED_AT,  // col4
          COL_MST_DELETED_DT,     // col5
          COL_FUELPL_NUM_GALLONS,
          COL_FUELPL_OCTANE,
          COL_FUELPL_ODOMETER,
          COL_FUELPL_PRICE_PER_GALLON,
          COL_FUELPL_CAR_WASH_PER_GALLON_DISCOUNT,
          COL_FUELPL_GOT_CAR_WASH,
          COL_FUELPL_PURCHASED_AT,
          COL_FUELPL_IS_DIESEL,
          COL_LOCAL_ID];          // where, col1
}

- (NSString *)updateStmtForMasterFuelPurchaseLogSansVehicleFuelStationFks {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ? \
WHERE %@ = ?",
          TBL_MASTER_FUELPURCHASE_LOG, // table
          COL_GLOBAL_ID,          // col1
          COL_MEDIA_TYPE,         // col2
          COL_MST_CREATED_AT,
          COL_MST_UPDATED_AT,  // col4
          COL_MST_DELETED_DT,     // col5
          COL_FUELPL_NUM_GALLONS,
          COL_FUELPL_OCTANE,
          COL_FUELPL_ODOMETER,
          COL_FUELPL_PRICE_PER_GALLON,
          COL_FUELPL_CAR_WASH_PER_GALLON_DISCOUNT,
          COL_FUELPL_GOT_CAR_WASH,
          COL_FUELPL_PURCHASED_AT,
          COL_FUELPL_IS_DIESEL,
          COL_LOCAL_ID];          // where, col1
}

- (NSArray *)updateArgsForMasterFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog {
  return [self updateArgsForMasterFuelPurchaseLog:fuelPurchaseLog vehicle:nil fuelStation:nil];
}

- (NSArray *)updateArgsForMasterFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                        vehicle:(FPVehicle *)vehicle
                                    fuelStation:(FPFuelStation *)fuelStation {
  NSMutableArray *args = [NSMutableArray array];
  if (vehicle) {
    [args addObject:[vehicle localMasterIdentifier]];
  }
  if (fuelStation) {
    [args addObject:[fuelStation localMasterIdentifier]];
  }
  NSArray *reqdArgs =
  @[PELMOrNil([fuelPurchaseLog globalIdentifier]),
    PELMOrNil([[fuelPurchaseLog mediaType] description]),
    PELMOrNil([PEUtils millisecondsFromDate:[fuelPurchaseLog createdAt]]),
    PELMOrNil([PEUtils millisecondsFromDate:[fuelPurchaseLog updatedAt]]),
    PELMOrNil([PEUtils millisecondsFromDate:[fuelPurchaseLog deletedAt]]),
    PELMOrNil([fuelPurchaseLog numGallons]),
    PELMOrNil([fuelPurchaseLog octane]),
    PELMOrNil([fuelPurchaseLog odometer]),
    PELMOrNil([fuelPurchaseLog gallonPrice]),
    PELMOrNil([fuelPurchaseLog carWashPerGallonDiscount]),
    [NSNumber numberWithBool:[fuelPurchaseLog gotCarWash]],
    PELMOrNil([PEUtils millisecondsFromDate:[fuelPurchaseLog purchasedAt]]),
    [NSNumber numberWithBool:[fuelPurchaseLog isDiesel]],
    [fuelPurchaseLog localMasterIdentifier]];
  [args addObjectsFromArray:reqdArgs];
  return args;
}

- (NSString *)updateStmtForMainFuelPurchaseLog {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MAIN_FUELPURCHASE_LOG,                   // table
          COL_MAIN_VEHICLE_ID,
          COL_MAIN_FUELSTATION_ID,
          COL_GLOBAL_ID,                      // col1
          COL_MEDIA_TYPE,                     // col2
          COL_MAN_MASTER_UPDATED_AT,      // col3
          COL_MAN_DT_COPIED_DOWN_FROM_MASTER, // col4
          COL_FUELPL_NUM_GALLONS,
          COL_FUELPL_OCTANE,
          COL_FUELPL_ODOMETER,
          COL_FUELPL_PRICE_PER_GALLON,
          COL_FUELPL_CAR_WASH_PER_GALLON_DISCOUNT,
          COL_FUELPL_GOT_CAR_WASH,
          COL_FUELPL_PURCHASED_AT,                   // col6
          COL_FUELPL_IS_DIESEL,
          COL_MAN_EDIT_IN_PROGRESS,           // col7
          COL_MAN_SYNC_IN_PROGRESS,           // col8
          COL_MAN_SYNCED,                     // col9
          COL_MAN_EDIT_COUNT,                 // col12
          COL_MAN_SYNC_HTTP_RESP_CODE,
          COL_MAN_SYNC_ERR_MASK,
          COL_MAN_SYNC_RETRY_AT,
          COL_LOCAL_ID];                      // where, col1
}

- (NSString *)updateStmtForMainFuelPurchaseLogSansVehicleFuelStationFks {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MAIN_FUELPURCHASE_LOG,                   // table
          COL_GLOBAL_ID,                      // col1
          COL_MEDIA_TYPE,                     // col2
          COL_MAN_MASTER_UPDATED_AT,      // col3
          COL_MAN_DT_COPIED_DOWN_FROM_MASTER, // col4
          COL_FUELPL_NUM_GALLONS,
          COL_FUELPL_OCTANE,
          COL_FUELPL_ODOMETER,
          COL_FUELPL_PRICE_PER_GALLON,
          COL_FUELPL_CAR_WASH_PER_GALLON_DISCOUNT,
          COL_FUELPL_GOT_CAR_WASH,
          COL_FUELPL_PURCHASED_AT,                   // col6
          COL_FUELPL_IS_DIESEL,
          COL_MAN_EDIT_IN_PROGRESS,           // col7
          COL_MAN_SYNC_IN_PROGRESS,           // col8
          COL_MAN_SYNCED,                     // col9
          COL_MAN_EDIT_COUNT,                 // col12
          COL_MAN_SYNC_HTTP_RESP_CODE,
          COL_MAN_SYNC_ERR_MASK,
          COL_MAN_SYNC_RETRY_AT,
          COL_LOCAL_ID];                      // where, col1
}

- (NSArray *)updateArgsForMainFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog {
  return [self updateArgsForMainFuelPurchaseLog:fuelPurchaseLog
                                        vehicle:nil
                                    fuelStation:nil];
}

- (NSArray *)updateArgsForMainFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                      vehicle:(FPVehicle *)vehicle
                                  fuelStation:(FPFuelStation *)fuelStation {
  NSMutableArray *args = [NSMutableArray array];
  if (vehicle) {
    [args addObject:[vehicle localMainIdentifier]];
  }
  if (fuelStation) {
    [args addObject:[fuelStation localMainIdentifier]];
  }
  NSArray *reqdArgs =
  @[PELMOrNil([fuelPurchaseLog globalIdentifier]),
    PELMOrNil([[fuelPurchaseLog mediaType] description]),
    PELMOrNil([PEUtils millisecondsFromDate:[fuelPurchaseLog updatedAt]]),
    PELMOrNil([PEUtils millisecondsFromDate:[fuelPurchaseLog dateCopiedFromMaster]]),
    PELMOrNil([fuelPurchaseLog numGallons]),
    PELMOrNil([fuelPurchaseLog octane]),
    PELMOrNil([fuelPurchaseLog odometer]),
    PELMOrNil([fuelPurchaseLog gallonPrice]),
    PELMOrNil([fuelPurchaseLog carWashPerGallonDiscount]),
    [NSNumber numberWithBool:[fuelPurchaseLog gotCarWash]],
    PELMOrNil([PEUtils millisecondsFromDate:[fuelPurchaseLog purchasedAt]]),
    [NSNumber numberWithBool:[fuelPurchaseLog isDiesel]],
    [NSNumber numberWithBool:[fuelPurchaseLog editInProgress]],
    [NSNumber numberWithBool:[fuelPurchaseLog syncInProgress]],
    [NSNumber numberWithBool:[fuelPurchaseLog synced]],
    [NSNumber numberWithInteger:[fuelPurchaseLog editCount]],
    PELMOrNil([fuelPurchaseLog syncHttpRespCode]),
    PELMOrNil([fuelPurchaseLog syncErrMask]),
    PELMOrNil([PEUtils millisecondsFromDate:[fuelPurchaseLog syncRetryAt]]),
    [fuelPurchaseLog localMainIdentifier]];
  [args addObjectsFromArray:reqdArgs];
  return args;
}

#pragma mark - Environment Log data access helpers (private)

- (void)insertIntoMasterEnvironmentLog:(FPEnvironmentLog *)environmentLog
                               forUser:(FPUser *)user
                                    db:(FMDatabase *)db
                                 error:(PELMDaoErrorBlk)errorBlk {
  NSString *vehicleGlobalId = [environmentLog vehicleGlobalIdentifier];
  if (!vehicleGlobalId && [environmentLog vehicleMainIdentifier]) {
    vehicleGlobalId = [PELMUtils stringFromTable:TBL_MAIN_VEHICLE
                                    selectColumn:COL_GLOBAL_ID
                                     whereColumn:COL_LOCAL_ID
                                      whereValue:[environmentLog vehicleMainIdentifier]
                                              db:db
                                           error:errorBlk];
  }
  NSAssert(vehicleGlobalId, @"Environment log's vehicle global ID is nil");
  FPVehicle *vehicle =
  (FPVehicle *)[PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", TBL_MASTER_VEHICLE, COL_GLOBAL_ID]
                              entityTable:TBL_MASTER_VEHICLE
                            localIdGetter:^NSNumber *(PELMModelSupport *entity){return [entity localMasterIdentifier];}
                                argsArray:@[vehicleGlobalId]
                              rsConverter:^(FMResultSet *rs){return [self masterVehicleFromResultSet:rs];}
                                       db:db
                                    error:errorBlk];
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@, \
%@, %@, %@, %@, %@, %@, %@, %@, %@, %@) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    TBL_MASTER_ENV_LOG,
                    COL_MASTER_USER_ID,
                    COL_MASTER_VEHICLE_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_MST_CREATED_AT,
                    COL_MST_UPDATED_AT,
                    COL_MST_DELETED_DT,
                    COL_ENVL_ODOMETER_READING,
                    COL_ENVL_MPG_READING,
                    COL_ENVL_MPH_READING,
                    COL_ENVL_OUTSIDE_TEMP_READING,
                    COL_ENVL_LOG_DT,
                    COL_ENVL_DTE];
  [PELMUtils doMasterInsert:stmt
                  argsArray:@[PELMOrNil([user localMasterIdentifier]),
                              PELMOrNil([vehicle localMasterIdentifier]),
                              PELMOrNil([environmentLog globalIdentifier]),
                              PELMOrNil([[environmentLog mediaType] description]),
                              PELMOrNil([PEUtils millisecondsFromDate:[environmentLog createdAt]]),
                              PELMOrNil([PEUtils millisecondsFromDate:[environmentLog updatedAt]]),
                              PELMOrNil([PEUtils millisecondsFromDate:[environmentLog deletedAt]]),
                              PELMOrNil([environmentLog odometer]),
                              PELMOrNil([environmentLog reportedAvgMpg]),
                              PELMOrNil([environmentLog reportedAvgMph]),
                              PELMOrNil([environmentLog reportedOutsideTemp]),
                              PELMOrNil([PEUtils millisecondsFromDate:[environmentLog logDate]]),
                              PELMOrNil([environmentLog reportedDte])]
                     entity:environmentLog
                         db:db
                      error:errorBlk];
}

- (void)insertIntoMainEnvironmentLog:(FPEnvironmentLog *)environmentLog
                             forUser:(FPUser *)user
                             vehicle:(FPVehicle *)vehicle
                                  db:(FMDatabase *)db
                               error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ \
                    (%@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@) VALUES \
                    (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    TBL_MAIN_ENV_LOG,
                    COL_MAIN_USER_ID,
                    COL_MAIN_VEHICLE_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_MAN_MASTER_UPDATED_AT,
                    COL_MAN_DT_COPIED_DOWN_FROM_MASTER,
                    COL_ENVL_ODOMETER_READING,
                    COL_ENVL_MPG_READING,
                    COL_ENVL_MPH_READING,
                    COL_ENVL_OUTSIDE_TEMP_READING,
                    COL_ENVL_LOG_DT,
                    COL_ENVL_DTE,
                    COL_MAN_EDIT_IN_PROGRESS,
                    COL_MAN_SYNC_IN_PROGRESS,
                    COL_MAN_SYNCED,
                    COL_MAN_EDIT_COUNT,
                    COL_MAN_SYNC_HTTP_RESP_CODE,
                    COL_MAN_SYNC_ERR_MASK,
                    COL_MAN_SYNC_RETRY_AT];
  [PELMUtils doMainInsert:stmt
                argsArray:@[PELMOrNil([user localMainIdentifier]),
                            PELMOrNil([vehicle localMainIdentifier]),
                            PELMOrNil([environmentLog globalIdentifier]),
                            PELMOrNil([[environmentLog mediaType] description]),
                            PELMOrNil([PEUtils millisecondsFromDate:[environmentLog updatedAt]]),
                            PELMOrNil([PEUtils millisecondsFromDate:[environmentLog dateCopiedFromMaster]]),
                            PELMOrNil([environmentLog odometer]),
                            PELMOrNil([environmentLog reportedAvgMpg]),
                            PELMOrNil([environmentLog reportedAvgMph]),
                            PELMOrNil([environmentLog reportedOutsideTemp]),
                            PELMOrNil([PEUtils millisecondsFromDate:[environmentLog logDate]]),
                            PELMOrNil([environmentLog reportedDte]),
                            [NSNumber numberWithBool:[environmentLog editInProgress]],
                            [NSNumber numberWithBool:[environmentLog syncInProgress]],
                            [NSNumber numberWithBool:[environmentLog synced]],
                            [NSNumber numberWithInteger:[environmentLog editCount]],
                            PELMOrNil([environmentLog syncHttpRespCode]),
                            PELMOrNil([environmentLog syncErrMask]),
                            PELMOrNil([PEUtils millisecondsFromDate:[environmentLog syncRetryAt]])]
                   entity:environmentLog
                       db:db
                    error:errorBlk];
}

- (NSString *)updateStmtForMasterEnvironmentLog {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MASTER_ENV_LOG, // table
          COL_MASTER_VEHICLE_ID,
          COL_GLOBAL_ID,          // col1
          COL_MEDIA_TYPE,         // col2
          COL_MST_CREATED_AT,
          COL_MST_UPDATED_AT,  // col4
          COL_MST_DELETED_DT,     // col5
          COL_ENVL_ODOMETER_READING,
          COL_ENVL_MPG_READING,
          COL_ENVL_MPH_READING,
          COL_ENVL_OUTSIDE_TEMP_READING,
          COL_ENVL_LOG_DT,
          COL_ENVL_DTE,
          COL_LOCAL_ID];          // where, col1
}

- (NSString *)updateStmtForMasterEnvironmentLogSansVehicleFks {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MASTER_ENV_LOG, // table
          COL_GLOBAL_ID,          // col1
          COL_MEDIA_TYPE,         // col2
          COL_MST_CREATED_AT,
          COL_MST_UPDATED_AT,  // col4
          COL_MST_DELETED_DT,     // col5
          COL_ENVL_ODOMETER_READING,
          COL_ENVL_MPG_READING,
          COL_ENVL_MPH_READING,
          COL_ENVL_OUTSIDE_TEMP_READING,
          COL_ENVL_LOG_DT,
          COL_ENVL_DTE,
          COL_LOCAL_ID];          // where, col1
}

- (NSArray *)updateArgsForMasterEnvironmentLog:(FPEnvironmentLog *)environmentLog {
  return [self updateArgsForMasterEnvironmentLog:environmentLog vehicle:nil];
}

- (NSArray *)updateArgsForMasterEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                       vehicle:(FPVehicle *)vehicle {
  NSMutableArray *args = [NSMutableArray array];
  if (vehicle) {
    [args addObject:[vehicle localMasterIdentifier]];
  }
  NSArray *reqdArgs =
  @[PELMOrNil([environmentLog globalIdentifier]),
    PELMOrNil([[environmentLog mediaType] description]),
    PELMOrNil([PEUtils millisecondsFromDate:[environmentLog createdAt]]),
    PELMOrNil([PEUtils millisecondsFromDate:[environmentLog updatedAt]]),
    PELMOrNil([PEUtils millisecondsFromDate:[environmentLog deletedAt]]),
    PELMOrNil([environmentLog odometer]),
    PELMOrNil([environmentLog reportedAvgMpg]),
    PELMOrNil([environmentLog reportedAvgMph]),
    PELMOrNil([environmentLog reportedOutsideTemp]),
    PELMOrNil([PEUtils millisecondsFromDate:[environmentLog logDate]]),
    PELMOrNil([environmentLog reportedDte]),
    [environmentLog localMasterIdentifier]];
  [args addObjectsFromArray:reqdArgs];
  return args;
}

- (NSString *)updateStmtForMainEnvironmentLog {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MAIN_ENV_LOG,                   // table
          COL_MAIN_VEHICLE_ID,
          COL_GLOBAL_ID,                      // col1
          COL_MEDIA_TYPE,                     // col2
          COL_MAN_MASTER_UPDATED_AT,      // col3
          COL_MAN_DT_COPIED_DOWN_FROM_MASTER, // col4
          COL_ENVL_ODOMETER_READING,
          COL_ENVL_MPG_READING,
          COL_ENVL_MPH_READING,
          COL_ENVL_OUTSIDE_TEMP_READING,
          COL_ENVL_LOG_DT,
          COL_ENVL_DTE,
          COL_MAN_EDIT_IN_PROGRESS,           // col7
          COL_MAN_SYNC_IN_PROGRESS,           // col8
          COL_MAN_SYNCED,                     // col9
          COL_MAN_EDIT_COUNT,                 // col12
          COL_MAN_SYNC_HTTP_RESP_CODE,
          COL_MAN_SYNC_ERR_MASK,
          COL_MAN_SYNC_RETRY_AT,
          COL_LOCAL_ID];                      // where, col1
}

- (NSString *)updateStmtForMainEnvironmentLogSansVehicleFks {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MAIN_ENV_LOG,                   // table
          COL_GLOBAL_ID,                      // col1
          COL_MEDIA_TYPE,                     // col2
          COL_MAN_MASTER_UPDATED_AT,      // col3
          COL_MAN_DT_COPIED_DOWN_FROM_MASTER, // col4
          COL_ENVL_ODOMETER_READING,
          COL_ENVL_MPG_READING,
          COL_ENVL_MPH_READING,
          COL_ENVL_OUTSIDE_TEMP_READING,
          COL_ENVL_LOG_DT,                  // col6
          COL_ENVL_DTE,
          COL_MAN_EDIT_IN_PROGRESS,           // col7
          COL_MAN_SYNC_IN_PROGRESS,           // col8
          COL_MAN_SYNCED,                     // col9
          COL_MAN_EDIT_COUNT,                 // col12
          COL_MAN_SYNC_HTTP_RESP_CODE,
          COL_MAN_SYNC_ERR_MASK,
          COL_MAN_SYNC_RETRY_AT,
          COL_LOCAL_ID];                      // where, col1
}

- (NSArray *)updateArgsForMainEnvironmentLog:(FPEnvironmentLog *)environmentLog {
  return [self updateArgsForMainEnvironmentLog:environmentLog
                                       vehicle:nil];
}

- (NSArray *)updateArgsForMainEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                     vehicle:(FPVehicle *)vehicle {
  NSMutableArray *args = [NSMutableArray array];
  if (vehicle) {
    [args addObject:[vehicle localMainIdentifier]];
  }
  NSArray *reqdArgs =
  @[PELMOrNil([environmentLog globalIdentifier]),
    PELMOrNil([[environmentLog mediaType] description]),
    PELMOrNil([PEUtils millisecondsFromDate:[environmentLog updatedAt]]),
    PELMOrNil([PEUtils millisecondsFromDate:[environmentLog dateCopiedFromMaster]]),
    PELMOrNil([environmentLog odometer]),
    PELMOrNil([environmentLog reportedAvgMpg]),
    PELMOrNil([environmentLog reportedAvgMph]),
    PELMOrNil([environmentLog reportedOutsideTemp]),
    PELMOrNil([PEUtils millisecondsFromDate:[environmentLog logDate]]),
    PELMOrNil([environmentLog reportedDte]),
    [NSNumber numberWithBool:[environmentLog editInProgress]],
    [NSNumber numberWithBool:[environmentLog syncInProgress]],
    [NSNumber numberWithBool:[environmentLog synced]],
    [NSNumber numberWithInteger:[environmentLog editCount]],
    PELMOrNil([environmentLog syncHttpRespCode]),
    PELMOrNil([environmentLog syncErrMask]),
    PELMOrNil([PEUtils millisecondsFromDate:[environmentLog syncRetryAt]]),
    [environmentLog localMainIdentifier]];
  [args addObjectsFromArray:reqdArgs];
  return args;
}

@end
