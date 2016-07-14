//
//  SSELUseCase.h
//
// Copyright (c) 2014-2015 PESimu-Select
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

/**
 Models a use case that can be simulated.
 */
@interface SSELUseCase : NSObject

#pragma mark - Initializers

/**
 Initializes a new use case instance.
 @param name The name to give to this use case.
 @param simulations The set of simulations associated with this use case.
 @return An initialized case instance.
 */
- (id)initWithName:(NSString *)name
       simulations:(NSArray *)simulations;

#pragma mark - Methods

/** De-selects all of the simulations. */
- (void)deselectAllSimulations;

#pragma mark - Properties

/** The name of this use case. */
@property (nonatomic, readonly) NSString *name;

/** The simulations associated with this use case. */
@property (nonatomic, readonly) NSArray *simulations;

@end
