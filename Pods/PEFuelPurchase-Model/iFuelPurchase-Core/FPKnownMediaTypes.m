//
//  FPKnownMediaTypes.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 9/13/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPKnownMediaTypes.h"

#import <PEHateoas-Client/HCMediaType.h>

NSString * const fpApplicationType = @"application/";
NSString * const fpApplicationSubtypePrefix = @"vnd.fp.";
NSString * const fpJsonSubtypePostfix = @"+json";

NSString * (^fpMtBuilder)(NSString *, NSString *) = ^NSString *(NSString *mtId, NSString *version) {
  return [NSString stringWithFormat:@"%@%@%@-v%@%@", fpApplicationType, fpApplicationSubtypePrefix, mtId, version, fpJsonSubtypePostfix];
};

@implementation FPKnownMediaTypes

+ (HCMediaType *)apiMediaTypeWithVersion:(NSString *)version {
  return [HCMediaType MediaTypeFromString:fpMtBuilder(@"api", version)];
}

+ (HCMediaType *)priceStreamMediaTypeWithVersion:(NSString *)version {
  return [HCMediaType MediaTypeFromString:fpMtBuilder(@"pricestream", version)];
}

+ (HCMediaType *)changelogMediaTypeWithVersion:(NSString *)version {
  return [HCMediaType MediaTypeFromString:fpMtBuilder(@"changelog", version)];
}

+ (HCMediaType *)userMediaTypeWithVersion:(NSString *)version {
  return [HCMediaType MediaTypeFromString:fpMtBuilder(@"user", version)];
}

+ (HCMediaType *)vehicleMediaTypeWithVersion:(NSString *)version {
  return [HCMediaType MediaTypeFromString:fpMtBuilder(@"vehicle", version)];
}

+ (HCMediaType *)fuelStationMediaTypeWithVersion:(NSString *)version {
  return [HCMediaType MediaTypeFromString:fpMtBuilder(@"fuelstation", version)];
}

+ (HCMediaType *)fuelPurchaseLogMediaTypeWithVersion:(NSString *)version {
  return [HCMediaType MediaTypeFromString:fpMtBuilder(@"fplog", version)];
}

+ (HCMediaType *)environmentLogMediaTypeWithVersion:(NSString *)version {
  return [HCMediaType MediaTypeFromString:fpMtBuilder(@"envlog", version)];
}

@end
