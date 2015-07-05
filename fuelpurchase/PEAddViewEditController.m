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
  SEL _getterForNotification;
  BOOL _isEntityAppropriateForBackgroundSync;
  id _newEntity;
  PELMMainSupport *_entityCopyBeforeEdit;
  float _percentCompleteSavingEntity;
  MBProgressHUDMode _syncImmediateMBProgressHUDMode;
  NSMutableArray *_errorsForSync;
  NSMutableArray *_successMessageTitlesForSync;
  BOOL _receivedAuthReqdErrorOnSyncAttempt;
  BOOL _isUserLoggedIn;
  PEListViewController *_listViewController;
  UIBarButtonItem *_syncBarButtonItem;
  PESyncerBlk _syncer;
}

#pragma mark - Initializers

- (id)initWithEntity:(PELMMainSupport *)entity
  listViewController:(PEListViewController *)listViewController
               isAdd:(BOOL)isAdd
           indexPath:(NSIndexPath *)indexPath
           uitoolkit:(PEUIToolkit *)uitoolkit
        itemAddedBlk:(PEItemAddedBlk)itemAddedBlk
      itemChangedBlk:(PEItemChangedBlk)itemChangedBlk
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
isEntityAppropriateForLaterSync:(BOOL)isEntityAppropriateForLaterSync // rename to 'isEntityAppropriateForLaterSync'
prepareUIForUserInteractionBlk:(PEPrepareUIForUserInteractionBlk)prepareUIForUserInteractionBlk
    viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
     entityValidator:(PEEntityValidatorBlk)entityValidator
              syncer:(PESyncerBlk)syncer
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
    _isEntityAppropriateForBackgroundSync = isEntityAppropriateForLaterSync;
    _prepareUIForUserInteractionBlk = prepareUIForUserInteractionBlk;
    _viewDidAppearBlk = viewDidAppearBlk;
    _entityValidator = entityValidator;
    _syncer = syncer;
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
                            syncImmediateWhenDoneEditing:(BOOL)syncImmediateWhenDoneEditing
                                          isUserLoggedIn:(BOOL)isUserLoggedIn
                          syncImmediateMBProgressHUDMode:(MBProgressHUDMode)syncImmediateMBProgressHUDMode
                    isEntityAppropriateForLaterSync:(BOOL)isEntityAppropriateForBackgroundSync {
  return [PEAddViewEditController addEntityCtrlrWithUitoolkit:uitoolkit
                                           listViewController:listViewController
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
                                 syncImmediateWhenDoneEditing:syncImmediateWhenDoneEditing
                                               isUserLoggedIn:isUserLoggedIn
                               syncImmediateMBProgressHUDMode:syncImmediateMBProgressHUDMode
                              isEntityAppropriateForLaterSync:isEntityAppropriateForBackgroundSync
                                        getterForNotification:nil];
}

+ (PEAddViewEditController *)addEntityCtrlrWithUitoolkit:(PEUIToolkit *)uitoolkit
                                      listViewController:(PEListViewController *)listViewController
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
                            syncImmediateWhenDoneEditing:(BOOL)syncImmediateWhenDoneEditing
                                          isUserLoggedIn:(BOOL)isUserLoggedIn
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
                         isEntityAppropriateForLaterSync:isEntityAppropriateForBackgroundSync
                          prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                        viewDidAppearBlk:viewDidAppearBlk
                                         entityValidator:entityValidator
                                                  syncer:nil
                                   getterForNotification:getterForNotification];
}

