//
//  FPScreenToolkit.m
//  fuelpurchase
//
//  Created by Evans, Paul on 9/17/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPScreenToolkit.h"
#import "FPEditsInProgressController.h"
#import "FPSettingsController.h"
#import "FPHomeController.h"
#import "FPRaisedCenterTabController.h"
#import "FPRecordsController.h"
#import <PEObjc-Commons/PEUtils.h>
#import <PEObjc-Commons/PEUIUtils.h>
#import <PEObjc-Commons/NSString+PEAdditions.h>
#import <PEObjc-Commons/PEDatePickerController.h>
#import "PEListViewController.h"
#import "PEAddViewEditController.h"
#import "FPUtils.h"
#import <PELocal-Data/PELMNotificationUtils.h>
#import "FPPanelToolkit.h"
#import "FPFpLogVehicleFuelStationDateDataSourceAndDelegate.h"
#import "FPEnvLogVehicleAndDateDataSourceDelegate.h"
#import "NSString+PEAdditions.h"
#import "FPLogEnvLogComposite.h"
#import "FPNames.h"
#import "PELMUIUtils.h"
#import "FPJotController.h"
#import "FPAccountController.h"
#import <FlatUIKit/UIColor+FlatUI.h>
#import <BlocksKit/UIView+BlocksKit.h>
#import <BlocksKit/UIControl+BlocksKit.h>
#import "FPUIUtils.h"
#import "FPAppNotificationNames.h"
#import "FPReportViews.h"
#import "FPCommonStatController.h"
#import <PEFuelPurchase-Model/FPStats.h>
#import "FPCommonStatsLaunchController.h"
#import "FPCommonStatComparisonController.h"
#import <PELocal-Data/PEUserCoordinatorDao.h>
#import <PEFuelPurchase-Model/FPLocalDao.h>
#import <PELocal-Data/PELocalDao.h>
#import <PEFuelPurchase-Model/FPVehicle.h>
#import <PEFuelPurchase-Model/FPFuelStation.h>
#import <PEFuelPurchase-Model/FPFuelPurchaseLog.h>
#import <PEFuelPurchase-Model/FPEnvironmentLog.h>

NSInteger const PAGINATION_PAGE_SIZE = 30;
NSInteger const USER_ACCOUNT_STATUS_PANEL_TAG = 12;

@implementation FPScreenToolkit {
  id<FPCoordinatorDao> _coordDao;
  FPPanelToolkit *_panelToolkit;
  PELMDaoErrorBlk _errorBlk;
  FPReportViews *_reportViews;
  FPStats *_stats;
  NSNumberFormatter *_currencyFormatter;
  NSNumberFormatter *_generalFormatter;
}

#pragma mark - Initializers

- (id)initWithCoordinatorDao:(id<FPCoordinatorDao>)coordDao
                   uitoolkit:(PEUIToolkit *)uitoolkit
                       error:(PELMDaoErrorBlk)errorBlk {
  self = [super init];
  if (self) {
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _panelToolkit = [[FPPanelToolkit alloc] initWithCoordinatorDao:coordDao
                                                     screenToolkit:self
                                                         uitoolkit:uitoolkit
                                                             error:errorBlk];
    _reportViews = [[FPReportViews alloc] initWithStats:[[FPStats alloc] initWithLocalDao:_coordDao errorBlk:errorBlk]];
    _stats = [[FPStats alloc] initWithLocalDao:_coordDao errorBlk:[FPUtils localFetchErrorHandlerMaker]()];
    _currencyFormatter = [PEUtils currencyFormatter];
    _generalFormatter = [[NSNumberFormatter alloc] init];
    [_generalFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [_generalFormatter setMaximumFractionDigits:1];
  }
  return self;
}

#pragma mark - Helpers

- (PEWouldBeIndexOfEntity)wouldBeIndexBlkForEqualityBlock:(BOOL(^)(id, id))equalityBlock
                                            entityFetcher:(NSArray *(^)(void))entityFetcher {
  return ^ NSInteger (PELMMainSupport *entity) {
    NSArray *entities = entityFetcher();
    NSInteger index = 0;
    NSInteger count = 0;
    for (PELMMainSupport *e in entities) {
      if (equalityBlock(e, entity)) {
        index = count;
        break;
      }
      count++;
    }
    return index;
  };
}

- (PEModalOperationStarted)commonModalOperationStartedBlock {
  return ^{
    [APP enableJotButton:NO];
  };
}

- (PEModalOperationDone)commonModalOperationDoneBlock {
  return ^{
    [APP enableJotButton:YES];
  };
}

- (void)deselectSelectedRowForTableOnView:(UIView *)parentView tableViewTag:(NSInteger)tableViewTag {
  UITableView *tableView = (UITableView *)[parentView viewWithTag:tableViewTag];
  if ([tableView indexPathForSelectedRow]) {
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
  }
}

+ (JGActionSheetSection *)funFactSectionWithNumFunFacts:(NSInteger)numFunFacts
                                         nextFunFactBlk:(FPFunFact(^)(void))nextFunFactBlk
                                                 record:(id)record
                                                   user:(FPUser *)user
                                         relativeToView:(UIView *)relativeToView {
  FPFunFact funFact = nextFunFactBlk();
  JGActionSheetSection *funFactSection = funFact(record, user, relativeToView);
  NSInteger funFactsAttempted = 1;
  while (funFactSection == nil) {
    if (funFactsAttempted == numFunFacts) {
      break;
    }
    funFact = nextFunFactBlk();
    funFactSection = funFact(record, user, relativeToView);
    funFactsAttempted++;
  }
  return funFactSection;
}

- (NSString *)formattedValueForValue:(id)value formatter:(NSString *(^)(id))formatter {
  if (![PEUtils isNil:value]) {
    return formatter(value);
  } else {
    return @"---";
  }
}

- (CGFloat(^)(void))heightForCellsBlkWithExtraPadding:(CGFloat)extraPadding {
  return ^CGFloat{ return [PEUIUtils sizeOfText:@""
                                       withFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleBody]].height +
    _uitoolkit.verticalPaddingForButtons + 15.0 + extraPadding; };
}

- (CGFloat(^)(void))heightForCellsBlk {
  return [self heightForCellsBlkWithExtraPadding:10.0];
}

#pragma mark - Generic Screens

- (FPAuthScreenMaker)newDatePickerScreenMakerWithTitle:(NSString *)title
                                   initialSelectedDate:(NSDate *)date
                                   logDatePickedAction:(void(^)(NSDate *))logDatePickedAction {
  return ^UIViewController *(FPUser *user) {
    return [[PEDatePickerController alloc] initWithTitle:title
                                        heightPercentage:0.70
                                             initialDate:date
                                     logDatePickedAction:logDatePickedAction];
  };
}

#pragma mark - Drafts Screens

- (FPAuthScreenMaker)newViewUnsyncedEditsScreenMaker {
  return ^ UIViewController *(FPUser *user) {
    return [[FPEditsInProgressController alloc] initWithStoreCoordinator:_coordDao
                                                                    user:user
                                                               uitoolkit:_uitoolkit
                                                           screenToolkit:self];
  };
}

#pragma mark - Settings Screens

- (FPAuthScreenMaker)newViewSettingsScreenMaker {
  return ^ UIViewController *(FPUser *user) {
    return [[FPSettingsController alloc] initWithStoreCoordinator:_coordDao
                                                             user:user
                                                        uitoolkit:_uitoolkit
                                                    screenToolkit:self];
  };
}

#pragma mark - User Account Screens

- (PEEntityValidatorBlk)newUserAccountValidator {
  return ^NSArray *(UIView *userAccountPanel) {
    NSMutableArray *errMsgs = [NSMutableArray array];
    //NSString *name = [((UITextField *)[userAccountPanel viewWithTag:FPUserTagName]) text];
    NSString *email = [((UITextField *)[userAccountPanel viewWithTag:FPUserTagEmail]) text];
    if ([email isBlank]) {
      [errMsgs addObject:@"E-mail cannot be blank."];
    }
    NSString *password = [((UITextField *)[userAccountPanel viewWithTag:FPUserTagPassword]) text];
    if (![password isBlank]) {
      NSString *confirmPassword = [((UITextField *)[userAccountPanel viewWithTag:FPUserTagConfirmPassword]) text];
      if ([confirmPassword isBlank]) {
        [errMsgs addObject:@"To update your password, re-enter it in the 'Confirm Password' field."];
      } else if (![password isEqualToString:confirmPassword]) {
        [errMsgs addObject:@"Passwords do not match."];
      }
    } else {
      NSString *confirmPassword = [((UITextField *)[userAccountPanel viewWithTag:FPUserTagConfirmPassword]) text];
      if (![confirmPassword isBlank]) {
        [errMsgs addObject:@"If you want to update your password, you have to enter it in both the 'Password' and 'Confirm Password' fields."];
      }
    }
    return errMsgs;
  };
}

