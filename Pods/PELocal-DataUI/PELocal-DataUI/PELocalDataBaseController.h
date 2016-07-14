//
//  PELocalDataBaseController.h
//  PELocal-DataUI
//
//  Created by Paul Evans on 12/4/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PEObjc-Commons/PEBaseController.h>

@interface PELocalDataBaseController : PEBaseController <UIScrollViewDelegate>

#pragma mark - Initializers

- (instancetype)initWithRequireRepaintNotifications:(NSArray *)notifications;

@end
