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
#import "FPQuickActionMenuController.h"
#import <PEObjc-Commons/PEUtils.h>
#import <PEObjc-Commons/PEUIUtils.h>
#import <PEObjc-Commons/NSString+PEAdditions.h>
#import <PEObjc-Commons/PEDatePickerController.h>
#import "PEListViewController.h"
#import "PEAddViewEditController.h"
#import "FPUtils.h"
#import <PEFuelPurchase-Model/PELMNotificationUtils.h>
#import "FPPanelToolkit.h"
#import "FPFpLogVehicleFuelStationDateDataSourceAndDelegate.h"
#import "FPEnvLogVehicleAndDateDataSourceDelegate.h"
#import "NSString+PEAdditions.h"
#import "FPLogEnvLogComposite.h"
#import "FPNames.h"
#import "PELMUIUtils.h"
#import <FlatUIKit/UIColor+FlatUI.h>

NSInteger const PAGINATION_PAGE_SIZE = 30;

@implementation FPScreenToolkit {
  FPCoordinatorDao *_coordDao;
  FPPanelToolkit *_panelToolkit;
  PELMDaoErrorBlk _errorBlk;
}

#pragma mark - Initializers

- (id)initWithCoordinatorDao:(FPCoordinatorDao *)coordDao
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

#pragma mark - Generic Screens

- (FPAuthScreenMaker)newDatePickerScreenMakerWithTitle:(NSString *)title
                                   initialSelectedDate:(NSDate *)date
                                   logDatePickedAction:(void(^)(NSDate *))logDatePickedAction {
  return ^UIViewController *(FPUser *user) {
    return [[PEDatePickerController alloc] initWithTitle:title initialDate:date logDatePickedAction:logDatePickedAction];
  };
}

#pragma mark - Drafts Screens

- (FPAuthScreenMaker)newViewUnsyncedEditsScreenMaker {
  return ^ UIViewController *(FPUser *user) {
    return [[FPEditsInProgressController alloc]
              initWithStoreCoordinator:_coordDao
                                  user:user
                             uitoolkit:_uitoolkit
                         screenToolkit:self];
  };
}

#pragma mark - Settings Screens

