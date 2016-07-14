//
//  PEAddViewEditController.m
//  PELocal-DataUI
//
//  Created by Evans, Paul on 9/30/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "PEAddViewEditController.h"
#import <PELocal-Data/PELMNotificationUtils.h>
#import <PEObjc-Commons/PEUIUtils.h>
#import <PEObjc-Commons/PEUtils.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <PEObjc-Commons/JGActionSheet.h>
#import "PEListViewController.h"

@interface PEAddViewEditController () <JGActionSheetDelegate>
@end

@implementation PEAddViewEditController {
  BOOL _isAdd;
  BOOL _isEdit;
  BOOL _isView;
  BOOL _isEditCanceled;
  NSIndexPath *_entityIndexPath;
  PEItemAddedBlk _itemAddedBlk;
  PEItemChangedBlk _itemChangedBlk;
  UIBarButtonItem *_backButton;
  PEEntityPanelMakerBlk _entityFormPanelMaker;
  PEEntityViewPanelMakerBlk _entityViewPanelMaker;
  PEPanelToEntityBinderBlk _panelToEntityBinder;
  NSString *_entityTitle;
  PEEnableDisablePanelBlk _panelEnablerDisabler;
  PEEntityEditPreparerBlk _entityEditPreparer;
  PEEntityEditCancelerBlk _entityEditCanceler;
  PEEntityMakerBlk _entityMaker;
  PESaveEntityBlk _entitySaver;
  PESaveNewEntityLocalBlk _newEntitySaverLocal;
  PESaveNewEntityImmediateSyncBlk _newEntitySaverImmediateSync;
  PEMarkAsDoneEditingLocalBlk _doneEditingEntityLocalSync;
  PEMarkAsDoneEditingImmediateSyncBlk _doneEditingEntityImmediateSync;
  PEPrepareUIForUserInteractionBlk _prepareUIForUserInteractionBlk;
  PEViewDidAppearBlk _viewDidAppearBlk;
  PEEntityValidatorBlk _entityValidator;
  PEEntityAddCancelerBlk _entityAddCanceler;
  PEEntitiesFromEntityBlk _entitiesFromEntity;
  id _newEntity;
  PELMMainSupport *_entityCopyBeforeEdit;
  MBProgressHUDMode _syncImmediateMBProgressHUDMode;
  PEIsLoggedInBlk _isUserLoggedIn;
  PEListViewController *_listViewController;
  UIBarButtonItem *_uploadBarButtonItem;
  UIBarButtonItem *_downloadBarButtonItem;
  UIBarButtonItem *_deleteBarButtonItem;
  PEUploaderBlk _uploader;
  PEIsAuthenticatedBlk _isAuthenticatedBlk;
  UIView *_entityViewPanel;
  PEMergeBlk _merge;
  PENumRemoteDepsNotLocal _numRemoteDepsNotLocal;
  PEDependencyFetcherBlk _fetchDependencies;
  PEDownloaderBlk _downloader;
  PEPostDownloaderSaver _postDownloadSaver;
  PEConflictResolveFields _conflictResolveFields;
  PEConflictResolvedEntity _conflictResolvedEntity;
  PEUpdateDepsPanel _updateDepsPanel;
  PEIsOfflineModeBlk _isOfflineMode;
  PEItemChildrenCounter _itemChildrenCounter;
  PEItemChildrenMsgsBlk _itemChildrenMsgsBlk;
  PEItemDeleter _itemDeleter;
  PEItemLocalDeleter _itemLocalDeleter;
  PEModalOperationStarted _modalOperationStarted;
  PEModalOperationDone _modalOperationDone;
  NSString *_entityAddedNotificationName;
  NSString *_entityUpdatedNotificationName;
  NSString *_entityRemovedNotificationName;
  PEAddlContentSection _addlContentSection;
}

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
        addlContentSection:(PEAddlContentSection)addlContentSection {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _listViewController = listViewController;
    _isAdd = isAdd;
    if (!isAdd) {
      _isEdit = [entity editInProgress];
      _isView = !_isEdit;
    }
    _parentEntity = parentEntity;
    _entity = entity;
    _entityIndexPath = indexPath;
    _uitoolkit = uitoolkit;
    _itemAddedBlk = itemAddedBlk;
    _itemChangedBlk = itemChangedBlk;
    _entityFormPanelMaker = entityFormPanelMaker;
    _entityViewPanelMaker = entityViewPanelMaker;
    _entityToPanelBinder = entityToPanelBinder;
    _panelToEntityBinder = panelToEntityBinder;
    _entityTitle = entityTitle;
    _panelEnablerDisabler = panelEnablerDisabler;
    _entityAddCanceler = entityAddCanceler;
    _entityEditPreparer = entityEditPreparer;
    _entityEditCanceler = entityEditCanceler;
    _entityMaker = entityMaker;
    _entitySaver = entitySaver;
    _newEntitySaverLocal = newEntitySaverLocal;
    _newEntitySaverImmediateSync = newEntitySaverImmediateSync;
    _doneEditingEntityLocalSync = doneEditingEntityLocal;
    _doneEditingEntityImmediateSync = doneEditingEntityImmediateSync;
    _isUserLoggedIn = isUserLoggedIn;
    _isOfflineMode = isOfflineMode;
    _syncImmediateMBProgressHUDMode = syncImmediateMBProgressHUDMode;
    _isAuthenticatedBlk = isAuthenticated;
    _prepareUIForUserInteractionBlk = prepareUIForUserInteractionBlk;
    _viewDidAppearBlk = viewDidAppearBlk;
    _entityValidator = entityValidator;
    _uploader = uploader;
    _numRemoteDepsNotLocal = numRemoteDepsNotLocal;
    _merge = merge;
    _fetchDependencies = fetchDependencies;
    _updateDepsPanel = updateDepsPanel;
    _downloader = downloader;
    _postDownloadSaver = postDownloadSaver;
    _conflictResolveFields = conflictResolveFields;
    _conflictResolvedEntity = conflictResolvedEntity;
    _itemChildrenCounter = itemChildrenCounter;
    _itemChildrenMsgsBlk = itemChildrenMsgsBlk;
    _itemDeleter = itemDeleter;
    _itemLocalDeleter = itemLocalDeleter;
    _entitiesFromEntity = entitiesFromEntity;
    _modalOperationStarted = modalOperationStarted;
    _modalOperationDone = modalOperationDone;
    _entityAddedNotificationName = entityAddedNotificationName;
    _entityUpdatedNotificationName = entityUpdatedNotificationName;
    _entityRemovedNotificationName = entityRemovedNotificationName;
    _addlContentSection = addlContentSection;
    _scrollContentOffset = CGPointMake(0.0, 0.0);
    _hasPoppedKeyboard = NO;
  }
  return self;
}

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
                                      addlContentSection:(PEAddlContentSection)addlContentSection {
  return [PEAddViewEditController addEntityCtrlrWithUitoolkit:uitoolkit
                                           listViewController:listViewController
                                                 itemAddedBlk:itemAddedBlk
                                         entityFormPanelMaker:entityFormPanelMaker
                                          entityToPanelBinder:entityToPanelBinder
                                          panelToEntityBinder:panelToEntityBinder
                                                  entityTitle:entityTitle
                                            entityAddCanceler:entityAddCanceler
                                                  entityMaker:entityMaker
                                          newEntitySaverLocal:newEntitySaverLocal
                                  newEntitySaverImmediateSync:newEntitySaverImmediateSync
                               prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                             viewDidAppearBlk:viewDidAppearBlk
                                              entityValidator:entityValidator
                                              isAuthenticated:isAuthenticated
                                               isUserLoggedIn:isUserLoggedIn
                                                isOfflineMode:isOfflineMode
                               syncImmediateMBProgressHUDMode:syncImmediateMBProgressHUDMode
                                           entitiesFromEntity:nil
                                        modalOperationStarted:modalOperationStarted
                                           modalOperationDone:modalOperationDone
                                  entityAddedNotificationName:entityAddedNotificationName
                                           addlContentSection:addlContentSection];
}

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
                                      addlContentSection:(PEAddlContentSection)addlContentSection {
  return [[PEAddViewEditController alloc] initWithParentEntity:nil
                                                        entity:nil
                                            listViewController:listViewController
                                                         isAdd:YES
                                                     indexPath:nil
                                                     uitoolkit:uitoolkit
                                                  itemAddedBlk:itemAddedBlk
                                                itemChangedBlk:nil
                                          entityFormPanelMaker:entityFormPanelMaker
                                          entityViewPanelMaker:nil
                                           entityToPanelBinder:entityToPanelBinder
                                           panelToEntityBinder:panelToEntityBinder
                                                   entityTitle:entityTitle
                                          panelEnablerDisabler:nil
                                             entityAddCanceler:entityAddCanceler
                                            entityEditPreparer:nil
                                            entityEditCanceler:nil
                                                   entityMaker:entityMaker
                                                   entitySaver:nil
                                           newEntitySaverLocal:newEntitySaverLocal
                                   newEntitySaverImmediateSync:newEntitySaverImmediateSync
                                        doneEditingEntityLocal:nil
                                doneEditingEntityImmediateSync:nil
                                               isAuthenticated:isAuthenticated
                                                isUserLoggedIn:isUserLoggedIn
                                                 isOfflineMode:isOfflineMode
                                syncImmediateMBProgressHUDMode:syncImmediateMBProgressHUDMode
                                prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                              viewDidAppearBlk:viewDidAppearBlk
                                               entityValidator:entityValidator
                                                      uploader:nil
                                         numRemoteDepsNotLocal:nil
                                                         merge:nil
                                             fetchDependencies:nil
                                               updateDepsPanel:nil
                                                    downloader:nil
                                             postDownloadSaver:nil
                                         conflictResolveFields:nil
                                        conflictResolvedEntity:nil
                                           itemChildrenCounter:nil
                                           itemChildrenMsgsBlk:nil
                                                   itemDeleter:nil
                                              itemLocalDeleter:nil
                                            entitiesFromEntity:entitiesFromEntity
                                         modalOperationStarted:modalOperationStarted
                                            modalOperationDone:modalOperationDone
                                   entityAddedNotificationName:entityAddedNotificationName
                                 entityUpdatedNotificationName:nil
                                 entityRemovedNotificationName:nil
                                            addlContentSection:addlContentSection];
}

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
                               entityRemovedNotificationName:(NSString *)entityRemovedNotificationName {
  return [[PEAddViewEditController alloc] initWithParentEntity:parentEntity
                                                        entity:entity
                                            listViewController:listViewController
                                                         isAdd:NO
                                                     indexPath:entityIndexPath
                                                     uitoolkit:uitoolkit
                                                  itemAddedBlk:nil
                                                itemChangedBlk:itemChangedBlk
                                          entityFormPanelMaker:entityFormPanelMaker
                                          entityViewPanelMaker:entityViewPanelMaker
                                           entityToPanelBinder:entityToPanelBinder
                                           panelToEntityBinder:panelToEntityBinder
                                                   entityTitle:entityTitle
                                          panelEnablerDisabler:panelEnablerDisabler
                                             entityAddCanceler:entityAddCanceler
                                            entityEditPreparer:entityEditPreparer
                                            entityEditCanceler:entityEditCanceler
                                                   entityMaker:nil
                                                   entitySaver:entitySaver
                                           newEntitySaverLocal:nil
                                   newEntitySaverImmediateSync:nil
                                        doneEditingEntityLocal:doneEditingEntityLocal
                                doneEditingEntityImmediateSync:doneEditingEntityImmediateSync
                                               isAuthenticated:isAuthenticated
                                                isUserLoggedIn:isUserLoggedIn
                                                 isOfflineMode:isOfflineMode
                                syncImmediateMBProgressHUDMode:syncImmediateMBProgressHUDMode
                                prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                              viewDidAppearBlk:viewDidAppearBlk
                                               entityValidator:entityValidator
                                                      uploader:uploader
                                         numRemoteDepsNotLocal:numRemoteDepsNotLocal
                                                         merge:merge
                                             fetchDependencies:fetchDependencies
                                               updateDepsPanel:updateDepsPanel
                                                    downloader:downloader
                                             postDownloadSaver:postDownloadSaver
                                         conflictResolveFields:conflictResolveFields
                                        conflictResolvedEntity:conflictResolvedEntity
                                           itemChildrenCounter:itemChildrenCounter
                                           itemChildrenMsgsBlk:itemChildrenMsgsBlk
                                                   itemDeleter:itemDeleter
                                              itemLocalDeleter:itemLocalDeleter
                                            entitiesFromEntity:nil
                                         modalOperationStarted:modalOperationStarted
                                            modalOperationDone:modalOperationDone
                                   entityAddedNotificationName:nil
                                 entityUpdatedNotificationName:entityUpdatedNotificationName
                                 entityRemovedNotificationName:entityRemovedNotificationName
                                            addlContentSection:nil];
}

#pragma mark - Scroll View Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  _scrollContentOffset = [scrollView contentOffset];
}

#pragma mark - Reset Scroll Offset

- (void)resetScrollOffset {
  _scrollContentOffset = CGPointMake(0.0, 0.0);
}

#pragma mark - Dynamic Type notification

- (void)changeTextSize:(NSNotification *)notification {
  [self viewDidAppear:YES];
}

#pragma mark - Hide Keyboard

- (void)hideKeyboard {
  [self.view endEditing:YES];
}

#pragma mark - View Controller Lifecyle

