//
// Created by Mateusz Malczak on 17/03/2014.
// Copyright (c) 2014
//

#import "XMLObjectParser.h"

#pragma mark - XMLObjectParser implementation

static NSString *const XMLOBJECT_CACHE_KEY = @"_object_cache_key";

@interface XMLObjectParser() <NSXMLParserDelegate, SoapObjectParserDelegate>

@end;

@implementation XMLObjectParser

- (instancetype)initWithTagName:(NSString*)parserTagName
{
    self = [self init];
    if(self)
    {
        _tagName = parserTagName;
    }
    return self;
}

- (instancetype)initWithTagName:(NSString*)parserTagName childParsers:(NSMutableDictionary *)parsers
{
    return [self initWithTagName:parserTagName];
}

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        _finished = NO;
        openElements = [NSMutableArray array];
    }
    return self;
}

-(instancetype)clone
{
    XMLObjectParser *parser = [[self.class alloc] initWithTagName:self.tagName];
    return parser;
}

-(void)reset
{
    if(_finished)
    {
        [self reuseXMLObject:_rootElement];
        [self cacheParser:childParser];
        [self resetValueHolders];
        childParser = nil;
        _rootElement = nil;
        _finished = NO;
    }
}

- (void)setXmlParser:(NSXMLParser *)xmlParser
{
    if(_xmlParser && (_xmlParser.delegate == self))
    {
        [_xmlParser setDelegate:nil];
    }
    
    _xmlParser = xmlParser;
    
    if(_xmlParser)
    {
        [_xmlParser setDelegate:self];
    }
}

-(id)modelObject
{
    return [self rootElement];
}

-(void)startOnElement:(NSString*)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    [self parser:self.xmlParser readElementName:elementName namespaceURI:namespaceURI qName:qName attributeDict:attributeDict];
}

- (void)parser:(NSXMLParser *)parser readElementName:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qName:(NSString *)qName attributeDict:(NSDictionary *)attributeDict
{
    if(![self.tagName isEqualToString:elementName])
    {
        childParser = [self parserForTag:elementName];
        if(childParser)
        {
            childParser.delegate = self;
            childParser.xmlParser = self.xmlParser;
            [childParser parser:parser
                didStartElement:elementName
                   namespaceURI:namespaceURI
                  qualifiedName:qName
                     attributes:attributeDict];
            return;
        }
    }
    
    if(currentElement)
    {
        [openElements addObject:currentElement];
    }
    
    currentElement = [self newXMLObject];
    currentElement.elementName = elementName;
    
    if(!_rootElement)
    {
        _rootElement = currentElement;
    }
    
    XMLParserConfig *config = [self configInstance];
    
    if(attributeDict && [attributeDict count])
    {
        currentElement.flags = (currentElement.flags | XMLOBJECT_HAS_ATTRS);
        [currentElement.properties addEntriesFromDictionary:attributeDict];
    } else
    if(config.extractArraysIfPossible)
    {
        [currentElement.properties setObject:[NSMutableArray array] forKey:XMLOBJECT_VALUE_KEY];
    }
    
    if(namespaceURI && [namespaceURI length])
    {
        currentElement.flags = (currentElement.flags | XMLOBJECT_HAS_NS);
        [currentElement.properties setObject:namespaceURI forKey:XMLOBJECT_NS_KEY];
    }
    
    currentValue = nil;
}

#pragma mark - Protocol conformance NSXMLParserDelegate

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if(_finished)
    {
        return;
    }
    
    if(ignoringTagName)
    {
        return;
    }
    
    if([[self config] shouldIgnoreTagName:elementName])
    {
        ignoringTagName = elementName;
    }
    
    [self parser:parser readElementName:elementName namespaceURI:namespaceURI qName:qName attributeDict:attributeDict];
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if(_finished || ignoringTagName)
    {
        return;
    }
    
    if(!currentValue)
    {
        currentValue = [NSMutableString string];
    }
    
    [currentValue appendString:string];
}

