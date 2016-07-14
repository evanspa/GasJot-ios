//
//  NSDictionary+PEAdditions.h
//  PEObjc-Commons
//
//  Created by Paul Evans on 6/3/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (PEAdditions)

/**
 *  @key key The key into the dictionary containing the value.
 *  @return NSDate representation of the date value.
 */
- (NSDate *)dateSince1970ForKey:(NSString *)key;

/**
 * @return The BOOL value found in the dictionary for the given key; or NO
 * if no entry exists for the key.
 */
- (BOOL)boolForKey:(NSString *)key;

/**
 * @return The BOOL value found in the dictionary for the given key; or defaultBool
 * if no entry exists for the key.
 */
- (BOOL)boolForKey:(NSString *)key defaultBool:(BOOL)defaultBool;

@end
