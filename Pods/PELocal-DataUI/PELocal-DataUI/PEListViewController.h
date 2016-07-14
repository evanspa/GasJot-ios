//
//  PEListViewController.h
//  PELocal-DataUI
//
//  Created by Evans, Paul on 9/19/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PEUIDefs.h"
#import "PEAddViewEditController.h"

@class PEListViewController;

@interface PEListViewController : UIViewController <UITableViewDataSource,
UITableViewDelegate, MBProgressHUDDelegate>

#pragma mark - Initializers

- (id)initWithClassOfDataSourceObjects:(Class)classOfDataSourceObjects
                                 title:(NSString *)title
                 isPaginatedDataSource:(BOOL)isPaginatedDataSource
                       tableCellStyler:(PETableCellContentViewStyler)tableCellStyler
                    itemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                   initialSelectedItem:(id)initialSelectedItem
                         addItemAction:(void(^)(PEListViewController *, PEItemAddedBlk))addItemActionBlk 
                        cellIdentifier:(NSString *)cellIdentifier
                        initialObjects:(NSArray *)initialObjects
                            pageLoader:(PEPageLoaderBlk)pageLoaderBlk
                     heightForCellsBlk:(CGFloat(^)(void))heightForCellsBlk
                       detailViewMaker:(PEDetailViewMaker)detailViewMaker
                             uitoolkit:(PEUIToolkit *)uitoolkit
        doesEntityBelongToThisListView:(PEDoesEntityBelongToListView)doesEntityBelongToThisListView
                  wouldBeIndexOfEntity:(PEWouldBeIndexOfEntity)wouldBeIndexOfEntity
                       isAuthenticated:(PEIsAuthenticatedBlk)isAuthenticated
                        isUserLoggedIn:(PEIsLoggedInBlk)isUserLoggedIn
                   itemChildrenCounter:(PEItemChildrenCounter)itemChildrenCounter
                   itemChildrenMsgsBlk:(PEItemChildrenMsgsBlk)itemChildrenMsgsBlk
                           itemDeleter:(PEItemDeleter)itemDeleter
                      itemLocalDeleter:(PEItemLocalDeleter)itemLocalDeleter
                          isEntityType:(BOOL)isEntityType
                      viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
           entityAddedNotificationName:(NSString *)entityAddedNotificationName
         entityUpdatedNotificationName:(NSString *)entityUpdatedNotificationName
         entityRemovedNotificationName:(NSString *)entityRemovedNotificationName;

#pragma mark - Properties

@property (nonatomic, readonly) NSMutableArray *dataSource;

@property (nonatomic) UITableView *tableView;

#pragma mark - Entity changed methods

- (BOOL)handleUpdatedEntity:(PELMMainSupport *)updatedEntity;

- (BOOL)handleRemovedEntity:(PELMMainSupport *)removedEntity;

- (BOOL)handleAddedEntity:(PELMMainSupport *)addedEntity;

@end
