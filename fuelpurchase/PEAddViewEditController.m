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
#import <JGActionSheet/JGActionSheet.h>
#import "FPLogging.h"
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
  PESaveNewEntityBlk _newEntitySaver;
  PEMarkAsDoneEditingBlk _doneEditingEntityMarker;
  PEPrepareUIForUserInteractionBlk _prepareUIForUserInteractionBlk;
  PEViewDidAppearBlk _viewDidAppearBlk;
  PEEntityValidatorBlk _entityValidator;
  PEEntityAddCancelerBlk _entityAddCanceler;
  SEL _getterForNotification;
  BOOL _isEntityAppropriateForBackgroundSync;
  id _newEntity;
  PELMMainSupport *_entityCopyBeforeEdit;
  float _percentCompleteSavingEntity;
  MBProgressHUDMode _syncImmediateMBProgressHUDMode;
  NSMutableArray *_errorsForSync;
  NSMutableArray *_successMessageTitlesForSync;
  BOOL _receivedAuthReqdErrorOnSyncAttempt;
  PEIsLoggedInBlk _isUserLoggedIn;
  PEListViewController *_listViewController;
  UIBarButtonItem *_syncBarButtonItem;
  PESyncerBlk _syncer;
  PEIsAuthenticatedBlk _isAuthenticatedBlk;
  UIView *_entityViewPanel;
  PEMergeBlk _merge;
  PENumRemoteDepsNotLocal _numRemoteDepsNotLocal;
  PEFetcherBlk _fetchDependencies;
  PEConflictResolveFields _conflictResolveFields;
  PEConflictResolvedEntity _conflictResolvedEntity;
  PEUpdateDepsPanel _updateDepsPanel;
}

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
      newEntitySaver:(PESaveNewEntityBlk)newEntitySaver
doneEditingEntityMarker:(PEMarkAsDoneEditingBlk)doneEditingEntityMarker
     isAuthenticated:(PEIsAuthenticatedBlk)isAuthenticated
      isUserLoggedIn:(PEIsLoggedInBlk)isUserLoggedIn
syncImmediateMBProgressHUDMode:(MBProgressHUDMode)syncImmediateMBProgressHUDMode
isEntityAppropriateForLaterSync:(BOOL)isEntityAppropriateForLaterSync // rename to 'isEntityAppropriateForLaterSync'
prepareUIForUserInteractionBlk:(PEPrepareUIForUserInteractionBlk)prepareUIForUserInteractionBlk
    viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
     entityValidator:(PEEntityValidatorBlk)entityValidator
              syncer:(PESyncerBlk)syncer
numRemoteDepsNotLocal:(PENumRemoteDepsNotLocal)numRemoteDepsNotLocal
               merge:(PEMergeBlk)merge
   fetchDependencies:(PEFetcherBlk)fetchDependencies
     updateDepsPanel:(PEUpdateDepsPanel)updateDepsPanel
conflictResolveFields:(PEConflictResolveFields)conflictResolveFields
conflictResolvedEntity:(PEConflictResolvedEntity)conflictResolvedEntity
getterForNotification:(SEL)getterForNotification {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _listViewController = listViewController;
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
    _newEntitySaver = newEntitySaver;
    _doneEditingEntityMarker = doneEditingEntityMarker;
    _isUserLoggedIn = isUserLoggedIn;
    _syncImmediateMBProgressHUDMode = syncImmediateMBProgressHUDMode;
    _isAuthenticatedBlk = isAuthenticated;
    _isEntityAppropriateForBackgroundSync = isEntityAppropriateForLaterSync;
    _prepareUIForUserInteractionBlk = prepareUIForUserInteractionBlk;
    _viewDidAppearBlk = viewDidAppearBlk;
    _entityValidator = entityValidator;
    _syncer = syncer;
    _numRemoteDepsNotLocal = numRemoteDepsNotLocal;
    _merge = merge;
    _fetchDependencies = fetchDependencies;
    _updateDepsPanel = updateDepsPanel;
    _conflictResolveFields = conflictResolveFields;
    _conflictResolvedEntity = conflictResolvedEntity;
    _getterForNotification = getterForNotification;
    _errorsForSync = [NSMutableArray array];
    _successMessageTitlesForSync = [NSMutableArray array];
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
                                          newEntitySaver:(PESaveNewEntityBlk)newEntitySaver
                          prepareUIForUserInteractionBlk:(PEPrepareUIForUserInteractionBlk)prepareUIForUserInteractionBlk
                                        viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
                                         entityValidator:(PEEntityValidatorBlk)entityValidator
                                         isAuthenticated:(PEIsAuthenticatedBlk)isAuthenticated
                                          isUserLoggedIn:(PEIsLoggedInBlk)isUserLoggedIn
                          syncImmediateMBProgressHUDMode:(MBProgressHUDMode)syncImmediateMBProgressHUDMode
                    isEntityAppropriateForLaterSync:(BOOL)isEntityAppropriateForBackgroundSync {
  return [PEAddViewEditController addEntityCtrlrWithUitoolkit:uitoolkit
                                           listViewController:listViewController
                                                 itemAddedBlk:itemAddedBlk
                                             entityFormPanelMaker:entityFormPanelMaker
                                          entityToPanelBinder:entityToPanelBinder
                                          panelToEntityBinder:panelToEntityBinder
                                                  entityTitle:entityTitle
                                            entityAddCanceler:entityAddCanceler
                                                  entityMaker:entityMaker
                                               newEntitySaver:newEntitySaver
                               prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                             viewDidAppearBlk:viewDidAppearBlk
                                              entityValidator:entityValidator
                                              isAuthenticated:isAuthenticated
                                               isUserLoggedIn:isUserLoggedIn
                               syncImmediateMBProgressHUDMode:syncImmediateMBProgressHUDMode
                              isEntityAppropriateForLaterSync:isEntityAppropriateForBackgroundSync
                                        getterForNotification:nil];
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
                                          newEntitySaver:(PESaveNewEntityBlk)newEntitySaver
                          prepareUIForUserInteractionBlk:(PEPrepareUIForUserInteractionBlk)prepareUIForUserInteractionBlk
                                        viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
                                         entityValidator:(PEEntityValidatorBlk)entityValidator
                                         isAuthenticated:(PEIsAuthenticatedBlk)isAuthenticated
                                          isUserLoggedIn:(PEIsLoggedInBlk)isUserLoggedIn
                          syncImmediateMBProgressHUDMode:(MBProgressHUDMode)syncImmediateMBProgressHUDMode
                         isEntityAppropriateForLaterSync:(BOOL)isEntityAppropriateForBackgroundSync
                                   getterForNotification:(SEL)getterForNotification {
  return [[PEAddViewEditController alloc] initWithEntity:nil
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
                                          newEntitySaver:newEntitySaver
                                 doneEditingEntityMarker:nil
                                         isAuthenticated:isAuthenticated
                                          isUserLoggedIn:isUserLoggedIn
                          syncImmediateMBProgressHUDMode:syncImmediateMBProgressHUDMode
                         isEntityAppropriateForLaterSync:isEntityAppropriateForBackgroundSync
                          prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                        viewDidAppearBlk:viewDidAppearBlk
                                         entityValidator:entityValidator
                                                  syncer:nil
                                   numRemoteDepsNotLocal:nil
                                                   merge:nil
                                       fetchDependencies:nil
                                         updateDepsPanel:nil
                                   conflictResolveFields:nil
                                  conflictResolvedEntity:nil
                                   getterForNotification:getterForNotification];
}

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
                               doneEditingEntityMarker:(PEMarkAsDoneEditingBlk)doneEditingEntityMarker
                                       isAuthenticated:(PEIsAuthenticatedBlk)isAuthenticated
                                        isUserLoggedIn:(PEIsLoggedInBlk)isUserLoggedIn
                        syncImmediateMBProgressHUDMode:(MBProgressHUDMode)syncImmediateMBProgressHUDMode
                       isEntityAppropriateForLaterSync:(BOOL)isEntityAppropriateForLaterSync
                        prepareUIForUserInteractionBlk:(PEPrepareUIForUserInteractionBlk)prepareUIForUserInteractionBlk
                                      viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
                                       entityValidator:(PEEntityValidatorBlk)entityValidator
                                                syncer:(PESyncerBlk)syncer
                                 numRemoteDepsNotLocal:(PENumRemoteDepsNotLocal)numRemoteDepsNotLocal
                                                 merge:(PEMergeBlk)merge
                                     fetchDependencies:(PEFetcherBlk)fetchDependencies
                                       updateDepsPanel:(PEUpdateDepsPanel)updateDepsPanel
                                 conflictResolveFields:(PEConflictResolveFields)conflictResolveFields
                                conflictResolvedEntity:(PEConflictResolvedEntity)conflictResolvedEntity {
  return [[PEAddViewEditController alloc] initWithEntity:entity
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
                                          newEntitySaver:nil
                                 doneEditingEntityMarker:doneEditingEntityMarker
                                         isAuthenticated:isAuthenticated
                                          isUserLoggedIn:isUserLoggedIn
                          syncImmediateMBProgressHUDMode:syncImmediateMBProgressHUDMode
                         isEntityAppropriateForLaterSync:isEntityAppropriateForLaterSync
                          prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                        viewDidAppearBlk:viewDidAppearBlk
                                         entityValidator:entityValidator
                                                  syncer:syncer
                                   numRemoteDepsNotLocal:numRemoteDepsNotLocal
                                                   merge:merge
                                       fetchDependencies:fetchDependencies
                                         updateDepsPanel:updateDepsPanel
                                   conflictResolveFields:conflictResolveFields
                                  conflictResolvedEntity:conflictResolvedEntity
                                   getterForNotification:nil];
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
      [_entity overwrite:(PELMMainSupport *)locallyUpdatedEntity];
      _entityToPanelBinder(_entity, _entityFormPanel);
    } else {
      DDLogDebug(@"in PEAVEC/dataObjectLocallyUpdated:, ignoring notification due to equality match w/_entity.");
    }
  }
}

