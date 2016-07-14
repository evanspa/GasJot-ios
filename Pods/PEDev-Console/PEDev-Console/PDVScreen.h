//
//  PDVScreen.h
//  dev-console
//
//  Created by Evans, Paul on 6/18/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PDVScreen : NSObject

#pragma mark - Initializers

- (id)initWithDisplayName:(NSString *)displayName
              description:(NSString *)screenDescription
      viewControllerMaker:(UIViewController *(^)(void))viewControllerMaker;

#pragma mark - Properties

@property (nonatomic, readonly) NSString *displayName;

@property (nonatomic, readonly) NSString *screenDescription;

@property (nonatomic, readonly) UIViewController *(^viewControllerMaker)(void);

@end