-(void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock
{
    if(_finished || ignoringTagName)
    {
        return;
    }
    
    if(!currentCData)
    {
        currentCData = [NSMutableData data];
    }
    
    [currentCData appendData:CDATABlock];
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if(_finished)
    {
        return;
    }
    
    if(ignoringTagName)
    {
        if([ignoringTagName isEqualToString:elementName])
        {
            ignoringTagName = nil;
        }
        return;
    }
    
    // build element value based on content characters or CData
    XMLParserConfig *config = [self configInstance];
    NSObject *elementValue = nil;
    if([self hasValue])
    {
        if(config.trimPropertyValues)
        {
            NSString *trimmedValue = [currentValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if([trimmedValue length])
            {
                elementValue = trimmedValue;
            }
        } else
        {
            elementValue = [NSString stringWithString:currentValue];
        }
    }
    
    if([self hasCDATAValue])
    {
        if(config.treatCDataAsStrings)
        {
            NSString *CDataStr = [[NSString alloc] initWithData:currentCData encoding:NSUTF8StringEncoding];
            if(elementValue)
            {
                elementValue = [(NSString*)elementValue stringByAppendingString:CDataStr];
            } else
            {
                elementValue = CDataStr;
            }
        } else
        {
            if(elementValue)
            {
                @throw [NSException exceptionWithName:@"|?|" reason:@"Only one CDATA or string expected" userInfo:nil];
            }
            elementValue = [NSData dataWithData:currentCData];
        }
    }
    
    // reset internal value/cdata holders
    [self resetValueHolders];

    // use element as a property of parent element
    XMLObject *parentElement = [self lastParentElement];
    if(parentElement)
    {
        BOOL isSimple = (false == [self hasAnyValue]) && (0 == [currentElement.properties count]);
        
        NSString *key = [currentElement elementName];
        if(key)
        {
            if(isSimple)
            {
                [self element:parentElement setObject:elementValue forKey:key];
                [self reuseXMLObject:currentElement];
                currentElement = nil;
                elementValue = nil;
            } else
            {
                [self element:parentElement setObject:currentElement forKey:key];
            }
        }
    }
    
    if(currentElement)
    {
        // if not consumed - set element value
        if(elementValue)
        {
            [currentElement.properties setObject:elementValue forKey:XMLOBJECT_VALUE_KEY];
        }
        
        // build xpath
        currentElement.xpath = [self buildElementXPath];
        
        [self simplifyXMLObject:currentElement];
    }
    
    currentElement = parentElement;
    [openElements removeObject:parentElement];
    
    if(_tagName && [elementName isEqualToString:_tagName])
    {
        _finished = YES;
        [openElements removeAllObjects];
        [self.delegate soapObjectParser:self didFinishWithObject:self.rootElement];
    }
}

#pragma mark - Delegate conformance

- (void)soapObjectParser:(XMLObjectParser *)parser didFinishWithObject:(XMLObject *)object
{
    
    NSObject *tagValue = childParser.modelObject;
    if(tagValue)
    {
        if(!_rootElement)
        {
            _rootElement = currentElement;
        } else
        {
            [self element:currentElement setObject:tagValue forKey:parser.tagName];   
        }
    }
    
    [self cacheParser:parser];
    
    NSXMLParser *xmlParser = parser.xmlParser;
    
    childParser.delegate = nil;
    childParser.xmlParser = nil;
    childParser = nil;
    
    self.xmlParser = xmlParser;
}

#pragma mark - Private methods

-(XMLObject*) lastParentElement
{
    return [openElements lastObject];
}

-(void) element:(XMLObject*) element setObject:(NSObject*) object forKey:(NSString*) key
{
    XMLParserConfig *config = [self configInstance];
    if(config.forceLowerCasePropertyNames)
    {
        NSString *firstChar = [key substringToIndex:1];
        NSString *keyTail = [key substringFromIndex:1];
        key = [[firstChar lowercaseString] stringByAppendingString:keyTail];
    }
    
    NSObject *keyValue = object;

    if(config.extractArraysIfPossible && !(element.flags & XMLOBJECT_HAS_ATTRS))
    {
        key = XMLOBJECT_VALUE_KEY;
    }

    NSObject *value = [element.properties objectForKey:key];

    if(value)
    {
        NSMutableArray *items = nil;
        if(![value isKindOfClass:[NSMutableArray class]])
        {
            if(!config.allowAttrsOverwrite || ([value class] == [object class]))
            {
                items = [NSMutableArray arrayWithObject:value];
            }
        } else
        {
            items = (NSMutableArray*) value;
        }
        
        if(items)
        {
            [items addObject:object];
            keyValue = items;
        }
    }
    
    [element.properties setObject:keyValue forKey:key];
}

-(void) simplifyXMLObject:(XMLObject*) object
{
    if(!object)
    {
        return;
    }
    
    if(![object isKindOfClass:[XMLObject class]])
    {
        return;
    }
    
    XMLParserConfig *config = [self configInstance];
    
    /*
     1) if parent has no attrs -> make parent an array
     eq.
     
     <images>
     <resource rid="93" uri="image_241188" type="2569" id="241188" source="desktop" folder="" width="3456" height="4608"/>
     <resource rid="113" uri="image_241202" type="2569" id="241202" source="desktop" folder="" width="4608" height="3456"/>
     <resource rid="119" uri="image_241207" type="2569" id="241207" source="desktop" folder="" width="2592" height="1944"/>
     </images>
     
     into
     
     images : <NSArray>[
        XMLObject(resource),
        XMLObject(resource),
        XMLObject(resource)
     ]
     
     instead of
     
     images : <NSObject>{
        "resource" : <NSArray>[
            XMLObject(resource),
            XMLObject(resource),
            XMLObject(resource)
            ]
     }
     
     
     
     2) if parent has attr -> make parent an object
     eq.
     
     <images id="image_1" name="image_name">
     <resource rid="93" uri="image_241188" type="2569" id="241188" source="desktop" folder="" width="3456" height="4608"/>
     <resource rid="113" uri="image_241202" type="2569" id="241202" source="desktop" folder="" width="4608" height="3456"/>
     <resource rid="119" uri="image_241207" type="2569" id="241207" source="desktop" folder="" width="2592" height="1944"/>
     </images>
     
     into
     
     images : <NSObject>{
        "id" : "image_1",
        "name" : "image_name",
        "resource" : <NSArray>[
            XMLObject(resource),
            XMLObject(resource),
            XMLObject(resource)
            ]
     }
     
     
     */
    if(config.extractArraysIfPossible)
    {
        if(!(object.flags & XMLOBJECT_HAS_ATTRS) && [object.properties count] == 1)
        {
            NSString *key =[[object.properties allKeys] firstObject];
            NSObject *keyObject = [object.properties objectForKey:key];
            if([keyObject isKindOfClass:[NSArray class]])
            {
                XMLObject *parent = [self lastParentElement];
                __block NSString *objectKey = nil;
                [parent.properties enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSObject *item, BOOL *stop){
                    if(item == object)
                    {
                        objectKey = key;
                        *stop = YES;
                    }
                }];
                if(objectKey)
                {
                    [parent.properties setObject:keyObject forKey:objectKey];
                    [object.properties removeAllObjects];
                    [self reuseXMLObject:object];
                }
            }
        }
    }
    
}

-(NSString*) buildElementXPath
{
    if(!currentElement)
    {
        return nil;
    }
    
    NSString *separator = @"/";
    __block NSMutableString *xpath = [NSMutableString stringWithString:@""];
    [openElements enumerateObjectsUsingBlock:^(XMLObject *xmlObject, NSUInteger idx, BOOL *stop){
        [xpath appendString:xmlObject.elementName];
        [xpath appendString:separator];
    }];
    [xpath appendString:currentElement.elementName];
    return [NSString stringWithString:xpath];
}

-(BOOL) hasValue
{
    return currentValue && ([currentValue length] > 0);
}

-(BOOL) hasCDATAValue
{
    return currentCData && ([currentCData length] > 0);
}

-(BOOL) hasAnyValue
{
    return [self hasValue] || [self hasCDATAValue];
}

-(void) resetValueHolders
{
    if(currentValue)
    {
        [currentValue deleteCharactersInRange:NSMakeRange(0, currentValue.length)];
    }
    
    if(currentCData)
    {
        currentCData.length = 0;
    }
}

-(XMLObject*) newXMLObject
{
    XMLParserCache *cache = [[self configInstance] cache];
    XMLObject *object = (XMLObject*)[cache popObjectForKey:XMLOBJECT_CACHE_KEY];

    if(!object)
    {
        object = [[XMLObject alloc] init];
    }
    
    return object;
}

-(void) reuseXMLObject:(NSObject*)xmlObject
{
    if(!xmlObject)
    {
        return;
    }
    
    if(![xmlObject isKindOfClass:[XMLObject class]])
    {
        return;
    }
    
    XMLObject *castedObject = (XMLObject*) xmlObject;
    castedObject.flags = 0;
    [castedObject.properties removeAllObjects];
    [[[self configInstance] cache] pushObject:castedObject forKey:XMLOBJECT_CACHE_KEY];
}

-(XMLObjectParser*) parserForTag:(NSString*) tagName
{
    XMLParserConfig *config = [self configInstance];
    XMLObjectParser *parser = (XMLObjectParser*)[config.cache popObjectForKey:tagName];
    
    if(!parser)
    {
        Class parserClass = [config parserClassForTagName:tagName];
        if(parserClass)
        {
            parser = [[parserClass alloc] initWithTagName:tagName];
        }
    }
    
    if(parser)
    {
        parser.config = [self configInstance];
        [parser reset];
    }
    
    return parser;
}

-(void) cacheParser:(XMLObjectParser*) parser
{
    if(!parser)
    {
        return;
    }
    
    parser.config = nil;
    
    [[[self configInstance] cache] pushObject:parser forKey:parser.tagName];
}

-(XMLParserConfig*) configInstance
{
    if(!self.config)
    {
        self.config = [XMLParserConfig defaultConfig];
    }
    if(!self.config.cache)
    {
        self.config.cache = [XMLParserCache cache];
    }
    return self.config;
}

- (void)dealloc {
    self.delegate = nil;
    self.xmlParser = nil;
    
    self.config = nil;
    
    _tagName = nil;
    _rootElement = nil;
    childParser = nil;
    currentElement = nil;
}


@end
