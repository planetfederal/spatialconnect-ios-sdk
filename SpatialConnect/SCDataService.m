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

#import "SCDataService.h"
#import "GeoJSONStore.h"
#import "SCGeometry.h"
#import "SCSpatialStore.h"

@interface SCDataService (PrivateMethods)
- (void)startAllStores;
- (void)stopAllStores;
- (void)startStore:(SCDataStore *)store;
- (void)stopStore:(SCDataStore *)store;
@end

@implementation SCDataService

@synthesize storesStarted;

#define DATA_SERVICE @"DataService"

- (id)init {
  if (self = [super init]) {
    supportedStoreImpls = [[NSMutableDictionary alloc] init];
    [self addDefaultStoreImpls];
    stores = [[NSMutableDictionary alloc] init];
    self.storesStarted = NO;
  }
  return self;
}

- (void)addDefaultStoreImpls {
  [supportedStoreImpls setObject:[GeoJSONStore class]
                          forKey:[GeoJSONStore versionKey]];
}

- (void)startAllStores {
  [stores enumerateKeysAndObjectsUsingBlock:^(NSString *key, SCDataStore *store,
                                              BOOL *stop) {
    [self startStore:store];
  }];
}

- (void)stopAllStores {
  for (NSString *key in [stores allKeys]) {
    SCDataStore *store = [stores objectForKey:key];
    [self stopStore:store];
  }
}

- (void)startStore:(SCDataStore *)store {
  if ([store conformsToProtocol:@protocol(SCDataStoreLifeCycle)]) {
    [((id<SCDataStoreLifeCycle>)store)start];
  } else {
    NSLog(@"%@",
          [NSString stringWithFormat:@"Store %@ with key:%@ version:%ld id:%@ "
                                     @"was not started. Make sure the store "
                                     @"conforms to the SCDataStoreLifeCycle",
                                     store.name, store.key, (long)store.version,
                                     store.storeId]);
  }
}

- (void)stopStore:(SCDataStore *)store {
  if ([store conformsToProtocol:@protocol(SCDataStoreLifeCycle)]) {
    [((id<SCDataStoreLifeCycle>)store)stop];
  } else {
    NSLog(@"%@",
          [NSString stringWithFormat:@"Store %@ with key:%@ version:%ld id:%@ "
                                     @"was not started. Make sure the store "
                                     @"conforms to the SCDataStoreLifeCycle",
                                     store.name, store.key, (long)store.version,
                                     store.storeId]);
  }
}

- (void)start {
  [super start];
  [self startAllStores];
  self.storesStarted = YES;
}

- (void)stop {
  [super stop];
  [self stopAllStores];
  self.storesStarted = NO;
}

/**
 * Stores can be registered automatically here through the use of configuration
 * files. If the service is already running, it will start newly registered
 *stores.
 **/
- (void)registerStore:(SCDataStore *)store {
  if (!store.storeId) {
    NSCAssert(store.storeId, @"Store Id not set");
  } else {
    [stores setObject:store forKey:store.storeId];
    if (self.status == SC_SERVICE_RUNNING) {
      [self startStore:store];
    }
  }
}

- (void)unregisterStore:(SCDataStore *)store {
  if (store.status == SC_DATASTORE_RUNNING) {
    [self stopStore:store];
  }
  [stores removeObjectForKey:store.storeId];
}

- (Class)supportedStoreByKey:(NSString *)key {
  return (Class)[supportedStoreImpls objectForKey:key];
}

#pragma mark -
#pragma Store Accessor Methods

- (NSArray *)activeStoreList {
  return [[stores.allValues.rac_sequence filter:^BOOL(SCDataStore *value) {
    if (value.status == SC_DATASTORE_RUNNING) {
      return YES;
    }
    return NO;
  }] array];
}

- (NSArray *)activeStoreListDictionary {
  NSMutableArray *arr = [[NSMutableArray alloc] init];
  [[self activeStoreList]
      enumerateObjectsUsingBlock:^(SCDataStore *ds, NSUInteger idx,
                                   BOOL *stop) {
        NSMutableDictionary *store = [[NSMutableDictionary alloc] init];
        [store setObject:ds.storeId forKey:@"storeid"];
        [store setObject:ds.name forKey:@"name"];
        [store setObject:DATA_SERVICE forKey:@"service"];
        [arr addObject:store];
      }];
  return [NSArray arrayWithArray:arr];
}

- (NSDictionary *)storeByIdAsDictionary:(NSString *)storeId {
  SCDataStore *ds = [self storeByIdentifier:storeId];
  NSMutableDictionary *store = [[NSMutableDictionary alloc] init];
  [store setObject:ds.storeId forKey:@"storeid"];
  [store setObject:ds.name forKey:@"name"];
  [store setObject:DATA_SERVICE forKey:@"service"];
  return store;
}

- (NSArray *)storesByProtocol:(Protocol *)protocol onlyRunning:(BOOL)running {
  NSMutableArray *arr = [NSMutableArray new];
  [stores enumerateKeysAndObjectsUsingBlock:^(NSString *key, SCDataStore *ds,
                                              BOOL *stop) {
    BOOL conforms = [ds conformsToProtocol:protocol];
    SCDataStoreStatus d = ds.status;
    BOOL running = d == SC_DATASTORE_RUNNING;
    if (conforms && running) {
      [arr addObject:ds];
    }
  }];

  return [NSArray arrayWithArray:arr];
}

- (NSArray *)storesByProtocol:(Protocol *)protocol {
  return [self storesByProtocol:protocol onlyRunning:YES];
}

- (SCDataStore *)storeByIdentifier:(NSString *)identifier {
  return [stores objectForKey:identifier];
}

#pragma mark -
#pragma mark Store Query/Messaging Methods

- (RACSignal *)queryAllStoresOfProtocol:(Protocol *)protocol
                                 filter:(SCQueryFilter *)filter {
  return nil; // TODO
}

- (RACSignal *)send:(SEL *)selector
         ofProtocol:(Protocol *)protocol
             filter:(SCQueryFilter *)filter {
  return [[[[self storesByProtocol:protocol onlyRunning:YES] rac_sequence]
      flattenMap:^RACSignal *(id store) {
        if ([store respondsToSelector:@selector(query)]) {
          return [store query:filter];
        } else {
          return nil;
        }
      }] signal];
}

- (RACSignal *)queryAllStores:(SCQueryFilter *)filter {
  return [RACSignal createSignal:^RACDisposable *(
                                     id<RACSubscriber> subscriber) {
    [[[[[self storesByProtocol:@protocol(SCSpatialStore)] rac_sequence] signal]
        flattenMap:^RACStream *(id<SCSpatialStore> store) {
          return [store queryAllLayers:filter];
        }] subscribeNext:^(SCSpatialFeature *x) {
      NSLog(@"%@", x.identifier);
      [subscriber sendNext:x];
    } error:^(NSError *error) {
      [subscriber sendError:error];
    } completed:^{
      [subscriber sendCompleted];
    }];
    return nil;
  }];
}

- (RACSignal *)queryStoreById:(NSString *)storeId
                   withFilter:(SCQueryFilter *)filter {
  id<SCSpatialStore> store = (id<SCSpatialStore>)[stores objectForKey:storeId];
  return [store queryAllLayers:filter];
}

@end
