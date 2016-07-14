//
//  PEHttpResponseUtils.m
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

#import "PEHttpResponseUtils.h"
#import <PEObjc-Commons/PEHttpUtils.h>
#import <KissXML/DDXML.h>
#import <PEXML-Utils/PEXMLUtils.h>

@implementation PEHttpResponseUtils

#pragma mark - Helpers

+ (NSDateFormatter *)dateFormatterWithFormat:(NSString *)format {
  NSDateFormatter *dateFormatter;
  dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
  dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
  dateFormatter.dateFormat = format;
  return dateFormatter;
}

+ (NSDate *)dateFromString:(NSString *)dateStr {
  NSArray *dateFormatters = @[
    [PEHttpResponseUtils
      dateFormatterWithFormat:@"EEE',' dd-MMM-yyyy HH':'mm':'ss z"],
    [PEHttpResponseUtils
      dateFormatterWithFormat:@"EEE',' MM-dd-yyyy HH':'mm':'ss z"]];
  __block NSDate *date = nil;
  [dateFormatters enumerateObjectsUsingBlock:^ void (id obj,
                                                     NSUInteger idx,
                                                     BOOL *stop) {
    date = [obj dateFromString:dateStr];
    if (date) {
      *stop = YES;
    }
  }];
  return date;
}

+ (PEHttpResponse *)mockResponseFromXml:(NSString *)xmlResponse
                  pathsRelativeToBundle:(NSBundle *)bundle {
  NSDateFormatter *rfc1123 = [[NSDateFormatter alloc] init];
  rfc1123.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
  rfc1123.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
  rfc1123.dateFormat = @"EEE',' dd-MMM-yyyy HH':'mm':'ss z";
  DDXMLDocument *xmlDoc = [[DDXMLDocument alloc]
                            initWithXMLString:xmlResponse options:0 error:nil];
  PEXmlUtils *xmlUtils = [[PEXmlUtils alloc] initWithDocument:xmlDoc];
  __block StrAttrExtractorBlk strAttrExtractor =
    [xmlUtils strAttrExtractorForElementAtXPath:@"/http-response/annotation"];
  NSString *host = strAttrExtractor(@"host");
  NSString *scheme = strAttrExtractor(@"scheme");
  NSInteger port = [strAttrExtractor(@"port") intValue];
  __block PEHttpResponse *mockResp =
    [[PEHttpResponse alloc]
      initWithRequestUrl:
        [[NSURL alloc]
          initWithString:strAttrExtractor(@"uri-path")
           relativeToURL:[PEHttpUtils urlFromHost:host
                                             port:port
                                           scheme:scheme]]];
  [mockResp setStatusCode:[xmlUtils
                            intValueForXPath:@"/http-response/@statusCode"]];
  [mockResp setName:strAttrExtractor(@"name")];
  [mockResp setResponseDescription:[xmlUtils
                     valueForXPath:@"/http-response/annotation"]];
  [mockResp setRequestMethod:strAttrExtractor(@"request-method")];
  NSArray *nodes = [xmlDoc nodesForXPath:@"/http-response/headers/header"
                                   error:nil];
  [nodes enumerateObjectsUsingBlock:^ (id obj, NSUInteger idx, BOOL *stop) {
      PEXmlUtils *xmlCmnsForHdr = [[PEXmlUtils alloc] initWithNode:obj];
      strAttrExtractor = [xmlCmnsForHdr strAttrExtractor];
      [mockResp addHeaderWithName:strAttrExtractor(@"name")
                            value:strAttrExtractor(@"value")];
    }];
  nodes = [xmlDoc nodesForXPath:@"/http-response/cookies/cookie" error:nil];
  [nodes enumerateObjectsUsingBlock:^ (id obj, NSUInteger idx, BOOL *stop) {
      PEXmlUtils *xmlCmnsForCookie = [[PEXmlUtils alloc] initWithNode:obj];
      strAttrExtractor = [xmlCmnsForCookie strAttrExtractor];
      BoolAttrExtractorBlk boolAttrExtractor =
        [xmlCmnsForCookie boolAttrExtractor];
      [mockResp addCookieWithName:strAttrExtractor(@"name")
                            value:strAttrExtractor(@"value")
                             path:strAttrExtractor(@"path")
                           domain:strAttrExtractor(@"domain")
                         isSecure:boolAttrExtractor(@"secure")
                          expires:[PEHttpResponseUtils
                                    dateFromString:strAttrExtractor(@"expires")]
                           maxAge:[strAttrExtractor(@"max-age") intValue]];
    }];
  NSString *fileDataPath = [xmlUtils valueForXPath:@"/http-response/body-file/@path"];
  if (fileDataPath) {
    NSString *bundlePath = [bundle bundlePath];
    NSString *fullPath = [bundlePath stringByAppendingPathComponent:fileDataPath];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSData *bodyAsData = [fm contentsAtPath:fullPath];
    [mockResp setBodyAsData:bodyAsData];
  } else {
    [mockResp setBodyAsString:[xmlUtils valueForXPath:@"/http-response/body"]];
  }
  return mockResp;
}

@end
