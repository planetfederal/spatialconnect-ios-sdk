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

@interface GeopackageStore (PrivateMethods)

@end

@implementation GeopackageStore

#define STORE_NAME @"Geopackage"
#define TYPE @"gpkg"
#define VERSION 1

#pragma mark -
#pragma mark Init Methods

- (id)initWithStoreConfig:(SCStoreConfig *)config {
  self = [super initWithStoreConfig:config];
  if (!self) {
    return nil;
  }
  adapter = [[GeopackageFileAdapter alloc] initWithStoreConfig:config];
  _name = config.name;
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

- (void)start {
  self.status = SC_DATASTORE_STARTED;
  [adapter.connect subscribeCompleted:^{
    self.status = SC_DATASTORE_RUNNING;
  }];
}

- (void)stop {
  self.status = SC_DATASTORE_STOPPED;
}

- (void)resume {
}

- (void)pause {
}

#pragma mark -
#pragma mark SCSpatialStore
- (RACSignal *)queryAllLayers:(SCQueryFilter *)filter {
  return nil;
}

- (RACSignal *)queryByLayerId:(NSString *)layerId
                   withFilter:(SCQueryFilter *)filter {
  return nil;
}

- (RACSignal *)createFeature:(SCSpatialFeature *)feature {
  return nil;
}

- (RACSignal *)updateFeature:(SCSpatialFeature *)feature {
  return nil;
}

- (RACSignal *)deleteFeature:(NSString *)identifier {
  return nil;
}

#pragma mark -
#pragma mark Override Parent
+ (NSString *)versionKey {
  return [NSString stringWithFormat:@"%@.%d", TYPE, VERSION];
}

@end
