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

NSString * const FPFpLogEntityMakerFpLogEntry = @"FPFpLogEntityMakerFpLogEntry";
NSString * const FPFpLogEntityMakerVehicleEntry = @"FPFpLogEntityMakerVehicleEntry";
NSString * const FPFpLogEntityMakerFuelStationEntry = @"FPFpLogEntityMakerFuelStationEntry";

@implementation FPPanelToolkit {
  FPCoordinatorDao *_coordDao;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  NSMutableArray *_tableViewDataSources;
  PELMDaoErrorBlk _errorBlk;
  FPStats *_stats;
}

#pragma mark - Initializers

- (id)initWithCoordinatorDao:(FPCoordinatorDao *)coordDao
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
    _stats = [[FPStats alloc] initWithLocalDao:_coordDao.localDao errorBlk:errorBlk];
  }
  return self;
}

#pragma mark - User Account Panel

- (PEEntityViewPanelMakerBlk)userAccountViewPanelMakerWithAccountStatusLabelTag:(NSInteger)accountStatusLabelTag {
  return ^ UIView * (PEAddViewEditController *parentViewController, id nilParent, FPUser *user) {
    UIView *parentView = [parentViewController view];
    UIView *userAccountPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:parentView];
    UIView *userAccountDataPanel = [PEUIUtils tablePanelWithRowData:@[@[@"Name", [PEUtils emptyIfNil:[user name]]],
                                                                      @[@"Email", [PEUtils emptyIfNil:[user email]]]]
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
    TaggedTextfieldMaker tfMaker =
    [_uitoolkit taggedTextfieldMakerForWidthOf:1.0 relativeTo:userAccountPanel];
    UITextField *nameTf = tfMaker(@"Name", FPUserTagName);
    UITextField *emailTf = tfMaker(@"E-mail", FPUserTagEmail);
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
                       coordinatorDao:(FPCoordinatorDao *)coordDao
                            uitoolkit:(PEUIToolkit *)uitoolkit
                       relativeToView:(UIView *)relativeToView
                           controller:(UIViewController *)controller {
  FPEnableUserInteractionBlk enableUserInteraction = [FPUIUtils makeUserEnabledBlockForController:controller];
  NSArray *accountStatusText = [FPPanelToolkit accountStatusTextForUser:user];
  UIView *statusPanel = [PEUIUtils labelValuePanelWithCellHeight:36.75
                                                     labelString:@"Account status"
                                                       labelFont:[uitoolkit fontForTextfields]
                                                  labelTextColor:[UIColor blackColor]
                                               labelLeftHPadding:10.0
                                                     valueString:accountStatusText[0]
                                                       valueFont:[uitoolkit fontForTextfields]
                                                  valueTextColor:accountStatusText[1]
                                              valueRightHPadding:15.0
                                                   valueLabelTag:nil
                                  minPaddingBetweenLabelAndValue:10.0
                                                  relativeToView:relativeToView];
  [statusPanel setBackgroundColor:[UIColor whiteColor]];
  UIView *panel;
  if ([PEUtils isNil:[user verifiedAt]]) {
    UIButton * (^makeSendEmailBtn)(void) = ^ UIButton * {
      UIButton *sendEmailBtn = [PEUIUtils buttonWithKey:@"re-send verification email"
                                                   font:[UIFont systemFontOfSize:14]
                                        backgroundColor:[UIColor concreteColor]
                                              textColor:[UIColor whiteColor]
                           disabledStateBackgroundColor:nil
                                 disabledStateTextColor:nil
                                        verticalPadding:8.5
                                      horizontalPadding:20.0
                                           cornerRadius:5.0
                                                 target:nil
                                                 action:nil];
      [sendEmailBtn bk_addEventHandler:^(id sender) {
        MBProgressHUD *sendVerificationEmailHud = [MBProgressHUD showHUDAddedTo:relativeToView animated:YES];
        enableUserInteraction(NO);
        sendVerificationEmailHud.labelText = @"Sending verification email...";
        [coordDao resendVerificationEmailForUser:user
                              remoteStoreBusyBlk:^(NSDate *retryAfter) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                  [sendVerificationEmailHud hide:YES afterDelay:0.0];
                                  [PEUIUtils showWaitAlertWithMsgs:nil
                                                             title:@"Busy with maintenance."
                                                  alertDescription:[[NSAttributedString alloc] initWithString:@"\
The server is currently busy at the moment undergoing maintenance.\n\n\
We apologize for the inconvenience.  Please try re-sending the verification email later."]
                                                          topInset:70.0
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
                                                          accentTextFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]];
                                   [PEUIUtils showSuccessAlertWithTitle:@"Verification e-mail sent."
                                                       alertDescription:attrMessage
                                                               topInset:70.0
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
                                                                     topInset:70.0
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
                                                 font:[UIFont systemFontOfSize:14]
                                      backgroundColor:[UIColor concreteColor]
                                            textColor:[UIColor whiteColor]
                         disabledStateBackgroundColor:nil
                               disabledStateTextColor:nil
                                      verticalPadding:8.5
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
                                                                         accentTextFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]]
                                         topInset:70.0
                                      buttonTitle:@"Okay."
                                     buttonAction:^{ enableUserInteraction(YES); }
                                   relativeToView:controller.tabBarController.view];
              };
              if ([downloadedUser isEqual:[NSNull null]]) { // user account not modified
                stillNotVerifiedAlert();
              } else { // user account modified
                [user setUpdatedAt:[downloadedUser updatedAt]];
                [user overwriteDomainProperties:downloadedUser];
                [[coordDao localDao] saveMasterUser:downloadedUser error:[FPUtils localSaveErrorHandlerMaker]()];
                if ([PEUtils isNil:[user verifiedAt]]) {  // user account modified, but still not verified
                  stillNotVerifiedAlert();
                } else {  // user account verified
                  [PEUIUtils showSuccessAlertWithTitle:@"Account verified."
                                      alertDescription:[[NSAttributedString alloc] initWithString:@"Thank you.  Your account is now verified."]
                                              topInset:70.0
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
                                        topInset:70.0
                                     buttonTitle:@"Okay."
                                    buttonAction:^{ enableUserInteraction(YES); }
                                  relativeToView:controller.tabBarController.view];
              } else if ([errsForRefresh[0][4] boolValue]) { // not found
                NSString *fetchErrMsg = @"Oops.  Something appears to be wrong with your account.  Try logging off and logging back in.";
                [PEUIUtils showErrorAlertWithMsgs:nil
                                            title:@"Something went wrong."
                                 alertDescription:[[NSAttributedString alloc] initWithString:fetchErrMsg]
                                         topInset:70.0
                                      buttonTitle:@"Okay."
                                     buttonAction:^{ enableUserInteraction(YES); }
                                   relativeToView:controller.tabBarController.view];
                
              } else { // any other error type
                NSString *fetchErrMsg = @"Oops.  There was a problem attempting to refresh.  Try it again a little later.";
                [PEUIUtils showErrorAlertWithMsgs:errsForRefresh[0][2]
                                            title:@"Something went wrong."
                                 alertDescription:[[NSAttributedString alloc] initWithString:fetchErrMsg]
                                         topInset:70.0
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
        [coordDao fetchUser:user
            ifModifiedSince:[user updatedAt]
        notFoundOnServerBlk:^{refreshNotFoundBlk(mainMsgFragment, recordTitle);}
                 successBlk:^(FPUser *fetchedUser) {refreshSuccessBlk(mainMsgFragment, recordTitle, fetchedUser);}
         remoteStoreBusyBlk:^(NSDate *retryAfter){refreshRetryAfterBlk(mainMsgFragment, recordTitle, retryAfter);}
         tempRemoteErrorBlk:^{refreshServerTempError(mainMsgFragment, recordTitle);}
        addlAuthRequiredBlk:^{refreshAuthReqdBlk(mainMsgFragment, recordTitle); [APP refreshTabs];}];        
      } forControlEvents:UIControlEventTouchUpInside];
      [PEUIUtils placeView:refreshBtn inMiddleOf:buttonsView withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:8.0];
      UIButton *resendEmailBtn = makeSendEmailBtn();
      [PEUIUtils placeView:resendEmailBtn toTheRightOf:refreshBtn onto:buttonsView withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:10.0];
    } else {
      UIButton *resendEmailBtn = makeSendEmailBtn();
      [PEUIUtils placeView:resendEmailBtn inMiddleOf:buttonsView withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:10.0];
    }
    [PEUIUtils placeView:statusPanel atTopOf:panel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
    [PEUIUtils placeView:buttonsView below:statusPanel onto:panel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:3.0 hpadding:0.0];
  } else {
    panel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:statusPanel];
    [PEUIUtils placeView:statusPanel atTopOf:panel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
  }
  [panel setTag:[panelTag integerValue]];
  return panel;
}

+ (void)refreshAccountStatusPanelForUser:(FPUser *)user
                                panelTag:(NSNumber *)panelTag
                    includeRefreshButton:(BOOL)includeRefreshButton
                          coordinatorDao:(FPCoordinatorDao *)coordDao
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
                           coordinatorDao:(FPCoordinatorDao *)coordDao
                                uitoolkit:(PEUIToolkit *)uitoolkit
                               controller:(UIViewController *)controller {
  UIButton *forgotPasswordBtn = [PEUIUtils buttonWithKey:@"Forgot password?"
                                                    font:[UIFont systemFontOfSize:14]
                                         backgroundColor:[UIColor concreteColor]
                                               textColor:[UIColor whiteColor]
                            disabledStateBackgroundColor:nil
                                  disabledStateTextColor:nil
                                         verticalPadding:8.5
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

- (void)placeViewLogsButtonsOntoVehiclePanel:(UIView *)vehiclePanel
                                   belowView:(UIView *)belowView
                        parentViewController:(PEAddViewEditController *)parentViewController {
  // View Fuel Purchase Logs button
  UIButton *viewFpLogsBtn = [PEUIUtils buttonWithLabel:@"Gas logs"
                                          tagForButton:@(FPVehicleTagViewFplogsBtn)
                                           recordCount:[_coordDao numFuelPurchaseLogsForVehicle:(FPVehicle *)[parentViewController entity] error:[FPUtils localFetchErrorHandlerMaker]()]
                                tagForRecordCountLabel:@(FPVehicleTagViewFplogsBtnRecordCount)
                                     addDisclosureIcon:YES
                                               handler:^{
                                                 FPAuthScreenMaker fpLogsScreenMaker =
                                                 [_screenToolkit newViewFuelPurchaseLogsScreenMakerForVehicleInCtx];
                                                 [PEUIUtils displayController:fpLogsScreenMaker((FPVehicle *)[parentViewController entity])
                                                               fromController:parentViewController
                                                                     animated:YES];
                                               }
                                             uitoolkit:_uitoolkit
                                        relativeToView:parentViewController.view];
  [PEUIUtils placeView:viewFpLogsBtn
                 below:belowView
                  onto:vehiclePanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:18.5
              hpadding:0];
  // View Environment Logs button
  UIButton *viewEnvLogsBtn = [PEUIUtils buttonWithLabel:@"Odometer logs"
                                           tagForButton:@(FPVehicleTagViewEnvlogsBtn)
                                            recordCount:[_coordDao numEnvironmentLogsForVehicle:(FPVehicle *)[parentViewController entity] error:[FPUtils localFetchErrorHandlerMaker]()]
                                 tagForRecordCountLabel:@(FPVehicleTagViewEnvlogsBtnRecordCount)
                                      addDisclosureIcon:YES
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
                  onto:vehiclePanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:8.0
              hpadding:0];
  UIView *msgPanel = [PEUIUtils leftPadView:[PEUIUtils labelWithKey:@"From here you can drill into the gas and odometer logs associated with this vehicle."
                                                               font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                                    backgroundColor:[UIColor clearColor]
                                                          textColor:[UIColor darkGrayColor]
                                                verticalTextPadding:3.0
                                                         fitToWidth:parentViewController.view.frame.size.width - 15.0]
                                    padding:8.0];
  [PEUIUtils placeView:msgPanel
                 below:viewEnvLogsBtn
                  onto:vehiclePanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0];
}

- (PEEntityViewPanelMakerBlk)vehicleViewPanelMaker {
  return ^ UIView * (PEAddViewEditController *parentViewController, FPUser *user, FPVehicle *vehicle) {
    UIView *parentView = [parentViewController view];
    UIView *vehiclePanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:parentView];
    UIView *vehicleDataPanel = [PEUIUtils tablePanelWithRowData:@[@[@"Vehicle name", [PEUtils emptyIfNil:[vehicle name]]],
                                                                  @[@"Default octane", [PEUtils descriptionOrEmptyIfNil:[vehicle defaultOctane]]],
                                                                  @[@"Fuel capacity", [PEUtils descriptionOrEmptyIfNil:[vehicle fuelCapacity]]]]
                                                      uitoolkit:_uitoolkit
                                                     parentView:parentView];
    [PEUIUtils placeView:vehicleDataPanel
                 atTopOf:vehiclePanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:15.0
                hpadding:0.0];
    UIButton *statsBtn = [_uitoolkit systemButtonMaker](@"Stats & Trends", nil, nil);
    [[statsBtn layer] setCornerRadius:0.0];
    [PEUIUtils setFrameWidthOfView:statsBtn ofWidth:1.0 relativeTo:parentView];
    [PEUIUtils addDisclosureIndicatorToButton:statsBtn];
    [statsBtn bk_addEventHandler:^(id sender) {
      [[parentViewController navigationController] pushViewController:[_screenToolkit newVehicleStatsLaunchScreenMakerWithVehicle:vehicle](user)
                                                             animated:YES];
    } forControlEvents:UIControlEventTouchUpInside];
    UIView *statsMsgPanel = [PEUIUtils leftPadView:[PEUIUtils labelWithKey:@"From here you can drill into the stats and trends associated with this vehicle."
                                                                      font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                                           backgroundColor:[UIColor clearColor]
                                                                 textColor:[UIColor darkGrayColor]
                                                       verticalTextPadding:3.0
                                                                fitToWidth:parentView.frame.size.width - 15.0]
                                           padding:8.0];
    [PEUIUtils placeView:statsBtn
                   below:vehicleDataPanel
                    onto:vehiclePanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:30.0
                hpadding:0.0];
    [PEUIUtils placeView:statsMsgPanel
                   below:statsBtn
                    onto:vehiclePanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:4.0
                hpadding:0.0];
    [self placeViewLogsButtonsOntoVehiclePanel:vehiclePanel
                                     belowView:statsMsgPanel
                          parentViewController:parentViewController];
    return vehiclePanel;
  };
}

- (PEEntityPanelMakerBlk)vehicleFormPanelMakerIncludeLogButtons:(BOOL)includeLogButtons {
  return ^ UIView * (PEAddViewEditController *parentViewController) {
    UIView *parentView = [parentViewController view];
    UIView *vehiclePanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:parentView];
    TaggedTextfieldMaker tfMaker =
      [_uitoolkit taggedTextfieldMakerForWidthOf:1.0 relativeTo:vehiclePanel];
    UITextField *vehicleNameTf = tfMaker(@"Vehicle name", FPVehicleTagName);
    UITextField *vehicleDefaultOctaneTf = tfMaker(@"Default octane", FPVehicleTagDefaultOctane);
    [vehicleDefaultOctaneTf setKeyboardType:UIKeyboardTypeNumberPad];
    UITextField *vehicleFuelCapacityTf = tfMaker(@"Fuel capacity", FPVehicleTagFuelCapacity);
    [vehicleFuelCapacityTf setKeyboardType:UIKeyboardTypeDecimalPad];
    [PEUIUtils placeView:vehicleNameTf
                 atTopOf:vehiclePanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:15
                hpadding:0];
    [PEUIUtils placeView:vehicleDefaultOctaneTf
                   below:vehicleNameTf
                    onto:vehiclePanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:vehicleFuelCapacityTf
                   below:vehicleDefaultOctaneTf
                    onto:vehiclePanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    if (includeLogButtons) {
      // I can't remember why I thought it was a good idea to include the
      // view-log buttons on the form/edit screen...oh well...
      /*[self placeViewLogsButtonsOntoVehiclePanel:vehiclePanel
                                       belowView:vehicleFuelCapacityTf
                            parentViewController:parentViewController];*/
    }
    return vehiclePanel;
  };
}

- (PEPanelToEntityBinderBlk)vehicleFormPanelToVehicleBinder {
  return ^ void (UIView *panel, FPVehicle *vehicle) {
    [PEUIUtils bindToEntity:vehicle
           withStringSetter:@selector(setName:)
       fromTextfieldWithTag:FPVehicleTagName
                   fromView:panel];
    [PEUIUtils bindToEntity:vehicle
           withNumberSetter:@selector(setDefaultOctane:)
       fromTextfieldWithTag:FPVehicleTagDefaultOctane
                   fromView:panel];
    [PEUIUtils bindToEntity:vehicle
          withDecimalSetter:@selector(setFuelCapacity:)
       fromTextfieldWithTag:FPVehicleTagFuelCapacity
                   fromView:panel];
  };
}

- (PEEntityToPanelBinderBlk)vehicleToVehiclePanelBinder {
  return ^ void (FPVehicle *vehicle, UIView *panel) {
    [PEUIUtils bindToTextControlWithTag:FPVehicleTagName
                               fromView:panel
                             fromEntity:vehicle
                             withGetter:@selector(name)];
    [PEUIUtils bindToTextControlWithTag:FPVehicleTagDefaultOctane
                               fromView:panel
                             fromEntity:vehicle
                             withGetter:@selector(defaultOctane)];
    [PEUIUtils bindToTextControlWithTag:FPVehicleTagFuelCapacity
                               fromView:panel
                             fromEntity:vehicle
                             withGetter:@selector(fuelCapacity)];
  };
}

- (PEEnableDisablePanelBlk)vehicleFormPanelEnablerDisabler {
  return ^ (UIView *panel, BOOL enable) {
    [PEUIUtils enableControlWithTag:FPVehicleTagName
                           fromView:panel
                             enable:enable];
    [PEUIUtils enableControlWithTag:FPVehicleTagDefaultOctane
                           fromView:panel
                             enable:enable];
    [PEUIUtils enableControlWithTag:FPVehicleTagFuelCapacity
                           fromView:panel
                             enable:enable];
  };
}

- (PEEntityMakerBlk)vehicleMaker {
  return ^ PELMModelSupport * (UIView *panel) {
    FPVehicle *newVehicle =
      [_coordDao vehicleWithName:[PEUIUtils stringFromTextFieldWithTag:FPVehicleTagName fromView:panel]
                   defaultOctane:[PEUIUtils numberFromTextFieldWithTag:FPVehicleTagDefaultOctane fromView:panel]
                    fuelCapacity:[PEUIUtils decimalNumberFromTextFieldWithTag:FPVehicleTagFuelCapacity fromView:panel]];
    return newVehicle;
  };
}

#pragma mark - Fuel Station Panel

- (UIButton *)placeViewLogsButtonOntoFuelstationPanel:(UIView *)fuelstationPanel
                                            belowView:(UIView *)belowView
                                 parentViewController:(PEAddViewEditController *)parentViewController {
  UIButton *viewFpLogsBtn = [PEUIUtils buttonWithLabel:@"Gas logs"
                                          tagForButton:@(FPFuelStationTagViewFplogsBtn)
                                           recordCount:[_coordDao numFuelPurchaseLogsForFuelStation:(FPFuelStation *)[parentViewController entity] error:[FPUtils localFetchErrorHandlerMaker]()]
                                tagForRecordCountLabel:@(FPFuelStationTagViewFplogsBtnRecordCount)
                                     addDisclosureIcon:YES
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
  UIView *msgPanel = [PEUIUtils leftPadView:[PEUIUtils labelWithKey:@"From here you can drill into the gas logs associated with this gas station."
                                                               font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
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
  return viewFpLogsBtn;
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
  [PEUIUtils setFrameHeight:142.0 ofView:coordinatesTableView];
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
    UIView *fuelstationPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.2 relativeToView:parentView];
    UIView *fuelstationDataPanel = [PEUIUtils tablePanelWithRowData:@[@[@"Gas station name", [PEUtils emptyIfNil:[fuelstation name]]],
                                                                      @[@"Street", [PEUtils emptyIfNil:[fuelstation street]]],
                                                                      @[@"City", [PEUtils emptyIfNil:[fuelstation city]]],
                                                                      @[@"State", [PEUtils emptyIfNil:[fuelstation state]]],
                                                                      @[@"Zip", [PEUtils emptyIfNil:[fuelstation zip]]]]
                                                          uitoolkit:_uitoolkit
                                                         parentView:parentView];
    [PEUIUtils placeView:fuelstationDataPanel
                 atTopOf:fuelstationPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:15.0
                hpadding:0.0];
    UITableView *coordinatesTableView = [self placeCoordinatesTableOntoFuelstationPanel:fuelstationPanel
                                                                            fuelstation:fuelstation
                                                                              belowView:fuelstationDataPanel
                                                                   parentViewController:parentViewController][0];
    UIButton *statsBtn = [_uitoolkit systemButtonMaker](@"Stats & Trends", nil, nil);
    [[statsBtn layer] setCornerRadius:0.0];
    [PEUIUtils setFrameWidthOfView:statsBtn ofWidth:1.0 relativeTo:parentView];
    [PEUIUtils addDisclosureIndicatorToButton:statsBtn];
    [statsBtn bk_addEventHandler:^(id sender) {
      [[parentViewController navigationController] pushViewController:[_screenToolkit newFuelStationStatsLaunchScreenMakerWithFuelstation:fuelstation](user)
                                                             animated:YES];
    } forControlEvents:UIControlEventTouchUpInside];
    UIView *statsMsgPanel = [PEUIUtils leftPadView:[PEUIUtils labelWithKey:@"From here you can drill into the stats and trends associated with this gas station."
                                                                      font:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                                           backgroundColor:[UIColor clearColor]
                                                                 textColor:[UIColor darkGrayColor]
                                                       verticalTextPadding:3.0
                                                                fitToWidth:parentView.frame.size.width - 15.0]
                                           padding:8.0];
    [PEUIUtils placeView:statsBtn
                   below:coordinatesTableView
                    onto:fuelstationPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:30.0
                hpadding:0.0];
    [PEUIUtils placeView:statsMsgPanel
                   below:statsBtn
                    onto:fuelstationPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:4.0
                hpadding:0.0];
    [self placeViewLogsButtonOntoFuelstationPanel:fuelstationPanel
                                        belowView:statsMsgPanel
                             parentViewController:parentViewController];
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:[fuelstationPanel frame]];
    [scrollView setContentSize:CGSizeMake(fuelstationPanel.frame.size.width, 1.285 * fuelstationPanel.frame.size.height)];
    [scrollView addSubview:fuelstationPanel];
    [scrollView setBounces:NO];
    return scrollView;
  };
}

- (PEEntityPanelMakerBlk)fuelstationFormPanelMakerIncludeLogButton:(BOOL)includeLogButton {
  return ^ UIView * (PEAddViewEditController *parentViewController) {
    UIView *parentView = [parentViewController view];
    UIView *fuelStationPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.4 relativeToView:parentView];
    TaggedTextfieldMaker tfMaker = [_uitoolkit taggedTextfieldMakerForWidthOf:1.0 relativeTo:fuelStationPanel];
    UITextField *fuelStationNameTf = tfMaker(@"Gas station name", FPFuelStationTagName);
    UITextField *fuelStationStreetTf = tfMaker(@"Street", FPFuelStationTagStreet);
    UITextField *fuelStationCityTf = tfMaker(@"City", FPFuelStationTagCity);
    UITextField *fuelStationStateTf = tfMaker(@"State", FPFuelStationTagState);
    UITextField *fuelStationZipTf = tfMaker(@"Zip", FPFuelStationTagZip);
    [fuelStationZipTf setKeyboardType:UIKeyboardTypeNumberPad];
    [PEUIUtils placeView:fuelStationNameTf
                 atTopOf:fuelStationPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:15
                hpadding:0];
    [PEUIUtils placeView:fuelStationStreetTf
                   below:fuelStationNameTf
                    onto:fuelStationPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:fuelStationCityTf
                   below:fuelStationStreetTf
                    onto:fuelStationPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:fuelStationStateTf
                   below:fuelStationCityTf
                    onto:fuelStationPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:fuelStationZipTf
                   below:fuelStationStateTf
                    onto:fuelStationPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    NSArray *tableAndDs = [self placeCoordinatesTableOntoFuelstationPanel:fuelStationPanel
                                                              fuelstation:nil
                                                                belowView:fuelStationZipTf
                                                     parentViewController:parentViewController];
    UITableView *coordinatesTableView = tableAndDs[0];
    FPFuelStationCoordinatesTableDataSource *ds = tableAndDs[1];
    UIButton *useCurrentLocationBtn = [PEUIUtils buttonWithKey:@"Use current location"
                                                          font:[UIFont systemFontOfSize:14]
                                               backgroundColor:[UIColor concreteColor]
                                                     textColor:[UIColor whiteColor]
                                  disabledStateBackgroundColor:nil
                                        disabledStateTextColor:nil
                                               verticalPadding:8.5
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
                                 accentTextFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]];
          [PEUIUtils showWarningAlertWithMsgs:nil
                                        title:@"Hmm."
                             alertDescription:attrDescTextWithInstructionalText
                                     topInset:70.0
                                  buttonTitle:@"Okay."
                                 buttonAction:^{}
                               relativeToView:parentView];
        } else {
          if ([APP hasBeenAskedToEnableLocationServices]) {
            [PEUIUtils showInstructionalAlertWithTitle:@"Enable location services."
                                  alertDescriptionText:@"To compute your current location, you need to enable location services for Gas Jot.  To do this, go to:\n\n"
                                       instructionText:@"Settings app \u2794 Privacy \u2794 Location Services \u2794 Gas Jot"
                                              topInset:70.0
                                           buttonTitle:@"Okay."
                                          buttonAction:^{}
                                        relativeToView:parentView];
          } else {
            [PEUIUtils showConfirmAlertWithTitle:@"Enable location services?"
                                      titleImage:[PEUIUtils bundleImageWithName:@"question"]
                                alertDescription:[[NSAttributedString alloc] initWithString:@"\
To compute your location, you need to enable location services for Gas Jot.  If you would like to do this, tap 'Allow' in the next pop-up."]
                                        topInset:70.0
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
                    onto:fuelStationPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:8.0
                hpadding:8.0];
    UIButton *recomputeCoordsBtn = [PEUIUtils buttonWithKey:@"Compute coordinates from address above"
                                                       font:[UIFont systemFontOfSize:14]
                                            backgroundColor:[UIColor concreteColor]
                                                  textColor:[UIColor whiteColor]
                               disabledStateBackgroundColor:nil
                                     disabledStateTextColor:nil
                                            verticalPadding:8.5
                                          horizontalPadding:20.0
                                               cornerRadius:5.0
                                                     target:nil
                                                     action:nil];
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
                                 topInset:70.0
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
                                                  topInset:70.0
                                               buttonTitle:@"Okay."
                                              buttonAction:nil
                                            relativeToView:parentView];
                       }
                     }];
      }
    } forControlEvents:UIControlEventTouchUpInside];
    [PEUIUtils placeView:recomputeCoordsBtn
                   below:useCurrentLocationBtn
                    onto:fuelStationPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:6.0
                hpadding:0.0];
    if (includeLogButton) {
      // I can't remember why I thought it was a good idea to include the
      // view-log buttons on the form/edit screen...oh well...
      /*[self placeViewLogsButtonOntoFuelstationPanel:fuelStationPanel
                                          belowView:recomputeCoordsBtn
                               parentViewController:parentViewController];*/
    }
    // wrap fuel station panel in scroll view (so everything can "fit")
    /*UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:[fuelStationPanel frame]];
    [scrollView setContentSize:CGSizeMake(fuelStationPanel.frame.size.width, 1.3 * fuelStationPanel.frame.size.height)];
    [scrollView addSubview:fuelStationPanel];
    [scrollView setBounces:NO];
    return scrollView;*/
    return fuelStationPanel;
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
                                          defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle
                                      defaultSelectedFuelStation:(FPFuelStation *)defaultSelectedFuelStation
                                            defaultPickedLogDate:(NSDate *)defaultPickedLogDate {
  return ^ UIView * (UIViewController *parentViewController) {
    UIView *parentView = [parentViewController view];
    UIView *fpEnvCompPanel = [PEUIUtils panelWithWidthOf:1.0
                                             andHeightOf:1.12
                                          relativeToView:parentView];
    NSDictionary *envlogComponents = [self envlogFormComponentsWithUser:user
                                            displayDisclosureIndicators:YES
                                                 defaultSelectedVehicle:defaultSelectedVehicle
                                                   defaultPickedLogDate:defaultPickedLogDate](parentViewController);
    UITextField *odometerTf = envlogComponents[@(FPEnvLogTagOdometer)];
    UITextField *reportedAvgMpgTf = envlogComponents[@(FPEnvLogTagReportedAvgMpg)];
    UITextField *reportedAvgMphTf = envlogComponents[@(FPEnvLogTagReportedAvgMph)];
    UITextField *reportedOutsideTempTf = envlogComponents[@(FPEnvLogTagReportedOutsideTemp)];
    TaggedTextfieldMaker tfMaker =
      [_uitoolkit taggedTextfieldMakerForWidthOf:1.0 relativeTo:fpEnvCompPanel];
    UITextField *preFillupReportedDteTf = tfMaker(@"Pre-fillup Reported DTE", FPFpEnvLogCompositeTagPreFillupReportedDte);
    [preFillupReportedDteTf setKeyboardType:UIKeyboardTypeNumberPad];
    UITextField *postFillupReportedDteTf = tfMaker(@"Post-fillup Reported DTE", FPFpEnvLogCompositeTagPostFillupReportedDte);
    [postFillupReportedDteTf setKeyboardType:UIKeyboardTypeNumberPad];
    NSDictionary *fplogComponents = [self fplogFormComponentsWithUser:user
                                           displayDisclosureIndicator:YES
                                               defaultSelectedVehicle:defaultSelectedVehicle
                                           defaultSelectedFuelStation:defaultSelectedFuelStation
                                                 defaultPickedLogDate:defaultPickedLogDate](parentViewController);
    UITableView *vehicleFuelStationDateTableView = fplogComponents[@(FPFpLogTagVehicleFuelStationAndDate)];
    //[PEUIUtils applyBorderToView:vehicleFuelStationDateTableView withColor:[UIColor yellowColor]];
    UITextField *numGallonsTf = fplogComponents[@(FPFpLogTagNumGallons)];
    UITextField *pricePerGallonTf = fplogComponents[@(FPFpLogTagPricePerGallon)];
    UITextField *octaneTf = fplogComponents[@(FPFpLogTagOctane)];
    UITextField *carWashPerGallonDiscountTf = fplogComponents[@(FPFpLogTagCarWashPerGallonDiscount)];
    UIView *gotCarWashPanel = fplogComponents[@(FPFpLogTagCarWashPanel)];
    [PEUIUtils placeView:vehicleFuelStationDateTableView
                 atTopOf:fpEnvCompPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0.0];
    [PEUIUtils placeView:octaneTf
                   below:vehicleFuelStationDateTableView
                    onto:fpEnvCompPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:preFillupReportedDteTf
                   below:octaneTf
                    onto:fpEnvCompPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:reportedAvgMpgTf
                   below:preFillupReportedDteTf
                    onto:fpEnvCompPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:reportedAvgMphTf
                   below:reportedAvgMpgTf
                    onto:fpEnvCompPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:odometerTf
                   below:reportedAvgMphTf
                    onto:fpEnvCompPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:reportedOutsideTempTf
                   below:odometerTf
                    onto:fpEnvCompPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:pricePerGallonTf
                   below:reportedOutsideTempTf
                    onto:fpEnvCompPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:carWashPerGallonDiscountTf
                   below:pricePerGallonTf
                    onto:fpEnvCompPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:gotCarWashPanel
                   below:carWashPerGallonDiscountTf
                    onto:fpEnvCompPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:numGallonsTf
                   below:gotCarWashPanel
                    onto:fpEnvCompPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:postFillupReportedDteTf
                   below:numGallonsTf
                    onto:fpEnvCompPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    
    NSNumber *defaultOctane = [defaultSelectedVehicle defaultOctane];
    if (![PEUtils isNil:defaultOctane]) {
      [octaneTf setText:[defaultOctane description]];
    }
    
    // wrap fuel station panel in scroll view (so everything can "fit")
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:[fpEnvCompPanel frame]];
    [scrollView setContentSize:CGSizeMake(fpEnvCompPanel.frame.size.width, 1.25 * fpEnvCompPanel.frame.size.height)];
    [scrollView addSubview:fpEnvCompPanel];
    [scrollView setBounces:NO];
    return scrollView;
  };
}

