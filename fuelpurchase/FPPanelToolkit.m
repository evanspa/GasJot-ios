//
//  FPPanelToolkit.m
//  fuelpurchase
//
//  Created by Evans, Paul on 10/1/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPPanelToolkit.h"
#import <PEObjc-Commons/PEUIUtils.h>
#import <PEObjc-Commons/PEUtils.h>
#import "FPFuelStationCoordinatesTableDataSource.h"
#import "FPFpLogVehicleFuelStationDateDataSourceAndDelegate.h"
#import "FPEnvLogVehicleAndDateDataSourceDelegate.h"
#import <BlocksKit/UIControl+BlocksKit.h>
#import "FPLogEnvLogComposite.h"
#import <FlatUIKit/UIColor+FlatUI.h>
#import "FPNames.h"
#import "FPUtils.h"
#import "FPUIUtils.h"
#import "FPForgotPasswordController.h"
#import <PEFuelPurchase-Model/FPStats.h>
#import <PELocal-Data/PEUserCoordinatorDao.h>
#import <PEFuelPurchase-Model/FPLocalDao.h>
#import <PELocal-Data/PELocalDao.h>
#import <PEFuelPurchase-Model/FPVehicle.h>
#import <PEFuelPurchase-Model/FPFuelStation.h>
#import <PEFuelPurchase-Model/FPFuelStationType.h>
#import <PEFuelPurchase-Model/FPFuelPurchaseLog.h>
#import <PEFuelPurchase-Model/FPEnvironmentLog.h>
#import "FPFuelstationTypeDsDelegate.h"

NSString * const FPFpLogEntityMakerFpLogEntry = @"FPFpLogEntityMakerFpLogEntry";
NSString * const FPFpLogEntityMakerVehicleEntry = @"FPFpLogEntityMakerVehicleEntry";
NSString * const FPFpLogEntityMakerFuelStationEntry = @"FPFpLogEntityMakerFuelStationEntry";

NSString * const FPPanelToolkitNaText = @"---";

NSString * const FPPanelToolkitVehicleDefaultOctanePlaceholerText = @"Default octane";
NSString * const FPPanelToolkitVehicleDefaultOctaneNaPlaceholerText = @"Default octane (NOT APPLICABLE)";

@implementation FPPanelToolkit {
  id<FPCoordinatorDao> _coordDao;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  NSMutableArray *_tableViewDataSources;
  PELMDaoErrorBlk _errorBlk;
  FPStats *_stats;
}

#pragma mark - Initializers

- (id)initWithCoordinatorDao:(id<FPCoordinatorDao>)coordDao
               screenToolkit:(FPScreenToolkit *)screenToolkit
                   uitoolkit:(PEUIToolkit *)uitoolkit
                       error:(PELMDaoErrorBlk)errorBlk {
  self = [super init];
  if (self) {
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
    _tableViewDataSources = [NSMutableArray array];
    _errorBlk = errorBlk;
    _stats = [[FPStats alloc] initWithLocalDao:_coordDao errorBlk:errorBlk];
  }
  return self;
}

#pragma mark - Helpers

- (UIView *)tablePanelWithRowData:(NSArray *)rowData
                        uitoolkit:(PEUIToolkit *)uitoolkit
                       parentView:(UIView *)parentView {
return [PEUIUtils tablePanelWithRowData:rowData
                         withCellHeight:([PEUIUtils sizeOfText:@"" withFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleBody]].height + uitoolkit.verticalPaddingForButtons + 1.5)
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
                   footerAttributedText:nil
         footerFontForHeightCalculation:nil
                  footerVerticalPadding:0.0
                               rowWidth:parentView.frame.size.width
                               maxWidth:parentView.frame.size.width
                         relativeToView:parentView];
}

#pragma mark - User Account Panel

- (PEEntityViewPanelMakerBlk)userAccountViewPanelMakerWithAccountStatusLabelTag:(NSInteger)accountStatusLabelTag {
  return ^ UIView * (PEAddViewEditController *parentViewController, id nilParent, FPUser *user) {
    UIView *parentView = [parentViewController view];
    UIView *userAccountPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:parentView];
    UIView *userAccountDataPanel = [self tablePanelWithRowData:@[@[@"Name", [PEUtils emptyIfNil:[user name]]],
                                                                 @[@"Email", [PEUtils emptyIfNil:[user email]]],
                                                                 @[@"Password", @"*****************"]]
                                                     uitoolkit:_uitoolkit
                                                    parentView:parentView];
    UIView *accountStatusPanel = [FPPanelToolkit accountStatusPanelForUser:user
                                                                  panelTag:@(accountStatusLabelTag)
                                                      includeRefreshButton:NO
                                                            coordinatorDao:_coordDao
                                                                 uitoolkit:_uitoolkit
                                                            relativeToView:parentView
                                                                controller:parentViewController];
    [PEUIUtils placeView:userAccountDataPanel
                 atTopOf:userAccountPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:25
                hpadding:0];
    [PEUIUtils placeView:accountStatusPanel
                   below:userAccountDataPanel
                    onto:userAccountPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:15.0
                hpadding:0.0];
    return userAccountPanel;
  };
}

- (PEEntityPanelMakerBlk)userAccountFormPanelMaker {
  return ^ UIView * (PEAddViewEditController *parentViewController) {
    UIView *parentView = [parentViewController view];
    UIView *userAccountPanel = [PEUIUtils panelWithWidthOf:1.0
                                               andHeightOf:1.0
                                            relativeToView:parentView];
    TaggedTextfieldMaker tfMaker = [_uitoolkit taggedTextfieldMakerForWidthOf:1.0 relativeTo:userAccountPanel];
    UITextField *nameTf = tfMaker(@"Name", FPUserTagName);
    UITextField *emailTf = tfMaker(@"E-mail", FPUserTagEmail);
    UITextField *passwordTf = tfMaker(@"Password", FPUserTagPassword);
    [passwordTf setSecureTextEntry:YES];
    UITextField *confirmPasswordTf = tfMaker(@"Confirm password", FPUserTagConfirmPassword);
    [confirmPasswordTf setSecureTextEntry:YES];
    UILabel *passwordMsg = [PEUIUtils labelWithKey:@"If you don't want to change your password, leave the password field blank."
                                              font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                   backgroundColor:[UIColor clearColor]
                                         textColor:[UIColor darkGrayColor]
                               verticalTextPadding:3.0
                                        fitToWidth:parentView.frame.size.width - 23.0];
    [PEUIUtils placeView:nameTf
                 atTopOf:userAccountPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:15
                hpadding:0];
    [PEUIUtils placeView:emailTf
                   below:nameTf
                    onto:userAccountPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:passwordTf
                   below:emailTf
                    onto:userAccountPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:confirmPasswordTf
                   below:passwordTf
                    onto:userAccountPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:passwordMsg
                   below:confirmPasswordTf
                    onto:userAccountPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:4.0
                hpadding:8.0];
    return userAccountPanel;
  };
}

- (PEPanelToEntityBinderBlk)userFormPanelToUserBinder {
  return ^ void (UIView *panel, FPUser *userAccount) {
    [PEUIUtils bindToEntity:userAccount
           withStringSetter:@selector(setName:)
       fromTextfieldWithTag:FPUserTagName
                   fromView:panel];
    [PEUIUtils bindToEntity:userAccount
           withStringSetter:@selector(setEmail:)
       fromTextfieldWithTag:FPUserTagEmail
                   fromView:panel];
    [PEUIUtils bindToEntity:userAccount
           withStringSetter:@selector(setPassword:)
       fromTextfieldWithTag:FPUserTagPassword
                   fromView:panel];
    [PEUIUtils bindToEntity:userAccount
           withStringSetter:@selector(setConfirmPassword:)
       fromTextfieldWithTag:FPUserTagConfirmPassword
                   fromView:panel];
  };
}

- (PEEntityToPanelBinderBlk)userToUserPanelBinder {
  return ^ void (FPUser *userAccount, UIView *panel) {
    [PEUIUtils bindToTextControlWithTag:FPUserTagName
                               fromView:panel
                             fromEntity:userAccount
                             withGetter:@selector(name)];
    [PEUIUtils bindToTextControlWithTag:FPUserTagEmail
                               fromView:panel
                             fromEntity:userAccount
                             withGetter:@selector(email)];
    [PEUIUtils bindToTextControlWithTag:FPUserTagPassword
                               fromView:panel
                             fromEntity:userAccount
                             withGetter:@selector(password)];
    [PEUIUtils bindToTextControlWithTag:FPUserTagConfirmPassword
                               fromView:panel
                             fromEntity:userAccount
                             withGetter:@selector(confirmPassword)];
  };
}

- (PEEnableDisablePanelBlk)userFormPanelEnablerDisabler {
  return ^ (UIView *panel, BOOL enable) {
    [PEUIUtils enableControlWithTag:FPUserTagName
                           fromView:panel
                             enable:enable];
    [PEUIUtils enableControlWithTag:FPUserTagEmail
                           fromView:panel
                             enable:enable];
    [PEUIUtils enableControlWithTag:FPUserTagPassword
                           fromView:panel
                             enable:enable];
    [PEUIUtils enableControlWithTag:FPUserTagConfirmPassword
                           fromView:panel
                             enable:enable];
  };
}

+ (NSArray *)accountStatusTextForUser:(FPUser *)user {
  if (![PEUtils isNil:[user verifiedAt]]) {
    return @[@"verified", [UIColor greenSeaColor]];
  } else {
    return @[@"not verified", [UIColor sunflowerColor]];
  }
}