- (void)viewWillDisappear:(BOOL)animated {
  if ([_entity editInProgress]) {
    _panelToEntityBinder(_entityFormPanel, _entity);
    _entitySaver(self, _entity);
  }
  [self.view endEditing:NO];
  [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  if (_isEdit) {
    _panelToEntityBinder(_entityFormPanel, _entity);
    UIView *tmpNewFormPanel = _entityFormPanelMaker(self);
    [_entityFormPanel removeFromSuperview];
    _entityFormPanel = tmpNewFormPanel;
    [PEUIUtils placeView:_entityFormPanel atTopOf:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
    _entityToPanelBinder(_entity, _entityFormPanel);
    if (_prepareUIForUserInteractionBlk) {
      _prepareUIForUserInteractionBlk(self, _entityFormPanel);
    }
  } else if (_isAdd) {
    id tmpEntity = _entityMaker(_entityFormPanel);
    UIView *tmpNewFormPanel = _entityFormPanelMaker(self);
    [_entityFormPanel removeFromSuperview];
    _entityFormPanel = tmpNewFormPanel;
    [PEUIUtils placeView:_entityFormPanel atTopOf:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
    _entityToPanelBinder(tmpEntity, _entityFormPanel);
    if (_prepareUIForUserInteractionBlk) {
      _prepareUIForUserInteractionBlk(self, _entityFormPanel);
    }
  } else {
    [_entityViewPanel removeFromSuperview];
    _entityViewPanel = _entityViewPanelMaker(self, _parentEntity, _entity);
    [PEUIUtils placeView:_entityViewPanel atTopOf:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
  }
  if (_viewDidAppearBlk) {
    _viewDidAppearBlk(self);
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeTextSize:)
                                               name:UIContentSizeCategoryDidChangeNotification
                                             object:nil];
  UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
  [gestureRecognizer setCancelsTouchesInView:NO];
  [self.view addGestureRecognizer:gestureRecognizer];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  UINavigationItem *navItem = [self navigationItem];
  _backButton = [navItem leftBarButtonItem];
  [self setEdgesForExtendedLayout:UIRectEdgeNone];
  [self setAutomaticallyAdjustsScrollViewInsets:NO];
  _entityFormPanel = _entityFormPanelMaker(self);
  if (_entityViewPanelMaker) {
    _entityViewPanel = _entityViewPanelMaker(self, _parentEntity, _entity);
  }
  void (^placeAndBindEntityPanel)(UIView *, BOOL) = ^(UIView *entityPanel, BOOL doBind) {
    [PEUIUtils placeView:entityPanel
                 atTopOf:[self view]
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0
                hpadding:0];
    if (doBind) {
      _entityToPanelBinder(_entity, entityPanel);
    }
  };
  NSString *title;
  if (_isView) {
    placeAndBindEntityPanel(_entityViewPanel, NO);
    title = _entityTitle;
  } else if (_isEdit) {
    placeAndBindEntityPanel(_entityFormPanel, YES);
    title = [NSString stringWithFormat:@"Edit %@", _entityTitle];
    [self prepareForEditing];
  } else {
    placeAndBindEntityPanel(_entityFormPanel, YES);
    title = [NSString stringWithFormat:@"Add %@", _entityTitle];
  }

  // ---------------------------------------------------------------------------
  // Setup the navigation item (left/center/right areas)
  // ---------------------------------------------------------------------------
  NSMutableArray *rightBarButtonItems = [NSMutableArray array];
  UIBarButtonItem *(^newSysItem)(UIBarButtonSystemItem, SEL) = ^ UIBarButtonItem *(UIBarButtonSystemItem item, SEL selector) {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:item target:self action:selector];
  };
  UIBarButtonItem *(^newImgItem)(NSString *, SEL) = ^ UIBarButtonItem * (NSString *imgName, SEL selector) {
    UIBarButtonItem *item =
      [[UIBarButtonItem alloc] initWithTitle:nil style:UIBarButtonItemStylePlain target:self action:selector];
    [item setImage:[UIImage imageNamed:imgName]];
    return item;
  };
  if (_isView) {
    [rightBarButtonItems addObject:[self editButtonItem]];
  } else {
    [navItem setLeftBarButtonItem:newSysItem(UIBarButtonSystemItemCancel, @selector(cancelAddEdit))];
    if (_isAdd) {
      [navItem setTitleView:[self titleWithText:title]]; // title only fits on adds
      [rightBarButtonItems addObject:newSysItem(UIBarButtonSystemItemDone, @selector(doneWithAdd))];
    } else {
      [rightBarButtonItems addObject:newSysItem(UIBarButtonSystemItemDone, @selector(doneWithEdit))];
    }
  }
  if (_isUserLoggedIn()) {
    _uploadBarButtonItem = newImgItem(@"upload-icon", @selector(doUpload));
    _downloadBarButtonItem = newImgItem(@"download-icon", @selector(doDownload));
    if (_uploader) { [rightBarButtonItems addObject:_uploadBarButtonItem]; }
    if (_downloader) { [rightBarButtonItems addObject:_downloadBarButtonItem]; }
  }
  if (_itemDeleter) {
    _deleteBarButtonItem = newImgItem(@"delete-icon", @selector(promptDoDelete));
    [rightBarButtonItems addObject:_deleteBarButtonItem];
  }
  [navItem setRightBarButtonItems:rightBarButtonItems animated:YES];
  [self setUploadDownloadDeleteBarButtonStates];
}

#pragma mark - JGActionSheetDelegate and Alert-related Helpers

- (void)actionSheetWillPresent:(JGActionSheet *)actionSheet {}

- (void)actionSheetDidPresent:(JGActionSheet *)actionSheet {}

- (void)actionSheetWillDismiss:(JGActionSheet *)actionSheet {}

- (void)actionSheetDidDismiss:(JGActionSheet *)actionSheet {}

- (JGActionSheetSection *)becameUnauthenticatedSection {
  NSAttributedString *attrBecameUnauthMessage =
  [PEUIUtils attributedTextWithTemplate:@"It appears you're no longer authenticated.  To re-authenticate, go to:\n\n%@."
                           textToAccent:@"Account \u2794 Re-authenticate"
                         accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]];
  return [PEUIUtils warningAlertSectionWithMsgs:nil
                                          title:@"Authentication failure."
                               alertDescription:attrBecameUnauthMessage
                                 relativeToView:[self parentViewForAlerts]];
}

#pragma mark - Uploading and Downloading (Sync)

- (void)setUploadDownloadDeleteBarButtonStates {
  [self setUploadBarButtonState];
  [self setDownloadBarButtonState];
  [self setDeleteBarButtonState];
}

- (void)setUploadBarButtonState {
  BOOL enableUploadItem = NO;
  if (_entity) {
    if (_uploader &&
        _isAuthenticatedBlk() &&
        [_entity localMainIdentifier] &&
        ![_entity synced] &&
        ![_entity editInProgress] &&
        !([_entity syncErrMask] && ([_entity syncErrMask].integerValue > 0))) {
      enableUploadItem = YES;
    }
  }
  [_uploadBarButtonItem setEnabled:enableUploadItem];
}

- (void)setDownloadBarButtonState {
  BOOL enableDownloadItem = NO;
  if (_entity) {
    if (_isAuthenticatedBlk() &&
        ([_entity synced] ||
         ([_entity localMainIdentifier] == nil) ||
         ([_entity editCount] == 0))) {
      enableDownloadItem = YES;
    }
  }
  [_downloadBarButtonItem setEnabled:enableDownloadItem];
}

- (void)setDeleteBarButtonState {
  BOOL enableDeleteItem = NO;
  if (_entity) {
    if (_isUserLoggedIn()) {
      if (_isAuthenticatedBlk() && YES // I can't remember why I put those below conditions in-place for enabling the delete icon
          /*([_entity synced] ||
           ([PEUtils isNil:[_entity localMainIdentifier]]) ||
           ([_entity editCount] == 0) ||
           ([PEUtils isNil:[_entity globalIdentifier]]))*/) {
        enableDeleteItem = YES;
      }
    } else {
      if (![_entity editInProgress]) {
        enableDeleteItem = YES;
      }
    }
  }
  [_deleteBarButtonItem setEnabled:enableDeleteItem];
}

- (void)promptDoDelete {
  [self.view endEditing:YES];
  void (^deleter)(void) = ^{
    [PEUIUtils showConfirmAlertWithTitle:@"Are you sure?"
                              titleImage:nil //[PEUIUtils bundleImageWithName:@"question"]
                        alertDescription:[[NSAttributedString alloc] initWithString:@"Are you sure you want to delete this record?"]
                                topInset:[PEUIUtils topInsetForAlertsWithController:self]
                         okayButtonTitle:@"Yes.  Delete it."
                        okayButtonAction:^{ [self doDelete]; }
                         okayButtonStyle:JGActionSheetButtonStyleRed
                       cancelButtonTitle:@"No.  Cancel."
                      cancelButtonAction:^{}
                        cancelButtonSyle:JGActionSheetButtonStyleDefault
                          relativeToView:[self parentViewForAlerts]];
  };
  if (_itemChildrenCounter) {
    NSInteger numChildren = _itemChildrenCounter(_entity);
    if (numChildren > 0) {
      [PEUIUtils showWarningConfirmAlertWithMsgs:_itemChildrenMsgsBlk(_entity)
                                           title:@"Are you sure?"
                                alertDescription:[[NSAttributedString alloc] initWithString:@"\
Deleting this record will result in the \
following child-records being deleted.\n\n\
Are you sure you want to continue?"]
                                        topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                 okayButtonTitle:@"Yes, delete."
                                okayButtonAction:^{ [self doDelete]; }
                               cancelButtonTitle:@"No, cancel."
                              cancelButtonAction:^{}
                                  relativeToView:[self parentViewForAlerts]];
    } else {
      deleter();
    }
  } else {
    deleter();
  }
}

- (void)doDelete {
  NSMutableArray *errorsForDelete = [NSMutableArray array];
  // The meaning of the elements of the arrays found within errorsForDelete:
  //
  // errorsForDelete[*][0]: Error title (string)
  // errorsForDelete[*][1]: Is error user-fixable (bool)
  // errorsForDelete[*][2]: An NSArray of sub-error messages (strings)
  // errorsForDelete[*][3]: Is error type server busy (bool)
  // errorsForDelete[*][4]: Is error conflict-type (bool)
  // errorsForDelete[*][5]: Latest entity for conflict error
  // errorsForDelete[*][6]: Entity not found (bool)
  //
  NSMutableArray *successMessageTitlesForDelete = [NSMutableArray array];
  __block BOOL receivedAuthReqdErrorOnDeleteAttempt = NO;
  if ([_entity globalIdentifier]) {
    __block MBProgressHUD *deleteHud;
    [self disableUi];
    void(^immediateDelDone)(NSString *) = ^(NSString *mainMsgTitle) {
      if ([errorsForDelete count] == 0) { // success
        dispatch_async(dispatch_get_main_queue(), ^{
          [[NSNotificationCenter defaultCenter] postNotificationName:_entityRemovedNotificationName
                                                              object:_entity
                                                            userInfo:nil];
          [deleteHud setLabelText:successMessageTitlesForDelete[0]];
          UIImage *image = [UIImage imageNamed:@"hud-complete"];
          UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
          [deleteHud setCustomView:imageView];
          deleteHud.mode = MBProgressHUDModeCustomView;
          [deleteHud hide:YES afterDelay:1.0];
          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if (_modalOperationDone) { _modalOperationDone(); }
            [[self navigationController] popViewControllerAnimated:YES];
          });
        });
      } else { // error
        dispatch_async(dispatch_get_main_queue(), ^{
          [deleteHud hide:YES afterDelay:0];          
          if ([errorsForDelete[0][4] boolValue]) { // conflict error
            id latestEntity = errorsForDelete[0][5];
            [PEUIUtils showDeleteConflictAlertWithTitle:@"Conflict"
                                       alertDescription:[[NSAttributedString alloc] initWithString:@"\
The remote copy of this record has been updated since you last downloaded it."]
                                               topInset:[PEUIUtils topInsetForAlertsWithController:self]
                            forceDeleteLocalButtonTitle:@"I don't care.  Delete it anyway."
                                forceDeleteButtonAction:^{
                                  [_entity setUpdatedAt:[latestEntity updatedAt]];
                                  [self doDelete];
                                }
                                      cancelButtonTitle:@"Cancel."
                                     cancelButtonAction:^{ [self enableUi]; }
                                         relativeToView:[self parentViewForAlerts]];
          } else if ([errorsForDelete[0][3] boolValue]) { // server is busy
            [self handleServerBusyErrorWithAction:^{ [self enableUi]; }];
          } else if ([errorsForDelete[0][6] boolValue]) { // not found
            [PEUIUtils showInfoAlertWithTitle:@"Already deleted."
                             alertDescription:[[NSAttributedString alloc] initWithString:@"\
It looks like this record was already deleted from a different device. \
It has now been removed from this device."]
                                     topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                  buttonTitle:@"Okay."
                                 buttonAction:^{
                                   _itemLocalDeleter(self, _entity, _entityIndexPath);
                                   [[NSNotificationCenter defaultCenter] postNotificationName:_entityRemovedNotificationName
                                                                                       object:_entity
                                                                                     userInfo:nil];
                                   if (_modalOperationDone) { _modalOperationDone(); }
                                   [[self navigationController] popViewControllerAnimated:YES];
                                 }
                               relativeToView:[self parentViewForAlerts]];
          } else { // any other error type
            NSString *title;
            NSString *message;
            NSArray *subErrors = errorsForDelete[0][2];
            if ([subErrors count] > 1) {
              message = @"There were problems deleting your record from the server.  The errors are as follows:";
              title = [NSString stringWithFormat:@"Errors %@.", mainMsgTitle];
            } else {
              message = @"There was a problem deleting your record from the server.  The error is as follows:";
              title = [NSString stringWithFormat:@"Error %@.", mainMsgTitle];
            }
            NSMutableArray *sections = [NSMutableArray array];
            if (receivedAuthReqdErrorOnDeleteAttempt) {
              [sections addObject:[self becameUnauthenticatedSection]];
            }
            [sections addObject:[PEUIUtils errorAlertSectionWithMsgs:subErrors
                                                               title:title
                                                    alertDescription:[[NSAttributedString alloc] initWithString:message]
                                                      relativeToView:[self parentViewForAlerts]]];
            JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                                  message:nil
                                                                             buttonTitles:@[@"Okay."]
                                                                              buttonStyle:JGActionSheetButtonStyleDefault];
            [buttonsSection setButtonStyle:JGActionSheetButtonStyleRed forButtonAtIndex:0];
            [sections addObject:buttonsSection];
            JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:sections];
            [alertSheet setDelegate:self];
            [alertSheet setInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
            [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *btnIndexPath) {
              [self enableUi];
              [sheet dismissAnimated:YES];
            }];
            [alertSheet showInView:self.view animated:YES];
          }
        });
      }
    };
    void(^delNotFoundBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                             NSString *mainMsgTitle,
                                                             NSString *recordTitle) {
      [errorsForDelete addObject:@[[NSString stringWithFormat:@"%@ not deleted.", recordTitle],
                                   [NSNumber numberWithBool:NO],
                                   @[[NSString stringWithFormat:@"Not found."]],
                                   [NSNumber numberWithBool:NO],
                                   [NSNumber numberWithBool:NO],
                                   [NSNull null],
                                   [NSNumber numberWithBool:YES]]];
      immediateDelDone(mainMsgTitle);
    };
    void(^delSuccessBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                            NSString *mainMsgTitle,
                                                            NSString *recordTitle) {
      [successMessageTitlesForDelete addObject:[NSString stringWithFormat:@"%@ deleted.", recordTitle]];
      immediateDelDone(mainMsgTitle);
    };
    void(^delRetryAfterBlk)(float, NSString *, NSString *, NSDate *) = ^(float percentComplete,
                                                                         NSString *mainMsgTitle,
                                                                         NSString *recordTitle,
                                                                         NSDate *retryAfter) {
      [errorsForDelete addObject:@[[NSString stringWithFormat:@"%@ not deleted.", recordTitle],
                                   [NSNumber numberWithBool:NO],
                                   @[[NSString stringWithFormat:@"Server undergoing maintnenace.  Try again later."]],
                                   [NSNumber numberWithBool:YES],
                                   [NSNumber numberWithBool:NO],
                                   [NSNull null],
                                   [NSNumber numberWithBool:NO]]];
      immediateDelDone(mainMsgTitle);
    };
    void (^delServerTempError)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                  NSString *mainMsgTitle,
                                                                  NSString *recordTitle) {
      [errorsForDelete addObject:@[[NSString stringWithFormat:@"%@ not deleted.", recordTitle],
                                   [NSNumber numberWithBool:NO],
                                   @[@"Temporary server error."],
                                   [NSNumber numberWithBool:NO],
                                   [NSNumber numberWithBool:NO],
                                   [NSNull null],
                                   [NSNumber numberWithBool:NO]]];
      immediateDelDone(mainMsgTitle);
    };
    void (^delServerError)(float, NSString *, NSString *, NSArray *) = ^(float percentComplete,
                                                                         NSString *mainMsgTitle,
                                                                         NSString *recordTitle,
                                                                         NSArray *computedErrMsgs) {
      BOOL isErrorUserFixable = YES;
      if (!computedErrMsgs || ([computedErrMsgs count] == 0)) {
        computedErrMsgs = @[@"Unknown server error."];
        isErrorUserFixable = NO;
      }
      [errorsForDelete addObject:@[[NSString stringWithFormat:@"%@ not deleted.", recordTitle],
                                   [NSNumber numberWithBool:isErrorUserFixable],
                                   computedErrMsgs,
                                   [NSNumber numberWithBool:NO],
                                   [NSNumber numberWithBool:NO],
                                   [NSNull null],
                                   [NSNumber numberWithBool:NO]]];
      immediateDelDone(mainMsgTitle);
    };
    void(^delConflictBlk)(float, NSString *, NSString *, id) = ^(float percentComplete,
                                                                 NSString *mainMsgTitle,
                                                                 NSString *recordTitle,
                                                                 id latestEntity) {
      [errorsForDelete addObject:@[[NSString stringWithFormat:@"%@ not deleted.", recordTitle],
                                   [NSNumber numberWithBool:NO],
                                   @[[NSString stringWithFormat:@"Conflict."]],
                                   [NSNumber numberWithBool:NO],
                                   [NSNumber numberWithBool:YES],
                                   latestEntity,
                                   [NSNumber numberWithBool:NO]]];
      immediateDelDone(mainMsgTitle);
    };
    void(^delAuthReqdBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                             NSString *mainMsgTitle,
                                                             NSString *recordTitle) {
      receivedAuthReqdErrorOnDeleteAttempt = YES;
      [errorsForDelete addObject:@[[NSString stringWithFormat:@"%@ not deleted.", recordTitle],
                                   [NSNumber numberWithBool:NO],
                                   @[@"Authentication required."],
                                   [NSNumber numberWithBool:NO],
                                   [NSNumber numberWithBool:NO],
                                   [NSNull null],
                                   [NSNumber numberWithBool:NO]]];
      immediateDelDone(mainMsgTitle);
    };
    void (^deleteRemoteItem)(void) = ^{
      deleteHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      deleteHud.delegate = self;
      deleteHud.labelText = @"Deleting from server...";
      [errorsForDelete removeAllObjects];
      [successMessageTitlesForDelete removeAllObjects];
      receivedAuthReqdErrorOnDeleteAttempt = NO;
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        _itemDeleter(self,
                     _entity,
                     _entityIndexPath,
                     delNotFoundBlk,
                     delSuccessBlk,
                     delRetryAfterBlk,
                     delServerTempError,
                     delServerError,
                     delConflictBlk,
                     delAuthReqdBlk);
      });
    };
    deleteRemoteItem();
   } else {
    _itemLocalDeleter(self, _entity, _entityIndexPath);
    dispatch_async(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter] postNotificationName:_entityRemovedNotificationName
                                                          object:_entity
                                                        userInfo:nil];
      if (_modalOperationDone) { _modalOperationDone(); }
      [[self navigationController] popViewControllerAnimated:YES];
    });
  }
}

