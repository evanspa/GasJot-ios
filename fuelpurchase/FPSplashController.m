//
//  FPSplashController.m
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 9/10/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import "FPSplashController.h"
#import "FPNames.h"
#import "FPUtils.h"
#import "FPCreateAccountController.h"
#import "UIColor+FPAdditions.h"

@implementation FPSplashController {
  FPCoordinatorDao *_coordDao;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  NSArray *_carouselViewMakers;
  NSInteger _numCarouselViewMakers;
  UIView *_dotsPanel;
  BOOL _letsGoButtonEnabled;
  iCarousel *_carousel;
  BOOL _isCarouselRemoved;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(FPCoordinatorDao *)coordDao
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(FPScreenToolkit *)screenToolkit
           letsGoButtonEnabled:(BOOL)letsGoButtonEnabled {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
    _letsGoButtonEnabled = letsGoButtonEnabled;
    _carouselViewMakers = @[^UIView *{ return [self rootCarouselView]; },
                            ^UIView *{ return [self rootCarouselView2]; }
                             ];
    _numCarouselViewMakers = [_carouselViewMakers count];
  }
  return self;
}

#pragma mark - iCarousel Data Source

- (NSInteger)numberOfItemsInCarousel:(iCarousel *)carousel {
  return _carouselViewMakers.count;
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(nullable UIView *)view {
  UIView *(^viewMaker)(void) = _carouselViewMakers[index];
  return viewMaker();
}

#pragma mark - iCarousel Delegate

- (void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel {
  [self refreshDotsPanelWithCarousel:carousel];
}

#pragma mark - Helpers

- (UIView *)rootCarouselView {
  UIView *northPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:0.5 relativeToView:self.view];
  UILabel *welcome = [PEUIUtils labelWithKey:@"Welcome to"
                                        font:[UIFont systemFontOfSize:20]
                             backgroundColor:[UIColor clearColor]
                                   textColor:[UIColor whiteColor]
                         verticalTextPadding:0.0];
  UIView *appName = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"splash-title"]];
  UILabel *message = [PEUIUtils labelWithKey:@"Ready to start having fun pumping gas?"
                                        font:[UIFont systemFontOfSize:14]
                             backgroundColor:[UIColor clearColor]
                                   textColor:[UIColor whiteColor]
                         verticalTextPadding:0.0 fitToWidth:(0.4 * northPanel.frame.size.width)];
  [message setTextAlignment:NSTextAlignmentCenter];
  [northPanel setBackgroundColor:[UIColor clearColor]];
  [PEUIUtils placeView:welcome atTopOf:northPanel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:100.0 hpadding:0.0];
  [PEUIUtils placeView:appName below:welcome onto:northPanel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:10.0 hpadding:0.0];
  [PEUIUtils placeView:message below:appName onto:northPanel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:10.0 hpadding:0.0];
  return northPanel;
}

- (UIView *)rootCarouselView2 {
  UIView *northPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:0.5 relativeToView:self.view];
  UILabel *welcome = [PEUIUtils labelWithKey:@"Welcome TOOO"
                                        font:[UIFont systemFontOfSize:20]
                             backgroundColor:[UIColor clearColor]
                                   textColor:[UIColor whiteColor]
                         verticalTextPadding:0.0];
  UIView *appName = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"splash-title"]];
  UILabel *message = [PEUIUtils labelWithKey:@"Ready to traXk your gas usage?"
                                        font:[UIFont systemFontOfSize:14]
                             backgroundColor:[UIColor clearColor]
                                   textColor:[UIColor whiteColor]
                         verticalTextPadding:0.0 fitToWidth:(0.4 * northPanel.frame.size.width)];
  [message setTextAlignment:NSTextAlignmentCenter];
  [northPanel setBackgroundColor:[UIColor clearColor]];
  [PEUIUtils placeView:welcome atTopOf:northPanel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:100.0 hpadding:0.0];
  [PEUIUtils placeView:appName below:welcome onto:northPanel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:10.0 hpadding:0.0];
  [PEUIUtils placeView:message below:appName onto:northPanel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:10.0 hpadding:0.0];
  return northPanel;
}

