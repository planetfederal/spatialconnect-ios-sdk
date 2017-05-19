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

#import "SCLocationStore.h"
#import "GeopackageStore.h"
#import "JSONKit.h"
#import "SCPoint+GeoJSON.h"
#import "SpatialConnect.h"

@implementation SCLocationStore

@synthesize storeType = _storeType;
@synthesize storeVersion = _storeVersion;

- (id)initWithStoreConfig:(SCStoreConfig *)config {
  self = [super initWithStoreConfig:config];
  if (self) {
    self.name = config.name;
    self.permission = SC_DATASTORE_READWRITE;
    _storeType = @"gpkg";
    _storeVersion = @"1";
    [super connectBlocking];
  }
  return self;
}

- (id)initWithStoreConfig:(SCStoreConfig *)config withStyle:(SCStyle *)style {
  self = [self initWithStoreConfig:config];
  if (self) {
    self.style = style;
  }
  return self;
}

- (RACSignal *)start {
  NSDictionary *d = @{ @"accuracy" : @"TEXT", @"timestamp" : @"INTEGER" };
  [super addLayer:@"last_known_location" withDef:d];
  return [super start];
}

- (void)stop {
  self.status = SC_DATASTORE_STOPPED;
}

- (void)resume {
}

- (void)pause {
}

- (void)destroy {
  [super destroy];
}

#pragma mark -
#pragma mark SCSpatialStore
- (RACSignal *)query:(SCQueryFilter *)filter {
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendCompleted];
        return nil;
      }];
}

- (RACSignal *)queryById:(SCKeyTuple *)key {
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendCompleted];
        return nil;
      }];
}

- (RACSignal *)update:(SCSpatialFeature *)feature {
  return nil;
}

- (RACSignal *) delete:(SCKeyTuple *)tuple {
  return nil;
}

//only send the last unSent location record
- (RACSignal *)unSent {
  RACSignal *unSentFeatures = [[[[self.gpkg unSent] rac_sequence] signal] takeLast:1];
  return [unSentFeatures map:^SCSpatialFeature*(SCSpatialFeature *f) {
    f.storeId = self.storeId;
    return f;
  }];
}

- (NSString *)syncChannel {
  return @"/store/tracking";
}

@end
