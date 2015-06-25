//
//  PEAddViewEditController.h
//  fuelpurchase
//
//  Created by Evans, Paul on 9/30/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PEObjc-Commons/PEUIToolkit.h>
#import <PEFuelPurchase-Model/PELMMainSupport.h>
#import <MBProgressHUD/MBProgressHUD.h>

@class PEAddViewEditController;
typedef NSDictionary *(^PEComponentsMakerBlk)(UIViewController *);
typedef UIView *(^PEEntityPanelMakerBlk)(PEAddViewEditController *);
typedef void (^PEPanelToEntityBinderBlk)(UIView *, id);
typedef void (^PEEntityToPanelBinderBlk)(id, UIView *);
typedef void (^PEEnableDisablePanelBlk)(UIView *, BOOL);
typedef BOOL (^PEEntityEditPreparerBlk)(PEAddViewEditController *, id);
typedef void (^PEEntityEditCancelerBlk)(PEAddViewEditController *, id);
typedef void (^PEEntityAddCancelerBlk)(PEAddViewEditController *, id);
typedef id   (^PEEntityMakerBlk)(UIView *);
typedef void (^PESaveEntityBlk)(PEAddViewEditController *, id);
typedef void (^PESyncImmediateSuccessBlk)(float, NSString *, NSString *);
typedef void (^PESyncImmediateServerTempErrorBlk)(float, NSString *, NSString *);
typedef void (^PESyncImmediateServerErrorBlk)(float, NSString *, NSString *, NSInteger);
typedef void (^PESyncImmediateAuthRequiredBlk)(float, NSString *, NSString *);
typedef void (^PESyncImmediateRetryAfterBlk)(float, NSString *, NSString *, NSDate *);
typedef void (^PEEntitySyncCancelerBlk)(PELMMainSupport *, NSError *, NSNumber *);
typedef void (^PEMarkAsDoneEditingBlk)(PEAddViewEditController *,
                                       id,
                                       PESyncImmediateSuccessBlk,
                                       PESyncImmediateRetryAfterBlk,
                                       PESyncImmediateServerTempErrorBlk,
                                       PESyncImmediateServerErrorBlk,
                                       PESyncImmediateAuthRequiredBlk);
typedef void (^PESaveNewEntityBlk)(UIView *,
                                   id,
                                   PESyncImmediateSuccessBlk,
                                   PESyncImmediateRetryAfterBlk,
                                   PESyncImmediateServerTempErrorBlk,
                                   PESyncImmediateServerErrorBlk,
                                   PESyncImmediateAuthRequiredBlk);
typedef void (^PEItemAddedBlk)(PEAddViewEditController *, id);
typedef void (^PEItemChangedBlk)(id, NSIndexPath *);
typedef void (^PEPrepareUIForUserInteractionBlk)(UIView *);
typedef void (^PEViewDidAppearBlk)(UIView *);
typedef NSArray *(^PEEntityValidatorBlk)(UIView *);
typedef NSArray *(^PEMessagesFromErrMask)(NSInteger);

@interface PEAddViewEditController : UIViewController <MBProgressHUDDelegate>

#pragma mark - Initializers

- (id)initWithEntity:(PELMMainSupport *)entity
               isAdd:(BOOL)isAdd
           indexPath:(NSIndexPath *)indexPath
           uitoolkit:(PEUIToolkit *)uitoolkit
        itemAddedBlk:(PEItemAddedBlk)itemAddedBlk
      itemChangedBlk:(PEItemChangedBlk)itemChangedBlk
syncInitiatedNotifName:(NSString *)syncInitiatedNotifName
     syncedNotifName:(NSString *)syncedNotifName
 syncFailedNotifName:(NSString *)syncFailedNotifName
entityRemotelyDeletedNotifName:(NSString *)entityRemotelyDeletedNotifName
entityLocallyUpdatedNotifNames:(NSArray *)entityLocallyUpdatedNotifNames
entityRemotelyUpdatedNotifName:(NSString *)entityRemotelyUpdatedNotifName
    entityPanelMaker:(PEEntityPanelMakerBlk)entityPanelMaker
 entityToPanelBinder:(PEEntityToPanelBinderBlk)entityToPanelBinder
 panelToEntityBinder:(PEPanelToEntityBinderBlk)panelToEntityBinder
         entityTitle:(NSString *)entityTitle
