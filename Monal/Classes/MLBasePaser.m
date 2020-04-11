//
//  MLBasePaser.m
//  monalxmpp
//
//  Created by Anurodh Pokharel on 4/11/20.
//  Copyright © 2020 Monal.im. All rights reserved.
//

#import "MLBasePaser.h"

@interface MLBasePaser ()

@property (nonatomic, strong) XMPPParser *currentParser;
@property (nonatomic, assign) NSInteger depth;
@property (nonatomic, strong) stanzaCompletion compeltion;

@end

@implementation MLBasePaser

-(id) initWithCompeltion:(stanzaCompletion) completion
{
    self =[super init];
    self.compeltion = completion;
    return self;
}

-(void) reset
{
    self.currentParser=nil;
    self.depth=0; 
}

#pragma mark common parser delegate functions
- (void)parserDidStartDocument:(NSXMLParser *)parser{
    DDLogVerbose(@"Document start");
    self.currentParser=nil;
     self.depth=0;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    self.depth++;
    DDLogDebug(@"Started element :%@ with depth: %ld", elementName, self.depth);
    
    //look at the element not the name space
    NSString *nameSpace;
    NSArray *parts =[elementName componentsSeparatedByString:@":"];
    if(parts.count>1)
    {
        nameSpace =parts[0];
        elementName =parts[1];
    }
    
    if(self.depth <=2) // stream:stream is 1
    {
        [self makeStanzaParser:elementName];
        self.currentParser.stanzaType=elementName;
        self.currentParser.stanzaNameSpace=nameSpace;
    }
    
    if(!self.currentParser)
    {
        DDLogError(@"no parser!");
        return;
    }
    
    [self.currentParser parser:parser didStartElement:elementName namespaceURI:nameSpace qualifiedName:qName attributes:attributeDict];

}

-(void) makeStanzaParser:(NSString *) elementName
{
    DDLogDebug(@"Getting parser for %@", elementName);
    if([elementName isEqualToString:@"a"])
    {
        self.currentParser=[[ParseA alloc] init];
    }
    
    if([elementName isEqualToString:@"stream"] ||
       [elementName isEqualToString:@"proceed"] ||
       [elementName isEqualToString:@"success"] ||
       [elementName isEqualToString:@"features"]
       )
    {
        self.currentParser=[[ParseStream alloc] init];
    }
    
    if([elementName isEqualToString:@"iq"])
    {
        self.currentParser=[[ParseIq alloc] init];
    }
    
    if([elementName isEqualToString:@"message"])
    {
        self.currentParser=[[ParseMessage alloc] init];
    }
    
    if([elementName isEqualToString:@"presence"])
    {
        self.currentParser=[[ParsePresence alloc] init];
    }
    
    if([elementName isEqualToString:@"enabled"])
    {
        self.currentParser=[[ParseEnabled alloc] init];
    }
    if([elementName isEqualToString:@"failed"])
    {
        self.currentParser=[[ParseFailed alloc] init];
    }
    if([elementName isEqualToString:@"resumed"])
    {
        self.currentParser=[[ParseResumed alloc] init];
    }

    if([elementName isEqualToString:@"failure"])
    {
        self.currentParser=[[ParseFailure alloc] init];
    }
    if([elementName isEqualToString:@"challenge"])
    {
        self.currentParser=[[ParseChallenge alloc] init];
    }
        
    if(!self.currentParser) {
        self.currentParser =[[XMPPParser alloc] init];
    }
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    [self.currentParser parser:parser foundCharacters:string];
}


-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    DDLogDebug(@"Ended element :%@ depth %ld", elementName, self.depth);
    [self.currentParser parser:parser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
    
    if(self.depth <=2) {
        if(self.compeltion) {
            if(!self.currentParser) {
                DDLogError(@"No parser. not calling completion");
            }
            self.compeltion(self.currentParser);
        } else  {
            DDLogError(@"no completion handler for stanza!");
        }
        self.currentParser=nil;
    }
    self.depth--;
}


-(void)parserDidEndDocument:(NSXMLParser *)parser {
    DDLogVerbose(@"Document end");
}

- (void)parser:(NSXMLParser *)parser foundIgnorableWhitespace:(NSString *)whitespaceString
{
    DDLogVerbose(@"found ignorable whitespace: %@", whitespaceString);
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    DDLogError(@"Error: line: %ld , col: %ld desc: %@ ",(long)[parser lineNumber],
               (long)[parser columnNumber], [parseError localizedDescription]);
}


@end
