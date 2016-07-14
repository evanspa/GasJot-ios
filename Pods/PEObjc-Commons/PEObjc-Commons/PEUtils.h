//
// PEUtils.h
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

/** Sugar for getting localized strings. */
#define LS(key) NSLocalizedString(key, nil)

typedef void (^PEDictionaryPutter)(id, SEL, NSString *);

typedef id (^PEOrNil)(id);

/**
 A collection of domain-agnostic helper functions.
 */
@interface PEUtils : NSObject

#pragma mark - System

/** @return Helper that returns the device make / model name. */
+ (NSString *)deviceMake;

#pragma mark - Merging

+ (void)mergeRemoteObject:(id)remoteObject
          withLocalObject:(id)localObject
      previousLocalObject:(id)previousLocalObject
                   getter:(SEL)getter
                   setter:(SEL)setter
               comparator:(BOOL(^)(SEL, id, id))comparator
   replaceLocalWithRemote:(void(^)(id, id))replaceLocalWithRemote
            mergeConflict:(void(^)(void))mergeConflict;

+ (NSDictionary *)mergeRemoteObject:(id)remoteObject
                    withLocalObject:(id)localObject
                previousLocalObject:(id)previousLocalObject
        getterSetterKeysComparators:(NSArray *)getterSetterKeysComparators;

#pragma mark - Dynamic Invocation

+ (BOOL)boolValueForTarget:(id)object selector:(SEL)selector;

+ (void)setBoolValueForTarget:(id)object selector:(SEL)selector value:(BOOL)value;

#pragma mark - Formatting

+ (NSNumberFormatter *)currencyFormatter;

#pragma mark - Common Validations

+ (BOOL)validateEmailWithString:(NSString*)email;

#pragma mark - Calendar

+ (NSInteger)daysFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate;

+ (NSArray *)daysBetweenDates:(NSArray *)dates;

+ (NSInteger)currentYear;

+ (NSDate *)dateFromCalendar:(NSCalendar *)calendar
                         day:(NSInteger)day
                       month:(NSInteger)month
                        year:(NSInteger)year;

+ (NSDate *)dateFromCalendar:(NSCalendar *)calendar
                         day:(NSInteger)day
                       month:(NSInteger)month
              fromYearOfDate:(NSDate *)date;

+ (NSDate *)firstDayOfYearOfDate:(NSDate *)date calendar:(NSCalendar *)calendar;

+ (NSDate *)firstDayOfYear:(NSInteger)year month:(NSInteger)month calendar:(NSCalendar *)calendar;

+ (NSDate *)firstDayOfMonth:(NSInteger)month ofYearOfDate:(NSDate *)date calendar:(NSCalendar *)calendar;

+ (NSDate *)lastDayOfMonthForDate:(NSDate *)date calendar:(NSCalendar *)calendar;

+ (NSArray *)lastYearRangeFromDate:(NSDate *)date calendar:(NSCalendar *)calendar;

#pragma mark - String

/**
 Concatenates the set of strings from msgs into 1 string, with newlines (\n)
 appended after each string (except the last), and returns it.
 @param msgs the set of strings to be concatenated
 @return the concatenated string
*/
+ (NSString *)concat:(NSArray *)msgs;

+ (NSNumber *)nullSafeNumberFromString:(NSString *)value;

+ (NSDecimalNumber *)nullSafeDecimalNumberFromString:(NSString *)value;

+ (NSString *)emptyIfNil:(NSString *)value;

+ (NSString *)descriptionOrEmptyIfNil:(id)object;

+ (NSString *)textForDecimal:(NSDecimalNumber *)decimalValue
                   formatter:(NSNumberFormatter *)formatter
                   textIfNil:(NSString *)textIfNil;

+ (NSString *)labelTextForRecordCount:(NSInteger)recordCount;



#pragma mark - Notifications

+ (void)observeIfNotNilNotificationName:(NSString *)notificationName
                               observer:(id)observer
                               selector:(SEL)selector;

#pragma mark - Timer

+ (NSTimer *)startNewTimerWithTargetObject:(NSObject *)object
                                  selector:(SEL)selector
                                  interval:(NSInteger)timerInterval
                                  oldTimer:(NSTimer *)oldTimer;

+ (void)stopTimer:(NSTimer *)timer;

#pragma mark - Collections

/**
 @param dictionary The dictionary in which objects will be added to by the
 returned block.
 @return A convenient block for inserting objects into the given dictionary.
 The block receives an object (target), selector and key, and will insert into
 the dictionary the value returned by invoking the selector against the target
 using the key.
 */
+ (PEDictionaryPutter)dictionaryPutterForDictionary:(NSMutableDictionary *)dictionary;

/**
 Creates and returns a dictionay from the given array.  Each object in the array
 becomes an object in the dictionary, keyed on the application of the given
 selector to the object.  The selector should be a no-argument selector.
 @param array the array
 @param selector the selector to apply to the object; the return value being the
 key used to store the object in the returned dictionary
 @return dictionary
 */
+ (NSDictionary *)dictionaryFromArray:(NSArray *)array
                        selectorAsKey:(SEL)selector;

#pragma mark - Address Helpers

