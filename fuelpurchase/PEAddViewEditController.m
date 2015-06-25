//
//  PEAddViewEditController.m
//  fuelpurchase
//
//  Created by Evans, Paul on 9/30/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "PEAddViewEditController.h"
#import <PEFuelPurchase-Model/PELMNotificationUtils.h>
#import <PEObjc-Commons/PEUIUtils.h>
#import <PEObjc-Commons/PEUtils.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "FPLogging.h"

@implementation PEAddViewEditController {
  BOOL _isAdd;
  BOOL _isEdit;
  BOOL _isView;
  BOOL _isEditCanceled;
  NSString *_entityRemotelyDeletedNotifName;
  NSArray *_entityLocallyUpdatedNotifNames;
  NSString *_entityRemotelyUpdatedNotifName;
  NSIndexPath *_entityIndexPath;
  PEItemAddedBlk _itemAddedBlk;
  PEItemChangedBlk _itemChangedBlk;
  UIBarButtonItem *_backButton;
  NSString *_syncInitiatedNotifName;
  NSString *_syncedNotifName;
  NSString *_syncFailedNotifName;
  PEEntityPanelMakerBlk _entityPanelMaker;
  PEPanelToEntityBinderBlk _panelToEntityBinder;
  NSString *_entityTitle;
  PEEnableDisablePanelBlk _panelEnablerDisabler;
  PEEntityEditPreparerBlk _entityEditPreparer;
  PEEntityEditCancelerBlk _entityEditCanceler;
  PEEntityMakerBlk _entityMaker;
  PESaveEntityBlk _entitySaver;
  PESaveNewEntityBlk _newEntitySaver;
  PEMarkAsDoneEditingBlk _doneEditingEntityMarker;
  BOOL _syncImmediateWhenDoneEditing;
  PEPrepareUIForUserInteractionBlk _prepareUIForUserInteractionBlk;
  PEViewDidAppearBlk _viewDidAppearBlk;
  PEEntityValidatorBlk _entityValidator;
  PEEntityAddCancelerBlk _entityAddCanceler;
  NSNumber *_foregroundEditActorId;
  NSString *_entityAddedNotificationToPost;
  NSString *_entityUpdatedNotificationToPost;
  SEL _getterForNotification;
  /*NSString *_syncImmediateInitiatedMsg;
  NSString *_syncImmediateCompleteMsg;
  NSString *_syncImmediateFailedMsg;
  NSString *_syncImmediateRetryAfterMsg;*/
  BOOL _isEntityAppropriateForBackgroundSync;
  id _newEntity;
  PEMessagesFromErrMask _messageComputer;
  PELMMainSupport *_entityCopyBeforeEdit;
  float _percentCompleteSavingEntity;
  MBProgressHUDMode _syncImmediateMBProgressHUDMode;
  NSMutableArray *_errorsForAdd;
  NSMutableArray *_successMessageTitlesForAdd;
  BOOL _receivedAuthReqdErrorOnSyncAttempt;
  BOOL _isUserLoggedIn;
}

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
getterForNotification:(SEL)getterForNotification {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _isAdd = isAdd;
    if (!isAdd) {
      _isEdit = [entity editInProgress];
      _isView = !_isEdit;
    }
    _entity = entity;
    _entityIndexPath = indexPath;
    _uitoolkit = uitoolkit;
    _itemAddedBlk = itemAddedBlk;
    _itemChangedBlk = itemChangedBlk;
    _syncInitiatedNotifName = syncInitiatedNotifName;
    _syncedNotifName = syncedNotifName;
    _syncFailedNotifName = syncFailedNotifName;
    _entityRemotelyDeletedNotifName = entityRemotelyDeletedNotifName;
    _entityLocallyUpdatedNotifNames = entityLocallyUpdatedNotifNames;
    _entityRemotelyUpdatedNotifName = entityRemotelyUpdatedNotifName;
    _entityPanelMaker = entityPanelMaker;
    _entityToPanelBinder = entityToPanelBinder;
    _panelToEntityBinder = panelToEntityBinder;
    _entityTitle = entityTitle;
    _panelEnablerDisabler = panelEnablerDisabler;
    _entityAddCanceler = entityAddCanceler;
    _entityEditPreparer = entityEditPreparer;
    _entityEditCanceler = entityEditCanceler;
    _entityMaker = entityMaker;
    _entitySaver = entitySaver;
    _newEntitySaver = newEntitySaver;
    _doneEditingEntityMarker = doneEditingEntityMarker;
    _syncImmediateWhenDoneEditing = syncImmediateWhenDoneEditing;
    _isUserLoggedIn = isUserLoggedIn;
    _syncImmediateMBProgressHUDMode = syncImmediateMBProgressHUDMode;
    /*_syncImmediateInitiatedMsg = syncImmediateInitiatedMsg;
    _syncImmediateCompleteMsg = syncImmediateCompleteMsg;
    _syncImmediateRetryAfterMsg = syncImmediateRetryAfterMsg;
    _syncImmediateFailedMsg = syncImmediateFailedMsg;*/
    _isEntityAppropriateForBackgroundSync = isEntityAppropriateForBackgroundSync;
    _prepareUIForUserInteractionBlk = prepareUIForUserInteractionBlk;
    _viewDidAppearBlk = viewDidAppearBlk;
    _entityValidator = entityValidator;
    _messageComputer = messageComputer;
    _foregroundEditActorId = foregroundEditActorId;
    _entityAddedNotificationToPost = entityAddedNotificationToPost;
    _entityUpdatedNotificationToPost = entityUpdatedNotificationToPost;
    _getterForNotification = getterForNotification;
    _errorsForAdd = [NSMutableArray array];
    _successMessageTitlesForAdd = [NSMutableArray array];
  }
  return self;
}

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
                    isEntityAppropriateForBackgroundSync:(BOOL)isEntityAppropriateForBackgroundSync {
  return [PEAddViewEditController addEntityCtrlrWithUitoolkit:uitoolkit
                                                 itemAddedBlk:itemAddedBlk
                                             entityPanelMaker:entityPanelMaker
                                          entityToPanelBinder:entityToPanelBinder
                                          panelToEntityBinder:panelToEntityBinder
                                                  entityTitle:entityTitle
                                            entityAddCanceler:entityAddCanceler
                                                  entityMaker:entityMaker
                                               newEntitySaver:newEntitySaver
                               prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                             viewDidAppearBlk:viewDidAppearBlk
                                              entityValidator:entityValidator
                                              messageComputer:messageComputer
                                        foregroundEditActorId:foregroundEditActorId
                                entityAddedNotificationToPost:entityAddedNotificationToPost
                                 syncImmediateWhenDoneEditing:syncImmediateWhenDoneEditing
                                               isUserLoggedIn:isUserLoggedIn
                               syncImmediateMBProgressHUDMode:syncImmediateMBProgressHUDMode
                         isEntityAppropriateForBackgroundSync:isEntityAppropriateForBackgroundSync
                                        getterForNotification:nil];
}

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
                                   getterForNotification:(SEL)getterForNotification {
  return [[PEAddViewEditController alloc] initWithEntity:nil
                                                   isAdd:YES
                                               indexPath:nil
                                               uitoolkit:uitoolkit
                                            itemAddedBlk:itemAddedBlk
                                          itemChangedBlk:nil
                                  syncInitiatedNotifName:nil
                                         syncedNotifName:nil
                                     syncFailedNotifName:nil
                          entityRemotelyDeletedNotifName:nil
                          entityLocallyUpdatedNotifNames:nil
                          entityRemotelyUpdatedNotifName:nil
                                        entityPanelMaker:entityPanelMaker
                                     entityToPanelBinder:entityToPanelBinder
                                     panelToEntityBinder:panelToEntityBinder
                                             entityTitle:entityTitle
                                    panelEnablerDisabler:nil
                                       entityAddCanceler:entityAddCanceler
                                      entityEditPreparer:nil
                                      entityEditCanceler:nil
                                             entityMaker:entityMaker
                                             entitySaver:nil
                                          newEntitySaver:newEntitySaver
                                 doneEditingEntityMarker:nil
                            syncImmediateWhenDoneEditing:syncImmediateWhenDoneEditing
                                          isUserLoggedIn:isUserLoggedIn
                          syncImmediateMBProgressHUDMode:syncImmediateMBProgressHUDMode
                               /*syncImmediateInitiatedMsg:nil
                                syncImmediateCompleteMsg:nil
                                  syncImmediateFailedMsg:nil
                              syncImmediateRetryAfterMsg:nil*/
                     isEntityAppropriateForBackgroundSync:isEntityAppropriateForBackgroundSync
                          prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                        viewDidAppearBlk:viewDidAppearBlk
                                         entityValidator:entityValidator
                                         messageComputer:messageComputer
                                   foregroundEditActorId:foregroundEditActorId
                           entityAddedNotificationToPost:entityAddedNotificationToPost
                         entityUpdatedNotificationToPost:nil
                                   getterForNotification:getterForNotification];
}

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
                             /*syncImmediateInitiatedMsg:(NSString *)syncImmediateInitiatedMsg
                              syncImmediateCompleteMsg:(NSString *)syncImmediateCompleteMsg
                                syncImmediateFailedMsg:(NSString *)syncImmediateFailedMsg
                            syncImmediateRetryAfterMsg:(NSString *)syncImmediateRetryAfterMsg*/
                   isEntityAppropriateForBackgroundSync:(BOOL)isEntityAppropriateForBackgroundSync
                        prepareUIForUserInteractionBlk:(PEPrepareUIForUserInteractionBlk)prepareUIForUserInteractionBlk
                                      viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
                                       entityValidator:(PEEntityValidatorBlk)entityValidator
                                       messageComputer:(PEMessagesFromErrMask)messageComputer
                                 foregroundEditActorId:(NSNumber *)foregroundEditActorId
                       entityUpdatedNotificationToPost:(NSString *)entityUpdatedNotificationToPost {
  return [[PEAddViewEditController alloc] initWithEntity:entity
                                                   isAdd:NO
                                               indexPath:entityIndexPath
                                               uitoolkit:uitoolkit
                                            itemAddedBlk:nil
                                          itemChangedBlk:itemChangedBlk
                                  syncInitiatedNotifName:syncInitiatedNotifName
                                         syncedNotifName:syncedNotifName
                                     syncFailedNotifName:syncFailedNotifName
                          entityRemotelyDeletedNotifName:entityRemotelyDeletedNotifName
                          entityLocallyUpdatedNotifNames:entityLocallyUpdatedNotifNames
                          entityRemotelyUpdatedNotifName:entityRemotelyUpdatedNotifName
                                        entityPanelMaker:entityPanelMaker
                                     entityToPanelBinder:entityToPanelBinder
                                     panelToEntityBinder:panelToEntityBinder
                                             entityTitle:entityTitle
                                    panelEnablerDisabler:panelEnablerDisabler
                                       entityAddCanceler:entityAddCanceler
                                      entityEditPreparer:entityEditPreparer
                                      entityEditCanceler:entityEditCanceler
                                             entityMaker:nil
                                             entitySaver:entitySaver
                                          newEntitySaver:nil
                                 doneEditingEntityMarker:doneEditingEntityMarker
                            syncImmediateWhenDoneEditing:syncImmediateWhenDoneEditing
                                          isUserLoggedIn:isUserLoggedIn
                          syncImmediateMBProgressHUDMode:syncImmediateMBProgressHUDMode
                               /*syncImmediateInitiatedMsg:syncImmediateInitiatedMsg
                                syncImmediateCompleteMsg:syncImmediateCompleteMsg
                                  syncImmediateFailedMsg:syncImmediateFailedMsg
                              syncImmediateRetryAfterMsg:syncImmediateRetryAfterMsg*/
                     isEntityAppropriateForBackgroundSync:isEntityAppropriateForBackgroundSync
                          prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                        viewDidAppearBlk:viewDidAppearBlk
                                         entityValidator:entityValidator
                                         messageComputer:messageComputer
                                   foregroundEditActorId:foregroundEditActorId
                           entityAddedNotificationToPost:nil
                         entityUpdatedNotificationToPost:entityUpdatedNotificationToPost
                                   getterForNotification:nil];
}

