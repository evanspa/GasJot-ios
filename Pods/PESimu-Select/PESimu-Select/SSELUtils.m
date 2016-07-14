//
//  SSELUtils.m
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

#import <PEWire-Control/PEHttpResponseUtils.h>
#import <PEWire-Control/PEHttpResponseSimulator.h>
#import <PEObjc-Commons/PEUIUtils.h>
#import "SSELUtils.h"
#import "SSELUseCase.h"
#import "SSELSimulation.h"
#import "SSELNotificationNames.h"
#import "SSELSimulationSelectionController.h"

@implementation SSELUtils {
  NSMutableDictionary *_screens;
  SSELSimulationSelectionController *_simSelCtrl;
  BOOL _simulationSelectorToggled;
}

#pragma mark - Initializers

- (id)initWithBaseResourceFolder:(NSString *)baseResourceFolder {
  self = [super init];
  if (self) {
    _baseResourceFolder = baseResourceFolder;
    _screens = [[NSMutableDictionary alloc] init];
    _simulationSelectorToggled = NO;
  }
  return self;
}

#pragma mark - Private Helpers

+ (NSArray *)usecaseSimulationsFromPath:(NSString *)path
                  pathsRelativeToBundle:(NSBundle *)bundle {
  NSMutableArray *usecaseSimulations = [[NSMutableArray alloc] init];
  NSFileManager *fm = [NSFileManager defaultManager];
  NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.xml'"];
  NSArray *usecaseSimulationXmlFiles = [[fm contentsOfDirectoryAtPath:path error:nil] filteredArrayUsingPredicate:fltr];
  [usecaseSimulationXmlFiles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSString *mockResponsePath = [path stringByAppendingPathComponent:obj];
    NSData *mockResponseData = [fm contentsAtPath:mockResponsePath];
    NSString *mockResponseStr = [[NSString  alloc] initWithData:mockResponseData encoding:NSUTF8StringEncoding];
    [usecaseSimulations addObject:[[SSELSimulation alloc] initWithHttpResponse:[PEHttpResponseUtils mockResponseFromXml:mockResponseStr
                                                                                                  pathsRelativeToBundle:bundle]]];
  }];
  return usecaseSimulations;
}

#pragma mark - Helpers

+ (NSArray *)usecasesForScreen:(NSString *)screen
        fromBaseResourceFolder:(NSString *)resourceFolder {
  NSFileManager *fm = [NSFileManager defaultManager];
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  NSString *bundlePath = [bundle bundlePath];
  NSString *baseResourceFldrPath = [bundlePath stringByAppendingPathComponent:resourceFolder];
  NSString *fullPath = [baseResourceFldrPath stringByAppendingPathComponent:screen];
  NSArray *usecaseFldrs = [fm contentsOfDirectoryAtPath:fullPath error:nil];
  NSMutableArray *usecases = [[NSMutableArray alloc] initWithCapacity:[usecaseFldrs count]];
  [usecaseFldrs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSString *simulationsPath = [fullPath stringByAppendingPathComponent:obj];
    NSArray *usecaseSimulations = [SSELUtils usecaseSimulationsFromPath:simulationsPath
                                                  pathsRelativeToBundle:bundle];
    SSELUseCase *usecase = [[SSELUseCase alloc] initWithName:obj simulations:usecaseSimulations];
    [usecases addObject:usecase];
  }];
  return usecases;
}

#pragma mark - Factory Functions

+ (SSELUtils *)utilsWithBaseResourceFolder:(NSString *)baseResourceFolder {
  return [[SSELUtils alloc] initWithBaseResourceFolder:baseResourceFolder];
}

#pragma mark - Toggle Simulation Selector

- (void)reactToShakeGestureForScreen:(NSString *)screenName
                  ontoViewController:(UIViewController *)viewController {
  [self setScreenName:screenName];
  [self setOntoViewController:viewController];
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(toggleSimulationsSelector)
   name:SSELShakeGesture
   object:nil];
}

