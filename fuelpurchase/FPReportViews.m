//
//  FPReportViews.m
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 10/10/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "FPReportViews.h"
#import "FPUtils.h"
#import <PEObjc-Commons/PEUtils.h>
#import <PEObjc-Commons/PEUIUtils.h>
#import "NSDate+PEAdditions.h"

NSString * const FPOdometerLogFunFactIndexDefaultsKey = @"FPOdometerLogFunFactIndex";
NSString * const FPGasLogFunFactIndexDefaultsKey = @"FPGasLogFunFactIndex";

@implementation FPReportViews {
  FPReports *_reports;
  NSArray *_odometerLogFunFacts;
  NSArray *_gasLogFunFacts;
}

#pragma mark - Initializers

- (id)initWithReports:(FPReports *)reports {
  self = [super init];
  if (self) {
    _reports = reports;
    _odometerLogFunFacts = [self odometerLogFunFacts];
    _gasLogFunFacts = [self gasLogFunFacts];
  }
  return self;
}

#pragma mark - Gas Log Fun Facts Collection

- (NSArray *)gasLogFunFacts {
  JGActionSheetSection *(^funFactIfFirstGasRecord)(UIView *) = ^(UIView *relativeToView) {
    return [PEUIUtils alertSectionWithTitle:nil
                                 titleImage:nil
                           alertDescription:[[NSAttributedString alloc] initWithString:@"Your first gas log.  Nice."]
                             relativeToView:relativeToView];
  };
  NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
  [numFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
  
/*- <DONE> (NSDecimalNumber *)yearToDateSpentOnGasForUser:(FPUser *)user;
  - (NSDecimalNumber *)yearToDateSpentOnGasForVehicle:(FPVehicle *)vehicle;
  - (NSDecimalNumber *)yearToDateSpentOnGasForFuelstation:(FPFuelStation *)vehicle;
  - (NSDecimalNumber *)totalSpentOnGasForUser:(FPUser *)user;
  - (NSDecimalNumber *)totalSpentOnGasForVehicle:(FPVehicle *)vehicle;
  - (NSDecimalNumber *)totalSpentOnGasForFuelstation:(FPFuelStation *)vehicle;
  - (NSDecimalNumber *)yearToDateAvgPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;
  - (NSDecimalNumber *)yearToDateAvgPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;
  - (NSDecimalNumber *)yearToDateAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;
  - (NSDecimalNumber *)overallAvgPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;
  - (NSDecimalNumber *)overallAvgPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;
  - (NSDecimalNumber *)overallAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;
  - (NSDecimalNumber *)yearToDateMaxPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;
  - (NSDecimalNumber *)yearToDateMaxPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;
  - (NSDecimalNumber *)yearToDateMaxPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;
  - (NSDecimalNumber *)overallMaxPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;
  - (NSDecimalNumber *)overallMaxPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;
  - (NSDecimalNumber *)overallMaxPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;*/
  
  FPFunFact f1 = ^JGActionSheetSection *(FPFuelPurchaseLog *gasLog, FPUser *user, UIView *relativeToView) {
    NSDecimalNumber *spentOnGas = [_reports yearToDateSpentOnGasForUser:user];
    NSAttributedString *funFact = [PEUIUtils attributedTextWithTemplate:@"This year, you've spent %@ on gas across all your vehicles."
                                                          textToAccent:[numFormatter stringFromNumber:spentOnGas]
                                                        accentTextFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]];
    return [PEUIUtils infoAlertSectionWithTitle:@"Fun Fact" alertDescription:funFact relativeToView:relativeToView];
  };
  return @[f1];
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
    NSDecimalNumber *milesDrivenSinceLastLog = [_reports milesDrivenSinceLastOdometerLogAndLog:odometerLog user:user];
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
    NSNumber *daysSinceLastLog = [_reports daysSinceLastOdometerLogAndLog:odometerLog user:user];
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
    NSNumber *temperateLastYear = [_reports temperatureLastYearFromLog:odometerLog user:user];
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

#pragma mark - 'Next' Odometer Log Fun Fact

- (NSInteger)numOdometerFunFacts {
  return [_odometerLogFunFacts count];
}

- (FPFunFact)nextOdometerFunFact {
  NSNumber *odometerFunFactIndex = [FPReportViews nextIndexForUserDefaultsKey:FPOdometerLogFunFactIndexDefaultsKey funFacts:_odometerLogFunFacts];
  return _odometerLogFunFacts[odometerFunFactIndex.integerValue];
}

#pragma mark - 'Next' Gas Log Fun Fact

- (NSInteger)numGasFunFacts {
  return [_gasLogFunFacts count];
}

- (FPFunFact)nextGasFunFact {
  NSNumber *gasFunFactIndex = [FPReportViews nextIndexForUserDefaultsKey:FPGasLogFunFactIndexDefaultsKey funFacts:_gasLogFunFacts];
  return _gasLogFunFacts[gasFunFactIndex.integerValue];
}

@end