+ (UIView *)accountStatusPanelForUser:(FPUser *)user
                             panelTag:(NSNumber *)panelTag
                 includeRefreshButton:(BOOL)includeRefreshButton
                       coordinatorDao:(id<FPCoordinatorDao>)coordDao
                            uitoolkit:(PEUIToolkit *)uitoolkit
                       relativeToView:(UIView *)relativeToView
                           controller:(UIViewController *)controller {
  FPEnableUserInteractionBlk enableUserInteraction = [FPUIUtils makeUserEnabledBlockForController:controller];
  NSArray *accountStatusText = [FPPanelToolkit accountStatusTextForUser:user];
  UIView *statusPanel = [PEUIUtils labelValuePanelWithCellHeight:([PEUIUtils sizeOfText:@"" withFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleTitle3]].height + uitoolkit.verticalPaddingForButtons)
                                                     labelString:@"Account status"
                                                  labelTextStyle:UIFontTextStyleTitle3
                                                  labelTextColor:[UIColor blackColor]
                                               labelLeftHPadding:10.0
                                                     valueString:accountStatusText[0]
                                                  valueTextStyle:UIFontTextStyleTitle3
                                                  valueTextColor:accountStatusText[1]
                                              valueRightHPadding:15.0
                                                   valueLabelTag:nil
                                  minPaddingBetweenLabelAndValue:10.0
                                                        rowWidth:(1.0 * relativeToView.frame.size.width)
                                                  relativeToView:relativeToView];
  [statusPanel setBackgroundColor:[UIColor whiteColor]];
  CGFloat heightOfPanel = statusPanel.frame.size.height;
  UIView *panel;
  if ([PEUtils isNil:[user verifiedAt]]) {
    UIButton * (^makeSendEmailBtn)(void) = ^ UIButton * {
      UIButton *sendEmailBtn = [PEUIUtils buttonWithKey:@"re-send verification email"
                                                   font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                        backgroundColor:[UIColor concreteColor]
                                              textColor:[UIColor whiteColor]
                           disabledStateBackgroundColor:nil
                                 disabledStateTextColor:nil
                                        verticalPadding:14.0
                                      horizontalPadding:20.0
                                           cornerRadius:5.0
                                                 target:nil
                                                 action:nil];
      [sendEmailBtn bk_addEventHandler:^(id sender) {
        MBProgressHUD *sendVerificationEmailHud = [MBProgressHUD showHUDAddedTo:relativeToView animated:YES];
        enableUserInteraction(NO);
        sendVerificationEmailHud.labelText = @"Sending verification email...";
        [coordDao.userCoordinatorDao resendVerificationEmailForUser:user
                                                 remoteStoreBusyBlk:^(NSDate *retryAfter) {
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                     [sendVerificationEmailHud hide:YES afterDelay:0.0];
                                                     [PEUIUtils showWaitAlertWithMsgs:nil
                                                                                title:@"Busy with maintenance."
                                                                     alertDescription:[[NSAttributedString alloc] initWithString:@"\
                                                                                       The server is currently busy at the moment undergoing maintenance.\n\n\
                                                                                       We apologize for the inconvenience.  Please try re-sending the verification email later."]
                                                                             topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                                                          buttonTitle:@"Okay."
                                                                         buttonAction:^{ enableUserInteraction(YES); }
                                                                       relativeToView:controller.tabBarController.view];
                                                   });
                                                 }
                                                         successBlk:^{
                                                           dispatch_async(dispatch_get_main_queue(), ^{
                                                             [sendVerificationEmailHud hide:YES afterDelay:0.0];
                                                             NSAttributedString *attrMessage =
                                                             [PEUIUtils attributedTextWithTemplate:@"The verification email was sent to at: %@."
                                                                                      textToAccent:[user email]
                                                                                    accentTextFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
                                                             [PEUIUtils showSuccessAlertWithTitle:@"Verification e-mail sent."
                                                                                 alertDescription:attrMessage
                                                                                         topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                                                                      buttonTitle:@"Okay."
                                                                                     buttonAction:^{ enableUserInteraction(YES); }
                                                                                   relativeToView:controller.tabBarController.view];
                                                           });
                                                         }
                                                           errorBlk:^{
                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                               [sendVerificationEmailHud hide:YES afterDelay:0.0];
                                                               [PEUIUtils showErrorAlertWithMsgs:nil
                                                                                           title:@"Something went wrong."
                                                                                alertDescription:[[NSAttributedString alloc] initWithString:@"\
                                                                                                  Oops.  Something went wrong in attempting to send you a verification email.  Please try this again a little later."]
                                                                                        topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                                                                     buttonTitle:@"Okay."
                                                                                    buttonAction:^{ enableUserInteraction(YES); }
                                                                                  relativeToView:controller.tabBarController.view];
                                                             });
                                                           }];
      } forControlEvents:UIControlEventTouchUpInside];
      return sendEmailBtn;
    };
    panel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:relativeToView fixedHeight:80];
    [panel setBackgroundColor:[UIColor clearColor]];
    UIView *buttonsView = [PEUIUtils panelWithWidthOf:1.0 relativeToView:relativeToView fixedHeight:30];
    [buttonsView setBackgroundColor:[UIColor clearColor]];
    if (includeRefreshButton) {
      UIButton *refreshBtn = [PEUIUtils buttonWithKey:@"refresh"
                                                 font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                      backgroundColor:[UIColor concreteColor]
                                            textColor:[UIColor whiteColor]
                         disabledStateBackgroundColor:nil
                               disabledStateTextColor:nil
                                      verticalPadding:14.0
                                    horizontalPadding:20.0
                                         cornerRadius:5.0
                                               target:nil
                                               action:nil];
      [refreshBtn bk_addEventHandler:^(id sender) {
        __block BOOL receivedAuthReqdErrorOnDownloadAttempt = NO;
        NSMutableArray *successMsgsForRefresh = [NSMutableArray array];
        NSMutableArray *errsForRefresh = [NSMutableArray array];
        // The meaning of the elements of the arrays found within errsForRefresh:
        //
        // errsForRefresh[*][0]: Error title (string)
        // errsForRefresh[*][1]: Is error user-fixable (bool)
        // errsForRefresh[*][2]: An NSArray of sub-error messages (strings)
        // errsForRefresh[*][3]: Is error type server-busy? (bool)
        // errsForRefresh[*][4]: Is entity not found (bool)
        //
        MBProgressHUD *refreshHud = [MBProgressHUD showHUDAddedTo:controller.view animated:YES];
        enableUserInteraction(NO);
        [refreshHud setLabelText:[NSString stringWithFormat:@"Refreshing account status..."]];
        void(^refreshDone)(NSString *) = ^(NSString *mainMsgTitle) {
          if ([errsForRefresh count] == 0) { // success
            dispatch_async(dispatch_get_main_queue(), ^{
              [refreshHud hide:YES afterDelay:0.0];
              id downloadedUser = successMsgsForRefresh[0][1];
              void (^stillNotVerifiedAlert)(void) = ^{
                [PEUIUtils showInfoAlertWithTitle:@"Still not verified."
                                 alertDescription:[PEUIUtils attributedTextWithTemplate:@"Your account is still not verified.  \
Use the %@ button to have a new account verification link emailed to you."
                                                                           textToAccent:@"re-send verification email"
                                                                         accentTextFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]]
                                         topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                      buttonTitle:@"Okay."
                                     buttonAction:^{ enableUserInteraction(YES); }
                                   relativeToView:controller.tabBarController.view];
              };
              if ([downloadedUser isEqual:[NSNull null]]) { // user account not modified
                stillNotVerifiedAlert();
              } else { // user account modified
                [user setUpdatedAt:[downloadedUser updatedAt]];
                [user overwriteDomainProperties:downloadedUser];
                [coordDao saveMasterUser:downloadedUser error:[FPUtils localSaveErrorHandlerMaker]()];
                if ([PEUtils isNil:[user verifiedAt]]) {  // user account modified, but still not verified
                  stillNotVerifiedAlert();
                } else {  // user account verified
                  [PEUIUtils showSuccessAlertWithTitle:@"Account verified."
                                      alertDescription:[[NSAttributedString alloc] initWithString:@"Thank you.  Your account is now verified."]
                                              topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                           buttonTitle:@"Okay."
                                          buttonAction:^{
                                            enableUserInteraction(YES);
                                            [FPPanelToolkit refreshAccountStatusPanelForUser:user
                                                                                    panelTag:panelTag
                                                                        includeRefreshButton:includeRefreshButton
                                                                              coordinatorDao:coordDao
                                                                                   uitoolkit:uitoolkit
                                                                              relativeToView:relativeToView
                                                                                  controller:controller];
                                          }
                                        relativeToView:controller.tabBarController.view];
                }
              }
            });
          } else { // error(s)
            dispatch_async(dispatch_get_main_queue(), ^{
              [refreshHud hide:YES afterDelay:0.0];
              if ([errsForRefresh[0][3] boolValue]) { // server busy
                [PEUIUtils showWaitAlertWithMsgs:nil
                                           title:@"Busy with maintenance."
                                alertDescription:[[NSAttributedString alloc] initWithString:@"The server is currently busy at the moment \
undergoing maintenance.\n\nWe apologize for the inconvenience.  Please try refreshing later."]
                                        topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                     buttonTitle:@"Okay."
                                    buttonAction:^{ enableUserInteraction(YES); }
                                  relativeToView:controller.tabBarController.view];
              } else if ([errsForRefresh[0][4] boolValue]) { // not found
                NSString *fetchErrMsg = @"Oops.  Something appears to be wrong with your account.  Try logging off and logging back in.";
                [PEUIUtils showErrorAlertWithMsgs:nil
                                            title:@"Something went wrong."
                                 alertDescription:[[NSAttributedString alloc] initWithString:fetchErrMsg]
                                         topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                      buttonTitle:@"Okay."
                                     buttonAction:^{ enableUserInteraction(YES); }
                                   relativeToView:controller.tabBarController.view];
                
              } else { // any other error type
                NSString *fetchErrMsg = @"Oops.  There was a problem attempting to refresh.  Try it again a little later.";
                [PEUIUtils showErrorAlertWithMsgs:errsForRefresh[0][2]
                                            title:@"Something went wrong."
                                 alertDescription:[[NSAttributedString alloc] initWithString:fetchErrMsg]
                                         topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                      buttonTitle:@"Okay."
                                     buttonAction:^{ enableUserInteraction(YES); }
                                   relativeToView:controller.tabBarController.view];
              }
            });
          }
        };
        void(^refreshNotFoundBlk)(NSString *, NSString *) = ^(NSString *mainMsgTitle, NSString *recordTitle) {
          [errsForRefresh addObject:@[[NSString stringWithFormat:@"%@ not downloaded.", recordTitle],
                                             [NSNumber numberWithBool:NO],
                                             @[[NSString stringWithFormat:@"Not found."]],
                                             [NSNumber numberWithBool:NO],
                                             [NSNumber numberWithBool:YES]]];
          refreshDone(mainMsgTitle);
        };
        void (^refreshSuccessBlk)(NSString *, NSString *, id) = ^(NSString *mainMsgTitle, NSString *recordTitle, id downloadedEntity) {
          if (downloadedEntity == nil) { // server responded with 304
            downloadedEntity = [NSNull null];
          }
          [successMsgsForRefresh addObject:@[[NSString stringWithFormat:@"%@ downloaded.", recordTitle],
                                                    downloadedEntity]];
          refreshDone(mainMsgTitle);
        };
        void(^refreshRetryAfterBlk)(NSString *, NSString *, NSDate *) = ^(NSString *mainMsgTitle, NSString *recordTitle, NSDate *retryAfter) {
          [errsForRefresh addObject:@[[NSString stringWithFormat:@"%@ not downloaded.", recordTitle],
                                             [NSNumber numberWithBool:NO],
                                             @[[NSString stringWithFormat:@"Server busy.  Retry after: %@", retryAfter]],
                                             [NSNumber numberWithBool:YES],
                                             [NSNumber numberWithBool:NO]]];
          refreshDone(mainMsgTitle);
        };
        void (^refreshServerTempError)(NSString *, NSString *) = ^(NSString *mainMsgTitle, NSString *recordTitle) {
          [errsForRefresh addObject:@[[NSString stringWithFormat:@"%@ not downloaded.", recordTitle],
                                             [NSNumber numberWithBool:NO],
                                             @[@"Temporary server error."],
                                             [NSNumber numberWithBool:NO],
                                             [NSNumber numberWithBool:NO]]];
          refreshDone(mainMsgTitle);
        };
        void(^refreshAuthReqdBlk)(NSString *, NSString *) = ^(NSString *mainMsgTitle, NSString *recordTitle) {
          receivedAuthReqdErrorOnDownloadAttempt = YES;
          [errsForRefresh addObject:@[[NSString stringWithFormat:@"%@ not downloaded.", recordTitle],
                                             [NSNumber numberWithBool:NO],
                                             @[@"Authentication required."],
                                             [NSNumber numberWithBool:NO],
                                             [NSNumber numberWithBool:NO]]];
          refreshDone(mainMsgTitle);
        };
        NSString *mainMsgFragment = @"refreshing account status";
        NSString *recordTitle = @"Account status";
        [coordDao.userCoordinatorDao fetchUser:user
                               ifModifiedSince:[user updatedAt]
                           notFoundOnServerBlk:^{refreshNotFoundBlk(mainMsgFragment, recordTitle);}
                                    successBlk:^(PELMUser *fetchedUser) {refreshSuccessBlk(mainMsgFragment, recordTitle, fetchedUser);}
                            remoteStoreBusyBlk:^(NSDate *retryAfter){refreshRetryAfterBlk(mainMsgFragment, recordTitle, retryAfter);}
                            tempRemoteErrorBlk:^{refreshServerTempError(mainMsgFragment, recordTitle);}
                           addlAuthRequiredBlk:^{refreshAuthReqdBlk(mainMsgFragment, recordTitle); [APP refreshTabs];}];
      } forControlEvents:UIControlEventTouchUpInside];
      [PEUIUtils placeView:refreshBtn inMiddleOf:buttonsView withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:8.0];
      UIButton *resendEmailBtn = makeSendEmailBtn();
      if ((refreshBtn.frame.size.width + 10.0 + resendEmailBtn.frame.size.width) > panel.frame.size.width) {
        [PEUIUtils placeView:resendEmailBtn below:refreshBtn onto:buttonsView withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:3.0 hpadding:0.0];
        [PEUIUtils setFrameHeight:((refreshBtn.frame.size.height * 2) + 3.0) ofView:buttonsView];
      } else {
        [PEUIUtils placeView:resendEmailBtn toTheRightOf:refreshBtn onto:buttonsView withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:10.0];
        [PEUIUtils setFrameHeight:refreshBtn.frame.size.height ofView:buttonsView];
      }
    } else {
      UIButton *resendEmailBtn = makeSendEmailBtn();
      [PEUIUtils placeView:resendEmailBtn inMiddleOf:buttonsView withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:10.0];
      [PEUIUtils setFrameHeight:resendEmailBtn.frame.size.height ofView:buttonsView];
    }
    [PEUIUtils placeView:statusPanel atTopOf:panel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
    [PEUIUtils placeView:buttonsView below:statusPanel onto:panel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:5.0 hpadding:0.0];
    heightOfPanel += buttonsView.frame.size.height + 5.0;
  } else {
    panel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:statusPanel];
    UILabel *statusVerifiedMsg = [PEUIUtils labelWithKey:@"Your account is verified.  Thank you."
                                                    font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                         backgroundColor:[UIColor clearColor]
                                               textColor:[UIColor darkGrayColor]
                                     verticalTextPadding:3.0
                                              fitToWidth:panel.frame.size.width - 15.0];
    [PEUIUtils placeView:statusPanel atTopOf:panel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
    [PEUIUtils placeView:statusVerifiedMsg
                   below:statusPanel
                    onto:panel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:panel
                vpadding:4.0
                hpadding:8.0];
    heightOfPanel += statusVerifiedMsg.frame.size.height + 4.0;
  }
  [panel setTag:[panelTag integerValue]];
  [PEUIUtils setFrameHeight:heightOfPanel ofView:panel];
  return panel;
}

+ (void)refreshAccountStatusPanelForUser:(FPUser *)user
                                panelTag:(NSNumber *)panelTag
                    includeRefreshButton:(BOOL)includeRefreshButton
                          coordinatorDao:(id<FPCoordinatorDao>)coordDao
                               uitoolkit:(PEUIToolkit *)uitoolkit
                          relativeToView:(UIView *)relativeToView
                              controller:(UIViewController *)controller {
  UIView *accountStatusPanel = [relativeToView viewWithTag:[panelTag integerValue]];
  UIView *superView = accountStatusPanel.superview;
  [accountStatusPanel removeFromSuperview];
  UIView *newStatusPanel = [FPPanelToolkit accountStatusPanelForUser:user
                                                            panelTag:panelTag
                                                includeRefreshButton:includeRefreshButton
                                                      coordinatorDao:coordDao
                                                           uitoolkit:uitoolkit
                                                      relativeToView:relativeToView
                                                          controller:controller];
  newStatusPanel.frame = accountStatusPanel.frame;
  [superView addSubview:newStatusPanel];
}

+ (UIButton *)forgotPasswordButtonForUser:(FPUser *)user
                           coordinatorDao:(id<FPCoordinatorDao>)coordDao
                                uitoolkit:(PEUIToolkit *)uitoolkit
                               controller:(UIViewController *)controller {
  UIButton *forgotPasswordBtn = [PEUIUtils buttonWithKey:@"Forgot password?"
                                                    font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                         backgroundColor:[UIColor concreteColor]
                                               textColor:[UIColor whiteColor]
                            disabledStateBackgroundColor:nil
                                  disabledStateTextColor:nil
                                         verticalPadding:14.0
                                       horizontalPadding:20.0
                                            cornerRadius:5.0
                                                  target:nil
                                                  action:nil];
  [forgotPasswordBtn bk_addEventHandler:^(id sender) {
    [controller presentViewController:[PEUIUtils navigationControllerWithController:[[FPForgotPasswordController alloc] initWithStoreCoordinator:coordDao user:user uitoolkit:uitoolkit]
                                                                navigationBarHidden:NO]
                             animated:YES
                           completion:^{}];
  } forControlEvents:UIControlEventTouchUpInside];
  return forgotPasswordBtn;
}

#pragma mark - Vehicle Panel

- (UIView *)placeViewLogsButtonsOntoVehiclePanel:(UIView *)vehiclePanel
                                       belowView:(UIView *)belowView
                                        vpadding:(CGFloat)vpadding
                            parentViewController:(PEAddViewEditController *)parentViewController {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:vehiclePanel fixedHeight:0.0];
  // View Fuel Purchase Logs button
  UIButton *viewFpLogsBtn = [PEUIUtils buttonWithLabel:@"Gas logs"
                                          tagForButton:@(FPVehicleTagViewFplogsBtn)
                                           recordCount:[_coordDao numFuelPurchaseLogsForVehicle:(FPVehicle *)[parentViewController entity] error:[FPUtils localFetchErrorHandlerMaker]()]
                                tagForRecordCountLabel:@(FPVehicleTagViewFplogsBtnRecordCount)
                                     addDisclosureIcon:YES
                             addlVerticalButtonPadding:10.0
                          recordCountFromBottomPadding:2.0
                                recordCountLeftPadding:6.0
                                               handler:^{
                                                 FPAuthScreenMaker fpLogsScreenMaker =
                                                 [_screenToolkit newViewFuelPurchaseLogsScreenMakerForVehicleInCtx];
                                                 [PEUIUtils displayController:fpLogsScreenMaker((FPVehicle *)[parentViewController entity])
                                                               fromController:parentViewController
                                                                     animated:YES];
                                               }
                                             uitoolkit:_uitoolkit
                                        relativeToView:parentViewController.view];
  [PEUIUtils placeView:viewFpLogsBtn atTopOf:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
  CGFloat totalHeight = viewFpLogsBtn.frame.size.height;
  // View Environment Logs button
  UIButton *viewEnvLogsBtn = [PEUIUtils buttonWithLabel:@"Odometer logs"
                                           tagForButton:@(FPVehicleTagViewEnvlogsBtn)
                                            recordCount:[_coordDao numEnvironmentLogsForVehicle:(FPVehicle *)[parentViewController entity] error:[FPUtils localFetchErrorHandlerMaker]()]
                                 tagForRecordCountLabel:@(FPVehicleTagViewEnvlogsBtnRecordCount)
                                      addDisclosureIcon:YES
                              addlVerticalButtonPadding:10.0
                           recordCountFromBottomPadding:2.0
                                 recordCountLeftPadding:6.0
                                                handler:^{
                                                  FPVehicle *vehicle = (FPVehicle *)[parentViewController entity];
                                                  FPAuthScreenMaker envLogsScreenMaker =
                                                  [_screenToolkit newViewEnvironmentLogsScreenMakerForVehicleInCtx];
                                                  [PEUIUtils displayController:envLogsScreenMaker(vehicle) fromController:parentViewController animated:YES];
                                                }
                                              uitoolkit:_uitoolkit
                                         relativeToView:parentViewController.view];  
  [PEUIUtils placeView:viewEnvLogsBtn
                 below:viewFpLogsBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:8.0
              hpadding:0];
  totalHeight += viewEnvLogsBtn.frame.size.height + 8.0;
  UIView *msgPanel = [PEUIUtils leftPadView:[PEUIUtils labelWithKey:@"From here you can drill into the gas and odometer logs associated with this vehicle."
                                                               font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                                    backgroundColor:[UIColor clearColor]
                                                          textColor:[UIColor darkGrayColor]
                                                verticalTextPadding:3.0
                                                         fitToWidth:parentViewController.view.frame.size.width - 15.0]
                                    padding:8.0];
  [PEUIUtils placeView:msgPanel
                 below:viewEnvLogsBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0];
  totalHeight += msgPanel.frame.size.height + 4.0;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  [PEUIUtils placeView:contentPanel
                 below:belowView
                  onto:vehiclePanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:vpadding
              hpadding:0];
  return contentPanel;
}

