//
//  PEHttpResponseUtils.h
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

@interface PEHttpResponseUtils : NSObject

#pragma mark - Helpers

/**
 Helper function that can parse 2 different types of date format:
 EEE',' dd-MMM-yyyy HH':'mm':'ss z
 EEE',' MM-dd-yyyy HH':'mm':'ss z
 @param dateStr the string representation of the date
 @return the NSDate parsed from the given date string; or nil if the string
 cannot be parsed
 */
+ (NSDate *)dateFromString:(NSString *)dateStr;

/**
 Helper function that creates and returns a mock HTTP response instance from
 the given XML representation of an HTTP response.
 @param xmlResponse XML representation of an HTTP response
 @param bundle The bundle to which file paths (that may appear in the response xml) are relative to.
 @return populated mock HTTP response instance
 */
+ (PEHttpResponse *)mockResponseFromXml:(NSString *)xmlResponse
                  pathsRelativeToBundle:(NSBundle *)bundle;

@end
