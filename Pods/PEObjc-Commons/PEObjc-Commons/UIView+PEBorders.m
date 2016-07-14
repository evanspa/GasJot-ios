//
//  PEBorders.m
//  PEObjc-Commons
//
//  Created by Paul Evans on 12/25/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "UIView+PEBorders.h"
@import QuartzCore;

@implementation UIView (PEBorders)

- (void)addTopBorderWithColor:(UIColor *)color andWidth:(CGFloat) borderWidth {
  CALayer *border = [CALayer layer];
  border.backgroundColor = color.CGColor;
  border.frame = CGRectMake(0, 0, self.frame.size.width, borderWidth);
  [self.layer addSublayer:border];
}

- (void)addBottomBorderWithColor:(UIColor *)color andWidth:(CGFloat) borderWidth {
  CALayer *border = [CALayer layer];
  border.backgroundColor = color.CGColor;
  border.frame = CGRectMake(0, self.frame.size.height - borderWidth, self.frame.size.width, borderWidth);
  [self.layer addSublayer:border];
}

- (void)addLeftBorderWithColor:(UIColor *)color andWidth:(CGFloat) borderWidth {
  CALayer *border = [CALayer layer];
  border.backgroundColor = color.CGColor;
  border.frame = CGRectMake(0, 0, borderWidth, self.frame.size.height);
  [self.layer addSublayer:border];
}

- (void)addRightBorderWithColor:(UIColor *)color andWidth:(CGFloat) borderWidth {
  CALayer *border = [CALayer layer];
  border.backgroundColor = color.CGColor;  
  border.frame = CGRectMake(self.frame.size.width - borderWidth, 0, borderWidth, self.frame.size.height);
  [self.layer addSublayer:border];
}

@end
