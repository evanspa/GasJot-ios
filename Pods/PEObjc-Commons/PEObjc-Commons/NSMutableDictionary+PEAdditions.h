//
// NSMutableDictionary+PEAdditions.h
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

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (PEAdditions)

/**
 *  Adds object into the dictionary keyed under key, only if object is
 *  non-nil.  If object is nil, nothing is done.
 *  @param object The object to add to the dictionary.
 *  @param key The key for the object.
 */
- (void)setObjectIfNotNull:(id)object forKey:(id<NSCopying>)key;

/**
 *  Adds strValue into the dictionary keyed under key, only if strValue is
 *  non a blank string (whitespace only).  If strValue is blank, nothing is done.
 *  @param strValue The string object to add to the dictionary.
 *  @param key The key for the object.
 */
- (void)setStringIfNotBlank:(NSString *)strValue forKey:(id<NSCopying>)key;

/**
 *  Adds object into the dictionary keyed under key.  If object is nil, then
 *  [NSNull null] will be set as the object.
 *  @param object The object to add to the dictionary.
 *  @param key The key for the object.
 */
- (void)nullSafeSetObject:(id)object forKey:(id<NSCopying>)key;

/**
 *  Adds an NSNumber representing the number of milliseconds since 1970 that date represents,
 *  into the dictionary keyed under key, only if date is non-nil.  If date is nil,
 *  nothing is done.
 *  @param date The date object whose seconds-since-1970 representation to add to the
 *  dictionary.
 *  @param key The key for the object.
 */
- (void)setMillisecondsSince1970FromDate:(NSDate *)date forKey:(id<NSCopying>)key;

@end
