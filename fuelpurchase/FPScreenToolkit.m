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
#import "FPUnauthStartController.h"
#import <PEObjc-Commons/PEUtils.h>
#import <PEObjc-Commons/PEUIUtils.h>
#import <PEObjc-Commons/NSString+PEAdditions.h>
#import <PEObjc-Commons/PEDatePickerController.h>
#import "PEListViewController.h"
#import "PEAddViewEditController.h"
#import "FPUtils.h"
#import <PEFuelPurchase-Model/FPNotificationNames.h>
#import <PEFuelPurchase-Model/PELMNotificationUtils.h>
#import "FPPanelToolkit.h"
#import "FPFpLogVehicleFuelStationDateDataSourceAndDelegate.h"
#import "FPEnvLogVehicleAndDateDataSourceDelegate.h"
#import "FPEditActors.h"
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

- (void(^)(void))entityBeingSyncedBlk {
  return ^{
    [PEUIUtils showAlertWithMsgs:@[[NSString stringWithFormat:@"Sorry, but the \
remote-synchronizer is currently attempting to sync this record.  Try again in a few moments."]]
                           title:@"Oops."
                     buttonTitle:@"okayMsg"];
  };
}

- (void(^)(void))entityDeletedBlk {
  return ^{
    [PEUIUtils showAlertWithMsgs:@[[NSString stringWithFormat:@"Sorry, but the \
remote-synchronizer indicates this record is marked for deletion."]]
                           title:@"Oops."
                     buttonTitle:@"okayMsg"];
  };
}

- (void(^)(void))entityInConflictBlk {
  return ^{
    [PEUIUtils showAlertWithMsgs:@[[NSString stringWithFormat:@"Sorry, but the \
remote-synchronizer indicates this record is marked as in-conflict."]]
                           title:@"Oops."
                     buttonTitle:@"okayMsg"];
  };
}

