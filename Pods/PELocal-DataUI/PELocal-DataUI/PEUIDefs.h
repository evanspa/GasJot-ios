//
//  PEUIDefs.h
//  PELocal-DataUI
//
//  Created by Paul Evans on 12/22/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

@class PEListViewController;
@class PEAddViewEditController;
@class JGActionSheetSection;
@class PELMMainSupport;

typedef NSArray *(^PEPageRefresherBlk)(id);
typedef NSArray *(^PEPageLoaderBlk)(id);
typedef void (^PETableCellContentViewStyler)(UITableViewCell *, UIView *, id);
typedef void (^PEItemSelectedAction)(id, NSIndexPath *, UIViewController *);
typedef void (^PEItemChangedBlk)(id, NSIndexPath *);
typedef UIViewController *(^PEDetailViewMaker)(PEListViewController *, id, NSIndexPath *, PEItemChangedBlk);
typedef BOOL (^PEDoesEntityBelongToListView)(PELMMainSupport *);
typedef NSInteger (^PEWouldBeIndexOfEntity)(id);

typedef NSDictionary *(^PEComponentsMakerBlk)(UIViewController *);
typedef UIView *(^PEEntityPanelMakerBlk)(PEAddViewEditController *);
typedef UIView *(^PEEntityViewPanelMakerBlk)(PEAddViewEditController *, id, id);
typedef void (^PEPanelToEntityBinderBlk)(UIView *, id);
typedef void (^PEEntityToPanelBinderBlk)(id, UIView *);
typedef void (^PEEnableDisablePanelBlk)(UIView *, BOOL);
typedef BOOL (^PEEntityEditPreparerBlk)(PEAddViewEditController *, id);
typedef void (^PEEntityEditCancelerBlk)(PEAddViewEditController *, id);
typedef void (^PEEntityAddCancelerBlk)(PEAddViewEditController *, BOOL, id);
typedef NSArray *(^PEEntitiesFromEntityBlk)(id);
typedef id   (^PEEntityMakerBlk)(UIView *);
typedef void (^PESaveEntityBlk)(PEAddViewEditController *, id);
typedef void (^PESyncNotFoundBlk)(float, NSString *, NSString *);
typedef void (^PESyncConflictBlk)(float, NSString *, NSString *, id);
typedef void (^PESyncSuccessBlk)(float, NSString *, NSString *);
typedef void (^PEDownloadSuccessBlk)(float, NSString *, NSString *, id);
typedef void (^PESyncServerTempErrorBlk)(float, NSString *, NSString *);
typedef void (^PESyncServerErrorBlk)(float, NSString *, NSString *, NSArray *);
typedef void (^PESyncAuthRequiredBlk)(float, NSString *, NSString *);
typedef void (^PESyncRetryAfterBlk)(float, NSString *, NSString *, NSDate *);
typedef void (^PESyncDependencyUnsynced)(float, NSString *, NSString *, NSString *);
typedef void (^PEEntitySyncCancelerBlk)(PELMMainSupport *, NSError *, NSNumber *);
typedef BOOL (^PEIsAuthenticatedBlk)(void);
typedef BOOL (^PEIsLoggedInBlk)(void);
typedef BOOL (^PEIsOfflineModeBlk)(void);
typedef NSInteger (^PENumRemoteDepsNotLocal)(id);
typedef void (^PEUpdateDepsPanel)(PEAddViewEditController *, id);
typedef NSDictionary * (^PEMergeBlk)(PEAddViewEditController *, id, id);
typedef NSArray * (^PEConflictResolveFields)(PEAddViewEditController *, NSDictionary *, id, id);
typedef id (^PEConflictResolvedEntity)(PEAddViewEditController *, NSDictionary *, NSArray *, id, id);
typedef void (^PEPostDownloaderSaver)(PEAddViewEditController *, id, id);
typedef NSInteger (^PEItemChildrenCounter)(id);
typedef NSArray * (^PEItemChildrenMsgsBlk)(id);
typedef void (^PEDependencyFetcherBlk)(PEAddViewEditController *,
                                       id,
                                       PESyncNotFoundBlk,
                                       PESyncSuccessBlk,
                                       PESyncRetryAfterBlk,
                                       PESyncServerTempErrorBlk,
                                       PESyncAuthRequiredBlk);
typedef void (^PEDownloaderBlk)(PEAddViewEditController *,
                                id,
                                PESyncNotFoundBlk,
                                PEDownloadSuccessBlk,
                                PESyncRetryAfterBlk,
                                PESyncServerTempErrorBlk,
                                PESyncAuthRequiredBlk);
typedef void (^PEMarkAsDoneEditingLocalBlk)(PEAddViewEditController *, id);
typedef void (^PEMarkAsDoneEditingImmediateSyncBlk)(PEAddViewEditController *,
                                                    id,
                                                    PESyncNotFoundBlk,
                                                    PESyncSuccessBlk,
                                                    PESyncRetryAfterBlk,
                                                    PESyncServerTempErrorBlk,
                                                    PESyncServerErrorBlk,
                                                    PESyncConflictBlk,
                                                    PESyncAuthRequiredBlk,
                                                    PESyncDependencyUnsynced);
typedef void (^PEUploaderBlk)(PEAddViewEditController *,
                              id,
                              PESyncNotFoundBlk,
                              PESyncSuccessBlk,
                              PESyncRetryAfterBlk,
                              PESyncServerTempErrorBlk,
                              PESyncServerErrorBlk,
                              PESyncConflictBlk,
                              PESyncAuthRequiredBlk,
                              PESyncDependencyUnsynced);
typedef NSArray * (^PESaveNewEntityLocalBlk)(UIView *, id);
typedef void (^PESaveNewEntityImmediateSyncBlk)(UIView *,
                                                id,
                                                PESyncNotFoundBlk,
                                                PESyncSuccessBlk,
                                                PESyncRetryAfterBlk,
                                                PESyncServerTempErrorBlk,
                                                PESyncServerErrorBlk,
                                                PESyncConflictBlk,
                                                PESyncAuthRequiredBlk,
                                                PESyncDependencyUnsynced);
typedef void (^PEItemDeleter)(UIViewController *,
                              id,
                              NSIndexPath *,
                              PESyncNotFoundBlk,
                              PESyncSuccessBlk,
                              PESyncRetryAfterBlk,
                              PESyncServerTempErrorBlk,
                              PESyncServerErrorBlk,
                              PESyncConflictBlk,
                              PESyncAuthRequiredBlk);
typedef void (^PEItemLocalDeleter)(UIViewController *, id, NSIndexPath *);
typedef void (^PEItemAddedBlk)(PEAddViewEditController *, id);
typedef void (^PEPrepareUIForUserInteractionBlk)(PEAddViewEditController *, UIView *);
typedef void (^PEViewDidAppearBlk)(id);
typedef NSArray *(^PEEntityValidatorBlk)(UIView *);
typedef NSArray *(^PEMessagesFromErrMask)(NSInteger);
typedef void (^PEModalOperationStarted)(void);
typedef void (^PEModalOperationDone)(void);
typedef JGActionSheetSection *(^PEAddlContentSection)(PEAddViewEditController *, UIView *, id);
