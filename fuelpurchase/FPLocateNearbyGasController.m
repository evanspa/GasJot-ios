//
//  FPLocateNearbyGasController.m
//  Gas Jot
//
//  Created by Paul Evans on 12/31/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "FPLocateNearbyGasController.h"
#import <PEObjc-Commons/PEUIUtils.h>
#import <PEObjc-Commons/PEUtils.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <PEFuelPurchase-Model/FPPriceEvent.h>
#import <PEFuelPurchase-Model/FPFuelStationType.h>
#import <PEFuelPurchase-Model/FPCoordinatorDao.h>
#import <PEFuelPurchase-Model/FPCoordinatorDaoImpl.h>
#import <FlatUIKit/UIColor+FlatUI.h>
#import <PEObjc-Commons/UIView+PEBorders.h>
#import <DateTools/NSDate+DateTools.h>
#import "UIColor+FPAdditions.h"
#import "FPUIUtils.h"

@implementation FPLocateNearbyGasController {
  id<FPCoordinatorDao> _coordDao;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  MBProgressHUD *_hud;
  NSArray *_priceEventStream;
  CLLocation *_currentLocation;
  NSNumberFormatter *_currencyFormatter;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<FPCoordinatorDao>)coordDao
               currentLocation:(CLLocation *)currentLocation
                      uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(FPScreenToolkit *)screenToolkit {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _coordDao = coordDao;
    _currentLocation = currentLocation;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
    _currencyFormatter = [PEUtils currencyFormatter];
  }
  return self;
}

#pragma mark - Navigation button handlers

- (void)cancel {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)animatedViewDidAppear {
  [self viewDidAppear:YES];
}

#pragma mark - View Controller Lifecyle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  UINavigationItem *navItem = [self navigationItem];
  [navItem setTitle:@"Locate Nearby Gas"];
  UIBarButtonItem *(^newSysItem)(UIBarButtonSystemItem, SEL) = ^ UIBarButtonItem *(UIBarButtonSystemItem item, SEL selector) {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:item target:self action:selector];
  };
  [navItem setLeftBarButtonItem:newSysItem(UIBarButtonSystemItemCancel, @selector(cancel))];
  _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  _hud.delegate = self;
  _hud.labelText = @"Locating nearby gas...";
  [_coordDao fetchPriceStreamSortedByPriceDistanceNearLat:[PEUtils decimalNumberFromDouble:[_currentLocation coordinate].latitude]
                                                     long:[PEUtils decimalNumberFromDouble:[_currentLocation coordinate].longitude]
                                           distanceWithin:50000
                                               maxResults:25
                                      notFoundOnServerBlk:^{
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                          // TODO
                                        });
                                      }
                                               successBlk:^(NSArray *priceEventStream) {
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                   [_hud hide:YES];
                                                   _priceEventStream = priceEventStream;
                                                   self.needsRepaint = YES;
                                                   //[self viewDidAppear:YES];
                                                   [self performSelector:@selector(animatedViewDidAppear) withObject:nil afterDelay:0.15];
                                                 });
                                               }
                                       remoteStoreBusyBlk:^(NSDate *retryAfter) {
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                           [_hud hide:YES];
                                           [PEUIUtils showWaitAlertWithMsgs:nil
                                                                      title:@"Server undergoing maintenance."
                                                           alertDescription:[[NSAttributedString alloc] initWithString:@"We apologize, but the Gas Jot server is currently \
busy undergoing maintenance.  Please try again later."]
                                                                   topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                                buttonTitle:@"Okay."
                                                               buttonAction:^{}
                                                             relativeToView:self.view];
                                         });
                                       }
                                       tempRemoteErrorBlk:^{
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                           [_hud hide:YES];
                                           [PEUIUtils showErrorAlertWithMsgs:nil
                                                                       title:@"Oops."
                                                            alertDescription:[[NSAttributedString alloc] initWithString:@"An error has occurred.  Please try again later."]
                                                                    topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                                 buttonTitle:@"Okay."
                                                                buttonAction:^{}
                                                              relativeToView:self.view];
                                         });
                                       }];
}

#pragma mark - Helpers

- (NSArray *)makeWaitContent {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:0.75 relativeToView:self.view];
  return @[contentPanel, @(YES), @(NO)];
}

