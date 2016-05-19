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
#import "GeopackageStore.h"
#import "SCConfigService.h"
#import "SCDataService.h"
#import "SCGeometry.h"
#import "SCServiceStatusEvent.h"
#import "SCSpatialStore.h"
#import "SCStoreStatusEvent.h"
#import "SpatialConnect.h"

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
@property(readwrite, nonatomic, strong) SCDefaultStore *defaultStore;
@end

@implementation SCDataService

@synthesize storeEvents = _storeEvents;
@synthesize status;
@synthesize defaultStore = _defaultStore;

- (id)init {
  if (self = [super init]) {
    self.supportedStoreImpls = [[NSMutableDictionary alloc] init];
    [self addDefaultStoreImpls];
    _stores = [[NSMutableDictionary alloc] init];
    self.name = kSERVICENAME;
    self.storesStarted = NO;
    self.storeEventSubject = [RACSubject new];
    self.storeEvents = [self.storeEventSubject publish];
    [self setupDefaultStore];
  }
  return self;
}

- (void)setupDefaultStore {
  SCStoreConfig *config = [[SCStoreConfig alloc] init];
  config.uniqueid = @"DEFAULT_STORE";
  config.uri = @"spacon_default_store.db";
  config.name = @"DEFAULT_STORE";
  _defaultStore = [[SCDefaultStore alloc] initWithStoreConfig:config];
  [_stores setObject:_defaultStore forKey:config.uniqueid];
}

- (NSArray *)defaultStoreLayers {
  return [self.defaultStore layerList];
}

- (void)addDefaultStoreImpls {
  [self.supportedStoreImpls setObject:[GeoJSONStore class]
                               forKey:[GeoJSONStore versionKey]];
  [self.supportedStoreImpls setObject:[GeopackageStore class]
                               forKey:[GeopackageStore versionKey]];
}

- (void)startAllStores {
  [self.stores enumerateKeysAndObjectsUsingBlock:^(
                   NSString *key, SCDataStore *store, BOOL *stop) {
    [self startStore:store];
  }];
}

- (void)stopAllStores {
  [self.stores enumerateKeysAndObjectsUsingBlock:^(
                   NSString *key, SCDataStore *store, BOOL *stop) {
    [self stopStore:store];
  }];
}

- (RACSignal *)storeStarted:(NSString *)storeId {
  RACMulticastConnection *rmcc = self.storeEvents;
  [rmcc connect];
  return [[rmcc.signal filter:^BOOL(SCStoreStatusEvent *evt) {
    if (evt.status == SC_DATASTORE_EVT_STARTED && evt.storeId == storeId) {
      return YES;
    }
    return NO;
  }] take:1];
}

- (void)startStore:(SCDataStore *)store {
  if ([store conformsToProtocol:@protocol(SCDataStoreLifeCycle)]) {
    [[((id<SCDataStoreLifeCycle>)store)start] subscribeError:^(NSError *error) {
      [self.storeEventSubject
          sendNext:[SCStoreStatusEvent fromEvent:SC_DATASTORE_EVT_STARTFAILED
                                      andStoreId:store.storeId]];
    }
        completed:^{
          [self.storeEventSubject
              sendNext:[SCStoreStatusEvent fromEvent:SC_DATASTORE_EVT_STARTED
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
        sendNext:[SCStoreStatusEvent fromEvent:SC_DATASTORE_EVT_STOPPED
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
}

- (void)stop {
  [super stop];
  [self stopAllStores];
}

- (void)addAndStartStore:(SCStoreConfig *)cfg {
  Class store =
      [self supportedStoreByKey:[NSString stringWithFormat:@"%@.%ld", cfg.type,
                                                           (long)cfg.version]];
  SCDataStore *gmStore = [[store alloc] initWithStoreConfig:cfg];
  if (gmStore.key) {
    [self registerStore:gmStore];
  }
  [self startStore:gmStore];
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
    if (self.status == SC_DATASTORE_RUNNING) {
      [(id<SCDataStoreLifeCycle>)store start];
    }
  }
}

- (void)registerStoreByConfig:(SCStoreConfig *)c {
  NSCAssert(c.uniqueid, @"Store Id not set");
  [self addAndStartStore:c];
}

- (void)registerFormByConfig:(SCFormConfig *)f {
  [_defaultStore addLayer:f.name withDef:[f sqlTypes] andFormId:f.identifier];
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

- (NSArray *)storeList {
  return self.stores.allValues;
}

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
  [[self activeStoreList] enumerateObjectsUsingBlock:^(
                              SCDataStore *ds, NSUInteger idx, BOOL *stop) {
    NSMutableDictionary *store = [[NSMutableDictionary alloc] init];
    [store setObject:ds.storeId forKey:@"storeId"];
    [store setObject:ds.name forKey:@"name"];
    [store setObject:kSERVICENAME forKey:@"service"];
    [store setObject:ds.type forKey:@"type"];
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
  [self.stores enumerateKeysAndObjectsUsingBlock:^(
                   NSString *key, SCDataStore *ds, BOOL *stop) {
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

- (NSArray *)storesRaster {
  return [self storesByProtocol:@protocol(SCRasterStore)];
}

- (SCDataStore *)storeByIdentifier:(NSString *)identifier {
  return [self.stores objectForKey:identifier];
}

#pragma mark -
#pragma mark Store Query/Messaging Methods
- (RACSignal *)queryAllStoresOfProtocol:(Protocol *)protocol
                                 filter:(SCQueryFilter *)filter {
  return [self queryStores:[self storesByProtocol:protocol onlyRunning:YES]
                    filter:filter];
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
  NSArray *arr = [self storesByProtocol:@protocol(SCSpatialStore)];
  return [self queryStores:arr filter:filter];
}

- (RACSignal *)queryStores:(NSArray *)stores filter:(SCQueryFilter *)filter {
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        __block NSUInteger queryCompleted = 0;
        __block NSUInteger count = stores.count;
        [[[[stores rac_sequence] signal]
            flattenMap:^RACStream *(id<SCSpatialStore> store) {
              return [RACSignal
                  createSignal:^RACDisposable *(id<RACSubscriber> qSub) {
                    [[store query:filter] subscribeNext:^(SCSpatialFeature *x) {
                      [qSub sendNext:x];
                    }
                        error:^(NSError *error) {
                          [qSub sendError:error];
                        }
                        completed:^{
                          queryCompleted++;
                          if (queryCompleted == count) {
                            [subscriber sendCompleted];
                          }
                        }];
                    return nil;
                  }];
            }] subscribeNext:^(SCSpatialFeature *x) {
          [subscriber sendNext:x];
        }
            error:^(NSError *error) {
              [subscriber sendError:error];
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