panelEnablerDisabler:(PEEnableDisablePanelBlk)panelEnablerDisabler
   entityAddCanceler:(PEEntityAddCancelerBlk)entityAddCanceler
  entityEditPreparer:(PEEntityEditPreparerBlk)entityEditPreparer
  entityEditCanceler:(PEEntityEditCancelerBlk)entityEditCanceler
         entityMaker:(PEEntityMakerBlk)entityMaker
         entitySaver:(PESaveEntityBlk)entitySaver
      newEntitySaver:(PESaveNewEntityBlk)newEntitySaver
doneEditingEntityMarker:(PEMarkAsDoneEditingBlk)doneEditingEntityMarker
syncImmediateWhenDoneEditing:(BOOL)syncImmediateWhenDoneEditing
      isUserLoggedIn:(BOOL)isUserLoggedIn
syncImmediateMBProgressHUDMode:(MBProgressHUDMode)syncImmediateMBProgressHUDMode
isEntityAppropriateForBackgroundSync:(BOOL)isEntityAppropriateForBackgroundSync
prepareUIForUserInteractionBlk:(PEPrepareUIForUserInteractionBlk)prepareUIForUserInteractionBlk
    viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
     entityValidator:(PEEntityValidatorBlk)entityValidator
     messageComputer:(PEMessagesFromErrMask)messageComputer
foregroundEditActorId:(NSNumber *)foregroundEditActorId
entityAddedNotificationToPost:(NSString *)entityAddedNotificationToPost
entityUpdatedNotificationToPost:(NSString *)entityUpdatedNotificationToPost
getterForNotification:(SEL)getterForNotification;

#pragma mark - Factory functions

+ (PEAddViewEditController *)addEntityCtrlrWithUitoolkit:(PEUIToolkit *)uitoolkit
                                            itemAddedBlk:(PEItemAddedBlk)itemAddedBlk
                                        entityPanelMaker:(PEEntityPanelMakerBlk)entityPanelMaker
                                     entityToPanelBinder:(PEEntityToPanelBinderBlk)entityToPanelBinder
                                     panelToEntityBinder:(PEPanelToEntityBinderBlk)panelToEntityBinder
                                             entityTitle:(NSString *)entityTitle
                                       entityAddCanceler:(PEEntityAddCancelerBlk)entityAddCanceler
                                             entityMaker:(PEEntityMakerBlk)entityMaker
                                          newEntitySaver:(PESaveNewEntityBlk)newEntitySaver
                          prepareUIForUserInteractionBlk:(PEPrepareUIForUserInteractionBlk)prepareUIForUserInteractionBlk
                                        viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
                                         entityValidator:(PEEntityValidatorBlk)entityValidator
                                         messageComputer:(PEMessagesFromErrMask)messageComputer
                                   foregroundEditActorId:(NSNumber *)foregroundEditActorId
                           entityAddedNotificationToPost:(NSString *)entityAddedNotificationToPost
                            syncImmediateWhenDoneEditing:(BOOL)syncImmediateWhenDoneEditing
                                          isUserLoggedIn:(BOOL)isUserLoggedIn
                          syncImmediateMBProgressHUDMode:(MBProgressHUDMode)syncImmediateMBProgressHUDMode
                    isEntityAppropriateForBackgroundSync:(BOOL)isEntityAppropriateForBackgroundSync;

