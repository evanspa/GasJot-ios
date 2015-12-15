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
#import <FlatUIKit/UIColor+FlatUI.h>
#import "FPUIUtils.h"

CGFloat const FPSPLASH_CONTENT_HEIGH_FACTOR = 0.65;

@implementation FPSplashController {
  id<FPCoordinatorDao> _coordDao;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  NSArray *_carouselViewMakers;
  NSInteger _numCarouselViewMakers;
  UIView *_dotsPanel;
  BOOL _letsGoButtonEnabled;
  //iCarousel *_carousel;
  BOOL _isCarouselRemoved;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<FPCoordinatorDao>)coordDao
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
                             ^UIView *{ return [self carouselViewWithImageNamed:@"carousel-record-data"]; },
                             ^UIView *{ return [self carouselViewWithImageNamed:@"carousel-know-thyself"]; },
                             ^UIView *{ return [self carouselViewWithImageNamed:@"carousel-any-device"]; },
                             ^UIView *{ return [self carouselViewWithImageNamed:@"carousel-offline"]; },
                             ^UIView *{ return [self carouselViewWithImageNamed:@"carousel-export"]; }
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
  [self refreshDotsPanelWithCarousel:carousel contentPanel:carousel.superview vpadding:20.0];
}

#pragma mark - Helpers

- (UIView *)rootCarouselView {
  UIView *panel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:FPSPLASH_CONTENT_HEIGH_FACTOR relativeToView:self.view];
  UILabel *welcome = [PEUIUtils labelWithKey:@"Welcome to"
                                        font:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle1]
                             backgroundColor:[UIColor clearColor]
                                   textColor:[UIColor whiteColor]
                         verticalTextPadding:0.0];
  UIView *appName = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"splash-title"]];
  UILabel *message = [PEUIUtils labelWithKey:@"Ready to start having fun pumping gas?"
                                        font:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                             backgroundColor:[UIColor clearColor]
                                   textColor:[UIColor whiteColor]
                         verticalTextPadding:0.0
                                  fitToWidth:(0.75 * panel.frame.size.width)];
  [message setTextAlignment:NSTextAlignmentCenter];
  [panel setBackgroundColor:[UIColor clearColor]];
  [PEUIUtils placeView:welcome atTopOf:panel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:100.0 hpadding:0.0];
  [PEUIUtils placeView:appName below:welcome onto:panel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:10.0 hpadding:0.0];
  [PEUIUtils placeView:message below:appName onto:panel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:10.0 hpadding:0.0];
  return panel;
}

- (UIView *)carouselViewWithImageNamed:(NSString *)imageName {
  UIView *panel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:FPSPLASH_CONTENT_HEIGH_FACTOR relativeToView:self.view];
  [panel setBackgroundColor:[UIColor clearColor]];
  UIImageView *imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
  [PEUIUtils placeView:imgView atBottomOf:panel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:5.0 hpadding:0.0];
  return panel;
}

- (UIView *)newWhiteDot {
  return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"white-dot"]];
}

- (UIView *)newGrayDot {
  return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gray-dot"]];
}

- (void)refreshDotsPanelWithCarousel:(iCarousel *)carousel
                        contentPanel:(UIView *)contentPanel
                            vpadding:(CGFloat)vpadding {
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
                  onto:contentPanel //self.view
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:vpadding
              hpadding:0.0];
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:self.view fixedHeight:0.0];
  iCarousel *carousel = [[iCarousel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  [carousel setDataSource:self];
  [carousel setDelegate:self];
  [PEUIUtils setFrameWidthOfView:carousel ofWidth:1.0 relativeTo:self.view];
  [PEUIUtils setFrameHeightOfView:carousel ofHeight:FPSPLASH_CONTENT_HEIGH_FACTOR relativeTo:self.view];
  [carousel setPagingEnabled:YES];
  [carousel setBounceDistance:0.25];
  [[self.navigationController navigationBar] setHidden:YES];
  _isCarouselRemoved = NO;
  [PEUIUtils placeView:carousel atTopOf:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:FPContentPanelTopPadding hpadding:0.0];
  CGFloat totalHeight = carousel.frame.size.height + FPContentPanelTopPadding;
  [self refreshDotsPanelWithCarousel:carousel contentPanel:contentPanel vpadding:20.0];
  totalHeight += _dotsPanel.frame.size.height + 20.0;
  UIButton *(^button)(NSString *, id, SEL) = ^UIButton *(NSString *title, id target, SEL sel) {
    UIButton *btn = [PEUIUtils buttonWithKey:title
                                        font:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle1] //[UIFont systemFontOfSize:24]
                             backgroundColor:[UIColor clearColor]
                                   textColor:[UIColor whiteColor]
                disabledStateBackgroundColor:nil
                      disabledStateTextColor:nil
                             verticalPadding:20.0
                           horizontalPadding:0.0
                                cornerRadius:7.0
                                      target:target
                                      action:sel];
    [btn setBackgroundImage:[UIImage imageNamed:@"blue-1-pixel"] forState:UIControlStateNormal];
    [btn setBackgroundImage:[UIImage imageNamed:@"gray-1-pixel"] forState:UIControlStateHighlighted];
    [PEUIUtils setFrameWidthOfView:btn ofWidth:0.85 relativeTo:self.view];
    [PEUIUtils applyBorderToView:btn withColor:[UIColor whiteColor] width:1.25];
    return btn;
  };
  UIButton *startUsing = button(@"Let's Go!", self, @selector(startUsing));
  [startUsing setUserInteractionEnabled:_letsGoButtonEnabled];
  [PEUIUtils addDisclosureIndicatorToButton:startUsing];
  [PEUIUtils placeView:startUsing below:_dotsPanel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeCenter alignmentRelativeToView:self.view vpadding:25.0 hpadding:0.0];
  totalHeight += startUsing.frame.size.height + 25.0;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(NO), @(YES)];
}

#pragma mark - View controller lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.view setBackgroundColor:[UIColor fpAppBlue]];
}

- (void)startUsing {
  FPUser *user = (FPUser *)[_coordDao.userCoordinatorDao newLocalUserWithError:[FPUtils localSaveErrorHandlerMaker]()];
  UITabBarController *tabBarController = (UITabBarController *)[_screenToolkit newTabBarHomeLandingScreenMakerIsLoggedIn:NO
                                                                                                         tagForJotButton:FPJotButtonTag](user);
  [APP setUser:user tabBarController:tabBarController];
  [[self navigationController] pushViewController:tabBarController animated:YES];
}

@end
