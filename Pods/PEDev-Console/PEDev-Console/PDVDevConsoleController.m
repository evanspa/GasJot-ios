//
//  PDVDevConsoleController.m
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

#import "PDVDevConsoleController.h"
#import "PDVScreenSelectionController.h"
#import <PEObjc-Commons/PEUIUtils.h>
#import <PEObjc-Commons/PEUIToolkit.h>
#import "PDVMacros.h"

@implementation PDVDevConsoleController {
  SSELUtils *_sselUtils;
  NSArray *_screenGroups;
  PDVUtils *_pdvUtils;
}

#pragma mark - Initializers

- (id)initWithSSELUtils:(SSELUtils *)sselUtils
               pdvUtils:(PDVUtils *)pdvUtils
           screenGroups:(NSArray *)screenGroups {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _sselUtils = sselUtils;
    _pdvUtils = pdvUtils;
    _screenGroups = screenGroups;
    [_sselUtils setOntoViewController:self];
    [self setTitle:@"PEDev-Console"];
  }
  return self;
}

#pragma mark UIViewController lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  PEUIToolkit *uitoolkit = [self defaultUIToolkit];
  [[self view] setBackgroundColor:[uitoolkit colorForWindows]];
  ButtonMaker btnMaker = [uitoolkit systemButtonMaker];
  [[self view] setBackgroundColor:[UIColor lightGrayColor]];
  UIButton *screensBtn = btnMaker(PDVLS(@"devconsole.screens.btn.txt"), self, @selector(presentScreens));
  [PEUIUtils placeView:screensBtn
            inMiddleOf:[self view]
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              hpadding:0.0];
  [PEUIUtils placeView:btnMaker(PDVLS(@"devconsole.simulations.btn.txt"), self, @selector(presentSimulations))
                 below:screensBtn
                  onto:[self view]
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:20.0
              hpadding:0.0];
}

#pragma mark - Button event handlers

- (void)presentScreens {
  PDVScreenSelectionController *screenSelectionCtrl =
    [[PDVScreenSelectionController alloc] initWithScreenGroups:_screenGroups
                                                      pdvUtils:_pdvUtils];
  [[self navigationController] pushViewController:screenSelectionCtrl animated:YES];
}

- (void)presentSimulations {
  [_sselUtils toggleSimulationsSelectorOn];
}

#pragma mark - UI Toolkit maker

- (PEUIToolkit *)defaultUIToolkit {
  return [[PEUIToolkit alloc] initWithColorForContentPanels:nil
                                            colorForWindows:nil
                           topBottomPaddingForContentPanels:15
                                                accentColor:nil
                                          fontForButtonsBlk:^{ return [UIFont systemFontOfSize:[UIFont buttonFontSize]]; }
                                  verticalPaddingForButtons:10
                                horizontalPaddingForButtons:20
                                       fontForTextfieldsBlk:^{ return [UIFont systemFontOfSize:16]; }
                                         colorForTextfields:[UIColor whiteColor]
                                  heightFactorForTextfields:1.75
                               leftViewPaddingForTextfields:10
                                  fontForTableCellTitlesBlk:^{ return [UIFont systemFontOfSize:16]; }
                                    colorForTableCellTitles:[UIColor blackColor]
                               fontForTableCellSubtitlesBlk:^{ return [UIFont systemFontOfSize:12]; }
                                 colorForTableCellSubtitles:[UIColor grayColor]];
}

@end