- (void)doDownload {
  __block BOOL receivedAuthReqdErrorOnDownloadAttempt = NO;
  __block CGFloat percentCompleteDownloadingEntity = 0.0;
  NSMutableArray *successMsgsForEntityDownload = [NSMutableArray array];
  NSMutableArray *errsForEntityDownload = [NSMutableArray array];
  // The meaning of the elements of the arrays found within errsForEntityDownload:
  //
  // errsForEntityDownload[*][0]: Error title (string)
  // errsForEntityDownload[*][1]: Is error user-fixable (bool)
  // errsForEntityDownload[*][2]: An NSArray of sub-error messages (strings)
  // errsForEntityDownload[*][3]: Is error type server-busy? (bool)
  // errsForEntityDownload[*][4]: Is entity not found (bool)
  //
  MBProgressHUD *downloadHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  [self disableUi];
  [downloadHud setLabelText:[NSString stringWithFormat:@"Downloading latest..."]];
  void (^handleHudProgress)(float) = ^(float percentComplete) {
    percentCompleteDownloadingEntity += percentComplete;
    dispatch_async(dispatch_get_main_queue(), ^{
      downloadHud.progress = percentCompleteDownloadingEntity;
    });
  };
  void (^postDownloadActivities)(void) = ^{
    if (_itemChangedBlk) {
      _itemChangedBlk(_entity, _entityIndexPath);
    }
    [self enableUi];
    [[NSNotificationCenter defaultCenter] postNotificationName:_entityUpdatedNotificationName
                                                        object:_entity
                                                      userInfo:nil];
    [_entityViewPanel removeFromSuperview];
    _entityViewPanel = _entityViewPanelMaker(self, _parentEntity, _entity);
    [PEUIUtils placeView:_entityViewPanel
                 atTopOf:[self view]
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0
                hpadding:0];
  };
  void(^entityDownloadDone)(NSString *) = ^(NSString *mainMsgTitle) {
    if ([errsForEntityDownload count] == 0) { // success
      dispatch_async(dispatch_get_main_queue(), ^{
        [downloadHud hide:YES afterDelay:0.0];
        id downloadedEntity = successMsgsForEntityDownload[0][1];
        if ([downloadedEntity isEqual:[NSNull null]]) {
          [PEUIUtils showInfoAlertWithTitle:@"You already have the latest."
                           alertDescription:[[NSAttributedString alloc] initWithString:@"\
You already have the latest version of this record on your device."]
                                   topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                buttonTitle:@"Okay."
                               buttonAction:^{ [self enableUi]; }
                             relativeToView:[self parentViewForAlerts]];
        } else {
          void (^fetchDepsThenTakeAction)(void(^)(void)) = [self downloadDepsForEntity:downloadedEntity
                                                             dismissErrAlertPostAction:^{ [self enableUi]; }];
          fetchDepsThenTakeAction(^{
            // If we're here, it means the entity was downloaded, and if it had any
            // dependencies, they were also successfully downloaded (if they *needed*
            // to be downloaded).  Also, this block executes on the main thread.
            [PEUIUtils showSuccessAlertWithTitle:[NSString stringWithFormat:@"%@ downloaded.", _entityTitle]
                                alertDescription:[[NSAttributedString alloc] initWithString:@"\
The latest version of this record has been successfully downloaded to your device."]
                                        topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                     buttonTitle:@"Okay."
                                    buttonAction:^{
                                      [_entity setUpdatedAt:[downloadedEntity updatedAt]];
                                      [_entity overwriteDomainProperties:downloadedEntity];
                                      _postDownloadSaver(self, downloadedEntity, _entity);
                                      postDownloadActivities();
                                    }
                                  relativeToView:[self parentViewForAlerts]];
          });
        }
      });
    } else { // error(s)
      dispatch_async(dispatch_get_main_queue(), ^{
        [downloadHud hide:YES afterDelay:0.0];
        if ([errsForEntityDownload[0][3] boolValue]) { // server busy
          [self handleServerBusyErrorWithAction:^{ [self enableUi]; }];
        } else if ([errsForEntityDownload[0][4] boolValue]) { // not found
          [self handleNotFoundError];
        } else { // any other error type
          NSString *fetchErrMsg = @"There was a problem downloading the record.";
          [PEUIUtils showErrorAlertWithMsgs:errsForEntityDownload[0][2]
                                      title:@"Download error."
                           alertDescription:[[NSAttributedString alloc] initWithString:fetchErrMsg]
                                   topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                buttonTitle:@"Okay."
                               buttonAction:^{ [self enableUi]; }
                             relativeToView:[self parentViewForAlerts]];
        }
      });
    }
  };
  void(^downloadNotFoundBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                NSString *mainMsgTitle,
                                                                NSString *recordTitle) {
    handleHudProgress(percentComplete);
    [errsForEntityDownload addObject:@[[NSString stringWithFormat:@"%@ not downloaded.", recordTitle],
                                       [NSNumber numberWithBool:NO],
                                       @[[NSString stringWithFormat:@"Not found."]],
                                       [NSNumber numberWithBool:NO],
                                       [NSNumber numberWithBool:YES]]];
    if (percentCompleteDownloadingEntity == 1.0) { entityDownloadDone(mainMsgTitle); }
  };
  PEDownloadSuccessBlk downloadSuccessBlk = ^(float percentComplete,
                                              NSString *mainMsgTitle,
                                              NSString *recordTitle,
                                              id downloadedEntity) {
    handleHudProgress(percentComplete);
    if (downloadedEntity == nil) { // server responded with 304
      downloadedEntity = [NSNull null];
    }
    [successMsgsForEntityDownload addObject:@[[NSString stringWithFormat:@"%@ downloaded.", recordTitle],
                                              downloadedEntity]];
    if (percentCompleteDownloadingEntity == 1.0) { entityDownloadDone(mainMsgTitle); }
  };
  void(^downloadRetryAfterBlk)(float, NSString *, NSString *, NSDate *) = ^(float percentComplete,
                                                                            NSString *mainMsgTitle,
                                                                            NSString *recordTitle,
                                                                            NSDate *retryAfter) {
    handleHudProgress(percentComplete);
    [errsForEntityDownload addObject:@[[NSString stringWithFormat:@"%@ not downloaded.", recordTitle],
                                       [NSNumber numberWithBool:NO],
                                       @[[NSString stringWithFormat:@"Server undergoing maintenance.  Try again later."]],
                                       [NSNumber numberWithBool:YES],
                                       [NSNumber numberWithBool:NO]]];
    if (percentCompleteDownloadingEntity == 1.0) { entityDownloadDone(mainMsgTitle); }
  };
  void (^downloadServerTempError)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                     NSString *mainMsgTitle,
                                                                     NSString *recordTitle) {
    handleHudProgress(percentComplete);
    [errsForEntityDownload addObject:@[[NSString stringWithFormat:@"%@ not downloaded.", recordTitle],
                                       [NSNumber numberWithBool:NO],
                                       @[@"Temporary server error."],
                                       [NSNumber numberWithBool:NO],
                                       [NSNumber numberWithBool:NO]]];
    if (percentCompleteDownloadingEntity == 1.0) { entityDownloadDone(mainMsgTitle); }
  };
  void(^downloadAuthReqdBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                NSString *mainMsgTitle,
                                                                NSString *recordTitle) {
    receivedAuthReqdErrorOnDownloadAttempt = YES;
    handleHudProgress(percentComplete);
    [errsForEntityDownload addObject:@[[NSString stringWithFormat:@"%@ not downloaded.", recordTitle],
                                       [NSNumber numberWithBool:NO],
                                       @[@"Authentication required."],
                                       [NSNumber numberWithBool:NO],
                                       [NSNumber numberWithBool:NO]]];
    if (percentCompleteDownloadingEntity == 1.0) { entityDownloadDone(mainMsgTitle); }
  };
  _downloader(self,
              _entity,
              downloadNotFoundBlk,
              downloadSuccessBlk,
              downloadRetryAfterBlk,
              downloadServerTempError,
              downloadAuthReqdBlk);
}

