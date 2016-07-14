//
// PEUIUtils.m
//
// Copyright (c) 2014-2015 PEObjc-Commons
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "PEUtils.h"
#import "PEUIUtils.h"
#import "NSString+PEAdditions.h"
#import "UIImage+PEAdditions.h"
#import "PEObjcCommonsConstantsInternal.h"
#import "UIControl+BlocksKit.h"
#import "UIView+PERoundify.h"

typedef JGActionSheetSection *(^PEAlertSectionMaker)(void);

@implementation PEUIUtils

#pragma mark - Validation Utils

+ (PEMessageCollector)newTfCannotBeEmptyBlkForMsgs:(NSMutableArray *)errMsgs
                                       entityPanel:(UIView *)entityPanel {
  return ^(NSUInteger tag, NSString *errMsg) {
    if ([[PEUIUtils stringFromTextFieldWithTag:tag fromView:entityPanel] isBlank]) {
      [errMsgs addObject:errMsg];
    }
  };
}

#pragma mark - Position Utils

+ (void)setFrameX:(CGFloat)xcoord andY:(CGFloat)ycoord ofView:(UIView *)view {
  CGRect frame = [view frame];
  CGRect newFrame =
  CGRectMake(xcoord, ycoord, frame.size.width, frame.size.height);
  [view setFrame:newFrame];
}

+ (void)setFrameOrigin:(CGPoint)origin ofView:(UIView *)view {
  [PEUIUtils setFrameX:origin.x andY:origin.y ofView:view];
}

+ (void)setFrameX:(CGFloat)xcoord ofView:(UIView *)view {
  [PEUIUtils setFrameX:xcoord andY:view.frame.origin.y ofView:view];
}

+ (void)setFrameY:(CGFloat)ycoord ofView:(UIView *)view {
  [PEUIUtils setFrameX:view.frame.origin.x andY:ycoord ofView:view];
}

+ (void)adjustXOfView:(UIView *)view withValue:(CGFloat)adjust {
  [PEUIUtils setFrameX:([view frame].origin.x + adjust) ofView:view];
}

+ (void)adjustYOfView:(UIView *)view withValue:(CGFloat)adjust {
  [PEUIUtils setFrameY:([view frame].origin.y + adjust) ofView:view];
}

+ (CGFloat)XForWidth:(CGFloat)width
       withAlignment:(PEUIHorizontalAlignmentType)alignment
      relativeToView:(UIView *)relativeToView
            hpadding:(CGFloat)hpadding {
  switch (alignment) {
  case PEUIHorizontalAlignmentTypeLeft:
    return relativeToView.frame.origin.x + hpadding;
  case PEUIHorizontalAlignmentTypeRight:
    return ((relativeToView.frame.size.width - width) +
            relativeToView.frame.origin.x) - hpadding;
  default: // center
    return relativeToView.frame.origin.x -
      ((width - relativeToView.frame.size.width) / 2);
  }
}

+ (CGFloat)YForHeight:(CGFloat)height
        withAlignment:(PEUIVerticalAlignmentType)alignment
       relativeToView:(UIView *)relativeToView
             vpadding:(CGFloat)vpadding {
  switch (alignment) {
  case PEUIVerticalAlignmentTypeTop:
    return relativeToView.frame.origin.y + vpadding;
  case PEUIVerticalAlignmentTypeBottom:
    return ((relativeToView.frame.size.height - height) +
            relativeToView.frame.origin.y) - vpadding;
  default: // center
    return relativeToView.frame.origin.y -
      ((height - relativeToView.frame.size.height) / 2);
  }
}

+ (CGPoint)pointToTheRightOf:(UIView *)view
               withAlignment:(PEUIVerticalAlignmentType)alignment
     alignmentRelativeToView:(UIView *)alignmentRelativeToView
                    hpadding:(CGFloat)hpadding
                forBoxOfSize:(CGSize)size {
  CGRect viewRect = [view frame];
  return CGPointMake(viewRect.origin.x + viewRect.size.width + hpadding,
                     [PEUIUtils YForHeight:size.height
                             withAlignment:alignment
                            relativeToView:alignmentRelativeToView
                                  vpadding:0]);
}

+ (CGPoint)pointToTheLeftOf:(UIView *)view
              withAlignment:(PEUIVerticalAlignmentType)alignment
    alignmentRelativeToView:(UIView *)alignmentRelativeToView
                   hpadding:(CGFloat)hpadding
               forBoxOfSize:(CGSize)size {
  CGRect viewRect = [view frame];
  return CGPointMake(viewRect.origin.x - (size.width + hpadding),
                     [PEUIUtils YForHeight:size.height
                             withAlignment:alignment
                            relativeToView:alignmentRelativeToView
                                  vpadding:0]);
}

