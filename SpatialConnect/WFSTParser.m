//
//  WFSParser.m
//  SpatialConnect
//
//  Created by Landon Robinson on 11/30/17.
//  Copyright © 2017 Boundless Spatial. All rights reserved.
//

#import "WFSTParser.h"
#import <Foundation/Foundation.h>

@implementation WFSTParser

@synthesize featureId;

- (id)initWithData:(NSData *)data {
  self = [super init];
  if (self) {
    self.success = NO;
    NSXMLParser *xmlParser = [[NSXMLParser alloc]
        initWithData:data]; // init NSXMLParser with receivedXMLData
    [xmlParser setDelegate:self];
    [xmlParser parse];
  }
  return self;
}

- (void)parser:(NSXMLParser *)parser
    didStartElement:(NSString *)elementName
       namespaceURI:(NSString *)namespaceURI
      qualifiedName:(NSString *)qName
         attributes:(NSDictionary *)attributeDict {
  if ([elementName isEqualToString:@"ogc:FeatureId"]) {
    self.featureId = [attributeDict objectForKey:@"fid"];
  }
  if ([elementName isEqualToString:@"wfs:SUCCESS"]) {
    self.success = YES;
  }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
  DDLogError(@"WFST parse error %@", parseError.localizedFailureReason);
}

@end