+ (PEAddViewEditController *)viewEntityCtrlrWithEntity:(PELMMainSupport *)entity
                                    listViewController:(PEListViewController *)listViewController
                                       entityIndexPath:(NSIndexPath *)entityIndexPath
                                             uitoolkit:(PEUIToolkit *)uitoolkit
                                        itemChangedBlk:(PEItemChangedBlk)itemChangedBlk
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
                       isEntityAppropriateForLaterSync:(BOOL)isEntityAppropriateForLaterSync
                        prepareUIForUserInteractionBlk:(PEPrepareUIForUserInteractionBlk)prepareUIForUserInteractionBlk
                                      viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
                                       entityValidator:(PEEntityValidatorBlk)entityValidator
                                                syncer:(PESyncerBlk)syncer {
  return [[PEAddViewEditController alloc] initWithEntity:entity
                                      listViewController:listViewController
                                                   isAdd:NO
                                               indexPath:entityIndexPath
                                               uitoolkit:uitoolkit
                                            itemAddedBlk:nil
                                          itemChangedBlk:itemChangedBlk
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
                         isEntityAppropriateForLaterSync:isEntityAppropriateForLaterSync
                          prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                        viewDidAppearBlk:viewDidAppearBlk
                                         entityValidator:entityValidator
                                                  syncer:syncer
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

#pragma mark - JGActionSheetDelegate

- (void)actionSheetWillPresent:(JGActionSheet *)actionSheet {}

- (void)actionSheetDidPresent:(JGActionSheet *)actionSheet {}

- (void)actionSheetWillDismiss:(JGActionSheet *)actionSheet {}

- (void)actionSheetDidDismiss:(JGActionSheet *)actionSheet {}

#pragma mark - Sync

- (void)setSyncBarButtonState {
  BOOL enableSyncItem = NO;
  NSString *syncTitle = @"";
  if (_entity) {
    syncTitle = @"";
    if (_syncer &&
        _syncImmediateWhenDoneEditing &&
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
    _panelEnablerDisabler(_entityPanel, NO);
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
        NSMutableString *message = [NSMutableString string];
        NSArray *subErrors = _errorsForSync[0][2];
        if ([subErrors count] > 1) {
          [message appendString:@"There were problems syncing to the server.  The errors are as follows:\n"];
          title = [NSString stringWithFormat:@"Errors %@.", mainMsgTitle];
        } else {
          [message appendString:@"There was a problem syncing to the server.  The error is as follows:\n"];
          title = [NSString stringWithFormat:@"Error %@.", mainMsgTitle];
        }
        for (NSString *subError in subErrors) {
          [message appendFormat:@"\n%@", subError];
        }
        if (_receivedAuthReqdErrorOnSyncAttempt) {
          [message appendString:@"\n\nIt appears that you are no longer\n"];
          [message appendString:@"authenticated.  To re-authenticate, go to\n"];
          [message appendString:@"Settings -> Authenticate."];
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okay = [UIAlertAction actionWithTitle:okayActionTitle
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) { postSyncActivities(); }];
        [alert addAction:okay];
        [self presentViewController:alert animated:YES completion:nil];
      });
    }
  };
  void (^handleHudProgress)(float) = ^(float percentComplete) {
    _percentCompleteSavingEntity += percentComplete;
    dispatch_async(dispatch_get_main_queue(), ^{
      HUD.progress = _percentCompleteSavingEntity;
    });
  };
  void(^_syncSuccessBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                            NSString *mainMsgTitle,
                                                            NSString *recordTitle) {
    handleHudProgress(percentComplete);
    [_successMessageTitlesForSync addObject:[NSString stringWithFormat:@"%@ synced.", recordTitle]];
    if (_percentCompleteSavingEntity == 1.0) {
      syncDone(mainMsgTitle);
    }
  };
  void(^_syncRetryAfterBlk)(float, NSString *, NSString *, NSDate *) = ^(float percentComplete,
                                                                         NSString *mainMsgTitle,
                                                                         NSString *recordTitle,
                                                                         NSDate *retryAfter) {
    handleHudProgress(percentComplete);
    [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                [NSNumber numberWithBool:NO],
                                @[[NSString stringWithFormat:@"Server busy.  Retry after: %@", retryAfter]]]];
    if (_percentCompleteSavingEntity == 1.0) {
      syncDone(mainMsgTitle);
    }
  };
  void (^_syncServerTempError)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                  NSString *mainMsgTitle,
                                                                  NSString *recordTitle) {
    handleHudProgress(percentComplete);
    [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                [NSNumber numberWithBool:NO],
                                @[@"Temporary server error."]]];
    if (_percentCompleteSavingEntity == 1.0) {
      syncDone(mainMsgTitle);
    }
  };
  void (^_syncServerError)(float, NSString *, NSString *, NSArray *) = ^(float percentComplete,
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
      syncDone(mainMsgTitle);
    }
  };
  void(^_syncAuthReqdBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                             NSString *mainMsgTitle,
                                                             NSString *recordTitle) {
    _receivedAuthReqdErrorOnSyncAttempt = YES;
    handleHudProgress(percentComplete);
    [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                [NSNumber numberWithBool:NO],
                                @[@"Authentication required."]]];
    if (_percentCompleteSavingEntity == 1.0) {
      syncDone(mainMsgTitle);
    }
  };
  void (^_syncDependencyUnsyncedBlk)(float, NSString *, NSString *, NSString *) = ^(float percentComplete,
                                                                                    NSString *mainMsgTitle,
                                                                                    NSString *recordTitle,
                                                                                    NSString *dependencyErrMsg) {
    handleHudProgress(percentComplete);
    [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                [NSNumber numberWithBool:NO],
                                @[dependencyErrMsg]]];
    if (_percentCompleteSavingEntity == 1.0) {
      syncDone(mainMsgTitle);
    }
  };
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    _syncer(self,
            _entity,
            _syncSuccessBlk,
            _syncRetryAfterBlk,
            _syncServerTempError,
            _syncServerError,
            _syncAuthReqdBlk,
            _syncDependencyUnsyncedBlk);
  });
}

