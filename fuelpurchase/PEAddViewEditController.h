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

@class PEListViewController;
@class PEAddViewEditController;
typedef NSDictionary *(^PEComponentsMakerBlk)(UIViewController *);
typedef UIView *(^PEEntityPanelMakerBlk)(PEAddViewEditController *);
typedef UIView *(^PEEntityViewPanelMakerBlk)(PEAddViewEditController *, id);
typedef void (^PEPanelToEntityBinderBlk)(UIView *, id);
typedef void (^PEEntityToPanelBinderBlk)(id, UIView *);
typedef void (^PEEnableDisablePanelBlk)(UIView *, BOOL);
typedef BOOL (^PEEntityEditPreparerBlk)(PEAddViewEditController *, id);
typedef void (^PEEntityEditCancelerBlk)(PEAddViewEditController *, id);
typedef void (^PEEntityAddCancelerBlk)(PEAddViewEditController *, BOOL, id);
typedef id   (^PEEntityMakerBlk)(UIView *);
typedef void (^PESaveEntityBlk)(PEAddViewEditController *, id);
typedef void (^PESyncNotFoundBlk)(float, NSString *, NSString *);
typedef void (^PESyncConflictBlk)(float, NSString *, NSString *, id);
typedef void (^PESyncSuccessBlk)(float, NSString *, NSString *);
typedef void (^PEDownloadSuccessBlk)(float, NSString *, NSString *, id);
typedef void (^PESyncServerTempErrorBlk)(float, NSString *, NSString *);
typedef void (^PESyncServerErrorBlk)(float, NSString *, NSString *, NSArray *);
typedef void (^PESyncAuthRequiredBlk)(float, NSString *, NSString *);
typedef void (^PESyncRetryAfterBlk)(float, NSString *, NSString *, NSDate *);
typedef void (^PESyncDependencyUnsynced)(float, NSString *, NSString *, NSString *);
typedef void (^PEEntitySyncCancelerBlk)(PELMMainSupport *, NSError *, NSNumber *);
typedef BOOL (^PEIsAuthenticatedBlk)(void);
typedef BOOL (^PEIsLoggedInBlk)(void);
typedef BOOL (^PEIsOfflineModeBlk)(void);
typedef NSInteger (^PENumRemoteDepsNotLocal)(id);
typedef void (^PEUpdateDepsPanel)(PEAddViewEditController *, id);
typedef NSDictionary * (^PEMergeBlk)(PEAddViewEditController *, id, id);
typedef NSArray * (^PEConflictResolveFields)(PEAddViewEditController *, NSDictionary *, id, id);
typedef id (^PEConflictResolvedEntity)(PEAddViewEditController *, NSDictionary *, NSArray *, id, id);
typedef void (^PEPostDownloaderSaver)(PEAddViewEditController *, id, id);
typedef void (^PEDependencyFetcherBlk)(PEAddViewEditController *,
                                       id,
                                       PESyncNotFoundBlk,
                                       PESyncSuccessBlk,
                                       PESyncRetryAfterBlk,
                                       PESyncServerTempErrorBlk,
                                       PESyncAuthRequiredBlk);
typedef void (^PEDownloaderBlk)(PEAddViewEditController *,
                                id,
                                PESyncNotFoundBlk,
                                PEDownloadSuccessBlk,
                                PESyncRetryAfterBlk,
                                PESyncServerTempErrorBlk,
                                PESyncAuthRequiredBlk);
typedef void (^PEMarkAsDoneEditingLocalBlk)(PEAddViewEditController *, id);
typedef void (^PEMarkAsDoneEditingImmediateSyncBlk)(PEAddViewEditController *,
                                                    id,
                                                    PESyncNotFoundBlk,
                                                    PESyncSuccessBlk,
                                                    PESyncRetryAfterBlk,
                                                    PESyncServerTempErrorBlk,
                                                    PESyncServerErrorBlk,
                                                    PESyncConflictBlk,
                                                    PESyncAuthRequiredBlk,
                                                    PESyncDependencyUnsynced);
typedef void (^PEUploaderBlk)(PEAddViewEditController *,
                              id,
                              PESyncNotFoundBlk,
                              PESyncSuccessBlk,
                              PESyncRetryAfterBlk,
                              PESyncServerTempErrorBlk,
                              PESyncServerErrorBlk,
                              PESyncConflictBlk,
                              PESyncAuthRequiredBlk,
                              PESyncDependencyUnsynced);
typedef void (^PESaveNewEntityLocalBlk)(UIView *, id);
typedef void (^PESaveNewEntityImmediateSyncBlk)(UIView *,
                                                id,
                                                PESyncNotFoundBlk,
                                                PESyncSuccessBlk,
                                                PESyncRetryAfterBlk,
                                                PESyncServerTempErrorBlk,
                                                PESyncServerErrorBlk,
                                                PESyncConflictBlk,
                                                PESyncAuthRequiredBlk,
                                                PESyncDependencyUnsynced);
