//
//  PEListViewController.h
//  fuelpurchase
//
//  Created by Evans, Paul on 9/19/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PEAddViewEditController.h"

@class PEListViewController;

typedef NSArray *(^PEPageRefresherBlk)(id);
typedef NSArray *(^PEPageLoaderBlk)(id);
typedef void (^PESyncViewStyler)(UIView *, id);
typedef void (^PEItemSelectedAction)(id, NSIndexPath *, UIViewController *);
typedef void (^PEItemDeleter)(UIViewController *,
                              id,
                              NSIndexPath *,
                              PESyncNotFoundBlk,
                              PESyncImmediateSuccessBlk,
                              PESyncImmediateRetryAfterBlk,
                              PESyncImmediateServerTempErrorBlk,
                              PESyncImmediateServerErrorBlk,
                              PESyncConflictBlk,
                              PESyncImmediateAuthRequiredBlk,
                              PESyncImmediateDependencyUnsynced);
typedef NSInteger (^PEItemChildrenCounter)(id, NSIndexPath *, UIViewController *);
typedef NSArray * (^PEItemChildrenMsgsBlk)(id, NSIndexPath *, UIViewController *);
typedef UIViewController *(^FPDetailViewMaker)(PEListViewController *, id, NSIndexPath *, PEItemChangedBlk);
typedef BOOL (^PEDoesEntityBelongToListView)(PELMMainSupport *);
typedef NSInteger (^PEWouldBeIndexOfEntity)(PELMMainSupport *);

@interface PEListViewController : UIViewController <UITableViewDataSource,
UITableViewDelegate, MBProgressHUDDelegate>

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
                       isAuthenticated:(PEIsAuthenticatedBlk)isAuthenticated
                        isUserLoggedIn:(PEIsLoggedInBlk)isUserLoggedIn
                   itemChildrenCounter:(PEItemChildrenCounter)itemChildrenCounter
                   itemChildrenMsgsBlk:(PEItemChildrenMsgsBlk)itemChildrenMsgsBlk
                           itemDeleter:(PEItemDeleter)itemDeleter;

#pragma mark - Entity changed methods

- (BOOL)handleUpdatedEntity:(PELMMainSupport *)updatedEntity;

- (BOOL)handleRemovedEntity:(PELMMainSupport *)removedEntity;

- (BOOL)handleAddedEntity:(PELMMainSupport *)addedEntity;

@end
