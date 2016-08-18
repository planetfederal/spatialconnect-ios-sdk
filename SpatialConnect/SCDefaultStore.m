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

#import "SCDefaultStore.h"
#import "SCPoint+GeoJSON.h"
#import "SpatialConnect.h"

@implementation SCDefaultStore

@synthesize storeType = _storeType;
@synthesize storeVersion = _storeVersion;

- (id)initWithStoreConfig:(SCStoreConfig *)config {
  self = [super initWithStoreConfig:config];
  if (self) {
    self.name = @"DEFAULT_STORE";
    self.permission = SC_DATASTORE_READWRITE;
    formIds = [NSMutableDictionary new];
    _storeType = @"default";
    _storeVersion = @"1";
    [self.adapter connectBlocking];
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
  return [super start];
}

- (void)stop {
  self.status = SC_DATASTORE_STOPPED;
}

- (void)resume {
}

- (void)pause {
}

- (void)addLayer:(NSString *)formKey
         withDef:(NSDictionary *)d
       andFormId:(NSInteger)formId {
  [formIds setObject:@(formId) forKey:formKey];
  [super addLayer:formKey withDef:d];
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

- (RACSignal *)create:(SCSpatialFeature *)feature {
  return [[[self.adapter createFeature:feature] materialize]
      filter:^BOOL(RACEvent *evt) {
        if (evt.eventType == RACEventTypeCompleted) {
          return YES;
        } else {
          return NO;
        }
      }];
}

- (RACSignal *)update:(SCSpatialFeature *)feature {
  return nil;
}

- (RACSignal *) delete:(SCKeyTuple *)tuple {
  return nil;
}

@end
