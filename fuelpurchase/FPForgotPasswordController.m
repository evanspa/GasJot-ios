// Copyright (C) 2013 Paul Evans
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

#import <ReactiveCocoa/UITextField+RACSignalSupport.h>
#import <ReactiveCocoa/RACSubscriptingAssignmentTrampoline.h>
#import <ReactiveCocoa/RACSignal+Operations.h>
#import <ReactiveCocoa/RACDisposable.h>
#import <PEObjc-Commons/PEUIUtils.h>
#import <PEObjc-Commons/PEUtils.h>
#import <PEFuelPurchase-Model/FPErrorDomainsAndCodes.h>
#import "FPForgotPasswordController.h"
#import "FPUtils.h"
#import "FPAppNotificationNames.h"
#import "FPNames.h"
#import <FlatUIKit/UIColor+FlatUI.h>
#import "FPUIUtils.h"
#import "FPPanelToolkit.h"

#ifdef FP_DEV
  #import <PEDev-Console/UIViewController+PEDevConsole.h>
#endif

@interface FPForgotPasswordController ()
@property (nonatomic) NSInteger formStateMask;
@end

@implementation FPForgotPasswordController {
  FPCoordinatorDao *_coordDao;
  UITextField *_emailTf;
  CGFloat animatedDistance;
  PEUIToolkit *_uitoolkit;
  FPUser *_user;
  RACDisposable *_disposable;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(FPCoordinatorDao *)coordDao
                          user:(FPUser *)user
                     uitoolkit:(PEUIToolkit *)uitoolkit {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _coordDao = coordDao;
    _user = user;
    _uitoolkit = uitoolkit;
  }
  return self;
}

#pragma mark - Cancel

- (void)cancel {
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - View Controller Lifecyle

- (void)viewDidLoad {
  [super viewDidLoad];
  #ifdef FP_DEV
    [self pdvDevEnable];
  #endif
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  UINavigationItem *navItem = [self navigationItem];
  [navItem setTitle:@"Forgot Password"];
  [navItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                              target:self
                                                                              action:@selector(cancel)]];
  [navItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                               target:self
                                                                               action:@selector(handleSendPasswordResetLink)]];
  [_emailTf becomeFirstResponder];
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:self.view fixedHeight:0.0];
  CGFloat leftPadding = 8.0;
  [PEUIUtils setFrameHeightOfView:contentPanel ofHeight:0.5 relativeTo:[self view]];
  UILabel *messageLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:@"Enter your email address and hit %@ and we'll send you an email with a link to reset your password."
                                                                                     textToAccent:@"Done"
                                                                                   accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]]
                                                       font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                            backgroundColor:[UIColor clearColor]
                                                  textColor:[UIColor darkGrayColor]
                                        verticalTextPadding:3.0
                                                 fitToWidth:(contentPanel.frame.size.width - leftPadding - 10.0)];
  UIView *messageLabelWithPad = [PEUIUtils leftPadView:messageLabel padding:leftPadding];
  TextfieldMaker tfMaker = [_uitoolkit textfieldMakerForWidthOf:1.0 relativeTo:contentPanel];
  _emailTf = tfMaker(@"unauth.start.ca.emailtf.pht");
  // if 'Login' screen, _user will be nil; if 'Re-authenticate' screen, _user will NOT be nil
  if (_user) {
    [_emailTf setText:[_user email]];
  }

  // place views
  [PEUIUtils placeView:_emailTf
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:FPContentPanelTopPadding
              hpadding:0.0];
  CGFloat totalHeight = _emailTf.frame.size.height + FPContentPanelTopPadding;
  [PEUIUtils placeView:messageLabelWithPad
                 below:_emailTf
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  totalHeight += messageLabelWithPad.frame.size.height + 4.0;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  [_disposable dispose];
  RACSignal *signal = [RACSignal combineLatest:@[_emailTf.rac_textSignal]
                                        reduce:^(NSString *email) {
                                          // will just re-use existing 'save user' error codes for validation
                                          NSUInteger emailErrMask = 0;
                                          if ([email length] == 0) {
                                            emailErrMask = emailErrMask | FPSaveUsrEmailNotProvided | FPSaveUsrAnyIssues;
                                          } else if (![PEUtils validateEmailWithString:email]) {
                                            emailErrMask = emailErrMask | FPSaveUsrInvalidEmail | FPSaveUsrAnyIssues;
                                          }
                                          return @(emailErrMask);
                                        }];
  _disposable = [signal setKeyPath:@"formStateMask" onObject:self nilValue:nil];
  return @[contentPanel, @(YES), @(NO)];
}

