//
//  FPFuelstationTypeDsDelegate.m
//  Gas Jot
//
//  Created by Paul Evans on 12/22/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "FPFuelstationTypeDsDelegate.h"
#import <PEObjc-Commons/PEUIUtils.h>
#import <PEObjc-Commons/PEUtils.h>
#import <PEFuelPurchase-Model/FPFuelStationType.h>
#import <PEObjc-Commons/PEUIToolkit.h>
#import "FPScreenToolkit.h"

NSInteger const FPFSTypeDsDelegateBrandLabelTag      = 1;
NSInteger const FPFSTypeDsDelegateBrandValueLabelTag = 2;
NSInteger const FPFSTypeDsDelegateBrandIconImgTag    = 3;

@implementation FPFuelstationTypeDsDelegate {
  id<FPCoordinatorDao> _coordDao;
  FPScreenToolkit *_screenToolkit;
  PEUIToolkit *_uitoolkit;
  FPUser *_user;
  UIViewController *_controllerCtx;
  PEItemSelectedAction _typeSelectedAction;
  BOOL _displayDisclosureIndicators;
}

#pragma mark - Initializers

- (id)initWithControllerCtx:(UIViewController *)controllerCtx
                     fsType:(FPFuelStationType *)fsType
       fsTypeSelectedAction:(PEItemSelectedAction)fsTypeSelectedAction
displayDisclosureIndicators:(BOOL)displayDisclosureIndicators
             coordinatorDao:(id<FPCoordinatorDao>)coordDao
                       user:(FPUser *)user
              screenToolkit:(FPScreenToolkit *)screenToolkit
                      error:(PELMDaoErrorBlk)errorBlk {
  self = [super init];
  if (self) {
    _controllerCtx = controllerCtx;
    _coordDao = coordDao;
    _selectedFsType = fsType;
    _displayDisclosureIndicators = displayDisclosureIndicators;
    _user = user;
    _screenToolkit = screenToolkit;
    _uitoolkit = [screenToolkit uitoolkit];
    __weak FPFuelstationTypeDsDelegate *weakSelf = self;
    _typeSelectedAction = ^(FPFuelStationType *selectedFsType, NSIndexPath *indexPath, UIViewController *selectionController) {
      [weakSelf setSelectedFsType:selectedFsType];
      fsTypeSelectedAction(selectedFsType, indexPath, selectionController);
    };
  }
  return self;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  switch ([indexPath section]) {
    case 0:
      [PEUIUtils displayController:[_screenToolkit newFuelstationTypesForSelectionScreenMakerWithItemSelectedAction:_typeSelectedAction
                                                                                                initialSelectedType:_selectedFsType](_user)
                    fromController:_controllerCtx
                          animated:YES];
      break;
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 15;
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath {
  UIView *contentView = cell.contentView;
  UIView *brandLabel = [contentView viewWithTag:FPFSTypeDsDelegateBrandLabelTag];
  UIView *brandValueLabel = [contentView viewWithTag:FPFSTypeDsDelegateBrandValueLabelTag];
  UIView *brandIconImg = [contentView viewWithTag:FPFSTypeDsDelegateBrandIconImgTag];
  [PEUIUtils positionView:brandLabel inMiddleOf:contentView withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:10.0];
  [PEUIUtils positionView:brandValueLabel inMiddleOf:contentView withAlignment:PEUIHorizontalAlignmentTypeRight hpadding:15.0];
  [PEUIUtils positionView:brandIconImg toTheLeftOf:brandValueLabel onto:contentView withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:10.0];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return [PEUIUtils sizeOfText:@"" withFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleBody]].height +
  _uitoolkit.verticalPaddingForButtons + 15.0;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
  UIView *contentView = cell.contentView;
  CGFloat availableWidth = contentView.frame.size.width;
  availableWidth -= (10.0 + 15.0); // subtract left and right margins
  UILabel *brandLabel = [PEUIUtils labelWithKey:@"Brand"
                                           font:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                backgroundColor:[UIColor clearColor]
                                      textColor:[UIColor blackColor]
                            verticalTextPadding:3.0];
  [brandLabel setTag:FPFSTypeDsDelegateBrandLabelTag];
  [contentView addSubview:brandLabel];
  availableWidth -= brandLabel.frame.size.width;
  UIImage *iconImg = [UIImage imageNamed:_selectedFsType.iconImgName];
  if (iconImg) {
    UIImageView *imgView = [[UIImageView alloc] initWithImage:iconImg];
    [imgView setTag:FPFSTypeDsDelegateBrandIconImgTag];
    [contentView addSubview:imgView];
    availableWidth -= imgView.frame.size.width;
  }
  NSString *fstypeName = [PEUIUtils truncatedTextForText:_selectedFsType.name
                                                    font:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                          availableWidth:availableWidth];
  UILabel *brandValueLabel = [PEUIUtils labelWithKey:fstypeName
                                                font:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                     backgroundColor:[UIColor clearColor]
                                           textColor:[UIColor grayColor]
                                 verticalTextPadding:3.0
                                          fitToWidth:availableWidth];
  [brandValueLabel setTag:FPFSTypeDsDelegateBrandValueLabelTag];
  [contentView addSubview:brandValueLabel];
  if (_displayDisclosureIndicators) {
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
  } else {
    [cell setAccessoryType:UITableViewCellAccessoryNone];
  }
  return cell;
}

@end
