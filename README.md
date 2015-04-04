# PEFuelPurchase-App

[![Build Status](https://travis-ci.org/evanspa/PEFuelPurchase-App.svg)](https://travis-ci.org/evanspa/PEFuelPurchase-App)

PEFuelPurchase-App is an iOS application for collecting fuel purchase data.
Its primary purpose is to serve as a reference application for leveraging the
PE* suite of libraries, including the [PEAppTransaction Logging Framework](#peapptransaction-logging-framework).

The PE* library suite is a set of iOS libraries to aid in the development of
applications.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Component Layering](#component-layering)
- [Deep Dependency Graph](#deep-dependency-graph)
- [App-specific Libraries used by PEFuelPurchase-App](#app-specific-libraries)
- [PE* iOS Library Suite](#pe-ios-library-suite)
- [PEAppTransaction Logging Framework](#peapptransaction-logging-framework)
  - [Motivation](#motivation)
- [Screenshots](#screenshots)
    - [Account Creation / Login](#account-creation--login)
    - [Quick Action Menu (home screen)](#quick-action-menu-home-screen)
    - [Adding a Vehicle](#adding-a-vehicle)
    - [Adding a Fuel Station](#adding-a-fuel-station)
    - [Adding a Fuel Purchase Log](#adding-a-fuel-purchase-log)
    - [Adding an Environment Log](#adding-an-environment-log)
    - [Not Yet Implemented](#not-yet-implemented)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Component Layering

The following diagram attempts to illustrate the layered architecture of the
fuel purchase application.  The [fuel purchase model](#app-specific-libraries)
appears largest because it encapsulates the bulk of the application; the core
logic, model and data access functionality.

<img
src="https://github.com/evanspa/PEFuelPurchase-App/raw/master/drawings/PEFuelPurchase-App-Component-Layers.png">

## Deep Dependency Graph

The following diagram attempts to illustrates the main components of the fuel purchase
application, along with showing the dependencies to the PE* suite of libraries.

<img
src="https://github.com/evanspa/PEFuelPurchase-App/raw/master/drawings/PEFuelPurchase-App-Dependency-Graph.png">

## App Specific Libraries
*(The following libraries are specific to the fuel purchase application domain, but are not GUI-related.)*
+ **[PEFuelPurchase-Common](https://github.com/evanspa/PEFuelPurchase-Common)**:
  contains *application agnostic* constant definitions.
+ **[PEFuelPurchase-Model](https://github.com/evanspa/PEFuelPurchase-Model)**:
  encapsulates the object model, local data access, web service access and core
  logic of the application.  This library effectively implements the *core* of the fuel purchase application domain.  The fuel purchase iOS application (*this repo*) is dependent on it for all its core logic, model and data access / persistence functionality.  This library for example, could be used to create a command-line version of the fuel purchase application.

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
+ **[PEDev-Console](https://github.com/evanspa/PEDev-Console)**: a library
  aiding in the functional testing of iOS applications.

## PEAppTransaction Logging Framework

The PEAppTransaction Logging Framework (PELF) is a framework for capturing important
events within your applications.  It is comprised of 3 main tiers: (1)
[the core data layer](https://github.com/evanspa/pe-apptxn-core), (2)
[the web service layer](https://github.com/evanspa/pe-apptxn-restsupport)
and (3) client libraries ([currently only iOS](https://github.com/evanspa/PEAppTransaction-Logger)).

The PELF provides a small set of functions to log what are termed "application
transactions."  An application transaction is not a transaction in a database
sense; it is meant more to model application-level actions.  For example, a user
creating a new purchase order within your application would be termed as an
application transaction.  A user signing in to your application would be an
application transaction.  A user signing out, another.

The PELF provides both client-side and server-side libraries.  PELF client-side
libraries are used by applications (*such as this one*) to locally record
user-initiated application transactions and transaction events.  Transaction
events are simply timestamped events associated with an application transaction.
E.g., if "create a fuel purchase log" is an application transaction, a
transaction event might be: "user clicks 'New Fuel Purchase Log' button to
initiate transaction."  Another event might be: "web service request initiated
to submit new fp log data to server".  And another: "web service response
received".  All of this log data is saved locally on the client, and then later
pushed to the server for permanent storage (and offline analysis).

### Motivation

The motivation behind the creation of the PEAppTransaction logging framework is
simple: to systematically track important events about the goings-on within an
application (*an end-user application or otherwise*).  You can use the framework
to record information about your application, such as:
+ How long a user takes to fill-out a form.
+ What the round-trip time is for making web service calls.
+ How often a user leaves a screen in your app without fulfilling the
call-to-action.

The set of use cases for which to use the framework to log metadata is
open-ended.  You can use it for basic A/B testing, tracking performance-related
metrics and many more.

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

#### Not Yet Implemented

As of this writing, none of the reporting functionality has been implemented
yet (but will be in the future).  Currently all you can do is log data.