#pragma mark - Login event handling

- (void)handleSendPasswordResetLink {
  FPEnableUserInteractionBlk enableUserInteraction = ^(BOOL enable) {
    [APP enableJotButton:enable];
    [[[self navigationItem] leftBarButtonItem] setEnabled:enable];
    [[[self navigationItem] rightBarButtonItem] setEnabled:enable];
    [[[self tabBarController] tabBar] setUserInteractionEnabled:enable];
  };
  [self.view endEditing:YES];
  if (!([self formStateMask] & FPSignInAnyIssues)) {
    MBProgressHUD *sendPasswordResetEmailHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    enableUserInteraction(NO);
    sendPasswordResetEmailHud.labelText = @"Sending password reset email...";
    NSString *emailAddress = [_emailTf text];
    [_coordDao sendPasswordResetEmailToEmail:emailAddress
                          remoteStoreBusyBlk:^(NSDate *retryAfter) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                              [sendPasswordResetEmailHud hide:YES afterDelay:0.0];
                              [PEUIUtils showWaitAlertWithMsgs:nil
                                                         title:@"Busy with maintenance."
                                              alertDescription:[[NSAttributedString alloc] initWithString:@"\
                                                                The server is currently busy at the moment undergoing maintenance.\n\n\
                                                                We apologize for the inconvenience.  Please try this again later."]
                                                      topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                   buttonTitle:@"Okay."
                                                  buttonAction:^{ enableUserInteraction(YES); }
                                                relativeToView:self.tabBarController.view];
                            });
                          }
                                  successBlk:^{
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                      [sendPasswordResetEmailHud hide:YES afterDelay:0.0];
                                      NSAttributedString *attrMessage =
                                      [PEUIUtils attributedTextWithTemplate:@"The password reset email was sent to: %@."
                                                               textToAccent:emailAddress
                                                             accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]];
                                      [PEUIUtils showSuccessAlertWithTitle:@"Password reset e-mail sent."
                                                          alertDescription:attrMessage
                                                                  topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                               buttonTitle:@"Okay."
                                                              buttonAction:^{
                                                                [self dismissViewControllerAnimated:YES completion:^{
                                                                  enableUserInteraction(YES);
                                                                }];
                                                              }
                                                            relativeToView:self.view];
                                    });
                                  }
                             unknownEmailBlk:^{
                               dispatch_async(dispatch_get_main_queue(), ^{
                                 [sendPasswordResetEmailHud hide:YES afterDelay:0.0];
                                 [PEUIUtils showErrorAlertWithMsgs:nil
                                                             title:@"Unknown e-mail address."
                                                  alertDescription:[[NSAttributedString alloc] initWithString:@"\
                                                                    The email address you provided is not associated with any Gas Jot accounts."]
                                                          topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                       buttonTitle:@"Okay."
                                                      buttonAction:^{ enableUserInteraction(YES); }
                                                    relativeToView:self.view];
                               });
                             }
                                    errorBlk:^{
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                        [sendPasswordResetEmailHud hide:YES afterDelay:0.0];
                                        [PEUIUtils showErrorAlertWithMsgs:nil
                                                                    title:@"Something went wrong."
                                                         alertDescription:[[NSAttributedString alloc] initWithString:@"\
                                                                           Oops.  Something went wrong in attempting to send you a password reset email.  Please try this again a little later."]
                                                                 topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                              buttonTitle:@"Okay."
                                                             buttonAction:^{ enableUserInteraction(YES); }
                                                           relativeToView:self.view];
                                      });
                                    }];
  } else {
    NSArray *errMsgs = [FPUtils computeSaveUsrErrMsgs:_formStateMask];
    [PEUIUtils showWarningAlertWithMsgs:errMsgs
                                  title:@"Oops"
                       alertDescription:[[NSAttributedString alloc] initWithString:@"There are some validation errors:"]
                               topInset:[PEUIUtils topInsetForAlertsWithController:self]
                            buttonTitle:@"Okay."
                           buttonAction:nil
                         relativeToView:self.view];
  }
}

@end