- (void)dataObjectSyncInitiated:(NSNotification *)notification {
  if (!_isAuthenticatedBlk()) {
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
  if (!_isAuthenticatedBlk()) {
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
  if (!_isAuthenticatedBlk()) {
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
  if ([_entity editInProgress]) {
    _panelToEntityBinder(_entityFormPanel, _entity);
    _entitySaver(self, _entity);
    DDLogDebug(@"in viewWillDisappear:, saved entity");
  }
  [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  if (_isAdd || _isEdit) {
    if (_prepareUIForUserInteractionBlk) {
      _prepareUIForUserInteractionBlk(_entityFormPanel);
    }
  }
  if (_viewDidAppearBlk) {
    _viewDidAppearBlk(_entityFormPanel);
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  UINavigationItem *navItem = [self navigationItem];
  _backButton = [navItem leftBarButtonItem];
  [self setEdgesForExtendedLayout:UIRectEdgeNone];
  _entityFormPanel = _entityFormPanelMaker(self);
  if (_entityViewPanelMaker) {
    _entityViewPanel = _entityViewPanelMaker(self, _entity);
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
    //_panelEnablerDisabler(_entityFormPanel, NO);
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
  [navItem setTitle:title];
  _syncBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:nil
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(doSync)];
  [self setSyncBarButtonState];
  if (_isView) {
    [navItem setRightBarButtonItems:@[[self editButtonItem],
                                      _syncBarButtonItem]
                           animated:YES];
  } else {
    [navItem setLeftBarButtonItem:[[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                   target:self
                                   action:@selector(cancelAddEdit)]];
    if (_isAdd) {
      [navItem setRightBarButtonItems:@[[[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self
                                      action:@selector(doneWithAdd)],
                                        _syncBarButtonItem]];
    } else {
      [navItem setRightBarButtonItems:@[[[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self
                                      action:@selector(doneWithEdit)],
                                        _syncBarButtonItem]];
    }
  }
  if ([_entity syncInProgress]) {
    [[self editButtonItem] setEnabled:NO];
    [PEUIUtils displayTempNotification:@"Sync in progress for this record."
                         forController:self
                             uitoolkit:_uitoolkit];
  }
}

#pragma mark - JGActionSheetDelegate and Alert-related Helpers

- (void)actionSheetWillPresent:(JGActionSheet *)actionSheet {}

- (void)actionSheetDidPresent:(JGActionSheet *)actionSheet {}

- (void)actionSheetWillDismiss:(JGActionSheet *)actionSheet {}

- (void)actionSheetDidDismiss:(JGActionSheet *)actionSheet {}

- (JGActionSheetSection *)becameUnauthenticatedSection {
  JGActionSheetSection *becameUnauthSection = nil;
  if (_receivedAuthReqdErrorOnSyncAttempt) {
    NSString *becameUnauthMessage = @"\
It appears you are no longer authenticated.\n\
To re-authenticate, go to:\n\nSettings \u2794 Re-authenticate.";
    NSDictionary *unauthMessageAttrs = @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0] };
    NSMutableAttributedString *attrBecameUnauthMessage = [[NSMutableAttributedString alloc] initWithString:becameUnauthMessage];
    NSRange unauthMsgAttrsRange = NSMakeRange(72, 26); // 'Settings...Re-authenticate'
    [attrBecameUnauthMessage setAttributes:unauthMessageAttrs range:unauthMsgAttrsRange];
    becameUnauthSection = [PEUIUtils warningAlertSectionWithMsgs:nil
                                                           title:@"Authentication Failure."
                                                alertDescription:attrBecameUnauthMessage
                                                  relativeToView:self.view];
  }
  return becameUnauthSection;
}

#pragma mark - Sync

- (void)setSyncBarButtonState {
  BOOL enableSyncItem = NO;
  NSString *syncTitle = @"";
  if (_entity) {
    syncTitle = @"";
    if (_syncer &&
        _isAuthenticatedBlk() &&
        [_entity localMainIdentifier] &&
        ![_entity synced] &&
        ![_entity editInProgress] &&
        !([_entity syncErrMask] && ([_entity syncErrMask].integerValue > 0))) {
      enableSyncItem = YES;
      syncTitle = @"Sync";
    }
  }
  [_syncBarButtonItem setTitle:syncTitle];
  [_syncBarButtonItem setEnabled:enableSyncItem];
}

- (void)doSync {
  void (^postSyncActivities)(void) = ^{
    if (_itemChangedBlk) {
      _itemChangedBlk(_entity, _entityIndexPath);
    }
    [self.navigationItem setHidesBackButton:NO animated:YES];
    [[[self navigationItem] rightBarButtonItem] setEnabled:YES];
    [[[self tabBarController] tabBar] setUserInteractionEnabled:YES];
    [[self navigationItem] setTitle:_entityTitle];
    _panelEnablerDisabler(_entityFormPanel, NO);
    if (_listViewController) {
      [_listViewController handleUpdatedEntity:_entity];
    }
    [self setSyncBarButtonState];
  };
  MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  [self.navigationItem setHidesBackButton:YES animated:YES];
  [[[self navigationItem] leftBarButtonItem] setEnabled:NO];
  [_syncBarButtonItem setEnabled:NO];
  [[[self navigationItem] rightBarButtonItem] setEnabled:NO];
  [[[self tabBarController] tabBar] setUserInteractionEnabled:NO];
  HUD.delegate = self;
  HUD.mode = _syncImmediateMBProgressHUDMode;
  HUD.labelText = @"Syncing to server...";
  _percentCompleteSavingEntity = 0.0;
  HUD.progress = _percentCompleteSavingEntity;
  [_errorsForSync removeAllObjects];
  
  // The meaning of the elements of the arrays found within _errorsForSync:
  //
  // _errorsForSync[*][0]: Error title (string)
  // _errorsForSync[*][1]: Is error user-fixable (bool)
  // _errorsForSync[*][2]: An NSArray of sub-error messages (strings)
  // _errorsForSync[*][3]: Is error conflict-type (bool)
  //
  
  [_successMessageTitlesForSync removeAllObjects];
  _receivedAuthReqdErrorOnSyncAttempt = NO;
  void(^syncDone)(NSString *) = ^(NSString *mainMsgTitle) {
    if ([_errorsForSync count] == 0) { // success
      dispatch_async(dispatch_get_main_queue(), ^{
        [HUD setLabelText:_successMessageTitlesForSync[0]];
        //[HUD setDetailsLabelText:@"(synced with server)"];
        UIImage *image = [UIImage imageNamed:@"hud-complete"];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        [HUD setCustomView:imageView];
        HUD.mode = MBProgressHUDModeCustomView;
        [HUD hide:YES afterDelay:1.30];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.35 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
          postSyncActivities();
        });
      });
    } else { // error
      dispatch_async(dispatch_get_main_queue(), ^{
        [HUD hide:YES afterDelay:0];
        NSString *title;
        NSString *okayActionTitle = @"Okay.  I'll try again later.";
        NSString *message;
        BOOL isConflictError = NO;
        NSArray *subErrors = _errorsForSync[0][2];
        if ([subErrors count] > 1) {
          message = @"There were problems syncing to the server.\n\
The errors are as follows:";
          title = [NSString stringWithFormat:@"Errors %@.", mainMsgTitle];
        } else {
          if ([_errorsForSync[0][3] boolValue]) {
            isConflictError = YES;
          } else {
            message = @"There was a problem syncing to the server.\n\
The error is as follows:";
            title = [NSString stringWithFormat:@"Error %@.", mainMsgTitle];
          }
        }
        if (isConflictError) {
          id latestEntity = _errorsForSync[0][4];
          NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] initWithString:@"\
The remote copy of this entity has been\n\
updated since you downloaded it.  You have\n\
a few options:\n\n\
If you cancel, your local edits will be\n\
retained."];
          NSDictionary *attrs = @{ NSFontAttributeName : [UIFont italicSystemFontOfSize:14.0] };
          [desc setAttributes:attrs range:NSMakeRange(99, 49)];
          [self presentConflictAlertWithLatestEntity:latestEntity
                                    alertDescription:desc
                                        cancelAction:postSyncActivities];
        } else {
          JGActionSheetSection *becameUnauthSection = [self becameUnauthenticatedSection];
          JGActionSheetSection *contentSection = [PEUIUtils errorAlertSectionWithMsgs:subErrors
                                                                                title:title
                                                                     alertDescription:[[NSAttributedString alloc] initWithString:message]
                                                                       relativeToView:self.view];
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
                postSyncActivities();
                [sheet dismissAnimated:YES];
                break;
            };}];
          [alertSheet showInView:[self view] animated:YES];
        }
      });
    }
  };
  void (^handleHudProgress)(float) = ^(float percentComplete) {
    _percentCompleteSavingEntity += percentComplete;
    dispatch_async(dispatch_get_main_queue(), ^{
      HUD.progress = _percentCompleteSavingEntity;
    });
  };
  void(^syncNotFoundBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                            NSString *mainMsgTitle,
                                                            NSString *recordTitle) {
    handleHudProgress(percentComplete);
    // TODO - perhaps need to add ability for 'not found' errors to be 'special' such that
    // a user is given a special error dialog informing that their record will now be deleted
    // from the device.  This VC needs to accept a 'delete me' block so the entity can be
    // locally deleted.
    [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                [NSNumber numberWithBool:NO],
                                @[[NSString stringWithFormat:@"Not found."]],
                                [NSNumber numberWithBool:NO]]];
    if (_percentCompleteSavingEntity == 1.0) {
      syncDone(mainMsgTitle);
    }
  };
  void(^syncSuccessBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                           NSString *mainMsgTitle,
                                                           NSString *recordTitle) {
    handleHudProgress(percentComplete);
    [_successMessageTitlesForSync addObject:[NSString stringWithFormat:@"%@ synced.", recordTitle]];
    if (_percentCompleteSavingEntity == 1.0) {
      syncDone(mainMsgTitle);
    }
  };
  void(^syncRetryAfterBlk)(float, NSString *, NSString *, NSDate *) = ^(float percentComplete,
                                                                        NSString *mainMsgTitle,
                                                                        NSString *recordTitle,
                                                                        NSDate *retryAfter) {
    handleHudProgress(percentComplete);
    [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                [NSNumber numberWithBool:NO],
                                @[[NSString stringWithFormat:@"Server busy.  Retry after: %@", retryAfter]],
                                [NSNumber numberWithBool:NO]]];
    if (_percentCompleteSavingEntity == 1.0) {
      syncDone(mainMsgTitle);
    }
  };
  void(^syncServerTempError)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                NSString *mainMsgTitle,
                                                                NSString *recordTitle) {
    handleHudProgress(percentComplete);
    [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                [NSNumber numberWithBool:NO],
                                @[@"Temporary server error."],
                                [NSNumber numberWithBool:NO]]];
    if (_percentCompleteSavingEntity == 1.0) {
      syncDone(mainMsgTitle);
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
    [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                [NSNumber numberWithBool:isErrorUserFixable],
                                computedErrMsgs,
                                [NSNumber numberWithBool:NO]]];
    if (_percentCompleteSavingEntity == 1.0) {
      syncDone(mainMsgTitle);
    }
  };
  void(^syncConflictBlk)(float, NSString *, NSString *, id) = ^(float percentComplete,
                                                                NSString *mainMsgTitle,
                                                                NSString *recordTitle,
                                                                id latestEntity) {
    handleHudProgress(percentComplete);
    [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                [NSNumber numberWithBool:NO],
                                @[[NSString stringWithFormat:@"Conflict."]],
                                [NSNumber numberWithBool:YES],
                                latestEntity]];
    if (_percentCompleteSavingEntity == 1.0) {
      syncDone(mainMsgTitle);
    }
  };
  void(^syncAuthReqdBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                            NSString *mainMsgTitle,
                                                            NSString *recordTitle) {
    _receivedAuthReqdErrorOnSyncAttempt = YES;
    handleHudProgress(percentComplete);
    [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                [NSNumber numberWithBool:NO],
                                @[@"Authentication required."],
                                [NSNumber numberWithBool:NO]]];
    if (_percentCompleteSavingEntity == 1.0) {
      syncDone(mainMsgTitle);
    }
  };
  void(^syncDependencyUnsyncedBlk)(float, NSString *, NSString *, NSString *) = ^(float percentComplete,
                                                                                  NSString *mainMsgTitle,
                                                                                  NSString *recordTitle,
                                                                                  NSString *dependencyErrMsg) {
    handleHudProgress(percentComplete);
    [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                [NSNumber numberWithBool:NO],
                                @[dependencyErrMsg],
                                [NSNumber numberWithBool:NO]]];
    if (_percentCompleteSavingEntity == 1.0) {
      syncDone(mainMsgTitle);
    }
  };
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    _syncer(self,
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
}

