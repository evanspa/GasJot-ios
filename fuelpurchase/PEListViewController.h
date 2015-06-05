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
typedef void (^PEStyleTableCellContentView)(UIView *, id);
typedef void (^PEItemSelectedAction)(id, NSIndexPath *, UIViewController *);
typedef UIViewController *(^FPDetailViewMaker)(PEListViewController *, id, NSIndexPath *, PEItemChangedBlk);
typedef BOOL (^PEDoesEntityBelongToListView)(PELMMainSupport *);
typedef NSInteger (^PEWouldBeIndexOfEntity)(PELMMainSupport *);

@interface PEListViewController : UIViewController <UITableViewDataSource,
UITableViewDelegate>

#pragma mark - Initializers

- (id)initWithClassOfDataSourceObjects:(Class)classOfDataSourceObjects
                                 title:(NSString *)title
                 isPaginatedDataSource:(BOOL)isPaginatedDataSource
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
                  wouldBeIndexOfEntity:(PEWouldBeIndexOfEntity)wouldBeIndexOfEntity;

@end
