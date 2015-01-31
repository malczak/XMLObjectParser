//
//  XmlParser.m
//  Xmls
//
//  Created by malczak on 30/01/15.
//  Copyright (c) 2015 piratcat. All rights reserved.
//

#import "XMLParser.h"
#import "XMLImageParser.h"

@implementation XMLParser

-(void) parseXmlFromData:(NSData*) data
{
    xmlParser = [[NSXMLParser alloc] initWithData:data];
    [xmlParser setDelegate: self];
    [xmlParser setShouldProcessNamespaces:YES];
    [xmlParser setShouldResolveExternalEntities: YES];
    [xmlParser parse];
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    objectParser = [[XMLObjectParser alloc] init];
    objectParser.allowAttrsOverwrite = YES;
    objectParser.xmlParser = xmlParser;
    [objectParser addParser:[XMLImageParser class] forTagName:@"Image"];
    [objectParser startOnElement:elementName namespaceURI:namespaceURI qualifiedName:qName attributes:attributeDict];
}

-(XMLObject*) soapObject
{
    return objectParser.rootElement;
}

@end
