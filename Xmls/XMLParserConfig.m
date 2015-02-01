//
//  XMLParserConfig.m
//  Xmls
//
//  Created by malczak on 31/01/15.
//  Copyright (c) 2015 piratcat. All rights reserved.
//

#import "XMLParserConfig.h"

@implementation XMLParserConfig

+ (instancetype) config
{
    return [[self alloc] init];
}

+ (instancetype) defaultConfig
{
    XMLParserConfig *config = [[self alloc] init];
    config.cache = [XMLParserCache cache];
    return config;
}

- (instancetype) init
{
    self = [super init];
    if(self)
    {
        self.forceLowerCasePropertyNames = YES;
        self.treatCDataAsStrings = YES;
        self.trimPropertyValues = YES;
        self.allowAttrsOverwrite = NO;
        self.extractArraysIfPossible = YES;
    }
    return self;
}

-(void)ignoreTagName:(NSString*) tagName
{
    if(!ignoredTagNames)
    {
        ignoredTagNames = [NSMutableSet set];
    }
    [ignoredTagNames addObject:tagName];
}

-(void)includeTagName:(NSString*) tagName
{
    if(!includeTagNames)
    {
        includeTagNames = [NSMutableSet set];
    }
    [includeTagNames addObject:tagName];
}

-(void)addParser:(Class)parserClass forTagName:(NSString*) tagName
{
    if(!childParsers)
    {
        childParsers = [NSMutableDictionary dictionary];
    }
    [childParsers setObject:parserClass forKey:tagName];
}

-(BOOL)shouldIgnoreTagName:(NSString *)tagName
{
    
    if(includeTagNames && ![includeTagNames member:tagName])
    {
        return YES;
    }
    
    if(ignoredTagNames && [ignoredTagNames member:tagName])
    {
        return YES;
    }
    
    return NO;
}
-(Class) parserClassForTagName:(NSString*) tagName
{
    return (childParsers) ? [childParsers objectForKey:tagName] : nil;
}

-(XMLParserCache*) cacheInstance
{
    if(!self.cache)
    {
        self.cache = [XMLParserCache cache];
    }
    return self.cache;
}

-(void)dealloc
{
    self.cache = nil;
}

@end
