//
//  PEListViewController.m
//  fuelpurchase
//
//  Created by Evans, Paul on 9/19/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "PEListViewController.h"
#import <PEObjc-Commons/PEUIUtils.h>
#import <PEObjc-Commons/PEUtils.h>
#import <PEFuelPurchase-Model/PELMNotificationUtils.h>
#import "PEObjc-Commons/NSMutableArray+PEAdditions.h"
#import "UIScrollView+PEAdditions.h"
#import "FPLogging.h"

@interface PEListViewController () <JGActionSheetDelegate>
@end

@implementation PEListViewController {
  Class _classOfDataSourceObjects;
  NSString *_title;
  UITableView *_tableView;
  PESyncViewStyler _tableCellStyler;
  PEItemSelectedAction _itemSelectedAction;
  id _initialSelectedItem;
  void (^_addItemAction)(PEListViewController *, PEItemAddedBlk);
  NSString *_cellIdentifier;
  NSMutableArray *_dataSource;
  PEPageLoaderBlk _pageLoaderBlk;
  CGFloat _heightForCells;
  FPDetailViewMaker _detailViewMaker;
  PEUIToolkit *_uitoolkit;
  NSIndexPath *_indexPathOfRemovedEntity;
  PEDoesEntityBelongToListView _doesEntityBelongToThisListView;
  PEWouldBeIndexOfEntity _wouldBeIndexOfEntity;
  BOOL _isPaginatedDataSource;
  NSMutableArray *_errorsForDelete;
  NSMutableArray *_successMessageTitlesForDelete;
  BOOL _receivedAuthReqdErrorOnDeleteAttempt;
  PEIsLoggedInBlk _isUserLoggedIn;
  PEIsAuthenticatedBlk _isAuthenticatedBlk;
  PEItemChildrenCounter _itemChildrenCounter;
  PEItemChildrenMsgsBlk _itemChildrenMsgsBlk;
  PEItemDeleter _itemDeleter;
}

#pragma mark - Initializers

- (id)initWithClassOfDataSourceObjects:(Class)classOfDataSourceObjects
                                 title:(NSString *)title
                 isPaginatedDataSource:(BOOL)isPaginatedDataSource
                       tableCellStyler:(PESyncViewStyler)tableCellStyler
                    itemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                   initialSelectedItem:(id)initialSelectedItem
                         addItemAction:(void(^)(PEListViewController *, PEItemAddedBlk))addItemActionBlk
                        cellIdentifier:(NSString *)cellIdentifier
                        initialObjects:(NSArray *)initialObjects
                            pageLoader:(PEPageLoaderBlk)pageLoaderBlk
                        heightForCells:(CGFloat)heightForCells
                       detailViewMaker:(FPDetailViewMaker)detailViewMaker
                             uitoolkit:(PEUIToolkit *)uitoolkit
        doesEntityBelongToThisListView:(PEDoesEntityBelongToListView)doesEntityBelongToThisListView
                  wouldBeIndexOfEntity:(PEWouldBeIndexOfEntity)wouldBeIndexOfEntity
                       isAuthenticated:(PEIsAuthenticatedBlk)isAuthenticatedBlk
                        isUserLoggedIn:(PEIsLoggedInBlk)isUserLoggedIn
                   itemChildrenCounter:(PEItemChildrenCounter)itemChildrenCounter
                   itemChildrenMsgsBlk:(PEItemChildrenMsgsBlk)itemChildrenMsgsBlk
                           itemDeleter:(PEItemDeleter)itemDeleter {
  NSAssert(!(detailViewMaker && initialSelectedItem), @"detailViewMaker and initialSelectedItem cannot BOTH be provided");
  NSAssert(!(detailViewMaker && itemSelectedAction), @"detailViewMaker and itemSelectedAction cannot BOTH be provided");
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _classOfDataSourceObjects = classOfDataSourceObjects;
    _title = title;
    _isPaginatedDataSource = isPaginatedDataSource;
    _tableCellStyler = tableCellStyler;
    _itemSelectedAction = itemSelectedAction;
    _initialSelectedItem = initialSelectedItem;
    _addItemAction = addItemActionBlk;
    _cellIdentifier = cellIdentifier;
    _pageLoaderBlk = pageLoaderBlk;
    _heightForCells = heightForCells;
    _detailViewMaker = detailViewMaker;
    _uitoolkit = uitoolkit;
    _dataSource = [NSMutableArray array];
    _indexPathOfRemovedEntity = nil;
    _doesEntityBelongToThisListView = doesEntityBelongToThisListView;
    _wouldBeIndexOfEntity = wouldBeIndexOfEntity;
    if (_initialSelectedItem) {
      [_dataSource addObject:_initialSelectedItem]; // initial selected is always at top
    }
    [_dataSource addObjectsFromArray:[self truncateInitialSelectedItemFromItems:initialObjects]];
    _errorsForDelete = [NSMutableArray array];
    _successMessageTitlesForDelete = [NSMutableArray array];
    _isAuthenticatedBlk = isAuthenticatedBlk;
    _isUserLoggedIn = isUserLoggedIn;
    _itemChildrenCounter = itemChildrenCounter;
    _itemChildrenMsgsBlk = itemChildrenMsgsBlk;
    _itemDeleter = itemDeleter;
  }
  return self;
}

