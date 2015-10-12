//
//  FPReports.m
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 10/10/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "FPReports.h"
#import "FPUtils.h"
#import <PEObjc-Commons/PEUtils.h>
#import <PEObjc-Commons/PEUIUtils.h>
#import "NSDate+PEAdditions.h"

NSString * const FPOdometerLogFunFactIndexDefaultsKey = @"FPOdometerLogFunFactIndex";

@implementation FPReports {
  FPLocalDao *_localDao;
  NSArray *_odometerLogFunFacts;
}

#pragma mark - Initializers

- (id)initWithLocalDao:(FPLocalDao *)localDao {
  self = [super init];
  if (self) {
    _localDao = localDao;
    _odometerLogFunFacts = [self odometerLogFunFacts];
  }
  return self;
}

#pragma mark - Odometer Log Fun Fact Definitions

- (NSDecimalNumber *)milesDrivenSinceLastOdometerLogAndLog:(FPEnvironmentLog *)odometerLog
                                                      user:(FPUser *)user {
  NSDecimalNumber *odometer = [odometerLog odometer];
  if (![PEUtils isNil:odometer]) {
    NSArray *odometerLogs =
      [_localDao environmentLogsForUser:user pageSize:1 beforeDateLogged:[odometerLog logDate] error:[FPUtils localFetchErrorHandlerMaker]()];
    if ([odometerLogs count] > 0) {
      NSDecimalNumber *lastOdometer = [odometerLogs[0] odometer];
      if (![PEUtils isNil:lastOdometer]) {
        return [odometer decimalNumberBySubtracting:lastOdometer];
      }
    }
  }
  return nil;
}

- (NSNumber *)daysSinceLastOdometerLogAndLog:(FPEnvironmentLog *)odometerLog
                                        user:(FPUser *)user {
  NSArray *odometerLogs =
    [_localDao environmentLogsForUser:user pageSize:1 beforeDateLogged:[odometerLog logDate] error:[FPUtils localFetchErrorHandlerMaker]()];
  if ([odometerLogs count] > 0) {
    NSDate *dateOfLastLog = [odometerLogs[0] logDate];
    if (dateOfLastLog) {
      return @([[odometerLog logDate] daysFromDate:dateOfLastLog]);
    }
  }
  return nil;
}

- (NSNumber *)temperatureLastYearFromLog:(FPEnvironmentLog *)odometerLog
                                    user:(FPUser *)user {
  NSInteger plusMinusDays = 15;
  NSDate *logDate = [odometerLog logDate];
  if (logDate) {
    NSDate *oneYearAgo = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitYear value:-1 toDate:logDate options:0];
    NSDate *oneYearAgoMinusSome = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay value:plusMinusDays toDate:oneYearAgo options:0];
    NSArray *odometerLogs =
      [_localDao environmentLogsForUser:user pageSize:5 beforeDateLogged:oneYearAgoMinusSome error:[FPUtils localFetchErrorHandlerMaker]()];
    if ([odometerLogs count] > 0) {
      // so we got at most 5 hits; use the one nearest to our 1-year-ago date.
      FPEnvironmentLog *nearestToAYearAgoLog = odometerLogs[0];
      for (NSInteger i = 1; i < odometerLogs.count; i++) {
        NSDate *atLeastYearAgoLogDate = [odometerLogs[i] logDate];
        if ([atLeastYearAgoLogDate daysFromDate:oneYearAgo] < [nearestToAYearAgoLog.logDate daysFromDate:oneYearAgo]) {
          nearestToAYearAgoLog = odometerLogs[i];
        }
      }
      // so we have our odometer log that is neareset to 1-year-ago, but, is it
      // within our plus/minus variance?
      if ([nearestToAYearAgoLog.logDate daysFromDate:oneYearAgo] <= plusMinusDays) {
        return [nearestToAYearAgoLog reportedOutsideTemp];
      }
    }
  }
  return nil;
}


#pragma mark - Odometer Log Fun Facts Collection