- (FPAuthScreenMaker)newUserAccountDetailScreenMaker {
  return ^ UIViewController * (FPUser *user) {
    PEEntityEditPreparerBlk userEditPreparer = ^BOOL(PEAddViewEditController *ctrl, FPUser *user) {
      BOOL prepareSuccess = [_coordDao prepareUserForEdit:user error:[FPUtils localSaveErrorHandlerMaker]()];
      [user setConfirmPassword:nil];
      [APP refreshTabs];
      return prepareSuccess;
    };
    PEEntityEditCancelerBlk userEditCanceler = ^(PEAddViewEditController *ctrl, FPUser *user) {
      [_coordDao cancelEditOfUser:user error:[FPUtils localSaveErrorHandlerMaker]()];
      [APP refreshTabs];
    };
    PESaveEntityBlk userSaver = ^(PEAddViewEditController *ctrl, FPUser *user) {
      [_coordDao saveUser:user error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEMarkAsDoneEditingImmediateSyncBlk doneEditingUserImmediateSync = ^(PEAddViewEditController *ctrl,
                                                                         FPUser *user,
                                                                         PESyncNotFoundBlk notFoundBlk,
                                                                         PESyncSuccessBlk successBlk,
                                                                         PESyncRetryAfterBlk retryAfterBlk,
                                                                         PESyncServerTempErrorBlk tempErrBlk,
                                                                         PESyncServerErrorBlk errBlk,
                                                                         PESyncConflictBlk conflictBlk,
                                                                         PESyncAuthRequiredBlk authReqdBlk,
                                                                         PESyncDependencyUnsynced depUnsyncedBlk) {
      NSString *mainMsgFragment = @"saving user account to the server";
      NSString *recordTitle = @"User account";
      [_coordDao.userCoordinatorDao markAsDoneEditingAndSyncUserImmediate:user
                                                      notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                           addlSuccessBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                   addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                                                   addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                       addlRemoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeSaveUsrErrMsgs:errMask]); [APP refreshTabs];}
                                                          addlConflictBlk:^(PELMUser *latestUser) {conflictBlk(1, mainMsgFragment, recordTitle, latestUser); [APP refreshTabs];}
                                                      addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                                    error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEPrepareUIForUserInteractionBlk prepareUIForUserInteractionBlk = ^(PEAddViewEditController *ctrl, UIView *entityPanel) {
      if (![ctrl hasPoppedKeyboard]) {
        UITextField *userNameTf = (UITextField *)[entityPanel viewWithTag:FPUserTagName];
        [userNameTf becomeFirstResponder];
        [ctrl setHasPoppedKeyboard:YES];
      }
    };
    
    PEMergeBlk mergeBlk = ^ NSDictionary * (PEAddViewEditController *ctrl, FPUser *localUser, FPUser *remoteUser) {
      FPUser *masterUser = (FPUser *)[_coordDao masterUserWithId:[localUser localMasterIdentifier] error:[FPUtils localFetchErrorHandlerMaker]()];
      return [FPUser mergeRemoteUser:remoteUser withLocalUser:localUser localMasterUser:masterUser];
    };
    PEConflictResolveFields conflictResolveFieldsBlk = ^(PEAddViewEditController *ctrl,
                                                         NSDictionary *mergeConflicts,
                                                         FPUser *localUser,
                                                         FPUser *remoteUser) {
      NSMutableArray *fields = [NSMutableArray arrayWithCapacity:mergeConflicts.count];
      [mergeConflicts enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *fieldName = key;
        if ([fieldName isEqualToString:FPUserNameField]) {
          [fields addObject:@[@"Name:", @(FPUserTagName), [PEUtils emptyIfNil:[localUser name]], [PEUtils emptyIfNil:[remoteUser name]]]];
        } else if ([fieldName isEqualToString:FPUserEmailField]) {
          [fields addObject:@[@"Email:", @(FPUserTagEmail), [PEUtils emptyIfNil:[localUser email]], [PEUtils emptyIfNil:[remoteUser email]]]];
        }
      }];
      return fields;
    };
    PEConflictResolvedEntity conflictResolvedEntityBlk = ^ id (PEAddViewEditController *ctrl,
                                                               NSDictionary *mergeConflicts,
                                                               NSArray *valueLabels,
                                                               FPUser *localUser,
                                                               FPUser *remoteUser) {
      FPUser *resolvedUser = [localUser copy];
      NSInteger numValueLabels = [valueLabels count];
      for (int i = 0; i < numValueLabels; i++) {
        NSArray *valueLabelPair = valueLabels[i];
        UILabel *remoteValue = valueLabelPair[1];
        if (remoteValue.tag > 0) {
          switch (remoteValue.tag) {
            case FPUserTagName:
              [resolvedUser setName:[remoteUser name]];
              break;
            case FPUserTagEmail:
              [resolvedUser setEmail:[remoteUser email]];
              break;
          }
        }
      }
      return resolvedUser;
    };
    PEDownloaderBlk downloaderBlk = ^ (PEAddViewEditController *ctrl,
                                       FPUser *user,
                                       PESyncNotFoundBlk notFoundBlk,
                                       PEDownloadSuccessBlk successBlk,
                                       PESyncRetryAfterBlk retryAfterBlk,
                                       PESyncServerTempErrorBlk tempErrBlk,
                                       PESyncAuthRequiredBlk authReqdBlk) {
      NSString *mainMsgFragment = @"fetching user account";
      NSString *recordTitle = @"User account";
      float percentOfFetching = 1.0;
      [_coordDao.userCoordinatorDao fetchUser:user
                              ifModifiedSince:[user updatedAt]
                          notFoundOnServerBlk:^{notFoundBlk(percentOfFetching, mainMsgFragment, recordTitle);}
                                   successBlk:^(PELMUser *fetchedUser) {successBlk(percentOfFetching, mainMsgFragment, recordTitle, fetchedUser);}
                           remoteStoreBusyBlk:^(NSDate *retryAfter){retryAfterBlk(percentOfFetching, mainMsgFragment, recordTitle, retryAfter);}
                           tempRemoteErrorBlk:^{tempErrBlk(percentOfFetching, mainMsgFragment, recordTitle);}
                          addlAuthRequiredBlk:^{authReqdBlk(percentOfFetching, mainMsgFragment, recordTitle); [APP refreshTabs];}];
    };
    PEPostDownloaderSaver postDownloadSaverBlk = ^ (PEAddViewEditController *ctrl,
                                                    FPUser *downloadedUser,
                                                    FPUser *user) {
      [_coordDao saveMasterUser:downloadedUser error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEViewDidAppearBlk viewDidAppearBlk = ^(PEAddViewEditController *ctrl) {
      [FPPanelToolkit refreshAccountStatusPanelForUser:user
                                              panelTag:@(USER_ACCOUNT_STATUS_PANEL_TAG)
                                  includeRefreshButton:NO
                                        coordinatorDao:_coordDao
                                             uitoolkit:_uitoolkit
                                        relativeToView:ctrl.view
                                            controller:ctrl];
    };
    return [PEAddViewEditController viewEntityCtrlrWithParentEntity:nil
                                                             entity:user
                                                 listViewController:nil
                                                    entityIndexPath:nil
                                                          uitoolkit:_uitoolkit
                                                     itemChangedBlk:nil
                                               entityFormPanelMaker:[_panelToolkit userAccountFormPanelMaker]
                                               entityViewPanelMaker:[_panelToolkit userAccountViewPanelMakerWithAccountStatusLabelTag:USER_ACCOUNT_STATUS_PANEL_TAG]
                                                entityToPanelBinder:[_panelToolkit userToUserPanelBinder]
                                                panelToEntityBinder:[_panelToolkit userFormPanelToUserBinder]
                                                        entityTitle:@"User Account"
                                               panelEnablerDisabler:[_panelToolkit userFormPanelEnablerDisabler]
                                                  entityAddCanceler:nil
                                                 entityEditPreparer:userEditPreparer
                                                 entityEditCanceler:userEditCanceler
                                                        entitySaver:userSaver
                                             doneEditingEntityLocal:nil
                                     doneEditingEntityImmediateSync:doneEditingUserImmediateSync
                                                    isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                     isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                      isOfflineMode:^{ return [APP offlineMode]; }
                                     syncImmediateMBProgressHUDMode:MBProgressHUDModeIndeterminate
                                     prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                                   viewDidAppearBlk:viewDidAppearBlk
                                                    entityValidator:[self newUserAccountValidator]
                                                           uploader:nil
                                              numRemoteDepsNotLocal:nil
                                                              merge:mergeBlk
                                                  fetchDependencies:nil
                                                    updateDepsPanel:nil
                                                         downloader:downloaderBlk
                                                  postDownloadSaver:postDownloadSaverBlk
                                              conflictResolveFields:conflictResolveFieldsBlk
                                             conflictResolvedEntity:conflictResolvedEntityBlk
                                                itemChildrenCounter:nil
                                                itemChildrenMsgsBlk:nil
                                                        itemDeleter:nil
                                                   itemLocalDeleter:nil
                                              modalOperationStarted:[self commonModalOperationStartedBlock]
                                                 modalOperationDone:[self commonModalOperationDoneBlock]
                                      entityUpdatedNotificationName:FPEntityUpdatedNotification
                                      entityRemovedNotificationName:FPEntityDeletedNotification];
  };
}

#pragma mark - User Stat Screens

- (FPAuthScreenMaker)newUserStatsLaunchScreenMakerWithParentController:(UIViewController *)parentController {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatsLaunchController alloc] initWithScreenTitle:@"Stats & Trends"
                                                  entityTypeLabelText:nil
                                                        entityNameBlk:nil
                                                               entity:user
                                                 statLaunchButtonsBlk:^{
                                                   NSMutableArray *statLaunchButtons = [NSMutableArray array];
                                                   [statLaunchButtons addObject:@"DAYS BETWEEN FILL-UPS"];
                                                   [statLaunchButtons addObject:@[^UIView *(void) {
                                                     return [PEUIUtils tablePanelWithRowData:@[@[@"Days since last fill-up",
                                                                                                 [self formattedValueForValue:[_stats daysSinceLastGasLogForUser:user]
                                                                                                                    formatter:^NSString *(id val) { return [_generalFormatter stringFromNumber:val]; }]]]
                                                                                   uitoolkit:_uitoolkit
                                                                                  parentView:parentController.view];
                                                   }]];
                                                   [statLaunchButtons addObject:@[@"Avg days between fill-ups",
                                                                                  ^{ return [self newAvgDaysBetweenFillupsStatsScreenMaker](user); }]];
                                                   [statLaunchButtons addObject:@[@"Max days between fill-ups",
                                                                                  ^{ return [self newMaxDaysBetweenFillupsStatsScreenMaker](user); }]];
                                                   [statLaunchButtons addObject:@"COST PER MILE"];
                                                   [statLaunchButtons addObject:@[@"Avg gas cost/mile",
                                                                                  ^{ return [self newAvgGasCostPerMileStatsScreenMaker](user); }]];
                                                   [statLaunchButtons addObject:@"MILES PER GALLON"];
                                                   [statLaunchButtons addObject:@[@"Avg MPG",
                                                                                  ^{ return [self newAvgReportedMpgStatsScreenMaker](user); }]];
                                                   [statLaunchButtons addObject:@[@"Max MPG",
                                                                                  ^{ return [self newMaxReportedMpgStatsScreenMaker](user); }]];
                                                   [statLaunchButtons addObject:@[@"Min MPG",
                                                                                  ^{ return [self newMinReportedMpgStatsScreenMaker](user); }]];
                                                   [statLaunchButtons addObject:@"MILES PER HOUR"];
                                                   [statLaunchButtons addObject:@[@"Avg MPH",
                                                                                  ^{ return [self newAvgReportedMphStatsScreenMaker](user); }]];
                                                   [statLaunchButtons addObject:@[@"Max MPH",
                                                                                  ^{ return [self newMaxReportedMphStatsScreenMaker](user); }]];
                                                   [statLaunchButtons addObject:@[@"Min MPH",
                                                                                  ^{ return [self newMinReportedMphStatsScreenMaker](user); }]];
                                                   [statLaunchButtons addObject:@"GAS SPEND"];
                                                   [statLaunchButtons addObject:@[@"Total amount spent",
                                                                                  ^{ return [self newSpentOnGasStatsScreenMaker](user); }]];
                                                   [statLaunchButtons addObject:@[@"Avg monthly spend",
                                                                                  ^{ return [self newAvgSpentOnGasStatsScreenMaker](user); }]];
                                                   [statLaunchButtons addObject:@[@"Min monthly spend",
                                                                                  ^{ return [self newMinSpentOnGasStatsScreenMaker](user); }]];
                                                   [statLaunchButtons addObject:@[@"Max monthly spend",
                                                                                  ^{ return [self newMaxSpentOnGasStatsScreenMaker](user); }]];
                                                   NSArray *octanes = [_coordDao distinctOctanesForUser:user error:_errorBlk];
                                                   for (NSNumber *octane in octanes) {
                                                     [statLaunchButtons addObject:[NSString stringWithFormat:@"%@ OCTANE - PRICE STATS", octane]];
                                                     [statLaunchButtons addObject:@[[NSString stringWithFormat:@"Avg price of %@", octane],
                                                                                    ^{ return [self newAvgPricePerGallonStatsScreenMakerWithOctane:octane](user); }]];
                                                     [statLaunchButtons addObject:@[[NSString stringWithFormat:@"Min price of %@", octane],
                                                                                    ^{ return [self newMinPricePerGallonStatsScreenMakerWithOctane:octane](user); }]];
                                                     [statLaunchButtons addObject:@[[NSString stringWithFormat:@"Max price of %@", octane],
                                                                                    ^{ return [self newMaxPricePerGallonStatsScreenMakerWithOctane:octane](user); }]];
                                                   }
                                                   if ([_coordDao hasDieselLogsForUser:user error:_errorBlk]) {
                                                     [statLaunchButtons addObject:@"DIESEL - PRICE STATS"];
                                                     [statLaunchButtons addObject:@[@"Avg price of diesel",
                                                                                    ^{ return [self newAvgPricePerDieselGallonStatsScreenMaker](user); }]];
                                                   }
                                                   return statLaunchButtons;
                                                 }
                                                            uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newAvgPricePerDieselGallonStatsScreenMaker {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:[NSString stringWithFormat:@"Avg Price of Diesel"]
                                           entityTypeLabelText:@"ALL GAS STATIONS"
                                                 entityNameBlk:nil
                                                        entity:user
                                          aggregatesHeaderText:[NSString stringWithFormat:@"AVG PRICE OF DIESEL"]
                                        compareButtonTitleText:@"Compare gas stations"
                                           alltimeAggregateBlk:^(FPUser *u) {return [_stats overallAvgPricePerDieselGallonForUser:u];}
                                        yearToDateAggregateBlk:^(FPUser *u) {return [_stats yearToDateAvgPricePerDieselGallonForUser:u];}
                                          lastYearAggregateBlk:^(FPUser *u) {return [_stats lastYearAvgPricePerDieselGallonForUser:u];}
                                             alltimeDatasetBlk:^(FPUser *u) {return [_stats overallAvgPricePerDieselGallonDataSetForUser:u];}
                                          yearToDateDatasetBlk:^(FPUser *u) {return [_stats yearToDateAvgPricePerDieselGallonDataSetForUser:u];}
                                            lastYearDatasetBlk:^(FPUser *u) {return [_stats lastYearAvgPricePerDieselGallonDataSetForUser:u];}
                                               siblingCountBlk:^{return [_coordDao fuelStationsForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newFuelStationCompareAvgPricePerDieselGallonStatsScreenMakerWithFuelstationInCtx:nil](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newMinReportedMphStatsScreenMaker {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Min MPH"
                                           entityTypeLabelText:@"ALL VEHICLES"
                                                 entityNameBlk:nil
                                                        entity:user
                                          aggregatesHeaderText:@"MIN MPH"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPUser *u) {return [_stats overallMinReportedMphForUser:u];}
                                        yearToDateAggregateBlk:^(FPUser *u) {return [_stats yearToDateMinReportedMphForUser:u];}
                                          lastYearAggregateBlk:^(FPUser *u) {return [_stats lastYearMinReportedMphForUser:u];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareMinReportedMphStatsScreenMakerWithVehicleInCtx:nil](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_generalFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newMaxReportedMphStatsScreenMaker {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Max MPH"
                                           entityTypeLabelText:@"ALL VEHICLES"
                                                 entityNameBlk:nil
                                                        entity:user
                                          aggregatesHeaderText:@"MAX MPH"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPUser *u) {return [_stats overallMaxReportedMphForUser:u];}
                                        yearToDateAggregateBlk:^(FPUser *u) {return [_stats yearToDateMaxReportedMphForUser:u];}
                                          lastYearAggregateBlk:^(FPUser *u) {return [_stats lastYearMaxReportedMphForUser:u];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareMaxReportedMphStatsScreenMakerWithVehicleInCtx:nil](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_generalFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newAvgReportedMphStatsScreenMaker {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Avg MPH"
                                           entityTypeLabelText:@"ALL VEHICLES"
                                                 entityNameBlk:nil
                                                        entity:user
                                          aggregatesHeaderText:@"AVG MPH"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPUser *u) {return [_stats overallAvgReportedMphForUser:u];}
                                        yearToDateAggregateBlk:^(FPUser *u) {return [_stats yearToDateAvgReportedMphForUser:u];}
                                          lastYearAggregateBlk:^(FPUser *u) {return [_stats lastYearAvgReportedMphForUser:u];}
                                             alltimeDatasetBlk:^(FPUser *u) {return [_stats overallAvgReportedMphDataSetForUser:u];}
                                          yearToDateDatasetBlk:^(FPUser *u) {return [_stats yearToDateAvgReportedMphDataSetForUser:u];}
                                            lastYearDatasetBlk:^(FPUser *u) {return [_stats lastYearAvgReportedMphDataSetForUser:u];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareAvgReportedMphStatsScreenMakerWithVehicleInCtx:nil](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_generalFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newMinReportedMpgStatsScreenMaker {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Min MPG"
                                           entityTypeLabelText:@"ALL VEHICLES"
                                                 entityNameBlk:nil
                                                        entity:user
                                          aggregatesHeaderText:@"MIN MPG"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPUser *u) {return [_stats overallMinReportedMpgForUser:u];}
                                        yearToDateAggregateBlk:^(FPUser *u) {return [_stats yearToDateMinReportedMpgForUser:u];}
                                          lastYearAggregateBlk:^(FPUser *u) {return [_stats lastYearMinReportedMpgForUser:u];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareMinReportedMpgStatsScreenMakerWithVehicleInCtx:nil](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_generalFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newMaxReportedMpgStatsScreenMaker {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Max MPG"
                                           entityTypeLabelText:@"ALL VEHICLES"
                                                 entityNameBlk:nil
                                                        entity:user
                                          aggregatesHeaderText:@"MAX MPG"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPUser *u) {return [_stats overallMaxReportedMpgForUser:u];}
                                        yearToDateAggregateBlk:^(FPUser *u) {return [_stats yearToDateMaxReportedMpgForUser:u];}
                                          lastYearAggregateBlk:^(FPUser *u) {return [_stats lastYearMaxReportedMpgForUser:u];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareMaxReportedMpgStatsScreenMakerWithVehicleInCtx:nil](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_generalFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newAvgReportedMpgStatsScreenMaker {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Avg MPG"
                                           entityTypeLabelText:@"ALL VEHICLES"
                                                 entityNameBlk:nil
                                                        entity:user
                                          aggregatesHeaderText:@"AVG MPG"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPUser *u) {return [_stats overallAvgReportedMpgForUser:u];}
                                        yearToDateAggregateBlk:^(FPUser *u) {return [_stats yearToDateAvgReportedMpgForUser:u];}
                                          lastYearAggregateBlk:^(FPUser *u) {return [_stats lastYearAvgReportedMpgForUser:u];}
                                             alltimeDatasetBlk:^(FPUser *u) {return [_stats overallAvgReportedMpgDataSetForUser:u];}
                                          yearToDateDatasetBlk:^(FPUser *u) {return [_stats yearToDateAvgReportedMpgDataSetForUser:u];}
                                            lastYearDatasetBlk:^(FPUser *u) {return [_stats lastYearAvgReportedMpgDataSetForUser:u];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareAvgReportedMpgStatsScreenMakerWithVehicleInCtx:nil](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_generalFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newMaxPricePerGallonStatsScreenMakerWithOctane:(NSNumber *)octane {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:[NSString stringWithFormat:@"Max Price of %@", octane]
                                           entityTypeLabelText:@"ALL GAS STATIONS"
                                                 entityNameBlk:nil
                                                        entity:user
                                          aggregatesHeaderText:[NSString stringWithFormat:@"MAX PRICE OF %@", octane]
                                        compareButtonTitleText:@"Compare gas stations"
                                           alltimeAggregateBlk:^(FPUser *u) {return [_stats overallMaxPricePerGallonForUser:u octane:octane];}
                                        yearToDateAggregateBlk:^(FPUser *u) {return [_stats yearToDateMaxPricePerGallonForUser:u octane:octane];}
                                          lastYearAggregateBlk:^(FPUser *u) {return [_stats lastYearMaxPricePerGallonForUser:u octane:octane];}
                                               siblingCountBlk:^{return [_coordDao fuelStationsForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newFuelStationCompareMaxPricePerGallonStatsScreenMakerWithFuelstationInCtx:nil
                                                                                                                                                  octane:octane](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newMinPricePerGallonStatsScreenMakerWithOctane:(NSNumber *)octane {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:[NSString stringWithFormat:@"Min Price of %@", octane]
                                           entityTypeLabelText:@"ALL GAS STATIONS"
                                                 entityNameBlk:nil
                                                        entity:user
                                          aggregatesHeaderText:[NSString stringWithFormat:@"MIN PRICE OF %@", octane]
                                        compareButtonTitleText:@"Compare gas stations"
                                           alltimeAggregateBlk:^(FPUser *u) {return [_stats overallMinPricePerGallonForUser:u octane:octane];}
                                        yearToDateAggregateBlk:^(FPUser *u) {return [_stats yearToDateMinPricePerGallonForUser:u octane:octane];}
                                          lastYearAggregateBlk:^(FPUser *u) {return [_stats lastYearMinPricePerGallonForUser:u octane:octane];}
                                               siblingCountBlk:^{return [_coordDao fuelStationsForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newFuelStationCompareMinPricePerGallonStatsScreenMakerWithFuelstationInCtx:nil
                                                                                                                                                  octane:octane](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newMaxSpentOnGasStatsScreenMaker {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Max Monthly Spend"
                                           entityTypeLabelText:@"ALL VEHICLES"
                                                 entityNameBlk:nil
                                                        entity:user
                                          aggregatesHeaderText:@"MAX MONTHLY SPEND"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPUser *u) {return [_stats overallMaxSpentOnGasForUser:u];}
                                        yearToDateAggregateBlk:^(FPUser *u) {return [_stats yearToDateMaxSpentOnGasForUser:u];}
                                          lastYearAggregateBlk:^(FPUser *u) {return [_stats lastYearMaxSpentOnGasForUser:u];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareMaxSpentOnGasStatsScreenMakerWithVehicleInCtx:nil](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newMinSpentOnGasStatsScreenMaker {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Min Monthly Spend"
                                           entityTypeLabelText:@"ALL VEHICLES"
                                                 entityNameBlk:nil
                                                        entity:user
                                          aggregatesHeaderText:@"MIN MONTHLY SPEND"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPUser *u) {return [_stats overallMinSpentOnGasForUser:u];}
                                        yearToDateAggregateBlk:^(FPUser *u) {return [_stats yearToDateMinSpentOnGasForUser:u];}
                                          lastYearAggregateBlk:^(FPUser *u) {return [_stats lastYearMinSpentOnGasForUser:u];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareMinSpentOnGasStatsScreenMakerWithVehicleInCtx:nil](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newAvgSpentOnGasStatsScreenMaker {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Avg Monthly Spend"
                                           entityTypeLabelText:@"ALL VEHICLES"
                                                 entityNameBlk:nil
                                                        entity:user
                                          aggregatesHeaderText:@"AVG MONTHLY SPEND"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPUser *u) {return [_stats overallAvgSpentOnGasForUser:u];}
                                        yearToDateAggregateBlk:^(FPUser *u) {return [_stats yearToDateAvgSpentOnGasForUser:u];}
                                          lastYearAggregateBlk:^(FPUser *u) {return [_stats lastYearAvgSpentOnGasForUser:u];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareAvgSpentOnGasStatsScreenMakerWithVehicleInCtx:nil](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newAvgGasCostPerMileStatsScreenMaker {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Avg Gas Cost/Mile"
                                           entityTypeLabelText:@"ALL VEHICLES"
                                                 entityNameBlk:nil
                                                        entity:user
                                          aggregatesHeaderText:@"AVG GAS COST/MILE"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPUser *u) {return [_stats overallAvgGasCostPerMileForUser:u];}
                                        yearToDateAggregateBlk:^(FPUser *u) {return [_stats yearToDateAvgGasCostPerMileForUser:u];}
                                          lastYearAggregateBlk:^(FPUser *u) {return [_stats lastYearAvgGasCostPerMileForUser:u];}
                                             alltimeDatasetBlk:^(FPUser *u) {return [_stats overallAvgGasCostPerMileDataSetForUser:u];}
                                          yearToDateDatasetBlk:^(FPUser *u) {return [_stats yearToDateAvgGasCostPerMileDataSetForUser:u];}
                                            lastYearDatasetBlk:^(FPUser *u) {return [_stats lastYearAvgGasCostPerMileDataSetForUser:u];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareAvgGasCostPerMileStatsScreenMakerWithVehicleInCtx:nil](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newMaxDaysBetweenFillupsStatsScreenMaker {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Max Days Between Fill-ups"
                                           entityTypeLabelText:@"ALL VEHICLES"
                                                 entityNameBlk:nil
                                                        entity:user
                                          aggregatesHeaderText:@"MAX DAYS BETWEEN FILL-UPS"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPUser *u) {return [_stats overallMaxDaysBetweenFillupsForUser:u];}
                                        yearToDateAggregateBlk:^(FPUser *u) {return [_stats yearToDateMaxDaysBetweenFillupsForUser:u];}
                                          lastYearAggregateBlk:^(FPUser *u) {return [_stats lastYearMaxDaysBetweenFillupsForUser:u];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareMaxDaysBetweenFillupsStatsScreenMakerWithVehicleInCtx:nil](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_generalFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newAvgDaysBetweenFillupsStatsScreenMaker {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Avg Days Between Fill-ups"
                                           entityTypeLabelText:@"ALL VEHICLES"
                                                 entityNameBlk:nil
                                                        entity:user
                                          aggregatesHeaderText:@"AVG DAYS BETWEEN FILL-UPS"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPUser *u) {return [_stats overallAvgDaysBetweenFillupsForUser:u];}
                                        yearToDateAggregateBlk:^(FPUser *u) {return [_stats yearToDateAvgDaysBetweenFillupsForUser:u];}
                                          lastYearAggregateBlk:^(FPUser *u) {return [_stats lastYearAvgDaysBetweenFillupsForUser:u];}
                                             alltimeDatasetBlk:^(FPUser *u) {return [_stats overallAvgDaysBetweenFillupsDataSetForUser:u];}
                                          yearToDateDatasetBlk:^(FPUser *u) {return [_stats yearToDateAvgDaysBetweenFillupsDataSetForUser:u];}
                                            lastYearDatasetBlk:^(FPUser *u) {return [_stats lastYearAvgDaysBetweenFillupsDataSetForUser:u];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareAvgDaysBetweenFillupsStatsScreenMakerWithVehicleInCtx:nil](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [NSString stringWithFormat:@"%@ days", [_generalFormatter stringFromNumber:val]];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newAvgPricePerGallonStatsScreenMakerWithOctane:(NSNumber *)octane {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:[NSString stringWithFormat:@"Avg Price of Gas (%@)", octane]
                                           entityTypeLabelText:@"ALL GAS STATIONS"
                                                 entityNameBlk:nil
                                                        entity:user
                                          aggregatesHeaderText:[NSString stringWithFormat:@"AVG PRICE OF GAS (%@ octane)", octane]
                                        compareButtonTitleText:@"Compare gas stations"
                                           alltimeAggregateBlk:^(FPUser *u) {return [_stats overallAvgPricePerGallonForUser:u octane:octane];}
                                        yearToDateAggregateBlk:^(FPUser *u) {return [_stats yearToDateAvgPricePerGallonForUser:u octane:octane];}
                                          lastYearAggregateBlk:^(FPUser *u) {return [_stats lastYearAvgPricePerGallonForUser:u octane:octane];}
                                             alltimeDatasetBlk:^(FPUser *u) {return [_stats overallAvgPricePerGallonDataSetForUser:u octane:octane];}
                                          yearToDateDatasetBlk:^(FPUser *u) {return [_stats yearToDateAvgPricePerGallonDataSetForUser:u octane:octane];}
                                            lastYearDatasetBlk:^(FPUser *u) {return [_stats lastYearAvgPricePerGallonDataSetForUser:u octane:octane];}
                                               siblingCountBlk:^{return [_coordDao fuelStationsForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newFuelStationCompareAvgPricePerGallonStatsScreenMakerWithFuelstationInCtx:nil octane:octane](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newAvgPricePerGallonStatsScreenMaker {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:[NSString stringWithFormat:@"Avg Price"]
                                           entityTypeLabelText:@"ALL GAS STATIONS"
                                                 entityNameBlk:nil
                                                        entity:user
                                          aggregatesHeaderText:[NSString stringWithFormat:@"AVG PRICE"]
                                        compareButtonTitleText:@"Compare gas stations"
                                           alltimeAggregateBlk:^(FPUser *u) {return [_stats overallAvgPricePerGallonForUser:u];}
                                        yearToDateAggregateBlk:^(FPUser *u) {return [_stats yearToDateAvgPricePerGallonForUser:u];}
                                          lastYearAggregateBlk:^(FPUser *u) {return [_stats lastYearAvgPricePerGallonForUser:u];}
                                             alltimeDatasetBlk:^(FPUser *u) {return [_stats overallAvgPricePerGallonDataSetForUser:u];}
                                          yearToDateDatasetBlk:^(FPUser *u) {return [_stats yearToDateAvgPricePerGallonDataSetForUser:u];}
                                            lastYearDatasetBlk:^(FPUser *u) {return [_stats lastYearAvgPricePerGallonDataSetForUser:u];}
                                               siblingCountBlk:^{return [_coordDao fuelStationsForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newFuelStationCompareAvgPricePerGallonStatsScreenMakerWithFuelstationInCtx:nil](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newSpentOnGasStatsScreenMaker {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Spend"
                                           entityTypeLabelText:@"ALL VEHICLES"
                                                 entityNameBlk:nil
                                                        entity:user
                                          aggregatesHeaderText:@"SPEND"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPUser *u) {return [_stats overallSpentOnGasForUser:u];}
                                        yearToDateAggregateBlk:^(FPUser *u) {return [_stats yearToDateSpentOnGasForUser:u];}
                                          lastYearAggregateBlk:^(FPUser *u) {return [_stats lastYearSpentOnGasForUser:u];}
                                             alltimeDatasetBlk:^(FPUser *u) {return [_stats overallSpentOnGasDataSetForUser:u];}
                                          yearToDateDatasetBlk:^(FPUser *u) {return [_stats yearToDateSpentOnGasDataSetForUser:u];}
                                            lastYearDatasetBlk:^(FPUser *u) {return [_stats lastYearSpentOnGasDataSetForUser:u];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareSpentOnGasStatsScreenMaker](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

#pragma mark - Vehicle Screens

- (PEItemChildrenCounter)vehicleItemChildrenCounter {
  PEItemChildrenCounter itemChildrenCounter = ^ NSInteger (FPVehicle *vehicle) {
    return [_coordDao numFuelPurchaseLogsForVehicle:vehicle
                                              error:[FPUtils localFetchErrorHandlerMaker]()] +
      [_coordDao numEnvironmentLogsForVehicle:vehicle
                                        error:[FPUtils localFetchErrorHandlerMaker]()];
  };
  return itemChildrenCounter;
}

- (PEItemChildrenMsgsBlk)vehicleItemChildrenMsgs {
  PEItemChildrenMsgsBlk itemChildrenMsgs = ^ NSArray * (FPVehicle *vehicle) {
    NSInteger numFplogs = [_coordDao numFuelPurchaseLogsForVehicle:vehicle
                                                             error:[FPUtils localFetchErrorHandlerMaker]()];
    NSInteger numEnvlogs = [_coordDao numEnvironmentLogsForVehicle:vehicle
                                                             error:[FPUtils localFetchErrorHandlerMaker]()];
    NSMutableArray *msgs = [NSMutableArray array];
    if (numFplogs > 0) {
      [msgs addObject:[NSString stringWithFormat:@"%ld gas log%@", (long)numFplogs, (numFplogs > 1 ? @"s" : @"")]];
    }
    if (numEnvlogs > 0) {
      [msgs addObject:[NSString stringWithFormat:@"%ld odometer log%@", (long)numEnvlogs, (numEnvlogs > 1 ? @"s" : @"")]];
    }
    return msgs;
  };
  return itemChildrenMsgs;
}

- (PEItemDeleter)vehicleItemDeleterForUser:(FPUser *)user {
  PEItemDeleter itemDeleter = ^ (UIViewController *listViewController,
                                 FPVehicle *vehicle,
                                 NSIndexPath *indexPath,
                                 PESyncNotFoundBlk notFoundBlk,
                                 PESyncSuccessBlk successBlk,
                                 PESyncRetryAfterBlk retryAfterBlk,
                                 PESyncServerTempErrorBlk tempErrBlk,
                                 PESyncServerErrorBlk errBlk,
                                 PESyncConflictBlk conflictBlk,
                                 PESyncAuthRequiredBlk authReqdBlk) {
    NSString *mainMsgFragment = @"deleting vehicle";
    NSString *recordTitle = @"Vehicle";
    [_coordDao deleteVehicle:vehicle
                     forUser:user
         notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
              addlSuccessBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
          remoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
          tempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
              remoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeEnvLogErrMsgs:errMask]); [APP refreshTabs];}
                 conflictBlk:^(FPVehicle *latestVehicle) {conflictBlk(1, mainMsgFragment, recordTitle, latestVehicle); [APP refreshTabs];}
         addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                       error:[FPUtils localSaveErrorHandlerMaker]()];
  };
  return itemDeleter;
}

- (PEItemLocalDeleter)vehicleItemLocalDeleter {
  return ^ (UIViewController *listViewController, FPVehicle *vehicle, NSIndexPath *indexPath) {
    [_coordDao deleteVehicle:vehicle error:[FPUtils localSaveErrorHandlerMaker]()];
    [APP refreshTabs];
  };
}

- (FPAuthScreenMaker)newViewVehiclesScreenMaker {
  return ^ UIViewController *(FPUser *user) {
    void (^addVehicleAction)(PEListViewController *, PEItemAddedBlk) =
      ^(PEListViewController *listViewCtrl, PEItemAddedBlk itemAddedBlk) {
      // the reason we present the add screen as a nav-ctrl is so we that can experience
      // the animation effect of the view appearing from the bottom-up (and it being modal)
      UIViewController *addVehicleScreen =
        [self newAddVehicleScreenMakerWithDelegate:itemAddedBlk listViewController:listViewCtrl](user);
      [listViewCtrl presentViewController:[PEUIUtils navigationControllerWithController:addVehicleScreen
                                                                    navigationBarHidden:NO]
                                 animated:YES
                               completion:nil];
    };
    FPDetailViewMaker vehicleDetailViewMaker = ^UIViewController *(PEListViewController *listViewCtrl,
                                                                   id dataObject,
                                                                   NSIndexPath *indexPath,
                                                                   PEItemChangedBlk itemChangedBlk) {
      return [self newVehicleDetailScreenMakerWithVehicle:dataObject
                                         vehicleIndexPath:indexPath
                                           itemChangedBlk:itemChangedBlk
                                       listViewController:listViewCtrl](user);
    };
    PEPageLoaderBlk pageLoader = ^ NSArray * (FPVehicle *lastVehicle) {
      return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];
    };
    PEWouldBeIndexOfEntity wouldBeIndexBlk = [self wouldBeIndexBlkForEqualityBlock:^(FPVehicle *v1, FPVehicle *v2){return [v1 isEqualToVehicle:v2];}
                                                                     entityFetcher:^{ return pageLoader(nil); }];
    PESyncViewStyler tableCellStyler = [PELMUIUtils syncViewStylerWithTitleBlk:^(FPVehicle *vehicle) {return [vehicle name];}
                                                        alwaysTopifyTitleLabel:NO
                                                                     uitoolkit:_uitoolkit
                                                          subtitleLeftHPadding:15.0
                                                      subtitleFitToWidthFactor:1.0
                                                                    isLoggedIn:[APP isUserLoggedIn]];
    return [[PEListViewController alloc] initWithClassOfDataSourceObjects:[FPVehicle class]
                                                                    title:@"Vehicles"
                                                    isPaginatedDataSource:NO
                                                          tableCellStyler:tableCellStyler
                                                       itemSelectedAction:nil
                                                      initialSelectedItem:nil
                                                            addItemAction:addVehicleAction
                                                           cellIdentifier:@"FPVehicleCell"
                                                           initialObjects:pageLoader(nil)
                                                               pageLoader:pageLoader
                                                        heightForCellsBlk:[self heightForCellsBlk]
                                                          detailViewMaker:vehicleDetailViewMaker
                                                                uitoolkit:_uitoolkit
                                           doesEntityBelongToThisListView:^BOOL(PELMMainSupport *entity){return YES;}
                                                     wouldBeIndexOfEntity:wouldBeIndexBlk
                                                          isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                           isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                      itemChildrenCounter:[self vehicleItemChildrenCounter]
                                                      itemChildrenMsgsBlk:[self vehicleItemChildrenMsgs]
                                                              itemDeleter:[self vehicleItemDeleterForUser:user]
                                                         itemLocalDeleter:[self vehicleItemLocalDeleter]];
  };
}

- (FPAuthScreenMaker)newViewUnsyncedVehiclesScreenMaker {
  return ^ UIViewController *(FPUser *user) {
    FPDetailViewMaker vehicleDetailViewMaker = ^UIViewController *(PEListViewController *listViewCtrl,
                                                                   id dataObject,
                                                                   NSIndexPath *indexPath,
                                                                   PEItemChangedBlk itemChangedBlk) {
      return [self newVehicleDetailScreenMakerWithVehicle:dataObject
                                         vehicleIndexPath:indexPath
                                           itemChangedBlk:itemChangedBlk
                                       listViewController:listViewCtrl](user);
    };
    PEPageLoaderBlk pageLoader = ^ NSArray * (FPVehicle *lastVehicle) {
      return [_coordDao unsyncedVehiclesForUser:user
                                          error:[FPUtils localFetchErrorHandlerMaker]()];
    };
    PEWouldBeIndexOfEntity wouldBeIndexBlk = [self wouldBeIndexBlkForEqualityBlock:^(FPVehicle *v1, FPVehicle *v2){return [v1 isEqualToVehicle:v2];}
                                                                     entityFetcher:^{ return pageLoader(nil); }];
    PESyncViewStyler tableCellStyler = [PELMUIUtils syncViewStylerWithTitleBlk:^(FPVehicle *vehicle) {return [vehicle name];}
                                                        alwaysTopifyTitleLabel:NO
                                                                     uitoolkit:_uitoolkit
                                                          subtitleLeftHPadding:15.0
                                                      subtitleFitToWidthFactor:1.0
                                                                    isLoggedIn:[APP isUserLoggedIn]];
    return [[PEListViewController alloc] initWithClassOfDataSourceObjects:[FPVehicle class]
                                                                    title:@"Unsynced Vehicles"
                                                    isPaginatedDataSource:NO
                                                          tableCellStyler:tableCellStyler
                                                       itemSelectedAction:nil
                                                      initialSelectedItem:nil
                                                            addItemAction:nil
                                                           cellIdentifier:@"FPVehicleCell"
                                                           initialObjects:pageLoader(nil)
                                                               pageLoader:pageLoader
                                                        heightForCellsBlk:[self heightForCellsBlk]
                                                          detailViewMaker:vehicleDetailViewMaker
                                                                uitoolkit:_uitoolkit
                                           doesEntityBelongToThisListView:^BOOL(PELMMainSupport *entity){return YES;}
                                                     wouldBeIndexOfEntity:wouldBeIndexBlk
                                                          isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                           isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                      itemChildrenCounter:[self vehicleItemChildrenCounter]
                                                      itemChildrenMsgsBlk:[self vehicleItemChildrenMsgs]
                                                              itemDeleter:[self vehicleItemDeleterForUser:user]
                                                         itemLocalDeleter:[self vehicleItemLocalDeleter]];
  };
}

- (FPAuthScreenMaker)newVehiclesForSelectionScreenMakerWithItemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                                                       initialSelectedVehicle:(FPVehicle *)initialSelectedVehicle {
  return ^ UIViewController *(FPUser *user) {
    void (^addVehicleAction)(PEListViewController *, PEItemAddedBlk) =
    ^(PEListViewController *listViewCtrlr, PEItemAddedBlk itemAddedBlk) {
      UIViewController *addVehicleScreen =
        [self newAddVehicleScreenMakerWithDelegate:itemAddedBlk
                                listViewController:listViewCtrlr](user);
      [listViewCtrlr presentViewController:[PEUIUtils navigationControllerWithController:addVehicleScreen
                                                                     navigationBarHidden:NO]
                                  animated:YES
                                completion:nil];
    };
    PEPageLoaderBlk pageLoader = ^ NSArray * (FPVehicle *lastVehicle) {
      return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];
    };
    PEWouldBeIndexOfEntity wouldBeIndexBlk = [self wouldBeIndexBlkForEqualityBlock:^(FPVehicle *v1, FPVehicle *v2){return [v1 isEqualToVehicle:v2];}
                                                                     entityFetcher:^{ return pageLoader(nil); }];
    PESyncViewStyler tableCellStyler = [PELMUIUtils syncViewStylerWithTitleBlk:^(FPVehicle *vehicle) {return [vehicle name];}
                                                        alwaysTopifyTitleLabel:NO
                                                                     uitoolkit:_uitoolkit
                                                          subtitleLeftHPadding:15.0
                                                      subtitleFitToWidthFactor:1.0
                                                                    isLoggedIn:[APP isUserLoggedIn]];
    return [[PEListViewController alloc] initWithClassOfDataSourceObjects:[FPVehicle class]
                                                                    title:@"Choose Vehicle"
                                                    isPaginatedDataSource:NO
                                                          tableCellStyler:tableCellStyler
                                                       itemSelectedAction:itemSelectedAction
                                                      initialSelectedItem:initialSelectedVehicle
                                                            addItemAction:addVehicleAction
                                                           cellIdentifier:@"FPVehicleCell"
                                                           initialObjects:pageLoader(nil)
                                                               pageLoader:pageLoader
                                                        heightForCellsBlk:[self heightForCellsBlk]
                                                          detailViewMaker:nil
                                                                uitoolkit:_uitoolkit
                                           doesEntityBelongToThisListView:^BOOL(PELMMainSupport *entity){return YES;}
                                                     wouldBeIndexOfEntity:wouldBeIndexBlk
                                                          isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                           isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                      itemChildrenCounter:nil
                                                      itemChildrenMsgsBlk:nil
                                                              itemDeleter:nil
                                                         itemLocalDeleter:nil];
  };
}

- (PEEntityValidatorBlk)newVehicleValidator {
  return ^NSArray *(UIView *vehiclePanel) {
    NSMutableArray *errMsgs = [NSMutableArray array];
    PEMessageCollector cannotBeBlankCollector =
      [PEUIUtils newTfCannotBeEmptyBlkForMsgs:errMsgs entityPanel:vehiclePanel];
    cannotBeBlankCollector(FPVehicleTagName, @"Name cannot be empty.");
    return errMsgs;
  };
}

- (FPAuthScreenMaker)newAddVehicleScreenMakerWithDelegate:(PEItemAddedBlk)itemAddedBlk
                                       listViewController:(PEListViewController *)listViewController {
  return ^ UIViewController * (FPUser *user) {
    PESaveNewEntityLocalBlk newVehicleSaverLocal = ^NSArray *(UIView *entityPanel, FPVehicle *newVehicle) {
      [_coordDao saveNewVehicle:newVehicle forUser:user error:[FPUtils localSaveErrorHandlerMaker]()];
      [APP refreshTabs];
      return @[@"Vehicle saved.", @[@"Vehicle saved locally."]];
    };
    PESaveNewEntityImmediateSyncBlk newVehicleSaverImmediateSync = ^(UIView *entityPanel,
                                                                     FPVehicle *newVehicle,
                                                                     PESyncNotFoundBlk notFoundBlk,
                                                                     PESyncSuccessBlk successBlk,
                                                                     PESyncRetryAfterBlk retryAfterBlk,
                                                                     PESyncServerTempErrorBlk tempErrBlk,
                                                                     PESyncServerErrorBlk errBlk,
                                                                     PESyncConflictBlk conflictBlk,
                                                                     PESyncAuthRequiredBlk authReqdBlk,
                                                                     PESyncDependencyUnsynced depUnsyncedBlk) {
      NSString *mainMsgFragment = @"saving vehicle to the server";
      NSString *recordTitle = @"Vehicle";
      [_coordDao saveNewAndSyncImmediateVehicle:newVehicle
                                        forUser:user
                            notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                 addlSuccessBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                         addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                         addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                             addlRemoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeSaveVehicleErrMsgs:errMask]); [APP refreshTabs];}
                                addlConflictBlk:^(FPVehicle *latestVehicle) {conflictBlk(1, mainMsgFragment, recordTitle, latestVehicle); [APP refreshTabs];}
                            addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                          error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEPrepareUIForUserInteractionBlk prepareUIForUserInteractionBlk = ^(PEAddViewEditController *ctrl, UIView *entityPanel) {
      if (![ctrl hasPoppedKeyboard]) {
        UITextField *vehicleNameTf = (UITextField *)[entityPanel viewWithTag:FPVehicleTagName];
        [vehicleNameTf becomeFirstResponder];
        [ctrl setHasPoppedKeyboard:YES];
      }
    };
    PEEntityAddCancelerBlk addCanceler = ^(PEAddViewEditController *ctrl, BOOL dismissCtrlr, FPVehicle *newVehicle) {
      if (newVehicle && [newVehicle localMainIdentifier]) {
        // delete the unwanted record (probably from when user attempt to sync it, got an app error, and chose to 'forget it, cancel')
        [newVehicle setEditInProgress:YES];
        [_coordDao cancelEditOfVehicle:newVehicle
                                 error:[FPUtils localSaveErrorHandlerMaker]()];
        [APP refreshTabs];
      }
      if (dismissCtrlr) {
        [[ctrl navigationController] dismissViewControllerAnimated:YES completion:nil];
      }
    };
    PEAddlContentSection addlContentSection = ^(PEAddViewEditController *ctrl, UIView *entityFormPanel, FPVehicle *newVehicle) {
      NSString *infoText;
      if ([[_coordDao fuelStationsForUser:user error:[FPUtils localFetchErrorHandlerMaker]()] count] == 0) {
        infoText = @"You can now create gas and odometer logs for this vehicle.  When creating your first gas log, you'll need to create the gas station record for it too.";
      } else {
        infoText = @"You can now create gas and odometer logs for this vehicle.";
      }
      return [PEUIUtils infoAlertSectionWithTitle:@"Tip"
                                 alertDescription:[[NSAttributedString alloc] initWithString:infoText]
                                   relativeToView:ctrl.view];
    };
    return [PEAddViewEditController addEntityCtrlrWithUitoolkit:_uitoolkit
                                             listViewController:listViewController
                                                   itemAddedBlk:itemAddedBlk
                                           entityFormPanelMaker:[_panelToolkit vehicleFormPanelMakerIncludeLogButtons:NO]
                                            entityToPanelBinder:[_panelToolkit vehicleToVehiclePanelBinder]
                                            panelToEntityBinder:[_panelToolkit vehicleFormPanelToVehicleBinder]
                                                    entityTitle:@"Vehicle"
                                              entityAddCanceler:addCanceler
                                                    entityMaker:[_panelToolkit vehicleMaker]
                                            newEntitySaverLocal:newVehicleSaverLocal
                                    newEntitySaverImmediateSync:newVehicleSaverImmediateSync
                                 prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                               viewDidAppearBlk:nil
                                                entityValidator:[self newVehicleValidator]
                                                isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                 isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                  isOfflineMode:^{ return [APP offlineMode]; }
                                 syncImmediateMBProgressHUDMode:MBProgressHUDModeIndeterminate
                                          modalOperationStarted:[self commonModalOperationStartedBlock]
                                             modalOperationDone:[self commonModalOperationDoneBlock]
                                    entityAddedNotificationName:FPEntityAddedNotification
                                             addlContentSection:addlContentSection];
  };
}

- (FPAuthScreenMaker)newVehicleDetailScreenMakerWithVehicle:(FPVehicle *)vehicle
                                           vehicleIndexPath:(NSIndexPath *)vehicleIndexPath
                                             itemChangedBlk:(PEItemChangedBlk)itemChangedBlk
                                         listViewController:(PEListViewController *)listViewController {
  return ^ UIViewController * (FPUser *user) {
    PEEntityEditPreparerBlk vehicleEditPreparer = ^BOOL(PEAddViewEditController *ctrl, FPVehicle *vehicle) {
      BOOL prepareSuccess = [_coordDao prepareVehicleForEdit:vehicle
                                                     forUser:user
                                                       error:[FPUtils localSaveErrorHandlerMaker]()];
      [APP refreshTabs];
      return prepareSuccess;
    };
    PEEntityEditCancelerBlk vehicleEditCanceler = ^(PEAddViewEditController *ctrl, FPVehicle *vehicle) {
      [_coordDao cancelEditOfVehicle:vehicle error:[FPUtils localSaveErrorHandlerMaker]()];
      [APP refreshTabs];
    };
    PESaveEntityBlk vehicleSaver = ^(PEAddViewEditController *ctrl, FPVehicle *vehicle) {
      [_coordDao saveVehicle:vehicle error:[FPUtils localSaveErrorHandlerMaker]()];
      [APP refreshTabs];
    };
    PEMarkAsDoneEditingLocalBlk doneEditingVehicleLocal = ^(PEAddViewEditController *ctrl, FPVehicle *vehicle) {
      [_coordDao markAsDoneEditingVehicle:vehicle error:[FPUtils localSaveErrorHandlerMaker]()];
      [APP refreshTabs];
    };
    PEMarkAsDoneEditingImmediateSyncBlk doneEditingVehicleImmediateSync = ^(PEAddViewEditController *ctrl,
                                                                            FPVehicle *vehicle,
                                                                            PESyncNotFoundBlk notFoundBlk,
                                                                            PESyncSuccessBlk successBlk,
                                                                            PESyncRetryAfterBlk retryAfterBlk,
                                                                            PESyncServerTempErrorBlk tempErrBlk,
                                                                            PESyncServerErrorBlk errBlk,
                                                                            PESyncConflictBlk conflictBlk,
                                                                            PESyncAuthRequiredBlk authReqdBlk,
                                                                            PESyncDependencyUnsynced depUnsyncedBlk) {
      NSString *mainMsgFragment = @"saving vehicle to the server";
      NSString *recordTitle = @"Vehicle";
      [_coordDao markAsDoneEditingAndSyncVehicleImmediate:vehicle
                                                  forUser:user
                                      notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                           addlSuccessBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                   addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                                   addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                       addlRemoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeSaveVehicleErrMsgs:errMask]); [APP refreshTabs];}
                                          addlConflictBlk:^(FPVehicle *latestVehicle) {conflictBlk(1, mainMsgFragment, recordTitle, latestVehicle); [APP refreshTabs];}
                                      addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                    error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEUploaderBlk uploader = ^(PEAddViewEditController *ctrl,
                               FPVehicle *vehicle,
                               PESyncNotFoundBlk notFoundBlk,
                               PESyncSuccessBlk successBlk,
                               PESyncRetryAfterBlk retryAfterBlk,
                               PESyncServerTempErrorBlk tempErrBlk,
                               PESyncServerErrorBlk errBlk,
                               PESyncConflictBlk conflictBlk,
                               PESyncAuthRequiredBlk authReqdBlk,
                               PESyncDependencyUnsynced depUnsyncedBlk) {
      NSString *mainMsgFragment = @"saving vehicle to the server";
      NSString *recordTitle = @"Vehicle";
      [_coordDao flushUnsyncedChangesToVehicle:vehicle
                                       forUser:user
                           notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                addlSuccessBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs]; }
                        addlRemoteStoreBusyBlk:^(NSDate *retryAfter){retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                        addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                            addlRemoteErrorBlk:^(NSInteger errMask){errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeSaveVehicleErrMsgs:errMask]); [APP refreshTabs];}
                               addlConflictBlk:^(FPVehicle *latestVehicle) {conflictBlk(1, mainMsgFragment, recordTitle, latestVehicle); [APP refreshTabs];}
                           addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                         error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEPrepareUIForUserInteractionBlk prepareUIForUserInteractionBlk = ^(PEAddViewEditController *ctrl, UIView *entityPanel) {
      if (![ctrl hasPoppedKeyboard]) {
        UITextField *vehicleNameTf = (UITextField *)[entityPanel viewWithTag:FPVehicleTagName];
        [vehicleNameTf becomeFirstResponder];
        [ctrl setHasPoppedKeyboard:YES];
      }
    };
    PEMergeBlk mergeBlk = ^ NSDictionary * (PEAddViewEditController *ctrl, FPVehicle *localVehicle, FPVehicle *remoteVehicle) {
      FPVehicle *masterVehicle = [_coordDao masterVehicleWithId:[localVehicle localMasterIdentifier]
                                                          error:[FPUtils localFetchErrorHandlerMaker]()];
      return [FPVehicle mergeRemoteVehicle:remoteVehicle withLocalVehicle:localVehicle localMasterVehicle:masterVehicle];
    };
    PEConflictResolveFields conflictResolveFieldsBlk = ^(PEAddViewEditController *ctrl,
                                                         NSDictionary *mergeConflicts,
                                                         FPVehicle *localVehicle,
                                                         FPVehicle *remoteVehicle) {
      NSMutableArray *fields = [NSMutableArray arrayWithCapacity:mergeConflicts.count];
      [mergeConflicts enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *fieldName = key;
        if ([fieldName isEqualToString:FPVehicleNameField]) {
          [fields addObject:@[@"Name:", @(FPVehicleTagName), [PEUtils emptyIfNil:[localVehicle name]], [PEUtils emptyIfNil:[remoteVehicle name]]]];
        } else if ([fieldName isEqualToString:FPVehicleIsDieselField]) {
          [fields addObject:@[@"Takes diesel?:", @(FPVehicleTagTakesDieselSwitch), [PEUtils yesNoFromBool:[localVehicle isDiesel]], [PEUtils yesNoFromBool:[remoteVehicle isDiesel]]]];
        } else if ([fieldName isEqualToString:FPVehicleDefaultOctaneField]) {
          [fields addObject:@[@"Default octane:", @(FPVehicleTagDefaultOctane), [PEUtils descriptionOrEmptyIfNil:[localVehicle defaultOctane]], [PEUtils descriptionOrEmptyIfNil:[remoteVehicle defaultOctane]]]];
        } else if ([fieldName isEqualToString:FPVehicleFuelCapacityField]) {
          [fields addObject:@[@"Fuel capacity:", @(FPVehicleTagFuelCapacity), [PEUtils descriptionOrEmptyIfNil:[localVehicle fuelCapacity]], [PEUtils descriptionOrEmptyIfNil:[remoteVehicle fuelCapacity]]]];
        } else if ([fieldName isEqualToString:FPVehicleHasDteReadoutField]) {
          [fields addObject:@[@"Has range readout?:", @(FPVehicleTagHasDteReadoutSwitch), [PEUtils yesNoFromBool:[localVehicle hasDteReadout]], [PEUtils yesNoFromBool:[remoteVehicle hasDteReadout]]]];
        } else if ([fieldName isEqualToString:FPVehicleHasMpgReadoutField]) {
          [fields addObject:@[@"Has avg MPG readout?:", @(FPVehicleTagHasMpgReadoutSwitch), [PEUtils yesNoFromBool:[localVehicle hasMpgReadout]], [PEUtils yesNoFromBool:[remoteVehicle hasMpgReadout]]]];
        } else if ([fieldName isEqualToString:FPVehicleHasMphReadoutField]) {
          [fields addObject:@[@"Has avg MPH readout?:", @(FPVehicleTagHasMphReadoutSwitch), [PEUtils yesNoFromBool:[localVehicle hasMphReadout]], [PEUtils yesNoFromBool:[remoteVehicle hasMphReadout]]]];
        } else if ([fieldName isEqualToString:FPVehicleHasOutsideTempReadoutField]) {
          [fields addObject:@[@"Has outside temp. readout?:", @(FPVehicleTagHasOutsideTempReadoutSwitch), [PEUtils yesNoFromBool:[localVehicle hasOutsideTempReadout]], [PEUtils yesNoFromBool:[remoteVehicle hasOutsideTempReadout]]]];
        } else if ([fieldName isEqualToString:FPVehicleVinField]) {
          [fields addObject:@[@"VIN:", @(FPVehicleTagVin), [PEUtils descriptionOrEmptyIfNil:[localVehicle vin]], [PEUtils descriptionOrEmptyIfNil:[remoteVehicle vin]]]];
        } else if ([fieldName isEqualToString:FPVehiclePlateField]) {
          [fields addObject:@[@"Plate #:", @(FPVehicleTagPlate), [PEUtils descriptionOrEmptyIfNil:[localVehicle plate]], [PEUtils descriptionOrEmptyIfNil:[remoteVehicle plate]]]];
        }
      }];
      return fields;
    };
    PEConflictResolvedEntity conflictResolvedEntityBlk = ^ id (PEAddViewEditController *ctrl,
                                                               NSDictionary *mergeConflicts,
                                                               NSArray *valueLabels,
                                                               FPVehicle *localVehicle,
                                                               FPVehicle *remoteVehicle) {
      FPVehicle *resolvedVehicle = [localVehicle copy];
      NSInteger numValueLabels = [valueLabels count];
      for (int i = 0; i < numValueLabels; i++) {
        NSArray *valueLabelPair = valueLabels[i];
        UILabel *remoteValue = valueLabelPair[1];
        if (remoteValue.tag > 0) {
          switch (remoteValue.tag) {
            case FPVehicleTagName:
              [resolvedVehicle setName:[remoteVehicle name]];
              break;
            case FPVehicleTagDefaultOctane:
              [resolvedVehicle setDefaultOctane:[remoteVehicle defaultOctane]];
              break;
            case FPVehicleTagFuelCapacity:
              [resolvedVehicle setFuelCapacity:[remoteVehicle fuelCapacity]];
              break;
            case FPVehicleTagTakesDieselSwitch:
              [resolvedVehicle setIsDiesel:[remoteVehicle isDiesel]];
              break;
            case FPVehicleTagVin:
              [resolvedVehicle setVin:[remoteVehicle vin]];
              break;
            case FPVehicleTagPlate:
              [resolvedVehicle setPlate:[remoteVehicle plate]];
              break;
            case FPVehicleTagHasDteReadoutSwitch:
              [resolvedVehicle setHasDteReadout:[remoteVehicle hasDteReadout]];
              break;
            case FPVehicleTagHasMpgReadoutSwitch:
              [resolvedVehicle setHasMpgReadout:[remoteVehicle hasMpgReadout]];
              break;
            case FPVehicleTagHasMphReadoutSwitch:
              [resolvedVehicle setHasMphReadout:[remoteVehicle hasMphReadout]];
              break;
            case FPVehicleTagHasOutsideTempReadoutSwitch:
              [resolvedVehicle setHasOutsideTempReadout:[remoteVehicle hasOutsideTempReadout]];
              break;
          }
        }
      }
      return resolvedVehicle;
    };
    PEDownloaderBlk downloaderBlk = ^ (PEAddViewEditController *ctrl,
                                       FPVehicle *vehicle,
                                       PESyncNotFoundBlk notFoundBlk,
                                       PEDownloadSuccessBlk successBlk,
                                       PESyncRetryAfterBlk retryAfterBlk,
                                       PESyncServerTempErrorBlk tempErrBlk,
                                       PESyncAuthRequiredBlk authReqdBlk) {
      NSString *mainMsgFragment = @"fetching vehicle";
      NSString *recordTitle = @"Vehicle";
      float percentOfFetching = 1.0;
      [_coordDao fetchVehicleWithGlobalId:[vehicle globalIdentifier]
                          ifModifiedSince:[vehicle updatedAt]
                                  forUser:user
                      notFoundOnServerBlk:^{notFoundBlk(percentOfFetching, mainMsgFragment, recordTitle);}
                               successBlk:^(FPVehicle *fetchedVehicle) {successBlk(percentOfFetching, mainMsgFragment, recordTitle, fetchedVehicle);}
                       remoteStoreBusyBlk:^(NSDate *retryAfter){retryAfterBlk(percentOfFetching, mainMsgFragment, recordTitle, retryAfter);}
                       tempRemoteErrorBlk:^{tempErrBlk(percentOfFetching, mainMsgFragment, recordTitle);}
                      addlAuthRequiredBlk:^{authReqdBlk(percentOfFetching, mainMsgFragment, recordTitle); [APP refreshTabs];}];
    };
    PEPostDownloaderSaver postDownloadSaverBlk = ^ (PEAddViewEditController *ctrl,
                                                    FPVehicle *downloadedVehicle,
                                                    FPVehicle *vehicle) {
      [_coordDao saveMasterVehicle:downloadedVehicle forUser:user error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEViewDidAppearBlk viewDidAppearBlk = ^(PEAddViewEditController *ctrl) {
      UIButton *viewFplogsBtn = (UIButton *)[ctrl.view viewWithTag:FPVehicleTagViewFplogsBtn];
      [PEUIUtils refreshRecordCountLabelOnButton:viewFplogsBtn
                             recordCountLabelTag:FPVehicleTagViewFplogsBtnRecordCount
                                     recordCount:[_coordDao numFuelPurchaseLogsForVehicle:vehicle error:[FPUtils localFetchErrorHandlerMaker]()]];
      UIButton *viewEnvlogsBtn = (UIButton *)[ctrl.view viewWithTag:FPVehicleTagViewEnvlogsBtn];
      [PEUIUtils refreshRecordCountLabelOnButton:viewEnvlogsBtn
                             recordCountLabelTag:FPVehicleTagViewEnvlogsBtnRecordCount
                                     recordCount:[_coordDao numEnvironmentLogsForVehicle:vehicle error:[FPUtils localFetchErrorHandlerMaker]()]];
    };
    return [PEAddViewEditController viewEntityCtrlrWithParentEntity:user
                                                             entity:vehicle
                                                 listViewController:listViewController
                                                    entityIndexPath:vehicleIndexPath
                                                          uitoolkit:_uitoolkit
                                                     itemChangedBlk:itemChangedBlk
                                               entityFormPanelMaker:[_panelToolkit vehicleFormPanelMakerIncludeLogButtons:YES]
                                               entityViewPanelMaker:[_panelToolkit vehicleViewPanelMaker]
                                                entityToPanelBinder:[_panelToolkit vehicleToVehiclePanelBinder]
                                                panelToEntityBinder:[_panelToolkit vehicleFormPanelToVehicleBinder]
                                                        entityTitle:@"Vehicle"
                                               panelEnablerDisabler:[_panelToolkit vehicleFormPanelEnablerDisabler]
                                                  entityAddCanceler:nil
                                                 entityEditPreparer:vehicleEditPreparer
                                                 entityEditCanceler:vehicleEditCanceler
                                                        entitySaver:vehicleSaver
                                             doneEditingEntityLocal:doneEditingVehicleLocal
                                     doneEditingEntityImmediateSync:doneEditingVehicleImmediateSync
                                                    isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                     isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                      isOfflineMode:^{ return [APP offlineMode]; }
                                     syncImmediateMBProgressHUDMode:MBProgressHUDModeIndeterminate
                                     prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                                   viewDidAppearBlk:viewDidAppearBlk
                                                    entityValidator:[self newVehicleValidator]
                                                           uploader:uploader
                                              numRemoteDepsNotLocal:nil
                                                              merge:mergeBlk
                                                  fetchDependencies:nil
                                                    updateDepsPanel:nil
                                                         downloader:downloaderBlk
                                                  postDownloadSaver:postDownloadSaverBlk
                                              conflictResolveFields:conflictResolveFieldsBlk
                                             conflictResolvedEntity:conflictResolvedEntityBlk
                                                itemChildrenCounter:[self vehicleItemChildrenCounter]
                                                itemChildrenMsgsBlk:[self vehicleItemChildrenMsgs]
                                                        itemDeleter:[self vehicleItemDeleterForUser:user]
                                                   itemLocalDeleter:[self vehicleItemLocalDeleter]
                                              modalOperationStarted:[self commonModalOperationStartedBlock]
                                                 modalOperationDone:[self commonModalOperationDoneBlock]
                                      entityUpdatedNotificationName:FPEntityUpdatedNotification
                                      entityRemovedNotificationName:FPEntityDeletedNotification];
  };
}

#pragma mark - Vehicle Stat Screens

- (FPAuthScreenMaker)newVehicleStatsLaunchScreenMakerWithVehicle:(FPVehicle *)vehicle
                                                parentController:(UIViewController *)parentController {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatsLaunchController alloc] initWithScreenTitle:@"Vehicle Stats & Trends"
                                                  entityTypeLabelText:@"VEHICLE"
                                                        entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                               entity:vehicle
                                                 statLaunchButtonsBlk:^{
                                                   NSMutableArray *statLaunchButtons = [NSMutableArray array];
                                                   [statLaunchButtons addObject:@"DAYS BETWEEN FILL-UPS"];
                                                   [statLaunchButtons addObject:@[^UIView *(void) {
                                                     return [PEUIUtils tablePanelWithRowData:@[@[@"Days since last fill-up",
                                                                                                 [self formattedValueForValue:[_stats daysSinceLastGasLogForVehicle:vehicle]
                                                                                                                    formatter:^NSString *(id val) { return [_generalFormatter stringFromNumber:val]; }]]]
                                                                                   uitoolkit:_uitoolkit
                                                                                  parentView:parentController.view];
                                                   }]];
                                                   [statLaunchButtons addObject:@[@"Avg days between fill-ups",
                                                                                  ^{ return [self newVehicleAvgDaysBetweenFillupsStatsScreenMakerWithVehicle:vehicle](user); }]];
                                                   [statLaunchButtons addObject:@[@"Max days between fill-ups",
                                                                                  ^{ return [self newVehicleMaxDaysBetweenFillupsStatsScreenMakerWithVehicle:vehicle](user); }]];
                                                   [statLaunchButtons addObject:@"COST PER MILE"];
                                                   [statLaunchButtons addObject:@[@"Gas cost/mile",
                                                                                  ^{ return [self newVehicleGasCostPerMileStatsScreenMakerWithVehicle:vehicle](user); }]];
                                                   [statLaunchButtons addObject:@"MILES PER GALLON"];
                                                   [statLaunchButtons addObject:@[@"Avg MPG",
                                                                                  ^{ return [self newVehicleAvgReportedMpgStatsScreenMakerWithVehicle:vehicle](user); }]];
                                                   [statLaunchButtons addObject:@[@"Max MPG",
                                                                                  ^{ return [self newVehicleMaxReportedMpgStatsScreenMakerWithVehicle:vehicle](user); }]];
                                                   [statLaunchButtons addObject:@[@"Min MPG",
                                                                                  ^{ return [self newVehicleMinReportedMpgStatsScreenMakerWithVehicle:vehicle](user); }]];
                                                   [statLaunchButtons addObject:@"MILES PER HOUR"];
                                                   [statLaunchButtons addObject:@[@"Avg MPH",
                                                                                  ^{ return [self newVehicleAvgReportedMphStatsScreenMakerWithVehicle:vehicle](user); }]];
                                                   [statLaunchButtons addObject:@[@"Max MPH",
                                                                                  ^{ return [self newVehicleMaxReportedMphStatsScreenMakerWithVehicle:vehicle](user); }]];
                                                   [statLaunchButtons addObject:@[@"Min MPH",
                                                                                  ^{ return [self newVehicleMinReportedMphStatsScreenMakerWithVehicle:vehicle](user); }]];
                                                   [statLaunchButtons addObject:@"GAS SPEND"];
                                                   [statLaunchButtons addObject:@[@"Total amount spent",
                                                                                  ^{ return [self newVehicleSpentOnGasStatsScreenMakerWithVehicle:vehicle](user); }]];
                                                   [statLaunchButtons addObject:@[@"Avg monthly spend",
                                                                                  ^{ return [self newVehicleAvgSpentOnGasStatsScreenMakerWithVehicle:vehicle](user); }]];
                                                   [statLaunchButtons addObject:@[@"Min monthly spend",
                                                                                  ^{ return [self newVehicleMinSpentOnGasStatsScreenMakerWithVehicle:vehicle](user); }]];
                                                   [statLaunchButtons addObject:@[@"Max monthly spend",
                                                                                  ^{ return [self newVehicleMaxSpentOnGasStatsScreenMakerWithVehicle:vehicle](user); }]];
                                                   NSArray *octanes = [_coordDao distinctOctanesForVehicle:vehicle error:_errorBlk];
                                                   for (NSNumber *octane in octanes) {
                                                     [statLaunchButtons addObject:[NSString stringWithFormat:@"%@ OCTANE - PRICE STATS", octane]];
                                                     [statLaunchButtons addObject:@[[NSString stringWithFormat:@"Avg price of %@", octane],
                                                                                    ^{ return [self newVehicleAvgPricePerGallonStatsScreenMakerWithVehicle:vehicle octane:octane](user); }]];
                                                     [statLaunchButtons addObject:@[[NSString stringWithFormat:@"Min price of %@", octane],
                                                                                    ^{ return [self newVehicleMinPricePerGallonStatsScreenMakerWithVehicle:vehicle octane:octane](user); }]];
                                                     [statLaunchButtons addObject:@[[NSString stringWithFormat:@"Max price of %@", octane],
                                                                                    ^{ return [self newVehicleMaxPricePerGallonStatsScreenMakerWithVehicle:vehicle octane:octane](user); }]];
                                                   }
                                                   if ([_coordDao hasDieselLogsForVehicle:vehicle error:_errorBlk]) {
                                                     [statLaunchButtons addObject:@"DIESEL - PRICE STATS"];
                                                     [statLaunchButtons addObject:@[@"Avg price of diesel",
                                                                                    ^{ return [self newAvgPricePerDieselGallonStatsScreenMakerWithVehicle:vehicle](user); }]];
                                                   }
                                                   return statLaunchButtons;
                                                 }
                                                            uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newAvgPricePerDieselGallonStatsScreenMakerWithVehicle:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:[NSString stringWithFormat:@"Avg Price of Diesel"]
                                           entityTypeLabelText:@"ALL DIESEL VEHICLES"
                                                 entityNameBlk:nil
                                                        entity:user
                                          aggregatesHeaderText:[NSString stringWithFormat:@"AVG PRICE OF DIESEL"]
                                        compareButtonTitleText:@"Compare diesel vehicles"
                                           alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallAvgPricePerDieselGallonForVehicle:v];}
                                        yearToDateAggregateBlk:^(FPVehicle *v) {return [_stats yearToDateAvgPricePerDieselGallonForVehicle:v];}
                                          lastYearAggregateBlk:^(FPVehicle *v) {return [_stats lastYearAvgPricePerDieselGallonForVehicle:v];}
                                             alltimeDatasetBlk:^(FPVehicle *v) {return [_stats overallAvgPricePerDieselGallonDataSetForVehicle:v];}
                                          yearToDateDatasetBlk:^(FPVehicle *v) {return [_stats yearToDateAvgPricePerDieselGallonDataSetForVehicle:v];}
                                            lastYearDatasetBlk:^(FPVehicle *v) {return [_stats lastYearAvgPricePerDieselGallonDataSetForVehicle:v];}
                                               siblingCountBlk:^{return [_coordDao dieselVehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareAvgPricePerDieselGallonStatsScreenMakerWithVehicleInCtx:vehicle](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleCompareAvgPricePerDieselGallonStatsScreenMakerWithVehicleInCtx:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:[NSString stringWithFormat:@"Avg Price of Diesel Comparison"]
                                                              headerText:[NSString stringWithFormat:@"AVG PRICE OF DIESEL (All time)"]
                                                           entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                                  entity:vehicle
                                                    entitiesToCompareBlk:^{return [_coordDao dieselVehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallAvgPricePerDieselGallonForVehicle:v];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v1 compare:v2]; // ascending
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleMinReportedMphStatsScreenMakerWithVehicle:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Min MPH"
                                           entityTypeLabelText:@"VEHICLE"
                                                 entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                        entity:vehicle
                                          aggregatesHeaderText:@"MIN MPH"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallMinReportedMphForVehicle:v];}
                                        yearToDateAggregateBlk:^(FPVehicle *v) {return [_stats yearToDateMinReportedMphForVehicle:v];}
                                          lastYearAggregateBlk:^(FPVehicle *v) {return [_stats lastYearMinReportedMphForVehicle:v];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareMinReportedMphStatsScreenMakerWithVehicleInCtx:vehicle](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_generalFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleCompareMinReportedMphStatsScreenMakerWithVehicleInCtx:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:@"Min MPH Comparison"
                                                              headerText:@"MIN MPH (all time)"
                                                           entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                                  entity:vehicle
                                                    entitiesToCompareBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallMinReportedMphForVehicle:v];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_generalFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v1 compare:v2];
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleMaxReportedMphStatsScreenMakerWithVehicle:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Max MPH"
                                           entityTypeLabelText:@"VEHICLE"
                                                 entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                        entity:vehicle
                                          aggregatesHeaderText:@"MAX MPH"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallMaxReportedMphForVehicle:v];}
                                        yearToDateAggregateBlk:^(FPVehicle *v) {return [_stats yearToDateMaxReportedMphForVehicle:v];}
                                          lastYearAggregateBlk:^(FPVehicle *v) {return [_stats lastYearMaxReportedMphForVehicle:v];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareMaxReportedMphStatsScreenMakerWithVehicleInCtx:vehicle](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_generalFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleCompareMaxReportedMphStatsScreenMakerWithVehicleInCtx:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:@"Max MPH Comparison"
                                                              headerText:@"MAX MPH (all time)"
                                                           entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                                  entity:vehicle
                                                    entitiesToCompareBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallMaxReportedMphForVehicle:v];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_generalFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v2 compare:v1]; // descending
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleAvgReportedMphStatsScreenMakerWithVehicle:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Avg MPH"
                                           entityTypeLabelText:@"VEHICLE"
                                                 entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                        entity:vehicle
                                          aggregatesHeaderText:@"AVG MPH"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallAvgReportedMphForVehicle:v];}
                                        yearToDateAggregateBlk:^(FPVehicle *v) {return [_stats yearToDateAvgReportedMphForVehicle:v];}
                                          lastYearAggregateBlk:^(FPVehicle *v) {return [_stats lastYearAvgReportedMphForVehicle:v];}
                                             alltimeDatasetBlk:^(FPVehicle *v) {return [_stats overallAvgReportedMphDataSetForVehicle:v];}
                                          yearToDateDatasetBlk:^(FPVehicle *v) {return [_stats yearToDateAvgReportedMphDataSetForVehicle:v];}
                                            lastYearDatasetBlk:^(FPVehicle *v) {return [_stats lastYearAvgReportedMphDataSetForVehicle:v];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareAvgReportedMphStatsScreenMakerWithVehicleInCtx:vehicle](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_generalFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleCompareAvgReportedMphStatsScreenMakerWithVehicleInCtx:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:@"Avg MPH Comparison"
                                                              headerText:@"AVG MPH (All time)"
                                                           entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                                  entity:vehicle
                                                    entitiesToCompareBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallAvgReportedMphForVehicle:v];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_generalFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v2 compare:v1]; // descending
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleMinReportedMpgStatsScreenMakerWithVehicle:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Min MPG"
                                           entityTypeLabelText:@"VEHICLE"
                                                 entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                        entity:vehicle
                                          aggregatesHeaderText:@"MIN MPG"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallMinReportedMpgForVehicle:v];}
                                        yearToDateAggregateBlk:^(FPVehicle *v) {return [_stats yearToDateMinReportedMpgForVehicle:v];}
                                          lastYearAggregateBlk:^(FPVehicle *v) {return [_stats lastYearMinReportedMpgForVehicle:v];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareMinReportedMpgStatsScreenMakerWithVehicleInCtx:vehicle](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_generalFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleCompareMinReportedMpgStatsScreenMakerWithVehicleInCtx:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:@"Min MPG Comparison"
                                                              headerText:@"MIN MPG (all time)"
                                                           entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                                  entity:vehicle
                                                    entitiesToCompareBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallMinReportedMpgForVehicle:v];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_generalFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v1 compare:v2];
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleMaxReportedMpgStatsScreenMakerWithVehicle:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Max MPG"
                                           entityTypeLabelText:@"VEHICLE"
                                                 entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                        entity:vehicle
                                          aggregatesHeaderText:@"MAX MPG"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallMaxReportedMpgForVehicle:v];}
                                        yearToDateAggregateBlk:^(FPVehicle *v) {return [_stats yearToDateMaxReportedMpgForVehicle:v];}
                                          lastYearAggregateBlk:^(FPVehicle *v) {return [_stats lastYearMaxReportedMpgForVehicle:v];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareMaxReportedMpgStatsScreenMakerWithVehicleInCtx:vehicle](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_generalFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleCompareMaxReportedMpgStatsScreenMakerWithVehicleInCtx:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:@"Max MPG Comparison"
                                                              headerText:@"MAX MPG (all time)"
                                                           entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                                  entity:vehicle
                                                    entitiesToCompareBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallMaxReportedMpgForVehicle:v];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_generalFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v2 compare:v1]; // descending
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleAvgReportedMpgStatsScreenMakerWithVehicle:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Avg MPG"
                                           entityTypeLabelText:@"VEHICLE"
                                                 entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                        entity:vehicle
                                          aggregatesHeaderText:@"AVG MPG"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallAvgReportedMpgForVehicle:v];}
                                        yearToDateAggregateBlk:^(FPVehicle *v) {return [_stats yearToDateAvgReportedMpgForVehicle:v];}
                                          lastYearAggregateBlk:^(FPVehicle *v) {return [_stats lastYearAvgReportedMpgForVehicle:v];}
                                             alltimeDatasetBlk:^(FPVehicle *v) {return [_stats overallAvgReportedMpgDataSetForVehicle:v];}
                                          yearToDateDatasetBlk:^(FPVehicle *v) {return [_stats yearToDateAvgReportedMpgDataSetForVehicle:v];}
                                            lastYearDatasetBlk:^(FPVehicle *v) {return [_stats lastYearAvgReportedMpgDataSetForVehicle:v];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareAvgReportedMpgStatsScreenMakerWithVehicleInCtx:vehicle](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_generalFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleCompareAvgReportedMpgStatsScreenMakerWithVehicleInCtx:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:@"Avg MPG Comparison"
                                                              headerText:@"AVG MPG (All time)"
                                                           entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                                  entity:vehicle
                                                    entitiesToCompareBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallAvgReportedMpgForVehicle:v];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_generalFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v2 compare:v1]; // descending
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleMaxDaysBetweenFillupsStatsScreenMakerWithVehicle:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Max Days Between Fill-ups"
                                           entityTypeLabelText:@"VEHICLE"
                                                 entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                        entity:vehicle
                                          aggregatesHeaderText:@"MAX DAYS BETWEEN FILL-UPS"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallMaxDaysBetweenFillupsForVehicle:v];}
                                        yearToDateAggregateBlk:^(FPVehicle *v) {return [_stats yearToDateMaxDaysBetweenFillupsForVehicle:v];}
                                          lastYearAggregateBlk:^(FPVehicle *v) {return [_stats lastYearMaxDaysBetweenFillupsForVehicle:v];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareMaxDaysBetweenFillupsStatsScreenMakerWithVehicleInCtx:vehicle](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_generalFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleCompareMaxDaysBetweenFillupsStatsScreenMakerWithVehicleInCtx:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:@"Max Days Between Fill-ups Comparison"
                                                              headerText:@"MAX DAYS BETWEEN FILL-UPS (All time)"
                                                           entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                                  entity:vehicle
                                                    entitiesToCompareBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallMaxDaysBetweenFillupsForVehicle:v];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_generalFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v2 compare:v1]; // descending
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleAvgDaysBetweenFillupsStatsScreenMakerWithVehicle:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Avg Days Between Fill-ups"
                                           entityTypeLabelText:@"VEHICLE"
                                                 entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                        entity:vehicle
                                          aggregatesHeaderText:@"AVG DAYS BETWEEN FILL-UPS"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallAvgDaysBetweenFillupsForVehicle:v];}
                                        yearToDateAggregateBlk:^(FPVehicle *v) {return [_stats yearToDateAvgDaysBetweenFillupsForVehicle:v];}
                                          lastYearAggregateBlk:^(FPVehicle *v) {return [_stats lastYearAvgDaysBetweenFillupsForVehicle:v];}
                                             alltimeDatasetBlk:^(FPVehicle *v) {return [_stats overallAvgDaysBetweenFillupsDataSetForVehicle:v];}
                                          yearToDateDatasetBlk:^(FPVehicle *v) {return [_stats yearToDateAvgDaysBetweenFillupsDataSetForVehicle:v];}
                                            lastYearDatasetBlk:^(FPVehicle *v) {return [_stats lastYearAvgDaysBetweenFillupsDataSetForVehicle:v];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareAvgDaysBetweenFillupsStatsScreenMakerWithVehicleInCtx:vehicle](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [NSString stringWithFormat:@"%@ days", [_generalFormatter stringFromNumber:val]];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleCompareAvgDaysBetweenFillupsStatsScreenMakerWithVehicleInCtx:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:@"Avg Days Between Fill-ups Comparison"
                                                              headerText:@"AVG DAYS BETWEEN FILL-UPS (All time)"
                                                           entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                                  entity:vehicle
                                                    entitiesToCompareBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallAvgDaysBetweenFillupsForVehicle:v];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_generalFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v2 compare:v1]; // descending
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleMinPricePerGallonStatsScreenMakerWithVehicle:(FPVehicle *)vehicle
                                                                     octane:(NSNumber *)octane {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:[NSString stringWithFormat:@"Min Price of Gas (%@)", octane]
                                           entityTypeLabelText:@"VEHICLE"
                                                 entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                        entity:vehicle
                                          aggregatesHeaderText:[NSString stringWithFormat:@"MIN PRICE OF GAS (%@ octane)", octane]
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallMinPricePerGallonForVehicle:v octane:octane];}
                                        yearToDateAggregateBlk:^(FPVehicle *v) {return [_stats yearToDateMinPricePerGallonForVehicle:v octane:octane];}
                                          lastYearAggregateBlk:^(FPVehicle *v) {return [_stats lastYearMinPricePerGallonForVehicle:v octane:octane];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareMinPricePerGallonStatsScreenMakerWithVehicleInCtx:vehicle
                                                                                                                                          octane:octane](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleCompareMinPricePerGallonStatsScreenMakerWithVehicleInCtx:(FPVehicle *)vehicle
                                                                                 octane:(NSNumber *)octane {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:[NSString stringWithFormat:@"Min Price of Gas (%@) Comparison", octane]
                                                              headerText:[NSString stringWithFormat:@"MIN PRICE OF GAS - %@ octane (All time)", octane]
                                                           entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                                  entity:vehicle
                                                    entitiesToCompareBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallMinPricePerGallonForVehicle:v octane:octane];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v1 compare:v2]; // ascending
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleMaxPricePerGallonStatsScreenMakerWithVehicle:(FPVehicle *)vehicle
                                                                     octane:(NSNumber *)octane {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:[NSString stringWithFormat:@"Max Price of Gas (%@)", octane]
                                           entityTypeLabelText:@"VEHICLE"
                                                 entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                        entity:vehicle
                                          aggregatesHeaderText:[NSString stringWithFormat:@"MAX PRICE OF GAS (%@ octane)", octane]
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallMaxPricePerGallonForVehicle:v octane:octane];}
                                        yearToDateAggregateBlk:^(FPVehicle *v) {return [_stats yearToDateMaxPricePerGallonForVehicle:v octane:octane];}
                                          lastYearAggregateBlk:^(FPVehicle *v) {return [_stats lastYearMaxPricePerGallonForVehicle:v octane:octane];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareMaxPricePerGallonStatsScreenMakerWithVehicleInCtx:vehicle
                                                                                                                                          octane:octane](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleCompareMaxPricePerGallonStatsScreenMakerWithVehicleInCtx:(FPVehicle *)vehicle
                                                                                 octane:(NSNumber *)octane {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:[NSString stringWithFormat:@"Max Price of %@ Comparison", octane]
                                                              headerText:[NSString stringWithFormat:@"MAX PRICE OF %@ (All time)", octane]
                                                           entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                                  entity:vehicle
                                                    entitiesToCompareBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallMaxPricePerGallonForVehicle:v octane:octane];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v2 compare:v1]; // descending
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleAvgPricePerGallonStatsScreenMakerWithVehicle:(FPVehicle *)vehicle
                                                                     octane:(NSNumber *)octane {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:[NSString stringWithFormat:@"Avg Price of %@", octane]
                                           entityTypeLabelText:@"VEHICLE"
                                                 entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                        entity:vehicle
                                          aggregatesHeaderText:[NSString stringWithFormat:@"AVG PRICE OF %@", octane]
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallAvgPricePerGallonForVehicle:v octane:octane];}
                                        yearToDateAggregateBlk:^(FPVehicle *v) {return [_stats yearToDateAvgPricePerGallonForVehicle:v octane:octane];}
                                          lastYearAggregateBlk:^(FPVehicle *v) {return [_stats lastYearAvgPricePerGallonForVehicle:v octane:octane];}
                                             alltimeDatasetBlk:^(FPVehicle *v) {return [_stats overallAvgPricePerGallonDataSetForVehicle:v octane:octane];}
                                          yearToDateDatasetBlk:^(FPVehicle *v) {return [_stats yearToDateAvgPricePerGallonDataSetForVehicle:v octane:octane];}
                                            lastYearDatasetBlk:^(FPVehicle *v) {return [_stats lastYearAvgPricePerGallonDataSetForVehicle:v octane:octane];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareAvgPricePerGallonStatsScreenMakerWithVehicleInCtx:vehicle
                                                                         octane:octane](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleCompareAvgPricePerGallonStatsScreenMakerWithVehicleInCtx:(FPVehicle *)vehicle
                                                                                 octane:(NSNumber *)octane {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:[NSString stringWithFormat:@"Avg Price of %@ Comparison", octane]
                                                              headerText:[NSString stringWithFormat:@"AVG PRICE OF %@ (All time)", octane]
                                                           entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                                  entity:vehicle
                                                    entitiesToCompareBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallAvgPricePerGallonForVehicle:v octane:octane];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v1 compare:v2]; // ascending
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleGasCostPerMileStatsScreenMakerWithVehicle:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Avg Gas Cost/Mile"
                                           entityTypeLabelText:@"VEHICLE"
                                                 entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                        entity:vehicle
                                          aggregatesHeaderText:@"AVG GAS COST/MILE"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallAvgGasCostPerMileForVehicle:v];}
                                        yearToDateAggregateBlk:^(FPVehicle *v) {return [_stats yearToDateAvgGasCostPerMileForVehicle:v];}
                                          lastYearAggregateBlk:^(FPVehicle *v) {return [_stats lastYearAvgGasCostPerMileForVehicle:v];}
                                             alltimeDatasetBlk:^(FPVehicle *v) {return [_stats overallAvgGasCostPerMileDataSetForVehicle:v];}
                                          yearToDateDatasetBlk:^(FPVehicle *v) {return [_stats yearToDateAvgGasCostPerMileDataSetForVehicle:v];}
                                            lastYearDatasetBlk:^(FPVehicle *v) {return [_stats lastYearAvgGasCostPerMileDataSetForVehicle:v];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareAvgGasCostPerMileStatsScreenMakerWithVehicleInCtx:vehicle](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleCompareAvgGasCostPerMileStatsScreenMakerWithVehicleInCtx:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:@"Avg Gas Cost/Mile Comparison"
                                                              headerText:@"AVG GAS COST/MILE (All time)"
                                                           entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                                  entity:vehicle
                                                    entitiesToCompareBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallAvgGasCostPerMileForVehicle:v];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v1 compare:v2]; // ascending
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleMaxSpentOnGasStatsScreenMakerWithVehicle:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Max Monthly Spend"
                                           entityTypeLabelText:@"VEHICLE"
                                                 entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                        entity:vehicle
                                          aggregatesHeaderText:@"MONTHLY SPEND"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallMaxSpentOnGasForVehicle:v];}
                                        yearToDateAggregateBlk:^(FPVehicle *v) {return [_stats yearToDateMaxSpentOnGasForVehicle:v];}
                                          lastYearAggregateBlk:^(FPVehicle *v) {return [_stats lastYearMaxSpentOnGasForVehicle:v];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareMaxSpentOnGasStatsScreenMakerWithVehicleInCtx:vehicle](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleCompareMaxSpentOnGasStatsScreenMakerWithVehicleInCtx:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:@"Max Spend Comparison"
                                                              headerText:@"MAX MONTHLY SPEND (all time)"
                                                           entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                                  entity:vehicle
                                                    entitiesToCompareBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallMaxSpentOnGasForVehicle:v];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v2 compare:v1]; // descending
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleMinSpentOnGasStatsScreenMakerWithVehicle:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Min Monthly Spend"
                                           entityTypeLabelText:@"VEHICLE"
                                                 entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                        entity:vehicle
                                          aggregatesHeaderText:@"MONTHLY SPEND"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallMinSpentOnGasForVehicle:v];}
                                        yearToDateAggregateBlk:^(FPVehicle *v) {return [_stats yearToDateMinSpentOnGasForVehicle:v];}
                                          lastYearAggregateBlk:^(FPVehicle *v) {return [_stats lastYearMinSpentOnGasForVehicle:v];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareMinSpentOnGasStatsScreenMakerWithVehicleInCtx:vehicle](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleCompareMinSpentOnGasStatsScreenMakerWithVehicleInCtx:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:@"Min Spend Comparison"
                                                              headerText:@"MIN MONTHLY SPEND (all time)"
                                                           entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                                  entity:vehicle
                                                    entitiesToCompareBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallMinSpentOnGasForVehicle:v];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v1 compare:v2];
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleAvgSpentOnGasStatsScreenMakerWithVehicle:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Avg Monthly Spend"
                                           entityTypeLabelText:@"VEHICLE"
                                                 entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                        entity:vehicle
                                          aggregatesHeaderText:@"MONTHLY SPEND"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallAvgSpentOnGasForVehicle:v];}
                                        yearToDateAggregateBlk:^(FPVehicle *v) {return [_stats yearToDateAvgSpentOnGasForVehicle:v];}
                                          lastYearAggregateBlk:^(FPVehicle *v) {return [_stats lastYearAvgSpentOnGasForVehicle:v];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareAvgSpentOnGasStatsScreenMakerWithVehicleInCtx:vehicle](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleCompareAvgSpentOnGasStatsScreenMakerWithVehicleInCtx:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:@"Avg Spend Comparison"
                                                              headerText:@"AVG MONTHLY SPEND (all time)"
                                                           entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                                  entity:vehicle
                                                    entitiesToCompareBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallAvgSpentOnGasForVehicle:v];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v2 compare:v1]; // descending
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleSpentOnGasStatsScreenMakerWithVehicle:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Total Spend"
                                           entityTypeLabelText:@"VEHICLE"
                                                 entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                        entity:vehicle
                                          aggregatesHeaderText:@"TOTAL SPEND"
                                        compareButtonTitleText:@"Compare vehicles"
                                           alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallSpentOnGasForVehicle:v];}
                                        yearToDateAggregateBlk:^(FPVehicle *v) {return [_stats yearToDateSpentOnGasForVehicle:v];}
                                          lastYearAggregateBlk:^(FPVehicle *v) {return [_stats lastYearSpentOnGasForVehicle:v];}
                                             alltimeDatasetBlk:^(FPVehicle *v) {return [_stats overallSpentOnGasDataSetForVehicle:v];}
                                          yearToDateDatasetBlk:^(FPVehicle *v) {return [_stats yearToDateSpentOnGasDataSetForVehicle:v];}
                                            lastYearDatasetBlk:^(FPVehicle *v) {return [_stats lastYearSpentOnGasDataSetForVehicle:v];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareSpentOnGasStatsScreenMakerWithVehicleInCtx:vehicle](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleCompareSpentOnGasStatsScreenMakerWithVehicleInCtx:(FPVehicle *)vehicle {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:@"Spend Comparison"
                                                              headerText:@"TOTAL SPEND (all time)"
                                                           entityNameBlk:^(FPVehicle *v) {return v.name;}
                                                                  entity:vehicle
                                                    entitiesToCompareBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPVehicle *v) {return [_stats overallSpentOnGasForVehicle:v];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v2 compare:v1]; // descending
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleCompareSpentOnGasStatsScreenMaker {
  return [self newVehicleCompareSpentOnGasStatsScreenMakerWithVehicleInCtx:nil];
}

#pragma mark - Fuel Station Screens

- (PEItemChildrenCounter)fuelStationItemChildrenCounter {
  PEItemChildrenCounter itemChildrenCounter = ^ NSInteger (FPFuelStation *fuelStation) {
    return [_coordDao numFuelPurchaseLogsForFuelStation:fuelStation
                                                  error:[FPUtils localFetchErrorHandlerMaker]()];
  };
  return itemChildrenCounter;
}

- (PEItemChildrenMsgsBlk)fuelStationItemChildrenMsgs {
  PEItemChildrenMsgsBlk itemChildrenMsgs = ^ NSArray * (FPFuelStation *fuelStation) {
    NSInteger numFplogs = [_coordDao numFuelPurchaseLogsForFuelStation:fuelStation
                                                                 error:[FPUtils localFetchErrorHandlerMaker]()];
    NSMutableArray *msgs = [NSMutableArray array];
    if (numFplogs > 0) {
      [msgs addObject:[NSString stringWithFormat:@"%ld gas log%@", (long)numFplogs, (numFplogs > 1 ? @"s" : @"")]];
    }
    return msgs;
  };
  return itemChildrenMsgs;
}

- (PEItemDeleter)fuelStationItemDeleterForUser:(FPUser *)user {
  PEItemDeleter itemDeleter = ^ (UIViewController *listViewController,
                                 FPFuelStation *fuelStation,
                                 NSIndexPath *indexPath,
                                 PESyncNotFoundBlk notFoundBlk,
                                 PESyncSuccessBlk successBlk,
                                 PESyncRetryAfterBlk retryAfterBlk,
                                 PESyncServerTempErrorBlk tempErrBlk,
                                 PESyncServerErrorBlk errBlk,
                                 PESyncConflictBlk conflictBlk,
                                 PESyncAuthRequiredBlk authReqdBlk) {
    NSString *mainMsgFragment = @"deleting gas station";
    NSString *recordTitle = @"Gas station";
    [_coordDao deleteFuelStation:fuelStation
                         forUser:user
             notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                  addlSuccessBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
              remoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
              tempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                  remoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeEnvLogErrMsgs:errMask]); [APP refreshTabs];}
                     conflictBlk:^(FPFuelStation *latestFuelstation) {conflictBlk(1, mainMsgFragment, recordTitle, latestFuelstation); [APP refreshTabs];}
             addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                           error:[FPUtils localSaveErrorHandlerMaker]()];
  };
  return itemDeleter;
}

