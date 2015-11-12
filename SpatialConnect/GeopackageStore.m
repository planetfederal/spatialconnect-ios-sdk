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
#define VERSION 1

@synthesize adapter = _adapter;

#pragma mark -
#pragma mark Init Methods

@synthesize type = _type;
@synthesize version = _version;

- (id)initWithStoreConfig:(SCStoreConfig *)config {
  self = [super initWithStoreConfig:config];
  if (!self) {
    return nil;
  }
  _adapter = [[GeopackageFileAdapter alloc] initWithStoreConfig:config];
  self.name = config.name;
  _type = TYPE;
  _version = VERSION;
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
  self.status = SC_DATASTORE_STARTED;
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.adapter.connect subscribeCompleted:^{
          self.status = SC_DATASTORE_RUNNING;
          [subscriber sendCompleted];
        }];
        return nil;
      }];
}

- (void)stop {
  self.status = SC_DATASTORE_STOPPED;
}

- (void)resume {
}

- (void)pause {
}

- (NSString *)defaultLayerName {
  return self.adapter.defaultLayerName;
}

#pragma mark -
#pragma mark SCSpatialStore
- (RACSignal *)queryAllLayers:(SCQueryFilter *)filter {
  return [self.adapter queryAllLayers:filter];
}

- (RACSignal *)queryByLayerId:(NSString *)layerId
                   withFilter:(SCQueryFilter *)filter {
  return [self.adapter queryByLayerId:layerId withFilter:filter];
}

- (RACSignal *)createFeature:(SCSpatialFeature *)feature {
  return [self.adapter createFeature:feature];
}

- (RACSignal *)updateFeature:(SCSpatialFeature *)feature {
  return [self.adapter updateFeature:feature];
}

- (RACSignal *)deleteFeature:(NSString *)identifier {
  return [self.adapter deleteFeature:identifier];
}

- (NSArray *)layerList {
  NSArray *arr = self.adapter.layerList;
  return arr;
}

#pragma mark -
#pragma mark Override Parent
- (NSString *)key {
  NSString *str = [NSString stringWithFormat:@"%@.%d", TYPE, VERSION];
  return str;
}

+ (NSString *)versionKey {
  return [NSString stringWithFormat:@"%@.%d", TYPE, VERSION];
}

@end