- (FPAuthScreenMaker)newViewSettingsScreenMaker {
  return ^ UIViewController *(FPUser *user) {
    return [[FPSettingsController alloc]
              initWithStoreCoordinator:_coordDao
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
    NSString *username = [((UITextField *)[userAccountPanel viewWithTag:FPUserTagUsername]) text];
    if ([email isBlank] && [username isBlank]) {
      [errMsgs addObject:@"Email and Username cannot both be blank."];
    }
    return errMsgs;
  };
}

- (FPAuthScreenMaker)newUserAccountDetailScreenMaker {
  return ^ UIViewController * (FPUser *user) {
    PEEntityEditPreparerBlk userEditPreparer = ^BOOL(PEAddViewEditController *ctrl, FPUser *user) {
      BOOL prepareSuccess = [_coordDao prepareUserForEdit:user
                                                    error:[FPUtils localSaveErrorHandlerMaker]()];
      [APP refreshTabs];
      return prepareSuccess;
    };
    PEEntityEditCancelerBlk userEditCanceler = ^(PEAddViewEditController *ctrl, FPUser *user) {
      [_coordDao cancelEditOfUser:user
                            error:[FPUtils localSaveErrorHandlerMaker]()];
      [APP refreshTabs];
    };
    PESaveEntityBlk userSaver = ^(PEAddViewEditController *ctrl, FPUser *user) {
      [_coordDao saveUser:user
                    error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEMarkAsDoneEditingBlk doneEditingUserMarker = ^(PEAddViewEditController *ctrl,
                                                     FPUser *user,
                                                     PESyncNotFoundBlk notFoundBlk,
                                                     PESyncImmediateSuccessBlk successBlk,
                                                     PESyncImmediateRetryAfterBlk retryAfterBlk,
                                                     PESyncImmediateServerTempErrorBlk tempErrBlk,
                                                     PESyncImmediateServerErrorBlk errBlk,
                                                     PESyncConflictBlk conflictBlk,
                                                     PESyncImmediateAuthRequiredBlk authReqdBlk,
                                                     PESyncImmediateDependencyUnsynced depUnsyncedBlk) {
      NSString *mainMsgFragment = @"syncing user account";
      NSString *recordTitle = @"User account";
      [_coordDao markAsDoneEditingAndSyncUserImmediate:user
                                   notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                            successBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                    remoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                                    tempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                        remoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeSaveUsrErrMsgs:errMask]); [APP refreshTabs];}
                                           conflictBlk:^(FPUser *latestUser) {conflictBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                       authRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                 error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEPrepareUIForUserInteractionBlk prepareUIForUserInteractionBlk = ^(UIView *entityPanel) {
      UITextField *userNameTf = (UITextField *)[entityPanel viewWithTag:FPUserTagName];
      [userNameTf becomeFirstResponder];
    };
    return [PEAddViewEditController
              viewEntityCtrlrWithEntity:user
                     listViewController:nil
                        entityIndexPath:nil
                              uitoolkit:_uitoolkit
                         itemChangedBlk:nil
                   entityFormPanelMaker:[_panelToolkit userAccountFormPanelMaker]
                   entityViewPanelMaker:[_panelToolkit userAccountViewPanelMaker]
                    entityToPanelBinder:[_panelToolkit userToUserPanelBinder]
                    panelToEntityBinder:[_panelToolkit userFormPanelToUserBinder]
                            entityTitle:@"User Account"
                   panelEnablerDisabler:[_panelToolkit userFormPanelEnablerDisabler]
                      entityAddCanceler:nil
                     entityEditPreparer:userEditPreparer
                     entityEditCanceler:userEditCanceler
                            entitySaver:userSaver
                doneEditingEntityMarker:doneEditingUserMarker
                        isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                         isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
         syncImmediateMBProgressHUDMode:MBProgressHUDModeIndeterminate
        isEntityAppropriateForLaterSync:NO
         prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                       viewDidAppearBlk:nil
                        entityValidator:[self newUserAccountValidator]
                                 syncer:nil];
  };
}

#pragma mark - Vehicle Screens

- (PEItemChildrenCounter)vehicleItemChildrenCounter {
  PEItemChildrenCounter itemChildrenCounter = ^ NSInteger (FPVehicle *vehicle,
                                                           NSIndexPath *indexPath,
                                                           UIViewController *listViewController) {
    return [_coordDao numFuelPurchaseLogsForVehicle:vehicle
                                              error:[FPUtils localFetchErrorHandlerMaker]()] +
      [_coordDao numEnvironmentLogsForVehicle:vehicle
                                        error:[FPUtils localFetchErrorHandlerMaker]()];
  };
  return itemChildrenCounter;
}

- (PEItemChildrenMsgsBlk)vehicleItemChildrenMsgs {
  PEItemChildrenMsgsBlk itemChildrenMsgs = ^ NSArray * (FPVehicle *vehicle,
                                                        NSIndexPath *indexPath,
                                                        UIViewController *listViewController) {
    NSInteger numFplogs = [_coordDao numFuelPurchaseLogsForVehicle:vehicle
                                                             error:[FPUtils localFetchErrorHandlerMaker]()];
    NSInteger numEnvlogs = [_coordDao numEnvironmentLogsForVehicle:vehicle
                                                             error:[FPUtils localFetchErrorHandlerMaker]()];
    return @[[NSString stringWithFormat:@"%ld fuel purchase log%@", (long)numFplogs, (numFplogs > 1 ? @"s" : @"")],
             [NSString stringWithFormat:@"%ld environment log%@", (long)numEnvlogs, (numEnvlogs > 1 ? @"s" : @"")]];
  };
  return itemChildrenMsgs;
}

- (PEItemDeleter)vehicleItemDeleterForUser:(FPUser *)user {
  PEItemDeleter itemDeleter = ^ (UIViewController *listViewController,
                                 FPVehicle *vehicle,
                                 NSIndexPath *indexPath,
                                 PESyncNotFoundBlk notFoundBlk,
                                 PESyncImmediateSuccessBlk successBlk,
                                 PESyncImmediateRetryAfterBlk retryAfterBlk,
                                 PESyncImmediateServerTempErrorBlk tempErrBlk,
                                 PESyncImmediateServerErrorBlk errBlk,
                                 PESyncConflictBlk conflictBlk,
                                 PESyncImmediateAuthRequiredBlk authReqdBlk,
                                 PESyncImmediateDependencyUnsynced depUnsyncedBlk) {
    NSString *mainMsgFragment = @"deleting vehicle";
    NSString *recordTitle = @"Vehicle";
    [_coordDao deleteVehicle:vehicle
                     forUser:user
         notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
              addlSuccessBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
      addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
      addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
          addlRemoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeEnvLogErrMsgs:errMask]); [APP refreshTabs];}
             addlConflictBlk:^(id e) {conflictBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
         addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                       error:[FPUtils localSaveErrorHandlerMaker]()];
  };
  return itemDeleter;
}

- (PEItemLocalDeleter)vehicleItemLocalDeleter {
  return ^ (UIViewController *listViewController, FPVehicle *vehicle, NSIndexPath *indexPath) {
    [[_coordDao localDao] deleteVehicle:vehicle error:[FPUtils localSaveErrorHandlerMaker]()];
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
        [self newAddVehicleScreenMakerWithDelegate:itemAddedBlk
                                listViewController:listViewCtrl](user);
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
      return [_coordDao vehiclesForUser:user
                                  error:[FPUtils localFetchErrorHandlerMaker]()];
    };
    PEWouldBeIndexOfEntity wouldBeIndexBlk = [self wouldBeIndexBlkForEqualityBlock:^(FPVehicle *v1, FPVehicle *v2){return [v1 isEqualToVehicle:v2];}
                                                                     entityFetcher:^{ return pageLoader(nil); }];
    PESyncViewStyler tableCellStyler = [PELMUIUtils syncViewStylerWithTitleBlk:^(FPVehicle *vehicle) {return [vehicle name];}
                                                        alwaysTopifyTitleLabel:NO
                                                                     uitoolkit:_uitoolkit
                                                          subtitleLeftHPadding:15.0
                                                                    isLoggedIn:[APP isUserLoggedIn]];
    return [[PEListViewController alloc]
              initWithClassOfDataSourceObjects:[FPVehicle class]
                                         title:@"Vehicles"
                         isPaginatedDataSource:NO
                               tableCellStyler:tableCellStyler
                            itemSelectedAction:nil
                           initialSelectedItem:nil
                                 addItemAction:addVehicleAction
                                cellIdentifier:@"FPVehicleCell"
                                initialObjects:pageLoader(nil)
                                    pageLoader:pageLoader
                                heightForCells:52.0
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
                                                                    isLoggedIn:[APP isUserLoggedIn]];
    return [[PEListViewController alloc]
              initWithClassOfDataSourceObjects:[FPVehicle class]
                                         title:@"Unsynced Vehicles"
                         isPaginatedDataSource:NO
                               tableCellStyler:tableCellStyler
                            itemSelectedAction:nil
                           initialSelectedItem:nil
                                 addItemAction:nil
                                cellIdentifier:@"FPVehicleCell"
                                initialObjects:pageLoader(nil)
                                    pageLoader:pageLoader
                                heightForCells:52.0
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
      return [_coordDao vehiclesForUser:user
                                  error:[FPUtils localFetchErrorHandlerMaker]()];
    };
    PEWouldBeIndexOfEntity wouldBeIndexBlk = [self wouldBeIndexBlkForEqualityBlock:^(FPVehicle *v1, FPVehicle *v2){return [v1 isEqualToVehicle:v2];}
                                                                     entityFetcher:^{ return pageLoader(nil); }];
    PESyncViewStyler tableCellStyler = [PELMUIUtils syncViewStylerWithTitleBlk:^(FPVehicle *vehicle) {return [vehicle name];}
                                                        alwaysTopifyTitleLabel:NO
                                                                     uitoolkit:_uitoolkit
                                                          subtitleLeftHPadding:15.0
                                                                    isLoggedIn:[APP isUserLoggedIn]];
    return [[PEListViewController alloc]
             initWithClassOfDataSourceObjects:[FPVehicle class]
                                        title:@"Choose Vehicle"
                        isPaginatedDataSource:NO
                              tableCellStyler:tableCellStyler
                           itemSelectedAction:itemSelectedAction
                          initialSelectedItem:initialSelectedVehicle
                                addItemAction:addVehicleAction
                               cellIdentifier:@"FPVehicleCell"
                               initialObjects:pageLoader(nil)
                                   pageLoader:pageLoader
                               heightForCells:52.0
                              detailViewMaker:nil
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
    PESaveNewEntityBlk newVehicleSaver = ^(UIView *entityPanel,
                                           FPVehicle *newVehicle,
                                           PESyncNotFoundBlk notFoundBlk,
                                           PESyncImmediateSuccessBlk successBlk,
                                           PESyncImmediateRetryAfterBlk retryAfterBlk,
                                           PESyncImmediateServerTempErrorBlk tempErrBlk,
                                           PESyncImmediateServerErrorBlk errBlk,
                                           PESyncConflictBlk conflictBlk,
                                           PESyncImmediateAuthRequiredBlk authReqdBlk,
                                           PESyncImmediateDependencyUnsynced depUnsyncedBlk) {
      if ([APP doesUserHaveValidAuthToken]) {
        NSString *mainMsgFragment = @"syncing vehicle";
        NSString *recordTitle = @"Vehicle";
        [_coordDao saveNewAndSyncImmediateVehicle:newVehicle
                                          forUser:user
                              notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                       successBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                               remoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                               tempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                   remoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeSaveVehicleErrMsgs:errMask]); [APP refreshTabs];}
                                      conflictBlk:^(id e) {conflictBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                  authRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                            error:[FPUtils localSaveErrorHandlerMaker]()];
      } else {
        [_coordDao saveNewVehicle:newVehicle forUser:user error:[FPUtils localSaveErrorHandlerMaker]()];
        [APP refreshTabs];
      }
    };
    PEPrepareUIForUserInteractionBlk prepareUIForUserInteractionBlk = ^(UIView *entityPanel) {
      UITextField *vehicleNameTf = (UITextField *)[entityPanel viewWithTag:FPVehicleTagName];
      [vehicleNameTf becomeFirstResponder];
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
    return [PEAddViewEditController
             addEntityCtrlrWithUitoolkit:_uitoolkit
                      listViewController:listViewController
                            itemAddedBlk:itemAddedBlk
                    entityFormPanelMaker:[_panelToolkit vehicleFormPanelMaker]
                     entityToPanelBinder:[_panelToolkit vehicleToVehiclePanelBinder]
                     panelToEntityBinder:[_panelToolkit vehicleFormPanelToVehicleBinder]
                             entityTitle:@"Vehicle"
                       entityAddCanceler:addCanceler
                             entityMaker:[_panelToolkit vehicleMaker]
                          newEntitySaver:newVehicleSaver
          prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                        viewDidAppearBlk:nil
                         entityValidator:[self newVehicleValidator]
                         isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                          isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
          syncImmediateMBProgressHUDMode:MBProgressHUDModeIndeterminate
         isEntityAppropriateForLaterSync:YES];
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
      [_coordDao cancelEditOfVehicle:vehicle
                               error:[FPUtils localSaveErrorHandlerMaker]()];
      [APP refreshTabs];
    };
    PESaveEntityBlk vehicleSaver = ^(PEAddViewEditController *ctrl, FPVehicle *vehicle) {
      [_coordDao saveVehicle:vehicle
                       error:[FPUtils localSaveErrorHandlerMaker]()];
      [APP refreshTabs];
    };
    PEMarkAsDoneEditingBlk doneEditingVehicleMarker = ^(PEAddViewEditController *ctrl,
                                                        FPVehicle *vehicle,
                                                        PESyncNotFoundBlk notFoundBlk,
                                                        PESyncImmediateSuccessBlk successBlk,
                                                        PESyncImmediateRetryAfterBlk retryAfterBlk,
                                                        PESyncImmediateServerTempErrorBlk tempErrBlk,
                                                        PESyncImmediateServerErrorBlk errBlk,
                                                        PESyncConflictBlk conflictBlk,
                                                        PESyncImmediateAuthRequiredBlk authReqdBlk,
                                                        PESyncImmediateDependencyUnsynced depUnsyncedBlk) {
      if ([APP doesUserHaveValidAuthToken]) {
        NSString *mainMsgFragment = @"syncing vehicle";
        NSString *recordTitle = @"Vehicle";
        [_coordDao markAsDoneEditingAndSyncVehicleImmediate:vehicle
                                                    forUser:user
                                        notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                 successBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                         remoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                                         tempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                             remoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeSaveVehicleErrMsgs:errMask]); [APP refreshTabs];}
                                                conflictBlk:^(FPVehicle *latestVehicle) {conflictBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                            authRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                      error:[FPUtils localSaveErrorHandlerMaker]()];
      } else {
        [_coordDao markAsDoneEditingVehicle:vehicle
                                      error:[FPUtils localSaveErrorHandlerMaker]()];
        [APP refreshTabs];
      }
    };
    PESyncerBlk syncer = ^(PEAddViewEditController *ctrl,
                           FPVehicle *vehicle,
                           PESyncNotFoundBlk notFoundBlk,
                           PESyncImmediateSuccessBlk successBlk,
                           PESyncImmediateRetryAfterBlk retryAfterBlk,
                           PESyncImmediateServerTempErrorBlk tempErrBlk,
                           PESyncImmediateServerErrorBlk errBlk,
                           PESyncConflictBlk conflictBlk,
                           PESyncImmediateAuthRequiredBlk authReqdBlk,
                           PESyncImmediateDependencyUnsynced depUnsyncedBlk) {
      NSString *mainMsgFragment = @"syncing vehicle";
      NSString *recordTitle = @"Vehicle";
      [_coordDao flushUnsyncedChangesToVehicle:vehicle
                                       forUser:user
                           notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                addlSuccessBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs]; }
                        addlRemoteStoreBusyBlk:^(NSDate *retryAfter){retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                        addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                            addlRemoteErrorBlk:^(NSInteger errMask){errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeSaveVehicleErrMsgs:errMask]); [APP refreshTabs];}
                               addlConflictBlk:^(FPVehicle *latestVehicle) {conflictBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                           addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                         error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEPrepareUIForUserInteractionBlk prepareUIForUserInteractionBlk = ^(UIView *entityPanel) {
      UITextField *vehicleNameTf = (UITextField *)[entityPanel viewWithTag:FPVehicleTagName];
      [vehicleNameTf becomeFirstResponder];
    };
    return [PEAddViewEditController
             viewEntityCtrlrWithEntity:vehicle
                    listViewController:listViewController
                       entityIndexPath:vehicleIndexPath
                             uitoolkit:_uitoolkit
                        itemChangedBlk:itemChangedBlk
                  entityFormPanelMaker:[_panelToolkit vehicleFormPanelMaker]
                  entityViewPanelMaker:[_panelToolkit vehicleViewPanelMaker]
                   entityToPanelBinder:[_panelToolkit vehicleToVehiclePanelBinder]
                   panelToEntityBinder:[_panelToolkit vehicleFormPanelToVehicleBinder]
                           entityTitle:@"Vehicle"
                  panelEnablerDisabler:[_panelToolkit vehicleFormPanelEnablerDisabler]
                     entityAddCanceler:nil
                    entityEditPreparer:vehicleEditPreparer
                    entityEditCanceler:vehicleEditCanceler
                           entitySaver:vehicleSaver
               doneEditingEntityMarker:doneEditingVehicleMarker
                       isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                        isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
        syncImmediateMBProgressHUDMode:MBProgressHUDModeIndeterminate
       isEntityAppropriateForLaterSync:YES
        prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                      viewDidAppearBlk:nil
                       entityValidator:[self newVehicleValidator]
                                syncer:syncer];
  };
}