- (PEEntityViewPanelMakerBlk)vehicleViewPanelMaker {
  return ^ UIView * (PEAddViewEditController *parentViewController, FPUser *user, FPVehicle *vehicle) {
    UIView *parentView = [parentViewController view];
    UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:parentView fixedHeight:0.0];
    NSMutableArray *rowData = [NSMutableArray arrayWithArray:@[@[@"Vehicle name", [PEUtils emptyIfNil:[vehicle name]]],
                                                               @[@"Takes diesel?", [PEUtils yesNoFromBool:[vehicle isDiesel]]]]];
    if (!vehicle.isDiesel) {
      [rowData addObject:@[@"Default octane", [PEUtils descriptionOrEmptyIfNil:[vehicle defaultOctane]]]];
    }
    [rowData addObjectsFromArray:@[@[@"Fuel capacity", [PEUtils descriptionOrEmptyIfNil:[vehicle fuelCapacity]]],
                                   /*@[@"Has range readout?", [PEUtils yesNoFromBool:[vehicle hasDteReadout]]],
                                   @[@"Has avg MPG readout?", [PEUtils yesNoFromBool:[vehicle hasMpgReadout]]],
                                   @[@"Has avg MPH readout?", [PEUtils yesNoFromBool:[vehicle hasMphReadout]]],
                                   @[@"Has outside temp. readout?", [PEUtils yesNoFromBool:[vehicle hasOutsideTempReadout]]],*/
                                   @[@"VIN", [PEUtils emptyIfNil:[vehicle vin]]],
                                   @[@"Plate #", [PEUtils emptyIfNil:[vehicle plate]]]]];
    UIView *vehicleDataPanel = [self tablePanelWithRowData:rowData
                                                 uitoolkit:_uitoolkit
                                                parentView:contentPanel];
    [PEUIUtils placeView:vehicleDataPanel
                 atTopOf:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:FPContentPanelTopPadding
                hpadding:0.0];
    CGFloat totalHeight = vehicleDataPanel.frame.size.height + FPContentPanelTopPadding;
    UIView *readoutsDataPanel = [self tablePanelWithRowData:@[@[@"Range readout?", [PEUtils yesNoFromBool:[vehicle hasDteReadout]]],
                                                              @[@"Avg MPG readout?", [PEUtils yesNoFromBool:[vehicle hasMpgReadout]]],
                                                              @[@"Avg MPH readout?", [PEUtils yesNoFromBool:[vehicle hasMphReadout]]],
                                                              @[@"Outside temp. readout?", [PEUtils yesNoFromBool:[vehicle hasOutsideTempReadout]]]]
                                                  uitoolkit:_uitoolkit
                                                 parentView:contentPanel];
    UILabel *hasReadoutsLabel = [PEUIUtils labelWithKey:@"Dashboard readout capabilities."
                                                   font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                        backgroundColor:[UIColor clearColor]
                                              textColor:[UIColor darkGrayColor]
                                    verticalTextPadding:3.0
                                             fitToWidth:parentView.frame.size.width - 15.0];
    [PEUIUtils placeView:readoutsDataPanel
                   below:vehicleDataPanel
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:20.0
                hpadding:0.0];
    totalHeight += readoutsDataPanel.frame.size.height + 20.0;
    [PEUIUtils placeView:hasReadoutsLabel
                   below:readoutsDataPanel
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:vehicleDataPanel
                vpadding:4.0
                hpadding:8.0];
    totalHeight += hasReadoutsLabel.frame.size.height + 4.0;
    UIButton *statsBtn = [_uitoolkit systemButtonMaker](@"Stats & Trends", nil, nil);
    [[statsBtn layer] setCornerRadius:0.0];
    [PEUIUtils setFrameWidthOfView:statsBtn ofWidth:1.0 relativeTo:parentView];
    [PEUIUtils addDisclosureIndicatorToButton:statsBtn];
    [statsBtn bk_addEventHandler:^(id sender) {
      [[parentViewController navigationController] pushViewController:[_screenToolkit newVehicleStatsLaunchScreenMakerWithVehicle:vehicle
                                                                                                                 parentController:parentViewController](user)
                                                             animated:YES];
    } forControlEvents:UIControlEventTouchUpInside];
    UIView *statsMsgPanel = [PEUIUtils leftPadView:[PEUIUtils labelWithKey:@"From here you can drill into the stats and trends associated with this vehicle."
                                                                      font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                                           backgroundColor:[UIColor clearColor]
                                                                 textColor:[UIColor darkGrayColor]
                                                       verticalTextPadding:3.0
                                                                fitToWidth:parentView.frame.size.width - 15.0]
                                           padding:8.0];
    [PEUIUtils placeView:statsBtn
                   below:hasReadoutsLabel
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:20.0
                hpadding:0.0];
    totalHeight += statsBtn.frame.size.height + 20.0;
    [PEUIUtils placeView:statsMsgPanel
                   below:statsBtn
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:4.0
                hpadding:0.0];
    totalHeight += statsMsgPanel.frame.size.height + 4.0;
    UIView *logsBtnsPanel = [self placeViewLogsButtonsOntoVehiclePanel:contentPanel
                                                             belowView:statsMsgPanel
                                                              vpadding:18.5
                                                  parentViewController:parentViewController];
    totalHeight += logsBtnsPanel.frame.size.height + 18.5;
    [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
    return [PEUIUtils displayPanelFromContentPanel:contentPanel
                                         scrolling:YES
                               scrollContentOffset:[parentViewController scrollContentOffset]
                                    scrollDelegate:parentViewController
                              delaysContentTouches:YES
                                           bounces:YES
                                  notScrollViewBlk:^{ [parentViewController resetScrollOffset]; }
                                          centered:NO
                                        controller:parentViewController];    
  };
}

- (PEEntityPanelMakerBlk)vehicleFormPanelMaker {
  return ^ UIView * (PEAddViewEditController *parentViewController) {
    UIView *parentView = [parentViewController view];
    TaggedTextfieldMaker tfMaker = [_uitoolkit taggedTextfieldMakerForWidthOf:1.0 relativeTo:parentView];
    UITextField *vehicleNameTf = tfMaker(@"Vehicle name", FPVehicleTagName);
    NSArray *(^switchPanelBlk)(NSInteger, NSString *, NSInteger) = ^NSArray *(NSInteger panelTag, NSString *labelText, NSInteger switchTag) {
      UIView *panel = [PEUIUtils panelWithWidthOf:1.0
                                   relativeToView:parentView
                                      fixedHeight:vehicleNameTf.frame.size.height];
      [panel setTag:panelTag];
      [panel setBackgroundColor:[UIColor whiteColor]];
      UILabel *label = [PEUIUtils labelWithKey:labelText
                                          font:[vehicleNameTf font]
                               backgroundColor:[UIColor clearColor]
                                     textColor:[_uitoolkit colorForTableCellTitles]
                           verticalTextPadding:3.0];
      UISwitch *uiswitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
      [uiswitch setTag:switchTag];
      [PEUIUtils placeView:label
                inMiddleOf:panel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  hpadding:10.0];
      [PEUIUtils placeView:uiswitch
                inMiddleOf:panel
             withAlignment:PEUIHorizontalAlignmentTypeRight
                  hpadding:15.0];
      return @[panel, uiswitch];
    };
    NSArray *takesDieselArray = switchPanelBlk(FPVehicleTagTakesDieselPanel, @"Takes Diesel?", FPVehicleTagTakesDieselSwitch);
    UIView *takesDieselPanel = takesDieselArray[0];
    UISwitch *takesDieselSwitch = takesDieselArray[1];
    UITextField *vehicleDefaultOctaneTf = tfMaker(FPPanelToolkitVehicleDefaultOctanePlaceholerText, FPVehicleTagDefaultOctane);
    [vehicleDefaultOctaneTf setKeyboardType:UIKeyboardTypeNumberPad];
    UITextField *vehicleFuelCapacityTf = tfMaker(@"Fuel capacity", FPVehicleTagFuelCapacity);
    [vehicleFuelCapacityTf setKeyboardType:UIKeyboardTypeDecimalPad];
    UILabel *readoutsLabel = [PEUIUtils labelWithKey:@"Select the dashboard readout capabilities of this vehicle."
                                                font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                     backgroundColor:[UIColor clearColor]
                                           textColor:[UIColor darkGrayColor]
                                 verticalTextPadding:3.0
                                          fitToWidth:parentView.frame.size.width - 15.0];
    UILabel *hasLabel = [PEUIUtils labelWithKey:@"This vehicle has..."
                                           font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                backgroundColor:[UIColor clearColor]
                                      textColor:[UIColor darkGrayColor]
                            verticalTextPadding:3.0
                                     fitToWidth:parentView.frame.size.width - 15.0];
    NSArray *hasDteReadoutArray = switchPanelBlk(FPVehicleTagHasDteReadoutPanel, @"Range readout?", FPVehicleTagHasDteReadoutSwitch);
    UIView *hasDteReadoutPanel = hasDteReadoutArray[0];
    NSArray *hasMpgReadoutArray = switchPanelBlk(FPVehicleTagHasMpgReadoutPanel, @"Avg MPG readout?", FPVehicleTagHasMpgReadoutSwitch);
    UIView *hasMpgReadoutPanel = hasMpgReadoutArray[0];
    NSArray *hasMphReadoutArray = switchPanelBlk(FPVehicleTagHasMphReadoutPanel, @"Avg MPH readout?", FPVehicleTagHasMphReadoutSwitch);
    UIView *hasMphReadoutPanel = hasMphReadoutArray[0];
    NSArray *hasOutsideTempReadoutArray = switchPanelBlk(FPVehicleTagHasOutsideTempReadoutPanel, @"Outside temp. readout?", FPVehicleTagHasOutsideTempReadoutSwitch);
    UIView *hasOutsideTempReadoutPanel = hasOutsideTempReadoutArray[0];
    UITextField *vinTf = tfMaker(@"VIN", FPVehicleTagVin);
    UITextField *plateTf = tfMaker(@"Plate #", FPVehicleTagPlate);
    UIView *topPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:parentView fixedHeight:0.0];
    [topPanel setTag:FPVehicleTagTopPanel];
    [PEUIUtils placeView:vehicleNameTf
                 atTopOf:topPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:FPContentPanelTopPadding
                hpadding:0];
    [PEUIUtils placeView:takesDieselPanel
                   below:vehicleNameTf
                    onto:topPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils setFrameHeight:(vehicleNameTf.frame.size.height + FPContentPanelTopPadding +
                               takesDieselPanel.frame.size.height + 5.0)
                       ofView:topPanel];    
    UIView *bottomPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:parentView fixedHeight:0.0];
    [bottomPanel setTag:FPVehicleTagBottomPanel];
    [PEUIUtils placeView:vehicleDefaultOctaneTf
                 atTopOf:bottomPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:vehicleFuelCapacityTf
                   below:vehicleDefaultOctaneTf
                    onto:bottomPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:vinTf
                   below:vehicleFuelCapacityTf
                    onto:bottomPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:plateTf
                   below:vinTf
                    onto:bottomPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:plateTf
                   below:vinTf
                    onto:bottomPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:hasLabel
                   below:plateTf
                    onto:bottomPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:20.0
                hpadding:8.0];
    [PEUIUtils placeView:hasDteReadoutPanel
                   below:hasLabel
                    onto:bottomPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:bottomPanel
                vpadding:4.0
                hpadding:0.0];
    [PEUIUtils placeView:hasMpgReadoutPanel
                   below:hasDteReadoutPanel
                    onto:bottomPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:hasMphReadoutPanel
                   below:hasMpgReadoutPanel
                    onto:bottomPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:hasOutsideTempReadoutPanel
                   below:hasMphReadoutPanel
                    onto:bottomPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:readoutsLabel
                   below:hasOutsideTempReadoutPanel
                    onto:bottomPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:4.0
                hpadding:8.0];
    [PEUIUtils setFrameHeight:(vehicleDefaultOctaneTf.frame.size.height + 5.0 +
                               vehicleFuelCapacityTf.frame.size.height + 5.0 +
                               vinTf.frame.size.height + 5.0 +
                               plateTf.frame.size.height + 5.0 +
                               hasLabel.frame.size.height + 20.0 +
                               hasDteReadoutPanel.frame.size.height + 4.0 +
                               hasMpgReadoutPanel.frame.size.height + 5.0 +
                               hasMphReadoutPanel.frame.size.height + 5.0 +
                               hasOutsideTempReadoutPanel.frame.size.height + 5.0 +
                               readoutsLabel.frame.size.height + 4.0)
                       ofView:bottomPanel];
    UIView *contentPanel = [PEUIUtils panelWithColumnOfViews:@[topPanel, bottomPanel]
                                 verticalPaddingBetweenViews:0.0
                                              viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
    [contentPanel bringSubviewToFront:topPanel];
    [takesDieselSwitch bk_addEventHandler:^(id sender) {
      [vehicleDefaultOctaneTf setEnabled:!takesDieselSwitch.on];
      if (takesDieselSwitch.on) {
        [UIView animateWithDuration:0.65
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                           [PEUIUtils adjustYOfView:bottomPanel withValue:((takesDieselPanel.frame.size.height + 5.0) * -1.0)];
                         }
                         completion:^(BOOL finished) {
                           [vehicleDefaultOctaneTf setText:@""];
                         }];
      } else {
        [UIView animateWithDuration:0.65
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                           [PEUIUtils adjustYOfView:bottomPanel withValue:((takesDieselPanel.frame.size.height + 5.0) * 1.0)];
                         }
                         completion:^(BOOL finished) {
                         }];
      }
    } forControlEvents:UIControlEventTouchUpInside];
    return [PEUIUtils displayPanelFromContentPanel:contentPanel
                                         scrolling:YES
                               scrollContentOffset:[parentViewController scrollContentOffset]
                                    scrollDelegate:parentViewController
                              delaysContentTouches:YES
                                           bounces:YES
                                  notScrollViewBlk:^{ [parentViewController resetScrollOffset]; }
                                          centered:NO
                                        controller:parentViewController];
  };
}

- (PEPanelToEntityBinderBlk)vehicleFormPanelToVehicleBinder {
  return ^ void (UIView *panel, FPVehicle *vehicle) {
    [PEUIUtils bindToEntity:vehicle
           withStringSetter:@selector(setName:)
       fromTextfieldWithTag:FPVehicleTagName
                   fromView:panel];
    UISwitch *takesDieselSwitch = (UISwitch *)[panel viewWithTag:FPVehicleTagTakesDieselSwitch];
    [vehicle setIsDiesel:takesDieselSwitch.on];
    if (takesDieselSwitch.on) {
      [vehicle setDefaultOctane:nil];
    } else {
      [PEUIUtils bindToEntity:vehicle
             withNumberSetter:@selector(setDefaultOctane:)
         fromTextfieldWithTag:FPVehicleTagDefaultOctane
                     fromView:panel];
    }
    [PEUIUtils bindToEntity:vehicle
          withDecimalSetter:@selector(setFuelCapacity:)
       fromTextfieldWithTag:FPVehicleTagFuelCapacity
                   fromView:panel];
    [vehicle setHasDteReadout:((UISwitch *)[panel viewWithTag:FPVehicleTagHasDteReadoutSwitch]).on];
    [vehicle setHasMpgReadout:((UISwitch *)[panel viewWithTag:FPVehicleTagHasMpgReadoutSwitch]).on];
    [vehicle setHasMphReadout:((UISwitch *)[panel viewWithTag:FPVehicleTagHasMphReadoutSwitch]).on];
    [vehicle setHasOutsideTempReadout:((UISwitch *)[panel viewWithTag:FPVehicleTagHasOutsideTempReadoutSwitch]).on];
    [PEUIUtils bindToEntity:vehicle
           withStringSetter:@selector(setVin:)
       fromTextfieldWithTag:FPVehicleTagVin
                   fromView:panel];
    [PEUIUtils bindToEntity:vehicle
           withStringSetter:@selector(setPlate:)
       fromTextfieldWithTag:FPVehicleTagPlate
                   fromView:panel];
  };
}

- (PEEntityToPanelBinderBlk)vehicleToVehiclePanelBinder {
  return ^ void (FPVehicle *vehicle, UIView *panel) {
    [PEUIUtils bindToTextControlWithTag:FPVehicleTagName
                               fromView:panel
                             fromEntity:vehicle
                             withGetter:@selector(name)];
    UISwitch *takesDieselSwitch = (UISwitch *)[panel viewWithTag:FPVehicleTagTakesDieselSwitch];
    [takesDieselSwitch setOn:[vehicle isDiesel] animated:NO];
    UITextField *defaultOctaneTf = [panel viewWithTag:FPVehicleTagDefaultOctane];
    if ([vehicle isDiesel]) {
      [defaultOctaneTf setText:@""];
      UIView *bottomPanel = [panel viewWithTag:FPVehicleTagBottomPanel];
      UIView *takesDieselPanel = [panel viewWithTag:FPVehicleTagTakesDieselPanel];
      [PEUIUtils adjustYOfView:bottomPanel withValue:((takesDieselPanel.frame.size.height + 5.0) * -1.0)];
    } else {
      [defaultOctaneTf setBackgroundColor:[UIColor whiteColor]];
      [PEUIUtils bindToTextControlWithTag:FPVehicleTagDefaultOctane
                                 fromView:panel
                               fromEntity:vehicle
                               withGetter:@selector(defaultOctane)];
    }
    [PEUIUtils bindToTextControlWithTag:FPVehicleTagFuelCapacity
                               fromView:panel
                             fromEntity:vehicle
                             withGetter:@selector(fuelCapacity)];
    [((UISwitch *)[panel viewWithTag:FPVehicleTagHasDteReadoutSwitch]) setOn:vehicle.hasDteReadout animated:NO];
    [((UISwitch *)[panel viewWithTag:FPVehicleTagHasMpgReadoutSwitch]) setOn:vehicle.hasMpgReadout animated:NO];
    [((UISwitch *)[panel viewWithTag:FPVehicleTagHasMphReadoutSwitch]) setOn:vehicle.hasMphReadout animated:NO];
    [((UISwitch *)[panel viewWithTag:FPVehicleTagHasOutsideTempReadoutSwitch]) setOn:vehicle.hasOutsideTempReadout animated:NO];
    [PEUIUtils bindToTextControlWithTag:FPVehicleTagVin
                               fromView:panel
                             fromEntity:vehicle
                             withGetter:@selector(vin)];
    [PEUIUtils bindToTextControlWithTag:FPVehicleTagPlate
                               fromView:panel
                             fromEntity:vehicle
                             withGetter:@selector(plate)];
  };
}

