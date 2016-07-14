# PEObjc-Commons

[![Build Status](https://travis-ci.org/evanspa/PEObjc-Commons.svg)](https://travis-ci.org/evanspa/PEObjc-Commons)

PEObj-Commons is an iOS static library that provides a set of everyday helper and utility
functionality.  The intent of this library is similar to that of the
[Apache's Commons-Lang](http://commons.apache.org/proper/commons-lang/) Java
library.

PEObjc-Commons is part of the
[PE* iOS Library Suite](#pe-ios-library-suite).

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**
- [Documentation and Demo](#documentation-and-demo)
- [Installation](#installation-with-cocoapods)
- [PE* iOS Library Suite](#pe-ios-library-suite)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Documentation and Demo

* [API docs](http://cocoadocs.org/docsets/PEObjc-Commons)

Also, a DemoApp exists to illustrate some of the UI-building functionality of the [PEUIUtils](https://github.com/evanspa/PEObjc-Commons/blob/master/PEObjc-Commons/PEUIUtils.h) class.

## Installation with CocoaPods

```ruby
pod 'PEObjc-Commons', '~> 1.0.110'
```

## PE* iOS Library Suite
*(Each library is implemented as a CocoaPod-enabled iOS static library.)*
+ **PEObjc-Commons**: this library.
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
