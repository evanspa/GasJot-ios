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
  FPCoordinatorDao *_coordDao;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  NSString *_entityTypeLabelText;
  FPEntityNameBlk _entityNameBlk;
  id _entity;
  NSArray *_statLaunchButtons;
}

#pragma mark - Initializers

- (id)initWithScreenTitle:(NSString *)screenTitle
      entityTypeLabelText:(NSString *)entityTypeLabelText
            entityNameBlk:(FPEntityNameBlk)entityNameBlk
                   entity:(id)entity
        statLaunchButtons:(NSArray *)statLaunchButtons
                uitoolkit:(PEUIToolkit *)uitoolkit {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _screenTitle = screenTitle;
    _entityTypeLabelText = entityTypeLabelText;
    _entityNameBlk = entityNameBlk;
    _entity = entity;
    _statLaunchButtons = statLaunchButtons;
    _uitoolkit = uitoolkit;
  }
  return self;
}

#pragma mark - View controller lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  [self setTitle:_screenTitle];
  NSAttributedString *entityHeaderText = [PEUIUtils attributedTextWithTemplate:[[NSString stringWithFormat:@"(%@: ", _entityTypeLabelText] stringByAppendingString:@"%@)"]
                                                                  textToAccent:_entityNameBlk(_entity)
                                                                accentTextFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]
                                                               accentTextColor:[UIColor fpAppBlue]];
  UILabel *entityLabel = [PEUIUtils labelWithAttributeText:entityHeaderText
                                                      font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                  fontForHeightCalculation:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]
                                           backgroundColor:[UIColor clearColor]
                                                 textColor:[UIColor darkGrayColor]
                                       verticalTextPadding:3.0
                                                fitToWidth:self.view.frame.size.width - 15.0];
  
  NSMutableArray *viewColumn = [NSMutableArray arrayWithCapacity:_statLaunchButtons.count];
  for (NSArray *statLaunchButtonArray in _statLaunchButtons) {
    NSString *buttonTitle = statLaunchButtonArray[0];
    UIViewController *(^statScreenMaker)(void) = statLaunchButtonArray[1];
    NSAttributedString *descriptionAttrText = statLaunchButtonArray[2];
    
    UIButton *btn = [_uitoolkit systemButtonMaker](buttonTitle, nil, nil);
    [PEUIUtils setFrameWidthOfView:btn ofWidth:1.0 relativeTo:self.view];
    [PEUIUtils addDisclosureIndicatorToButton:btn];
    [btn bk_addEventHandler:^(id sender) {
      [self.navigationController pushViewController:statScreenMaker()
                                           animated:YES];
    } forControlEvents:UIControlEventTouchUpInside];
    UILabel *descriptionLabel = [PEUIUtils labelWithAttributeText:descriptionAttrText
                                                             font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                         fontForHeightCalculation:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]
                                                  backgroundColor:[UIColor clearColor]
                                                        textColor:[UIColor darkGrayColor]
                                              verticalTextPadding:3.0
                                                       fitToWidth:self.view.frame.size.width - 15.0];
    UIView *btnPanel = [PEUIUtils panelWithFixedWidth:self.view.frame.size.width fixedHeight:btn.frame.size.height + descriptionLabel.frame.size.height + 4.0];
    [PEUIUtils placeView:btn atTopOf:btnPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
    [PEUIUtils placeView:descriptionLabel below:btn onto:btnPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:self.view vpadding:4.0 hpadding:8.0];
    [viewColumn addObject:btnPanel];
  }
  
  
  /*UIButton *gasCostPerMileBtn = [_uitoolkit systemButtonMaker](@"Gas cost per mile", nil, nil);
  [PEUIUtils setFrameWidthOfView:gasCostPerMileBtn ofWidth:1.0 relativeTo:self.view];
  [PEUIUtils addDisclosureIndicatorToButton:gasCostPerMileBtn];
  [gasCostPerMileBtn bk_addEventHandler:^(id sender) {
    [self.navigationController pushViewController:[_screenToolkit newVehicleGasCostPerMileStatsScreenMakerWithVehicle:_vehicle](_user)
                                         animated:YES];
  } forControlEvents:UIControlEventTouchUpInside];
  UILabel *gasCostPerMileMsg = [PEUIUtils labelWithKey:@"Stats and trend information on the average cost of a mile.  \
The cost of a mile is calculated by dividing the total amount spent on gas by the total number of recorded miles driven (from odometer logs)."
                                                  font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                       backgroundColor:[UIColor clearColor]
                                             textColor:[UIColor darkGrayColor]
                                   verticalTextPadding:3.0
                                            fitToWidth:self.view.frame.size.width - 15.0];
  
  
  UIButton *spentOnGasBtn = [_uitoolkit systemButtonMaker](@"Amount spent on gas", nil, nil);
  [PEUIUtils setFrameWidthOfView:spentOnGasBtn ofWidth:1.0 relativeTo:self.view];
  [PEUIUtils addDisclosureIndicatorToButton:spentOnGasBtn];
  [spentOnGasBtn bk_addEventHandler:^(id sender) {
    [self.navigationController pushViewController:[_screenToolkit newVehicleSpentOnGasStatsScreenMakerWithVehicle:_vehicle](_user)
                                         animated:YES];
  } forControlEvents:UIControlEventTouchUpInside];
  NSAttributedString *spentOnGasMsgText = [PEUIUtils attributedTextWithTemplate:@"Stats and trend information on the total amount spent on gas:\n(per price gallon %@ number of gallons)."
                                                                   textToAccent:@"x"
                                                                 accentTextFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]];
  UILabel *spentOnGasMsg = [PEUIUtils labelWithAttributeText:spentOnGasMsgText
                                                        font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                    fontForHeightCalculation:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]
                                             backgroundColor:[UIColor clearColor]
                                                   textColor:[UIColor darkGrayColor]
                                         verticalTextPadding:3.0
                                                  fitToWidth:self.view.frame.size.width - 15.0];*/
  
  // place the views
  [PEUIUtils placeView:entityLabel atTopOf:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:80.0 hpadding:8.0];
  
  [PEUIUtils placeView:[PEUIUtils panelWithColumnOfViews:viewColumn verticalPaddingBetweenViews:18.0 viewsAlignment:PEUIHorizontalAlignmentTypeLeft]
                 below:entityLabel
                  onto:self.view
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:self.view
              vpadding:20.0
              hpadding:0.0];
  
  
  /*[PEUIUtils placeView:gasCostPerMileBtn below:vehicleLabel onto:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:self.view vpadding:20.0 hpadding:0.0];
  [PEUIUtils placeView:gasCostPerMileMsg below:gasCostPerMileBtn onto:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:4.0 hpadding:8.0];
  [PEUIUtils placeView:spentOnGasBtn below:gasCostPerMileMsg onto:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:self.view vpadding:20.0 hpadding:0.0];
  [PEUIUtils placeView:spentOnGasMsg below:spentOnGasBtn onto:self.view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:4.0 hpadding:8.0];*/
}

@end