- (void)doUpload {
  void (^postUploadActivities)(void) = ^{
    if (_itemChangedBlk) {
      _itemChangedBlk(_entity, _entityIndexPath);
    }
    [self enableUi];
    _panelEnablerDisabler(_entityFormPanel, NO);
    [[NSNotificationCenter defaultCenter] postNotificationName:_entityUpdatedNotificationName
                                                        object:_entity
                                                      userInfo:nil];
  };
  MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  [self disableUi];
  HUD.delegate = self;
  HUD.mode = _syncImmediateMBProgressHUDMode;
  HUD.labelText = @"Uploading to server.";
  __block float percentCompleteUploadingEntity = 0.0;
  HUD.progress = percentCompleteUploadingEntity;
  NSMutableArray *errorsForUpload = [NSMutableArray array];
  // The meaning of the elements of the arrays found within errorsForUpload:
  //
  // errorsForUpload[*][0]: Error title (string)
  // errorsForUpload[*][1]: Is error user-fixable (bool)
  // errorsForUpload[*][2]: An NSArray of sub-error messages (strings)
  // errorsForUpload[*][3]: Is error type server busy (bool)
  // errorsForUpload[*][4]: Is error conflict-type (bool)
  // errorsForUpload[*][5]: Latest entity for conflict error
  // errorsForUpload[*][6]: Entity not found (bool)
  //
  NSMutableArray *successMessageTitlesForUpload = [NSMutableArray array];
  __block BOOL receivedAuthReqdErrorOnUploadAttempt = NO;
  void(^uploadDone)(NSString *) = ^(NSString *mainMsgTitle) {
    if ([errorsForUpload count] == 0) { // success
      dispatch_async(dispatch_get_main_queue(), ^{
        [HUD setLabelText:successMessageTitlesForUpload[0]];
        //[HUD setDetailsLabelText:@"(uploaded to the server)"];
        UIImage *image = [UIImage imageNamed:@"hud-complete"];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        [HUD setCustomView:imageView];
        HUD.mode = MBProgressHUDModeCustomView;
        [HUD hide:YES afterDelay:1.0];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
          postUploadActivities();
        });
      });
    } else { // error
      dispatch_async(dispatch_get_main_queue(), ^{
        [HUD hide:YES afterDelay:0];
        if ([errorsForUpload[0][4] boolValue]) { // conflict error
          id latestEntity = errorsForUpload[0][5];
          NSAttributedString *desc =
          [PEUIUtils attributedTextWithTemplate:@"The remote copy of this record has been \
updated since you started to edit it.  You have a few options:\n\nIf you cancel, %@."
                                   textToAccent:@"your local edits will be retained"
                                 accentTextFont:[PEUIUtils italicFontForTextStyle:UIFontTextStyleSubheadline]];
          [self presentSaveConflictAlertWithLatestEntity:latestEntity
                                        alertDescription:desc
                                            cancelAction:postUploadActivities];
        } else if ([errorsForUpload[0][3] boolValue]) { // server is busy
          [self handleServerBusyErrorWithAction:^{
            postUploadActivities();
          }];
        } else if ([errorsForUpload[0][6] boolValue]) { // not found
          [self handleNotFoundError];
        } else {  // any other error type
          NSString *title;
          NSString *okayActionTitle = @"Okay.  I'll try again later.";
          NSString *message;
          NSArray *subErrors = errorsForUpload[0][2];
          if ([subErrors count] > 1) {
            message = @"There were problems uploading to the server.  The errors are as follows:";
            title = [NSString stringWithFormat:@"Errors %@.", mainMsgTitle];
          } else {
            message = @"There was a problem uploading to the server.  The error is as follows:";
            title = [NSString stringWithFormat:@"Error %@.", mainMsgTitle];
          }
          JGActionSheetSection *becameUnauthSection = nil;
          if (receivedAuthReqdErrorOnUploadAttempt) {
            becameUnauthSection = [self becameUnauthenticatedSection];
          }
          JGActionSheetSection *contentSection = [PEUIUtils errorAlertSectionWithMsgs:subErrors
                                                                                title:title
                                                                     alertDescription:[[NSAttributedString alloc] initWithString:message]
                                                                       relativeToView:[self parentViewForAlerts]];
          JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                                message:nil
                                                                           buttonTitles:@[okayActionTitle]
                                                                            buttonStyle:JGActionSheetButtonStyleDefault];
          JGActionSheet *alertSheet;
          if (becameUnauthSection) {
            alertSheet = [JGActionSheet actionSheetWithSections:@[contentSection, becameUnauthSection, buttonsSection]];
          } else {
            alertSheet = [JGActionSheet actionSheetWithSections:@[contentSection, buttonsSection]];
          }
          [alertSheet setDelegate:self];
          [alertSheet setInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
          [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
            switch ([indexPath row]) {
              case 0: // okay
                postUploadActivities();
                [sheet dismissAnimated:YES];
                break;
            };}];
          [alertSheet showInView:[self view] animated:YES];
        }
      });
    }
  };
  void (^handleHudProgress)(float) = ^(float percentComplete) {
    percentCompleteUploadingEntity += percentComplete;
    dispatch_async(dispatch_get_main_queue(), ^{
      HUD.progress = percentCompleteUploadingEntity;
    });
  };
  void(^uploadNotFoundBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                              NSString *mainMsgTitle,
                                                              NSString *recordTitle) {
    handleHudProgress(percentComplete);
    [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                 [NSNumber numberWithBool:NO],
                                 @[[NSString stringWithFormat:@"Not found."]],
                                 [NSNumber numberWithBool:NO],
                                 [NSNumber numberWithBool:NO],
                                 [NSNull null],
                                 [NSNumber numberWithBool:YES]]];
    if (percentCompleteUploadingEntity == 1.0) {
      uploadDone(mainMsgTitle);
    }
  };
  void(^uploadSuccessBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                             NSString *mainMsgTitle,
                                                             NSString *recordTitle) {
    handleHudProgress(percentComplete);
    [successMessageTitlesForUpload addObject:[NSString stringWithFormat:@"%@ saved to the server.", recordTitle]];
    if (percentCompleteUploadingEntity == 1.0) {
      uploadDone(mainMsgTitle);
    }
  };
  void(^uploadRetryAfterBlk)(float, NSString *, NSString *, NSDate *) = ^(float percentComplete,
                                                                          NSString *mainMsgTitle,
                                                                          NSString *recordTitle,
                                                                          NSDate *retryAfter) {
    handleHudProgress(percentComplete);
    [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                 [NSNumber numberWithBool:NO],
                                 @[[NSString stringWithFormat:@"Server undergoing maintenance.  Try again later."]],
                                 [NSNumber numberWithBool:YES],
                                 [NSNumber numberWithBool:NO],
                                 [NSNull null],
                                 [NSNumber numberWithBool:NO]]];
    if (percentCompleteUploadingEntity == 1.0) {
      uploadDone(mainMsgTitle);
    }
  };
  void(^uploadServerTempError)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                  NSString *mainMsgTitle,
                                                                  NSString *recordTitle) {
    handleHudProgress(percentComplete);
    [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                 [NSNumber numberWithBool:NO],
                                 @[@"Temporary server error."],
                                 [NSNumber numberWithBool:NO],
                                 [NSNumber numberWithBool:NO],
                                 [NSNull null],
                                 [NSNumber numberWithBool:NO]]];
    if (percentCompleteUploadingEntity == 1.0) {
      uploadDone(mainMsgTitle);
    }
  };
  void(^uploadServerError)(float, NSString *, NSString *, NSArray *) = ^(float percentComplete,
                                                                         NSString *mainMsgTitle,
                                                                         NSString *recordTitle,
                                                                         NSArray *computedErrMsgs) {
    handleHudProgress(percentComplete);
    BOOL isErrorUserFixable = YES;
    if (!computedErrMsgs || ([computedErrMsgs count] == 0)) {
      computedErrMsgs = @[@"Unknown server error."];
      isErrorUserFixable = NO;
    }
    [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                 [NSNumber numberWithBool:isErrorUserFixable],
                                 computedErrMsgs,
                                 [NSNumber numberWithBool:NO],
                                 [NSNumber numberWithBool:NO],
                                 [NSNull null],
                                 [NSNumber numberWithBool:NO]]];
    if (percentCompleteUploadingEntity == 1.0) {
      uploadDone(mainMsgTitle);
    }
  };
  void(^uploadConflictBlk)(float, NSString *, NSString *, id) = ^(float percentComplete,
                                                                  NSString *mainMsgTitle,
                                                                  NSString *recordTitle,
                                                                  id latestEntity) {
    handleHudProgress(percentComplete);
    [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not uploaded.", recordTitle],
                                 [NSNumber numberWithBool:NO],
                                 @[[NSString stringWithFormat:@"Conflict."]],
                                 [NSNumber numberWithBool:NO],
                                 [NSNumber numberWithBool:YES],
                                 latestEntity,
                                 [NSNumber numberWithBool:NO]]];
    if (percentCompleteUploadingEntity == 1.0) {
      uploadDone(mainMsgTitle);
    }
  };
  void(^uploadAuthReqdBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                              NSString *mainMsgTitle,
                                                              NSString *recordTitle) {
    receivedAuthReqdErrorOnUploadAttempt = YES;
    handleHudProgress(percentComplete);
    [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not uploaded.", recordTitle],
                                 [NSNumber numberWithBool:NO],
                                 @[@"Authentication required."],
                                 [NSNumber numberWithBool:NO],
                                 [NSNumber numberWithBool:NO],
                                 [NSNull null],
                                 [NSNumber numberWithBool:NO]]];
    if (percentCompleteUploadingEntity == 1.0) {
      uploadDone(mainMsgTitle);
    }
  };
  void(^uploadDependencyUnsyncedBlk)(float, NSString *, NSString *, NSString *) = ^(float percentComplete,
                                                                                    NSString *mainMsgTitle,
                                                                                    NSString *recordTitle,
                                                                                    NSString *dependencyErrMsg) {
    handleHudProgress(percentComplete);
    [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not uploaded.", recordTitle],
                                 [NSNumber numberWithBool:NO],
                                 @[dependencyErrMsg],
                                 [NSNumber numberWithBool:NO],
                                 [NSNumber numberWithBool:NO],
                                 [NSNull null],
                                 [NSNumber numberWithBool:NO]]];
    if (percentCompleteUploadingEntity == 1.0) {
      uploadDone(mainMsgTitle);
    }
  };
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    _uploader(self,
              _entity,
              uploadNotFoundBlk,
              uploadSuccessBlk,
              uploadRetryAfterBlk,
              uploadServerTempError,
              uploadServerError,
              uploadConflictBlk,
              uploadAuthReqdBlk,
              uploadDependencyUnsyncedBlk);
  });
}

#pragma mark - Conflict, Not Found and other helpers

- (UIView *)parentViewForAlerts {
  if (self.tabBarController) {
    return self.tabBarController.view;
  }
  return self.view;
}

- (void)handleServerBusyErrorWithAction:(void(^)(void))action {
  [PEUIUtils showWaitAlertWithMsgs:nil
                             title:@"Busy with maintenance."
                  alertDescription:[[NSAttributedString alloc] initWithString:@"\
The server is currently busy at the moment \
undergoing maintenance.\n\n\
We apologize for the inconvenience.  Please \
try this operation again later."]
                          topInset:[PEUIUtils topInsetForAlertsWithController:self]
                       buttonTitle:@"Okay."
                      buttonAction:action
                    relativeToView:[self parentViewForAlerts]];
}

- (void)handleNotFoundError {
  NSString *fetchErrMsg = @"\
It would appear this record no longer \
exists and was probably deleted on \
a different device.\n\n\
To keep the data on your device consistent \
with your remote account, it will be removed now.";
  [PEUIUtils showErrorAlertWithMsgs:nil
                              title:@"Record not found."
                   alertDescription:[[NSAttributedString alloc] initWithString:fetchErrMsg]
                           topInset:[PEUIUtils topInsetForAlertsWithController:self]
                        buttonTitle:@"Okay."
                       buttonAction:^{
                         _itemLocalDeleter(self, _entity, _entityIndexPath);
                         [[NSNotificationCenter defaultCenter] postNotificationName:_entityRemovedNotificationName
                                                                             object:_entity
                                                                           userInfo:nil];
                         if (_modalOperationDone) { _modalOperationDone(); }
                         [[self navigationController] popViewControllerAnimated:YES];
                       }
                     relativeToView:[self parentViewForAlerts]];
}

