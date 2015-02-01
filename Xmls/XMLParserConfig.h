//
//  XMLParserConfig.h
//  Xmls
//
//  Created by malczak on 31/01/15.
//  Copyright (c) 2015 piratcat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMLParserCache.h"

@interface XMLParserConfig : NSObject
{
    NSMutableDictionary *childParsers;
    NSMutableSet *ignoredTagNames;
    NSMutableSet *includeTagNames;
}

// @default YES
@property (nonatomic, assign) BOOL forceLowerCasePropertyNames;
// @default YES
@property (nonatomic, assign) BOOL treatCDataAsStrings;
// @default YES
@property (nonatomic, assign) BOOL trimPropertyValues;
// @default NO
@property (nonatomic, assign) BOOL allowAttrsOverwrite;
// @default YES
@property (nonatomic, assign) BOOL extractArraysIfPossible;

@property (nonatomic, strong) XMLParserCache* cache;

+ (instancetype) config;

+ (instancetype) defaultConfig;

-(void)ignoreTagName:(NSString*) tagName;

-(void)includeTagName:(NSString*) tagName;

-(BOOL)shouldIgnoreTagName:(NSString*) tagName;

-(void)addParser:(Class)parserClass forTagName:(NSString*) tagName;

-(Class)parserClassForTagName:(NSString*) tagName;

@end