- (PEItemLocalDeleter)fuelStationItemLocalDeleter {
  return ^ (UIViewController *listViewController, FPFuelStation *fuelStation, NSIndexPath *indexPath) {
    [_coordDao deleteFuelstation:fuelStation error:[FPUtils localSaveErrorHandlerMaker]()];
    [APP refreshTabs];
  };
}

- (void)addDistanceInfoToTopOfCellContentView:(UIView *)contentView
                          withVerticalPadding:(CGFloat)verticalPadding
                            horizontalPadding:(CGFloat)horizontalPadding
                              withFuelstation:(FPFuelStation *)fuelstation {
  [self addDistanceInfoToTopOfCellContentView:contentView
                      withHorizontalAlignment:PEUIHorizontalAlignmentTypeLeft
                          withVerticalPadding:verticalPadding
                            horizontalPadding:horizontalPadding
                              withFuelstation:fuelstation];
}

- (void)addDistanceInfoToTopOfCellContentView:(UIView *)contentView
                      withHorizontalAlignment:(PEUIHorizontalAlignmentType)horizontalAlignment
                          withVerticalPadding:(CGFloat)verticalPadding
                            horizontalPadding:(CGFloat)horizontalPadding
                              withFuelstation:(FPFuelStation *)fuelstation {
  NSInteger distanceTag = 10;
  NSInteger unknownReasonTag = 11;
  [[contentView viewWithTag:distanceTag] removeFromSuperview];
  [[contentView viewWithTag:unknownReasonTag] removeFromSuperview];
  LabelMaker cellSubtitleMaker = [_uitoolkit tableCellSubtitleMaker];
  CLLocation *fuelStationLocation = [fuelstation location];
  UILabel *distance = nil;
  if (fuelStationLocation) {
    CLLocation *latestCurrentLocation = [APP latestLocation];
    if (latestCurrentLocation) {
      CLLocationDistance distanceVal = [latestCurrentLocation distanceFromLocation:fuelStationLocation];
      NSString *distanceUom = @"m";
      BOOL isNearby = NO;
      if (distanceVal < 150.0) {
        isNearby = YES;
      }
      if (distanceVal > 1000) {
        distanceUom = @"km";
        distanceVal = distanceVal / 1000.0;
      }
      distance = cellSubtitleMaker([NSString stringWithFormat:@"%.1f %@", distanceVal, distanceUom],
                                   (0.5 * contentView.frame.size.width) - horizontalPadding);
      [distance setTag:distanceTag];
      if (isNearby) {
        [distance setTextColor:[UIColor greenSeaColor]];
      }
      [PEUIUtils placeView:distance atBottomOf:contentView withAlignment:PEUIHorizontalAlignmentTypeRight vpadding:0.0 hpadding:horizontalPadding];
    }
  }
}