- (PEEnableDisablePanelBlk)vehicleFormPanelEnablerDisabler {
  return ^ (UIView *panel, BOOL enable) {
    [PEUIUtils enableControlWithTag:FPVehicleTagName
                           fromView:panel
                             enable:enable];
    [PEUIUtils enableControlWithTag:FPVehicleTagTakesDieselSwitch
                           fromView:panel
                             enable:enable];
    [PEUIUtils enableControlWithTag:FPVehicleTagDefaultOctane
                           fromView:panel
                             enable:enable];
    [PEUIUtils enableControlWithTag:FPVehicleTagFuelCapacity
                           fromView:panel
                             enable:enable];
    [PEUIUtils enableControlWithTag:FPVehicleTagHasDteReadoutSwitch
                           fromView:panel
                             enable:enable];
    [PEUIUtils enableControlWithTag:FPVehicleTagHasMpgReadoutSwitch
                           fromView:panel
                             enable:enable];
    [PEUIUtils enableControlWithTag:FPVehicleTagHasMphReadoutSwitch
                           fromView:panel
                             enable:enable];
    [PEUIUtils enableControlWithTag:FPVehicleTagHasOutsideTempReadoutSwitch
                           fromView:panel
                             enable:enable];
    [PEUIUtils enableControlWithTag:FPVehicleTagVin
                           fromView:panel
                             enable:enable];
    [PEUIUtils enableControlWithTag:FPVehicleTagPlate
                           fromView:panel
                             enable:enable];
  };
}

- (PEEntityMakerBlk)vehicleMaker {
  return ^ PELMModelSupport * (UIView *panel) {
    FPVehicle *newVehicle =
      [_coordDao vehicleWithName:[PEUIUtils stringFromTextFieldWithTag:FPVehicleTagName fromView:panel]
                   defaultOctane:[PEUIUtils numberFromTextFieldWithTag:FPVehicleTagDefaultOctane fromView:panel]
                    fuelCapacity:[PEUIUtils decimalNumberFromTextFieldWithTag:FPVehicleTagFuelCapacity fromView:panel]
                        isDiesel:((UISwitch *)[panel viewWithTag:FPVehicleTagTakesDieselSwitch]).on
                   hasDteReadout:((UISwitch *)[panel viewWithTag:FPVehicleTagHasDteReadoutSwitch]).on
                   hasMpgReadout:((UISwitch *)[panel viewWithTag:FPVehicleTagHasMpgReadoutSwitch]).on
                   hasMphReadout:((UISwitch *)[panel viewWithTag:FPVehicleTagHasMphReadoutSwitch]).on
           hasOutsideTempReadout:((UISwitch *)[panel viewWithTag:FPVehicleTagHasOutsideTempReadoutSwitch]).on
                             vin:[PEUIUtils stringFromTextFieldWithTag:FPVehicleTagVin fromView:panel]
                           plate:[PEUIUtils stringFromTextFieldWithTag:FPVehicleTagPlate fromView:panel]];
    return newVehicle;
  };
}

#pragma mark - Fuel Station Panel

- (NSArray *)placeViewLogsButtonOntoFuelstationPanel:(UIView *)fuelstationPanel
                                           belowView:(UIView *)belowView
                                parentViewController:(PEAddViewEditController *)parentViewController {
  UIButton *viewFpLogsBtn = [PEUIUtils buttonWithLabel:@"Gas logs"
                                          tagForButton:@(FPFuelStationTagViewFplogsBtn)
                                           recordCount:[_coordDao numFuelPurchaseLogsForFuelStation:(FPFuelStation *)[parentViewController entity] error:[FPUtils localFetchErrorHandlerMaker]()]
                                tagForRecordCountLabel:@(FPFuelStationTagViewFplogsBtnRecordCount)
                                     addDisclosureIcon:YES
                             addlVerticalButtonPadding:10.0
                          recordCountFromBottomPadding:2.0
                                recordCountLeftPadding:6.0
                                               handler:^{
                                                 FPAuthScreenMaker fpLogsScreenMaker =
                                                 [_screenToolkit newViewFuelPurchaseLogsScreenMakerForFuelStationInCtx];
                                                 [PEUIUtils displayController:fpLogsScreenMaker((FPFuelStation *)[parentViewController entity])
                                                               fromController:parentViewController
                                                                     animated:YES];
                                               }
                                             uitoolkit:_uitoolkit
                                        relativeToView:parentViewController.view];
  [PEUIUtils placeView:viewFpLogsBtn
                 below:belowView
                  onto:fuelstationPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:18.5
              hpadding:0];
  CGFloat totalHeight = viewFpLogsBtn.frame.size.height + 18.5;
  UIView *msgPanel = [PEUIUtils leftPadView:[PEUIUtils labelWithKey:@"From here you can drill into the gas logs associated with this gas station."
                                                               font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                                    backgroundColor:[UIColor clearColor]
                                                          textColor:[UIColor darkGrayColor]
                                                verticalTextPadding:3.0
                                                         fitToWidth:parentViewController.view.frame.size.width - 15.0]
                                    padding:8.0];
  [PEUIUtils placeView:msgPanel
                 below:viewFpLogsBtn
                  onto:fuelstationPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0];
  totalHeight += msgPanel.frame.size.height + 4.0;
  return @[viewFpLogsBtn, @(totalHeight)];
}

- (NSArray *)placeCoordinatesTableOntoFuelstationPanel:(UIView *)fuelstationPanel
                                           fuelstation:(FPFuelStation *)fuelstation
                                             belowView:(UIView *)belowView
                                  parentViewController:(PEAddViewEditController *)parentViewController {
  UIView *parentView = [parentViewController view];
  UITableView *coordinatesTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)
                                                                   style:UITableViewStyleGrouped];
  FPFuelStationCoordinatesTableDataSource *ds =
    [[FPFuelStationCoordinatesTableDataSource alloc] initWithFuelStationLatitude:[PEUtils nilIfNSNull:[fuelstation latitude]]
                                                                       longitude:[PEUtils nilIfNSNull:[fuelstation longitude]]];
  [_tableViewDataSources addObject:ds];
  [coordinatesTableView setDataSource:ds];
  [coordinatesTableView setScrollEnabled:NO];
  [coordinatesTableView setTag:FPFuelStationTagLocationCoordinates];
  [PEUIUtils setFrameWidthOfView:coordinatesTableView ofWidth:1.0 relativeTo:parentView];
  [PEUIUtils setFrameHeight:((2 * [PEUIUtils sizeOfText:@"" withFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleBody]].height) + 120)
                     ofView:coordinatesTableView];
  [PEUIUtils placeView:coordinatesTableView
                 below:belowView
                  onto:fuelstationPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:0.0
              hpadding:0.0];
  return @[coordinatesTableView, ds];
}

- (PEEntityViewPanelMakerBlk)fuelstationViewPanelMaker {
  return ^ UIView * (PEAddViewEditController *parentViewController, FPUser *user, FPFuelStation *fuelstation) {
    UIView *parentView = [parentViewController view];
    UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:parentView fixedHeight:0.0];
    NSDictionary *components = [self fuelstationFormComponentsWithUser:user displayDisclosureIndicators:NO fsType:fuelstation.type](parentViewController);
    UITableView *fsTypeTableView = (UITableView *)components[@(FPFuelStationTagType)];
    [fsTypeTableView setUserInteractionEnabled:NO];
    [PEUIUtils placeView:fsTypeTableView
                 atTopOf:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0.0];
    CGFloat totalHeight = fsTypeTableView.frame.size.height;
    UIView *fuelstationDataPanel = [self tablePanelWithRowData:@[@[@"Nickname", [PEUtils emptyIfNil:[fuelstation name]]],
                                                                 @[@"Street", [PEUtils emptyIfNil:[fuelstation street]]],
                                                                 @[@"City", [PEUtils emptyIfNil:[fuelstation city]]],
                                                                 @[@"State", [PEUtils emptyIfNil:[fuelstation state]]],
                                                                 @[@"Zip", [PEUtils emptyIfNil:[fuelstation zip]]]]
                                                     uitoolkit:_uitoolkit
                                                    parentView:parentView];
    [PEUIUtils placeView:fuelstationDataPanel
                   below:fsTypeTableView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:10.0
                hpadding:0.0];
    totalHeight = fuelstationDataPanel.frame.size.height + 10.0;
    UITableView *coordinatesTableView = [self placeCoordinatesTableOntoFuelstationPanel:contentPanel
                                                                            fuelstation:fuelstation
                                                                              belowView:fuelstationDataPanel
                                                                   parentViewController:parentViewController][0];
    totalHeight += coordinatesTableView.frame.size.height;
    UIButton *statsBtn = [_uitoolkit systemButtonMaker](@"Stats & Trends", nil, nil);
    [[statsBtn layer] setCornerRadius:0.0];
    [PEUIUtils setFrameWidthOfView:statsBtn ofWidth:1.0 relativeTo:parentView];
    [PEUIUtils addDisclosureIndicatorToButton:statsBtn];
    [statsBtn bk_addEventHandler:^(id sender) {
      [[parentViewController navigationController] pushViewController:[_screenToolkit newFuelStationStatsLaunchScreenMakerWithFuelstation:fuelstation](user)
                                                             animated:YES];
    } forControlEvents:UIControlEventTouchUpInside];
    UIView *statsMsgPanel = [PEUIUtils leftPadView:[PEUIUtils labelWithKey:@"From here you can drill into the stats and trends associated with this gas station."
                                                                      font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                                           backgroundColor:[UIColor clearColor]
                                                                 textColor:[UIColor darkGrayColor]
                                                       verticalTextPadding:3.0
                                                                fitToWidth:parentView.frame.size.width - 15.0]
                                           padding:8.0];
    [PEUIUtils placeView:statsBtn
                   below:coordinatesTableView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:20.0
                hpadding:0.0];
    totalHeight += statsBtn.frame.size.height + 20.0;
    [PEUIUtils placeView:statsMsgPanel
                   below:statsBtn
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:4.0
                hpadding:0.0];
    totalHeight += statsMsgPanel.frame.size.height + 4.0;
    NSArray *viewLogsContent = [self placeViewLogsButtonOntoFuelstationPanel:contentPanel
                                                                   belowView:statsMsgPanel
                                                        parentViewController:parentViewController];
    totalHeight += ((NSDecimalNumber *)viewLogsContent[1]).floatValue;
    [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
    return [PEUIUtils displayPanelFromContentPanel:contentPanel
                                         scrolling:YES
                               scrollContentOffset:[parentViewController scrollContentOffset]
                                    scrollDelegate:parentViewController
                              delaysContentTouches:YES
                                           bounces:YES
                                  notScrollViewBlk:^{ [parentViewController resetScrollOffset]; }
                                          centered:NO
                                        controller:parentViewController];
  };
}

- (PEComponentsMakerBlk)fuelstationFormComponentsWithUser:(FPUser *)user
                              displayDisclosureIndicators:(BOOL)displayDisclosureIndicators
                                                   fsType:(FPFuelStationType *)fsType {
  return ^ NSDictionary * (UIViewController *parentViewController) {
    NSMutableDictionary *components = [NSMutableDictionary dictionary];
    UIView *parentView = [parentViewController view];
    UITableView *fsTypeTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 0, 0) style:UITableViewStyleGrouped];
    [fsTypeTableView setScrollEnabled:NO];
    [fsTypeTableView setTag:FPFuelStationTagType];
    [PEUIUtils setFrameWidthOfView:fsTypeTableView ofWidth:1.0 relativeTo:parentView];
    [PEUIUtils setFrameHeight:((1 * [PEUIUtils sizeOfText:@"" withFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleBody]].height) + 52)
                       ofView:fsTypeTableView];
    PEItemSelectedAction fsTypeSelectedAction = ^(FPFuelStationType *fsType, NSIndexPath *indexPath, UIViewController *fsTypeSelectionController) {
      [[fsTypeSelectionController navigationController] popViewControllerAnimated:YES];
      [fsTypeTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
    };
    FPFuelstationTypeDsDelegate *fsTypeDs = [[FPFuelstationTypeDsDelegate alloc] initWithControllerCtx:parentViewController
                                                                                                fsType:fsType
                                                                                  fsTypeSelectedAction:fsTypeSelectedAction
                                                                           displayDisclosureIndicators:displayDisclosureIndicators
                                                                                        coordinatorDao:_coordDao
                                                                                                  user:user
                                                                                         screenToolkit:_screenToolkit
                                                                                                 error:_errorBlk];
    [_tableViewDataSources addObject:fsTypeDs];
    fsTypeTableView.sectionHeaderHeight = 2.0;
    fsTypeTableView.sectionFooterHeight = 2.0;
    [fsTypeTableView setDataSource:fsTypeDs];
    [fsTypeTableView setDelegate:fsTypeDs];
    components[@(FPFuelStationTagType)] = fsTypeTableView;
    TaggedTextfieldMaker tfMaker = [_uitoolkit taggedTextfieldMakerForWidthOf:1.0 relativeTo:parentView];
    UITextField *fuelStationNameTf = tfMaker(@"Station nickname", FPFuelStationTagName);
    components[@(FPFuelStationTagName)] = fuelStationNameTf;
    UITextField *fuelStationStreetTf = tfMaker(@"Street", FPFuelStationTagStreet);
    components[@(FPFuelStationTagStreet)] = fuelStationStreetTf;
    UITextField *fuelStationCityTf = tfMaker(@"City", FPFuelStationTagCity);
    components[@(FPFuelStationTagCity)] = fuelStationCityTf;
    UITextField *fuelStationStateTf = tfMaker(@"State", FPFuelStationTagState);
    components[@(FPFuelStationTagState)] = fuelStationStateTf;
    UITextField *fuelStationZipTf = tfMaker(@"Zip", FPFuelStationTagZip);
    [fuelStationZipTf setKeyboardType:UIKeyboardTypeNumberPad];
    components[@(FPFuelStationTagZip)] = fuelStationZipTf;
    return components;
  };
}

