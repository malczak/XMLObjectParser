//
//  XmlParser.m
//  Xmls
//
//  Created by malczak on 30/01/15.
//  Copyright (c) 2015 piratcat. All rights reserved.
//

#import "XMLParser.h"
#import "XMLParserConfig.h"
#import "XMLImageParser.h"
#import "XMLImageContainerParser.h"

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
    XMLParserConfig *config = [XMLParserConfig config];
    config.allowAttrsOverwrite = YES;
    [config addParser:[XMLImageParser class] forTagName:@"Image"];
    [config addParser:[XMLImageContainerParser class] forTagName:@"ImageContainer"];
    
    objectParser = [[XMLObjectParser alloc] init];
    objectParser.config = config;
    objectParser.xmlParser = xmlParser;
    [objectParser startOnElement:elementName namespaceURI:namespaceURI qualifiedName:qName attributes:attributeDict];
}

-(XMLObject*) soapObject
{
    return objectParser.rootElement;
}

@end