- (PEPanelToEntityBinderBlk)fpEnvLogCompositeFormPanelToFpEnvLogCompositeBinder {
  PEPanelToEntityBinderBlk fpLogPanelToEntityBinder =
    [self fplogFormPanelToFplogBinder];
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
  PEEntityToPanelBinderBlk fpLogToPanelBinder =
    [self fplogToFplogPanelBinder];
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
    FPLogEnvLogComposite *composite = [[FPLogEnvLogComposite alloc] initWithNumGallons:tfdec(FPFpLogTagNumGallons)
                                                                                octane:tfnum(FPFpLogTagOctane)
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
    UIView *fplogPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:parentView];
    UIView *fplogDataPanel = [PEUIUtils tablePanelWithRowData:@[@[@"Octane", [PEUtils descriptionOrEmptyIfNil:[fplog octane]]],
                                                                @[@"Price per gallon", [PEUtils descriptionOrEmptyIfNil:[fplog gallonPrice]]],
                                                                @[@"Car wash per-gallon discount", [PEUtils descriptionOrEmptyIfNil:[fplog carWashPerGallonDiscount]]],
                                                                @[@"Got car wash?", [PEUtils yesNoFromBool:[fplog gotCarWash]]],
                                                                @[@"Num gallons", [PEUtils descriptionOrEmptyIfNil:[fplog numGallons]]]]
                                                    uitoolkit:_uitoolkit
                                                   parentView:parentView];
    FPVehicle *vehicle = [_coordDao vehicleForFuelPurchaseLog:fplog error:[FPUtils localFetchErrorHandlerMaker]()];
    FPFuelStation *fuelstation = [_coordDao fuelStationForFuelPurchaseLog:fplog error:[FPUtils localFetchErrorHandlerMaker]()];
    NSDictionary *components = [self fplogFormComponentsWithUser:user
                                      displayDisclosureIndicator:NO
                                          defaultSelectedVehicle:vehicle
                                      defaultSelectedFuelStation:fuelstation
                                            defaultPickedLogDate:[fplog purchasedAt]](parentViewController);
    UITableView *vehicleFuelStationDateTableView = components[@(FPFpLogTagVehicleFuelStationAndDate)];
    FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds = (FPFpLogVehicleFuelStationDateDataSourceAndDelegate *)vehicleFuelStationDateTableView.dataSource;
    [ds setSelectedFuelStation:fuelstation];
    [ds setSelectedVehicle:vehicle];
    [vehicleFuelStationDateTableView setUserInteractionEnabled:NO];
    [PEUIUtils placeView:vehicleFuelStationDateTableView
                 atTopOf:fplogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0.0];
    [PEUIUtils placeView:fplogDataPanel
                   below:vehicleFuelStationDateTableView
                    onto:fplogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    return fplogPanel;
  };
}