#pragma mark - Helpers

- (NSNumber *)indexOfEntity:(PELMMainSupport *)entity {
  NSNumber *index = nil;
  NSUInteger dsCount = [_dataSource count];
  for (int i = 0; i < dsCount; i++) {
    if ([entity doesHaveEqualIdentifiers:_dataSource[i]]) {
      index = @(i);
      break;
    }
  }
  return index;
}

- (UIView *)viewForAlerts {
  if (self.tabBarController) {
    return self.tabBarController.view;
  }
  return self.view;
}

#pragma mark - Entity changed methods

- (BOOL)handleUpdatedEntity:(PELMMainSupport *)updatedEntity {
  BOOL entityUpdated = NO;
  DDLogDebug(@"=== begin === in PELVC/handleUpdatedEntity: (hUE) =============================");
  // first (of 2) checks of belonging - type check:
  if ([updatedEntity isKindOfClass:_classOfDataSourceObjects]) {
    // okay, check 1/2 that it belongs.  But before we do the next check, lets
    // obtain the knowledge if it's currently here or not.
    DDLogDebug(@"PELVC/hUE, check 1/2 passed.");
    NSNumber *indexOfExistingEntity = [self indexOfEntity:updatedEntity];
    DDLogDebug(@"PELVC/hUE, idxOfExistingEntity: %@", indexOfExistingEntity);
    // (we'll need these handy-dandy blocks later - sorry for the interruption)
    void (^deleteAtTableIndex)(NSInteger) = ^(NSInteger index) {
      [_tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                        withRowAnimation:UITableViewRowAnimationFade];
    };
    void (^deleteAtIndex)(NSInteger) = ^(NSInteger index) {
      [_dataSource removeObjectAtIndex:index];
      deleteAtTableIndex(index);
    };
    void (^insertAtTableIndex)(NSInteger) = ^(NSInteger index) {
      [_tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                        withRowAnimation:UITableViewRowAnimationAutomatic];
    };
    // Now check 2/2 that it belongs.
    BOOL doesUpdatedEntityBelong = _doesEntityBelongToThisListView(updatedEntity);
    DDLogDebug(@"PELVC/hUE, doesUpdatedEntityBelong: %@", [PEUtils yesNoFromBool:doesUpdatedEntityBelong]);
    if (doesUpdatedEntityBelong) {
      // (the fact we'll be taking "some sort of action" for the given
      //  updatedEntity is good enough for me to set this flag for the return value)
      entityUpdated = YES;
      // So it really does belong.  Let's figure what we need to do.  To know
      // what to do, we need to compute the updated entity's would-be index.
      NSInteger wouldBeIndex = _wouldBeIndexOfEntity(updatedEntity);
      DDLogDebug(@"PELVC/hUE, wouldBeIndex: %ld", (long)wouldBeIndex);
      DDLogDebug(@"PELVC/hUE, FYI, dataSource count: %lu", (unsigned long)[_dataSource count]);
      // We need to know where the entity CURRENTLY is.  Well, is it even here?
      if (indexOfExistingEntity) {
        // It's here.  Lets get its index as plain int.
        NSInteger indexOfExistingEntityAsInt = [indexOfExistingEntity integerValue];
        // Now to see what we have to do.
        if (wouldBeIndex == indexOfExistingEntityAsInt) {
          // No 'movement' required.  It's currently where it needs to be.  Just
          // need to reload the table view row.
          [_dataSource[indexOfExistingEntityAsInt] overwrite:updatedEntity];
          [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:wouldBeIndex inSection:0]]
                            withRowAnimation:UITableViewRowAnimationAutomatic];
          DDLogDebug(@"PELVC/hUE, just need to reload index: %ld.", (long)wouldBeIndex);
        } else if (wouldBeIndex < [_dataSource count]) {
          // Move (fyi, we can't use moveRowsAtIn... because it DOESN't reload
          // the moved rows from the data source, which we need).
          [_dataSource[indexOfExistingEntityAsInt] overwrite:updatedEntity];
          [_dataSource moveObjectFromIndex:indexOfExistingEntityAsInt
                                   toIndex:wouldBeIndex];
          [_tableView beginUpdates];
          deleteAtTableIndex(indexOfExistingEntityAsInt);
          insertAtTableIndex(wouldBeIndex);
          [_tableView endUpdates];
          DDLogDebug(@"PELVC/hUE, moved.");
        } else { // wouldBeIndex >= [_dataSource count]
          // wouldBeIndex is equal to or larger than [_dataSource count], so we need to
          // simply delete it.  I.e., it shouldn't be visible yet.
          deleteAtIndex(indexOfExistingEntityAsInt);
          DDLogDebug(@"PELVC/hUE, deleted.");
        }
      } else {
        // The updated entity belongs, but is not currently here.  Should it be
        // visible?  Lets check.
        DDLogDebug(@"PELVC/hUE, belongs, but is not currently here.");
        if (wouldBeIndex < [_dataSource count]) {
          [_dataSource insertObject:updatedEntity atIndex:wouldBeIndex];
          insertAtTableIndex(wouldBeIndex);
          DDLogDebug(@"PELVC/hUE, belongs, wasn't here, but is now inserted.");
        } else {
          DDLogDebug(@"PELVC/hUE, belongs, wasn't here, but not taking any action because its would-be index is larger than the data source count.");
        }
        // otherwise, the updatedEntity will become visible when the user scrolls
        // and older entities are loaded
      }
    } else {
      // So it doesn't belong.  If it's still here, it needs to be deleted.
      if (indexOfExistingEntity) {
        DDLogDebug(@"PELVC/hUE, unbelonging entity is here at index: %@.  Proceeding to delete it.", indexOfExistingEntity);
        deleteAtIndex([indexOfExistingEntity integerValue]);
      }
    }
  }
  DDLogDebug(@"=== end === in PELVC/handleUpdatedEntity: (hUE) (returning: %@) ==================", [PEUtils yesNoFromBool:entityUpdated]);
  return entityUpdated;
}

