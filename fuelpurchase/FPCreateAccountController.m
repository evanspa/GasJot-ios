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
#import <PEObjc-Commons/PEUIUtils.h>
#import <PEFuelPurchase-Model/FPErrorDomainsAndCodes.h>
#import "FPCreateAccountController.h"
#import "FPAuthenticationAssertionSerializer.h"
#import "FPUserSerializer.h"
#import "FPAuthenticationAssertion.h"
#import "FPQuickActionMenuController.h"
#import "FPUtils.h"
#import "NSObject+appdelegate.h"
#import "FPAppNotificationNames.h"
#import "FPNames.h"

#ifdef FP_DEV
  #import <PEDev-Console/UIViewController+PEDevConsole.h>
#endif

@interface FPCreateAccountController ()
@property (nonatomic) NSUInteger formStateMaskForAcctCreation;
@property (nonatomic) NSUInteger formStateMaskForSignIn;
@end

@implementation FPCreateAccountController {
  FPCoordinatorDao *_coordDao;
  UITextField *_caFullNameTf;
  UITextField *_caEmailOrUsernameTf;
  UITextField *_caPasswordTf;
  CGFloat animatedDistance;
  MBProgressHUD *_HUD;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  FPUser *_localUser;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(FPCoordinatorDao *)coordDao
                     localUser:(FPUser *)localUser
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(FPScreenToolkit *)screenToolkit {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _coordDao = coordDao;
    _localUser = localUser;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
  }
  return self;
}

#pragma mark - View Controller Lifecyle

- (void)viewDidLoad {
  [super viewDidLoad];
  #ifdef FP_DEV
    [self pdvDevEnable];
  #endif
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  [PEUIUtils placeView:[self panelForAccountCreation]
               atTopOf:[self view]
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:100.0
              hpadding:0.0];
  UINavigationItem *navItem = [self navigationItem];
  [navItem setTitle:@"Create Account"];
  [navItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                               target:self
                                                                               action:@selector(handleAccountCreation)]];
  [_caFullNameTf becomeFirstResponder];
}

#pragma mark - GUI construction (making panels)

- (UIView *)panelForAccountCreation {
  PanelMaker pnlMaker = [_uitoolkit contentPanelMakerRelativeTo:[self view]];
  UIView *createAcctPnl = pnlMaker(1.0);
  TextfieldMaker tfMaker =
    [_uitoolkit textfieldMakerForWidthOf:1.0 relativeTo:createAcctPnl];
  _caFullNameTf = tfMaker(@"unauth.start.ca.fullnametf.pht");
  [PEUIUtils placeView:_caFullNameTf
               atTopOf:createAcctPnl
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:0.0
              hpadding:0.0];
  _caEmailOrUsernameTf = tfMaker(@"unauth.start.ca.emailorusernametf.pht");
  [PEUIUtils placeView:_caEmailOrUsernameTf
                 below:_caFullNameTf
                  onto:createAcctPnl
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:5
              hpadding:0];
  _caPasswordTf = tfMaker(@"unauth.start.ca.pwdtf.pht");
  [_caPasswordTf setSecureTextEntry:YES];
  [PEUIUtils placeView:_caPasswordTf
                 below:_caEmailOrUsernameTf
                  onto:createAcctPnl
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:5
              hpadding:0];

  RAC(self, formStateMaskForAcctCreation) =
    [RACSignal combineLatest:@[_caFullNameTf.rac_textSignal,
                               _caEmailOrUsernameTf.rac_textSignal,
                               _caPasswordTf.rac_textSignal]
                      reduce:^(NSString *fullName,
                               NSString *emailOrUsername,
                               NSString *password) {
        NSUInteger createUsrErrMask = 0;
        if ([emailOrUsername length] == 0) {
          createUsrErrMask = createUsrErrMask | FPSaveUsrUsernameAndEmailNotProvided
              | FPSaveUsrAnyIssues;
        }
        if ([password length] == 0) {
          createUsrErrMask = createUsrErrMask | FPSaveUsrPasswordNotProvided |
              FPSaveUsrAnyIssues;
        }
        return @(createUsrErrMask);
      }];
  return createAcctPnl;
}

#pragma mark - Event handling

- (void)handleAccountCreation {
  if (!([self formStateMaskForAcctCreation] & FPSaveUsrAnyIssues)) {
    _HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _HUD.delegate = self;
    _HUD.labelText = @"Creating Account...";
    NSString *emailOrUsername = [_caEmailOrUsernameTf text];
    NSString *email = nil;
    NSString *username = nil;
    if ([emailOrUsername containsString:@"@"]) {
      email = emailOrUsername;
    } else {
      username = emailOrUsername;
    }
    [_localUser setName:[_caFullNameTf text]];
    [_localUser setEmail:email];
    [_localUser setUsername:username];
    [_localUser setPassword:[_caPasswordTf text]];
    void (^successBlock)(FPUser *) = ^(FPUser *newUser){
      dispatch_async(dispatch_get_main_queue(), ^{
        [_HUD hide:YES afterDelay:0];
        NSString *msg = @"Your account has been created successfully.";
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success"
                                                                       message:msg
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okay = [UIAlertAction actionWithTitle:@"Okay."
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                       [[NSNotificationCenter defaultCenter] postNotificationName:FPAppAccountCreationNotification
                                                                                                           object:nil
                                                                                                         userInfo:nil];
                                                       [[self navigationController] popViewControllerAnimated:YES];
                                                     }];
        [alert addAction:okay];
        [self presentViewController:alert animated:YES completion:nil];
      });
    };
    ErrMsgsMaker errMsgsMaker = ^ NSArray * (NSInteger errCode) {
      return [FPUtils computeSaveUsrErrMsgs:errCode];
    };
    [_coordDao
      establishRemoteAccountForLocalUser:_localUser
           preserveExistingLocalEntities:YES
                         remoteStoreBusy:[FPUtils serverBusyHandlerMakerForUI](_HUD)
                       completionHandler:[FPUtils synchUnitOfWorkHandlerMakerWithErrMsgsMaker:errMsgsMaker](_HUD, successBlock)
                   localSaveErrorHandler:[FPUtils localDatabaseErrorHudHandlerMaker](_HUD)];
  } else {
    NSArray *errMsgs = [FPUtils computeSaveUsrErrMsgs:_formStateMaskForAcctCreation];
    [PEUIUtils showAlertWithMsgs:errMsgs title:@"oopsMsg" buttonTitle:@"okayMsg"];
  }
}

@end
