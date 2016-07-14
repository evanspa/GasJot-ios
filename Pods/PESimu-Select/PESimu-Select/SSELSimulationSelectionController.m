//
//  SSELSimulationSelectionController.m
//
// Copyright (c) 2014-2015 PESimu-Select
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "SSELSimulationSelectionController.h"
#import <PEObjc-Commons/PEUIUtils.h>
#import "SSELUseCase.h"
#import "SSELSimulation.h"
#import "SSELSimulationTableCell.h"

@implementation SSELSimulationSelectionController {
  NSArray *_useCases;
  NSMutableArray *_cellsForUsecases;
}

#pragma mark - Initializers

- (id)initWithUseCases:(NSArray *)useCases {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _useCases = useCases;
    [self initializeCellsArray];
    [self setTitle:@"Use Case Simulations"];
  }
  return self;
}

#pragma mark - Event Handlers

- (void)clearSimulations {
  [_useCases enumerateObjectsUsingBlock:^(id obj,
                                          NSUInteger idx,
                                          BOOL *stop) {
      SSELUseCase *useCase = (SSELUseCase *)obj;
      [useCase deselectAllSimulations];
      NSArray *cellsForUseCase = [_cellsForUsecases objectAtIndex:idx];
      [cellsForUseCase enumerateObjectsUsingBlock:^(id innerObj,
                                                    NSUInteger innerIdx,
                                                    BOOL *innerStop) {
          SSELSimulationTableCell *cell = (SSELSimulationTableCell *)innerObj;
          [cell clearLatencies];
          [cell setAccessoryType:UITableViewCellAccessoryNone];
        }];
    }];
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  UITableView *tableView = [[UITableView alloc]
                             initWithFrame:CGRectMake(0, 0, 0, 0)
                                     style:UITableViewStyleGrouped];
  [PEUIUtils setFrameWidthOfView:tableView ofWidth:1.0 relativeTo:[self view]];
  [PEUIUtils setFrameHeightOfView:tableView ofHeight:1.0 relativeTo:[self view]];
  [tableView setDelaysContentTouches:NO];
  [tableView setDataSource:self];
  [tableView setDelegate:self];
  [[self view] addSubview:tableView];
}

#pragma mark - Helpers

- (void)initializeCellsArray {
  _cellsForUsecases = [NSMutableArray arrayWithCapacity:[_useCases count]];
  [_useCases enumerateObjectsUsingBlock:^(id obj,
                                          NSUInteger idx,
                                          BOOL *stop) {
      SSELUseCase *useCase = (SSELUseCase *)obj;
      NSArray *simulations = [useCase simulations];
      [_cellsForUsecases
        addObject:[NSMutableArray arrayWithCapacity:[simulations count]]];
    }];
}

- (void)addCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
  NSMutableArray *sectionCells = [_cellsForUsecases objectAtIndex:[indexPath section]];
  if ([sectionCells count] > [indexPath row]) {
    [sectionCells replaceObjectAtIndex:[indexPath row] withObject:cell];
  } else {
    [sectionCells insertObject:cell atIndex:[indexPath row]];
  }
}

- (void)deselectNeighboringSimulationsForIndexPath:(NSIndexPath *)indexPath {
  SSELUseCase *usecase = [_useCases objectAtIndex:[indexPath section]];
  NSArray *simulations = [usecase simulations];
  NSArray *sectionCells = [_cellsForUsecases objectAtIndex:[indexPath section]];
  [sectionCells enumerateObjectsUsingBlock:^(id obj,
                                             NSUInteger idx,
                                             BOOL *stop) {
      if (idx != [indexPath row]) {
        UITableViewCell *cell = (UITableViewCell *)obj;
        SSELSimulation *simulation = [simulations objectAtIndex:idx];
        [simulation setSelected:NO];
        [cell setAccessoryType:UITableViewCellAccessoryNone];
      }
    }];
}

- (SSELSimulation *)simulationAtIndexPath:(NSIndexPath *)indexPath {
  SSELUseCase *usecase = [_useCases objectAtIndex:[indexPath section]];
  NSArray *simulations = [usecase simulations];
  return [simulations objectAtIndex:[indexPath row]];
}

- (CGFloat)heightForFooterView {
  return 60;
}

- (BOOL)isLastTableSection:(NSInteger)sectionIndex {
  return sectionIndex == ([_useCases count] - 1);
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return [_useCases count];
}

- (NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section {
  return [[_useCases objectAtIndex:section] name];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString *reuseIdent = @"UITableViewCell";
  SSELSimulationTableCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdent];
  if (!cell) {
    cell = [[SSELSimulationTableCell alloc] initWithReuseIdentifier:reuseIdent];
  }
  SSELSimulation *simulation = [self simulationAtIndexPath:indexPath];
  [cell bindSimulation:simulation];
  if ([simulation selected]) {
    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
  } else {
    [cell setAccessoryType:UITableViewCellAccessoryNone];
  }
  [self addCell:cell forIndexPath:indexPath];
  return cell;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
  SSELUseCase *usecase = [_useCases objectAtIndex:section];
  return [[usecase simulations] count];
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  SSELSimulation *simulation = [self simulationAtIndexPath:indexPath];
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  [self deselectNeighboringSimulationsForIndexPath:indexPath];
  [simulation toggleSelected];
  if ([simulation selected]) {
    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
  } else {
    [cell setAccessoryType:UITableViewCellAccessoryNone];
  }
  [cell setSelected:NO animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  // '48.6' is magic padding constant
  return [SSELSimulationTableCell
            tableCellHeightForSimulation:
              [self simulationAtIndexPath:indexPath]] + 48.6;
}

- (UIView *)tableView:(UITableView *)tableView
viewForFooterInSection:(NSInteger)section {
  UIView *footerView = nil;
  if ([self isLastTableSection:section]) {
    footerView =
      [[UIView alloc]
        initWithFrame:CGRectMake(0,
                                 0,
                                 [tableView frame].size.width,
                                 [self heightForFooterView])];
    UIButton *clearSimsBtn = [PEUIUtils buttonWithKey:@"Clear Simulations"
                                                 font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                      backgroundColor:[UIColor blueColor]
                                            textColor:[UIColor whiteColor]
                         disabledStateBackgroundColor:[UIColor grayColor]
                               disabledStateTextColor:[UIColor grayColor]
                                      verticalPadding:15
                                    horizontalPadding:15
                                         cornerRadius:3
                                               target:self
                                               action:@selector(clearSimulations)];
    [PEUIUtils placeView:clearSimsBtn
              inMiddleOf:footerView
           withAlignment:PEUIHorizontalAlignmentTypeCenter
                hpadding:0];
  }
  return footerView;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForFooterInSection:(NSInteger)section {
  CGFloat height = 0;
  if ([self isLastTableSection:section]) {
    height = [self heightForFooterView];
  }
  return height;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForHeaderInSection:(NSInteger)section {
  return 30;
}

#pragma mark - Methods

- (void)bindLatencies {
  [_useCases enumerateObjectsUsingBlock:^(id obj,
                                          NSUInteger idx,
                                          BOOL *stop) {
      NSArray *cellsForUseCase = [_cellsForUsecases objectAtIndex:idx];
      [cellsForUseCase enumerateObjectsUsingBlock:^(id innerObj,
                                                    NSUInteger innerIdx,
                                                    BOOL *innerStop) {
          SSELSimulationTableCell *cell = (SSELSimulationTableCell *)innerObj;
          [cell bindLatencies];
        }];
    }];
}

@end
