//
//  FPAuthenticationAssertion.h
//  fuelpurchase
//
//  Created by Evans, Paul on 1/30/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PEFuelPurchase-Model/FPUser.h>

/**
 This abstraction has a dual purpose with an RPC feel to it.  It is used to
 attempt to authenticate.  When attempting to authenticate, the usernameOrEmail
 and password properties should be populated.  In a success response situation,
 the authToken and user properties will be populated.  This reason for this
 dual purpose inside this single abstraction is rooted in the constraint of the
 rules of HTTP POST.  The response payload (if present) of an HTTP POST should
 be the same resource that was in the request (perhaps annotated with additional
 data).  Thus, in the POST request body, a serialized instance of this class
 will be provided, but with only the usernameOrEmail and password fields
 present; in the response, if successful, will also be an instance of this
 class, but with the authToken and user fields populated only.
 */
@interface FPAuthenticationAssertion : NSObject

#pragma mark - Initializers

/**
 Initializes a new instance with the intent to be used as the request payload
 of an HTTP POST to the authentications endpoint URI.
 */
- (id)initWithUsernameOrEmail:(NSString *)usernameOrEmail
                     password:(NSString *)password;

/**
 Initializes a new instance with the intent to be used to deserialize the
 response payload of a successful HTTP POST to the authentications endpoint
 URI.
 */
- (id)initWithAuthToken:(NSString *)authToken
                   user:(FPUser *)user;

#pragma mark - Properties

@property (nonatomic, readonly) NSString *usernameOrEmail;

@property (nonatomic, readonly) NSString *password;

@property (nonatomic, readonly) NSString *authToken;

@property (nonatomic, readonly) FPUser *user;

@end
