//
//  SSELSimulationTableCell.h
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

#import <UIKit/UIKit.h>
#import "SSELSimulation.h"

/**
 Simulation selector table cell.
 */
@interface SSELSimulationTableCell : UITableViewCell

#pragma mark - Initializers

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;

#pragma mark - Properties

/** Simulation model instance. */
@property (nonatomic, readonly) SSELSimulation *simulation;

#pragma mark - Methods

- (void)bindSimulation:(SSELSimulation *)simulation;

/**
 Binds the inputted request/response latencies to the simulation model instance.
 */
- (void)bindLatencies;

/**
 Clears the request/response latencies currently on the simulation model instance.
 */
- (void)clearLatencies;

#pragma mark - Helpers

/**
 @return The estimated height of a table cell housing the information contained
 in the given simulation instance.
 @param simulation The simulation data housed by a table cell whose height is
 returned.
 */
+ (CGFloat)tableCellHeightForSimulation:(SSELSimulation *)simulation;

@end
