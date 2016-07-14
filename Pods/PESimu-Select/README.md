# PESimu-Select

[![Build Status](https://travis-ci.org/evanspa/PESimu-Select.svg)](https://travis-ci.org/evanspa/PESimu-Select)

PESimu-Select is an iOS static library providing a view controller for the purpose of selecting what we call a "simulation" for the purpose of faking Cocoa's URL loading system in order to return controlled mock HTTP responses to web service calls.

PESimu-Select works on top of
[PEWire-Control](https://github.com/evanspa/PEWire-Control).

PESimu-Select is also a part of the
[PE* iOS Library Suite](#pe-ios-library-suite).

**Table of Contents**

- [Motivation](#motivation)
- [How To Use It](#how-to-use-it)
    - [1. Creating Mock HTTP Response XML Files](#1-creating-mock-http-response-xml-files)
    - [2. Incorporate PESimu-Select's simulation selection view controller into your application.](#2-incorporate-pesimu-selects-simulation-selection-view-controller-into-your-application)
- [Installation with CocoaPods](#installation-with-cocoapods)
- [PE* iOS Library Suite](#pe-ios-library-suite)

## Motivation

Imagine you are building an iPhone app that presents a screen allowing the user to either Log In or Create an Account.  For each of these 2 use cases, the app would presumably make a web service call to your server as part of carrying out the selected use case.  Let us also imagine that at the time you are developing your screens, the web services don't exist yet (they are being developed in parallel to the app by server dev folks).  What do you do?  You have several options; some more complex than others.  The simplest option is too simply not make any web service calls, and have your app hard-coded to allow you to move on to the next screen.

The problem is, you'd like to be able to development and test the "full stack" of your application.  I.e., you want to be able to develop and test the code that actually makes a web service call, serializes / deserializes requests and responses, handles failure modes properly, etc.  Enter PESimu-Select.

With PESimu-Select, you simply create a set of XML files representing HTTP responses for the various use cases associated with your application.  PESimu-Select provides a view controller that you can incorporate into a dev build of your app, allowing you to test various web service response scenarios.  In this way, you can develop the full stack of your application and exercise it in complete isolation.

## How To Use It

##### 1. Creating Mock HTTP Response XML Files

+ Create a folder: "application-screens/" within your application project folder.
+ For each screen of your iOS app in which a web service call might be made, create a folder for that screen.  E.g., if you have a "Log In or Create Account" screen, create the folder: "unauthenticated-landing-screen/" under your "application-screens/" folder.

*FYI, PESimu-Select's design is such that it believes for each screen of an application, mutliple use cases may be exercised.  E.g.., in our "Log In or Create Account" screen, there are really 2 use cases in play: (1) logging in, and (2) creating an account.*

At this point we have the following folder structure:
```
application-screens/
  unauthenticated-landing-screen/
```
Underneath "unauthenticated-landing-screen/", create a folder for each use case that is in-play with this screen.  In our case, those use cases are: logging in and creating an account.  It doesn't matter what you name them.  Choose good, terse names.  Now our folder structure should be something like:
```
application-screens/
  unauthenticated-landing-screen/
    create-account/
    login/
```
Now we're ready to create our actual XML HTTP response files.  For the specific syntax of these files, refer to [PEWire-Control](https://github.com/evanspa/PEWire-Control)'s documentation.  The idea is, for each scenario you want to test, create an XML HTTP response capturing that scenario.  E.g., for the login use case, the server team's web service design may stipulate that for incorrect login attempts, an HTTP status code of 401 is returned, with some sort of message in the response body, formatted as JSON.  For a successful login, the response might be a 200, with the user's profile information contained in the body and an authentication token in a cookie.  For each possible scenario you want to account for, create an XML HTTP response file in that usecase's folder.  After doing this, your folder structure may look like this:
```
application-screens/
  unauthenticated-landing-screen/
    create-account/
      fail-user-already-registered.xml
      success-test-user-0.xml
    login/
      fail-server-failure.xml
      fail-unknown-username.xml
      success-test-user-0.xml
      success-test-user-1.xml
```
As you can see, we can create mock HTTP response XML files for a wide range of scenarios, including server errors (where the response status code would be 500) and client errors (4XX response codes).

Finally, you'll need to add your root "application-screens/" folder to your Xcode project.  Generally you'll want to hang this folder off your application's "Supporting Files" folder.

##### 2. Incorporate PESimu-Select's simulation selection view controller into your application.

In your application's delegate .h file, put the following import statement:
```objective-c
#import <PESimu-Select/SSELUtils.h>
```
Declare as a property:

```objective-c
@property (nonatomic) SSELUtils *sselutils;
```
And in your application:didFinishLaunchingWithOptions: method, instantiate your _sselutils instance providing the name of your top-level screens folder:
```objective-c
_sselutils = [SSELUtils utilsWithBaseResourceFolder:@"application-screens"];
```
Because each view controller will need access to our _sselutils instance, and you probably don't want to have to pass it as an argument to each view controller's initializer (after all, our _sselutils instance is really just a dev tool), define a macro in your AppDelegate.h file like so ([as per this SO answer](http://stackoverflow.com/a/4141202/1034895)):
```objective-c
#define AppDelegate (YourAppDelegate *)[[UIApplication sharedApplication] delegate]
```
Now each of your view controller's can simply do: `[YourAppDelegate sselutils]` to get a handle to it.

In your view controller's `viewDidLoad` method, add the following line (in this example, assume this is our "UnauthenticatedLandingScreen" UIViewController subclass)
```objective-c
[[YourAppDelegate sselutils] addSimulationTogglerForScreen:@"unauthenticated-landing-screen"
                                        ontoViewController:self];
```
Notice we specify the name of the "screen" folder this view controller corresponds to.  `addSimulationTogglerForScreen:ontoViewController:` will add a button to the top-right portion of the view controller's view that when tapped, will bring up the PESimu-Select's simulation selection screen.  FYI, PESimu-Select comes with a demo app that implements these steps.  Here's a graphic illustrating the flow:

<img
src="https://github.com/evanspa/PESimu-Select/raw/master/screenshots/PESimu-Select-S1.png"
height="418px" width="532px">

FYI, for this demo app, for the sake of brevity, I only have 2 mock HTTP XML
files defined for the 'create account' use case, and 2 for the 'login' use
case.  Here's how the folder structure looks in Xcode:

<img
src="https://github.com/evanspa/PESimu-Select/raw/master/screenshots/PESimu-Select-S2.png">

Notice that our "Use Case Simulations" screen is driven precisely from our
folder structure:

<img
src="https://github.com/evanspa/PESimu-Select/raw/master/screenshots/PESimu-Select-S3.png"
height="418px" width="575px">

*FYI, the table view section titles are driven by the use case folder names.
 The title and subtitles of the table views are driven by the
 `/http-response/annotation/@name` and `/http-response/annotation` values from
 the corresponding XML files.*

At this point you can tap to select a simulation for each use case and
optionally choose to enact request and response latencies (in seconds):

<img
src="https://github.com/evanspa/PESimu-Select/raw/master/screenshots/PESimu-Select-S4.png"
height="418px" width="237px">

Tap 'Done' to enable the simulations (this is the equivalent of using [PEWire-Control](https://github.com/evanspa/PEWire-Control)
 --- *which uses [OHHTTPStubs](https://github.com/AliSoftware/OHHTTPStubs)*) to fake Cocoa's URL loading system to respond
 with those HTTP responses as appropriate.  To clear the simulations and return
 to normal, tap the 'Clear Simulations' button.

If you do not want to have a blue "Toggle Simulations" button appearing at the
top of your view controllers, you can use a shake gesture to bring up the
simulation selector screen.  To do this, in your app delegate, import
SSELUIWindow:

```objective-c
#import <PESimu-Select/SSELUIWindow.h>
```
and replace `UIWindow` with `SSELUIWindow` when instantiating `self.window`
inside application:didFinishLaunchingWithOptions:
```objective-c
self.window = [[SSELUIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
```
And then in your view controllers, use:
```objective-c
[[YourAppDelegate sselutils] reactToShakeGestureForScreen:@"unauthenticated-landing-screen"
                                       ontoViewController:self];
```

All of these steps can be found implemented in the demo app .

## Installation with CocoaPods

```ruby
pod 'PESimu-Select', '~> 1.0.4'
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
+ **PESimu-Select**: this library.
+ **[PEDev-Console](https://github.com/evanspa/PEDev-Console)**: a library
  aiding in the functional testing of iOS applications.
