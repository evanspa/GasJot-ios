//
//  FPFuelStationSerializer.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 9/3/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <PEHateoas-Client/HCHalJsonSerializerExtensionSupport.h>
#import <PELocal-Data/PELMDefs.h>

@protocol FPCoordinatorDao;

@interface FPFuelStationSerializer : HCHalJsonSerializerExtensionSupport

#pragma mark - Initializers

- (id)initWithMediaType:(HCMediaType *)mediaType
                charset:(HCCharset *)charset
serializersForEmbeddedResources:(NSDictionary *)embeddedSerializers
actionsForEmbeddedResources:(NSDictionary *)actions
         coordinatorDao:(id<FPCoordinatorDao>)coordinatorDao
                  error:(PELMDaoErrorBlk)errorBlk;

@end
