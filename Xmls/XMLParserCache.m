//
//  XMLParserCache.m
//  Xmls
//
//  Created by malczak on 31/01/15.
//  Copyright (c) 2015 piratcat. All rights reserved.
//

#import "XMLParserCache.h"

@interface XMLParserCache () {
    NSMutableDictionary *cache;
}

@end

@implementation XMLParserCache

+(id) cache
{
    return [[XMLParserCache alloc] init];
}

-(id) init
{
    self = [super init];
    if(self)
    {
        cache = nil;
    }
    return self;
}

-(void) flush
{
    if(cache)
    {
        [cache enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSMutableArray *keyCache, BOOL *stop){
            [keyCache removeAllObjects];
        }];
    }
}

-(void) pushObject:(NSObject*) object forKey:(NSString*) key
{
    [[self cacheForKey:key createMissing:YES] addObject:object];
}

-(NSObject*) popObjectForKey:(NSString*) key
{
    NSMutableArray *keyCache = [self cacheForKey:key createMissing:NO];
    if(!keyCache || ![keyCache count])
    {
        return nil;
    }
    NSObject *object = [keyCache lastObject];
    [keyCache removeLastObject];
    return object;
}

-(NSMutableArray*) cacheForKey:(NSString*) key createMissing:(BOOL) createNew
{
    if(!cache)
    {
        cache = [NSMutableDictionary dictionary];
    }
    
    NSMutableArray *keyCache = [cache objectForKey:key];
    if(!keyCache)
    {
        if(!createNew)
        {
            return nil;
        }
        
        keyCache = [NSMutableArray array];
        [cache setObject:keyCache forKey:key];
    }
    
    return keyCache;
}

-(void)dealloc
{
    [self flush];
    cache = nil;
}

@end
