//
//  PDVUtils.h
//
// Copyright (c) 2014-2015 PEDev-Console
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
#import "PDVScreen.h"
#import "PDVDevEnabled.h"

/**
 * The work horse of PEDev-Console.  An instance of this class should be created
 * in your application delegate.
 */
@interface PDVUtils : NSObject

#pragma mark - Initialization

/**
 * Initializes this instance with the base/root folder of PESimu-Select simulation
 * folders.  See PESimu-Select documentation and/or the DemoApp for example
 * usage.
 * @param baseResourceFolder The root folder containing your PESimu-Select HTTP
 simulation folders.
 * @param screenGroups       The set of screen groups to be presented in the 
 screen selection controller.
 * @return An initialized instance.
 */
- (id)initWithBaseResourceFolderOfSimulations:(NSString *)baseResourceFolder
                                 screenGroups:(NSArray *)screenGroups;

#pragma mark - Setting the current screen name

/**
 @param screenName This screen name is used to find a folder within the base
 resource folder in order to populate the PESimu-Select HTTP simulation selector
 with the proper simulation choices.
 */
- (void)setCurrentScreenName:(NSString *)screenName;

#pragma mark - Properties

/**
 * The current top view controller of the application.
 */
@property (nonatomic) UIViewController *currentTopController;


@end
