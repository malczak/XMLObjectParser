//
//  Image.h
//  Xmls
//
//  Created by malczak on 31/01/15.
//  Copyright (c) 2015 piratcat. All rights reserved.
//

#import <Foundation/Foundation.h>

//              <Image rid="93" type="2569" uri="image_241188" pictureId="241188" width="3456" height="4608" matrix="matrix(1.0000, 0.0000, 0.0000, 1.0000, 0.0000, 0.0000)"/>

@interface Image : NSObject

@property (nonatomic, assign) NSUInteger rid;

@property(nonatomic, assign) NSUInteger type;

@property(nonatomic, assign) NSUInteger pictureId;

@property(nonatomic, strong) NSString *uri;

@end
