# PEDev-Console

[![Build Status](https://travis-ci.org/evanspa/PEDev-Console.svg)](https://travis-ci.org/evanspa/PEDev-Console)

PEDev-Console is an iOS static library for simplifying the development process
of iOS applications.  It provides a view controller that integrates into your
application that enables you to jump to any screen of your application
instantly.  It also includes the functionality of [PESimu-Select](https://github.com/evanspa/PESimu-Select) in order to
enable HTTP response simulations.

PEDev-Console is part of the
[PE* iOS Library Suite](#pe-ios-library-suite).


**Table of Contents**

- [Motivation](#motivation)
- [Setup Guide](#setup-guide)
- [Screenshots](#screenshots)
- [Demo Application](#demo-application)
- [Installation with CocoaPods](#installation-with-cocoapods)
- [PE* iOS Library Suite](#pe-ios-library-suite)

## Motivation

When developing an iOS application, the development of view controllers in
particular can be particularly painstakingly iterative in nature.  This becomes
more pronounced when developing views programmatically (i.e., not using
interface builder).  The ability to see the results of your code changes quickly
is very important to developer-productivity.

You may often find yourself working on a particular screen of your application
that is buried deeply underneath many other screens.  Testing changes to this
screen usually involves running the app, and manually navigating to the screen.
If the screens above it require things like forms to be filled-out properly,
etc, the workflow can soon become very slow and cumbersome.

PEDev-Console attempts to fix this situation.  The idea is simple: after
application launch, give your device a shake.  The PEDev-Console dev console
will appear, giving you a choice to view the full set of screens contained in
your application.  Simply tap the screen you want, and it will be instantiated
and presented.  As a bonus, from the dev console you can also --- *if
configured*  --- choose an HTTP response simulation to activate (*provided by
[PESimu-Select](https://github.com/evanspa/PESimu-Select) integration*).

## Setup Guide

Have your app delegate conform to the PDVDevEnabled protocol.

```objective-c
#import "PDVDevEnabled.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, PDVDevEnabled>
```

*This step is to enable PESimu-Select functionality.*  Create a folder called
 **application-screens**.  In this folder, create a sub folder for each screen
 of your application in which you want to integrate PESimu-Select
 functionality.  Within each screen folder, create a folder for each use case
 the screen supports.  For each use case folder, create a PESimu-Select
 simulation XML file for each HTTP response scenario you wish to test.  The
 following screenshot shows our folder setup for PEDev-Console's demo application:

<img
src="https://github.com/evanspa/PEDev-Console/raw/master/screenshots/PESimu-Select-folders.png">

In your application delegate, declare a class-level PDVUtils instance:

```objective-c
@implementation AppDelegate {
  PDVUtils *_pdvUtils;
}
```

In your application delegate, instead of instantiating `UIWindow`, use
`PDVUIWindow`.  Also, instantiate your `_pdvUtils` instance (*be sure to provide
the correct name of your base screens folder name*):

```objective-c
- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [self setWindow:[[PDVUIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]]];
  _pdvUtils = [[PDVUtils alloc] initWithBaseResourceFolderOfSimulations:@"application-screens"
                                                           screenGroups:[self screenGroups]];
```

In your application delegate, implement the `screenGroups` getter:

```objective-c
- (NSArray *)screenGroups {
NSArray *unauthenticatedScreens =
  @[ // Create Account screen
     [[PDVScreen alloc] initWithDisplayName:@"Create Account"
                                description:@"Create Account screen."
                        viewControllerMaker:^{return
                        [[PDVCreateAccountController alloc] init];}],
     // Login screen
     [[PDVScreen alloc] initWithDisplayName:@"Log In"
                                description:@"Log In screen."
                        viewControllerMaker:^{return [[PDVLoginController alloc] init];}]];
  PDVScreenGroup *unauthenticatedScreenGroup =
    [[PDVScreenGroup alloc] initWithName:@"Unauthenticated Screens"
                                 screens:unauthenticatedScreens];

  NSArray *authenticatedScreens =
    @[ // Authenticated landing screen
       [[PDVScreen alloc] initWithDisplayName:@"Authenticated Landing"
                                  description:@"Authenticated landing screen of pre-existing user with resident auth token."
                          viewControllerMaker:^{return [[PDVAuthenticatedLandingController alloc] init];}]];
  PDVScreenGroup *authenticatedScreenGroup =
    [[PDVScreenGroup alloc] initWithName:@"Authenticated Screens"
                                 screens:authenticatedScreens];
  return @[ unauthenticatedScreenGroup, authenticatedScreenGroup ];
}
```

What's going on here is that for each screen in your application, you'll create
a `PDVScreen` instance to serve as a sort of container for it.  These
`PDVScreen` instances are used by PEDev-Console's screen selection view
controller.  Each `PDVScreen` instance is given a block (with signature:
`UIViewController *(^)(void)`) that is used to instantiate your view controller
if the user selects it from the screen selection controller.  You also need to
group each `PDVScreen` instance within a `PDVScreenGroup` instance.  The purpose
of `PDVScreenGroup` is to give you a basic mechanism for grouping
logically-related screens.  These groups are then used for creating the
table-sections of the PEDev-Console screen selection controller's table view.

Next, in our application delegate, we implement the 2 methods from the
`PDVDevEnabled` protocol:

```objective-c
- (PDVUtils *)pdvUtils {
  return _pdvUtils;
}
```

```objective-c
- (NSDictionary *)screenNamesForViewControllers {
  return @{
    NSStringFromClass([PDVCreateAccountController class]) : @"create-account-screen",
    NSStringFromClass([PDVLoginController class]) : @"login-screen",
    NSStringFromClass([PDVAuthenticatedLandingController class]) : @"authenticated-landing-screen"
  };
}

```
The purpose of `screenNamesForViewControllers` is to map the classes of your
application view controllers to the their corresponding PESimu-Select HTTP
response simulation folders.

<img
src="https://github.com/evanspa/PEDev-Console/raw/master/screenshots/PEDev-Console-mapping.png">

Finally, in each of your application view controllers, include the following
import:

```objective-c
#import "UIViewController+PEDevConsole.h"
```

And in your `viewDidLoad` method, include the following line:

```objective-c
// enables PEDev-Console integration
[self pdvDevEnable];
```
By doing this, a simple shake of the device will launch the dev console.

## Screenshots

The following are taken from the DemoApp.  The DemoApp has an initial launch
screen, and 3 application screens (*Log In*, *Create Account* and *Authenticated
Home*).  Funny thing is, none of the application screens are accessible from the
launch screen :)

First we launch the app.

<img
src="https://github.com/evanspa/PEDev-Console/raw/master/screenshots/PEDev-Console-Demo-s1.png"
height="418px" width="237px">

Shaking the device presents the dev console screen.

<img
src="https://github.com/evanspa/PEDev-Console/raw/master/screenshots/PEDev-Console-Demo-s2.png"
height="418px" width="237px">

From here we have 2 basic options: get our list of application screens, or bring
up the list of HTTP response simulations (PESimu-Select).  If we tap to view our
applications screens, we get:

<img
src="https://github.com/evanspa/PEDev-Console/raw/master/screenshots/PEDev-Console-Demo-s3.png"
height="418px" width="237px">

Here we see our 3 application screens, organized into 2 groups.  We'll tap on
'Create Account' to launch that screen.

<img
src="https://github.com/evanspa/PEDev-Console/raw/master/screenshots/PEDev-Console-Demo-s4.png"
height="418px" width="237px">

Voila!  Lets shake again, and this time tap to view the set of available HTTP
response simulations:

<img
src="https://github.com/evanspa/PEDev-Console/raw/master/screenshots/PEDev-Console-Demo-s5.png"
height="418px" width="237px">

Now lets assume we tapped the 'Log In' row from the screen selector.  Here we
see our app's log in screen:

<img
src="https://github.com/evanspa/PEDev-Console/raw/master/screenshots/PEDev-Console-Demo-s6.png"
height="418px" width="237px">

Shaking and tapping to view our HTTP response simulations gives us:

<img
src="https://github.com/evanspa/PEDev-Console/raw/master/screenshots/PEDev-Console-Demo-s7.png"
height="418px" width="237px">

Notice that the set of HTTP response simulations available is based on our
current screen - the log in screen.

## Demo Application

The DemoApp is a working application illustrating how to use PEDev-Console.

## Installation with CocoaPods

```ruby
pod 'PEDev-Console', '~> 1.0.5'
```

## PE* iOS Library Suite
*(Each library is implemented as a CocoaPod-enabled iOS static library.)*
+ **[PEObjc-Commons](https://github.com/evanspa/PEObjc-Commons)**: a library
  providing a set of everyday helper functionality.
+ **[PEXML-Utils](https://github.com/evanspa/PEXML-Utils)**: a library
  simplifying working with XML.  Built on top of [KissXML](https://github.com/robbiehanson/KissXML).
+ **[PEHateoas-Client](https://github.com/evanspa/PEHateoas-Client)**: a library
  for consuming hypermedia REST APIs.  I.e. those that adhere to the *Hypermedia
  As The Engine Of Application State ([HATEOAS](http://en.wikipedia.org/wiki/HATEOAS))* constraint.  Built on top of [AFNetworking](https://github.com/AFNetworking/AFNetworking).
+ **[PEWire-Control](https://github.com/evanspa/PEWire-Control)**: a library for
  controlling Cocoa's NSURL loading system using simple XML files.  Built on top of [OHHTTPStubs](https://github.com/AliSoftware/OHHTTPStubs).
+ **[PEAppTransaction-Logger](https://github.com/evanspa/PEAppTransaction-Logger)**: a
  library client for the PEAppTransaction Logging Framework.  Clojure-based libraries exist implementing the server-side [core data access](https://github.com/evanspa/pe-apptxn-core) and [REST API functionality](https://github.com/evanspa/pe-apptxn-restsupport).
+ **[PESimu-Select](https://github.com/evanspa/PESimu-Select)**: a library
  aiding in the functional testing of web service enabled iOS applications.
+ **PEDev-Console**: this library.
