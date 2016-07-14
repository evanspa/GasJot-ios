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

#import <Foundation/Foundation.h>
#import <KissXML/DDXMLNode.h>

/**
 Block type that encapsulates the computation of extracting boolean attribute
 values from an XML document at the element described by the given XPath
 expression.  Block parameters:
 - *attributeName* The name of the attribute whose value is sought.
 */
typedef BOOL (^BoolAttrExtractorBlk)(NSString *attributeName);

/**
 Block type that encapsulates the computation of extracting string attribute
 values from an XML document at the element described by the given XPath
 expression.  Block parameters:
 - *attributeName* The name of the attribute whose value is sought.
*/
typedef NSString * (^StrAttrExtractorBlk)(NSString *attributeName);

/**
 Block type that encapsulates the computation of extracting decimal number
 attribute objects from an XML document at the element described by the given
 XPath expression.  Block parameters:
 - *attributeName* The name of the attribute whose value is sought.
*/
typedef NSDecimalNumber * (^DecAttrExtractorBlk)(NSString *attributeName);

/**
 Block type that encapsulates the computation of extracting date
 attribute objects from an XML document at the element described by the given
 XPath expression.  Block parameters:
 - *attributeName* The name of the attribute whose value is sought.
*/
typedef NSDate * (^DateAttrExtractorBlk)(NSString *attributeName);

/**
 A collection of XML-related helper functions.
 */
@interface PEXmlUtils : NSObject

#pragma mark - Initializers

/**
 Constructs and returns a new commons instance with the given XML document.
 @param node the XML document to encapsulate
 */
- (id)initWithDocument:(DDXMLNode *)node;

/**
 Constructs and returns a new commons instance with the given XML node.
 @param node the XML node to encapsulate
*/
- (id)initWithNode:(DDXMLNode *)node;

/**
 Constructs and returns a new commons instance with the given XML document.  If
 the document's root contains a default namespace, then the given prefix can
 be used when executing xpath expressions.
 @param node the XML document to encapsulate
 @param prefix prefix to be used when executing xpath expressions against the
               XML document when the document contains a default namespace
               prefix.
*/
- (id)initWithDocument:(DDXMLNode *)node prefixForDefaultNs:(NSString *)prefix;

#pragma mark - Helpers

/**
 Converts and returns the given XSD-based string representation of a boolean as
 a BOOL.
 @param xsdBool the XSD-based string representation of a boolean to parse
 */
+ (BOOL)xsdBoolStrToBool:(NSString *)xsdBool;

#pragma mark - XPath Helpers

/**
 Helper that returns the XPath expression needed to get at an attribute within
 a specified element.
 @param attributeName The name of the attribute.
 @param elementXPath XPath expression to the element in which the given
 attribute is contained.  If nil is provided, it means the element is already
 'in scope' and the returned XPath expression is just the attribute name
 prefixed with the '@' character.
 @return XPath expression for extracting the given attribute from some XML
 document.
 */
+ (NSString *)xpathForAttribute:(NSString *)attributeName
                   elementXPath:(NSString *)elementXPath;

/**
 Helper that returns a block encapsulating a computation for extracting
 an attribute from the XML encapsulated by the xmlCommons object (allows for
 consise and terse code) as a boolean value.
 @return A block to be used for extracting boolean attributes from the XML
 encapsulated by the xmlCommons object.
 */
- (BoolAttrExtractorBlk)boolAttrExtractor;

/**
 Helper that returns a block encapsulating a computation for extracting an
 attribute from the XML encapsulated by the xmlCommons object (allows for
 consise and terse code) as a boolean value.
 @param elementXpath XPath expression to the element in which the given
 attribute is contained.  If nil is provided, it means the element is already
 'in scope' and the returned XPath expression is just the attribute name
 prefixed with the '@' character.
 @return A block to be used for extracting boolean attributes from the XML
 encapsulated by the xmlCommons object.
 */
- (BoolAttrExtractorBlk)boolAttrExtractorForElementAtXPath:(NSString *)elementXpath;                                            

