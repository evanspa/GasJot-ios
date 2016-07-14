//
//  PELMUIUtils.h
//  PELocal-DataUI
//
//  Created by Paul Evans on 6/12/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PEObjc-Commons/PEUIToolkit.h>
#import "PEUIDefs.h"

@interface PELMUIUtils : NSObject

+ (PETableCellContentViewStyler)syncViewStylerWithUitoolkit:(PEUIToolkit *)uitoolkit
                                       subtitleLeftHPadding:(CGFloat)subtitleLeftHPadding
                                   subtitleFitToWidthFactor:(CGFloat)subtitleFitToWidthFactor
                                                 isLoggedIn:(BOOL)isLoggedIn;

+ (PETableCellContentViewStyler)syncViewStylerWithTitleBlk:(NSString *(^)(id))titleBlk
                                    alwaysTopifyTitleLabel:(BOOL)alwaysTopifyTitleLabel
                                                 uitoolkit:(PEUIToolkit *)uitoolkit
                                      subtitleLeftHPadding:(CGFloat)subtitleLeftHPadding
                                  subtitleFitToWidthFactor:(CGFloat)subtitleFitToWidthFactor
                                                isLoggedIn:(BOOL)isLoggedIn;

@end
