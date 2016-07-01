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
 * See the License for the specific language governing permissions and limitations under the License
 */

#import "WFSDataStore.h"
#import "XMLDictionary.h"
#import "SCGeoFilterContains.h"
#import "SCBoundingBox.h"
#import "SCPoint.h"

@interface WFSDataStore()
@property (readwrite) NSString* baseUri;
@end

@implementation WFSDataStore

#define TYPE @"wfs"
#define VERSION @"1.1"

@synthesize baseUri,storeVersion,storeType;

- (id)initWithStoreConfig:(SCStoreConfig *)config {
  self = [super initWithStoreConfig:config];
  if (!self) {
    return nil;
  }
  self.baseUri = config.uri;
  self.name = config.name;
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

- (NSArray*) layerList {
  NSString *url = [NSString stringWithFormat:@"%@?service=WFS&version=1.1.0&request=GetCapabilities",self.baseUri];
  SCNetworkService *ns = [[SpatialConnect sharedInstance] networkService];
  NSData *data = [ns getRequestURLAsDataBLOCKING:[NSURL URLWithString:url]];
  NSDictionary* d = [NSDictionary dictionaryWithXMLData:data];
  NSMutableArray *layers = [NSMutableArray new];
  NSArray *a = d[@"FeatureTypeList"][@"FeatureType"];
  [a enumerateObjectsUsingBlock:^(NSDictionary *d, NSUInteger idx, BOOL * _Nonnull stop) {
    [layers addObject:d[@"Name"]];
  }];
  return [NSArray arrayWithArray:layers];
}

- (NSString*)defaultLayerName {
  return [[self layerList] firstObject];
}

- (NSString*)storeType {
  return @"wfs";
}

- (NSString*)storeVersion {
  return @"1.1";
}

#pragma mark -
#pragma mark SCSpatialStore
- (RACSignal*)query:(SCQueryFilter *)filter {
  NSMutableString *url = [NSMutableString stringWithFormat:@"%@?service=WFS&version=1.1&request=GetFeature&typeName=%@&outputFormat=application/json&srsname=EPSG:4326&maxFeatures=%ld",self.baseUri,filter.layerIds[0],(long)filter.limit];

  SCPredicate *p = [[filter geometryFilters] firstObject];
  if ([p.filter isKindOfClass:[SCGeoFilterContains class]]) {
    SCGeoFilterContains *fc = (SCGeoFilterContains *)p.filter;
    SCBoundingBox *b = fc.bbox;
    [url appendFormat:@"&bbox=%f,%f,%f,%f,EPSG:4326",b.lowerLeft.longitude,b.lowerLeft.latitude,b.upperRight.longitude,b.upperRight.latitude];

  }

  SCNetworkService *ns = [[SpatialConnect sharedInstance] networkService];
  return [[ns getRequestURLAsDict:[NSURL URLWithString:url]]
          map:^SCGeometry*(NSDictionary *d) {
            SCGeometry *g = [SCGeoJSON parseDict:d];
            g.layerId = filter.layerIds[0];
            g.storeId = self.storeId;
            return g;
          }];
}

- (RACSignal*)queryById:(SCKeyTuple *)key {
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

#pragma mark -
#pragma mark SCDataStoreLifeCycle

- (RACSignal *)start {
  self.status = SC_DATASTORE_RUNNING;
  return [RACSignal empty];
}

- (void)stop {
  self.status = SC_DATASTORE_STOPPED;
}

- (void)pause {
  self.status = SC_DATASTORE_PAUSED;
}

- (void)resume {
  self.status = SC_DATASTORE_RUNNING;
}

+ (NSString *)versionKey {
  return [NSString stringWithFormat:@"%@.%@", TYPE, VERSION];
}

@end