- (void (^)(void(^)(void)))downloadDepsForEntity:(id)entity
                       dismissErrAlertPostAction:(void(^)(void))dismissErrAlertPostAction {
  __block BOOL receivedAuthReqdErrorOnDownloadDepsAttempt = NO;
  void (^fetchDepsThenTakeAction)(void(^)(void)) = ^(void(^postFetchAction)(void)) {
    if (_numRemoteDepsNotLocal) {
      NSInteger numDepsThatDontExistLocally = _numRemoteDepsNotLocal(entity);
      if (numDepsThatDontExistLocally == 0) {
        postFetchAction();
      } else {
        // Ugh.  This sucks. Okay, let's do this!
        __block float percentCompleteFetchingDeps = 0.0;
        NSMutableArray *successMsgsForDepsFetch = [NSMutableArray array];
        NSMutableArray *errsForDepsFetch = [NSMutableArray array];
        MBProgressHUD *depFetchHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [depFetchHud setLabelText:[NSString stringWithFormat:@"Downloading dependencies."]];
        void (^handleHudProgress)(float) = ^(float percentComplete) {
          percentCompleteFetchingDeps += percentComplete;
          dispatch_async(dispatch_get_main_queue(), ^{
            depFetchHud.progress = percentCompleteFetchingDeps;
          });
        };
        void(^depFetchDone)(NSString *) = ^(NSString *mainMsgTitle) {
          if ([errsForDepsFetch count] == 0) { // success
            dispatch_async(dispatch_get_main_queue(), ^{
              [depFetchHud setLabelText:@"Dependencies fetched."];
              [depFetchHud hide:YES afterDelay:1.0];
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                postFetchAction();
              });
            });
          } else { // error(s)
            dispatch_async(dispatch_get_main_queue(), ^{
              [depFetchHud hide:YES afterDelay:0];
              void (^dismissErrAlertAction)(void) = ^{
                _entityEditPreparer(self, _entity);
                [self setEditing:YES animated:YES];
                //reenableNavButtons();
                dismissErrAlertPostAction();
              };
              if ([errsForDepsFetch count] > 1) {
                NSString *fetchErrMsg = @"\
There were problems downloading this \
entity's dependencies.";
                [PEUIUtils showMultiErrorAlertWithFailures:errsForDepsFetch
                                                     title:@"Fetch errors."
                                          alertDescription:[[NSAttributedString alloc] initWithString:fetchErrMsg]
                                                  topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                               buttonTitle:@"Okay."
                                              buttonAction:^{
                                                dismissErrAlertAction();
                                              }
                                            relativeToView:[self parentViewForAlerts]];
              } else {
                NSString *fetchErrMsg = @"\
There was a problem downloading this \
entity's dependency.";
                [PEUIUtils showErrorAlertWithMsgs:errsForDepsFetch[0][2]
                                            title:@"Fetch error."
                                 alertDescription:[[NSAttributedString alloc] initWithString:fetchErrMsg]
                                         topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                      buttonTitle:@"Okay."
                                     buttonAction:^{
                                       dismissErrAlertAction();
                                     }
                                   relativeToView:[self parentViewForAlerts]];
              }
            });
          }
        };
        void(^depNotFoundBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                 NSString *mainMsgTitle,
                                                                 NSString *recordTitle) {
          handleHudProgress(percentComplete);
          [errsForDepsFetch addObject:@[[NSString stringWithFormat:@"%@ not fetched.", recordTitle],
                                        [NSNumber numberWithBool:NO],
                                        @[[NSString stringWithFormat:@"Not found."]],
                                        [NSNumber numberWithBool:NO]]];
          if (percentCompleteFetchingDeps == 1.0) { depFetchDone(mainMsgTitle); }
        };
        void(^depSuccessBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                NSString *mainMsgTitle,
                                                                NSString *recordTitle) {
          handleHudProgress(percentComplete);
          [successMsgsForDepsFetch addObject:[NSString stringWithFormat:@"%@ fetched.", recordTitle]];
          if (percentCompleteFetchingDeps == 1.0) { depFetchDone(mainMsgTitle); }
        };
        void(^depRetryAfterBlk)(float, NSString *, NSString *, NSDate *) = ^(float percentComplete,
                                                                             NSString *mainMsgTitle,
                                                                             NSString *recordTitle,
                                                                             NSDate *retryAfter) {
          handleHudProgress(percentComplete);
          [errsForDepsFetch addObject:@[[NSString stringWithFormat:@"%@ not fetched.", recordTitle],
                                        [NSNumber numberWithBool:NO],
                                        @[[NSString stringWithFormat:@"Server undergoing maintenance.  Try again later."]],
                                        [NSNumber numberWithBool:NO]]];
          if (percentCompleteFetchingDeps == 1.0) { depFetchDone(mainMsgTitle); }
        };
        void (^depServerTempError)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                      NSString *mainMsgTitle,
                                                                      NSString *recordTitle) {
          handleHudProgress(percentComplete);
          [errsForDepsFetch addObject:@[[NSString stringWithFormat:@"%@ not fetched.", recordTitle],
                                        [NSNumber numberWithBool:NO],
                                        @[@"Temporary server error."],
                                        [NSNumber numberWithBool:NO]]];
          if (percentCompleteFetchingDeps == 1.0) { depFetchDone(mainMsgTitle); }
        };
        void(^depAuthReqdBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                 NSString *mainMsgTitle,
                                                                 NSString *recordTitle) {
          receivedAuthReqdErrorOnDownloadDepsAttempt = YES;
          handleHudProgress(percentComplete);
          [errsForDepsFetch addObject:@[[NSString stringWithFormat:@"%@ not fetched.", recordTitle],
                                        [NSNumber numberWithBool:NO],
                                        @[@"Authentication required."],
                                        [NSNumber numberWithBool:NO]]];
          if (percentCompleteFetchingDeps == 1.0) { depFetchDone(mainMsgTitle); }
        };
        _fetchDependencies(self,
                           entity,
                           depNotFoundBlk,
                           depSuccessBlk,
                           depRetryAfterBlk,
                           depServerTempError,
                           depAuthReqdBlk);
      }
    } else {
      postFetchAction();
    }
  };
  return fetchDepsThenTakeAction;
}

- (void(^)(void))mergerWithLatestEntity:(id)latestEntity
                           navReenabler:(void(^)(void))navReenabler
                           alertSection:(UIView *)alertSection {
  void (^doMerge)(void) = ^{
    _entityEditPreparer(self, _entity);
    [self setEditing:YES animated:YES];
    NSDictionary *mergeConflicts = _merge(self, _entity, latestEntity);
    if ([mergeConflicts count] > 0) {
      [[[self navigationItem] leftBarButtonItem] setEnabled:NO]; // ensures 'Cancel' button stays grayed-out
      [_deleteBarButtonItem setEnabled:NO];
      [self.view endEditing:YES]; // dismiss the keyboard
      NSString *desc = @"Use the form below to resolve the merge conflicts.";
      [PEUIUtils showConflictResolverWithTitle:@"Conflict resolver."
                              alertDescription:[[NSAttributedString alloc] initWithString:desc]
                         conflictResolveFields:_conflictResolveFields(self, mergeConflicts, _entity, latestEntity)
                                withCellHeight:([PEUIUtils sizeOfText:@"" withFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]].height + _uitoolkit.verticalPaddingForButtons)
                             labelLeftHPadding:5.0
                            valueRightHPadding:8.0
                                     labelFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                     valueFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                labelTextColor:[UIColor darkGrayColor]
                                valueTextColor:[UIColor darkGrayColor]
                minPaddingBetweenLabelAndValue:10.0
                             includeTopDivider:NO
                          includeBottomDivider:NO
                          includeInnerDividers:YES
                       innerDividerWidthFactor:0.967
                                dividerPadding:3.0
                       rowPanelBackgroundColor:[UIColor clearColor]
                          panelBackgroundColor:[UIColor whiteColor]
                                  dividerColor:[UIColor lightGrayColor]
                                      topInset:0.0
                               okayButtonTitle:@"Okay.  Merge 'em!"
                              okayButtonAction:^(NSArray *valueLabels) {
                                navReenabler();
                                [_entity setUpdatedAt:[latestEntity updatedAt]];
                                id resultEntity = _conflictResolvedEntity(self, mergeConflicts, valueLabels, _entity, latestEntity);
                                _entityToPanelBinder(resultEntity, _entityFormPanel);
                              }
                             cancelButtonTitle:@"Cancel.  I'll deal with this later."
                            cancelButtonAction:^{ navReenabler(); }
                       relativeToViewForLayout:alertSection
                          relativeToViewForPop:self.view];
    } else {
      navReenabler();
      [_entity setUpdatedAt:[latestEntity updatedAt]];
      _entityToPanelBinder(_entity, _entityFormPanel);
    }
  };
  return doMerge;
}

- (void)presentSaveConflictAlertWithLatestEntity:(id)latestEntity
                                alertDescription:(NSAttributedString *)desc
                                    cancelAction:(void(^)(void))cancelAction {
  void (^reenableNavButtons)(void) = ^{
    [[[self navigationItem] leftBarButtonItem] setEnabled:YES];
    [[[self navigationItem] rightBarButtonItem] setEnabled:YES];
    [_deleteBarButtonItem setEnabled:YES];
    [[[self tabBarController] tabBar] setUserInteractionEnabled:YES];
    if (_modalOperationDone) { _modalOperationDone(); }
    [self setUploadDownloadDeleteBarButtonStates];
  };
  void (^fetchDepsThenTakeAction)(void(^)(void)) = [self downloadDepsForEntity:latestEntity
                                                     dismissErrAlertPostAction:reenableNavButtons];
  [PEUIUtils showEditConflictAlertWithTitle:@"Conflict."
                           alertDescription:desc
                                   topInset:[PEUIUtils topInsetForAlertsWithController:self]
                           mergeButtonTitle:@"Merge remote and local, then review."
                          mergeButtonAction:^(UIView *alertSection) {
                            void (^doMerge)(void) = [self mergerWithLatestEntity:latestEntity
                                                                    navReenabler:reenableNavButtons
                                                                    alertSection:alertSection];
                            fetchDepsThenTakeAction(doMerge);
                          }
                         replaceButtonTitle:@"Replace local with remote, then review."
                        replaceButtonAction:^{
                          fetchDepsThenTakeAction(^{
                            _entityEditPreparer(self, _entity);
                            [self setEditing:YES animated:YES];
                            reenableNavButtons();
                            [_entity setUpdatedAt:[latestEntity updatedAt]];
                            [_entity overwriteDomainProperties:latestEntity];
                            _entityToPanelBinder(_entity, _entityFormPanel);
                            if (_updateDepsPanel) {
                              _updateDepsPanel(self, latestEntity);
                            }
                          });
                        }
                  forceSaveLocalButtonTitle:@"I don't care.  Force save my local copy."
                      forceSaveButtonAction:^{
                        _entityEditPreparer(self, _entity);
                        [_entity setUpdatedAt:[latestEntity updatedAt]];
                        [self setEditing:YES animated:YES];
                        reenableNavButtons();
                        [self doneWithEdit];
                        [super setEditing:NO animated:YES];
                      }
                          cancelButtonTitle:@"Cancel.  I'll deal with this later."
                         cancelButtonAction:^{ cancelAction(); }
                             relativeToView:[self parentViewForAlerts]];
}

#pragma mark - Toggle into edit mode

- (void)setEditing:(BOOL)flag animated:(BOOL)animated {
  if (flag) {
    if ([self prepareForEditing]) {
      _entityCopyBeforeEdit = [_entity copy];
      _isEdit = YES;
      [super setEditing:flag animated:animated];
      if (_prepareUIForUserInteractionBlk) {
        _prepareUIForUserInteractionBlk(self, _entityFormPanel);
      }
      [self setUploadDownloadDeleteBarButtonStates];
    }
  } else {
    if ([self stopEditing]) {
      [super setEditing:flag animated:animated];
    }
  }
}

#pragma mark - UI state changes

- (void)disableUi {
  [self.navigationItem setHidesBackButton:YES animated:YES];
  [[[self navigationItem] leftBarButtonItem] setEnabled:NO];
  [[[self navigationItem] rightBarButtonItem] setEnabled:NO];
  [[[self tabBarController] tabBar] setUserInteractionEnabled:NO];
  [_uploadBarButtonItem setEnabled:NO];
  [_downloadBarButtonItem setEnabled:NO];
  [_deleteBarButtonItem setEnabled:NO];
  if (_modalOperationStarted) { _modalOperationStarted(); }
}

- (void)enableUi {
  [self.navigationItem setHidesBackButton:NO animated:YES];
  [[[self navigationItem] leftBarButtonItem] setEnabled:YES];
  [[[self navigationItem] rightBarButtonItem] setEnabled:YES];
  [[[self tabBarController] tabBar] setUserInteractionEnabled:YES];
  if (_modalOperationDone) { _modalOperationDone(); }
  [self setUploadDownloadDeleteBarButtonStates];
}

