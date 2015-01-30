//
//  XmlParser.h
//  Xmls
//
//  Created by malczak on 30/01/15.
//  Copyright (c) 2015 piratcat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMLObjectParser.h"

@interface XMLParser : NSObject <NSXMLParserDelegate>
{
    XMLObjectParser *objectParser;
    NSXMLParser *xmlParser;
}

-(XMLObject*) soapObject;
-(void) parseXmlFromData:(NSData*) data;

@end
