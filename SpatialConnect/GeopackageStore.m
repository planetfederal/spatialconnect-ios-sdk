/*****************************************************************************
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 ******************************************************************************/

#import "GeopackageStore.h"

NSString *const SCGeopackageErrorDomain = @"SCGeopackageErrorDomain";

@interface GeopackageStore ()
@property(readwrite, nonatomic, strong) GeopackageFileAdapter *adapter;
@end

@implementation GeopackageStore

#define STORE_NAME @"Geopackage"
#define TYPE @"gpkg"
#define VERSION @"1"

@synthesize adapter = _adapter;

#pragma mark -
#pragma mark Init Methods

@synthesize storeType = _storeType;
@synthesize storeVersion = _storeVersion;

- (id)initWithStoreConfig:(SCStoreConfig *)config {
  self = [super initWithStoreConfig:config];
  if (!self) {
    return nil;
  }
  _adapter = [[GeopackageFileAdapter alloc] initWithFileName:config.uniqueid andURI:config.uri];
  self.name = config.name;
  self.permission = SC_DATASTORE_READWRITE;
  _storeType = TYPE;
  _storeVersion = VERSION;
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

#pragma mark -
#pragma mark SCDataStoreLifeCycle

- (RACSignal *)start {
  self.adapter.parentStore = self;
  self.status = SC_DATASTORE_STARTED;
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.adapter.connect subscribeError:^(NSError *error) {
          self.status = SC_DATASTORE_STOPPED;
          [subscriber sendError:error];
        }
            completed:^{
              self.status = SC_DATASTORE_RUNNING;
              [subscriber sendCompleted];
            }];
        return nil;
      }];
}

- (void)stop {
  [self.adapter disconnect];
  self.status = SC_DATASTORE_STOPPED;
}

- (void)resume {
}

- (void)pause {
}

- (NSString *)defaultLayerName {
  return self.adapter.defaultLayerName;
}

- (void)addLayer:(NSString *)name withDef:(NSDictionary *)def {
  [self.adapter addLayer:name typeDefs:def];
}

- (void)removeLayer:(NSString *)name {
}

#pragma mark -
#pragma mark SCRasterStore
- (MKTileOverlay *)overlayFromLayer:(NSString *)layer
                            mapview:(MKMapView *)mapView {
  return [self.adapter overlayFromLayer:layer mapview:mapView];
}

#pragma mark -
#pragma mark SCSpatialStore
- (RACSignal *)query:(SCQueryFilter *)filter {
  return [[self.adapter query:filter] map:^SCSpatialFeature *(SCSpatialFeature *f) {
    f.storeId = self.storeId;
    return f;
  }];
}

- (RACSignal *)queryById:(SCKeyTuple *)key {
  return [self.adapter queryById:key];
}

- (RACSignal *)create:(SCSpatialFeature *)feature {
  if (feature.storeId == nil) {
    feature.storeId = self.storeId;
  }
  if (feature.layerId == nil) {
    feature.layerId = self.defaultLayerName;
  }
  return [self.adapter createFeature:feature];
}

- (RACSignal *)update:(SCSpatialFeature *)feature {
  return [self.adapter updateFeature:feature];
}

- (RACSignal *) delete:(SCKeyTuple *)tuple {
  NSParameterAssert(tuple);
  return [self.adapter deleteFeature:tuple];
}

- (NSArray *)layers {
  return [self.vectorLayers arrayByAddingObjectsFromArray:self.rasterLayers];
}

- (NSArray *)vectorLayers {
  return [[[[self.adapter.vectorLayers rac_sequence] signal]
   map:^NSString *(SCGpkgFeatureSource *f) {
     return f.name;
   }] toArray];
}

- (NSArray *)rasterLayers {
  return [[[[self.adapter.rasterLayers rac_sequence] signal]
   map:^NSString *(SCGpkgFeatureSource *f) {
     return f.name;
   }] toArray];
}

- (NSString *)defaultLayer {
  return @"DEFAULT";
}

- (SCPolygon *)coverage:(NSString *)layer {
  return [self.adapter coverage:layer];
}

#pragma mark -
#pragma mark Override Parent
- (NSString *)key {
  NSString *str =
      [NSString stringWithFormat:@"%@.%@", _storeType, _storeVersion];
  return str;
}

+ (NSString *)versionKey {
  return [NSString stringWithFormat:@"%@.%@", TYPE, VERSION];
}

@end
