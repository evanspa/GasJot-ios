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
#import "FPReauthenticateController.h"
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

@interface FPReauthenticateController ()
@property (nonatomic) NSInteger formStateMaskForLightLogin;
@end

@implementation FPReauthenticateController {
  FPCoordinatorDao *_coordDao;
  UITextField *_caPasswordTf;
  CGFloat animatedDistance;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  FPUser *_user;
  NSNumber *_preserveExistingLocalEntities;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(FPCoordinatorDao *)coordDao
                          user:(FPUser *)user
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(FPScreenToolkit *)screenToolkit {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _coordDao = coordDao;
    _user = user;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
  }
  return self;
}

#pragma mark - View Controller Lifecyle

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [_caPasswordTf becomeFirstResponder];
}

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
  [navItem setTitle:@"Re-authenticate"];
  [navItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                               target:self
                                                                               action:@selector(handleLightLogin)]];
}

#pragma mark - GUI construction (making panels)

- (UIView *)panelForAccountCreation {
  UIView *reauthPnl = [PEUIUtils panelWithWidthOf:1.0
                                          andHeightOf:1.0
                                       relativeToView:[self view]];
  [PEUIUtils setFrameHeightOfView:reauthPnl ofHeight:0.5 relativeTo:[self view]];
  TextfieldMaker tfMaker =
    [_uitoolkit textfieldMakerForWidthOf:1.0 relativeTo:reauthPnl];
  _caPasswordTf = tfMaker(@"unauth.start.ca.pwdtf.pht");
  [_caPasswordTf setSecureTextEntry:YES];
  [PEUIUtils placeView:_caPasswordTf
               atTopOf:reauthPnl
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:0.0
              hpadding:0.0];
  RAC(self, formStateMaskForLightLogin) =
    [RACSignal combineLatest:@[_caPasswordTf.rac_textSignal]
                      reduce:^(NSString *password) {
        NSUInteger reauthErrMask = 0;
        if ([password length] == 0) {
          reauthErrMask = reauthErrMask | FPSaveUsrPasswordNotProvided;
        }
        return @(reauthErrMask);
      }];
  return reauthPnl;
}

#pragma mark - Login event handling

- (void)handleLightLogin {
  [[self view] endEditing:YES];
  if (!([self formStateMaskForLightLogin] & FPSignInAnyIssues)) {
    __block MBProgressHUD *HUD;
    void (^successBlk)(void) = ^{
      dispatch_async(dispatch_get_main_queue(), ^{
        [HUD hide:YES];
        NSString *msg = @"You're all set again.  Thank you.";
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success"
                                                                       message:msg
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okay = [UIAlertAction actionWithTitle:@"Okay."
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                       [[self navigationController] popViewControllerAnimated:YES];
                                                     }];
        [alert addAction:okay];
        [self presentViewController:alert animated:YES completion:nil];
      });
    };
    ErrMsgsMaker errMsgsMaker = ^ NSArray * (NSInteger errCode) {
      return [FPUtils computeSignInErrMsgs:errCode];
    };
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.delegate = self;
    HUD.labelText = @"Re-authenticating...";
    [_coordDao lightLoginForUser:_user
                        password:[_caPasswordTf text]
                 remoteStoreBusy:[FPUtils serverBusyHandlerMakerForUI](HUD)
               completionHandler:[FPUtils synchUnitOfWorkZeroArgHandlerMakerWithErrMsgsMaker:errMsgsMaker](HUD, successBlk)
           localSaveErrorHandler:[FPUtils localDatabaseErrorHudHandlerMaker](HUD)];
  } else {
    NSArray *errMsgs = [FPUtils computeSignInErrMsgs:_formStateMaskForLightLogin];
    [PEUIUtils showAlertWithMsgs:errMsgs title:@"oopsMsg" buttonTitle:@"okayMsg"];
  }
}

@end