#pragma mark - Toggle into edit mode

- (void)setEditing:(BOOL)flag animated:(BOOL)animated {
  if (flag) {
    if ([self prepareForEditing]) {
      _entityCopyBeforeEdit = [_entity copy];
      [super setEditing:flag animated:animated];
      if (_prepareUIForUserInteractionBlk) {
        _prepareUIForUserInteractionBlk(_entityPanel);
      }
      [self setSyncBarButtonState];
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
    _panelEnablerDisabler(_entityPanel, NO);
    if (_listViewController) {
      [_listViewController handleUpdatedEntity:_entity];
    }
    [self setSyncBarButtonState];
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
              NSString *title;
              NSString *fixNowActionTitle;
              NSString *fixLaterActionTitle;
              NSString *dealWithLaterActionTitle;
              NSString *cancelActionTitle;
              NSMutableString *message = [NSMutableString string];
              NSArray *subErrors = _errorsForSync[0][2]; // because only single-record edit, we can skip the "not saved" msg title, and just display the sub-errors
              if ([subErrors count] > 1) {
                [message appendString:@"Although there were problems syncing your edits to the server, they have been saved locally.  The errors are as follows:\n"];
                fixNowActionTitle = @"I'll fix them now.";
                fixLaterActionTitle = @"I'll fix them later.";
                dealWithLaterActionTitle = @"I'll try syncing them later.";
                cancelActionTitle = @"Forget it.  Just cancel them.";
                title = [NSString stringWithFormat:@"Errors %@.", mainMsgTitle];
              } else {
                [message appendString:@"Although there was a problem syncing your edits to the server, they have been saved locally.  The error is as follows:\n"];
                fixLaterActionTitle = @"I'll fix it later.";
                fixNowActionTitle = @"I'll fix it now.";
                dealWithLaterActionTitle = @"I'll try syncing it later.";
                cancelActionTitle = @"Forget it.  Just cancel it.";
                title = [NSString stringWithFormat:@"Error %@.", mainMsgTitle];
              }
              for (NSString *subError in subErrors) {
                [message appendFormat:@"\n%@", subError];
              }
              if (_receivedAuthReqdErrorOnSyncAttempt) {
                [message appendString:@"\n\nIt appears that you are no longer\n"];
                [message appendString:@"authenticated.  To re-authenticate, go to\n"];
                [message appendString:@"Settings -> Authenticate."];
              }
              UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
              if ([PEAddViewEditController areErrorsAllUserFixable:_errorsForSync]) {
                UIAlertAction *fixNow = [UIAlertAction actionWithTitle:fixNowActionTitle
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction *action){
                                                                 _entityEditPreparer(self, _entity);
                                                                 [super setEditing:YES animated:NO];
                                                                 [[[self navigationItem] rightBarButtonItem] setEnabled:YES];
                                                               }];
                UIAlertAction *fixLater = [UIAlertAction actionWithTitle:fixLaterActionTitle
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *action) { postEditActivities(); }];
                [alert addAction:fixNow];
                [alert addAction:fixLater];
              } else {
                UIAlertAction *dealWithLater = [UIAlertAction actionWithTitle:dealWithLaterActionTitle
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction *action) { postEditActivities(); }];
                [alert addAction:dealWithLater];
              }
              UIAlertAction *cancel = [UIAlertAction actionWithTitle:cancelActionTitle
                                                               style:UIAlertActionStyleDestructive
                                                             handler:^(UIAlertAction *action) {
                                                               // First, we need to save the copy-before-edit entity to get the database
                                                               // back to how it was before the user did the editing
                                                               _entitySaver(self, _entityCopyBeforeEdit);

                                                               // now we can cancel the edit session as we normally would
                                                               [_entity overwrite:_entityCopyBeforeEdit];
                                                               _entityEditCanceler(self, _entity);
                                                               _entityToPanelBinder(_entity, _entityPanel);
                                                               _isEditCanceled = NO; // reseting this
                                                               postEditActivities();
                                                             }];
              [alert addAction:cancel];
              [self presentViewController:alert animated:YES completion:nil];
            });
          }
        };
        void (^handleHudProgress)(float) = ^(float percentComplete) {
          _percentCompleteSavingEntity += percentComplete;
          dispatch_async(dispatch_get_main_queue(), ^{
            HUD.progress = _percentCompleteSavingEntity;
          });
        };
        void(^_syncSuccessBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                  NSString *mainMsgTitle,
                                                                  NSString *recordTitle) {
          handleHudProgress(percentComplete);
          [_successMessageTitlesForSync addObject:[NSString stringWithFormat:@"%@ synced.", recordTitle]];
          if (_percentCompleteSavingEntity == 1.0) {
            immediateSyncDone(mainMsgTitle);
          }
        };
        void(^_syncRetryAfterBlk)(float, NSString *, NSString *, NSDate *) = ^(float percentComplete,
                                                                               NSString *mainMsgTitle,
                                                                               NSString *recordTitle,
                                                                               NSDate *retryAfter) {
          handleHudProgress(percentComplete);
          [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                     [NSNumber numberWithBool:NO],
                                     @[[NSString stringWithFormat:@"Server busy.  Retry after: %@", retryAfter]]]];
          if (_percentCompleteSavingEntity == 1.0) {
            immediateSyncDone(mainMsgTitle);
          }
        };
        void (^_syncServerTempError)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                        NSString *mainMsgTitle,
                                                                        NSString *recordTitle) {
          handleHudProgress(percentComplete);
          [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                     [NSNumber numberWithBool:NO],
                                     @[@"Temporary server error."]]];
          if (_percentCompleteSavingEntity == 1.0) {
            immediateSyncDone(mainMsgTitle);
          }
        };
        void (^_syncServerError)(float, NSString *, NSString *, NSArray *) = ^(float percentComplete,
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
            immediateSyncDone(mainMsgTitle);
          }
        };
        void(^_syncAuthReqdBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                   NSString *mainMsgTitle,
                                                                   NSString *recordTitle) {
          _receivedAuthReqdErrorOnSyncAttempt = YES;
          handleHudProgress(percentComplete);
          [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                     [NSNumber numberWithBool:NO],
                                     @[@"Authentication required."]]];
          if (_percentCompleteSavingEntity == 1.0) {
            immediateSyncDone(mainMsgTitle);
          }
        };
        void (^_syncDependencyUnsyncedBlk)(float, NSString *, NSString *, NSString *) = ^(float percentComplete,
                                                                                          NSString *mainMsgTitle,
                                                                                          NSString *recordTitle,
                                                                                          NSString *dependencyErrMsg) {
          handleHudProgress(percentComplete);
          [_errorsForSync addObject:@[[NSString stringWithFormat:@"%@ not synced.", recordTitle],
                                      [NSNumber numberWithBool:NO],
                                      @[dependencyErrMsg]]];
          if (_percentCompleteSavingEntity == 1.0) {
            immediateSyncDone(mainMsgTitle);
          }
        };
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
          _doneEditingEntityMarker(self,
                                   _entity,
                                   _syncSuccessBlk,
                                   _syncRetryAfterBlk,
                                   _syncServerTempError,
                                   _syncServerError,
                                   _syncAuthReqdBlk,
                                   _syncDependencyUnsyncedBlk);
        });
      } else {
        [[[self navigationItem] leftBarButtonItem] setEnabled:NO]; // cancel btn (so they can't cancel it after we'ved saved and we're displaying the HUD)
        [[[self navigationItem] rightBarButtonItem] setEnabled:NO]; // done btn
        [[[self tabBarController] tabBar] setUserInteractionEnabled:NO];
        _doneEditingEntityMarker(self, _entity, nil, nil, nil, nil, nil, nil);
        MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        HUD.delegate = self;
        [HUD setLabelText:[NSString stringWithFormat:@"%@ Saved.", _entityTitle]];
        if (_isUserLoggedIn) {
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

- (UIView *)errorPanelWithTitle:(NSString *)title
                 forContentView:(UIView *)contentView
                         height:(CGFloat)height
                    leftImgIcon:(UIImage *)leftImgIcon {
  UIView *errorPanel = [PEUIUtils panelWithWidthOf:0.9 relativeToView:contentView fixedHeight:height];
  //[PEUIUtils applyBorderToView:subErrorPanel withColor:[UIColor blueColor]];
  UIImageView *errImgView = [[UIImageView alloc] initWithImage:leftImgIcon];
  UILabel *errorMsgLbl = [PEUIUtils labelWithKey:title
                                            font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                 backgroundColor:[UIColor clearColor]
                                       textColor:[UIColor blackColor]
                           horizontalTextPadding:3.0
                             verticalTextPadding:0.0];
  [PEUIUtils placeView:errImgView
            inMiddleOf:errorPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              hpadding:0.0];
  [PEUIUtils placeView:errorMsgLbl
          toTheRightOf:errImgView
                  onto:errorPanel
         withAlignment:PEUIVerticalAlignmentTypeCenter
              hpadding:5.0];
  return errorPanel;
}

- (NSArray *)subErrorPanelsForSubErrors:(NSArray *)subErrors
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
      if (_listViewController) {
        [_listViewController handleAddedEntity:newEntityForNotification];
      }
    };
    if (_syncImmediateWhenDoneEditing) {
      void (^reenableScreen)(void) = ^{
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
              NSMutableString *message = [NSMutableString string];
              [message appendString:@"\n\n"];
              [message appendString:[PEUtils concat:_successMessageTitlesForSync]];
              UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
              UIAlertAction *okay = [UIAlertAction actionWithTitle:@"Okay."
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
                                                             _itemAddedBlk(self, _newEntity);}];
              [alert addAction:okay];
              [self presentViewController:alert animated:YES completion:nil];
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
          UIImage *syncErrorImg = [UIImage imageNamed:@"sync-error"];
          UIImage *blackDotImg = [UIImage imageNamed:@"black-dot"];
          dispatch_async(dispatch_get_main_queue(), ^{
            [HUD hide:YES afterDelay:0];
            if ([_successMessageTitlesForSync count] > 0) {
              // mixed results
              NSString *title = [NSString stringWithFormat:@"Mixed results %@.", mainMsgTitle];
              NSMutableString *message = [NSMutableString string];
              [message appendString:@"Because the results are mixed, you\n"];
              [message appendString:@"need to fix the errors on the\n"];
              [message appendString:@"individual affected records.\n\n"];
              [message appendString:@"Successes:\n\n"];
              [message appendString:[PEUtils concat:_successMessageTitlesForSync]];
              [message appendString:@"\n\nErrors:\n"];
              for (NSArray *error in _errorsForSync) {
                [message appendFormat:@"\n%@", error[0]]; // error message title
                NSArray *subErrors = error[2];
                for (NSString *subError in subErrors) {
                  [message appendFormat:@"\n\t%@", subError];
                }
              }
              if (_receivedAuthReqdErrorOnSyncAttempt) {
                [message appendString:@"\n\nIt appears that you are no longer\n"];
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
              NSArray *subErrorPanels;
              CGFloat contentViewHeight;
              UIView *contentView = [PEUIUtils panelWithWidthOf:0.905
                                                 relativeToView:[self view]
                                                    fixedHeight:0.0];
              NSString *title;
              NSString *fixNowActionTitle;
              NSString *fixLaterActionTitle;
              NSString *dealWithLaterActionTitle;
              NSString *cancelActionTitle;
              NSMutableString *message = [NSMutableString string];
              if (isMultiStepAdd) {
                contentViewHeight = 145.0;
                [message appendString:@"\
Although there were problems syncing your\n\
edits to the server, they have been saved\n\
locally.  The details are as follows:\n"];
                fixNowActionTitle = @"I'll fix them now.";
                fixLaterActionTitle = @"I'll fix them later.";
                cancelActionTitle = @"Forget it.  Just cancel them.";
                dealWithLaterActionTitle = @"I'll try syncing them later.";
                title = [NSString stringWithFormat:@"Error %@.", mainMsgTitle];
                
                subErrorPanels = [NSMutableArray arrayWithCapacity:[_errorsForSync count]];
                for (NSArray *error in _errorsForSync) {
                  NSArray *subErrors = error[2];
                  contentViewHeight += (25 + ([subErrors count] * 19.0));
                  UIView *subErrorPanel = [PEUIUtils panelWithWidthOf:0.9
                                                       relativeToView:contentView
                                                          fixedHeight:0]; // will set later
                  //[PEUIUtils applyBorderToView:subErrorPanel withColor:[UIColor redColor]];
                  UIView *recordMsgTitle = [self errorPanelWithTitle:error[0]
                                                      forContentView:contentView
                                                              height:25.0
                                                         leftImgIcon:syncErrorImg];
                  //[PEUIUtils applyBorderToView:recordMsgTitle withColor:[UIColor greenColor]];
                  NSArray *recordSubErrorPanels = [self subErrorPanelsForSubErrors:subErrors
                                                                    forContentView:contentView
                                                                       leftImgIcon:blackDotImg];
                  [PEUIUtils placeView:recordMsgTitle
                               atTopOf:subErrorPanel
                         withAlignment:PEUIHorizontalAlignmentTypeLeft
                              vpadding:0.0
                              hpadding:0.0];
                  UIView *columnOfViews = [PEUIUtils panelWithColumnOfViews:recordSubErrorPanels
                                                verticalPaddingBetweenViews:0.0
                                                             viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
                  [PEUIUtils setFrameHeight:(columnOfViews.frame.size.height + recordMsgTitle.frame.size.height) ofView:subErrorPanel];
                  //[PEUIUtils applyBorderToView:columnOfViews withColor:[UIColor purpleColor]];
                  [PEUIUtils placeView:columnOfViews
                                 below:recordMsgTitle
                                  onto:subErrorPanel
                         withAlignment:PEUIHorizontalAlignmentTypeLeft
                              vpadding:0.0
                              hpadding:15.0];
                  [(NSMutableArray *)subErrorPanels addObject:subErrorPanel];
                }
              } else {
                contentViewHeight = 120.0;
                NSArray *subErrors = _errorsForSync[0][2]; // because only single-record add, we can skip the "not saved" msg title, and just display the sub-errors
                if ([subErrors count] > 1) {
                  contentViewHeight += ([subErrors count] * 17);
                  title = [NSString stringWithFormat:@"Errors %@.", mainMsgTitle];
                  [message appendString:@"\
Although there were problems syncing your\n\
edits to the server, they have been saved\n\
locally.  The errors are as follows:\n"];
                  fixNowActionTitle = @"I'll fix them now.";
                  fixLaterActionTitle = @"I'll fix them later.";
                  dealWithLaterActionTitle = @"I'll try syncing it later.";
                  cancelActionTitle = @"Forget it.  Just cancel this.";
                } else {
                  title = [NSString stringWithFormat:@"Error %@.", mainMsgTitle];
                  [message appendString:@"\
Although there was a problem syncing your\n\
edits to the server, they have been saved\n\
locally.  The error is as follows:\n"];
                  fixLaterActionTitle = @"I'll fix it later.";
                  fixNowActionTitle = @"I'll fix it now.";
                  dealWithLaterActionTitle = @"I'll try syncing it later.";
                  cancelActionTitle = @"Forget it.  Just cancel this.";
                }
                subErrorPanels = [self subErrorPanelsForSubErrors:subErrors
                                                   forContentView:contentView
                                                     leftImgIcon:syncErrorImg];
              }
              if (_receivedAuthReqdErrorOnSyncAttempt) {
                [message appendString:@"\n\n\
It appears that you are not longer\n\
authenticated.  To re-authenticate, go to\n\
Settings -> Authenticate."];
              }
              [PEUIUtils setFrameHeight:contentViewHeight ofView:contentView];
              UILabel *messageLbl = [PEUIUtils labelWithKey:message
                                                       font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                            backgroundColor:[UIColor clearColor]
                                                  textColor:[UIColor blackColor]
                                      horizontalTextPadding:3.0
                                        verticalTextPadding:0.0];
              [PEUIUtils setFrameHeight:62.0 ofView:messageLbl];
              [messageLbl setLineBreakMode:NSLineBreakByWordWrapping];
              //NSLog(@"messageLbl.height: %f", messageLbl.frame.size.height);
              
              UILabel *titleLbl = [PEUIUtils labelWithKey:title
                                                     font:[UIFont boldSystemFontOfSize:18]
                                          backgroundColor:[UIColor clearColor]
                                                textColor:[UIColor blackColor]
                                    horizontalTextPadding:3.0
                                      verticalTextPadding:0.0];
              [titleLbl setLineBreakMode:NSLineBreakByWordWrapping];
              NSLog(@"titleLbl.height: %f", titleLbl.frame.size.height);
              
              [PEUIUtils placeView:titleLbl
                           atTopOf:contentView
                     withAlignment:PEUIHorizontalAlignmentTypeLeft
                          vpadding:0.0
                          hpadding:5.0];
              
              [PEUIUtils placeView:messageLbl
                             below:titleLbl
                              onto:contentView
                     withAlignment:PEUIHorizontalAlignmentTypeLeft
                          vpadding:0.0
                          hpadding:0.0];
              //[PEUIUtils applyBorderToView:messageLbl withColor:[UIColor yellowColor]];
              UIView *subErrorsPanel = [PEUIUtils panelWithColumnOfViews:subErrorPanels
                                             verticalPaddingBetweenViews:1.0
                                                          viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
              //[PEUIUtils applyBorderToView:subErrorsPanel withColor:[UIColor purpleColor]];
              [PEUIUtils placeView:subErrorsPanel
                             below:messageLbl
                              onto:contentView
                     withAlignment:PEUIHorizontalAlignmentTypeLeft
                          vpadding:0.0
                          hpadding:0.0];
              JGActionSheetSection *msgSection = [JGActionSheetSection sectionWithTitle:nil
                                                                                message:nil
                                                                            contentView:contentView];
              [[msgSection titleLabel] setFont:[UIFont boldSystemFontOfSize:18.0]];
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
                      _itemAddedBlk(self, _newEntity);
                      break;
                    case 1:  // cancel
                      _entityAddCanceler(self, YES, _newEntity);
                      break;
                  }
                  [sheet dismissAnimated:YES];
                };
              }
              JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:@[msgSection, buttonsSection]];
              [alertSheet setDelegate:self];
              [alertSheet setInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
              [alertSheet setButtonPressedBlock:buttonsPressedBlock];
              [alertSheet showInView:[self view] animated:YES];
              /*UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
              if ([PEAddViewEditController areErrorsAllUserFixable:_errorsForSync]) {
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
              [self presentViewController:alert animated:YES completion:nil];*/
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
      void(^_syncSuccessBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                NSString *mainMsgTitle,
                                                                NSString *recordTitle) {
        handleHudProgress(percentComplete);
        [_successMessageTitlesForSync addObject:[NSString stringWithFormat:@"%@ synced.", recordTitle]];
        if (_percentCompleteSavingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      void(^_syncRetryAfterBlk)(float, NSString *, NSString *, NSDate *) = ^(float percentComplete,
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
      void (^_syncServerTempError)(float, NSString *, NSString *) = ^(float percentComplete,
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
      void (^_syncServerError)(float, NSString *, NSString *, NSArray *) = ^(float percentComplete,
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
      void(^_syncAuthReqdBlk)(float, NSString *, NSString *) = ^(float percentComplete,
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
      void (^_syncDependencyUnsyncedBlk)(float, NSString *, NSString *, NSString *) = ^(float percentComplete,
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
        _newEntitySaver(_entityPanel,
                        _newEntity,
                        _syncSuccessBlk,
                        _syncRetryAfterBlk,
                        _syncServerTempError,
                        _syncServerError,
                        _syncAuthReqdBlk,
                        _syncDependencyUnsyncedBlk);
      });
    } else {
      _newEntitySaver(_entityPanel, _newEntity, nil, nil, nil, nil, nil, nil);
      notificationSenderForAdd(_newEntity);
      [[[self navigationItem] leftBarButtonItem] setEnabled:NO]; // cancel btn (so they can't cancel it after we'ved saved and we're displaying the HUD)
      [[[self navigationItem] rightBarButtonItem] setEnabled:NO]; // done btn
      [[[self tabBarController] tabBar] setUserInteractionEnabled:NO];
      MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      HUD.delegate = self;
      [HUD setLabelText:[NSString stringWithFormat:@"%@ Saved.", _entityTitle]];
      if (_isUserLoggedIn) {
        [HUD setDetailsLabelText:@"(not synced with server)"];
      }
      UIImage *image = [UIImage imageNamed:@"hud-complete"];
      UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
      [HUD setCustomView:imageView];
      HUD.mode = MBProgressHUDModeCustomView;
      [HUD hide:YES afterDelay:1.30];
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
    _entityAddCanceler(self, YES, _newEntity);
    _newEntity = nil;
  } else {
    _isEditCanceled = YES;
    [self setEditing:NO animated:YES]; // to get 'Done' button to turn to 'Edit'
  }
}

@end