- (PEEntityPanelMakerBlk)fuelstationFormPanelMakerWithUser:(FPUser *)user
                                          defaultFsTypeBlk:(FPFuelStationType *(^)(void))defaultFsTypeBlk {
  return ^ UIView * (PEAddViewEditController *parentViewController) {
    UIView *parentView = [parentViewController view];
    FPFuelstationTypeDsDelegate *fsTypeDs = (FPFuelstationTypeDsDelegate *)[(UITableView *)[parentView viewWithTag:FPFuelStationTagType] dataSource];
    FPFuelStationType *fsType;
    if (fsTypeDs) {
      fsType = [fsTypeDs selectedFsType];
    } else {
      fsType = defaultFsTypeBlk();
    }
    UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:parentView fixedHeight:0.0];
    NSDictionary *components = [self fuelstationFormComponentsWithUser:user displayDisclosureIndicators:YES fsType:fsType](parentViewController);
    UITableView *fsTypeTableView = (UITableView *)components[@(FPFuelStationTagType)];
    UITextField *fuelStationNameTf = components[@(FPFuelStationTagName)];
    UITextField *fuelStationStreetTf = components[@(FPFuelStationTagStreet)];
    UITextField *fuelStationCityTf = components[@(FPFuelStationTagCity)];
    UITextField *fuelStationStateTf = components[@(FPFuelStationTagState)];
    UITextField *fuelStationZipTf = components[@(FPFuelStationTagZip)];
    [PEUIUtils placeView:fsTypeTableView
                 atTopOf:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0];
    CGFloat totalHeight = fsTypeTableView.frame.size.height;
    [PEUIUtils placeView:fuelStationNameTf
                   below:fsTypeTableView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:10.0
                hpadding:0.0];
    totalHeight += fuelStationNameTf.frame.size.height + 10.0;
    [PEUIUtils placeView:fuelStationStreetTf
                   below:fuelStationNameTf
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    totalHeight += fuelStationStreetTf.frame.size.height + 5.0;
    [PEUIUtils placeView:fuelStationCityTf
                   below:fuelStationStreetTf
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    totalHeight += fuelStationCityTf.frame.size.height + 5.0;
    [PEUIUtils placeView:fuelStationStateTf
                   below:fuelStationCityTf
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    totalHeight += fuelStationStateTf.frame.size.height + 5.0;
    [PEUIUtils placeView:fuelStationZipTf
                   below:fuelStationStateTf
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    totalHeight += fuelStationZipTf.frame.size.height + 5.0;
    NSArray *tableAndDs = [self placeCoordinatesTableOntoFuelstationPanel:contentPanel
                                                              fuelstation:nil
                                                                belowView:fuelStationZipTf
                                                     parentViewController:parentViewController];
    UITableView *coordinatesTableView = tableAndDs[0];
    totalHeight += coordinatesTableView.frame.size.height;
    FPFuelStationCoordinatesTableDataSource *ds = tableAndDs[1];
    UIButton *useCurrentLocationBtn = [PEUIUtils buttonWithKey:@"Use current location"
                                                          font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                               backgroundColor:[UIColor concreteColor]
                                                     textColor:[UIColor whiteColor]
                                  disabledStateBackgroundColor:nil
                                        disabledStateTextColor:nil
                                               verticalPadding:24.0
                                             horizontalPadding:20.0
                                                  cornerRadius:5.0
                                                        target:nil
                                                        action:nil];
    [useCurrentLocationBtn setTag:FPFuelStationTagUseCurrentLocation];
    [useCurrentLocationBtn bk_addEventHandler:^(id sender) {
      [parentViewController.view endEditing:YES];
      void (^doUseCurrentLocation)(void) = ^{
        CLLocation *currentLocation = [APP latestLocation];
        if (currentLocation) {
          [ds setLatitude:[PEUtils decimalNumberFromDouble:[currentLocation coordinate].latitude]];
          [ds setLongitude:[PEUtils decimalNumberFromDouble:[currentLocation coordinate].longitude]];
          [coordinatesTableView reloadData];
        }
      };
      if ([PEUtils isNil:[APP latestLocation]]) {
        if ([APP locationServicesAuthorized]) {
          NSAttributedString *attrDescTextWithInstructionalText =
          [PEUIUtils attributedTextWithTemplate:@"Your current location cannot be determined.  \
Make sure you have location services enabled for Gas Jot.  You can check this by going to:\n\n%@"
                                   textToAccent:@"Settings app \u2794 Privacy \u2794 Location Services \u2794 Gas Jot"
                                 accentTextFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
          [PEUIUtils showWarningAlertWithMsgs:nil
                                        title:@"Hmm."
                             alertDescription:attrDescTextWithInstructionalText
                                     topInset:[PEUIUtils topInsetForAlertsWithController:parentViewController]
                                  buttonTitle:@"Okay."
                                 buttonAction:^{}
                               relativeToView:parentView];
        } else {
          if ([APP hasBeenAskedToEnableLocationServices]) {
            [PEUIUtils showInstructionalAlertWithTitle:@"Enable location services."
                                  alertDescriptionText:@"To compute your current location, you need to enable location services for Gas Jot.  To do this, go to:\n\n"
                                       instructionText:@"Settings app \u2794 Privacy \u2794 Location Services \u2794 Gas Jot"
                                              topInset:[PEUIUtils topInsetForAlertsWithController:parentViewController]
                                           buttonTitle:@"Okay."
                                          buttonAction:^{}
                                        relativeToView:parentView];
          } else {
            [PEUIUtils showConfirmAlertWithTitle:@"Enable location services?"
                                      titleImage:[PEUIUtils bundleImageWithName:@"question"]
                                alertDescription:[[NSAttributedString alloc] initWithString:@"\
To compute your location, you need to enable location services for Gas Jot.  If you would like to do this, tap 'Allow' in the next pop-up."]
                                        topInset:[PEUIUtils topInsetForAlertsWithController:parentViewController]
                                 okayButtonTitle:@"Okay."
                                okayButtonAction:^{
                                  [[APP locationManager] requestWhenInUseAuthorization];
                                  [APP setHasBeenAskedToEnableLocationServices:YES];
                                }
                                 okayButtonStyle:JGActionSheetButtonStyleBlue
                               cancelButtonTitle:@"No.  Not at this time."
                              cancelButtonAction:^{ }
                                cancelButtonSyle:JGActionSheetButtonStyleDefault
                                  relativeToView:parentView];
          }
        }
      } else {
        doUseCurrentLocation();
      }
    } forControlEvents:UIControlEventTouchUpInside];
    [PEUIUtils placeView:useCurrentLocationBtn
                   below:coordinatesTableView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:8.0
                hpadding:8.0];
    totalHeight += useCurrentLocationBtn.frame.size.height + 8.0;
    UIButton *recomputeCoordsBtn = [PEUIUtils buttonWithKey:@"Compute coordinates from\nabove address"
                                                       font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                            backgroundColor:[UIColor concreteColor]
                                                  textColor:[UIColor whiteColor]
                               disabledStateBackgroundColor:nil
                                     disabledStateTextColor:nil
                                            verticalPadding:14.0
                                          horizontalPadding:20.0
                                               cornerRadius:5.0
                                                     target:nil
                                                     action:nil];
    recomputeCoordsBtn.titleLabel.textAlignment = NSTextAlignmentLeft;
    [recomputeCoordsBtn setTag:FPFuelStationTagRecomputeCoordinates];
    [recomputeCoordsBtn bk_addEventHandler:^(id sender) {
      [parentViewController.view endEditing:YES];
      if (([[fuelStationStreetTf text] length] == 0) &&
          ([[fuelStationCityTf text] length] == 0) &&
          ([[fuelStationStateTf text] length] == 0) &&
          ([[fuelStationZipTf text] length] == 0)) {
        [PEUIUtils showErrorAlertWithMsgs:nil
                                    title:@"Oops."
                         alertDescription:[[NSAttributedString alloc] initWithString:@"You need to enter at least part of the address above in order to compute the location coordinates."]
                                 topInset:[PEUIUtils topInsetForAlertsWithController:parentViewController]
                              buttonTitle:@"Okay."
                             buttonAction:nil
                           relativeToView:parentView];
      } else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:parentView animated:YES];
        hud.delegate = parentViewController;
        hud.labelText = @"Computing Location Coordinates";
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        [geocoder geocodeAddressString:[PEUtils addressStringFromStreet:[fuelStationStreetTf text]
                                                                   city:[fuelStationCityTf text]
                                                                  state:[fuelStationStateTf text]
                                                                    zip:[fuelStationZipTf text]]
                     completionHandler:^(NSArray *placemarks, NSError *error) {
                       if (placemarks && ([placemarks count] > 0)) {
                         CLPlacemark *placemark = placemarks[0];
                         CLLocation *location = [placemark location];
                         CLLocationCoordinate2D coordinate = [location coordinate];
                         [ds setLatitude:[PEUtils decimalNumberFromDouble:coordinate.latitude]];
                         [ds setLongitude:[PEUtils decimalNumberFromDouble:coordinate.longitude]];
                         [coordinatesTableView reloadData];
                         [hud hide:YES];
                       } else if (error) {
                         [hud hide:YES];
                         [PEUIUtils showErrorAlertWithMsgs:nil
                                                     title:@"Oops."
                                          alertDescription:[[NSAttributedString alloc] initWithString:@"There was a problem trying to compute the \
                                                            location from the given address above."]
                                                  topInset:[PEUIUtils topInsetForAlertsWithController:parentViewController]
                                               buttonTitle:@"Okay."
                                              buttonAction:nil
                                            relativeToView:parentView];
                       }
                     }];
      }
    } forControlEvents:UIControlEventTouchUpInside];
    [PEUIUtils placeView:recomputeCoordsBtn
                   below:useCurrentLocationBtn
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:6.0
                hpadding:0.0];
    totalHeight += recomputeCoordsBtn.frame.size.height + 6.0;
    [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
    return [PEUIUtils displayPanelFromContentPanel:contentPanel
                                         scrolling:YES
                               scrollContentOffset:[parentViewController scrollContentOffset]
                                    scrollDelegate:parentViewController
                              delaysContentTouches:YES
                                           bounces:YES
                                  notScrollViewBlk:^{ [parentViewController resetScrollOffset]; }
                                          centered:NO
                                        controller:parentViewController];
  };
}

- (PEPanelToEntityBinderBlk)fuelstationFormPanelToFuelstationBinder {
  return ^ void (UIView *panel, FPFuelStation *fuelStation) {
    void (^bindte)(NSInteger, SEL) = ^(NSInteger tag, SEL sel) {
      [PEUIUtils bindToEntity:fuelStation
             withStringSetter:sel
         fromTextfieldWithTag:tag
                     fromView:panel];
    };
    bindte(FPFuelStationTagName, @selector(setName:));
    bindte(FPFuelStationTagStreet, @selector(setStreet:));
    bindte(FPFuelStationTagCity, @selector(setCity:));
    bindte(FPFuelStationTagState, @selector(setState:));
    bindte(FPFuelStationTagZip, @selector(setZip:));
    UITableView *coordinatesTableView =
      (UITableView *)[panel viewWithTag:FPFuelStationTagLocationCoordinates];
    FPFuelStationCoordinatesTableDataSource *ds =
      [coordinatesTableView dataSource];
    [fuelStation setLatitude:[ds latitude]];
    [fuelStation setLongitude:[ds longitude]];
    FPFuelstationTypeDsDelegate *fsTypeDs = (FPFuelstationTypeDsDelegate *)[(UITableView *)[panel viewWithTag:FPFuelStationTagType] dataSource];
    [fuelStation setType:fsTypeDs.selectedFsType];
  };
}

- (PEEntityToPanelBinderBlk)fuelstationToFuelstationPanelBinder {
  return ^ void (FPFuelStation *fuelStation, UIView *panel) {
    void (^bindtt)(NSInteger, SEL) = ^ (NSInteger tag, SEL sel) {
      [PEUIUtils bindToTextControlWithTag:tag
                                 fromView:panel
                               fromEntity:fuelStation
                               withGetter:sel];
    };
    bindtt(FPFuelStationTagName, @selector(name));
    bindtt(FPFuelStationTagStreet, @selector(street));
    bindtt(FPFuelStationTagCity, @selector(city));
    bindtt(FPFuelStationTagState, @selector(state));
    bindtt(FPFuelStationTagZip, @selector(zip));
    UITableView *coordinatesTableView =
      (UITableView *)[panel viewWithTag:FPFuelStationTagLocationCoordinates];
    FPFuelStationCoordinatesTableDataSource *dataSource =
      (FPFuelStationCoordinatesTableDataSource *)[coordinatesTableView dataSource];
    [dataSource setLatitude:[fuelStation latitude]];
    [dataSource setLongitude:[fuelStation longitude]];
    [coordinatesTableView reloadData];
    UITableView *fsTypeTableView = (UITableView *)[panel viewWithTag:FPFuelStationTagType];
    FPFuelstationTypeDsDelegate *fsTypeDs = (FPFuelstationTypeDsDelegate *)[fsTypeTableView dataSource];
    [fsTypeDs setSelectedFsType:fuelStation.type];
    [fsTypeTableView reloadData];
  };
}

- (PEEnableDisablePanelBlk)fuelstationFormPanelEnablerDisabler {
  return ^ (UIView *panel, BOOL enable) {
    void (^enabDisab)(NSInteger) = ^(NSInteger tag) {
      [PEUIUtils enableControlWithTag:tag
                             fromView:panel
                               enable:enable];
    };
    enabDisab(FPFuelStationTagName);
    enabDisab(FPFuelStationTagStreet);
    enabDisab(FPFuelStationTagCity);
    enabDisab(FPFuelStationTagState);
    enabDisab(FPFuelStationTagZip);
    enabDisab(FPFuelStationTagUseCurrentLocation);
    enabDisab(FPFuelStationTagRecomputeCoordinates);
    UITableView *fsTypeTableView = (UITableView *)[panel viewWithTag:FPFuelStationTagType];
    [fsTypeTableView setUserInteractionEnabled:enable];
  };
}

- (PEEntityMakerBlk)fuelstationMaker {
  return ^ PELMModelSupport * (UIView *panel) {
    NSString *(^tfstr)(NSInteger) = ^ NSString * (NSInteger tag) {
      return [PEUIUtils stringFromTextFieldWithTag:tag fromView:panel];
    };
    UITableView *coordinatesTableView =
      (UITableView *)[panel viewWithTag:FPFuelStationTagLocationCoordinates];
    FPFuelStationCoordinatesTableDataSource *ds =
      [coordinatesTableView dataSource];
    FPFuelStation *newFuelstation = [_coordDao fuelStationWithName:tfstr(FPFuelStationTagName)
                                                              type:[[FPFuelStationType alloc] initWithIdentifier:@(0) name:@"Other" iconImgName:@""]
                                                            street:tfstr(FPFuelStationTagStreet)
                                                              city:tfstr(FPFuelStationTagCity)
                                                             state:tfstr(FPFuelStationTagState)
                                                               zip:tfstr(FPFuelStationTagZip)
                                                          latitude:[ds latitude]
                                                         longitude:[ds longitude]];
    return newFuelstation;
  };
}

#pragma mark - Fuel Purchase / Environment Log Composite Panel (Add only)

- (PEEntityPanelMakerBlk)fpEnvLogCompositeFormPanelMakerWithUser:(FPUser *)user
                                                  defaultVehicle:(FPVehicle *)defaultVehicle
                                              defaultFuelstation:(FPFuelStation *)defaultFuelstation
                                                         logDate:(NSDate *)logDate {
  return ^ UIView * (PEAddViewEditController *parentViewController) {
    UIView *parentView = [parentViewController view];
    FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds =
    (FPFpLogVehicleFuelStationDateDataSourceAndDelegate *)[(UITableView *)[parentView viewWithTag:FPFpLogTagVehicleFuelStationAndDate] dataSource];
    FPVehicle *vehicle = defaultVehicle;
    FPFuelStation *fuelstation = defaultFuelstation;
    if (ds) {
      vehicle = [ds selectedVehicle];
      fuelstation = [ds selectedFuelStation];
    }
    UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:parentView fixedHeight:0.0];
    TaggedTextfieldMaker tfMaker = [_uitoolkit taggedTextfieldMakerForWidthOf:1.0 relativeTo:contentPanel];
    NSDictionary *envlogComponents = [self envlogFormComponentsWithUser:user
                                            displayDisclosureIndicators:YES
                                                                vehicle:vehicle
                                                                logDate:logDate](parentViewController);
    UITextField *odometerTf = envlogComponents[@(FPEnvLogTagOdometer)];
    NSDictionary *fplogComponents = [self fplogFormComponentsWithUser:user
                                           displayDisclosureIndicator:YES
                                                              vehicle:vehicle
                                                          fuelstation:fuelstation
                                                              logDate:logDate](parentViewController);
    UITableView *vehicleFuelStationDateTableView = fplogComponents[@(FPFpLogTagVehicleFuelStationAndDate)];
    UITextField *numGallonsTf = fplogComponents[@(FPFpLogTagNumGallons)];
    UITextField *pricePerGallonTf = fplogComponents[@(FPFpLogTagPricePerGallon)];
    UITextField *carWashPerGallonDiscountTf = fplogComponents[@(FPFpLogTagCarWashPerGallonDiscount)];
    UIView *gotCarWashPanel = fplogComponents[@(FPFpLogTagCarWashPanel)];
    [PEUIUtils placeView:vehicleFuelStationDateTableView
                 atTopOf:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0.0];
    CGFloat totalHeight = vehicleFuelStationDateTableView.frame.size.height;
    UIView *aboveView;
    CGFloat aboveViewPadding;
    if (vehicle.isDiesel) {
      aboveView = vehicleFuelStationDateTableView;
      aboveViewPadding = FPContentPanelTopPadding;
    } else {
      UITextField *octaneTf = fplogComponents[@(FPFpLogTagOctane)];
      [PEUIUtils placeView:octaneTf
                     below:vehicleFuelStationDateTableView
                      onto:contentPanel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:FPContentPanelTopPadding
                  hpadding:0.0];
      totalHeight += octaneTf.frame.size.height + FPContentPanelTopPadding;
      NSNumber *defaultOctane = [vehicle defaultOctane];
      if (![PEUtils isNil:defaultOctane]) {
        [octaneTf setText:[defaultOctane description]];
      }
      aboveView = octaneTf;
      aboveViewPadding = 5.0;
    }
    if (vehicle.hasDteReadout) {
      UITextField *preFillupReportedDteTf = tfMaker(@"Pre-fillup range readout", FPFpEnvLogCompositeTagPreFillupReportedDte);
      [preFillupReportedDteTf setKeyboardType:UIKeyboardTypeNumberPad];
      [PEUIUtils placeView:preFillupReportedDteTf
                     below:aboveView
                      onto:contentPanel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:aboveViewPadding
                  hpadding:0.0];
      aboveViewPadding = 5.0;
      totalHeight += preFillupReportedDteTf.frame.size.height + aboveViewPadding;
      aboveView = preFillupReportedDteTf;
    }
    if (vehicle.hasMpgReadout) {
      UITextField *reportedAvgMpgTf = envlogComponents[@(FPEnvLogTagReportedAvgMpg)];
      [PEUIUtils placeView:reportedAvgMpgTf
                     below:aboveView
                      onto:contentPanel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:aboveViewPadding
                  hpadding:0.0];
      aboveViewPadding = 5.0;
      totalHeight += reportedAvgMpgTf.frame.size.height + aboveViewPadding;
      aboveView = reportedAvgMpgTf;
    }
    if (vehicle.hasMphReadout) {
      UITextField *reportedAvgMphTf = envlogComponents[@(FPEnvLogTagReportedAvgMph)];
      [PEUIUtils placeView:reportedAvgMphTf
                     below:aboveView
                      onto:contentPanel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:aboveViewPadding
                  hpadding:0.0];
      totalHeight += reportedAvgMphTf.frame.size.height + aboveViewPadding;
      aboveViewPadding = 5.0;
      aboveView = reportedAvgMphTf;
    }
    [PEUIUtils placeView:odometerTf
                   below:aboveView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:aboveViewPadding
                hpadding:0.0];
    totalHeight += odometerTf.frame.size.height + aboveViewPadding;
    aboveView = odometerTf;
    if (vehicle.hasOutsideTempReadout) {
      UITextField *reportedOutsideTempTf = envlogComponents[@(FPEnvLogTagReportedOutsideTemp)];
      [PEUIUtils placeView:reportedOutsideTempTf
                     below:odometerTf
                      onto:contentPanel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:aboveViewPadding
                  hpadding:0.0];
      totalHeight += reportedOutsideTempTf.frame.size.height + aboveViewPadding;
      aboveViewPadding = 5.0;
      aboveView = reportedOutsideTempTf;
    }
    [PEUIUtils placeView:pricePerGallonTf
                   below:aboveView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:aboveViewPadding
                hpadding:0.0];
    totalHeight += pricePerGallonTf.frame.size.height + aboveViewPadding;
    aboveViewPadding = 5.0;
    [PEUIUtils placeView:carWashPerGallonDiscountTf
                   below:pricePerGallonTf
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:aboveViewPadding
                hpadding:0.0];
    totalHeight += carWashPerGallonDiscountTf.frame.size.height + aboveViewPadding;
    aboveViewPadding = 5.0;
    [PEUIUtils placeView:gotCarWashPanel
                   below:carWashPerGallonDiscountTf
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:aboveViewPadding
                hpadding:0.0];
    totalHeight += gotCarWashPanel.frame.size.height + aboveViewPadding;
    [PEUIUtils placeView:numGallonsTf
                   below:gotCarWashPanel
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:aboveViewPadding
                hpadding:0.0];
    totalHeight += numGallonsTf.frame.size.height + aboveViewPadding;
    if (vehicle.hasDteReadout) {
      UITextField *postFillupReportedDteTf = tfMaker(@"Post-fillup range readout", FPFpEnvLogCompositeTagPostFillupReportedDte);
      [postFillupReportedDteTf setKeyboardType:UIKeyboardTypeNumberPad];
      [PEUIUtils placeView:postFillupReportedDteTf
                     below:numGallonsTf
                      onto:contentPanel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:aboveViewPadding
                  hpadding:0.0];
      totalHeight += postFillupReportedDteTf.frame.size.height + aboveViewPadding;
    }
    [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
    return [PEUIUtils displayPanelFromContentPanel:contentPanel
                                         scrolling:YES
                               scrollContentOffset:[parentViewController scrollContentOffset]
                                    scrollDelegate:parentViewController
                              delaysContentTouches:YES
                                           bounces:YES
                                  notScrollViewBlk:^{ [parentViewController resetScrollOffset]; }
                                          centered:NO
                                        controller:parentViewController];
  };
}

- (PEPanelToEntityBinderBlk)fpEnvLogCompositeFormPanelToFpEnvLogCompositeBinder {
  PEPanelToEntityBinderBlk fpLogPanelToEntityBinder = [self fplogFormPanelToFplogBinder];
  return ^ void (UIView *panel, FPLogEnvLogComposite *fpEnvLogComposite) {
    fpLogPanelToEntityBinder(panel, [fpEnvLogComposite fpLog]);
    void (^binddecToEnvLogs)(NSInteger, SEL) = ^(NSInteger tag, SEL sel) {
      [PEUIUtils bindToEntity:[fpEnvLogComposite preFillupEnvLog]
            withDecimalSetter:sel
         fromTextfieldWithTag:tag
                     fromView:panel];
      [PEUIUtils bindToEntity:[fpEnvLogComposite postFillupEnvLog]
            withDecimalSetter:sel
         fromTextfieldWithTag:tag
                     fromView:panel];
    };
    void (^bindnumToEnvLogs)(NSInteger, SEL) = ^(NSInteger tag, SEL sel) {
      [PEUIUtils bindToEntity:[fpEnvLogComposite preFillupEnvLog]
             withNumberSetter:sel
         fromTextfieldWithTag:tag
                     fromView:panel];
      [PEUIUtils bindToEntity:[fpEnvLogComposite postFillupEnvLog]
             withNumberSetter:sel
         fromTextfieldWithTag:tag
                     fromView:panel];
    };
    binddecToEnvLogs(FPEnvLogTagOdometer, @selector(setOdometer:));
    [PEUIUtils bindToEntity:[fpEnvLogComposite preFillupEnvLog]
          withDecimalSetter:@selector(setReportedDte:)
       fromTextfieldWithTag:FPFpEnvLogCompositeTagPreFillupReportedDte
                   fromView:panel];
    [PEUIUtils bindToEntity:[fpEnvLogComposite postFillupEnvLog]
          withDecimalSetter:@selector(setReportedDte:)
       fromTextfieldWithTag:FPFpEnvLogCompositeTagPostFillupReportedDte
                   fromView:panel];
    binddecToEnvLogs(FPEnvLogTagReportedAvgMpg, @selector(setReportedAvgMpg:));
    binddecToEnvLogs(FPEnvLogTagReportedAvgMph, @selector(setReportedAvgMph:));
    bindnumToEnvLogs(FPEnvLogTagReportedOutsideTemp, @selector(setReportedOutsideTemp:));
    [[fpEnvLogComposite preFillupEnvLog] setLogDate:[[fpEnvLogComposite fpLog] purchasedAt]];
    [[fpEnvLogComposite postFillupEnvLog] setLogDate:[[fpEnvLogComposite fpLog] purchasedAt]];
  };
}

- (PEEntityToPanelBinderBlk)fpEnvLogCompositeToFpEnvLogCompositePanelBinder {
  PEEntityToPanelBinderBlk fpLogToPanelBinder = [self fplogToFplogPanelBinder];
  return ^ void (FPLogEnvLogComposite *fpEnvLogComposite, UIView *panel) {
    fpLogToPanelBinder([fpEnvLogComposite fpLog], panel);
    void (^bindtt)(NSInteger, SEL) = ^ (NSInteger tag, SEL sel) {
     [PEUIUtils bindToTextControlWithTag:tag
                                fromView:panel
                              fromEntity:[fpEnvLogComposite preFillupEnvLog] // either envLog instance will do here
                              withGetter:sel];
    };
    bindtt(FPEnvLogTagOdometer, @selector(odometer));
    bindtt(FPEnvLogTagReportedAvgMpg, @selector(reportedAvgMpg));
    bindtt(FPEnvLogTagReportedAvgMph, @selector(reportedAvgMph));
    bindtt(FPEnvLogTagReportedOutsideTemp, @selector(reportedOutsideTemp));
    [PEUIUtils bindToTextControlWithTag:FPFpEnvLogCompositeTagPreFillupReportedDte
                               fromView:panel
                             fromEntity:[fpEnvLogComposite preFillupEnvLog]
                             withGetter:@selector(reportedDte)];
    [PEUIUtils bindToTextControlWithTag:FPFpEnvLogCompositeTagPostFillupReportedDte
                               fromView:panel
                             fromEntity:[fpEnvLogComposite postFillupEnvLog]
                             withGetter:@selector(reportedDte)];
  };
}

- (PEEntityMakerBlk)fpEnvLogCompositeMaker {
  return ^ FPLogEnvLogComposite * (UIView *panel) {
    NSNumber *(^tfnum)(NSInteger) = ^ NSNumber * (NSInteger tag) {
      return [PEUIUtils numberFromTextFieldWithTag:tag fromView:panel];
    };
    NSDecimalNumber *(^tfdec)(NSInteger) = ^ NSDecimalNumber * (NSInteger tag) {
      return [PEUIUtils decimalNumberFromTextFieldWithTag:tag fromView:panel];
    };
    UISwitch *gotCarWashSwitch = (UISwitch *)[panel viewWithTag:FPFpLogTagGotCarWash];
    UITableView *vehicleFuelStationDateTableView =
      (UITableView *)[panel viewWithTag:FPFpLogTagVehicleFuelStationAndDate];
    FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds =
      (FPFpLogVehicleFuelStationDateDataSourceAndDelegate *)[vehicleFuelStationDateTableView dataSource];
    FPVehicle *vehicle = [ds selectedVehicle];
    NSNumber *octane = nil;
    if (![vehicle isDiesel]) {
      octane = tfnum(FPFpLogTagOctane);
    }
    FPLogEnvLogComposite *composite = [[FPLogEnvLogComposite alloc] initWithNumGallons:tfdec(FPFpLogTagNumGallons)
                                                                              isDiesel:[vehicle isDiesel]
                                                                                octane:octane
                                                                           gallonPrice:tfdec(FPFpLogTagPricePerGallon)
                                                                            gotCarWash:[gotCarWashSwitch isOn]
                                                              carWashPerGallonDiscount:tfdec(FPFpLogTagCarWashPerGallonDiscount)
                                                                              odometer:tfdec(FPEnvLogTagOdometer)
                                                                        reportedAvgMpg:tfdec(FPEnvLogTagReportedAvgMpg)
                                                                        reportedAvgMph:tfdec(FPEnvLogTagReportedAvgMph)
                                                                   reportedOutsideTemp:tfnum(FPEnvLogTagReportedOutsideTemp)
                                                                  preFillupReportedDte:tfnum(FPFpEnvLogCompositeTagPreFillupReportedDte)
                                                                 postFillupReportedDte:tfnum(FPFpEnvLogCompositeTagPostFillupReportedDte)
                                                                               logDate:[ds pickedLogDate]
                                                                              coordDao:_coordDao];
    return composite;
  };
}

#pragma mark - Fuel Purchase Log

- (PEEntityViewPanelMakerBlk)fplogViewPanelMakerWithUser:(FPUser *)user {
  return ^ UIView * (PEAddViewEditController *parentViewController, FPUser *user, FPFuelPurchaseLog *fplog) {
    UIView *parentView = [parentViewController view];
    UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:parentView fixedHeight:0.0];
    NSMutableArray *rowData = [NSMutableArray array];
    if (![fplog isDiesel]) {
      [rowData addObject:@[@"Octane", [PEUtils descriptionOrEmptyIfNil:[fplog octane]]]];
    }
    [rowData addObjectsFromArray:@[@[@"Odometer", [PEUtils descriptionOrEmptyIfNil:[fplog odometer]]],
                                   @[@"Price per gallon", [PEUtils descriptionOrEmptyIfNil:[fplog gallonPrice]]],
                                   @[@"Got car wash?", [PEUtils yesNoFromBool:[fplog gotCarWash]]]]];
    if (![PEUtils isNil:[fplog carWashPerGallonDiscount]]) {
      [rowData addObject:@[@"Car wash gal. discount", [PEUtils descriptionOrEmptyIfNil:[fplog carWashPerGallonDiscount]]]];
    }
    [rowData addObject:@[@"Num gallons", [PEUtils descriptionOrEmptyIfNil:[fplog numGallons]]]];
    UIView *fplogDataPanel = [self tablePanelWithRowData:rowData
                                               uitoolkit:_uitoolkit
                                              parentView:parentView];
    FPVehicle *vehicle = [_coordDao vehicleForFuelPurchaseLog:fplog error:[FPUtils localFetchErrorHandlerMaker]()];
    FPFuelStation *fuelstation = [_coordDao fuelStationForFuelPurchaseLog:fplog error:[FPUtils localFetchErrorHandlerMaker]()];
    NSDictionary *components = [self fplogFormComponentsWithUser:user
                                      displayDisclosureIndicator:NO
                                                         vehicle:vehicle
                                                     fuelstation:fuelstation
                                                         logDate:[fplog purchasedAt]](parentViewController);
    UITableView *vehicleFuelStationDateTableView = components[@(FPFpLogTagVehicleFuelStationAndDate)];
    FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds = (FPFpLogVehicleFuelStationDateDataSourceAndDelegate *)vehicleFuelStationDateTableView.dataSource;
    [ds setSelectedFuelStation:fuelstation];
    [ds setSelectedVehicle:vehicle];
    [vehicleFuelStationDateTableView setUserInteractionEnabled:NO];
    [PEUIUtils placeView:vehicleFuelStationDateTableView
                 atTopOf:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0.0];
    CGFloat totalHeight = vehicleFuelStationDateTableView.frame.size.height;
    [PEUIUtils placeView:fplogDataPanel
                   below:vehicleFuelStationDateTableView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:FPContentPanelTopPadding
                hpadding:0.0];
    totalHeight += fplogDataPanel.frame.size.height + FPContentPanelTopPadding;
    [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
    return [PEUIUtils displayPanelFromContentPanel:contentPanel
                                         scrolling:YES
                               scrollContentOffset:[parentViewController scrollContentOffset]
                                    scrollDelegate:parentViewController
                              delaysContentTouches:YES
                                           bounces:YES
                                  notScrollViewBlk:^{ [parentViewController resetScrollOffset]; }
                                          centered:NO
                                        controller:parentViewController];
  };
}

- (PEComponentsMakerBlk)fplogFormComponentsWithUser:(FPUser *)user
                         displayDisclosureIndicator:(BOOL)displayDisclosureIndicator
                                            vehicle:(FPVehicle *)vehicle
                                        fuelstation:(FPFuelStation *)fuelstation
                                            logDate:(NSDate *)logDate {
  return ^ NSDictionary * (UIViewController *parentViewController) {
    NSMutableDictionary *components = [NSMutableDictionary dictionary];
    UIView *parentView = [parentViewController view];
    UITableView *vehicleFuelStationDateTableView = (UITableView *)[parentView viewWithTag:FPFpLogTagVehicleFuelStationAndDate];
    if (!vehicleFuelStationDateTableView) {
      vehicleFuelStationDateTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 0, 0) style:UITableViewStyleGrouped];
      [vehicleFuelStationDateTableView setScrollEnabled:NO];
      [vehicleFuelStationDateTableView setTag:FPFpLogTagVehicleFuelStationAndDate];
      [PEUIUtils setFrameWidthOfView:vehicleFuelStationDateTableView ofWidth:1.0 relativeTo:parentView];
      [PEUIUtils setFrameHeight:((3 * [PEUIUtils sizeOfText:@"" withFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleBody]].height) + 130)
                         ofView:vehicleFuelStationDateTableView];
      vehicleFuelStationDateTableView.sectionHeaderHeight = 2.0;
      vehicleFuelStationDateTableView.sectionFooterHeight = 2.0;
      PEItemSelectedAction vehicleSelectedAction = ^(FPVehicle *vehicle, NSIndexPath *indexPath, UIViewController *vehicleSelectionController) {
        [[vehicleSelectionController navigationController] popViewControllerAnimated:YES];
        [vehicleFuelStationDateTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] // 'Vehicle' is col-index 0
                                               withRowAnimation:UITableViewRowAnimationAutomatic];
      };
      PEItemSelectedAction fuelStationSelectedAction = ^(FPFuelStation *fuelStation, NSIndexPath *indexPath, UIViewController *fuelStationSelectionController) {
        [[fuelStationSelectionController navigationController] popViewControllerAnimated:YES];
        [vehicleFuelStationDateTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] // 'Fuel Station' is col-index 1
                                               withRowAnimation:UITableViewRowAnimationAutomatic];
      };
      void (^logDatePickedAction)(NSDate *) = ^(NSDate *logDate) {
        [vehicleFuelStationDateTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:2]] // 'Log Date' is col-index 2
                                               withRowAnimation:UITableViewRowAnimationAutomatic];
      };
      FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds =
      [[FPFpLogVehicleFuelStationDateDataSourceAndDelegate alloc] initWithControllerCtx:parentViewController
                                                                                vehicle:vehicle
                                                                            fuelstation:fuelstation
                                                                                logDate:logDate
                                                                  vehicleSelectedAction:vehicleSelectedAction
                                                              fuelStationSelectedAction:fuelStationSelectedAction
                                                                    logDatePickedAction:logDatePickedAction
                                                            displayDisclosureIndicators:displayDisclosureIndicator
                                                                         coordinatorDao:_coordDao
                                                                                   user:user
                                                                          screenToolkit:_screenToolkit
                                                                                  error:_errorBlk];
      [_tableViewDataSources addObject:ds];
      [vehicleFuelStationDateTableView setDataSource:ds];
      [vehicleFuelStationDateTableView setDelegate:ds];
    }
    components[@(FPFpLogTagVehicleFuelStationAndDate)] = vehicleFuelStationDateTableView;
    TaggedTextfieldMaker tfMaker = [_uitoolkit taggedTextfieldMakerForWidthOf:1.0 relativeTo:parentView];
    UITextField *numGallonsTf = (UITextField *)[parentView viewWithTag:FPFpLogTagNumGallons];
    if (!numGallonsTf) {
      numGallonsTf = tfMaker(@"Num gallons", FPFpLogTagNumGallons);
      [numGallonsTf setKeyboardType:UIKeyboardTypeDecimalPad];
    }
    components[@(FPFpLogTagNumGallons)] = numGallonsTf;
    UITextField *pricePerGallonTf = (UITextField *)[parentView viewWithTag:FPFpLogTagPricePerGallon];
    if (!pricePerGallonTf) {
      pricePerGallonTf = tfMaker(@"Price per gallon", FPFpLogTagPricePerGallon);
      [pricePerGallonTf setKeyboardType:UIKeyboardTypeDecimalPad];
    }
    components[@(FPFpLogTagPricePerGallon)] = pricePerGallonTf;
    if (vehicle) {
      if (!vehicle.isDiesel) {
        UITextField *octaneTf = (UITextField *)[parentView viewWithTag:FPFpLogTagOctane];
        if (!octaneTf) {
          octaneTf = tfMaker(@"Octane", FPFpLogTagOctane);
        }
        NSNumber *defaultOctane = [vehicle defaultOctane];
        if (![PEUtils isNil:defaultOctane]) {
          [octaneTf setText:[defaultOctane description]];
        } else {
          [octaneTf setText:@""];
        }
        [octaneTf setKeyboardType:UIKeyboardTypeNumberPad];
        components[@(FPFpLogTagOctane)] = octaneTf;
      }
    } else {
      UITextField *octaneTf = (UITextField *)[parentView viewWithTag:FPFpLogTagOctane];
      if (!octaneTf) {
        octaneTf = tfMaker(@"Octane", FPFpLogTagOctane);
      }
      [octaneTf setKeyboardType:UIKeyboardTypeNumberPad];
      components[@(FPFpLogTagOctane)] = octaneTf;
    }
    UITextField *odometerTf = (UITextField *)[parentView viewWithTag:FPFplogTagOdometer];
    if (!odometerTf) {
      odometerTf = tfMaker(@"Odometer", FPFplogTagOdometer);
      [odometerTf setKeyboardType:UIKeyboardTypeNumberPad];
    }
    components[@(FPFplogTagOdometer)] = odometerTf;
    UITextField *carWashPerGallonDiscountTf = (UITextField *)[parentView viewWithTag:FPFpLogTagCarWashPerGallonDiscount];
    if (!carWashPerGallonDiscountTf) {
      carWashPerGallonDiscountTf = tfMaker(@"Car was per-gallon discount", FPFpLogTagCarWashPerGallonDiscount);
      [carWashPerGallonDiscountTf setKeyboardType:UIKeyboardTypeDecimalPad];
    }
    components[@(FPFpLogTagCarWashPerGallonDiscount)] = carWashPerGallonDiscountTf;
    UISwitch *gotCarWashSwitch = (UISwitch *)[parentView viewWithTag:FPFpLogTagGotCarWash];
    UIView *gotCarWashPanel = (UIView *)[parentView viewWithTag:FPFpLogTagCarWashPanel];
    if (!gotCarWashSwitch) {
      gotCarWashSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
      [gotCarWashSwitch setTag:FPFpLogTagGotCarWash];
      gotCarWashPanel = [PEUIUtils panelWithWidthOf:1.0
                                     relativeToView:parentView
                                        fixedHeight:numGallonsTf.frame.size.height];
      [gotCarWashPanel setTag:FPFpLogTagCarWashPanel];
      [gotCarWashPanel setBackgroundColor:[UIColor whiteColor]];
      UILabel *gotCarWashLbl = [PEUIUtils labelWithKey:@"Got car wash?"
                                                  font:[numGallonsTf font]
                                       backgroundColor:[UIColor clearColor]
                                             textColor:[_uitoolkit colorForTableCellTitles]
                                   verticalTextPadding:3.0];
      [PEUIUtils placeView:gotCarWashLbl
                inMiddleOf:gotCarWashPanel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  hpadding:10.0];
      [PEUIUtils placeView:gotCarWashSwitch
                inMiddleOf:gotCarWashPanel
             withAlignment:PEUIHorizontalAlignmentTypeRight
                  hpadding:15.0];
    }
    components[@(FPFpLogTagGotCarWash)] = gotCarWashSwitch;
    components[@(FPFpLogTagCarWashPanel)] = gotCarWashPanel;
    return components;
  };
}