#pragma mark - Helpers

- (void)displayHeadsUpAlertWithMsgs:(NSArray *)msgs {
  [PEUIUtils showAlertWithMsgs:msgs title:@"Heads Up!" buttonTitle:@"Okay"];
}

#pragma mark - Notification Observing

- (void)dataObjectLocallyUpdated:(NSNotification *)notification {
  // this can only happen while the user is viewing the entity (because by definition,
  // if the user is editing the entity, nothing else locally would have the ability
  // to (as per our design vis-a-vis the 'editInProgress' flag)
  NSNumber *indexOfNotifEntity =
    [PELMNotificationUtils indexOfEntityRef:_entity notification:notification];
  if (indexOfNotifEntity) {
    PELMMainSupport *locallyUpdatedEntity =
      [PELMNotificationUtils entityAtIndex:[indexOfNotifEntity integerValue]
                              notification:notification];
    DDLogDebug(@"PEAVEC/locallyUpdatedEntity: %@", locallyUpdatedEntity);
    // the thing is, THIS view controller will raise 'object updated' notifications
    // associated with _entity, and so will receive them!  So, we do a reference-compare;
    // if the notification is for the entity in our context, we can safely ignore it.
    if (_entity != locallyUpdatedEntity) {
      [self displayHeadsUpAlertWithMsgs:@[LS(@"vieweditentity.headsup.whileviewing.locallyupdated.msg1"),
                                          LS(@"vieweditentity.headsup.whileviewing.locallyupdated.msg2")]];
      [_entity overwrite:(PELMMainSupport *)locallyUpdatedEntity];
      _entityToPanelBinder(_entity, _entityPanel);
    } else {
      DDLogDebug(@"in PEAVEC/dataObjectLocallyUpdated:, ignoring notification due to equality match w/_entity.");
    }
  }
}

