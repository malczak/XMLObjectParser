//
// Created by Mateusz Malczak on 17/03/2014.
// Copyright (c) 2014
//

#import "XMLObjectParser.h"

#pragma mark - SoapObject implemenatation

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


#pragma mark - SoapObjectParser implementation
static NSString *OBJECT_CACHE_KEY = @"_object_cache_key";

@interface XMLObjectParser() <NSXMLParserDelegate, SoapObjectParserDelegate>

@end;

@implementation XMLObjectParser

-(id)initWithTagName:(NSString*)parserTagName
{
    self = [self init];
    if(self)
    {
        _tagName = parserTagName;
    }
    return self;
}

-(id)initWithTagName:(NSString*)parserTagName childParsers:(NSMutableDictionary *)parsers
{
    self = [self initWithTagName:parserTagName];
    if(self)
    {
        childParsers = parsers;
    }
    return self;
}

- (id)init
{
    self = [super init];
    if(self)
    {
        _finished = NO;
        openElements = [NSMutableArray array];
        
        self.forceLowerCasePropertyNames = YES;
        self.treatCDataAsStrings = YES;
        self.trimPropertyValues = YES;
        self.allowAttrsOverwrite = NO;
    }
    return self;
}

-(id)clone
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

-(void)addParser:(Class)parserClass forTagName:(NSString*) tagName
{
    if(!childParsers)
    {
        childParsers = [NSMutableDictionary dictionary];
    }
    [childParsers setObject:parserClass forKey:tagName];
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
    
    childParser = [self parserForTag:elementName];
    if(childParser)
    {
        [childParser reset];
        childParser.delegate = self;
        childParser.xmlParser = self.xmlParser;
        [childParser parser:parser
            didStartElement:elementName
               namespaceURI:namespaceURI
              qualifiedName:qName
                 attributes:attributeDict];
        return;
    }
    
    if(currentElement)
    {
        currentElement.simple = NO;
        [openElements addObject:currentElement];
    }
    
    currentElement = [self newXMLObject];
    currentElement.elementName = elementName;
    
    if(_rootElement ==nil)
    {
        _rootElement = currentElement;
        [openElements addObject:_rootElement];
    };
    
    [currentElement.properties addEntriesFromDictionary:attributeDict];
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
    
    if(includeTagNames && ![includeTagNames member:elementName])
    {
        ignoringTagName = elementName;
        return;
    }
    
    if(ignoredTagNames && [ignoredTagNames member:elementName])
    {
        ignoringTagName = elementName;
        return;
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
    NSObject *elementValue = nil;
    if([self hasValue])
    {
        if(self.trimPropertyValues)
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
        if(self.treatCDataAsStrings)
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
            if(self.forceLowerCasePropertyNames)
            {
                NSString *firstChar = [key substringToIndex:1];
                NSString *keyTail = [key substringFromIndex:1];
                key = [[firstChar lowercaseString] stringByAppendingString:keyTail];
            }
            
            if(isSimple)
            {
                [self element:parentElement setObject:elementValue forKey:key];
                [self reuseXMLObject:currentElement];
                elementValue = nil;
            } else
            {
                [self element:parentElement setObject:currentElement forKey:key];
            }
        }
    }
    
    // if not consumed - set element value
    if(elementValue)
    {
        [currentElement.properties setObject:elementValue forKey:@"value"];
    }
    
    // build xpath
    currentElement.xpath = [self buildElementXPath];
    
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

- (void)soapObjectParser:(XMLObjectParser *)parser didFinishWithObject:(XMLObject *)object {
    
    NSObject *tagValue = childParser.modelObject;
    if(tagValue)
    {
        [self element:currentElement setObject:tagValue forKey:parser.tagName];
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
    NSObject *keyValue = object;
    NSObject *value = [element.properties objectForKey:key];
    if(value)
    {
        NSMutableArray *items = nil;
        if(![value isKindOfClass:[NSMutableArray class]])
        {
            if(!self.allowAttrsOverwrite || ([value class] == [object class]))
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
    
    // try to extract array :?
    
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
    XMLParserCache *cache = [self cacheInstance];
    XMLObject *object = (XMLObject*)[cache popObjectForKey:OBJECT_CACHE_KEY];

    if(!object)
    {
        object = [[XMLObject alloc] init];
    }
    
    return object;
}

-(void) reuseXMLObject:(XMLObject*)xmlObject
{
    if(!xmlObject)
    {
        return;
    }
    
    [[self cacheInstance] pushObject:xmlObject forKey:OBJECT_CACHE_KEY];
}

-(XMLObjectParser*) parserForTag:(NSString*) tagName
{
    XMLParserCache *cache = [self cacheInstance];
    XMLObjectParser *parser = (XMLObjectParser*)[cache popObjectForKey:tagName];
    
    if(!parser)
    {
        Class elementParserClass = (childParsers) ? [childParsers objectForKey:tagName] : nil;
        if(elementParserClass)
        {
            parser = [[elementParserClass alloc] initWithTagName:tagName];
        }
    }
    
    parser.cache = cache;
    
    return parser;
}

-(void) cacheParser:(XMLObjectParser*) parser
{
    if(!parser)
    {
        return;
    }
    
    parser.cache = nil;
    
    [[self cacheInstance] pushObject:parser forKey:parser.tagName];
}

-(XMLParserCache*) cacheInstance
{
    if(!self.cache)
    {
        self.cache = [XMLParserCache cache];
    }
    return self.cache;
}

- (void)dealloc {
    self.delegate = nil;
    self.xmlParser = nil;
    
    self.cache = nil;
    
    _tagName = nil;
    _rootElement = nil;
    childParser = nil;
    currentElement = nil;
    childParsers = nil;
}


@end
