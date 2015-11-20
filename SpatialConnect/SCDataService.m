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
#import "GeopackageStore.h"
#import "SCGeometry.h"
#import "SCSpatialStore.h"
#import "SCStoreStatusEvent.h"
#import "SCServiceStatusEvent.h"

NSString *const kSERVICENAME = @"DATASERVICE";

@interface SCDataService ()
- (void)startAllStores;
- (void)stopAllStores;
- (void)startStore:(SCDataStore *)store;
- (void)stopStore:(SCDataStore *)store;
@property(readwrite, nonatomic) BOOL storesStarted;
@property(readwrite, nonatomic) SCServiceStatus status;
@property(readwrite, nonatomic, strong)
    NSMutableDictionary *supportedStoreImpls;
@property(readwrite, atomic, strong) NSMutableDictionary *stores;
@property(readwrite, nonatomic, strong) RACSubject *storeEventSubject;
@end

@implementation SCDataService

@synthesize storeEvents = _storeEvents;
@synthesize status;

- (id)init {
  if (self = [super init]) {
    self.supportedStoreImpls = [[NSMutableDictionary alloc] init];
    [self addDefaultStoreImpls];
    _stores = [[NSMutableDictionary alloc] init];
    self.name = kSERVICENAME;
    self.storesStarted = NO;
    self.storeEventSubject = [RACSubject new];
    self.storeEvents = [self.storeEventSubject publish];
  }
  return self;
}

- (void)addDefaultStoreImpls {
  [self.supportedStoreImpls setObject:[GeoJSONStore class]
                               forKey:[GeoJSONStore versionKey]];
  [self.supportedStoreImpls setObject:[GeopackageStore class]
                               forKey:[GeopackageStore versionKey]];
}

- (void)startAllStores {
  __block NSUInteger count = self.stores.count;
  __block NSUInteger startCount = 0;
  RACMulticastConnection *c = self.storeEvents;
  [c connect];
  [[c.signal filter:^BOOL(SCStoreStatusEvent *evt) {
    if (evt.status == SC_DATASTORE_RUNNING) {
      return YES;
    }
    return NO;
  }] subscribeNext:^(id x) {
    startCount++;
    if (startCount == count) {
      [self.storeEventSubject
          sendNext:[SCStoreStatusEvent fromEvent:SC_DATASTORE_ALLSTARTED
                                      andStoreId:nil]];
    }
  }];
  [self.stores
      enumerateKeysAndObjectsUsingBlock:^(NSString *key, SCDataStore *store,
                                          BOOL *stop) {
        [self startStore:store];
      }];
}

- (void)stopAllStores {
  [self.stores
      enumerateKeysAndObjectsUsingBlock:^(NSString *key, SCDataStore *store,
                                          BOOL *stop) {
        [self stopStore:store];
      }];
}

- (RACSignal *)allStoresStartedSignal {
  RACMulticastConnection *rmcc = self.storeEvents;
  [rmcc connect];
  return [[rmcc.signal filter:^BOOL(SCStoreStatusEvent *evt) {
    if (evt.status == SC_DATASTORE_ALLSTARTED) {
      return YES;
    }
    return NO;
  }] take:1];
}

- (void)startStore:(SCDataStore *)store {
  if ([store conformsToProtocol:@protocol(SCDataStoreLifeCycle)]) {
    [[((id<SCDataStoreLifeCycle>)store)start] subscribeError:^(NSError *error) {
      [self.storeEventSubject
          sendNext:[SCStoreStatusEvent fromEvent:SC_DATASTORE_STARTFAILED
                                      andStoreId:store.storeId]];
    } completed:^{
      [self.storeEventSubject
          sendNext:[SCStoreStatusEvent fromEvent:SC_DATASTORE_RUNNING
                                      andStoreId:store.storeId]];
    }];

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
    [self.storeEventSubject
        sendNext:[SCStoreStatusEvent fromEvent:SC_DATASTORE_STOPPED
                                    andStoreId:store.storeId]];
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
    [self.stores setObject:store forKey:store.storeId];
  }
}

- (void)unregisterStore:(SCDataStore *)store {
  if (store.status == SC_DATASTORE_RUNNING) {
    [self stopStore:store];
  }
  [self.stores removeObjectForKey:store.storeId];
}

- (Class)supportedStoreByKey:(NSString *)key {
  return (Class)[self.supportedStoreImpls objectForKey:key];
}

#pragma mark -
#pragma Store Accessor Methods

- (NSArray *)activeStoreList {
  return [[self.stores.allValues.rac_sequence filter:^BOOL(SCDataStore *value) {
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
        [store setObject:kSERVICENAME forKey:@"service"];
        [arr addObject:store];
      }];
  return [NSArray arrayWithArray:arr];
}

- (NSDictionary *)storeByIdAsDictionary:(NSString *)storeId {
  SCDataStore *ds = [self storeByIdentifier:storeId];
  NSMutableDictionary *store = [[NSMutableDictionary alloc] init];
  [store setObject:ds.storeId forKey:@"storeid"];
  [store setObject:ds.name forKey:@"name"];
  [store setObject:kSERVICENAME forKey:@"service"];
  return store;
}

- (NSArray *)storesByProtocol:(Protocol *)protocol onlyRunning:(BOOL)running {
  NSMutableArray *arr = [NSMutableArray new];
  [self.stores
      enumerateKeysAndObjectsUsingBlock:^(NSString *key, SCDataStore *ds,
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
  return [self.stores objectForKey:identifier];
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
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSArray *arr = [self storesByProtocol:@protocol(SCSpatialStore)];
        __block NSUInteger queryCompleted = 0;
        __block NSUInteger count = arr.count;
        [[[[arr rac_sequence] signal] flattenMap:^RACStream *(
                                                     id<SCSpatialStore> store) {
          return
              [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> qSub) {
                [[store query:filter] subscribeNext:^(id x) {
                  [qSub sendNext:x];
                } error:^(NSError *error) {
                  [qSub sendError:error];
                } completed:^{
                  queryCompleted++;
                  if (queryCompleted == count) {
                    [subscriber sendCompleted];
                  }
                }];
                return nil;
              }];
        }] subscribeNext:^(SCSpatialFeature *x) {
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
  id<SCSpatialStore> store =
      (id<SCSpatialStore>)[self.stores objectForKey:storeId];
  return [store query:filter];
}

@end
