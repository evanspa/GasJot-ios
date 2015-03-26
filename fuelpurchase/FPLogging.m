// Copyright (C) 2013 Paul Evans
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

#import "FPLogging.h"

@implementation FPLogging

#pragma mark - Initialization

+ (void)initializeLogging {
  [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
  [DDLog addLogger:[DDASLLogger sharedInstance]];
  [DDLog addLogger:[DDTTYLogger sharedInstance]];
}

#pragma mark - Error/Warn/Info logging (structured output)

#pragma mark - Verbose logging (unstructured output)

+ (void)logAllCookies {
  NSHTTPCookieStorage *store = [NSHTTPCookieStorage sharedHTTPCookieStorage];
  NSArray *cookies = [store cookies];
  if ([cookies count] > 0) {
    DDLogVerbose(@"All cookies:");
    [cookies enumerateObjectsUsingBlock:^ void (id obj,
                                                NSUInteger idx,
                                                BOOL *stop) {
        NSHTTPCookie *cookie = (NSHTTPCookie *)obj;
        DDLogVerbose(@"\tCookie: [%@]", cookie);
      }];
  } else {
    DDLogVerbose(@"There are no cookies in the shared cookie storage.");
  }
}

@end
