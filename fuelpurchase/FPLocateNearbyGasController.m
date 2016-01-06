//
//  FPLocateNearbyGasController.m
//  Gas Jot
//
//  Created by Paul Evans on 12/31/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "FPLocateNearbyGasController.h"
#import <PEObjc-Commons/PEUIUtils.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <PEFuelPurchase-Model/FPPriceEvent.h>
#import <PEFuelPurchase-Model/FPFuelStationType.h>

@implementation FPLocateNearbyGasController {
  id<FPCoordinatorDao> _coordDao;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  MBProgressHUD *_hud;
  NSArray *_priceEventStream;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<FPCoordinatorDao>)coordDao
                      uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(FPScreenToolkit *)screenToolkit {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
  }
  return self;
}

#pragma mark - Navigation button handlers

- (void)cancel {
  [self dismissViewControllerAnimated:YES completion:nil];
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
  [_coordDao fetchPriceEventsNearLatitude:nil
                                longitude:nil
                                   within:nil
                      notFoundOnServerBlk:nil
                               successBlk:^(NSArray *priceEventStream) {
                                 _priceEventStream = priceEventStream;
                                 [_hud hide:YES];
                                 self.needsRepaint = YES;
                                 [self viewDidAppear:YES];
                               }
                       remoteStoreBusyBlk:nil
                       tempRemoteErrorBlk:nil];
}

#pragma mark - Helpers

- (NSArray *)makeWaitContent {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:0.75 relativeToView:self.view];
  [PEUIUtils applyBorderToView:contentPanel withColor:[UIColor blueColor]];
  return @[contentPanel, @(YES), @(NO)];
}

- (UIView *)makeRowPanelForPriceEvent:(FPPriceEvent *)priceEvent {
  UIView *rowPanel = [PEUIUtils panelWithWidthOf:1.0
                                  relativeToView:self.view
                                     fixedHeight:([PEUIUtils sizeOfText:@"" withFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleBody]].height + _uitoolkit.verticalPaddingForButtons + 15.0)];
  UIImageView *fsTypeIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:priceEvent.fsType.iconImgName]];
  [PEUIUtils placeView:fsTypeIconView inMiddleOf:rowPanel withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:15.0];
  return rowPanel;
}

- (NSArray *)makePriceEventStreamContent {
  NSMutableArray *rowPanels = [NSMutableArray arrayWithCapacity:_priceEventStream.count];
  for (FPPriceEvent *priceEvent in _priceEventStream) {
    [rowPanels addObject:[self makeRowPanelForPriceEvent:priceEvent]];
  }
  UIView *contentPanel = [PEUIUtils panelWithColumnOfViews:rowPanels verticalPaddingBetweenViews:5.0 viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
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
