//
//  NSMutableArray+MoveObject.h
//  fuelpurchase
//
//  Created by Evans, Paul on 1/21/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (MoveObject)

- (void)moveObjectFromIndex:(NSUInteger)from toIndex:(NSUInteger)to;

@end
