//
//  XMLObject.h
//  Xmls
//
//  Created by malczak on 31/01/15.
//  Copyright (c) 2015 piratcat. All rights reserved.
//

#import <Foundation/Foundation.h>
extern NSString * const XMLOBJECT_VALUE_KEY;

extern NSString * const XMLOBJECT_NS_KEY;

typedef NS_OPTIONS(NSUInteger, kXMLObjectFlags) {
    XMLOBJECT_HAS_ATTRS = 1 << 0,
    XMLOBJECT_HAS_NS    = 1 << 1
};

@interface XMLObject : NSObject

@property (nonatomic, assign) kXMLObjectFlags flags;
@property (nonatomic, strong) NSString *xpath;
@property (nonatomic, strong) NSString *elementName;
@property (nonatomic, strong) NSMutableDictionary *properties;

- (NSObject*)valueForPath:(NSString*)keyPath;

- (void)enumerateProperty:(NSString*)propertyName withBlock:(void (^)(id value, NSUInteger index, BOOL *stop))block;

@end