- (UIView *)newWhiteDot {
  return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"white-dot"]];
}

- (UIView *)newGrayDot {
  return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gray-dot"]];
}

- (void)refreshDotsPanelWithCarousel:(iCarousel *)carousel {
  if (_dotsPanel) {
    [_dotsPanel removeFromSuperview];
  }
  NSMutableArray *dotImageViews = [NSMutableArray array];
  NSInteger currentWhiteDotIndex = carousel.currentItemIndex;
  for (int i = 0; i < _numCarouselViewMakers; i++) {
    if (i == currentWhiteDotIndex) {
      [dotImageViews addObject:[self newWhiteDot]];
    } else {
      [dotImageViews addObject:[self newGrayDot]];
    }
  }
  _dotsPanel = [PEUIUtils panelWithViews:dotImageViews
                                 ofWidth:1.0
                    vertAlignmentOfViews:PEUIVerticalAlignmentTypeMiddle
                     horAlignmentOfViews:PEUIHorizontalAlignmentTypeCenter
                              relativeTo:self.view
                                vpadding:0.0
                                hpadding:5.0];
  [PEUIUtils placeView:_dotsPanel
                 below:carousel
                  onto:self.view
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:20.0
              hpadding:0.0];
}

#pragma mark - View controller lifecycle

- (void)viewWillDisappear:(BOOL)animated {
  [_carousel removeFromSuperview];
  _isCarouselRemoved = YES;
  [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  if (_isCarouselRemoved) {
    [self.view addSubview:_carousel];
    _isCarouselRemoved = NO;
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.view setBackgroundColor:[UIColor fpAppBlue]];
  _carousel = [[iCarousel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  [_carousel setDataSource:self];
  [_carousel setDelegate:self];
  [PEUIUtils setFrameWidthOfView:_carousel ofWidth:1.0 relativeTo:self.view];
  [PEUIUtils setFrameHeightOfView:_carousel ofHeight:0.5 relativeTo:self.view];
  [_carousel setPagingEnabled:YES];
  [_carousel setBounceDistance:0.25];
  [PEUIUtils placeView:_carousel atTopOf:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
  _isCarouselRemoved = NO;
  [self refreshDotsPanelWithCarousel:_carousel];
  UIView *southPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:0.5 relativeToView:self.view];
  UIButton *(^button)(NSString *, id, SEL) = ^UIButton *(NSString *title, id target, SEL sel) {
    UIButton *btn = [PEUIUtils buttonWithKey:title
                                        font:[UIFont systemFontOfSize:24]
                             backgroundColor:[UIColor clearColor]
                                   textColor:[UIColor whiteColor]
                disabledStateBackgroundColor:nil
                      disabledStateTextColor:nil
                             verticalPadding:50.0
                           horizontalPadding:0.0
                                cornerRadius:7.0
                                      target:target
                                      action:sel];
    [btn setBackgroundImage:[UIImage imageNamed:@"blue-1-pixel"] forState:UIControlStateNormal];
    [btn setBackgroundImage:[UIImage imageNamed:@"gray-1-pixel"] forState:UIControlStateHighlighted];
    [PEUIUtils setFrameWidthOfView:btn ofWidth:0.85 relativeTo:southPanel];
    [PEUIUtils applyBorderToView:btn withColor:[UIColor whiteColor] width:1.25];
    return btn;
  };
  UIButton *startUsing = button(@"Let's Go!", self, @selector(startUsing));
  [startUsing setUserInteractionEnabled:_letsGoButtonEnabled];
  [PEUIUtils addDisclosureIndicatorToButton:startUsing];
  [PEUIUtils placeView:startUsing atBottomOf:southPanel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:100.0 hpadding:0.0];
  [PEUIUtils placeView:southPanel atBottomOf:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
}

- (void)startUsing {
  FPUser *user = [_coordDao newLocalUserWithError:[FPUtils localSaveErrorHandlerMaker]()];
  UITabBarController *tabBarController = (UITabBarController *)[_screenToolkit newTabBarHomeLandingScreenMakerIsLoggedIn:NO](user);
  [APP setUser:user tabBarController:tabBarController];
  [[self navigationController] pushViewController:tabBarController animated:YES];
}

@end