- (void)dataObjectSyncInitiated:(NSNotification *)notification {
  if (!_syncImmediateWhenDoneEditing) {
    NSNumber *indexOfNotifEntity =
      [PELMNotificationUtils indexOfEntityRef:_entity notification:notification];
    if (indexOfNotifEntity) {
      [PEUIUtils displayTempNotification:@"Sync initiated for this record."
                           forController:self
                               uitoolkit:_uitoolkit];
    }
  }
}

- (void)dataObjectSynced:(NSNotification *)notification {
  if (!_syncImmediateWhenDoneEditing) {
    NSNumber *indexOfNotifEntity =
      [PELMNotificationUtils indexOfEntityRef:_entity notification:notification];
    if (indexOfNotifEntity) {
      [PEUIUtils displayTempNotification:@"Sync complete for this record."
                           forController:self
                               uitoolkit:_uitoolkit];
    }
  }
}

- (void)dataObjectSyncFailed:(NSNotification *)notification {
  if (!_syncImmediateWhenDoneEditing) {
    NSNumber *indexOfNotifEntity =
      [PELMNotificationUtils indexOfEntityRef:_entity notification:notification];
    if (indexOfNotifEntity) {
      [PEUIUtils displayTempNotification:@"Sync failed for this record."
                           forController:self
                               uitoolkit:_uitoolkit];
    }
  }
}

#pragma mark - NSObject

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View Controller Lifecyle