typedef void (^PEItemAddedBlk)(PEAddViewEditController *, id);
typedef void (^PEItemChangedBlk)(id, NSIndexPath *);
typedef void (^PEPrepareUIForUserInteractionBlk)(UIView *);
typedef void (^PEViewDidAppearBlk)(UIView *);
typedef NSArray *(^PEEntityValidatorBlk)(UIView *);
typedef NSArray *(^PEMessagesFromErrMask)(NSInteger);

@interface PEAddViewEditController : UIViewController <MBProgressHUDDelegate>

#pragma mark - Initializers

- (id)initWithEntity:(PELMMainSupport *)entity
  listViewController:(PEListViewController *)listViewController
               isAdd:(BOOL)isAdd
           indexPath:(NSIndexPath *)indexPath
           uitoolkit:(PEUIToolkit *)uitoolkit
        itemAddedBlk:(PEItemAddedBlk)itemAddedBlk
      itemChangedBlk:(PEItemChangedBlk)itemChangedBlk
entityFormPanelMaker:(PEEntityPanelMakerBlk)entityFormPanelMaker
entityViewPanelMaker:(PEEntityViewPanelMakerBlk)entityViewPanelMaker
 entityToPanelBinder:(PEEntityToPanelBinderBlk)entityToPanelBinder
 panelToEntityBinder:(PEPanelToEntityBinderBlk)panelToEntityBinder
         entityTitle:(NSString *)entityTitle
panelEnablerDisabler:(PEEnableDisablePanelBlk)panelEnablerDisabler
   entityAddCanceler:(PEEntityAddCancelerBlk)entityAddCanceler
  entityEditPreparer:(PEEntityEditPreparerBlk)entityEditPreparer
  entityEditCanceler:(PEEntityEditCancelerBlk)entityEditCanceler
         entityMaker:(PEEntityMakerBlk)entityMaker
         entitySaver:(PESaveEntityBlk)entitySaver
 newEntitySaverLocal:(PESaveNewEntityLocalBlk)newEntitySaverLocal
newEntitySaverImmediateSync:(PESaveNewEntityImmediateSyncBlk)newEntitySaverImmediateSync
doneEditingEntityLocal:(PEMarkAsDoneEditingLocalBlk)doneEditingEntityLocal
doneEditingEntityImmediateSync:(PEMarkAsDoneEditingImmediateSyncBlk)doneEditingEntityImmediateSync
     isAuthenticated:(PEIsAuthenticatedBlk)isAuthenticated
      isUserLoggedIn:(PEIsLoggedInBlk)isUserLoggedIn
       isOfflineMode:(PEIsOfflineModeBlk)isOfflineMode
syncImmediateMBProgressHUDMode:(MBProgressHUDMode)syncImmediateMBProgressHUDMode
prepareUIForUserInteractionBlk:(PEPrepareUIForUserInteractionBlk)prepareUIForUserInteractionBlk
    viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
     entityValidator:(PEEntityValidatorBlk)entityValidator
              uploader:(PEUploaderBlk)uploader
numRemoteDepsNotLocal:(PENumRemoteDepsNotLocal)numRemoteDepsNotLocal
               merge:(PEMergeBlk)merge
   fetchDependencies:(PEDependencyFetcherBlk)fetchDependencies
     updateDepsPanel:(PEUpdateDepsPanel)updateDepsPanel
          downloader:(PEDownloaderBlk)downloader
   postDownloadSaver:(PEPostDownloaderSaver)postDownloadSaver
conflictResolveFields:(PEConflictResolveFields)conflictResolveFields
conflictResolvedEntity:(PEConflictResolvedEntity)conflictResolvedEntity
getterForNotification:(SEL)getterForNotification;

#pragma mark - Factory functions

+ (PEAddViewEditController *)addEntityCtrlrWithUitoolkit:(PEUIToolkit *)uitoolkit
                                      listViewController:(PEListViewController *)listViewController
                                            itemAddedBlk:(PEItemAddedBlk)itemAddedBlk
                                    entityFormPanelMaker:(PEEntityPanelMakerBlk)entityFormPanelMaker
                                     entityToPanelBinder:(PEEntityToPanelBinderBlk)entityToPanelBinder
                                     panelToEntityBinder:(PEPanelToEntityBinderBlk)panelToEntityBinder
                                             entityTitle:(NSString *)entityTitle
                                       entityAddCanceler:(PEEntityAddCancelerBlk)entityAddCanceler
                                             entityMaker:(PEEntityMakerBlk)entityMaker
                                     newEntitySaverLocal:(PESaveNewEntityLocalBlk)newEntitySaverLocal
                             newEntitySaverImmediateSync:(PESaveNewEntityImmediateSyncBlk)newEntitySaverImmediateSync
                          prepareUIForUserInteractionBlk:(PEPrepareUIForUserInteractionBlk)prepareUIForUserInteractionBlk
                                        viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
                                         entityValidator:(PEEntityValidatorBlk)entityValidator
                                         isAuthenticated:(PEIsAuthenticatedBlk)isAuthenticated
                                          isUserLoggedIn:(PEIsLoggedInBlk)isUserLoggedIn
                                           isOfflineMode:(PEIsOfflineModeBlk)isOfflineMode
                          syncImmediateMBProgressHUDMode:(MBProgressHUDMode)syncImmediateMBProgressHUDMode;

