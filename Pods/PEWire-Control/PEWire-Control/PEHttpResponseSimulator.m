//
//  PEHttpResponseSimulator.m
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

#import <OHHTTPStubs/OHHTTPStubs.h>
#import "PEHttpResponseSimulator.h"
#import "PEHttpResponseUtils.h"

@implementation PEHttpResponseSimulator

#pragma mark - Helpers

+ (BOOL)shouldMockRequest:(NSURLRequest *)request
               forUrlPath:(NSString *)urlPath
                andMethod:(NSString *)httpMethod {
  return [[[request URL] path] isEqualToString:urlPath] &&
    [[request HTTPMethod] isEqualToString:httpMethod];
}

+ (NSString *)cookiesToRfc2109Format:(NSArray *)cookies {
  NSDateFormatter *rfc1123 = [[NSDateFormatter alloc] init];
  rfc1123.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
  rfc1123.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
  rfc1123.dateFormat = @"EEE',' dd-MMM-yyyy HH':'mm':'ss z";
  __block NSString *cookieHdr = [NSString string];
  [cookies enumerateObjectsUsingBlock:^(id obj,
                                        NSUInteger idx,
                                        BOOL *stop) {
      NSHTTPCookie *cookie = (NSHTTPCookie *)obj;
      NSString *cookieStr = [NSString stringWithFormat:@"%@=%@;",
                                      [cookie name], [cookie value]];
      if ([cookie path]) {
        cookieStr = [cookieStr stringByAppendingString:
                   [NSString stringWithFormat:@"path=%@;", [cookie path]]];
      }
      if ([cookie domain]) {
        cookieStr = [cookieStr stringByAppendingString:
                   [NSString stringWithFormat:@"domain=%@;", [cookie domain]]];
      }
      if ([cookie isSecure]) {
        cookieStr = [cookieStr stringByAppendingString:@"Secure;"];
      }
      // FYI, if the NSHTTPCookieMaximumAge property was originally used to
      // create the cookie, it ultimately manifests as the return value for the
      // "expiresDate" getter
      if ([cookie expiresDate]) {
        cookieStr = [cookieStr stringByAppendingString:
                    [NSString stringWithFormat:@"expires=%@;",
                      [rfc1123 stringFromDate:[cookie expiresDate]]]];
      }
      if ((idx + 1) < [cookies count]) {
        cookieStr = [cookieStr stringByAppendingString:@","];
      }
      cookieHdr = [cookieHdr stringByAppendingString:cookieStr];
    }];
  return cookieHdr;
}

#pragma mark - Simulating an HTTP response

+ (void)simulateResponseFromXml:(NSString *)xml
          pathsRelativeToBundle:(NSBundle *)bundle
                 requestLatency:(NSUInteger)reqLatency
                responseLatency:(NSUInteger)respLatency {
  [PEHttpResponseSimulator simulateResponseFromMock:[PEHttpResponseUtils mockResponseFromXml:xml
                                                                       pathsRelativeToBundle:bundle]
                                     requestLatency:reqLatency
                                    responseLatency:respLatency];
}

+ (void)simulateResponseFromMock:(PEHttpResponse *)mockResp
                  requestLatency:(NSUInteger)reqLatency
                 responseLatency:(NSUInteger)respLatency {
  if ([mockResp bodyAsData]) {
    [PEHttpResponseSimulator simulateResponseWithBody:[mockResp bodyAsData]
                                           statusCode:[mockResp statusCode]
                                              headers:[mockResp headers]
                                              cookies:[mockResp cookies]
                                        forRequestUrl:[mockResp requestUrl]
                                 andRequestHttpMethod:[mockResp requestMethod]
                                       requestLatency:reqLatency
                                      responseLatency:respLatency];
  } else {
    [PEHttpResponseSimulator simulateResponseWithUTF8Body:[mockResp bodyAsString]
                                               statusCode:[mockResp statusCode]
                                                  headers:[mockResp headers]
                                                  cookies:[mockResp cookies]
                                            forRequestUrl:[mockResp requestUrl]
                                     andRequestHttpMethod:[mockResp requestMethod]
                                           requestLatency:reqLatency
                                          responseLatency:respLatency];
  }
}

