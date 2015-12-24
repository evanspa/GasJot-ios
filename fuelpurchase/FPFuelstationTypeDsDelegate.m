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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return [PEUIUtils sizeOfText:@"" withFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleBody]].height +
  _uitoolkit.verticalPaddingForButtons + 15.0;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
  return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                                 reuseIdentifier:nil];
  [[cell textLabel] setText:@"Brand"];
  [[cell detailTextLabel] setText:[_selectedFsType name]];
  if (_displayDisclosureIndicators) {
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
  } else {
    [cell setAccessoryType:UITableViewCellAccessoryNone];
  }
  return cell;
}

@end
