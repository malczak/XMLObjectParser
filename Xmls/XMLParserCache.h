//
//  XMLParserCache.h
//  Xmls
//
//  Created by malczak on 31/01/15.
//  Copyright (c) 2015 piratcat. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XMLParserCache : NSObject

+ (instancetype) cache;

- (instancetype) init;

-(void) flush;

-(void) pushObject:(NSObject*) object forKey:(NSString*) key;

-(NSObject*) popObjectForKey:(NSString*) key;

@end
