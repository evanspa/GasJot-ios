//
//  PECustomController.h
//  Gas Jot
//
//  Created by Paul Evans on 12/4/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PECustomController : UIViewController <UIScrollViewDelegate>

#pragma mark - Properties

@property (nonatomic) CGPoint scrollContentOffset;

#pragma mark - Make Content

- (NSArray *)makeContent;

#pragma mark - Reset Scroll Offset

- (void)resetScrollOffset;

@end
