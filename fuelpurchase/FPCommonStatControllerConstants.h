//
//  FPCommonStatControllerConstants.h
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 10/26/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

typedef NSString *(^FPEntityNameBlk)(id);
typedef NSNumber *(^FPAlltimeAggregate)(id);
typedef NSNumber *(^FPYearToDateAggregate)(id);
typedef NSNumber *(^FPLastYearAggregate)(id);

typedef NSArray *(^FPAlltimeDataset)(id);
typedef NSArray *(^FPYearToDateDataset)(id);
typedef NSArray *(^FPLastYearDataset)(id);

typedef NSString *(^FPValueFormatter)(id);
