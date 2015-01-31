//
//  XMLObject.m
//  Xmls
//
//  Created by malczak on 31/01/15.
//  Copyright (c) 2015 piratcat. All rights reserved.
//

#import "XMLObject.h"

@implementation XMLObject

- (id)init {
    self = [super init];
    if (self) {
        self.simple = YES;
        self.properties = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSObject*)valueForPath:(NSString*)keyPath {
    NSArray *path = [keyPath componentsSeparatedByString:@"."];
    
    if(![path count])
    {
        return nil;
    }
    
    Class soapObjectClass = [XMLObject class];
    
    NSUInteger propertyIdx = 0;
    XMLObject *object = self;
    
    while((propertyIdx < [path count])&&([object isKindOfClass:soapObjectClass]))
    {
        NSString *property = [path objectAtIndex:propertyIdx];
        propertyIdx += 1;
        object = [object.properties objectForKey:property];
    }
    
    return object;
}

- (void)enumerateProperty:(NSString*)propertyName withBlock:(void (^)(id value, NSUInteger index, BOOL *stop))block
{
    id propertyObject = [self valueForPath:propertyName];
    if([propertyObject isKindOfClass:[NSArray class]])
    {
        NSArray *objects = (NSArray*) propertyObject;
        [objects enumerateObjectsUsingBlock:block];
    } else {
        BOOL stop;
        block(propertyObject, 0, &stop);
    }
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@[%@]:\n", NSStringFromClass([self class]),self.elementName];
    [description appendString:@"\nproperties: "];
    if(self.properties) {
        [description appendString:self.properties.description];
    }
    [description appendString:@">"];
    return description;
}


@end

