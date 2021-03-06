//
//  PEBaseController.m
//  PEObjc-Commons
//
//  Created by Paul Evans on 12/4/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "PEBaseController.h"
#import "PEUIUtils.h"

@implementation PEBaseController {
  UIView *_displayPanel;
  CGPoint _scrollContentOffset;
  NSArray *_requireRepaintNotifications;
}

#pragma mark - Initializers

- (instancetype)initWithRequireRepaintNotifications:(NSArray *)notifications {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _requireRepaintNotifications = notifications;
  }
  return self;
}

#pragma mark - Dynamic Type Support

- (void)changeTextSize:(NSNotification *)notification {
  _needsRepaint = YES;
  [self viewDidAppear:YES];
}

#pragma mark - Scroll View Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  _scrollContentOffset = [scrollView contentOffset];
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel { return nil; }

#pragma mark - Reset Scroll Offset

- (void)resetScrollOffset {
  _scrollContentOffset = CGPointMake(0.0, 0.0);
}

#pragma mark - Hide Keyboard

- (void)hideKeyboard {
  [self.view endEditing:YES];
}

#pragma mark - Notification Observing

- (void)requireRepaint:(NSNotification *)notification {
  _needsRepaint = YES;
}

#pragma mark - Display Panel

- (UIView *)makeDisplayPanelWithContentPanel:(UIView *)contentPanel
                               withScrolling:(BOOL)scrolling
                                      center:(BOOL)center {
  return [PEUIUtils displayPanelFromContentPanel:contentPanel
                                       scrolling:scrolling
                             scrollContentOffset:_scrollContentOffset
                                  scrollDelegate:self
                            delaysContentTouches:YES
                                         bounces:YES
                                notScrollViewBlk:^{ [self resetScrollOffset]; }
                                        centered:center
                                      controller:self];
}

- (void)placeDisplayPanelWithCentering:(BOOL)centering {
  void (^placeOnTop)(void) = ^{
    CGFloat vpadding = 0.0;
    if (self.navigationController && !self.navigationController.navigationBar.hidden) {
      /* 20.0 = statusBarFrame height.  The reason for hard-coding it and not using
       the actual height is because when there's a phone call or hotspot connection
       active, the statusBarFrame's height grows to 40.0; but since we don't care about
       that, we just have to hardcode to 20.0
       */
      vpadding = (20.0 + self.navigationController.navigationBar.frame.size.height);
    }
    [PEUIUtils placeView:_displayPanel
                 atTopOf:self.view
           withAlignment:PEUIHorizontalAlignmentTypeCenter
                vpadding:vpadding
                hpadding:0.0];
  };
  if ([_displayPanel isKindOfClass:[UIScrollView class]]) {
    placeOnTop();
  } else {
    if (centering) {
      if (self.navigationController && !self.navigationController.navigationBar.hidden) {
        if (self.tabBarController) {
          [PEUIUtils placeView:_displayPanel
                          onto:self.view
               inMiddleBetween:self.navigationController.navigationBar
                           and:self.tabBarController.tabBar
                 withAlignment:PEUIHorizontalAlignmentTypeCenter
                      hpadding:0.0];
        } else {
          [PEUIUtils placeView:_displayPanel
                          onto:self.view
               inMiddleBetween:self.navigationController.navigationBar
                     andYCoord:self.view.frame.size.height
                 withAlignment:PEUIHorizontalAlignmentTypeCenter
                      hpadding:0.0];
        }
      } else if (self.tabBarController) {
        [PEUIUtils placeView:_displayPanel
                        onto:self.view
       inMiddleBetweenYCoord:self.view.frame.origin.y
                     andView:self.tabBarController.tabBar
               withAlignment:PEUIHorizontalAlignmentTypeCenter
                    hpadding:0.0];
      } else {
        [PEUIUtils placeView:_displayPanel
                  inMiddleOf:self.view
               withAlignment:PEUIHorizontalAlignmentTypeCenter
                    hpadding:0.0];
      }
    } else {
      placeOnTop();
    }
  }
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setAutomaticallyAdjustsScrollViewInsets:NO];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeTextSize:)
                                               name:UIContentSizeCategoryDidChangeNotification
                                             object:nil];
  
  if (_requireRepaintNotifications) {
    for (NSString *notificationName in _requireRepaintNotifications) {
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(requireRepaint:)
                                                   name:notificationName
                                                 object:nil];
    }
  }
  UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
  [gestureRecognizer setCancelsTouchesInView:NO];
  [self.view addGestureRecognizer:gestureRecognizer];
  NSArray *content = [self makeContentWithOldContentPanel:nil];
  UIView *contentPanel = content[0];
  BOOL scrolling = [(NSNumber *)content[1] boolValue];
  BOOL center = [(NSNumber *) content[2] boolValue];
  _displayPanel = [self makeDisplayPanelWithContentPanel:contentPanel
                                           withScrolling:scrolling
                                                  center:center];
  
  [self placeDisplayPanelWithCentering:center];
  _needsRepaint = NO;
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  //NSLog(@"inside PEBaseController, viewDidAppear, _needsRepaint: %d, ctrl: %@", _needsRepaint, NSStringFromClass(self.class));
  if (_needsRepaint) {
    NSArray *content = [self makeContentWithOldContentPanel:_displayPanel];
    [_displayPanel removeFromSuperview];
    UIView *contentPanel = content[0];
    BOOL scrolling = [(NSNumber *)content[1] boolValue];
    BOOL center = [(NSNumber *) content[2] boolValue];
    _displayPanel = [self makeDisplayPanelWithContentPanel:contentPanel
                                             withScrolling:scrolling
                                                    center:center];
    [self placeDisplayPanelWithCentering:center];
    _needsRepaint = NO;
  }
}

@end