- (BOOL)handleRemovedEntity:(PELMMainSupport *)removedEntity {
  BOOL entityRemoved = NO;
  DDLogDebug(@"=== begin === in PELVC/handleRemovedEntity: (hRE) =============================");
  DDLogDebug(@"hRE, removedEntity's localMainIdentifier: %@", [removedEntity localMainIdentifier]);
  DDLogDebug(@"hRE, removedEntity's localMasterIdentifier: %@", [removedEntity localMasterIdentifier]);
  DDLogDebug(@"hRE, removedEntity's globalIdentifier: %@", [removedEntity globalIdentifier]);
  if ([removedEntity isKindOfClass:_classOfDataSourceObjects]) {
    if (([removedEntity localMainIdentifier] == nil) && ([removedEntity localMasterIdentifier] == nil)) {
      DDLogDebug(@"PELVC/hRE, removedEntity's IDs are nil.  So, we're going to check if any entities here match that.");
      NSUInteger dsCount = [_dataSource count];
      PELMMainSupport *entity;
      for (NSInteger i = 0; i < dsCount; i++) {
        entity = _dataSource[i];
        if ([entity localMainIdentifier] == nil && [entity localMasterIdentifier] == nil) {
          DDLogDebug(@"PELVC/hRE, entity at index [%ld] has nil IDs, so we'll remove it.", (long)i);
          [_dataSource removeObjectAtIndex:i];
          [_tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]]
                            withRowAnimation:UITableViewRowAnimationFade];
          entityRemoved = YES;
          break;
        }
      }
      if (!entityRemoved) {
        DDLogDebug(@"PELVC/hRE, couldn't find any entities with nil IDs.");
      }
    } else {
      // Is it currently here?
      DDLogDebug(@"PELVC/hRE, check 1/2 passed.");
      NSNumber *idxOfExistingEntity = [self indexOfEntity:removedEntity];
      DDLogDebug(@"PELVC/hRE, idxOfExistingEntity: %@", idxOfExistingEntity);
      if (idxOfExistingEntity) {
        DDLogDebug(@"PELVC/hRE, removedEntity is here.  Proceeding to remove it.");
        [_dataSource removeObjectAtIndex:[idxOfExistingEntity integerValue]];
        [_tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[idxOfExistingEntity integerValue] inSection:0]]
                          withRowAnimation:UITableViewRowAnimationFade];
        entityRemoved = YES;
      } else {
        DDLogDebug(@"PELVC/hRE, removedEntity is not here.");
      }
    }
  } else {
    DDLogDebug(@"PELVC/hRE, removedEntity is of a different class than the entities here.");
  }
  DDLogDebug(@"=== end === in PELVC/handleRemovedEntity: (hRE) =============================");
  return entityRemoved;
}

