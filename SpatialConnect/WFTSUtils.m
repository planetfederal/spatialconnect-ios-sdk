//
//  WFSParser.m
//  SpatialConnect
//
//  Created by Landon Robinson on 11/30/17.
//  Copyright © 2017 Boundless Spatial. All rights reserved.
//

#import "WFSTUtils.h"
#import <Foundation/Foundation.h>

@implementation WFSTUtils

+ (NSString *)buildWFSTInsertPayload:(SCSpatialFeature *)feature url:(NSString *)remoteUrl {
  
  NSString *featureTypeUrl = [NSString
                              stringWithFormat:@"%@/geoserver/wfs/DescribeFeatureType?typename=%@:%@",
                              remoteUrl, @"geonode", feature.layerId];
  
  return [NSString stringWithFormat:wfstInsertTemplate, featureTypeUrl,
          feature.layerId,
          [self buildPropertiesXml:feature],
          [self buildGeometryXml:feature]];
}

+ (NSString *)buildWFSTUpdatePayload:(SCSpatialFeature *)feature {
  
  return [NSString stringWithFormat:wfstUpdateTemplate, feature.layerId,
          [self buildPropertiesXml:feature],
          [self buildFilterXml:feature]];
}

+ (NSString *)buildWFSTDeletePayload:(SCSpatialFeature *)feature {
  
  return [NSString stringWithFormat:wfstDeleteTemplate, feature.layerId,
          [self buildFilterXml:feature]];
}

+ (NSString *)buildPropertiesXml:(SCSpatialFeature *)feature {
  NSMutableString *properties = [NSMutableString new];
  [feature.properties enumerateKeysAndObjectsUsingBlock:^(
                                                          NSString *key, NSObject *obj, BOOL *stop) {
    if (![obj isEqual:[NSNull null]]) {
      [properties appendString:[NSString stringWithFormat:@"<%1$@>%2$@</%1$@>",
                                key, obj]];
    }
    
  }];
  return properties;
}

+ (NSString *)buildGeometryXml:(SCSpatialFeature *)feature {
  NSDictionary *geoJson = feature.JSONDict;
  NSDictionary *geometry = [geoJson objectForKey:@"geometry"];
  NSArray *coordinate = [geometry objectForKey:@"coordinates"];
  NSString *geometryXml;
  
  if (![geometry isEqual:[NSNull null]]) {
    // need to find geometry property instead of hard coding it
    NSString *geomColumn = @"wkb_geometry";
    geometryXml =
    [NSString stringWithFormat:wfstPointTemplate, geomColumn,
     [[coordinate objectAtIndex:0] doubleValue],
     [[coordinate objectAtIndex:1] doubleValue]];
  } else {
    geometryXml = @"";
  }
  
  return geometryXml;
}

+ (NSString *)buildFilterXml:(SCSpatialFeature *)feature {
  NSString *ogcFilter = @"<ogc:Filter>\n"
  "   <ogc:FeatureId fid=\"%1$@\"/>\n"
  "</ogc:Filter>\n";
  NSString *filterXml =
  [NSString stringWithFormat:ogcFilter, feature.identifier];
  
  return filterXml;
}



static NSString *wfstInsertTemplate =
@"<wfs:Transaction service=\"WFS\" version=\"1.0.0\"\n"
"xmlns:wfs=\"http://www.opengis.net/wfs\"\n"
"xmlns:gml=\"http://www.opengis.net/gml\"\n"
"xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n"
"xsi:schemaLocation=\"http://www.opengis.net/wfs "
"http://schemas.opengis.net/wfs/1.0.0/WFS-transaction.xsd %1$@\">\n"
"<wfs:Insert>\n"
"<%2$@>\n"
"%3$@"
"%4$@"
"</%2$@>\n"
"</wfs:Insert>\n"
"</wfs:Transaction>";

static NSString *wfstPointTemplate =
@"<%1$@>\n"
"<gml:Point srsName=\"http://www.opengis.net/gml/srs/epsg.xml#4326\">\n"
"<gml:coordinates decimal=\".\" cs=\",\" ts=\" "
"\">%2$f,%3$f</gml:coordinates>\n"
"</gml:Point>\n"
"</%1$@>\n";

static NSString *wfstDeleteTemplate =
@"<wfs:Transaction service=\"WFS\" version=\"1.0.0\"\n"
"xmlns:wfs=\"http://www.opengis.net/wfs\"\n"
"xmlns:gml=\"http://www.opengis.net/gml\"\n"
"  xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n"
"  xsi:schemaLocation=\"http://www.opengis.net/wfs "
"http://schemas.opengis.net/wfs/1.0.0/WFS-transaction.xsd \">\n"
"  <wfs:Delete typeName=\"%1$@\">\n"
"   %2$@\n"
"  </wfs:Delete>\n"
"</wfs:Transaction>";

static NSString *wfstUpdateTemplate =
@"<wfs:Transaction service=\"WFS\" version=\"1.0.0\"\n"
"  xmlns:wfs=\"http://www.opengis.net/wfs\"\n"
"  xmlns:gml=\"http://www.opengis.net/gml\"\n"
"  xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n"
"  xsi:schemaLocation=\"http://www.opengis.net/wfs "
"http://schemas.opengis.net/wfs/1.0.0/WFS-transaction.xsd \">\n"
"  <wfs:Update typeName=\"%1$@\">\n"
"      %2$@\n"
"      %3$@\n"
"  </wfs:Update>\n"
"</wfs:Transaction>";

@end