- (FPAuthScreenMaker)newViewFuelStationsScreenMaker {
  return ^ UIViewController *(FPUser *user) {
    void (^addFuelStationAction)(PEListViewController *, PEItemAddedBlk) =
    ^(PEListViewController *listViewCtrlr, PEItemAddedBlk itemAddedBlk) {
      UIViewController *addFuelStationScreen =
        [self newAddFuelStationScreenMakerWithBlk:itemAddedBlk
                               listViewController:listViewCtrlr](user);
      [listViewCtrlr presentViewController:[PEUIUtils navigationControllerWithController:addFuelStationScreen
                                                                     navigationBarHidden:NO]
                                  animated:YES
                                completion:nil];
    };
    FPDetailViewMaker fuelStationDetailViewMaker = ^UIViewController *(PEListViewController *listViewCtlr,
                                                                       id dataObject,
                                                                       NSIndexPath *indexPath,
                                                                       PEItemChangedBlk itemChangedBlk) {
      return [self newFuelStationDetailScreenMakerWithFuelStation:dataObject
                                             fuelStationIndexPath:indexPath
                                                   itemChangedBlk:itemChangedBlk
                                               listViewController:listViewCtlr](user);
    };
    PEPageLoaderBlk pageLoader = ^ NSArray * (id lastObject) {
      NSArray *fuelstations = [_coordDao fuelStationsForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];
      fuelstations = [FPUtils sortFuelstations:fuelstations inAscOrderByDistanceFrom:[APP latestLocation]];
      return fuelstations;
    };
    PEWouldBeIndexOfEntity wouldBeIndexBlk = [self wouldBeIndexBlkForEqualityBlock:^(FPFuelStation *fs1, FPFuelStation *fs2){return [fs1 isEqualToFuelStation:fs2];}
                                                                     entityFetcher:^{ return pageLoader(nil); }];
    PESyncViewStyler tableCellStyler = ^(UIView *contentView, FPFuelStation *fuelstation) {
      [PELMUIUtils syncViewStylerWithTitleBlk:^(FPFuelStation *fuelStation) {return [fuelStation name];}
                       alwaysTopifyTitleLabel:YES
                                    uitoolkit:_uitoolkit
                         subtitleLeftHPadding:15.0
                     subtitleFitToWidthFactor:0.5
                                   isLoggedIn:[APP isUserLoggedIn]](contentView, fuelstation);
      CGFloat distanceInfoVPadding = 15.0; //25.5;
      if ([fuelstation location]) {
        if ([APP latestLocation]) {
          distanceInfoVPadding = 18.5; //28.5;
        }
      }
      [self addDistanceInfoToTopOfCellContentView:contentView
                          withHorizontalAlignment:PEUIHorizontalAlignmentTypeRight
                              withVerticalPadding:distanceInfoVPadding
                                horizontalPadding:20.0
                                  withFuelstation:fuelstation];
    };
    return [[PEListViewController alloc] initWithClassOfDataSourceObjects:[FPFuelStation class]
                                                                    title:@"Gas Stations"
                                                    isPaginatedDataSource:NO
                                                          tableCellStyler:tableCellStyler
                                                       itemSelectedAction:nil
                                                      initialSelectedItem:nil
                                                            addItemAction:addFuelStationAction
                                                           cellIdentifier:@"FPFuelStationCell"
                                                           initialObjects:pageLoader(nil)
                                                               pageLoader:pageLoader
                                                        heightForCellsBlk:[self heightForCellsBlkWithExtraPadding:15.0]
                                                          detailViewMaker:fuelStationDetailViewMaker
                                                                uitoolkit:_uitoolkit
                                           doesEntityBelongToThisListView:^BOOL(PELMMainSupport *entity){return YES;}
                                                     wouldBeIndexOfEntity:wouldBeIndexBlk
                                                          isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                           isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                      itemChildrenCounter:[self fuelStationItemChildrenCounter]
                                                      itemChildrenMsgsBlk:[self fuelStationItemChildrenMsgs]
                                                              itemDeleter:[self fuelStationItemDeleterForUser:user]
                                                         itemLocalDeleter:[self fuelStationItemLocalDeleter]];
  };
}

- (FPAuthScreenMaker)newViewUnsyncedFuelStationsScreenMaker {
  return ^ UIViewController *(FPUser *user) {
    FPDetailViewMaker fuelStationDetailViewMaker = ^UIViewController *(PEListViewController *listViewCtlr,
                                                                       id dataObject,
                                                                       NSIndexPath *indexPath,
                                                                       PEItemChangedBlk itemChangedBlk) {
      return [self newFuelStationDetailScreenMakerWithFuelStation:dataObject
                                             fuelStationIndexPath:indexPath
                                                   itemChangedBlk:itemChangedBlk
                                               listViewController:listViewCtlr](user);
    };
    PEPageLoaderBlk pageLoader = ^ NSArray * (id lastObject) {
      NSArray *fuelstations = [_coordDao unsyncedFuelStationsForUser:user
                                                               error:[FPUtils localFetchErrorHandlerMaker]()];
      fuelstations = [FPUtils sortFuelstations:fuelstations inAscOrderByDistanceFrom:[APP latestLocation]];
      return fuelstations;
    };
    PEWouldBeIndexOfEntity wouldBeIndexBlk = [self wouldBeIndexBlkForEqualityBlock:^(FPFuelStation *fs1, FPFuelStation *fs2){return [fs1 isEqualToFuelStation:fs2];}
                                                                     entityFetcher:^{ return pageLoader(nil); }];
    PESyncViewStyler tableCellStyler = ^(UIView *contentView, FPFuelStation *fuelstation) {
      [PELMUIUtils syncViewStylerWithTitleBlk:^(FPFuelStation *fuelStation) {return [fuelStation name];}
                       alwaysTopifyTitleLabel:YES
                                    uitoolkit:_uitoolkit
                         subtitleLeftHPadding:15.0
                     subtitleFitToWidthFactor:0.5
                                   isLoggedIn:[APP isUserLoggedIn]](contentView, fuelstation);
      CGFloat distanceInfoVPadding = 25.5;
      if ([fuelstation location]) {
        if ([APP latestLocation]) {
          distanceInfoVPadding = 28.5;
        }
      }
      [self addDistanceInfoToTopOfCellContentView:contentView
                          withHorizontalAlignment:PEUIHorizontalAlignmentTypeRight
                              withVerticalPadding:distanceInfoVPadding
                                horizontalPadding:20.0
                                  withFuelstation:fuelstation];
    };
    return [[PEListViewController alloc] initWithClassOfDataSourceObjects:[FPFuelStation class]
                                                                    title:@"Unsynced Gas Stations"
                                                    isPaginatedDataSource:NO
                                                          tableCellStyler:tableCellStyler
                                                       itemSelectedAction:nil
                                                      initialSelectedItem:nil
                                                            addItemAction:nil
                                                           cellIdentifier:@"FPFuelStationCell"
                                                           initialObjects:pageLoader(nil)
                                                               pageLoader:pageLoader
                                                        heightForCellsBlk:[self heightForCellsBlk]
                                                          detailViewMaker:fuelStationDetailViewMaker
                                                                uitoolkit:_uitoolkit
                                           doesEntityBelongToThisListView:^BOOL(PELMMainSupport *entity){return YES;}
                                                     wouldBeIndexOfEntity:wouldBeIndexBlk
                                                          isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                           isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                      itemChildrenCounter:[self fuelStationItemChildrenCounter]
                                                      itemChildrenMsgsBlk:[self fuelStationItemChildrenMsgs]
                                                              itemDeleter:[self fuelStationItemDeleterForUser:user]
                                                         itemLocalDeleter:[self fuelStationItemLocalDeleter]];
  };
}

- (FPAuthScreenMaker)newFuelStationsForSelectionScreenMakerWithItemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                                                       initialSelectedFuelStation:(FPFuelStation *)initialSelectedFuelStation {
  return ^ UIViewController *(FPUser *user) {
    void (^addFuelStationAction)(PEListViewController *, PEItemAddedBlk) =
    ^(PEListViewController *listViewCtrlr, PEItemAddedBlk itemAddedBlk) {
      UIViewController *addFuelStationScreen =
        [self newAddFuelStationScreenMakerWithBlk:itemAddedBlk
                               listViewController:listViewCtrlr](user);
      [listViewCtrlr presentViewController:[PEUIUtils navigationControllerWithController:addFuelStationScreen
                                                                     navigationBarHidden:NO]
                                  animated:YES
                                completion:nil];
    };
    PEPageLoaderBlk pageLoader = ^ NSArray * (id lastObject) {
      NSArray *fuelstations = [_coordDao fuelStationsForUser:user
                                                       error:[FPUtils localFetchErrorHandlerMaker]()];
      fuelstations = [FPUtils sortFuelstations:fuelstations inAscOrderByDistanceFrom:[APP latestLocation]];
      return fuelstations;
    };
    PEWouldBeIndexOfEntity wouldBeIndexBlk = [self wouldBeIndexBlkForEqualityBlock:^(FPFuelStation *fs1, FPFuelStation *fs2){return [fs1 isEqualToFuelStation:fs2];}
                                                                     entityFetcher:^{ return pageLoader(nil); }];
    PESyncViewStyler tableCellStyler = ^(UIView *contentView, FPFuelStation *fuelstation) {
      [PELMUIUtils syncViewStylerWithTitleBlk:^(FPFuelStation *fuelStation) {return [fuelStation name];}
                       alwaysTopifyTitleLabel:YES
                                    uitoolkit:_uitoolkit
                         subtitleLeftHPadding:15.0
                     subtitleFitToWidthFactor:0.5
                                   isLoggedIn:[APP isUserLoggedIn]](contentView, fuelstation);
      CGFloat distanceInfoVPadding = 25.5;
      if ([fuelstation location]) {
        if ([APP latestLocation]) {
          distanceInfoVPadding = 28.5;
        }
      }
      [self addDistanceInfoToTopOfCellContentView:contentView
                          withHorizontalAlignment:PEUIHorizontalAlignmentTypeRight
                              withVerticalPadding:distanceInfoVPadding
                                horizontalPadding:20.0
                                  withFuelstation:fuelstation];
    };
    return [[PEListViewController alloc] initWithClassOfDataSourceObjects:[FPFuelStation class]
                                                                    title:@"Choose Gas Station"
                                                    isPaginatedDataSource:NO
                                                          tableCellStyler:tableCellStyler
                                                       itemSelectedAction:itemSelectedAction
                                                      initialSelectedItem:initialSelectedFuelStation
                                                            addItemAction:addFuelStationAction
                                                           cellIdentifier:@"FPFuelStationCell"
                                                           initialObjects:pageLoader(nil)
                                                               pageLoader:pageLoader
                                                        heightForCellsBlk:[self heightForCellsBlk]
                                                          detailViewMaker:nil
                                                                uitoolkit:_uitoolkit
                                           doesEntityBelongToThisListView:^BOOL(PELMMainSupport *entity){return YES;}
                                                     wouldBeIndexOfEntity:wouldBeIndexBlk
                                                          isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                           isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                      itemChildrenCounter:nil
                                                      itemChildrenMsgsBlk:nil
                                                              itemDeleter:nil
                                                         itemLocalDeleter:nil];
  };
}

- (PEEntityValidatorBlk)newFuelStationValidator {
  return ^NSArray *(UIView *fuelStationPanel) {
    NSMutableArray *errMsgs = [NSMutableArray array];
    PEMessageCollector cannotBeBlankCollector =
      [PEUIUtils newTfCannotBeEmptyBlkForMsgs:errMsgs entityPanel:fuelStationPanel];
    cannotBeBlankCollector(FPFuelStationTagName, @"Name cannot be empty.");
    return errMsgs;
  };
}

- (FPAuthScreenMaker)newAddFuelStationScreenMakerWithBlk:(PEItemAddedBlk)itemAddedBlk
                                      listViewController:(PEListViewController *)listViewController {
  return ^ UIViewController * (FPUser *user) {
    PESaveNewEntityLocalBlk newFuelStationSaverLocal = ^NSArray *(UIView *entityPanel, FPFuelStation *newFuelStation) {
      [_coordDao saveNewFuelStation:newFuelStation forUser:user error:[FPUtils localSaveErrorHandlerMaker]()];
      [APP refreshTabs];
      return @[@"Gas station saved.", @[@"Gas station saved locally."]];
    };
    PESaveNewEntityImmediateSyncBlk newFuelStationSaverImmediateSync = ^(UIView *entityPanel,
                                                                         FPFuelStation *newFuelStation,
                                                                         PESyncNotFoundBlk notFoundBlk,
                                                                         PESyncSuccessBlk successBlk,
                                                                         PESyncRetryAfterBlk retryAfterBlk,
                                                                         PESyncServerTempErrorBlk tempErrBlk,
                                                                         PESyncServerErrorBlk errBlk,
                                                                         PESyncConflictBlk conflictBlk,
                                                                         PESyncAuthRequiredBlk authReqdBlk,
                                                                         PESyncDependencyUnsynced depUnsyncedBlk) {
      NSString *mainMsgFragment = @"saving gas station to the server";
      NSString *recordTitle = @"Gas station";
      [_coordDao saveNewAndSyncImmediateFuelStation:newFuelStation
                                            forUser:user
                                notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                     addlSuccessBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                             addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                             addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                 addlRemoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeSaveFuelStationErrMsgs:errMask]); [APP refreshTabs];}
                                    addlConflictBlk:^(FPFuelStation *latestFuelstation) {conflictBlk(1, mainMsgFragment, recordTitle, latestFuelstation); [APP refreshTabs];}
                                addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                              error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEPrepareUIForUserInteractionBlk prepareUIForUserInteractionBlk = ^(PEAddViewEditController *ctrl, UIView *entityPanel) {
      if (![ctrl hasPoppedKeyboard]) {
        UITextField *nameTf = (UITextField *)[entityPanel viewWithTag:FPFuelStationTagName];
        [nameTf becomeFirstResponder];
        [ctrl setHasPoppedKeyboard:YES];
      }
    };
    PEEntityAddCancelerBlk addCanceler = ^(PEAddViewEditController *ctrl, BOOL dismissCtrlr, FPFuelStation *newFuelStation) {
      if (newFuelStation && [newFuelStation localMainIdentifier]) {
        // delete the unwanted record (probably from when user attempt to sync it, got an app error, and chose to 'forget it, cancel'
        [newFuelStation setEditInProgress:YES];
        [_coordDao cancelEditOfFuelStation:newFuelStation
                                     error:[FPUtils localSaveErrorHandlerMaker]()];
        [APP refreshTabs];
      }
      if (dismissCtrlr) {
        [[ctrl navigationController] dismissViewControllerAnimated:YES completion:nil];
      }
    };
    PEAddlContentSection addlContentSection = ^(PEAddViewEditController *ctrl, UIView *entityFormPanel, FPFuelStation *newFuelstation) {
      NSString *infoText;
      if ([[_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()] count] == 0) {
        infoText = @"You can now create gas logs for this gas station.  When creating your first gas log, you'll need to create the vehicle record for it too.";
      } else {
        infoText = @"You can now create gas logs for this gas station.";
      }
      return [PEUIUtils infoAlertSectionWithTitle:@"Tip"
                                 alertDescription:[[NSAttributedString alloc] initWithString:infoText]
                                   relativeToView:ctrl.view];
    };
    return [PEAddViewEditController addEntityCtrlrWithUitoolkit:_uitoolkit
                                             listViewController:listViewController
                                                   itemAddedBlk:itemAddedBlk
                                           entityFormPanelMaker:[_panelToolkit fuelstationFormPanelMakerIncludeLogButton:NO]
                                            entityToPanelBinder:[_panelToolkit fuelstationToFuelstationPanelBinder]
                                            panelToEntityBinder:[_panelToolkit fuelstationFormPanelToFuelstationBinder]
                                                    entityTitle:@"Gas Station"
                                              entityAddCanceler:addCanceler
                                                    entityMaker:[_panelToolkit fuelstationMaker]
                                            newEntitySaverLocal:newFuelStationSaverLocal
                                    newEntitySaverImmediateSync:newFuelStationSaverImmediateSync
                                 prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                               viewDidAppearBlk:nil
                                                entityValidator:[self newFuelStationValidator]
                                                isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                 isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                  isOfflineMode:^{ return [APP offlineMode]; }
                                 syncImmediateMBProgressHUDMode:MBProgressHUDModeIndeterminate
                                          modalOperationStarted:[self commonModalOperationStartedBlock]
                                             modalOperationDone:[self commonModalOperationDoneBlock]
                                    entityAddedNotificationName:FPEntityAddedNotification
                                             addlContentSection:addlContentSection];
  };
}

