//
//  PEListViewController.m
//  fuelpurchase
//
//  Created by Evans, Paul on 9/19/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "PEListViewController.h"
#import <objc-commons/PEUIUtils.h>
#import <objc-commons/PEUtils.h>
//#import <SVPullToRefresh/SVPullToRefresh.h>
#import <iFuelPurchase-Core/PELMNotificationUtils.h>
#import "NSMutableArray+MoveObject.h"
#import "UIScrollView+PEAdditions.h"

@implementation PEListViewController {
  Class _classOfDataSourceObjects;
  NSString *_title;
  UITableView *_tableView;
  PEStyleTableCellContentView _tableCellStyler;
  PEItemSelectedAction _itemSelectedAction;
  id _initialSelectedItem;
  void (^_addItemAction)(PEListViewController *, PEItemAddedBlk);
  NSString *_cellIdentifier;
  NSMutableArray *_dataSource;
  PEPageLoaderBlk _pageLoaderBlk;
  CGFloat _heightForCells;
  FPDetailViewMaker _detailViewMaker;
  PEUIToolkit *_uitoolkit;
  NSArray *_entityAddedNotifNames;
  NSArray *_entityUpdatedNotifNames;
  NSArray *_entityRemovedNotifNames;
  NSIndexPath *_indexPathOfRemovedEntity;
  PEDoesEntityBelongToListView _doesEntityBelongToThisListView;
  PEWouldBeIndexOfEntity _wouldBeIndexOfEntity;
}

#pragma mark - Initializers

- (id)initWithClassOfDataSourceObjects:(Class)classOfDataSourceObjects
                                 title:(NSString *)title
                       tableCellStyler:(PEStyleTableCellContentView)tableCellStyler
                    itemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                   initialSelectedItem:(id)initialSelectedItem
                         addItemAction:(void(^)(PEListViewController *, PEItemAddedBlk))addItemActionBlk
                        cellIdentifier:(NSString *)cellIdentifier
                        initialObjects:(NSArray *)initialObjects
                            pageLoader:(PEPageLoaderBlk)pageLoaderBlk
                        heightForCells:(CGFloat)heightForCells
                       detailViewMaker:(FPDetailViewMaker)detailViewMaker
                             uitoolkit:(PEUIToolkit *)uitoolkit
                 entityAddedNotifNames:(NSArray *)entityAddedNotifNames
               entityUpdatedNotifNames:(NSArray *)entityUpdatedNotifNames
               entityRemovedNotifNames:(NSArray *)entityRemovedNotifNames
        doesEntityBelongToThisListView:(PEDoesEntityBelongToListView)doesEntityBelongToThisListView
                  wouldBeIndexOfEntity:(PEWouldBeIndexOfEntity)wouldBeIndexOfEntity {
  NSAssert(!(detailViewMaker && initialSelectedItem), @"detailViewMaker and initialSelectedItem cannot BOTH be provided");
  NSAssert(!(detailViewMaker && itemSelectedAction), @"detailViewMaker and itemSelectedAction cannot BOTH be provided");
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _classOfDataSourceObjects = classOfDataSourceObjects;
    _title = title;
    _tableCellStyler = tableCellStyler;
    _itemSelectedAction = itemSelectedAction;
    _initialSelectedItem = initialSelectedItem;
    _addItemAction = addItemActionBlk;
    _cellIdentifier = cellIdentifier;
    _pageLoaderBlk = pageLoaderBlk;
    _heightForCells = heightForCells;
    _detailViewMaker = detailViewMaker;
    _uitoolkit = uitoolkit;
    _entityAddedNotifNames = entityAddedNotifNames;
    _entityUpdatedNotifNames = entityUpdatedNotifNames;
    _entityRemovedNotifNames = entityRemovedNotifNames;
    _dataSource = [NSMutableArray array];
    _indexPathOfRemovedEntity = nil;
    _doesEntityBelongToThisListView = doesEntityBelongToThisListView;
    _wouldBeIndexOfEntity = wouldBeIndexOfEntity;
    if (_initialSelectedItem) {
      [_dataSource addObject:_initialSelectedItem]; // initial selected is always at top
    }
    [_dataSource addObjectsFromArray:[self truncateInitialSelectedItemFromItems:initialObjects]];
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

#pragma mark - Notification Observing

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
          deleteAtTableIndex(indexOfExistingEntityAsInt);
          insertAtTableIndex(wouldBeIndex);
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
  if ([removedEntity isKindOfClass:_classOfDataSourceObjects]) {
    // Is it currently here?
    NSNumber *indexOfEntity = [self indexOfEntity:removedEntity];
    if (indexOfEntity) {
      [_dataSource removeObjectAtIndex:[indexOfEntity integerValue]];
      [_tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[indexOfEntity integerValue] inSection:0]]
                        withRowAnimation:UITableViewRowAnimationFade];
      return YES;
    }
  }
  return NO;
}

- (BOOL)handleAddedEntity:(PELMMainSupport *)addedEntity {
  BOOL entityAdded = NO;
  DDLogDebug(@"begin in PELVC/handleAddedEntity: (hAE)");
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
      // state of the table view.
      NSInteger wouldBeIndex = _wouldBeIndexOfEntity(addedEntity);
      DDLogDebug(@"PELVC/hAE, wouldBeIndex: %ld", (long)wouldBeIndex);
      DDLogDebug(@"PELVC/hAE, FYI, dataSource count: %lu", (unsigned long)[_dataSource count]);
      if (wouldBeIndex == [_dataSource count]) {
        // Add (i.e., append to the end of the data source).
        [_dataSource addObject:addedEntity];
        insertAtTableIndex(wouldBeIndex);
        DDLogDebug(@"PELVC/hAE, appended entity.");
      } else if (wouldBeIndex < [_dataSource count]) {
        // Insert.
        [_dataSource insertObject:addedEntity atIndex:wouldBeIndex];
        insertAtTableIndex(wouldBeIndex);
        DDLogDebug(@"PELVC/hAE, inserted entity.");
      } else {
        // wouldBeIndex is larger than [_dataSource count], so we needn't take
        // action.  I.e., it shouldn't be visible yet.
        DDLogDebug(@"PELVC/hAE, no action taken.");
      }
    }
  }
  return entityAdded;
}