+ (CGPoint)pointAbove:(UIView *)view
        withAlignment:(PEUIHorizontalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
             vpadding:(CGFloat)vpadding
             hpadding:(CGFloat)hpadding
         forBoxOfSize:(CGSize)size {
  CGRect viewRect = [view frame];
  return CGPointMake([PEUIUtils XForWidth:size.width
                            withAlignment:alignment
                           relativeToView:alignmentRelativeToView
                                 hpadding:hpadding],
                     viewRect.origin.y - (size.height + vpadding));
}

+ (CGPoint)pointBelow:(UIView *)view
        withAlignment:(PEUIHorizontalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
             vpadding:(CGFloat)vpadding
             hpadding:(CGFloat)hpadding
         forBoxOfSize:(CGSize)size {
  CGRect viewRect = [view frame];
  return CGPointMake([PEUIUtils XForWidth:size.width
                            withAlignment:alignment
                           relativeToView:alignmentRelativeToView
                                 hpadding:hpadding],
                     viewRect.origin.y + (viewRect.size.height + vpadding));
}

#pragma mark - Dimension Utils

+ (CGFloat)heightForText:(NSString *)text forWidth:(CGFloat)width {
  NSMutableAttributedString *attrStr =
    [[NSMutableAttributedString alloc] initWithString:text];
  CGRect bounds =
    [attrStr boundingRectWithSize:CGSizeMake(width * 0.5, 0)
                          options:(NSLineBreakByWordWrapping |
                                   NSStringDrawingUsesLineFragmentOrigin)
                          context:nil];
  return bounds.size.height;
}

+ (CGSize)sizeOfText:(NSString *)text withFont:(UIFont *)font {
  NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  [paragraphStyle setLineBreakMode:NSLineBreakByCharWrapping];
  CGSize textSize = [text sizeWithAttributes:@{NSFontAttributeName : font,
                                               NSParagraphStyleAttributeName : paragraphStyle}];
  return CGSizeMake(textSize.width, textSize.height);
}

+ (CGFloat)widthWidestAmong:(NSArray *)views {
  __block CGFloat largestWidth = 0;
  [views enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
      if (obj.frame.size.width > largestWidth) {
        largestWidth = obj.frame.size.width;
      }
    }];
  return largestWidth;
}

#pragma mark - View Movement

+ (void)positionView:(UIView *)view
             atTopOf:(UIView *)ontoView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            vpadding:(CGFloat)vpadding
            hpadding:(CGFloat)hpadding {
  [PEUIUtils setFrameOrigin:CGPointMake([PEUIUtils XForWidth:[view frame].size.width
                                               withAlignment:alignment
                                              relativeToView:ontoView
                                                    hpadding:hpadding],
                                        vpadding)
                     ofView:view];
}

+ (void)positionView:(UIView *)view
          atBottomOf:(UIView *)ontoView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            vpadding:(CGFloat)vpadding
            hpadding:(CGFloat)hpadding {
  [PEUIUtils setFrameOrigin:CGPointMake([PEUIUtils XForWidth:[view frame].size.width
                                               withAlignment:alignment
                                              relativeToView:ontoView
                                                    hpadding:hpadding],
                                        [PEUIUtils YForHeight:[view frame].size.height
                                                withAlignment:PEUIVerticalAlignmentTypeBottom
                                               relativeToView:ontoView
                                                     vpadding:vpadding])
                     ofView:view];
}

+ (void)positionView:(UIView *)view
          inMiddleOf:(UIView *)ontoView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            hpadding:(CGFloat)hpadding {
  [PEUIUtils setFrameOrigin:CGPointMake([PEUIUtils XForWidth:[view frame].size.width
                                               withAlignment:alignment
                                              relativeToView:ontoView
                                                    hpadding:hpadding],
                                        [PEUIUtils YForHeight:[view frame].size.height
                                                withAlignment:PEUIVerticalAlignmentTypeMiddle
                                               relativeToView:ontoView
                                                     vpadding:0])
                     ofView:view];
}

+ (void)positionView:(UIView *)view
                onto:(UIView *)ontoView
     inMiddleBetween:(UIView *)topView
                 and:(UIView *)bottomView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            hpadding:(CGFloat)hpadding {
  [PEUIUtils positionView:view
                     onto:ontoView
    inMiddleBetweenYCoord:(topView.frame.origin.y + topView.frame.size.height)
                andYCoord:bottomView.frame.origin.y
            withAlignment:alignment
                 hpadding:hpadding];
}

+ (void)positionView:(UIView *)view
                onto:(UIView *)ontoView
     inMiddleBetween:(UIView *)topView
           andYCoord:(CGFloat)bottomYCoord
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            hpadding:(CGFloat)hpadding {
  [PEUIUtils positionView:view
                     onto:ontoView
    inMiddleBetweenYCoord:(topView.frame.origin.y + topView.frame.size.height)
                andYCoord:bottomYCoord
            withAlignment:alignment
                 hpadding:hpadding];
}

+ (void)positionView:(UIView *)view
                onto:(UIView *)ontoView
inMiddleBetweenYCoord:(CGFloat)topYCoordinate
             andView:(UIView *)bottomView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            hpadding:(CGFloat)hpadding {
  [PEUIUtils positionView:view
                     onto:ontoView
    inMiddleBetweenYCoord:topYCoordinate
                andYCoord:bottomView.frame.origin.y
            withAlignment:alignment
                 hpadding:hpadding];
}

+ (void)positionView:(UIView *)view
                onto:(UIView *)ontoView
inMiddleBetweenYCoord:(CGFloat)topYCoordinate
           andYCoord:(CGFloat)bottomYCoordinate
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            hpadding:(CGFloat)hpadding {
  [PEUIUtils setFrameOrigin: CGPointMake([PEUIUtils XForWidth:[view frame].size.width
                                                withAlignment:alignment
                                               relativeToView:ontoView
                                                     hpadding:hpadding],
                                         topYCoordinate -
                                         (([view frame].size.height - (bottomYCoordinate - topYCoordinate)) / 2))
                     ofView:view];
}

+ (void)positionView:(UIView *)view
               below:(UIView *)relativeTo
                onto:(UIView *)ontoView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            vpadding:(CGFloat)vpadding
            hpadding:(CGFloat)hpadding {
  [PEUIUtils positionView:view
                    below:relativeTo
                     onto:ontoView
            withAlignment:alignment
  alignmentRelativeToView:relativeTo
                 vpadding:vpadding
                 hpadding:hpadding];
}

+ (void)positionView:(UIView *)view
               below:(UIView *)relativeTo
                onto:(UIView *)ontoView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
            vpadding:(CGFloat)vpadding
            hpadding:(CGFloat)hpadding {
  [PEUIUtils setFrameOrigin:[PEUIUtils pointBelow:relativeTo
                                    withAlignment:alignment
                          alignmentRelativeToView:alignmentRelativeToView
                                         vpadding:vpadding
                                         hpadding:hpadding
                                     forBoxOfSize:[view frame].size]
                     ofView:view];
}

+ (void)positionView:(UIView *)view
               above:(UIView *)relativeTo
                onto:(UIView *)ontoView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            vpadding:(CGFloat)vpadding
            hpadding:(CGFloat)hpadding {
  [PEUIUtils positionView:view
                    above:relativeTo
                     onto:ontoView
            withAlignment:alignment
  alignmentRelativeToView:relativeTo
                 vpadding:vpadding
                 hpadding:hpadding];
}

+ (void)positionView:(UIView *)view
               above:(UIView *)relativeTo
                onto:(UIView *)ontoView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
            vpadding:(CGFloat)vpadding
            hpadding:(CGFloat)hpadding {
  [PEUIUtils setFrameOrigin:[PEUIUtils pointAbove:relativeTo
                                    withAlignment:alignment
                          alignmentRelativeToView:alignmentRelativeToView
                                         vpadding:vpadding
                                         hpadding:hpadding
                                     forBoxOfSize:[view frame].size]
                     ofView:view];
}

+ (void)positionView:(UIView *)view
         toTheLeftOf:(UIView *)relativeTo
                onto:(UIView *)ontoView
       withAlignment:(PEUIVerticalAlignmentType)alignment
            hpadding:(CGFloat)hpadding {
  [PEUIUtils positionView:view
              toTheLeftOf:relativeTo
                     onto:ontoView
            withAlignment:alignment
  alignmentRelativeToView:relativeTo
                 hpadding:hpadding];
}

+ (void)positionView:(UIView *)view
         toTheLeftOf:(UIView *)relativeTo
                onto:(UIView *)ontoView
       withAlignment:(PEUIVerticalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
            hpadding:(CGFloat)hpadding {
  [PEUIUtils setFrameOrigin:[PEUIUtils pointToTheLeftOf:relativeTo
                                          withAlignment:alignment
                                alignmentRelativeToView:alignmentRelativeToView
                                               hpadding:hpadding
                                           forBoxOfSize:[view frame].size]
                     ofView:view];
}

+ (void)positionView:(UIView *)view
        toTheRightOf:(UIView *)relativeTo
                onto:(UIView *)ontoView
       withAlignment:(PEUIVerticalAlignmentType)alignment
            hpadding:(CGFloat)hpadding {
  [PEUIUtils positionView:view
             toTheRightOf:relativeTo
                     onto:ontoView
            withAlignment:alignment
  alignmentRelativeToView:relativeTo
                 hpadding:hpadding];
}

+ (void)positionView:(UIView *)view
        toTheRightOf:(UIView *)relativeTo
                onto:(UIView *)ontoView
       withAlignment:(PEUIVerticalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
            hpadding:(CGFloat)hpadding {
  [PEUIUtils setFrameOrigin:[PEUIUtils pointToTheRightOf:relativeTo
                                           withAlignment:alignment
                                 alignmentRelativeToView:alignmentRelativeToView
                                                hpadding:hpadding
                                            forBoxOfSize:[view frame].size]
                     ofView:view];
}

#pragma mark - View Placement

+ (void)placeView:(UIView *)view
          atTopOf:(UIView *)ontoView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         vpadding:(CGFloat)vpadding
         hpadding:(CGFloat)hpadding {
  [ontoView addSubview:view];
  [PEUIUtils positionView:view
                  atTopOf:ontoView
            withAlignment:alignment
                 vpadding:vpadding
                 hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
       atBottomOf:(UIView *)ontoView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         vpadding:(CGFloat)vpadding
         hpadding:(CGFloat)hpadding {
  [ontoView addSubview:view];
  [PEUIUtils positionView:view
               atBottomOf:ontoView
            withAlignment:alignment
                 vpadding:vpadding
                 hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
       inMiddleOf:(UIView *)ontoView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         hpadding:(CGFloat)hpadding {
  [ontoView addSubview:view];
  [PEUIUtils positionView:view
               inMiddleOf:ontoView
            withAlignment:alignment
                 hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
             onto:(UIView *)ontoView
  inMiddleBetween:(UIView *)topView
              and:(UIView *)bottomView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         hpadding:(CGFloat)hpadding {
  [PEUIUtils placeView:view
                  onto:ontoView
 inMiddleBetweenYCoord:(topView.frame.origin.y + topView.frame.size.height)
             andYCoord:bottomView.frame.origin.y
         withAlignment:alignment
              hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
             onto:(UIView *)ontoView
  inMiddleBetween:(UIView *)topView
        andYCoord:(CGFloat)bottomYCoord
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         hpadding:(CGFloat)hpadding {
  [PEUIUtils placeView:view
                  onto:ontoView
 inMiddleBetweenYCoord:(topView.frame.origin.y + topView.frame.size.height)
             andYCoord:bottomYCoord
         withAlignment:alignment
              hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
             onto:(UIView *)ontoView
inMiddleBetweenYCoord:(CGFloat)topYCoordinate
          andView:(UIView *)bottomView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         hpadding:(CGFloat)hpadding {
  [PEUIUtils placeView:view
                  onto:ontoView
 inMiddleBetweenYCoord:topYCoordinate
             andYCoord:bottomView.frame.origin.y
         withAlignment:alignment
              hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
             onto:(UIView *)ontoView
inMiddleBetweenYCoord:(CGFloat)topYCoordinate
        andYCoord:(CGFloat)bottomYCoordinate
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         hpadding:(CGFloat)hpadding {
  [ontoView addSubview:view];
  [PEUIUtils positionView:view
                     onto:ontoView
    inMiddleBetweenYCoord:topYCoordinate
                andYCoord:bottomYCoordinate
            withAlignment:alignment
                 hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
            below:(UIView *)relativeTo
             onto:(UIView *)ontoView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         vpadding:(CGFloat)vpadding
         hpadding:(CGFloat)hpadding {
  [PEUIUtils placeView:view
                 below:relativeTo
                  onto:ontoView
         withAlignment:alignment
alignmentRelativeToView:relativeTo
              vpadding:vpadding
              hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
            below:(UIView *)relativeTo
             onto:(UIView *)ontoView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
         vpadding:(CGFloat)vpadding
         hpadding:(CGFloat)hpadding {
  [ontoView addSubview:view];
  [PEUIUtils positionView:view
                    below:relativeTo
                     onto:ontoView
            withAlignment:alignment
  alignmentRelativeToView:alignmentRelativeToView
                 vpadding:vpadding
                 hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
            above:(UIView *)relativeTo
             onto:(UIView *)ontoView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         vpadding:(CGFloat)vpadding
         hpadding:(CGFloat)hpadding {
  [PEUIUtils placeView:view
                 above:relativeTo
                  onto:ontoView
         withAlignment:alignment
alignmentRelativeToView:relativeTo
              vpadding:vpadding
              hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
            above:(UIView *)relativeTo
             onto:(UIView *)ontoView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
         vpadding:(CGFloat)vpadding
         hpadding:(CGFloat)hpadding {
  [ontoView addSubview:view];
  [PEUIUtils positionView:view
                    above:relativeTo
                     onto:ontoView
            withAlignment:alignment
  alignmentRelativeToView:alignmentRelativeToView
                 vpadding:vpadding
                 hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
      toTheLeftOf:(UIView *)relativeTo
             onto:(UIView *)ontoView
    withAlignment:(PEUIVerticalAlignmentType)alignment
         hpadding:(CGFloat)hpadding {
  [PEUIUtils placeView:view
           toTheLeftOf:relativeTo
                  onto:ontoView
         withAlignment:alignment
alignmentRelativeToView:relativeTo
              hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
      toTheLeftOf:(UIView *)relativeTo
             onto:(UIView *)ontoView
    withAlignment:(PEUIVerticalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
         hpadding:(CGFloat)hpadding {
  [ontoView addSubview:view];
  [PEUIUtils positionView:view
              toTheLeftOf:relativeTo
                     onto:ontoView
            withAlignment:alignment
  alignmentRelativeToView:alignmentRelativeToView
                 hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
     toTheRightOf:(UIView *)relativeTo
             onto:(UIView *)ontoView
    withAlignment:(PEUIVerticalAlignmentType)alignment
         hpadding:(CGFloat)hpadding {
  [PEUIUtils placeView:view
          toTheRightOf:relativeTo
                  onto:ontoView
         withAlignment:alignment
alignmentRelativeToView:relativeTo
              hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
     toTheRightOf:(UIView *)relativeTo
             onto:(UIView *)ontoView
    withAlignment:(PEUIVerticalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
         hpadding:(CGFloat)hpadding {
  [ontoView addSubview:view];
  [PEUIUtils positionView:view
             toTheRightOf:relativeTo
                     onto:ontoView
            withAlignment:alignment
  alignmentRelativeToView:alignmentRelativeToView
                 hpadding:hpadding];
}

#pragma mark - Animations

+ (void)placeAndAnimateView:(UIView *)view
              fromTopOfView:(UIView *)relativeTo
                    downToY:(CGFloat)downToY
              withAlignment:(PEUIHorizontalAlignmentType)alignment
                   hpadding:(CGFloat)hpadding
                   duration:(NSTimeInterval)duration
            fadeOutDuration:(NSTimeInterval)fadeOutDuration {
  [PEUIUtils placeView:view
                 above:relativeTo
                  onto:relativeTo
         withAlignment:alignment
              vpadding:0
              hpadding:0];
  [UIView animateWithDuration:duration
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:^{
    CGPoint destPoint =
      CGPointMake([PEUIUtils XForWidth:[view frame].size.width
                         withAlignment:alignment
                        relativeToView:relativeTo
                              hpadding:hpadding], downToY);
    [PEUIUtils setFrameOrigin:destPoint ofView:view]; }
                   completion:^(BOOL finished) {
                     [UIView animateWithDuration:fadeOutDuration
                                           delay:0.0f
                                         options:UIViewAnimationOptionCurveEaseInOut
                                      animations:^{
                       [view setAlpha:0.0f]; }
                                      completion:^(BOOL finished){ [view removeFromSuperview]; }]; }];
}

#pragma mark - View Sizing

+ (void)setFrameWidth:(CGFloat)width ofView:(UIView *)view {
  CGRect frame = [view frame];
  CGRect newFrame = CGRectMake(frame.origin.x, frame.origin.y, width,
                               frame.size.height);
  [view setFrame:newFrame];
}

+ (void)setFrameWidthOfView:(UIView *)view
                    ofWidth:(CGFloat)percentage
                 relativeTo:(UIView *)relativeToView {
  [PEUIUtils setFrameWidth:([relativeToView frame].size.width * percentage)
                    ofView:view];
}

+ (void)setFrameHeight:(CGFloat)height ofView:(UIView *)view {
  CGRect frame = [view frame];
  CGRect newFrame =
    CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, height);
  [view setFrame:newFrame];
}

+ (void)setFrameHeightOfView:(UIView *)view
                    ofHeight:(CGFloat)percentage
                  relativeTo:(UIView *)relativeToView {
  [PEUIUtils setFrameHeight:([relativeToView frame].size.height * percentage)
                     ofView:view];
}

+ (void)adjustHeightToFitSubviewsForView:(UIView *)panel
                           bottomPadding:(CGFloat)bottomPadding {
  NSArray *subviews = [panel subviews];
  CGRect boundingRect = CGRectZero;
  for (UIView *view in subviews) {
    boundingRect = CGRectUnion(boundingRect, view.frame);
  }
  [PEUIUtils setFrameHeight:(boundingRect.size.height + bottomPadding)
                     ofView:panel];
}

#pragma mark - View Controller Commons

+ (UINavigationController *)navigationControllerWithController:(UIViewController *)viewController {
  return [PEUIUtils navigationControllerWithController:viewController
                                   navigationBarHidden:YES];
}

+ (UINavigationController *)navigationControllerWithController:(UIViewController *)viewController
                                           navigationBarHidden:(BOOL)navigationBarHidden {
  UINavigationController *navCtrl =
    [[UINavigationController alloc] initWithRootViewController:viewController];
  [navCtrl setNavigationBarHidden:navigationBarHidden];
  return navCtrl;
}

+ (void)displayController:(UIViewController *)controller
           fromController:(UIViewController *)fromController
                 animated:(BOOL)animated {
  UINavigationController *fromControllerParentNavCtrl =
    [fromController navigationController];
  if (fromControllerParentNavCtrl) {
    [fromControllerParentNavCtrl pushViewController:controller animated:animated];
  } else {
    [fromController presentViewController:controller animated:animated completion:nil];
  }
}

+ (UINavigationController *)navControllerWithRootController:(UIViewController *)viewController
                                        navigationBarHidden:(BOOL)navigationBarHidden
                                            tabBarItemTitle:(NSString *)tabBarItemTitle
                                            tabBarItemImage:(UIImage *)tabBarItemImage
                                    tabBarItemSelectedImage:(UIImage *)tabBarItemSelectedImage {
  UINavigationController *navCtrl =
    [PEUIUtils navigationControllerWithController:viewController
                              navigationBarHidden:navigationBarHidden];
  UITabBarItem *tabBarItem =
  [[UITabBarItem alloc] initWithTitle:tabBarItemTitle
                                image:tabBarItemImage
                        selectedImage:tabBarItemSelectedImage];
  if (!tabBarItemTitle) {
    // http://stackoverflow.com/questions/16285205/moving-uitabbaritem-image-down
    tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
  }
  [navCtrl setTabBarItem:tabBarItem];
  return navCtrl;
}

#pragma mark - Color Utils

+ (UIImage *)imageWithColor:(UIColor *)color {
  CGRect rect = CGRectMake(0, 0, 1, 1);
  UIGraphicsBeginImageContext(rect.size);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetFillColorWithColor(context, [color CGColor]);
  CGContextFillRect(context, rect);
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

+ (void)applyBorderToView:(UIView *)view
                withColor:(UIColor *)color {
  [PEUIUtils applyBorderToView:view withColor:color width:1.0];
}

+ (void)applyBorderToView:(UIView *)view
                withColor:(UIColor *)color
                    width:(CGFloat)width {
  view.layer.borderColor = color.CGColor;
  view.layer.borderWidth = width;
}

#pragma mark - Attributed Text

+ (NSAttributedString *)attributedTextWithTemplate:(NSString *)templateText
                                 templateTextColor:(UIColor *)templateTextColor
                                  templateTextFont:(UIFont *)templateTextFont
                                      textToAccent:(NSString *)textToAccent
                                    accentTextFont:(UIFont *)accentTextFont
                                   accentTextColor:(UIColor *)accentTextColor {
  NSMutableDictionary *templateAttrs = [NSMutableDictionary dictionary];
  if (templateTextFont) {
    [templateAttrs setObject:templateTextFont forKey:NSFontAttributeName];
  }
  if (templateTextColor) {
    [templateAttrs setObject:templateTextColor forKey:NSForegroundColorAttributeName];
  }
  NSMutableDictionary *accentAttrs = [NSMutableDictionary dictionary];
  if (accentTextFont) {
    [accentAttrs setObject:accentTextFont forKey:NSFontAttributeName];
  }
  if (accentTextColor) {
    [accentAttrs setObject:accentTextColor forKey:NSForegroundColorAttributeName];
  }
  NSString *text = [NSString stringWithFormat:templateText, textToAccent];
  NSRange accentRange = [text rangeOfString:textToAccent];
  NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text];
  [attributedText setAttributes:templateAttrs range:NSMakeRange(0, text.length)];
  [attributedText setAttributes:accentAttrs range:accentRange];
  return attributedText;
}

+ (NSAttributedString *)attributedTextWithTemplate:(NSString *)templateText
                                      textToAccent:(NSString *)textToAccent
                                    accentTextFont:(UIFont *)accentTextFont
                                   accentTextColor:(UIColor *)accentTextColor {
  return [PEUIUtils attributedTextWithTemplate:templateText
                             templateTextColor:nil
                              templateTextFont:nil
                                  textToAccent:textToAccent
                                accentTextFont:accentTextFont
                               accentTextColor:accentTextColor];
}

+ (NSAttributedString *)attributedTextWithTemplate:(NSString *)templateText
                                      textToAccent:(NSString *)textToAccent
                                    accentTextFont:(UIFont *)accentTextFont {
  return [PEUIUtils attributedTextWithTemplate:templateText
                                  textToAccent:textToAccent
                                accentTextFont:accentTextFont
                               accentTextColor:nil];
}

#pragma mark - Text Truncation

+ (NSString *)truncatedTextForText:(NSString *)text
                              font:(UIFont *)font
                    availableWidth:(CGFloat)availableWidth {
  CGFloat wouldBeWidthOfValueLabel = [PEUIUtils sizeOfText:text withFont:font].width;
  CGFloat widthOfElipses = [PEUIUtils sizeOfText:@"..." withFont:font].width;
  if (wouldBeWidthOfValueLabel > availableWidth) {
    if ([text length] > 0) {
      NSDecimalNumber *avgWidthPerLetter = [[[NSDecimalNumber alloc] initWithFloat:wouldBeWidthOfValueLabel] decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithInteger:[text length]]];
      NSInteger availableWidthMinusElipses = availableWidth - widthOfElipses;
      NSDecimalNumber *allowedNumLetters = [[[NSDecimalNumber alloc] initWithInteger:(availableWidth - widthOfElipses)] decimalNumberByDividingBy:avgWidthPerLetter];
      allowedNumLetters = [allowedNumLetters decimalNumberByRoundingAccordingToBehavior:[NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain
                                                                                                                                               scale:0
                                                                                                                                    raiseOnExactness:NO
                                                                                                                                     raiseOnOverflow:NO
                                                                                                                                    raiseOnUnderflow:NO
                                                                                                                                 raiseOnDivideByZero:NO]];
      if (availableWidthMinusElipses > 0) {
        if (allowedNumLetters.integerValue > 0) {
          if (allowedNumLetters.integerValue <= text.length) {
            text = [[text substringToIndex:(allowedNumLetters.integerValue - 1)] stringByAppendingString:@"..."];
          }
        }
      } else {
        text = @"...";
      }
    }
  }
  return text;
}

#pragma mark - Label maker helper

+ (UILabel *)emptyLabelWithFont:(UIFont *)font
                backgroundColor:(UIColor *)backgroundColor
                      textColor:(UIColor *)textColor
            verticalTextPadding:(CGFloat)verticalTextPadding
                          width:(CGFloat)width
                         height:(CGFloat)height {
  UILabel *label =
    [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, height + verticalTextPadding)];
  [label setNumberOfLines:0];
  [label setBackgroundColor:backgroundColor];
  [label setLineBreakMode:NSLineBreakByWordWrapping];
  [label setTextColor:textColor];
  [label setFont:font];
  return label;
}

+ (UILabel *)emptyLabelToFitText:(NSString *)text
                            font:(UIFont *)font
        fontForHeightCalculation:(UIFont *)fontForHeightCalculation
                 backgroundColor:(UIColor *)backgroundColor
                       textColor:(UIColor *)textColor
             verticalTextPadding:(CGFloat)verticalTextPadding
                      fitToWidth:(CGFloat)fitToWidth {
  CGRect rect = [text boundingRectWithSize:CGSizeMake(fitToWidth, MAXFLOAT)
                                   options:NSStringDrawingUsesLineFragmentOrigin
                                attributes:@{ NSFontAttributeName : fontForHeightCalculation }
                                   context:nil];
  return [PEUIUtils emptyLabelWithFont:font
                       backgroundColor:backgroundColor
                             textColor:textColor
                   verticalTextPadding:verticalTextPadding
                                 width:rect.size.width
                                height:rect.size.height];
}

+ (UILabel *)emptyLabelToFitText:(NSString *)text
                            font:(UIFont *)font
        fontForHeightCalculation:(UIFont *)fontForHeightCalculation
                 backgroundColor:(UIColor *)backgroundColor
                       textColor:(UIColor *)textColor
             verticalTextPadding:(CGFloat)verticalTextPadding {
  CGSize textSize = [PEUIUtils sizeOfText:text withFont:fontForHeightCalculation];
  return [PEUIUtils emptyLabelWithFont:font
                       backgroundColor:backgroundColor
                             textColor:textColor
                   verticalTextPadding:verticalTextPadding
                                 width:textSize.width
                                height:textSize.height];
}

#pragma mark - Labels

+ (UIFont *)boldFontForTextStyle:(NSString *)textStyle {
  return [PEUIUtils fontForTextStyle:textStyle trait:UIFontDescriptorTraitBold];
}

+ (UIFont *)italicFontForTextStyle:(NSString *)textStyle {
  return [PEUIUtils fontForTextStyle:textStyle trait:UIFontDescriptorTraitItalic];
}

+ (UIFont *)fontForTextStyle:(NSString *)textStyle
                       trait:(UIFontDescriptorSymbolicTraits)trait {
  UIFontDescriptor* fontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:textStyle];
  UIFontDescriptor* boldFontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:trait];
  return [UIFont fontWithDescriptor:boldFontDescriptor size:0.0];
}

+ (UILabel *)labelWithKey:(NSString *)key
                     font:(UIFont *)font
          backgroundColor:(UIColor *)backgroundColor
                textColor:(UIColor *)textColor
      verticalTextPadding:(CGFloat)verticalTextPadding {
  NSString *text = LS(key);
  UILabel *label = [PEUIUtils emptyLabelToFitText:text
                                             font:font
                         fontForHeightCalculation:font
                                  backgroundColor:backgroundColor
                                        textColor:textColor
                              verticalTextPadding:verticalTextPadding];
  [label setText:text];
  return label;
}

+ (UILabel *)labelWithKey:(NSString *)key
                     font:(UIFont *)font
          backgroundColor:(UIColor *)backgroundColor
                textColor:(UIColor *)textColor
      verticalTextPadding:(CGFloat)verticalTextPadding
               fitToWidth:(CGFloat)fitToWidth {
  NSString *text = LS(key);
  UILabel *label = [PEUIUtils emptyLabelToFitText:text
                                             font:font
                         fontForHeightCalculation:font
                                  backgroundColor:backgroundColor
                                        textColor:textColor
                              verticalTextPadding:verticalTextPadding
                                       fitToWidth:fitToWidth];
  [label setText:text];
  return label;
}

+ (UILabel *)labelWithAttributeText:(NSAttributedString *)attributedText
                               font:(UIFont *)font
                    backgroundColor:(UIColor *)backgroundColor
                          textColor:(UIColor *)textColor
                verticalTextPadding:(CGFloat)verticalTextPadding {
  return [PEUIUtils labelWithAttributeText:attributedText
                                      font:font
                  fontForHeightCalculation:font
                           backgroundColor:backgroundColor
                                 textColor:textColor
                       verticalTextPadding:verticalTextPadding];
}

+ (UILabel *)labelWithAttributeText:(NSAttributedString *)attributedText
                               font:(UIFont *)font
           fontForHeightCalculation:(UIFont *)fontForHeightCalculation
                    backgroundColor:(UIColor *)backgroundColor
                          textColor:(UIColor *)textColor
                verticalTextPadding:(CGFloat)verticalTextPadding {
  UILabel *label = [PEUIUtils emptyLabelToFitText:[attributedText string]
                                             font:font
                         fontForHeightCalculation:fontForHeightCalculation
                                  backgroundColor:backgroundColor
                                        textColor:textColor
                              verticalTextPadding:verticalTextPadding];
  [label setAttributedText:attributedText];
  return label;
}

+ (UILabel *)labelWithAttributeText:(NSAttributedString *)attributedText
                               font:(UIFont *)font
                    backgroundColor:(UIColor *)backgroundColor
                          textColor:(UIColor *)textColor
                verticalTextPadding:(CGFloat)verticalTextPadding
                         fitToWidth:(CGFloat)fitToWidth {
  return [PEUIUtils labelWithAttributeText:attributedText
                                      font:font
                  fontForHeightCalculation:font
                           backgroundColor:backgroundColor
                                 textColor:textColor
                       verticalTextPadding:verticalTextPadding
                                fitToWidth:fitToWidth];
}

+ (UILabel *)labelWithAttributeText:(NSAttributedString *)attributedText
                               font:(UIFont *)font
           fontForHeightCalculation:(UIFont *)fontForHeightCalculation
                    backgroundColor:(UIColor *)backgroundColor
                          textColor:(UIColor *)textColor
                verticalTextPadding:(CGFloat)verticalTextPadding
                         fitToWidth:(CGFloat)fitToWidth {
  UILabel *label = [PEUIUtils emptyLabelToFitText:[attributedText string]
                                             font:font
                         fontForHeightCalculation:fontForHeightCalculation
                                  backgroundColor:backgroundColor
                                        textColor:textColor
                              verticalTextPadding:verticalTextPadding
                                       fitToWidth:fitToWidth];
  [label setAttributedText:attributedText];
  return label;
}

+ (UIView *)leftPadView:(UIView *)view
                padding:(CGFloat)padding {
  UIView *panel = [PEUIUtils panelWithFixedWidth:padding + view.frame.size.width
                                     fixedHeight:view.frame.size.height];
  UIView *paddingPanel = [PEUIUtils panelWithFixedWidth:padding fixedHeight:view.frame.size.height];
  [paddingPanel setBackgroundColor:[UIColor clearColor]];
  [PEUIUtils placeView:paddingPanel inMiddleOf:panel withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:0.0];
  [PEUIUtils placeView:view toTheRightOf:paddingPanel onto:panel withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:0.0];
  return panel;
}

+ (UIView *)rightPadView:(UIView *)view
                 padding:(CGFloat)padding {
  UIView *panel = [PEUIUtils panelWithFixedWidth:padding + view.frame.size.width
                                     fixedHeight:view.frame.size.height];
  UIView *paddingPanel = [PEUIUtils panelWithFixedWidth:padding fixedHeight:view.frame.size.height];
  [paddingPanel setBackgroundColor:[UIColor clearColor]];
  [PEUIUtils placeView:paddingPanel inMiddleOf:panel withAlignment:PEUIHorizontalAlignmentTypeRight hpadding:0.0];
  [PEUIUtils placeView:view toTheLeftOf:paddingPanel onto:panel withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:0.0];
  return panel;
}

+ (void)setTextAndResize:(NSString *)text forLabel:(UILabel *)label {
  CGSize textSize = [PEUIUtils sizeOfText:text withFont:[label font]];
  [label setText:text];
  [PEUIUtils setFrameHeight:textSize.height ofView:label];
  [PEUIUtils setFrameWidth:textSize.width ofView:label];
}

+ (UIView *)badgeForNum:(NSInteger)num
                  color:(UIColor *)color
         badgeTextColor:(UIColor *)badgeTextColor {
  CGFloat widthPadding = 30.0;
  CGFloat heightFactor = 1.45;
  UIFont* boldSubheadlineFont = [self boldFontForTextStyle:UIFontTextStyleSubheadline];
  NSString *labelText = [NSString stringWithFormat:@"%ld", (long)num];
  UILabel *label = [PEUIUtils labelWithKey:labelText
                                      font:boldSubheadlineFont
                           backgroundColor:[UIColor clearColor]
                                 textColor:badgeTextColor
                       verticalTextPadding:0.0];
  UIView *badge = [PEUIUtils panelWithFixedWidth:label.frame.size.width + widthPadding
                                     fixedHeight:label.frame.size.height * heightFactor];
  [badge addRoundedCorners:UIRectCornerAllCorners
                 withRadii:CGSizeMake(20.0, 20.0)];
  badge.alpha = 0.8;
  badge.backgroundColor = color;
  [PEUIUtils placeView:label
            inMiddleOf:badge
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              hpadding:0.0];
  return badge;
}

+ (UILabel *)labelForRecordCount:(NSInteger)recordCount {
  return [PEUIUtils labelWithKey:[PEUtils labelTextForRecordCount:recordCount]
                            font:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption2]
                 backgroundColor:[UIColor clearColor]
                       textColor:[UIColor darkGrayColor]
             verticalTextPadding:0.0];
}

+ (void)placeRecordCountLabel:(UILabel *)recordCountLabel
                   ontoButton:(UIButton *)button
                     hpadding:(CGFloat)hpadding
                     vpadding:(CGFloat)vpadding {
  [PEUIUtils placeView:recordCountLabel
            atBottomOf:button
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:vpadding
              hpadding:hpadding];
}

+ (void)refreshRecordCountLabelOnButton:(UIButton *)button
                    recordCountLabelTag:(NSInteger)recordCountLabelTag
                            recordCount:(NSInteger)recordCount {
  UILabel *recordCountLabel = (UILabel *)[button viewWithTag:recordCountLabelTag];
  if (recordCountLabel) {
    [PEUIUtils setTextAndResize:[PEUtils labelTextForRecordCount:recordCount] forLabel:recordCountLabel];
  }
}

#pragma mark - Text Fields

+ (UITextField *)textfieldWithPlaceholderTextKey:(NSString *)key
                                            font:(UIFont *)font
                                 backgroundColor:(UIColor *)backgroundColor
                                 leftViewPadding:(CGFloat)leftViewPadding
                                      fixedWidth:(CGFloat)width {
  return [PEUIUtils textfieldWithPlaceholderTextKey:key
                                               font:font
                                    backgroundColor:backgroundColor
                                    leftViewPadding:leftViewPadding
                                         fixedWidth:width
                                       heightFactor:1.75]; // a reasonable default
}

+ (UITextField *)textfieldWithPlaceholderTextKey:(NSString *)key
                                            font:(UIFont *)font
                                 backgroundColor:(UIColor *)backgroundColor
                                 leftViewPadding:(CGFloat)leftViewPadding
                                      fixedWidth:(CGFloat)width
                                    heightFactor:(CGFloat)heightFactor {
  NSString *placeholderText = LS(key);
  CGFloat height = [PEUIUtils sizeOfText:placeholderText withFont:font].height *
    heightFactor;
  UITextField *tf =
    [[UITextField alloc]
      initWithFrame:CGRectMake(0, 0, width, height)];
  [tf setAutocorrectionType:UITextAutocorrectionTypeNo];
  [tf setAutocapitalizationType:UITextAutocapitalizationTypeNone];
  [tf setClearButtonMode:UITextFieldViewModeWhileEditing];
  UIView *paddingView =
    [[UIView alloc] initWithFrame:CGRectMake(0, 0, leftViewPadding, height)];
  [tf setLeftView:paddingView];
  [tf setLeftViewMode:UITextFieldViewModeAlways];
  [tf setBackgroundColor:backgroundColor];
  [tf setFont:font];
  [tf setPlaceholder:placeholderText];
  return tf;
}

+ (UITextField *)textfieldWithPlaceholderTextKey:(NSString *)key
                                            font:(UIFont *)font
                                 backgroundColor:(UIColor *)backgroundColor
                                 leftViewPadding:(CGFloat)leftViewPadding
                                         ofWidth:(CGFloat)percentage
                                      relativeTo:(UIView *)relativeToView {
  CGFloat width = relativeToView.frame.size.width * percentage;
  return [PEUIUtils textfieldWithPlaceholderTextKey:key
                                               font:font
                                    backgroundColor:backgroundColor
                                    leftViewPadding:leftViewPadding
                                         fixedWidth:width];
}

+ (NSString *)stringFromTextFieldWithTag:(NSInteger)tag
                                fromView:(UIView *)view {
  return [(UITextField *)[view viewWithTag:tag] text];
}

+ (NSNumber *)numberFromTextFieldWithTag:(NSInteger)tag
                                fromView:(UIView *)view {
  return [PEUtils nullSafeNumberFromString:[(UITextField *)[view viewWithTag:tag] text]];
}

+ (NSDecimalNumber *)decimalNumberFromTextFieldWithTag:(NSInteger)tag
                                              fromView:(UIView *)view {
  return [PEUtils nullSafeDecimalNumberFromString:[(UITextField *)[view viewWithTag:tag] text]];
}

+ (void)bindToEntity:(id)entity
          withSetter:(SEL)setter
fromTextfieldWithTag:(NSInteger)tfTag
   stringTransformer:(id (^)(NSString *))stringTransformer
            fromView:(UIView *)view {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  NSString *strValue = [PEUIUtils stringFromTextFieldWithTag:tfTag
                                                    fromView:view];
  [entity performSelector:setter
               withObject:stringTransformer(strValue)];
#pragma clang diagnostic pop
}

+ (void)bindToEntity:(id)entity
    withStringSetter:(SEL)setter
fromTextfieldWithTag:(NSInteger)tfTag
            fromView:(UIView *)view {
  [PEUIUtils bindToEntity:entity
               withSetter:setter
     fromTextfieldWithTag:tfTag
        stringTransformer:^id(NSString *strValue){return strValue;}
                 fromView:view];
}

+ (void)bindToEntity:(id)entity
    withNumberSetter:(SEL)setter
fromTextfieldWithTag:(NSInteger)tfTag
            fromView:(UIView *)view {
  [PEUIUtils bindToEntity:entity
               withSetter:setter
     fromTextfieldWithTag:tfTag
        stringTransformer:^id(NSString *strValue){return [PEUtils nullSafeNumberFromString:strValue];}
                 fromView:view];
}

+ (void)bindToEntity:(id)entity
   withDecimalSetter:(SEL)setter
fromTextfieldWithTag:(NSInteger)tfTag
            fromView:(UIView *)view {
  [PEUIUtils bindToEntity:entity
               withSetter:setter
     fromTextfieldWithTag:tfTag
        stringTransformer:^id(NSString *strValue){return [PEUtils nullSafeDecimalNumberFromString:strValue];}
                 fromView:view];
}

+ (void)bindToTextControlWithTag:(NSInteger)tfTag
                        fromView:(UIView *)view
                      fromEntity:(id)entity
                      withGetter:(SEL)getter {
  UIView *textView = [view viewWithTag:tfTag];
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  NSObject *val = [entity performSelector:getter];
  NSString *valStr;
  if (val && ![val isEqual:[NSNull null]]) {
    valStr = [val description];
  } else {
    valStr = @"";
  }
  [textView performSelector:@selector(setText:) withObject:valStr];
  #pragma clang diagnostic pop
}

+ (void)enableControlWithTag:(NSInteger)tag
                    fromView:(UIView *)view
                      enable:(BOOL)enable {
  UIControl *control = (UIControl *)[view viewWithTag:tag];
  [control setEnabled:enable];
}

#pragma mark - Buttons

+ (UIButton *)buttonWithKey:(NSString *)key
                       font:(UIFont *)font
            backgroundColor:(UIColor *)backgroundColor
                  textColor:(UIColor *)textColor
disabledStateBackgroundColor:(UIColor *)disabledStateBackgroundColor
     disabledStateTextColor:(UIColor *)disabledStateTextColor
            verticalPadding:(CGFloat)verticalPadding
          horizontalPadding:(CGFloat)horizontalPadding
               cornerRadius:(CGFloat)cornerRadius
                     target:(id)target
                     action:(SEL)action {
  NSString *titleText = LS(key);
  UIButton *btn = [self templateButtonWithTitleText:titleText
                           fontForHeightCalculation:font
                                    backgroundColor:backgroundColor
                       disabledStateBackgroundColor:disabledStateBackgroundColor
                                    verticalPadding:verticalPadding
                                  horizontalPadding:horizontalPadding
                                       cornerRadius:cornerRadius
                                             target:target
                                             action:action];
  [btn setTitle:titleText forState:UIControlStateNormal];
  [btn setTitleColor:textColor forState:UIControlStateNormal];
  [btn setTitleColor:disabledStateTextColor forState:UIControlStateDisabled];
  [[btn titleLabel] setFont:font];
  return btn;
}

+ (UIButton *)templateButtonWithTitleText:(NSString *)titleText
                 fontForHeightCalculation:(UIFont *)fontForHeightCalculation
                          backgroundColor:(UIColor *)backgroundColor
             disabledStateBackgroundColor:(UIColor *)disabledStateBackgroundColor
                          verticalPadding:(CGFloat)verticalPadding
                        horizontalPadding:(CGFloat)horizontalPadding
                             cornerRadius:(CGFloat)cornerRadius
                                   target:(id)target
                                   action:(SEL)action {
  CGSize textSize = [PEUIUtils sizeOfText:titleText withFont:fontForHeightCalculation];
  textSize = CGSizeMake(textSize.width + horizontalPadding,
                        textSize.height + verticalPadding);
  UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  UIImage *bgColorAsImgNormState = [PEUIUtils imageWithColor:backgroundColor];
  UIImage *bgColorAsImgDisState =
  [PEUIUtils imageWithColor:disabledStateBackgroundColor];
  [btn setBackgroundImage:bgColorAsImgNormState forState:UIControlStateNormal];
  [btn setBackgroundImage:bgColorAsImgDisState forState:UIControlStateDisabled];
  [[btn layer] setCornerRadius:cornerRadius];
  [btn setClipsToBounds:YES]; // needed for corner radius to work
  [[btn titleLabel] setLineBreakMode:NSLineBreakByWordWrapping];
  [[btn titleLabel] setTextAlignment:NSTextAlignmentCenter];
  [btn setFrame:CGRectMake(0, 0, textSize.width, textSize.height)];
  if (target) {
    [btn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
  }
  return btn;
}

+ (UIButton *)buttonWithAttributedTitle:(NSAttributedString *)attributedTitle
               fontForHeightCalculation:(UIFont *)fontForHeightCalculation
                        backgroundColor:(UIColor *)backgroundColor
           disabledStateBackgroundColor:(UIColor *)disabledStateBackgroundColor
                        verticalPadding:(CGFloat)verticalPadding
                      horizontalPadding:(CGFloat)horizontalPadding
                           cornerRadius:(CGFloat)cornerRadius
                                 target:(id)target
                                 action:(SEL)action {
  UIButton *btn = [self templateButtonWithTitleText:attributedTitle.string
                           fontForHeightCalculation:fontForHeightCalculation
                                    backgroundColor:backgroundColor
                       disabledStateBackgroundColor:disabledStateBackgroundColor
                                    verticalPadding:verticalPadding
                                  horizontalPadding:horizontalPadding
                                       cornerRadius:cornerRadius
                                             target:target
                                             action:action];
  [btn setAttributedTitle:attributedTitle forState:UIControlStateNormal];
  return btn;
}

+ (void)addDisclosureIndicatorToButton:(UIButton *)button {
  // hacky, but works
  UITableViewCell *disclosure = [[UITableViewCell alloc] init];
  [button addSubview:disclosure];
  [disclosure setFrame:[button bounds]];
  [disclosure setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
  [disclosure setUserInteractionEnabled:NO];
}

+ (void)setBackgroundColorOfButton:(UIButton *)button
                             color:(UIColor *)color {
  UIImage *bgColorAsImgNormState = [PEUIUtils imageWithColor:color];
  [button setBackgroundImage:bgColorAsImgNormState forState:UIControlStateNormal];
}

+ (UIButton *)buttonWithLabel:(NSString *)labelText
                 tagForButton:(NSNumber *)tagForButton
                  recordCount:(NSInteger)recordCount
       tagForRecordCountLabel:(NSNumber *)tagForRecordCountLabel
            addDisclosureIcon:(BOOL)addDisclosureIcon
    addlVerticalButtonPadding:(CGFloat)addlVerticalButtonPadding
 recordCountFromBottomPadding:(CGFloat)recordCountFromBottomPadding
       recordCountLeftPadding:(CGFloat)recordCountLeftPadding
                      handler:(void(^)(void))handler
                    uitoolkit:(PEUIToolkit *)uitoolkit
               relativeToView:(UIView *)relativeToView {
  UIButton *button = [PEUIUtils buttonWithKey:labelText
                                         font:[uitoolkit fontForButtonsBlk]()
                              backgroundColor:[UIColor whiteColor]
                                    textColor:[UIColor darkTextColor]
                 disabledStateBackgroundColor:[UIColor whiteColor]
                       disabledStateTextColor:[UIColor grayColor]
                              verticalPadding:([uitoolkit verticalPaddingForButtons] + addlVerticalButtonPadding)
                            horizontalPadding:[uitoolkit horizontalPaddingForButtons]
                                 cornerRadius:0.0
                                       target:nil
                                       action:nil];
  if (tagForButton) {
    [button setTag:[tagForButton integerValue]];
  }
  [[button layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:button ofWidth:1.0 relativeTo:relativeToView];
  if (addDisclosureIcon) {
    [PEUIUtils addDisclosureIndicatorToButton:button];
  }
  [button bk_addEventHandler:^(id sender) {
    handler();
  } forControlEvents:UIControlEventTouchUpInside];
  UILabel *recordCountLabel = [PEUIUtils labelForRecordCount:recordCount];
  if (tagForRecordCountLabel) {
    [recordCountLabel setTag:[tagForRecordCountLabel integerValue]];
  }
  [PEUIUtils placeRecordCountLabel:recordCountLabel
                        ontoButton:button
                          hpadding:recordCountLeftPadding
                          vpadding:recordCountFromBottomPadding];
  return button;
}

+ (UIButton *)buttonWithLabel:(NSString *)labelText
                     badgeNum:(NSInteger)badgeNum
                   badgeColor:(UIColor *)badgeColor
               badgeTextColor:(UIColor *)badgeTextColor
            addDisclosureIcon:(BOOL)addDisclosureIcon
                      handler:(void(^)(void))handler
                    uitoolkit:(PEUIToolkit *)uitoolkit
               relativeToView:(UIView *)relativeToView {
  UIButton *button = [uitoolkit systemButtonMaker](labelText, nil, nil);
  [[button layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:button ofWidth:1.0 relativeTo:relativeToView];
  if (addDisclosureIcon) {
    [PEUIUtils addDisclosureIndicatorToButton:button];
  }
  [button bk_addEventHandler:^(id sender) {
    handler();
  } forControlEvents:UIControlEventTouchUpInside];
  UIView *badge = [PEUIUtils badgeForNum:badgeNum color:badgeColor badgeTextColor:badgeTextColor];
  [PEUIUtils placeView:badge
            inMiddleOf:button
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              hpadding:15.0];
  return button;
}

#pragma mark - Panels

+ (UIView *)displayPanelFromContentPanel:(UIView *)contentPanel
                               scrolling:(BOOL)scrolling
                     scrollContentOffset:(CGPoint)scrollContentOffset
                          scrollDelegate:(id<UIScrollViewDelegate>)scrollDelegate
                    delaysContentTouches:(BOOL)delaysContentTouches
                                 bounces:(BOOL)bounces
                        notScrollViewBlk:(void(^)(void))notScrollViewBlk
                                centered:(BOOL)centered
                              controller:(UIViewController *)controller {
  CGFloat contentPanelHeight = contentPanel.frame.size.height;
  CGFloat visibleControllerViewHeight = controller.view.frame.size.height;
  /*
   So, normally the status bar is translucent, and you're accordingly supposed
   to ignore the fact that it sits on top of the controller's view.  However,
   when there is a navigation bar present, it sits below the status bar, and as
   such, you have to take into account the status bar's height when calculating
   the total visible height of the controller's view.
   */
  if (controller.navigationController && !controller.navigationController.navigationBar.hidden) {
    visibleControllerViewHeight -= ([UIApplication sharedApplication].statusBarFrame.size.height +
                                      controller.navigationController.navigationBar.frame.size.height);
  }
  if (controller.tabBarController) {
    visibleControllerViewHeight -= controller.tabBarController.tabBar.frame.size.height;
  }
  UIScrollView *(^makeScrollView)(void) = ^UIScrollView * {
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:controller.view.frame];
    [scrollView setDelegate:scrollDelegate];
    [scrollView setDelaysContentTouches:delaysContentTouches];
    [scrollView setBounces:bounces];
    [scrollView setContentSize:CGSizeMake(controller.view.frame.size.width, (contentPanelHeight + (controller.view.frame.size.height / 1.5)))];
    [scrollView addSubview:contentPanel];
    [scrollView setContentOffset:scrollContentOffset animated:NO];
    return scrollView;
  };
  if (contentPanelHeight > visibleControllerViewHeight) {
    return makeScrollView();
  } else if ((contentPanelHeight * 2.0) <= visibleControllerViewHeight) {
    if (notScrollViewBlk) { notScrollViewBlk(); }
    return contentPanel;
  } else {
    if (scrolling) {
      return makeScrollView();
    } else {
      if (notScrollViewBlk) { notScrollViewBlk(); }
      return contentPanel;
    }
  }
}

+ (UIView *)dividerWithWidthOf:(CGFloat)widthOf
                         color:(UIColor *)color
                relativeToView:(UIView *)relativeToView {
  CGFloat dividerHeight = (1.0 / [UIScreen mainScreen].scale);
  UIView *divider = [PEUIUtils panelWithWidthOf:widthOf relativeToView:relativeToView fixedHeight:dividerHeight];
  [divider setBackgroundColor:color];
  return divider;
}

+ (UIView *)panelWithFixedWidth:(CGFloat)width
                    fixedHeight:(CGFloat)height {
  return [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
}

+ (UIView *)panelWithWidthOf:(CGFloat)percentage
              relativeToView:(UIView *)relativeToView
                 fixedHeight:(CGFloat)height {
  CGFloat width = relativeToView.frame.size.width * percentage;
  return [PEUIUtils panelWithFixedWidth:width fixedHeight:height];
}

+ (UIView *)panelWithWidthOf:(CGFloat)widthPercentage
                 andHeightOf:(CGFloat)heightPercentage
              relativeToView:(UIView *)relativeToView {
  CGFloat width = relativeToView.frame.size.width * widthPercentage;
  CGFloat height = relativeToView.frame.size.height * heightPercentage;
  return [PEUIUtils panelWithFixedWidth:width fixedHeight:height];
}

+ (UIView *)panelWithColumnOfViews:(NSArray *)views
       verticalPaddingBetweenViews:(CGFloat)vpadding
                    viewsAlignment:(PEUIHorizontalAlignmentType)alignment {
  UIView *panel =
    [PEUIUtils panelWithFixedWidth:[PEUIUtils widthWidestAmong:views]
                       fixedHeight:0];
  __block UIView *currentView = nil;
  __block CGFloat height = ([views count] - 1) * vpadding;
  [views enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
      if (currentView) {
        [PEUIUtils placeView:view
                       below:currentView
                        onto:panel
               withAlignment:alignment
                    vpadding:vpadding
                    hpadding:0];
      } else {
        [panel addSubview:view];
        [PEUIUtils setFrameX:[PEUIUtils XForWidth:view.frame.size.width
                                    withAlignment:alignment
                                   relativeToView:panel
                                         hpadding:0]
                      ofView:view];
      }
      currentView = view;
      height += [currentView frame].size.height;
    }];
  [PEUIUtils setFrameHeight:height ofView:panel];
  return panel;
}

+ (UIView *)twoColumnViewCluster:(NSArray *)ltColViews
                 withRightColumn:(NSArray *)rtColViews
     verticalPaddingBetweenViews:(CGFloat)vpadding
 horizontalPaddingBetweenColumns:(CGFloat)hpadding {
  UIView *ltColContainerPnl =
    [PEUIUtils panelWithColumnOfViews:ltColViews
          verticalPaddingBetweenViews:vpadding
                       viewsAlignment:PEUIHorizontalAlignmentTypeRight];
  UIView *rtColContainerPnl =
    [PEUIUtils panelWithColumnOfViews:rtColViews
          verticalPaddingBetweenViews:vpadding
                       viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
  UIView *mainPanel =
    [PEUIUtils panelWithFixedWidth:([ltColContainerPnl frame].size.width +
                                    [rtColContainerPnl frame].size.width +
                                    hpadding)
                       fixedHeight:(([ltColContainerPnl frame].size.height >
                                     [rtColContainerPnl frame].size.height) ?
                                    [ltColContainerPnl frame].size.height :
                                    [rtColContainerPnl frame].size.height)];
  [mainPanel addSubview:ltColContainerPnl];
  [PEUIUtils adjustYOfView:ltColContainerPnl
                 withValue:[PEUIUtils YForHeight:[ltColContainerPnl frame].size.height
                                   withAlignment:PEUIVerticalAlignmentTypeMiddle
                                  relativeToView:mainPanel
                                        vpadding:0]];
  [PEUIUtils placeView:rtColContainerPnl
          toTheRightOf:ltColContainerPnl
                  onto:mainPanel
         withAlignment:PEUIVerticalAlignmentTypeMiddle
              hpadding:hpadding];
  return mainPanel;
}

+ (UIView *)labelValuePanelWithCellHeight:(CGFloat)cellHeight
                              labelString:(id)labelStr
                           labelTextStyle:(NSString *)labelTextStyle
                           labelTextColor:(UIColor *)labelTextColor
                        labelLeftHPadding:(CGFloat)labelLeftHPadding
                              valueString:(NSString *)valueStr
                           valueTextStyle:(NSString *)valueTextStyle
                           valueTextColor:(UIColor *)valueTextColor
                       valueRightHPadding:(CGFloat)valueRightHPadding
                            valueLabelTag:(NSNumber *)valueLabelTag
           minPaddingBetweenLabelAndValue:(CGFloat)minPaddingBetweenLabelAndValue
                                 rowWidth:(CGFloat)rowWidth
                           relativeToView:(UIView *)relativeToView {
  UIView *rowPanel = [PEUIUtils panelWithFixedWidth:rowWidth fixedHeight:cellHeight];
  UILabel *label;
  UIFont *labelFont = [UIFont preferredFontForTextStyle:labelTextStyle];
  if ([labelStr isKindOfClass:[NSAttributedString class]]) {
    label = [PEUIUtils labelWithAttributeText:labelStr
                                         font:labelFont
                     fontForHeightCalculation:[self boldFontForTextStyle:labelTextStyle]
                              backgroundColor:[UIColor clearColor]
                                    textColor:labelTextColor
                          verticalTextPadding:0.0];
  } else {
    label = [PEUIUtils labelWithKey:labelStr
                               font:labelFont
                    backgroundColor:[UIColor clearColor]
                          textColor:labelTextColor
                verticalTextPadding:0.0];
  }
  UIFont *valueFont = [UIFont preferredFontForTextStyle:valueTextStyle];
  CGFloat availableWidth = rowPanel.frame.size.width -
    label.frame.size.width -
    minPaddingBetweenLabelAndValue -
    labelLeftHPadding -
    valueRightHPadding;
  valueStr = [PEUIUtils truncatedTextForText:valueStr font:valueFont availableWidth:availableWidth];
  UILabel *value = [PEUIUtils labelWithKey:valueStr
                                      font:valueFont
                           backgroundColor:[UIColor clearColor]
                                 textColor:valueTextColor
                       verticalTextPadding:0.0];
  if (valueLabelTag) {
    [value setTag:[valueLabelTag integerValue]];
  }
  [PEUIUtils placeView:label inMiddleOf:rowPanel withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:labelLeftHPadding];
  [PEUIUtils placeView:value inMiddleOf:rowPanel withAlignment:PEUIHorizontalAlignmentTypeRight hpadding:valueRightHPadding];
  return rowPanel;
}

+ (UIView *)tablePanelWithRowData:(NSArray *)rowData
                   withCellHeight:(CGFloat)cellHeight
                labelLeftHPadding:(CGFloat)labelLeftHPadding
               valueRightHPadding:(CGFloat)valueRightHPadding
                   labelTextStyle:(NSString *)labelTextStyle
                   valueTextStyle:(NSString *)valueTextStyle
                   labelTextColor:(UIColor *)labelTextColor
                   valueTextColor:(UIColor *)valueTextColor
   minPaddingBetweenLabelAndValue:(CGFloat)minPaddingBetweenLabelAndValue
                includeTopDivider:(BOOL)includeTopDivider
             includeBottomDivider:(BOOL)includeBottomDivider
             includeInnerDividers:(BOOL)includeInnerDividers
          innerDividerWidthFactor:(CGFloat)innerDividerWidthFactor
                   dividerPadding:(CGFloat)dividerPadding
          rowPanelBackgroundColor:(UIColor *)rowPanelPackgroundColor
             panelBackgroundColor:(UIColor *)panelBackgroundColor
                     dividerColor:(UIColor *)dividerColor
                         rowWidth:(CGFloat)rowWidth
                   relativeToView:(UIView *)relativeToView {
  return [PEUIUtils tablePanelWithRowData:rowData
                           withCellHeight:cellHeight
                        labelLeftHPadding:labelLeftHPadding
                       valueRightHPadding:valueRightHPadding
                           labelTextStyle:labelTextStyle
                           valueTextStyle:valueTextStyle
                           labelTextColor:labelTextColor
                           valueTextColor:valueTextColor
           minPaddingBetweenLabelAndValue:minPaddingBetweenLabelAndValue
                        includeTopDivider:includeTopDivider
                     includeBottomDivider:includeBottomDivider
                     includeInnerDividers:includeInnerDividers
                  innerDividerWidthFactor:innerDividerWidthFactor
                           dividerPadding:dividerPadding
                  rowPanelBackgroundColor:rowPanelPackgroundColor
                     panelBackgroundColor:panelBackgroundColor
                             dividerColor:dividerColor
                     footerAttributedText:nil
           footerFontForHeightCalculation:nil
                    footerVerticalPadding:0.0
                                 rowWidth:rowWidth
                                 maxWidth:relativeToView.frame.size.width
                           relativeToView:relativeToView];
}

+ (UIView *)tablePanelWithRowData:(NSArray *)rowData
                   withCellHeight:(CGFloat)cellHeight
                labelLeftHPadding:(CGFloat)labelLeftHPadding
               valueRightHPadding:(CGFloat)valueRightHPadding
                   labelTextStyle:(NSString *)labelTextStyle
                   valueTextStyle:(NSString *)valueTextStyle
                   labelTextColor:(UIColor *)labelTextColor
                   valueTextColor:(UIColor *)valueTextColor
   minPaddingBetweenLabelAndValue:(CGFloat)minPaddingBetweenLabelAndValue
                includeTopDivider:(BOOL)includeTopDivider
             includeBottomDivider:(BOOL)includeBottomDivider
             includeInnerDividers:(BOOL)includeInnerDividers
          innerDividerWidthFactor:(CGFloat)innerDividerWidthFactor
                   dividerPadding:(CGFloat)dividerPadding
          rowPanelBackgroundColor:(UIColor *)rowPanelPackgroundColor
             panelBackgroundColor:(UIColor *)panelBackgroundColor
                     dividerColor:(UIColor *)dividerColor
             footerAttributedText:(NSAttributedString *)footerAttributedText
   footerFontForHeightCalculation:(UIFont *)footerFontForHeightCalculation
            footerVerticalPadding:(CGFloat)footerVerticalPadding
                         maxWidth:(CGFloat)maxWidth
                   relativeToView:(UIView *)relativeToView {
  CGFloat maxWidthOfLabelLbl = 0.0;
  CGFloat maxWidthOfValueLbl = 0.0;
  for (NSArray *row in rowData) {
    NSString *labelStr = row[0];
    NSString *valueStr = row[1];
    CGFloat wouldBeWidthOfValueLbl = [PEUIUtils sizeOfText:valueStr
                                                  withFont:[self boldFontForTextStyle:valueTextStyle]].width;
    if (wouldBeWidthOfValueLbl > maxWidthOfValueLbl) {
      maxWidthOfValueLbl = wouldBeWidthOfValueLbl;
    }
    CGFloat wouldBeWidthOfLabelLbl = [PEUIUtils sizeOfText:labelStr
                                                  withFont:[self boldFontForTextStyle:labelTextStyle]].width;
    if (wouldBeWidthOfLabelLbl > maxWidthOfLabelLbl) {
      maxWidthOfLabelLbl = wouldBeWidthOfLabelLbl;
    }
  }
  CGFloat totalWidthNeeded = labelLeftHPadding + maxWidthOfLabelLbl + minPaddingBetweenLabelAndValue + maxWidthOfValueLbl + valueRightHPadding;
  if (totalWidthNeeded > relativeToView.frame.size.width) {
    totalWidthNeeded = relativeToView.frame.size.width;
  }
  return [self tablePanelWithRowData:rowData
                      withCellHeight:cellHeight
                   labelLeftHPadding:labelLeftHPadding
                  valueRightHPadding:valueRightHPadding
                      labelTextStyle:(NSString *)labelTextStyle
                      valueTextStyle:(NSString *)valueTextStyle
                      labelTextColor:labelTextColor
                      valueTextColor:valueTextColor
      minPaddingBetweenLabelAndValue:minPaddingBetweenLabelAndValue
                   includeTopDivider:includeTopDivider
                includeBottomDivider:includeBottomDivider
                includeInnerDividers:includeInnerDividers
             innerDividerWidthFactor:innerDividerWidthFactor
                      dividerPadding:dividerPadding
             rowPanelBackgroundColor:rowPanelPackgroundColor
                panelBackgroundColor:panelBackgroundColor
                        dividerColor:dividerColor
                footerAttributedText:footerAttributedText
      footerFontForHeightCalculation:footerFontForHeightCalculation
               footerVerticalPadding:footerVerticalPadding
                            rowWidth:totalWidthNeeded
                            maxWidth:maxWidth
                      relativeToView:relativeToView];
}

+ (UIView *)tablePanelWithRowData:(NSArray *)rowData
                   withCellHeight:(CGFloat)cellHeight
                labelLeftHPadding:(CGFloat)labelLeftHPadding
               valueRightHPadding:(CGFloat)valueRightHPadding
                   labelTextStyle:(NSString *)labelTextStyle
                   valueTextStyle:(NSString *)valueTextStyle
                   labelTextColor:(UIColor *)labelTextColor
                   valueTextColor:(UIColor *)valueTextColor
   minPaddingBetweenLabelAndValue:(CGFloat)minPaddingBetweenLabelAndValue
                includeTopDivider:(BOOL)includeTopDivider
             includeBottomDivider:(BOOL)includeBottomDivider
             includeInnerDividers:(BOOL)includeInnerDividers
          innerDividerWidthFactor:(CGFloat)innerDividerWidthFactor
                   dividerPadding:(CGFloat)dividerPadding
          rowPanelBackgroundColor:(UIColor *)rowPanelPackgroundColor
             panelBackgroundColor:(UIColor *)panelBackgroundColor
                     dividerColor:(UIColor *)dividerColor
             footerAttributedText:(NSAttributedString *)footerAttributedText
   footerFontForHeightCalculation:(UIFont *)footerFontForHeightCalculation
            footerVerticalPadding:(CGFloat)footerVerticalPadding
                         rowWidth:(CGFloat)rowWidth
                         maxWidth:(CGFloat)maxWidth
                   relativeToView:(UIView *)relativeToView {
  CGFloat dividerHeight = (1.0 / [UIScreen mainScreen].scale);
  NSInteger numRows = [rowData count];
  CGFloat innerDividerPaddingFactor = includeInnerDividers ? 2.0 : 1.5;
  CGFloat panelHeight = (includeTopDivider ? (dividerHeight + (innerDividerPaddingFactor * dividerPadding)) : 0) + // top divider and its padding
    (includeBottomDivider ? (dividerHeight + (innerDividerPaddingFactor * dividerPadding)) : 0) + // bottom divider and its padding
    (numRows * cellHeight) + // cumulative cell height
    (includeInnerDividers ? ((numRows - 1) * dividerHeight) : 0) + // cumulative height of inner dividers
    ((numRows -1) * (innerDividerPaddingFactor * dividerPadding)); // cumulative height of inner divider paddings
  CGFloat panelWidth = rowWidth;
  if (rowWidth > maxWidth) {
    panelWidth = maxWidth;
  }
  UIView *panel = [PEUIUtils panelWithFixedWidth:panelWidth fixedHeight:panelHeight];
  [panel setBackgroundColor:panelBackgroundColor];
  UIView *divider = nil;
  UIView *(^makeDivider)(CGFloat) = ^ UIView * (CGFloat widthOf) {
    UIView *divider = [PEUIUtils panelWithWidthOf:widthOf relativeToView:relativeToView fixedHeight:dividerHeight];
    [divider setBackgroundColor:dividerColor];
    return divider;
  };
  UIView *topDivider = nil;
  if (includeTopDivider) {
    topDivider = makeDivider(1.0);
    [PEUIUtils placeView:topDivider atTopOf:panel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
  }
  UIView *aboveRowPanel = topDivider;
  for (int i = 0; i < numRows; i++) {
    NSArray *cellData = rowData[i];
    id labelStr = cellData[0];
    NSString *valueStr = cellData[1];
    UIView *rowPanel = [PEUIUtils labelValuePanelWithCellHeight:cellHeight
                                                    labelString:labelStr
                                                 labelTextStyle:labelTextStyle
                                                 labelTextColor:labelTextColor
                                              labelLeftHPadding:labelLeftHPadding
                                                    valueString:valueStr
                                                 valueTextStyle:valueTextStyle
                                                 valueTextColor:valueTextColor
                                             valueRightHPadding:valueRightHPadding
                                                  valueLabelTag:@(i + 1)
                                 minPaddingBetweenLabelAndValue:minPaddingBetweenLabelAndValue
                                                       rowWidth:panelWidth
                                                 relativeToView:relativeToView];
    [rowPanel setBackgroundColor:rowPanelPackgroundColor];
    if (i == 0) {
      if (includeTopDivider) {
        [PEUIUtils placeView:rowPanel
                       below:topDivider
                        onto:panel
               withAlignment:PEUIHorizontalAlignmentTypeLeft
                    vpadding:(innerDividerPaddingFactor * dividerPadding)
                    hpadding:0.0];
      } else {
        [PEUIUtils placeView:rowPanel
                     atTopOf:panel
               withAlignment:PEUIHorizontalAlignmentTypeLeft
                    vpadding:0.0
                    hpadding:0.0];
      }
    } else {
      [PEUIUtils placeView:rowPanel
                     below:aboveRowPanel
                      onto:panel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:(includeInnerDividers ? (dividerHeight + (innerDividerPaddingFactor * dividerPadding)) : (innerDividerPaddingFactor * dividerPadding))
                  hpadding:0.0];
    }
    aboveRowPanel = rowPanel;
    if (includeInnerDividers) {
      if (i + 1 < numRows) {
        divider = makeDivider(innerDividerWidthFactor);
        [PEUIUtils placeView:divider
                       below:rowPanel
                        onto:panel
               withAlignment:PEUIHorizontalAlignmentTypeRight
                    vpadding:dividerPadding
                    hpadding:0.0];
      }
    }
  }
  if (includeBottomDivider) {
    UIView *bottomDivider = makeDivider(1.0);
    if (aboveRowPanel) {
      [PEUIUtils placeView:bottomDivider
                     below:aboveRowPanel
                      onto:panel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:(innerDividerPaddingFactor * dividerPadding)
                  hpadding:0.0];
    } else {
      [PEUIUtils placeView:bottomDivider
                atTopOf:panel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:0.0
                  hpadding:0.0];
    }
    aboveRowPanel = bottomDivider;
  }
  if (footerAttributedText) {
    UILabel *footerLabel = [PEUIUtils labelWithAttributeText:footerAttributedText
                                                        font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                    fontForHeightCalculation:footerFontForHeightCalculation
                                             backgroundColor:[UIColor clearColor]
                                                   textColor:[UIColor darkGrayColor]
                                         verticalTextPadding:3.0
                                                  fitToWidth:(panel.frame.size.width - 8)];
    [PEUIUtils placeView:footerLabel
                   below:aboveRowPanel
                    onto:panel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:footerVerticalPadding
                hpadding:10.0];
    [PEUIUtils setFrameHeight:(panel.frame.size.height + footerVerticalPadding + footerLabel.frame.size.height) ofView:panel];
  }
  return panel;
}

+ (UIView *)tablePanelWithRowData:(NSArray *)rowData
                        uitoolkit:(PEUIToolkit *)uitoolkit
                       parentView:(UIView *)parentView {
  return [PEUIUtils tablePanelWithRowData:rowData
                     footerAttributedText:nil
           footerFontForHeightCalculation:nil
                    footerVerticalPadding:0.0
                                uitoolkit:uitoolkit
                               parentView:parentView];
}

+ (UIView *)tablePanelWithRowData:(NSArray *)rowData
             footerAttributedText:(NSAttributedString *)footerAttributedText
   footerFontForHeightCalculation:(UIFont *)footerFontForHeightCalculation
            footerVerticalPadding:(CGFloat)footerVerticalPadding
                        uitoolkit:(PEUIToolkit *)uitoolkit
                       parentView:(UIView *)parentView {
  return [PEUIUtils tablePanelWithRowData:rowData
                           withCellHeight:([PEUIUtils sizeOfText:@"" withFont:[self boldFontForTextStyle:UIFontTextStyleBody]].height + uitoolkit.verticalPaddingForButtons)
                        labelLeftHPadding:10.0
                       valueRightHPadding:12.5
                           labelTextStyle:UIFontTextStyleBody
                           valueTextStyle:UIFontTextStyleBody
                           labelTextColor:[UIColor blackColor]
                           valueTextColor:[UIColor grayColor]
           minPaddingBetweenLabelAndValue:10.0
                        includeTopDivider:NO
                     includeBottomDivider:NO
                     includeInnerDividers:NO
                  innerDividerWidthFactor:0.95
                           dividerPadding:3.5
                  rowPanelBackgroundColor:[UIColor whiteColor]
                     panelBackgroundColor:[uitoolkit colorForWindows]
                             dividerColor:nil
                     footerAttributedText:footerAttributedText
           footerFontForHeightCalculation:footerFontForHeightCalculation
                    footerVerticalPadding:footerVerticalPadding
                                 rowWidth:parentView.frame.size.width
                                 maxWidth:parentView.frame.size.width
                           relativeToView:parentView];
}


+ (UIView *)panelWithViews:(NSArray *)views
                   ofWidth:(CGFloat)percentage
      vertAlignmentOfViews:(PEUIVerticalAlignmentType)vertAlignment
       horAlignmentOfViews:(PEUIHorizontalAlignmentType)horAlignment
                relativeTo:(UIView *)relativeToView
                  vpadding:(CGFloat)vpadding
                  hpadding:(CGFloat)hpadding {
  UIView *viewHolder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  NSUInteger numViews = [views count];
  int tallestHeight = 0;
  if (numViews > 0) {
    UIView *view = [views objectAtIndex:0];
    [viewHolder addSubview:view];
    int runningWidth = [view frame].size.width;
    tallestHeight = [view frame].size.height;
    UIView *previousView = view;
    for (int i = 1; i < numViews; i++) {
      view = [views objectAtIndex:i];
      [PEUIUtils placeView:view
              toTheRightOf:previousView
                      onto:viewHolder
             withAlignment:vertAlignment
                  hpadding:hpadding];
      runningWidth += [view frame].size.width + hpadding;
      if ([view frame].size.height > tallestHeight) {
        tallestHeight = [view frame].size.height;
      }
      previousView = view;
    }
    [PEUIUtils setFrameWidth:runningWidth ofView:viewHolder];
    [PEUIUtils setFrameHeight:tallestHeight ofView:viewHolder];
  }
  UIView *outerPnl = [PEUIUtils panelWithWidthOf:percentage
                                  relativeToView:relativeToView
                                     fixedHeight:tallestHeight];
  [PEUIUtils placeView:viewHolder
            inMiddleOf:outerPnl
         withAlignment:horAlignment
              hpadding:0];
  return outerPnl;
}

+ (UIView *)panelWithTitle:(NSString *)title
                titleImage:(UIImage *)titleImage
               description:(NSAttributedString *)description
            relativeToView:(UIView *)relativeToView {
  return [PEUIUtils panelWithMsgs:nil
                            title:title
                       titleImage:titleImage
                      description:description
                      messageIcon:nil
                   relativeToView:relativeToView];
}

+ (UIView *)panelWithTitle:(NSString *)title
                titleImage:(UIImage *)titleImage
           descriptionText:(NSString *)descriptionText
           instructionText:(NSString *)instructionText
            relativeToView:(UIView *)relativeToView {
  UIFont* boldSubheadlineFont = [self boldFontForTextStyle:UIFontTextStyleSubheadline];
  NSString *descTextWithInstructionalText = [NSString stringWithFormat:@"%@%@", descriptionText, instructionText];
  NSDictionary *attrs = @{ NSFontAttributeName : boldSubheadlineFont };
  NSMutableAttributedString *attrDescTextWithInstructionalText =
    [[NSMutableAttributedString alloc] initWithString:descTextWithInstructionalText];
  NSRange instructionTextRange  = [descTextWithInstructionalText rangeOfString:instructionText];
  [attrDescTextWithInstructionalText setAttributes:attrs range:instructionTextRange];
  return [PEUIUtils panelWithTitle:title
                        titleImage:titleImage
                       description:attrDescTextWithInstructionalText
                    relativeToView:relativeToView];
}

+ (UIView *)panelWithMsgs:(NSArray *)msgs
                    title:(NSString *)title
               titleImage:(UIImage *)titleImage
              description:(NSAttributedString *)description
              messageIcon:(UIImage *)messageIcon
           relativeToView:(UIView *)relativeToView {
  return [PEUIUtils panelWithMsgs:msgs
                            title:title
                       titleImage:titleImage
                      description:description
                  descriptionFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                      messageIcon:messageIcon
                   relativeToView:relativeToView];
}

+ (UIView *)panelWithMsgs:(NSArray *)msgs
                    title:(NSString *)title
               titleImage:(UIImage *)titleImage
              description:(NSAttributedString *)description
          descriptionFont:(UIFont *)descriptionFont
              messageIcon:(UIImage *)messageIcon
           relativeToView:(UIView *)relativeToView {
  return [PEUIUtils panelWithMsgs:msgs
                            title:title
                       titleImage:titleImage
                    topRightImage:nil
                      description:description
                  descriptionFont:descriptionFont
                      messageIcon:messageIcon
                   relativeToView:relativeToView];
}

+ (UIView *)panelWithMsgs:(NSArray *)msgs
                    title:(NSString *)title
               titleImage:(UIImage *)titleImage
            topRightImage:(UIImage *)topRightImage
              description:(NSAttributedString *)description
          descriptionFont:(UIFont *)descriptionFont
              messageIcon:(UIImage *)messageIcon
           relativeToView:(UIView *)relativeToView {
  UIView *contentView = [PEUIUtils panelWithWidthOf:0.905 relativeToView:relativeToView fixedHeight:0];
  UIView *topPanel;
  CGFloat topViewHeight;
  UIFont* boldBodyFont = [self boldFontForTextStyle:UIFontTextStyleBody];
  if (title) {
    UILabel *(^makeTitleLabel)(CGFloat) = ^ UILabel * (CGFloat widthToFit) {
      return [PEUIUtils labelWithKey:title
                                font:boldBodyFont
                     backgroundColor:[UIColor clearColor]
                           textColor:[UIColor blackColor]
                 verticalTextPadding:0.0
                          fitToWidth:widthToFit];
    };
    if (titleImage) {
      CGFloat leftPaddingForTitleImg = 2.0;
      CGFloat paddingBetweenTitleImgAndLabel = 8.0;
      UIImageView *titleImageView = [[UIImageView alloc] initWithImage:titleImage];
      UILabel *titleLbl = makeTitleLabel(contentView.frame.size.width - titleImageView.frame.size.width - leftPaddingForTitleImg - paddingBetweenTitleImgAndLabel);
      topViewHeight = (titleImageView.frame.size.height > titleLbl.frame.size.height
                       ? titleImageView.frame.size.height : titleLbl.frame.size.height);
      topPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:contentView fixedHeight:topViewHeight];
      [PEUIUtils placeView:titleImageView
                inMiddleOf:topPanel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  hpadding:leftPaddingForTitleImg];
      [PEUIUtils placeView:titleLbl
              toTheRightOf:titleImageView
                      onto:topPanel
             withAlignment:PEUIVerticalAlignmentTypeMiddle
                  hpadding:paddingBetweenTitleImgAndLabel];
    } else {
      UILabel *titleLbl = makeTitleLabel(contentView.frame.size.width);
      topViewHeight = titleLbl.frame.size.height;
      topPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:contentView fixedHeight:topViewHeight];
      [PEUIUtils placeView:titleLbl
                inMiddleOf:topPanel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  hpadding:2.0];
    }
  } else {
    topViewHeight = 0.0;
    topPanel = [PEUIUtils panelWithFixedWidth:0.0 fixedHeight:topViewHeight];
  }
  UIFont* boldSubheadlineFont = [self boldFontForTextStyle:UIFontTextStyleSubheadline];
  UILabel *descriptionLbl = [PEUIUtils labelWithAttributeText:description
                                                         font:descriptionFont
                                     fontForHeightCalculation:boldSubheadlineFont
                                              backgroundColor:[UIColor clearColor]
                                                    textColor:[UIColor blackColor]
                                          verticalTextPadding:0.0
                                                   fitToWidth:contentView.frame.size.width - 5.0];
  UIImageView *topRightImageView = nil;
  if (topRightImage) {
    topRightImageView = [[UIImageView alloc] initWithImage:topRightImage];
  }
  UIView *alertPanelsColumn = nil;
  if ([msgs count] > 0) {
    alertPanelsColumn = [PEUIUtils panelWithColumnOfViews:[PEUIUtils alertPanelsForMessages:msgs
                                                                                      width:contentView.frame.size.width
                                                                                leftImgIcon:messageIcon]
                              verticalPaddingBetweenViews:3.0
                                           viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
  }
  CGFloat topPanelVpadding = 3.0;
  CGFloat panelsVpadding = alertPanelsColumn != nil ? 13.0 : 0.0;
  CGFloat contentViewHeight = topViewHeight + descriptionLbl.frame.size.height + alertPanelsColumn.frame.size.height;
  CGFloat descriptionVpadding = 13.0;
  contentViewHeight += topPanelVpadding + descriptionVpadding + panelsVpadding;
  // now add a little bit more height so there's some nice bottom-padding; we'll have more
  // padding for when we have no messages panel-column.
  if ([msgs count] > 0) {
    contentViewHeight += 7.5;
  } else {
    contentViewHeight += 10.0;
  }
  [PEUIUtils setFrameHeight:contentViewHeight ofView:contentView];
  if (topRightImageView) {
    [PEUIUtils placeView:topRightImageView atTopOf:contentView withAlignment:PEUIHorizontalAlignmentTypeRight vpadding:3.0 hpadding:3.0];
  }
  [PEUIUtils placeView:topPanel
               atTopOf:contentView
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:topPanelVpadding
              hpadding:0.0];
  [PEUIUtils placeView:descriptionLbl
                 below:topPanel
                  onto:contentView
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:descriptionVpadding
              hpadding:3.0];
  if (alertPanelsColumn) {
    [PEUIUtils placeView:alertPanelsColumn
                   below:descriptionLbl
                    onto:contentView
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:panelsVpadding
                hpadding:0.0];
  }
  return contentView;
}

+ (UIView *)failuresPanelWithFailures:(NSArray *)failures
                                width:(CGFloat)width {
  NSMutableArray *failurePanels = [NSMutableArray arrayWithCapacity:[failures count]];
  for (NSArray *failure in failures) {
    NSString *failureTitle = failure[0];
    //BOOL isFailureFixableByUser = [failure[1] boolValue];
    NSArray *failureReasons = failure[2];
    UIView *failureReasonsPanel = [PEUIUtils panelWithColumnOfViews:[PEUIUtils alertPanelsForMessages:failureReasons
                                                                                                width:(width - (width * 0.05))
                                                                                          leftImgIcon:[PEUIUtils bundleImageWithName:@"black-dot"]]
                                        verticalPaddingBetweenViews:0.0
                                                     viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
    UIView *failurePanel = [PEUIUtils messagePanelWithTitle:failureTitle
                                                leftImgIcon:[PEUIUtils bundleImageWithName:@"error-icon"]
                                                      width:width];
    [PEUIUtils setFrameHeight:(failurePanel.frame.size.height + failureReasonsPanel.frame.size.height)
                       ofView:failurePanel];
    [PEUIUtils placeView:failureReasonsPanel
              atBottomOf:failurePanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:(width * 0.05)];
    [failurePanels addObject:failurePanel];
  }
  return [PEUIUtils panelWithColumnOfViews:failurePanels
               verticalPaddingBetweenViews:1.0
                            viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
}

+ (UIView *)failuresPanelWithFailures:(NSArray *)failures
                          description:(NSAttributedString *)description
                      descriptionFont:(UIFont *)descriptionFont
                       relativeToView:(UIView *)relativeToView {
  return [PEUIUtils failuresPanelWithFailures:failures
                                        title:nil
                                  description:description
                              descriptionFont:descriptionFont
                               relativeToView:relativeToView];
}

+ (UIView *)failuresPanelWithFailures:(NSArray *)failures
                                title:(NSString *)title
                          description:(NSAttributedString *)description
                      descriptionFont:(UIFont *)descriptionFont
                       relativeToView:(UIView *)relativeToView {
  UIView *contentView = [PEUIUtils panelWithMsgs:nil
                                           title:title
                                      titleImage:(title != nil ? [PEUIUtils bundleImageWithName:@"error"] : nil)
                                     description:description
                                 descriptionFont:descriptionFont
                                     messageIcon:nil
                                  relativeToView:relativeToView];
  UIView *failuresPanel = [PEUIUtils failuresPanelWithFailures:failures
                                                         width:contentView.frame.size.width];
  // extending the height here will give a nice bit of bottom-padding
  [PEUIUtils setFrameHeight:failuresPanel.frame.size.height + 6.5 ofView:failuresPanel];
  return [PEUIUtils panelWithColumnOfViews:@[contentView, failuresPanel]
               verticalPaddingBetweenViews:0.0
                            viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
}

+ (UIView *)mixedResultsPanelWithSuccessMsgs:(NSArray *)successMsgs
                                       title:(NSString *)title
                                 description:(NSAttributedString *)description
                         failuresDescription:(NSAttributedString *)failuresDescription
                                    failures:(NSArray *)failures
                              relativeToView:(UIView *)relativeToView {
  UIView *successesContent = [PEUIUtils panelWithMsgs:successMsgs
                                                title:title
                                           titleImage:[PEUIUtils bundleImageWithName:@"warning"]
                                          description:description
                                          messageIcon:[PEUIUtils bundleImageWithName:@"success-icon"]
                                       relativeToView:relativeToView];
  UIView *failuresContent = [PEUIUtils failuresPanelWithFailures:failures
                                                     description:failuresDescription
                                                 descriptionFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                                  relativeToView:relativeToView];
  return [PEUIUtils panelWithColumnOfViews:@[successesContent, failuresContent]
               verticalPaddingBetweenViews:0.0
                            viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
}

+ (NSArray *)conflictResolvePanelWithFields:(NSArray *)fields
                             withCellHeight:(CGFloat)cellHeight
                          labelLeftHPadding:(CGFloat)labelLeftHPadding
                         valueRightHPadding:(CGFloat)valueRightHPadding
                                  labelFont:(UIFont *)labelFont
                                  valueFont:(UIFont *)valueFont
                             labelTextColor:(UIColor *)labelTextColor
                             valueTextColor:(UIColor *)valueTextColor
             minPaddingBetweenLabelAndValue:(CGFloat)minPaddingBetweenLabelAndValue
                          includeTopDivider:(BOOL)includeTopDivider
                       includeBottomDivider:(BOOL)includeBottomDivider
                       includeInnerDividers:(BOOL)includeInnerDividers
                    innerDividerWidthFactor:(CGFloat)innerDividerWidthFactor
                             dividerPadding:(CGFloat)dividerPadding
                    rowPanelBackgroundColor:(UIColor *)rowPanelPackgroundColor
                       panelBackgroundColor:(UIColor *)panelBackgroundColor
                               dividerColor:(UIColor *)dividerColor
                             relativeToView:(UIView *)relativeToView {
  CGFloat dividerHeight = (1.0 / [UIScreen mainScreen].scale);
  NSInteger numRows = [fields count];
  CGFloat rowContainerHeightFactor = 1.2;
  CGFloat paddingBetweenRowPanels = 5.0;
  CGFloat innerDividerPaddingFactor = includeInnerDividers ? 2.0 : 1.5;
  CGFloat panelHeight = (includeTopDivider ? (dividerHeight + (innerDividerPaddingFactor * dividerPadding)) : 0) + // top divider and its padding
    (includeBottomDivider ? (dividerHeight + (innerDividerPaddingFactor * dividerPadding)) : 0) + // bottom divider and its padding
    (numRows * (2 * (paddingBetweenRowPanels + (rowContainerHeightFactor * cellHeight)))) + // cumulative cell height
    (includeInnerDividers ? ((numRows - 1) * dividerHeight) : 0) + // cumulative height of inner dividers
    ((numRows -1) * (innerDividerPaddingFactor * dividerPadding)); // cumulative height of inner divider paddings
  UIView *panel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:relativeToView fixedHeight:panelHeight];
  [panel setBackgroundColor:panelBackgroundColor];
  UIView *divider = nil;
  UIView *(^makeDivider)(CGFloat) = ^ UIView * (CGFloat widthOf) {
    UIView *divider = [PEUIUtils panelWithWidthOf:widthOf relativeToView:relativeToView fixedHeight:dividerHeight];
    [divider setBackgroundColor:dividerColor];
    return divider;
  };
  UIView *topDivider = nil;
  if (includeTopDivider) {
    topDivider = makeDivider(1.0);
    [PEUIUtils placeView:topDivider atTopOf:panel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
  }
  UIView *aboveRowPanel;
  CGFloat widthOfElipses = [PEUIUtils sizeOfText:@"..." withFont:valueFont].width;
  UILabel *(^makeLabel)(NSString *, UIFont *, UIColor *) = ^ (NSString *fieldLabelStr, UIFont *font, UIColor *textColor) {
    return [PEUIUtils labelWithKey:fieldLabelStr
                              font:font
                   backgroundColor:[UIColor clearColor]
                         textColor:textColor
               verticalTextPadding:0.0];
  };
  NSString *(^truncateValueString)(CGFloat, NSString *) = ^(CGFloat availableWidth, NSString *valueStr) {
    CGFloat wouldBeWidthOfValueLabel = [PEUIUtils sizeOfText:valueStr withFont:valueFont].width;
    if (wouldBeWidthOfValueLabel > availableWidth) {
      CGFloat avgWidthPerLetter = wouldBeWidthOfValueLabel / [valueStr length];
      NSInteger allowedNumLetters = (availableWidth - widthOfElipses) / avgWidthPerLetter;
      valueStr = [[valueStr substringToIndex:allowedNumLetters] stringByAppendingString:@"..."];
    }
    return valueStr;
  };
  CGFloat rowPanelContainerWidthFactor = 0.967;
  CGFloat rowPanelWidthFactor = 0.825;
  UIColor *selectedColor = [UIColor blueColor];
  UIColor *unselectedColor = [UIColor darkGrayColor];
  NSArray *(^makeRowPanel)(NSString *,
                          NSString *,
                          NSString *) = ^(NSString *fieldName,
                                          NSString *valueStr,
                                          NSString *indicatorStr) {
    UIView *rowPanel = [PEUIUtils panelWithWidthOf:rowPanelWidthFactor relativeToView:panel fixedHeight:cellHeight];
    [rowPanel setBackgroundColor:rowPanelPackgroundColor];
    CGFloat rowPanelContainerHeight = rowContainerHeightFactor * rowPanel.frame.size.height;
    UIView *rowPanelContainer = [PEUIUtils panelWithWidthOf:rowPanelContainerWidthFactor relativeToView:panel fixedHeight:rowPanelContainerHeight];
    [rowPanelContainer setBackgroundColor:[UIColor clearColor]];
    [PEUIUtils applyBorderToView:rowPanel withColor:selectedColor width:3.0];
    UILabel *localLabel = makeLabel(fieldName, labelFont, labelTextColor);
    CGFloat availableWidth = rowPanel.frame.size.width -
    localLabel.frame.size.width -
    minPaddingBetweenLabelAndValue -
    labelLeftHPadding -
    valueRightHPadding;
    valueStr = truncateValueString(availableWidth, valueStr);
    UILabel *value = makeLabel(valueStr, valueFont, valueTextColor);
    UILabel *ind = makeLabel(indicatorStr, [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2], selectedColor);
    // http://stackoverflow.com/questions/13670181/how-can-i-remove-uilabels-gray-border-on-the-right-side
    [ind setBackgroundColor:[UIColor clearColor]];
    [[ind layer] setBackgroundColor:[UIColor whiteColor].CGColor];
    UIButton *useBtn = [PEUIUtils buttonWithKey:@"Use"
                                           font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                backgroundColor:selectedColor
                                      textColor:[UIColor whiteColor]
                   disabledStateBackgroundColor:nil
                         disabledStateTextColor:nil
                                verticalPadding:5.0
                              horizontalPadding:12.0
                                   cornerRadius:3.0
                                         target:nil
                                         action:nil];
    [PEUIUtils setFrameHeight:rowPanel.frame.size.height ofView:useBtn];
    [PEUIUtils placeView:localLabel inMiddleOf:rowPanel withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:labelLeftHPadding];
    [PEUIUtils placeView:value inMiddleOf:rowPanel withAlignment:PEUIHorizontalAlignmentTypeRight hpadding:valueRightHPadding];
    [PEUIUtils placeView:rowPanel atBottomOf:rowPanelContainer withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
    [PEUIUtils placeView:ind atTopOf:rowPanelContainer withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:1.0 hpadding:20.0];
    [PEUIUtils placeView:useBtn atBottomOf:rowPanelContainer withAlignment:PEUIHorizontalAlignmentTypeRight vpadding:0.0 hpadding:1.0];
    return @[rowPanelContainer, rowPanel, useBtn, ind, value];
  };
  NSMutableArray *valueLabels = [NSMutableArray arrayWithCapacity:numRows];
  for (int i = 0; i < numRows; i++) {
    NSArray *field = fields[i];
    NSString *fieldName = field[0];
    NSInteger fieldTagValue = [field[1] integerValue];
    NSString *localValueStr = field[2];
    NSString *remoteValueStr = field[3];
    NSArray *localRowArray = makeRowPanel(fieldName, localValueStr, @" Local ");
    NSArray *remoteRowArray = makeRowPanel(fieldName, remoteValueStr, @" Remote ");
    UIView *localRowContainerPanel = localRowArray[0];
    UIView *remoteRowContainerPanel = remoteRowArray[0];
    UIView *localRowPanel = localRowArray[1];
    UIView *remoteRowPanel = remoteRowArray[1];
    UIButton *useLocalBtn = localRowArray[2];
    UIButton *useRemoteBtn = remoteRowArray[2];
    UILabel *localInd = localRowArray[3];
    UILabel *remoteInd = remoteRowArray[3];
    UILabel *localValue = localRowArray[4];
    UILabel *remoteValue = remoteRowArray[4];
    valueLabels[i] = @[localValue, remoteValue];
    [localValue setTag:fieldTagValue];
    [PEUIUtils applyBorderToView:remoteRowPanel withColor:unselectedColor];
    [PEUIUtils setBackgroundColorOfButton:useRemoteBtn color:unselectedColor];
    [remoteInd setTextColor:unselectedColor];
    [useLocalBtn bk_addEventHandler:^(id sender) {
      [PEUIUtils applyBorderToView:localRowPanel withColor:selectedColor width:3.0];
      [PEUIUtils setBackgroundColorOfButton:useLocalBtn color:selectedColor];
      [localInd setTextColor:selectedColor];
      [localValue setTag:fieldTagValue];
      
      [PEUIUtils applyBorderToView:remoteRowPanel withColor:unselectedColor];
      [PEUIUtils setBackgroundColorOfButton:useRemoteBtn color:unselectedColor];
      [remoteInd setTextColor:unselectedColor];
      [remoteValue setTag:0];
    } forControlEvents:UIControlEventTouchUpInside];
    [useRemoteBtn bk_addEventHandler:^(id sender) {
      [PEUIUtils applyBorderToView:localRowPanel withColor:unselectedColor];
      [PEUIUtils setBackgroundColorOfButton:useLocalBtn color:unselectedColor];
      [localInd setTextColor:unselectedColor];
      [localValue setTag:0];
      
      [PEUIUtils applyBorderToView:remoteRowPanel withColor:selectedColor width:3.0];
      [PEUIUtils setBackgroundColorOfButton:useRemoteBtn color:selectedColor];
      [remoteInd setTextColor:selectedColor];
      [remoteValue setTag:fieldTagValue];
    } forControlEvents:UIControlEventTouchUpInside];
    UIView *rowPanelContainer = [PEUIUtils panelWithFixedWidth:localRowContainerPanel.frame.size.width
                                                   fixedHeight:((localRowContainerPanel.frame.size.height * 2) + paddingBetweenRowPanels)];
    [PEUIUtils placeView:localRowContainerPanel
                 atTopOf:rowPanelContainer
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0.0];
    [PEUIUtils placeView:remoteRowContainerPanel
                   below:localRowContainerPanel
                    onto:rowPanelContainer
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0.0];
    if (i == 0) {
      if (includeTopDivider) {
        [PEUIUtils placeView:rowPanelContainer
                       below:topDivider
                        onto:panel
               withAlignment:PEUIHorizontalAlignmentTypeLeft
                    vpadding:(innerDividerPaddingFactor * dividerPadding)
                    hpadding:0.0];
      } else {
        [PEUIUtils placeView:rowPanelContainer
                     atTopOf:panel
               withAlignment:PEUIHorizontalAlignmentTypeLeft
                    vpadding:0.0
                    hpadding:0.0];
      }
    } else {
      [PEUIUtils placeView:rowPanelContainer
                     below:aboveRowPanel
                      onto:panel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:(includeInnerDividers ? (dividerHeight + (innerDividerPaddingFactor * dividerPadding)) : (innerDividerPaddingFactor * dividerPadding))
                  hpadding:0.0];
    }
    aboveRowPanel = rowPanelContainer;
    if (includeInnerDividers) {
      if (i + 1 < numRows) {
        divider = makeDivider(innerDividerWidthFactor);
        [PEUIUtils placeView:divider
                       below:rowPanelContainer
                        onto:panel
               withAlignment:PEUIHorizontalAlignmentTypeRight
                    vpadding:dividerPadding
                    hpadding:0.0];
      }
    }
  }
  if (includeBottomDivider) {
    UIView *bottomDivider = makeDivider(1.0);
    [PEUIUtils placeView:bottomDivider
              atBottomOf:panel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:(innerDividerPaddingFactor * dividerPadding)
                hpadding:0.0];
  }
  return @[panel, valueLabels];
}

+ (UIView *)loginSuccessPanelWithTitle:(NSString *)title
                           description:(NSAttributedString *)description
                       descriptionFont:(UIFont *)descriptionFont
                       syncIconMessage:(NSAttributedString *)syncIconMessage
                         syncImageIcon:(UIImage *)syncImageIcon
                        relativeToView:(UIView *)relativeToView {
  UIView *contentView = [PEUIUtils panelWithWidthOf:0.905 relativeToView:relativeToView fixedHeight:0];
  UIView *topPanel;
  CGFloat topViewHeight;
  UIImageView *titleImageView = [[UIImageView alloc] initWithImage:[PEUIUtils bundleImageWithName:@"success"]];
  CGFloat leftPaddingForTitleImg = 2.0;
  CGFloat paddingBetweenTitleImgAndLabel = 8.0;
  UILabel *titleLbl = [PEUIUtils labelWithKey:title
                                         font:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                              backgroundColor:[UIColor clearColor]
                                    textColor:[UIColor blackColor]
                          verticalTextPadding:0.0
                                   fitToWidth:(contentView.frame.size.width - titleImageView.frame.size.width - leftPaddingForTitleImg - paddingBetweenTitleImgAndLabel)];
  topViewHeight = (titleImageView.frame.size.height > titleLbl.frame.size.height
                   ? titleImageView.frame.size.height : titleLbl.frame.size.height);
  topPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:contentView fixedHeight:topViewHeight];
  [PEUIUtils placeView:titleImageView
            inMiddleOf:topPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              hpadding:leftPaddingForTitleImg];
  [PEUIUtils placeView:titleLbl
          toTheRightOf:titleImageView
                  onto:topPanel
         withAlignment:PEUIVerticalAlignmentTypeMiddle
              hpadding:paddingBetweenTitleImgAndLabel];
  UILabel *descriptionLbl = [PEUIUtils labelWithAttributeText:description
                                                         font:descriptionFont
                                              backgroundColor:[UIColor clearColor]
                                                    textColor:[UIColor blackColor]
                                          verticalTextPadding:0.0
                                                   fitToWidth:contentView.frame.size.width];
  UILabel *syncIconMessageLbl = [PEUIUtils labelWithAttributeText:syncIconMessage
                                                             font:descriptionFont
                                                  backgroundColor:[UIColor clearColor]
                                                        textColor:[UIColor blackColor]
                                              verticalTextPadding:0.0
                                                       fitToWidth:contentView.frame.size.width];
  UIImageView *syncMsgIconImageView = [[UIImageView alloc] initWithImage:syncImageIcon];
  CGFloat topPanelVpadding = 3.0;
  CGFloat contentViewHeight = topViewHeight + descriptionLbl.frame.size.height + syncIconMessageLbl.frame.size.height + syncMsgIconImageView.frame.size.height;
  CGFloat descriptionVpadding = 13.0;
  CGFloat syncIconMessageVpadding = 15.0;
  CGFloat syncMsgIconImageVpadding = 7.0;
  contentViewHeight += topPanelVpadding + descriptionVpadding + syncIconMessageVpadding + syncMsgIconImageVpadding;
  // now add a little bit more height so there's some nice bottom-padding; we'll have more
  // padding for when we have no messages panel-column.
  contentViewHeight += 5.0;
  [PEUIUtils setFrameHeight:contentViewHeight ofView:contentView];
  [PEUIUtils placeView:topPanel
               atTopOf:contentView
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:topPanelVpadding
              hpadding:0.0];
  [PEUIUtils placeView:descriptionLbl
                 below:topPanel
                  onto:contentView
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:descriptionVpadding
              hpadding:3.0];
  [PEUIUtils placeView:syncIconMessageLbl
                 below:descriptionLbl
                  onto:contentView
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:syncIconMessageVpadding
              hpadding:0.0];
  [PEUIUtils placeView:syncMsgIconImageView
                 below:syncIconMessageLbl
                  onto:contentView
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:syncMsgIconImageVpadding
              hpadding:7.0];
  return contentView;
}

#pragma mark - Private Alert Helpers

+ (UIView *)messagePanelWithTitle:(NSString *)title
                      leftImgIcon:(UIImage *)leftImgIcon
                            width:(CGFloat)width {
  UIView *errorPanel = [PEUIUtils panelWithFixedWidth:width fixedHeight:0.0];
  UIImageView *errImgView = [[UIImageView alloc] initWithImage:leftImgIcon];
  CGFloat paddingBetweenImgAndLabel = 5.0;
  UILabel *errorMsgLbl = [PEUIUtils labelWithKey:title
                                            font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                 backgroundColor:[UIColor clearColor]
                                       textColor:[UIColor blackColor]
                             verticalTextPadding:0.0
                                      fitToWidth:(width - (errImgView.frame.size.width + paddingBetweenImgAndLabel))];
  CGFloat frameHeight = errorMsgLbl.frame.size.height > errImgView.frame.size.height ?
    errorMsgLbl.frame.size.height : errImgView.frame.size.height;
  [PEUIUtils setFrameHeight:frameHeight ofView:errorPanel];
  [PEUIUtils placeView:errImgView
               atTopOf:errorPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:3.0
              hpadding:0.0];
  [PEUIUtils placeView:errorMsgLbl
               atTopOf:errorPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:0.0
              hpadding:errImgView.frame.size.width + paddingBetweenImgAndLabel];
  return errorPanel;
}

+ (NSArray *)alertPanelsForMessages:(NSArray *)messages
                              width:(CGFloat)width
                        leftImgIcon:(UIImage *)leftImgIcon {
  NSMutableArray *alertPanels = [NSMutableArray arrayWithCapacity:[messages count]];
  for (NSString *message in messages) {
    UIView *errorPanel = [PEUIUtils messagePanelWithTitle:message leftImgIcon:leftImgIcon width:width];
    [alertPanels addObject:errorPanel];
  }
  return alertPanels;
}

#pragma mark - Bundle Image Fetch

+ (UIImage *)bundleImageWithName:(NSString *)imageName {
  UIImage *image;
  if (PE_IS_IOS8_OR_GREATER) {
    NSBundle *mainBundle = [NSBundle bundleForClass:[PEUIUtils class]];
    NSBundle *resourcesBundle = [NSBundle bundleWithPath:[mainBundle pathForResource:@"PEObjc-Commons" ofType:@"bundle"]];
    if (resourcesBundle == nil) {
      resourcesBundle = mainBundle;
    }
    image = [UIImage imageNamed:imageName inBundle:resourcesBundle compatibleWithTraitCollection:nil];
  } else {
    image = [UIImage imageNamed:[NSString stringWithFormat:@"PEObjc-Commons.bundle/%@", imageName]];
  }
  return image;
}

#pragma mark - Alert Section Makers

+ (JGActionSheetSection *)alertSectionWithTitle:(NSString *)title
                                     titleImage:(UIImage *)titleImage
                               alertDescription:(NSAttributedString *)alertDescription
                                 relativeToView:(UIView *)relativeToView {
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:[PEUIUtils panelWithTitle:title
                                                               titleImage:titleImage
                                                              description:alertDescription
                                                           relativeToView:relativeToView]];
}

+ (JGActionSheetSection *)alertSectionWithMsgs:(NSArray *)msgs
                                         title:(NSString *)title
                                    titleImage:(UIImage *)titleImage
                              alertDescription:(NSAttributedString *)alertDescription
                                relativeToView:(UIView *)relativeToView {
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:[PEUIUtils panelWithMsgs:msgs
                                                                   title:title
                                                              titleImage:titleImage
                                                             description:alertDescription
                                                             messageIcon:[PEUIUtils bundleImageWithName:@"black-dot"]
                                                          relativeToView:relativeToView]];
}

+ (JGActionSheetSection *)warningAlertSectionWithMsgs:(NSArray *)msgs
                                                title:(NSString *)title
                                     alertDescription:(NSAttributedString *)alertDescription
                                       relativeToView:(UIView *)relativeToView {
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:[PEUIUtils panelWithMsgs:msgs
                                                                   title:title
                                                              titleImage:[PEUIUtils bundleImageWithName:@"warning"]
                                                             description:alertDescription
                                                             messageIcon:[PEUIUtils bundleImageWithName:@"black-dot"]
                                                          relativeToView:relativeToView]];
}

+ (JGActionSheetSection *)successAlertSectionWithTitle:(NSString *)title
                                      alertDescription:(NSAttributedString *)alertDescription
                                        relativeToView:(UIView *)relativeToView {
  return [PEUIUtils successAlertSectionWithMsgs:nil
                                          title:title
                               alertDescription:alertDescription
                                 relativeToView:relativeToView];
}

+ (JGActionSheetSection *)infoAlertSectionWithTitle:(NSString *)title
                                   alertDescription:(NSAttributedString *)alertDescription
                                     relativeToView:(UIView *)relativeToView {
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:[PEUIUtils panelWithTitle:title
                                                               titleImage:[PEUIUtils bundleImageWithName:@"info"]
                                                              description:alertDescription
                                                           relativeToView:relativeToView]];
}

+ (JGActionSheetSection *)infoAlertSectionWithTitle:(NSString *)title
                               alertDescriptionText:(NSString *)alertDescriptionText
                                    instructionText:(NSString *)instructionText
                                     relativeToView:(UIView *)relativeToView {
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:[PEUIUtils panelWithTitle:title
                                                               titleImage:[PEUIUtils bundleImageWithName:@"info"]
                                                          descriptionText:alertDescriptionText
                                                          instructionText:instructionText
                                                           relativeToView:relativeToView]];
}

+ (JGActionSheetSection *)successAlertSectionWithMsgs:(NSArray *)msgs
                                                title:(NSString *)title
                                     alertDescription:(NSAttributedString *)alertDescription
                                       relativeToView:(UIView *)relativeToView {
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:[PEUIUtils panelWithMsgs:msgs
                                                                   title:title
                                                              titleImage:[PEUIUtils bundleImageWithName:@"success"]
                                                             description:alertDescription
                                                             messageIcon:[PEUIUtils bundleImageWithName:@"success-icon"]
                                                          relativeToView:relativeToView]];
}

+ (JGActionSheetSection *)waitAlertSectionWithMsgs:(NSArray *)msgs
                                             title:(NSString *)title
                                  alertDescription:(NSAttributedString *)alertDescription
                                    relativeToView:(UIView *)relativeToView {
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:[PEUIUtils panelWithMsgs:msgs
                                                                   title:title
                                                              titleImage:[PEUIUtils bundleImageWithName:@"wait"]
                                                             description:alertDescription
                                                             messageIcon:[PEUIUtils bundleImageWithName:@"black-dot"]
                                                          relativeToView:relativeToView]];
}

+ (JGActionSheetSection *)errorAlertSectionWithMsgs:(NSArray *)msgs
                                              title:(NSString *)title
                                   alertDescription:(NSAttributedString *)alertDescription
                                     relativeToView:(UIView *)relativeToView {
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:[PEUIUtils panelWithMsgs:msgs
                                                                   title:title
                                                              titleImage:[PEUIUtils bundleImageWithName:@"error"]
                                                             description:alertDescription
                                                             messageIcon:[PEUIUtils bundleImageWithName:@"error-icon"]
                                                          relativeToView:relativeToView]];
}

+ (JGActionSheetSection *)dangerAlertSectionWithTitle:(NSString *)title
                                     alertDescription:(NSAttributedString *)alertDescription
                                       relativeToView:(UIView *)relativeToView {
  return [PEUIUtils alertSectionWithTitle:title
                               titleImage:[PEUIUtils bundleImageWithName:@"red-exclamation"]
                         alertDescription:alertDescription
                           relativeToView:relativeToView];
}

+ (JGActionSheetSection *)questionAlertSectionWithTitle:(NSString *)title
                                       alertDescription:(NSAttributedString *)alertDescription
                                         relativeToView:(UIView *)relativeToView {
  return [PEUIUtils alertSectionWithTitle:title
                               titleImage:[PEUIUtils bundleImageWithName:@"question"]
                         alertDescription:alertDescription
                           relativeToView:relativeToView];
}

+ (JGActionSheetSection *)multiErrorAlertSectionWithFailures:(NSArray *)failures
                                                       title:(NSString *)title
                                            alertDescription:(NSAttributedString *)alertDescription
                                              relativeToView:(UIView *)relativeToView {
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:[PEUIUtils failuresPanelWithFailures:failures
                                                                               title:title
                                                                         description:alertDescription
                                                                     descriptionFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                                                      relativeToView:relativeToView]];
}

+ (JGActionSheetSection *)mixedResultsAlertSectionWithSuccessMsgs:(NSArray *)successMsgs
                                                            title:(NSString *)title
                                                 alertDescription:(NSAttributedString *)alertDescription
                                              failuresDescription:(NSAttributedString *)failuresDescription
                                                         failures:(NSArray *)failures
                                                   relativeToView:(UIView *)relativeToView {
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:[PEUIUtils mixedResultsPanelWithSuccessMsgs:successMsgs
                                                                                      title:title
                                                                                description:alertDescription
                                                                        failuresDescription:failuresDescription
                                                                                   failures:failures
                                                                             relativeToView:relativeToView]];
}

+ (JGActionSheetSection *)conflictAlertSectionWithTitle:(NSString *)title
                                       alertDescription:(NSAttributedString *)alertDescription
                                         relativeToView:(UIView *)relativeToView {
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:[PEUIUtils panelWithTitle:title
                                                               titleImage:[PEUIUtils bundleImageWithName:@"conflict"]
                                                              description:alertDescription
                                                           relativeToView:relativeToView]];
}

+ (NSArray *)conflictResolveAlertSectionWithFields:(NSArray *)fields
                                    withCellHeight:(CGFloat)cellHeight
                                 labelLeftHPadding:(CGFloat)labelLeftHPadding
                                valueRightHPadding:(CGFloat)valueRightHPadding
                                         labelFont:(UIFont *)labelFont
                                         valueFont:(UIFont *)valueFont
                                    labelTextColor:(UIColor *)labelTextColor
                                    valueTextColor:(UIColor *)valueTextColor
                    minPaddingBetweenLabelAndValue:(CGFloat)minPaddingBetweenLabelAndValue
                                 includeTopDivider:(BOOL)includeTopDivider
                              includeBottomDivider:(BOOL)includeBottomDivider
                              includeInnerDividers:(BOOL)includeInnerDividers
                           innerDividerWidthFactor:(CGFloat)innerDividerWidthFactor
                                    dividerPadding:(CGFloat)dividerPadding
                           rowPanelBackgroundColor:(UIColor *)rowPanelPackgroundColor
                              panelBackgroundColor:(UIColor *)panelBackgroundColor
                                      dividerColor:(UIColor *)dividerColor
                                    relativeToView:(UIView *)relativeToView {
  NSArray *conflictResolvePanelArray = [PEUIUtils conflictResolvePanelWithFields:fields
                                                                  withCellHeight:cellHeight
                                                               labelLeftHPadding:labelLeftHPadding
                                                              valueRightHPadding:valueRightHPadding
                                                                       labelFont:labelFont
                                                                       valueFont:valueFont
                                                                  labelTextColor:labelTextColor
                                                                  valueTextColor:valueTextColor
                                                  minPaddingBetweenLabelAndValue:minPaddingBetweenLabelAndValue
                                                               includeTopDivider:includeTopDivider
                                                            includeBottomDivider:includeBottomDivider
                                                            includeInnerDividers:includeInnerDividers
                                                         innerDividerWidthFactor:innerDividerWidthFactor
                                                                  dividerPadding:dividerPadding
                                                         rowPanelBackgroundColor:rowPanelPackgroundColor
                                                            panelBackgroundColor:panelBackgroundColor
                                                                    dividerColor:dividerColor
                                                                  relativeToView:relativeToView];
  JGActionSheetSection *section = [JGActionSheetSection sectionWithTitle:nil
                                                                 message:nil
                                                             contentView:conflictResolvePanelArray[0]];
  return @[section, conflictResolvePanelArray[1]];
}

#pragma mark - Showing Alert Helpers

+ (void)showAlertWithButtonTitle:(NSString *)buttonTitle
                        topInset:(CGFloat)topInset
                    buttonAction:(void(^)(void))buttonAction
                  relativeToView:(UIView *)relativeToView
             contentSectionMaker:(PEAlertSectionMaker)contentSectionMaker
        additionalContentSection:(JGActionSheetSection *)additionalContentSection {
  JGActionSheetSection *contentSection = contentSectionMaker();
  JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                        message:nil
                                                                   buttonTitles:@[buttonTitle]
                                                                    buttonStyle:JGActionSheetButtonStyleDefault];
  NSMutableArray *sections = [NSMutableArray array];
  [sections addObject:contentSection];
  if (additionalContentSection) {
    [sections addObject:additionalContentSection];
  }
  [sections addObject:buttonsSection];
  JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:sections];
  [alertSheet setInsets:UIEdgeInsetsMake(topInset, 0.0f, 0.0f, 0.0f)];
  [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
    [sheet dismissAnimated:YES];
    if (buttonAction) {
      buttonAction();
    }
  }];
  [alertSheet showInView:relativeToView animated:YES];
}

+ (void)showAlertWithButtonTitle:(NSString *)buttonTitle
                        topInset:(CGFloat)topInset
                    buttonAction:(void(^)(void))buttonAction
                  relativeToView:(UIView *)relativeToView
             contentSectionMaker:(PEAlertSectionMaker)contentSectionMaker {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                       relativeToView:relativeToView
                  contentSectionMaker:contentSectionMaker
             additionalContentSection:nil];
}

+ (CGFloat)topInsetForAlertsWithController:(UIViewController *)controller {
  /*if (controller.navigationController.navigationBarHidden) {
    return 0.0;
  }
  return 70.0;*/
  return 0.0; // I can't remember why I'd ever want the '70.0' top inset
}

#pragma mark - Showing Alerts

+ (void)showAlertWithTitle:(NSString *)title
                titleImage:(UIImage *)titleImage
          alertDescription:(NSAttributedString *)alertDescription
                  topInset:(CGFloat)topInset
               buttonTitle:(NSString *)buttonTitle
              buttonAction:(void(^)(void))buttonAction
            relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils alertSectionWithTitle:title
                                                                      titleImage:titleImage
                                                                alertDescription:alertDescription
                                                                  relativeToView:relativeToView]; }];
}

+ (void)showConfirmAlertWithTitle:(NSString *)title
                       titleImage:(UIImage *)titleImage
                 alertDescription:(NSAttributedString *)alertDescription
                         topInset:(CGFloat)topInset
                  okayButtonTitle:(NSString *)okayButtonTitle
                 okayButtonAction:(void(^)(void))okayButtonAction
                  okayButtonStyle:(JGActionSheetButtonStyle)okayButtonStyle
                cancelButtonTitle:(NSString *)cancelButtonTitle
               cancelButtonAction:(void(^)(void))cancelButtonAction
                 cancelButtonSyle:(JGActionSheetButtonStyle)cancelButtonStyle
                   relativeToView:(UIView *)relativeToView {
  JGActionSheetSection *contentSection = [PEUIUtils alertSectionWithTitle:title
                                                               titleImage:titleImage
                                                         alertDescription:alertDescription
                                                           relativeToView:relativeToView];
  JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                        message:nil
                                                                   buttonTitles:@[okayButtonTitle, cancelButtonTitle]
                                                                    buttonStyle:JGActionSheetButtonStyleDefault];
  JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:@[contentSection, buttonsSection]];
  [buttonsSection setButtonStyle:okayButtonStyle forButtonAtIndex:0];
  [buttonsSection setButtonStyle:cancelButtonStyle forButtonAtIndex:1];
  [alertSheet setInsets:UIEdgeInsetsMake(topInset, 0.0f, 0.0f, 0.0f)];
  [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
    switch (indexPath.row) {
      case 0:  // okay
        okayButtonAction();
        break;
      case 1:  // cancel
        cancelButtonAction();
        break;
    }
    [sheet dismissAnimated:YES];
  }];
  [alertSheet showInView:relativeToView animated:YES];
}

+ (void)showConfirmAlertWithMsgs:(NSArray *)msgs
                           title:(NSString *)title
                      titleImage:(UIImage *)titleImage
                alertDescription:(NSAttributedString *)alertDescription
                        topInset:(CGFloat)topInset
                 okaybuttonTitle:(NSString *)okayButtonTitle
                okaybuttonAction:(void(^)(void))okayButtonAction
                 okayButtonStyle:(JGActionSheetButtonStyle)okayButtonStyle
               cancelbuttonTitle:(NSString *)cancelButtonTitle
              cancelbuttonAction:(void(^)(void))cancelButtonAction
                cancelButtonSyle:(JGActionSheetButtonStyle)cancelButtonStyle
                  relativeToView:(UIView *)relativeToView {
  JGActionSheetSection *contentSection = [PEUIUtils alertSectionWithMsgs:msgs
                                                                   title:title
                                                              titleImage:titleImage
                                                        alertDescription:alertDescription
                                                          relativeToView:relativeToView];
  JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                        message:nil
                                                                   buttonTitles:@[okayButtonTitle, cancelButtonTitle]
                                                                    buttonStyle:JGActionSheetButtonStyleDefault];
  JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:@[contentSection, buttonsSection]];
  [buttonsSection setButtonStyle:okayButtonStyle forButtonAtIndex:0];
  [buttonsSection setButtonStyle:cancelButtonStyle forButtonAtIndex:1];
  [alertSheet setInsets:UIEdgeInsetsMake(topInset, 0.0f, 0.0f, 0.0f)];
  [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
    switch (indexPath.row) {
      case 0:  // okay
        okayButtonAction();
        break;
      case 1:  // cancel
        cancelButtonAction();
        break;
    }
    [sheet dismissAnimated:YES];
  }];
  [alertSheet showInView:relativeToView animated:YES];
}

+ (void)showWarningConfirmAlertWithTitle:(NSString *)title
                        alertDescription:(NSAttributedString *)alertDescription
                                topInset:(CGFloat)topInset
                         okayButtonTitle:(NSString *)okayButtonTitle
                        okayButtonAction:(void(^)(void))okayButtonAction
                       cancelButtonTitle:(NSString *)cancelButtonTitle
                      cancelButtonAction:(void(^)(void))cancelButtonAction
                          relativeToView:(UIView *)relativeToView {
  [self showConfirmAlertWithTitle:title
                       titleImage:[PEUIUtils bundleImageWithName:@"warning"]
                 alertDescription:alertDescription
                         topInset:topInset
                  okayButtonTitle:okayButtonTitle
                 okayButtonAction:okayButtonAction
                  okayButtonStyle:JGActionSheetButtonStyleRed
                cancelButtonTitle:cancelButtonTitle
               cancelButtonAction:cancelButtonAction
                 cancelButtonSyle:JGActionSheetButtonStyleDefault
                   relativeToView:relativeToView];
}

+ (void)showWarningConfirmAlertWithMsgs:(NSArray *)msgs
                                  title:(NSString *)title
                       alertDescription:(NSAttributedString *)alertDescription
                               topInset:(CGFloat)topInset
                        okayButtonTitle:(NSString *)okayButtonTitle
                       okayButtonAction:(void(^)(void))okayButtonAction
                      cancelButtonTitle:(NSString *)cancelButtonTitle
                     cancelButtonAction:(void(^)(void))cancelButtonAction
                         relativeToView:(UIView *)relativeToView {
  [self showConfirmAlertWithMsgs:msgs
                           title:title
                      titleImage:[PEUIUtils bundleImageWithName:@"warning"]
                alertDescription:alertDescription
                        topInset:topInset
                 okaybuttonTitle:okayButtonTitle
                okaybuttonAction:okayButtonAction
                 okayButtonStyle:JGActionSheetButtonStyleRed
               cancelbuttonTitle:cancelButtonTitle
              cancelbuttonAction:cancelButtonAction
                cancelButtonSyle:JGActionSheetButtonStyleDefault
                  relativeToView:relativeToView];
}

+ (void)showEditConflictAlertWithTitle:(NSString *)title
                      alertDescription:(NSAttributedString *)alertDescription
                              topInset:(CGFloat)topInset
                      mergeButtonTitle:(NSString *)mergeButtonTitle
                     mergeButtonAction:(void(^)(UIView *))mergeButtonAction
                    replaceButtonTitle:(NSString *)replaceButtonTitle
                   replaceButtonAction:(void(^)(void))replaceButtonAction
             forceSaveLocalButtonTitle:(NSString *)forceSaveButtonTitle
                 forceSaveButtonAction:(void(^)(void))forceSaveButtonAction
                     cancelButtonTitle:(NSString *)cancelButtonTitle
                    cancelButtonAction:(void(^)(void))cancelButtonAction
                        relativeToView:(UIView *)relativeToView {
  JGActionSheetSection *contentSection = [PEUIUtils alertSectionWithTitle:title
                                                               titleImage:[PEUIUtils bundleImageWithName:@"conflict"]
                                                         alertDescription:alertDescription
                                                           relativeToView:relativeToView];
  JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                        message:nil
                                                                   buttonTitles:@[mergeButtonTitle, replaceButtonTitle, forceSaveButtonTitle, cancelButtonTitle]
                                                                    buttonStyle:JGActionSheetButtonStyleDefault];
  JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:@[contentSection, buttonsSection]];
  [buttonsSection setButtonStyle:JGActionSheetButtonStyleBlue forButtonAtIndex:0];
  [buttonsSection setButtonStyle:JGActionSheetButtonStyleDefault forButtonAtIndex:1];
  [buttonsSection setButtonStyle:JGActionSheetButtonStyleDefault forButtonAtIndex:2];
  [buttonsSection setButtonStyle:JGActionSheetButtonStyleDefault forButtonAtIndex:3];
  [alertSheet setInsets:UIEdgeInsetsMake(topInset, 0.0f, 0.0f, 0.0f)];
  __weak JGActionSheetSection *weakContentSection = contentSection;
  [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
    switch (indexPath.row) {
      case 0:  // merge
        mergeButtonAction(weakContentSection);
        break;
      case 1:  // replace local copy with remote copy
        replaceButtonAction();
        break;
      case 2: // force save using local copy
        forceSaveButtonAction();
        break;
      case 3: // cancel
        cancelButtonAction();
        break;
    }
    [sheet dismissAnimated:YES];
  }];
  [alertSheet showInView:relativeToView animated:YES];
}

+ (void)showDeleteConflictAlertWithTitle:(NSString *)title
                        alertDescription:(NSAttributedString *)alertDescription
                                topInset:(CGFloat)topInset
             forceDeleteLocalButtonTitle:(NSString *)forceDeleteButtonTitle
                 forceDeleteButtonAction:(void(^)(void))forceDeleteButtonAction
                       cancelButtonTitle:(NSString *)cancelButtonTitle
                      cancelButtonAction:(void(^)(void))cancelButtonAction
                          relativeToView:(UIView *)relativeToView {
  JGActionSheetSection *contentSection = [PEUIUtils alertSectionWithTitle:title
                                                               titleImage:[PEUIUtils bundleImageWithName:@"conflict"]
                                                         alertDescription:alertDescription
                                                           relativeToView:relativeToView];
  JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                        message:nil
                                                                   buttonTitles:@[forceDeleteButtonTitle, cancelButtonTitle]
                                                                    buttonStyle:JGActionSheetButtonStyleDefault];
  JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:@[contentSection, buttonsSection]];
  [buttonsSection setButtonStyle:JGActionSheetButtonStyleRed forButtonAtIndex:0];
  [buttonsSection setButtonStyle:JGActionSheetButtonStyleDefault forButtonAtIndex:1];
  [alertSheet setInsets:UIEdgeInsetsMake(topInset, 0.0f, 0.0f, 0.0f)];
  [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
    switch (indexPath.row) {
      case 0:  // force delete
        forceDeleteButtonAction();
        break;
      case 1: // cancel
        cancelButtonAction();
        break;
    }
    [sheet dismissAnimated:YES];
  }];
  [alertSheet showInView:relativeToView animated:YES];
}

+ (void)showConflictResolverWithTitle:(NSString *)title
                     alertDescription:(NSAttributedString *)alertDescription
                conflictResolveFields:(NSArray *)conflictResolveFields
                       withCellHeight:(CGFloat)cellHeight
                    labelLeftHPadding:(CGFloat)labelLeftHPadding
                   valueRightHPadding:(CGFloat)valueRightHPadding
                            labelFont:(UIFont *)labelFont
                            valueFont:(UIFont *)valueFont
                       labelTextColor:(UIColor *)labelTextColor
                       valueTextColor:(UIColor *)valueTextColor
       minPaddingBetweenLabelAndValue:(CGFloat)minPaddingBetweenLabelAndValue
                    includeTopDivider:(BOOL)includeTopDivider
                 includeBottomDivider:(BOOL)includeBottomDivider
                 includeInnerDividers:(BOOL)includeInnerDividers
              innerDividerWidthFactor:(CGFloat)innerDividerWidthFactor
                       dividerPadding:(CGFloat)dividerPadding
              rowPanelBackgroundColor:(UIColor *)rowPanelPackgroundColor
                 panelBackgroundColor:(UIColor *)panelBackgroundColor
                         dividerColor:(UIColor *)dividerColor
                             topInset:(CGFloat)topInset
                      okayButtonTitle:(NSString *)okayButtonTitle
                     okayButtonAction:(void(^)(NSArray *))okayButtonAction
                    cancelButtonTitle:(NSString *)cancelButtonTitle
                   cancelButtonAction:(void(^)(void))cancelButtonAction
              relativeToViewForLayout:(UIView *)relativeToViewForLayout
                 relativeToViewForPop:(UIView *)relativeToViewForPop {
  JGActionSheetSection *descriptionSection = [PEUIUtils alertSectionWithTitle:title
                                                                   titleImage:[PEUIUtils bundleImageWithName:@"conflict-resolve"]
                                                             alertDescription:alertDescription
                                                               relativeToView:relativeToViewForPop];
  NSArray *conflictResolveSectionArray = [PEUIUtils conflictResolveAlertSectionWithFields:conflictResolveFields
                                                                           withCellHeight:cellHeight
                                                                        labelLeftHPadding:labelLeftHPadding
                                                                       valueRightHPadding:valueRightHPadding
                                                                                labelFont:labelFont
                                                                                valueFont:valueFont
                                                                           labelTextColor:labelTextColor
                                                                           valueTextColor:valueTextColor
                                                           minPaddingBetweenLabelAndValue:minPaddingBetweenLabelAndValue
                                                                        includeTopDivider:includeTopDivider
                                                                     includeBottomDivider:includeBottomDivider
                                                                     includeInnerDividers:includeInnerDividers
                                                                  innerDividerWidthFactor:innerDividerWidthFactor
                                                                           dividerPadding:dividerPadding
                                                                  rowPanelBackgroundColor:rowPanelPackgroundColor
                                                                     panelBackgroundColor:panelBackgroundColor
                                                                             dividerColor:dividerColor
                                                                           relativeToView:relativeToViewForLayout];
  JGActionSheetSection *conflictResolveSection = conflictResolveSectionArray[0];
  JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                        message:nil
                                                                   buttonTitles:@[okayButtonTitle, cancelButtonTitle]
                                                                    buttonStyle:JGActionSheetButtonStyleDefault];
  JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:@[descriptionSection, conflictResolveSection, buttonsSection]];
  [buttonsSection setButtonStyle:JGActionSheetButtonStyleBlue forButtonAtIndex:0];
  [buttonsSection setButtonStyle:JGActionSheetButtonStyleDefault forButtonAtIndex:1];
  [alertSheet setInsets:UIEdgeInsetsMake(topInset, 0.0f, 0.0f, 0.0f)];
  [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
    switch (indexPath.row) {
      case 0:  // okay
        okayButtonAction(conflictResolveSectionArray[1]);
        break;
      case 1: // cancel
        cancelButtonAction();
        break;
    }
    [sheet dismissAnimated:YES];
  }];
  [alertSheet showInView:relativeToViewForPop animated:YES];
}

+ (void)showWarningAlertWithMsgs:(NSArray *)msgs
                           title:(NSString *)title
                alertDescription:(NSAttributedString *)alertDescription
                        topInset:(CGFloat)topInset
                     buttonTitle:(NSString *)buttonTitle
                    buttonAction:(void(^)(void))buttonAction
                  relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils warningAlertSectionWithMsgs:msgs
                                                                                 title:title
                                                                      alertDescription:alertDescription
                                                                        relativeToView:relativeToView]; }];
}

