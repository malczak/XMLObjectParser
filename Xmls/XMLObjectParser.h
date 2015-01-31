//
// Created by Mateusz Malczak on 17/03/2014.
// Copyright (c) 2014 
//

#import <Foundation/Foundation.h>
#import "XMLObject.h"
#import "XMLParserConfig.h"

@class XMLObjectParser;

#pragma mark - SoapObjectParserDelegate protocol

@protocol SoapObjectParserDelegate
-(void)soapObjectParser:(XMLObjectParser*)parser didFinishWithObject:(XMLObject *)object;
@end

#pragma mark - SoapObjectParser implementation

@interface XMLObjectParser : NSObject
{
    XMLObject *currentElement;
    NSMutableArray *openElements;
    NSMutableString *currentValue;
    NSMutableData *currentCData;

    XMLObjectParser *childParser;
    NSString *ignoringTagName;
}

@property (nonatomic, strong) id<SoapObjectParserDelegate> delegate;
@property (nonatomic, strong) NSXMLParser *xmlParser;

@property (nonatomic, strong) XMLParserConfig *config;

@property (nonatomic, readonly) BOOL finished;
@property (nonatomic, readonly) NSString *tagName;
@property (nonatomic, readonly) XMLObject *rootElement;

-(id)initWithTagName:(NSString*)parserTagName;
-(id)initWithTagName:(NSString*)parserTagName childParsers:(NSMutableDictionary *)parsers;

-(void)startOnElement:(NSString*)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict;

-(id)clone;

-(void)reset;

-(id)modelObject;

@end
