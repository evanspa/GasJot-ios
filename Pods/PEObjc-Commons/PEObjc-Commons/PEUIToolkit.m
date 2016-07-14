//
// PEUIToolkit.m
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

#import "PEUIUtils.h"
#import "PEUIToolkit.h"

@implementation PEUIToolkit {
  FontMaker _fontForButtonsBlk;
  FontMaker _fontForTextfieldsBlk;
  FontMaker _fontForTableCellTitlesBlk;
  FontMaker _fontForTableCellSubtitlesBlk;
}

#pragma mark - Initializers

- (id)initWithColorForContentPanels:(UIColor *)colorForContentPanels
                    colorForWindows:(UIColor *)colorForWindows
   topBottomPaddingForContentPanels:(CGFloat)topBottomPaddingForContentPanels
                        accentColor:(UIColor *)accentColor
                  fontForButtonsBlk:(UIFont *(^)(void))fontForButtonsBlk
          verticalPaddingForButtons:(CGFloat)verticalPaddingForButtons
        horizontalPaddingForButtons:(CGFloat)horizontalPaddingForButtons
               fontForTextfieldsBlk:(UIFont *(^)(void))fontForTextfieldsBlk
                 colorForTextfields:(UIColor *)colorForTextfields
          heightFactorForTextfields:(CGFloat)heightFactorForTextfields
       leftViewPaddingForTextfields:(CGFloat)leftViewPaddingForTextfields
          fontForTableCellTitlesBlk:(UIFont *(^)(void))fontForTableCellTitlesBlk
            colorForTableCellTitles:(UIColor *)colorForTableCellTitles
       fontForTableCellSubtitlesBlk:(UIFont *(^)(void))fontForTableCellSubtitlesBlk
         colorForTableCellSubtitles:(UIColor *)colorForTableCellSubtitles {
  self = [super init];
  if (self) {
    _colorForContentPanels = colorForContentPanels;
    _colorForWindows = colorForWindows;
    _topBottomPaddingForContentPanels = topBottomPaddingForContentPanels;
    _accentColor = accentColor;
    _fontForButtonsBlk = fontForButtonsBlk;
    _verticalPaddingForButtons = verticalPaddingForButtons;
    _horizontalPaddingForButtons = horizontalPaddingForButtons;
    _fontForTextfieldsBlk = fontForTextfieldsBlk;
    _colorForTextfields = colorForTextfields;
    _leftViewPaddingForTextfields = leftViewPaddingForTextfields;
    _heightFactorForTextfields = heightFactorForTextfields;
    _fontForTableCellTitlesBlk = fontForTableCellTitlesBlk;
    _colorForTableCellTitles = colorForTableCellTitles;
    _fontForTableCellSubtitlesBlk = fontForTableCellSubtitlesBlk;
    _colorForTableCellSubtitles = colorForTableCellSubtitles;
  }
  return self;
}

#pragma mark - Font Makers

- (FontMaker)fontForButtonsBlk {
  return _fontForButtonsBlk;
}

- (FontMaker)fontForTextfieldsBlk {
  return _fontForTextfieldsBlk;
}

- (FontMaker)fontForTableCellTitlesBlk {
  return _fontForTableCellTitlesBlk;
}

- (FontMaker)fontForTableCellSubtitlesBlk {
  return _fontForTableCellSubtitlesBlk;
}

#pragma mark - Panel makers

- (PanelMaker)contentPanelMakerRelativeTo:(UIView *)relativeToView {
  return ^(CGFloat ofWidth) {
    UIView *panel = [PEUIUtils panelWithWidthOf:ofWidth
                                 relativeToView:relativeToView
                                    fixedHeight:0];
    [panel setBackgroundColor:[self colorForContentPanels]];
    return panel;
  };
}

- (PanelMaker)accentPanelMakerRelativeTo:(UIView *)relativeToView {
  return ^(CGFloat ofWidth) {
    UIView *panel = [PEUIUtils panelWithWidthOf:ofWidth
                                 relativeToView:relativeToView
                                    fixedHeight:0];
    [panel setBackgroundColor:[self accentColor]];
    return panel;
  };
}

#pragma mark - Button makers

- (ButtonMaker)systemButtonMaker {
  return ^(NSString *key, id target, SEL action) {
    return [PEUIUtils buttonWithKey:key
                               font:_fontForButtonsBlk()
                    backgroundColor:[UIColor whiteColor]
                          textColor:[UIColor darkTextColor]
       disabledStateBackgroundColor:[UIColor whiteColor]
             disabledStateTextColor:[UIColor grayColor]
                    verticalPadding:[self verticalPaddingForButtons]
                  horizontalPadding:[self horizontalPaddingForButtons]
                       cornerRadius:0.0
                             target:target
                             action:action];
  };
}

#pragma mark - Label makers

- (LabelMaker)tableCellTitleMaker {
  return ^(NSString *key, CGFloat fitToWidth) {
    return [PEUIUtils labelWithKey:key
                              font:_fontForTableCellTitlesBlk()
                   backgroundColor:[UIColor clearColor]
                         textColor:[self colorForTableCellTitles]
               verticalTextPadding:0
                        fitToWidth:fitToWidth];
  };
}

- (LabelMaker)tableCellSubtitleMaker {
  return ^(NSString *key, CGFloat fitToWidth) {
    return [PEUIUtils labelWithKey:key
                              font:_fontForTableCellSubtitlesBlk()
                   backgroundColor:[UIColor clearColor]
                         textColor:[self colorForTableCellSubtitles]
               verticalTextPadding:5
                        fitToWidth:fitToWidth];
  };
}

#pragma mark - Text TextField makers

- (TextfieldMaker)textfieldMakerForFixedWidth:(CGFloat)width {
  return ^(NSString *key) {
    return [PEUIUtils textfieldWithPlaceholderTextKey:key
                                                 font:_fontForTextfieldsBlk()
                                      backgroundColor:[self colorForTextfields]
                                      leftViewPadding:[self leftViewPaddingForTextfields]
                                           fixedWidth:width
                                         heightFactor:[self heightFactorForTextfields]];
  };
}

- (TextfieldMaker)textfieldMakerForWidthOf:(CGFloat)percentage
                                relativeTo:(UIView *)relativeToView {
  CGFloat width = percentage * [relativeToView frame].size.width;
  return [self textfieldMakerForFixedWidth:width];
}

- (TaggedTextfieldMaker)taggedTextfieldMakerForFixedWidth:(CGFloat)width {
  return ^UITextField *(NSString *key, NSInteger tag) {
    UITextField *tf =
    [PEUIUtils textfieldWithPlaceholderTextKey:key
                                          font:_fontForTextfieldsBlk()
                               backgroundColor:[self colorForTextfields]
                               leftViewPadding:[self leftViewPaddingForTextfields]
                                    fixedWidth:width
                                  heightFactor:[self heightFactorForTextfields]];
    [tf setTag:tag];
    return tf;
  };
}

- (TaggedTextfieldMaker)taggedTextfieldMakerForWidthOf:(CGFloat)percentage
                                            relativeTo:(UIView *)relativeToView {
  CGFloat width = percentage * [relativeToView frame].size.width;
  return [self taggedTextfieldMakerForFixedWidth:width];
}

#pragma mark - Resizing

- (void)adjustHeightToFitSubviewsForContentPanel:(UIView *)panel {
  [PEUIUtils
   adjustHeightToFitSubviewsForView:panel
   bottomPadding:[self topBottomPaddingForContentPanels]];
}

@end
