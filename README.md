# PEFuelPurchase-App

PEFuelPurchase-App is an iOS application for collecting fuel purchase data.
Its primary purpose is to serve as a reference application for leveraging the
PE* suite of libraries.

The PE* library suite is a set of iOS libraries to aid in the development of
applications.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Dependency Graph](#dependency-graph)
- [PE* iOS Library Suite](#pe-ios-library-suite)
- [Other Libraries used by PEFuelPurchase-App](#other-libraries-used-by-pefuelpurchase-app)
- [Screenshots](#screenshots)
    - [Account Creation / Login](#account-creation--login)
    - [Quick Action Menu (home screen)](#quick-action-menu-home-screen)
    - [Adding a Vehicle](#adding-a-vehicle)
    - [Adding a Fuel Station](#adding-a-fuel-station)
    - [Adding a Fuel Purchase Log](#adding-a-fuel-purchase-log)
    - [Adding an Environment Log](#adding-an-environment-log)
- [Not Yet Implemented](#not-yet-implemented)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Dependency Graph

The following diagram illustrates the main components of the fuel purchase
application, along with showing the dependencies to the PE* suite of libraries.

<img
src="https://github.com/evanspa/PEFuelPurchase-App/raw/master/drawings/PEFuelPurchase-App-Dependency-Graph.png">

## PE* iOS Library Suite
*(Each library is implemented as a CocoaPod-enabled iOS static library.)*
+ **[PEHateoas-Client](https://github.com/evanspa/PEHateoas-Client)**: a library
  for consuming hypermedia REST APIs.  I.e., those that adhere to the *Hypermedia
  As The Engine Of Application State* (HATEOAS) constraint.
+ **[PEWire-Control](https://github.com/evanspa/PEWire-Control)**: a library for
  controlling Cocoa's NSURL loading system using simple XML files.
+ **[PEXML-Utils](https://github.com/evanspa/PEXML-Utils)**: a library
  simplifying working with XML.
+ **[PEObjc-Commons](https://github.com/evanspa/PEObjc-Commons)**: a library
  providing a set of generic helper functionality.
+ **[PEDev-Console](https://github.com/evanspa/PEDev-Console)**: a library
  aiding in the functional testing of iOS applications.
+ **[PESimu-Select](https://github.com/evanspa/PESimu-Select)**: a library
  aiding in the functional testing of web service enabled iOS applications.

## Other Libraries used by PEFuelPurchase-App
+ **[PEFuelPurchase-Common](https://github.com/evanspa/PEFuelPurchase-Common)**:
  contains *application agnostic* constant definitions.
+ **[PEFuelPurchase-Model](https://github.com/evanspa/PEFuelPurchase-Model)**:
  encapsulates the object model, local data access, web service access and core
  logic of the application.

## Screenshots

To give a sense for what the fuel purchase app is about, below is a sample of
actual screenshots.

#### Account Creation / Login

Unfortunately the fuel purchase app suffers from the
[login barrier anti-pattern](http://blog.codinghorror.com/removing-the-login-barrier/).
No worries though, as this app is meant to serve as a reference to using the PE*
library suite, and is not meant for general user adoption.

<img
src="https://github.com/evanspa/PEFuelPurchase-App/raw/master/screenshots/create-acct-login.png"
height="418px" width="237px">

#### Quick Action Menu (home screen)

Main menu screen.  This is the screen that appears after logging in or creating
account.  It's also the default authenticated screen when launching the app
after a login has occured.

<img
src="https://github.com/evanspa/PEFuelPurchase-App/raw/master/screenshots/quick-action-menu.png"
height="418px" width="237px">

#### Adding a Vehicle

Adding a vehicle (which is needed in order to log fuel purchases).

<img
src="https://github.com/evanspa/PEFuelPurchase-App/raw/master/screenshots/add-vehicle.png"
height="418px" width="237px">


#### Adding a Fuel Station

Adding a fuel station (which is needed in order to log fuel purchases).

<img
src="https://github.com/evanspa/PEFuelPurchase-App/raw/master/screenshots/add-fuelstation.png"
height="418px" width="237px">

#### Adding a Fuel Purchase Log

Adding a fuel purchase log requires the user to pick the associated vehicle and
fuel station.

<img
src="https://github.com/evanspa/PEFuelPurchase-App/raw/master/screenshots/add-fplog.png"
height="418px" width="237px">

#### Adding an Environment Log

We can also log things about the "environment" vis-a-vis one of our vehicles.

<img
src="https://github.com/evanspa/PEFuelPurchase-App/raw/master/screenshots/add-envlog.png"
height="418px" width="237px">

## Not Yet Implemented

As of this writing, none of the reporting functionality has been implemented
yet (but will be in the future).  Currently all you can do is log data.
