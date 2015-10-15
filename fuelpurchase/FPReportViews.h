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
#import <PEFuelPurchase-Model/FPStats.h>

typedef JGActionSheetSection *(^FPFunFact)(id, FPUser *, UIView *);

@interface FPReportViews : NSObject

#pragma mark - Initializers

- (id)initWithStats:(FPStats *)stats;

#pragma mark - Odometer Log Fun Fact Iteration

- (NSInteger)numOdometerFunFacts;

- (FPFunFact)nextOdometerFunFact;

#pragma mark - Gas Log Fun Fact Iteration

- (NSInteger)numGasFunFacts;

- (FPFunFact)nextGasFunFact;

@end
