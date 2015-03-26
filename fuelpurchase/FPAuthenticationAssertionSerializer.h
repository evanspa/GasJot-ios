//
//  FPAuthenticationAssertionSerializer.h
//  fuelpurchase
//
//  Created by Evans, Paul on 1/30/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "HCHalJsonSerializerExtensionSupport.h"
#import "FPUserSerializer.h"

@interface FPAuthenticationAssertionSerializer : HCHalJsonSerializerExtensionSupport

#pragma mark - Initializers

- (id)initWithUserSerializer:(FPUserSerializer *)userSerializer
                     charset:(HCCharset *)charset;

@end
