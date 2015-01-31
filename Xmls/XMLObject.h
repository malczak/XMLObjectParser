//
//  XMLObject.h
//  Xmls
//
//  Created by malczak on 31/01/15.
//  Copyright (c) 2015 piratcat. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XMLObject : NSObject

@property (nonatomic, assign) BOOL simple;
@property (nonatomic, strong) NSString *xpath;
@property (nonatomic, strong) NSString *elementName;
@property (nonatomic, strong) NSMutableDictionary *properties;

- (NSObject*)valueForPath:(NSString*)keyPath;

- (void)enumerateProperty:(NSString*)propertyName withBlock:(void (^)(id value, NSUInteger index, BOOL *stop))block;

@end