/**
 Helper that returns a block encapsulating a computation for extracting
 an attribute from the XML encapsulated by the xmlCommons object (allows for
 consise and terse code) as a string value.
  @return A block to be used for extracting string attributes from the XML
 encapsulated by the xmlCommons object.
*/
- (StrAttrExtractorBlk)strAttrExtractor;

/**
 Helper that returns a block encapsulating a computation for extracting an
 attribute from the XML encapsulated by the xmlCommons object (allows for
 consise and terse code) as a string value.
 @param elementXpath XPath expression to the element in which the given
 attribute is contained.  If nil is provided, it means the element is already
 'in scope' and the returned XPath expression is just the attribute name
 prefixed with the '@' character.
 @return A block to be used for extracting string attributes from the XML
 encapsulated by the xmlCommons object.
*/
- (StrAttrExtractorBlk)strAttrExtractorForElementAtXPath:(NSString *)elementXpath;

/**
 Helper that returns a block encapsulating a computation for extracting
 an attribute from the XML encapsulated by the xmlCommons object (allows for
 consise and terse code) as a decimal number object.
 @return A block to be used for extracting decimal number attributes from the
 XML encapsulated by the xmlCommons object.
*/
- (DecAttrExtractorBlk)decAttrExtractor;

/**
 Helper that returns a block encapsulating a computation for extracting
 an attribute from the XML encapsulated by the xmlCommons object (allows for
 consise and terse code) as a decimal number object.
 @param elementXpath XPath expression to the element in which the given
 attribute is contained.  If nil is provided, it means the element is already
 'in scope' and the returned XPath expression is just the attribute name
 prefixed with the '@' character.
 @return A block to be used for extracting decimal number attributes from the
 XML encapsulated by the xmlCommons object.
*/
- (DecAttrExtractorBlk)decAttrExtractorForElementAtXPath:(NSString *)elementXpath;

/**
 Helper that returns a block encapsulating a computation for extracting
 an attribute from the XML encapsulated by the xmlCommons object (allows for
 consise and terse code) as a date object.
 @param datePattern The pattern of the date represented as a string.
 @return A block to be used for extracting date attributes from the XML 
 encapsulated by the xmlCommons object.
*/
- (DateAttrExtractorBlk)dateAttrExtractorWithPattern:(NSString *)datePattern;

/**
 Helper that returns a block encapsulating a computation for extracting
 an attribute from the XML encapsulated by the xmlCommons object (allows for
 consise and terse code) as a date object.
 @param elementXpath XPath expression to the element in which the given
 attribute is contained.  If nil is provided, it means the element is already
 'in scope' and the returned XPath expression is just the attribute name
 prefixed with the '@' character.
 @param datePattern The pattern of the date represented as a string.
 @return A block to be used for extracting date attributes from the XML
 encapsulated by the xmlCommons object.
*/
- (DateAttrExtractorBlk)dateAttrExtractorForElementAtXPath:(NSString *)elementXpath
                                               withPattern:(NSString *)datePattern;

/**
 Executes the given xpath expression against the contained XML document, and
 returns the value as a string.
 @param xpath XPath expression
 @return the value of the xpath expression - presumably a string
 */
- (NSString *)valueForXPath:(NSString *)xpath;

/**
 Executes the given xpath expression against the contained XML document, and
 returns the value as a BOOL.
 @param xpath XPath expression
 @return the value of the xpath expression - presumably a boolean
*/
- (BOOL)boolValueForXPath:(NSString *)xpath;

/**
 Executes the given xpath expression against the contained XML document, and
 returns the value as an integer.
 @param xpath XPath expression
 @return the value of the xpath expression - presumably an integer
*/
- (NSInteger)intValueForXPath:(NSString *)xpath;

/**
 Executes the given xpath expression against the contained XML document, and
 returns the found nodes.
 @param xpath XPath expression
 @return the value of the xpath expression - the set of matching nodes
 */
- (NSArray *)nodesForXPath:(NSString *)xpath;

@end