- (PEEntityPanelMakerBlk)fplogFormPanelMakerWithUser:(FPUser *)user
                                   defaultVehicleBlk:(FPVehicle *(^)(void))defaultVehicleBlk
                               defaultFuelstationBlk:(FPFuelStation *(^)(void))defaultFuelstationBlk
                                             logDate:(NSDate *)logDate {
  return ^ UIView * (PEAddViewEditController *parentViewController) {
    UIView *parentView = [parentViewController view];
    FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds =
    (FPFpLogVehicleFuelStationDateDataSourceAndDelegate *)[(UITableView *)[parentView viewWithTag:FPFpLogTagVehicleFuelStationAndDate] dataSource];
    FPVehicle *vehicle;
    FPFuelStation *fuelstation;
    if (ds) {
      vehicle = [ds selectedVehicle];
      fuelstation = [ds selectedFuelStation];
    } else {
      vehicle = defaultVehicleBlk();
      fuelstation = defaultFuelstationBlk();
    }
    UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:parentView fixedHeight:0.0];
    NSDictionary *components = [self fplogFormComponentsWithUser:user
                                      displayDisclosureIndicator:YES
                                                         vehicle:vehicle
                                                     fuelstation:fuelstation
                                                         logDate:logDate](parentViewController);
    UITableView *vehicleFuelStationDateTableView = components[@(FPFpLogTagVehicleFuelStationAndDate)];
    UITextField *numGallonsTf = components[@(FPFpLogTagNumGallons)];
    UITextField *pricePerGallonTf = components[@(FPFpLogTagPricePerGallon)];
    UITextField *odometerTf = components[@(FPFplogTagOdometer)];
    UITextField *carWashPerGallonDiscountTf = components[@(FPFpLogTagCarWashPerGallonDiscount)];
    UIView *gotCarWashPanel = components[@(FPFpLogTagCarWashPanel)];
    [PEUIUtils placeView:vehicleFuelStationDateTableView
                 atTopOf:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0.0];
    CGFloat totalHeight = vehicleFuelStationDateTableView.frame.size.height;
    UIView *aboveView;
    CGFloat aboveViewPadding;
    if (vehicle.isDiesel) {
      aboveView = vehicleFuelStationDateTableView;
      aboveViewPadding = FPContentPanelTopPadding;
    } else {
      UITextField *octaneTf = components[@(FPFpLogTagOctane)];
      [PEUIUtils placeView:octaneTf
                     below:vehicleFuelStationDateTableView
                      onto:contentPanel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:FPContentPanelTopPadding
                  hpadding:0.0];
      totalHeight += octaneTf.frame.size.height + FPContentPanelTopPadding;
      aboveView = octaneTf;
      aboveViewPadding = 5.0;
    }
    [PEUIUtils placeView:odometerTf
                   below:aboveView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:aboveViewPadding
                hpadding:0.0];
    totalHeight += odometerTf.frame.size.height + aboveViewPadding;
    [PEUIUtils placeView:pricePerGallonTf
                   below:odometerTf
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    totalHeight += pricePerGallonTf.frame.size.height + 5.0;
    [PEUIUtils placeView:gotCarWashPanel
                   below:pricePerGallonTf
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    totalHeight += gotCarWashPanel.frame.size.height + 5.0;
    [PEUIUtils placeView:carWashPerGallonDiscountTf
                   below:gotCarWashPanel
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    totalHeight += carWashPerGallonDiscountTf.frame.size.height + 5.0;
    [PEUIUtils placeView:numGallonsTf
                   below:carWashPerGallonDiscountTf
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    totalHeight += numGallonsTf.frame.size.height + 5.0;
    [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
    return [PEUIUtils displayPanelFromContentPanel:contentPanel
                                         scrolling:YES
                               scrollContentOffset:[parentViewController scrollContentOffset]
                                    scrollDelegate:parentViewController
                              delaysContentTouches:YES
                                           bounces:YES
                                  notScrollViewBlk:^{ [parentViewController resetScrollOffset]; }
                                          centered:NO
                                        controller:parentViewController];
  };
}

- (PEPanelToEntityBinderBlk)fplogFormPanelToFplogBinder {
  return ^ void (UIView *panel, FPFuelPurchaseLog *fpLog) {
    void (^binddec)(NSInteger, SEL) = ^(NSInteger tag, SEL sel) {
      [PEUIUtils bindToEntity:fpLog
            withDecimalSetter:sel
         fromTextfieldWithTag:tag
                     fromView:panel];
    };
    void (^bindnum)(NSInteger, SEL) = ^(NSInteger tag, SEL sel) {
      [PEUIUtils bindToEntity:fpLog
             withNumberSetter:sel
         fromTextfieldWithTag:tag
                     fromView:panel];
    };
    binddec(FPFpLogTagNumGallons, @selector(setNumGallons:));
    binddec(FPFpLogTagPricePerGallon, @selector(setGallonPrice:));
    binddec(FPFplogTagOdometer, @selector(setOdometer:));
    binddec(FPFpLogTagCarWashPerGallonDiscount, @selector(setCarWashPerGallonDiscount:));
    UISwitch *gotCarWasSwitch = (UISwitch *)[panel viewWithTag:FPFpLogTagGotCarWash];
    [fpLog setGotCarWash:[gotCarWasSwitch isOn]];
    UITableView *vehicleFuelStationDateTableView =
      (UITableView *)[panel viewWithTag:FPFpLogTagVehicleFuelStationAndDate];
    FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds =
      (FPFpLogVehicleFuelStationDateDataSourceAndDelegate *)[vehicleFuelStationDateTableView dataSource];
    [fpLog setPurchasedAt:[ds pickedLogDate]];
    FPVehicle *vehicle = [ds selectedVehicle];
    [fpLog setIsDiesel:[vehicle isDiesel]];
    if ([fpLog isDiesel]) {
      [fpLog setOctane:nil];
    } else {
      bindnum(FPFpLogTagOctane, @selector(setOctane:));
    }
  };
}

- (PEEntityToPanelBinderBlk)fplogToFplogPanelBinder {
  return ^ void (FPFuelPurchaseLog *fpLog, UIView *panel) {
    if (fpLog) {
      void (^bindtt)(NSInteger, SEL) = ^ (NSInteger tag, SEL sel) {
        [PEUIUtils bindToTextControlWithTag:tag
                                   fromView:panel
                                 fromEntity:fpLog
                                 withGetter:sel];
      };
      bindtt(FPFpLogTagNumGallons, @selector(numGallons));
      bindtt(FPFpLogTagPricePerGallon, @selector(gallonPrice));
      bindtt(FPFplogTagOdometer, @selector(odometer));
      bindtt(FPFpLogTagCarWashPerGallonDiscount, @selector(carWashPerGallonDiscount));
      UISwitch *gotCarWashSwitch = (UISwitch *)[panel viewWithTag:FPFpLogTagGotCarWash];
      [gotCarWashSwitch setOn:[fpLog gotCarWash] animated:YES];
      if ([fpLog purchasedAt]) {
        UITableView *vehicleFuelStationDateTableView =
        (UITableView *)[panel viewWithTag:FPFpLogTagVehicleFuelStationAndDate];
        FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds =
        (FPFpLogVehicleFuelStationDateDataSourceAndDelegate *)[vehicleFuelStationDateTableView dataSource];
        [ds setPickedLogDate:[fpLog purchasedAt]];
        [vehicleFuelStationDateTableView reloadData];
      }
      UISwitch *dieselSwitch = (UISwitch *)[panel viewWithTag:FPFpLogTagDieselSwitch];
      [dieselSwitch setOn:[fpLog isDiesel] animated:YES];
      if ([fpLog isDiesel]) {
        //UITextField *octaneTf = [panel viewWithTag:FPFpLogTagOctane];
        //[octaneTf setText:@""];
        //[octaneTf setPlaceholder:FPPanelToolkitFplogOctaneNaPlaceholerText];
      } else {
        bindtt(FPFpLogTagOctane, @selector(octane));
      }
    }
  };
}

- (PEEnableDisablePanelBlk)fplogFormPanelEnablerDisabler {
  return ^ (UIView *panel, BOOL enable) {
    void (^enabDisab)(NSInteger) = ^(NSInteger tag) {
      [PEUIUtils enableControlWithTag:tag
                             fromView:panel
                               enable:enable];
    };
    enabDisab(FPFpLogTagVehicleFuelStationAndDate);
    enabDisab(FPFpLogTagNumGallons);
    enabDisab(FPFpLogTagPricePerGallon);
    enabDisab(FPFpLogTagDieselSwitch);
    enabDisab(FPFpLogTagOctane);
    enabDisab(FPFplogTagOdometer);
    enabDisab(FPFpLogTagCarWashPerGallonDiscount);
    enabDisab(FPFpLogTagGotCarWash);
    UITableView *vehicleFuelStationDateTableView =
      (UITableView *)[panel viewWithTag:FPFpLogTagVehicleFuelStationAndDate];
    [vehicleFuelStationDateTableView setUserInteractionEnabled:enable];
  };
}

#pragma mark - Environment Log

- (PEEntityViewPanelMakerBlk)envlogViewPanelMakerWithUser:(FPUser *)user {
  return ^ UIView * (PEAddViewEditController *parentViewController, FPUser *user, FPEnvironmentLog *envlog) {
    UIView *parentView = [parentViewController view];
    FPVehicle *vehicle = [_coordDao vehicleForEnvironmentLog:envlog error:[FPUtils localFetchErrorHandlerMaker]()];
    UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:parentView fixedHeight:0.0];
    NSMutableArray *rowData = [NSMutableArray array];
    [rowData addObject:@[@"Odometer", [PEUtils descriptionOrEmptyIfNil:[envlog odometer]]]];
    if (vehicle.hasDteReadout) {
      [rowData addObject:@[@"Range readout", [PEUtils descriptionOrEmptyIfNil:[envlog reportedDte]]]];
    }
    if (vehicle.hasMpgReadout) {
      [rowData addObject:@[@"Average MPG readout", [PEUtils descriptionOrEmptyIfNil:[envlog reportedAvgMpg]]]];
    }
    if (vehicle.hasMphReadout) {
      [rowData addObject:@[@"Average MPH readout", [PEUtils descriptionOrEmptyIfNil:[envlog reportedAvgMph]]]];
    }
    if (vehicle.hasOutsideTempReadout) {
      [rowData addObject:@[@"Outside temp. readout", [PEUtils descriptionOrEmptyIfNil:[envlog reportedOutsideTemp]]]];
    }
    UIView *envlogDataPanel = [self tablePanelWithRowData:rowData
                                                uitoolkit:_uitoolkit
                                               parentView:parentView];
    NSDictionary *components = [self envlogFormComponentsWithUser:user
                                      displayDisclosureIndicators:NO
                                                          vehicle:vehicle
                                                          logDate:[envlog logDate]](parentViewController);
    UITableView *vehicleAndLogDateTableView = components[@(FPEnvLogTagVehicleAndDate)];
    [vehicleAndLogDateTableView setUserInteractionEnabled:NO];
    [PEUIUtils placeView:vehicleAndLogDateTableView
                 atTopOf:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0.0];
    CGFloat totalHeight = vehicleAndLogDateTableView.frame.size.height;
    [PEUIUtils placeView:envlogDataPanel
                   below:vehicleAndLogDateTableView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:FPContentPanelTopPadding
                hpadding:0.0];
    totalHeight += envlogDataPanel.frame.size.height + FPContentPanelTopPadding;
    [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
    return [PEUIUtils displayPanelFromContentPanel:contentPanel
                                         scrolling:YES
                               scrollContentOffset:[parentViewController scrollContentOffset]
                                    scrollDelegate:parentViewController
                              delaysContentTouches:YES
                                           bounces:YES
                                  notScrollViewBlk:^{ [parentViewController resetScrollOffset]; }
                                          centered:NO
                                        controller:parentViewController];
  };
}

- (PEComponentsMakerBlk)envlogFormComponentsWithUser:(FPUser *)user
                         displayDisclosureIndicators:(BOOL)displayDisclosureIndicators
                                             vehicle:(FPVehicle *)vehicle
                                             logDate:(NSDate *)logDate {
  return ^ NSDictionary * (UIViewController *parentViewController) {
    NSMutableDictionary *components = [NSMutableDictionary dictionary];
    UIView *parentView = [parentViewController view];
    TaggedTextfieldMaker tfMaker = [_uitoolkit taggedTextfieldMakerForWidthOf:1.0 relativeTo:parentView];
    UITableView *vehicleAndLogDateTableView = (UITableView *)[parentView viewWithTag:FPEnvLogTagVehicleAndDate];
    if (!vehicleAndLogDateTableView) {
      vehicleAndLogDateTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 0, 0) style:UITableViewStyleGrouped];
      [vehicleAndLogDateTableView setScrollEnabled:NO];
      [vehicleAndLogDateTableView setTag:FPEnvLogTagVehicleAndDate];
      [PEUIUtils setFrameWidthOfView:vehicleAndLogDateTableView ofWidth:1.0 relativeTo:parentView];
      [PEUIUtils setFrameHeight:((2 * [PEUIUtils sizeOfText:@"" withFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleBody]].height) + 91) //124.96
                         ofView:vehicleAndLogDateTableView];
      PEItemSelectedAction vehicleSelectedAction = ^(FPVehicle *vehicle, NSIndexPath *indexPath, UIViewController *vehicleSelectionController) {
        [[vehicleSelectionController navigationController] popViewControllerAnimated:YES];
        [vehicleAndLogDateTableView
         reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] // 'Vehicle' is col-index 0
         withRowAnimation:UITableViewRowAnimationAutomatic];
      };
      void (^logDatePickedAction)(NSDate *) = ^(NSDate *logDate) {
        [vehicleAndLogDateTableView
         reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] // 'Log Date' is col-index 1
         withRowAnimation:UITableViewRowAnimationAutomatic];
      };
      FPEnvLogVehicleAndDateDataSourceDelegate *ds =
      [[FPEnvLogVehicleAndDateDataSourceDelegate alloc] initWithControllerCtx:parentViewController
                                                                      vehicle:vehicle
                                                                      logDate:logDate
                                                        vehicleSelectedAction:vehicleSelectedAction
                                                          logDatePickedAction:logDatePickedAction
                                                  displayDisclosureIndicators:displayDisclosureIndicators
                                                               coordinatorDao:_coordDao
                                                                         user:user
                                                                screenToolkit:_screenToolkit
                                                                        error:_errorBlk];
      [_tableViewDataSources addObject:ds];
      vehicleAndLogDateTableView.sectionHeaderHeight = 2.0;
      vehicleAndLogDateTableView.sectionFooterHeight = 2.0;
      [vehicleAndLogDateTableView setDataSource:ds];
      [vehicleAndLogDateTableView setDelegate:ds];
    }
    components[@(FPEnvLogTagVehicleAndDate)] = vehicleAndLogDateTableView;
    UITextField *odometerTf = (UITextField *)[parentView viewWithTag:FPEnvLogTagOdometer];
    if (!odometerTf) {
      odometerTf = tfMaker(@"Odometer", FPEnvLogTagOdometer);
      [odometerTf setKeyboardType:UIKeyboardTypeDecimalPad];
    }
    components[@(FPEnvLogTagOdometer)] = odometerTf;
    if (vehicle.hasDteReadout) {
      UITextField *reportedDteTf = (UITextField *)[parentView viewWithTag:FPEnvLogTagReportedDte];
      if (!reportedDteTf) {
        reportedDteTf = tfMaker(@"Range readout", FPEnvLogTagReportedDte);
        [reportedDteTf setKeyboardType:UIKeyboardTypeNumberPad];
      }
      components[@(FPEnvLogTagReportedDte)] = reportedDteTf;
    }
    if (vehicle.hasMpgReadout) {
      UITextField *reportedAvgMpgTf = (UITextField *)[parentView viewWithTag:FPEnvLogTagReportedAvgMpg];
      if (!reportedAvgMpgTf) {
        reportedAvgMpgTf = tfMaker(@"Average MPG readout", FPEnvLogTagReportedAvgMpg);
        [reportedAvgMpgTf setKeyboardType:UIKeyboardTypeDecimalPad];
      }
      components[@(FPEnvLogTagReportedAvgMpg)] = reportedAvgMpgTf;
    }
    if (vehicle.hasMphReadout) {
      UITextField *reportedAvgMphTf = (UITextField *)[parentView viewWithTag:FPEnvLogTagReportedAvgMph];
      if (!reportedAvgMphTf) {
        reportedAvgMphTf = tfMaker(@"Average MPH readout", FPEnvLogTagReportedAvgMph);
        [reportedAvgMphTf setKeyboardType:UIKeyboardTypeDecimalPad];
      }
      components[@(FPEnvLogTagReportedAvgMph)] = reportedAvgMphTf;
    }
    if (vehicle.hasOutsideTempReadout) {
      UITextField *reportedOutsideTempTf = (UITextField *)[parentView viewWithTag:FPEnvLogTagReportedOutsideTemp];
      if (!reportedOutsideTempTf) {
        reportedOutsideTempTf = tfMaker(@"Outside temperature readout", FPEnvLogTagReportedOutsideTemp);
        [reportedOutsideTempTf setKeyboardType:UIKeyboardTypeNumberPad];
      }
      components[@(FPEnvLogTagReportedOutsideTemp)] = reportedOutsideTempTf;
    }
    return components;
  };
}

