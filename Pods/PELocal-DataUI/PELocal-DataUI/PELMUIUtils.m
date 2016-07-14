//
//  PELMUIUtils.m
//  PELocal-DataUI
//
//  Created by Paul Evans on 6/12/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import "PELMUIUtils.h"
#import <PEObjc-Commons/PEUIUtils.h>
#import <FlatUIKit/UIColor+FlatUI.h>
#import <PELocal-Data/PELMMainSupport.h>

@implementation PELMUIUtils

+ (PETableCellContentViewStyler)syncViewStylerWithUitoolkit:(PEUIToolkit *)uitoolkit
                                       subtitleLeftHPadding:(CGFloat)subtitleLeftHPadding
                                   subtitleFitToWidthFactor:(CGFloat)subtitleFitToWidthFactor
                                                 isLoggedIn:(BOOL)isLoggedIn {
  return [self syncViewStylerWithTitleBlk:nil
                   alwaysTopifyTitleLabel:NO
                                uitoolkit:uitoolkit
                     subtitleLeftHPadding:subtitleLeftHPadding
                 subtitleFitToWidthFactor:subtitleFitToWidthFactor
                               isLoggedIn:isLoggedIn];
}

+ (PETableCellContentViewStyler)syncViewStylerWithTitleBlk:(NSString *(^)(id))titleBlk
                                    alwaysTopifyTitleLabel:(BOOL)alwaysTopifyTitleLabel
                                                 uitoolkit:(PEUIToolkit *)uitoolkit
                                      subtitleLeftHPadding:(CGFloat)subtitleLeftHPadding
                                  subtitleFitToWidthFactor:(CGFloat)subtitleFitToWidthFactor
                                                isLoggedIn:(BOOL)isLoggedIn {
  NSInteger titleTag = 89;
  NSInteger subtitleTag = 90;
  NSInteger warningIconTag = 91;
  CGFloat vpaddingForTopifiedTitleToFitNeedFixIcon = 8.0;
  CGFloat vpaddingForTopifiedTitleToFitSubtitle = 11.0;
  void (^removeView)(NSInteger, UIView *) = ^(NSInteger tag, UIView *view) {
    [[view viewWithTag:tag] removeFromSuperview];
  };
  NSString * (^truncatedTitleText)(id) = ^NSString *(id dataObject) {
    NSInteger maxLength = 35;
    NSString *title = titleBlk(dataObject);
    if ([title length] > maxLength) {
      title = [[title substringToIndex:maxLength] stringByAppendingString:@"..."];
    }
    return title;
  };
  return ^(UITableViewCell *cell, UIView *view, id dataObject) {
    removeView(titleTag, view);
    removeView(subtitleTag, view);
    removeView(warningIconTag, view);
    PELMMainSupport *entity = (PELMMainSupport *)dataObject;
    NSString *subTitleMsg = nil;
    BOOL syncWarningNeedsFix = NO;
    BOOL syncWarningTemporary = NO;
    CGFloat vpaddingForTopification = vpaddingForTopifiedTitleToFitSubtitle;
    if ([entity editInProgress]) {
      subTitleMsg = @"editing";
    } else if (isLoggedIn) {
      if ([entity syncInProgress]) {
        subTitleMsg = @"synching";
      } else if (![entity globalIdentifier] || ([entity editCount] > 0)) {
        if ([entity syncErrMask] && ([entity syncErrMask].integerValue > 0)) {
          syncWarningNeedsFix = YES;
          subTitleMsg = @"needs fixing";
          vpaddingForTopification = vpaddingForTopifiedTitleToFitNeedFixIcon;
        } else {
          subTitleMsg = @"sync needed";
        }
      }
    }
    
    // place title label
    UILabel *titleLabel = nil;
    if (titleBlk) {
      titleLabel = [uitoolkit tableCellTitleMaker](truncatedTitleText(entity), view.frame.size.width);
      [titleLabel setTag:titleTag];
      if (subTitleMsg) {
        [PEUIUtils placeView:titleLabel
                     atTopOf:view
               withAlignment:PEUIHorizontalAlignmentTypeLeft
                    vpadding:vpaddingForTopification
                    hpadding:15.0];
      } else {
        [PEUIUtils placeView:titleLabel
                  inMiddleOf:view
               withAlignment:PEUIHorizontalAlignmentTypeLeft
                    hpadding:15.0];
      }
    }
    
    // place subtitle label
    if (subTitleMsg) {
      UIColor *textColor = [UIColor grayColor];
      UILabel *subtitleLabel;
      if (syncWarningNeedsFix) {
        textColor = [UIColor sunflowerColor];
        UIImage *syncWarningIcon = [UIImage imageNamed:@"warning-icon"];
        UIImageView *syncWarningIconView = [[UIImageView alloc] initWithImage:syncWarningIcon];
        [syncWarningIconView setTag:warningIconTag];
        [PEUIUtils placeView:syncWarningIconView
                  atBottomOf:view
               withAlignment:PEUIHorizontalAlignmentTypeLeft
                    vpadding:4.0
                    hpadding:subtitleLeftHPadding];
        subtitleLabel = [uitoolkit tableCellSubtitleMaker](subTitleMsg,
                                                           (subtitleFitToWidthFactor * view.frame.size.width)
                                                           - (syncWarningIconView.frame.size.width + 2.0));
        [PEUIUtils placeView:subtitleLabel
                toTheRightOf:syncWarningIconView
                        onto:view
               withAlignment:PEUIVerticalAlignmentTypeMiddle
                    hpadding:2.0];
      } else {
        if (syncWarningTemporary) {
          textColor = [UIColor sunflowerColor];
        }
        subtitleLabel = [uitoolkit tableCellSubtitleMaker](subTitleMsg,
                                                           (subtitleFitToWidthFactor * view.frame.size.width)
                                                           - subtitleLeftHPadding);
        [PEUIUtils placeView:subtitleLabel
                       below:titleLabel
                        onto:view
               withAlignment:PEUIHorizontalAlignmentTypeLeft
                    vpadding:4.0
                    hpadding:0.0];
      }
      [subtitleLabel setTextColor:textColor];
      [subtitleLabel setTag:subtitleTag];
    }
  };
}


@end
