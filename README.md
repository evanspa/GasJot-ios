# PEFuelPurchase-App

PEFuelPurchase-App is an iOS application for collecting fuel purchase data.
Its primary purpose is to serve as a reference application for leveraging the
PE* suite of libraries.

The PE* library suite is a set of iOS libraries to aid in the development of
applications.

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

#### Account Creation / Login

<img
src="https://github.com/evanspa/PEFuelPurchase-App/raw/master/screenshots/create-acct-login.png"
height="418px" width="237px">

### Logging in & Account Creation
