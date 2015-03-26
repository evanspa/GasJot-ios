//
//  FPAuthenticationAssertion.m
//  fuelpurchase
//
//  Created by Evans, Paul on 1/30/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPAuthenticationAssertion.h"

@implementation FPAuthenticationAssertion

#pragma mark - Initializers

- (id)initWithUsernameOrEmail:(NSString *)usernameOrEmail
                     password:(NSString *)password {
  self = [super init];
  if (self) {
    _usernameOrEmail = usernameOrEmail;
    _password = password;
  }
  return self;
}

- (id)initWithAuthToken:(NSString *)authToken
                   user:(FPUser *)user {
  self = [super init];
  if (self) {
    _authToken = authToken;
    _user = user;
  }
  return self;
}

@end
