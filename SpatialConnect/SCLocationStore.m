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
#import "Scmessage.pbobjc.h"
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

- (RACSignal *)create:(SCPoint *)pt {
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  pt.layerId = @"last_known_location";
  RACSignal *c = [super create:pt];
  if (!sc.backendService.backendUri) {
    return c;
  } else {
    return [[[c materialize] filter:^BOOL(RACEvent *evt) {
      if (evt.eventType == RACEventTypeCompleted) {
        return YES;
      } else {
        return NO;
      }
    }] flattenMap:^RACStream *(id value) {
      SCMessage *msg = [[SCMessage alloc] init];
      msg.payload = [[pt JSONDict] JSONString];
      [sc.backendService publish:msg onTopic:@"/store/tracking"];
      return [RACSignal empty];
    }];
  }
}

- (RACSignal *)update:(SCSpatialFeature *)feature {
  return nil;
}

- (RACSignal *) delete:(SCKeyTuple *)tuple {
  return nil;
}

@end