- (UIView *)makeRowPanelForPriceEvent:(FPPriceEvent *)priceEvent {
  UIView *rowPanel = [PEUIUtils panelWithWidthOf:1.0
                                  relativeToView:self.view
                                     fixedHeight:([PEUIUtils sizeOfText:@""
                                                               withFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleBody]].height +
                                                                  _uitoolkit.verticalPaddingForButtons + 40.0)];
  [rowPanel setBackgroundColor:[UIColor whiteColor]];
  [rowPanel addTopBorderWithColor:[UIColor cloudsColor] andWidth:1.5];
  
  UIView *pricePanel = [PEUIUtils panelWithWidthOf:0.30 andHeightOf:0.8 relativeToView:rowPanel];
  [pricePanel addRightBorderWithColor:[UIColor cloudsColor] andWidth:1.5];
  UILabel *priceLabel = [PEUIUtils labelWithKey:[_currencyFormatter stringFromNumber:priceEvent.price]
                                           font:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle2]
                                backgroundColor:[UIColor clearColor]
                                      textColor:[UIColor greenSeaColor]
                            verticalTextPadding:3.0
                                     fitToWidth:pricePanel.frame.size.width];
  UILabel *priceTimeAgoLabel = [PEUIUtils labelWithKey:priceEvent.date.timeAgoSinceNow
                                                  font:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption2]
                                       backgroundColor:[UIColor clearColor]
                                             textColor:[UIColor darkGrayColor]
                                   verticalTextPadding:3.0
                                            fitToWidth:pricePanel.frame.size.width];
  [PEUIUtils placeView:priceLabel atTopOf:pricePanel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:10.0 hpadding:0.0];
  [PEUIUtils placeView:priceTimeAgoLabel below:priceLabel onto:pricePanel withAlignment:PEUIHorizontalAlignmentTypeCenter alignmentRelativeToView:pricePanel vpadding:5.0 hpadding:0.0];
  
  UIView *gasStationPanel = [PEUIUtils panelWithFixedWidth:(rowPanel.frame.size.width - pricePanel.frame.size.width)
                                               fixedHeight:rowPanel.frame.size.height];
  
  UIImageView *fsTypeIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:priceEvent.fsType.iconImgName]];
  CGFloat availableWidth = gasStationPanel.frame.size.width - (fsTypeIconView.frame.size.width + 10.0);
  UILabel *fsTypeName = [PEUIUtils labelWithKey:priceEvent.fsType.name
                                           font:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]
                                backgroundColor:[UIColor clearColor]
                                      textColor:[UIColor darkGrayColor]
                            verticalTextPadding:3.0
                                     fitToWidth:availableWidth];
  UIView *fsIconAndNamePanel = [PEUIUtils panelWithColumnOfViews:@[fsTypeIconView, fsTypeName]
                                     verticalPaddingBetweenViews:5.0
                                                  viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
  [PEUIUtils setFrameWidthOfView:fsIconAndNamePanel ofWidth:0.23 relativeTo:gasStationPanel];
  [PEUIUtils placeView:fsIconAndNamePanel inMiddleOf:gasStationPanel withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:5.0];
  UIView *btnsPanel = [PEUIUtils panelWithFixedWidth:(gasStationPanel.frame.size.width - (fsIconAndNamePanel.frame.size.width + 5.0 + 10.0))
                                         fixedHeight:gasStationPanel.frame.size.height];
  UIButton *directionsBtn = [PEUIUtils buttonWithKey:@"Route"
                                                font:[PEUIUtils boldFontForTextStyle:UIFontTextStyleCaption1]
                                     backgroundColor:[UIColor peterRiverColor]
                                           textColor:[UIColor whiteColor]
                        disabledStateBackgroundColor:nil
                              disabledStateTextColor:nil
                                     verticalPadding:12.5
                                   horizontalPadding:40.0
                                        cornerRadius:5.0
                                              target:nil
                                              action:nil];
  UIButton *logBtn = [PEUIUtils buttonWithKey:@"Make Log"
                                                font:[PEUIUtils boldFontForTextStyle:UIFontTextStyleCaption1]
                                     backgroundColor:[UIColor turquoiseColor]
                                           textColor:[UIColor whiteColor]
                        disabledStateBackgroundColor:nil
                              disabledStateTextColor:nil
                                     verticalPadding:12.5
                                   horizontalPadding:18.0
                                        cornerRadius:5.0
                                              target:nil
                                              action:nil];
  [PEUIUtils placeView:directionsBtn atTopOf:btnsPanel withAlignment:PEUIHorizontalAlignmentTypeRight vpadding:12.5 hpadding:15.0];
  [PEUIUtils placeView:logBtn below:directionsBtn onto:btnsPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:8.0 hpadding:0.0];
  
  [PEUIUtils placeView:btnsPanel
          toTheRightOf:fsIconAndNamePanel
                  onto:gasStationPanel
         withAlignment:PEUIVerticalAlignmentTypeTop
alignmentRelativeToView:gasStationPanel
              hpadding:0.0];
  
  // place views onto row panel
  [PEUIUtils placeView:pricePanel inMiddleOf:rowPanel withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:0.0];
  [PEUIUtils placeView:gasStationPanel
          toTheRightOf:pricePanel
                  onto:rowPanel
         withAlignment:PEUIVerticalAlignmentTypeMiddle
alignmentRelativeToView:rowPanel
              hpadding:10.0];
  return rowPanel;
}

- (NSArray *)makePriceEventStreamContent {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:0.0 relativeToView:self.view];
  [contentPanel setBackgroundColor:[UIColor whiteColor]];
  NSMutableArray *rowPanels = [NSMutableArray arrayWithCapacity:_priceEventStream.count];
  //BOOL white = YES;
  for (FPPriceEvent *priceEvent in _priceEventStream) {
    UIView *rowPanel = [self makeRowPanelForPriceEvent:priceEvent];
    /*if (white) {
      [rowPanel setBackgroundColor:[UIColor whiteColor]];
    } else {
      [rowPanel setBackgroundColor:[UIColor cloudsColor]];
    }
    white = !white;*/
    [rowPanels addObject:rowPanel];
  }
  CGFloat totalHeight = 0.0;
  UIView *dataTablePanel = [PEUIUtils panelWithColumnOfViews:rowPanels verticalPaddingBetweenViews:0.0 viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
  totalHeight += dataTablePanel.frame.size.height;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  [PEUIUtils placeView:dataTablePanel
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:FPContentPanelTopPadding
              hpadding:0.0];
  return @[contentPanel, @(YES), @(NO)];
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContent {
  if (_priceEventStream) {
    return [self makePriceEventStreamContent];
  } else {
    return [self makeWaitContent];
  }
}

@end
