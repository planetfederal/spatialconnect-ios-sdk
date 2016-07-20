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

#import "GeoJSONStore.h"
#import "SCFileUtils.h"

#ifndef TEST
BOOL const isUnitTesting = NO;
#else
BOOL const isUnitTesting = YES;
#endif

@interface GeoJSONStore ()
- (void)initializeAdapter:(SCStoreConfig *)config;
@end

@implementation GeoJSONStore

const int kVERSION = 1;
const NSString *kTYPE = @"geojson";
const NSString *kSTORE_NAME = @"GeoJSONStore";

- (id)initWithStoreConfig:(SCStoreConfig *)config {
  self = [super initWithStoreConfig:config];
  if (!self) {
    return nil;
  }
  self.name = config.name;
  [self initializeAdapter:config];
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

- (void)initializeAdapter:(SCStoreConfig *)config {
  NSString *filePath;
  if (config.isMainBundle) {
    filePath = [SCFileUtils filePathFromMainBundle:config.uri];
  } else {
    if (isUnitTesting) {
      filePath = [SCFileUtils filePathFromNSHomeDirectory:config.uri];
    } else {
      filePath = [SCFileUtils filePathFromDocumentsDirectory:config.uri];
    }
  }
  adapter = [[GeoJSONAdapter alloc] initWithFilePath:filePath];
  adapter.defaultStyle = self.style;
  adapter.storeId = self.storeId;
}

- (NSString *)storeType {
  return [NSString stringWithFormat:@"%@", kTYPE];
}

- (NSInteger)version {
  return kVERSION;
}

#pragma mark -
#pragma mark SCSpatialStore
- (RACSignal *)query:(SCQueryFilter *)filter {
  return [(GeoJSONAdapter *)adapter query:filter];
}

- (RACSignal *)queryById:(SCKeyTuple *)key {
  return nil;
}

- (RACSignal *)create:(SCSpatialFeature *)feature {
  return [(GeoJSONAdapter *)adapter create:feature];
}

- (RACSignal *)update:(SCSpatialFeature *)feature {
  return [(GeoJSONAdapter *)adapter update:feature];
}

- (RACSignal *) delete:(SCSpatialFeature *)feature {
  return [(GeoJSONAdapter *)adapter delete:feature];
}

#pragma mark -
#pragma mark SCDataStoreLifeCycle

- (RACSignal *)start {
  self.status = SC_DATASTORE_STARTED;
  [adapter connect];
  adapter.defaultStyle = self.style;
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
  return [NSString stringWithFormat:@"%@.%d", kTYPE, kVERSION];
}

@end
