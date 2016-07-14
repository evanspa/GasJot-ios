//
//  SSELUtils.h
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 A collection of helper functions.
 */
@interface SSELUtils : NSObject

#pragma mark - Factory Functions

/**
 Factory function that returns a new utils instance that uses the given folder
 path as its source for simulation data.
 @param baseResourceFolder The folder root containing the set of simulation
 data utilized by this utils instance.
 @return A new, initialized utils instance.
 */
+ (SSELUtils *)utilsWithBaseResourceFolder:(NSString *)baseResourceFolder;

#pragma mark - Toggle Simulation Selector

/**
 If SSELUIWindow was used to generate notifications on shake gestures, this
 method enables this instance to react to shake gestures in the context of the
 given screen name and view controller.
 @param screenName The logical screen name associated with the given view
 controller (this screen name is used to find a folder within the base
 resource folder in order to populate the simulation selector with the proper
 simulation choices).
 @param viewController The view controller whose view should be given a button
 to toggle the simulation selector.
 */
- (void)reactToShakeGestureForScreen:(NSString *)screenName
                  ontoViewController:(UIViewController *)viewController;

/**
 Adds a button to the top-right corner of the given view controller's view that
 can be used to select a use case simulation to enable.
 @param screenName The logical name of the screen that is ultimately used to
 load the relevant simulation data from the base resource folder (used to
 construct this instance).
 @param screenName The logical screen name associated with the given view
 controller (this screen name is used to find a folder within the base
 resource folder in order to populate the simulation selector with the proper
 simulation choices).
 @param viewController The view controller whose view should be given a button
 to toggle the simulation selector.
 */
- (void)addSimulationTogglerForScreen:(NSString *)screenName
                   ontoViewController:(UIViewController *)viewController;

- (void)toggleSimulationsSelectorOn;

#pragma mark - Helpers

/**
 Class helper function that returns an array of SSELUseCase instances for the
 given logical screen name (used as a folder name) searched within the given
 resource folder parameter.
 @param screen The logical screen nam (folder name).
 @param resourceFolder The base folder of the screen folder.
 @return An array of SSELUseCase instances loaded from the simulations stored
 within the screen folder found within the resource folder.
 */
+ (NSArray *)usecasesForScreen:(NSString *)screen
        fromBaseResourceFolder:(NSString *)resourceFolder;

#pragma mark - Properties

/** Base folder of where simulations are stored. */
@property (nonatomic, readonly) NSString *baseResourceFolder;

/** The name of the screen. */
@property (nonatomic) NSString *screenName;

/** View controller. */
@property (nonatomic) UIViewController *ontoViewController;

@end