+ (void)showSuccessAlertWithTitle:(NSString *)title
                 alertDescription:(NSAttributedString *)alertDescription
                         topInset:(CGFloat)topInset
                      buttonTitle:(NSString *)buttonTitle
                     buttonAction:(void(^)(void))buttonAction
                   relativeToView:(UIView *)relativeToView {
  [PEUIUtils showSuccessAlertWithTitle:title
                      alertDescription:alertDescription
              additionalContentSection:nil
                              topInset:topInset
                           buttonTitle:buttonTitle
                          buttonAction:buttonAction
                        relativeToView:relativeToView];
}

+ (void)showSuccessAlertWithTitle:(NSString *)title
                 alertDescription:(NSAttributedString *)alertDescription
         additionalContentSection:(JGActionSheetSection *)additionalContentSection
                         topInset:(CGFloat)topInset
                      buttonTitle:(NSString *)buttonTitle
                     buttonAction:(void(^)(void))buttonAction
                   relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils successAlertSectionWithTitle:title
                                                                       alertDescription:alertDescription
                                                                         relativeToView:relativeToView]; }
             additionalContentSection:additionalContentSection];
}

+ (void)showSuccessAlertWithMsgs:(NSArray *)msgs
                           title:(NSString *)title
                alertDescription:(NSAttributedString *)alertDescription
                        topInset:(CGFloat)topInset
                     buttonTitle:(NSString *)buttonTitle
                    buttonAction:(void(^)(void))buttonAction
                  relativeToView:(UIView *)relativeToView {
  [PEUIUtils showSuccessAlertWithMsgs:msgs
                                title:title
                     alertDescription:alertDescription
             additionalContentSection:nil
                             topInset:topInset
                          buttonTitle:buttonTitle
                         buttonAction:buttonAction
                       relativeToView:relativeToView];
}