- (void(^)(NSNumber *))entityBeingEditedByOtherActorBlk {
  return ^(NSNumber *otherActorId) {
    [PEUIUtils showAlertWithMsgs:@[[NSString stringWithFormat:@"Sorry, but \
the background-processor is currently attempting to edit this record.  Try again in a few moments."]]
                           title:@"Oops."
                     buttonTitle:@"okayMsg"];
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

- (FPAuthScreenMaker)newViewDraftsScreenMaker {
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
      return [_coordDao prepareUserForEdit:user
                               editActorId:@(FPForegroundActorId)
                         entityBeingSynced:[self entityBeingSyncedBlk]
                             entityDeleted:[self entityDeletedBlk]
                          entityInConflict:[self entityInConflictBlk]
             entityBeingEditedByOtherActor:[self entityBeingEditedByOtherActorBlk]
                                     error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEEntityEditCancelerBlk userEditCanceler = ^(PEAddViewEditController *ctrl, FPUser *user) {
      [_coordDao cancelEditOfUser:user
                      editActorId:@(FPForegroundActorId)
                            error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PESaveEntityBlk userSaver = ^(PEAddViewEditController *ctrl, FPUser *user) {
      [_coordDao saveUser:user
              editActorId:@(FPForegroundActorId)
                    error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEMarkAsDoneEditingBlk doneEditingUserMarker = ^(FPUser *user,
                                                     PESyncImmediateSuccessBlk successBlk,
                                                     PESyncImmediateFailedBlk failedBlk,
                                                     PESyncImmediateRetryAfterBlk retryAFterBlk) {
      [_coordDao markAsDoneEditingAndSyncUserImmediate:user editActorId:@(FPForegroundActorId) successBlk:^{
        successBlk();
      } remoteErrorBlk:^(NSError *err) {
        failedBlk(err);
      } remoteStoreBusyBlk:^(NSDate *retryAfter) {
        retryAFterBlk(retryAfter);
      } error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEEntitySyncCancelerBlk syncCanceler = ^(PELMMainSupport *entity, NSError *err, NSNumber *httpStatusCode) {
      [[_coordDao localDao] cancelSyncForUser:(FPUser *)entity
                                 httpRespCode:httpStatusCode
                                    errorMask:nil
                                      retryAt:nil
                                  editActorId:@(FPForegroundActorId)
                                        error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEPrepareUIForUserInteractionBlk prepareUIForUserInteractionBlk = ^(UIView *entityPanel) {
      UITextField *userNameTf = (UITextField *)[entityPanel viewWithTag:FPUserTagName];
      [userNameTf becomeFirstResponder];
    };
    return [PEAddViewEditController
              viewEntityCtrlrWithEntity:user
                        entityIndexPath:nil
                              uitoolkit:_uitoolkit
                         itemChangedBlk:nil
                 syncInitiatedNotifName:FPUserSyncInitiated
                        syncedNotifName:FPUserSynced
                    syncFailedNotifName:FPUserSyncFailed
         entityRemotelyDeletedNotifName:FPUserRemotelyDeleted
         entityLocallyUpdatedNotifNames:@[FPUserUpdated]
         entityRemotelyUpdatedNotifName:FPUserRemotelyUpdated
                       entityPanelMaker:[_panelToolkit userAccountPanelMaker]
                    entityToPanelBinder:[_panelToolkit userAccountToUserAccountPanelBinder]
                    panelToEntityBinder:[_panelToolkit userAccountPanelToUserAccountBinder]
                        viewEntityTitle:@"User Account"
                        editEntityTitle:@"Edit User Account"
                   panelEnablerDisabler:[_panelToolkit userAccountPanelEnablerDisabler]
                      entityAddCanceler:^(PEAddViewEditController *ctrl){[[ctrl navigationController] dismissViewControllerAnimated:YES completion:nil];}
                     entityEditPreparer:userEditPreparer
                     entityEditCanceler:userEditCanceler
                            entitySaver:userSaver
                doneEditingEntityMarker:doneEditingUserMarker
           syncImmediateWhenDoneEditing:YES
              syncImmediateInitiatedMsg:@"Saving User"
               syncImmediateCompleteMsg:@"Complete"
                 syncImmediateFailedMsg:@"Saved Failed"
             syncImmediateRetryAfterMsg:@"Server temporarily unavailable."
                     entitySyncCanceler:syncCanceler
    isEntityConfiguredForBackgroundSync:NO
         prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                       viewDidAppearBlk:nil
                        entityValidator:[self newUserAccountValidator]
                  foregroundEditActorId:@(FPForegroundActorId)
        entityUpdatedNotificationToPost:FPUserUpdated];
  };
}

#pragma mark - Vehicle Screens

+ (NSInteger)indexOfVehicle:(FPVehicle *)vehicle inVehicles:(NSArray *)vehicles {
  NSInteger index = 0;
  NSInteger count = 0;
  for (FPVehicle *v in vehicles) {
    if ([v isEqualToVehicle:vehicle]) {
      index = count;
      break;
    }
    count++;
  }
  return index;
}

- (FPAuthScreenMaker)newViewVehiclesScreenMaker {
  return ^ UIViewController *(FPUser *user) {
    void (^addVehicleAction)(PEListViewController *, PEItemAddedBlk) =
      ^(PEListViewController *listViewCtrl, PEItemAddedBlk itemAddedBlk) {
      // the reason we present the add screen as a nav-ctrl is so we that can experience
      // the animation effect of the view appearing from the bottom-up (and it being modal)
      UIViewController *addVehicleScreen =
        [self newAddVehicleScreenMakerWithDelegate:itemAddedBlk](user);
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
                                           itemChangedBlk:itemChangedBlk](user);
    };
    PEPageLoaderBlk pageLoader = ^ NSArray * (FPVehicle *lastVehicle) {
      return [_coordDao vehiclesForUser:user
                                  error:[FPUtils localFetchErrorHandlerMaker]()];
    };
    NSArray *initialVehicles = [_coordDao vehiclesForUser:user
                                                    error:[FPUtils localFetchErrorHandlerMaker]()];
    PEWouldBeIndexOfEntity wouldBeIndexBlk = ^ NSInteger (PELMMainSupport *entity) {
      return [FPScreenToolkit indexOfVehicle:(FPVehicle *)entity inVehicles:pageLoader(nil)];
    };
    return [[PEListViewController alloc]
              initWithClassOfDataSourceObjects:[FPVehicle class]
                                         title:@"Vehicles"
                         isPaginatedDataSource:NO
                               tableCellStyler:[PELMUIUtils syncViewStylerWithTitleBlk:^(FPVehicle *vehicle) {return [vehicle name];} alwaysTopifyTitleLabel:NO uitoolkit:_uitoolkit foregroundActorId:FPForegroundActorId subtitleLeftHPadding:15.0]
                            itemSelectedAction:nil
                           initialSelectedItem:nil
                                 addItemAction:addVehicleAction
                                cellIdentifier:@"FPVehicleCell"
                                initialObjects:initialVehicles
                                    pageLoader:pageLoader
                                heightForCells:52.0
                               detailViewMaker:vehicleDetailViewMaker
                                     uitoolkit:_uitoolkit
                         entityAddedNotifNames:@[FPVehicleAdded,
                                                 FPVehicleRemotelyAdded]
                       entityUpdatedNotifNames:@[FPVehicleUpdated,
                                                 FPVehicleRemotelyUpdated,
                                                 FPVehicleSynced,
                                                 //FPVehicleSyncInitiated,
                                                 FPVehicleSyncFailed]
                       entityRemovedNotifNames:@[FPVehicleDeleted,
                                                 FPVehicleRemotelyDeleted]
                doesEntityBelongToThisListView:^BOOL(PELMMainSupport *entity){return YES;}
                          wouldBeIndexOfEntity:wouldBeIndexBlk];
  };
}

- (FPAuthScreenMaker)newVehiclesForSelectionScreenMakerWithItemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                                                       initialSelectedVehicle:(FPVehicle *)initialSelectedVehicle {
  return ^ UIViewController *(FPUser *user) {
    void (^addVehicleAction)(PEListViewController *, PEItemAddedBlk) =
    ^(PEListViewController *listViewCtrlr, PEItemAddedBlk itemAddedBlk) {
      UIViewController *addVehicleScreen =
        [self newAddVehicleScreenMakerWithDelegate:itemAddedBlk](user);
      [listViewCtrlr presentViewController:[PEUIUtils navigationControllerWithController:addVehicleScreen
                                                                     navigationBarHidden:NO]
                                  animated:YES
                                completion:nil];
    };
    PEPageLoaderBlk pageLoader = ^ NSArray * (FPVehicle *lastVehicle) {
      return [_coordDao vehiclesForUser:user
                                  error:[FPUtils localFetchErrorHandlerMaker]()];
    };
    NSArray *initialVehicles = [_coordDao vehiclesForUser:user
                                                    error:[FPUtils localFetchErrorHandlerMaker]()];
    PEWouldBeIndexOfEntity wouldBeIndexBlk = ^ NSInteger (PELMMainSupport *entity) {
      return [FPScreenToolkit indexOfVehicle:(FPVehicle *)entity inVehicles:pageLoader(nil)];
    };
    return [[PEListViewController alloc]
             initWithClassOfDataSourceObjects:[FPVehicle class]
                                        title:@"Choose Vehicle"
                        isPaginatedDataSource:NO
                              tableCellStyler:[PELMUIUtils syncViewStylerWithTitleBlk:^(FPVehicle *vehicle) {return [vehicle name];} alwaysTopifyTitleLabel:NO uitoolkit:_uitoolkit foregroundActorId:FPForegroundActorId subtitleLeftHPadding:15.0]
                           itemSelectedAction:itemSelectedAction
                          initialSelectedItem:initialSelectedVehicle
                                addItemAction:addVehicleAction
                               cellIdentifier:@"FPVehicleCell"
                               initialObjects:initialVehicles
                                   pageLoader:pageLoader
                               heightForCells:52.0
                              detailViewMaker:nil
                                    uitoolkit:_uitoolkit
                        entityAddedNotifNames:@[FPVehicleAdded,
                                                FPVehicleRemotelyAdded]
                      entityUpdatedNotifNames:@[FPVehicleUpdated,
                                                FPVehicleRemotelyUpdated,
                                                FPVehicleSynced,
                                                FPVehicleSyncInitiated,
                                                FPVehicleSyncFailed]
                      entityRemovedNotifNames:@[FPVehicleDeleted,
                                                FPVehicleRemotelyDeleted]
               doesEntityBelongToThisListView:^BOOL(PELMMainSupport *entity){return YES;}
                         wouldBeIndexOfEntity:wouldBeIndexBlk];
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

- (FPAuthScreenMaker)newAddVehicleScreenMakerWithDelegate:(PEItemAddedBlk)itemAddedBlk {
  return ^ UIViewController * (FPUser *user) {
    PESaveNewEntityBlk newVehicleSaver = ^(UIView *entityPanel, id newEntity) {
      FPVehicle *newVehicle = (FPVehicle *)newEntity;
      [_coordDao saveNewVehicle:newVehicle
                        forUser:user
                          error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEPrepareUIForUserInteractionBlk prepareUIForUserInteractionBlk = ^(UIView *entityPanel) {
      UITextField *vehicleNameTf = (UITextField *)[entityPanel viewWithTag:FPVehicleTagName];
      [vehicleNameTf becomeFirstResponder];
    };
    return [PEAddViewEditController
             addEntityCtrlrWithUitoolkit:_uitoolkit
                            itemAddedBlk:itemAddedBlk
                        entityPanelMaker:[_panelToolkit vehiclePanelMaker]
                     entityToPanelBinder:[_panelToolkit vehicleToVehiclePanelBinder]
                     panelToEntityBinder:[_panelToolkit vehiclePanelToVehicleBinder]
                          addEntityTitle:@"Add Vehicle"
                       entityAddCanceler:^(PEAddViewEditController *ctrl){[[ctrl navigationController] dismissViewControllerAnimated:YES completion:nil];}
                             entityMaker:[_panelToolkit vehicleMaker]
                          newEntitySaver:newVehicleSaver
          prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                        viewDidAppearBlk:nil
                         entityValidator:[self newVehicleValidator]
                   foregroundEditActorId:@(FPForegroundActorId)
            entityAddedNotificationToPost:FPVehicleAdded];
  };
}

- (FPAuthScreenMaker)newVehicleDetailScreenMakerWithVehicle:(FPVehicle *)vehicle
                                           vehicleIndexPath:(NSIndexPath *)vehicleIndexPath
                                             itemChangedBlk:(PEItemChangedBlk)itemChangedBlk {
  return ^ UIViewController * (FPUser *user) {
    PEEntityEditPreparerBlk vehicleEditPreparer = ^BOOL(PEAddViewEditController *ctrl, FPVehicle *vehicle) {
      return [_coordDao prepareVehicleForEdit:vehicle
                                      forUser:user
                                  editActorId:@(FPForegroundActorId)
                            entityBeingSynced:[self entityBeingSyncedBlk]
                                entityDeleted:[self entityDeletedBlk]
                             entityInConflict:[self entityInConflictBlk]
                entityBeingEditedByOtherActor:[self entityBeingEditedByOtherActorBlk]
                                        error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEEntityEditCancelerBlk vehicleEditCanceler = ^(PEAddViewEditController *ctrl, FPVehicle *vehicle) {
      [_coordDao cancelEditOfVehicle:vehicle
                         editActorId:@(FPForegroundActorId)
                               error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PESaveEntityBlk vehicleSaver = ^(PEAddViewEditController *ctrl, FPVehicle *vehicle) {
      [_coordDao saveVehicle:vehicle
                 editActorId:@(FPForegroundActorId)
                       error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEMarkAsDoneEditingBlk doneEditingVehicleMarker = ^(FPVehicle *vehicle,
                                                        PESyncImmediateSuccessBlk successBlk,
                                                        PESyncImmediateFailedBlk failedBlk,
                                                        PESyncImmediateRetryAfterBlk retryAFterBlk) {
      [_coordDao markAsDoneEditingVehicle:vehicle
                              editActorId:@(FPForegroundActorId)
                                    error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEPrepareUIForUserInteractionBlk prepareUIForUserInteractionBlk = ^(UIView *entityPanel) {
      UITextField *vehicleNameTf = (UITextField *)[entityPanel viewWithTag:FPVehicleTagName];
      [vehicleNameTf becomeFirstResponder];
    };
    return [PEAddViewEditController
             viewEntityCtrlrWithEntity:vehicle
                       entityIndexPath:vehicleIndexPath
                             uitoolkit:_uitoolkit
                         itemChangedBlk:itemChangedBlk
                syncInitiatedNotifName:FPVehicleSyncInitiated
                       syncedNotifName:FPVehicleSynced
                   syncFailedNotifName:FPVehicleSyncFailed
        entityRemotelyDeletedNotifName:FPVehicleRemotelyDeleted
        entityLocallyUpdatedNotifNames:@[FPVehicleUpdated]
        entityRemotelyUpdatedNotifName:FPVehicleRemotelyUpdated
                      entityPanelMaker:[_panelToolkit vehiclePanelMaker]
                   entityToPanelBinder:[_panelToolkit vehicleToVehiclePanelBinder]
                   panelToEntityBinder:[_panelToolkit vehiclePanelToVehicleBinder]
                       viewEntityTitle:@"Vehicle"
                       editEntityTitle:@"Edit Vehicle"
                  panelEnablerDisabler:[_panelToolkit vehiclePanelEnablerDisabler]
                     entityAddCanceler:^(PEAddViewEditController *ctrl){[[ctrl navigationController] dismissViewControllerAnimated:YES completion:nil];}
                    entityEditPreparer:vehicleEditPreparer
                    entityEditCanceler:vehicleEditCanceler
                           entitySaver:vehicleSaver
               doneEditingEntityMarker:doneEditingVehicleMarker
          syncImmediateWhenDoneEditing:NO
             syncImmediateInitiatedMsg:nil
              syncImmediateCompleteMsg:nil
                syncImmediateFailedMsg:nil
            syncImmediateRetryAfterMsg:nil
                    entitySyncCanceler:nil
   isEntityConfiguredForBackgroundSync:YES
        prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                      viewDidAppearBlk:nil
                       entityValidator:[self newVehicleValidator]
                 foregroundEditActorId:@(FPForegroundActorId)
       entityUpdatedNotificationToPost:FPVehicleUpdated];
  };
}

#pragma mark - Fuel Station Screens

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
  //[PEUIUtils applyBorderToView:contentView withColor:[UIColor yellowColor]];
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
  //[PEUIUtils applyBorderToView:distance withColor:[UIColor blueColor]];
  [distance setTag:distanceTag];
  [unknownReason setTag:unknownReasonTag];
}

+ (NSInteger)indexOfFuelStation:(FPFuelStation *)fuelstation inFuelStations:(NSArray *)fuelstations {
  NSInteger index = 0;
  NSInteger count = 0;
  for (FPFuelStation *fs in fuelstations) {
    if ([fs isEqualToFuelStation:fuelstation]) {
      index = count;
      break;
    }
    count++;
  }
  return index;
}

- (FPAuthScreenMaker)newViewFuelStationsScreenMaker {
  return ^ UIViewController *(FPUser *user) {
    void (^addFuelStationAction)(PEListViewController *, PEItemAddedBlk) =
    ^(PEListViewController *listViewCtrlr, PEItemAddedBlk itemAddedBlk) {
      UIViewController *addFuelStationScreen =
        [self newAddFuelStationScreenMakerWithBlk:itemAddedBlk](user);
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
                                                   itemChangedBlk:itemChangedBlk](user);
    };
    PEPageLoaderBlk pageLoader = ^ NSArray * (id lastObject) {
      NSArray *fuelstations = [_coordDao fuelStationsForUser:user
                                                       error:[FPUtils localFetchErrorHandlerMaker]()];
      fuelstations = [FPUtils sortFuelstations:fuelstations inAscOrderByDistanceFrom:[APP latestLocation]];
      return fuelstations;
    };
    NSArray *initialFuelStations =
      [_coordDao fuelStationsForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];
    initialFuelStations = [FPUtils sortFuelstations:initialFuelStations inAscOrderByDistanceFrom:[APP latestLocation]];
    PEWouldBeIndexOfEntity wouldBeIndexBlk = ^ NSInteger (PELMMainSupport *entity) {
      return [FPScreenToolkit indexOfFuelStation:(FPFuelStation *)entity inFuelStations:pageLoader(nil)];
    };
    PESyncViewStyler tableCellStyler = ^(UIView *contentView, FPFuelStation *fuelstation) {
      [PELMUIUtils syncViewStylerWithTitleBlk:^(FPFuelStation *fuelStation) {return [fuelStation name];}
                       alwaysTopifyTitleLabel:YES
                                    uitoolkit:_uitoolkit
                            foregroundActorId:FPForegroundActorId
                         subtitleLeftHPadding:15.0](contentView, fuelstation);
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
                               initialObjects:initialFuelStations
                                   pageLoader:pageLoader
                               heightForCells:52.0
                              detailViewMaker:fuelStationDetailViewMaker
                                    uitoolkit:_uitoolkit
                        entityAddedNotifNames:@[FPFuelStationAdded,
                                                FPFuelStationRemotelyAdded]
                      entityUpdatedNotifNames:@[FPFuelStationUpdated,
                                                FPFuelStationRemotelyUpdated,
                                                FPFuelStationSynced,
                                                FPFuelStationSyncInitiated,
                                                FPFuelStationSyncFailed,
                                                FPFuelStationCoordinateComputeInitiated,
                                                FPFuelStationCoordinateComputeSuccess,
                                                FPFuelStationCoordinateComputeFailed]
                      entityRemovedNotifNames:@[FPFuelStationDeleted,
                                                FPFuelStationRemotelyDeleted]
               doesEntityBelongToThisListView:^BOOL(PELMMainSupport *entity){return YES;}
                         wouldBeIndexOfEntity:wouldBeIndexBlk];
  };
}

- (FPAuthScreenMaker)newFuelStationsForSelectionScreenMakerWithItemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                                                       initialSelectedFuelStation:(FPFuelStation *)initialSelectedFuelStation {
  return ^ UIViewController *(FPUser *user) {
    void (^addFuelStationAction)(PEListViewController *, PEItemAddedBlk) =
    ^(PEListViewController *listViewCtrlr, PEItemAddedBlk itemAddedBlk) {
      UIViewController *addFuelStationScreen =
        [self newAddFuelStationScreenMakerWithBlk:itemAddedBlk](user);
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
    NSArray *initialFuelStations =
    [_coordDao fuelStationsForUser:user error:[FPUtils localFetchErrorHandlerMaker]()];
    initialFuelStations = [FPUtils sortFuelstations:initialFuelStations inAscOrderByDistanceFrom:[APP latestLocation]];
    PEWouldBeIndexOfEntity wouldBeIndexBlk = ^ NSInteger (PELMMainSupport *entity) {
      return [FPScreenToolkit indexOfFuelStation:(FPFuelStation *)entity inFuelStations:pageLoader(nil)];
    };
    PESyncViewStyler tableCellStyler = ^(UIView *contentView, FPFuelStation *fuelstation) {
      [PELMUIUtils syncViewStylerWithTitleBlk:^(FPFuelStation *fuelStation) {return [fuelStation name];}
                       alwaysTopifyTitleLabel:YES
                                    uitoolkit:_uitoolkit
                            foregroundActorId:FPForegroundActorId
                         subtitleLeftHPadding:15.0](contentView, fuelstation);
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
                               initialObjects:initialFuelStations
                                   pageLoader:pageLoader
                               heightForCells:52.0
                              detailViewMaker:nil
                                    uitoolkit:_uitoolkit
                        entityAddedNotifNames:@[FPFuelStationAdded,
                                                FPFuelStationRemotelyAdded]
                      entityUpdatedNotifNames:@[FPFuelStationUpdated,
                                                FPFuelStationRemotelyUpdated,
                                                FPFuelStationSynced,
                                                FPFuelStationSyncInitiated,
                                                FPFuelStationSyncFailed,
                                                FPFuelStationCoordinateComputeInitiated,
                                                FPFuelStationCoordinateComputeSuccess,
                                                FPFuelStationCoordinateComputeFailed]
                      entityRemovedNotifNames:@[FPFuelStationDeleted,
                                                FPFuelStationRemotelyDeleted]
               doesEntityBelongToThisListView:^BOOL(PELMMainSupport *entity){return YES;}
                         wouldBeIndexOfEntity:wouldBeIndexBlk];
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

- (FPAuthScreenMaker)newAddFuelStationScreenMakerWithBlk:(PEItemAddedBlk)itemAddedBlk {
  return ^ UIViewController * (FPUser *user) {
    PESaveNewEntityBlk newFuelStationSaver = ^(UIView *entityPanel, FPFuelStation *newFuelStation) {
      [_coordDao saveNewFuelStation:newFuelStation
                            forUser:user
                              error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEPrepareUIForUserInteractionBlk prepareUIForUserInteractionBlk = ^(UIView *entityPanel) {
      UITextField *nameTf = (UITextField *)[entityPanel viewWithTag:FPFuelStationTagName];
      [nameTf becomeFirstResponder];
    };
    return [PEAddViewEditController
             addEntityCtrlrWithUitoolkit:_uitoolkit
                            itemAddedBlk:itemAddedBlk
                        entityPanelMaker:[_panelToolkit fuelStationPanelMaker]
                     entityToPanelBinder:[_panelToolkit fuelStationToFuelStationPanelBinder]
                     panelToEntityBinder:[_panelToolkit fuelStationPanelToFuelStationBinder]
                          addEntityTitle:@"Add Fuel Station"
                       entityAddCanceler:^(PEAddViewEditController *ctrl){[[ctrl navigationController] dismissViewControllerAnimated:YES completion:nil];}
                             entityMaker:[_panelToolkit fuelStationMaker]
                          newEntitySaver:newFuelStationSaver
          prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                        viewDidAppearBlk:nil
                         entityValidator:[self newFuelStationValidator]
                   foregroundEditActorId:@(FPForegroundActorId)
            entityAddedNotificationToPost:FPFuelStationAdded];
  };
}

- (FPAuthScreenMaker)newFuelStationDetailScreenMakerWithFuelStation:(FPFuelStation *)fuelStation
                                               fuelStationIndexPath:(NSIndexPath *)fuelStationIndexPath
                                                     itemChangedBlk:(PEItemChangedBlk)itemChangedBlk {
  return ^ UIViewController * (FPUser *user) {
    PEEntityEditPreparerBlk fuelStationEditPreparer = ^BOOL(PEAddViewEditController *ctrl, PELMModelSupport *entity) {
      FPFuelStation *fuelStation = (FPFuelStation *)entity;
      return [_coordDao prepareFuelStationForEdit:fuelStation
                                          forUser:user
                                      editActorId:@(FPForegroundActorId)
                                entityBeingSynced:[self entityBeingSyncedBlk]
                                    entityDeleted:[self entityDeletedBlk]
                                 entityInConflict:[self entityInConflictBlk]
                    entityBeingEditedByOtherActor:[self entityBeingEditedByOtherActorBlk]
                                            error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEEntityEditCancelerBlk fuelStationEditCanceler = ^ (PEAddViewEditController *ctrl, PELMModelSupport *entity) {
      FPFuelStation *fuelStation = (FPFuelStation *)entity;
      [_coordDao cancelEditOfFuelStation:fuelStation
                             editActorId:@(FPForegroundActorId)
                                   error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PESaveEntityBlk fuelStationSaver = ^(PEAddViewEditController *ctrl, PELMModelSupport *entity) {
      FPFuelStation *fuelStation = (FPFuelStation *)entity;
      [_coordDao saveFuelStation:fuelStation
                     editActorId:@(FPForegroundActorId)
                           error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEMarkAsDoneEditingBlk doneEditingFuelStationMarker = ^(PELMModelSupport *entity,
                                                            PESyncImmediateSuccessBlk successBlk,
                                                            PESyncImmediateFailedBlk failedBlk,
                                                            PESyncImmediateRetryAfterBlk retryAFterBlk) {
      FPFuelStation *fuelStation = (FPFuelStation *)entity;
      [_coordDao markAsDoneEditingFuelStation:fuelStation
                                  editActorId:@(FPForegroundActorId)
                                        error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEPrepareUIForUserInteractionBlk prepareUIForUserInteractionBlk = ^(UIView *entityPanel) {
      UITextField *nameTf = (UITextField *)[entityPanel viewWithTag:FPFuelStationTagName];
      [nameTf becomeFirstResponder];
    };
    return [PEAddViewEditController
             viewEntityCtrlrWithEntity:fuelStation
                       entityIndexPath:fuelStationIndexPath
                             uitoolkit:_uitoolkit
                        itemChangedBlk:itemChangedBlk
                syncInitiatedNotifName:FPFuelStationSyncInitiated
                       syncedNotifName:FPFuelStationSynced
                   syncFailedNotifName:FPFuelStationSyncFailed
        entityRemotelyDeletedNotifName:FPFuelStationRemotelyDeleted
        entityLocallyUpdatedNotifNames:@[FPFuelStationCoordinateComputeSuccess,
                                         FPFuelStationUpdated]
        entityRemotelyUpdatedNotifName:FPVehicleRemotelyUpdated
                      entityPanelMaker:[_panelToolkit fuelStationPanelMaker]
                   entityToPanelBinder:[_panelToolkit fuelStationToFuelStationPanelBinder]
                   panelToEntityBinder:[_panelToolkit fuelStationPanelToFuelStationBinder]
                       viewEntityTitle:@"Fuel Station"
                       editEntityTitle:@"Edit Fuel Station"
                  panelEnablerDisabler:[_panelToolkit fuelStationPanelEnablerDisabler]
                     entityAddCanceler:^(PEAddViewEditController *ctrl){[[ctrl navigationController] dismissViewControllerAnimated:YES completion:nil];}
                    entityEditPreparer:fuelStationEditPreparer
                    entityEditCanceler:fuelStationEditCanceler
                           entitySaver:fuelStationSaver
               doneEditingEntityMarker:doneEditingFuelStationMarker
          syncImmediateWhenDoneEditing:NO
             syncImmediateInitiatedMsg:nil
              syncImmediateCompleteMsg:nil
                syncImmediateFailedMsg:nil
            syncImmediateRetryAfterMsg:nil
                    entitySyncCanceler:nil
   isEntityConfiguredForBackgroundSync:YES
        prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                      viewDidAppearBlk:nil
                       entityValidator:[self newFuelStationValidator]
                 foregroundEditActorId:@(FPForegroundActorId)
       entityUpdatedNotificationToPost:FPFuelStationUpdated];
  };
}

#pragma mark - Fuel Purchase Log Screens

- (PEEntityValidatorBlk)newFpEnvLogCompositeValidator {
  return ^NSArray *(UIView *fpEnvLogCompositePanel) {
    NSMutableArray *errMsgs = [NSMutableArray array];
    PEEntityValidatorBlk fpLogValidator = [self newFuelPurchaseLogValidator];
    [errMsgs addObjectsFromArray:fpLogValidator(fpEnvLogCompositePanel)];
    //PEMessageCollector cannotBeBlankCollector =
    //  [PEUIUtils newTfCannotBeEmptyBlkForMsgs:errMsgs entityPanel:fpEnvLogCompositePanel];
    //cannotBeBlankCollector(FPEnvLogTagOdometer, @"Odometer cannot be empty.");
    //fcannotBeBlankCollector(FPEnvLogTagReportedOutsideTemp, @"Reported outside temperature cannot be empty.");
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
    //PEMessageCollector cannotBeBlankCollector =
      //[PEUIUtils newTfCannotBeEmptyBlkForMsgs:errMsgs entityPanel:fpLogPanel];
    //cannotBeBlankCollector(FPFpLogTagNumGallons, @"Num gallons cannot be empty.");
    //cannotBeBlankCollector(FPFpLogTagPricePerGallon, @"Price-per-gallon cannot be empty.");
    //cannotBeBlankCollector(FPFpLogTagOctane, @"Octane cannot be empty.");
    return errMsgs;
  };
}

- (FPAuthScreenMaker)newAddFuelPurchaseLogScreenMakerWithBlk:(PEItemAddedBlk)itemAddedBlk
                                      defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle
                                  defaultSelectedFuelStation:(FPFuelStation *)defaultSelectedFuelStation {
  return ^ UIViewController * (FPUser *user) {
    PESaveNewEntityBlk newFuelPurchaseLogSaver = ^(UIView *entityPanel, FPLogEnvLogComposite *fpEnvLogComposite) {
      FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds =
        (FPFpLogVehicleFuelStationDateDataSourceAndDelegate *)
          [(UITableView *)[entityPanel viewWithTag:FPFpLogTagVehicleFuelStationAndDate] dataSource];
      FPVehicle *selectedVehicle = [ds selectedVehicle];
      FPFuelStation *selectedFuelStation = [ds selectedFuelStation];
      [_coordDao saveNewFuelPurchaseLog:[fpEnvLogComposite fpLog]
                                forUser:user
                                vehicle:selectedVehicle
                            fuelStation:selectedFuelStation
                                  error:[FPUtils localSaveErrorHandlerMaker]()];
      BOOL (^isEnvLogEmpty)(FPEnvironmentLog *) = ^BOOL(FPEnvironmentLog *envLog) {
        return ![envLog odometer] &&
               ![envLog reportedAvgMpg] &&
               ![envLog reportedAvgMph] &&
               ![envLog reportedOutsideTemp] &&
               ![envLog reportedDte];
      };
      // 3 possible outcomes: (1) we save 2 envlog records because the user gave
      // both pre and post DTE values.  (2) we save a single envlog record because
      // the user only gave a single DTE value, or none at all.  The below logic
      // captures this. (3) we don't save any envlog records because the user
      // hasn't provided any env log data
      if ([[fpEnvLogComposite preFillupEnvLog] reportedDte]) {
        if (!isEnvLogEmpty([fpEnvLogComposite preFillupEnvLog])) {
          [_coordDao saveNewEnvironmentLog:[fpEnvLogComposite preFillupEnvLog]
                                   forUser:user
                                   vehicle:selectedVehicle
                                     error:[FPUtils localSaveErrorHandlerMaker]()];
        }
        if ([[fpEnvLogComposite postFillupEnvLog] reportedDte]) {
          if (!isEnvLogEmpty([fpEnvLogComposite postFillupEnvLog])) {
            [_coordDao saveNewEnvironmentLog:[fpEnvLogComposite postFillupEnvLog]
                                     forUser:user
                                     vehicle:selectedVehicle
                                       error:[FPUtils localSaveErrorHandlerMaker]()];
          }
        }
      } else {
        // although we're specifying the 'postFillup' envlog instance, it could
        // very well be that its 'reportedDte' value is nil; that doesn't matter
        // because even if it's nil, we want to record an envlog record.
        if (!isEnvLogEmpty([fpEnvLogComposite postFillupEnvLog])) {
          [_coordDao saveNewEnvironmentLog:[fpEnvLogComposite postFillupEnvLog]
                                   forUser:user
                                   vehicle:selectedVehicle
                                     error:[FPUtils localSaveErrorHandlerMaker]()];
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
    return [PEAddViewEditController
             addEntityCtrlrWithUitoolkit:_uitoolkit
                            itemAddedBlk:itemAddedBlk
                        entityPanelMaker:[_panelToolkit fpEnvLogCompositePanelMakerWithUser:user
                                                                   defaultSelectedVehicle:defaultSelectedVehicle
                                                               defaultSelectedFuelStation:defaultSelectedFuelStation
                                                                     defaultPickedLogDate:[NSDate date]]
                     entityToPanelBinder:[_panelToolkit fpEnvLogCompositeToFpEnvLogCompositePanelBinder]
                     panelToEntityBinder:[_panelToolkit fpEnvLogCompositePanelToFpEnvLogCompositeBinder]
                          addEntityTitle:@"Add Fuel Purchase Log"
                       entityAddCanceler:^(PEAddViewEditController *ctrl){[[ctrl navigationController] dismissViewControllerAnimated:YES completion:nil];}
                             entityMaker:[_panelToolkit fpEnvLogCompositeMaker]
                          newEntitySaver:newFuelPurchaseLogSaver
          prepareUIForUserInteractionBlk:nil
                        viewDidAppearBlk:viewDidAppearBlk
                         entityValidator:[self newFpEnvLogCompositeValidator]
                   foregroundEditActorId:@(FPForegroundActorId)
            entityAddedNotificationToPost:FPFuelPurchaseLogAdded
                   getterForNotification:@selector(fpLog)];
  };
}

- (FPAuthScreenMaker)newFuelPurchaseLogDetailScreenMakerWithFpLog:(FPFuelPurchaseLog *)fpLog
                                                   fpLogIndexPath:(NSIndexPath *)fpLogIndexPath
                                                   itemChangedBlk:(PEItemChangedBlk)itemChangedBlk
                                    listViewParentIsVehicleDetail:(BOOL)listViewParentIsVehicleDetail
                                listViewParentIsFuelStationDetail:(BOOL)listViewParentIsFuelStationDetail {
  return ^ UIViewController * (FPUser *user) {
    void (^refreshVehicleFuelStationTableView)(PEAddViewEditController *, FPFuelPurchaseLog *) = ^(PEAddViewEditController *ctrl, FPFuelPurchaseLog *fpLog) {
      UITableView *vehicleFuelStationDateTableView =
      (UITableView *)[[ctrl view] viewWithTag:FPFpLogTagVehicleFuelStationAndDate];
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
                                                 editActorId:@(FPForegroundActorId)
                                           entityBeingSynced:[self entityBeingSyncedBlk]
                                               entityDeleted:[self entityDeletedBlk]
                                            entityInConflict:[self entityInConflictBlk]
                               entityBeingEditedByOtherActor:[self entityBeingEditedByOtherActorBlk]
                                                       error:[FPUtils localSaveErrorHandlerMaker]()];
      if (result) {
        // this is needed because the 'prepare' call right above will mutate the currently-selected vehicle
        // and fuelstation such that they will have been copied to their main tables, and given non-nil
        // local main IDs.  Because of this, we need to fresh the in-memory vehicle and fuel station entries
        // in the table view.
        refreshVehicleFuelStationTableView(ctrl, fpLog);
      }
      return result;
    };
    PEEntityEditCancelerBlk fpLogEditCanceler = ^(PEAddViewEditController *ctrl, FPFuelPurchaseLog *fpLog) {
      [_coordDao cancelEditOfFuelPurchaseLog:fpLog
                                 editActorId:@(FPForegroundActorId)
                                       error:[FPUtils localSaveErrorHandlerMaker]()];
      refreshVehicleFuelStationTableView(ctrl, fpLog);
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
                         editActorId:@(FPForegroundActorId)
                               error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEMarkAsDoneEditingBlk doneEditingFuelPurchaseLogMarker = ^(FPFuelPurchaseLog *fpLog,
                                                                PESyncImmediateSuccessBlk successBlk,
                                                                PESyncImmediateFailedBlk failedBlk,
                                                                PESyncImmediateRetryAfterBlk retryAFterBlk) {
      [_coordDao markAsDoneEditingFuelPurchaseLog:fpLog
                                      editActorId:@(FPForegroundActorId)
                                            error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    return [PEAddViewEditController
             viewEntityCtrlrWithEntity:fpLog
                       entityIndexPath:fpLogIndexPath
                             uitoolkit:_uitoolkit
                        itemChangedBlk:itemChangedBlk
                syncInitiatedNotifName:FPFuelPurchaseLogSyncInitiated
                       syncedNotifName:FPFuelPurchaseLogSynced
                   syncFailedNotifName:FPFuelPurchaseLogSyncFailed
        entityRemotelyDeletedNotifName:FPFuelPurchaseLogRemotelyDeleted
        entityLocallyUpdatedNotifNames:@[FPFuelPurchaseLogUpdated]
        entityRemotelyUpdatedNotifName:FPFuelPurchaseLogRemotelyUpdated
                      entityPanelMaker:
                        [_panelToolkit
                           fuelPurchaseLogPanelMakerWithUser:user
                                      defaultSelectedVehicle:[_coordDao vehicleForFuelPurchaseLog:fpLog error:[FPUtils localFetchErrorHandlerMaker]()]
                                  defaultSelectedFuelStation:[_coordDao fuelStationForFuelPurchaseLog:fpLog error:[FPUtils localFetchErrorHandlerMaker]()]
                                        defaultPickedLogDate:[fpLog purchasedAt]]
                   entityToPanelBinder:[_panelToolkit fuelPurchaseLogToFuelPurchaseLogPanelBinder]
                   panelToEntityBinder:[_panelToolkit fuelPurchaseLogPanelToFuelPurchaseLogBinder]
                       viewEntityTitle:@"Fuel Purchase Log"
                       editEntityTitle:@"Edit Fuel Purchase Log"
                  panelEnablerDisabler:[_panelToolkit fuelPurchaseLogPanelEnablerDisabler]
                     entityAddCanceler:^(PEAddViewEditController *ctrl){[[ctrl navigationController] dismissViewControllerAnimated:YES completion:nil];}
                    entityEditPreparer:fpLogEditPreparer
                    entityEditCanceler:fpLogEditCanceler
                           entitySaver:fpLogSaver
               doneEditingEntityMarker:doneEditingFuelPurchaseLogMarker
          syncImmediateWhenDoneEditing:NO
             syncImmediateInitiatedMsg:nil
              syncImmediateCompleteMsg:nil
                syncImmediateFailedMsg:nil
            syncImmediateRetryAfterMsg:nil
                    entitySyncCanceler:nil
   isEntityConfiguredForBackgroundSync:YES
        prepareUIForUserInteractionBlk:nil
                      viewDidAppearBlk:nil
                       entityValidator:[self newFuelPurchaseLogValidator]
                 foregroundEditActorId:@(FPForegroundActorId)
       entityUpdatedNotificationToPost:FPFuelPurchaseLogUpdated];
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
                                                                                 error:[FPUtils localFetchErrorHandlerMaker]()]](user);
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
                              listViewParentIsFuelStationDetail:NO](user);
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
    return [[PEListViewController alloc]
             initWithClassOfDataSourceObjects:[FPFuelPurchaseLog class]
                                        title:@"Fuel Purchase Logs"
                        isPaginatedDataSource:YES
                              tableCellStyler:[PELMUIUtils syncViewStylerWithTitleBlk:^(FPFuelPurchaseLog *fpLog) {return [PEUtils stringFromDate:[fpLog purchasedAt] withPattern:@"MM/dd/YYYY"];} alwaysTopifyTitleLabel:NO uitoolkit:_uitoolkit foregroundActorId:FPForegroundActorId subtitleLeftHPadding:15.0]
                           itemSelectedAction:nil
                          initialSelectedItem:nil
                                addItemAction:addFpLogAction
                               cellIdentifier:@"FPFuelPurchaseLogCell"
                               initialObjects:initialFpLogs
                                   pageLoader:pageLoader
                               heightForCells:52.0
                              detailViewMaker:fpLogDetailViewMaker
                                    uitoolkit:_uitoolkit
                        entityAddedNotifNames:@[FPFuelPurchaseLogAdded,
                                                FPFuelPurchaseLogRemotelyAdded]
                      entityUpdatedNotifNames:@[FPFuelPurchaseLogUpdated,
                                                FPFuelPurchaseLogRemotelyUpdated,
                                                FPFuelPurchaseLogSynced,
                                                FPFuelPurchaseLogSyncInitiated,
                                                FPFuelPurchaseLogSyncFailed]
                      entityRemovedNotifNames:@[FPFuelPurchaseLogDeleted,
                                                FPFuelPurchaseLogRemotelyDeleted]
               doesEntityBelongToThisListView:doesEntityBelongToThisListViewBlk
                         wouldBeIndexOfEntity:wouldBeIndexBlk];
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
                         defaultSelectedFuelStation:fuelStation](user);
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
                              listViewParentIsFuelStationDetail:YES](user);
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
    return [[PEListViewController alloc]
             initWithClassOfDataSourceObjects:[FPFuelPurchaseLog class]
                                        title:@"Fuel Purchase Logs"
                        isPaginatedDataSource:YES
                              tableCellStyler:[PELMUIUtils syncViewStylerWithTitleBlk:^(FPFuelPurchaseLog *fpLog) {return [PEUtils stringFromDate:[fpLog purchasedAt] withPattern:@"MM/dd/YYYY"];} alwaysTopifyTitleLabel:NO uitoolkit:_uitoolkit foregroundActorId:FPForegroundActorId subtitleLeftHPadding:15.0]
                           itemSelectedAction:nil
                          initialSelectedItem:nil
                                addItemAction:addFpLogAction
                               cellIdentifier:@"FPFuelPurchaseLogCell"
                               initialObjects:initialFpLogs
                                   pageLoader:pageLoader
                               heightForCells:52.0
                              detailViewMaker:fpLogDetailViewMaker
                                    uitoolkit:_uitoolkit
                        entityAddedNotifNames:@[FPFuelPurchaseLogAdded,
                                                FPFuelPurchaseLogRemotelyAdded]
                      entityUpdatedNotifNames:@[FPFuelPurchaseLogUpdated,
                                                FPFuelPurchaseLogRemotelyUpdated,
                                                FPFuelPurchaseLogSynced,
                                                FPFuelPurchaseLogSyncInitiated,
                                                FPFuelPurchaseLogSyncFailed]
                      entityRemovedNotifNames:@[FPFuelPurchaseLogDeleted,
                                                FPFuelPurchaseLogRemotelyDeleted]
               doesEntityBelongToThisListView:doesEntityBelongToThisListViewBlk
                         wouldBeIndexOfEntity:wouldBeIndexBlk];
  };
}

#pragma mark - Environment Log Screens

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
    cannotBeBlankCollector(FPEnvLogTagReportedOutsideTemp, @"Reported outside temperature cannot be empty.");
    return errMsgs;
  };
}

- (FPAuthScreenMaker)newAddEnvironmentLogScreenMakerWithBlk:(PEItemAddedBlk)itemAddedBlk
                                     defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle {
  return ^ UIViewController * (FPUser *user) {
    PESaveNewEntityBlk newEnvironmentLogSaver = ^(UIView *entityPanel, FPEnvironmentLog *envLog) {
      FPEnvLogVehicleAndDateDataSourceDelegate *ds =
        (FPEnvLogVehicleAndDateDataSourceDelegate *)
        [(UITableView *)[entityPanel viewWithTag:FPEnvLogTagVehicleAndDate] dataSource];
      FPVehicle *selectedVehicle = [ds selectedVehicle];
      [_coordDao saveNewEnvironmentLog:envLog
                               forUser:user
                               vehicle:selectedVehicle
                                 error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEViewDidAppearBlk viewDidAppearBlk = ^(UIView *entityPanel) {
      UITableView *vehicleTable =
      (UITableView *)[entityPanel viewWithTag:FPEnvLogTagVehicleAndDate];
      if ([vehicleTable indexPathForSelectedRow]) {
        [vehicleTable deselectRowAtIndexPath:[vehicleTable indexPathForSelectedRow]
                                    animated:YES];
      }
    };
    return [PEAddViewEditController
              addEntityCtrlrWithUitoolkit:_uitoolkit
                             itemAddedBlk:itemAddedBlk
                         entityPanelMaker:[_panelToolkit environmentLogPanelMakerWithUser:user
                                                                   defaultSelectedVehicle:defaultSelectedVehicle
                                                                     defaultPickedLogDate:[NSDate date]]
                      entityToPanelBinder:[_panelToolkit environmentLogToEnvironmentLogPanelBinder]
                      panelToEntityBinder:[_panelToolkit environmentLogPanelToEnvironmentLogBinder]
                           addEntityTitle:@"Add Environment Log"
                        entityAddCanceler:^(PEAddViewEditController *ctrl){[[ctrl navigationController] dismissViewControllerAnimated:YES completion:nil];}
                              entityMaker:[_panelToolkit environmentLogMaker]
                           newEntitySaver:newEnvironmentLogSaver
           prepareUIForUserInteractionBlk:nil
                         viewDidAppearBlk:viewDidAppearBlk
                          entityValidator:[self newEnvironmentLogValidator]
                    foregroundEditActorId:@(FPForegroundActorId)
            entityAddedNotificationToPost:FPEnvironmentLogAdded];
  };
}

- (FPAuthScreenMaker)newEnvironmentLogDetailScreenMakerWithEnvLog:(FPEnvironmentLog *)envLog
                                                  envLogIndexPath:(NSIndexPath *)envLogIndexPath
                                                   itemChangedBlk:(PEItemChangedBlk)itemChangedBlk {
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
                                                editActorId:@(FPForegroundActorId)
                                          entityBeingSynced:[self entityBeingSyncedBlk]
                                              entityDeleted:[self entityDeletedBlk]
                                           entityInConflict:[self entityInConflictBlk]
                              entityBeingEditedByOtherActor:[self entityBeingEditedByOtherActorBlk]
                                                      error:[FPUtils localSaveErrorHandlerMaker]()];
      if (result) {
        refreshVehicleTableView(ctrl, envLog);
      }
      return result;
    };
    PEEntityEditCancelerBlk envLogEditCanceler = ^(PEAddViewEditController *ctrl, FPEnvironmentLog *envLog) {
      [_coordDao cancelEditOfEnvironmentLog:envLog
                                editActorId:@(FPForegroundActorId)
                                      error:[FPUtils localSaveErrorHandlerMaker]()];
      refreshVehicleTableView(ctrl, envLog);
    };
    PESaveEntityBlk envLogSaver = ^(PEAddViewEditController *ctrl, FPEnvironmentLog *envLog) {
      FPEnvLogVehicleAndDateDataSourceDelegate *ds =
        (FPEnvLogVehicleAndDateDataSourceDelegate *)
        [(UITableView *)[[ctrl view] viewWithTag:FPEnvLogTagVehicleAndDate] dataSource];
      FPVehicle *selectedVehicle = [ds selectedVehicle];
      [_coordDao saveEnvironmentLog:envLog
                            forUser:user
                            vehicle:selectedVehicle
                        editActorId:@(FPForegroundActorId)
                              error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    PEMarkAsDoneEditingBlk doneEditingEnvironmentLogMarker = ^(FPEnvironmentLog *envLog,
                                                               PESyncImmediateSuccessBlk successBlk,
                                                               PESyncImmediateFailedBlk failedBlk,
                                                               PESyncImmediateRetryAfterBlk retryAFterBlk) {
      [_coordDao markAsDoneEditingEnvironmentLog:envLog
                                     editActorId:@(FPForegroundActorId)
                                           error:[FPUtils localSaveErrorHandlerMaker]()];
    };
    return [PEAddViewEditController viewEntityCtrlrWithEntity:envLog
                                              entityIndexPath:envLogIndexPath
                                                    uitoolkit:_uitoolkit
                                               itemChangedBlk:itemChangedBlk
                                       syncInitiatedNotifName:FPEnvironmentLogSyncInitiated
                                              syncedNotifName:FPEnvironmentLogSynced
                                          syncFailedNotifName:FPEnvironmentLogSyncFailed
                               entityRemotelyDeletedNotifName:FPEnvironmentLogRemotelyDeleted
                               entityLocallyUpdatedNotifNames:@[FPEnvironmentLogUpdated]
                               entityRemotelyUpdatedNotifName:FPEnvironmentLogRemotelyUpdated
                                             entityPanelMaker:[_panelToolkit environmentLogPanelMakerWithUser:user
                                                                                       defaultSelectedVehicle:[_coordDao vehicleForEnvironmentLog:envLog
                                                                                                                                            error:[FPUtils localFetchErrorHandlerMaker]()]
                                                                                         defaultPickedLogDate:[envLog logDate]]
                                          entityToPanelBinder:[_panelToolkit environmentLogToEnvironmentLogPanelBinder]
                                          panelToEntityBinder:[_panelToolkit environmentLogPanelToEnvironmentLogBinder]
                                              viewEntityTitle:@"Environment Log"
                                              editEntityTitle:@"Edit Environment Log"
                                         panelEnablerDisabler:[_panelToolkit environmentLogPanelEnablerDisabler]
                                            entityAddCanceler:^(PEAddViewEditController *ctrl){[[ctrl navigationController] dismissViewControllerAnimated:YES completion:nil];}
                                           entityEditPreparer:envLogEditPreparer
                                           entityEditCanceler:envLogEditCanceler
                                                  entitySaver:envLogSaver
                                      doneEditingEntityMarker:doneEditingEnvironmentLogMarker
                                 syncImmediateWhenDoneEditing:NO
                                    syncImmediateInitiatedMsg:nil
                                     syncImmediateCompleteMsg:nil
                                       syncImmediateFailedMsg:nil
                                   syncImmediateRetryAfterMsg:nil
                                           entitySyncCanceler:nil
                          isEntityConfiguredForBackgroundSync:YES
                               prepareUIForUserInteractionBlk:nil
                                             viewDidAppearBlk:nil
                                              entityValidator:[self newEnvironmentLogValidator]
                                        foregroundEditActorId:@(FPForegroundActorId)
                              entityUpdatedNotificationToPost:FPEnvironmentLogUpdated];
  };
}

- (FPAuthScreenMaker)newViewEnvironmentLogsScreenMakerForVehicleInCtx {
  return ^ UIViewController *(FPVehicle *vehicle) {
    FPUser *user = [_coordDao userForVehicle:vehicle error:[FPUtils localFetchErrorHandlerMaker]()];
    void (^addEnvLogAction)(PEListViewController *, PEItemAddedBlk) =
    ^(PEListViewController *listViewCtrlr, PEItemAddedBlk itemAddedBlk) {
      UIViewController *addEnvLogScreen =
      [self newAddEnvironmentLogScreenMakerWithBlk:itemAddedBlk
                            defaultSelectedVehicle:vehicle](user);
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
                                                 itemChangedBlk:itemChangedBlk](user);
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
    return [[PEListViewController alloc]
             initWithClassOfDataSourceObjects:[FPEnvironmentLog class]
                                        title:@"Environment Logs"
                        isPaginatedDataSource:YES
                              tableCellStyler:[PELMUIUtils syncViewStylerWithTitleBlk:^(FPEnvironmentLog *envLog) {return [PEUtils stringFromDate:[envLog logDate] withPattern:@"MM/dd/YYYY"];} alwaysTopifyTitleLabel:NO uitoolkit:_uitoolkit foregroundActorId:FPForegroundActorId subtitleLeftHPadding:15.0]
                           itemSelectedAction:nil
                          initialSelectedItem:nil
                                addItemAction:addEnvLogAction
                               cellIdentifier:@"FPEnvironmentLogCell"
                               initialObjects:initialEnvLogs
                                   pageLoader:pageLoader
                               heightForCells:52.0
                              detailViewMaker:envLogDetailViewMaker
                                    uitoolkit:_uitoolkit
                        entityAddedNotifNames:@[FPEnvironmentLogAdded,
                                                FPEnvironmentLogRemotelyAdded]
                      entityUpdatedNotifNames:@[FPEnvironmentLogUpdated,
                                                FPEnvironmentLogRemotelyUpdated,
                                                FPEnvironmentLogSynced,
                                                FPEnvironmentLogSyncInitiated,
                                                FPEnvironmentLogSyncFailed]
                      entityRemovedNotifNames:@[FPEnvironmentLogDeleted,
                                                FPEnvironmentLogRemotelyDeleted]
               doesEntityBelongToThisListView:doesEntityBelongToThisListViewBlk
                         wouldBeIndexOfEntity:wouldBeIndexBlk];
  };
}

#pragma mark - Quick Action Screen

- (FPAuthScreenMakerWithTempNotification)newQuickActionMenuScreenMaker {
  return ^ UIViewController *(FPUser *user,
                              NSString *tempNotification) {
    return [[FPQuickActionMenuController alloc]
              initWithStoreCoordinator:_coordDao
                                  user:user
                      tempNotification:tempNotification
                             uitoolkit:_uitoolkit
                         screenToolkit:self];
  };
}

#pragma mark - Unauthenticated Landing Screen

- (FPUnauthScreenMaker)newUnauthLandingScreenMakerWithTempNotification:(NSString *)msgOrKey {
  return ^ UIViewController * {
    return [[FPUnauthStartController alloc]
              initWithStoreCoordinator:_coordDao
                      tempNotification:msgOrKey
                             uitoolkit:_uitoolkit
                         screenToolkit:self];
  };
}

#pragma mark - Tab-bar Authenticated Landing Screen

- (FPAuthScreenMaker)newTabBarAuthHomeLandingScreenMakerWithTempNotification:(NSString *)tempNotification {
  return ^ UIViewController *(FPUser *user) {
    UIViewController *quickActionMenuCtrl = [self newQuickActionMenuScreenMaker](user, tempNotification);
    UIViewController *settingsMenuCtrl = [self newViewSettingsScreenMaker](user);
    UIViewController *draftsCtrl = [self newViewDraftsScreenMaker](user);
    UITabBarController *tabBarCtrl =
    [[UITabBarController alloc] initWithNibName:nil bundle:nil];
    [tabBarCtrl setViewControllers:@[
                                     [PEUIUtils navControllerWithRootController:quickActionMenuCtrl
                                                            navigationBarHidden:NO
                                                                tabBarItemTitle:@"Quick Action Menu"
                                                                tabBarItemImage:[UIImage imageNamed:@"tab-home"]
                                                        tabBarItemSelectedImage:[[UIImage imageNamed:@"tab-home"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]],
                                     [PEUIUtils navControllerWithRootController:settingsMenuCtrl
                                                            navigationBarHidden:NO
                                                                tabBarItemTitle:@"Settings"
                                                                tabBarItemImage:[UIImage imageNamed:@"tab-settings"]
                                                        tabBarItemSelectedImage:[[UIImage imageNamed:@"tab-settings"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]],
                                     [PEUIUtils navControllerWithRootController:draftsCtrl
                                                            navigationBarHidden:NO
                                                                tabBarItemTitle:@"Drafts"
                                                                tabBarItemImage:[UIImage imageNamed:@"tab-drafts"]
                                                        tabBarItemSelectedImage:[[UIImage imageNamed:@"tab-drafts"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]]]];
    [tabBarCtrl setSelectedIndex:0];
    return tabBarCtrl;
  };
}

@end
