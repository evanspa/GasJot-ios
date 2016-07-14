//
//  PDVScreenSelectionController.m
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

#import "PDVScreenSelectionController.h"
#import "PDVScreen.h"
#import "PDVScreenGroup.h"
#import <PEObjc-Commons/PEUIUtils.h>
#import "PDVMacros.h"

@implementation PDVScreenSelectionController {
  NSArray *_screenGroups;
  PDVUtils *_pdvUtils;
}

#pragma mark - Initializers

- (id)initWithScreenGroups:(NSArray *)screenGroups
                  pdvUtils:(PDVUtils *)pdvUtils {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _screenGroups = screenGroups;
    _pdvUtils = pdvUtils;
  }
  return self;
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
  [self setTitle:PDVLS(@"devconsole.screenselector.title.txt")];
  [[self view] addSubview:tableView];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return [_screenGroups count];
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
  return [[_screenGroups objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString *reuseIdent = @"UITableViewCell";
  UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:reuseIdent];
  if (!cell) {
    PDVScreen *screen = [self screenAtIndexPath:indexPath];
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                  reuseIdentifier:reuseIdent];
    [[cell textLabel] setText:[screen displayName]];
    [[cell detailTextLabel] setText:[screen screenDescription]];
    [[cell detailTextLabel] setNumberOfLines:0];
    [[cell detailTextLabel] setLineBreakMode:NSLineBreakByWordWrapping];
  }
  return cell;
}

- (NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section {
  return [[_screenGroups objectAtIndex:section] name];
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  PDVScreen *screen = [self screenAtIndexPath:indexPath];
  [self presentViewController:[screen viewControllerMaker]()
                     animated:YES
                   completion:nil];
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  PDVScreen *screen = [self screenAtIndexPath:indexPath];
  return [PEUIUtils heightForText:[screen description]
                         forWidth:[tableView frame].size.width] + 45;
}

#pragma mark - Helpers

- (PDVScreen *)screenAtIndexPath:(NSIndexPath *)indexPath {
  PDVScreenGroup *screenGroup = [_screenGroups objectAtIndex:[indexPath section]];
  return [screenGroup screenAtIndex:[indexPath row]];
}

@end