- (void)handleEntitiesNotification:(NSNotification *)notification
                     entityHandler:(BOOL(^)(PELMMainSupport *))entityHandler
                  tempNotifPostfix:(NSString *)tempNotifPostfix {
  @synchronized(self) {
    NSArray *entities = [PELMNotificationUtils entitiesFromNotification:notification];
    [_tableView beginUpdates];
    NSInteger numHandled = 0;
    for (PELMMainSupport *entity in entities) {
      if (entityHandler(entity)) {
        numHandled++;
      }
    }
    [_tableView endUpdates];
    if (numHandled > 0) {
      [PEUIUtils displayTempNotification:[NSString stringWithFormat:@"%ld record(s) %@.", (long)numHandled, tempNotifPostfix]
                           forController:self
                               uitoolkit:_uitoolkit];
    }
  }
}

- (void)entitiesUpdated:(NSNotification *)notification {
  [self handleEntitiesNotification:notification
                     entityHandler:^BOOL(PELMMainSupport *entity){return [self handleUpdatedEntity:entity];}
                  tempNotifPostfix:@"updated"];
}

- (void)entitiesRemoved:(NSNotification *)notification {
  [self handleEntitiesNotification:notification
                     entityHandler:^BOOL(PELMMainSupport *entity){return [self handleRemovedEntity:entity];}
                  tempNotifPostfix:@"removed"];
}

- (void)entitiesAdded:(NSNotification *)notification {
  [self handleEntitiesNotification:notification
                     entityHandler:^BOOL(PELMMainSupport *entity){return [self handleAddedEntity:entity];}
                  tempNotifPostfix:@"added"];
}

#pragma mark - NSObject

- (void)dealloc {
  _tableView.delegate = nil; // http://stackoverflow.com/a/8381334/1034895
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View Controller Lifecycle

- (void)viewWillDisappear:(BOOL)animated {
  if ([self isMovingFromParentViewController]) {
    DDLogDebug(@"Removing PELVC as a notification observer.");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
  }
  [super viewWillDisappear:animated];
}

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
  
  // Set the background color
  [[self view] setBackgroundColor:[UIColor whiteColor]];

  /* Add 'add' action */
  if (_addItemAction) {
    [navItem setRightBarButtonItem:
      [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                             target:self
                             action:@selector(addItem)]];
  }
  
  /* Setup Notification observing */
  void (^observeNotifNames)(NSArray *, SEL) = ^(NSArray *notifNames, SEL selector) {
    for (NSString *notifName in notifNames) {
      [PEUtils observeIfNotNilNotificationName:notifName
                                      observer:self
                                      selector:selector];
    }
  };
  observeNotifNames(_entityAddedNotifNames, @selector(entitiesAdded:));
  observeNotifNames(_entityUpdatedNotifNames, @selector(entitiesUpdated:));
  observeNotifNames(_entityRemovedNotifNames, @selector(entitiesRemoved:));
  
  /* Add the table view */
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
  
  // setup infinite scrolling
  //__weak PEListViewController *weakSelf = self;
  //[_tableView addInfiniteScrollingWithActionHandler:^{
  //  [weakSelf addRowsToBottom];
  //}];
  
  [_tableView registerClass:[UITableViewCell class]
     forCellReuseIdentifier:_cellIdentifier];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  //if ([scrollView isAtTop]) {
    //NSLog(@"we are at the top");
  //} else
  if ([scrollView isAtBottom]) {
    //NSLog(@"we are at the bottom");
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
      [[addViewEditCtrl navigationController] dismissViewControllerAnimated:YES completion:^{
      /*[_tableView beginUpdates];
      [_dataSource insertObject:newItem atIndex:0];
      [_tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                        withRowAnimation:UITableViewRowAnimationAutomatic];
      [_tableView endUpdates];*/
    }];
  };
  _addItemAction(self, itemAddedBlk);
}

#pragma mark - Loading items to bottom of table (infinite scrolling)

- (void)addRowsToBottom {
  //@synchronized(self) {
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
    //[_tableView.infiniteScrollingView stopAnimating];
  //}
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (_itemSelectedAction) {
    _itemSelectedAction(_dataSource[[indexPath row]], indexPath, self);
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
accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
  PEItemChangedBlk itemChangedBlk = ^(id dataObject, NSIndexPath *indexRow) {
    /*NSIndexPath *indexPathOfRemovedEntity = [self indexPathOfRemovedEntity];
    if (!(indexPathOfRemovedEntity && [indexPathOfRemovedEntity isEqual:indexPath])) {
      [_dataSource replaceObjectAtIndex:[indexPath row] withObject:dataObject];
      [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:YES];
    }*/
  };
  [PEUIUtils displayController:_detailViewMaker(self, _dataSource[indexPath.row], indexPath, itemChangedBlk)
                fromController:self
                      animated:YES];
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
    [cell setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
  }
  if (_initialSelectedItem) {
    if ([_initialSelectedItem isEqual:dataObject]) {
      [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
      [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
  }
  _tableCellStyler([cell contentView], dataObject);
  return cell;
}

@end
