//
//  PEAddViewEditController.h
//  PELocal-DataUI
//
//  Created by Evans, Paul on 9/30/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PEObjc-Commons/PEUIToolkit.h>
#import <PEObjc-Commons/PEUIUtils.h>
#import <PELocal-Data/PELMMainSupport.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "PEUIDefs.h"

@class PEListViewController;
@class PEAddViewEditController;

@interface PEAddViewEditController : UIViewController <MBProgressHUDDelegate, UIScrollViewDelegate>

#pragma mark - Initializers

- (id)initWithParentEntity:(PELMMainSupport *)parentEntity
                    entity:(PELMMainSupport *)entity
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
       itemChildrenCounter:(PEItemChildrenCounter)itemChildrenCounter
       itemChildrenMsgsBlk:(PEItemChildrenMsgsBlk)itemChildrenMsgsBlk
               itemDeleter:(PEItemDeleter)itemDeleter
          itemLocalDeleter:(PEItemLocalDeleter)itemLocalDeleter
        entitiesFromEntity:(PEEntitiesFromEntityBlk)entitiesFromEntity
     modalOperationStarted:(PEModalOperationStarted)modalOperationStarted
        modalOperationDone:(PEModalOperationDone)modalOperationDone
entityAddedNotificationName:(NSString *)entityAddedNotificationName
entityUpdatedNotificationName:(NSString *)entityUpdatedNotificationName
entityRemovedNotificationName:(NSString *)entityRemovedNotificationName
        addlContentSection:(PEAddlContentSection)addlContentSection;

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
                          syncImmediateMBProgressHUDMode:(MBProgressHUDMode)syncImmediateMBProgressHUDMode
                                   modalOperationStarted:(PEModalOperationStarted)modalOperationStarted
                                      modalOperationDone:(PEModalOperationDone)modalOperationDone
                             entityAddedNotificationName:(NSString *)entityAddedNotificationName
                                      addlContentSection:(PEAddlContentSection)addlContentSection;

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
                                      entitiesFromEntity:(PEEntitiesFromEntityBlk)entitiesFromEntity
                                   modalOperationStarted:(PEModalOperationStarted)modalOperationStarted
                                      modalOperationDone:(PEModalOperationDone)modalOperationDone
                             entityAddedNotificationName:(NSString *)entityAddedNotificationName
                                      addlContentSection:(PEAddlContentSection)addlContentSection;

+ (PEAddViewEditController *)viewEntityCtrlrWithParentEntity:(PELMMainSupport *)parentEntity
                                                      entity:(PELMMainSupport *)entity
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
                                      conflictResolvedEntity:(PEConflictResolvedEntity)conflictResolvedEntity
                                         itemChildrenCounter:(PEItemChildrenCounter)itemChildrenCounter
                                         itemChildrenMsgsBlk:(PEItemChildrenMsgsBlk)itemChildrenMsgsBlk
                                                 itemDeleter:(PEItemDeleter)itemDeleter
                                            itemLocalDeleter:(PEItemLocalDeleter)itemLocalDeleter
                                       modalOperationStarted:(PEModalOperationStarted)modalOperationStarted
                                          modalOperationDone:(PEModalOperationDone)modalOperationDone
                               entityUpdatedNotificationName:(NSString *)entityUpdatedNotificationName
                               entityRemovedNotificationName:(NSString *)entityRemovedNotificationName;

#pragma mark - Properties

@property (readonly, nonatomic) PELMMainSupport *parentEntity;

@property (readonly, nonatomic) PELMMainSupport *entity;

@property (readonly, nonatomic) PEUIToolkit *uitoolkit;

@property (readonly, nonatomic) PEEntityToPanelBinderBlk entityToPanelBinder;

@property (nonatomic) UIView *entityFormPanel;

@property (nonatomic) CGPoint scrollContentOffset;

@property (nonatomic) BOOL hasPoppedKeyboard;

#pragma mark - Reset Scroll Offset

- (void)resetScrollOffset;

#pragma mark - Helpers

- (UIView *)parentViewForAlerts;

@end