#pragma mark - Fuel Station Screens

- (PEItemChildrenCounter)fuelStationItemChildrenCounter {
  PEItemChildrenCounter itemChildrenCounter = ^ NSInteger (FPFuelStation *fuelStation,
                                                           NSIndexPath *indexPath,
                                                           UIViewController *listViewController) {
    return [_coordDao numFuelPurchaseLogsForFuelStation:fuelStation
                                                  error:[FPUtils localFetchErrorHandlerMaker]()];
  };
  return itemChildrenCounter;
}

- (PEItemChildrenMsgsBlk)fuelStationItemChildrenMsgs {
  PEItemChildrenMsgsBlk itemChildrenMsgs = ^ NSArray * (FPFuelStation *fuelStation,
                                                        NSIndexPath *indexPath,
                                                        UIViewController *listViewController) {
    NSInteger numFplogs = [_coordDao numFuelPurchaseLogsForFuelStation:fuelStation
                                                                 error:[FPUtils localFetchErrorHandlerMaker]()];
    return @[[NSString stringWithFormat:@"%ld fuel purchase log%@", (long)numFplogs, (numFplogs > 1 ? @"s" : @"")]];
  };
  return itemChildrenMsgs;
}

- (PEItemDeleter)fuelStationItemDeleterForUser:(FPUser *)user {
  PEItemDeleter itemDeleter = ^ (UIViewController *listViewController,
                                 FPFuelStation *fuelStation,
                                 NSIndexPath *indexPath,
                                 PESyncNotFoundBlk notFoundBlk,
                                 PESyncImmediateSuccessBlk successBlk,
                                 PESyncImmediateRetryAfterBlk retryAfterBlk,
                                 PESyncImmediateServerTempErrorBlk tempErrBlk,
                                 PESyncImmediateServerErrorBlk errBlk,
                                 PESyncConflictBlk conflictBlk,
                                 PESyncImmediateAuthRequiredBlk authReqdBlk,
                                 PESyncImmediateDependencyUnsynced depUnsyncedBlk) {
    NSString *mainMsgFragment = @"deleting fuel station";
    NSString *recordTitle = @"Fuel station";
    [_coordDao deleteFuelStation:fuelStation
                         forUser:user
             notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                  addlSuccessBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
          addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
          addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
              addlRemoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeEnvLogErrMsgs:errMask]); [APP refreshTabs];}
                 addlConflictBlk:^(id e) {conflictBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
             addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                           error:[FPUtils localSaveErrorHandlerMaker]()];
  };
  return itemDeleter;
}

