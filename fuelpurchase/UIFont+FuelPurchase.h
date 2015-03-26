// Copyright (C) 2013 Paul Evans
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

#import <UIKit/UIKit.h>

/**
 Adds new standard fonts specific to this FuelPurchase application.
 */
@interface UIFont (FuelPurchase)

/**
 @return The font intended to be used for all section headings
 */
+ (UIFont *) fp_sectionHeadingFont;

/**
 @return The font intended to be used for all bolded sub-section headings
 */
+ (UIFont *) fp_subSectionHeadingFont;

/**
 @return The font intended to be used for all non-bolded sub-section headings
 */
+ (UIFont *) fp_subSectionHeadingFontNonBold;

/**
 @return The font intended to be used for all button labels
 */
+ (UIFont *)fp_buttonFont;

@end