- (PEEntityPanelMakerBlk)envlogFormPanelMakerWithUser:(FPUser *)user
                                    defaultVehicleBlk:(FPVehicle *(^)(void))defaultVehicleBlk
                                              logDate:(NSDate *)logDate {
  return ^ UIView * (PEAddViewEditController *parentViewController) {
    UIView *parentView = [parentViewController view];
    FPEnvLogVehicleAndDateDataSourceDelegate *ds =
      (FPEnvLogVehicleAndDateDataSourceDelegate *)[(UITableView *)[parentView viewWithTag:FPEnvLogTagVehicleAndDate] dataSource];
    FPVehicle *vehicle;
    if (ds) {
      vehicle = [ds selectedVehicle];
    } else {
      vehicle = defaultVehicleBlk();
    }
    UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:parentView fixedHeight:0.0];
    NSDictionary *components = [self envlogFormComponentsWithUser:user
                                      displayDisclosureIndicators:YES
                                                          vehicle:vehicle
                                                          logDate:logDate](parentViewController);
    UITableView *vehicleAndLogDateTableView = components[@(FPEnvLogTagVehicleAndDate)];
    UITextField *odometerTf = components[@(FPEnvLogTagOdometer)];
    [PEUIUtils placeView:vehicleAndLogDateTableView
                 atTopOf:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0.0];
    CGFloat totalHeight = vehicleAndLogDateTableView.frame.size.height;
    [PEUIUtils placeView:odometerTf
                   below:vehicleAndLogDateTableView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:FPContentPanelTopPadding
                hpadding:0.0];
    totalHeight += odometerTf.frame.size.height + FPContentPanelTopPadding;
    UIView *aboveView = odometerTf;
    if (vehicle.hasMpgReadout) {
      UITextField *reportedAvgMpgTf = components[@(FPEnvLogTagReportedAvgMpg)];
      [PEUIUtils placeView:reportedAvgMpgTf
                     below:aboveView
                      onto:contentPanel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:5.0
                  hpadding:0.0];
      totalHeight += reportedAvgMpgTf.frame.size.height + 5.0;
      aboveView = reportedAvgMpgTf;
    }
    if (vehicle.hasDteReadout) {
      UITextField *reportedDteTf = components[@(FPEnvLogTagReportedDte)];
      [PEUIUtils placeView:reportedDteTf
                     below:aboveView
                      onto:contentPanel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:5.0
                  hpadding:0.0];
      totalHeight += reportedDteTf.frame.size.height + 5.0;
      aboveView = reportedDteTf;
    }
    if (vehicle.hasMphReadout) {
      UITextField *reportedAvgMphTf = components[@(FPEnvLogTagReportedAvgMph)];
      [PEUIUtils placeView:reportedAvgMphTf
                     below:aboveView
                      onto:contentPanel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:5.0
                  hpadding:0.0];
      totalHeight += reportedAvgMphTf.frame.size.height + 5.0;
      aboveView = reportedAvgMphTf;
    }
    if (vehicle.hasOutsideTempReadout) {
      UITextField *reportedOutsideTempTf = components[@(FPEnvLogTagReportedOutsideTemp)];
      [PEUIUtils placeView:reportedOutsideTempTf
                     below:aboveView
                      onto:contentPanel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:5.0
                  hpadding:0.0];
      totalHeight += reportedOutsideTempTf.frame.size.height + 5.0;
      aboveView = reportedOutsideTempTf;
    }
    [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
    return [PEUIUtils displayPanelFromContentPanel:contentPanel
                                         scrolling:YES
                               scrollContentOffset:[parentViewController scrollContentOffset]
                                    scrollDelegate:parentViewController
                              delaysContentTouches:YES
                                           bounces:YES
                                  notScrollViewBlk:^{ [parentViewController resetScrollOffset]; }
                                          centered:NO
                                        controller:parentViewController];
  };
}

