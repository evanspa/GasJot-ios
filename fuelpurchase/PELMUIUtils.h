//
//  PELMUIUtils.h
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 6/12/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PEObjc-Commons/PEUIToolkit.h>

typedef void (^PESyncViewStyler)(UIView *, id);

@interface PELMUIUtils : NSObject

+ (PESyncViewStyler)syncViewStylerWithUitoolkit:(PEUIToolkit *)uitoolkit
                           subtitleLeftHPadding:(CGFloat)subtitleLeftHPadding
                       subtitleFitToWidthFactor:(CGFloat)subtitleFitToWidthFactor
                                     isLoggedIn:(BOOL)isLoggedIn;

+ (PESyncViewStyler)syncViewStylerWithTitleBlk:(NSString *(^)(id))titleBlk
                        alwaysTopifyTitleLabel:(BOOL)alwaysTopifyTitleLabel
                                     uitoolkit:(PEUIToolkit *)uitoolkit
                          subtitleLeftHPadding:(CGFloat)subtitleLeftHPadding
                      subtitleFitToWidthFactor:(CGFloat)subtitleFitToWidthFactor
                                    isLoggedIn:(BOOL)isLoggedIn;

@end
