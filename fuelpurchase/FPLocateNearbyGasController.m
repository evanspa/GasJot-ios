//
//  FPLocateNearbyGasController.m
//  Gas Jot
//
//  Created by Paul Evans on 12/31/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

@import MapKit;
#import "FPLocateNearbyGasController.h"
#import <PEObjc-Commons/PEUIUtils.h>
#import <PEObjc-Commons/PEUtils.h>
#import <BlocksKit/UIControl+BlocksKit.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <PEFuelPurchase-Model/FPPriceEvent.h>
#import <PEFuelPurchase-Model/FPFuelStationType.h>
#import <PEFuelPurchase-Model/FPCoordinatorDao.h>
#import <PEFuelPurchase-Model/FPCoordinatorDaoImpl.h>
#import <FormatterKit/TTTAddressFormatter.h>
#import <FormatterKit/TTTLocationFormatter.h>
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
  TTTAddressFormatter *_addressFormatter;
  TTTLocationFormatter *_locationFormatter;
  UIBarButtonItem *_refreshBarButtonItem;
  BOOL _sortByLowestPrice;
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
    _addressFormatter = [[TTTAddressFormatter alloc] init];
    _locationFormatter = [[TTTLocationFormatter alloc] init];
    [_locationFormatter setUnitSystem:TTTImperialSystem];
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
  _sortByLowestPrice = YES;
  [navItem setLeftBarButtonItem:newSysItem(UIBarButtonSystemItemCancel, @selector(cancel))];
  [self loadPriceStreamWithResultsBlk:^(NSArray *priceEventStream) {
    _priceEventStream = priceEventStream;
    self.needsRepaint = YES;
    [self viewDidAppear:YES];
  }];
}

#pragma mark - Helpers

- (void)refresh {
  [FPUIUtils actionWithCurrentLocationBlk:^(CLLocation *currentLocation) {
    _currentLocation = currentLocation;
    [self loadPriceStreamWithResultsBlk:^(NSArray *priceEventStream) {
      if (priceEventStream.count > 0) {
        _priceEventStream = priceEventStream;
        self.needsRepaint = YES;
        [self viewDidAppear:YES];
      } else {
        [PEUIUtils showInfoAlertWithTitle:@"No nearby gas stations found."
                         alertDescription:[[NSAttributedString alloc] initWithString:@"Sorry, but Gas Jot doesn't have any nearby price information."]
                                 topInset:[PEUIUtils topInsetForAlertsWithController:self]
                              buttonTitle:@"Okay."
                             buttonAction:^{}
                           relativeToView:self.view];
      }
    }];
  }
                 locationNeededReasonText:@"To find nearby gas stations"
                         parentController:self
                               parentView:self.view];
}

