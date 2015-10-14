//
//  FPReportViews.h
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 10/10/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PEObjc-Commons/JGActionSheet.h>
#import <PEFuelPurchase-Model/FPLocalDao.h>
#import <PEFuelPurchase-Model/FPReports.h>

typedef JGActionSheetSection *(^FPFunFact)(id, FPUser *, UIView *);

@interface FPReportViews : NSObject

#pragma mark - Initializers

- (id)initWithReports:(FPReports *)reports;

#pragma mark - 'Next' Odometer Fun Fact

- (NSInteger)numOdometerFunFacts;

- (FPFunFact)nextOdometerFunFact;

#pragma mark - 'Next' Gas Log Fun Fact

- (NSInteger)numGasFunFacts;

- (FPFunFact)nextGasFunFact;

@end