#pragma mark - Conflict Helpers

- (void (^)(void(^)(void)))downloadDepsForEntity:(id)latestEntity
                       dismissErrAlertPostAction:(void(^)(void))dismissErrAlertPostAction {
  void (^fetchDepsThenTakeAction)(void(^)(void)) = ^(void(^postFetchAction)(void)) {
    if (_numRemoteDepsNotLocal) {
      NSInteger numDepsThatDontExistLocally = _numRemoteDepsNotLocal(latestEntity);
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
              [depFetchHud hide:YES afterDelay:1.30];
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.35 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
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
There were problems downloading this\n\
entity's dependencies.";
                [PEUIUtils showMultiErrorAlertWithFailures:errsForDepsFetch
                                                     title:@"Fetch errors."
                                          alertDescription:[[NSAttributedString alloc] initWithString:fetchErrMsg]
                                                  topInset:70.0
                                               buttonTitle:@"Okay."
                                              buttonAction:^{
                                                dismissErrAlertAction();
                                              }
                                            relativeToView:self.view];
              } else {
                NSString *fetchErrMsg = @"\
There was a problem downloading this\n\
entity's dependency.";
                [PEUIUtils showErrorAlertWithMsgs:errsForDepsFetch[0][2]
                                            title:@"Fetch error."
                                 alertDescription:[[NSAttributedString alloc] initWithString:fetchErrMsg]
                                         topInset:70.0
                                      buttonTitle:@"Okay."
                                     buttonAction:^{
                                       dismissErrAlertAction();
                                     }
                                   relativeToView:self.view];
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
                                        @[[NSString stringWithFormat:@"Server busy.  Retry after: %@", retryAfter]],
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
          _receivedAuthReqdErrorOnSyncAttempt = YES;
          handleHudProgress(percentComplete);
          [errsForDepsFetch addObject:@[[NSString stringWithFormat:@"%@ not fetched.", recordTitle],
                                        [NSNumber numberWithBool:NO],
                                        @[@"Authentication required."],
                                        [NSNumber numberWithBool:NO]]];
          if (percentCompleteFetchingDeps == 1.0) { depFetchDone(mainMsgTitle); }
        };
        _fetchDependencies(self,
                           latestEntity,
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
      [self.view endEditing:YES]; // dismiss the keyboard
      NSString *desc = @"\
Use the form below to resolve the\n\
merge conflicts.";
      [PEUIUtils showConflictResolverWithTitle:@"Conflict resolver."
                              alertDescription:[[NSAttributedString alloc] initWithString:desc]
                         conflictResolveFields:_conflictResolveFields(self, mergeConflicts, _entity, latestEntity)
                                withCellHeight:36.75
                             labelLeftHPadding:5.0
                            valueRightHPadding:8.0
                                     labelFont:[UIFont systemFontOfSize:14]
                                     valueFont:[UIFont systemFontOfSize:14]
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

- (void)presentConflictAlertWithLatestEntity:(id)latestEntity
                            alertDescription:(NSAttributedString *)desc
                                cancelAction:(void(^)(void))cancelAction {
  void (^reenableNavButtons)(void) = ^{
    [[[self navigationItem] leftBarButtonItem] setEnabled:YES];
    [[[self navigationItem] rightBarButtonItem] setEnabled:YES];
  };
  void (^fetchDepsThenTakeAction)(void(^)(void)) = [self downloadDepsForEntity:latestEntity
                                                     dismissErrAlertPostAction:reenableNavButtons];
  [PEUIUtils showEditConflictAlertWithTitle:@"Conflict."
                           alertDescription:desc
                                   topInset:70.0
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
                            // TODO - need to invoke block that takes 'self' for additional
                            // updating of the UI (e.g., the updating of the table DS for envlog
                            // and fplog screens) - like:
                            _updateDepsPanel(self, latestEntity);
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
                         cancelButtonAction:^{ cancelAction(); /*postEditActivities();*/ }
                             relativeToView:self.view];
}

#pragma mark - Toggle into edit mode

- (void)setEditing:(BOOL)flag animated:(BOOL)animated {
  if (flag) {
    if ([self prepareForEditing]) {
      _entityCopyBeforeEdit = [_entity copy];
      [super setEditing:flag animated:animated];
      if (_prepareUIForUserInteractionBlk) {
        _prepareUIForUserInteractionBlk(_entityFormPanel);
      }
      [self setSyncBarButtonState];
      //_backButton = [[self navigationItem] leftBarButtonItem]; // i just added this
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
    [_entityViewPanel removeFromSuperview];
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
    [self.navigationItem setHidesBackButton:NO animated:YES];
    [[[self navigationItem] rightBarButtonItem] setEnabled:YES];
    [[[self tabBarController] tabBar] setUserInteractionEnabled:YES];
    [[self navigationItem] setLeftBarButtonItem:_backButton];
    [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];
    [[self navigationItem] setTitle:_entityTitle];
    _panelEnablerDisabler(_entityFormPanel, NO);
    if (_listViewController) {
      [_listViewController handleUpdatedEntity:_entity];
    }
    [self setSyncBarButtonState];
    [_entityFormPanel removeFromSuperview];
    _entityViewPanel = _entityViewPanelMaker(self, _entity);
    [PEUIUtils placeView:_entityViewPanel atTopOf:[self view] withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0 hpadding:0];
  };
  if (_isEditCanceled) {
    if (_entityCopyBeforeEdit) {
      [_entity overwrite:_entityCopyBeforeEdit];
    }
    _entityEditCanceler(self, _entity);
    _entityToPanelBinder(_entity, _entityFormPanel);
    postEditActivities();
    _isEditCanceled = NO;
  } else {
    NSArray *errMsgs = _entityValidator(_entityFormPanel);
    BOOL isValidEntity = YES;
    if (errMsgs && [errMsgs count] > 0) {
      isValidEntity = NO;
    }
    if (isValidEntity) {
      _panelToEntityBinder(_entityFormPanel, _entity);
      _entitySaver(self, _entity);
      if (_isAuthenticatedBlk()) {
        MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [self.navigationItem setHidesBackButton:YES animated:YES];
        [[[self navigationItem] leftBarButtonItem] setEnabled:NO];
        [[[self navigationItem] rightBarButtonItem] setEnabled:NO];
        [[[self tabBarController] tabBar] setUserInteractionEnabled:NO];
        HUD.delegate = self;
        HUD.mode = _syncImmediateMBProgressHUDMode;
        HUD.labelText = @"Syncing to server...";
        _percentCompleteSavingEntity = 0.0;
        HUD.progress = _percentCompleteSavingEntity;
        [_errorsForSync removeAllObjects];
        
        // The meaning of the elements of the arrays found within _errorsForSync:
        //
        // _errorsForSync[*][0]: Error title (string)
        // _errorsForSync[*][1]: Is error user-fixable (bool)
        // _errorsForSync[*][2]: An NSArray of sub-error messages (strings)
        // _errorsForSync[*][3]: Is error conflict-type (bool)
        //
        
        [_successMessageTitlesForSync removeAllObjects];
        _receivedAuthReqdErrorOnSyncAttempt = NO;
        void(^immediateSyncDone)(NSString *) = ^(NSString *mainMsgTitle) {
          if ([_errorsForSync count] == 0) { // success
            dispatch_async(dispatch_get_main_queue(), ^{
              [HUD setLabelText:_successMessageTitlesForSync[0]];
              //[HUD setDetailsLabelText:@"(synced with server)"];
              UIImage *image = [UIImage imageNamed:@"hud-complete"];
              UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
              [HUD setCustomView:imageView];
              HUD.mode = MBProgressHUDModeCustomView;
              [HUD hide:YES afterDelay:1.30];
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.35 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                postEditActivities();
              });
            });
          } else { // error
            dispatch_async(dispatch_get_main_queue(), ^{
              [HUD hide:YES afterDelay:0];
              NSDictionary *messageAttrs = @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0],
                                              NSForegroundColorAttributeName : [UIColor blueColor] };
              NSRange messageAttrsRange;
              NSMutableAttributedString *attrMessage;
              NSString *title;
              NSString *fixNowActionTitle;
              NSString *fixLaterActionTitle;
              NSString *dealWithLaterActionTitle;
              NSString *cancelActionTitle;
              NSString *message;
              BOOL isConflictError = NO;
              NSArray *subErrors = _errorsForSync[0][2]; // because only single-record edit, we can skip the "not saved" msg title, and just display the sub-errors
              if ([subErrors count] > 1) {
                message = @"\
Although there were problems syncing your\n\
edits to the server, they have been saved\n\
locally.  The errors are as follows:";
                fixNowActionTitle = @"I'll fix them now.";
                fixLaterActionTitle = @"I'll fix them later.";
                dealWithLaterActionTitle = @"I'll try syncing them later.";
                cancelActionTitle = @"Forget it.  Just cancel them.";
                title = [NSString stringWithFormat:@"Errors %@.", mainMsgTitle];
              } else {
                if ([_errorsForSync[0][3] boolValue]) {
                  isConflictError = YES;
                } else {
                  message = @"\
Although there was a problem syncing your\n\
edits to the server, they have been saved\n\
locally.  The error is as follows:";
                  fixLaterActionTitle = @"I'll fix it later.";
                  fixNowActionTitle = @"I'll fix it now.";
                  dealWithLaterActionTitle = @"I'll try syncing it later.";
                  cancelActionTitle = @"Forget it.  Just cancel it.";
                  title = [NSString stringWithFormat:@"Error %@.", mainMsgTitle];
                }
              }
              if (isConflictError) {
                id latestEntity = _errorsForSync[0][4];
                NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] initWithString:@"\
The remote copy of this entity has been\n\
updated since you downloaded it.  You have\n\
a few options:\n\n\
If you cancel, your local edits will be\n\
retained."];
                NSDictionary *attrs = @{ NSFontAttributeName : [UIFont italicSystemFontOfSize:14.0] };
                [desc setAttributes:attrs range:NSMakeRange(99, 49)];
                [self presentConflictAlertWithLatestEntity:latestEntity
                                          alertDescription:desc
                                              cancelAction:postEditActivities];
              } else {
                messageAttrsRange = NSMakeRange(68, 23); // 'have...locally'
                attrMessage = [[NSMutableAttributedString alloc] initWithString:message];
                [attrMessage setAttributes:messageAttrs range:messageAttrsRange];
                JGActionSheetSection *becameUnauthSection = [self becameUnauthenticatedSection];
                JGActionSheetSection *contentSection = [PEUIUtils errorAlertSectionWithMsgs:subErrors
                                                                                      title:title
                                                                           alertDescription:attrMessage
                                                                             relativeToView:self.view];
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
                if ([PEAddViewEditController areErrorsAllUserFixable:_errorsForSync]) {
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
          _percentCompleteSavingEntity += percentComplete;
          dispatch_async(dispatch_get_main_queue(), ^{
            HUD.progress = _percentCompleteSavingEntity;
          });
        };
        void(^syncNotFoundBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                  NSString *mainMsgTitle,
                                                                  NSString *recordTitle) {
          handleHudProgress(percentComplete);
          // TODO - perhaps need to add ability for 'not found' errors to be 'special' such that
          // a user is given a special error dialog informing that their record will now be deleted
          // from the device.  This VC needs to accept a 'delete me' block so the entity can be
          // locally deleted.
          [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                      [NSNumber numberWithBool:NO],
                                      @[[NSString stringWithFormat:@"Not found."]],
                                      [NSNumber numberWithBool:NO]]];
          if (_percentCompleteSavingEntity == 1.0) {
            immediateSyncDone(mainMsgTitle);
          }
        };
        void(^syncSuccessBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                 NSString *mainMsgTitle,
                                                                 NSString *recordTitle) {
          handleHudProgress(percentComplete);
          [_successMessageTitlesForSync addObject:[NSString stringWithFormat:@"%@ synced.", recordTitle]];
          if (_percentCompleteSavingEntity == 1.0) {
            immediateSyncDone(mainMsgTitle);
          }
        };
        void(^syncRetryAfterBlk)(float, NSString *, NSString *, NSDate *) = ^(float percentComplete,
                                                                              NSString *mainMsgTitle,
                                                                              NSString *recordTitle,
                                                                              NSDate *retryAfter) {
          handleHudProgress(percentComplete);
          [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                      [NSNumber numberWithBool:NO],
                                      @[[NSString stringWithFormat:@"Server busy.  Retry after: %@", retryAfter]],
                                      [NSNumber numberWithBool:NO]]];
          if (_percentCompleteSavingEntity == 1.0) {
            immediateSyncDone(mainMsgTitle);
          }
        };
        void (^syncServerTempError)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                       NSString *mainMsgTitle,
                                                                       NSString *recordTitle) {
          handleHudProgress(percentComplete);
          [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                      [NSNumber numberWithBool:NO],
                                      @[@"Temporary server error."],
                                      [NSNumber numberWithBool:NO]]];
          if (_percentCompleteSavingEntity == 1.0) {
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
          [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                      [NSNumber numberWithBool:isErrorUserFixable],
                                      computedErrMsgs,
                                      [NSNumber numberWithBool:NO]]];
          if (_percentCompleteSavingEntity == 1.0) {
            immediateSyncDone(mainMsgTitle);
          }
        };
        void(^syncConflictBlk)(float, NSString *, NSString *, id) = ^(float percentComplete,
                                                                      NSString *mainMsgTitle,
                                                                      NSString *recordTitle,
                                                                      id latestEntity) {
          handleHudProgress(percentComplete);
          [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                      [NSNumber numberWithBool:NO],
                                      @[[NSString stringWithFormat:@"Conflict."]],
                                      [NSNumber numberWithBool:YES],
                                      latestEntity]];
          if (_percentCompleteSavingEntity == 1.0) {
            immediateSyncDone(mainMsgTitle);
          }
        };
        void(^syncAuthReqdBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                  NSString *mainMsgTitle,
                                                                  NSString *recordTitle) {
          _receivedAuthReqdErrorOnSyncAttempt = YES;
          handleHudProgress(percentComplete);
          [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                      [NSNumber numberWithBool:NO],
                                      @[@"Authentication required."],
                                      [NSNumber numberWithBool:NO]]];
          if (_percentCompleteSavingEntity == 1.0) {
            immediateSyncDone(mainMsgTitle);
          }
        };
        void (^syncDependencyUnsyncedBlk)(float, NSString *, NSString *, NSString *) = ^(float percentComplete,
                                                                                         NSString *mainMsgTitle,
                                                                                         NSString *recordTitle,
                                                                                         NSString *dependencyErrMsg) {
          handleHudProgress(percentComplete);
          [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                      [NSNumber numberWithBool:NO],
                                      @[dependencyErrMsg],
                                      [NSNumber numberWithBool:NO]]];
          if (_percentCompleteSavingEntity == 1.0) {
            immediateSyncDone(mainMsgTitle);
          }
        };
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
          _doneEditingEntityMarker(self,
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
        [[[self navigationItem] leftBarButtonItem] setEnabled:NO]; // cancel btn (so they can't cancel it after we'ved saved and we're displaying the HUD)
        [[[self navigationItem] rightBarButtonItem] setEnabled:NO]; // done btn
        [[[self tabBarController] tabBar] setUserInteractionEnabled:NO];
        _doneEditingEntityMarker(self, _entity, nil, nil, nil, nil, nil, nil, nil, nil);
        MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        HUD.delegate = self;
        [HUD setLabelText:[NSString stringWithFormat:@"%@ Saved.", _entityTitle]];
        if (_isUserLoggedIn()) {
          [HUD setDetailsLabelText:@"(not synced with server)"];
        }
        UIImage *image = [UIImage imageNamed:@"hud-complete"];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        [HUD setCustomView:imageView];
        HUD.mode = MBProgressHUDModeCustomView;
        [HUD hide:YES afterDelay:1.30];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.35 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
          postEditActivities();
        });
      }
    } else {
      [PEUIUtils showWarningAlertWithMsgs:errMsgs
                                    title:@"Oops"
                         alertDescription:[[NSAttributedString alloc] initWithString:@"There are some validation errors:"]
                                 topInset:70.0
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
                                            font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
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
      id newEntityForNotification = theNewEntity;
      if (_getterForNotification) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        newEntityForNotification = [theNewEntity performSelector:_getterForNotification];
        #pragma clang diagnostic pop
      }
      if (_listViewController) {
        [_listViewController handleAddedEntity:newEntityForNotification];
      }
    };
    if (_isAuthenticatedBlk()) {
      void (^reenableScreen)(void) = ^{
        [[[self navigationItem] leftBarButtonItem] setEnabled:YES];
        [[[self navigationItem] rightBarButtonItem] setEnabled:YES];
        [[[self tabBarController] tabBar] setUserInteractionEnabled:YES];
      };
      MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      [self.navigationItem setHidesBackButton:YES animated:YES];
      [[[self navigationItem] leftBarButtonItem] setEnabled:NO]; // cancel btn (so they can't cancel it while HUD is displaying)
      [[[self navigationItem] rightBarButtonItem] setEnabled:NO];
      [[[self tabBarController] tabBar] setUserInteractionEnabled:NO];
      HUD.delegate = self;
      HUD.mode = _syncImmediateMBProgressHUDMode;
      HUD.labelText = @"Syncing to server...";
      _percentCompleteSavingEntity = 0.0;
      HUD.progress = _percentCompleteSavingEntity;
      [_errorsForSync removeAllObjects];
      
      // The meaning of the elements of the arrays found within _errorsForSync:
      //
      // _errorsForSync[*][0]: Error title (string)
      // _errorsForSync[*][1]: Is error user-fixable (bool)
      // _errorsForSync[*][2]: An NSArray of sub-error messages (strings)
      //
      
      [_successMessageTitlesForSync removeAllObjects];
      _receivedAuthReqdErrorOnSyncAttempt = NO;
      void(^immediateSaveDone)(NSString *) = ^(NSString *mainMsgTitle) {
        BOOL isMultiStepAdd = ([_errorsForSync count] + [_successMessageTitlesForSync count]) > 1;
        if ([_errorsForSync count] == 0) {
          dispatch_async(dispatch_get_main_queue(), ^{
            notificationSenderForAdd(_newEntity);
            if (isMultiStepAdd) {
              [HUD hide:YES afterDelay:0];
              // all successes
              NSString *title = [NSString stringWithFormat:@"Success %@.", mainMsgTitle];
              JGActionSheetSection *contentSection = [PEUIUtils successAlertSectionWithMsgs:_successMessageTitlesForSync
                                                                                      title:title
                                                                           alertDescription:[[NSAttributedString alloc] initWithString:@"Your records have been successfully\nsynced."]
                                                                             relativeToView:[self view]];
              JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                                    message:nil
                                                                               buttonTitles:@[@"Okay."]
                                                                                buttonStyle:JGActionSheetButtonStyleDefault];
              JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:@[contentSection, buttonsSection]];
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
            } else {
              // single add success
              [HUD setLabelText:_successMessageTitlesForSync[0]];
              //[HUD setDetailsLabelText:@"(synced with server)"];
              UIImage *image = [UIImage imageNamed:@"hud-complete"];
              UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
              [HUD setCustomView:imageView];
              HUD.mode = MBProgressHUDModeCustomView;
              [HUD hide:YES afterDelay:1.30];
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                _itemAddedBlk(self, _newEntity);  // this is what causes this controller to be dismissed
              });
            }
          });
        } else {
          // mixed results or only errors
          dispatch_async(dispatch_get_main_queue(), ^{
            [HUD hide:YES afterDelay:0];
            NSDictionary *messageAttrs = @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0],
                                            NSForegroundColorAttributeName : [UIColor blueColor] };
            NSRange messageAttrsRange;
            NSMutableAttributedString *attrMessage;
            if ([_successMessageTitlesForSync count] > 0) {
              // mixed results
              NSString *title = [NSString stringWithFormat:@"Mixed results %@.", mainMsgTitle];
              NSString *message = @"\
Some of the edits synced and some did not.\n\
The ones that did not have been saved\n\
locally and will need to be fixed individually.\n\
The successful syncs are:";
              messageAttrsRange = NSMakeRange(65, 88); // 'have...locally'
              attrMessage = [[NSMutableAttributedString alloc] initWithString:message];
              [attrMessage setAttributes:messageAttrs range:messageAttrsRange];
              JGActionSheetSection *contentSection = [PEUIUtils mixedResultsAlertSectionWithSuccessMsgs:_successMessageTitlesForSync
                                                                                                  title:title
                                                                                       alertDescription:attrMessage
                                                                                    failuresDescription:[[NSAttributedString alloc] initWithString:@"The errors are:"]
                                                                                               failures:_errorsForSync
                                                                                         relativeToView:self.view];
              JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                                    message:nil
                                                                               buttonTitles:@[@"Okay."]
                                                                                buttonStyle:JGActionSheetButtonStyleDefault];
              JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:@[contentSection, buttonsSection]];
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
            } else {
              // only error(s)
              NSString *title;
              NSString *fixNowActionTitle;
              NSString *fixLaterActionTitle;
              NSString *dealWithLaterActionTitle;
              NSString *cancelActionTitle;
              NSString *message;
              JGActionSheetSection *contentSection;
              if (isMultiStepAdd) {
                message = @"\
Although there were problems syncing your\n\
edits to the server, they have been saved\n\
locally.  The details are as follows:";
                messageAttrsRange = NSMakeRange(69, 23); // 'have...locally'
                attrMessage = [[NSMutableAttributedString alloc] initWithString:message];
                [attrMessage setAttributes:messageAttrs range:messageAttrsRange];
                fixNowActionTitle = @"I'll fix them now.";
                fixLaterActionTitle = @"I'll fix them later.";
                cancelActionTitle = @"Forget it.  Just cancel them.";
                dealWithLaterActionTitle = @"I'll try syncing them later.";
                title = [NSString stringWithFormat:@"Problems %@.", mainMsgTitle];
                contentSection = [PEUIUtils multiErrorAlertSectionWithFailures:_errorsForSync
                                                                         title:title
                                                              alertDescription:attrMessage
                                                                relativeToView:self.view];
              } else {
                dealWithLaterActionTitle = @"I'll try syncing it later.";
                cancelActionTitle = @"Forget it.  Just cancel this.";
                NSArray *subErrors = _errorsForSync[0][2]; // because only single-record add, we can skip the "not saved" msg title, and just display the sub-errors
                if ([subErrors count] > 1) {
                  title = [NSString stringWithFormat:@"Errors %@.", mainMsgTitle];
                  message = @"\
Although there were problems syncing your\n\
edits to the server, they have been saved\n\
locally.  The errors are as follows:";
                  messageAttrsRange = NSMakeRange(68, 23); // 'have...locally'
                  fixNowActionTitle = @"I'll fix them now.";
                  fixLaterActionTitle = @"I'll fix them later.";
                } else {
                  title = [NSString stringWithFormat:@"Error %@.", mainMsgTitle];
                  message = @"\
Although there was a problem syncing your\n\
edits to the server, they have been saved\n\
locally.  The error is as follows:";
                  messageAttrsRange = NSMakeRange(68, 23); // 'have...locally'
                  fixLaterActionTitle = @"I'll fix it later.";
                  fixNowActionTitle = @"I'll fix it now.";
                }
                attrMessage = [[NSMutableAttributedString alloc] initWithString:message];
                [attrMessage setAttributes:messageAttrs range:messageAttrsRange];
                contentSection = [PEUIUtils errorAlertSectionWithMsgs:subErrors
                                                                title:title
                                                     alertDescription:attrMessage
                                                       relativeToView:self.view];
              }
              JGActionSheetSection *becameUnauthSection = [self becameUnauthenticatedSection];
              JGActionSheetSection *buttonsSection;
              void (^buttonsPressedBlock)(JGActionSheet *, NSIndexPath *);
              if ([PEAddViewEditController areErrorsAllUserFixable:_errorsForSync]) {
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
                      reenableScreen();
                      break;
                    case 1: // fix later
                      notificationSenderForAdd(_newEntity);
                      _itemAddedBlk(self, _newEntity);
                      break;
                    case 2: // cancel
                      _entityAddCanceler(self, YES, _newEntity);
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
                    case 0:  // sync/deal-with it later
                      notificationSenderForAdd(_newEntity);
                      _itemAddedBlk(self, _newEntity);
                      break;
                    case 1:  // cancel
                      _entityAddCanceler(self, YES, _newEntity);
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
      void(^handleHudProgress)(float) = ^(float percentComplete) {
        _percentCompleteSavingEntity += percentComplete;
        dispatch_async(dispatch_get_main_queue(), ^{
          HUD.progress = _percentCompleteSavingEntity;
        });
      };
      void(^syncNotFoundBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                NSString *mainMsgTitle,
                                                                NSString *recordTitle) {
        handleHudProgress(percentComplete);
        [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                    [NSNumber numberWithBool:NO],
                                    @[[NSString stringWithFormat:@"Not found."]]]];
        if (_percentCompleteSavingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      void(^syncSuccessBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                               NSString *mainMsgTitle,
                                                               NSString *recordTitle) {
        handleHudProgress(percentComplete);
        [_successMessageTitlesForSync addObject:[NSString stringWithFormat:@"%@ synced.", recordTitle]];
        if (_percentCompleteSavingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      void(^syncRetryAfterBlk)(float, NSString *, NSString *, NSDate *) = ^(float percentComplete,
                                                                            NSString *mainMsgTitle,
                                                                            NSString *recordTitle,
                                                                            NSDate *retryAfter) {
        handleHudProgress(percentComplete);
        [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                   [NSNumber numberWithBool:NO],
                                   @[[NSString stringWithFormat:@"Server busy.  Retry after: %@", retryAfter]]]];
        if (_percentCompleteSavingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      void(^syncServerTempError)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                    NSString *mainMsgTitle,
                                                                    NSString *recordTitle) {
        handleHudProgress(percentComplete);
        [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                   [NSNumber numberWithBool:NO],
                                   @[@"Temporary server error."]]];
        if (_percentCompleteSavingEntity == 1.0) {
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
        [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                   [NSNumber numberWithBool:isErrorUserFixable],
                                   computedErrMsgs]];
        if (_percentCompleteSavingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      void(^syncAuthReqdBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                NSString *mainMsgTitle,
                                                                NSString *recordTitle) {
        _receivedAuthReqdErrorOnSyncAttempt = YES;
        handleHudProgress(percentComplete);
        [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                   [NSNumber numberWithBool:NO],
                                   @[@"Authentication required."]]];
        if (_percentCompleteSavingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      void(^syncDependencyUnsyncedBlk)(float, NSString *, NSString *, NSString *) = ^(float percentComplete,
                                                                                      NSString *mainMsgTitle,
                                                                                      NSString *recordTitle,
                                                                                      NSString *dependencyErrMsg) {
        handleHudProgress(percentComplete);
        [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                    [NSNumber numberWithBool:NO],
                                    @[dependencyErrMsg]]];
        if (_percentCompleteSavingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        _newEntitySaver(_entityFormPanel,
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
      _newEntitySaver(_entityFormPanel, _newEntity, nil, nil, nil, nil, nil, nil, nil, nil);
      [[[self navigationItem] leftBarButtonItem] setEnabled:NO]; // cancel btn (so they can't cancel it after we'ved saved and we're displaying the HUD)
      [[[self navigationItem] rightBarButtonItem] setEnabled:NO]; // done btn
      [[[self tabBarController] tabBar] setUserInteractionEnabled:NO];
      MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      HUD.delegate = self;
      [HUD setLabelText:[NSString stringWithFormat:@"%@ Saved.", _entityTitle]];
      if (_isUserLoggedIn()) {
        [HUD setDetailsLabelText:@"(not synced with server)"];
      }
      UIImage *image = [UIImage imageNamed:@"hud-complete"];
      UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
      [HUD setCustomView:imageView];
      HUD.mode = MBProgressHUDModeCustomView;
      [HUD hide:YES afterDelay:1.30];
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        notificationSenderForAdd(_newEntity);
        _itemAddedBlk(self, _newEntity);  // this is what causes this controller to be dismissed
      });
    }
  } else {
    [PEUIUtils showWarningAlertWithMsgs:errMsgs
                                  title:@"Oops"
                       alertDescription:[[NSAttributedString alloc] initWithString:@"There are some validation errors:"]
                               topInset:70.0
                            buttonTitle:@"Okay."
                           buttonAction:nil
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
    [self setEditing:NO animated:YES]; // to get 'Done' button to turn to 'Edit'
  }
}

@end
