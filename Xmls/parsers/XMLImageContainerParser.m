//
//  XMLImageContainerParser.m
//  Xmls
//
//  Created by malczak on 31/01/15.
//  Copyright (c) 2015 piratcat. All rights reserved.
//

#import "XMLImageContainerParser.h"
#import "ImageContainer.h"

@implementation XMLImageContainerParser

//          <ImageContainer depth="0" x="0.0738" y="0.0221" width="737.0208" height="595.2379" rotation="0.0000"

-(id)modelObject
{
    XMLObject *node = [self rootElement];
    ImageContainer *container = [[ImageContainer alloc] init];
    container.image = [node.properties objectForKey:@"image"];
    return container;
}


@end
