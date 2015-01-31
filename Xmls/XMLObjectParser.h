//
// Created by Mateusz Malczak on 17/03/2014.
// Copyright (c) 2014 
//

#import <Foundation/Foundation.h>
#import "XMLParserCache.h"

@class XMLObjectParser;
@class XMLObject;

#pragma mark - SoapObjectParserDelegate protocol

@protocol SoapObjectParserDelegate
-(void)soapObjectParser:(XMLObjectParser*)parser didFinishWithObject:(XMLObject *)object;
@end


#pragma mark - SoapObject interface

@interface XMLObject : NSObject

@property (nonatomic, assign) BOOL simple;
@property (nonatomic, strong) NSString *xpath;
@property (nonatomic, strong) NSString *elementName;
@property (nonatomic, strong) NSMutableDictionary *properties;

- (NSObject*)valueForPath:(NSString*)keyPath;

- (void)enumerateProperty:(NSString*)propertyName withBlock:(void (^)(id value, NSUInteger index, BOOL *stop))block;

@end


#pragma mark - SoapObjectParser implementation

@interface XMLObjectParser : NSObject {    
    XMLObject *currentElement;
    NSMutableArray *openElements;
    NSMutableString *currentValue;
    NSMutableData *currentCData;

    XMLObjectParser *childParser;
    NSMutableDictionary *childParsers;
    NSMutableSet *ignoredTagNames;
    NSMutableSet *includeTagNames;
    NSString *ignoringTagName;
}

// @default YES
@property (nonatomic, assign) BOOL forceLowerCasePropertyNames;
// @default YES
@property (nonatomic, assign) BOOL treatCDataAsStrings;
// @default YES
@property (nonatomic, assign) BOOL trimPropertyValues;
// @default NO
@property (nonatomic, assign) BOOL allowAttrsOverwrite;


@property (nonatomic, strong) XMLParserCache* cache;


@property (nonatomic, strong) id<SoapObjectParserDelegate> delegate;
@property (nonatomic, strong) NSXMLParser *xmlParser;

@property (nonatomic, readonly) BOOL finished;
@property (nonatomic, readonly) NSString *tagName;
@property (nonatomic, readonly) XMLObject *rootElement;

-(id)initWithTagName:(NSString*)parserTagName;
-(id)initWithTagName:(NSString*)parserTagName childParsers:(NSMutableDictionary *)parsers;

-(void)startOnElement:(NSString*)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict;

-(id)clone;
-(void)reset;

-(void)addParser:(Class)parserClass forTagName:(NSString*) tagName;

-(void)ignoreTagName:(NSString*) tagName;
-(void)includeTagName:(NSString*) tagName;

-(id)modelObject;

@end
