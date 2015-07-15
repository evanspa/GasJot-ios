//
//  PELMUIUtils.m
//  PEFuelPurchase-App
//
//  Created by Paul Evans on 6/12/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import "PELMUIUtils.h"
#import <PEObjc-Commons/PEUIUtils.h>
#import <FlatUIKit/UIColor+FlatUI.h>

@implementation PELMUIUtils

+ (PESyncViewStyler)syncViewStylerWithUitoolkit:(PEUIToolkit *)uitoolkit
                           subtitleLeftHPadding:(CGFloat)subtitleLeftHPadding
                                     isLoggedIn:(BOOL)isLoggedIn {
  return [self syncViewStylerWithTitleBlk:nil
                   alwaysTopifyTitleLabel:NO
                                uitoolkit:uitoolkit
                     subtitleLeftHPadding:subtitleLeftHPadding
                               isLoggedIn:isLoggedIn];
}

+ (PESyncViewStyler)syncViewStylerWithTitleBlk:(NSString *(^)(id))titleBlk
                        alwaysTopifyTitleLabel:(BOOL)alwaysTopifyTitleLabel
                                     uitoolkit:(PEUIToolkit *)uitoolkit
                          subtitleLeftHPadding:(CGFloat)subtitleLeftHPadding
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
  return ^(UIView *view, id dataObject) {
    removeView(titleTag, view);
    removeView(subtitleTag, view);
    removeView(warningIconTag, view);
    PELMMainSupport *entity = (PELMMainSupport *)dataObject;
    NSString *subTitleMsg = nil;
    BOOL syncWarningNeedsFix = NO;
    BOOL syncWarningTemporary = NO;
    CGFloat vpaddingForTopification = vpaddingForTopifiedTitleToFitSubtitle;
    if ([entity editInProgress]) {
      subTitleMsg = @"Edit in progress.";
    } else if (isLoggedIn) {
      if ([entity syncInProgress]) {
        subTitleMsg = @"Sync in progress.";
      } else if (![entity globalIdentifier] || ([entity editCount] > 0)) {
        if ([entity syncErrMask] && ([entity syncErrMask].integerValue > 0)) {
          syncWarningNeedsFix = YES;
          subTitleMsg = @"Needs fixing.";
          vpaddingForTopification = vpaddingForTopifiedTitleToFitNeedFixIcon;
        } else {
          subTitleMsg = @"Sync needed.";
        }
      }
    }
    
    // place title label
    if (titleBlk) {
      UILabel *titleLabel = [uitoolkit tableCellTitleMaker](truncatedTitleText(entity));
      [titleLabel setTag:titleTag];
      if (alwaysTopifyTitleLabel) {
        [PEUIUtils placeView:titleLabel
                     atTopOf:view
               withAlignment:PEUIHorizontalAlignmentTypeLeft
                    vpadding:vpaddingForTopification
                    hpadding:15.0];
      } else {
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
    }
    
    // place subtitle label
    if (subTitleMsg) {
      UIColor *textColor = [UIColor grayColor];
      UILabel *subtitleLabel = [uitoolkit tableCellSubtitleMaker](subTitleMsg);
      [subtitleLabel setTag:subtitleTag];
      if (syncWarningNeedsFix) {
        textColor = [UIColor sunflowerColor];
        UIImage *syncWarningIcon = [UIImage imageNamed:@"warning-icon"];
        UIImageView *syncWarningIconView = [[UIImageView alloc] initWithImage:syncWarningIcon];
        [syncWarningIconView setTag:warningIconTag];
        [PEUIUtils placeView:syncWarningIconView
                  atBottomOf:view
               withAlignment:PEUIHorizontalAlignmentTypeLeft
                    vpadding:2.0
                    hpadding:subtitleLeftHPadding]; //2.0];
        [PEUIUtils placeView:subtitleLabel
                toTheRightOf:syncWarningIconView
                        onto:view
               withAlignment:PEUIVerticalAlignmentTypeBottom
                    hpadding:2.0];
      } else {
        if (syncWarningTemporary) {
          textColor = [UIColor sunflowerColor];
        }
        [PEUIUtils placeView:subtitleLabel
                  atBottomOf:view
               withAlignment:PEUIHorizontalAlignmentTypeLeft
                    vpadding:2.0
                    hpadding:subtitleLeftHPadding]; //2.0];
      }
      [subtitleLabel setTextColor:textColor];
    }
  };
}


@end