- (UILabel *)titleWithText:(NSString *)titleText {
  return [PEUIUtils labelWithKey:titleText
                            font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                 backgroundColor:[UIColor clearColor]
                       textColor:[UIColor blackColor]
             verticalTextPadding:0.0];
}

- (BOOL)prepareForEditing {
  BOOL editPrepareSuccess = YES;
  if (![_entity editInProgress]) {
    editPrepareSuccess = _entityEditPreparer(self, _entity);
  }
  if (editPrepareSuccess) {
    [[self navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc]
                                                 initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                 target:self
                                                 action:@selector(cancelAddEdit)]];
    [_entityViewPanel removeFromSuperview];
    [_entityFormPanel removeFromSuperview];
    _entityFormPanel = _entityFormPanelMaker(self);
    [PEUIUtils placeView:_entityFormPanel atTopOf:[self view] withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0 hpadding:0];
    _entityToPanelBinder(_entity, _entityFormPanel);
    _panelEnablerDisabler(_entityFormPanel, YES);
  }
  return editPrepareSuccess;
}

- (BOOL)stopEditing {
  [self.view endEditing:YES];
  void (^postEditActivities)(void) = ^{
    if (_itemChangedBlk) {
      _itemChangedBlk(_entity, _entityIndexPath);
    }
    _isEdit = NO;
    [self enableUi];
    [[self navigationItem] setLeftBarButtonItem:_backButton];
    [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];
    _panelEnablerDisabler(_entityFormPanel, NO);
    [[NSNotificationCenter defaultCenter] postNotificationName:_entityUpdatedNotificationName
                                                        object:_entity
                                                      userInfo:nil];
    [_entityFormPanel removeFromSuperview];
    _entityViewPanel = _entityViewPanelMaker(self, _parentEntity, _entity);
    [PEUIUtils placeView:_entityViewPanel
                 atTopOf:[self view]
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0
                hpadding:0];
  };
  if (_isEditCanceled) {
    if (_entityCopyBeforeEdit) {
      [_entity overwrite:_entityCopyBeforeEdit];
    }
    _entityEditCanceler(self, _entity);
    _entityToPanelBinder(_entity, _entityFormPanel);
    postEditActivities();
    _isEditCanceled = NO;
    _isEdit = NO;
  } else {
    NSArray *errMsgs = _entityValidator(_entityFormPanel);
    BOOL isValidEntity = YES;
    if (errMsgs && [errMsgs count] > 0) {
      isValidEntity = NO;
    }
    if (isValidEntity) {
      _panelToEntityBinder(_entityFormPanel, _entity);
      _entitySaver(self, _entity);
      if (_isAuthenticatedBlk() && (!_isOfflineMode() || (_doneEditingEntityLocalSync == nil))) {
        MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [self disableUi];
        HUD.delegate = self;
        HUD.mode = _syncImmediateMBProgressHUDMode;
        HUD.labelText = @"Saving to the server.";
        __block float percentCompleteUploadingEntity = 0.0;
        HUD.progress = percentCompleteUploadingEntity;
        NSMutableArray *errorsForUpload = [NSMutableArray array];
        // The meaning of the elements of the arrays found within errorsForUpload:
        //
        // errorsForUpload[*][0]: Error title (string)
        // errorsForUpload[*][1]: Is error user-fixable (bool)
        // errorsForUpload[*][2]: An NSArray of sub-error messages (strings)
        // errorsForUpload[*][3]: Is error type server-busy? (bool)
        // errorsForUpload[*][4]: Is error conflict-type (bool)
        // errorsForUpload[*][5]: The latest entity if err is conflict-type
        // errorsForUpload[*][6]: Is entity not found
        //
        NSMutableArray *successMessageTitlesForUpload = [NSMutableArray array];
        __block BOOL receivedAuthReqdErrorOnSaveAttempt = NO;
        void(^immediateSyncDone)(NSString *) = ^(NSString *mainMsgTitle) {
          if ([errorsForUpload count] == 0) { // success
            dispatch_async(dispatch_get_main_queue(), ^{
              UIImage *image = [UIImage imageNamed:@"hud-complete"];
              UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
              [HUD setCustomView:imageView];
              HUD.mode = MBProgressHUDModeCustomView;
              [HUD hide:YES];
              [PEUIUtils showSuccessAlertWithTitle:[NSString stringWithFormat:@"%@ saved.", _entityTitle]
                                  alertDescription:[[NSAttributedString alloc] initWithString:successMessageTitlesForUpload[0]]
                                          topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                       buttonTitle:@"Okay."
                                      buttonAction:^{ postEditActivities(); }
                                    relativeToView:[self parentViewForAlerts]];
            });
          } else { // error
            dispatch_async(dispatch_get_main_queue(), ^{
              [HUD hide:YES afterDelay:0];
              if ([errorsForUpload[0][6] boolValue]) { // is entity not found
                [self handleNotFoundError];
              } else if ([errorsForUpload[0][3] boolValue]) { // server busy
                [PEUIUtils showWaitAlertWithMsgs:nil
                                           title:@"Busy with maintenance."
                                alertDescription:[[NSAttributedString alloc] initWithString:@"\
The server is currently busy at the moment \
undergoing maintenance.\n\n\
Your edits have been saved locally.  You \
can try to upload them later."]
                                        topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                     buttonTitle:@"Okay."
                                    buttonAction:^{
                                      postEditActivities();
                                    }
                                  relativeToView:[self parentViewForAlerts]];
              } else if ([errorsForUpload[0][4] boolValue]) { // conflict error
                id latestEntity = errorsForUpload[0][5];
                NSAttributedString *desc =
                [PEUIUtils attributedTextWithTemplate:@"The remote copy of this record has been \
updated since you started to edit it.  You have a few options:\n\nIf you cancel, %@."
                                         textToAccent:@"your local edits will be retained"
                                       accentTextFont:[PEUIUtils italicFontForTextStyle:UIFontTextStyleSubheadline]];
                [self presentSaveConflictAlertWithLatestEntity:latestEntity
                                              alertDescription:desc
                                                  cancelAction:postEditActivities];
              } else { // all other error types
                NSString *messageTemplate;
                NSString *textToAccent;
                NSAttributedString *attrMessage;
                NSString *title;
                NSString *fixNowActionTitle;
                NSString *fixLaterActionTitle;
                NSString *dealWithLaterActionTitle;
                NSString *cancelActionTitle;
                NSArray *subErrors = errorsForUpload[0][2]; // because only single-record edit, we can skip the "not saved" msg title, and just display the sub-errors
                if ([subErrors count] > 1) {
                  textToAccent = @"they have been saved locally";
                  messageTemplate = @"Although there were problems syncing your edits to the server, %@.  The errors are as follows:";
                  fixNowActionTitle = @"I'll fix them now.";
                  fixLaterActionTitle = @"I'll fix them later.";
                  dealWithLaterActionTitle = @"I'll try syncing them later.";
                  cancelActionTitle = @"Forget it.  Just cancel them.";
                  title = [NSString stringWithFormat:@"Errors %@.", mainMsgTitle];
                } else {
                  textToAccent = @"they have been saved locally";
                  messageTemplate = @"Although there was a problem syncing your edits to the server, %@.  The error is as follows:";
                  fixLaterActionTitle = @"I'll fix it later.";
                  fixNowActionTitle = @"I'll fix it now.";
                  dealWithLaterActionTitle = @"I'll try syncing it later.";
                  cancelActionTitle = @"Forget it.  Just cancel it.";
                  title = [NSString stringWithFormat:@"Error %@.", mainMsgTitle];
                }
                attrMessage = [PEUIUtils attributedTextWithTemplate:messageTemplate
                                                       textToAccent:textToAccent
                                                     accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]];
                JGActionSheetSection *becameUnauthSection = nil;
                if (receivedAuthReqdErrorOnSaveAttempt) {
                  becameUnauthSection = [self becameUnauthenticatedSection];
                }
                JGActionSheetSection *contentSection = [PEUIUtils errorAlertSectionWithMsgs:subErrors
                                                                                      title:title
                                                                           alertDescription:attrMessage
                                                                             relativeToView:[self parentViewForAlerts]];
                JGActionSheetSection *buttonsSection;
                void (^buttonsPressedBlock)(JGActionSheet *, NSIndexPath *);
                // 'fix' buttons here
                void (^cancelAction)(void) = ^{
                  // First, we need to save the copy-before-edit entity to get the database
                  // back to how it was before the user did the editing
                  _entitySaver(self, _entityCopyBeforeEdit);
                  
                  // now we can cancel the edit session as we normally would
                  [_entity overwrite:_entityCopyBeforeEdit];
                  _entityEditCanceler(self, _entity);
                  _entityToPanelBinder(_entity, _entityFormPanel);
                  _isEditCanceled = NO; // reseting this
                  postEditActivities();
                };
                if ([PEAddViewEditController areErrorsAllUserFixable:errorsForUpload]) {
                  buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                  message:nil
                                                             buttonTitles:@[fixNowActionTitle,
                                                                            fixLaterActionTitle,
                                                                            cancelActionTitle]
                                                              buttonStyle:JGActionSheetButtonStyleDefault];
                  [buttonsSection setButtonStyle:JGActionSheetButtonStyleRed forButtonAtIndex:2];
                  buttonsPressedBlock = ^(JGActionSheet *sheet, NSIndexPath *indexPath) {
                    switch ([indexPath row]) {
                      case 0: // fix now
                        _entityEditPreparer(self, _entity);
                        [super setEditing:YES animated:NO];
                        [[[self navigationItem] leftBarButtonItem] setEnabled:YES];
                        [[[self navigationItem] rightBarButtonItem] setEnabled:YES];
                        break;
                      case 1: // fix later
                        postEditActivities();
                        break;
                      case 2: // cancel
                        cancelAction();
                        break;
                    }
                    [sheet dismissAnimated:YES];
                  };
                } else {
                  buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                  message:nil
                                                             buttonTitles:@[dealWithLaterActionTitle,
                                                                            cancelActionTitle]
                                                              buttonStyle:JGActionSheetButtonStyleDefault];
                  [buttonsSection setButtonStyle:JGActionSheetButtonStyleRed forButtonAtIndex:1];
                  buttonsPressedBlock = ^(JGActionSheet *sheet, NSIndexPath *indexPath) {
                    switch ([indexPath row]) {
                      case 0: // deal with later
                        postEditActivities();
                        break;
                      case 1: // cancel
                        cancelAction();
                        break;
                    }
                    [sheet dismissAnimated:YES];
                  };
                }
                JGActionSheet *alertSheet;
                if (becameUnauthSection) {
                  alertSheet = [JGActionSheet actionSheetWithSections:@[contentSection, becameUnauthSection, buttonsSection]];
                } else {
                  alertSheet = [JGActionSheet actionSheetWithSections:@[contentSection, buttonsSection]];
                }
                [alertSheet setDelegate:self];
                [alertSheet setInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
                [alertSheet setButtonPressedBlock:buttonsPressedBlock];
                [alertSheet showInView:[self view] animated:YES];
              }
            });
          }
        };
        void (^handleHudProgress)(float) = ^(float percentComplete) {
          percentCompleteUploadingEntity += percentComplete;
          dispatch_async(dispatch_get_main_queue(), ^{
            HUD.progress = percentCompleteUploadingEntity;
          });
        };
        void(^syncNotFoundBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                  NSString *mainMsgTitle,
                                                                  NSString *recordTitle) {
          handleHudProgress(percentComplete);
          [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                       [NSNumber numberWithBool:NO],
                                       @[[NSString stringWithFormat:@"Not found."]],
                                       [NSNumber numberWithBool:NO],
                                       [NSNumber numberWithBool:NO],
                                       [NSNull null],
                                       [NSNumber numberWithBool:YES]]];
          if (percentCompleteUploadingEntity == 1.0) {
            immediateSyncDone(mainMsgTitle);
          }
        };
        void(^syncSuccessBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                 NSString *mainMsgTitle,
                                                                 NSString *recordTitle) {
          handleHudProgress(percentComplete);
          [successMessageTitlesForUpload addObject:[NSString stringWithFormat:@"%@ saved to the server.", recordTitle]];
          if (percentCompleteUploadingEntity == 1.0) {
            immediateSyncDone(mainMsgTitle);
          }
        };
        void(^syncRetryAfterBlk)(float, NSString *, NSString *, NSDate *) = ^(float percentComplete,
                                                                              NSString *mainMsgTitle,
                                                                              NSString *recordTitle,
                                                                              NSDate *retryAfter) {
          handleHudProgress(percentComplete);
          [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                       [NSNumber numberWithBool:NO],
                                       @[[NSString stringWithFormat:@"Server undergoing maintenance.  Try again later."]],
                                       [NSNumber numberWithBool:YES],
                                       [NSNumber numberWithBool:NO],
                                       [NSNull null],
                                       [NSNumber numberWithBool:NO]]];
          if (percentCompleteUploadingEntity == 1.0) {
            immediateSyncDone(mainMsgTitle);
          }
        };
        void (^syncServerTempError)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                       NSString *mainMsgTitle,
                                                                       NSString *recordTitle) {
          handleHudProgress(percentComplete);
          [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                       [NSNumber numberWithBool:NO],
                                       @[@"Temporary server error."],
                                       [NSNumber numberWithBool:NO],
                                       [NSNumber numberWithBool:NO],
                                       [NSNull null],
                                       [NSNumber numberWithBool:NO]]];
          if (percentCompleteUploadingEntity == 1.0) {
            immediateSyncDone(mainMsgTitle);
          }
        };
        void (^syncServerError)(float, NSString *, NSString *, NSArray *) = ^(float percentComplete,
                                                                              NSString *mainMsgTitle,
                                                                              NSString *recordTitle,
                                                                              NSArray *computedErrMsgs) {
          handleHudProgress(percentComplete);
          BOOL isErrorUserFixable = YES;
          if (!computedErrMsgs || ([computedErrMsgs count] == 0)) {
            computedErrMsgs = @[@"Unknown server error."];
            isErrorUserFixable = NO;
          }
          [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                       [NSNumber numberWithBool:isErrorUserFixable],
                                       computedErrMsgs,
                                       [NSNumber numberWithBool:NO],
                                       [NSNumber numberWithBool:NO],
                                       [NSNull null],
                                       [NSNumber numberWithBool:NO]]];
          if (percentCompleteUploadingEntity == 1.0) {
            immediateSyncDone(mainMsgTitle);
          }
        };
        void(^syncConflictBlk)(float, NSString *, NSString *, id) = ^(float percentComplete,
                                                                      NSString *mainMsgTitle,
                                                                      NSString *recordTitle,
                                                                      id latestEntity) {
          handleHudProgress(percentComplete);
          [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                       [NSNumber numberWithBool:NO],
                                       @[[NSString stringWithFormat:@"Conflict."]],
                                       [NSNumber numberWithBool:NO],
                                       [NSNumber numberWithBool:YES],
                                       latestEntity,
                                       [NSNumber numberWithBool:NO]]];
          if (percentCompleteUploadingEntity == 1.0) {
            immediateSyncDone(mainMsgTitle);
          }
        };
        void(^syncAuthReqdBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                  NSString *mainMsgTitle,
                                                                  NSString *recordTitle) {
          receivedAuthReqdErrorOnSaveAttempt = YES;
          handleHudProgress(percentComplete);
          [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                       [NSNumber numberWithBool:NO],
                                       @[@"Authentication required."],
                                       [NSNumber numberWithBool:NO],
                                       [NSNumber numberWithBool:NO],
                                       [NSNull null],
                                       [NSNumber numberWithBool:NO]]];
          if (percentCompleteUploadingEntity == 1.0) {
            immediateSyncDone(mainMsgTitle);
          }
        };
        void (^syncDependencyUnsyncedBlk)(float, NSString *, NSString *, NSString *) = ^(float percentComplete,
                                                                                         NSString *mainMsgTitle,
                                                                                         NSString *recordTitle,
                                                                                         NSString *dependencyErrMsg) {
          handleHudProgress(percentComplete);
          [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                       [NSNumber numberWithBool:NO],
                                       @[dependencyErrMsg],
                                       [NSNumber numberWithBool:NO],
                                       [NSNumber numberWithBool:NO],
                                       [NSNull null],
                                       [NSNumber numberWithBool:NO]]];
          if (percentCompleteUploadingEntity == 1.0) {
            immediateSyncDone(mainMsgTitle);
          }
        };
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
          _doneEditingEntityImmediateSync(self,
                                   _entity,
                                   syncNotFoundBlk,
                                   syncSuccessBlk,
                                   syncRetryAfterBlk,
                                   syncServerTempError,
                                   syncServerError,
                                   syncConflictBlk,
                                   syncAuthReqdBlk,
                                   syncDependencyUnsyncedBlk);
        });
      } else {
        [self disableUi];
        if (_modalOperationStarted) { _modalOperationStarted(); }
        _doneEditingEntityLocalSync(self, _entity);
        MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        HUD.delegate = self;
        [HUD setLabelText:[NSString stringWithFormat:@"%@ Saved.", _entityTitle]];
        NSString *hudDetailText = nil;
        if (_isOfflineMode() && _isAuthenticatedBlk()) {
          hudDetailText = @"(offline mode enabled)";
        } else if (_isUserLoggedIn() && !_isAuthenticatedBlk()) {
          hudDetailText = @"(not saved to the server)";
        }
        if (hudDetailText) {
          [HUD setDetailsLabelText:hudDetailText];
        }
        UIImage *image = [UIImage imageNamed:@"hud-complete"];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        [HUD setCustomView:imageView];
        HUD.mode = MBProgressHUDModeCustomView;
        [HUD hide:YES afterDelay:1.0];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
          postEditActivities();
        });
      }
    } else {
      [PEUIUtils showWarningAlertWithMsgs:errMsgs
                                    title:@"Oops"
                         alertDescription:[[NSAttributedString alloc] initWithString:@"There are some validation errors:"]
                                 topInset:[PEUIUtils topInsetForAlertsWithController:self]
                              buttonTitle:@"Okay."
                             buttonAction:nil
                           relativeToView:[self view]];
      return NO;
    }
  }
  return YES;
}