- (void)addSimulationTogglerForScreen:(NSString *)screenName
                   ontoViewController:(UIViewController *)viewController {
  [self setScreenName:screenName];
  [self setOntoViewController:viewController];
  UIView *toggleSimPnl = [PEUIUtils panelWithWidthOf:0.5
                                         andHeightOf:0.2
                                      relativeToView:[[self ontoViewController] view]];
  UIButton *toggleSimsBtn = [PEUIUtils buttonWithKey:@"Toggle Simulations"
                                                font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                     backgroundColor:[UIColor blueColor]
                                           textColor:[UIColor whiteColor]
                        disabledStateBackgroundColor:[UIColor grayColor]
                              disabledStateTextColor:[UIColor grayColor]
                                     verticalPadding:15
                                   horizontalPadding:15
                                        cornerRadius:3
                                              target:self
                                              action:@selector(toggleSimulationsSelectorOn)];
  [PEUIUtils placeView:toggleSimsBtn
            inMiddleOf:toggleSimPnl
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              hpadding:0];
  [PEUIUtils placeView:toggleSimPnl
               atTopOf:[[self ontoViewController] view]
         withAlignment:PEUIHorizontalAlignmentTypeRight
              vpadding:0
              hpadding:0];
}

- (NSArray *)simulatedUsecases {
  NSArray *usecases = [_screens objectForKey:[self screenName]];
  if (!usecases) {
    usecases = [SSELUtils usecasesForScreen:[self screenName]
                     fromBaseResourceFolder:[self baseResourceFolder]];
    if ([self screenName]) {
      [_screens setObject:usecases forKey:[self screenName]];
    }
  }
  return usecases;
}

- (void)enableSelectedSimulations {
  NSArray *usecases = [self simulatedUsecases];
  [usecases enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    SSELUseCase *usecase = (SSELUseCase *)obj;
    NSArray *simulations = [usecase simulations];
    [simulations enumerateObjectsUsingBlock:^(id objInner,
                                              NSUInteger idxInnder,
                                              BOOL *stopInner) {
      SSELSimulation *simulation = (SSELSimulation *)objInner;
      if ([simulation selected]) {
        [PEHttpResponseSimulator
         simulateResponseFromMock:[simulation httpResponse]
         requestLatency:[simulation requestLatency]
         responseLatency:[simulation responseLatency]];
      }
    }];
  }];
}

#pragma Simulation Selector Toggler

- (void)toggleSimulationsSelector {
  if (_simulationSelectorToggled) {
    [self dismissSimulationSelector];
  } else {
    [self toggleSimulationsSelectorOn];
  }
}

#pragma mark - Show Simulation Selector

- (void)toggleSimulationsSelectorOn {
  NSArray *simulatedUsecases = [self simulatedUsecases];
  _simSelCtrl = [[SSELSimulationSelectionController alloc]
                 initWithUseCases:simulatedUsecases];
  UINavigationController *navCtrl =
  [PEUIUtils navigationControllerWithController:_simSelCtrl];
  UIBarButtonItem *doneButton =
  [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                   style:UIBarButtonItemStyleDone
                                  target:self
                                  action:@selector(dismissSimulationSelector)];
  [[[navCtrl topViewController] navigationItem] setRightBarButtonItem:doneButton];
  [navCtrl setNavigationBarHidden:NO];
  [[self ontoViewController] presentViewController:navCtrl
                                          animated:YES
                                        completion:nil];
  _simulationSelectorToggled = YES;
}

#pragma mark - Dismiss Simulation Selector

- (void)dismissSimulationSelector {
  [PEHttpResponseSimulator clearSimulations];
  [_simSelCtrl bindLatencies];
  [self enableSelectedSimulations];
  [_ontoViewController dismissViewControllerAnimated:YES completion:nil];
  _simulationSelectorToggled = NO;
}

@end
