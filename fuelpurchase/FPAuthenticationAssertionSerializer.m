//
//  FPAuthenticationAssertionSerializer.m
//  fuelpurchase
//
//  Created by Evans, Paul on 1/30/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPAuthenticationAssertionSerializer.h"
#import "FPAuthenticationAssertion.h"

NSString * const FPUsernameOrEmailKey = @"fpuser/usernameoremail";
NSString * const FPPasswordKey        = @"fpuser/password";
NSString * const FPAuthTokenKey       = @"fpuser/authToken";

@implementation FPAuthenticationAssertionSerializer {
  FPUserSerializer *_userSerializer;
}

#pragma mark - Initializers

- (id)initWithUserSerializer:(FPUserSerializer *)userSerializer
                     charset:(HCCharset *)charset {
  self = [super initWithCharset:charset];
  if (self) {
    _userSerializer = userSerializer;
  }
  return self;
}

#pragma mark - Serialization (Dictionary -> Resource Model)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  FPAuthenticationAssertion *authAssertion =
    (FPAuthenticationAssertion *)resourceModel;
  NSMutableDictionary *userDictionary = [NSMutableDictionary dictionary];
  [userDictionary setObject:[authAssertion usernameOrEmail] forKey:FPUsernameOrEmailKey];
  [userDictionary setObject:[authAssertion password] forKey:FPPasswordKey];
  return userDictionary;
}

#pragma mark - Deserialization (Resource Model -> Dictionary)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict {
  return [[FPAuthenticationAssertion alloc]
           initWithAuthToken:[resDict objectForKey:FPAuthTokenKey]
                        user:[_userSerializer resourceModelWithDictionary:resDict]];
}

@end