- (void)doneWithEdit {
  [self stopEditing];
}

+ (BOOL)areErrorsAllUserFixable:(NSArray *)errors {
  for (NSArray *error in errors) {
    NSNumber *isErrorUserFixable = error[1];
    if (![isErrorUserFixable boolValue]) {
      return NO;
    }
  }
  return YES;
}

+ (BOOL)areErrorsAllAuthenticationRequired:(NSArray *)errors {
  for (NSArray *error in errors) {
    NSNumber *isErrorAuthRequired = error[1];
    if (![isErrorAuthRequired boolValue]) {
      return NO;
    }
  }
  return YES;
}

- (UIView *)errorPanelWithTitle:(NSString *)title
                 forContentView:(UIView *)contentView
                         height:(CGFloat)height
                    leftImgIcon:(UIImage *)leftImgIcon {
  UIView *errorPanel = [PEUIUtils panelWithWidthOf:0.9 relativeToView:contentView fixedHeight:height];
  UIImageView *errImgView = [[UIImageView alloc] initWithImage:leftImgIcon];
  UILabel *errorMsgLbl = [PEUIUtils labelWithKey:title
                                            font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                 backgroundColor:[UIColor clearColor]
                                       textColor:[UIColor blackColor]
                             verticalTextPadding:0.0];
  [PEUIUtils placeView:errImgView
            inMiddleOf:errorPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              hpadding:0.0];
  [PEUIUtils placeView:errorMsgLbl
          toTheRightOf:errImgView
                  onto:errorPanel
         withAlignment:PEUIVerticalAlignmentTypeMiddle
              hpadding:5.0];
  return errorPanel;
}

- (NSArray *)panelsForMessages:(NSArray *)subErrors
                         forContentView:(UIView *)contentView
                            leftImgIcon:(UIImage *)leftImgIcon {
  NSMutableArray *subErrorPanels = [NSMutableArray arrayWithCapacity:[subErrors count]];
  for (NSString *subError in subErrors) {
    UIView *errorPanel = [self errorPanelWithTitle:subError
                                    forContentView:contentView
                                            height:25.0
                                       leftImgIcon:leftImgIcon];
    [subErrorPanels addObject:errorPanel];
  }
  return subErrorPanels;
}

