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
 Adds new standard colors specific to this FuelPurchase application.
 */
@interface UIColor (FuelPurchase)

/**
 @return The font color intended to be used for all section headings
 */
+ (UIColor *)fp_sectionHeadingTextColor;

/**
 @return The font color intended to be used for all sub-section headings
 */
+ (UIColor *)fp_subSectionHeadingTextColor;

/**
 @return The color characterizing the overall theme of the application; this
         color should be used for backgrounds when specific screen-specific
         colors have not been defined
 */
+ (UIColor *)fp_themeColor;

/**
 @return The background color used for the 'create account' screen
 */
+ (UIColor *)fp_createAcctColor;

@end