- (PEComponentsMakerBlk)fplogFormComponentsWithUser:(FPUser *)user
                         displayDisclosureIndicator:(BOOL)displayDisclosureIndicator
                             defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle
                         defaultSelectedFuelStation:(FPFuelStation *)defaultSelectedFuelStation
                               defaultPickedLogDate:(NSDate *)defaultPickedLogDate {
  return ^ NSDictionary * (UIViewController *parentViewController) {
    NSMutableDictionary *components = [NSMutableDictionary dictionary];
    UIView *parentView = [parentViewController view];
    UITableView *vehicleFuelStationDateTableView =
    [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)
                                 style:UITableViewStyleGrouped];
    [vehicleFuelStationDateTableView setScrollEnabled:NO];
    [vehicleFuelStationDateTableView setTag:FPFpLogTagVehicleFuelStationAndDate];
    [PEUIUtils setFrameWidthOfView:vehicleFuelStationDateTableView ofWidth:1.0 relativeTo:parentView];
    [PEUIUtils setFrameHeight:180.0 ofView:vehicleFuelStationDateTableView];
    vehicleFuelStationDateTableView.sectionHeaderHeight = 2.0;
    vehicleFuelStationDateTableView.sectionFooterHeight = 2.0;
    components[@(FPFpLogTagVehicleFuelStationAndDate)] = vehicleFuelStationDateTableView;
    TaggedTextfieldMaker tfMaker =
    [_uitoolkit taggedTextfieldMakerForWidthOf:1.0 relativeTo:parentView];
    UITextField *numGallonsTf = tfMaker(@"Num gallons", FPFpLogTagNumGallons);
    components[@(FPFpLogTagNumGallons)] = numGallonsTf;
    [numGallonsTf setKeyboardType:UIKeyboardTypeDecimalPad];
    UITextField *pricePerGallonTf =
      tfMaker(@"Price per gallon", FPFpLogTagPricePerGallon);
    components[@(FPFpLogTagPricePerGallon)] = pricePerGallonTf;
    [pricePerGallonTf setKeyboardType:UIKeyboardTypeDecimalPad];
    UITextField *octaneTf = tfMaker(@"Octane", FPFpLogTagOctane);
    if (defaultSelectedVehicle) {
      NSNumber *defaultOctane = [defaultSelectedVehicle defaultOctane];
      if (![PEUtils isNil:defaultOctane]) {
        [octaneTf setText:[defaultOctane description]];
      }
    }
    [octaneTf setKeyboardType:UIKeyboardTypeNumberPad];
    components[@(FPFpLogTagOctane)] = octaneTf;
    UITextField *carWashPerGallonDiscountTf =
    tfMaker(@"Car was per-gallon discount", FPFpLogTagCarWashPerGallonDiscount);
    [carWashPerGallonDiscountTf setKeyboardType:UIKeyboardTypeDecimalPad];
    components[@(FPFpLogTagCarWashPerGallonDiscount)] = carWashPerGallonDiscountTf;
    UISwitch *gotCarWashSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [gotCarWashSwitch setTag:FPFpLogTagGotCarWash];
    components[@(FPFpLogTagGotCarWash)] = gotCarWashSwitch;
    UIView *gotCarWashPanel =
    [PEUIUtils panelWithWidthOf:1.0
                 relativeToView:parentView
                    fixedHeight:numGallonsTf.frame.size.height];
    [gotCarWashPanel setTag:FPFpLogTagCarWashPanel];
    [gotCarWashPanel setBackgroundColor:[UIColor whiteColor]];
    UILabel *gotCarWashLbl =
    [PEUIUtils labelWithKey:@"Got car wash?"
                       font:[numGallonsTf font]
            backgroundColor:[UIColor clearColor]
                  textColor:[_uitoolkit colorForTableCellTitles]
        verticalTextPadding:3.0]; 
    [PEUIUtils placeView:gotCarWashLbl
              inMiddleOf:gotCarWashPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                hpadding:10.0];
    [PEUIUtils placeView:gotCarWashSwitch
            toTheRightOf:gotCarWashLbl
                    onto:gotCarWashPanel
           withAlignment:PEUIVerticalAlignmentTypeMiddle
                hpadding:15.0];
    components[@(FPFpLogTagCarWashPanel)] = gotCarWashPanel;
    PEItemSelectedAction vehicleSelectedAction = ^(FPVehicle *vehicle, NSIndexPath *indexPath, UIViewController *vehicleSelectionController) {
      [[vehicleSelectionController navigationController] popViewControllerAnimated:YES];
      [vehicleFuelStationDateTableView
       reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] // 'Vehicle' is col-index 0
       withRowAnimation:UITableViewRowAnimationAutomatic];
      NSNumber *defaultOctane = [vehicle defaultOctane];
      if (![PEUtils isNil:defaultOctane]) {
        [octaneTf setText:[defaultOctane description]];
      } else {
        [octaneTf setText:@""];
      }
    };
    PEItemSelectedAction fuelStationSelectedAction = ^(FPFuelStation *fuelStation, NSIndexPath *indexPath, UIViewController *fuelStationSelectionController) {
      [[fuelStationSelectionController navigationController] popViewControllerAnimated:YES];
      [vehicleFuelStationDateTableView
       reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] // 'Fuel Station' is col-index 1
       withRowAnimation:UITableViewRowAnimationAutomatic];
    };
    void (^logDatePickedAction)(NSDate *) = ^(NSDate *logDate) {
      [vehicleFuelStationDateTableView
       reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:2]] // 'Log Date' is col-index 2
       withRowAnimation:UITableViewRowAnimationAutomatic];
    };
    FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds =
    [[FPFpLogVehicleFuelStationDateDataSourceAndDelegate alloc] initWithControllerCtx:parentViewController
                                                               defaultSelectedVehicle:defaultSelectedVehicle
                                                           defaultSelectedFuelStation:defaultSelectedFuelStation
                                                                       defaultLogDate:defaultPickedLogDate
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
    return components;
  };
}

