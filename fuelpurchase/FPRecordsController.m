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
#import <PEFuelPurchase-Model/FPLocalDao.h>

@implementation FPRecordsController {
  id<FPCoordinatorDao> _coordDao;
  PEUIToolkit *_uitoolkit;
  FPUser *_user;
  FPScreenToolkit *_screenToolkit;
  UIButton *_unsyncedEditsBtn;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<FPCoordinatorDao>)coordDao
                          user:(FPUser *)user
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(FPScreenToolkit *)screenToolkit {
  self = [super initWithRequireRepaintNotifications:nil];
  if (self) {
    _user = user;
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
  }
  return self;
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:self.view fixedHeight:0.0];
  CGFloat leftPadding = 8.0;
  UIView *msgPanel =  [PEUIUtils leftPadView:[PEUIUtils labelWithKey:@"From here you can drill into all of your data records."
                                                         font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                              backgroundColor:[UIColor clearColor]
                                                    textColor:[UIColor darkGrayColor]
                                          verticalTextPadding:3.0
                                                   fitToWidth:self.view.frame.size.width - (leftPadding + 3.0)]
                              padding:leftPadding];
  UIButton *vehiclesBtn = [PEUIUtils buttonWithLabel:@"Vehicles"
                                        tagForButton:nil
                                         recordCount:[_coordDao numVehiclesForUser:_user error:[FPUtils localFetchErrorHandlerMaker]()]
                              tagForRecordCountLabel:nil
                                   addDisclosureIcon:YES
                           addlVerticalButtonPadding:10.0
                        recordCountFromBottomPadding:2.0
                              recordCountLeftPadding:6.0
                                             handler:^{
                                               [PEUIUtils displayController:[_screenToolkit newViewVehiclesScreenMaker](_user)
                                                             fromController:self
                                                                   animated:YES];
                                             }
                                           uitoolkit:_uitoolkit
                                      relativeToView:self.view];
  UIButton *fuelstationsBtn = [PEUIUtils buttonWithLabel:@"Gas stations"
                                   tagForButton:nil
                                    recordCount:[_coordDao numFuelStationsForUser:_user error:[FPUtils localFetchErrorHandlerMaker]()]
                         tagForRecordCountLabel:nil
                              addDisclosureIcon:YES
                               addlVerticalButtonPadding:10.0
                            recordCountFromBottomPadding:2.0
                                  recordCountLeftPadding:6.0
                                        handler:^{
                                          [PEUIUtils displayController:[_screenToolkit newViewFuelStationsScreenMaker](_user)
                                                        fromController:self
                                                              animated:YES];
                                        }
                                      uitoolkit:_uitoolkit
                                 relativeToView:self.view];
  UIButton *fplogsBtn = [PEUIUtils buttonWithLabel:@"Gas logs"
                             tagForButton:nil
                              recordCount:[_coordDao numFuelPurchaseLogsForUser:_user error:[FPUtils localFetchErrorHandlerMaker]()]
                   tagForRecordCountLabel:nil
                        addDisclosureIcon:YES
                         addlVerticalButtonPadding:10.0
                      recordCountFromBottomPadding:2.0
                            recordCountLeftPadding:6.0
                                  handler:^{
                                    [PEUIUtils displayController:[_screenToolkit newViewFuelPurchaseLogsScreenMaker](_user)
                                                  fromController:self
                                                        animated:YES];
                                  }
                                uitoolkit:_uitoolkit
                           relativeToView:self.view];
  UIButton *envlogsBtn = [PEUIUtils buttonWithLabel:@"Odometer logs"
                              tagForButton:nil
                               recordCount:[_coordDao numEnvironmentLogsForUser:_user error:[FPUtils localFetchErrorHandlerMaker]()]
                    tagForRecordCountLabel:nil
                         addDisclosureIcon:YES
                          addlVerticalButtonPadding:10.0
                       recordCountFromBottomPadding:2.0
                             recordCountLeftPadding:6.0
                                   handler:^{
                                     [PEUIUtils displayController:[_screenToolkit newViewEnvironmentLogsScreenMaker](_user)
                                                   fromController:self
                                                         animated:YES];
                                   }
                                 uitoolkit:_uitoolkit
                            relativeToView:self.view];
  [PEUIUtils placeView:msgPanel
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:FPContentPanelTopPadding
              hpadding:0.0];
  CGFloat totalHeight = msgPanel.frame.size.height + FPContentPanelTopPadding;
  [PEUIUtils placeView:vehiclesBtn
                 below:msgPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:10.0
              hpadding:0.0];
  totalHeight += vehiclesBtn.frame.size.height + 10.0;
  [PEUIUtils placeView:fuelstationsBtn
                 below:vehiclesBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:10.0
              hpadding:0.0];
  totalHeight += fuelstationsBtn.frame.size.height + 10.0;
  [PEUIUtils placeView:fplogsBtn
                 below:fuelstationsBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:10.0
              hpadding:0.0];
  totalHeight += fplogsBtn.frame.size.height + 10.0;
  [PEUIUtils placeView:envlogsBtn
                 below:fplogsBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:10.0
              hpadding:0.0];
  totalHeight += envlogsBtn.frame.size.height + 10.0;
  
  [_unsyncedEditsBtn removeFromSuperview];
  if ([APP isUserLoggedIn]) {
    NSInteger numUnsynced = [_coordDao totalNumUnsyncedEntitiesForUser:_user];
    if (numUnsynced > 0) {
      _unsyncedEditsBtn = [self unsyncedEditsButtonWithBadgeNum:numUnsynced];
      [PEUIUtils placeView:_unsyncedEditsBtn below:envlogsBtn onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:25.0 hpadding:0.0];
      totalHeight += _unsyncedEditsBtn.frame.size.height + 25.0;
    }
  }
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(NO)];
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  UINavigationItem *navItem = [self navigationItem];
  [navItem setTitle:@"Data Records"];
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
