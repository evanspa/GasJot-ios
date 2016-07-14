//
//  SSELSimulation.h
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
#import <PEWire-Control/PEHttpResponse.h>

/**
 A mutable abstraction modeling a discrete HTTP response simulation, including
 request and response latencies.  A simulation can be enabled (selected) or not.
 */
@interface SSELSimulation : NSObject

#pragma mark - Initializers

/**
 Creates and initializations a new instance with the given HTTP response
 object.
 @param httpResponse Fake HTTP response.
 @return Initialized simulation instance.
 */
- (id)initWithHttpResponse:(PEHttpResponse *)httpResponse;

#pragma mark - Methods

/**
 Toggles this simulation to be enabled / disabled.
 */
- (void)toggleSelected;

#pragma mark - Properties

/**
 Whether or not this simulation is enabled (aka active/selected).
 */
@property (nonatomic) BOOL selected;

/**
 Request latency (time for an HTTP request to reach its endpoint) to simulate,
 in seconds.
 */
@property (nonatomic) NSInteger requestLatency;

/**
 Response latency (time for the HTTP response to return) to simulate, in
 seconds.
 */
@property (nonatomic) NSInteger responseLatency;

/**
 HTTP response that will be used for this simulation.
 */
@property (nonatomic, readonly) PEHttpResponse *httpResponse;

@end
