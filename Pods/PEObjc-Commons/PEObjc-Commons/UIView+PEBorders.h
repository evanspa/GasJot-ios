//
//  PEBorders.h
//  PEObjc-Commons
//
//  Created by Paul Evans on 12/25/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

@import Foundation;
@import UIKit;

@interface UIView (PEBorders)

- (void)addBottomBorderWithColor: (UIColor *) color andWidth:(CGFloat) borderWidth;

- (void)addLeftBorderWithColor: (UIColor *) color andWidth:(CGFloat) borderWidth;

- (void)addRightBorderWithColor: (UIColor *) color andWidth:(CGFloat) borderWidth;

- (void)addTopBorderWithColor: (UIColor *) color andWidth:(CGFloat) borderWidth;

@end
