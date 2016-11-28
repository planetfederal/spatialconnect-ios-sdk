/**
 * Copyright 2016 Boundless http://boundlessgeo.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License
 */

#import "WFSDataStore.h"
#import "SCBoundingBox.h"
#import "SCGeoFilterContains.h"
#import "SCGeometryCollection.h"
#import "SCHttpUtils.h"
#import "SCPoint.h"
#import "XMLDictionary.h"

@interface WFSDataStore ()
@property(readwrite) NSString *baseUri;
@property(readwrite) NSArray *defaultLayers;
@end

@implementation WFSDataStore

#define TYPE @"wfs"
#define VERSION @"1.1.0"

@synthesize baseUri, storeVersion, storeType, defaultLayers;

- (id)initWithStoreConfig:(SCStoreConfig *)config {
  self = [super initWithStoreConfig:config];
  if (!self) {
    return nil;
  }
  self.baseUri = config.uri;
  self.name = config.name;
  self.defaultLayers = config.defaultLayers;
  return self;
}

- (id)initWithStoreConfig:(SCStoreConfig *)config withStyle:(SCStyle *)style {
  self = [self initWithStoreConfig:config];
  if (!self) {
    return nil;
  }
  self.style = style;
  return self;
}

- (NSArray *)layers {
  return self.vectorLayers;
}

- (NSArray *)vectorLayers {
  NSString *url = [NSString
      stringWithFormat:@"%@?service=WFS&version=%@&request=GetCapabilities",
                       self.baseUri, self.storeVersion];
  NSData *data =
      [SCHttpUtils getRequestURLAsDataBLOCKING:[NSURL URLWithString:url]];
  NSDictionary *d = [NSDictionary dictionaryWithXMLData:data];
  NSMutableArray *layers = [NSMutableArray new];
  id a = d[@"FeatureTypeList"][@"FeatureType"];
  if ([a isKindOfClass:NSDictionary.class]) {
    [layers addObject:a[@"Name"]];
  } else {
    [a enumerateObjectsUsingBlock:^(NSDictionary *d, NSUInteger idx,
                                    BOOL *_Nonnull stop) {
      [layers addObject:d[@"Name"]];
    }];
  }
  return [NSArray arrayWithArray:layers];
}

- (NSString *)storeType {
  return @"wfs";
}

- (NSString *)storeVersion {
  return @"1.1.0";
}

#pragma mark -
#pragma mark SCSpatialStore
- (RACSignal *)query:(SCQueryFilter *)filter {
  NSArray *layers =
      filter.layerIds.count == 0 ? [self defaultLayers] : filter.layerIds;
  NSMutableString *url = [NSMutableString
      stringWithFormat:@"%@?service=WFS&version=%@&request=GetFeature&typeName="
                       @"%@&outputFormat=application/"
                       @"json&srsname=EPSG:4326&maxFeatures=%ld",
                       self.baseUri, self.storeVersion,
                       [layers componentsJoinedByString:@","],
                       (long)filter.limit];
  SCPredicate *p = [[filter geometryFilters] firstObject];
  if ([p.filter isKindOfClass:[SCGeoFilterContains class]]) {
    SCGeoFilterContains *fc = (SCGeoFilterContains *)p.filter;
    SCBoundingBox *b = fc.bbox;
    [url appendFormat:@"&bbox=%f,%f,%f,%f,EPSG:4326", b.lowerLeft.longitude,
                      b.lowerLeft.latitude, b.upperRight.longitude,
                      b.upperRight.latitude];
  }

  return [[[SCHttpUtils getRequestURLAsDict:[NSURL URLWithString:url]]
      flattenMap:^RACStream *(NSDictionary *d) {
        SCGeometry *g = [SCGeoJSON parseDict:d];
        if ([g isKindOfClass:[SCGeometryCollection class]]) {
          SCGeometryCollection *gc = (SCGeometryCollection *)g;
          return [[gc.geometries rac_sequence] signal];
        } else {
          return [RACStream return:g];
        }
      }] map:^SCGeometry *(SCGeometry *g) {
    NSString *ident = g.identifier;
    NSArray *arr = [ident componentsSeparatedByString:@"."];
    if (arr.count > 1) {
      NSArray *layerArr = [arr subarrayWithRange:NSMakeRange(0, arr.count - 1)];
      g.layerId = [layerArr componentsJoinedByString:@"."];
    }
    g.storeId = self.storeId;
    return g;
  }];
}

- (RACSignal *)queryById:(SCKeyTuple *)key {
  return nil;
}

- (RACSignal *)create:(SCSpatialFeature *)feature {
  return nil;
}

- (RACSignal *)update:(SCSpatialFeature *)feature {
  return nil;
}

- (RACSignal *) delete:(SCSpatialFeature *)feature {
  return nil;
}

+ (NSString *)versionKey {
  return [NSString stringWithFormat:@"%@.%@", TYPE, VERSION];
}

@end