+ (void)showSuccessAlertWithMsgs:(NSArray *)msgs
                           title:(NSString *)title
                alertDescription:(NSAttributedString *)alertDescription
        additionalContentSection:(JGActionSheetSection *)additionalContentSection
                        topInset:(CGFloat)topInset
                     buttonTitle:(NSString *)buttonTitle
                    buttonAction:(void(^)(void))buttonAction
                  relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils successAlertSectionWithMsgs:msgs
                                                                                 title:title
                                                                      alertDescription:alertDescription
                                                                        relativeToView:relativeToView]; }
             additionalContentSection:additionalContentSection];
}

+ (void)showInfoAlertWithTitle:(NSString *)title
              alertDescription:(NSAttributedString *)alertDescription
                      topInset:(CGFloat)topInset
                   buttonTitle:(NSString *)buttonTitle
                  buttonAction:(void(^)(void))buttonAction
                relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils infoAlertSectionWithTitle:title
                                                                    alertDescription:alertDescription
                                                                      relativeToView:relativeToView]; }];
}

+ (void)showInstructionalAlertWithTitle:(NSString *)title
                   alertDescriptionText:(NSString *)alertDescriptionText
                        instructionText:(NSString *)instructionText
                               topInset:(CGFloat)topInset
                            buttonTitle:(NSString *)buttonTitle
                           buttonAction:(void(^)(void))buttonAction
                         relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils infoAlertSectionWithTitle:title
                                                                alertDescriptionText:alertDescriptionText
                                                                     instructionText:instructionText
                                                                      relativeToView:relativeToView]; }];
}

