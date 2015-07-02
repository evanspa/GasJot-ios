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
        UIImage *syncWarningIcon = [UIImage imageNamed:@"sync-warning"];
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
  
  /*NSString * (^titleText)(id) = ^NSString *(id dataObject) {
    NSInteger maxLength = 35;
    NSString *title = titleBlk(dataObject);
    if ([title length] > maxLength) {
      title = [[title substringToIndex:maxLength] stringByAppendingString:@"..."];
    }
    return title;
  };
  void (^setTitleText)(UILabel *, id) = ^(UILabel *titleLbl, id dataObject) {
    [titleLbl setText:titleText(dataObject)];
  };
  NSInteger titleNameTag = 1;
  NSInteger subTitleTag = 2;
  NSInteger subTitleWarningImageTag = 3;
  return ^(UIView *view, id dataObject) {
    void (^placeSubtitleLabel)(UILabel *, BOOL, BOOL) = ^(UILabel *subtitleLabel, BOOL syncWarningNeedsFix, BOOL syncWarningTemporary) {
      if (syncWarningNeedsFix) {
        UIImage *syncWarningIcon = [UIImage imageNamed:@"sync-warning"];
        UIImageView *syncWarningIconView = [[UIImageView alloc] initWithImage:syncWarningIcon];
        [syncWarningIconView setTag:subTitleWarningImageTag];
        [PEUIUtils placeView:syncWarningIconView
                  atBottomOf:view
               withAlignment:PEUIHorizontalAlignmentTypeLeft
                    vpadding:2.0
                    hpadding:2.0];
        [PEUIUtils placeView:subtitleLabel
                toTheRightOf:syncWarningIconView
                        onto:view
               withAlignment:PEUIVerticalAlignmentTypeBottom
                    hpadding:2.0];
      } else {
        UIView *subTitleWarningImageView = [view viewWithTag:subTitleWarningImageTag];
        if (subTitleWarningImageView) {
          [subTitleWarningImageView removeFromSuperview];
        }
        [subtitleLabel setTextColor:[UIColor blueColor]];
        [PEUIUtils placeView:subtitleLabel
                  atBottomOf:view
               withAlignment:PEUIHorizontalAlignmentTypeLeft
                    vpadding:5.0
                    hpadding:3.0];
      }
    };
    PELMMainSupport *entity = (PELMMainSupport *)dataObject;
    NSString *subTitleMsg = nil;
    CGFloat vpaddingForTopifiedTitle = 8.0;
    BOOL syncWarningNeedsFix = NO;
    BOOL syncWarningTemporary = NO;
    if ([entity editInProgress]) {
      if ([[entity editActorId] isEqualToNumber:@(foregroundActorId)]) {
        subTitleMsg = @"Edit in progress.";
      } else {
        subTitleMsg = @"Edit in progress (by background-processor)";
      }
    } else if ([entity syncInProgress]) {
      subTitleMsg = @"Sync in progress.";
    } else if (![entity globalIdentifier] || ([entity editCount] > 0)) {
      if ([entity syncErrMask] && ([entity syncErrMask].integerValue > 0)) {
        syncWarningNeedsFix = YES;
        subTitleMsg = @"Needs fixing.";
      } else if ([entity syncHttpRespCode] || ([entity syncErrMask] && ([entity syncErrMask].integerValue <= 0))) {
        syncWarningTemporary = YES;
        subTitleMsg = @"Temporary sync problem.";
      } else if ([entity syncRetryAt]) {
        subTitleMsg = @"Will retry sync later.";
      } else {
        subTitleMsg = @"Sync pending.";
      }
    }
    UILabel *titleLbl = (UILabel *)[view viewWithTag:titleNameTag];
    UILabel *subTitleLbl = nil;
    //[titleLbl removeFromSuperview];
    //[[view viewWithTag:subTitleTag] removeFromSuperview];
    //[[view viewWithTag:subTitleWarningImageTag] removeFromSuperview];
    void (^removeAndCenterLabel)(UILabel *) = ^(UILabel *lbl) {
      [lbl removeFromSuperview];
      [PEUIUtils placeView:titleLbl
                inMiddleOf:view
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  hpadding:15.0];
    };
    void (^removeAndTopifyLabel)(UILabel *) = ^(UILabel *lbl) {
      [lbl removeFromSuperview];
      [PEUIUtils placeView:lbl
                   atTopOf:view
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:vpaddingForTopifiedTitle
                  hpadding:15.0];
    };
    if (titleBlk && titleLbl) {
      setTitleText(titleLbl, dataObject);
      subTitleLbl = (UILabel *)[view viewWithTag:subTitleTag];
      if (subTitleMsg || alwaysTopifyTitleLabel) {
        if (!subTitleLbl) {
          // first, let's remove the title label and re-add so it's properly
          // aligned at the top
          removeAndTopifyLabel(titleLbl);
          LabelMaker tableCellSubtitleMaker = [uitoolkit tableCellSubtitleMaker];
          subTitleLbl = tableCellSubtitleMaker(subTitleMsg);
          [subTitleLbl setTag:subTitleTag];
          [PEUIUtils setFrameWidthOfView:subTitleLbl
                                 ofWidth:1.0
                              relativeTo:view];
          placeSubtitleLabel(subTitleLbl, syncWarningNeedsFix, syncWarningTemporary);
        } else {
          [subTitleLbl setText:subTitleMsg];
        }
      } else {
        subTitleLbl = (UILabel *)[view viewWithTag:subTitleTag];
        UIView *subTitleWarningImageView = [view viewWithTag:subTitleWarningImageTag];
        if (subTitleLbl) {
          [subTitleLbl removeFromSuperview];
          if (subTitleWarningImageView) {
            [subTitleWarningImageView removeFromSuperview];
          }
          if (!alwaysTopifyTitleLabel) {
            // because subTitleLbl is NOT nil, then titleLbl is currently placed
            // at the top of the cell; this is bad; it should be centered.  So
            // we'll remove it and re-add it.
            removeAndCenterLabel(titleLbl);
          }
        }
      }
    } else {
      LabelMaker tableCellTitleMaker = [uitoolkit tableCellTitleMaker];
      LabelMaker tableCellSubtitleMaker = [uitoolkit tableCellSubtitleMaker];
      if (titleBlk) {
        titleLbl = tableCellTitleMaker(titleText(dataObject));
        [titleLbl setTag:titleNameTag];
        [PEUIUtils setFrameWidthOfView:titleLbl
                               ofWidth:1.0
                            relativeTo:view];
      }
      if (subTitleMsg) {
        if (titleBlk) {
          [PEUIUtils placeView:titleLbl
                       atTopOf:view
                 withAlignment:PEUIHorizontalAlignmentTypeLeft
                      vpadding:vpaddingForTopifiedTitle
                      hpadding:15.0];
        }
        if (!subTitleLbl) {
          subTitleLbl = tableCellSubtitleMaker(subTitleMsg);
          [subTitleLbl setTag:subTitleTag];
        }
        [PEUIUtils setFrameWidthOfView:subTitleLbl
                               ofWidth:1.0
                            relativeTo:view];
        placeSubtitleLabel(subTitleLbl, syncWarningNeedsFix, syncWarningTemporary);
      } else {
        if (titleBlk) {
          if (alwaysTopifyTitleLabel) {
            [PEUIUtils placeView:titleLbl
                         atTopOf:view
                   withAlignment:PEUIHorizontalAlignmentTypeLeft
                        vpadding:vpaddingForTopifiedTitle
                        hpadding:15.0];
          } else {
            [PEUIUtils placeView:titleLbl
                      inMiddleOf:view
                   withAlignment:PEUIHorizontalAlignmentTypeLeft
                        hpadding:15.0];
          }
        }
      }
    }
    if (subTitleLbl && (syncWarningNeedsFix || syncWarningTemporary)) {
      [subTitleLbl setTextColor:[UIColor sunflowerColor]];
    } else if (subTitleLbl) {
      [subTitleLbl setTextColor:[UIColor grayColor]];
    }
  };*/
}


@end