- (void)loadPriceStreamWithResultsBlk:(void(^)(NSArray *))resultsBlk {
  _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  _hud.delegate = self;
  _hud.labelText = @"Locating nearby gas...";
  [_refreshBarButtonItem setEnabled:NO];
  void(^notFoundOnServerBlk)(void) = ^{
    dispatch_async(dispatch_get_main_queue(), ^{
      [_hud hide:YES];
      [PEUIUtils showErrorAlertWithMsgs:nil
                                  title:@"Oops."
                       alertDescription:[[NSAttributedString alloc] initWithString:@"An error has occurred.  Please try again later."]
                               topInset:[PEUIUtils topInsetForAlertsWithController:self]
                            buttonTitle:@"Okay."
                           buttonAction:^{ [_refreshBarButtonItem setEnabled:YES]; }
                         relativeToView:self.view];
    });
  };
  void(^successBlk)(NSArray *) = ^(NSArray *priceEventStream) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [_hud hide:YES];
      [_refreshBarButtonItem setEnabled:YES];
      resultsBlk(priceEventStream);
    });
  };
  PELMRemoteMasterBusyBlk remoteStoreBusyBlk = ^(NSDate *retryAfter) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [_hud hide:YES];
      [PEUIUtils showWaitAlertWithMsgs:nil
                                 title:@"Server undergoing maintenance."
                      alertDescription:[[NSAttributedString alloc] initWithString:@"We apologize, but the Gas Jot server is currently \
busy undergoing maintenance.  Please try again later."]
                              topInset:[PEUIUtils topInsetForAlertsWithController:self]
                           buttonTitle:@"Okay."
                          buttonAction:^{ [_refreshBarButtonItem setEnabled:YES]; }
                        relativeToView:self.view];
    });
  };
  void(^tempRemoteErrorBlk)(void) = ^{
    dispatch_async(dispatch_get_main_queue(), ^{
      [_hud hide:YES];
      [PEUIUtils showErrorAlertWithMsgs:nil
                                  title:@"Oops."
                       alertDescription:[[NSAttributedString alloc] initWithString:@"An error has occurred.  Please try again later."]
                               topInset:[PEUIUtils topInsetForAlertsWithController:self]
                            buttonTitle:@"Okay."
                           buttonAction:^{ [_refreshBarButtonItem setEnabled:YES]; }
                         relativeToView:self.view];
    });
  };
  NSDecimalNumber *latitude = [PEUtils decimalNumberFromDouble:[_currentLocation coordinate].latitude];
  NSDecimalNumber *longitude = [PEUtils decimalNumberFromDouble:[_currentLocation coordinate].longitude];
  NSInteger distanceWithin = [APP priceSearchDistanceWithin];
  NSInteger maxResults = [APP priceSearchMaxResults];
  if (_sortByLowestPrice) {
    [_coordDao fetchPriceStreamSortedByPriceDistanceNearLat:latitude
                                                       long:longitude
                                             distanceWithin:distanceWithin
                                                 maxResults:maxResults
                                        notFoundOnServerBlk:notFoundOnServerBlk
                                                 successBlk:successBlk
                                         remoteStoreBusyBlk:remoteStoreBusyBlk
                                         tempRemoteErrorBlk:tempRemoteErrorBlk];
  } else {
    [_coordDao fetchPriceStreamSortedByDistancePriceNearLat:latitude
                                                       long:longitude
                                             distanceWithin:distanceWithin
                                                 maxResults:maxResults
                                        notFoundOnServerBlk:notFoundOnServerBlk
                                                 successBlk:successBlk
                                         remoteStoreBusyBlk:remoteStoreBusyBlk
                                         tempRemoteErrorBlk:tempRemoteErrorBlk];
  }
}

- (NSArray *)makeWaitContent {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:0.75 relativeToView:self.view];
  return @[contentPanel, @(YES), @(NO)];
}