+ (void)showWaitAlertWithMsgs:(NSArray *)msgs
                        title:(NSString *)title
             alertDescription:(NSAttributedString *)alertDescription
                     topInset:(CGFloat)topInset
                  buttonTitle:(NSString *)buttonTitle
                 buttonAction:(void(^)(void))buttonAction
               relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils waitAlertSectionWithMsgs:msgs
                                                                              title:title
                                                                   alertDescription:alertDescription
                                                                     relativeToView:relativeToView]; }];
}

+ (void)showErrorAlertWithMsgs:(NSArray *)msgs
                         title:(NSString *)title
              alertDescription:(NSAttributedString *)alertDescription
                      topInset:(CGFloat)topInset
                   buttonTitle:(NSString *)buttonTitle
                  buttonAction:(void(^)(void))buttonAction
                relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils errorAlertSectionWithMsgs:msgs
                                                                               title:title
                                                                    alertDescription:alertDescription
                                                                      relativeToView:relativeToView]; }];
}

+ (void)showMultiErrorAlertWithFailures:(NSArray *)failures
                                  title:(NSString *)title
                       alertDescription:(NSAttributedString *)alertDescription
                               topInset:(CGFloat)topInset
                            buttonTitle:(NSString *)buttonTitle
                           buttonAction:(void(^)(void))buttonAction
                         relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils multiErrorAlertSectionWithFailures:failures
                                                                                        title:title
                                                                             alertDescription:alertDescription
                                                                               relativeToView:relativeToView]; }];
}