- (FPAuthScreenMaker)newFuelStationDetailScreenMakerWithFuelStation:(FPFuelStation *)fuelStation
                                               fuelStationIndexPath:(NSIndexPath *)fuelStationIndexPath
                                                     itemChangedBlk:(PEItemChangedBlk)itemChangedBlk
                                                 listViewController:(PEListViewController *)listViewController {
  return ^ UIViewController * (FPUser *user) {
    PEEntityEditPreparerBlk fuelStationEditPreparer = ^BOOL(PEAddViewEditController *ctrl, PELMModelSupport *entity) {
      FPFuelStation *fuelStation = (FPFuelStation *)entity;
      BOOL prepareSuccess = [_coordDao prepareFuelStationForEdit:fuelStation
                                                         forUser:user
                                                           error:[FPUtils localSaveErrorHandlerMaker]()];
      [APP refreshTabs];
      return prepareSuccess;
    };
    PEEntityEditCancelerBlk fuelStationEditCanceler = ^ (PEAddViewEditController *ctrl, PELMModelSupport *entity) {
      FPFuelStation *fuelStation = (FPFuelStation *)entity;
      [_coordDao cancelEditOfFuelStation:fuelStation
                                   error:[FPUtils localSaveErrorHandlerMaker]()];
      [APP refreshTabs];
    };
    PESaveEntityBlk fuelStationSaver = ^(PEAddViewEditController *ctrl, PELMModelSupport *entity) {
      FPFuelStation *fuelStation = (FPFuelStation *)entity;
      [_coordDao saveFuelStation:fuelStation
                           error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEMarkAsDoneEditingLocalBlk doneEditingFuelStationLocal = ^(PEAddViewEditController *ctrl, FPFuelStation *fuelStation) {
      [_coordDao markAsDoneEditingFuelStation:fuelStation error:[FPUtils localSaveErrorHandlerMaker]()];
      [APP refreshTabs];
    };
    PEMarkAsDoneEditingImmediateSyncBlk doneEditingFuelStationImmediateSync = ^(PEAddViewEditController *ctrl,
                                                                                FPFuelStation *fuelStation,
                                                                                PESyncNotFoundBlk notFoundBlk,
                                                                                PESyncSuccessBlk successBlk,
                                                                                PESyncRetryAfterBlk retryAfterBlk,
                                                                                PESyncServerTempErrorBlk tempErrBlk,
                                                                                PESyncServerErrorBlk errBlk,
                                                                                PESyncConflictBlk conflictBlk,
                                                                                PESyncAuthRequiredBlk authReqdBlk,
                                                                                PESyncDependencyUnsynced depUnsyncedBlk) {
      NSString *mainMsgFragment = @"saving gas station to the server";
      NSString *recordTitle = @"Gas station";
      [_coordDao markAsDoneEditingAndSyncFuelStationImmediate:fuelStation
                                                      forUser:user
                                          notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                               addlSuccessBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                       addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                                       addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                           addlRemoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeSaveFuelStationErrMsgs:errMask]); [APP refreshTabs];}
                                              addlConflictBlk:^(FPFuelStation *latestFuelStation) {conflictBlk(1, mainMsgFragment, recordTitle, latestFuelStation); [APP refreshTabs];}
                                          addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                        error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEUploaderBlk uploader = ^(PEAddViewEditController *ctrl,
                               FPFuelStation *fuelStation,
                               PESyncNotFoundBlk notFoundBlk,
                               PESyncSuccessBlk successBlk,
                               PESyncRetryAfterBlk retryAfterBlk,
                               PESyncServerTempErrorBlk tempErrBlk,
                               PESyncServerErrorBlk errBlk,
                               PESyncConflictBlk conflictBlk,
                               PESyncAuthRequiredBlk authReqdBlk,
                               PESyncDependencyUnsynced depUnsyncedBlk) {
      NSString *mainMsgFragment = @"saving gas station to the server";
      NSString *recordTitle = @"Gas station";
      [_coordDao flushUnsyncedChangesToFuelStation:fuelStation
                                           forUser:user
                               notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                    addlSuccessBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                            addlRemoteStoreBusyBlk:^(NSDate *retryAfter){retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                            addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                addlRemoteErrorBlk:^(NSInteger errMask){errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeSaveFuelStationErrMsgs:errMask]); [APP refreshTabs];}
                                   addlConflictBlk:^(FPFuelStation *latestFuelStation) {conflictBlk(1, mainMsgFragment, recordTitle, latestFuelStation); [APP refreshTabs];}
                               addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                             error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEPrepareUIForUserInteractionBlk prepareUIForUserInteractionBlk = ^(PEAddViewEditController *ctrl, UIView *entityPanel) {
      if (![ctrl hasPoppedKeyboard]) {
        UITextField *nameTf = (UITextField *)[entityPanel viewWithTag:FPFuelStationTagName];
        [nameTf becomeFirstResponder];
        [ctrl setHasPoppedKeyboard:YES];
      }
    };
    PEMergeBlk mergeBlk = ^ NSDictionary * (PEAddViewEditController *ctrl, FPFuelStation *localFuelstation, FPFuelStation *remoteFuelstation) {
      FPFuelStation *masterFuelstation = [_coordDao masterFuelstationWithId:[localFuelstation localMasterIdentifier]
                                                                                 error:[FPUtils localFetchErrorHandlerMaker]()];
      return [FPFuelStation mergeRemoteFuelstation:remoteFuelstation withLocalFuelstation:localFuelstation localMasterFuelstation:masterFuelstation];
    };
    PEConflictResolveFields conflictResolveFieldsBlk = ^(PEAddViewEditController *ctrl,
                                                         NSDictionary *mergeConflicts,
                                                         FPFuelStation *localFuelstation,
                                                         FPFuelStation *remoteFuelstation) {
      NSMutableArray *fields = [NSMutableArray arrayWithCapacity:mergeConflicts.count];
      [mergeConflicts enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *fieldName = key;
        if ([fieldName isEqualToString:FPFuelstationNameField]) {
          [fields addObject:@[@"Gas station name:", @(FPFuelStationTagName), [PEUtils emptyIfNil:[localFuelstation name]], [PEUtils emptyIfNil:[remoteFuelstation name]]]];
        } else if ([fieldName isEqualToString:FPFuelstationStreetField]) {
          [fields addObject:@[@"Street:", @(FPFuelStationTagStreet), [PEUtils emptyIfNil:[localFuelstation street]], [PEUtils emptyIfNil:[remoteFuelstation street]]]];
        } else if ([fieldName isEqualToString:FPFuelstationCityField]) {
          [fields addObject:@[@"City:", @(FPFuelStationTagCity), [PEUtils emptyIfNil:[localFuelstation city]], [PEUtils emptyIfNil:[remoteFuelstation city]]]];
        } else if ([fieldName isEqualToString:FPFuelstationStateField]) {
          [fields addObject:@[@"State:", @(FPFuelStationTagState), [PEUtils emptyIfNil:[localFuelstation state]], [PEUtils emptyIfNil:[remoteFuelstation state]]]];
        } else if ([fieldName isEqualToString:FPFuelstationZipField]) {
          [fields addObject:@[@"Zip:", @(FPFuelStationTagZip), [PEUtils emptyIfNil:[localFuelstation zip]], [PEUtils emptyIfNil:[remoteFuelstation zip]]]];
        } else if ([fieldName isEqualToString:FPFuelstationLatitudeField]) {
          [fields addObject:@[@"Latitude:", @(FPFuelStationTagLocationCoordinates), [PEUtils descriptionOrEmptyIfNil:[localFuelstation latitude]], [PEUtils descriptionOrEmptyIfNil:[remoteFuelstation latitude]]]];
        } else if ([fieldName isEqualToString:FPFuelstationLongitudeField]) {
          [fields addObject:@[@"Longitude:", @(FPFuelStationTagLocationCoordinates+1), [PEUtils descriptionOrEmptyIfNil:[localFuelstation longitude]], [PEUtils descriptionOrEmptyIfNil:[remoteFuelstation longitude]]]];
        }
      }];
      return fields;
    };
    PEConflictResolvedEntity conflictResolvedEntityBlk = ^ id (PEAddViewEditController *ctrl,
                                                               NSDictionary *mergeConflicts,
                                                               NSArray *valueLabels,
                                                               FPFuelStation *localFuelstation,
                                                               FPFuelStation *remoteFuelstation) {
      FPFuelStation *resolvedFuelstation = [localFuelstation copy];
      NSInteger numValueLabels = [valueLabels count];
      for (int i = 0; i < numValueLabels; i++) {
        NSArray *valueLabelPair = valueLabels[i];
        UILabel *remoteValue = valueLabelPair[1];
        if (remoteValue.tag > 0) {
          switch (remoteValue.tag) {
            case FPFuelStationTagName:
              [resolvedFuelstation setName:[remoteFuelstation name]];
              break;
            case FPFuelStationTagStreet:
              [resolvedFuelstation setStreet:[remoteFuelstation street]];
              break;
            case FPFuelStationTagCity:
              [resolvedFuelstation setCity:[remoteFuelstation city]];
              break;
            case FPFuelStationTagState:
              [resolvedFuelstation setState:[remoteFuelstation state]];
              break;
            case FPFuelStationTagZip:
              [resolvedFuelstation setZip:[remoteFuelstation zip]];
              break;
            case FPFuelStationTagLocationCoordinates: // latitude
              [resolvedFuelstation setLatitude:[remoteFuelstation latitude]];
              break;
            case (FPFuelStationTagLocationCoordinates + 1): // longitude
              [resolvedFuelstation setLongitude:[remoteFuelstation longitude]];
              break;
          }
        }
      }
      return resolvedFuelstation;
    };
    PEDownloaderBlk downloaderBlk = ^ (PEAddViewEditController *ctrl,
                                       FPFuelStation *fuelstation,
                                       PESyncNotFoundBlk notFoundBlk,
                                       PEDownloadSuccessBlk successBlk,
                                       PESyncRetryAfterBlk retryAfterBlk,
                                       PESyncServerTempErrorBlk tempErrBlk,
                                       PESyncAuthRequiredBlk authReqdBlk) {
      NSString *mainMsgFragment = @"fetching gas station";
      NSString *recordTitle = @"Gas station";
      float percentOfFetching = 1.0;
      [_coordDao fetchFuelstationWithGlobalId:[fuelstation globalIdentifier]
                              ifModifiedSince:[fuelstation updatedAt]
                                      forUser:user
                          notFoundOnServerBlk:^{notFoundBlk(percentOfFetching, mainMsgFragment, recordTitle);}
                                   successBlk:^(FPFuelStation *fetchedFuelstation) {successBlk(percentOfFetching, mainMsgFragment, recordTitle, fetchedFuelstation);}
                           remoteStoreBusyBlk:^(NSDate *retryAfter){retryAfterBlk(percentOfFetching, mainMsgFragment, recordTitle, retryAfter);}
                           tempRemoteErrorBlk:^{tempErrBlk(percentOfFetching, mainMsgFragment, recordTitle);}
                          addlAuthRequiredBlk:^{authReqdBlk(percentOfFetching, mainMsgFragment, recordTitle); [APP refreshTabs];}];
    };
    PEPostDownloaderSaver postDownloadSaverBlk = ^ (PEAddViewEditController *ctrl,
                                                    FPFuelStation *downloadedFuelstation,
                                                    FPFuelStation *fuelstation) {
      [_coordDao saveMasterFuelstation:downloadedFuelstation forUser:user error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEViewDidAppearBlk viewDidAppearBlk = ^(PEAddViewEditController *ctrl) {
      UIButton *viewFplogsBtn = (UIButton *)[ctrl.view viewWithTag:FPFuelStationTagViewFplogsBtn];
      [PEUIUtils refreshRecordCountLabelOnButton:viewFplogsBtn
                             recordCountLabelTag:FPFuelStationTagViewFplogsBtnRecordCount
                                     recordCount:[_coordDao numFuelPurchaseLogsForFuelStation:fuelStation error:[FPUtils localFetchErrorHandlerMaker]()]];
    };
    return [PEAddViewEditController viewEntityCtrlrWithParentEntity:user
                                                             entity:fuelStation
                                                 listViewController:listViewController
                                                    entityIndexPath:fuelStationIndexPath
                                                          uitoolkit:_uitoolkit
                                                     itemChangedBlk:itemChangedBlk
                                               entityFormPanelMaker:[_panelToolkit fuelstationFormPanelMakerIncludeLogButton:YES]
                                               entityViewPanelMaker:[_panelToolkit fuelstationViewPanelMaker]
                                                entityToPanelBinder:[_panelToolkit fuelstationToFuelstationPanelBinder]
                                                panelToEntityBinder:[_panelToolkit fuelstationFormPanelToFuelstationBinder]
                                                        entityTitle:@"Gas Station"
                                               panelEnablerDisabler:[_panelToolkit fuelstationFormPanelEnablerDisabler]
                                                  entityAddCanceler:nil
                                                 entityEditPreparer:fuelStationEditPreparer
                                                 entityEditCanceler:fuelStationEditCanceler
                                                        entitySaver:fuelStationSaver
                                             doneEditingEntityLocal:doneEditingFuelStationLocal
                                     doneEditingEntityImmediateSync:doneEditingFuelStationImmediateSync
                                                    isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                     isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                      isOfflineMode:^{ return [APP offlineMode]; }
                                     syncImmediateMBProgressHUDMode:MBProgressHUDModeIndeterminate
                                     prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                                   viewDidAppearBlk:viewDidAppearBlk
                                                    entityValidator:[self newFuelStationValidator]
                                                           uploader:uploader
                                              numRemoteDepsNotLocal:nil
                                                              merge:mergeBlk
                                                  fetchDependencies:nil
                                                    updateDepsPanel:nil
                                                         downloader:downloaderBlk
                                                  postDownloadSaver:postDownloadSaverBlk
                                              conflictResolveFields:conflictResolveFieldsBlk
                                             conflictResolvedEntity:conflictResolvedEntityBlk
                                                itemChildrenCounter:[self fuelStationItemChildrenCounter]
                                                itemChildrenMsgsBlk:[self fuelStationItemChildrenMsgs]
                                                        itemDeleter:[self fuelStationItemDeleterForUser:user]
                                                   itemLocalDeleter:[self fuelStationItemLocalDeleter]
                                              modalOperationStarted:[self commonModalOperationStartedBlock]
                                                 modalOperationDone:[self commonModalOperationDoneBlock]
                                      entityUpdatedNotificationName:FPEntityUpdatedNotification
                                      entityRemovedNotificationName:FPEntityDeletedNotification];
  };
}

#pragma mark - Fuel Station Stat Screens

- (FPAuthScreenMaker)newFuelStationStatsLaunchScreenMakerWithFuelstation:(FPFuelStation *)fuelstation {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatsLaunchController alloc] initWithScreenTitle:@"Gas Station Stats & Trends"
                                                  entityTypeLabelText:@"GAS STATION"
                                                        entityNameBlk:^(FPFuelStation *fs) {return fs.name;}
                                                               entity:fuelstation
                                                 statLaunchButtonsBlk:^{
                                                   NSMutableArray *statLaunchButtons = [NSMutableArray array];
                                                   [statLaunchButtons addObject:@"GAS SPEND"];
                                                   [statLaunchButtons addObject:@[@"Total amount spent",
                                                                                  ^{ return [self newFuelStationSpentOnGasStatsScreenMakerWithFuelstation:fuelstation](user); }]];
                                                   [statLaunchButtons addObject:@[@"Avg monthly spend",
                                                                                  ^{ return [self newFuelStationAvgSpentOnGasStatsScreenMakerWithFuelstation:fuelstation](user); }]];
                                                   [statLaunchButtons addObject:@[@"Min monthly spend",
                                                                                  ^{ return [self newFuelStationMinSpentOnGasStatsScreenMakerWithFuelstation:fuelstation](user); }]];
                                                   [statLaunchButtons addObject:@[@"Max monthly spend",
                                                                                  ^{ return [self newFuelStationMaxSpentOnGasStatsScreenMakerWithFuelstation:fuelstation](user); }]];
                                                   NSArray *octanes = [_coordDao distinctOctanesForFuelstation:fuelstation error:_errorBlk];
                                                   for (NSNumber *octane in octanes) {
                                                     [statLaunchButtons addObject:[NSString stringWithFormat:@"%@ OCTANE - PRICE STATS", octane]];
                                                     [statLaunchButtons addObject:@[[NSString stringWithFormat:@"Avg price of %@", octane],
                                                                                    ^{ return [self newFuelStationAvgPricePerGallonStatsScreenMakerWithFuelstation:fuelstation octane:octane](user); }]];
                                                     [statLaunchButtons addObject:@[[NSString stringWithFormat:@"Min price of %@", octane],
                                                                                    ^{ return [self newFuelStationMinPricePerGallonStatsScreenMakerWithFuelstation:fuelstation octane:octane](user); }]];
                                                     [statLaunchButtons addObject:@[[NSString stringWithFormat:@"Max price of %@", octane],
                                                                                    ^{ return [self newFuelStationMaxPricePerGallonStatsScreenMakerWithFuelstation:fuelstation octane:octane](user); }]];
                                                   }
                                                   if ([_coordDao hasDieselLogsForFuelstation:fuelstation error:_errorBlk]) {
                                                     [statLaunchButtons addObject:@"DIESEL - PRICE STATS"];
                                                     [statLaunchButtons addObject:@[@"Avg price of diesel",
                                                                                    ^{ return [self newAvgPricePerDieselGallonStatsScreenMakerWithFuelstation:fuelstation](user); }]];
                                                   }
                                                   return statLaunchButtons;
                                                 }
                                                            uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newAvgPricePerDieselGallonStatsScreenMakerWithFuelstation:(FPFuelStation *)fuelstation {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:[NSString stringWithFormat:@"Avg Price of Diesel"]
                                           entityTypeLabelText:@"ALL GAS STATIONS"
                                                 entityNameBlk:nil
                                                        entity:user
                                          aggregatesHeaderText:[NSString stringWithFormat:@"AVG PRICE OF DIESEL"]
                                        compareButtonTitleText:@"Compare gas stations"
                                           alltimeAggregateBlk:^(FPFuelStation *fs) {return [_stats overallAvgPricePerDieselGallonForFuelstation:fs];}
                                        yearToDateAggregateBlk:^(FPFuelStation *fs) {return [_stats yearToDateAvgPricePerDieselGallonForFuelstation:fs];}
                                          lastYearAggregateBlk:^(FPFuelStation *fs) {return [_stats lastYearAvgPricePerDieselGallonForFuelstation:fs];}
                                             alltimeDatasetBlk:^(FPFuelStation *fs) {return [_stats overallAvgPricePerDieselGallonDataSetForFuelstation:fs];}
                                          yearToDateDatasetBlk:^(FPFuelStation *fs) {return [_stats yearToDateAvgPricePerDieselGallonDataSetForFuelstation:fs];}
                                            lastYearDatasetBlk:^(FPFuelStation *fs) {return [_stats lastYearAvgPricePerDieselGallonDataSetForFuelstation:fs];}
                                               siblingCountBlk:^{return [_coordDao dieselVehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newVehicleCompareAvgPricePerDieselGallonStatsScreenMakerWithFuelstationInCtx:fuelstation](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newVehicleCompareAvgPricePerDieselGallonStatsScreenMakerWithFuelstationInCtx:(FPFuelStation *)fuelstation {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:[NSString stringWithFormat:@"Avg Price of Diesel Comparison"]
                                                              headerText:[NSString stringWithFormat:@"AVG PRICE OF DIESEL (All time)"]
                                                           entityNameBlk:^(FPFuelStation *fs) {return fs.name;}
                                                                  entity:fuelstation
                                                    entitiesToCompareBlk:^{return [_coordDao dieselVehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPFuelStation *fs) {return [_stats overallAvgPricePerDieselGallonForFuelstation:fs];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v1 compare:v2]; // ascending
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newFuelStationMinPricePerGallonStatsScreenMakerWithFuelstation:(FPFuelStation *)fuelstation
                                                                             octane:(NSNumber *)octane {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:[NSString stringWithFormat:@"Min Price of %@", octane]
                                           entityTypeLabelText:@"GAS STATION"
                                                 entityNameBlk:^(FPFuelStation *fs) {return fs.name;}
                                                        entity:fuelstation
                                          aggregatesHeaderText:[NSString stringWithFormat:@"MIN PRICE OF %@", octane]
                                        compareButtonTitleText:@"Compare gas stations"
                                           alltimeAggregateBlk:^(FPFuelStation *fs) {return [_stats overallMinPricePerGallonForFuelstation:fs octane:octane];}
                                        yearToDateAggregateBlk:^(FPFuelStation *fs) {return [_stats yearToDateMinPricePerGallonForFuelstation:fs octane:octane];}
                                          lastYearAggregateBlk:^(FPFuelStation *fs) {return [_stats lastYearMinPricePerGallonForFuelstation:fs octane:octane];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newFuelStationCompareMinPricePerGallonStatsScreenMakerWithFuelstationInCtx:fuelstation
                                                                                                                                                  octane:octane](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newFuelStationCompareMinPricePerGallonStatsScreenMakerWithFuelstationInCtx:(FPFuelStation *)fuelstation
                                                                                         octane:(NSNumber *)octane {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:[NSString stringWithFormat:@"Min Price of %@ Comparison", octane]
                                                              headerText:[NSString stringWithFormat:@"MIN PRICE OF %@ (All time)", octane]
                                                           entityNameBlk:^(FPFuelStation *fs) {return fs.name;}
                                                                  entity:fuelstation
                                                    entitiesToCompareBlk:^{return [_coordDao fuelStationsForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPFuelStation *fs) {return [_stats overallMinPricePerGallonForFuelstation:fs octane:octane];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v1 compare:v2]; // ascending
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newFuelStationMaxPricePerGallonStatsScreenMakerWithFuelstation:(FPFuelStation *)fuelstation
                                                                             octane:(NSNumber *)octane {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:[NSString stringWithFormat:@"Max Price of %@", octane]
                                           entityTypeLabelText:@"GAS STATION"
                                                 entityNameBlk:^(FPFuelStation *fs) {return fs.name;}
                                                        entity:fuelstation
                                          aggregatesHeaderText:[NSString stringWithFormat:@"MAX PRICE OF %@", octane]
                                        compareButtonTitleText:@"Compare gas stations"
                                           alltimeAggregateBlk:^(FPFuelStation *fs) {return [_stats overallMaxPricePerGallonForFuelstation:fs octane:octane];}
                                        yearToDateAggregateBlk:^(FPFuelStation *fs) {return [_stats yearToDateMaxPricePerGallonForFuelstation:fs octane:octane];}
                                          lastYearAggregateBlk:^(FPFuelStation *fs) {return [_stats lastYearMaxPricePerGallonForFuelstation:fs octane:octane];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newFuelStationCompareMaxPricePerGallonStatsScreenMakerWithFuelstationInCtx:fuelstation
                                                                                                                                                  octane:octane](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newFuelStationCompareMaxPricePerGallonStatsScreenMakerWithFuelstationInCtx:(FPFuelStation *)fuelstation
                                                                                         octane:(NSNumber *)octane {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:[NSString stringWithFormat:@"Max Price of %@ Comparison", octane]
                                                              headerText:[NSString stringWithFormat:@"MAX PRICE OF %@ (All time)", octane]
                                                           entityNameBlk:^(FPFuelStation *fs) {return fs.name;}
                                                                  entity:fuelstation
                                                    entitiesToCompareBlk:^{return [_coordDao fuelStationsForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPFuelStation *fs) {return [_stats overallMaxPricePerGallonForFuelstation:fs octane:octane];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v2 compare:v1]; // descending
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newFuelStationAvgPricePerGallonStatsScreenMakerWithOctane:(NSNumber *)octane {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:[NSString stringWithFormat:@"Avg Price of %@", octane]
                                           entityTypeLabelText:@"GAS STATION"
                                                 entityNameBlk:^(FPFuelStation *fs) {return fs.name;}
                                                        entity:nil
                                          aggregatesHeaderText:[NSString stringWithFormat:@"AVG PRICE OF %@", octane]
                                        compareButtonTitleText:@"Compare gas stations"
                                           alltimeAggregateBlk:^(FPFuelStation *fs) {return [_stats overallAvgPricePerGallonForFuelstation:fs octane:octane];}
                                        yearToDateAggregateBlk:^(FPFuelStation *fs) {return [_stats yearToDateAvgPricePerGallonForFuelstation:fs octane:octane];}
                                          lastYearAggregateBlk:^(FPFuelStation *fs) {return [_stats lastYearAvgPricePerGallonForFuelstation:fs octane:octane];}
                                             alltimeDatasetBlk:^(FPFuelStation *fs) {return [_stats overallAvgPricePerGallonDataSetForFuelstation:fs octane:octane];}
                                          yearToDateDatasetBlk:^(FPFuelStation *fs) {return [_stats yearToDateAvgPricePerGallonDataSetForFuelstation:fs octane:octane];}
                                            lastYearDatasetBlk:^(FPFuelStation *fs) {return [_stats lastYearAvgPricePerGallonDataSetForFuelstation:fs octane:octane];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newFuelStationCompareAvgPricePerGallonStatsScreenMakerWithFuelstationInCtx:nil octane:octane](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newFuelStationAvgPricePerGallonStatsScreenMakerWithFuelstation:(FPFuelStation *)fuelstation
                                                                             octane:(NSNumber *)octane {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:[NSString stringWithFormat:@"Avg Price of %@", octane]
                                           entityTypeLabelText:@"GAS STATION"
                                                 entityNameBlk:^(FPFuelStation *fs) {return fs.name;}
                                                        entity:fuelstation
                                          aggregatesHeaderText:[NSString stringWithFormat:@"AVG PRICE OF %@", octane]
                                        compareButtonTitleText:@"Compare gas stations"
                                           alltimeAggregateBlk:^(FPFuelStation *fs) {return [_stats overallAvgPricePerGallonForFuelstation:fs octane:octane];}
                                        yearToDateAggregateBlk:^(FPFuelStation *fs) {return [_stats yearToDateAvgPricePerGallonForFuelstation:fs octane:octane];}
                                          lastYearAggregateBlk:^(FPFuelStation *fs) {return [_stats lastYearAvgPricePerGallonForFuelstation:fs octane:octane];}
                                             alltimeDatasetBlk:^(FPFuelStation *fs) {return [_stats overallAvgPricePerGallonDataSetForFuelstation:fs octane:octane];}
                                          yearToDateDatasetBlk:^(FPFuelStation *fs) {return [_stats yearToDateAvgPricePerGallonDataSetForFuelstation:fs octane:octane];}
                                            lastYearDatasetBlk:^(FPFuelStation *fs) {return [_stats lastYearAvgPricePerGallonDataSetForFuelstation:fs octane:octane];}
                                               siblingCountBlk:^{return [_coordDao vehiclesForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newFuelStationCompareAvgPricePerGallonStatsScreenMakerWithFuelstationInCtx:fuelstation
                                                                                                                                                  octane:octane](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newFuelStationCompareAvgPricePerDieselGallonStatsScreenMakerWithFuelstationInCtx:(FPFuelStation *)fuelstation {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:[NSString stringWithFormat:@"Avg Price of Diesel Comparison"]
                                                              headerText:[NSString stringWithFormat:@"AVG PRICE OF DIESEL (All time)"]
                                                           entityNameBlk:^(FPFuelStation *fs) {return fs.name;}
                                                                  entity:fuelstation
                                                    entitiesToCompareBlk:^{return [_coordDao fuelStationsForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPFuelStation *fs) {return [_stats overallAvgPricePerDieselGallonForFuelstation:fs];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v1 compare:v2]; // ascending
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newFuelStationCompareAvgPricePerGallonStatsScreenMakerWithFuelstationInCtx:(FPFuelStation *)fuelstation
                                                                                         octane:(NSNumber *)octane {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:[NSString stringWithFormat:@"Avg Price of %@ Comparison", octane]
                                                              headerText:[NSString stringWithFormat:@"AVG PRICE OF %@ (All time)", octane]
                                                           entityNameBlk:^(FPFuelStation *fs) {return fs.name;}
                                                                  entity:fuelstation
                                                    entitiesToCompareBlk:^{return [_coordDao fuelStationsForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPFuelStation *fs) {return [_stats overallAvgPricePerGallonForFuelstation:fs octane:octane];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v1 compare:v2]; // ascending
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newFuelStationCompareAvgPricePerGallonStatsScreenMakerWithFuelstationInCtx:(FPFuelStation *)fuelstation {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:[NSString stringWithFormat:@"Avg Price Comparison"]
                                                              headerText:[NSString stringWithFormat:@"AVG PRICE (All time)"]
                                                           entityNameBlk:^(FPFuelStation *fs) {return fs.name;}
                                                                  entity:fuelstation
                                                    entitiesToCompareBlk:^{return [_coordDao fuelStationsForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPFuelStation *fs) {return [_stats overallAvgPricePerGallonForFuelstation:fs];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v1 compare:v2]; // ascending
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newFuelStationMaxSpentOnGasStatsScreenMakerWithFuelstation:(FPFuelStation *)fuelstation {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Max Monthly Spend"
                                           entityTypeLabelText:@"FUELSTATION"
                                                 entityNameBlk:^(FPFuelStation *fs) {return fs.name;}
                                                        entity:fuelstation
                                          aggregatesHeaderText:@"MONTHLY SPEND"
                                        compareButtonTitleText:@"Compare gas stations"
                                           alltimeAggregateBlk:^(FPFuelStation *fs) {return [_stats overallMaxSpentOnGasForFuelstation:fs];}
                                        yearToDateAggregateBlk:^(FPFuelStation *fs) {return [_stats yearToDateMaxSpentOnGasForFuelstation:fs];}
                                          lastYearAggregateBlk:^(FPFuelStation *fs) {return [_stats lastYearMaxSpentOnGasForFuelstation:fs];}
                                               siblingCountBlk:^{return [_coordDao fuelStationsForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newFuelStationCompareMaxSpentOnGasStatsScreenMakerWithFuelstationInCtx:fuelstation](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newFuelStationCompareMaxSpentOnGasStatsScreenMakerWithFuelstationInCtx:(FPFuelStation *)fuelstation {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:@"Max Spend Comparison"
                                                              headerText:@"MAX MONTHLY SPEND (all time)"
                                                           entityNameBlk:^(FPFuelStation *fs) {return fs.name;}
                                                                  entity:fuelstation
                                                    entitiesToCompareBlk:^{return [_coordDao fuelStationsForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPFuelStation *fs) {return [_stats overallMaxSpentOnGasForFuelstation:fs];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v2 compare:v1]; // descending
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newFuelStationMinSpentOnGasStatsScreenMakerWithFuelstation:(FPFuelStation *)fuelstation {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Min Monthly Spend"
                                           entityTypeLabelText:@"FUELSTATION"
                                                 entityNameBlk:^(FPFuelStation *fs) {return fs.name;}
                                                        entity:fuelstation
                                          aggregatesHeaderText:@"MONTHLY SPEND"
                                        compareButtonTitleText:@"Compare gas stations"
                                           alltimeAggregateBlk:^(FPFuelStation *fs) {return [_stats overallMinSpentOnGasForFuelstation:fs];}
                                        yearToDateAggregateBlk:^(FPFuelStation *fs) {return [_stats yearToDateMinSpentOnGasForFuelstation:fs];}
                                          lastYearAggregateBlk:^(FPFuelStation *fs) {return [_stats lastYearMinSpentOnGasForFuelstation:fs];}
                                               siblingCountBlk:^{return [_coordDao fuelStationsForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newFuelStationCompareMinSpentOnGasStatsScreenMakerWithFuelstationInCtx:fuelstation](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newFuelStationCompareMinSpentOnGasStatsScreenMakerWithFuelstationInCtx:(FPFuelStation *)fuelstation {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:@"Min Spend Comparison"
                                                              headerText:@"MIN MONTHLY SPEND (all time)"
                                                           entityNameBlk:^(FPFuelStation *fs) {return fs.name;}
                                                                  entity:fuelstation
                                                    entitiesToCompareBlk:^{return [_coordDao fuelStationsForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPFuelStation *fs) {return [_stats overallMinSpentOnGasForFuelstation:fs];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v1 compare:v2];
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newFuelStationAvgSpentOnGasStatsScreenMakerWithFuelstation:(FPFuelStation *)fuelstation {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Avg Monthly Spend"
                                           entityTypeLabelText:@"FUELSTATION"
                                                 entityNameBlk:^(FPFuelStation *fs) {return fs.name;}
                                                        entity:fuelstation
                                          aggregatesHeaderText:@"MONTHLY SPEND"
                                        compareButtonTitleText:@"Compare gas stations"
                                           alltimeAggregateBlk:^(FPFuelStation *fs) {return [_stats overallAvgSpentOnGasForFuelstation:fs];}
                                        yearToDateAggregateBlk:^(FPFuelStation *fs) {return [_stats yearToDateAvgSpentOnGasForFuelstation:fs];}
                                          lastYearAggregateBlk:^(FPFuelStation *fs) {return [_stats lastYearAvgSpentOnGasForFuelstation:fs];}
                                               siblingCountBlk:^{return [_coordDao fuelStationsForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newFuelStationCompareAvgSpentOnGasStatsScreenMakerWithFuelstationInCtx:fuelstation](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newFuelStationCompareAvgSpentOnGasStatsScreenMakerWithFuelstationInCtx:(FPFuelStation *)fuelstation {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:@"Avg Spend Comparison"
                                                              headerText:@"AVG MONTHLY SPEND (all time)"
                                                           entityNameBlk:^(FPFuelStation *v) {return v.name;}
                                                                  entity:fuelstation
                                                    entitiesToCompareBlk:^{return [_coordDao fuelStationsForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPFuelStation *v) {return [_stats overallAvgSpentOnGasForFuelstation:v];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v2 compare:v1]; // descending
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newFuelStationSpentOnGasStatsScreenMakerWithFuelstation:(FPFuelStation *)fuelstation {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatController alloc] initWithScreenTitle:@"Total Spend"
                                           entityTypeLabelText:@"GAS STATION"
                                                 entityNameBlk:^(FPFuelStation *v) {return v.name;}
                                                        entity:fuelstation
                                          aggregatesHeaderText:@"TOTAL SPEND"
                                        compareButtonTitleText:@"Compare gas stations"
                                           alltimeAggregateBlk:^(FPFuelStation *fs) {return [_stats overallSpentOnGasForFuelstation:fs];}
                                        yearToDateAggregateBlk:^(FPFuelStation *fs) {return [_stats yearToDateSpentOnGasForFuelstation:fs];}
                                          lastYearAggregateBlk:^(FPFuelStation *fs) {return [_stats lastYearSpentOnGasForFuelstation:fs];}
                                             alltimeDatasetBlk:^(FPFuelStation *fs) {return [_stats overallSpentOnGasDataSetForFuelstation:fs];}
                                          yearToDateDatasetBlk:^(FPFuelStation *fs) {return [_stats yearToDateSpentOnGasDataSetForFuelstation:fs];}
                                            lastYearDatasetBlk:^(FPFuelStation *fs) {return [_stats lastYearSpentOnGasDataSetForFuelstation:fs];}
                                               siblingCountBlk:^{return [_coordDao fuelStationsForUser:user error:[FPUtils localFetchErrorHandlerMaker]()].count;}
                                      comparisonScreenMakerBlk:^{return [self newFuelStationCompareSpentOnGasStatsScreenMakerWithFuelstationInCtx:fuelstation](user);}
                                             valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                     uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newFuelStationCompareSpentOnGasStatsScreenMakerWithFuelstationInCtx:(FPFuelStation *)fuelstation {
  return ^ UIViewController * (FPUser *user) {
    return [[FPCommonStatComparisonController alloc] initWithScreenTitle:@"Spend Comparison"
                                                              headerText:@"TOTAL SPEND (all time)"
                                                           entityNameBlk:^(FPFuelStation *fs) {return fs.name;}
                                                                  entity:fuelstation
                                                    entitiesToCompareBlk:^{return [_coordDao fuelStationsForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                     alltimeAggregateBlk:^(FPFuelStation *fs) {return [_stats overallSpentOnGasForFuelstation:fs];}
                                                       valueFormatterBlk:^(NSDecimalNumber *val) {return [_currencyFormatter stringFromNumber:val];}
                                                              comparator:^(NSArray *o1, NSArray *o2) {
                                                                NSDecimalNumber *v1 = o1[2];
                                                                NSDecimalNumber *v2 = o2[2];
                                                                return [v2 compare:v1]; // descending
                                                              }
                                                               uitoolkit:_uitoolkit];
  };
}

- (FPAuthScreenMaker)newFuelStationCompareSpentOnGasStatsScreenMaker {
  return [self newFuelStationCompareSpentOnGasStatsScreenMakerWithFuelstationInCtx:nil];
}

#pragma mark - Fuel Purchase Log Screens

- (PEEntityValidatorBlk)newFpEnvLogCompositeValidator {
  return ^NSArray *(UIView *fpEnvLogCompositePanel) {
    NSMutableArray *errMsgs = [NSMutableArray array];
    PEEntityValidatorBlk fpLogValidator = [self newFuelPurchaseLogValidator];
    [errMsgs addObjectsFromArray:fpLogValidator(fpEnvLogCompositePanel)];
    PEMessageCollector cannotBeBlankCollector = [PEUIUtils newTfCannotBeEmptyBlkForMsgs:errMsgs
                                                                            entityPanel:fpEnvLogCompositePanel];
    cannotBeBlankCollector(FPEnvLogTagOdometer, @"Odometer cannot be empty.");
    return errMsgs;
  };
}

- (PEEntityValidatorBlk)newFuelPurchaseLogValidator {
  return ^NSArray *(UIView *fpLogPanel) {
    NSMutableArray *errMsgs = [NSMutableArray array];
    FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds =
      (FPFpLogVehicleFuelStationDateDataSourceAndDelegate *)
        [(UITableView *)[fpLogPanel viewWithTag:FPFpLogTagVehicleFuelStationAndDate] dataSource];
    FPVehicle *selectedVehicle = [ds selectedVehicle];
    FPFuelStation *selectedFuelStation = [ds selectedFuelStation];
    if (!selectedVehicle) {
      [errMsgs addObject:@"Must select a vehicle."];
    }
    if (!selectedFuelStation) {
      [errMsgs addObject:@"Must select a gas station."];
    }
    PEMessageCollector cannotBeBlankCollector = [PEUIUtils newTfCannotBeEmptyBlkForMsgs:errMsgs
                                                                            entityPanel:fpLogPanel];
    cannotBeBlankCollector(FPFpLogTagPricePerGallon, @"Gallon price cannot be empty.");
    cannotBeBlankCollector(FPFpLogTagNumGallons, @"Num gallons cannot be empty.");
    cannotBeBlankCollector(FPFplogTagOdometer, @"Odometer cannot be empty.");
    return errMsgs;
  };
}

- (NSArray *)shouldSavePrePostFillupEnvLogs:(FPLogEnvLogComposite *)fpEnvLogComposite {
  BOOL (^isEnvLogEmpty)(FPEnvironmentLog *) = ^BOOL(FPEnvironmentLog *envLog) {
    return ![envLog odometer] &&
    ![envLog reportedAvgMpg] &&
    ![envLog reportedAvgMph] &&
    ![envLog reportedOutsideTemp] &&
    ![envLog reportedDte];
  };
  BOOL shouldSavePreFillupEnvLog = NO;
  BOOL shouldSavePostFillupEnvLog = NO;
  shouldSavePreFillupEnvLog = [[fpEnvLogComposite preFillupEnvLog] reportedDte] && !isEnvLogEmpty([fpEnvLogComposite preFillupEnvLog]);
  shouldSavePostFillupEnvLog = [[fpEnvLogComposite postFillupEnvLog] reportedDte] && !isEnvLogEmpty([fpEnvLogComposite postFillupEnvLog]);
  if (!shouldSavePreFillupEnvLog && !shouldSavePostFillupEnvLog) {
    if (!isEnvLogEmpty([fpEnvLogComposite postFillupEnvLog])) {
      shouldSavePostFillupEnvLog = YES;
    }
  }
  return @[[NSNumber numberWithBool:shouldSavePreFillupEnvLog],
           [NSNumber numberWithBool:shouldSavePostFillupEnvLog]];
}

- (FPAuthScreenMaker)newAddFuelPurchaseLogScreenMakerWithBlk:(PEItemAddedBlk)itemAddedBlk
                                      defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle
                                  defaultSelectedFuelStation:(FPFuelStation *)defaultSelectedFuelStation
                                          listViewController:(PEListViewController *)listViewController {
  return ^ UIViewController * (FPUser *user) {
    NSArray *(^selectionsAndPercents)(UIView *entityPanel, FPLogEnvLogComposite *) = ^ NSArray * (UIView *entityPanel, FPLogEnvLogComposite *fpEnvLogComposite) {
      FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds =
        (FPFpLogVehicleFuelStationDateDataSourceAndDelegate *)[(UITableView *)[entityPanel viewWithTag:FPFpLogTagVehicleFuelStationAndDate] dataSource];
      FPVehicle *selectedVehicle = [ds selectedVehicle];
      FPFuelStation *selectedFuelStation = [ds selectedFuelStation];
      NSArray *shouldSavePrePostFillupEnvLogs = [self shouldSavePrePostFillupEnvLogs:fpEnvLogComposite];
      BOOL shouldSavePreFillupEnvLog = [shouldSavePrePostFillupEnvLogs[0] boolValue];
      BOOL shouldSavePostFillupEnvLog = [shouldSavePrePostFillupEnvLogs[1] boolValue];
      float saveFpLogPercentComplete = 0;
      float savePreFillupEnvLogPercentComplete = 0;
      float savePostFillupEnvLogPercentComplete = 0;
      if (shouldSavePreFillupEnvLog) {
        if (shouldSavePostFillupEnvLog) {
          saveFpLogPercentComplete = 0.4;
          savePreFillupEnvLogPercentComplete = 0.3;
          savePostFillupEnvLogPercentComplete = 0.3;
        } else {
          saveFpLogPercentComplete = 0.5;
          savePreFillupEnvLogPercentComplete = 0.5;
        }
      } else if (shouldSavePostFillupEnvLog) {
        saveFpLogPercentComplete = 0.5;
        savePostFillupEnvLogPercentComplete = 0.5;
      } else {
        saveFpLogPercentComplete = 1.0;
      }
      return @[selectedVehicle,
               selectedFuelStation,
               @(shouldSavePreFillupEnvLog),
               @(shouldSavePostFillupEnvLog),
               @(saveFpLogPercentComplete),
               @(savePreFillupEnvLogPercentComplete),
               @(savePostFillupEnvLogPercentComplete)];
    };
    PESaveNewEntityLocalBlk newFuelPurchaseLogSaverLocal = ^NSArray *(UIView *entityPanel, FPLogEnvLogComposite *fpEnvLogComposite) {
      NSArray *selectionsAndPercentArray = selectionsAndPercents(entityPanel, fpEnvLogComposite);
      FPVehicle *selectedVehicle = selectionsAndPercentArray[0];
      FPFuelStation *selectedFuelStation = selectionsAndPercentArray[1];
      BOOL shouldSavePreFillupEnvLog = [selectionsAndPercentArray[2] boolValue];
      BOOL shouldSavePostFillupEnvLog = [selectionsAndPercentArray[3] boolValue];
      NSMutableArray *saveMessages = [NSMutableArray array];
      [saveMessages addObject:@"Gas log saved locally."];
      [_coordDao saveNewFuelPurchaseLog:[fpEnvLogComposite fpLog]
                                forUser:user
                                vehicle:selectedVehicle
                            fuelStation:selectedFuelStation
                                  error:[FPUtils localSaveErrorHandlerMaker]()];
      if (shouldSavePreFillupEnvLog) {
        if (shouldSavePostFillupEnvLog) {
          [saveMessages addObject:@"Pre-fillup odometer log saved locally."];
        } else {
          [saveMessages addObject:@"Odometer log saved locally."];
        }
        [_coordDao saveNewEnvironmentLog:[fpEnvLogComposite preFillupEnvLog]
                                 forUser:user
                                 vehicle:selectedVehicle
                                   error:[FPUtils localSaveErrorHandlerMaker]()];
      }
      if (shouldSavePostFillupEnvLog) {
        if (shouldSavePreFillupEnvLog) {
          [saveMessages addObject:@"Post-fillup odometer log saved locally."];
        } else {
          [saveMessages addObject:@"Odometer log saved locally."];
        }
        [_coordDao saveNewEnvironmentLog:[fpEnvLogComposite postFillupEnvLog]
                                 forUser:user
                                 vehicle:selectedVehicle
                                   error:[FPUtils localSaveErrorHandlerMaker]()];
      }
      NSString *saveTitle = @"Gas log saved.";
      if (shouldSavePostFillupEnvLog || shouldSavePreFillupEnvLog) {
        if (shouldSavePostFillupEnvLog && shouldSavePreFillupEnvLog) {
          saveTitle = @"Gas and odometer logs saved.";
        } else {
          saveTitle = @"Gas and odometer log saved.";
        }
      }
      [APP refreshTabs];
      return @[saveTitle, saveMessages];
    };
    PESaveNewEntityImmediateSyncBlk newFuelPurchaseLogSaverImmediateSync = ^(UIView *entityPanel,
                                                                             FPLogEnvLogComposite *fpEnvLogComposite,
                                                                             PESyncNotFoundBlk notFoundBlk,
                                                                             PESyncSuccessBlk successBlk,
                                                                             PESyncRetryAfterBlk retryAfterBlk,
                                                                             PESyncServerTempErrorBlk tempErrBlk,
                                                                             PESyncServerErrorBlk errBlk,
                                                                             PESyncConflictBlk conflictBlk,
                                                                             PESyncAuthRequiredBlk authReqdBlk,
                                                                             PESyncDependencyUnsynced depUnsyncedBlk) {
      NSArray *selectionsAndPercentArray = selectionsAndPercents(entityPanel, fpEnvLogComposite);
      FPVehicle *selectedVehicle = selectionsAndPercentArray[0];
      FPFuelStation *selectedFuelStation = selectionsAndPercentArray[1];
      BOOL shouldSavePreFillupEnvLog = [selectionsAndPercentArray[2] boolValue];
      BOOL shouldSavePostFillupEnvLog = [selectionsAndPercentArray[3] boolValue];
      float saveFpLogPercentComplete = [selectionsAndPercentArray[4] floatValue];
      float savePreFillupEnvLogPercentComplete = [selectionsAndPercentArray[5] floatValue];
      float savePostFillupEnvLogPercentComplete = [selectionsAndPercentArray[6] floatValue];
      NSString *mainMsgFragment = @"Gas log";
      if (savePreFillupEnvLogPercentComplete || savePostFillupEnvLogPercentComplete) {
        mainMsgFragment = @"Gas and odometer logs";
      }
      NSString *recordTitle = @"Gas log";
      [_coordDao saveNewAndSyncImmediateFuelPurchaseLog:[fpEnvLogComposite fpLog]
                                                forUser:user
                                                vehicle:selectedVehicle
                                            fuelStation:selectedFuelStation
                                    notFoundOnServerBlk:^{notFoundBlk(saveFpLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                         addlSuccessBlk:^{successBlk(saveFpLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                 addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(saveFpLogPercentComplete, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                                 addlTempRemoteErrorBlk:^{tempErrBlk(saveFpLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                     addlRemoteErrorBlk:^(NSInteger errMask) {errBlk(saveFpLogPercentComplete, mainMsgFragment, recordTitle, [FPUtils computeFpLogErrMsgs:errMask]); [APP refreshTabs];}
                                        addlConflictBlk:^(FPFuelPurchaseLog *latestFplog) {conflictBlk(saveFpLogPercentComplete, mainMsgFragment, recordTitle, latestFplog); [APP refreshTabs];}
                                    addlAuthRequiredBlk:^{authReqdBlk(saveFpLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                           skippedDueToVehicleNotSynced:^{depUnsyncedBlk(saveFpLogPercentComplete, mainMsgFragment, recordTitle, @"The vehicle is not yet saved to the server."); [APP refreshTabs];}
                       skippedDueToFuelStationNotSynced:^{depUnsyncedBlk(saveFpLogPercentComplete, mainMsgFragment, recordTitle, @"The gas station is not yet saved to the server."); [APP refreshTabs];}
                                                  error:[FPUtils localSaveErrorHandlerMaker]()];
      if (shouldSavePreFillupEnvLog) {
        if (shouldSavePostFillupEnvLog) {
          recordTitle = @"Pre-fillup odometer log";
        } else {
          recordTitle = @"Odometer log";
        }
        [_coordDao saveNewAndSyncImmediateEnvironmentLog:[fpEnvLogComposite preFillupEnvLog]
                                                 forUser:user
                                                 vehicle:selectedVehicle
                                     notFoundOnServerBlk:^{notFoundBlk(savePreFillupEnvLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                          addlSuccessBlk:^{successBlk(savePreFillupEnvLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                  addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(savePreFillupEnvLogPercentComplete, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                                  addlTempRemoteErrorBlk:^{tempErrBlk(savePreFillupEnvLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                      addlRemoteErrorBlk:^(NSInteger errMask) {errBlk(savePreFillupEnvLogPercentComplete, mainMsgFragment, recordTitle, [FPUtils computeEnvLogErrMsgs:errMask]); [APP refreshTabs];}
                                         addlConflictBlk:^(FPEnvironmentLog *latestEnvlog) {conflictBlk(savePreFillupEnvLogPercentComplete, mainMsgFragment, recordTitle, latestEnvlog); [APP refreshTabs];}
                                     addlAuthRequiredBlk:^{authReqdBlk(savePreFillupEnvLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                            skippedDueToVehicleNotSynced:^{depUnsyncedBlk(savePreFillupEnvLogPercentComplete, mainMsgFragment, recordTitle, @"The vehicle is not yet saved to the server."); [APP refreshTabs];}
                                                   error:[FPUtils localSaveErrorHandlerMaker]()];
      }
      if (shouldSavePostFillupEnvLog) {
        if (shouldSavePreFillupEnvLog) {
          recordTitle = @"Post-fillup odometer log";
        } else {
          recordTitle = @"Odometer log";
        }
        [_coordDao saveNewAndSyncImmediateEnvironmentLog:[fpEnvLogComposite postFillupEnvLog]
                                                 forUser:user
                                                 vehicle:selectedVehicle
                                     notFoundOnServerBlk:^{notFoundBlk(savePostFillupEnvLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                          addlSuccessBlk:^{successBlk(savePostFillupEnvLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                  addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(savePostFillupEnvLogPercentComplete, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                                  addlTempRemoteErrorBlk:^{tempErrBlk(savePostFillupEnvLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                      addlRemoteErrorBlk:^(NSInteger errMask) {errBlk(savePostFillupEnvLogPercentComplete, mainMsgFragment, recordTitle, [FPUtils computeEnvLogErrMsgs:errMask]); [APP refreshTabs];}
                                         addlConflictBlk:^(FPEnvironmentLog *latestEnvlog) {conflictBlk(savePostFillupEnvLogPercentComplete, mainMsgFragment, recordTitle, latestEnvlog); [APP refreshTabs];}
                                     addlAuthRequiredBlk:^{authReqdBlk(savePostFillupEnvLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                            skippedDueToVehicleNotSynced:^{depUnsyncedBlk(savePostFillupEnvLogPercentComplete, mainMsgFragment, recordTitle, @"The vehicle is not yet saved to the server."); [APP refreshTabs];}
                                                   error:[FPUtils localSaveErrorHandlerMaker]()];
      }
    };
    PEViewDidAppearBlk viewDidAppearBlk = ^(PEAddViewEditController *ctrl) {
      [self deselectSelectedRowForTableOnView:ctrl.view tableViewTag:FPFpLogTagVehicleFuelStationAndDate];
    };
    PEPrepareUIForUserInteractionBlk prepareUIForUserInteractionBlk = ^(PEAddViewEditController *ctrl, UIView *entityFormPanel) {
      if (![ctrl hasPoppedKeyboard]) {
        BOOL (^setFirstResponder)(NSInteger) = ^BOOL(NSInteger tag) {
          UITextField *tf = (UITextField *)[entityFormPanel viewWithTag:tag];
          if (tf && tf.text.length == 0) {
            [tf becomeFirstResponder];
            [ctrl setHasPoppedKeyboard:YES];
            return YES;
          }
          return NO;
        };
        if (!setFirstResponder(FPFpLogTagOctane)) {
          if (!setFirstResponder(FPFpEnvLogCompositeTagPreFillupReportedDte)) {
            if (!setFirstResponder(FPEnvLogTagReportedAvgMpg)) {
              if (!setFirstResponder(FPEnvLogTagReportedAvgMph)) {
                if (!setFirstResponder(FPEnvLogTagOdometer)) { // has to at least have this
                }
              }
            }
          }
        }
      }
    };
    PEEntityAddCancelerBlk addCanceler = ^(PEAddViewEditController *ctrl, BOOL dismissCtrlr, FPLogEnvLogComposite *fpEnvLogComposite) {
      if (fpEnvLogComposite) {
        FPFuelPurchaseLog *fpLog = [fpEnvLogComposite fpLog];
        if (fpLog && [fpLog localMainIdentifier]) {
          [fpLog setEditInProgress:YES];
          [_coordDao cancelEditOfFuelPurchaseLog:fpLog
                                           error:[FPUtils localSaveErrorHandlerMaker]()];
        }
        NSArray *shouldSavePrePostFillupEnvLogs = [self shouldSavePrePostFillupEnvLogs:fpEnvLogComposite];
        BOOL shouldSavePreFillupEnvLog = [shouldSavePrePostFillupEnvLogs[0] boolValue];
        BOOL shouldSavePostFillupEnvLog = [shouldSavePrePostFillupEnvLogs[1] boolValue];
        if (shouldSavePreFillupEnvLog) {
          if ([fpEnvLogComposite preFillupEnvLog] && [[fpEnvLogComposite preFillupEnvLog] localMainIdentifier]) {
            [[fpEnvLogComposite preFillupEnvLog] setEditInProgress:YES];
            [_coordDao cancelEditOfEnvironmentLog:[fpEnvLogComposite preFillupEnvLog]
                                            error:[FPUtils localSaveErrorHandlerMaker]()];
          }
        }
        if (shouldSavePostFillupEnvLog) {
          if ([fpEnvLogComposite postFillupEnvLog] && [[fpEnvLogComposite postFillupEnvLog] localMainIdentifier]) {
            [[fpEnvLogComposite postFillupEnvLog] setEditInProgress:YES];
            [_coordDao cancelEditOfEnvironmentLog:[fpEnvLogComposite postFillupEnvLog]
                                            error:[FPUtils localSaveErrorHandlerMaker]()];
          }
        }
        [APP refreshTabs];
      }
      if (dismissCtrlr) {
        [[ctrl navigationController] dismissViewControllerAnimated:YES completion:nil];
      }
    };
    PEEntitiesFromEntityBlk entitiesFromEntity = ^NSArray *(FPLogEnvLogComposite *fpEnvLogComposite) {
      NSMutableArray *logs = [NSMutableArray array];
      [logs addObject:[fpEnvLogComposite fpLog]];
      FPEnvironmentLog *preFillupEnvlog = [fpEnvLogComposite preFillupEnvLog];
      FPEnvironmentLog *postFillupEnvlog = [fpEnvLogComposite postFillupEnvLog];
      if (preFillupEnvlog) {
        [logs addObject:preFillupEnvlog];
      }
      if (postFillupEnvlog) {
        [logs addObject:postFillupEnvlog];
      }
      return logs;
    };
    PEAddlContentSection addlContentSection = ^(PEAddViewEditController *ctrl, UIView *entityFormPanel, FPLogEnvLogComposite *fpEnvLogComposite) {
      NSArray *selectionsAndPercentArray = selectionsAndPercents(entityFormPanel, fpEnvLogComposite);
      FPVehicle *selectedVehicle = selectionsAndPercentArray[0];
      FPFuelStation *selectedFuelStation = selectionsAndPercentArray[1];
      return [FPScreenToolkit funFactSectionWithNumFunFacts:[_reportViews numGasFunFacts]
                                             nextFunFactBlk:^{ return [_reportViews nextGasFunFact]; }
                                                     record:@[fpEnvLogComposite.fpLog, selectedVehicle, selectedFuelStation]
                                                       user:user
                                             relativeToView:ctrl.view];
    };
    return [PEAddViewEditController addEntityCtrlrWithUitoolkit:_uitoolkit
                                             listViewController:listViewController
                                                   itemAddedBlk:itemAddedBlk
                                           entityFormPanelMaker:[_panelToolkit fpEnvLogCompositeFormPanelMakerWithUser:user
                                                                                                        defaultVehicle:defaultSelectedVehicle
                                                                                                    defaultFuelstation:defaultSelectedFuelStation
                                                                                                               logDate:[NSDate date]]
                                            entityToPanelBinder:[_panelToolkit fpEnvLogCompositeToFpEnvLogCompositePanelBinder]
                                            panelToEntityBinder:[_panelToolkit fpEnvLogCompositeFormPanelToFpEnvLogCompositeBinder]
                                                    entityTitle:@"Gas (and odo.) Logs"
                                              entityAddCanceler:addCanceler
                                                    entityMaker:[_panelToolkit fpEnvLogCompositeMaker]
                                            newEntitySaverLocal:newFuelPurchaseLogSaverLocal
                                    newEntitySaverImmediateSync:newFuelPurchaseLogSaverImmediateSync
                                 prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                               viewDidAppearBlk:viewDidAppearBlk
                                                entityValidator:[self newFpEnvLogCompositeValidator]
                                                isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                 isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                  isOfflineMode:^{ return [APP offlineMode]; }
                                 syncImmediateMBProgressHUDMode:MBProgressHUDModeDeterminate
                                             entitiesFromEntity:entitiesFromEntity
                                          modalOperationStarted:[self commonModalOperationStartedBlock]
                                             modalOperationDone:[self commonModalOperationDoneBlock]
                                    entityAddedNotificationName:FPEntityAddedNotification
                                             addlContentSection:addlContentSection];
  };
}

- (FPAuthScreenMaker)newFuelPurchaseLogDetailScreenMakerWithFpLog:(FPFuelPurchaseLog *)fpLog
                                                   fpLogIndexPath:(NSIndexPath *)fpLogIndexPath
                                                   itemChangedBlk:(PEItemChangedBlk)itemChangedBlk
                                    listViewParentIsVehicleDetail:(BOOL)listViewParentIsVehicleDetail
                                listViewParentIsFuelStationDetail:(BOOL)listViewParentIsFuelStationDetail
                                               listViewController:(PEListViewController *)listViewController {
  return ^ UIViewController * (FPUser *user) {
    void (^refreshVehicleFuelStationTableView)(PEAddViewEditController *, FPFuelPurchaseLog *) = ^(PEAddViewEditController *ctrl, FPFuelPurchaseLog *fpLog) {
      UITableView *vehicleFuelStationDateTableView = (UITableView *)[[ctrl view] viewWithTag:FPFpLogTagVehicleFuelStationAndDate];
      FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds =
        (FPFpLogVehicleFuelStationDateDataSourceAndDelegate *)[vehicleFuelStationDateTableView dataSource];
      FPVehicle *currentFpLogVehicleInDb = [_coordDao vehicleForFuelPurchaseLog:fpLog error:[FPUtils localSaveErrorHandlerMaker]()];
      FPFuelStation *currentFpLogFuelStationInDb = [_coordDao fuelStationForFuelPurchaseLog:fpLog error:[FPUtils localSaveErrorHandlerMaker]()];
      [ds setSelectedVehicle:currentFpLogVehicleInDb];
      [ds setSelectedFuelStation:currentFpLogFuelStationInDb];
      [vehicleFuelStationDateTableView reloadData];
    };
    PEEntityEditPreparerBlk fpLogEditPreparer = ^BOOL(PEAddViewEditController *ctrl, FPFuelPurchaseLog *fpLog) {
      BOOL result = [_coordDao prepareFuelPurchaseLogForEdit:fpLog
                                                     forUser:user
                                                       error:[FPUtils localSaveErrorHandlerMaker]()];
      if (result) {
        // this is needed because the 'prepare' call right above will mutate the currently-selected vehicle
        // and fuelstation such that they will have been copied to their main tables, and given non-nil
        // local main IDs.  Because of this, we need to fresh the in-memory vehicle and fuel station entries
        // in the table view.
        refreshVehicleFuelStationTableView(ctrl, fpLog);
      }
      [APP refreshTabs];
      return result;
    };
    PEEntityEditCancelerBlk fpLogEditCanceler = ^(PEAddViewEditController *ctrl, FPFuelPurchaseLog *fpLog) {
      [_coordDao cancelEditOfFuelPurchaseLog:fpLog error:[FPUtils localSaveErrorHandlerMaker]()];
      refreshVehicleFuelStationTableView(ctrl, fpLog);
      [APP refreshTabs];
    };
    PESaveEntityBlk fpLogSaver = ^(PEAddViewEditController *ctrl, FPFuelPurchaseLog *fpLog) {
      FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds =
        (FPFpLogVehicleFuelStationDateDataSourceAndDelegate *)
          [(UITableView *)[[ctrl view] viewWithTag:FPFpLogTagVehicleFuelStationAndDate] dataSource];
      FPVehicle *selectedVehicle = [ds selectedVehicle];
      FPFuelStation *selectedFuelStation = [ds selectedFuelStation];
      [_coordDao saveFuelPurchaseLog:fpLog
                             forUser:user
                             vehicle:selectedVehicle
                         fuelStation:selectedFuelStation
                               error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEMarkAsDoneEditingLocalBlk doneEditingFuelPurchaseLogLocal = ^(PEAddViewEditController *ctrl, FPFuelPurchaseLog *fpLog) {
      [_coordDao markAsDoneEditingFuelPurchaseLog:fpLog error:[FPUtils localSaveErrorHandlerMaker]()];
      [APP refreshTabs];
    };
    PEMarkAsDoneEditingImmediateSyncBlk doneEditingFuelPurchaseLogImmediateSync = ^(PEAddViewEditController *ctrl,
                                                                FPFuelPurchaseLog *fpLog,
                                                                PESyncNotFoundBlk notFoundBlk,
                                                                PESyncSuccessBlk successBlk,
                                                                PESyncRetryAfterBlk retryAfterBlk,
                                                                PESyncServerTempErrorBlk tempErrBlk,
                                                                PESyncServerErrorBlk errBlk,
                                                                PESyncConflictBlk conflictBlk,
                                                                PESyncAuthRequiredBlk authReqdBlk,
                                                                PESyncDependencyUnsynced depUnsyncedBlk) {
      NSString *mainMsgFragment = @"saving gas log to the server";
      NSString *recordTitle = @"Gas log";
      [_coordDao markAsDoneEditingAndSyncFuelPurchaseLogImmediate:fpLog
                                                          forUser:user
                                              notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                   addlSuccessBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                           addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                                           addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                               addlRemoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeFpLogErrMsgs:errMask]); [APP refreshTabs];}
                                                  addlConflictBlk:^(FPFuelPurchaseLog *latestFplog) {conflictBlk(1, mainMsgFragment, recordTitle, latestFplog); [APP refreshTabs];}
                                              addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                     skippedDueToVehicleNotSynced:^{depUnsyncedBlk(1, mainMsgFragment, recordTitle, @"The vehicle is not yet saved to the server."); [APP refreshTabs];}
                                 skippedDueToFuelStationNotSynced:^{depUnsyncedBlk(1, mainMsgFragment, recordTitle, @"The gas station is not yet saved to the server."); [APP refreshTabs];}
                                                            error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEUploaderBlk uploader = ^(PEAddViewEditController *ctrl,
                               FPFuelPurchaseLog *fpLog,
                               PESyncNotFoundBlk notFoundBlk,
                               PESyncSuccessBlk successBlk,
                               PESyncRetryAfterBlk retryAfterBlk,
                               PESyncServerTempErrorBlk tempErrBlk,
                               PESyncServerErrorBlk errBlk,
                               PESyncConflictBlk conflictBlk,
                               PESyncAuthRequiredBlk authReqdBlk,
                               PESyncDependencyUnsynced depUnsyncedBlk) {
      NSString *mainMsgFragment = @"saving gas log to the server";
      NSString *recordTitle = @"Gas log";
      [_coordDao flushUnsyncedChangesToFuelPurchaseLog:fpLog
                                               forUser:user
                                   notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                        addlSuccessBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                addlRemoteStoreBusyBlk:^(NSDate *retryAfter){retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                                addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                    addlRemoteErrorBlk:^(NSInteger errMask){errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeFpLogErrMsgs:errMask]); [APP refreshTabs];}
                                       addlConflictBlk:^(FPFuelPurchaseLog *latestFplog) {conflictBlk(1, mainMsgFragment, recordTitle, latestFplog); [APP refreshTabs];}
                                   addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                          skippedDueToVehicleNotSynced:^{depUnsyncedBlk(1, mainMsgFragment, recordTitle, @"The vehicle is not yet saved to the server."); [APP refreshTabs];}
                      skippedDueToFuelStationNotSynced:^{depUnsyncedBlk(1, mainMsgFragment, recordTitle, @"The gas station is not yet saved to the server."); [APP refreshTabs];}
                                                 error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PENumRemoteDepsNotLocal numRemoteDepsNotLocalBlk = ^ NSInteger (FPFuelPurchaseLog *remoteFplog) {
      FPVehicle *vehicle = [_coordDao masterVehicleWithGlobalId:[remoteFplog vehicleGlobalIdentifier] error:[FPUtils localFetchErrorHandlerMaker]()];
      FPFuelStation *fuelstation = [_coordDao masterFuelstationWithGlobalId:[remoteFplog fuelStationGlobalIdentifier] error:[FPUtils localFetchErrorHandlerMaker]()];
      NSInteger numNonLocalDeps = 0;
      if (!vehicle) numNonLocalDeps++;
      if (!fuelstation) numNonLocalDeps++;
      return numNonLocalDeps;
    };
    PEDependencyFetcherBlk depFetcherBlk = ^(PEAddViewEditController *ctrl,
                                             FPFuelPurchaseLog *remoteFplog,
                                             PESyncNotFoundBlk notFoundBlk,
                                             PESyncSuccessBlk successBlk,
                                             PESyncRetryAfterBlk retryAfterBlk,
                                             PESyncServerTempErrorBlk tempErrBlk,
                                             PESyncAuthRequiredBlk authReqdBlk) {
      FPVehicle *vehicle = [_coordDao masterVehicleWithGlobalId:[remoteFplog vehicleGlobalIdentifier] error:[FPUtils localFetchErrorHandlerMaker]()];
      FPFuelStation *fuelstation = [_coordDao masterFuelstationWithGlobalId:[remoteFplog fuelStationGlobalIdentifier] error:[FPUtils localFetchErrorHandlerMaker]()];
      float percentOfFetching = 1.0;
      if (!vehicle && !fuelstation) {
        percentOfFetching = 0.5;
      }
      if (!vehicle) {
        NSString *mainMsgFragment = @"fetching vehicle";
        NSString *recordTitle = @"Vehicle";
        [_coordDao fetchAndSaveNewVehicleWithGlobalId:[remoteFplog vehicleGlobalIdentifier]
                                              forUser:user
                                  notFoundOnServerBlk:^{notFoundBlk(percentOfFetching, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                       addlSuccessBlk:^(FPVehicle *fetchedVehicle) {successBlk(percentOfFetching, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                   remoteStoreBusyBlk:^(NSDate *retryAfter){retryAfterBlk(percentOfFetching, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                                   tempRemoteErrorBlk:^{tempErrBlk(percentOfFetching, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                  addlAuthRequiredBlk:^{authReqdBlk(percentOfFetching, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                error:[FPUtils localSaveErrorHandlerMaker]()];
      }
      if (!fuelstation) {
        NSString *mainMsgFragment = @"fetching gas station";
        NSString *recordTitle = @"Gas station";
        [_coordDao fetchAndSaveNewFuelstationWithGlobalId:[remoteFplog fuelStationGlobalIdentifier]
                                                  forUser:user
                                      notFoundOnServerBlk:^{notFoundBlk(percentOfFetching, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                           addlSuccessBlk:^(FPFuelStation *fetchedFuelstation) {successBlk(percentOfFetching, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                       remoteStoreBusyBlk:^(NSDate *retryAfter){retryAfterBlk(percentOfFetching, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                                       tempRemoteErrorBlk:^{tempErrBlk(percentOfFetching, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                      addlAuthRequiredBlk:^{authReqdBlk(percentOfFetching, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                    error:[FPUtils localSaveErrorHandlerMaker]()];
      }
    };
    PEMergeBlk mergeBlk = ^ NSDictionary * (PEAddViewEditController *ctrl, FPFuelPurchaseLog *localFplog, FPFuelPurchaseLog *remoteFplog) {
      FPFuelPurchaseLog *masterFplog = [_coordDao masterFplogWithId:[localFplog localMasterIdentifier]
                                                                         error:[FPUtils localFetchErrorHandlerMaker]()];
      UITableView *vehFsAndDateTableView = (UITableView *)[[ctrl view] viewWithTag:FPFpLogTagVehicleFuelStationAndDate];
      FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds = (FPFpLogVehicleFuelStationDateDataSourceAndDelegate *)[vehFsAndDateTableView dataSource];
      FPVehicle *vehicleForLocalFplog = [ds selectedVehicle];
      FPVehicle *vehicleForMasterFplog = [_coordDao masterVehicleForMasterFpLog:masterFplog error:[FPUtils localFetchErrorHandlerMaker]()];
      FPVehicle *vehicleForRemoteFplog = [_coordDao masterVehicleWithGlobalId:[remoteFplog vehicleGlobalIdentifier] error:[FPUtils localFetchErrorHandlerMaker]()];
      NSString *origLocalFplogVehicleGlobalId = [vehicleForLocalFplog globalIdentifier];
      [localFplog setVehicleGlobalIdentifier:[vehicleForLocalFplog globalIdentifier]];
      [masterFplog setVehicleGlobalIdentifier:[vehicleForMasterFplog globalIdentifier]];
      [remoteFplog setVehicleGlobalIdentifier:[vehicleForRemoteFplog globalIdentifier]];
      FPFuelStation *fuelstationForLocalFplog = [ds selectedFuelStation];
      FPFuelStation *fuelstationForMasterFplog = [_coordDao masterFuelstationForMasterFpLog:masterFplog error:[FPUtils localFetchErrorHandlerMaker]()];
      FPFuelStation *fuelstationForRemoteFplog = [_coordDao masterFuelstationWithGlobalId:[remoteFplog fuelStationGlobalIdentifier] error:[FPUtils localFetchErrorHandlerMaker]()];
      NSString *origLocalFplogFuelstationGlobalId = [fuelstationForLocalFplog globalIdentifier];
      [localFplog setFuelStationGlobalIdentifier:[fuelstationForLocalFplog globalIdentifier]];
      [masterFplog setFuelStationGlobalIdentifier:[fuelstationForMasterFplog globalIdentifier]];
      [remoteFplog setFuelStationGlobalIdentifier:[fuelstationForRemoteFplog globalIdentifier]];
      NSDictionary *mergeConflicts = [FPFuelPurchaseLog mergeRemoteFplog:remoteFplog withLocalFplog:localFplog localMasterFplog:masterFplog];
      if (![origLocalFplogVehicleGlobalId isEqualToString:[localFplog vehicleGlobalIdentifier]]) {
        [ds setSelectedVehicle:vehicleForRemoteFplog];
      }
      if (![origLocalFplogFuelstationGlobalId isEqualToString:[localFplog fuelStationGlobalIdentifier]]) {
        [ds setSelectedFuelStation:fuelstationForRemoteFplog];
      }
      return mergeConflicts;
    };
    PEConflictResolveFields conflictResolveFieldsBlk =
    ^(PEAddViewEditController *ctrl, NSDictionary *mergeConflicts, FPFuelPurchaseLog *localFplog, FPFuelPurchaseLog *remoteFplog) {
      UITableView *vehFsAndDateTableView = (UITableView *)[[ctrl view] viewWithTag:FPFpLogTagVehicleFuelStationAndDate];
      FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds = (FPFpLogVehicleFuelStationDateDataSourceAndDelegate *)[vehFsAndDateTableView dataSource];
      FPVehicle *vehicleForLocalFplog = [ds selectedVehicle];
      FPVehicle *vehicleForRemoteFplog = [_coordDao masterVehicleWithGlobalId:[remoteFplog vehicleGlobalIdentifier]
                                                                                   error:[FPUtils localFetchErrorHandlerMaker]()];
      FPFuelStation *fuelstationForLocalFplog = [ds selectedFuelStation];
      FPFuelStation *fuelstationForRemoteFplog = [_coordDao masterFuelstationWithGlobalId:[remoteFplog fuelStationGlobalIdentifier]
                                                                                               error:[FPUtils localFetchErrorHandlerMaker]()];
      PEOrNil orNil = [PEUtils orNilMaker];
      NSMutableArray *fields = [NSMutableArray arrayWithCapacity:mergeConflicts.count];
      [mergeConflicts enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *fieldName = key;
        if ([fieldName isEqualToString:FPFplogVehicleGlobalIdField]) {
          [fields addObject:@[@"Vehicle:", @(FPFpLogTagVehicle), orNil([vehicleForLocalFplog name]), orNil([vehicleForRemoteFplog name])]];
        } else if ([fieldName isEqualToString:FPFplogFuelstationGlobalIdField]) {
          [fields addObject:@[@"Gas station:", @(FPFpLogTagFuelstation), orNil([fuelstationForLocalFplog name]), orNil([fuelstationForRemoteFplog name])]];
        } else if ([fieldName isEqualToString:FPFplogPurchasedAtField]) {
          [fields addObject:@[@"Purchased:", @(FPFpLogTagPurchasedDate), [PEUtils stringFromDate:[localFplog purchasedAt] withPattern:@"MM/dd/YYYY"], [PEUtils stringFromDate:[remoteFplog purchasedAt] withPattern:@"MM/dd/YYYY"]]];
        } else if ([fieldName isEqualToString:FPFplogOctaneField]) {
          [fields addObject:@[@"Octane:", @(FPFpLogTagOctane), [PEUtils descriptionOrEmptyIfNil:[localFplog octane]], [PEUtils descriptionOrEmptyIfNil:[remoteFplog octane]]]];
        } else if ([fieldName isEqualToString:FPFplogOdometerField]) {
          [fields addObject:@[@"Odometer:", @(FPFplogTagOdometer), [PEUtils descriptionOrEmptyIfNil:[localFplog odometer]], [PEUtils descriptionOrEmptyIfNil:[remoteFplog odometer]]]];
        } else if ([fieldName isEqualToString:FPFplogGallonPriceField]) {
          [fields addObject:@[@"Price per gallon:", @(FPFpLogTagPricePerGallon), [PEUtils descriptionOrEmptyIfNil:[localFplog gallonPrice]], [PEUtils descriptionOrEmptyIfNil:[remoteFplog gallonPrice]]]];
        } else if ([fieldName isEqualToString:FPFplogCarWashPerGallonDiscountField]) {
          [fields addObject:@[@"Car Wash per-gal disc.:", @(FPFpLogTagCarWashPerGallonDiscount), [PEUtils descriptionOrEmptyIfNil:[localFplog carWashPerGallonDiscount]], [PEUtils descriptionOrEmptyIfNil:[remoteFplog carWashPerGallonDiscount]]]];
        } else if ([fieldName isEqualToString:FPFplogGotCarWashField]) {
          [fields addObject:@[@"Got car wash?", @(FPFpLogTagGotCarWash), [PEUtils yesNoFromBool:[localFplog gotCarWash]], [PEUtils yesNoFromBool:[remoteFplog gotCarWash]]]];
        } else if ([fieldName isEqualToString:FPFplogNumGallonsField]) {
          [fields addObject:@[@"Num gallons:", @(FPFpLogTagNumGallons), [PEUtils descriptionOrEmptyIfNil:[localFplog numGallons]], [PEUtils descriptionOrEmptyIfNil:[remoteFplog numGallons]]]];
        }
      }];
      return fields;
    };
    PEConflictResolvedEntity conflictResolvedEntityBlk =
    ^ id (PEAddViewEditController *ctrl, NSDictionary *mergeConflicts, NSArray *valueLabels, FPFuelPurchaseLog *localFplog, FPFuelPurchaseLog *remoteFplog) {
      FPFuelPurchaseLog *resolvedFplog = [localFplog copy];
      NSInteger numValueLabels = [valueLabels count];
      UITableView *vehFsAndDateTableView = (UITableView *)[[ctrl view] viewWithTag:FPFpLogTagVehicleFuelStationAndDate];
      FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds = (FPFpLogVehicleFuelStationDateDataSourceAndDelegate *)[vehFsAndDateTableView dataSource];
      for (int i = 0; i < numValueLabels; i++) {
        NSArray *valueLabelPair = valueLabels[i];
        UILabel *remoteValue = valueLabelPair[1];
        if (remoteValue.tag > 0) {
          switch (remoteValue.tag) {
            case FPFpLogTagOctane:
              [resolvedFplog setOctane:[remoteFplog octane]];
              break;
            case FPFplogTagOdometer:
              [resolvedFplog setOdometer:[remoteFplog odometer]];
              break;
            case FPFpLogTagPricePerGallon:
              [resolvedFplog setGallonPrice:[remoteFplog gallonPrice]];
              break;
            case FPFpLogTagCarWashPerGallonDiscount:
              [resolvedFplog setCarWashPerGallonDiscount:[remoteFplog carWashPerGallonDiscount]];
              break;
            case FPFpLogTagGotCarWash:
              [resolvedFplog setGotCarWash:[remoteFplog gotCarWash]];
              break;
            case FPFpLogTagNumGallons:
              [resolvedFplog setNumGallons:[remoteFplog numGallons]];
              break;
            case FPFpLogTagPurchasedDate:
              [resolvedFplog setPurchasedAt:[remoteFplog purchasedAt]];
              [ds setPickedLogDate:[resolvedFplog purchasedAt]];
              break;
            case FPFpLogTagVehicle:
            {
              FPVehicle *vehicleForRemoteFplog = [_coordDao masterVehicleWithGlobalId:[remoteFplog vehicleGlobalIdentifier]
                                                                                           error:[FPUtils localFetchErrorHandlerMaker]()];
              [ds setSelectedVehicle:vehicleForRemoteFplog];
              break;
            }
            case FPFpLogTagFuelstation:
            {
              FPFuelStation *fuelstationForRemoteFplog = [_coordDao masterFuelstationWithGlobalId:[remoteFplog fuelStationGlobalIdentifier]
                                                                                                       error:[FPUtils localFetchErrorHandlerMaker]()];
              [ds setSelectedFuelStation:fuelstationForRemoteFplog];
              break;
            }
          }
        }
      }
      return resolvedFplog;
    };
    PEUpdateDepsPanel updateDepsPanel = ^(PEAddViewEditController *ctrl, FPFuelPurchaseLog *remoteFplog) {
      UITableView *vehFsAndDateTableView = (UITableView *)[[ctrl view] viewWithTag:FPFpLogTagVehicleFuelStationAndDate];
      FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds = (FPFpLogVehicleFuelStationDateDataSourceAndDelegate *)[vehFsAndDateTableView dataSource];
      FPVehicle *vehicleForRemoteFplog = [_coordDao masterVehicleWithGlobalId:[remoteFplog vehicleGlobalIdentifier]
                                                                                   error:[FPUtils localFetchErrorHandlerMaker]()];
      FPFuelStation *fuelstationForRemoteFplog = [_coordDao masterFuelstationWithGlobalId:[remoteFplog fuelStationGlobalIdentifier]
                                                                                               error:[FPUtils localFetchErrorHandlerMaker]()];
      [ds setSelectedVehicle:vehicleForRemoteFplog];
      [ds setSelectedFuelStation:fuelstationForRemoteFplog];
    };
    PEDownloaderBlk downloaderBlk = ^ (PEAddViewEditController *ctrl,
                                       FPFuelPurchaseLog *fplog,
                                       PESyncNotFoundBlk notFoundBlk,
                                       PEDownloadSuccessBlk successBlk,
                                       PESyncRetryAfterBlk retryAfterBlk,
                                       PESyncServerTempErrorBlk tempErrBlk,
                                       PESyncAuthRequiredBlk authReqdBlk) {
      NSString *mainMsgFragment = @"fetching gas log";
      NSString *recordTitle = @"Gas log";
      float percentOfFetching = 1.0;
      [_coordDao fetchFuelPurchaseLogWithGlobalId:[fplog globalIdentifier]
                                  ifModifiedSince:[fplog updatedAt]
                                          forUser:user
                              notFoundOnServerBlk:^{notFoundBlk(percentOfFetching, mainMsgFragment, recordTitle);}
                                       successBlk:^(FPFuelPurchaseLog *fetchedFplog) {successBlk(percentOfFetching, mainMsgFragment, recordTitle, fetchedFplog);}
                               remoteStoreBusyBlk:^(NSDate *retryAfter){retryAfterBlk(percentOfFetching, mainMsgFragment, recordTitle, retryAfter);}
                               tempRemoteErrorBlk:^{tempErrBlk(percentOfFetching, mainMsgFragment, recordTitle);}
                              addlAuthRequiredBlk:^{authReqdBlk(percentOfFetching, mainMsgFragment, recordTitle); [APP refreshTabs];}];
    };
    PEPostDownloaderSaver postDownloadSaverBlk = ^ (PEAddViewEditController *ctrl,
                                                    FPFuelPurchaseLog *downloadedFplog,
                                                    FPFuelPurchaseLog *fplog) {
      FPVehicle *vehicleForDownloadedFplog = [_coordDao masterVehicleWithGlobalId:[downloadedFplog vehicleGlobalIdentifier]
                                                                                       error:[FPUtils localFetchErrorHandlerMaker]()];
      FPFuelStation *fuelstationForDownloadedFplog = [_coordDao masterFuelstationWithGlobalId:[downloadedFplog fuelStationGlobalIdentifier]
                                                                                                   error:[FPUtils localFetchErrorHandlerMaker]()];
      [_coordDao saveMasterFuelPurchaseLog:downloadedFplog
                                           forVehicle:vehicleForDownloadedFplog
                                       forFuelstation:fuelstationForDownloadedFplog
                                              forUser:user
                                                error:[FPUtils localSaveErrorHandlerMaker]()];
      UITableView *vehFsAndDateTableView = (UITableView *)[[ctrl view] viewWithTag:FPFpLogTagVehicleFuelStationAndDate];
      FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds = (FPFpLogVehicleFuelStationDateDataSourceAndDelegate *)[vehFsAndDateTableView dataSource];
      [ds setSelectedVehicle:vehicleForDownloadedFplog];
      [ds setSelectedFuelStation:fuelstationForDownloadedFplog];
      [vehFsAndDateTableView reloadData];
    };
    PEPrepareUIForUserInteractionBlk prepareUIForUserInteractionBlk = ^(PEAddViewEditController *ctrl, UIView *entityFormPanel) {
      if (![ctrl hasPoppedKeyboard]) {
        BOOL (^setFirstResponder)(NSInteger) = ^BOOL(NSInteger tag) {
          UITextField *tf = (UITextField *)[entityFormPanel viewWithTag:tag];
          if (tf) {
            [tf becomeFirstResponder];
            [ctrl setHasPoppedKeyboard:YES];
            return YES;
          }
          return NO;
        };
        if (!setFirstResponder(FPFpLogTagOctane)) {
          if (!setFirstResponder(FPFplogTagOdometer)) {} // has to at least have this
        }
      }
    };
    PEViewDidAppearBlk viewDidAppearBlk = ^(PEAddViewEditController *ctrl) {
      [self deselectSelectedRowForTableOnView:ctrl.view tableViewTag:FPFpLogTagVehicleFuelStationAndDate];
    };
    return [PEAddViewEditController viewEntityCtrlrWithParentEntity:user
                                                             entity:fpLog
                                                 listViewController:listViewController
                                                    entityIndexPath:fpLogIndexPath
                                                          uitoolkit:_uitoolkit
                                                     itemChangedBlk:itemChangedBlk
                                               entityFormPanelMaker:[_panelToolkit fplogFormPanelMakerWithUser:user
                                                                                             defaultVehicleBlk:^{return [_coordDao vehicleForFuelPurchaseLog:fpLog error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                                                         defaultFuelstationBlk:^{return [_coordDao fuelStationForFuelPurchaseLog:fpLog error:[FPUtils localFetchErrorHandlerMaker]()];}
                                                                                                       logDate:[fpLog purchasedAt]]
                                               entityViewPanelMaker:[_panelToolkit fplogViewPanelMakerWithUser:user]
                                                entityToPanelBinder:[_panelToolkit fplogToFplogPanelBinder]
                                                panelToEntityBinder:[_panelToolkit fplogFormPanelToFplogBinder]
                                                        entityTitle:@"Gas Log"
                                               panelEnablerDisabler:[_panelToolkit fplogFormPanelEnablerDisabler]
                                                  entityAddCanceler:nil
                                                 entityEditPreparer:fpLogEditPreparer
                                                 entityEditCanceler:fpLogEditCanceler
                                                        entitySaver:fpLogSaver
                                             doneEditingEntityLocal:doneEditingFuelPurchaseLogLocal
                                     doneEditingEntityImmediateSync:doneEditingFuelPurchaseLogImmediateSync
                                                    isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                     isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                      isOfflineMode:^{ return [APP offlineMode]; }
                                     syncImmediateMBProgressHUDMode:MBProgressHUDModeIndeterminate
                                     prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                                   viewDidAppearBlk:viewDidAppearBlk
                                                    entityValidator:[self newFuelPurchaseLogValidator]
                                                           uploader:uploader
                                              numRemoteDepsNotLocal:numRemoteDepsNotLocalBlk
                                                              merge:mergeBlk
                                                  fetchDependencies:depFetcherBlk
                                                    updateDepsPanel:updateDepsPanel
                                                         downloader:downloaderBlk
                                                  postDownloadSaver:postDownloadSaverBlk
                                              conflictResolveFields:conflictResolveFieldsBlk
                                             conflictResolvedEntity:conflictResolvedEntityBlk
                                                itemChildrenCounter:nil
                                                itemChildrenMsgsBlk:nil
                                                        itemDeleter:[self fplogItemDeleterForUser:user]
                                                   itemLocalDeleter:[self fplogItemLocalDeleter]
                                              modalOperationStarted:[self commonModalOperationStartedBlock]
                                                 modalOperationDone:[self commonModalOperationDoneBlock]
                                      entityUpdatedNotificationName:FPEntityUpdatedNotification
                                      entityRemovedNotificationName:FPEntityDeletedNotification];
  };
}

- (PEItemDeleter)fplogItemDeleterForUser:(FPUser *)user {
  PEItemDeleter itemDeleter = ^ (UIViewController *listViewController,
                                 FPFuelPurchaseLog *fplog,
                                 NSIndexPath *indexPath,
                                 PESyncNotFoundBlk notFoundBlk,
                                 PESyncSuccessBlk successBlk,
                                 PESyncRetryAfterBlk retryAfterBlk,
                                 PESyncServerTempErrorBlk tempErrBlk,
                                 PESyncServerErrorBlk errBlk,
                                 PESyncConflictBlk conflictBlk,
                                 PESyncAuthRequiredBlk authReqdBlk) {
    NSString *mainMsgFragment = @"deleting gas log";
    NSString *recordTitle = @"Gas log";
    [_coordDao deleteFuelPurchaseLog:fplog
                             forUser:user
                 notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                      addlSuccessBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                  remoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                  tempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                      remoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeEnvLogErrMsgs:errMask]); [APP refreshTabs];}
                         conflictBlk:^(FPFuelPurchaseLog *latestFplog) {conflictBlk(1, mainMsgFragment, recordTitle, latestFplog); [APP refreshTabs];}
                 addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                               error:[FPUtils localSaveErrorHandlerMaker]()];
  };
  return itemDeleter;
}

- (PEItemLocalDeleter)fplogItemLocalDeleter {
  return ^ (UIViewController *listViewController, FPFuelPurchaseLog *fplog, NSIndexPath *indexPath) {
    [_coordDao deleteFuelPurchaseLog:fplog error:[FPUtils localSaveErrorHandlerMaker]()];
    [APP refreshTabs];
  };
}

- (FPAuthScreenMaker)newViewFuelPurchaseLogsScreenMaker {
  return ^ UIViewController *(FPUser *user) {
    void (^addFpLogAction)(PEListViewController *, PEItemAddedBlk) =
    ^(PEListViewController *listViewCtrlr, PEItemAddedBlk itemAddedBlk) {
      UIViewController *addFpLogScreen =
      [self newAddFuelPurchaseLogScreenMakerWithBlk:itemAddedBlk
                             defaultSelectedVehicle:[_coordDao vehicleForMostRecentFuelPurchaseLogForUser:user
                                                                                                    error:[FPUtils localFetchErrorHandlerMaker]()]
                         defaultSelectedFuelStation:[_coordDao defaultFuelStationForNewFuelPurchaseLogForUser:user
                                                                                              currentLocation:[APP latestLocation]
                                                                                                        error:[FPUtils localFetchErrorHandlerMaker]()]
                                 listViewController:listViewCtrlr](user);
      [listViewCtrlr presentViewController:[PEUIUtils navigationControllerWithController:addFpLogScreen navigationBarHidden:NO]
                                  animated:YES
                                completion:nil];
    };
    FPDetailViewMaker fpLogDetailViewMaker =
    ^UIViewController *(PEListViewController *listViewCtrlr,
                        id dataObject,
                        NSIndexPath *indexPath,
                        PEItemChangedBlk itemChangedBlk) {
      return [self newFuelPurchaseLogDetailScreenMakerWithFpLog:dataObject
                                                 fpLogIndexPath:indexPath
                                                 itemChangedBlk:itemChangedBlk
                                  listViewParentIsVehicleDetail:YES
                              listViewParentIsFuelStationDetail:NO
                                             listViewController:listViewCtrlr](user);
    };
    PEPageLoaderBlk pageLoader = ^ NSArray * (FPFuelPurchaseLog *lastFpLog) {
      return [_coordDao fuelPurchaseLogsForUser:user
                                       pageSize:PAGINATION_PAGE_SIZE
                               beforeDateLogged:[lastFpLog purchasedAt]
                                          error:[FPUtils localFetchErrorHandlerMaker]()];
    };
    NSArray *initialFpLogs = [_coordDao fuelPurchaseLogsForUser:user
                                                       pageSize:PAGINATION_PAGE_SIZE
                                                          error:[FPUtils localFetchErrorHandlerMaker]()];
    PEDoesEntityBelongToListView doesEntityBelongToThisListViewBlk = ^BOOL(PELMMainSupport *entity) {
      return YES;
    };
    PEWouldBeIndexOfEntity wouldBeIndexBlk = ^ NSInteger (PELMMainSupport *entity) {
      FPFuelPurchaseLog *fpLog = (FPFuelPurchaseLog *)entity;
      return [_coordDao numFuelPurchaseLogsForUser:user
                                         newerThan:[fpLog purchasedAt]
                                             error:[FPUtils localFetchErrorHandlerMaker]()];
    };
    PESyncViewStyler tableCellStyler = [PELMUIUtils syncViewStylerWithTitleBlk:^(FPFuelPurchaseLog *fpLog) {return [PEUtils stringFromDate:[fpLog purchasedAt] withPattern:@"MM/dd/YYYY"];}
                                                        alwaysTopifyTitleLabel:NO
                                                                     uitoolkit:_uitoolkit
                                                          subtitleLeftHPadding:15.0
                                                      subtitleFitToWidthFactor:1.0
                                                                    isLoggedIn:[APP isUserLoggedIn]];
    return [[PEListViewController alloc] initWithClassOfDataSourceObjects:[FPFuelPurchaseLog class]
                                                                    title:@"Gas Logs"
                                                    isPaginatedDataSource:YES
                                                          tableCellStyler:tableCellStyler
                                                       itemSelectedAction:nil
                                                      initialSelectedItem:nil
                                                            addItemAction:addFpLogAction
                                                           cellIdentifier:@"FPFuelPurchaseLogCell"
                                                           initialObjects:initialFpLogs
                                                               pageLoader:pageLoader
                                                           heightForCellsBlk:[self heightForCellsBlk]
                                                          detailViewMaker:fpLogDetailViewMaker
                                                                uitoolkit:_uitoolkit
                                           doesEntityBelongToThisListView:doesEntityBelongToThisListViewBlk
                                                     wouldBeIndexOfEntity:wouldBeIndexBlk
                                                          isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                           isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                      itemChildrenCounter:nil
                                                      itemChildrenMsgsBlk:nil
                                                              itemDeleter:[self fplogItemDeleterForUser:user]
                                                         itemLocalDeleter:[self fplogItemLocalDeleter]];
  };
}

- (FPAuthScreenMaker)newViewFuelPurchaseLogsScreenMakerForVehicleInCtx {
  return ^ UIViewController *(FPVehicle *vehicle) {
    FPUser *user = [_coordDao userForVehicle:vehicle error:[FPUtils localFetchErrorHandlerMaker]()];
    void (^addFpLogAction)(PEListViewController *, PEItemAddedBlk) =
      ^(PEListViewController *listViewCtrlr, PEItemAddedBlk itemAddedBlk) {
      UIViewController *addFpLogScreen =
        [self newAddFuelPurchaseLogScreenMakerWithBlk:itemAddedBlk
                               defaultSelectedVehicle:vehicle
                           defaultSelectedFuelStation:
                             [_coordDao defaultFuelStationForNewFuelPurchaseLogForUser:user
                                                                       currentLocation:[APP latestLocation]
                                                                                 error:[FPUtils localFetchErrorHandlerMaker]()]
                                    listViewController:listViewCtrlr](user);
      [listViewCtrlr presentViewController:[PEUIUtils navigationControllerWithController:addFpLogScreen navigationBarHidden:NO]
                                  animated:YES
                                completion:nil];
    };
    FPDetailViewMaker fpLogDetailViewMaker =
      ^UIViewController *(PEListViewController *listViewCtrlr,
                          id dataObject,
                          NSIndexPath *indexPath,
                          PEItemChangedBlk itemChangedBlk) {
      return [self newFuelPurchaseLogDetailScreenMakerWithFpLog:dataObject
                                                 fpLogIndexPath:indexPath
                                                 itemChangedBlk:itemChangedBlk
                                  listViewParentIsVehicleDetail:YES
                              listViewParentIsFuelStationDetail:NO
                                             listViewController:listViewCtrlr](user);
    };
    PEPageLoaderBlk pageLoader = ^ NSArray * (FPFuelPurchaseLog *lastFpLog) {
      return [_coordDao fuelPurchaseLogsForVehicle:vehicle
                                          pageSize:PAGINATION_PAGE_SIZE
                                  beforeDateLogged:[lastFpLog purchasedAt]
                                             error:[FPUtils localFetchErrorHandlerMaker]()];
    };
    NSArray *initialFpLogs = [_coordDao fuelPurchaseLogsForVehicle:vehicle
                                                          pageSize:PAGINATION_PAGE_SIZE
                                                             error:[FPUtils localFetchErrorHandlerMaker]()];
    PEDoesEntityBelongToListView doesEntityBelongToThisListViewBlk = ^BOOL(PELMMainSupport *entity) {
      FPFuelPurchaseLog *fplog = (FPFuelPurchaseLog *)entity;
      FPVehicle *vehicleForFpLog = [_coordDao vehicleForFuelPurchaseLog:fplog
                                                                  error:[FPUtils localFetchErrorHandlerMaker]()];
      return [vehicleForFpLog doesHaveEqualIdentifiers:vehicle];
    };
    PEWouldBeIndexOfEntity wouldBeIndexBlk = ^ NSInteger (PELMMainSupport *entity) {
      FPFuelPurchaseLog *fpLog = (FPFuelPurchaseLog *)entity;
      return [_coordDao numFuelPurchaseLogsForVehicle:vehicle
                                            newerThan:[fpLog purchasedAt]
                                                error:[FPUtils localFetchErrorHandlerMaker]()];
    };
    PESyncViewStyler tableCellStyler = [PELMUIUtils syncViewStylerWithTitleBlk:^(FPFuelPurchaseLog *fpLog) {return [PEUtils stringFromDate:[fpLog purchasedAt] withPattern:@"MM/dd/YYYY"];}
                                                        alwaysTopifyTitleLabel:NO
                                                                     uitoolkit:_uitoolkit
                                                          subtitleLeftHPadding:15.0
                                                      subtitleFitToWidthFactor:1.0
                                                                    isLoggedIn:[APP isUserLoggedIn]];
    return [[PEListViewController alloc] initWithClassOfDataSourceObjects:[FPFuelPurchaseLog class]
                                                                    title:@"Gas Logs"
                                                    isPaginatedDataSource:YES
                                                          tableCellStyler:tableCellStyler
                                                       itemSelectedAction:nil
                                                      initialSelectedItem:nil
                                                            addItemAction:addFpLogAction
                                                           cellIdentifier:@"FPFuelPurchaseLogCell"
                                                           initialObjects:initialFpLogs
                                                               pageLoader:pageLoader
                                                        heightForCellsBlk:[self heightForCellsBlk]
                                                          detailViewMaker:fpLogDetailViewMaker
                                                                uitoolkit:_uitoolkit
                                           doesEntityBelongToThisListView:doesEntityBelongToThisListViewBlk
                                                     wouldBeIndexOfEntity:wouldBeIndexBlk
                                                          isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                           isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                      itemChildrenCounter:nil
                                                      itemChildrenMsgsBlk:nil
                                                              itemDeleter:[self fplogItemDeleterForUser:user]
                                                         itemLocalDeleter:[self fplogItemLocalDeleter]];
  };
}

- (FPAuthScreenMaker)newViewFuelPurchaseLogsScreenMakerForFuelStationInCtx {
  return ^ UIViewController *(FPFuelStation *fuelStation) {
    FPUser *user = [_coordDao userForFuelStation:fuelStation error:[FPUtils localFetchErrorHandlerMaker]()];
    void (^addFpLogAction)(PEListViewController *, PEItemAddedBlk) =
    ^(PEListViewController *listViewCtrlr, PEItemAddedBlk itemAddedBlk) {
      UIViewController *addFpLogScreen =
      [self newAddFuelPurchaseLogScreenMakerWithBlk:itemAddedBlk
                             defaultSelectedVehicle:[_coordDao vehicleForMostRecentFuelPurchaseLogForUser:user
                                                                                                    error:[FPUtils localFetchErrorHandlerMaker]()]
                         defaultSelectedFuelStation:fuelStation
                                 listViewController:listViewCtrlr](user);
      [listViewCtrlr presentViewController:[PEUIUtils navigationControllerWithController:addFpLogScreen navigationBarHidden:NO]
                                  animated:YES
                                completion:nil];
    };
    FPDetailViewMaker fpLogDetailViewMaker =
    ^UIViewController *(PEListViewController *listViewCtrlr,
                        id dataObject,
                        NSIndexPath *indexPath,
                        PEItemChangedBlk itemChangedBlk) {
      return [self newFuelPurchaseLogDetailScreenMakerWithFpLog:dataObject
                                                 fpLogIndexPath:indexPath
                                                 itemChangedBlk:itemChangedBlk
                                  listViewParentIsVehicleDetail:NO
                              listViewParentIsFuelStationDetail:YES
                                             listViewController:listViewCtrlr](user);
    };
    PEPageLoaderBlk pageLoader = ^ NSArray * (FPFuelPurchaseLog *lastFpLog) {
      return [_coordDao fuelPurchaseLogsForFuelStation:fuelStation
                                              pageSize:PAGINATION_PAGE_SIZE
                                      beforeDateLogged:[lastFpLog purchasedAt]
                                                 error:[FPUtils localFetchErrorHandlerMaker]()];
    };
    NSArray *initialFpLogs = [_coordDao fuelPurchaseLogsForFuelStation:fuelStation
                                                              pageSize:PAGINATION_PAGE_SIZE
                                                                 error:[FPUtils localFetchErrorHandlerMaker]()];
    PEDoesEntityBelongToListView doesEntityBelongToThisListViewBlk = ^BOOL(PELMMainSupport *entity) {
      FPFuelPurchaseLog *fplog = (FPFuelPurchaseLog *)entity;
      FPFuelStation *fuelStationForFpLog = [_coordDao fuelStationForFuelPurchaseLog:fplog
                                                                              error:[FPUtils localFetchErrorHandlerMaker]()];
      return [fuelStationForFpLog doesHaveEqualIdentifiers:fuelStation];
    };
    PEWouldBeIndexOfEntity wouldBeIndexBlk = ^ NSInteger (PELMMainSupport *entity) {
      FPFuelPurchaseLog *fpLog = (FPFuelPurchaseLog *)entity;
      return [_coordDao numFuelPurchaseLogsForFuelStation:fuelStation
                                                newerThan:[fpLog purchasedAt]
                                                    error:[FPUtils localFetchErrorHandlerMaker]()];
    };
    PESyncViewStyler tableCellStyler = [PELMUIUtils syncViewStylerWithTitleBlk:^(FPFuelPurchaseLog *fpLog) {return [PEUtils stringFromDate:[fpLog purchasedAt] withPattern:@"MM/dd/YYYY"];}
                                                        alwaysTopifyTitleLabel:NO
                                                                     uitoolkit:_uitoolkit
                                                          subtitleLeftHPadding:15.0
                                                      subtitleFitToWidthFactor:1.0
                                                                    isLoggedIn:[APP isUserLoggedIn]];
    return [[PEListViewController alloc] initWithClassOfDataSourceObjects:[FPFuelPurchaseLog class]
                                                                    title:@"Gas Logs"
                                                    isPaginatedDataSource:YES
                                                          tableCellStyler:tableCellStyler
                                                       itemSelectedAction:nil
                                                      initialSelectedItem:nil
                                                            addItemAction:addFpLogAction
                                                           cellIdentifier:@"FPFuelPurchaseLogCell"
                                                           initialObjects:initialFpLogs
                                                               pageLoader:pageLoader
                                                        heightForCellsBlk:[self heightForCellsBlk]
                                                          detailViewMaker:fpLogDetailViewMaker
                                                                uitoolkit:_uitoolkit
                                           doesEntityBelongToThisListView:doesEntityBelongToThisListViewBlk
                                                     wouldBeIndexOfEntity:wouldBeIndexBlk
                                                          isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                           isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                      itemChildrenCounter:nil
                                                      itemChildrenMsgsBlk:nil
                                                              itemDeleter:[self fplogItemDeleterForUser:user]
                                                         itemLocalDeleter:[self fplogItemLocalDeleter]];
  };
}

- (FPAuthScreenMaker)newViewUnsyncedFuelPurchaseLogsScreenMaker {
  return ^ UIViewController *(FPUser *user) {
    FPDetailViewMaker fpLogDetailViewMaker =
      ^UIViewController *(PEListViewController *listViewCtrlr,
                          id dataObject,
                          NSIndexPath *indexPath,
                          PEItemChangedBlk itemChangedBlk) {
      return [self newFuelPurchaseLogDetailScreenMakerWithFpLog:dataObject
                                                 fpLogIndexPath:indexPath
                                                 itemChangedBlk:itemChangedBlk
                                  listViewParentIsVehicleDetail:NO
                              listViewParentIsFuelStationDetail:NO
                                             listViewController:listViewCtrlr](user);
    };
    PEPageLoaderBlk pageLoader = ^ NSArray * (FPFuelPurchaseLog *lastFpLog) {
      return [_coordDao unsyncedFuelPurchaseLogsForUser:user
                                                  error:[FPUtils localFetchErrorHandlerMaker]()];
    };
    PEWouldBeIndexOfEntity wouldBeIndexBlk = [self wouldBeIndexBlkForEqualityBlock:^(FPFuelPurchaseLog *f1, FPFuelPurchaseLog *f2){return [f1 isEqualToFuelPurchaseLog:f2];}
                                                                     entityFetcher:^{ return pageLoader(nil); }];
    PESyncViewStyler tableCellStyler = [PELMUIUtils syncViewStylerWithTitleBlk:^(FPFuelPurchaseLog *fpLog) {return [PEUtils stringFromDate:[fpLog purchasedAt] withPattern:@"MM/dd/YYYY"];}
                                                        alwaysTopifyTitleLabel:NO
                                                                     uitoolkit:_uitoolkit
                                                          subtitleLeftHPadding:15.0
                                                      subtitleFitToWidthFactor:1.0
                                                                    isLoggedIn:[APP isUserLoggedIn]];
    return [[PEListViewController alloc] initWithClassOfDataSourceObjects:[FPFuelPurchaseLog class]
                                                                    title:@"Unsynced Gas Logs"
                                                    isPaginatedDataSource:NO
                                                          tableCellStyler:tableCellStyler
                                                       itemSelectedAction:nil
                                                      initialSelectedItem:nil
                                                            addItemAction:nil
                                                           cellIdentifier:@"FPFuelPurchaseLogCell"
                                                           initialObjects:pageLoader(nil)
                                                               pageLoader:pageLoader
                                                        heightForCellsBlk:[self heightForCellsBlk]
                                                          detailViewMaker:fpLogDetailViewMaker
                                                                uitoolkit:_uitoolkit
                                           doesEntityBelongToThisListView:^BOOL(PELMMainSupport *entity){return YES;}
                                                     wouldBeIndexOfEntity:wouldBeIndexBlk
                                                          isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                           isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                      itemChildrenCounter:nil
                                                      itemChildrenMsgsBlk:nil
                                                              itemDeleter:[self fplogItemDeleterForUser:user]
                                                         itemLocalDeleter:[self fplogItemLocalDeleter]];
  };
}

#pragma mark - Environment Log Screen

- (PEEntityValidatorBlk)newEnvironmentLogValidator {
  return ^NSArray *(UIView *envLogPanel) {
    NSMutableArray *errMsgs = [NSMutableArray array];
    FPEnvLogVehicleAndDateDataSourceDelegate *ds =
      (FPEnvLogVehicleAndDateDataSourceDelegate *)
        [(UITableView *)[envLogPanel viewWithTag:FPEnvLogTagVehicleAndDate] dataSource];
    FPVehicle *selectedVehicle = [ds selectedVehicle];
    if (!selectedVehicle) {
      [errMsgs addObject:@"Must select a vehicle."];
    }
    PEMessageCollector cannotBeBlankCollector = [PEUIUtils newTfCannotBeEmptyBlkForMsgs:errMsgs entityPanel:envLogPanel];
    cannotBeBlankCollector(FPEnvLogTagOdometer, @"Odometer cannot be empty.");
    return errMsgs;
  };
}

- (FPAuthScreenMaker)newAddEnvironmentLogScreenMakerWithBlk:(PEItemAddedBlk)itemAddedBlk
                                     defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle
                                         listViewController:(PEListViewController *)listViewController {
  return ^ UIViewController * (FPUser *user) {
    PESaveNewEntityLocalBlk newEnvironmentLogSaverLocal = ^NSArray *(UIView *entityPanel, FPEnvironmentLog *envLog) {
      FPEnvLogVehicleAndDateDataSourceDelegate *ds =
        (FPEnvLogVehicleAndDateDataSourceDelegate *)[(UITableView *)[entityPanel viewWithTag:FPEnvLogTagVehicleAndDate] dataSource];
      FPVehicle *selectedVehicle = [ds selectedVehicle];
      [_coordDao saveNewEnvironmentLog:envLog
                               forUser:user
                               vehicle:selectedVehicle
                                 error:[FPUtils localSaveErrorHandlerMaker]()];
      [APP refreshTabs];
      return @[@"Odometer log saved.", @[@"Odometer log saved locally."]];
    };
    PESaveNewEntityImmediateSyncBlk newEnvironmentLogSaverImmediateSync = ^(UIView *entityPanel,
                                                                            FPEnvironmentLog *envLog,
                                                                            PESyncNotFoundBlk notFoundBlk,
                                                                            PESyncSuccessBlk successBlk,
                                                                            PESyncRetryAfterBlk retryAfterBlk,
                                                                            PESyncServerTempErrorBlk tempErrBlk,
                                                                            PESyncServerErrorBlk errBlk,
                                                                            PESyncConflictBlk conflictBlk,
                                                                            PESyncAuthRequiredBlk authReqdBlk,
                                                                            PESyncDependencyUnsynced depUnsyncedBlk) {
      FPEnvLogVehicleAndDateDataSourceDelegate *ds =
        (FPEnvLogVehicleAndDateDataSourceDelegate *)[(UITableView *)[entityPanel viewWithTag:FPEnvLogTagVehicleAndDate] dataSource];
      FPVehicle *selectedVehicle = [ds selectedVehicle];
      NSString *mainMsgFragment = @"saving odometer log to the server";
      NSString *recordTitle = @"Odometer log";
      [_coordDao saveNewAndSyncImmediateEnvironmentLog:envLog
                                               forUser:user
                                               vehicle:selectedVehicle
                                   notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                        addlSuccessBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                                addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                    addlRemoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeEnvLogErrMsgs:errMask]); [APP refreshTabs];}
                                       addlConflictBlk:^(FPEnvironmentLog *latestEnvlog) {conflictBlk(1, mainMsgFragment, recordTitle, latestEnvlog); [APP refreshTabs];}
                                   addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                          skippedDueToVehicleNotSynced:^{depUnsyncedBlk(1, mainMsgFragment, recordTitle, @"The vehicle is not yet saved to the server."); [APP refreshTabs];}
                                                 error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEViewDidAppearBlk viewDidAppearBlk = ^(PEAddViewEditController *ctrl) {
      [self deselectSelectedRowForTableOnView:ctrl.view tableViewTag:FPEnvLogTagVehicleAndDate];
    };
    PEEntityAddCancelerBlk addCanceler = ^(PEAddViewEditController *ctrl, BOOL dismissCtrlr, FPEnvironmentLog *newEnvLog) {
      if (newEnvLog && [newEnvLog localMainIdentifier]) {
        // delete the unwanted record (probably from when user attempt to sync it, got an app error, and chose to 'forget it, cancel'
        [newEnvLog setEditInProgress:YES];
        [_coordDao cancelEditOfEnvironmentLog:newEnvLog
                                        error:[FPUtils localSaveErrorHandlerMaker]()];
        [APP refreshTabs];
      }
      if (dismissCtrlr) {
        [[ctrl navigationController] dismissViewControllerAnimated:YES completion:nil];
      }
    };
    PEPrepareUIForUserInteractionBlk prepareUIForUserInteractionBlk = ^(PEAddViewEditController *ctrl, UIView *entityFormPanel) {
      if (![ctrl hasPoppedKeyboard]) {
        UITextField *odometerTf = (UITextField *)[entityFormPanel viewWithTag:FPEnvLogTagOdometer];
        [odometerTf becomeFirstResponder];
        [ctrl setHasPoppedKeyboard:YES];
      }
    };
    PEAddlContentSection addlContentSection = ^(PEAddViewEditController *ctrl, UIView *entityFormPanel, FPEnvironmentLog *envlog) {
      FPEnvLogVehicleAndDateDataSourceDelegate *ds =
        (FPEnvLogVehicleAndDateDataSourceDelegate *)[(UITableView *)[entityFormPanel viewWithTag:FPEnvLogTagVehicleAndDate] dataSource];
      FPVehicle *selectedVehicle = [ds selectedVehicle];
      return [FPScreenToolkit funFactSectionWithNumFunFacts:[_reportViews numOdometerFunFacts]
                                             nextFunFactBlk:^{ return [_reportViews nextOdometerFunFact]; }
                                                     record:@[envlog, selectedVehicle]
                                                       user:user
                                             relativeToView:ctrl.view];
    };
    return [PEAddViewEditController addEntityCtrlrWithUitoolkit:_uitoolkit
                                             listViewController:listViewController
                                                   itemAddedBlk:itemAddedBlk
                                           entityFormPanelMaker:[_panelToolkit envlogFormPanelMakerWithUser:user
                                                                                          defaultVehicleBlk:^{ return defaultSelectedVehicle; }
                                                                                                    logDate:[NSDate date]]
                                            entityToPanelBinder:[_panelToolkit envlogToEnvlogPanelBinder]
                                            panelToEntityBinder:[_panelToolkit envlogFormPanelToEnvlogBinder]
                                                    entityTitle:@"Odometer Log"
                                              entityAddCanceler:addCanceler
                                                    entityMaker:[_panelToolkit envlogMaker]
                                            newEntitySaverLocal:newEnvironmentLogSaverLocal
                                    newEntitySaverImmediateSync:newEnvironmentLogSaverImmediateSync
                                 prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                               viewDidAppearBlk:viewDidAppearBlk
                                                entityValidator:[self newEnvironmentLogValidator]
                                                isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                 isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                  isOfflineMode:^{ return [APP offlineMode]; }
                                 syncImmediateMBProgressHUDMode:MBProgressHUDModeIndeterminate
                                          modalOperationStarted:[self commonModalOperationStartedBlock]
                                             modalOperationDone:[self commonModalOperationDoneBlock]
                                    entityAddedNotificationName:FPEntityAddedNotification
                                             addlContentSection:addlContentSection];
  };
}

- (FPAuthScreenMaker)newEnvironmentLogDetailScreenMakerWithEnvLog:(FPEnvironmentLog *)envLog
                                                  envLogIndexPath:(NSIndexPath *)envLogIndexPath
                                                   itemChangedBlk:(PEItemChangedBlk)itemChangedBlk
                                               listViewController:(PEListViewController *)listViewController {
  return ^ UIViewController * (FPUser *user) {
    void (^refreshVehicleTableView)(PEAddViewEditController *, FPEnvironmentLog *) = ^(PEAddViewEditController *ctrl, FPEnvironmentLog *envLog) {
      UITableView *vehicleAndDateTableView =
        (UITableView *)[[ctrl view] viewWithTag:FPEnvLogTagVehicleAndDate];
      FPEnvLogVehicleAndDateDataSourceDelegate *ds =
        (FPEnvLogVehicleAndDateDataSourceDelegate *)[vehicleAndDateTableView dataSource];
      FPVehicle *currentEnvLogVehicleInDb =
      [_coordDao vehicleForEnvironmentLog:envLog error:[FPUtils localSaveErrorHandlerMaker]()];
      [ds setSelectedVehicle:currentEnvLogVehicleInDb];
      [vehicleAndDateTableView reloadData];
    };
    PEEntityEditPreparerBlk envLogEditPreparer = ^BOOL(PEAddViewEditController *ctrl, FPEnvironmentLog *envLog) {
      BOOL result = [_coordDao prepareEnvironmentLogForEdit:envLog
                                                    forUser:user
                                                      error:[FPUtils localSaveErrorHandlerMaker]()];
      if (result) {
        refreshVehicleTableView(ctrl, envLog);
      }
      [APP refreshTabs];
      return result;
    };
    PEEntityEditCancelerBlk envLogEditCanceler = ^(PEAddViewEditController *ctrl, FPEnvironmentLog *envLog) {
      [_coordDao cancelEditOfEnvironmentLog:envLog
                                      error:[FPUtils localSaveErrorHandlerMaker]()];
      refreshVehicleTableView(ctrl, envLog);
      [APP refreshTabs];
    };
    PESaveEntityBlk envLogSaver = ^(PEAddViewEditController *ctrl, FPEnvironmentLog *envLog) {
      FPEnvLogVehicleAndDateDataSourceDelegate *ds =
        (FPEnvLogVehicleAndDateDataSourceDelegate *)
        [(UITableView *)[[ctrl view] viewWithTag:FPEnvLogTagVehicleAndDate] dataSource];
      FPVehicle *selectedVehicle = [ds selectedVehicle];
      [_coordDao saveEnvironmentLog:envLog
                            forUser:user
                            vehicle:selectedVehicle
                              error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEMarkAsDoneEditingLocalBlk doneEditingEnvironmentLogLocal = ^(PEAddViewEditController *ctrl, FPEnvironmentLog *envLog) {
      [_coordDao markAsDoneEditingEnvironmentLog:envLog error:[FPUtils localSaveErrorHandlerMaker]()];
      [APP refreshTabs];
    };
    PEMarkAsDoneEditingImmediateSyncBlk doneEditingEnvironmentLogImmediateSync = ^(PEAddViewEditController *ctrl,
                                                               FPEnvironmentLog *envLog,
                                                               PESyncNotFoundBlk notFoundBlk,
                                                               PESyncSuccessBlk successBlk,
                                                               PESyncRetryAfterBlk retryAfterBlk,
                                                               PESyncServerTempErrorBlk tempErrBlk,
                                                               PESyncServerErrorBlk errBlk,
                                                               PESyncConflictBlk conflictBlk,
                                                               PESyncAuthRequiredBlk authReqdBlk,
                                                               PESyncDependencyUnsynced depUnsyncedBlk) {
      NSString *mainMsgFragment = @"saving odometer log to the server";
      NSString *recordTitle = @"Odometer log";
      [_coordDao markAsDoneEditingAndSyncEnvironmentLogImmediate:envLog
                                                         forUser:user
                                             notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                  addlSuccessBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                          addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                                          addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                              addlRemoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeEnvLogErrMsgs:errMask]); [APP refreshTabs];}
                                                 addlConflictBlk:^(FPEnvironmentLog *latestEnvlog) {conflictBlk(1, mainMsgFragment, recordTitle, latestEnvlog); [APP refreshTabs];}
                                             addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                    skippedDueToVehicleNotSynced:^{depUnsyncedBlk(1, mainMsgFragment, recordTitle, @"The vehicle is not yet saved to the server."); [APP refreshTabs];}
                                                           error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEUploaderBlk uploader = ^(PEAddViewEditController *ctrl,
                               FPEnvironmentLog *envLog,
                               PESyncNotFoundBlk notFoundBlk,
                               PESyncSuccessBlk successBlk,
                               PESyncRetryAfterBlk retryAfterBlk,
                               PESyncServerTempErrorBlk tempErrBlk,
                               PESyncServerErrorBlk errBlk,
                               PESyncConflictBlk conflictBlk,
                               PESyncAuthRequiredBlk authReqdBlk,
                               PESyncDependencyUnsynced depUnsyncedBlk) {
      NSString *mainMsgFragment = @"saving odometer log to the server";
      NSString *recordTitle = @"Odometer log";
      [_coordDao flushUnsyncedChangesToEnvironmentLog:envLog
                                              forUser:user
                                  notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                       addlSuccessBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                               addlRemoteStoreBusyBlk:^(NSDate *retryAfter){retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                               addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                   addlRemoteErrorBlk:^(NSInteger errMask){errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeEnvLogErrMsgs:errMask]); [APP refreshTabs];}
                                      addlConflictBlk:^(FPEnvironmentLog *latestEnvlog) {conflictBlk(1, mainMsgFragment, recordTitle, latestEnvlog); [APP refreshTabs];}
                                  addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                         skippedDueToVehicleNotSynced:^{depUnsyncedBlk(1, mainMsgFragment, recordTitle, @"The vehicle is not yet saved to the server."); [APP refreshTabs];}
                                                error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PENumRemoteDepsNotLocal numRemoteDepsNotLocalBlk = ^ NSInteger (FPEnvironmentLog *remoteEnvlog) {
      FPVehicle *vehicle = [_coordDao masterVehicleWithGlobalId:[remoteEnvlog vehicleGlobalIdentifier] error:[FPUtils localFetchErrorHandlerMaker]()];
      if (vehicle) {
        return 0;
      }
      return 1;
    };
    PEDependencyFetcherBlk depFetcherBlk = ^(PEAddViewEditController *ctrl,
                                   FPEnvironmentLog *remoteEnvlog,
                                   PESyncNotFoundBlk notFoundBlk,
                                   PESyncSuccessBlk successBlk,
                                   PESyncRetryAfterBlk retryAfterBlk,
                                   PESyncServerTempErrorBlk tempErrBlk,
                                   PESyncAuthRequiredBlk authReqdBlk) {
      NSString *mainMsgFragment = @"fetching vehicle";
      NSString *recordTitle = @"Vehicle";
      [_coordDao fetchAndSaveNewVehicleWithGlobalId:[remoteEnvlog vehicleGlobalIdentifier]
                                            forUser:user
                                notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                     addlSuccessBlk:^(FPVehicle *fetchedVehicle) {successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                 remoteStoreBusyBlk:^(NSDate *retryAfter){retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                                 tempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                              error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEMergeBlk mergeBlk = ^ NSDictionary * (PEAddViewEditController *ctrl, FPEnvironmentLog *localEnvlog, FPEnvironmentLog *remoteEnvlog) {
      FPEnvironmentLog *masterEnvlog = [_coordDao masterEnvlogWithId:[localEnvlog localMasterIdentifier]
                                                                          error:[FPUtils localFetchErrorHandlerMaker]()];
      UITableView *vehicleAndDateTableView = (UITableView *)[[ctrl view] viewWithTag:FPEnvLogTagVehicleAndDate];
      FPEnvLogVehicleAndDateDataSourceDelegate *ds = (FPEnvLogVehicleAndDateDataSourceDelegate *)[vehicleAndDateTableView dataSource];
      // the vehicles to compare
      FPVehicle *vehicleForLocalEnvlog = [ds selectedVehicle];
      FPVehicle *vehicleForMasterEnvlog = [_coordDao masterVehicleForMasterEnvLog:masterEnvlog error:[FPUtils localFetchErrorHandlerMaker]()];
      FPVehicle *vehicleForRemoteEnvlog = [_coordDao masterVehicleWithGlobalId:[remoteEnvlog vehicleGlobalIdentifier] error:[FPUtils localFetchErrorHandlerMaker]()];
      NSString *origLocalEnvlogVehicleGlobalId = [vehicleForLocalEnvlog globalIdentifier];
      // well, really we're only going to compare global IDs using our existing 'mergeRemoteEnvlog' function
      [localEnvlog setVehicleGlobalIdentifier:[vehicleForLocalEnvlog globalIdentifier]];
      [masterEnvlog setVehicleGlobalIdentifier:[vehicleForMasterEnvlog globalIdentifier]];
      [remoteEnvlog setVehicleGlobalIdentifier:[vehicleForRemoteEnvlog globalIdentifier]];
      NSDictionary *mergeConflicts = [FPEnvironmentLog mergeRemoteEnvlog:remoteEnvlog withLocalEnvlog:localEnvlog localMasterEnvlog:masterEnvlog];
      if (![origLocalEnvlogVehicleGlobalId isEqualToString:[localEnvlog vehicleGlobalIdentifier]]) {
        // since the vehicle global ID changed on the local env log, then the remote's version
        // MUST have been substituded-in.
        [ds setSelectedVehicle:vehicleForRemoteEnvlog];
      }
      return mergeConflicts;
    };
    PEConflictResolveFields conflictResolveFieldsBlk =
    ^(PEAddViewEditController *ctrl, NSDictionary *mergeConflicts, FPEnvironmentLog *localEnvlog, FPEnvironmentLog *remoteEnvlog) {
      UITableView *vehicleAndDateTableView = (UITableView *)[[ctrl view] viewWithTag:FPEnvLogTagVehicleAndDate];
      FPEnvLogVehicleAndDateDataSourceDelegate *ds = (FPEnvLogVehicleAndDateDataSourceDelegate *)[vehicleAndDateTableView dataSource];
      FPVehicle *vehicleForLocalEnvlog = [ds selectedVehicle];
      FPVehicle *vehicleForRemoteEnvlog = [_coordDao masterVehicleWithGlobalId:[remoteEnvlog vehicleGlobalIdentifier]
                                                                                    error:[FPUtils localFetchErrorHandlerMaker]()];
      NSMutableArray *fields = [NSMutableArray arrayWithCapacity:mergeConflicts.count];
      [mergeConflicts enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *fieldName = key;
        if ([fieldName isEqualToString:FPEnvlogVehicleGlobalIdField]) {
          [fields addObject:@[@"Vehicle:", @(FPEnvLogTagVehicle), [vehicleForLocalEnvlog name], [vehicleForRemoteEnvlog name]]];
        } else if ([fieldName isEqualToString:FPEnvlogLogDateField]) {
          [fields addObject:@[@"Log date:", @(FPEnvLogTagLogDate), [PEUtils stringFromDate:[localEnvlog logDate] withPattern:@"MM/dd/YYYY"], [PEUtils stringFromDate:[remoteEnvlog logDate] withPattern:@"MM/dd/YYYY"]]];
        } else if ([fieldName isEqualToString:FPEnvlogOdometerField]) {
          [fields addObject:@[@"Odometer:", @(FPEnvLogTagOdometer), [PEUtils descriptionOrEmptyIfNil:[localEnvlog odometer]], [PEUtils descriptionOrEmptyIfNil:[remoteEnvlog odometer]]]];
        } else if ([fieldName isEqualToString:FPEnvlogReportedDteField]) {
          [fields addObject:@[@"Range readout:", @(FPEnvLogTagReportedDte), [PEUtils descriptionOrEmptyIfNil:[localEnvlog reportedDte]], [PEUtils descriptionOrEmptyIfNil:[remoteEnvlog reportedDte]]]];
        } else if ([fieldName isEqualToString:FPEnvlogReportedAvgMpgField]) {
          [fields addObject:@[@"Average MPG readout:", @(FPEnvLogTagReportedAvgMpg), [PEUtils descriptionOrEmptyIfNil:[localEnvlog reportedAvgMpg]], [PEUtils descriptionOrEmptyIfNil:[remoteEnvlog reportedAvgMpg]]]];
        } else if ([fieldName isEqualToString:FPEnvlogReportedAvgMphField]) {
          [fields addObject:@[@"Average MPG readout:", @(FPEnvLogTagReportedAvgMph), [PEUtils descriptionOrEmptyIfNil:[localEnvlog reportedAvgMph]], [PEUtils descriptionOrEmptyIfNil:[remoteEnvlog reportedAvgMph]]]];
        } else if ([fieldName isEqualToString:FPEnvlogReportedOutsideTempField]) {
          [fields addObject:@[@"Outside temp. readout:", @(FPEnvLogTagReportedOutsideTemp), [PEUtils descriptionOrEmptyIfNil:[localEnvlog reportedOutsideTemp]], [PEUtils descriptionOrEmptyIfNil:[remoteEnvlog reportedOutsideTemp]]]];
        }
      }];
      return fields;
    };
    PEConflictResolvedEntity conflictResolvedEntityBlk =
      ^ id (PEAddViewEditController *ctrl, NSDictionary *mergeConflicts, NSArray *valueLabels, FPEnvironmentLog *localEnvlog, FPEnvironmentLog *remoteEnvlog) {
      FPEnvironmentLog *resolvedEnvlog = [localEnvlog copy];
      NSInteger numValueLabels = [valueLabels count];
      UITableView *vehicleAndDateTableView = (UITableView *)[[ctrl view] viewWithTag:FPEnvLogTagVehicleAndDate];
      FPEnvLogVehicleAndDateDataSourceDelegate *ds = (FPEnvLogVehicleAndDateDataSourceDelegate *)[vehicleAndDateTableView dataSource];
      for (int i = 0; i < numValueLabels; i++) {
        NSArray *valueLabelPair = valueLabels[i];
        UILabel *remoteValue = valueLabelPair[1];
        if (remoteValue.tag > 0) {
          switch (remoteValue.tag) {
            case FPEnvLogTagOdometer:
              [resolvedEnvlog setOdometer:[remoteEnvlog odometer]];
              break;
            case FPEnvLogTagReportedDte:
              [resolvedEnvlog setReportedDte:[remoteEnvlog reportedDte]];
              break;
            case FPEnvLogTagReportedAvgMpg:
              [resolvedEnvlog setReportedAvgMpg:[remoteEnvlog reportedAvgMpg]];
              break;
            case FPEnvLogTagReportedAvgMph:
              [resolvedEnvlog setReportedAvgMph:[remoteEnvlog reportedAvgMph]];
              break;
            case FPEnvLogTagReportedOutsideTemp:
              [resolvedEnvlog setReportedOutsideTemp:[remoteEnvlog reportedOutsideTemp]];
              break;
            case FPEnvLogTagLogDate:
              [resolvedEnvlog setLogDate:[remoteEnvlog logDate]];
              [ds setPickedLogDate:[resolvedEnvlog logDate]];
              break;
            case FPEnvLogTagVehicle:
            {
              FPVehicle *vehicleForRemoteEnvlog = [_coordDao masterVehicleWithGlobalId:[remoteEnvlog vehicleGlobalIdentifier]
                                                                                            error:[FPUtils localFetchErrorHandlerMaker]()];
              [ds setSelectedVehicle:vehicleForRemoteEnvlog];
              break;
            }
          }
        }
      }
      return resolvedEnvlog;
    };
    PEUpdateDepsPanel updateDepsPanel = ^(PEAddViewEditController *ctrl, FPEnvironmentLog *remoteEnvlog) {
      UITableView *vehicleAndDateTableView = (UITableView *)[[ctrl view] viewWithTag:FPEnvLogTagVehicleAndDate];
      FPEnvLogVehicleAndDateDataSourceDelegate *ds = (FPEnvLogVehicleAndDateDataSourceDelegate *)[vehicleAndDateTableView dataSource];
      FPVehicle *vehicleForRemoteEnvlog = [_coordDao masterVehicleWithGlobalId:[remoteEnvlog vehicleGlobalIdentifier]
                                                                                    error:[FPUtils localFetchErrorHandlerMaker]()];
      [ds setSelectedVehicle:vehicleForRemoteEnvlog];
    };
    PEDownloaderBlk downloaderBlk = ^ (PEAddViewEditController *ctrl,
                                       FPEnvironmentLog *envlog,
                                       PESyncNotFoundBlk notFoundBlk,
                                       PEDownloadSuccessBlk successBlk,
                                       PESyncRetryAfterBlk retryAfterBlk,
                                       PESyncServerTempErrorBlk tempErrBlk,
                                       PESyncAuthRequiredBlk authReqdBlk) {
      NSString *mainMsgFragment = @"fetching odometer log";
      NSString *recordTitle = @"Odometer log";
      float percentOfFetching = 1.0;
      [_coordDao fetchEnvironmentLogWithGlobalId:[envLog globalIdentifier]
                                 ifModifiedSince:[envLog updatedAt]
                                         forUser:user
                             notFoundOnServerBlk:^{notFoundBlk(percentOfFetching, mainMsgFragment, recordTitle);}
                                      successBlk:^(FPEnvironmentLog *fetchedEnvlog) {successBlk(percentOfFetching, mainMsgFragment, recordTitle, fetchedEnvlog);}
                              remoteStoreBusyBlk:^(NSDate *retryAfter){retryAfterBlk(percentOfFetching, mainMsgFragment, recordTitle, retryAfter);}
                              tempRemoteErrorBlk:^{tempErrBlk(percentOfFetching, mainMsgFragment, recordTitle);}
                             addlAuthRequiredBlk:^{authReqdBlk(percentOfFetching, mainMsgFragment, recordTitle); [APP refreshTabs];}];
    };
    PEPostDownloaderSaver postDownloadSaverBlk = ^ (PEAddViewEditController *ctrl,
                                                    FPEnvironmentLog *downloadedEnvlog,
                                                    FPEnvironmentLog *envlog) {
      FPVehicle *vehicleForDownloadedEnvlog = [_coordDao masterVehicleWithGlobalId:[downloadedEnvlog vehicleGlobalIdentifier]
                                                                                        error:[FPUtils localFetchErrorHandlerMaker]()];
      [_coordDao saveMasterEnvironmentLog:downloadedEnvlog forVehicle:vehicleForDownloadedEnvlog forUser:user error:[FPUtils localSaveErrorHandlerMaker]()];
      UITableView *vehicleAndDateTableView = (UITableView *)[[ctrl view] viewWithTag:FPEnvLogTagVehicleAndDate];
      FPEnvLogVehicleAndDateDataSourceDelegate *ds = (FPEnvLogVehicleAndDateDataSourceDelegate *)[vehicleAndDateTableView dataSource];
      [ds setSelectedVehicle:vehicleForDownloadedEnvlog];
      [vehicleAndDateTableView reloadData];
    };
    PEPrepareUIForUserInteractionBlk prepareUIForUserInteractionBlk = ^(PEAddViewEditController *ctrl, UIView *entityPanel) {
      if (![ctrl hasPoppedKeyboard]) {
        UITextField *odometerTf = (UITextField *)[entityPanel viewWithTag:FPEnvLogTagOdometer];
        [odometerTf becomeFirstResponder];
        [ctrl setHasPoppedKeyboard:YES];
      }
    };
    PEViewDidAppearBlk viewDidAppearBlk = ^(PEAddViewEditController *ctrl) {
      [self deselectSelectedRowForTableOnView:ctrl.view tableViewTag:FPEnvLogTagVehicleAndDate];
    };
    return [PEAddViewEditController viewEntityCtrlrWithParentEntity:user
                                                             entity:envLog
                                                 listViewController:listViewController
                                                    entityIndexPath:envLogIndexPath
                                                          uitoolkit:_uitoolkit
                                                     itemChangedBlk:itemChangedBlk
                                               entityFormPanelMaker:[_panelToolkit envlogFormPanelMakerWithUser:user
                                                                                              defaultVehicleBlk:^{ return [_coordDao vehicleForEnvironmentLog:envLog
                                                                                                                                                        error:[FPUtils localFetchErrorHandlerMaker]()]; }
                                                                                                        logDate:[envLog logDate]]
                                               entityViewPanelMaker:[_panelToolkit envlogViewPanelMakerWithUser:user]
                                                entityToPanelBinder:[_panelToolkit envlogToEnvlogPanelBinder]
                                                panelToEntityBinder:[_panelToolkit envlogFormPanelToEnvlogBinder]
                                                        entityTitle:@"Odometer Log"
                                               panelEnablerDisabler:[_panelToolkit envlogFormPanelEnablerDisabler]
                                                  entityAddCanceler:nil
                                                 entityEditPreparer:envLogEditPreparer
                                                 entityEditCanceler:envLogEditCanceler
                                                        entitySaver:envLogSaver
                                             doneEditingEntityLocal:doneEditingEnvironmentLogLocal
                                     doneEditingEntityImmediateSync:doneEditingEnvironmentLogImmediateSync
                                                    isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                     isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                      isOfflineMode:^{ return [APP offlineMode]; }
                                     syncImmediateMBProgressHUDMode:MBProgressHUDModeIndeterminate
                                     prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                                   viewDidAppearBlk:viewDidAppearBlk
                                                    entityValidator:[self newEnvironmentLogValidator]
                                                           uploader:uploader
                                              numRemoteDepsNotLocal:numRemoteDepsNotLocalBlk
                                                              merge:mergeBlk
                                                  fetchDependencies:depFetcherBlk
                                                    updateDepsPanel:updateDepsPanel
                                                         downloader:downloaderBlk
                                                  postDownloadSaver:postDownloadSaverBlk
                                              conflictResolveFields:conflictResolveFieldsBlk
                                             conflictResolvedEntity:conflictResolvedEntityBlk
                                                itemChildrenCounter:nil
                                                itemChildrenMsgsBlk:nil
                                                        itemDeleter:[self envlogItemDeleterForUser:user]
                                                   itemLocalDeleter:[self envlogItemLocalDeleter]
                                              modalOperationStarted:[self commonModalOperationStartedBlock]
                                                 modalOperationDone:[self commonModalOperationDoneBlock]
                                      entityUpdatedNotificationName:FPEntityUpdatedNotification
                                      entityRemovedNotificationName:FPEntityDeletedNotification];
  };
}

- (PEItemDeleter)envlogItemDeleterForUser:(FPUser *)user {
  PEItemDeleter itemDeleter = ^ (UIViewController *listViewController,
                                 FPEnvironmentLog *envlog,
                                 NSIndexPath *indexPath,
                                 PESyncNotFoundBlk notFoundBlk,
                                 PESyncSuccessBlk successBlk,
                                 PESyncRetryAfterBlk retryAfterBlk,
                                 PESyncServerTempErrorBlk tempErrBlk,
                                 PESyncServerErrorBlk errBlk,
                                 PESyncConflictBlk conflictBlk,
                                 PESyncAuthRequiredBlk authReqdBlk) {
    NSString *mainMsgFragment = @"deleting odometer log";
    NSString *recordTitle = @"Odometer log";
    [_coordDao deleteEnvironmentLog:envlog
                            forUser:user
                notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                     addlSuccessBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                 remoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                 tempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                     remoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeEnvLogErrMsgs:errMask]); [APP refreshTabs];}
                        conflictBlk:^(FPEnvironmentLog *latestEnvlog) {conflictBlk(1, mainMsgFragment, recordTitle, latestEnvlog); [APP refreshTabs];}
                addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                              error:[FPUtils localSaveErrorHandlerMaker]()];
  };
  return itemDeleter;
}

- (PEItemLocalDeleter)envlogItemLocalDeleter {
  return ^ (UIViewController *listViewController, FPEnvironmentLog *envlog, NSIndexPath *indexPath) {
    [_coordDao deleteEnvironmentLog:envlog error:[FPUtils localSaveErrorHandlerMaker]()];
    [APP refreshTabs];
  };
}

- (FPAuthScreenMaker)newViewEnvironmentLogsScreenMaker {
  return ^ UIViewController *(FPUser *user) {
    void (^addEnvLogAction)(PEListViewController *, PEItemAddedBlk) =
    ^(PEListViewController *listViewCtrlr, PEItemAddedBlk itemAddedBlk) {
      UIViewController *addEnvLogScreen =
      [self newAddEnvironmentLogScreenMakerWithBlk:itemAddedBlk
                            defaultSelectedVehicle:[_coordDao vehicleForMostRecentFuelPurchaseLogForUser:user
                                                                                                   error:[FPUtils localFetchErrorHandlerMaker]()]
                                listViewController:listViewCtrlr](user);
      [listViewCtrlr presentViewController:[PEUIUtils navigationControllerWithController:addEnvLogScreen navigationBarHidden:NO]
                                  animated:YES
                                completion:nil];
    };
    FPDetailViewMaker envLogDetailViewMaker =
    ^UIViewController *(PEListViewController *listViewCtrlr,
                        id dataObject,
                        NSIndexPath *indexPath,
                        PEItemChangedBlk itemChangedBlk) {
      return [self newEnvironmentLogDetailScreenMakerWithEnvLog:dataObject
                                                envLogIndexPath:indexPath
                                                 itemChangedBlk:itemChangedBlk
                                             listViewController:listViewCtrlr](user);
    };
    PEPageLoaderBlk pageLoader = ^ NSArray * (FPEnvironmentLog *lastEnvLog) {
      return [_coordDao environmentLogsForUser:user
                                      pageSize:PAGINATION_PAGE_SIZE
                              beforeDateLogged:[lastEnvLog logDate]
                                         error:[FPUtils localFetchErrorHandlerMaker]()];
    };
    NSArray *initialEnvLogs = [_coordDao environmentLogsForUser:user pageSize:PAGINATION_PAGE_SIZE error:[FPUtils localFetchErrorHandlerMaker]()];
    PEDoesEntityBelongToListView doesEntityBelongToThisListViewBlk = ^BOOL(PELMMainSupport *entity) {
      return YES;
    };
    PEWouldBeIndexOfEntity wouldBeIndexBlk = ^ NSInteger (PELMMainSupport *entity) {
      FPEnvironmentLog *envLog = (FPEnvironmentLog *)entity;
      return [_coordDao numEnvironmentLogsForUser:user newerThan:[envLog logDate] error:[FPUtils localFetchErrorHandlerMaker]()];
    };
    PESyncViewStyler tableCellStyler = [PELMUIUtils syncViewStylerWithTitleBlk:^(FPEnvironmentLog *envLog) {return [PEUtils stringFromDate:[envLog logDate] withPattern:@"MM/dd/YYYY"];}
                                                        alwaysTopifyTitleLabel:NO
                                                                     uitoolkit:_uitoolkit
                                                          subtitleLeftHPadding:15.0
                                                      subtitleFitToWidthFactor:1.0
                                                                    isLoggedIn:[APP isUserLoggedIn]];
    return [[PEListViewController alloc] initWithClassOfDataSourceObjects:[FPEnvironmentLog class]
                                                                    title:@"Odometer Logs"
                                                    isPaginatedDataSource:YES
                                                          tableCellStyler:tableCellStyler
                                                       itemSelectedAction:nil
                                                      initialSelectedItem:nil
                                                            addItemAction:addEnvLogAction
                                                           cellIdentifier:@"FPEnvironmentLogCell"
                                                           initialObjects:initialEnvLogs
                                                               pageLoader:pageLoader
                                                           heightForCellsBlk:[self heightForCellsBlk]
                                                          detailViewMaker:envLogDetailViewMaker
                                                                uitoolkit:_uitoolkit
                                           doesEntityBelongToThisListView:doesEntityBelongToThisListViewBlk
                                                     wouldBeIndexOfEntity:wouldBeIndexBlk
                                                          isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                           isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                      itemChildrenCounter:nil
                                                      itemChildrenMsgsBlk:nil
                                                              itemDeleter:[self envlogItemDeleterForUser:user]
                                                         itemLocalDeleter:[self envlogItemLocalDeleter]];
  };
}

- (FPAuthScreenMaker)newViewEnvironmentLogsScreenMakerForVehicleInCtx {
  return ^ UIViewController *(FPVehicle *vehicle) {
    FPUser *user = [_coordDao userForVehicle:vehicle error:[FPUtils localFetchErrorHandlerMaker]()];
    void (^addEnvLogAction)(PEListViewController *, PEItemAddedBlk) =
    ^(PEListViewController *listViewCtrlr, PEItemAddedBlk itemAddedBlk) {
      UIViewController *addEnvLogScreen =
      [self newAddEnvironmentLogScreenMakerWithBlk:itemAddedBlk
                            defaultSelectedVehicle:vehicle
                                listViewController:listViewCtrlr](user);
      [listViewCtrlr presentViewController:[PEUIUtils navigationControllerWithController:addEnvLogScreen navigationBarHidden:NO]
                                  animated:YES
                                completion:nil];
    };
    FPDetailViewMaker envLogDetailViewMaker =
    ^UIViewController *(PEListViewController *listViewCtrlr,
                        id dataObject,
                        NSIndexPath *indexPath,
                        PEItemChangedBlk itemChangedBlk) {
      //[_coordDao reloadEnvironmentLog:dataObject error:[FPUtils localFetchErrorHandlerMaker]()];
      return [self newEnvironmentLogDetailScreenMakerWithEnvLog:dataObject
                                                envLogIndexPath:indexPath
                                                 itemChangedBlk:itemChangedBlk
                                             listViewController:listViewCtrlr](user);
    };
    PEPageLoaderBlk pageLoader = ^ NSArray * (FPEnvironmentLog *lastEnvLog) {
      return [_coordDao environmentLogsForVehicle:vehicle
                                         pageSize:PAGINATION_PAGE_SIZE
                                 beforeDateLogged:[lastEnvLog logDate]
                                            error:[FPUtils localFetchErrorHandlerMaker]()];
    };
    NSArray *initialEnvLogs = [_coordDao environmentLogsForVehicle:vehicle
                                                          pageSize:PAGINATION_PAGE_SIZE
                                                             error:[FPUtils localFetchErrorHandlerMaker]()];
    PEDoesEntityBelongToListView doesEntityBelongToThisListViewBlk = ^BOOL(PELMMainSupport *entity) {
      FPEnvironmentLog *envlog = (FPEnvironmentLog *)entity;
      FPVehicle *vehicleForEnvLog = [_coordDao vehicleForEnvironmentLog:envlog
                                                                 error:[FPUtils localFetchErrorHandlerMaker]()];
      return [vehicleForEnvLog doesHaveEqualIdentifiers:vehicle];
    };
    PEWouldBeIndexOfEntity wouldBeIndexBlk = ^ NSInteger (PELMMainSupport *entity) {
      FPEnvironmentLog *envLog = (FPEnvironmentLog *)entity;
      return [_coordDao numEnvironmentLogsForVehicle:vehicle
                                           newerThan:[envLog logDate]
                                               error:[FPUtils localFetchErrorHandlerMaker]()];
    };
    PESyncViewStyler tableCellStyler = [PELMUIUtils syncViewStylerWithTitleBlk:^(FPEnvironmentLog *envLog) {return [PEUtils stringFromDate:[envLog logDate] withPattern:@"MM/dd/YYYY"];}
                                                        alwaysTopifyTitleLabel:NO
                                                                     uitoolkit:_uitoolkit
                                                          subtitleLeftHPadding:15.0
                                                      subtitleFitToWidthFactor:1.0
                                                                    isLoggedIn:[APP isUserLoggedIn]];
    return [[PEListViewController alloc] initWithClassOfDataSourceObjects:[FPEnvironmentLog class]
                                                                    title:@"Odometer Logs"
                                                    isPaginatedDataSource:YES
                                                          tableCellStyler:tableCellStyler
                                                       itemSelectedAction:nil
                                                      initialSelectedItem:nil
                                                            addItemAction:addEnvLogAction
                                                           cellIdentifier:@"FPEnvironmentLogCell"
                                                           initialObjects:initialEnvLogs
                                                               pageLoader:pageLoader
                                                        heightForCellsBlk:[self heightForCellsBlk]
                                                          detailViewMaker:envLogDetailViewMaker
                                                                uitoolkit:_uitoolkit
                                           doesEntityBelongToThisListView:doesEntityBelongToThisListViewBlk
                                                     wouldBeIndexOfEntity:wouldBeIndexBlk
                                                          isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                           isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                      itemChildrenCounter:nil
                                                      itemChildrenMsgsBlk:nil
                                                              itemDeleter:[self envlogItemDeleterForUser:user]
                                                         itemLocalDeleter:[self envlogItemLocalDeleter]];
  };
}

- (FPAuthScreenMaker)newViewUnsyncedEnvironmentLogsScreenMaker {
  return ^ UIViewController *(FPUser *user) {
    FPDetailViewMaker envLogDetailViewMaker =
    ^UIViewController *(PEListViewController *listViewCtrlr,
                        id dataObject,
                        NSIndexPath *indexPath,
                        PEItemChangedBlk itemChangedBlk) {
      return [self newEnvironmentLogDetailScreenMakerWithEnvLog:dataObject
                                                envLogIndexPath:indexPath
                                                 itemChangedBlk:itemChangedBlk
                                             listViewController:listViewCtrlr](user);
    };
    PEPageLoaderBlk pageLoader = ^ NSArray * (FPEnvironmentLog *lastEnvLog) {
      return [_coordDao unsyncedEnvironmentLogsForUser:user
                                                 error:[FPUtils localFetchErrorHandlerMaker]()];
    };
    PEWouldBeIndexOfEntity wouldBeIndexBlk = [self wouldBeIndexBlkForEqualityBlock:^(FPEnvironmentLog *e1, FPEnvironmentLog *e2){return [e1 isEqualToEnvironmentLog:e2];}
                                                                     entityFetcher:^{ return pageLoader(nil); }];
    PESyncViewStyler tableCellStyler = [PELMUIUtils syncViewStylerWithTitleBlk:^(FPEnvironmentLog *envLog) {return [PEUtils stringFromDate:[envLog logDate] withPattern:@"MM/dd/YYYY"];}
                                                        alwaysTopifyTitleLabel:NO
                                                                     uitoolkit:_uitoolkit
                                                          subtitleLeftHPadding:15.0
                                                      subtitleFitToWidthFactor:1.0
                                                                    isLoggedIn:[APP isUserLoggedIn]];
    return [[PEListViewController alloc] initWithClassOfDataSourceObjects:[FPEnvironmentLog class]
                                                                    title:@"Unsynced Odometer Logs"
                                                    isPaginatedDataSource:NO
                                                          tableCellStyler:tableCellStyler
                                                       itemSelectedAction:nil
                                                      initialSelectedItem:nil
                                                            addItemAction:nil
                                                           cellIdentifier:@"FPEnvironmentLogCell"
                                                           initialObjects:pageLoader(nil)
                                                               pageLoader:pageLoader
                                                        heightForCellsBlk:[self heightForCellsBlk]
                                                          detailViewMaker:envLogDetailViewMaker
                                                                uitoolkit:_uitoolkit
                                           doesEntityBelongToThisListView:^BOOL(PELMMainSupport *entity){return YES;}
                                                     wouldBeIndexOfEntity:wouldBeIndexBlk
                                                          isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                           isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                      itemChildrenCounter:nil
                                                      itemChildrenMsgsBlk:nil
                                                              itemDeleter:[self envlogItemDeleterForUser:user]
                                                         itemLocalDeleter:[self envlogItemLocalDeleter]];
  };
}

#pragma mark - Home Screen

- (FPAuthScreenMaker)newHomeScreenMaker {
  return ^ UIViewController *(FPUser *user) {
    return [[FPHomeController alloc] initWithStoreCoordinator:_coordDao
                                                         user:user
                                                        stats:_stats
                                                    uitoolkit:_uitoolkit
                                                screenToolkit:self];
  };
}

#pragma mark - Records Screen

- (FPAuthScreenMaker)newRecordsScreenMaker {
  return ^ UIViewController *(FPUser *user) {
    return [[FPRecordsController alloc] initWithStoreCoordinator:_coordDao
                                                            user:user
                                                       uitoolkit:_uitoolkit
                                                   screenToolkit:self];
  };
}

#pragma mark - Jot Screen

- (FPAuthScreenMaker)newJotScreenMaker {
  return ^ UIViewController *(FPUser *user) {
    return [[FPJotController alloc] initWithStoreCoordinator:_coordDao
                                                        user:user
                                                   uitoolkit:_uitoolkit
                                               screenToolkit:self];
  };
}

#pragma mark - Account Screen

- (FPAuthScreenMaker)newAccountScreenMaker {
  return ^ UIViewController *(FPUser *user) {
    return [[FPAccountController alloc] initWithStoreCoordinator:_coordDao
                                                            user:user
                                                       uitoolkit:_uitoolkit
                                                   screenToolkit:self];
  };
}

#pragma mark - Tab-bar Authenticated Landing Screen

- (FPAuthScreenMaker)newTabBarHomeLandingScreenMakerIsLoggedIn:(BOOL)isLoggedIn
                                               tagForJotButton:(NSInteger)tagForJotButton {
  return ^ UIViewController *(FPUser *user) {
    UIViewController *homeController = [self newHomeScreenMaker](user);
    UIViewController *recordsController = [self newRecordsScreenMaker](user);
    UIViewController *jotController = [self newJotScreenMaker](user);
    UIViewController *settingsController = [self newViewSettingsScreenMaker](user);
    UIViewController *accountController = [self newAccountScreenMaker](user);
    FPRaisedCenterTabController *tabBarCtrl = [[FPRaisedCenterTabController alloc] initWithNibName:nil bundle:nil];
    jotController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"" image:nil tag:0];
    NSArray *controllers = @[[PEUIUtils navControllerWithRootController:homeController
                                                    navigationBarHidden:NO
                                                        tabBarItemTitle:@"Home"
                                                        tabBarItemImage:[UIImage imageNamed:@"tab-home"]
                                                tabBarItemSelectedImage:[[UIImage imageNamed:@"tab-home"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]],
                             [PEUIUtils navControllerWithRootController:recordsController
                                                    navigationBarHidden:NO
                                                        tabBarItemTitle:@"Records"
                                                        tabBarItemImage:[UIImage imageNamed:@"tab-records"]
                                                tabBarItemSelectedImage:[[UIImage imageNamed:@"tab-records"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]],
                             jotController,
                             [PEUIUtils navControllerWithRootController:settingsController
                                                    navigationBarHidden:NO
                                                        tabBarItemTitle:@"Settings"
                                                        tabBarItemImage:[UIImage imageNamed:@"tab-settings"]
                                                tabBarItemSelectedImage:[[UIImage imageNamed:@"tab-settings"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]],
                             [PEUIUtils navControllerWithRootController:accountController
                                                    navigationBarHidden:NO
                                                        tabBarItemTitle:@"Account"
                                                        tabBarItemImage:[UIImage imageNamed:@"tab-account"]
                                                tabBarItemSelectedImage:[[UIImage imageNamed:@"tab-account"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]]
                             ];
    __weak FPRaisedCenterTabController *weakTabBarCtrl = tabBarCtrl;
    __block BOOL jotting = NO;
    CGFloat belowScreenY = weakTabBarCtrl.view.frame.size.height + 100;
    UIImage *tabJotImg = [UIImage imageNamed:@"tab-jot"];
    NSInteger jotPanelTag = 722;
    NSInteger dimmedBgPanelTag = 723;
    NSInteger addVehicleBtnTag = 724;
    NSInteger addFuelstationBtnTag = 725;
    NSInteger addGasLogBtnTag = 726;
    NSInteger addOdometerLogBtnTag = 727;
    UIButton *(^newButton)(NSString *, NSInteger, CGFloat, UIView *) = ^UIButton * (NSString *imgName, NSInteger tagValue, CGFloat hpaddingOnParentView, UIView *theJotPanel) {
      UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50.0, 50.0)];
      [button setBackgroundImage:[UIImage imageNamed:imgName] forState:UIControlStateNormal];
      [button setTag:tagValue];
      [weakTabBarCtrl.view addSubview:button];
      [PEUIUtils setFrameY:belowScreenY ofView:button];
      [PEUIUtils setFrameX:[PEUIUtils XForWidth:button.frame.size.width
                                  withAlignment:PEUIHorizontalAlignmentTypeLeft
                                 relativeToView:theJotPanel
                                       hpadding:hpaddingOnParentView]
                    ofView:button];
      button.transform = CGAffineTransformMakeScale(0.1, 0.1);
      return button;
    };
    PEListViewController *(^listViewController)(void) = ^PEListViewController * {
      PEListViewController *listViewController = nil;
      UIViewController *topVc = ((UINavigationController *)weakTabBarCtrl.selectedViewController).topViewController;
      if ([topVc isKindOfClass:[PEListViewController class]]) {
        listViewController = (PEListViewController *)topVc;
      }
      return listViewController;
    };
    void (^jotAction)(UIButton *) = ^(UIButton *jotBtn) {
      jotting = !jotting;
      CGFloat rotationAmount = 0.0;
      UIView *jotPanel = [weakTabBarCtrl.view viewWithTag:jotPanelTag];
      weakTabBarCtrl.tabBar.userInteractionEnabled = !jotting;
      CGFloat (^onscreenYForJotButtons)(UIView *, UIButton *) = ^ CGFloat (UIView *theJotPanel, UIButton *addButton) {
        return ((weakTabBarCtrl.view.frame.size.height * 0.705) + (theJotPanel.frame.size.height/2) - (addButton.frame.size.height/2));
      };
      __block UIButton *addVehicleBtn;
      __block UIButton *addFuelstationBtn;
      __block UIButton *addGasLogBtn;
      __block UIButton *addOdometerLogBtn;
      void (^dismissJotPanel)(void) = ^ {
        jotting = NO;
        weakTabBarCtrl.tabBar.userInteractionEnabled = !jotting;
        addVehicleBtn = (UIButton *)[weakTabBarCtrl.view viewWithTag:addVehicleBtnTag];
        addFuelstationBtn = (UIButton *)[weakTabBarCtrl.view viewWithTag:addFuelstationBtnTag];
        addOdometerLogBtn = (UIButton *)[weakTabBarCtrl.view viewWithTag:addOdometerLogBtnTag];
        addGasLogBtn = (UIButton *)[weakTabBarCtrl.view viewWithTag:addGasLogBtnTag];
        CGFloat buttonDismissDuration = 0.4;
        CGFloat buttonShrinkDuration = 0.8;
        CGFloat panelRotateAwayDuration = 0.3;
        [UIView animateWithDuration:buttonDismissDuration
                              delay:0.15
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                           [PEUIUtils setFrameY:belowScreenY ofView:addVehicleBtn];
                           [PEUIUtils setFrameY:belowScreenY ofView:addFuelstationBtn];
                           [PEUIUtils setFrameY:belowScreenY ofView:addOdometerLogBtn];
                           [PEUIUtils setFrameY:belowScreenY ofView:addGasLogBtn];
                         }
                         completion:^(BOOL finished) {
                           [addVehicleBtn removeFromSuperview];
                           [addFuelstationBtn removeFromSuperview];
                           [addOdometerLogBtn removeFromSuperview];
                           [addGasLogBtn removeFromSuperview];
                         }];
        [UIView animateWithDuration:buttonShrinkDuration
                         animations:^{
                           addVehicleBtn.transform = CGAffineTransformMakeScale(0.1, 0.1);
                           addFuelstationBtn.transform = CGAffineTransformMakeScale(0.1, 0.1);
                           addOdometerLogBtn.transform = CGAffineTransformMakeScale(0.1, 0.1);
                           addGasLogBtn.transform = CGAffineTransformMakeScale(0.1, 0.1);
                         }];
        [UIView animateWithDuration:panelRotateAwayDuration
                         animations:^{
                           jotPanel.transform = CGAffineTransformMakeRotation(rotationAmount);
                           jotBtn.transform = CGAffineTransformMakeRotation(rotationAmount);
                         } completion:^(BOOL finished) {
                           UIView *dimmedBackgroundView = [weakTabBarCtrl.selectedViewController.view viewWithTag:dimmedBgPanelTag];
                           [UIView animateWithDuration:0.18
                                            animations:^{ dimmedBackgroundView.alpha = 0.0; }
                                            completion:^(BOOL finished) { [dimmedBackgroundView removeFromSuperview]; }];
                         }];
      };
      void (^configJotButton)(UIViewController *(^)(PEItemAddedBlk)) = ^(UIViewController *(^controllerMaker)(PEItemAddedBlk itemAddedBlk)) {
        PEItemAddedBlk itemAddedBlk = ^(PEAddViewEditController *addViewEditCtrl, id record) {
          [[addViewEditCtrl navigationController] dismissViewControllerAnimated:YES completion:nil];
        };
        UIViewController *addRecordController = controllerMaker(itemAddedBlk);
        [weakTabBarCtrl.selectedViewController presentViewController:[PEUIUtils navigationControllerWithController:addRecordController
                                                                                               navigationBarHidden:NO]
                                                            animated:YES
                                                          completion:^{ dismissJotPanel(); }];
      };
      if (jotting) {
        addOdometerLogBtn = newButton(@"jot-odometer", addOdometerLogBtnTag, 10, jotPanel);
        [addOdometerLogBtn bk_addEventHandler:^(id sender) {
          configJotButton(^UIViewController * (PEItemAddedBlk itemAddedBlk) {
            return [self newAddEnvironmentLogScreenMakerWithBlk:itemAddedBlk
                                         defaultSelectedVehicle:[_coordDao defaultVehicleForNewEnvironmentLogForUser:user error:[FPUtils localFetchErrorHandlerMaker]()]
                                             listViewController:listViewController()](user);
          });
        } forControlEvents:UIControlEventTouchUpInside];
        addGasLogBtn = newButton(@"jot-gas", addGasLogBtnTag, 77, jotPanel);
        [addGasLogBtn bk_addEventHandler:^(id sender) {
          configJotButton(^UIViewController * (PEItemAddedBlk itemAddedBlk) {
            return [self newAddFuelPurchaseLogScreenMakerWithBlk:itemAddedBlk
                                          defaultSelectedVehicle:[_coordDao vehicleForMostRecentFuelPurchaseLogForUser:user
                                                                                                                 error:[FPUtils localFetchErrorHandlerMaker]()]
                                      defaultSelectedFuelStation:[_coordDao defaultFuelStationForNewFuelPurchaseLogForUser:user
                                                                                                           currentLocation:[APP latestLocation]
                                                                                                                     error:[FPUtils localFetchErrorHandlerMaker]()]
                                              listViewController:listViewController()](user);
          });
        } forControlEvents:UIControlEventTouchUpInside];
        addFuelstationBtn = newButton(@"jot-fuelstation", addFuelstationBtnTag, 144, jotPanel);
        [addFuelstationBtn bk_addEventHandler:^(id sender) {
          configJotButton(^UIViewController * (PEItemAddedBlk itemAddedBlk) {
            return [self newAddFuelStationScreenMakerWithBlk:itemAddedBlk listViewController:listViewController()](user);
          });
        } forControlEvents:UIControlEventTouchUpInside];
        addVehicleBtn = newButton(@"jot-vehicle", addVehicleBtnTag, 211, jotPanel);
        [addVehicleBtn bk_addEventHandler:^(id sender) {
          configJotButton(^UIViewController * (PEItemAddedBlk itemAddedBlk) {
            return [self newAddVehicleScreenMakerWithDelegate:itemAddedBlk listViewController:listViewController()](user);
          });
        } forControlEvents:UIControlEventTouchUpInside];
        rotationAmount = 180 * M_PI/180;
        UIView *dimmedBackgroundView = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:weakTabBarCtrl.view];
        [dimmedBackgroundView setTag:dimmedBgPanelTag];
        [dimmedBackgroundView bk_whenTapped:^{ dismissJotPanel(); }];
        dimmedBackgroundView.backgroundColor = [UIColor blackColor];
        dimmedBackgroundView.alpha = 0.0;
        [weakTabBarCtrl.selectedViewController.view addSubview:dimmedBackgroundView];
        CGFloat offscreenYValueForJotButtons = onscreenYForJotButtons(jotPanel, addVehicleBtn);
        [UIView animateWithDuration:0.18
                         animations:^{ dimmedBackgroundView.alpha = 0.6; }
                         completion:^(BOOL finished) {
                           [UIView animateWithDuration:0.8
                                                 delay:0.0
                                usingSpringWithDamping:0.8
                                 initialSpringVelocity:1.0
                                               options:UIViewAnimationOptionCurveLinear
                                            animations:^{
                                              [PEUIUtils setFrameY:offscreenYValueForJotButtons ofView:addVehicleBtn];
                                              [PEUIUtils setFrameY:offscreenYValueForJotButtons ofView:addFuelstationBtn];
                                              [PEUIUtils setFrameY:offscreenYValueForJotButtons ofView:addOdometerLogBtn];
                                              [PEUIUtils setFrameY:offscreenYValueForJotButtons ofView:addGasLogBtn];
                                            }
                                            completion:nil];
                           [UIView animateWithDuration:0.6f
                                            animations:^{
                                              addVehicleBtn.transform = CGAffineTransformIdentity;
                                              addFuelstationBtn.transform = CGAffineTransformIdentity;
                                              addOdometerLogBtn.transform = CGAffineTransformIdentity;
                                              addGasLogBtn.transform = CGAffineTransformIdentity;
                                            }];
                           [UIView animateWithDuration:0.2f
                                            animations:^{
                                              jotPanel.transform = CGAffineTransformMakeRotation(rotationAmount);
                                              jotBtn.transform = CGAffineTransformMakeRotation(rotationAmount);
                                            }
                                            completion:nil];
                         }];
      } else {
        dismissJotPanel();
      }
    };
    UIButton *jotBtn = [tabBarCtrl addCenterButtonWithImage:tabJotImg highlightImage:nil buttonAction:jotAction];
    [jotBtn setTag:tagForJotButton];
    UIView *jotPanel = [PEUIUtils panelWithWidthOf:0.85 andHeightOf:0.15 relativeToView:weakTabBarCtrl.view];
    jotPanel.layer.cornerRadius = 5.0;
    [jotPanel setTag:jotPanelTag];
    [jotPanel setBackgroundColor:[UIColor whiteColor]];
    jotPanel.layer.anchorPoint = CGPointMake(0.5, -0.5);
    [PEUIUtils placeView:jotPanel
                   below:jotBtn
                    onto:weakTabBarCtrl.view
           withAlignment:PEUIHorizontalAlignmentTypeCenter
                vpadding:3.5
                hpadding:0.0];
    [tabBarCtrl setViewControllers:controllers];
    [tabBarCtrl setSelectedIndex:0];
    return tabBarCtrl;
  };
}

- (UIViewController *)unsynedEditsViewControllerForUser:(FPUser *)user {
  UIViewController *unsyncedEditsController = [self newViewUnsyncedEditsScreenMaker](user);
  return [PEUIUtils navControllerWithRootController:unsyncedEditsController
                                navigationBarHidden:NO
                                    tabBarItemTitle:@"Unsynced Edits"
                                    tabBarItemImage:[UIImage imageNamed:@"tab-drafts"]
                            tabBarItemSelectedImage:[[UIImage imageNamed:@"tab-drafts"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
}

@end