- (UIView *)makeRowPanelForPriceEvent:(FPPriceEvent *)priceEvent {
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
  [directionsBtn bk_addEventHandler:^(id sender) {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(priceEvent.fsLatitude.doubleValue, priceEvent.fsLongitude.doubleValue);
    MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil];
    MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
    [mapItem setName:priceEvent.fsType.name];
    NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
    MKMapItem *currentLocationMapItem = [MKMapItem mapItemForCurrentLocation];
    [MKMapItem openMapsWithItems:@[currentLocationMapItem, mapItem]
                   launchOptions:launchOptions];
  } forControlEvents:UIControlEventTouchUpInside];
  CGFloat anticipatedRowHeight = [PEUIUtils sizeOfText:@" \n \n "
                                              withFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleCaption1]].height;
  anticipatedRowHeight += directionsBtn.frame.size.height;
  anticipatedRowHeight += 27.5; // padding
  UIView *rowPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:self.view fixedHeight:anticipatedRowHeight];
  [rowPanel setBackgroundColor:[UIColor whiteColor]];
  [rowPanel addTopBorderWithColor:[UIColor cloudsColor] andWidth:1.5];
  
  UIView *pricePanel = [PEUIUtils panelWithWidthOf:0.28 andHeightOf:0.8 relativeToView:rowPanel];
  [pricePanel addRightBorderWithColor:[UIColor cloudsColor] andWidth:1.5];
  UILabel *priceLabel = [PEUIUtils labelWithKey:[_currencyFormatter stringFromNumber:priceEvent.price]
                                           font:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle2]
                                backgroundColor:[UIColor clearColor]
                                      textColor:[UIColor greenSeaColor]
                            verticalTextPadding:3.0
                                     fitToWidth:pricePanel.frame.size.width];
  UIFont *caption2Font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
  NSString *timeAgoText = [PEUIUtils truncatedTextForText:priceEvent.date.timeAgoSinceNow
                                                     font:caption2Font
                                           availableWidth:(pricePanel.frame.size.width - 4.0)]; // 4.0 some padding
  UILabel *priceTimeAgoLabel = [PEUIUtils labelWithKey:timeAgoText
                                                  font:caption2Font
                                       backgroundColor:[UIColor clearColor]
                                             textColor:[UIColor darkGrayColor]
                                   verticalTextPadding:3.0
                                            fitToWidth:pricePanel.frame.size.width];
  UIView *priceAndTimeAgoPanel = [PEUIUtils panelWithColumnOfViews:@[priceLabel, priceTimeAgoLabel]
                                       verticalPaddingBetweenViews:5.0
                                                    viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
  [PEUIUtils placeView:priceAndTimeAgoPanel inMiddleOf:pricePanel withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:7.5];
  
  UIView *gasStationPanel = [PEUIUtils panelWithFixedWidth:(rowPanel.frame.size.width - pricePanel.frame.size.width)
                                               fixedHeight:rowPanel.frame.size.height];
  
  UIImageView *fsTypeIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:priceEvent.fsType.iconImgName]];
  CGFloat fsIconAndNamePanelWidth = 0.24 * gasStationPanel.frame.size.width;
  UIFont *caption1Font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
  NSString *fsTypeNameText = [PEUIUtils truncatedTextForText:priceEvent.fsType.name
                                                        font:caption1Font
                                              availableWidth:fsIconAndNamePanelWidth];
  UILabel *fsTypeNameLabel = [PEUIUtils labelWithKey:fsTypeNameText
                                                font:caption1Font
                                     backgroundColor:[UIColor clearColor]
                                           textColor:[UIColor darkGrayColor]
                                 verticalTextPadding:3.0];
  UIView *fsIconAndNamePanel = [PEUIUtils panelWithColumnOfViews:@[fsTypeIconView, fsTypeNameLabel]
                                     verticalPaddingBetweenViews:5.0
                                                  viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
  [PEUIUtils setFrameWidth:fsIconAndNamePanelWidth ofView:fsIconAndNamePanel];
  [PEUIUtils placeView:fsIconAndNamePanel inMiddleOf:gasStationPanel withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:1.0];
  UIView *btnsPanel = [PEUIUtils panelWithFixedWidth:(gasStationPanel.frame.size.width - (fsIconAndNamePanel.frame.size.width + 1.0 + 10.0))
                                         fixedHeight:gasStationPanel.frame.size.height];
  //[PEUIUtils applyBorderToView:btnsPanel withColor:[UIColor redColor]];
  CGFloat addrAvailableWidth = btnsPanel.frame.size.width - (10 + 2); // 10 for left-padding; 2 for a little extra
  NSString *fsStreetText = [PEUIUtils truncatedTextForText:priceEvent.fsStreet font:caption1Font availableWidth:addrAvailableWidth];
  NSString *addressText = [_addressFormatter stringFromAddressWithStreet:fsStreetText
                                                               locality:priceEvent.fsCity
                                                                 region:priceEvent.fsState
                                                             postalCode:nil
                                                                country:nil];
  UILabel *addressLabel = [PEUIUtils labelWithKey:addressText
                                             font:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]
                                  backgroundColor:[UIColor clearColor]
                                        textColor:[UIColor grayColor]
                              verticalTextPadding:3.0];
  [addressLabel setTextAlignment:NSTextAlignmentRight];
  
  [PEUIUtils placeView:directionsBtn atTopOf:btnsPanel withAlignment:PEUIHorizontalAlignmentTypeRight vpadding:12.5 hpadding:20.0];
  [PEUIUtils placeView:addressLabel
                 below:directionsBtn
                  onto:btnsPanel
         withAlignment:PEUIHorizontalAlignmentTypeRight
alignmentRelativeToView:btnsPanel
              vpadding:5.0
              hpadding:10.0];
  NSDecimalNumber *distance = priceEvent.fsDistance;
  if (distance) {
    UIColor *distanceLabelColor;
    if (distance.floatValue < 4900.0) { // a little over 3 miles
      distanceLabelColor = [UIColor greenSeaColor];
    } else {
      distanceLabelColor = [UIColor grayColor];
    }
    UILabel *distanceLabel = [PEUIUtils labelWithKey:[_locationFormatter stringFromDistance:distance.doubleValue]
                                                font:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]
                                     backgroundColor:[UIColor clearColor]
                                           textColor:distanceLabelColor
                                 verticalTextPadding:3.0];
    [distanceLabel setTextAlignment:NSTextAlignmentRight];
    [PEUIUtils placeView:distanceLabel below:addressLabel onto:btnsPanel withAlignment:PEUIHorizontalAlignmentTypeRight vpadding:2.5 hpadding:0.0];
  }
  
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
  if (_priceEventStream.count > 0) {
    UINavigationItem *navItem = [self navigationItem];
    _refreshBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Refresh" style:UIBarButtonItemStylePlain target:self action:@selector(refresh)];
    [navItem setRightBarButtonItem:_refreshBarButtonItem];
    NSMutableArray *rowPanels = [NSMutableArray arrayWithCapacity:_priceEventStream.count];
    for (FPPriceEvent *priceEvent in _priceEventStream) {
      UIView *rowPanel = [self makeRowPanelForPriceEvent:priceEvent];
      [rowPanels addObject:rowPanel];
    }
    UISegmentedControl *sortBySegmentedChooser = [[UISegmentedControl alloc] initWithItems:@[@"by Lowest Price", @"by Nearest Location"]];
    [sortBySegmentedChooser bk_addEventHandler:^(id sender) {
      _sortByLowestPrice = (sortBySegmentedChooser.selectedSegmentIndex == 0);
      [self refresh];
    } forControlEvents:UIControlEventValueChanged];
    if (_sortByLowestPrice) {
      [sortBySegmentedChooser setSelectedSegmentIndex:0];
    } else {
      [sortBySegmentedChooser setSelectedSegmentIndex:1];
    }
    UILabel *searchRadiusLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:@"Search radius: %@"
                                                                                            textToAccent:[_locationFormatter stringFromDistance:[APP priceSearchDistanceWithin]]
                                                                                          accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleCaption1]]
                                                              font:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]
                                          fontForHeightCalculation:[PEUIUtils boldFontForTextStyle:UIFontTextStyleCaption1]
                                                   backgroundColor:[UIColor clearColor]
                                                         textColor:[UIColor darkGrayColor]
                                               verticalTextPadding:3.0];
    UILabel *maxResultsLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:@"Max results: %@"
                                                                                            textToAccent:[NSString stringWithFormat:@"%ld", (long)[APP priceSearchMaxResults]]
                                                                                          accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleCaption1]]
                                                              font:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]
                                          fontForHeightCalculation:[PEUIUtils boldFontForTextStyle:UIFontTextStyleCaption1]
                                                   backgroundColor:[UIColor clearColor]
                                                         textColor:[UIColor darkGrayColor]
                                               verticalTextPadding:3.0];
    UIView *dataTablePanel = [PEUIUtils panelWithColumnOfViews:rowPanels
                                   verticalPaddingBetweenViews:0.0
                                                viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
    // place the views
    CGFloat totalHeight = 0.0;
    [PEUIUtils placeView:sortBySegmentedChooser
                 atTopOf:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeCenter
                vpadding:FPContentPanelTopPadding + 5.0
                hpadding:0.0];
    totalHeight += FPContentPanelTopPadding + 5.0 + sortBySegmentedChooser.frame.size.height;
    [PEUIUtils placeView:searchRadiusLabel
                   below:sortBySegmentedChooser
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:FPContentPanelTopPadding
                hpadding:8.0];
    totalHeight += searchRadiusLabel.frame.size.height + FPContentPanelTopPadding;
    [PEUIUtils placeView:maxResultsLabel
                   below:searchRadiusLabel
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:2.0
                hpadding:8.0];
    totalHeight += searchRadiusLabel.frame.size.height + 4.0;
    [PEUIUtils placeView:dataTablePanel
                   below:maxResultsLabel
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:4.0
                hpadding:0.0];
    totalHeight += dataTablePanel.frame.size.height + 4.0;
    [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  } else {
    [PEUIUtils showInfoAlertWithTitle:@"No nearby gas stations found."
                     alertDescription:[[NSAttributedString alloc] initWithString:@"Sorry, but Gas Jot doesn't have any nearby price information."]
                             topInset:[PEUIUtils topInsetForAlertsWithController:self]
                          buttonTitle:@"Okay."
                         buttonAction:^{ [self dismissViewControllerAnimated:YES completion:nil]; }
                       relativeToView:self.view];
  }
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