- (void)doneWithAdd {
  [self.view endEditing:YES];
  NSArray *errMsgs = _entityValidator(_entityFormPanel);
  BOOL isValidEntity = YES;
  if (errMsgs && [errMsgs count] > 0) {
    isValidEntity = NO;
  }
  if (isValidEntity) {
    _newEntity = _entityMaker(_entityFormPanel);
    void (^notificationSenderForAdd)(id) = ^(id theNewEntity) {
      NSArray *entitiesFromEntity;
      if (_entitiesFromEntity) {
        entitiesFromEntity = _entitiesFromEntity(theNewEntity);
      } else {
        entitiesFromEntity = @[theNewEntity];
      }
      for (id entity in entitiesFromEntity) {
        [[NSNotificationCenter defaultCenter] postNotificationName:_entityAddedNotificationName
                                                            object:entity
                                                          userInfo:nil];
      }
    };
    if (_isAuthenticatedBlk() && !_isOfflineMode()) {
      MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      [self disableUi];
      HUD.delegate = self;
      HUD.mode = _syncImmediateMBProgressHUDMode;
      HUD.labelText = @"Saving to the server...";
      __block float percentCompleteUploadingEntity = 0.0;
      HUD.progress = percentCompleteUploadingEntity;
      NSMutableArray *errorsForUpload = [NSMutableArray array];
      // The meaning of the elements of the arrays found within errorsForUpload:
      //
      // errorsForUpload[*][0]: Error title (string)
      // errorsForUpload[*][1]: Is error user-fixable (bool)
      // errorsForUpload[*][2]: An NSArray of sub-error messages (strings)
      // errorsForUpload[*][3]: Is error type server-busy? (bool)
      //
      NSMutableArray *successMessageTitlesForUpload = [NSMutableArray array];
      __block BOOL receivedAuthReqdErrorOnAddAttempt = NO;
      void(^immediateSaveDone)(NSString *) = ^(NSString *mainMsgTitle) {
        BOOL isMultiStepAdd = ([errorsForUpload count] + [successMessageTitlesForUpload count]) > 1;
        if ([errorsForUpload count] == 0) { // no errors
          dispatch_async(dispatch_get_main_queue(), ^{
            notificationSenderForAdd(_newEntity);
            if (isMultiStepAdd) { // all successes
              [HUD hide:YES afterDelay:0];
              [PEUIUtils showSuccessAlertWithMsgs:successMessageTitlesForUpload
                                            title:[NSString stringWithFormat:@"%@ saved.", mainMsgTitle]
                                 alertDescription:[[NSAttributedString alloc] initWithString:@"Your records have been successfully saved to the server."]
                         additionalContentSection:(_addlContentSection != nil) ? _addlContentSection(self, _entityFormPanel, _newEntity) : nil
                                         topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                      buttonTitle:@"Okay."
                                     buttonAction:^{
                                       notificationSenderForAdd(_newEntity);
                                       _itemAddedBlk(self, _newEntity);
                                       if (_modalOperationDone) { _modalOperationDone(); }
                                     }
                                   relativeToView:self.view];
            } else { // single add success
              UIImage *image = [UIImage imageNamed:@"hud-complete"];
              UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
              [HUD setCustomView:imageView];
              HUD.mode = MBProgressHUDModeCustomView;
              [HUD hide:YES];
              [PEUIUtils showSuccessAlertWithTitle:[NSString stringWithFormat:@"%@ saved.", _entityTitle]
                                  alertDescription:[[NSAttributedString alloc] initWithString:successMessageTitlesForUpload[0]]
                          additionalContentSection:(_addlContentSection != nil) ? _addlContentSection(self, _entityFormPanel, _newEntity) : nil
                                          topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                       buttonTitle:@"Okay."
                                      buttonAction:^{
                                        _itemAddedBlk(self, _newEntity);  // this is what causes this controller to be dismissed
                                        if (_modalOperationDone) { _modalOperationDone(); }
                                      }
                                    relativeToView:[self parentViewForAlerts]];
            }
          });
        } else { // mixed results or only errors
          NSMutableArray *sections = [NSMutableArray array];
          BOOL (^doesContainBusyError)(void) = ^{
            BOOL containsBusyError = NO;
            for (NSArray *failure in errorsForUpload) {
              containsBusyError = [failure[3] boolValue];
              break;
            }
            return containsBusyError;
          };
          BOOL (^areAllBusyErrors)(void) = ^{
            BOOL allBusyErrors = YES;
            for (NSArray *failure in errorsForUpload) {
              if (![failure[3] boolValue]) {
                allBusyErrors = NO;
                break;
              }
            }
            return allBusyErrors;
          };
          void (^addServerBusySection)(void) = ^{
            NSString *msg;
            if (isMultiStepAdd) {
              msg = @"\
While attempting to upload at least one your \
records, the server reported it is busy \
undergoing maintenance.  All your records \
have been saved locally and can be uploaded \
later.";
            } else {
              msg = @"\
While attempting to sync your record, the \
server reported that it is busy undergoing \
maintenance.  Your record has been saved \
locally.  Try uploading it later.";
            }
            [sections addObject:[PEUIUtils waitAlertSectionWithMsgs:nil
                                                              title:@"Busy with maintenance."
                                                   alertDescription:[[NSAttributedString alloc] initWithString:msg]
                                                     relativeToView:[self parentViewForAlerts]]];
          };
          NSArray *(^stripOutBusyErrors)(void) = ^ NSArray * {
            NSMutableArray *errorsSansBusyErrs = [NSMutableArray array];
            for (NSArray *failure in errorsForUpload) {
              if (![failure[3] boolValue]) {
                [errorsSansBusyErrs addObject:failure];
              }
            }
            return errorsSansBusyErrs;
          };
          dispatch_async(dispatch_get_main_queue(), ^{
            [HUD hide:YES afterDelay:0];
            if ([successMessageTitlesForUpload count] > 0) { // mixed results
              if (receivedAuthReqdErrorOnAddAttempt) {
                [sections addObject:[self becameUnauthenticatedSection]];
              }
              if (doesContainBusyError()) {
                addServerBusySection();
              }
              if (!areAllBusyErrors()) {
                NSString *title = [NSString stringWithFormat:@"Mixed results saving %@.", [mainMsgTitle lowercaseString]];
                NSAttributedString *attrMessage = [PEUIUtils attributedTextWithTemplate:@"Some of the edits were saved to the server and some were not. \
The ones that did not %@ and will need to be fixed individually."
                                                       textToAccent:@"have been saved locally"
                                                     accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]];
                [sections addObject:[PEUIUtils mixedResultsAlertSectionWithSuccessMsgs:successMessageTitlesForUpload
                                                                                 title:title
                                                                      alertDescription:attrMessage
                                                                   failuresDescription:[[NSAttributedString alloc] initWithString:@"The problems are:"]
                                                                              failures:stripOutBusyErrors()
                                                                        relativeToView:[self parentViewForAlerts]]];
              }
              // buttons section
              [sections addObject:[JGActionSheetSection sectionWithTitle:nil
                                                                 message:nil
                                                            buttonTitles:@[@"Okay."]
                                                             buttonStyle:JGActionSheetButtonStyleDefault]];
              JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:sections];
              [alertSheet setDelegate:self];
              [alertSheet setInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
              [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
                switch ([indexPath row]) {
                  case 0: // okay
                    notificationSenderForAdd(_newEntity);
                    _itemAddedBlk(self, _newEntity);
                    [sheet dismissAnimated:YES];
                    break;
                };}];
              [alertSheet showInView:[self view] animated:YES];
            } else { // only error(s)
              NSString *title;
              NSString *fixNowActionTitle;
              NSString *fixLaterActionTitle;
              NSString *dealWithLaterActionTitle;
              NSString *cancelActionTitle;
              if (receivedAuthReqdErrorOnAddAttempt) {
                [sections addObject:[self becameUnauthenticatedSection]];
              }
              if (doesContainBusyError()) {
                addServerBusySection();
              }
              if (isMultiStepAdd) {
                NSString *textToAccent = @"they have been saved locally";
                NSString *messageTemplate = @"Although there were problems saving your edits to the server, %@.  The details are as follows:";
                fixNowActionTitle = @"I'll fix them now.";
                fixLaterActionTitle = @"I'll fix them later.";
                cancelActionTitle = @"Forget it.  Just cancel them.";
                dealWithLaterActionTitle = @"I'll try uploading them later.";
                title = [NSString stringWithFormat:@"Problems saving %@.", [mainMsgTitle lowercaseString]];
                if (!areAllBusyErrors()) {
                  [sections addObject:[PEUIUtils multiErrorAlertSectionWithFailures:stripOutBusyErrors()
                                                                              title:title
                                                                   alertDescription:[PEUIUtils attributedTextWithTemplate:messageTemplate
                                                                                                             textToAccent:textToAccent
                                                                                                           accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]]
                                                                     relativeToView:[self parentViewForAlerts]]];
                }
              } else {
                NSString *messageTemplate;
                NSString *textToAccent = @"they have been saved locally";
                dealWithLaterActionTitle = @"I'll try uploading it later.";
                cancelActionTitle = @"Forget it.  Just cancel this.";
                NSArray *subErrors = errorsForUpload[0][2]; // because only single-record add, we can skip the "not saved" msg title, and just display the sub-errors
                if ([subErrors count] > 1) {
                  title = [NSString stringWithFormat:@"Errors %@.", mainMsgTitle];
                  messageTemplate = @"Although there were problems saving your edits to the server, %@.  The errors are as follows:";
                  fixNowActionTitle = @"I'll fix them now.";
                  fixLaterActionTitle = @"I'll fix them later.";
                } else {
                  title = [NSString stringWithFormat:@"Error %@.", mainMsgTitle];
                  messageTemplate = @"Although there was a problem saving your edits to the server, %@.  The error is as follows:";
                  fixLaterActionTitle = @"I'll fix it later.";
                  fixNowActionTitle = @"I'll fix it now.";
                }
                if (!areAllBusyErrors()) {
                  [sections addObject:[PEUIUtils errorAlertSectionWithMsgs:subErrors
                                                                     title:title
                                                          alertDescription:[PEUIUtils attributedTextWithTemplate:messageTemplate
                                                                                                    textToAccent:textToAccent
                                                                                                  accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]]
                                                            relativeToView:[self parentViewForAlerts]]];
                }
              }
              JGActionSheetSection *buttonsSection;
              void (^buttonsPressedBlock)(JGActionSheet *, NSIndexPath *);
              if ([PEAddViewEditController areErrorsAllUserFixable:errorsForUpload]) {
                buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                message:nil
                                                           buttonTitles:@[fixNowActionTitle,
                                                                          fixLaterActionTitle,
                                                                          cancelActionTitle]
                                                            buttonStyle:JGActionSheetButtonStyleDefault];
                [buttonsSection setButtonStyle:JGActionSheetButtonStyleRed forButtonAtIndex:2];
                buttonsPressedBlock = ^(JGActionSheet *sheet, NSIndexPath *indexPath) {
                  switch ([indexPath row]) {
                    case 0: // fix now
                      _entityAddCanceler(self, NO, _newEntity);
                      [self enableUi];
                      break;
                    case 1: // fix later
                      notificationSenderForAdd(_newEntity);
                      _itemAddedBlk(self, _newEntity);
                      break;
                    case 2: // cancel
                      _entityAddCanceler(self, YES, _newEntity);
                      break;
                  }
                  if (_modalOperationDone) { _modalOperationDone(); }
                  [sheet dismissAnimated:YES];
                };
              } else {
                buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                message:nil
                                                           buttonTitles:@[dealWithLaterActionTitle,
                                                                          cancelActionTitle]
                                                            buttonStyle:JGActionSheetButtonStyleDefault];
                [buttonsSection setButtonStyle:JGActionSheetButtonStyleRed forButtonAtIndex:1];
                buttonsPressedBlock = ^(JGActionSheet *sheet, NSIndexPath *indexPath) {
                  switch ([indexPath row]) {
                    case 0:  // sync/deal-with it later
                      notificationSenderForAdd(_newEntity);
                      _itemAddedBlk(self, _newEntity);
                      break;
                    case 1:  // cancel
                      _entityAddCanceler(self, YES, _newEntity);
                      break;
                  }
                 if (_modalOperationDone) { _modalOperationDone(); }
                  [sheet dismissAnimated:YES];
                };
              }
              [sections addObject:buttonsSection];
              JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:sections];
              [alertSheet setDelegate:self];
              [alertSheet setInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
              [alertSheet setButtonPressedBlock:buttonsPressedBlock];
              [alertSheet showInView:[self view] animated:YES];
            }
          });
        }
      };
      void(^handleHudProgress)(float) = ^(float percentComplete) {
        percentCompleteUploadingEntity += percentComplete;
        dispatch_async(dispatch_get_main_queue(), ^{
          HUD.progress = percentCompleteUploadingEntity;
        });
      };
      void(^syncNotFoundBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                NSString *mainMsgTitle,
                                                                NSString *recordTitle) {
        handleHudProgress(percentComplete);
        [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                     [NSNumber numberWithBool:NO],
                                     @[[NSString stringWithFormat:@"Not found."]],
                                     [NSNumber numberWithBool:NO]]];
        if (percentCompleteUploadingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      void(^syncSuccessBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                               NSString *mainMsgTitle,
                                                               NSString *recordTitle) {
        handleHudProgress(percentComplete);
        [successMessageTitlesForUpload addObject:[NSString stringWithFormat:@"%@ saved to the server.", recordTitle]];
        if (percentCompleteUploadingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      void(^syncRetryAfterBlk)(float, NSString *, NSString *, NSDate *) = ^(float percentComplete,
                                                                            NSString *mainMsgTitle,
                                                                            NSString *recordTitle,
                                                                            NSDate *retryAfter) {
        handleHudProgress(percentComplete);
        [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                     [NSNumber numberWithBool:NO],
                                     @[[NSString stringWithFormat:@"Server undergoing maintenance.  Try again later."]],
                                     [NSNumber numberWithBool:YES]]];
        if (percentCompleteUploadingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      void(^syncServerTempError)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                    NSString *mainMsgTitle,
                                                                    NSString *recordTitle) {
        handleHudProgress(percentComplete);
        [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                     [NSNumber numberWithBool:NO],
                                     @[@"Temporary server error."],
                                     [NSNumber numberWithBool:NO]]];
        if (percentCompleteUploadingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      void(^syncServerError)(float, NSString *, NSString *, NSArray *) = ^(float percentComplete,
                                                                           NSString *mainMsgTitle,
                                                                           NSString *recordTitle,
                                                                           NSArray *computedErrMsgs) {
        handleHudProgress(percentComplete);
        BOOL isErrorUserFixable = YES;
        if (!computedErrMsgs || ([computedErrMsgs count] == 0)) {
          computedErrMsgs = @[@"Unknown server error."];
          isErrorUserFixable = NO;
        }
        [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                     [NSNumber numberWithBool:isErrorUserFixable],
                                     computedErrMsgs,
                                     [NSNumber numberWithBool:NO]]];
        if (percentCompleteUploadingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      void(^syncAuthReqdBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                NSString *mainMsgTitle,
                                                                NSString *recordTitle) {
        receivedAuthReqdErrorOnAddAttempt = YES;
        handleHudProgress(percentComplete);
        [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                     [NSNumber numberWithBool:NO],
                                     @[@"Authentication required."],
                                     [NSNumber numberWithBool:NO]]];
        if (percentCompleteUploadingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      void(^syncDependencyUnsyncedBlk)(float, NSString *, NSString *, NSString *) = ^(float percentComplete,
                                                                                      NSString *mainMsgTitle,
                                                                                      NSString *recordTitle,
                                                                                      NSString *dependencyErrMsg) {
        handleHudProgress(percentComplete);
        [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                     [NSNumber numberWithBool:NO],
                                     @[dependencyErrMsg],
                                     [NSNumber numberWithBool:NO]]];
        if (percentCompleteUploadingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        _newEntitySaverImmediateSync(_entityFormPanel,
                        _newEntity,
                        syncNotFoundBlk,
                        syncSuccessBlk,
                        syncRetryAfterBlk,
                        syncServerTempError,
                        syncServerError,
                        nil, // conflicts are not possible with adds
                        syncAuthReqdBlk,
                        syncDependencyUnsyncedBlk);
      });
    } else {
      NSArray *saveResult = _newEntitySaverLocal(_entityFormPanel, _newEntity);
      NSString *saveTitle = saveResult[0];
      NSArray *saveMessages = saveResult[1];
      [[[self navigationItem] leftBarButtonItem] setEnabled:NO]; // cancel btn (so they can't cancel it after we'ved saved and we're displaying the HUD)
      [[[self navigationItem] rightBarButtonItem] setEnabled:NO]; // done btn
      [[[self tabBarController] tabBar] setUserInteractionEnabled:NO];
      if (_modalOperationStarted) { _modalOperationStarted(); }
      
      NSMutableAttributedString *descSubtext = [NSMutableAttributedString new];
      if (_isOfflineMode() && _isAuthenticatedBlk()) {
        [descSubtext appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\n\n(%@)"
                                                                     textToAccent:@"offline mode enabled"
                                                                   accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]
                                                                  accentTextColor:[UIColor blackColor]]];
      } else if (_isUserLoggedIn() && !_isAuthenticatedBlk()) {
        [descSubtext appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\n\n(%@)"
                                                                     textToAccent:@"not saved to the server"
                                                                   accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]
                                                                  accentTextColor:[UIColor blackColor]]];
      }
      if ([saveMessages count] > 1) {
        NSMutableAttributedString *desc = [NSMutableAttributedString new];
        [desc appendAttributedString:[[NSAttributedString alloc] initWithString:@"Your records have been saved locally."]];
        [desc appendAttributedString:descSubtext];
        [PEUIUtils showSuccessAlertWithMsgs:saveMessages
                                      title:saveTitle
                           alertDescription:desc
                   additionalContentSection:(_addlContentSection != nil) ? _addlContentSection(self, _entityFormPanel, _newEntity) : nil
                                   topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                buttonTitle:@"Okay."
                               buttonAction:^{
                                 if (_modalOperationDone) { _modalOperationDone(); }
                                 notificationSenderForAdd(_newEntity);
                                 _itemAddedBlk(self, _newEntity);
                               }
                             relativeToView:self.view];
      } else {
        NSMutableAttributedString *desc = [NSMutableAttributedString new];
        [desc appendAttributedString:[[NSAttributedString alloc] initWithString:@"Your record has been saved locally."]];
        [desc appendAttributedString:descSubtext];
        [PEUIUtils showSuccessAlertWithTitle:saveTitle
                            alertDescription:desc
                    additionalContentSection:(_addlContentSection != nil) ? _addlContentSection(self, _entityFormPanel, _newEntity) : nil
                                    topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                 buttonTitle:@"Okay."
                                buttonAction:^{
                                  if (_modalOperationDone) { _modalOperationDone(); }
                                  notificationSenderForAdd(_newEntity);
                                  _itemAddedBlk(self, _newEntity);
                                }
                              relativeToView:self.view];
      }
    }
  } else {
    [PEUIUtils showWarningAlertWithMsgs:errMsgs
                                  title:@"Oops"
                       alertDescription:[[NSAttributedString alloc] initWithString:@"There are some validation errors:"]
                               topInset:[PEUIUtils topInsetForAlertsWithController:self]
                            buttonTitle:@"Okay."
                           buttonAction:^{  }
                         relativeToView:[self view]];
  }
}

#pragma mark - Cancellation

- (void)cancelAddEdit {
  if (_isAdd) {
    _entityAddCanceler(self, YES, _newEntity);
    _newEntity = nil;
  } else {
    _isEditCanceled = YES;
    _isEdit = NO;
    [self setEditing:NO animated:YES]; // to get 'Done' button to turn to 'Edit'
    [self setHasPoppedKeyboard:NO];
  }
}

@end