+ (void)simulateResponseWithUTF8Body:(NSString *)body
                          statusCode:(NSUInteger)statusCode
                             headers:(NSDictionary *)headers
                             cookies:(NSArray *)cookies
                       forRequestUrl:(NSURL *)requestUrl
                andRequestHttpMethod:(NSString *)httpMethod
                      requestLatency:(NSUInteger)reqLatency
                     responseLatency:(NSUInteger)respLatency {
  [self simulateResponseWithBody:[body dataUsingEncoding:NSUTF8StringEncoding]
                      statusCode:statusCode
                         headers:headers
                         cookies:cookies
                   forRequestUrl:requestUrl
            andRequestHttpMethod:httpMethod
                  requestLatency:reqLatency
                 responseLatency:respLatency];
}

+ (void)simulateResponseWithBody:(NSData *)body
                      statusCode:(NSUInteger)statusCode
                         headers:(NSDictionary *)headers
                         cookies:(NSArray *)cookies
                   forRequestUrl:(NSURL *)requestUrl
            andRequestHttpMethod:(NSString *)httpMethod
                  requestLatency:(NSUInteger)reqLatency
                 responseLatency:(NSUInteger)respLatency {
  [OHHTTPStubs stubRequestsPassingTest:^(NSURLRequest *request) {
    return [PEHttpResponseSimulator shouldMockRequest:request
                                           forUrlPath:[requestUrl path]
                                            andMethod:httpMethod];
  } withStubResponse:^(NSURLRequest *request) {
    NSMutableDictionary *allHeaders =
    [NSMutableDictionary dictionaryWithCapacity:([headers count] + 1)];
    [allHeaders addEntriesFromDictionary:headers];
    NSString *cookieHdr =
    [PEHttpResponseSimulator cookiesToRfc2109Format:cookies];
    [allHeaders setObject:cookieHdr forKey:@"Set-Cookie"];
    return [[OHHTTPStubsResponse responseWithData:body
                                       statusCode:(int)statusCode
                                          headers:allHeaders]
               requestTime:reqLatency
              responseTime:respLatency];
  }];
}

#pragma mark - Ending a simulation

+ (void)clearSimulations {
  [OHHTTPStubs removeAllStubs];
}

#pragma mark - Simulating network failures

+ (void)simulateNetworkFailure:(NSInteger)urlErrCode
                 forRequestUrl:(NSURL *)requestUrl
          andRequestHttpMethod:(NSString *)httpMethod {
  [OHHTTPStubs stubRequestsPassingTest:^(NSURLRequest *request) {
      return [PEHttpResponseSimulator shouldMockRequest:request
                                             forUrlPath:[requestUrl path]
                                              andMethod:httpMethod];
    } withStubResponse:^(NSURLRequest *request) {
      return [OHHTTPStubsResponse
               responseWithError:[NSError errorWithDomain:NSURLErrorDomain
                                                     code:urlErrCode
                                                 userInfo:nil]];
    }];
}

+ (void)simulateDNSFailureForRequestUrl:(NSURL *)requestUrl
                       andRequestHttpMethod:(NSString *)httpMethod {
  [PEHttpResponseSimulator simulateNetworkFailure:NSURLErrorDNSLookupFailed
                                    forRequestUrl:requestUrl
                             andRequestHttpMethod:httpMethod];
}

+ (void)simulateConnectionTimedOutForRequestUrl:(NSURL *)requestUrl
                               andRequestHttpMethod:(NSString *)httpMethod {
  [PEHttpResponseSimulator simulateNetworkFailure:NSURLErrorTimedOut
                                    forRequestUrl:requestUrl
                             andRequestHttpMethod:httpMethod];
}

+ (void)simulateCannotConnectToHostForRequestUrl:(NSURL *)requestUrl
                                andRequestHttpMethod:(NSString *)httpMethod {
  [PEHttpResponseSimulator simulateNetworkFailure:NSURLErrorCannotConnectToHost
                                    forRequestUrl:requestUrl
                             andRequestHttpMethod:httpMethod];
}

+ (void)simulateNotConnectedToInternetForRequestUrl:(NSURL *)requestUrl
                                   andRequestHttpMethod:(NSString *)httpMethod {
  [PEHttpResponseSimulator
    simulateNetworkFailure:NSURLErrorNotConnectedToInternet
             forRequestUrl:requestUrl
      andRequestHttpMethod:httpMethod];
}

+ (void)simulateConnectionLostForRequestUrl:(NSURL *)requestUrl
                           andRequestHttpMethod:(NSString *)httpMethod {
  [PEHttpResponseSimulator
    simulateNetworkFailure:NSURLErrorNetworkConnectionLost
             forRequestUrl:requestUrl
      andRequestHttpMethod:httpMethod];
}

@end