- (PEEntityPanelMakerBlk)fplogFormPanelMakerWithUser:(FPUser *)user
                              defaultSelectedVehicle:(FPVehicle *(^)(void))defaultSelectedVehicle
                          defaultSelectedFuelStation:(FPFuelStation *(^)(void))defaultSelectedFuelStation
                                defaultPickedLogDate:(NSDate *)defaultPickedLogDate {
  return ^ UIView * (UIViewController *parentViewController) {
    UIView *parentView = [parentViewController view];
    UIView *fpLogPanel = [PEUIUtils panelWithWidthOf:1.0
                                         andHeightOf:1.0
                                      relativeToView:parentView];
    NSDictionary *components = [self fplogFormComponentsWithUser:user
                                      displayDisclosureIndicator:YES
                                          defaultSelectedVehicle:defaultSelectedVehicle()
                                      defaultSelectedFuelStation:defaultSelectedFuelStation()
                                            defaultPickedLogDate:defaultPickedLogDate](parentViewController);
    UITableView *vehicleFuelStationDateTableView = components[@(FPFpLogTagVehicleFuelStationAndDate)];
    UITextField *numGallonsTf = components[@(FPFpLogTagNumGallons)];
    UITextField *pricePerGallonTf = components[@(FPFpLogTagPricePerGallon)];
    UITextField *octaneTf = components[@(FPFpLogTagOctane)];
    UITextField *carWashPerGallonDiscountTf = components[@(FPFpLogTagCarWashPerGallonDiscount)];
    UIView *gotCarWashPanel = components[@(FPFpLogTagCarWashPanel)];
    [PEUIUtils placeView:vehicleFuelStationDateTableView
                 atTopOf:fpLogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0.0];
    [PEUIUtils placeView:octaneTf
                   below:vehicleFuelStationDateTableView
                    onto:fpLogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:pricePerGallonTf
                   below:octaneTf
                    onto:fpLogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:carWashPerGallonDiscountTf
                   below:pricePerGallonTf
                    onto:fpLogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:gotCarWashPanel
                   below:carWashPerGallonDiscountTf
                    onto:fpLogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:numGallonsTf
                   below:gotCarWashPanel
                    onto:fpLogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    
//    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:[fpLogPanel frame]];
//    [scrollView setContentSize:CGSizeMake(fpLogPanel.frame.size.width, 1.3 * fpLogPanel.frame.size.height)];
//    [scrollView addSubview:fpLogPanel];
//    [scrollView setBounces:NO];
//    return scrollView;
    return fpLogPanel;
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
    bindnum(FPFpLogTagOctane, @selector(setOctane:));
    binddec(FPFpLogTagCarWashPerGallonDiscount, @selector(setCarWashPerGallonDiscount:));
    UISwitch *gotCarWasSwitch = (UISwitch *)[panel viewWithTag:FPFpLogTagGotCarWash];
    [fpLog setGotCarWash:[gotCarWasSwitch isOn]];
    UITableView *vehicleFuelStationDateTableView =
      (UITableView *)[panel viewWithTag:FPFpLogTagVehicleFuelStationAndDate];
    FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds =
      (FPFpLogVehicleFuelStationDateDataSourceAndDelegate *)[vehicleFuelStationDateTableView dataSource];
    [fpLog setPurchasedAt:[ds pickedLogDate]];
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
      bindtt(FPFpLogTagOctane, @selector(octane));
      bindtt(FPFpLogTagCarWashPerGallonDiscount, @selector(carWashPerGallonDiscount));
      UISwitch *gotCarWasSwitch = (UISwitch *)[panel viewWithTag:FPFpLogTagGotCarWash];
      [gotCarWasSwitch setOn:[fpLog gotCarWash] animated:YES];
      if ([fpLog purchasedAt]) {
        UITableView *vehicleFuelStationDateTableView =
        (UITableView *)[panel viewWithTag:FPFpLogTagVehicleFuelStationAndDate];
        FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds =
        (FPFpLogVehicleFuelStationDateDataSourceAndDelegate *)[vehicleFuelStationDateTableView dataSource];
        [ds setPickedLogDate:[fpLog purchasedAt]];
        [vehicleFuelStationDateTableView reloadData];
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
    enabDisab(FPFpLogTagOctane);
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
    UIView *envlogPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:parentView];
    UIView *envlogDataPanel = [PEUIUtils tablePanelWithRowData:@[@[@"Odometer", [PEUtils descriptionOrEmptyIfNil:[envlog odometer]]],
                                                                 @[@"Reported DTE", [PEUtils descriptionOrEmptyIfNil:[envlog reportedDte]]],
                                                                 @[@"Reported avg mpg", [PEUtils descriptionOrEmptyIfNil:[envlog reportedAvgMpg]]],
                                                                 @[@"Reported avg mph", [PEUtils descriptionOrEmptyIfNil:[envlog reportedAvgMph]]],
                                                                 @[@"Reported outside temperature", [PEUtils descriptionOrEmptyIfNil:[envlog reportedOutsideTemp]]]]
                                                     uitoolkit:_uitoolkit
                                                    parentView:parentView];
    NSDictionary *components = [self envlogFormComponentsWithUser:user
                                      displayDisclosureIndicators:NO
                                           defaultSelectedVehicle:[_coordDao vehicleForEnvironmentLog:envlog error:[FPUtils localFetchErrorHandlerMaker]()]
                                             defaultPickedLogDate:[envlog logDate]](parentViewController);
    UITableView *vehicleAndLogDateTableView = components[@(FPEnvLogTagVehicleAndDate)];
    [vehicleAndLogDateTableView setUserInteractionEnabled:NO];
    [PEUIUtils placeView:vehicleAndLogDateTableView
                 atTopOf:envlogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0.0];
    [PEUIUtils placeView:envlogDataPanel
                   below:vehicleAndLogDateTableView
                    onto:envlogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    return envlogPanel;
  };
}

- (PEComponentsMakerBlk)envlogFormComponentsWithUser:(FPUser *)user
                         displayDisclosureIndicators:(BOOL)displayDisclosureIndicators
                              defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle
                                defaultPickedLogDate:(NSDate *)defaultPickedLogDate {
  return ^ NSDictionary * (UIViewController *parentViewController) {
    NSMutableDictionary *components = [NSMutableDictionary dictionary];
    UIView *parentView = [parentViewController view];
    UITableView *vehicleAndLogDateTableView =
    [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)
                                 style:UITableViewStyleGrouped];
    [vehicleAndLogDateTableView setScrollEnabled:NO];
    [vehicleAndLogDateTableView setTag:FPEnvLogTagVehicleAndDate];
    [PEUIUtils setFrameWidthOfView:vehicleAndLogDateTableView ofWidth:1.0 relativeTo:parentView];
    [PEUIUtils setFrameHeight:124.96 ofView:vehicleAndLogDateTableView];
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
                                                     defaultSelectedVehicle:defaultSelectedVehicle
                                                             defaultLogDate:defaultPickedLogDate
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
    components[@(FPEnvLogTagVehicleAndDate)] = vehicleAndLogDateTableView;
    TaggedTextfieldMaker tfMaker =
      [_uitoolkit taggedTextfieldMakerForWidthOf:1.0 relativeTo:parentView];
    UITextField *odometerTf = tfMaker(@"Odometer", FPEnvLogTagOdometer);
    [odometerTf setKeyboardType:UIKeyboardTypeDecimalPad];
    components[@(FPEnvLogTagOdometer)] = odometerTf;
    UITextField *reportedDteTf = tfMaker(@"Reported DTE", FPEnvLogTagReportedDte);
    [reportedDteTf setKeyboardType:UIKeyboardTypeNumberPad];
    components[@(FPEnvLogTagReportedDte)] = reportedDteTf;
    UITextField *reportedAvgMpgTf =
    tfMaker(@"Reported avg mpg", FPEnvLogTagReportedAvgMpg);
    [reportedAvgMpgTf setKeyboardType:UIKeyboardTypeDecimalPad];
    components[@(FPEnvLogTagReportedAvgMpg)] = reportedAvgMpgTf;
    UITextField *reportedAvgMphTf = tfMaker(@"Reported avg mph", FPEnvLogTagReportedAvgMph);
    [reportedAvgMphTf setKeyboardType:UIKeyboardTypeDecimalPad];
    components[@(FPEnvLogTagReportedAvgMph)] = reportedAvgMphTf;
    UITextField *reportedOutsideTempTf =
    tfMaker(@"Reported outside temperature", FPEnvLogTagReportedOutsideTemp);
    [reportedOutsideTempTf setKeyboardType:UIKeyboardTypeNumberPad];
    components[@(FPEnvLogTagReportedOutsideTemp)] = reportedOutsideTempTf;
    return components;
  };
}

- (PEEntityPanelMakerBlk)envlogFormPanelMakerWithUser:(FPUser *)user
                               defaultSelectedVehicle:(FPVehicle *(^)(void))defaultSelectedVehicle
                                 defaultPickedLogDate:(NSDate *)defaultPickedLogDate {
  return ^ UIView * (UIViewController *parentViewController) {
    UIView *parentView = [parentViewController view];
    UIView *envLogPanel = [PEUIUtils panelWithWidthOf:1.0
                                          andHeightOf:1.0
                                       relativeToView:parentView];
    NSDictionary *components = [self envlogFormComponentsWithUser:user
                                      displayDisclosureIndicators:YES
                                           defaultSelectedVehicle:defaultSelectedVehicle()
                                             defaultPickedLogDate:defaultPickedLogDate](parentViewController);
    UITableView *vehicleAndLogDateTableView = components[@(FPEnvLogTagVehicleAndDate)];
    UITextField *odometerTf = components[@(FPEnvLogTagOdometer)];
    UITextField *reportedDteTf = components[@(FPEnvLogTagReportedDte)];
    UITextField *reportedAvgMpgTf = components[@(FPEnvLogTagReportedAvgMpg)];
    UITextField *reportedAvgMphTf = components[@(FPEnvLogTagReportedAvgMph)];
    UITextField *reportedOutsideTempTf = components[@(FPEnvLogTagReportedOutsideTemp)];
    [PEUIUtils placeView:vehicleAndLogDateTableView
                 atTopOf:envLogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0.0];
    [PEUIUtils placeView:odometerTf
                   below:vehicleAndLogDateTableView
                    onto:envLogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:reportedAvgMpgTf
                   below:odometerTf
                    onto:envLogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:reportedDteTf
                   below:reportedAvgMpgTf
                    onto:envLogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:reportedAvgMphTf
                   below:reportedDteTf
                    onto:envLogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:reportedOutsideTempTf
                   below:reportedAvgMphTf
                    onto:envLogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    return envLogPanel;
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
