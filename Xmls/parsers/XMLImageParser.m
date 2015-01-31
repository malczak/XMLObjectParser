//
//  XMLImageParser.m
//  Xmls
//
//  Created by malczak on 31/01/15.
//  Copyright (c) 2015 piratcat. All rights reserved.
//

#import "XMLImageParser.h"
#import "Image.h"

@implementation XMLImageParser

-(id)modelObject
{
    XMLObject *node = [self rootElement];
    Image *image = [[Image alloc] init];
    image.rid = [node.properties[@"rid"] integerValue];
    image.pictureId = [node.properties[@"pictureId"] integerValue];
    image.type = [node.properties[@"type"] integerValue];
    image.uri = node.properties[@"uri"];
    return image;
}

@end
