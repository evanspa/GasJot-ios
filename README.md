# PEFuelPurchase-App

[![Build Status](https://travis-ci.org/evanspa/PEFuelPurchase-App.svg)](https://travis-ci.org/evanspa/PEFuelPurchase-App)

Gas Jot is an iOS application for collecting gas purchase and other data about
your vehicle.  It's a fun application to use to track your gas purchase and
utilization history.  It's serves as the unofficial reference application for
leveraging the PE* suite of libraries.

The PE* library suite is a set of iOS libraries to aid in the development of
applications.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [About the Gas Jot System](#about-the-gas-jot-system)
  - [Server-side Application](#server-side-application)
- [Component Layering](#component-layering)
- [Dependency Graph](#dependency-graph)
- [App-specific Libraries used by PEFuelPurchase-App](#app-specific-libraries)
- [PE* iOS Library Suite](#pe-ios-library-suite)
- [Analytics](#analytics)
- [Screenshots](#screenshots)
    - [Account Creation / Login](#account-creation--login)
    - [Quick Action Menu (home screen)](#quick-action-menu-home-screen)
    - [Adding a Vehicle](#adding-a-vehicle)
    - [Adding a Gas Station](#adding-a-gas-station)
    - [Adding a Gas Purchase Log](#adding-a-gas-purchase-log)
    - [Adding an Odometer Log](#adding-an-odometer-log)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## About the Gas Jot System

The Gas Jot system serves as nice a reference implementation for a set of
client-side and server-side libraries.  The Gas Jot system is a client/server
one.  This repo, *PEFuelPurchase-App*, represents a client-side application of
the Gas Jot system.  The libraries it uses are generic, and thus are not coupled
to Gas Jot.  These libraries are the
[PE* iOS library suite](#pe-ios-library-suite).

### Server-side Application

The server-side application of Gas Jot provides a REST API endpoint (*written in
Clojure*) for the client applications to consume:
[pe-fp-app](https://github.com/evanspa/pe-fp-app).

## Component Layering

The following diagram attempts to illustrate the layered architecture of the
Gas Jot iOS client application.  The [Gas Jot model](#app-specific-libraries)
appears largest because it encapsulates the bulk of the application; the core
logic, model and data access functionality.

<img
src="https://github.com/evanspa/PEFuelPurchase-App/raw/master/drawings/PEFuelPurchase-App-Component-Layers.png">

## Dependency Graph

The following diagram attempts to illustrates the dependencies among the main
components of the Gas Jot iOS client application.

<img
src="https://github.com/evanspa/PEFuelPurchase-App/raw/master/drawings/PEFuelPurchase-App-Dependency-Graph.png">

## App Specific Libraries
*(The following libraries are specific to the Gas Jot application domain, but are not GUI-related.)*
+ **[PEFuelPurchase-Common](https://github.com/evanspa/PEFuelPurchase-Common)**:
  contains *application agnostic* constant definitions.
+ **[PEFuelPurchase-Model](https://github.com/evanspa/PEFuelPurchase-Model)**:
  encapsulates the object model, local data access, web service access and core
  logic of the application.  This library effectively implements the *core* of
  the Gas Jot application domain.  The Gas Jot iOS application (*this repo*) is
  dependent on it for all its core logic, model and data access / persistence
  functionality.  This library for example, could be used to create a
  command-line version of Gas Jot.

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

## Analytics

The Gas Jot app **used** to leverage the  PEAppTransaction Logging Framework
(PELF) for capturing application events / logs; but going forward will leverage
Google Analytics.

*The PELF is comprised of 3 main tiers: (1)
[the core data layer](https://github.com/evanspa/pe-apptxn-core), (2)
[the web service layer](https://github.com/evanspa/pe-apptxn-restsupport)
and (3) client libraries
([currently only iOS](https://github.com/evanspa/PEAppTransaction-Logger)).*

## Screenshots

To give a sense for what Gas Jot is about, below is a sample of
actual screenshots.

#### Splash

<img
src="https://github.com/evanspa/PEFuelPurchase-App/raw/master/screenshots/splash.png"
height="418px" width="237px">

Gas Jot's splash screen.  The top portion of the screen is an image carousel
showing a glimpse of functionality within the app.

#### Home Screen

Gas Jot does not suffer from the
[login barrier anti-pattern](http://blog.codinghorror.com/removing-the-login-barrier/).
Instead, users can start using the app immediately (*adding vehicles*, *recording gas and odometer logs*,
etc.), without having to sign up for an account or log in.

<img
src="https://github.com/evanspa/PEFuelPurchase-App/raw/master/screenshots/home-intro-1.png"
height="418px" width="237px">

Upon launching, the app invites you to create your first vehicle record.

<img
src="https://github.com/evanspa/PEFuelPurchase-App/raw/master/screenshots/create-vehicle.png"
border="5" height="418px" width="237px">

Creating a vehicle is pretty simple; just 3 fields: *name*, *default octane* and
*fuel capacity*.  Only the *name* field is required.

<img
src="https://github.com/evanspa/PEFuelPurchase-App/raw/master/screenshots/vehicle-saved-local.png"
border="5" height="418px" width="237px">

Successful creation of a vehicle record.  At this point the vehicle record is saved locally
in the app and the user can now start recording gas and odometer logs.

<img
src="https://github.com/evanspa/PEFuelPurchase-App/raw/master/screenshots/home-intro-2.png"
height="418px" width="237px">

The home screen now updates to reflect that you have at least 1 vehicle record.

#### Adding an Odometer Log

<img
src="https://github.com/evanspa/PEFuelPurchase-App/raw/master/screenshots/create-odometer-log.png"
height="418px" width="237px">

Odometer logs are used for recording your vehicle's current odometer, the
vehicle's reported average miles per gallon and miles per hour, the vehicle's
reported distance-to-empty (DTE) and the outside temperature.

Odometer logs can be recorded at anytime.

#### Adding a Gas Purchase Log

<img
src="https://github.com/evanspa/PEFuelPurchase-App/raw/master/screenshots/create-gas-log.png"
height="528px" width="237px">

Adding a gas purchase log requires the user to pick the associated vehicle and
gas station.

#### Gas Jot Account Creation

#### Adding a Gas Station

Adding a gas station (which is needed in order to log gas purchases).
