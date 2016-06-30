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

@synthesize type = _type;
@synthesize version = _version;

- (id)initWithStoreConfig:(SCStoreConfig *)config {
  self = [super initWithStoreConfig:config];
  if (self) {
    self.name = @"DEFAULT_STORE";
    self.permission = SC_DATASTORE_READWRITE;
    formIds = [NSMutableDictionary new];
    _type = @"default";
    _version = @"1";
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

- (void)addLayer:(NSString *)n
         withDef:(NSDictionary *)d
       andFormId:(NSInteger)formId {
  [formIds setObject:@(formId) forKey:n];
  [super addLayer:n withDef:d];
}

#pragma mark -
#pragma mark SCSpatialStore
- (RACSignal *)query:(SCQueryFilter *)filter {
  return nil;
}

- (RACSignal *)queryById:(SCKeyTuple *)key {
  return nil;
}

- (RACSignal *)create:(SCSpatialFeature *)feature {
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  return [[[[self.adapter createFeature:feature] materialize]
      filter:^BOOL(RACEvent *evt) {
        if (evt.eventType == RACEventTypeCompleted) {
          return YES;
        } else {
          return NO;
        }
      }] flattenMap:^RACStream *(id value) {
    NSInteger formid = [[formIds objectForKey:feature.layerId] integerValue];
        if (sc.configService.remoteUri) {
          NSString *urlStr = [NSString
                              stringWithFormat:@"%@/api/forms/%ld/submit", sc.configService.remoteUri,(long)formid];
          NSURL *url = [NSURL URLWithString:urlStr];
          NSString *uniqueId =  [[NSUserDefaults standardUserDefaults] stringForKey:@"UNIQUE_ID"];
          feature.layerId = self.storeId;
          feature.layerId = [NSString stringWithFormat:@"%@-%@",feature.layerId,uniqueId];
          return [sc.networkService postDictRequestAsDict:url body:feature.JSONDict];
        } else {
          return [RACSignal empty];
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
