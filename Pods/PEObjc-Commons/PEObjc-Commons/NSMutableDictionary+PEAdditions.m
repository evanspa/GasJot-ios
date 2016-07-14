//
// NSMutableDictionary+PEAdditions.m
//
// Copyright (c) 2014-2015 PEObjc-Commons
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

#import "NSMutableDictionary+PEAdditions.h"
#import "NSString+PEAdditions.h"
#import "PEUtils.h"

@implementation NSMutableDictionary (PEAdditions)

- (void)setObjectIfNotNull:(id)object forKey:(id<NSCopying>)key {
  if (object) {
    [self setObject:object forKey:key];
  }
}

- (void)setStringIfNotBlank:(NSString *)strValue forKey:(id<NSCopying>)key {
  if (strValue && ![strValue isBlank]) {
    [self setObject:strValue forKey:key];
  }
}

- (void)nullSafeSetObject:(id)object forKey:(id<NSCopying>)key {
  if (object) {
    [self setObject:object forKey:key];
  } else {
    [self setObject:[NSNull null] forKey:key];
  }
}

- (void)setMillisecondsSince1970FromDate:(NSDate *)date forKey:(id<NSCopying>)key {
  if (![PEUtils isNil:date]) {
    NSNumber *num = [NSNumber numberWithInteger:([date timeIntervalSince1970] * 1000)];
    [self setObject:num forKey:key];
  }
}

@end
