# Gas Jot

[![Build Status](https://travis-ci.org/evanspa/GasJot-ios.svg)](https://travis-ci.org/evanspa/GasJot-ios)

Gas Jot is an iOS application for collecting gas purchase and other data about
your vehicle.  It's a fun application to use to track your gas purchase and
utilization history.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [About the Gas Jot System](#about-the-gas-jot-system)
  - [Server-side Application](#server-side-application)
- [Component Layering](#component-layering)
- [Dependency Graph](#dependency-graph)
- [App-specific Libraries used by GasJot-ios](#app-specific-libraries)
- [PE* iOS Library Suite](#pe-ios-library-suite)
- [Analytics](#analytics)
- [Screenshots](#screenshots)
    - [Splash](#splash)
    - [Home](#home-screen)
    - [Adding an Odometer Log](#adding-an-odometer-log)
    - [Adding a Gas Purchase Log](#adding-a-gas-purchase-log)
    - [Adding a Gas Station](#adding-a-gas-station)
    - [Jot Button](#jot-button)
    - [Records](#records-screen)
    - [Home (with charts)](#home-screen-with-charts)
    - [Gas Jot Account](#gas-jot-account)
    - [Account Creation](#account-creation)
    - [Account Log In](#account-log-in)
    - [Account Screen](#account-screen)
    - [Data Record Detail](#data-record-detail)
    - [Data Record Stats](#data-record-stats)
    - [Conflict Detection](#conflict-detection)
    - [Settings](#settings)
    - [Export](#export)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## About the Gas Jot System

The Gas Jot system serves as nice a reference implementation for a set of
client-side and server-side libraries.  The Gas Jot system is a client/server
one.  This repo, *GasJot-ios*, represents a client-side application of
the Gas Jot system.  The libraries it uses are generic, and thus are not coupled
to Gas Jot.  These libraries are the
[PE* iOS library suite](#pe-ios-library-suite).

### Server-side Application

The server-side application of Gas Jot provides a REST API endpoint (*written in
Clojure*) for the client applications to consume:
[pe-gasjot-app](https://github.com/evanspa/pe-gasjot-app).

## Component Layering

The following diagram attempts to illustrate the layered architecture of the
Gas Jot iOS client application.  The [Gas Jot model](#app-specific-libraries)
appears largest because it encapsulates the bulk of the application; the core
logic, model and data access functionality.

<img
src="https://github.com/evanspa/GasJot-ios/raw/master/drawings/PEFuelPurchase-App-Component-Layers.png">

## Dependency Graph

The following diagram attempts to illustrates the dependencies among the main
components of the Gas Jot iOS client application.

<img
src="https://github.com/evanspa/GasJot-ios/raw/master/drawings/PEFuelPurchase-App-Dependency-Graph.png">

## App Specific Libraries
*(The following libraries are specific to the Gas Jot application domain, but are not GUI-related.)*
+ **[GasJot-ios-common](https://github.com/evanspa/GasJot-ios-common)**:
  contains *application agnostic* constant definitions.
+ **[GasJot-ios-model](https://github.com/evanspa/GasJot-ios-model)**:
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
src="https://github.com/evanspa/GasJot-ios/raw/master/screenshots/splash.png"
height="418px" width="237px">

Gas Jot's splash screen.  The top portion of the screen is an image carousel
showing a glimpse of functionality within the app.

#### Home Screen

Gas Jot does not suffer from the
[login barrier anti-pattern](http://blog.codinghorror.com/removing-the-login-barrier/).
Instead, users can start using the app immediately (*adding vehicles*, *recording gas and odometer logs*,
etc.), without having to sign up for an account or log in.

<img
src="https://github.com/evanspa/GasJot-ios/raw/master/screenshots/home-intro-1.png"
height="418px" width="237px">

Upon launching, the app invites you to create your first vehicle record.

<img
src="https://github.com/evanspa/GasJot-ios/raw/master/screenshots/create-vehicle.png"
border="5" height="418px" width="237px">

Creating a vehicle is pretty simple; just 3 fields: *name*, *default octane* and
*fuel capacity*.  Only the *name* field is required.

<img
src="https://github.com/evanspa/GasJot-ios/raw/master/screenshots/vehicle-saved-local.png"
border="5" height="418px" width="237px">

Successful creation of a vehicle record.  At this point the vehicle record is saved locally
in the app and the user can now start recording gas and odometer logs.

<img
src="https://github.com/evanspa/GasJot-ios/raw/master/screenshots/home-intro-2.png"
height="418px" width="237px">

The home screen now updates to reflect that you have at least 1 vehicle record.

#### Adding an Odometer Log

<img
src="https://github.com/evanspa/GasJot-ios/raw/master/screenshots/create-odometer-log.png"
height="418px" width="237px">

Odometer logs are used for recording your vehicle's current odometer, the
vehicle's reported average miles per gallon and miles per hour, the vehicle's
reported distance-to-empty (DTE) and the outside temperature.

Odometer logs can be recorded at anytime.

#### Adding a Gas Purchase Log

<img
src="https://github.com/evanspa/GasJot-ios/raw/master/screenshots/create-gas-log.png"
height="528px" width="237px">

Adding a gas purchase log requires the user to pick the associated vehicle and
gas station.  The **Pre-fillup Reported DTE** field is the vehicle's distance-to-empty
(DTE) indicator before you pump the gas; the **Post-fillup Reported DTE** field
is the DTE indicated by the vehicle after you're done pumping the gas.  If both
of these fields are provided, then 2 odometer logs will be created in addition
to the gas log to record all the information.

#### Adding a Gas Station

<img
src="https://github.com/evanspa/GasJot-ios/raw/master/screenshots/create-gas-station.png"
height="418px" width="237px">

Adding a gas station (which is needed in order to log gas purchases).

#### Jot Button

<img
src="https://github.com/evanspa/GasJot-ios/raw/master/screenshots/jot-button.png"
height="418px" width="237px">

The Jot button conveniently allows you to create any type of data record at any
time.

#### Records Screen

<img
src="https://github.com/evanspa/GasJot-ios/raw/master/screenshots/records.png"
height="418px" width="237px">

The records screen lets you explore and navigate all of your data records.

#### Home Screen with Charts

<img
src="https://github.com/evanspa/GasJot-ios/raw/master/screenshots/home.png"
height="418px" width="237px">

The home screen displays a series of charts and aggregate data points.

#### Gas Jot Account

<img
src="https://github.com/evanspa/GasJot-ios/raw/master/screenshots/login-or-create-account.png"
height="418px" width="237px">

Users can create an account or log into their existing Gas Jot account.
Creating an account enables users' records to be saved to the Gas Jot server so
they can be accessed from multiple devices.

#### Account Creation

<img
src="https://github.com/evanspa/GasJot-ios/raw/master/screenshots/create-account.png"
height="418px" width="237px">

Creating an account is fairly simple affair.  Upon successfully creating an
account, the user will receive a verification email.

#### Account Log In

<img
src="https://github.com/evanspa/GasJot-ios/raw/master/screenshots/login.png"
height="418px" width="237px">

Logging in is also a simple affair.  Password reset functionality is provided.

#### Account Screen

<img
src="https://github.com/evanspa/GasJot-ios/raw/master/screenshots/authenticated-account.png"
height="418px" width="237px">

When logged in, the Account screen is where the user can log out, view and edit
their account details and drill into several stats and trends screens.

#### Data Record Detail

<img
src="https://github.com/evanspa/GasJot-ios/raw/master/screenshots/view-vehicle.png"
height="418px" width="237px">

From a data record's detail screen, the record can be edited or deleted.  In
addition, the **download** button on the navigation bar allow edits made to the
record on other devices to be downloaded and merged.

Child records can also be navigated to (*gas and odometer logs for vehicles; gas
logs for gas stations*).

#### Data Record Stats

<img
src="https://github.com/evanspa/GasJot-ios/raw/master/screenshots/vehicle-stats.png"
height="418px" width="237px">

Stats and trend information can be drilled-into for vehicle and gas station
records (*and at the user-level too; giving stats trends across ALL vehicles or
ALL gas stations*).

<img
src="https://github.com/evanspa/GasJot-ios/raw/master/screenshots/vehicle-stats-days-between.png"
height="418px" width="237px">

The above is an example showing the average number of days between fill-ups
stats and trend information.

<img
src="https://github.com/evanspa/GasJot-ios/raw/master/screenshots/vehicle-stats-days-between-compare.png"
height="418px" width="237px">

A *Compare* button is usually present to compare aggregate values.


#### Conflict Detection

With a distributed system like Gas Jot's, it's wholly possible for conflicts to
arise vis-a-vis the editing of data records.  If a data record was changed on
the server at some point after it was last downloaded to the device, a conflict
will be detected by the server if the user attempts to edit the record on their
device without having downloaded the latest from the server.

<img
src="https://github.com/evanspa/GasJot-ios/raw/master/screenshots/edit-vehicle-conflict.png"
height="418px" width="237px">

Gas Jot is smart enough to know if merging is possible.  If the fields of the
data record edited by the user on the device differ than the fields of the
record that were updated on the server, then automatic merging will be possible.  If the
fields being edited locally are the same as the ones edited on the record on the
server, an automatic merge will not be possible, and the user will be presented
with a manual merge screen.

<img
src="https://github.com/evanspa/GasJot-ios/raw/master/screenshots/edit-vehicle-manual-merge.png"
height="418px" width="237px">

In this example, the vehicle record on the server had been updated at some point
AFTER the record was last downloaded to the user's device.  Specifically it's
**name** was updated to *Fairlady Z*.  The user was trying to update the vehicle
record on their device to change the name to *300ZX TT*.  In this case, an
automatic merge cannot be done; so the user is presented with the conflict
resolver screen.  For each field in conflict, the user chooses which they want:
the local value, or the server copy's value.

#### Settings

<img
src="https://github.com/evanspa/GasJot-ios/raw/master/screenshots/settings.png"
height="530px" width="237px">

From the Settings screen, the user can tap the *Download all changes* button to
download records from the server that have been updated/added/deleted from other
devices.  Doing this keeps the data records on users' devices up-to-date and
consistent.

**Offline mode** allows just that; it prevents communication with the Gas Jot
server when doing adds and edits, in order to keep those operations very fast,
since they'll be local-only.  Later, from the **Records** screen, all unsynced
edits can up uploaded to the Gas Jot server in 1 bulk operation.

**Export** allows the user to export their Gas Jot data to CSV files.

#### Export

<img
src="https://github.com/evanspa/GasJot-ios/raw/master/screenshots/export.png"
height="418px" width="237px">

Users can export their Gas Jot to CSV files and download them to their device
through the File Sharing feature of iTunes.