+ (PEAddViewEditController *)addEntityCtrlrWithUitoolkit:(PEUIToolkit *)uitoolkit
                                      listViewController:(PEListViewController *)listViewController
                                            itemAddedBlk:(PEItemAddedBlk)itemAddedBlk
                                    entityFormPanelMaker:(PEEntityPanelMakerBlk)entityFormPanelMaker
                                     entityToPanelBinder:(PEEntityToPanelBinderBlk)entityToPanelBinder
                                     panelToEntityBinder:(PEPanelToEntityBinderBlk)panelToEntityBinder
                                             entityTitle:(NSString *)entityTitle
                                       entityAddCanceler:(PEEntityAddCancelerBlk)entityAddCanceler
                                             entityMaker:(PEEntityMakerBlk)entityMaker
                                     newEntitySaverLocal:(PESaveNewEntityLocalBlk)newEntitySaverLocal
                             newEntitySaverImmediateSync:(PESaveNewEntityImmediateSyncBlk)newEntitySaverImmediateSync
                          prepareUIForUserInteractionBlk:(PEPrepareUIForUserInteractionBlk)prepareUIForUserInteractionBlk
                                        viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
                                         entityValidator:(PEEntityValidatorBlk)entityValidator
                                         isAuthenticated:(PEIsAuthenticatedBlk)isAuthenticated
                                          isUserLoggedIn:(PEIsLoggedInBlk)isUserLoggedIn
                                           isOfflineMode:(PEIsOfflineModeBlk)isOfflineMode
                          syncImmediateMBProgressHUDMode:(MBProgressHUDMode)syncImmediateMBProgressHUDMode
                                   getterForNotification:(SEL)getterForNotification;

+ (PEAddViewEditController *)viewEntityCtrlrWithEntity:(PELMMainSupport *)entity
                                    listViewController:(PEListViewController *)listViewController
                                       entityIndexPath:(NSIndexPath *)entityIndexPath
                                             uitoolkit:(PEUIToolkit *)uitoolkit
                                        itemChangedBlk:(PEItemChangedBlk)itemChangedBlk
                                  entityFormPanelMaker:(PEEntityPanelMakerBlk)entityFormPanelMaker
                                  entityViewPanelMaker:(PEEntityViewPanelMakerBlk)entityViewPanelMaker
                                   entityToPanelBinder:(PEEntityToPanelBinderBlk)entityToPanelBinder
                                   panelToEntityBinder:(PEPanelToEntityBinderBlk)panelToEntityBinder
                                           entityTitle:(NSString *)entityTitle
                                  panelEnablerDisabler:(PEEnableDisablePanelBlk)panelEnablerDisabler
                                     entityAddCanceler:(PEEntityAddCancelerBlk)entityAddCanceler
                                    entityEditPreparer:(PEEntityEditPreparerBlk)entityEditPreparer
                                    entityEditCanceler:(PEEntityEditCancelerBlk)entityEditCanceler
                                           entitySaver:(PESaveEntityBlk)entitySaver
                                doneEditingEntityLocal:(PEMarkAsDoneEditingLocalBlk)doneEditingEntityLocal
                        doneEditingEntityImmediateSync:(PEMarkAsDoneEditingImmediateSyncBlk)doneEditingEntityImmediateSync
                                       isAuthenticated:(PEIsAuthenticatedBlk)isAuthenticated
                                        isUserLoggedIn:(PEIsLoggedInBlk)isUserLoggedIn
                                         isOfflineMode:(PEIsOfflineModeBlk)isOfflineMode
                        syncImmediateMBProgressHUDMode:(MBProgressHUDMode)syncImmediateMBProgressHUDMode
                        prepareUIForUserInteractionBlk:(PEPrepareUIForUserInteractionBlk)prepareUIForUserInteractionBlk
                                      viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
                                       entityValidator:(PEEntityValidatorBlk)entityValidator
                                              uploader:(PEUploaderBlk)uploader
                                 numRemoteDepsNotLocal:(PENumRemoteDepsNotLocal)numRemoteDepsNotLocal
                                                 merge:(PEMergeBlk)merge
                                     fetchDependencies:(PEDependencyFetcherBlk)fetchDependencies
                                       updateDepsPanel:(PEUpdateDepsPanel)updateDepsPanel
                                            downloader:(PEDownloaderBlk)downloader
                                     postDownloadSaver:(PEPostDownloaderSaver)postDownloadSaver
                                 conflictResolveFields:(PEConflictResolveFields)conflictResolveFields
                                conflictResolvedEntity:(PEConflictResolvedEntity)conflictResolvedEntity;

#pragma mark - Properties

@property (readonly, nonatomic) PELMMainSupport *entity;

@property (readonly, nonatomic) PEUIToolkit *uitoolkit;

@property (readonly, nonatomic) PEEntityToPanelBinderBlk entityToPanelBinder;

@property (nonatomic) UIView *entityFormPanel;

@end
