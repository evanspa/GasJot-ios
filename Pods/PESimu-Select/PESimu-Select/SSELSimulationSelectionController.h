//
//  SSELSimulationSelectionController.h
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
 Provides a user interface for a set of HTTP response simulations to be enabled,
 and configured (request / response latencies set).
 */
@interface SSELSimulationSelectionController : UIViewController
<UITableViewDataSource, UITableViewDelegate>

#pragma mark - Initializers

/**
 Initializes a new instance with a set of use cases that will be used to
 populate the table view groups that are contained with the view controllers
 root view (each use case contains a set of simulations that can be toggeled).
 @return A new view controller instance.
 */
- (id)initWithUseCases:(NSArray *)useCases;

#pragma mark - Methods

/**
 Syncs the simulation instances contained within the use cases collection with
 the table cells of this view controller's table view.
 */
- (void)bindLatencies;

@end
