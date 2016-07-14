//
//  PEHttpResponseSimulator.h
//
// Copyright (c) 2014-2015 PEWire-Control
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
#import "PEHttpResponse.h"

/**
 Abstraction for simulating HTTP responses.
 */
@interface PEHttpResponseSimulator : NSObject

#pragma mark - Helpers

/**
 Helper function that converts a collection of NSHTTPCookie instances into
 a properly formatted header value to be used as the value of a single
 "Set-Cookie" header.  Each cookie will be comma-delimeted.
 @param cookies the set of cookies
 @return properly formatted string to be used in a "Set-Cookie" header
 */
+ (NSString *)cookiesToRfc2109Format:(NSArray *)cookies;

#pragma mark - Simulating an HTTP response

/**
 Simulates the HTTP response that is encoded in the given XML string.  The
 simulation will only be in effect for requests whose URL and HTTP method match
 the given parameters.
 @param xml an XML representation of the HTTP response to be simulated
 @param reqLatency simulated latency (in seconds) for the request to reach its
 endpoint
 @param respLatency simulated latency (in seconds) for the response to return
*/
+ (void)simulateResponseFromXml:(NSString *)xml
          pathsRelativeToBundle:(NSBundle *)bundle
                 requestLatency:(NSUInteger)reqLatency
                responseLatency:(NSUInteger)respLatency;

/**
 Simulates the HTTP response from the given mock response instance.  The
 simulation will only be in effect for requests whose URL and HTTP method match
 the given parameters.
 @param mockResponse the basis for the simulation
 @param reqLatency simulated latency (in seconds) for the request to reach its
 endpoint
 @param respLatency simulated latency (in seconds) for the response to return
*/
+ (void)simulateResponseFromMock:(PEHttpResponse *)mockResponse
                  requestLatency:(NSUInteger)reqLatency
                 responseLatency:(NSUInteger)respLatency;

/**
 Simulates an HTTP response from the given parameters for the given request
 URL and HTTP method.  The simulation will only be in effect for requests
 whose URL and HTTP method match the given parameters.
 @param body the http response body as a string
 @param statusCode the http response status code
 @param headers the http response headers
 @param cookies the http response cookies
 @param requestUrl the http request URL for which the simulation should be
 active
 @param httpMethod the http request method for which the simulation should be
 active
 @param reqLatency simulated latency (in seconds) for the request to reach its
 endpoint
 @param respLatency simulated latency (in seconds) for the response to return
 */
+ (void)simulateResponseWithUTF8Body:(NSString *)body
                          statusCode:(NSUInteger)statusCode
                             headers:(NSDictionary *)headers
                             cookies:(NSArray *)cookies
                       forRequestUrl:(NSURL *)requestUrl
                andRequestHttpMethod:(NSString *)httpMethod
                      requestLatency:(NSUInteger)reqLatency
                     responseLatency:(NSUInteger)respLatency;

/**
 Simulates an HTTP response from the given parameters for the given request
 URL and HTTP method.  The simulation will only be in effect for requests
 whose URL and HTTP method match the given parameters.
 @param body the http response body
 @param statusCode the http response status code
 @param headers the http response headers
 @param cookies the http response cookies
 @param requestUrl the http request URL for which the simulation should be
 active
 @param httpMethod the http request method for which the simulation should be
 active
 @param reqLatency simulated latency (in seconds) for the request to reach its
 endpoint
 @param respLatency simulated latency (in seconds) for the response to return
 */
+ (void)simulateResponseWithBody:(NSData *)body
                      statusCode:(NSUInteger)statusCode
                         headers:(NSDictionary *)headers
                         cookies:(NSArray *)cookies
                   forRequestUrl:(NSURL *)requestUrl
            andRequestHttpMethod:(NSString *)httpMethod
                  requestLatency:(NSUInteger)reqLatency
                 responseLatency:(NSUInteger)respLatency;

#pragma mark - Ending a simulation

/**
 Clears all simulations (stubs) from the underlying NSURL*** loading system.
 */
+ (void)clearSimulations;

#pragma mark - Simulating network failures

/**
 Registers a custom NSURLProtocol within the iOS HTTP system in order to
 simulate a network failure.
 @param urlErrCode the NSURLError code that should be associated with the
 simulated failure
 @param requestUrl the http request URL for which the simulation should be
 active
 @param httpMethod the http request method for which the simulation should be
 active
*/
+ (void)simulateNetworkFailure:(NSInteger)urlErrCode
                 forRequestUrl:(NSURL *)requestUrl
          andRequestHttpMethod:(NSString *)httpMethod;

/**
 Registers a custom NSURLProtocol within the iOS HTTP system in order to
 simulate a DNS failure.
 @param requestUrl the http request URL for which the simulation should be
 active
 @param httpMethod the http request method for which the simulation should be
 active
*/
+ (void)simulateDNSFailureForRequestUrl:(NSURL *)requestUrl
                   andRequestHttpMethod:(NSString *)httpMethod;

/**
 Registers a custom NSURLProtocol within the iOS HTTP system in order to
 simulate a connection timeout.
 @param requestUrl the http request URL for which the simulation should be
 active
 @param httpMethod the http request method for which the simulation should be
 active
*/
+ (void)simulateConnectionTimedOutForRequestUrl:(NSURL *)requestUrl
                           andRequestHttpMethod:(NSString *)httpMethod;

/**
 Registers a custom NSURLProtocol within the iOS HTTP system in order to
 simulate a cannot-connect-to-host network error.
 @param requestUrl the http request URL for which the simulation should be
 active
 @param httpMethod the http request method for which the simulation should be
 active
*/
+ (void)simulateCannotConnectToHostForRequestUrl:(NSURL *)requestUrl
                            andRequestHttpMethod:(NSString *)httpMethod;

/**
 Registers a custom NSURLProtocol within the iOS HTTP system in order to
 simulate a not-connected-to-internet failure.
 @param requestUrl the http request URL for which the simulation should be
 active
 @param httpMethod the http request method for which the simulation should be
 active
*/
+ (void)simulateNotConnectedToInternetForRequestUrl:(NSURL *)requestUrl
                               andRequestHttpMethod:(NSString *)httpMethod;

/**
 Registers a custom NSURLProtocol within the iOS HTTP system in order to
 simulate a connection-lost network error.
 @param requestUrl the http request URL for which the simulation should be
 active
 @param httpMethod the http request method for which the simulation should be
 active
*/
+ (void)simulateConnectionLostForRequestUrl:(NSURL *)requestUrl
                       andRequestHttpMethod:(NSString *)httpMethod;

@end