- (BOOL)handleAddedEntity:(PELMMainSupport *)addedEntity {
  BOOL entityAdded = NO;
  DDLogDebug(@"=== begin === in PELVC/handleAddedEntity: (hAE)");
  if ([addedEntity isKindOfClass:_classOfDataSourceObjects]) {
    DDLogDebug(@"PELVC/hAE, check 1/2 passed.");
    BOOL doesEntityBelong = _doesEntityBelongToThisListView(addedEntity);
    DDLogDebug(@"PELVC/hAE, doesEntityBelong: %d", doesEntityBelong);
    if (doesEntityBelong) {
      void (^insertAtTableIndex)(NSInteger) = ^(NSInteger index) {
        [_tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
      };
      // So it belongs.  But, should we take any action?  I.e., we need to compute
      // its would-be index to see if it should even be visible given the current
      // state of the table view.  But even before that, we should check to see
      // if it's already here!
      NSNumber *indexOfExistingEntity = [self indexOfEntity:addedEntity];
      DDLogDebug(@"PELVC/hUA, idxOfExistingEntity: %@", indexOfExistingEntity);
      if (indexOfExistingEntity) {
        DDLogDebug(@"PELVC/hUA, the entity is already here.  Taking no action then.");
      } else {
        NSInteger wouldBeIndex = _wouldBeIndexOfEntity(addedEntity);
        DDLogDebug(@"PELVC/hAE, wouldBeIndex: %ld", (long)wouldBeIndex);
        DDLogDebug(@"PELVC/hAE, FYI, dataSource count: %lu", (unsigned long)[_dataSource count]);
        if (wouldBeIndex == [_dataSource count]) {
          // Add (i.e., append to the end of the data source).
          [_dataSource addObject:addedEntity];
          insertAtTableIndex(wouldBeIndex);
          DDLogDebug(@"PELVC/hAE, appended entity.");
          entityAdded = YES;
        } else if (wouldBeIndex < [_dataSource count]) {
          // Insert.
          [_dataSource insertObject:addedEntity atIndex:wouldBeIndex];
          insertAtTableIndex(wouldBeIndex);
          DDLogDebug(@"PELVC/hAE, inserted entity.");
          entityAdded = YES;
        } else {
          // wouldBeIndex is larger than [_dataSource count], so we needn't take
          // action.  I.e., it shouldn't be visible yet.
          DDLogDebug(@"PELVC/hAE, no action taken.");
        }
      }
    }
  }
  DDLogDebug(@"=== end === in PELVC/handleAddedEntity: (hAE)");
  return entityAdded;
}

#pragma mark - NSObject

- (void)dealloc {
  _tableView.delegate = nil; // http://stackoverflow.com/a/8381334/1034895
}

#pragma mark - View Controller Lifecycle

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  if ([_tableView indexPathForSelectedRow]) {
    [_tableView deselectRowAtIndexPath:[_tableView indexPathForSelectedRow]
                              animated:YES];
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  UINavigationItem *navItem = [self navigationItem];
  [self setTitle:_title];
  [navItem setTitle:_title];
  [[self view] setBackgroundColor:[UIColor whiteColor]];
  if (_addItemAction) {
    [navItem setRightBarButtonItem:
      [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                             target:self
                             action:@selector(addItem)]];
  }
  _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)
                                            style:UITableViewStylePlain];
  [PEUIUtils setFrameWidthOfView:_tableView ofWidth:1.0 relativeTo:[self view]];
  [PEUIUtils setFrameHeightOfView:_tableView ofHeight:.80 relativeTo:[self view]];
  [_tableView setDataSource:self];
  [_tableView setDelegate:self];
  [PEUIUtils placeView:_tableView
            inMiddleOf:[self view]
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              hpadding:0.0];
  [_tableView registerClass:[UITableViewCell class]
     forCellReuseIdentifier:_cellIdentifier];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  if ([scrollView isAtBottom]) {
    [self addRowsToBottom];
  }
}

