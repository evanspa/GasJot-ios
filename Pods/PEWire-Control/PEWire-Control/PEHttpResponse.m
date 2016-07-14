//
//  PEHttpResponse.m
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

#import "PEHttpResponse.h"

@implementation PEHttpResponse {
  NSMutableDictionary *_headers;
  NSMutableArray *_cookies;
}

#pragma mark - Initializers

- (id)initWithRequestUrl:(NSURL *)requestUrl {
  self = [super init];
  if (self) {
    _requestUrl = requestUrl;
    _headers = [[NSMutableDictionary alloc] init];
    _cookies = [[NSMutableArray alloc] init];
  }
  return self;
}

#pragma mark - Helpers

- (void)setObjectIfNotNil:(id)value
                   forKey:(NSString *)key
                  toProps:(NSMutableDictionary *)props {
  if (value) {
    [props setObject:value forKey:key];
  }
}

#pragma mark - Methods

- (void)addHeaderWithName:(NSString *)name value:(NSString *)value {
  [_headers setObject:value forKey:name];
}

- (void)addCookieWithName:(NSString *)name
                    value:(NSString *)value
                     path:(NSString *)path
                   domain:(NSString *)domain
                 isSecure:(BOOL)isSecure
                  expires:(NSDate *)expires
                   maxAge:(NSInteger)maxAge {
  NSMutableDictionary *props = [[NSMutableDictionary alloc] initWithCapacity:7];
  NSString *pathVal = path;
  NSString *domainVal = domain;
  if (!pathVal) {
    pathVal = [_requestUrl path];
  }
  [props setObject:pathVal forKey:NSHTTPCookiePath];
  if (!domainVal) {
    domainVal = [_requestUrl host];
  }
  [props setObject:domainVal forKey:NSHTTPCookieDomain];
  [self setObjectIfNotNil:name forKey:NSHTTPCookieName toProps:props];
  [self setObjectIfNotNil:value forKey:NSHTTPCookieValue toProps:props];
  [self setObjectIfNotNil:domain forKey:NSHTTPCookieDomain toProps:props];
  if (isSecure) {
    [props setObject:@"Secure" forKey:NSHTTPCookieSecure];
  }
  [self setObjectIfNotNil:expires forKey:NSHTTPCookieExpires toProps:props];
  if (maxAge > 0) {
    [props setObject:[NSString stringWithFormat:@"%ld",(long)maxAge]
              forKey:NSHTTPCookieMaximumAge];
  }
  [_cookies addObject:[NSHTTPCookie cookieWithProperties:props]];
}

@end
