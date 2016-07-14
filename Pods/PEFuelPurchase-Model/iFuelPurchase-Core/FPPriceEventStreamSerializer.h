//
//  FPPriceEventStreamSerializer.h
//  Gas Jot Model
//
//  Created by Paul Evans on 12/29/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import <PEHateoas-Client/HCHalJsonSerializerExtensionSupport.h>
#import <PELocal-Data/PELMDefs.h>

@protocol FPCoordinatorDao;

@interface FPPriceEventStreamSerializer : HCHalJsonSerializerExtensionSupport

#pragma mark - Initializers

- (id)initWithMediaType:(HCMediaType *)mediaType
                charset:(HCCharset *)charset
serializersForEmbeddedResources:(NSDictionary *)embeddedSerializers
actionsForEmbeddedResources:(NSDictionary *)actions
         coordinatorDao:(id<FPCoordinatorDao>)coordinatorDao
                  error:(PELMDaoErrorBlk)errorBlk;

@end