+ (NSString *)addressStringFromStreet:(NSString *)street
                                 city:(NSString *)city
                                state:(NSString *)state
                                  zip:(NSString *)zip;

#pragma mark - Conversions

+ (id)orNil:(id)object;

+ (PEOrNil)orNilMaker;

+ (id)nilIfNSNull:(id)object;

+ (NSNumber *)millisecondsFromDate:(NSDate *)date;

/**
 Returns an NSDecimalNumber instance from the given double scalar value.
 @param doubleVal 
 @return an NSDecimalNumber instance from the given double scalar value.
 */
+ (NSDecimalNumber *)decimalNumberFromDouble:(double)doubleVal;

/**
 Returns a string, "true" or "false" from the given BOOL value.
 @param boolValue
 @return "true" if boolValue is YES; otherwise "false"
 */
+ (NSString *)trueFalseFromBool:(BOOL)boolValue;

/**
 Returns a string, "yes" or "no" from the given BOOL value.
 @param boolValue
 @return "yes" if boolValue is YES; otherwise "no"
 */
+ (NSString *)yesNoFromBool:(BOOL)boolValue;

/**
 Returns a date object by parsing dateValue using the given pattern.
 @param dateValue The string-encoded date to be parsed.
 @param datePattern The pattern that describes the given date string value.
 @return NSDate instance.
 */
+ (NSDate *)dateFromString:(NSString *)dateValue
               withPattern:(NSString *)datePattern;

/**
 @return String representation of the given date using the given pattern.
 */
+ (NSString *)stringFromDate:(NSDate *)dateValue
                 withPattern:(NSString *)datePattern;

#pragma mark - Comparisons

/**
 @return date1 if date1 is later than date2.  nil if date1 and date2 are both
 nil.  If one is nil and the other isn't, the non-nil date is return.
 */
+ (NSDate *)largerOfDate:(NSDate *)date1 andDate:(NSDate *)date2;

/**
 @return YES If object is nil or equal to [NSNull null]; otherwise returns NO.
 */
+ (BOOL)isNil:(id)object;

/**
 @return YES If obj1 is equal to obj2, including if both of them are nil.
 */
+ (BOOL)nilSafeIs:(NSObject *)obj1 equalTo:(NSObject *)obj2;

/**
 @return YES If str1 and str2 are equal to each other.  If both are nil, then
 YES is returned.
 */
+ (BOOL)isString:(NSString *)str1 equalTo:(NSString *)str2;

/**
 @return YES If num1 and num2 are equal to each other.  If both are nil, then
 YES is returned.
 */
+ (BOOL)isNumber:(NSNumber *)num1 equalTo:(NSNumber *)num2;

/**
 @return YES If dt1 and dt1 are equal to each other.  If both are nil, then
 YES is returned.
 */
+ (BOOL)isDate:(NSDate *)dt1 equalTo:(NSDate *)dt2;

/**
 @return YES If dt1 and dt2 are equal to millisecond precision to each other. If
 both are nil, then YES is returned.
 */
+ (BOOL)isDate:(NSDate *)dt1 msprecisionEqualTo:(NSDate *)dt2;

/**
 Convenience function that checks if the given numerical property is equal for
 the given objects.
 @param numProp A property that returns an NSNumber object (doesn't work if it
 returns a scalar - it must be an object).
 @param object1 An object with the property.
 @param object2 Another object with the property.
 @return YES if the value of the property is equal for both objects; NO
 otherwise.
 */
+ (BOOL)isNumProperty:(SEL)numProp equalFor:(id)object1 and:(id)object2;

/**
 Convenience function that checks if the given string property is equal for the
 given objects.
 @param strProp A property that returns an NSString object.
 @param object1 An object with the property.
 @param object2 Another object with the property.
 @return YES if the value of the property is equal for both objects; NO
 otherwise.
 */
+ (BOOL)isStringProperty:(SEL)strProp equalFor:(id)object1 and:(id)object2;

/**
 Convenience function that checks if the given date property is equal for the
 given objects.
 @param dtProp A property that returns an NSDate object (doesn't work if it
 returns a scalar - it must be an object).
 @param object1 An object with the property.
 @param object2 Another object with the property.
 @return YES if the value of the property is equal for both objects; NO
 otherwise.
 */
+ (BOOL)isDateProperty:(SEL)dtProp equalFor:(id)object1 and:(id)object2;

/**
 Convenience function that checks if the given date property is equal for the
 given objects to millisecondn precision.
 @param dtProp A property that returns an NSDate object (doesn't work if it
 returns a scalar - it must be an object).
 @param object1 An object with the property.
 @param object2 Another object with the property.
 @return YES if the value of the property is equal for both objects; NO
 otherwise.
 */
+ (BOOL)isDateProperty:(SEL)dtProp msprecisionEqualFor:(id)object1 and:(id)object2;

/**
 Convenience function that checks if the given BOOL property is equal for the
 given objects.
 @param boolProp A property that returns a BOOL value
 @param object1 An object with the property.
 @param object2 Another object with the property.
 @return YES if the BOOL value of the property is equal for both objects; NO
 otherwise.
 */
+ (BOOL)isBoolProperty:(SEL)boolProp equalFor:(id)object1 and:(id)object2;

@end
