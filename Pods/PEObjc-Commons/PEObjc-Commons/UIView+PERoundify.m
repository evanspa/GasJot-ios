//
//  UIView+PERoundify.m
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

#import "UIView+PERoundify.h"

@implementation UIView (PERoundify)

-(void)addRoundedCorners:(UIRectCorner)corners withRadii:(CGSize)radii {
  CALayer *tMaskLayer = [self maskForRoundedCorners:corners withRadii:radii];
  self.layer.mask = tMaskLayer;
}

-(CALayer*)maskForRoundedCorners:(UIRectCorner)corners withRadii:(CGSize)radii {
  CAShapeLayer *maskLayer = [CAShapeLayer layer];
  maskLayer.frame = self.bounds;
  UIBezierPath *roundedPath = [UIBezierPath bezierPathWithRoundedRect:
                               maskLayer.bounds byRoundingCorners:corners cornerRadii:radii];
  maskLayer.fillColor = [[UIColor whiteColor] CGColor];
  maskLayer.backgroundColor = [[UIColor clearColor] CGColor];
  maskLayer.path = [roundedPath CGPath];
  return maskLayer;
}

@end
