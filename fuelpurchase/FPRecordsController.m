//
//  FPRecordsController.m
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 9/13/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import "FPRecordsController.h"
#import <PEObjc-Commons/PEUIUtils.h>
#import <BlocksKit/UIControl+BlocksKit.h>
#import <BlocksKit/UIView+BlocksKit.h>
#import "FPUIUtils.h"
#import "FPUtils.h"
#import "UIColor+FPAdditions.h"

@implementation FPRecordsController {
  FPCoordinatorDao *_coordDao;
  PEUIToolkit *_uitoolkit;
  FPUser *_user;
  FPScreenToolkit *_screenToolkit;
  UIView *_msgPanel;
  UIButton *_vehiclesBtn;
  UIButton *_fuelstationsBtn;
  UIButton *_fplogsBtn;
  UIButton *_envlogsBtn;
  UIButton *_unsyncedEditsBtn;
  UIScrollView *_scrollView;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(FPCoordinatorDao *)coordDao
                          user:(FPUser *)user
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(FPScreenToolkit *)screenToolkit {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _user = user;
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
  }
  return self;
}

#pragma mark - Dynamic Type Support

- (void)changeTextSize:(NSNotification *)notification {
  [self viewDidAppear:YES];
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeTextSize:)
                                               name:UIContentSizeCategoryDidChangeNotification
                                             object:nil];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  UINavigationItem *navItem = [self navigationItem];
  [navItem setTitle:@"Data Records"];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [_vehiclesBtn removeFromSuperview];
  [_fuelstationsBtn removeFromSuperview];
  [_fplogsBtn removeFromSuperview];
  [_envlogsBtn removeFromSuperview];
  [_scrollView removeFromSuperview];
  
  CGFloat leftPadding = 8.0;
  _msgPanel =  [PEUIUtils leftPadView:[PEUIUtils labelWithKey:@"From here you can drill into all of your data records."
                                                         font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                              backgroundColor:[UIColor clearColor]
                                                    textColor:[UIColor darkGrayColor]
                                          verticalTextPadding:3.0
                                                   fitToWidth:self.view.frame.size.width - (leftPadding + 3.0)]
                              padding:leftPadding];
  _vehiclesBtn = [PEUIUtils buttonWithLabel:@"Vehicles"
                               tagForButton:nil
                                recordCount:[_coordDao numVehiclesForUser:_user error:[FPUtils localFetchErrorHandlerMaker]()]
                     tagForRecordCountLabel:nil
                          addDisclosureIcon:YES
                                    handler:^{
                                      [PEUIUtils displayController:[_screenToolkit newViewVehiclesScreenMaker](_user)
                                                    fromController:self
                                                          animated:YES];
                                    }
                                  uitoolkit:_uitoolkit
                             relativeToView:self.view];
  _fuelstationsBtn = [PEUIUtils buttonWithLabel:@"Gas stations"
                                   tagForButton:nil
                                    recordCount:[_coordDao numFuelStationsForUser:_user error:[FPUtils localFetchErrorHandlerMaker]()]
                         tagForRecordCountLabel:nil
                              addDisclosureIcon:YES
                                        handler:^{
                                          [PEUIUtils displayController:[_screenToolkit newViewFuelStationsScreenMaker](_user)
                                                        fromController:self
                                                              animated:YES];
                                        }
                                      uitoolkit:_uitoolkit
                                 relativeToView:self.view];
  _fplogsBtn = [PEUIUtils buttonWithLabel:@"Gas logs"
                             tagForButton:nil
                              recordCount:[_coordDao numFuelPurchaseLogsForUser:_user error:[FPUtils localFetchErrorHandlerMaker]()]
                   tagForRecordCountLabel:nil
                        addDisclosureIcon:YES
                                  handler:^{
                                    [PEUIUtils displayController:[_screenToolkit newViewFuelPurchaseLogsScreenMaker](_user)
                                                  fromController:self
                                                        animated:YES];
                                  }
                                uitoolkit:_uitoolkit
                           relativeToView:self.view];
  _envlogsBtn = [PEUIUtils buttonWithLabel:@"Odometer logs"
                              tagForButton:nil
                               recordCount:[_coordDao numEnvironmentLogsForUser:_user error:[FPUtils localFetchErrorHandlerMaker]()]
                    tagForRecordCountLabel:nil
                         addDisclosureIcon:YES
                                   handler:^{
                                    [PEUIUtils displayController:[_screenToolkit newViewEnvironmentLogsScreenMaker](_user)
                                                  fromController:self
                                                        animated:YES];
                                  }
                                 uitoolkit:_uitoolkit
                            relativeToView:self.view];
  _scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
  [PEUIUtils placeView:_msgPanel
               atTopOf:_scrollView
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:75.0
              hpadding:0.0];
  CGFloat totalHeight = _msgPanel.frame.size.height + 75.0;
  [PEUIUtils placeView:_vehiclesBtn
                 below:_msgPanel
                  onto:_scrollView //self.view
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:10.0
              hpadding:0.0];
  totalHeight += _vehiclesBtn.frame.size.height + 10.0;
  [PEUIUtils placeView:_fuelstationsBtn
                 below:_vehiclesBtn
                  onto:_scrollView //self.view
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:10.0
              hpadding:0.0];
  totalHeight += _fuelstationsBtn.frame.size.height + 10.0;
  [PEUIUtils placeView:_fplogsBtn
                 below:_fuelstationsBtn
                  onto:_scrollView //self.view
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:10.0
              hpadding:0.0];
  totalHeight += _fplogsBtn.frame.size.height + 10.0;
  [PEUIUtils placeView:_envlogsBtn
                 below:_fplogsBtn
                  onto:_scrollView //self.view
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:10.0
              hpadding:0.0];
  totalHeight += _envlogsBtn.frame.size.height + 10.0;
  
  [_unsyncedEditsBtn removeFromSuperview];
  if ([APP isUserLoggedIn]) {
    NSInteger numUnsynced = [_coordDao totalNumUnsyncedEntitiesForUser:_user];
    if (numUnsynced > 0) {
      _unsyncedEditsBtn = [self unsyncedEditsButtonWithBadgeNum:numUnsynced];
      [PEUIUtils placeView:_unsyncedEditsBtn below:_envlogsBtn onto:_scrollView withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:25.0 hpadding:0.0];
      totalHeight += _unsyncedEditsBtn.frame.size.height + 25.0;
    }
  }
  [PEUIUtils setFrameHeight:totalHeight ofView:_scrollView];
  [_scrollView setDelaysContentTouches:NO];
  [_scrollView setContentSize:CGSizeMake(self.view.frame.size.width, 1.6 * _scrollView.frame.size.height)];
  [_scrollView setBounces:YES];
  [PEUIUtils placeView:_scrollView atTopOf:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
}

#pragma mark - Helpers

- (UIButton *)unsyncedEditsButtonWithBadgeNum:(NSInteger)numUnsynced {
  return [PEUIUtils buttonWithLabel:@"Unsynced Edits"
                           badgeNum:numUnsynced
                         badgeColor:[UIColor redColor]
                     badgeTextColor:[UIColor whiteColor]
                  addDisclosureIcon:YES
                            handler:^{
                              [PEUIUtils displayController:[_screenToolkit newViewUnsyncedEditsScreenMaker](_user)
                                            fromController:self
                                                  animated:YES];
                            }
                          uitoolkit:_uitoolkit
                     relativeToView:self.view];
}

@end
