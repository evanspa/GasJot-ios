//
//  PDVUtils.m
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

#import "PDVUtils.h"
#import "PDVNotificationNames.h"
#import "PDVDevConsoleController.h"
#import <PESimu-Select/SSELUtils.h>
#import <PEObjc-Commons/PEUIUtils.h>
//#import <PPTopMostController/UIViewController+PPTopMostController.h>

@implementation PDVUtils {
  SSELUtils *_sselUtils;
  PDVDevConsoleController *_devConsoleController;
  NSArray *_screenGroups;  
}

#pragma mark - Initialization

- (id)initWithBaseResourceFolderOfSimulations:(NSString *)baseResourceFolder
                                 screenGroups:(NSArray *)screenGroups {
  self = [super init];
  if (self) {
    _screenGroups = screenGroups;
    _sselUtils = [SSELUtils utilsWithBaseResourceFolder:baseResourceFolder];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(toggleDevConsoleOn)
                                                 name:PdvShakeGesture
                                               object:nil];
  }
  return self;
}

#pragma mark - Setters

- (void)setCurrentTopController:(UIViewController *)currentTopController {
  _currentTopController = currentTopController;
  id<PDVDevEnabled> devEnabledAppDelegate =
    (id<PDVDevEnabled>)[[UIApplication sharedApplication] delegate];
  [self setCurrentScreenName:[PDVUtils nameForViewController:currentTopController
                                               forDevEnabled:devEnabledAppDelegate]];
}

#pragma mark - Setting the current screen name

- (void)setCurrentScreenName:(NSString *)screenName {
  [_sselUtils setScreenName:screenName];
}

#pragma mark - Show Dev Console

- (void)toggleDevConsoleOn {
  _devConsoleController =[[PDVDevConsoleController alloc] initWithSSELUtils:_sselUtils
                                                                   pdvUtils:self
                                                               screenGroups:_screenGroups];
  UINavigationController *navCtrl =
    [PEUIUtils navigationControllerWithController:_devConsoleController];
  UIBarButtonItem *doneButton =
    [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                     style:UIBarButtonItemStyleDone
                                    target:self
                                    action:@selector(dismissDevConsole)];
  [[[navCtrl topViewController] navigationItem] setRightBarButtonItem:doneButton];
  [navCtrl setNavigationBarHidden:NO];
  [_currentTopController presentViewController:navCtrl animated:YES completion:nil];
}

#pragma mark - Dismiss Dev Console

- (void)dismissDevConsole {
  [_devConsoleController dismissViewControllerAnimated:NO
                                            completion:nil];
}

#pragma mark - Helpers

+ (NSString *)nameForViewController:(UIViewController *)viewController
                      forDevEnabled:(id<PDVDevEnabled>)devEnabled {
  return [PDVUtils nameForViewControllerClass:[viewController class]
                                forDevEnabled:devEnabled];
}

+ (NSString *)nameForViewControllerClass:(Class)viewControllerClass
                           forDevEnabled:(id<PDVDevEnabled>)devEnabled {
  NSDictionary *screenNames = [devEnabled screenNamesForViewControllers];
  return [screenNames objectForKey:NSStringFromClass(viewControllerClass)];
}

@end
