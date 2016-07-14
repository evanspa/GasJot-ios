//
//  UIScrollView+PEAdditions.m
//  PELocal-DataUI
//
//  Created by Evans, Paul on 2/19/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import "UIScrollView+PEAdditions.h"

@implementation UIScrollView (PEAdditions)

- (BOOL)isAtTop {
  return (self.contentOffset.y <= [self verticalOffsetForTop]);
}

- (BOOL)isAtBottom {
  return (self.contentOffset.y >= [self verticalOffsetForBottom]);
}

- (CGFloat)verticalOffsetForTop {
  CGFloat topInset = self.contentInset.top;
  return -topInset;
}

- (CGFloat)verticalOffsetForBottom {
  CGFloat scrollViewHeight = self.bounds.size.height;
  CGFloat scrollContentSizeHeight = self.contentSize.height;
  CGFloat bottomInset = self.contentInset.bottom;
  CGFloat scrollViewBottomOffset = scrollContentSizeHeight + bottomInset - scrollViewHeight;
  return scrollViewBottomOffset;
}

@end