#pragma mark - Initial Selected Item

- (NSArray *)truncateInitialSelectedItemFromItems:(NSArray *)items {
  NSMutableArray *mutableItems = [items mutableCopy];
  if (_initialSelectedItem) {
    NSInteger numItems = [items count];
    for (NSInteger i = 0; i < numItems; i++) {
      if ([_initialSelectedItem doesHaveEqualIdentifiers:items[i]]) {
        [mutableItems removeObjectAtIndex:i];
        break;
      }
    }
  }
  return mutableItems;
}

#pragma mark - Adding an item

- (void)addItem {
  PEItemAddedBlk itemAddedBlk = ^(PEAddViewEditController *addViewEditCtrl, id newItem) {    
      [[addViewEditCtrl navigationController] dismissViewControllerAnimated:YES
                                                                 completion:^{}];
  };
  _addItemAction(self, itemAddedBlk);
}

#pragma mark - Loading items to bottom of table (infinite scrolling)

- (void)addRowsToBottom {
  if (_isPaginatedDataSource) {
    NSUInteger dataSourceCount = [_dataSource count];
    id lastItem = [_dataSource lastObject];
    NSArray *nextPage = [self truncateInitialSelectedItemFromItems:_pageLoaderBlk(lastItem)];
    NSUInteger nextPageCount = [nextPage count];
    if (nextPageCount > 0) {
      [_tableView beginUpdates];
      [_dataSource addObjectsFromArray:nextPage];
      NSMutableArray *indexPathsAdded = [NSMutableArray arrayWithCapacity:nextPageCount];
      for (int i = 0; i < nextPageCount; i++) {
        [indexPathsAdded addObject:[NSIndexPath indexPathForRow:(dataSourceCount + i)
                                                      inSection:0]];
      }
      [_tableView insertRowsAtIndexPaths:indexPathsAdded
                        withRowAnimation:UITableViewRowAnimationTop];
      [_tableView endUpdates];
    }
  } else {
    [_dataSource removeAllObjects];
    [_dataSource addObjectsFromArray:_pageLoaderBlk(nil)];
    [_tableView reloadData];
  }
}

#pragma mark - JGActionSheetDelegate and Alert-related Helpers

- (void)actionSheetWillPresent:(JGActionSheet *)actionSheet {}

- (void)actionSheetDidPresent:(JGActionSheet *)actionSheet {}

- (void)actionSheetWillDismiss:(JGActionSheet *)actionSheet {}

- (void)actionSheetDidDismiss:(JGActionSheet *)actionSheet {}

