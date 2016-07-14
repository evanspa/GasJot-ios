//
//  PDVScreenGroup.h
//  dev-console
//
//  Created by Evans, Paul on 6/18/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PDVScreen.h"

@interface PDVScreenGroup : NSObject

#pragma mark - Initializers

- (id)initWithName:(NSString *)name screens:(NSArray *)screens;

#pragma mark - Properties

@property (nonatomic, readonly) NSString *name;

@property (nonatomic, readonly) NSArray *screens;

#pragma mark - Methods

- (NSUInteger)count;

- (PDVScreen *)screenAtIndex:(NSInteger)index;

@end