- (NSArray *)odometerLogFunFacts {
  JGActionSheetSection *(^funFactIfFirstOdometerRecord)(UIView *) = ^(UIView *relativeToView) {
    return [PEUIUtils alertSectionWithTitle:nil
                                 titleImage:nil
                           alertDescription:[[NSAttributedString alloc] initWithString:@"Your first odometer log.  Nice."]
                             relativeToView:relativeToView];
  };
  FPFunFact f1 = ^JGActionSheetSection *(FPEnvironmentLog *odometerLog, FPUser *user, UIView *relativeToView) {
    NSDecimalNumber *milesDrivenSinceLastLog = [self milesDrivenSinceLastOdometerLogAndLog:odometerLog user:user];
    if (milesDrivenSinceLastLog) {
      NSAttributedString *funFact = [PEUIUtils attributedTextWithTemplate:@"You have driven %@ miles since your last odometer log was recorded."
                                                             textToAccent:[milesDrivenSinceLastLog description]
                                                           accentTextFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]];
      return [PEUIUtils infoAlertSectionWithTitle:@"Fun Fact" alertDescription:funFact relativeToView:relativeToView];
    } else {
      return funFactIfFirstOdometerRecord(relativeToView);
    }
  };
  FPFunFact f2 = ^JGActionSheetSection *(FPEnvironmentLog *odometerLog, FPUser *user, UIView *relativeToView) {
    NSNumber *daysSinceLastLog = [self daysSinceLastOdometerLogAndLog:odometerLog user:user];
    if (daysSinceLastLog) {
      NSAttributedString *funFact = [PEUIUtils attributedTextWithTemplate:@"It has been %@ days since your last odometer log was recorded."
                                                             textToAccent:[daysSinceLastLog description]
                                                           accentTextFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]];
      return [PEUIUtils infoAlertSectionWithTitle:@"Factoid" alertDescription:funFact relativeToView:relativeToView];
    } else {
      return funFactIfFirstOdometerRecord(relativeToView);
    }
  };
  FPFunFact f3 = ^JGActionSheetSection *(FPEnvironmentLog *odometerLog, FPUser *user, UIView *relativeToView) {
    NSNumber *temperateLastYear = [self temperatureLastYearFromLog:odometerLog user:user];
    if (temperateLastYear) {
      NSAttributedString *funFact = [PEUIUtils attributedTextWithTemplate:@"A year ago the temperature was %@ degrees."
                                                             textToAccent:[temperateLastYear description]
                                                           accentTextFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]];
      NSNumber *temperature = [odometerLog reportedOutsideTemp];
      if (temperature) {
        NSInteger temperatureDifference = labs(temperateLastYear.integerValue - odometerLog.reportedOutsideTemp.integerValue);
        NSMutableAttributedString *funFactMore = [[NSMutableAttributedString alloc] initWithAttributedString:funFact];
        if (temperatureDifference == 0) {
          [funFactMore appendAttributedString:[[NSAttributedString alloc] initWithString:@"  The temperature last year was exactly the same as it is today.  How about that?"]];
        } else {
          [funFactMore appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"  That's a difference of %@ degrees."
                                                                       textToAccent:[NSString stringWithFormat:@"%ld", (long)temperatureDifference]
                                                                     accentTextFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]]];
        }
        return [PEUIUtils infoAlertSectionWithTitle:@"Fun Fact" alertDescription:funFactMore relativeToView:relativeToView];
      } else {
        return [PEUIUtils infoAlertSectionWithTitle:@"Factoid" alertDescription:funFact relativeToView:relativeToView];
      }
    }
    return nil;
  };
  return @[f1, f2, f3];
}

#pragma mark - Fun Fact Index Helpers

+ (NSNumber *)nextIndexForUserDefaultsKey:(NSString *)userDefaultsIndexKey
                                 funFacts:(NSArray *)funFacts {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSNumber *funFactIndex = [defaults objectForKey:userDefaultsIndexKey];
  if ([PEUtils isNil:funFactIndex]) {
    funFactIndex = @(0);
  } else {
    if (funFactIndex.integerValue + 1 == [funFacts count]) {
      funFactIndex = @(0);
    } else {
      funFactIndex = @(funFactIndex.integerValue + 1);
    }
  }
  [defaults setObject:funFactIndex forKey:userDefaultsIndexKey];
  return funFactIndex;
}

#pragma mark - 'Next' Fun Fact

- (NSInteger)numOdometerFunFacts {
  return [_odometerLogFunFacts count];
}

- (FPFunFact)nextOdometerFunFact {
  NSNumber *odometerFunFactIndex =
    [FPReports nextIndexForUserDefaultsKey:FPOdometerLogFunFactIndexDefaultsKey funFacts:_odometerLogFunFacts];
  return _odometerLogFunFacts[odometerFunFactIndex.integerValue];
}

@end
