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
#import "FPEditActors.h"
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
  BOOL _syncImmediateWhenDoneEditing;
  PEPrepareUIForUserInteractionBlk _prepareUIForUserInteractionBlk;
  PEViewDidAppearBlk _viewDidAppearBlk;
  PEEntityValidatorBlk _entityValidator;
  PEEntityAddCancelerBlk _entityAddCanceler;
  NSNumber *_foregroundEditActorId;
  NSString *_entityAddedNotificationToPost;
  NSString *_entityUpdatedNotificationToPost;
  SEL _getterForNotification;
  NSString *_syncImmediateInitiatedMsg;
  NSString *_syncImmediateCompleteMsg;
  NSString *_syncImmediateFailedMsg;
  NSString *_syncImmediateRetryAfterMsg;
  PEEntitySyncCancelerBlk _entitySyncCanceler;
  BOOL _isEntityConfiguredForBackgroundSync;
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
syncImmediateWhenDoneEditing:(BOOL)syncImmediateWhenDoneEditing
syncImmediateInitiatedMsg:(NSString *)syncImmediateInitiatedMsg
syncImmediateCompleteMsg:(NSString *)syncImmediateCompleteMsg
syncImmediateFailedMsg:(NSString *)syncImmediateFailedMsg
syncImmediateRetryAfterMsg:(NSString *)syncImmediateRetryAfterMsg
entitySyncCanceler:(PEEntitySyncCancelerBlk)entitySyncCanceler
isEntityConfiguredForBackgroundSync:(BOOL)isEntityConfiguredForBackgroundSync
prepareUIForUserInteractionBlk:(PEPrepareUIForUserInteractionBlk)prepareUIForUserInteractionBlk
    viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
     entityValidator:(PEEntityValidatorBlk)entityValidator
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
    _syncImmediateWhenDoneEditing = syncImmediateWhenDoneEditing;
    _syncImmediateInitiatedMsg = syncImmediateInitiatedMsg;
    _syncImmediateCompleteMsg = syncImmediateCompleteMsg;
    _syncImmediateRetryAfterMsg = syncImmediateRetryAfterMsg;
    _syncImmediateFailedMsg = syncImmediateFailedMsg;
    _entitySyncCanceler = entitySyncCanceler;
    _isEntityConfiguredForBackgroundSync = isEntityConfiguredForBackgroundSync;
    _prepareUIForUserInteractionBlk = prepareUIForUserInteractionBlk;
    _viewDidAppearBlk = viewDidAppearBlk;
    _entityValidator = entityValidator;
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
syncImmediateWhenDoneEditing:NO
syncImmediateInitiatedMsg:nil
 syncImmediateCompleteMsg:nil
   syncImmediateFailedMsg:nil
syncImmediateRetryAfterMsg:nil
        entitySyncCanceler:nil
          isEntityConfiguredForBackgroundSync:NO
prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
         viewDidAppearBlk:viewDidAppearBlk
          entityValidator:entityValidator
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
                          syncImmediateWhenDoneEditing:(BOOL)syncImmediateWhenDoneEditing
                             syncImmediateInitiatedMsg:(NSString *)syncImmediateInitiatedMsg
                              syncImmediateCompleteMsg:(NSString *)syncImmediateCompleteMsg
                                syncImmediateFailedMsg:(NSString *)syncImmediateFailedMsg
                            syncImmediateRetryAfterMsg:(NSString *)syncImmediateRetryAfterMsg
                                    entitySyncCanceler:(PEEntitySyncCancelerBlk)entitySyncCanceler
                   isEntityConfiguredForBackgroundSync:(BOOL)isEntityConfiguredForBackgroundSync
                        prepareUIForUserInteractionBlk:(PEPrepareUIForUserInteractionBlk)prepareUIForUserInteractionBlk
                                      viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
                                       entityValidator:(PEEntityValidatorBlk)entityValidator
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
syncImmediateWhenDoneEditing:syncImmediateWhenDoneEditing
syncImmediateInitiatedMsg:syncImmediateInitiatedMsg
 syncImmediateCompleteMsg:syncImmediateCompleteMsg
  syncImmediateFailedMsg:syncImmediateFailedMsg
syncImmediateRetryAfterMsg:syncImmediateRetryAfterMsg
      entitySyncCanceler:entitySyncCanceler
isEntityConfiguredForBackgroundSync:isEntityConfiguredForBackgroundSync
prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
        viewDidAppearBlk:viewDidAppearBlk
          entityValidator:entityValidator
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
    [[self navigationItem] setTitle:_editEntityTitle];
    [[self navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc]
                                                 initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                 target:self
                                                 action:@selector(cancelAddEdit)]];
    _panelEnablerDisabler(_entityPanel, YES);
  }
  return editPrepareSuccess;
}