- (PEItemLocalDeleter)fuelStationItemLocalDeleter {
  return ^ (UIViewController *listViewController, FPFuelStation *fuelStation, NSIndexPath *indexPath) {
    [[_coordDao localDao] deleteFuelstation:fuelStation error:[FPUtils localSaveErrorHandlerMaker]()];
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
  UILabel * (^compressLabel)(UILabel *) = ^UILabel *(UILabel *label) {
    [PEUIUtils setTextAndResize:[label text] forLabel:label];
    return label;
  };
  NSInteger distanceTag = 10;
  NSInteger unknownReasonTag = 11;
  [[contentView viewWithTag:distanceTag] removeFromSuperview];
  [[contentView viewWithTag:unknownReasonTag] removeFromSuperview];
  LabelMaker cellSubtitleMaker = [_uitoolkit tableCellSubtitleMaker];
  CLLocation *fuelStationLocation = [fuelstation location];
  UILabel *distance = nil;
  UILabel *unknownReason = nil;
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
      distance = cellSubtitleMaker([NSString stringWithFormat:@"%.1f %@ away", distanceVal, distanceUom]);
      if (isNearby) {
        [distance setTextColor:[UIColor greenSeaColor]];
      }
      [PEUIUtils placeView:distance atTopOf:contentView withAlignment:horizontalAlignment vpadding:verticalPadding hpadding:horizontalPadding];
    } else {
      distance = compressLabel(cellSubtitleMaker(@"? away"));
      unknownReason = compressLabel(cellSubtitleMaker(@"(current loc. unknown)"));
      [PEUIUtils placeView:distance atTopOf:contentView withAlignment:horizontalAlignment vpadding:verticalPadding hpadding:horizontalPadding];
      [PEUIUtils placeView:unknownReason below:distance onto:contentView withAlignment:PEUIHorizontalAlignmentTypeRight vpadding:0.0 hpadding:0.0];
    }
  } else {
    distance = compressLabel(cellSubtitleMaker(@"? away"));
    unknownReason = compressLabel(cellSubtitleMaker(@"(fuel station loc. unknown)"));
    [PEUIUtils placeView:distance atTopOf:contentView withAlignment:horizontalAlignment vpadding:verticalPadding hpadding:horizontalPadding];
    [PEUIUtils placeView:unknownReason below:distance onto:contentView withAlignment:PEUIHorizontalAlignmentTypeRight vpadding:0.0 hpadding:0.0];
  }
  [distance setTag:distanceTag];
  [unknownReason setTag:unknownReasonTag];
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
    return [[PEListViewController alloc]
             initWithClassOfDataSourceObjects:[FPFuelStation class]
                                        title:@"Fuel Stations"
                        isPaginatedDataSource:NO
                              tableCellStyler:tableCellStyler
                           itemSelectedAction:nil
                          initialSelectedItem:nil
                                addItemAction:addFuelStationAction
                               cellIdentifier:@"FPFuelStationCell"
                               initialObjects:pageLoader(nil)
                                   pageLoader:pageLoader
                               heightForCells:52.0
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
    return [[PEListViewController alloc]
             initWithClassOfDataSourceObjects:[FPFuelStation class]
                                        title:@"Unsynced Fuel Stations"
                        isPaginatedDataSource:NO
                              tableCellStyler:tableCellStyler
                           itemSelectedAction:nil
                          initialSelectedItem:nil
                                addItemAction:nil
                               cellIdentifier:@"FPFuelStationCell"
                               initialObjects:pageLoader(nil)
                                   pageLoader:pageLoader
                               heightForCells:52.0
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
    return [[PEListViewController alloc]
             initWithClassOfDataSourceObjects:[FPFuelStation class]
                                        title:@"Choose Fuel Station"
                        isPaginatedDataSource:NO
                              tableCellStyler:tableCellStyler
                           itemSelectedAction:itemSelectedAction
                          initialSelectedItem:initialSelectedFuelStation
                                addItemAction:addFuelStationAction
                               cellIdentifier:@"FPFuelStationCell"
                               initialObjects:pageLoader(nil)
                                   pageLoader:pageLoader
                               heightForCells:52.0
                              detailViewMaker:nil
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
    PESaveNewEntityBlk newFuelStationSaver = ^(UIView *entityPanel,
                                               FPFuelStation *newFuelStation,
                                               PESyncNotFoundBlk notFoundBlk,
                                               PESyncImmediateSuccessBlk successBlk,
                                               PESyncImmediateRetryAfterBlk retryAfterBlk,
                                               PESyncImmediateServerTempErrorBlk tempErrBlk,
                                               PESyncImmediateServerErrorBlk errBlk,
                                               PESyncConflictBlk conflictBlk,
                                               PESyncImmediateAuthRequiredBlk authReqdBlk,
                                               PESyncImmediateDependencyUnsynced depUnsyncedBlk) {
      if ([APP doesUserHaveValidAuthToken]) {
        NSString *mainMsgFragment = @"syncing fuel station";
        NSString *recordTitle = @"Fuel station";
        [_coordDao saveNewAndSyncImmediateFuelStation:newFuelStation
                                              forUser:user
                                  notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                           successBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                   remoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                                   tempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                       remoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeSaveFuelStationErrMsgs:errMask]); [APP refreshTabs];}
                                          conflictBlk:^(id e) {conflictBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                      authRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                error:[FPUtils localSaveErrorHandlerMaker]()];
      } else {
        [_coordDao saveNewFuelStation:newFuelStation
                              forUser:user
                                error:[FPUtils localSaveErrorHandlerMaker]()];
        [APP refreshTabs];
      }
    };
    PEPrepareUIForUserInteractionBlk prepareUIForUserInteractionBlk = ^(UIView *entityPanel) {
      UITextField *nameTf = (UITextField *)[entityPanel viewWithTag:FPFuelStationTagName];
      [nameTf becomeFirstResponder];
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
    return [PEAddViewEditController
             addEntityCtrlrWithUitoolkit:_uitoolkit
                      listViewController:listViewController
                            itemAddedBlk:itemAddedBlk
                    entityFormPanelMaker:[_panelToolkit fuelstationFormPanelMaker]
                     entityToPanelBinder:[_panelToolkit fuelstationToFuelstationPanelBinder]
                     panelToEntityBinder:[_panelToolkit fuelstationFormPanelToFuelstationBinder]
                             entityTitle:@"Fuel Station"
                       entityAddCanceler:addCanceler
                             entityMaker:[_panelToolkit fuelstationMaker]
                          newEntitySaver:newFuelStationSaver
          prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                        viewDidAppearBlk:nil
                         entityValidator:[self newFuelStationValidator]
                         isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                          isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
          syncImmediateMBProgressHUDMode:MBProgressHUDModeIndeterminate
         isEntityAppropriateForLaterSync:YES];
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
    PEMarkAsDoneEditingBlk doneEditingFuelStationMarker = ^(PEAddViewEditController *ctrl,
                                                            PELMModelSupport *entity,
                                                            PESyncNotFoundBlk notFoundBlk,
                                                            PESyncImmediateSuccessBlk successBlk,
                                                            PESyncImmediateRetryAfterBlk retryAfterBlk,
                                                            PESyncImmediateServerTempErrorBlk tempErrBlk,
                                                            PESyncImmediateServerErrorBlk errBlk,
                                                            PESyncConflictBlk conflictBlk,
                                                            PESyncImmediateAuthRequiredBlk authReqdBlk,
                                                            PESyncImmediateDependencyUnsynced depUnsyncedBlk) {
      if ([APP doesUserHaveValidAuthToken]) {
        NSString *mainMsgFragment = @"syncing fuel station";
        NSString *recordTitle = @"Fuel station";
        FPFuelStation *fuelStation = (FPFuelStation *)entity;
        [_coordDao markAsDoneEditingAndSyncFuelStationImmediate:fuelStation
                                                        forUser:user
                                            notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                     successBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                             remoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                                             tempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                 remoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeSaveFuelStationErrMsgs:errMask]); [APP refreshTabs];}
                                                    conflictBlk:^(FPFuelStation *latestFuelStation) {conflictBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                authRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                          error:[FPUtils localSaveErrorHandlerMaker]()];
      } else {
        [_coordDao markAsDoneEditingFuelStation:fuelStation
                                          error:[FPUtils localSaveErrorHandlerMaker]()];
        [APP refreshTabs];
      }
    };
    PESyncerBlk syncer = ^(PEAddViewEditController *ctrl,
                           FPFuelStation *fuelStation,
                           PESyncNotFoundBlk notFoundBlk,
                           PESyncImmediateSuccessBlk successBlk,
                           PESyncImmediateRetryAfterBlk retryAfterBlk,
                           PESyncImmediateServerTempErrorBlk tempErrBlk,
                           PESyncImmediateServerErrorBlk errBlk,
                           PESyncConflictBlk conflictBlk,
                           PESyncImmediateAuthRequiredBlk authReqdBlk,
                           PESyncImmediateDependencyUnsynced depUnsyncedBlk) {
      NSString *mainMsgFragment = @"syncing fuel station";
      NSString *recordTitle = @"Fuel station";
      [_coordDao flushUnsyncedChangesToFuelStation:fuelStation
                                           forUser:user
                               notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                    addlSuccessBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                            addlRemoteStoreBusyBlk:^(NSDate *retryAfter){retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                            addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                addlRemoteErrorBlk:^(NSInteger errMask){errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeSaveFuelStationErrMsgs:errMask]); [APP refreshTabs];}
                                   addlConflictBlk:^(FPFuelStation *latestFuelStation) {conflictBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                               addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                             error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEPrepareUIForUserInteractionBlk prepareUIForUserInteractionBlk = ^(UIView *entityPanel) {
      UITextField *nameTf = (UITextField *)[entityPanel viewWithTag:FPFuelStationTagName];
      [nameTf becomeFirstResponder];
    };
    return [PEAddViewEditController
             viewEntityCtrlrWithEntity:fuelStation
                    listViewController:listViewController
                       entityIndexPath:fuelStationIndexPath
                             uitoolkit:_uitoolkit
                        itemChangedBlk:itemChangedBlk
                  entityFormPanelMaker:[_panelToolkit fuelstationFormPanelMaker]
                  entityViewPanelMaker:[_panelToolkit fuelstationViewPanelMaker]
                   entityToPanelBinder:[_panelToolkit fuelstationToFuelstationPanelBinder]
                   panelToEntityBinder:[_panelToolkit fuelstationFormPanelToFuelstationBinder]
                           entityTitle:@"Fuel Station"
                  panelEnablerDisabler:[_panelToolkit fuelstationFormPanelEnablerDisabler]
                     entityAddCanceler:nil
                    entityEditPreparer:fuelStationEditPreparer
                    entityEditCanceler:fuelStationEditCanceler
                           entitySaver:fuelStationSaver
               doneEditingEntityMarker:doneEditingFuelStationMarker
                       isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                        isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
        syncImmediateMBProgressHUDMode:MBProgressHUDModeIndeterminate
       isEntityAppropriateForLaterSync:YES
        prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                      viewDidAppearBlk:nil
                       entityValidator:[self newFuelStationValidator]
                                syncer:syncer];
  };
}