+ (void)showMixedResultsAlertSectionWithSuccessMsgs:(NSArray *)successMsgs
                                              title:(NSString *)title
                                   alertDescription:(NSAttributedString *)alertDescription
                                failuresDescription:(NSAttributedString *)failuresDescription
                                           failures:(NSArray *)failures
                                           topInset:(CGFloat)topInset
                                        buttonTitle:(NSString *)buttonTitle
                                       buttonAction:(void(^)(void))buttonAction
                                     relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils mixedResultsAlertSectionWithSuccessMsgs:successMsgs
                                                                                             title:title
                                                                                  alertDescription:alertDescription
                                                                               failuresDescription:failuresDescription
                                                                                          failures:failures
                                                                                    relativeToView:relativeToView]; }];
}

+ (void)showAlertForNSURLErrorCode:(NSInteger)errorCode
                             title:(NSString *)title
                          topInset:(CGFloat)topInset
                       buttonTitle:(NSString *)buttonTitle
                      buttonAction:(void(^)(void))buttonAction
                    relativeToView:(UIView *)relativeToView {
  NSMutableArray *errMsgs = [NSMutableArray arrayWithCapacity:1];
  switch (errorCode) {
  case NSURLErrorTimedOut:
    [errMsgs addObject:LS(@"nsurlerr.timeout")];
    break;
  case NSURLErrorCannotConnectToHost:
    [errMsgs addObject:LS(@"nsurlerr.serverdown")];
    break;
  case NSURLErrorNetworkConnectionLost:
    [errMsgs addObject:LS(@"nsurlerr.inetconnlost")];
    break;
  case NSURLErrorDNSLookupFailed:
    [errMsgs addObject:LS(@"nsurlerr.dnslkupfailed")];
    break;
  case NSURLErrorNotConnectedToInternet:
    [errMsgs addObject:LS(@"nsurlerr.noinetconn")];
    break;
  default:
    [errMsgs addObject:LS(@"nsurlerr.unknownerr")];
    break;
  }
  [PEUIUtils showWarningAlertWithMsgs:errMsgs
                                title:title
                     alertDescription:[[NSAttributedString alloc] initWithString:@"There was a problem communicating with\n\
the server.  The error is as follows:"]
                             topInset:topInset
                          buttonTitle:buttonTitle
                         buttonAction:buttonAction
                       relativeToView:relativeToView];
}

@end