- (BOOL)stopEditing {
  if (_isEditCanceled) {
    _entityEditCanceler(self, _entity);
    [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];
    _entityToPanelBinder(_entity, _entityPanel);
    _isEditCanceled = NO;
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
        void (^reenableScreen)(void) = ^{
          [self.navigationItem setHidesBackButton:NO animated:YES];
          [[[self navigationItem] rightBarButtonItem] setEnabled:YES];
          [[[self tabBarController] tabBar] setUserInteractionEnabled:YES];
        };
/*        void (^comeBackLaterBlk)(void) = ^{
          //[self dismissViewControllerAnimated:YES completion:nil];
          [[self navigationController] popViewControllerAnimated:YES];
        };*/
        MBProgressHUD *_HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [self.navigationItem setHidesBackButton:YES animated:YES];
        [[[self navigationItem] rightBarButtonItem] setEnabled:NO];
        [[[self tabBarController] tabBar] setUserInteractionEnabled:NO];
        _HUD.delegate = self;
        _HUD.labelText = _syncImmediateInitiatedMsg;
        void(^syncSuccessBlk)(void) = ^{
          dispatch_async(dispatch_get_main_queue(), ^{
            [_HUD setLabelText:_syncImmediateCompleteMsg];
            __block UIImageView *imageView;
            UIImage *image = [UIImage imageNamed:@"hud-complete"];
            imageView = [[UIImageView alloc] initWithImage:image];
            [_HUD setCustomView:imageView];
            _HUD.mode = MBProgressHUDModeCustomView;
            [_HUD hide:YES afterDelay:0.85];
            reenableScreen();
          });
        };
        void(^syncFailedBlk)(NSError *) = ^(NSError *err) {
          //_entitySyncCanceler(_entity, err, nil);
          dispatch_async(dispatch_get_main_queue(), ^{
            [_HUD hide:YES afterDelay:0];
            if (_isEntityConfiguredForBackgroundSync) { // for now, this is unreachable
              // configure alert message to indicate that entity-sync can
              // occur in background.  Give 4 options:
              // 0. Do background sync (we'll let you know when you're edits have synced)
              // 1. Retry Now (nah; nix this idea)
              // 2. Come back later and retry (the edits you've made will not be lost) - i.e., leave in edit-in-progress mode
              // 3. Cancel Edits - invoke: [self cancelAddEdit]; return NO;
              UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Oops"
                                                                             message:_syncImmediateFailedMsg
                                                                      preferredStyle:UIAlertControllerStyleAlert];
              UIAlertAction *syncLater = [UIAlertAction actionWithTitle:@"I'll sync this for you automatically later."
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction *action) {reenableScreen();}];
              [alert addAction:syncLater];
              [self presentViewController:alert animated:YES completion:nil];
            } else {
              // offer the following options:
              // 1. Retry Now (nah; nix this idea)
              // 2. Come back later and retry (the edits you've made will not be lost) - i.e., leave in edit-in-progress mode
              // 3. Cancel Edits (you'll lose your changes) - invoke: invoke: [self cancelAddEdit]; return NO;
              UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Connection Error"
                                                                             message:@"We're sorry, but there was a problem communicating with the server.  We are currently working on the problem." //_syncImmediateFailedMsg
                                                                      preferredStyle:UIAlertControllerStyleAlert];
              UIAlertAction *comeBackLater = [UIAlertAction actionWithTitle:@"Come back later and try again."
                                                                      style:UIAlertActionStyleDefault
                                                                    handler:^(UIAlertAction *action) {
                                                                      [_entity setEditInProgress:YES]; // hack needed so that canceler can be called w/out its consistency-check blowing-up
                                                                      _entityEditCanceler(self, _entity);
                                                                      //_entityEditPreparer(self, _entity);
                                                                      [[self navigationController] popViewControllerAnimated:YES];
                                                                      //comeBackLaterBlk();
                                                                      //reenableScreen();
                                                                      //[self dismissViewControllerAnimated:YES completion:nil];
                                                                      //[self setEditing:YES animated:YES];
              }];
              /*UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel edits"
                                                               style:UIAlertActionStyleDestructive
                                                             handler:^(UIAlertAction *action) {
                //reenableScreen();
                                                               _entityEditCanceler(self, _entity);
                                                               [self dismissViewControllerAnimated:YES completion:nil];
              }];*/
              [alert addAction:comeBackLater];
              //[alert addAction:cancel];
              [self presentViewController:alert animated:YES completion:nil];
            }
          });
        };
        void(^syncRetryAfterBlk)(NSDate *) = ^(NSDate *retryAfter) {
          //_entitySyncCanceler(_entity, nil, nil);
          dispatch_async(dispatch_get_main_queue(), ^{
            [_HUD hide:YES afterDelay:1];
            reenableScreen();
            //[PEUIUtils showAlertWithMsgs:@[_syncImmediateRetryAfterMsg]
            //                       title:@"Server Temporarily Unavailable"
            //                 buttonTitle:@"Okay"];
          });
        };
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
          _doneEditingEntityMarker(_entity, syncSuccessBlk, syncFailedBlk, syncRetryAfterBlk);
        });
      } else {
        _doneEditingEntityMarker(_entity, nil, nil, nil);
      }
      
      
    } else {
      [PEUIUtils showAlertWithMsgs:errMsgs title:@"Oops" buttonTitle:@"Okay"];
      return NO;
    }
  }

  if (_itemChangedBlk) {
    _itemChangedBlk(_entity, _entityIndexPath);
  }
  
  [[self navigationItem] setLeftBarButtonItem:_backButton];
  [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];
  [[self navigationItem] setTitle:_viewEntityTitle];
  
  _panelEnablerDisabler(_entityPanel, NO);
  [PELMNotificationUtils postNotificationWithName:_entityUpdatedNotificationToPost
                                           entity:_entity];
  
  return YES;
}

- (void)doneWithEdit {
  [self stopEditing];
}

- (void)doneWithAdd {
  NSArray *errMsgs = _entityValidator(_entityPanel);
  BOOL isValidEntity = YES;
  if (errMsgs && [errMsgs count] > 0) {
    isValidEntity = NO;
  }
  if (isValidEntity) {
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
  } else {
    [PEUIUtils showAlertWithMsgs:errMsgs title:@"Oops" buttonTitle:@"Okay"];
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