+ (PEAddViewEditController *)addEntityCtrlrWithUitoolkit:(PEUIToolkit *)uitoolkit
                                            itemAddedBlk:(PEItemAddedBlk)itemAddedBlk
                                        entityPanelMaker:(PEEntityPanelMakerBlk)entityPanelMaker
                                     entityToPanelBinder:(PEEntityToPanelBinderBlk)entityToPanelBinder
                                     panelToEntityBinder:(PEPanelToEntityBinderBlk)panelToEntityBinder
                                             entityTitle:(NSString *)entityTitle
                                       entityAddCanceler:(PEEntityAddCancelerBlk)entityAddCanceler
                                             entityMaker:(PEEntityMakerBlk)entityMaker
                                          newEntitySaver:(PESaveNewEntityBlk)newEntitySaver
                          prepareUIForUserInteractionBlk:(PEPrepareUIForUserInteractionBlk)prepareUIForUserInteractionBlk
                                        viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
                                         entityValidator:(PEEntityValidatorBlk)entityValidator
                                         messageComputer:(PEMessagesFromErrMask)messageComputer
                                   foregroundEditActorId:(NSNumber *)foregroundEditActorId
                           entityAddedNotificationToPost:(NSString *)entityAddedNotificationToPost
                            syncImmediateWhenDoneEditing:(BOOL)syncImmediateWhenDoneEditing
                                          isUserLoggedIn:(BOOL)isUserLoggedIn
                          syncImmediateMBProgressHUDMode:(MBProgressHUDMode)syncImmediateMBProgressHUDMode
                    isEntityAppropriateForBackgroundSync:(BOOL)isEntityAppropriateForBackgroundSync
                                   getterForNotification:(SEL)getterForNotification;

+ (PEAddViewEditController *)viewEntityCtrlrWithEntity:(PELMMainSupport *)entity
                                       entityIndexPath:(NSIndexPath *)entityIndexPath
                                             uitoolkit:(PEUIToolkit *)uitoolkit
                                        itemChangedBlk:(PEItemChangedBlk)itemChangedBlk
                                syncInitiatedNotifName:(NSString *)syncInitiatedNotifName
                                       syncedNotifName:(NSString *)syncedNotifName
                                   syncFailedNotifName:(NSString *)syncFailedNotifName
                        entityRemotelyDeletedNotifName:(NSString *)entityRemotelyDeletedNotifName
                        entityLocallyUpdatedNotifNames:(NSArray *)entityLocallyUpdatedNotifNames
                        entityRemotelyUpdatedNotifName:(NSString *)entityRemotelyUpdatedNotifName
                                      entityPanelMaker:(PEEntityPanelMakerBlk)entityPanelMaker
                                   entityToPanelBinder:(PEEntityToPanelBinderBlk)entityToPanelBinder
                                   panelToEntityBinder:(PEPanelToEntityBinderBlk)panelToEntityBinder
                                           entityTitle:(NSString *)entityTitle
                                  panelEnablerDisabler:(PEEnableDisablePanelBlk)panelEnablerDisabler
                                     entityAddCanceler:(PEEntityAddCancelerBlk)entityAddCanceler
                                    entityEditPreparer:(PEEntityEditPreparerBlk)entityEditPreparer
                                    entityEditCanceler:(PEEntityEditCancelerBlk)entityEditCanceler
                                           entitySaver:(PESaveEntityBlk)entitySaver
                               doneEditingEntityMarker:(PEMarkAsDoneEditingBlk)doneEditingEntityMarker
                          syncImmediateWhenDoneEditing:(BOOL)syncImmediateWhenDoneEditing
                                        isUserLoggedIn:(BOOL)isUserLoggedIn
                        syncImmediateMBProgressHUDMode:(MBProgressHUDMode)syncImmediateMBProgressHUDMode
                  isEntityAppropriateForBackgroundSync:(BOOL)isEntityAppropriateForBackgroundSync
                        prepareUIForUserInteractionBlk:(PEPrepareUIForUserInteractionBlk)prepareUIForUserInteractionBlk
                                      viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
                                       entityValidator:(PEEntityValidatorBlk)entityValidator
                                       messageComputer:(PEMessagesFromErrMask)messageComputer
                                 foregroundEditActorId:(NSNumber *)foregroundEditActorId
                       entityUpdatedNotificationToPost:(NSString *)entityUpdatedNotificationToPost;

#pragma mark - Properties

@property (readonly, nonatomic) PELMMainSupport *entity;

@property (readonly, nonatomic) PEUIToolkit *uitoolkit;

@property (readonly, nonatomic) PEEntityToPanelBinderBlk entityToPanelBinder;

@property (nonatomic) UIView *entityPanel;

@end
