//
//  SSELSimulationTableCell.m
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

#import "SSELSimulationTableCell.h"
#import <PEObjc-Commons/PEUIUtils.h>

@implementation SSELSimulationTableCell {
  UITextField *_requestLatencyTf;
  UITextField *_responseLatencyTf;
  UILabel *_titleLbl;
  UILabel *_descriptionLbl;
}

#pragma mark - Initializers

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:UITableViewCellStyleDefault
              reuseIdentifier:reuseIdentifier];
  if (self) {
    _requestLatencyTf = [self latencyTextField];
    _responseLatencyTf = [self latencyTextField];
    UIView *contentView = [self contentView];
    CGSize titleLblSize =
    [PEUIUtils sizeOfText:@""
                 withFont:[SSELSimulationTableCell fontForCellTitle]];
    _titleLbl =
    [[UILabel alloc]
     initWithFrame:CGRectMake(5,
                              10,
                              titleLblSize.width,
                              titleLblSize.height)];
    [_titleLbl setFont:[UIFont boldSystemFontOfSize:14]];
    [contentView addSubview:_titleLbl];
    
    _descriptionLbl =
    [PEUIUtils labelWithKey:@""
                       font:[SSELSimulationTableCell fontForCellDescription]
            backgroundColor:[UIColor clearColor]
                  textColor:[UIColor blackColor]
        verticalTextPadding:7];
    [PEUIUtils placeView:_descriptionLbl
                   below:_titleLbl
                    onto:contentView
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:7.5
                hpadding:0];
    
    UILabel *reqLatencyLbl =
    [PEUIUtils labelWithKey:[SSELSimulationTableCell requestLatencyLabelText]
                       font:[SSELSimulationTableCell fontForLatencyLabels]
            backgroundColor:[UIColor clearColor]
                  textColor:[UIColor blackColor]
        verticalTextPadding:0];
    [PEUIUtils placeView:reqLatencyLbl
                   below:_descriptionLbl
                    onto:contentView
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:10.0
                hpadding:0];
    [PEUIUtils placeView:_requestLatencyTf
            toTheRightOf:reqLatencyLbl
                    onto:contentView
           withAlignment:PEUIVerticalAlignmentTypeMiddle
                hpadding:3.0];
    
    UILabel *respLatencyLbl =
    [PEUIUtils labelWithKey:[SSELSimulationTableCell responseLatencyLabelText]
                       font:[SSELSimulationTableCell fontForLatencyLabels]
            backgroundColor:[UIColor clearColor]
                  textColor:[UIColor blackColor]
        verticalTextPadding:0];
    [PEUIUtils placeView:respLatencyLbl
            toTheRightOf:_requestLatencyTf
                    onto:contentView
           withAlignment:PEUIVerticalAlignmentTypeMiddle
                hpadding:3.0];
    [PEUIUtils placeView:_responseLatencyTf
            toTheRightOf:respLatencyLbl
                    onto:contentView
           withAlignment:PEUIVerticalAlignmentTypeMiddle
                hpadding:3.0];
  }
  return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
  [super setSelected:selected animated:animated];
  // thank you: http://stackoverflow.com/questions/7053340/why-do-all-backgrounds-disappear-on-uitableviewcell-select
  [_requestLatencyTf setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
  [_responseLatencyTf setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
}

#pragma mark - Helpers

+ (NSString *)requestLatencyLabelText {
  return @"Req latency:";
}

+ (NSString *)responseLatencyLabelText {
  return @"Resp latency:";
}

+ (UIFont *)fontForCellTitle {
  return [UIFont boldSystemFontOfSize:14];
}

+ (UIFont *)fontForCellDescription {
  return [UIFont systemFontOfSize:12];
}

+ (UIFont *)fontForLatencyLabels {
  return [UIFont systemFontOfSize:12];
}

- (UITextField *)latencyTextField {
  UITextField *tf = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 45, 22)];
  [tf setText:@""];
  UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 10)];
  [tf setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
  [tf setLeftView:paddingView];
  [tf setLeftViewMode:UITextFieldViewModeAlways];
  [tf setAutocorrectionType:UITextAutocorrectionTypeNo];
  [tf setFont:[UIFont systemFontOfSize:12]];
  return tf;
}

#pragma mark - Methods

- (void)bindSimulation:(SSELSimulation *)simulation {
  _simulation = simulation;
  NSString *title = [[simulation httpResponse] name];
  NSString *description = [[simulation httpResponse] responseDescription];
  if ([simulation requestLatency] > 0) {
    [_requestLatencyTf
     setText:[NSString stringWithFormat:@"%ld", (long)[simulation requestLatency]]];
  }
  if ([simulation responseLatency] > 0) {
    [_responseLatencyTf
     setText:[NSString stringWithFormat:@"%ld", (long)[simulation responseLatency]]];
  }
  [PEUIUtils setTextAndResize:title forLabel:_titleLbl];
  [PEUIUtils setTextAndResize:description forLabel:_descriptionLbl];
}

- (void)bindLatencies {
  [_simulation setRequestLatency:[[_requestLatencyTf text] intValue]];
  [_simulation setResponseLatency:[[_responseLatencyTf text] intValue]];
}

- (void)clearLatencies {
  [_requestLatencyTf setText:@""];
  [_responseLatencyTf setText:@""];
  [_simulation setRequestLatency:0];
  [_simulation setResponseLatency:0];
}

#pragma mark - Helpers

+ (CGFloat)tableCellHeightForSimulation:(SSELSimulation *)simulation {
  int computedHeight = 0;
  computedHeight +=
    [PEUIUtils sizeOfText:[[simulation httpResponse] name]
                 withFont:[self fontForCellTitle]].height;
  computedHeight +=
    [PEUIUtils sizeOfText:[[simulation httpResponse] description]
                 withFont:[self fontForCellDescription]].height;
  computedHeight +=
    [PEUIUtils sizeOfText:[self requestLatencyLabelText]
                 withFont:[self fontForLatencyLabels]].height;
  return computedHeight;
}

@end