- (void)viewWillDisappear:(BOOL)animated {
  if ([self isMovingFromParentViewController]) {
    DDLogDebug(@"Removing PEAVEC as a notification observer.");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
  }
  [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  if (_isAdd || _isEdit) {
    if (_prepareUIForUserInteractionBlk) {
      _prepareUIForUserInteractionBlk(_entityPanel);
    }
  }
  if (_viewDidAppearBlk) {
    _viewDidAppearBlk(_entityPanel);
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  UINavigationItem *navItem = [self navigationItem];
  _backButton = [navItem leftBarButtonItem];

  /* Setup Notification observing */
  [PEUtils observeIfNotNilNotificationName:_syncInitiatedNotifName
                                  observer:self
                                  selector:@selector(dataObjectSyncInitiated:)];
  [PEUtils observeIfNotNilNotificationName:_syncedNotifName
                                  observer:self
                                  selector:@selector(dataObjectSynced:)];
  [PEUtils observeIfNotNilNotificationName:_syncFailedNotifName
                                  observer:self
                                  selector:@selector(dataObjectSyncFailed:)];
  if (_entityLocallyUpdatedNotifNames) {
    for (NSString *entityLocallyUpdatedNotifName in _entityLocallyUpdatedNotifNames) {
      [PEUtils observeIfNotNilNotificationName:entityLocallyUpdatedNotifName
                                      observer:self
                                      selector:@selector(dataObjectLocallyUpdated:)];
    }
  }
  _entityPanel = _entityPanelMaker(self);
  [self setEdgesForExtendedLayout:UIRectEdgeNone];
  [PEUIUtils placeView:_entityPanel
               atTopOf:[self view]
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:0 // parameterize this value too?
              hpadding:0];

  NSString *title;
  if (_isView) {
    title = _entityTitle;
    _panelEnablerDisabler(_entityPanel, NO);
  } else if (_isEdit) {
    title = [NSString stringWithFormat:@"Edit %@", _entityTitle];
    [self prepareForEditing];
  } else {
    title = [NSString stringWithFormat:@"Add %@", _entityTitle];
  }
  _entityToPanelBinder(_entity, _entityPanel);

  // ---------------------------------------------------------------------------
  // Setup the navigation item (left/center/right areas)
  // ---------------------------------------------------------------------------
  [navItem setTitle:title];
  if (_isView) {
    [navItem setRightBarButtonItem:[self editButtonItem]];
  } else {
    [navItem setLeftBarButtonItem:[[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                   target:self
                                   action:@selector(cancelAddEdit)]];
    if (_isAdd) {
      [navItem setRightBarButtonItem:[[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self
                                      action:@selector(doneWithAdd)]];
    } else {
      [navItem setRightBarButtonItem:[[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self
                                      action:@selector(doneWithEdit)]];
    }
  }
  if ([_entity syncInProgress]) {
    [[self editButtonItem] setEnabled:NO];
    [PEUIUtils displayTempNotification:@"Sync in progress for this record."
                         forController:self
                             uitoolkit:_uitoolkit];
  }
}

#pragma mark - Toggle into edit mode

- (void)setEditing:(BOOL)flag animated:(BOOL)animated {
  if (flag) {
    _entityCopyBeforeEdit = [_entity copy];
    if ([self prepareForEditing]) {
      [super setEditing:flag animated:animated];
      if (_prepareUIForUserInteractionBlk) {
        _prepareUIForUserInteractionBlk(_entityPanel);
      }
    }
  } else {
    if ([self stopEditing]) {
      [super setEditing:flag animated:animated];
    }
  }
}

#pragma mark - UI state changes

- (BOOL)prepareForEditing {
  BOOL editPrepareSuccess = YES;
  if (![_entity editInProgress]) {
    editPrepareSuccess = _entityEditPreparer(self, _entity);
  }
  if (editPrepareSuccess) {
    [[self navigationItem] setTitle:[NSString stringWithFormat:@"Edit %@", _entityTitle]];
    [[self navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc]
                                                 initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                 target:self
                                                 action:@selector(cancelAddEdit)]];
    _panelEnablerDisabler(_entityPanel, YES);
  }
  return editPrepareSuccess;
}

- (BOOL)stopEditing {
  void (^postEditActivities)(void) = ^{
    if (_itemChangedBlk) {
      _itemChangedBlk(_entity, _entityIndexPath);
    }
    [self.navigationItem setHidesBackButton:NO animated:YES];
    [[[self navigationItem] rightBarButtonItem] setEnabled:YES];
    [[[self tabBarController] tabBar] setUserInteractionEnabled:YES];
    [[self navigationItem] setLeftBarButtonItem:_backButton];
    [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];
    [[self navigationItem] setTitle:_entityTitle];
    _panelEnablerDisabler(_entityPanel, NO);
    [PELMNotificationUtils postNotificationWithName:_entityUpdatedNotificationToPost
                                             entity:_entity];
  };
  if (_isEditCanceled) {
    _entityEditCanceler(self, _entity);
    _entityToPanelBinder(_entity, _entityPanel);
    _isEditCanceled = NO;
    postEditActivities();
  } else {
    NSArray *errMsgs = _entityValidator(_entityPanel);
    BOOL isValidEntity = YES;
    if (errMsgs && [errMsgs count] > 0) {
      isValidEntity = NO;
    }
    if (isValidEntity) {
      _panelToEntityBinder(_entityPanel, _entity);
      _entitySaver(self, _entity);
      if (_syncImmediateWhenDoneEditing) {
        MBProgressHUD *_HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [self.navigationItem setHidesBackButton:YES animated:YES];
        [[[self navigationItem] rightBarButtonItem] setEnabled:NO];
        [[[self tabBarController] tabBar] setUserInteractionEnabled:NO];
        _HUD.delegate = self;
        _HUD.labelText = @"Attempting to sync edits to server.";
        void(^syncSuccessBlk)(float, NSString *, NSString *) = ^(float percentComplete, NSString *mainMsgTitle, NSString *successMsg) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [_HUD setLabelText:@"Success!"];
            [_HUD setDetailsLabelText:successMsg];
            __block UIImageView *imageView;
            UIImage *image = [UIImage imageNamed:@"hud-complete"];
            imageView = [[UIImageView alloc] initWithImage:image];
            [_HUD setCustomView:imageView];
            _HUD.mode = MBProgressHUDModeCustomView;
            [_HUD hide:YES afterDelay:1.30];
            postEditActivities();
          });
        };
        void (^genericTempFailureHandler)(float) = ^(float percentComplete) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [_HUD hide:YES afterDelay:0];
            if (_isEntityAppropriateForBackgroundSync) {
              UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Temporary Connection Issue"
                                                                             message:@"We're sorry, but there was a problem communicating with the server.  We are currently working on the problem.  You can sync this edit (and all other edits) later from the main 'Quick Launch' screen or from the 'Settings' screen."
                                                                      preferredStyle:UIAlertControllerStyleAlert];
              UIAlertAction *syncLater = [UIAlertAction actionWithTitle:@"I'll sync this later."
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction *action) { [[self navigationController] popViewControllerAnimated:YES]; }];
              UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Forget it.  Just cancel these edits."
                                                               style:UIAlertActionStyleDestructive
                                                             handler:^(UIAlertAction *action) {
                                                               [_entityCopyBeforeEdit setEditInProgress:YES];
                                                               [_entityCopyBeforeEdit incrementEditCount];
                                                               _entitySaver(self, _entityCopyBeforeEdit);
                                                               _entityEditCanceler(self, _entityCopyBeforeEdit);
                                                               [[self navigationController] popViewControllerAnimated:YES];
                                                             }];
              [alert addAction:syncLater];
              [alert addAction:cancel];
              [self presentViewController:alert animated:YES completion:nil];
            } else {
              UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Temporary Connection Issue"
                                                                             message:@"We're sorry, but there was a problem communicating with the server.  We are currently working on the problem."
                                                                      preferredStyle:UIAlertControllerStyleAlert];
              UIAlertAction *comeBackLater = [UIAlertAction actionWithTitle:@"Come back later and try again."
                                                                      style:UIAlertActionStyleDefault
                                                                    handler:^(UIAlertAction *action) {
                                                                      [_entity setEditInProgress:YES]; // needed so that canceler can be called w/out its consistency-check blowing-up
                                                                      _entityEditCanceler(self, _entity);
                                                                      [[self navigationController] popViewControllerAnimated:YES];
                                                                    }];
              [alert addAction:comeBackLater];
              [self presentViewController:alert animated:YES completion:nil];
            }
          });
        };
        void(^syncRetryAfterBlk)(float, NSString *, NSString *, NSDate *) = ^(float percentComplete, NSString *mainMsgTitle, NSString *errMsgTitle, NSDate *retryAfter) {
          genericTempFailureHandler(percentComplete);
        };
        void (^syncServerTempError)(float, NSString *, NSString *) = ^(float percentComplete, NSString *mainMsgTitle, NSString *errMsgTitle) {
          genericTempFailureHandler(percentComplete);
        };
        void (^syncServerError)(float, NSString *, NSString *, NSInteger) = ^(float percentComplete, NSString *mainMsgTitle, NSString *errMsgTitle, NSInteger errorMask) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [_HUD hide:YES afterDelay:0];
            NSArray *msgs = _messageComputer(errorMask);
            NSString *errorMessage;
            if ([msgs count] == 0) {
              errorMessage = @"There was a problem saving your edits.\nThere are no details from\nthe server though.  Sorry.";
            } else if ([msgs count] == 1) {
              errorMessage = @"There was a problem saving your edits.\nThe message from the server is:\n\n";
            } else {
              errorMessage = @"There was a problem saving your edits.\nThe messages from the server are:\n\n";
            }
            errorMessage = [errorMessage stringByAppendingString:[PEUtils concat:msgs]];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                           message:errorMessage
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *fixNow = [UIAlertAction actionWithTitle:@"Okay.  I'll fix them now."
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
                                                             _entityEditPreparer(self, _entity);
                                                             [super setEditing:YES animated:NO];
                                                             [[[self navigationItem] rightBarButtonItem] setEnabled:YES];
                                                           }];
            UIAlertAction *fixLater = [UIAlertAction actionWithTitle:@"I'll fix them later."
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                                                               postEditActivities();
                                                             }];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Forget it.  Just cancel these edits."
                                                             style:UIAlertActionStyleDestructive
                                                           handler:^(UIAlertAction *action) {
                                                             [_entity setEditInProgress:YES]; // needed so that canceler can be called w/out its consistency-check blowing-up
                                                             _entityEditCanceler(self, _entity);
                                                             _entityToPanelBinder(_entity, _entityPanel);
                                                             _isEditCanceled = NO; // reset this to NO
                                                             postEditActivities();
                                                           }];
            [alert addAction:fixNow];
            [alert addAction:fixLater];
            [alert addAction:cancel];
            [self presentViewController:alert animated:YES completion:nil];
          });
        };
        void(^syncAuthReqdBlk)(float, NSString *, NSString *) = ^(float percentComplete, NSString *mainMsgTitle, NSString *errMsgTitle) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [_HUD hide:YES afterDelay:0];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Authentication Error"
                                                                           message:@"It would seem you're no longer authenticated.  Please sign-in."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *ack = [UIAlertAction actionWithTitle:@"Okay"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action) {
                                                          postEditActivities();
                                                        }];
            [alert addAction:ack];
            [self presentViewController:alert animated:YES completion:nil];
          });
        };
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
          _doneEditingEntityMarker(self, _entity, syncSuccessBlk, syncRetryAfterBlk, syncServerTempError, syncServerError, syncAuthReqdBlk);
        });
      } else {
        _doneEditingEntityMarker(self, _entity, nil, nil, nil, nil, nil);
        postEditActivities();
      }
    } else {
      [PEUIUtils showAlertWithMsgs:errMsgs title:@"Oops" buttonTitle:@"Okay"];
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

- (void)doneWithAdd {
  NSArray *errMsgs = _entityValidator(_entityPanel);
  BOOL isValidEntity = YES;
  if (errMsgs && [errMsgs count] > 0) {
    isValidEntity = NO;
  }
  if (isValidEntity) {
    _newEntity = _entityMaker(_entityPanel);
    void (^notificationSenderForAdd)(id) = ^(id theNewEntity) {
      id newEntityForNotification = theNewEntity;
      if (_getterForNotification) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        newEntityForNotification = [theNewEntity performSelector:_getterForNotification];
        #pragma clang diagnostic pop
      }
      [PELMNotificationUtils postNotificationWithName:_entityAddedNotificationToPost
                                               entity:newEntityForNotification];
    };
    if (_syncImmediateWhenDoneEditing) {
      
      
      // TODO - invoke block that takes _newEntity and returns an array of
      // error messages; a non-empty array indicates _newEntity cannot be
      // remotely synced because of invalid state (most likely due to dependencies
      // it has are not currently synced).  So, if non-empty array is returned,
      // display an alert controller displaying them with 2 available actions:
      // 1. 'Just save it locally.  I'll sync it later.', and 2. 'Forget it.  Just
      // cancel this record.'
      
      void (^reenableScreen)(void) = ^{        
        [[[self navigationItem] rightBarButtonItem] setEnabled:YES];
        [[[self tabBarController] tabBar] setUserInteractionEnabled:YES];
      };
      MBProgressHUD *_HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      [self.navigationItem setHidesBackButton:YES animated:YES];
      [[[self navigationItem] rightBarButtonItem] setEnabled:NO];
      [[[self tabBarController] tabBar] setUserInteractionEnabled:NO];
      _HUD.delegate = self;
      _HUD.mode = _syncImmediateMBProgressHUDMode;
      _HUD.labelText = @"Syncing to server...";
      _percentCompleteSavingEntity = 0.0;
      _HUD.progress = _percentCompleteSavingEntity;
      [_errorsForAdd removeAllObjects];
      [_successMessageTitlesForAdd removeAllObjects];
      _receivedAuthReqdErrorOnSyncAttempt = NO;
      
      /*void(^syncSuccessBlk)(float) = ^(float percentComplete) {
        _percentCompleteSavingEntity += percentComplete;
        if (_percentCompleteSavingEntity == 1.0) {
          notificationSenderForAdd(_newEntity);
          dispatch_async(dispatch_get_main_queue(), ^{
            [_HUD setLabelText:@"Success!"];
            [_HUD setDetailsLabelText:@"Your record was synced to the server."];
            __block UIImageView *imageView;
            UIImage *image = [UIImage imageNamed:@"hud-complete"];
            imageView = [[UIImageView alloc] initWithImage:image];
            [_HUD setCustomView:imageView];
            _HUD.mode = MBProgressHUDModeCustomView;
            [_HUD hide:YES afterDelay:1.30];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
              _itemAddedBlk(self, _newEntity);  // this is what causes this controller to be dismissed
            });
          });
        } else {
          dispatch_async(dispatch_get_main_queue(), ^{
            _HUD.progress = _percentCompleteSavingEntity;
          });
        }
        
      };
      void (^genericTempFailureHandler)(float) = ^(float percentComplete) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [_HUD hide:YES afterDelay:0];
          if (_isEntityAppropriateForBackgroundSync) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Temporary Connection Issue"
                                                                           message:@"We're sorry, but there was a problem communicating with the server.  We are currently working on the problem.  You can sync this record (and all other edits) later from the main 'Quick Launch' screen or from the 'Settings' screen." 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *syncLater = [UIAlertAction actionWithTitle:@"I'll sync this later."
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action) {
                                                                _itemAddedBlk(self, _newEntity);
                                                                notificationSenderForAdd(_newEntity);
                                                              }];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Forget it.  Just cancel this record."
                                                             style:UIAlertActionStyleDestructive
                                                           handler:^(UIAlertAction *action) {
                                                             _entityAddCanceler(self, _newEntity); // should cause controller to be dismissed
                                                           }];
            [alert addAction:syncLater];
            [alert addAction:cancel];
            [self presentViewController:alert animated:YES completion:nil];
          } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Temporary Connection Issue"
                                                                           message:@"We're sorry, but there was a problem communicating with the server.  We are currently working on the problem."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *comeBackLater = [UIAlertAction actionWithTitle:@"Come back later and try again."
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction *action) {
                                                                    _entityAddCanceler(self, _newEntity); // should cause controller to be dismissed
                                                                    notificationSenderForAdd(_newEntity);
                                                                  }];
            [alert addAction:comeBackLater];
            [self presentViewController:alert animated:YES completion:nil];
          }
        });
      };
      void(^syncRetryAfterBlk)(float, NSDate *) = ^(float percentComplete, NSDate *retryAfter) {
        genericTempFailureHandler(percentComplete);
      };
      void (^syncServerTempError)(float) = ^(float percentComplete) {
        genericTempFailureHandler(percentComplete);
      };
      void (^syncServerError)(float, NSInteger) = ^(float percentComplete, NSInteger errorMask) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [_HUD hide:YES afterDelay:0];
          NSArray *msgs = _messageComputer(errorMask);
          NSString *errorMessage;
          if ([msgs count] == 0) {
            errorMessage = @"There was a problem saving your\nrecord.  There are no details from\nthe server though.  Sorry.";
          } else if ([msgs count] == 1) {
            errorMessage = @"There was a problem saving your\nrecord.  The message from\nthe server is:\n\n";
          } else {
            errorMessage = @"There was a problem saving your\nrecord.  The messages from\nthe server are:\n\n";
          }
          errorMessage = [errorMessage stringByAppendingString:[PEUtils concat:msgs]];
          UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                         message:errorMessage
                                                                  preferredStyle:UIAlertControllerStyleAlert];
          UIAlertAction *fixNow = [UIAlertAction actionWithTitle:@"I'll fix it now."
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                        reenableScreen();
                                                      }];
          UIAlertAction *fixLater = [UIAlertAction actionWithTitle:@"I'll fix the issues later."
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                        notificationSenderForAdd(_newEntity);
                                                        _itemAddedBlk(self, _newEntity); // causes screen to be dismissed
                                                      }];
          UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Forget it.  Just cancel this record."
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *action) {
                                                           _entityAddCanceler(self, _newEntity); // should cause controller to be dismissed
                                                         }];
          [alert addAction:fixNow];
          [alert addAction:fixLater];
          [alert addAction:cancel];
          [self presentViewController:alert animated:YES completion:nil];
        });
      };
      void(^syncAuthReqdBlk)(float) = ^(float percentCopmlete) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [_HUD hide:YES afterDelay:0];
          UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Authentication Error"
                                                                         message:@"It would seem you're no longer authenticated.  Please sign-in."
                                                                  preferredStyle:UIAlertControllerStyleAlert];
          UIAlertAction *ack = [UIAlertAction actionWithTitle:@"Okay"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                        reenableScreen();
                                                      }];
          [alert addAction:ack];
          [self presentViewController:alert animated:YES completion:nil];
        });
      };*/
      
      void(^immediateSaveDone)(NSString *) = ^(NSString *mainMsgTitle) {
        BOOL isMultiStepAdd = ([_errorsForAdd count] + [_successMessageTitlesForAdd count]) > 1;
        if ([_errorsForAdd count] == 0) {
          notificationSenderForAdd(_newEntity);
          dispatch_async(dispatch_get_main_queue(), ^{
            if (isMultiStepAdd) {
              [_HUD hide:YES afterDelay:0];
              // all successes
              NSString *title = [NSString stringWithFormat:@"Success %@", mainMsgTitle];
              NSMutableString *message = [NSMutableString string];
              [message appendString:@"\n\n"];
              [message appendString:[PEUtils concat:_successMessageTitlesForAdd]];
              UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
              UIAlertAction *okay = [UIAlertAction actionWithTitle:@"Okay."
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
                                                             notificationSenderForAdd(_newEntity);
                                                             _itemAddedBlk(self, _newEntity);}];
              [alert addAction:okay];
              [self presentViewController:alert animated:YES completion:nil];
            } else {
              // single add success
              [_HUD setLabelText:_successMessageTitlesForAdd[0]];
              UIImage *image = [UIImage imageNamed:@"hud-complete"];
              UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
              [_HUD setCustomView:imageView];
              _HUD.mode = MBProgressHUDModeCustomView;
              [_HUD hide:YES afterDelay:1.30];
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                _itemAddedBlk(self, _newEntity);  // this is what causes this controller to be dismissed
              });
            }
          });
        } else {
          // mixed results or only errors
          dispatch_async(dispatch_get_main_queue(), ^{
            [_HUD hide:YES afterDelay:0];
            if ([_successMessageTitlesForAdd count] > 0) {
              // mixed results
              NSString *title = [NSString stringWithFormat:@"Mixed results %@", mainMsgTitle];
              NSMutableString *message = [NSMutableString string];
              [message appendString:@"Because the results are mixed, you\n"];
              [message appendString:@"need to fix the errors on the\n"];
              [message appendString:@"individual affected records.\n\n"];
              [message appendString:@"Successes:\n\n"];
              [message appendString:[PEUtils concat:_successMessageTitlesForAdd]];
              [message appendString:@"\n\nErrors:\n"];
              for (NSArray *error in _errorsForAdd) {
                [message appendFormat:@"\n%@", error[0]]; // error message title
                NSArray *subErrors = error[2];
                for (NSString *subError in subErrors) {
                  [message appendFormat:@"\n\t%@", subError];
                }
              }
              if (_receivedAuthReqdErrorOnSyncAttempt) {
                [message appendString:@"\n\nIt appears that you are not longer\n"];
                [message appendString:@"authenticated.  To re-authenticate, \ngo to "];
                [message appendString:@"Settings -> Authenticate."];
              }
              UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
              UIAlertAction *okay = [UIAlertAction actionWithTitle:@"Okay."
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
                                                                 notificationSenderForAdd(_newEntity);
                                                                 _itemAddedBlk(self, _newEntity);}];
              [alert addAction:okay];
              [self presentViewController:alert animated:YES completion:nil];
            } else {
              // only error(s)
              NSString *title;
              NSString *fixNowActionTitle;
              NSString *fixLaterActionTitle;
              NSString *dealWithLaterActionTitle;
              NSString *cancelActionTitle;
              NSMutableString *message = [NSMutableString string];
              if (isMultiStepAdd) {
                fixNowActionTitle = @"I'll fix them now.";
                fixLaterActionTitle = @"I'll fix them later.";
                cancelActionTitle = @"Forget it.  Just cancel them.";
                dealWithLaterActionTitle = @"I'll deal with them later.";
                title = [NSString stringWithFormat:@"Error %@", mainMsgTitle];
                for (NSArray *error in _errorsForAdd) {
                  [message appendFormat:@"\n%@", error[0]]; // because multi-record add, we display each record's "not saved" msg title
                  NSArray *subErrors = error[2];
                  for (NSString *subError in subErrors) {
                    [message appendFormat:@"\n\t%@", subError];
                  }
                }
              } else {
                NSArray *subErrors = _errorsForAdd[0][2]; // because only single-record add, we can skip the "not saved" msg title, and just display the sub-errors
                if ([subErrors count] > 1) {
                  fixNowActionTitle = @"I'll fix them now.";
                  fixLaterActionTitle = @"I'll fix them later.";
                  dealWithLaterActionTitle = @"I'll deal with them later.";
                  cancelActionTitle = @"Forget it.  Just cancel them.";
                  title = [NSString stringWithFormat:@"Errors %@", mainMsgTitle];
                } else {
                  fixLaterActionTitle = @"I'll fix it later.";
                  fixNowActionTitle = @"I'll fix it now.";
                  dealWithLaterActionTitle = @"I'll deal with it later.";
                  cancelActionTitle = @"Forget it.  Just cancel it.";
                  title = [NSString stringWithFormat:@"Error %@", mainMsgTitle];
                }
                for (NSString *subError in subErrors) {
                  [message appendFormat:@"\n%@", subError];
                }
              }
              if (_receivedAuthReqdErrorOnSyncAttempt) {
                [message appendString:@"\n\nIt appears that you are not longer\n"];
                [message appendString:@"authenticated.  To re-authenticate, go to\n"];
                [message appendString:@"Settings -> Authenticate."];
              }
              UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
              if ([PEAddViewEditController areErrorsAllUserFixable:_errorsForAdd]) {
                UIAlertAction *fixNow = [UIAlertAction actionWithTitle:fixNowActionTitle
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction *action){reenableScreen();}];
                UIAlertAction *fixLater = [UIAlertAction actionWithTitle:fixLaterActionTitle
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *action) {
                                                                   notificationSenderForAdd(_newEntity);
                                                                   _itemAddedBlk(self, _newEntity);}];
                [alert addAction:fixNow];
                [alert addAction:fixLater];
              } else {
                UIAlertAction *dealWithLater = [UIAlertAction actionWithTitle:dealWithLaterActionTitle
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction *action) {
                                                                        notificationSenderForAdd(_newEntity);
                                                                        _itemAddedBlk(self, _newEntity);}];
                [alert addAction:dealWithLater];
              }              
              UIAlertAction *cancel = [UIAlertAction actionWithTitle:cancelActionTitle
                                                               style:UIAlertActionStyleDestructive
                                                             handler:^(UIAlertAction *action){_entityAddCanceler(self, _newEntity);}];
              [alert addAction:cancel];
              [self presentViewController:alert animated:YES completion:nil];
            }
          });
        }
      };
      
      void (^handleHudProgress)(float) = ^(float percentComplete) {
        _percentCompleteSavingEntity += percentComplete;
        dispatch_async(dispatch_get_main_queue(), ^{
          _HUD.progress = _percentCompleteSavingEntity;
        });
      };
      void(^_syncSuccessBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                NSString *mainMsgTitle,
                                                                NSString *recordTitle) {
        handleHudProgress(percentComplete);
        [_successMessageTitlesForAdd addObject:[NSString stringWithFormat:@"%@ saved", recordTitle]];
        if (_percentCompleteSavingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      void(^_syncRetryAfterBlk)(float, NSString *, NSString *, NSDate *) = ^(float percentComplete,
                                                                             NSString *mainMsgTitle,
                                                                             NSString *recordTitle,
                                                                             NSDate *retryAfter) {
        handleHudProgress(percentComplete);
        [_errorsForAdd addObject:@[[NSString stringWithFormat:@"%@ not saved", recordTitle],
                                   [NSNumber numberWithBool:NO],
                                   @[[NSString stringWithFormat:@"Server busy.  Retry after: %@", retryAfter]]]];
        if (_percentCompleteSavingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      void (^_syncServerTempError)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                      NSString *mainMsgTitle,
                                                                      NSString *recordTitle) {
        handleHudProgress(percentComplete);
        [_errorsForAdd addObject:@[[NSString stringWithFormat:@"%@ not saved", recordTitle],
                                   [NSNumber numberWithBool:NO],
                                   @[@"Temporary server error."]]];
        if (_percentCompleteSavingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      void (^_syncServerError)(float, NSString *, NSString *, NSInteger) = ^(float percentComplete,
                                                                             NSString *mainMsgTitle,
                                                                             NSString *recordTitle,
                                                                             NSInteger errorMask) {
        handleHudProgress(percentComplete);
        NSArray *computedErrMsgs = _messageComputer(errorMask);
        BOOL isErrorUserFixable = YES;
        if (!computedErrMsgs || ([computedErrMsgs count] == 0)) {
          computedErrMsgs = @[@"Unknown server error."];
          isErrorUserFixable = NO;
        }
        [_errorsForAdd addObject:@[[NSString stringWithFormat:@"%@ not saved", recordTitle],
                                   [NSNumber numberWithBool:isErrorUserFixable],
                                   computedErrMsgs]];
        if (_percentCompleteSavingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      void(^_syncAuthReqdBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                 NSString *mainMsgTitle,
                                                                 NSString *recordTitle) {
        _receivedAuthReqdErrorOnSyncAttempt = YES;
        handleHudProgress(percentComplete);
        [_errorsForAdd addObject:@[[NSString stringWithFormat:@"%@ not saved", recordTitle],
                                   [NSNumber numberWithBool:NO],
                                   @[@"Authentication required."]]];
        if (_percentCompleteSavingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      
      dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        _newEntitySaver(_entityPanel,
                        _newEntity,
                        _syncSuccessBlk,
                        _syncRetryAfterBlk,
                        _syncServerTempError,
                        _syncServerError,
                        _syncAuthReqdBlk);
      });
    } else {
      _newEntitySaver(_entityPanel, _newEntity, nil, nil, nil, nil, nil);
      notificationSenderForAdd(_newEntity);
      MBProgressHUD *_HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      _HUD.delegate = self;
      [_HUD setLabelText:[NSString stringWithFormat:@"%@ Saved", _entityTitle]];
      if (_isUserLoggedIn) {
        [_HUD setDetailsLabelText:@"(not synced with server)"];
      }
      UIImage *image = [UIImage imageNamed:@"hud-complete"];
      UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
      [_HUD setCustomView:imageView];
      _HUD.mode = MBProgressHUDModeCustomView;
      [_HUD hide:YES afterDelay:1.30];
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        _itemAddedBlk(self, _newEntity);  // this is what causes this controller to be dismissed
      });
    }
  } else {
    // local (i.e., not from server) validation checking failed
    [PEUIUtils showAlertWithMsgs:errMsgs title:@"Oops" buttonTitle:@"Okay"];
  }
}

#pragma mark - Cancellation

- (void)cancelAddEdit {
  if (_isAdd) {
    _entityAddCanceler(self, _newEntity);
    _newEntity = nil;
  } else {
    _isEditCanceled = YES;
    [self setEditing:NO animated:YES]; // to get 'Done' button to turn to 'Edit'
  }
}

@end
