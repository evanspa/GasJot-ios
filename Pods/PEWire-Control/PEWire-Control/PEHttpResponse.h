//
//  PEHttpResponse.h
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

/**
 Abstraction for modeling an HTTP response.  Ideally this abstraction should be
 immutable.  However, it is fully mutable for convenience only (this abstraction
 is intended to be used in testing / development contexts).
 */
@interface PEHttpResponse : NSObject

#pragma mark - Initializers

/**
 @param requestUrl Request URL to initialize the mock response with.
 */
- (id)initWithRequestUrl:(NSURL *)requestUrl;

#pragma mark - Methods

/**
 Adds a header to the response with the given name and value.
 @param name the header name
 @param value the header value
 */
- (void)addHeaderWithName:(NSString *)name value:(NSString *)value;

/**
 Adds a cookie to the response with the given attributes.
 @param name the cookie name
 @param value the cookie value
 @param path the cookie path
 @param domain the cookie domain
 @param isSecure whether or not the cookie should be secure or not
 @param expires the expires-date for the cookie
 @param maxAge the maximum age value for the cookie
 */
- (void)addCookieWithName:(NSString *)name
                    value:(NSString *)value
                     path:(NSString *)path
                   domain:(NSString *)domain
                 isSecure:(BOOL)isSecure
                  expires:(NSDate *)expires
                   maxAge:(NSInteger)maxAge;

#pragma mark - Properties

/**
 A human-readable identifier that can be associated with this mock response
 (but is not part of the actual http response data).
 */
@property (nonatomic) NSString *name;

/**
 A human-readable description that an be associated with this mock response (but
 is not part of the actual http response data).
 */
@property (nonatomic) NSString *responseDescription;

/**
 The HTTP request method associated with the response.
 */
@property (nonatomic) NSString *requestMethod;

/**
 The status code for the response.
 */
@property (nonatomic) NSInteger statusCode;

/**
 The entity body of the response as a string.
 */
@property (nonatomic) NSString *bodyAsString;

/**
 The entity body of the response as raw data.
 */
@property (nonatomic) NSData *bodyAsData;

/**
 The headers of the response.
 */
@property (nonatomic, readonly) NSDictionary *headers;

/**
 The cookies of the response.
 */
@property (nonatomic, readonly) NSArray *cookies;

/**
   The request URL associated with the response.
*/
@property (nonatomic, readonly) NSURL *requestUrl;

@end
