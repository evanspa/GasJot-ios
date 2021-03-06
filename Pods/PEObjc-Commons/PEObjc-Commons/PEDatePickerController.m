//
// PEDatePickerController.m
//
// Copyright (c) 2014-2015 PEObjc-Commons
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

#import "PEDatePickerController.h"

@implementation PEDatePickerController {
  NSDate *_initialDate;
  CGFloat _heightPercentage;
  UIDatePicker *_datePicker;
  NSString *_title;
  void (^_logDatePickedAction)(NSDate *);
}

#pragma mark - Initializers

- (id)initWithTitle:(NSString *)title
   heightPercentage:(CGFloat)heightPercentage
        initialDate:(NSDate *)initialDate
logDatePickedAction:(void(^)(NSDate *))logDatePickedAction {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _title = title;
    _heightPercentage = heightPercentage;
    _initialDate = initialDate;
    _logDatePickedAction = logDatePickedAction;
  }
  return self;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[UIColor whiteColor]];
  [[self navigationItem] setTitle:_title];
  _datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0,
                                                               80,
                                                               self.view.frame.size.width,
                                                               (_heightPercentage * self.view.frame.size.height))];
  [_datePicker setDatePickerMode:UIDatePickerModeDate];
  [_datePicker setDate:_initialDate animated:YES];
  [[self view] addSubview:_datePicker];
}

-(void)viewWillDisappear:(BOOL)animated {
  _logDatePickedAction([_datePicker date]);
  [super viewWillDisappear:animated];
}

@end