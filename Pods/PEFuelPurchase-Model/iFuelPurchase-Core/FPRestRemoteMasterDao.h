//
//  FPRestRemoteMasterDao.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/18/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

@import Foundation;

#import <PELocal-Data/PERestRemoteMasterDao.h>
#import "FPRemoteMasterDao.h"

@class PEChangelogSerializer;
@class PEUserSerializer;
@class PELoginSerializer;
@class PELogoutSerializer;
@class FPVehicleSerializer;
@class FPFuelStationSerializer;
@class FPFuelPurchaseLogSerializer;
@class FPEnvironmentLogSerializer;
@class PEPasswordResetSerializer;
@class PEResendVerificationEmailSerializer;
@class FPPriceEventStreamSerializer;

@interface FPRestRemoteMasterDao : PERestRemoteMasterDao <FPRemoteMasterDao>

#pragma mark - Initializers

- (id)initWithAcceptCharset:(HCCharset *)acceptCharset
             acceptLanguage:(NSString *)acceptLanguage
         contentTypeCharset:(HCCharset *)contentTypeCharset
                 authScheme:(NSString *)authScheme
         authTokenParamName:(NSString *)authTokenParamName
                  authToken:(NSString *)authToken
        errorMaskHeaderName:(NSString *)errorMaskHeaderName
 establishSessionHeaderName:(NSString *)establishHeaderSessionName
        authTokenHeaderName:(NSString *)authTokenHeaderName
  ifModifiedSinceHeaderName:(NSString *)ifModifiedSinceHeaderName
ifUnmodifiedSinceHeaderName:(NSString *)ifUnmodifiedSinceHeaderName
loginFailedReasonHeaderName:(NSString *)loginFailedReasonHeaderName
accountClosedReasonHeaderName:(NSString *)accountClosedReasonHeaderName
bundleHoldingApiJsonResource:(NSBundle *)bundle
  nameOfApiJsonResourceFile:(NSString *)apiResourceFileName
            apiResMtVersion:(NSString *)apiResMtVersion
             userSerializer:(PEUserSerializer *)userSerializer
        changelogSerializer:(PEChangelogSerializer *)changelogSerializer
            loginSerializer:(PELoginSerializer *)loginSerializer
           logoutSerializer:(PELogoutSerializer *)logoutSerializer
resendVerificationEmailSerializer:(PEResendVerificationEmailSerializer *)resendVerificationEmailSerializer
    passwordResetSerializer:(PEPasswordResetSerializer *)passwordResetSerializer
          vehicleSerializer:(FPVehicleSerializer *)vehicleSerializer
      fuelStationSerializer:(FPFuelStationSerializer *)fuelStationSerializer
  fuelPurchaseLogSerializer:(FPFuelPurchaseLogSerializer *)fuelPurchaseLogSerializer
   environmentLogSerializer:(FPEnvironmentLogSerializer *)environmentLogSerializer
 priceEventStreamSerializer:(FPPriceEventStreamSerializer *)priceEventStreamSerializer
   allowInvalidCertificates:(BOOL)allowInvalidCertificates;

@end