- (PEPanelToEntityBinderBlk)envlogFormPanelToEnvlogBinder {
  return ^ void (UIView *panel, FPEnvironmentLog *envLog) {
    void (^binddec)(NSInteger, SEL) = ^(NSInteger tag, SEL sel) {
      [PEUIUtils bindToEntity:envLog
            withDecimalSetter:sel
         fromTextfieldWithTag:tag
                     fromView:panel];
    };
    void (^bindnum)(NSInteger, SEL) = ^(NSInteger tag, SEL sel) {
      [PEUIUtils bindToEntity:envLog
             withNumberSetter:sel
         fromTextfieldWithTag:tag
                     fromView:panel];
    };
    binddec(FPEnvLogTagOdometer, @selector(setOdometer:));
    binddec(FPEnvLogTagReportedDte, @selector(setReportedDte:));
    binddec(FPEnvLogTagReportedAvgMpg, @selector(setReportedAvgMpg:));
    binddec(FPEnvLogTagReportedAvgMph, @selector(setReportedAvgMph:));
    bindnum(FPEnvLogTagReportedOutsideTemp, @selector(setReportedOutsideTemp:));
    
    UITableView *vehicleAndDateTableView =
      (UITableView *)[panel viewWithTag:FPEnvLogTagVehicleAndDate];
    FPEnvLogVehicleAndDateDataSourceDelegate *ds =
      (FPEnvLogVehicleAndDateDataSourceDelegate *)[vehicleAndDateTableView dataSource];
    [envLog setLogDate:[ds pickedLogDate]];
  };
}

- (PEEntityToPanelBinderBlk)envlogToEnvlogPanelBinder {
  return ^ void (FPEnvironmentLog *envLog, UIView *panel) {
    void (^bindtt)(NSInteger, SEL) = ^ (NSInteger tag, SEL sel) {
      [PEUIUtils bindToTextControlWithTag:tag
                                 fromView:panel
                               fromEntity:envLog
                               withGetter:sel];
    };
    bindtt(FPEnvLogTagOdometer, @selector(odometer));
    bindtt(FPEnvLogTagReportedDte, @selector(reportedDte));
    bindtt(FPEnvLogTagReportedAvgMpg, @selector(reportedAvgMpg));
    bindtt(FPEnvLogTagReportedAvgMph, @selector(reportedAvgMph));
    bindtt(FPEnvLogTagReportedOutsideTemp, @selector(reportedOutsideTemp));
    if ([envLog logDate]) {
      UITableView *vehicleAndDateTableView =
        (UITableView *)[panel viewWithTag:FPEnvLogTagVehicleAndDate];
      FPEnvLogVehicleAndDateDataSourceDelegate *ds =
        (FPEnvLogVehicleAndDateDataSourceDelegate *)[vehicleAndDateTableView dataSource];
      [ds setPickedLogDate:[envLog logDate]];
      [vehicleAndDateTableView reloadData];
    }
    // FYI, we have to do the binding back up the screen toolkit method because
    // we simply don't have access to envlog's associated vehicle; we only have
    // access to the vehicle back in the screnn toolkit context.
  };
}

- (PEEnableDisablePanelBlk)envlogFormPanelEnablerDisabler {
  return ^ (UIView *panel, BOOL enable) {
    void (^enabDisab)(NSInteger) = ^(NSInteger tag) {
      [PEUIUtils enableControlWithTag:tag
                             fromView:panel
                               enable:enable];
    };
    enabDisab(FPEnvLogTagOdometer);
    enabDisab(FPEnvLogTagReportedDte);
    enabDisab(FPEnvLogTagReportedAvgMpg);
    enabDisab(FPEnvLogTagReportedAvgMph);
    enabDisab(FPEnvLogTagReportedOutsideTemp);
    UITableView *vehicleAndDateTableView =
      (UITableView *)[panel viewWithTag:FPEnvLogTagVehicleAndDate];
    [vehicleAndDateTableView setUserInteractionEnabled:enable];
  };
}

- (PEEntityMakerBlk)envlogMaker {
  return ^ PELMModelSupport * (UIView *panel) {
    NSNumber *(^tfnum)(NSInteger) = ^ NSNumber * (NSInteger tag) {
      return [PEUIUtils numberFromTextFieldWithTag:tag fromView:panel];
    };
    NSDecimalNumber *(^tfdec)(NSInteger) = ^ NSDecimalNumber * (NSInteger tag) {
      return [PEUIUtils decimalNumberFromTextFieldWithTag:tag fromView:panel];
    };
    UITableView *vehicleAndDateTableView =
      (UITableView *)[panel viewWithTag:FPEnvLogTagVehicleAndDate];
    FPEnvLogVehicleAndDateDataSourceDelegate *ds =
      (FPEnvLogVehicleAndDateDataSourceDelegate *)[vehicleAndDateTableView dataSource];
    FPEnvironmentLog *envlog = [_coordDao environmentLogWithOdometer:tfdec(FPEnvLogTagOdometer)
                                                      reportedAvgMpg:tfdec(FPEnvLogTagReportedAvgMpg)
                                                      reportedAvgMph:tfdec(FPEnvLogTagReportedAvgMph)
                                                 reportedOutsideTemp:tfnum(FPEnvLogTagReportedOutsideTemp)
                                                             logDate:[ds pickedLogDate]
                                                         reportedDte:tfnum(FPEnvLogTagReportedDte)];
    return envlog;
  };
}

@end