- (JGActionSheetSection *)becameUnauthenticatedSection {
  JGActionSheetSection *becameUnauthSection = nil;
  if (_receivedAuthReqdErrorOnDeleteAttempt) {
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

#pragma mark - Table view delegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return _itemDeleter != nil;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    __block MBProgressHUD *HUD = nil;
    if (_itemDeleter) {
      id item = _dataSource[[indexPath row]];
      void (^postDeleteAttemptActivities)(void) = ^{
        [[[self tabBarController] tabBar] setUserInteractionEnabled:YES];
      };
      if (_isAuthenticatedBlk()) {
        [[[self tabBarController] tabBar] setUserInteractionEnabled:NO];
        void(^immediateDelDone)(NSString *) = ^(NSString *mainMsgTitle) {
          if ([_errorsForDelete count] == 0) { // success
            dispatch_async(dispatch_get_main_queue(), ^{
              [_tableView beginUpdates];
              [_dataSource removeObjectAtIndex:indexPath.row];
              [_tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
              [_tableView endUpdates];
              [HUD setLabelText:_successMessageTitlesForDelete[0]];
              UIImage *image = [UIImage imageNamed:@"hud-complete"];
              UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
              [HUD setCustomView:imageView];
              HUD.mode = MBProgressHUDModeCustomView;
              [HUD hide:YES afterDelay:1.30];
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.35 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                postDeleteAttemptActivities();
              });
            });
          } else { // error
            dispatch_async(dispatch_get_main_queue(), ^{
              [HUD hide:YES afterDelay:0];
              NSMutableAttributedString *attrMessage;
              NSString *title;
              NSString *message;
              NSArray *subErrors = _errorsForDelete[0][2];
              if ([subErrors count] > 1) {
                message = @"\
There were problems deleting your\n\
entity from the server.  The errors are\n\
as follows:";
                title = [NSString stringWithFormat:@"Errors %@.", mainMsgTitle];
              } else {
                message = @"\
There was a problem deleting your\n\
entity from the server.  The error is\n\
as follows:";
                title = [NSString stringWithFormat:@"Error %@.", mainMsgTitle];
              }
              attrMessage = [[NSMutableAttributedString alloc] initWithString:message];
              JGActionSheetSection *becameUnauthSection = [self becameUnauthenticatedSection];
              JGActionSheetSection *contentSection = [PEUIUtils errorAlertSectionWithMsgs:subErrors
                                                                                    title:title
                                                                         alertDescription:attrMessage
                                                                           relativeToView:self.view];
              JGActionSheetSection *buttonsSection;
              void (^buttonsPressedBlock)(JGActionSheet *, NSIndexPath *);
              buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                              message:nil
                                                         buttonTitles:@[@"Okay."]
                                                          buttonStyle:JGActionSheetButtonStyleDefault];
              [buttonsSection setButtonStyle:JGActionSheetButtonStyleRed forButtonAtIndex:0];
              buttonsPressedBlock = ^(JGActionSheet *sheet, NSIndexPath *btnIndexPath) {
                postDeleteAttemptActivities();
                [sheet dismissAnimated:YES];
                [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
              };
              JGActionSheet *alertSheet;
              if (becameUnauthSection) {
                alertSheet = [JGActionSheet actionSheetWithSections:@[contentSection, becameUnauthSection, buttonsSection]];
              } else {
                alertSheet = [JGActionSheet actionSheetWithSections:@[contentSection, buttonsSection]];
              }
              [alertSheet setDelegate:self];
              [alertSheet setInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
              [alertSheet setButtonPressedBlock:buttonsPressedBlock];
              [alertSheet showInView:[self viewForAlerts] animated:YES];
            });
          }
        };
        void(^delNotFoundBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                 NSString *mainMsgTitle,
                                                                 NSString *recordTitle) {
          [_errorsForDelete addObject:@[[NSString stringWithFormat:@"%@ not deleted.", recordTitle],
                                        [NSNumber numberWithBool:NO],
                                        @[[NSString stringWithFormat:@"Not found."]]]];
          immediateDelDone(mainMsgTitle);
        };
        void(^delSuccessBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                NSString *mainMsgTitle,
                                                                NSString *recordTitle) {
          [_successMessageTitlesForDelete addObject:[NSString stringWithFormat:@"%@ deleted.", recordTitle]];
          immediateDelDone(mainMsgTitle);
        };
        void(^delRetryAfterBlk)(float, NSString *, NSString *, NSDate *) = ^(float percentComplete,
                                                                             NSString *mainMsgTitle,
                                                                             NSString *recordTitle,
                                                                             NSDate *retryAfter) {
          [_errorsForDelete addObject:@[[NSString stringWithFormat:@"%@ not deleted.", recordTitle],
                                        [NSNumber numberWithBool:NO],
                                        @[[NSString stringWithFormat:@"Server busy.  Retry after: %@", retryAfter]]]];
          immediateDelDone(mainMsgTitle);
        };
        void (^delServerTempError)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                      NSString *mainMsgTitle,
                                                                      NSString *recordTitle) {
          [_errorsForDelete addObject:@[[NSString stringWithFormat:@"%@ not deleted.", recordTitle],
                                        [NSNumber numberWithBool:NO],
                                        @[@"Temporary server error."]]];
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
          [_errorsForDelete addObject:@[[NSString stringWithFormat:@"%@ not deleted.", recordTitle],
                                        [NSNumber numberWithBool:isErrorUserFixable],
                                        computedErrMsgs]];
          immediateDelDone(mainMsgTitle);
        };
        void(^delConflictBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                 NSString *mainMsgTitle,
                                                                 NSString *recordTitle) {
          [_errorsForDelete addObject:@[[NSString stringWithFormat:@"%@ not deleted.", recordTitle],
                                        [NSNumber numberWithBool:NO],
                                        @[[NSString stringWithFormat:@"Conflict."]]]];
          immediateDelDone(mainMsgTitle);
        };
        void(^delAuthReqdBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                   NSString *mainMsgTitle,
                                                                   NSString *recordTitle) {
          _receivedAuthReqdErrorOnDeleteAttempt = YES;
          [_errorsForDelete addObject:@[[NSString stringWithFormat:@"%@ not deleted.", recordTitle],
                                        [NSNumber numberWithBool:NO],
                                        @[@"Authentication required."]]];
          immediateDelDone(mainMsgTitle);
        };
        void (^delDependencyUnsyncedBlk)(float, NSString *, NSString *, NSString *) = ^(float percentComplete,
                                                                                        NSString *mainMsgTitle,
                                                                                        NSString *recordTitle,
                                                                                        NSString *dependencyErrMsg) {
          [_errorsForDelete addObject:@[[NSString stringWithFormat:@"%@ not deleted.", recordTitle],
                                        [NSNumber numberWithBool:NO],
                                        @[dependencyErrMsg]]];
          immediateDelDone(mainMsgTitle);
        };
        void (^deleteItem)(void) = ^{
          HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
          HUD.delegate = self;
          HUD.labelText = @"Deleting from server...";
          [_errorsForDelete removeAllObjects];
          [_successMessageTitlesForDelete removeAllObjects];
          _receivedAuthReqdErrorOnDeleteAttempt = NO;
          dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            _itemDeleter(self,
                         item,
                         indexPath,
                         delNotFoundBlk,
                         delSuccessBlk,
                         delRetryAfterBlk,
                         delServerTempError,
                         delServerError,
                         delConflictBlk,
                         delAuthReqdBlk,
                         delDependencyUnsyncedBlk);
          });
        };
        if (_itemChildrenCounter) {
          NSInteger numChildren = _itemChildrenCounter(item, indexPath, self);
          if (numChildren > 0) {
            [PEUIUtils showWarningConfirmAlertWithMsgs:_itemChildrenMsgsBlk(item, indexPath, self)
                                                 title:@"Are you sure?"
                                      alertDescription:[[NSAttributedString alloc] initWithString:@"\
Deleting this record will result in the\n\
following child-records being deleted.\n\n\
Are you sure you want to continue?"]
                                       okaybuttonTitle:@"Yes, delete."
                                      okaybuttonAction:^{deleteItem();}
                                     cancelbuttonTitle:@"No, cancel."
                                    cancelbuttonAction:^{
                                      postDeleteAttemptActivities();
                                      [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                                    }
                                        relativeToView:[self viewForAlerts]];
          } else {
            deleteItem();
          }
        } else {
          deleteItem();
        }
      } else {
        [PEUIUtils showWarningAlertWithMsgs:@[]
                                      title:@"Oops"
                           alertDescription:[[NSAttributedString alloc] initWithString:@"You cannot delete anything because you're currently not authenticated."]
                                buttonTitle:@"Okay."
                               buttonAction:nil
                             relativeToView:[self viewForAlerts]];
      }
    }
  }
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (_itemSelectedAction) {
    _itemSelectedAction(_dataSource[[indexPath row]], indexPath, self);
  } else if (_detailViewMaker) {
    [PEUIUtils displayController:_detailViewMaker(self, _dataSource[indexPath.row], indexPath, ^(id dataObject, NSIndexPath *indexRow) {})
                  fromController:self
                        animated:YES];
  } else {
    [_tableView deselectRowAtIndexPath:[_tableView indexPathForSelectedRow]
                              animated:YES];
  }
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return _heightForCells;
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath {
  id dataObject = _dataSource[indexPath.row];
  _tableCellStyler([cell contentView], dataObject);
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
  return [_dataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  id dataObject = _dataSource[indexPath.row];
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:_cellIdentifier
                                                          forIndexPath:indexPath];
  if (_detailViewMaker) {
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
  }
  if (_initialSelectedItem) {
    if ([_initialSelectedItem isEqual:dataObject]) {
      [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
      [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
  }
  return cell;
}

@end
