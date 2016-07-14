//
//  PEXMLUtils.m
//
// Copyright (c) 2014-2015 PEXML-Utils
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "PEUtils.h"
#import "PEXMLUtils.h"
#import "DDXMLDocument.h"

@implementation PEXmlUtils {
  DDXMLNode *_node;
}

#pragma mark - Initializers

- (id)initWithDocument:(DDXMLNode *)node {
  return [self initWithDocument:node prefixForDefaultNs:nil];
}

- (id)initWithNode:(DDXMLNode *)node {
  return [self initWithDocument:node];
}

- (id)initWithDocument:(DDXMLNode *)node prefixForDefaultNs:(NSString *)prefix {
  self = [super init];
  if (self) {
    _node = node;

    ////////////////////////////////////////////////////////////////////////////
    // This is a hack to be able to execute xpath expressions against XML
    // documents that contain a default namespace URI.  It would be nice if
    // KissXML had a function similar to Java with the ability to register
    // namespace prefix / value pairs with the xpath engine.
    ////////////////////////////////////////////////////////////////////////////
    if (prefix) {
      DDXMLDocument *doc = (DDXMLDocument *)_node;
      DDXMLNode *ns = [[doc rootElement] namespaceForPrefix:@""];
      if (ns) {
        NSString *nsValue = [ns stringValue];
        DDXMLNode *newNs = [DDXMLNode namespaceWithName:prefix
                                            stringValue:nsValue];
        [[doc rootElement] addNamespace:newNs];
      }
    }
  }
  return self;
}

#pragma mark - Helpers

+ (BOOL)xsdBoolStrToBool:(NSString *)xsdBool {
  BOOL val;
  if ([xsdBool isEqualToString:@"true"]) {
    val = YES;
  } else {
    val = [xsdBool boolValue];
  }
  return val;
}

#pragma mark - XPath Helpers

+ (NSString *)xpathForAttribute:(NSString *)attributeName
                   elementXPath:(NSString *)elementXPath {
  NSString *xpath;
  if (elementXPath) {
    xpath = [NSString stringWithFormat:@"%@/@%@", elementXPath, attributeName];
  } else {
    xpath = [NSString stringWithFormat:@"@%@", attributeName];
  }
  return xpath;
}

- (BoolAttrExtractorBlk)boolAttrExtractor {
  return [self boolAttrExtractorForElementAtXPath:nil];
}

- (BoolAttrExtractorBlk)boolAttrExtractorForElementAtXPath:(NSString *)elementXpath {
  return ^(NSString *attributeName) {
    NSString *xpath = [PEXmlUtils xpathForAttribute:attributeName
                                          elementXPath:elementXpath];
    return [self boolValueForXPath:xpath];
  };
}

- (StrAttrExtractorBlk)strAttrExtractor {
  return [self strAttrExtractorForElementAtXPath:nil];
}

- (StrAttrExtractorBlk)strAttrExtractorForElementAtXPath:(NSString *)elementXpath {
  return ^(NSString *attributeName) {
    NSString *xpath = [PEXmlUtils xpathForAttribute:attributeName
                                          elementXPath:elementXpath];
    return [self valueForXPath:xpath];
  };
}

- (DateAttrExtractorBlk)dateAttrExtractorWithPattern:(NSString *)datePattern {
  return [self dateAttrExtractorForElementAtXPath:nil
                                      withPattern:datePattern];
}

- (DateAttrExtractorBlk)dateAttrExtractorForElementAtXPath:(NSString *)elementXpath
                                               withPattern:(NSString *)datePattern {
  return ^(NSString *attributeName) {
    NSDate *dateVal = nil;
    NSString *xpath = [PEXmlUtils xpathForAttribute:attributeName
                                       elementXPath:elementXpath];
    NSString *value = [self valueForXPath:xpath];
    if (value) {
      dateVal = [PEUtils dateFromString:value withPattern:datePattern];
    }
    return dateVal;
  };
}

- (DecAttrExtractorBlk)decAttrExtractor {
  return [self decAttrExtractorForElementAtXPath:nil];
}

- (DecAttrExtractorBlk)decAttrExtractorForElementAtXPath:(NSString *)elementXpath {
  return ^(NSString *attributeName) {
    NSDecimalNumber *decimalVal = nil;
    NSString *xpath = [PEXmlUtils xpathForAttribute:attributeName
                                       elementXPath:elementXpath];
    NSString *value = [self valueForXPath:xpath];
    if (value) {
      decimalVal = [NSDecimalNumber decimalNumberWithString:value];
    }
    return decimalVal;
  };
}

- (NSString *)valueForXPath:(NSString *)xpath {
  NSArray *nodes = [_node nodesForXPath:xpath error:nil];
  NSString *value = nil;
  if (nodes && ([nodes count] == 1)) {
    value = [[nodes firstObject] stringValue];
  }
  return value;
}

- (BOOL)boolValueForXPath:(NSString *)xpath {
  NSString *strVal = [self valueForXPath:xpath];
  return [PEXmlUtils xsdBoolStrToBool:strVal];
}

- (NSInteger)intValueForXPath:(NSString *)xpath {
  NSString *strVal = [self valueForXPath:xpath];
  NSInteger intVal = 0;
  if (strVal) {
    intVal = [strVal integerValue];
  }
  return intVal;
}

- (NSArray *)nodesForXPath:(NSString *)xpath {
  return [_node nodesForXPath:xpath error:nil];
}

@end
