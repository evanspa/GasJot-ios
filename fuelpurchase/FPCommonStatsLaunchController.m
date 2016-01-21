//
//  FPCommonStatsLaunchController.m
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 10/18/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "FPCommonStatsLaunchController.h"
#import <PEObjc-Commons/PEUtils.h>
#import <PEObjc-Commons/PEUIUtils.h>
#import "FPUtils.h"
#import "FPUIUtils.h"
#import <BlocksKit/UIControl+BlocksKit.h>
#import "UIColor+FPAdditions.h"

@implementation FPCommonStatsLaunchController {
  NSString *_screenTitle;
  id<FPCoordinatorDao> _coordDao;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  NSString *_entityTypeLabelText;
  FPEntityNameBlk _entityNameBlk;
  id _entity;
  NSArray *(^_statLaunchButtonsBlk)(void);
}

#pragma mark - Initializers

- (id)initWithScreenTitle:(NSString *)screenTitle
      entityTypeLabelText:(NSString *)entityTypeLabelText
            entityNameBlk:(FPEntityNameBlk)entityNameBlk
                   entity:(id)entity
     statLaunchButtonsBlk:(NSArray *(^)(void))statLaunchButtonsBlk
                uitoolkit:(PEUIToolkit *)uitoolkit {
  self = [super initWithRequireRepaintNotifications:nil];
  if (self) {
    _screenTitle = screenTitle;
    _entityTypeLabelText = entityTypeLabelText;
    _entityNameBlk = entityNameBlk;
    _entity = entity;
    _statLaunchButtonsBlk = statLaunchButtonsBlk;
    _uitoolkit = uitoolkit;
  }
  return self;
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  UILabel *entityLabel = nil;
  if (_entityNameBlk) {
    NSString *entityName = [FPUtils truncatedText:_entityNameBlk(_entity) maxLength:27];
    NSAttributedString *entityHeaderText = [PEUIUtils attributedTextWithTemplate:[[NSString stringWithFormat:@"%@: ", _entityTypeLabelText] stringByAppendingString:@"%@"]
                                                                    textToAccent:entityName
                                                                  accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]
                                                                 accentTextColor:[UIColor fpAppBlue]];
    entityLabel = [PEUIUtils labelWithAttributeText:entityHeaderText
                                               font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                           fontForHeightCalculation:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]
                                    backgroundColor:[UIColor clearColor]
                                          textColor:[UIColor darkGrayColor]
                                verticalTextPadding:3.0
                                         fitToWidth:self.view.frame.size.width - 15.0];
  }
  NSArray *statLaunchButtons = _statLaunchButtonsBlk();
  NSMutableArray *viewColumn = [NSMutableArray arrayWithCapacity:statLaunchButtons.count];
  for (id statLaunchButtonElement in statLaunchButtons) {
    if ([statLaunchButtonElement isKindOfClass:[NSArray class]]) {
      NSArray *statLaunchButtonArray = statLaunchButtonElement;
      if (statLaunchButtonArray.count == 1) {
        UIView *(^viewMaker)(void) = statLaunchButtonArray[0];
        [viewColumn addObject:viewMaker()];
      } else {
        NSString *buttonTitle = statLaunchButtonArray[0];
        UIViewController *(^statScreenMaker)(void) = statLaunchButtonArray[1];
        UIButton *btn = [_uitoolkit systemButtonMaker](buttonTitle, nil, nil);
        [PEUIUtils setFrameWidthOfView:btn ofWidth:1.0 relativeTo:self.view];
        [PEUIUtils addDisclosureIndicatorToButton:btn];
        [btn bk_addEventHandler:^(id sender) {
          [self.navigationController pushViewController:statScreenMaker()
                                               animated:YES];
        } forControlEvents:UIControlEventTouchUpInside];
        
        CGFloat btnPanelHeight = btn.frame.size.height;
        UILabel *descriptionLabel = nil;
        if (statLaunchButtonArray.count > 2) {
          NSAttributedString *descriptionAttrText = statLaunchButtonArray[2];
          descriptionLabel = [PEUIUtils labelWithAttributeText:descriptionAttrText
                                                          font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                      fontForHeightCalculation:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]
                                               backgroundColor:[UIColor clearColor]
                                                     textColor:[UIColor darkGrayColor]
                                           verticalTextPadding:3.0
                                                    fitToWidth:self.view.frame.size.width - 15.0];
          btnPanelHeight += descriptionLabel.frame.size.height + 4.0;
        }
        UIView *btnPanel = [PEUIUtils panelWithFixedWidth:self.view.frame.size.width fixedHeight:btnPanelHeight];
        [PEUIUtils placeView:btn atTopOf:btnPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
        if (descriptionLabel) {
          [PEUIUtils placeView:descriptionLabel
                         below:btn
                          onto:btnPanel
                 withAlignment:PEUIHorizontalAlignmentTypeLeft
       alignmentRelativeToView:self.view
                      vpadding:4.0
                      hpadding:8.0];
        }
        [viewColumn addObject:btnPanel];
      }
    } else if ([statLaunchButtonElement isKindOfClass:[NSString class]]) {
      NSString *groupHeadingText = statLaunchButtonElement;
      UIView *groupHeadingLabel = [PEUIUtils leftPadView:[PEUIUtils labelWithKey:groupHeadingText
                                                                            font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                                                 backgroundColor:[UIColor clearColor]
                                                                       textColor:[UIColor fpAppBlue]
                                                             verticalTextPadding:3.0
                                                                      fitToWidth:self.view.frame.size.width - 15.0]
                                                 padding:8.0];
      [viewColumn addObject:groupHeadingLabel];
    } else if ([statLaunchButtonElement isKindOfClass:[UIView class]]) {
      [viewColumn addObject:statLaunchButtonElement];
    }
  }
  UIView *buttonsPanel = [PEUIUtils panelWithColumnOfViews:viewColumn
                               verticalPaddingBetweenViews:10.0
                                            viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
  NSMutableArray *views = [NSMutableArray array];
  if (entityLabel) {
    [views addObject:[PEUIUtils leftPadView:entityLabel padding:8.0]];
  }
  [views addObject:buttonsPanel];
  UIView *panel = [PEUIUtils panelWithColumnOfViews:views
                        verticalPaddingBetweenViews:15.0
                                     viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:self.view fixedHeight:panel.frame.size.height + FPContentPanelTopPadding];
  [PEUIUtils placeView:panel atBottomOf:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
  return @[contentPanel, @(YES), @(NO)];
}

#pragma mark - View controller lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  [self setTitle:_screenTitle];
}

@end