#pragma mark - Fuel Purchase Log Screens

- (PEEntityValidatorBlk)newFpEnvLogCompositeValidator {
  return ^NSArray *(UIView *fpEnvLogCompositePanel) {
    NSMutableArray *errMsgs = [NSMutableArray array];
    PEEntityValidatorBlk fpLogValidator = [self newFuelPurchaseLogValidator];
    [errMsgs addObjectsFromArray:fpLogValidator(fpEnvLogCompositePanel)];
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
      [errMsgs addObject:@"Must select a fuel station."];
    }
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
    PESaveNewEntityBlk newFuelPurchaseLogSaver = ^(UIView *entityPanel,
                                                   FPLogEnvLogComposite *fpEnvLogComposite,
                                                   PESyncNotFoundBlk notFoundBlk,
                                                   PESyncImmediateSuccessBlk successBlk,
                                                   PESyncImmediateRetryAfterBlk retryAfterBlk,
                                                   PESyncImmediateServerTempErrorBlk tempErrBlk,
                                                   PESyncImmediateServerErrorBlk errBlk,
                                                   PESyncConflictBlk conflictBlk,
                                                   PESyncImmediateAuthRequiredBlk authReqdBlk,
                                                   PESyncImmediateDependencyUnsynced depUnsyncedBlk) {
      FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds =
        (FPFpLogVehicleFuelStationDateDataSourceAndDelegate *)
          [(UITableView *)[entityPanel viewWithTag:FPFpLogTagVehicleFuelStationAndDate] dataSource];
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
      NSString *mainMsgFragment = @"syncing fuel purchase log";
      if (savePreFillupEnvLogPercentComplete || savePostFillupEnvLogPercentComplete) {
        mainMsgFragment = @"syncing fuel purchase\nand environment logs";
      }
      NSString *recordTitle = @"Fuel purchase log";
      BOOL doSyncImmediate = [APP doesUserHaveValidAuthToken];
      if (doSyncImmediate) {
        [_coordDao saveNewAndSyncImmediateFuelPurchaseLog:[fpEnvLogComposite fpLog]
                                                  forUser:user
                                                  vehicle:selectedVehicle
                                              fuelStation:selectedFuelStation
                                      notFoundOnServerBlk:^{notFoundBlk(saveFpLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                               successBlk:^{successBlk(saveFpLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                       remoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(saveFpLogPercentComplete, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                                       tempRemoteErrorBlk:^{tempErrBlk(saveFpLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                           remoteErrorBlk:^(NSInteger errMask) {errBlk(saveFpLogPercentComplete, mainMsgFragment, recordTitle, [FPUtils computeFpLogErrMsgs:errMask]); [APP refreshTabs];}
                                              conflictBlk:^(id e) {conflictBlk(saveFpLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                          authRequiredBlk:^{authReqdBlk(saveFpLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                             skippedDueToVehicleNotSynced:^{depUnsyncedBlk(saveFpLogPercentComplete, mainMsgFragment, recordTitle, @"The associated vehicle is not yet synced."); [APP refreshTabs];}
                         skippedDueToFuelStationNotSynced:^{depUnsyncedBlk(saveFpLogPercentComplete, mainMsgFragment, recordTitle, @"The associated fuel station is not yet synced."); [APP refreshTabs];}
                                                    error:[FPUtils localSaveErrorHandlerMaker]()];
      } else {
        [_coordDao saveNewFuelPurchaseLog:[fpEnvLogComposite fpLog]
                                  forUser:user
                                  vehicle:selectedVehicle
                              fuelStation:selectedFuelStation
                                    error:[FPUtils localSaveErrorHandlerMaker]()];
        [APP refreshTabs];
      }
      if (savePreFillupEnvLogPercentComplete) {
        recordTitle = @"Pre-fillup environment log";
        if (doSyncImmediate) {
          [_coordDao saveNewAndSyncImmediateEnvironmentLog:[fpEnvLogComposite preFillupEnvLog]
                                                   forUser:user
                                                   vehicle:selectedVehicle
                                       notFoundOnServerBlk:^{notFoundBlk(savePreFillupEnvLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                successBlk:^{successBlk(savePreFillupEnvLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                        remoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(savePreFillupEnvLogPercentComplete, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                                        tempRemoteErrorBlk:^{tempErrBlk(savePreFillupEnvLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                            remoteErrorBlk:^(NSInteger errMask) {errBlk(savePreFillupEnvLogPercentComplete, mainMsgFragment, recordTitle, [FPUtils computeEnvLogErrMsgs:errMask]); [APP refreshTabs];}
                                               conflictBlk:^(id e) {conflictBlk(savePreFillupEnvLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                           authRequiredBlk:^{authReqdBlk(savePreFillupEnvLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                              skippedDueToVehicleNotSynced:^{depUnsyncedBlk(savePreFillupEnvLogPercentComplete, mainMsgFragment, recordTitle, @"The associated vehicle is not yet synced."); [APP refreshTabs];}
                                                     error:[FPUtils localSaveErrorHandlerMaker]()];
        } else {
          [_coordDao saveNewEnvironmentLog:[fpEnvLogComposite preFillupEnvLog]
                                   forUser:user vehicle:selectedVehicle
                                     error:[FPUtils localSaveErrorHandlerMaker]()];
          [APP refreshTabs];
        }
      }
      if (savePostFillupEnvLogPercentComplete) {
        recordTitle = @"Post-fillup environment log";
        if (doSyncImmediate) {
          [_coordDao saveNewAndSyncImmediateEnvironmentLog:[fpEnvLogComposite postFillupEnvLog]
                                                   forUser:user
                                                   vehicle:selectedVehicle
                                       notFoundOnServerBlk:^{notFoundBlk(savePostFillupEnvLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                successBlk:^{successBlk(savePostFillupEnvLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                        remoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(savePostFillupEnvLogPercentComplete, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                                        tempRemoteErrorBlk:^{tempErrBlk(savePostFillupEnvLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                            remoteErrorBlk:^(NSInteger errMask) {errBlk(savePostFillupEnvLogPercentComplete, mainMsgFragment, recordTitle, [FPUtils computeEnvLogErrMsgs:errMask]); [APP refreshTabs];}
                                               conflictBlk:^(id e) {conflictBlk(savePostFillupEnvLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                           authRequiredBlk:^{authReqdBlk(savePostFillupEnvLogPercentComplete, mainMsgFragment, recordTitle); [APP refreshTabs];}
                              skippedDueToVehicleNotSynced:^{depUnsyncedBlk(savePostFillupEnvLogPercentComplete, mainMsgFragment, recordTitle, @"The associated vehicle is not yet synced."); [APP refreshTabs];}
                                                     error:[FPUtils localSaveErrorHandlerMaker]()];
        } else {
          [_coordDao saveNewEnvironmentLog:[fpEnvLogComposite postFillupEnvLog]
                                   forUser:user vehicle:selectedVehicle
                                     error:[FPUtils localSaveErrorHandlerMaker]()];
          [APP refreshTabs];
        }
      }
    };
    PEViewDidAppearBlk viewDidAppearBlk = ^(UIView *entityPanel) {
      UITableView *vehicleFuelStationTable =
        (UITableView *)[entityPanel viewWithTag:FPFpLogTagVehicleFuelStationAndDate];
      if ([vehicleFuelStationTable indexPathForSelectedRow]) {
        [vehicleFuelStationTable deselectRowAtIndexPath:[vehicleFuelStationTable indexPathForSelectedRow]
                                               animated:YES];
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
    return [PEAddViewEditController
             addEntityCtrlrWithUitoolkit:_uitoolkit
                      listViewController:listViewController
                            itemAddedBlk:itemAddedBlk
                        entityFormPanelMaker:[_panelToolkit fpEnvLogCompositeFormPanelMakerWithUser:user
                                                                     defaultSelectedVehicle:defaultSelectedVehicle
                                                                 defaultSelectedFuelStation:defaultSelectedFuelStation
                                                                       defaultPickedLogDate:[NSDate date]]
                     entityToPanelBinder:[_panelToolkit fpEnvLogCompositeToFpEnvLogCompositePanelBinder]
                     panelToEntityBinder:[_panelToolkit fpEnvLogCompositeFormPanelToFpEnvLogCompositeBinder]
                             entityTitle:@"Fuel Purchase Log"
                       entityAddCanceler:addCanceler
                             entityMaker:[_panelToolkit fpEnvLogCompositeMaker]
                          newEntitySaver:newFuelPurchaseLogSaver
          prepareUIForUserInteractionBlk:nil
                        viewDidAppearBlk:viewDidAppearBlk
                         entityValidator:[self newFpEnvLogCompositeValidator]
                         isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                          isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
          syncImmediateMBProgressHUDMode:MBProgressHUDModeDeterminate
         isEntityAppropriateForLaterSync:YES
                   getterForNotification:@selector(fpLog)];
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
      [_coordDao cancelEditOfFuelPurchaseLog:fpLog
                                       error:[FPUtils localSaveErrorHandlerMaker]()];
      refreshVehicleFuelStationTableView(ctrl, fpLog);
      [APP refreshTabs];
    };
    PESaveEntityBlk fpLogSaver = ^(PEAddViewEditController *ctrl, FPFuelPurchaseLog *fpLog) {
      refreshVehicleFuelStationTableView(ctrl, fpLog);
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
    PEMarkAsDoneEditingBlk doneEditingFuelPurchaseLogMarker = ^(PEAddViewEditController *ctrl,
                                                                FPFuelPurchaseLog *fpLog,
                                                                PESyncNotFoundBlk notFoundBlk,
                                                                PESyncImmediateSuccessBlk successBlk,
                                                                PESyncImmediateRetryAfterBlk retryAfterBlk,
                                                                PESyncImmediateServerTempErrorBlk tempErrBlk,
                                                                PESyncImmediateServerErrorBlk errBlk,
                                                                PESyncConflictBlk conflictBlk,
                                                                PESyncImmediateAuthRequiredBlk authReqdBlk,
                                                                PESyncImmediateDependencyUnsynced depUnsyncedBlk) {
      if ([APP doesUserHaveValidAuthToken]) {
        NSString *mainMsgFragment = @"syncing fuel purchase log";
        NSString *recordTitle = @"Fuel purchase log";
        [_coordDao markAsDoneEditingAndSyncFuelPurchaseLogImmediate:fpLog
                                                            forUser:user
                                                notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                         successBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                 remoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                                                 tempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                     remoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeFpLogErrMsgs:errMask]); [APP refreshTabs];}
                                                        conflictBlk:^(FPFuelPurchaseLog *latestFplog) {conflictBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                    authRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                       skippedDueToVehicleNotSynced:^{depUnsyncedBlk(1, mainMsgFragment, recordTitle, @"The associated vehicle is not yet synced."); [APP refreshTabs];}
                                   skippedDueToFuelStationNotSynced:^{depUnsyncedBlk(1, mainMsgFragment, recordTitle, @"The associated fuel station is not yet synced."); [APP refreshTabs];}
                                                              error:[FPUtils localSaveErrorHandlerMaker]()];
      } else {
        [_coordDao markAsDoneEditingFuelPurchaseLog:fpLog
                                              error:[FPUtils localSaveErrorHandlerMaker]()];
        [APP refreshTabs];
      }
    };
    PESyncerBlk syncer = ^(PEAddViewEditController *ctrl,
                           FPFuelPurchaseLog *fpLog,
                           PESyncNotFoundBlk notFoundBlk,
                           PESyncImmediateSuccessBlk successBlk,
                           PESyncImmediateRetryAfterBlk retryAfterBlk,
                           PESyncImmediateServerTempErrorBlk tempErrBlk,
                           PESyncImmediateServerErrorBlk errBlk,
                           PESyncConflictBlk conflictBlk,
                           PESyncImmediateAuthRequiredBlk authReqdBlk,
                           PESyncImmediateDependencyUnsynced depUnsyncedBlk) {
      NSString *mainMsgFragment = @"syncing fuel purchase log";
      NSString *recordTitle = @"Fuel purchase log";
      [_coordDao flushUnsyncedChangesToFuelPurchaseLog:fpLog
                                              forUser:user
                                   notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                       addlSuccessBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                               addlRemoteStoreBusyBlk:^(NSDate *retryAfter){retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                               addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                   addlRemoteErrorBlk:^(NSInteger errMask){errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeFpLogErrMsgs:errMask]); [APP refreshTabs];}
                                      addlConflictBlk:^(FPFuelPurchaseLog *latestFplog) {conflictBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                  addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                         skippedDueToVehicleNotSynced:^{depUnsyncedBlk(1, mainMsgFragment, recordTitle, @"The associated vehicle is not yet synced."); [APP refreshTabs];}
                     skippedDueToFuelStationNotSynced:^{depUnsyncedBlk(1, mainMsgFragment, recordTitle, @"The associated fuel station is not yet synced."); [APP refreshTabs];}
                                                error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    return [PEAddViewEditController
             viewEntityCtrlrWithEntity:fpLog
                    listViewController:listViewController
                       entityIndexPath:fpLogIndexPath
                             uitoolkit:_uitoolkit
                        itemChangedBlk:itemChangedBlk
                  entityFormPanelMaker:
                        [_panelToolkit
                           fplogFormPanelMakerWithUser:user
                                defaultSelectedVehicle:[_coordDao vehicleForFuelPurchaseLog:fpLog error:[FPUtils localFetchErrorHandlerMaker]()]
                            defaultSelectedFuelStation:[_coordDao fuelStationForFuelPurchaseLog:fpLog error:[FPUtils localFetchErrorHandlerMaker]()]
                                  defaultPickedLogDate:[fpLog purchasedAt]]
                  entityViewPanelMaker:[_panelToolkit fplogViewPanelMakerWithUser:user]
                   entityToPanelBinder:[_panelToolkit fplogToFplogPanelBinder]
                   panelToEntityBinder:[_panelToolkit fplogFormPanelToFplogBinder]
                           entityTitle:@"Fuel Purchase Log"
                  panelEnablerDisabler:[_panelToolkit fplogFormPanelEnablerDisabler]
                     entityAddCanceler:nil
                    entityEditPreparer:fpLogEditPreparer
                    entityEditCanceler:fpLogEditCanceler
                           entitySaver:fpLogSaver
               doneEditingEntityMarker:doneEditingFuelPurchaseLogMarker
                       isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                        isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
        syncImmediateMBProgressHUDMode:MBProgressHUDModeIndeterminate
       isEntityAppropriateForLaterSync:YES
        prepareUIForUserInteractionBlk:nil
                      viewDidAppearBlk:nil
                       entityValidator:[self newFuelPurchaseLogValidator]
                                syncer:syncer];
  };
}

- (PEItemDeleter)fplogItemDeleterForUser:(FPUser *)user {
  PEItemDeleter itemDeleter = ^ (UIViewController *listViewController,
                                 FPFuelPurchaseLog *fplog,
                                 NSIndexPath *indexPath,
                                 PESyncNotFoundBlk notFoundBlk,
                                 PESyncImmediateSuccessBlk successBlk,
                                 PESyncImmediateRetryAfterBlk retryAfterBlk,
                                 PESyncImmediateServerTempErrorBlk tempErrBlk,
                                 PESyncImmediateServerErrorBlk errBlk,
                                 PESyncConflictBlk conflictBlk,
                                 PESyncImmediateAuthRequiredBlk authReqdBlk,
                                 PESyncImmediateDependencyUnsynced depUnsyncedBlk) {
    NSString *mainMsgFragment = @"deleting fuel purchase log";
    NSString *recordTitle = @"Fuel purchase log";
    [_coordDao deleteFuelPurchaseLog:fplog
                             forUser:user
                 notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                      addlSuccessBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
              addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
              addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                  addlRemoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeEnvLogErrMsgs:errMask]); [APP refreshTabs];}
                     addlConflictBlk:^(id e) {conflictBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                 addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                               error:[FPUtils localSaveErrorHandlerMaker]()];
  };
  return itemDeleter;
}

- (PEItemLocalDeleter)fplogItemLocalDeleter {
  return ^ (UIViewController *listViewController, FPFuelPurchaseLog *fplog, NSIndexPath *indexPath) {
    [[_coordDao localDao] deleteFuelPurchaseLog:fplog error:[FPUtils localSaveErrorHandlerMaker]()];
    [APP refreshTabs];
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
                                                                    isLoggedIn:[APP isUserLoggedIn]];
    return [[PEListViewController alloc]
             initWithClassOfDataSourceObjects:[FPFuelPurchaseLog class]
                                        title:@"Fuel Purchase Logs"
                        isPaginatedDataSource:YES
                              tableCellStyler:tableCellStyler
                           itemSelectedAction:nil
                          initialSelectedItem:nil
                                addItemAction:addFpLogAction
                               cellIdentifier:@"FPFuelPurchaseLogCell"
                               initialObjects:initialFpLogs
                                   pageLoader:pageLoader
                               heightForCells:52.0
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
                             defaultSelectedVehicle:[_coordDao defaultVehicleForNewFuelPurchaseLogForUser:user
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
                                                                    isLoggedIn:[APP isUserLoggedIn]];
    return [[PEListViewController alloc]
             initWithClassOfDataSourceObjects:[FPFuelPurchaseLog class]
                                        title:@"Fuel Purchase Logs"
                        isPaginatedDataSource:YES
                              tableCellStyler:tableCellStyler
                           itemSelectedAction:nil
                          initialSelectedItem:nil
                                addItemAction:addFpLogAction
                               cellIdentifier:@"FPFuelPurchaseLogCell"
                               initialObjects:initialFpLogs
                                   pageLoader:pageLoader
                               heightForCells:52.0
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
                                                                    isLoggedIn:[APP isUserLoggedIn]];
    return [[PEListViewController alloc]
             initWithClassOfDataSourceObjects:[FPFuelPurchaseLog class]
                                        title:@"Unsynced FP Logs"
                        isPaginatedDataSource:NO
                              tableCellStyler:tableCellStyler
                           itemSelectedAction:nil
                          initialSelectedItem:nil
                                addItemAction:nil
                               cellIdentifier:@"FPFuelPurchaseLogCell"
                               initialObjects:pageLoader(nil)
                                   pageLoader:pageLoader
                               heightForCells:52.0
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
    PEMessageCollector cannotBeBlankCollector =
      [PEUIUtils newTfCannotBeEmptyBlkForMsgs:errMsgs entityPanel:envLogPanel];
    cannotBeBlankCollector(FPEnvLogTagOdometer, @"Odometer cannot be empty.");
    cannotBeBlankCollector(FPEnvLogTagReportedOutsideTemp, @"Reported outside temperature cannot\nbe empty.");
    return errMsgs;
  };
}

- (FPAuthScreenMaker)newAddEnvironmentLogScreenMakerWithBlk:(PEItemAddedBlk)itemAddedBlk
                                     defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle
                                         listViewController:(PEListViewController *)listViewController {
  return ^ UIViewController * (FPUser *user) {
    PESaveNewEntityBlk newEnvironmentLogSaver = ^(UIView *entityPanel,
                                                  FPEnvironmentLog *envLog,
                                                  PESyncNotFoundBlk notFoundBlk,
                                                  PESyncImmediateSuccessBlk successBlk,
                                                  PESyncImmediateRetryAfterBlk retryAfterBlk,
                                                  PESyncImmediateServerTempErrorBlk tempErrBlk,
                                                  PESyncImmediateServerErrorBlk errBlk,
                                                  PESyncConflictBlk conflictBlk,
                                                  PESyncImmediateAuthRequiredBlk authReqdBlk,
                                                  PESyncImmediateDependencyUnsynced depUnsyncedBlk) {
      FPEnvLogVehicleAndDateDataSourceDelegate *ds =
        (FPEnvLogVehicleAndDateDataSourceDelegate *)
        [(UITableView *)[entityPanel viewWithTag:FPEnvLogTagVehicleAndDate] dataSource];
      FPVehicle *selectedVehicle = [ds selectedVehicle];
      if ([APP doesUserHaveValidAuthToken]) {
        NSString *mainMsgFragment = @"syncing environment log";
        NSString *recordTitle = @"Environment log";
        [_coordDao saveNewAndSyncImmediateEnvironmentLog:envLog
                                                 forUser:user
                                                 vehicle:selectedVehicle
                                     notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                              successBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                      remoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                                      tempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                          remoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeEnvLogErrMsgs:errMask]); [APP refreshTabs];}
                                             conflictBlk:^(id e) {conflictBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                         authRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                            skippedDueToVehicleNotSynced:^{depUnsyncedBlk(1, mainMsgFragment, recordTitle, @"The associated vehicle is not yet synced."); [APP refreshTabs];}
                                                   error:[FPUtils localSaveErrorHandlerMaker]()];
      } else {
        [_coordDao saveNewEnvironmentLog:envLog
                                 forUser:user
                                 vehicle:selectedVehicle
                                   error:[FPUtils localSaveErrorHandlerMaker]()];
        [APP refreshTabs];
      }
    };
    PEViewDidAppearBlk viewDidAppearBlk = ^(UIView *entityPanel) {
      UITableView *vehicleTable =
      (UITableView *)[entityPanel viewWithTag:FPEnvLogTagVehicleAndDate];
      if ([vehicleTable indexPathForSelectedRow]) {
        [vehicleTable deselectRowAtIndexPath:[vehicleTable indexPathForSelectedRow]
                                    animated:YES];
      }
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
    return [PEAddViewEditController
              addEntityCtrlrWithUitoolkit:_uitoolkit
                       listViewController:listViewController
                             itemAddedBlk:itemAddedBlk
                         entityFormPanelMaker:[_panelToolkit envlogFormPanelMakerWithUser:user
                                                                   defaultSelectedVehicle:defaultSelectedVehicle
                                                                     defaultPickedLogDate:[NSDate date]]
                      entityToPanelBinder:[_panelToolkit envlogToEnvlogPanelBinder]
                      panelToEntityBinder:[_panelToolkit envlogFormPanelToEnvlogBinder]
                              entityTitle:@"Environment Log"
                        entityAddCanceler:addCanceler
                              entityMaker:[_panelToolkit envlogMaker]
                           newEntitySaver:newEnvironmentLogSaver
           prepareUIForUserInteractionBlk:nil
                         viewDidAppearBlk:viewDidAppearBlk
                          entityValidator:[self newEnvironmentLogValidator]
                          isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                           isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
           syncImmediateMBProgressHUDMode:MBProgressHUDModeIndeterminate
          isEntityAppropriateForLaterSync:YES];
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
      refreshVehicleTableView(ctrl, envLog);
      FPEnvLogVehicleAndDateDataSourceDelegate *ds =
        (FPEnvLogVehicleAndDateDataSourceDelegate *)
        [(UITableView *)[[ctrl view] viewWithTag:FPEnvLogTagVehicleAndDate] dataSource];
      FPVehicle *selectedVehicle = [ds selectedVehicle];
      [_coordDao saveEnvironmentLog:envLog
                            forUser:user
                            vehicle:selectedVehicle
                              error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEMarkAsDoneEditingBlk doneEditingEnvironmentLogMarker = ^(PEAddViewEditController *ctrl,
                                                               FPEnvironmentLog *envLog,
                                                               PESyncNotFoundBlk notFoundBlk,
                                                               PESyncImmediateSuccessBlk successBlk,
                                                               PESyncImmediateRetryAfterBlk retryAfterBlk,
                                                               PESyncImmediateServerTempErrorBlk tempErrBlk,
                                                               PESyncImmediateServerErrorBlk errBlk,
                                                               PESyncConflictBlk conflictBlk,
                                                               PESyncImmediateAuthRequiredBlk authReqdBlk,
                                                               PESyncImmediateDependencyUnsynced depUnsyncedBlk) {
      if ([APP doesUserHaveValidAuthToken]) {
        NSString *mainMsgFragment = @"syncing environment log";
        NSString *recordTitle = @"Environment log";
        [_coordDao markAsDoneEditingAndSyncEnvironmentLogImmediate:envLog
                                                            forUser:user
                                               notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                         successBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                 remoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                                                 tempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                     remoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeEnvLogErrMsgs:errMask]); [APP refreshTabs];}
                                                        conflictBlk:^(FPEnvironmentLog *latestEnvlog) {conflictBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                                    authRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                       skippedDueToVehicleNotSynced:^{depUnsyncedBlk(1, mainMsgFragment, recordTitle, @"The associated vehicle is not yet synced."); [APP refreshTabs];}
                                                              error:[FPUtils localSaveErrorHandlerMaker]()];
      } else {
        [_coordDao markAsDoneEditingEnvironmentLog:envLog
                                              error:[FPUtils localSaveErrorHandlerMaker]()];
        [APP refreshTabs];
      }
    };
    PESyncerBlk syncer = ^(PEAddViewEditController *ctrl,
                           FPEnvironmentLog *envLog,
                           PESyncNotFoundBlk notFoundBlk,
                           PESyncImmediateSuccessBlk successBlk,
                           PESyncImmediateRetryAfterBlk retryAfterBlk,
                           PESyncImmediateServerTempErrorBlk tempErrBlk,
                           PESyncImmediateServerErrorBlk errBlk,
                           PESyncConflictBlk conflictBlk,
                           PESyncImmediateAuthRequiredBlk authReqdBlk,
                           PESyncImmediateDependencyUnsynced depUnsyncedBlk) {
      NSString *mainMsgFragment = @"syncing environment log";
      NSString *recordTitle = @"Environment log";
      [_coordDao flushUnsyncedChangesToEnvironmentLog:envLog
                                              forUser:user
                                  notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                       addlSuccessBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                               addlRemoteStoreBusyBlk:^(NSDate *retryAfter){retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
                               addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                   addlRemoteErrorBlk:^(NSInteger errMask){errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeEnvLogErrMsgs:errMask]); [APP refreshTabs];}
                                      addlConflictBlk:^(FPEnvironmentLog *latestEnvlog) {conflictBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                                  addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                         skippedDueToVehicleNotSynced:^{depUnsyncedBlk(1, mainMsgFragment, recordTitle, @"The associated vehicle is not yet synced."); [APP refreshTabs];}
                                                error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    return [PEAddViewEditController viewEntityCtrlrWithEntity:envLog
                                           listViewController:listViewController
                                              entityIndexPath:envLogIndexPath
                                                    uitoolkit:_uitoolkit
                                               itemChangedBlk:itemChangedBlk
                                         entityFormPanelMaker:[_panelToolkit envlogFormPanelMakerWithUser:user
                                                                                   defaultSelectedVehicle:[_coordDao vehicleForEnvironmentLog:envLog
                                                                                                                                        error:[FPUtils localFetchErrorHandlerMaker]()]
                                                                                     defaultPickedLogDate:[envLog logDate]]
                                         entityViewPanelMaker:[_panelToolkit envlogViewPanelMakerWithUser:user]
                                          entityToPanelBinder:[_panelToolkit envlogToEnvlogPanelBinder]
                                          panelToEntityBinder:[_panelToolkit envlogFormPanelToEnvlogBinder]
                                                  entityTitle:@"Environment Log"
                                         panelEnablerDisabler:[_panelToolkit envlogFormPanelEnablerDisabler]
                                            entityAddCanceler:nil
                                           entityEditPreparer:envLogEditPreparer
                                           entityEditCanceler:envLogEditCanceler
                                                  entitySaver:envLogSaver
                                      doneEditingEntityMarker:doneEditingEnvironmentLogMarker
                                              isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                               isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                               syncImmediateMBProgressHUDMode:MBProgressHUDModeIndeterminate
                              isEntityAppropriateForLaterSync:YES
                               prepareUIForUserInteractionBlk:nil
                                             viewDidAppearBlk:nil
                                              entityValidator:[self newEnvironmentLogValidator]
                                                       syncer:syncer];
  };
}

- (PEItemDeleter)envlogItemDeleterForUser:(FPUser *)user {
  PEItemDeleter itemDeleter = ^ (UIViewController *listViewController,
                                 FPEnvironmentLog *envlog,
                                 NSIndexPath *indexPath,
                                 PESyncNotFoundBlk notFoundBlk,
                                 PESyncImmediateSuccessBlk successBlk,
                                 PESyncImmediateRetryAfterBlk retryAfterBlk,
                                 PESyncImmediateServerTempErrorBlk tempErrBlk,
                                 PESyncImmediateServerErrorBlk errBlk,
                                 PESyncConflictBlk conflictBlk,
                                 PESyncImmediateAuthRequiredBlk authReqdBlk,
                                 PESyncImmediateDependencyUnsynced depUnsyncedBlk) {
    NSString *mainMsgFragment = @"deleting environment log";
    NSString *recordTitle = @"Environment log";
    [_coordDao deleteEnvironmentLog:envlog
                            forUser:user
                notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                     addlSuccessBlk:^{successBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
             addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs];}
             addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                 addlRemoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [FPUtils computeEnvLogErrMsgs:errMask]); [APP refreshTabs];}
                    addlConflictBlk:^(id e) {conflictBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs];}
                              error:[FPUtils localSaveErrorHandlerMaker]()];
  };
  return itemDeleter;
}

- (PEItemLocalDeleter)envlogItemLocalDeleter {
  return ^ (UIViewController *listViewController, FPEnvironmentLog *envlog, NSIndexPath *indexPath) {
    [[_coordDao localDao] deleteEnvironmentLog:envlog error:[FPUtils localSaveErrorHandlerMaker]()];
    [APP refreshTabs];
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
                                                                    isLoggedIn:[APP isUserLoggedIn]];
    return [[PEListViewController alloc]
             initWithClassOfDataSourceObjects:[FPEnvironmentLog class]
                                        title:@"Environment Logs"
                        isPaginatedDataSource:YES
                              tableCellStyler:tableCellStyler
                           itemSelectedAction:nil
                          initialSelectedItem:nil
                                addItemAction:addEnvLogAction
                               cellIdentifier:@"FPEnvironmentLogCell"
                               initialObjects:initialEnvLogs
                                   pageLoader:pageLoader
                               heightForCells:52.0
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
                                                                    isLoggedIn:[APP isUserLoggedIn]];
    return [[PEListViewController alloc]
             initWithClassOfDataSourceObjects:[FPEnvironmentLog class]
                                        title:@"Unsynced Env Logs"
                        isPaginatedDataSource:NO
                              tableCellStyler:tableCellStyler
                           itemSelectedAction:nil
                          initialSelectedItem:nil
                                addItemAction:nil
                               cellIdentifier:@"FPEnvironmentLogCell"
                               initialObjects:pageLoader(nil)
                                   pageLoader:pageLoader
                               heightForCells:52.0
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

#pragma mark - Quick Action Screen

- (FPAuthScreenMakerWithTempNotification)newQuickActionMenuScreenMaker {
  return ^ UIViewController *(FPUser *user) {
    return [[FPQuickActionMenuController alloc] initWithStoreCoordinator:_coordDao
                                                                    user:user
                                                               uitoolkit:_uitoolkit
                                                           screenToolkit:self];
  };
}

#pragma mark - Tab-bar Authenticated Landing Screen

- (FPAuthScreenMaker)newTabBarHomeLandingScreenMakerIsLoggedIn:(BOOL)isLoggedIn {
  return ^ UIViewController *(FPUser *user) {
    UIViewController *quickActionMenuCtrl = [self newQuickActionMenuScreenMaker](user);
    UIViewController *settingsMenuCtrl = [self newViewSettingsScreenMaker](user);
    UITabBarController *tabBarCtrl =
    [[UITabBarController alloc] initWithNibName:nil bundle:nil];
    NSMutableArray *controllers = [NSMutableArray array];
    [controllers addObject:[PEUIUtils navControllerWithRootController:quickActionMenuCtrl
                                                  navigationBarHidden:NO
                                                      tabBarItemTitle:@"Quick Action Menu"
                                                      tabBarItemImage:[UIImage imageNamed:@"tab-home"]
                                              tabBarItemSelectedImage:[[UIImage imageNamed:@"tab-home"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]]];
    [controllers addObject:[PEUIUtils navControllerWithRootController:settingsMenuCtrl
                                                  navigationBarHidden:NO
                                                      tabBarItemTitle:@"Settings"
                                                      tabBarItemImage:[UIImage imageNamed:@"tab-settings"]
                                              tabBarItemSelectedImage:[[UIImage imageNamed:@"tab-settings"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]]];
    if (isLoggedIn) {
      [controllers addObject:[self unsynedEditsViewControllerForUser:user]];
    }
    [tabBarCtrl setViewControllers:controllers animated:YES];
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
