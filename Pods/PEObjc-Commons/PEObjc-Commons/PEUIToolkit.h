//
// PEUIToolkit.h
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef UIButton * (^ButtonMaker)(NSString *, id, SEL);
typedef UILabel * (^LabelMaker)(NSString *, CGFloat);
typedef UITextField * (^TextfieldMaker)(NSString *);
typedef UITextField * (^TaggedTextfieldMaker)(NSString *, NSInteger);
typedef UIView * (^PanelMaker)(CGFloat);
typedef UIFont * (^FontMaker)(void);

/**
 A simple container-like abstraction for encapsulating styling information that
 would be used within the scope of an iOS application.  An instance of this class
 is intended to be instantiated once (within an application delegate), and passed
 along as a parameter to each instantiated view controller, so the view controller
 can use it when styling its views.
 */
@interface PEUIToolkit : NSObject

///------------------------------------------------
/// @name Initialization
///------------------------------------------------
#pragma mark - Initialization

- (id)initWithColorForContentPanels:(UIColor *)colorForContentPanels
                    colorForWindows:(UIColor *)colorForWindows
   topBottomPaddingForContentPanels:(CGFloat)topBottomPaddingForContentPanels
                        accentColor:(UIColor *)accentColor
                  fontForButtonsBlk:(FontMaker)fontForButtonsBlk
          verticalPaddingForButtons:(CGFloat)verticalPaddingForButtons
        horizontalPaddingForButtons:(CGFloat)horizontalPaddingForButtons
               fontForTextfieldsBlk:(FontMaker)fontForTextfieldsBlk
                 colorForTextfields:(UIColor *)colorForTextfields
          heightFactorForTextfields:(CGFloat)heightFactorForTextfields
       leftViewPaddingForTextfields:(CGFloat)leftViewPaddingForTextfields
          fontForTableCellTitlesBlk:(FontMaker)fontForTableCellTitlesBlk
            colorForTableCellTitles:(UIColor *)colorForTableCellTitles
       fontForTableCellSubtitlesBlk:(FontMaker)fontForTableCellSubtitlesBlk
         colorForTableCellSubtitles:(UIColor *)colorForTableCellSubtitles;

#pragma mark - Color Properties

@property (nonatomic, readonly) UIColor *colorForContentPanels;

@property (nonatomic, readonly) UIColor *colorForWindows;

@property (nonatomic, readonly) UIColor *accentColor;

@property (nonatomic, readonly) UIColor *colorForTextfields;

@property (nonatomic, readonly) UIColor *colorForTableCellTitles;

@property (nonatomic, readonly) UIColor *colorForTableCellSubtitles;

#pragma mark - Button-specific Properties

@property (nonatomic, readonly) CGFloat cornerRadiusForButtons;

@property (nonatomic, readonly) CGFloat verticalPaddingForButtons;

@property (nonatomic, readonly) CGFloat horizontalPaddingForButtons;

#pragma mark - Padding Properties

@property (nonatomic, readonly) CGFloat topBottomPaddingForContentPanels;

@property (nonatomic, readonly) CGFloat leftViewPaddingForTextfields;

@property (nonatomic, readonly) CGFloat heightFactorForTextfields;

#pragma mark - Font Makers

- (FontMaker)fontForButtonsBlk;

- (FontMaker)fontForTextfieldsBlk;

- (FontMaker)fontForTableCellTitlesBlk;

- (FontMaker)fontForTableCellSubtitlesBlk;

#pragma mark - Panel makers

- (PanelMaker)contentPanelMakerRelativeTo:(UIView *)relativeToView;

- (PanelMaker)accentPanelMakerRelativeTo:(UIView *)relativeToView;

#pragma mark - Button makers

- (ButtonMaker)systemButtonMaker;

#pragma mark - Label makers

- (LabelMaker)tableCellTitleMaker;

- (LabelMaker)tableCellSubtitleMaker;

#pragma mark - Text TextField makers

- (TextfieldMaker)textfieldMakerForFixedWidth:(CGFloat)width;

- (TextfieldMaker)textfieldMakerForWidthOf:(CGFloat)percentage
                                relativeTo:(UIView *)relativeToView;

- (TaggedTextfieldMaker)taggedTextfieldMakerForFixedWidth:(CGFloat)width;

- (TaggedTextfieldMaker)taggedTextfieldMakerForWidthOf:(CGFloat)percentage
                                            relativeTo:(UIView *)relativeToView;

#pragma mark - Resizing

- (void)adjustHeightToFitSubviewsForContentPanel:(UIView *)panel;

@end
