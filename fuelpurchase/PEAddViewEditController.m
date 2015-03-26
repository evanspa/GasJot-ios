//
//  PEAddViewEditController.m
//  fuelpurchase
//
//  Created by Evans, Paul on 9/30/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "PEAddViewEditController.h"
#import <iFuelPurchase-Core/PELMNotificationUtils.h>
#import <objc-commons/PEUIUtils.h>
#import <objc-commons/PEUtils.h>
#import "FPEditActors.h"

@implementation PEAddViewEditController {
  BOOL _isAdd;
  BOOL _isEdit;
  BOOL _isView;
  BOOL _isEditCanceled;
  BOOL _entityRemotelyDeletedWhileEditing;
  BOOL _entityRemotelyUpdatedWhileEditing;
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
  NSString *_addEntityTitle;
  NSString *_viewEntityTitle;
  NSString *_editEntityTitle;
  PEEnableDisablePanelBlk _panelEnablerDisabler;
  PEEntityEditPreparerBlk _entityEditPreparer;
  PEEntityEditCancelerBlk _entityEditCanceler;
  PEEntityMakerBlk _entityMaker;
  PESaveEntityBlk _entitySaver;
  PESaveNewEntityBlk _newEntitySaver;
  PEMarkAsDoneEditingBlk _doneEditingEntityMarker;
  PEPrepareUIForUserInteractionBlk _prepareUIForUserInteractionBlk;
  PEViewDidAppearBlk _viewDidAppearBlk;
  PEEntityValidatorBlk _entityValidator;
  PEEntityAddCancelerBlk _entityAddCanceler;
  NSNumber *_foregroundEditActorId;
  NSString *_entityAddedNotificationToPost;
  NSString *_entityUpdatedNotificationToPost;
  SEL _getterForNotification;
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
      addEntityTitle:(NSString *)addEntityTitle
     viewEntityTitle:(NSString *)viewEntityTitle
     editEntityTitle:(NSString *)editEntityTitle
panelEnablerDisabler:(PEEnableDisablePanelBlk)panelEnablerDisabler
   entityAddCanceler:(PEEntityAddCancelerBlk)entityAddCanceler
  entityEditPreparer:(PEEntityEditPreparerBlk)entityEditPreparer
  entityEditCanceler:(PEEntityEditCancelerBlk)entityEditCanceler
         entityMaker:(PEEntityMakerBlk)entityMaker
         entitySaver:(PESaveEntityBlk)entitySaver
      newEntitySaver:(PESaveNewEntityBlk)newEntitySaver
doneEditingEntityMarker:(PEMarkAsDoneEditingBlk)doneEditingEntityMarker
prepareUIForUserInteractionBlk:(PEPrepareUIForUserInteractionBlk)prepareUIForUserInteractionBlk
    viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
     entityValidator:(PEEntityValidatorBlk)entityValidator
  listViewDataSource:(id<UITableViewDataSource>)listViewDataSource
foregroundEditActorId:(NSNumber *)foregroundEditActorId
entityAddedNotificationToPost:(NSString *)entityAddedNotificationToPost
entityUpdatedNotificationToPost:(NSString *)entityUpdatedNotificationToPost
getterForNotification:(SEL)getterForNotification {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _isAdd = isAdd;
    if (!isAdd) {
      _isEdit = ([entity editInProgress] && ([[entity editActorId] isEqualToNumber:foregroundEditActorId]));
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
    _addEntityTitle = addEntityTitle;
    _viewEntityTitle = viewEntityTitle;
    _editEntityTitle = editEntityTitle;
    _panelEnablerDisabler = panelEnablerDisabler;
    _entityAddCanceler = entityAddCanceler;
    _entityEditPreparer = entityEditPreparer;
    _entityEditCanceler = entityEditCanceler;
    _entityMaker = entityMaker;
    _entitySaver = entitySaver;
    _newEntitySaver = newEntitySaver;
    _doneEditingEntityMarker = doneEditingEntityMarker;
    _prepareUIForUserInteractionBlk = prepareUIForUserInteractionBlk;
    _viewDidAppearBlk = viewDidAppearBlk;
    _entityValidator = entityValidator;
    _listViewDataSource = listViewDataSource;
    _foregroundEditActorId = foregroundEditActorId;
    _entityAddedNotificationToPost = entityAddedNotificationToPost;
    _entityUpdatedNotificationToPost = entityUpdatedNotificationToPost;
    _getterForNotification = getterForNotification;
  }
  return self;
}

#pragma mark - Factory functions

+ (PEAddViewEditController *)addEntityCtrlrWithUitoolkit:(PEUIToolkit *)uitoolkit
                                            itemAddedBlk:(PEItemAddedBlk)itemAddedBlk
                                        entityPanelMaker:(PEEntityPanelMakerBlk)entityPanelMaker
                                     entityToPanelBinder:(PEEntityToPanelBinderBlk)entityToPanelBinder
                                     panelToEntityBinder:(PEPanelToEntityBinderBlk)panelToEntityBinder
                                          addEntityTitle:(NSString *)addEntityTitle
                                       entityAddCanceler:(PEEntityAddCancelerBlk)entityAddCanceler
                                             entityMaker:(PEEntityMakerBlk)entityMaker
                                          newEntitySaver:(PESaveNewEntityBlk)newEntitySaver
                          prepareUIForUserInteractionBlk:(PEPrepareUIForUserInteractionBlk)prepareUIForUserInteractionBlk
                                        viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
                                         entityValidator:(PEEntityValidatorBlk)entityValidator
                                      listViewDataSource:(id<UITableViewDataSource>)listViewDataSource
                                   foregroundEditActorId:(NSNumber *)foregroundEditActorId
                           entityAddedNotificationToPost:(NSString *)entityAddedNotificationToPost {
  return [PEAddViewEditController addEntityCtrlrWithUitoolkit:uitoolkit
                                                 itemAddedBlk:itemAddedBlk
                                             entityPanelMaker:entityPanelMaker
                                          entityToPanelBinder:entityToPanelBinder
                                          panelToEntityBinder:panelToEntityBinder
                                               addEntityTitle:addEntityTitle
                                            entityAddCanceler:entityAddCanceler
                                                  entityMaker:entityMaker
                                               newEntitySaver:newEntitySaver
                               prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                             viewDidAppearBlk:viewDidAppearBlk
                                              entityValidator:entityValidator
                                           listViewDataSource:listViewDataSource
                                        foregroundEditActorId:foregroundEditActorId
                                entityAddedNotificationToPost:entityAddedNotificationToPost
                                        getterForNotification:nil];
}

+ (PEAddViewEditController *)addEntityCtrlrWithUitoolkit:(PEUIToolkit *)uitoolkit
                                            itemAddedBlk:(PEItemAddedBlk)itemAddedBlk
                                        entityPanelMaker:(PEEntityPanelMakerBlk)entityPanelMaker
                                     entityToPanelBinder:(PEEntityToPanelBinderBlk)entityToPanelBinder
                                     panelToEntityBinder:(PEPanelToEntityBinderBlk)panelToEntityBinder
                                          addEntityTitle:(NSString *)addEntityTitle
                                       entityAddCanceler:(PEEntityAddCancelerBlk)entityAddCanceler
                                             entityMaker:(PEEntityMakerBlk)entityMaker
                                          newEntitySaver:(PESaveNewEntityBlk)newEntitySaver
                          prepareUIForUserInteractionBlk:(PEPrepareUIForUserInteractionBlk)prepareUIForUserInteractionBlk
                                        viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
                                         entityValidator:(PEEntityValidatorBlk)entityValidator
                                      listViewDataSource:(id<UITableViewDataSource>)listViewDataSource
                                   foregroundEditActorId:(NSNumber *)foregroundEditActorId
                           entityAddedNotificationToPost:(NSString *)entityAddedNotificationToPost
                                   getterForNotification:(SEL)getterForNotification {
  return [[PEAddViewEditController alloc]
           initWithEntity:nil
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
           addEntityTitle:addEntityTitle
          viewEntityTitle:nil
          editEntityTitle:nil
     panelEnablerDisabler:nil
          entityAddCanceler:entityAddCanceler
       entityEditPreparer:nil
       entityEditCanceler:nil
              entityMaker:entityMaker
              entitySaver:nil
           newEntitySaver:newEntitySaver
  doneEditingEntityMarker:nil
prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
         viewDidAppearBlk:viewDidAppearBlk
          entityValidator:entityValidator
          listViewDataSource:listViewDataSource
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
                                       viewEntityTitle:(NSString *)viewEntityTitle
                                       editEntityTitle:(NSString *)editEntityTitle
                                  panelEnablerDisabler:(PEEnableDisablePanelBlk)panelEnablerDisabler
                                     entityAddCanceler:(PEEntityAddCancelerBlk)entityAddCanceler
                                    entityEditPreparer:(PEEntityEditPreparerBlk)entityEditPreparer
                                    entityEditCanceler:(PEEntityEditCancelerBlk)entityEditCanceler
                                           entitySaver:(PESaveEntityBlk)entitySaver
                               doneEditingEntityMarker:(PEMarkAsDoneEditingBlk)doneEditingEntityMarker
                        prepareUIForUserInteractionBlk:(PEPrepareUIForUserInteractionBlk)prepareUIForUserInteractionBlk
                                      viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
                                       entityValidator:(PEEntityValidatorBlk)entityValidator
                                    listViewDataSource:(id<UITableViewDataSource>)listViewDataSource
                                 foregroundEditActorId:(NSNumber *)foregroundEditActorId
                       entityUpdatedNotificationToPost:(NSString *)entityUpdatedNotificationToPost {
  return [[PEAddViewEditController alloc]
          initWithEntity:entity
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
          addEntityTitle:nil
         viewEntityTitle:viewEntityTitle
         editEntityTitle:editEntityTitle
    panelEnablerDisabler:panelEnablerDisabler
          entityAddCanceler:entityAddCanceler
      entityEditPreparer:entityEditPreparer
      entityEditCanceler:entityEditCanceler
             entityMaker:nil
             entitySaver:entitySaver
          newEntitySaver:nil
 doneEditingEntityMarker:doneEditingEntityMarker
prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
        viewDidAppearBlk:viewDidAppearBlk
          entityValidator:entityValidator
       listViewDataSource:listViewDataSource
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
    if (!((_entity == locallyUpdatedEntity) ||
          ([_entity doesHaveEqualIdentifiers:locallyUpdatedEntity] &&
           ([locallyUpdatedEntity editActorId] &&
            [[locallyUpdatedEntity editActorId] integerValue] == FPForegroundActorId)))) {
      [self displayHeadsUpAlertWithMsgs:@[LS(@"vieweditentity.headsup.whileviewing.locallyupdated.msg1"),
                                          LS(@"vieweditentity.headsup.whileviewing.locallyupdated.msg2")]];
      [_entity overwrite:(PELMMainSupport *)locallyUpdatedEntity];
      _entityToPanelBinder(_entity, _entityPanel);
    } else {
      DDLogDebug(@"in PEAVEC/dataObjectLocallyUpdated:, ignoring notification due to equality match w/_entity.");
    }
  }
}

- (void)dataObjectRemotelyUpdated:(NSNotification *)notification {
  NSNumber *indexOfNotifEntity =
    [PELMNotificationUtils indexOfEntityRef:_entity notification:notification];
  if (indexOfNotifEntity) {
    if ([self isEditing]) {
      _entityRemotelyUpdatedWhileEditing = YES;
      [PEUIUtils displayTempNotification:@"Record remotely updated."
                           forController:self
                               uitoolkit:_uitoolkit];
    } else {
      [self displayHeadsUpAlertWithMsgs:@[LS(@"vieweditentity.headsup.whileviewing.remotelyupdated.msg1"),
                                          LS(@"vieweditentity.headsup.whileviewing.remotelyupdated.msg2")]];
    }
  }
}

- (void)dataObjectRemotelyDeleted:(NSNotification *)notification {
  NSNumber *indexOfNotifEntity =
    [PELMNotificationUtils indexOfEntityRef:_entity notification:notification];
  if (indexOfNotifEntity) {
    if ([self isEditing]) {
      _entityRemotelyDeletedWhileEditing = YES;
      [PEUIUtils displayTempNotification:@"Record remotely deleted."
                           forController:self
                               uitoolkit:_uitoolkit];
    } else {
      [self displayHeadsUpAlertWithMsgs:@[LS(@"vieweditentity.headsup.whileviewing.remotelydeleted.msg1"),
                                          LS(@"vieweditentity.headsup.whileviewing.remotelydeleted.msg2"),
                                          LS(@"vieweditentity.headsup.whileviewing.remotelydeleted.msg3")]];
    }
  }
}

- (void)dataObjectSyncInitiated:(NSNotification *)notification {
  NSNumber *indexOfNotifEntity =
    [PELMNotificationUtils indexOfEntityRef:_entity notification:notification];
  if (indexOfNotifEntity) {
    [PEUIUtils displayTempNotification:@"Sync initiated for this record."
                         forController:self
                             uitoolkit:_uitoolkit];
  }
}

- (void)dataObjectSynced:(NSNotification *)notification {
  NSNumber *indexOfNotifEntity =
    [PELMNotificationUtils indexOfEntityRef:_entity notification:notification];
  if (indexOfNotifEntity) {
    [PEUIUtils displayTempNotification:@"Sync complete for this record."
                         forController:self
                             uitoolkit:_uitoolkit];
  }
}

- (void)dataObjectSyncFailed:(NSNotification *)notification {
  NSNumber *indexOfNotifEntity =
    [PELMNotificationUtils indexOfEntityRef:_entity notification:notification];
  if (indexOfNotifEntity) {
    [PEUIUtils displayTempNotification:@"Sync failed for this record."
                         forController:self
                             uitoolkit:_uitoolkit];
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
  [PEUtils observeIfNotNilNotificationName:_entityRemotelyDeletedNotifName
                                  observer:self
                                  selector:@selector(dataObjectRemotelyDeleted:)];
  if (_entityLocallyUpdatedNotifNames) {
    for (NSString *entityLocallyUpdatedNotifName in _entityLocallyUpdatedNotifNames) {
      [PEUtils observeIfNotNilNotificationName:entityLocallyUpdatedNotifName
                                      observer:self
                                      selector:@selector(dataObjectLocallyUpdated:)];
    }
  }
  [PEUtils observeIfNotNilNotificationName:_entityRemotelyUpdatedNotifName
                                  observer:self
                                  selector:@selector(dataObjectRemotelyUpdated:)];
  _entityPanel = _entityPanelMaker(self);
  [self setEdgesForExtendedLayout:UIRectEdgeNone];
  [PEUIUtils placeView:_entityPanel
               atTopOf:[self view]
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:0 // parameterize this value too?
              hpadding:0];

  NSString *title = _addEntityTitle;
  if (_isView) {
    title = _viewEntityTitle;
    _panelEnablerDisabler(_entityPanel, NO);
  } else if (_isEdit) {
    title = _editEntityTitle;
    [self prepareForEditing];
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
    if ([self prepareForEditing]) {
      [super setEditing:flag animated:animated];
      if (_prepareUIForUserInteractionBlk) {
        _prepareUIForUserInteractionBlk(_entityPanel);
      }
    }
  } else {
    [super setEditing:flag animated:animated];
    [self stopEditing];
  }
}

#pragma mark - UI state changes

- (BOOL)validEntityUserInput {
  NSArray *errMsgs = _entityValidator(_entityPanel);
  if (errMsgs && [errMsgs count] > 0) {
    [PEUIUtils showAlertWithMsgs:errMsgs title:@"Oops" buttonTitle:@"Okay"];
    return NO;
  }
  return YES;
}

- (BOOL)prepareForEditing {
  BOOL editPrepareSuccess = YES;
  if (![_entity editInProgress]) {
    editPrepareSuccess = _entityEditPreparer(self, _entity);
  }
  if (editPrepareSuccess) {
    [[self navigationItem] setTitle:_editEntityTitle];
    [[self navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc]
                                                 initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                 target:self
                                                 action:@selector(cancelAddEdit)]];
    _panelEnablerDisabler(_entityPanel, YES);
  }
  return editPrepareSuccess;
}

- (void)stopEditing {
  void (^displayHeadsUpIfRemoteDeletionOccured)(NSArray *msgs) = ^(NSArray *msgs) {
    if (_entityRemotelyDeletedWhileEditing) {
      [self displayHeadsUpAlertWithMsgs:msgs];
      _entityRemotelyDeletedWhileEditing = NO;
    }
  };
  void (^displayHeadsUpIfRemoteUpdateOccured)(NSArray *msgs) = ^(NSArray *msgs) {
    if (_entityRemotelyUpdatedWhileEditing) {
      [self displayHeadsUpAlertWithMsgs:msgs];
      _entityRemotelyUpdatedWhileEditing = NO;
    }
  };
  if (_isEditCanceled) {
    _entityEditCanceler(self, _entity);
    [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];
    _entityToPanelBinder(_entity, _entityPanel);
    _isEditCanceled = NO;
    displayHeadsUpIfRemoteDeletionOccured(@[LS(@"vieweditentity.headsup.whileediting.editcanceled.remotelydeleted.msg1"),
                                            LS(@"vieweditentity.headsup.whileediting.editcanceled.remotelydeleted.msg2"),
                                            LS(@"vieweditentity.headsup.whileediting.editcanceled.remotelydeleted.msg3")]);
    displayHeadsUpIfRemoteUpdateOccured(@[LS(@"vieweditentity.headsup.whileediting.editcanceled.remotelyupdated.msg1"),
                                          LS(@"vieweditentity.headsup.whileediting.editcanceled.remotelyupdated.msg2"),
                                          LS(@"vieweditentity.headsup.whileediting.editcanceled.remotelyupdated.msg3")]);
  } else {
    if ([self validEntityUserInput]) {
      _panelToEntityBinder(_entityPanel, _entity);
      _entitySaver(_listViewDataSource, self, _entity);
      _doneEditingEntityMarker(_entity);
      displayHeadsUpIfRemoteDeletionOccured(@[LS(@"vieweditentity.headsup.whileediting.editsucceeded.remotelydeleted.msg1"),
                                              LS(@"vieweditentity.headsup.whileediting.editsucceeded.remotelydeleted.msg2")]);
      displayHeadsUpIfRemoteUpdateOccured(@[LS(@"vieweditentity.headsup.whileediting.editsucceeded.remotelyupdated.msg1"),
                                            LS(@"vieweditentity.headsup.whileediting.editsucceeded.remotelyupdated.msg2")]);
    } else {
      displayHeadsUpIfRemoteDeletionOccured(@[LS(@"vieweditentity.headsup.whileediting.editfailed.remotelydeleted.msg1"),
                                              LS(@"vieweditentity.headsup.whileediting.editfailed.remotelydeleted.msg2"),
                                              LS(@"vieweditentity.headsup.whileediting.editfailed.remotelydeleted.msg3")]);
      displayHeadsUpIfRemoteUpdateOccured(@[LS(@"vieweditentity.headsup.whileediting.editfailed.remotelyupdated.msg1"),
                                            LS(@"vieweditentity.headsup.whileediting.editfailed.remotelyupdated.msg2"),
                                            LS(@"vieweditentity.headsup.whileediting.editfailed.remotelyupdated.msg3")]);
      return; // we want to short-circuit out if validation fails
    }
  }
  _itemChangedBlk(_entity, _entityIndexPath);
  [[self navigationItem] setLeftBarButtonItem:_backButton];
  [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];
  [[self navigationItem] setTitle:_viewEntityTitle];
  _panelEnablerDisabler(_entityPanel, NO);
  [PELMNotificationUtils postNotificationWithName:_entityUpdatedNotificationToPost
                                           entity:_entity];
}

- (void)doneWithEdit {
  [self stopEditing];
}

- (void)doneWithAdd {
  if ([self validEntityUserInput]) {
    id newEntity = _entityMaker(_entityPanel);
    _newEntitySaver(_entityPanel, newEntity);
    _itemAddedBlk(self, newEntity);
    
    id newEntityForNotification = newEntity;
    if (_getterForNotification) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        newEntityForNotification = [newEntity performSelector:_getterForNotification];
#pragma clang diagnostic pop
    }
    [PELMNotificationUtils postNotificationWithName:_entityAddedNotificationToPost
                                             entity:newEntityForNotification];
  }
}

#pragma mark - Cancellation

- (void)cancelAddEdit {
  if (_isAdd) {
    _entityAddCanceler(self);
  } else {
    _isEditCanceled = YES;
    [self setEditing:NO animated:YES]; // to get 'Done' button to turn to 'Edit'
  }
}

@end
