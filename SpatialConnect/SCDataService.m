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
#import "SCConfigService.h"
#import "SCGeometry.h"
#import "SCServiceStatusEvent.h"
#import "SCSpatialStore.h"
#import "SCStoreStatusEvent.h"
#import "SpatialConnect.h"
#import "WFSDataStore.h"

NSString *const kDEFAULTSTORE = @"DEFAULT_STORE";
NSString *const kFORMSTORE = @"FORM_STORE";
NSString *const kLOCATIONSTORE = @"LOCATION_STORE";
static NSString *const kSERVICENAME = @"SC_DATA_SERVICE";

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
@property(readonly) RACSignal *timer;
@property(readwrite, nonatomic, strong) RACSubject *storeEventSubject;
@end

@implementation SCDataService

@synthesize storeEvents = _storeEvents;
@synthesize status;
@synthesize hasStores = _hasStores;

- (id)init {
  if (self = [super init]) {
    self.supportedStoreImpls = [[NSMutableDictionary alloc] init];
    [self addDefaultStoreImpls];
    _stores = [NSMutableDictionary new];
    _timer =
        [RACSignal interval:2 onScheduler:[RACScheduler mainThreadScheduler]];
    self.storesStarted = NO;
    self.storeEventSubject = [RACSubject new];
    self.storeEvents = [self.storeEventSubject publish];
    _hasStores = [RACBehaviorSubject behaviorSubjectWithDefaultValue:@(NO)];
    [self setupDefaultStore];
    [self setupFormsStore];
    [self setupLocationStore];
  }
  return self;
}

- (void)setupDefaultStore {
  SCStoreConfig *config = [[SCStoreConfig alloc] initWithDictionary:@{
    @"id" : @"DEFAULT_STORE",
    @"uri" : @"spacon_default_store.db",
    @"name" : @"DEFAULT_STORE"
  }];
  defaultStore = [[SCDefaultStore alloc] initWithStoreConfig:config];
  [_stores setObject:defaultStore forKey:config.uniqueid];
}

- (void)setupFormsStore {
  SCStoreConfig *config = [[SCStoreConfig alloc] initWithDictionary:@{
    @"id" : kFORMSTORE,
    @"uri" : @"spacon_form_store.db",
    @"name" : kFORMSTORE
  }];
  formStore = [[SCFormStore alloc] initWithStoreConfig:config];
  [_stores setObject:formStore forKey:config.uniqueid];
}

- (void)setupLocationStore {
  SCStoreConfig *config = [[SCStoreConfig alloc] initWithDictionary:@{
    @"id" : kLOCATIONSTORE,
    @"uri" : @"spacon_location_store.db",
    @"name" : kLOCATIONSTORE
  }];
  locationStore = [[SCLocationStore alloc] initWithStoreConfig:config];
  [_stores setObject:locationStore forKey:config.uniqueid];
}

- (SCDefaultStore *)defaultStore {
  return [_stores objectForKey:kDEFAULTSTORE];
}

- (SCFormStore *)formStore {
  return [_stores objectForKey:kFORMSTORE];
}

- (SCLocationStore *)locationStore {
  return [_stores objectForKey:kLOCATIONSTORE];
}

- (void)addDefaultStoreImpls {
  [self.supportedStoreImpls setObject:[GeoJSONStore class]
                               forKey:[GeoJSONStore versionKey]];
  [self.supportedStoreImpls setObject:[GeopackageStore class]
                               forKey:[GeopackageStore versionKey]];
  [self.supportedStoreImpls setObject:[WFSDataStore class]
                               forKey:[WFSDataStore versionKey]];
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
  if ([[self storeByIdentifier:storeId] status] == SC_DATASTORE_RUNNING) {
    SCStoreStatusEvent *evt =
        [[SCStoreStatusEvent alloc] initWithEvent:SC_DATASTORE_EVT_STARTED
                                       andStoreId:storeId];
    return [RACSignal return:evt];
  }
  RACMulticastConnection *rmcc = self.storeEvents;
  [rmcc connect];
  return [[rmcc.signal filter:^BOOL(SCStoreStatusEvent *evt) {
    if (evt.status == SC_DATASTORE_EVT_STARTED &&
        [evt.storeId isEqualToString:storeId]) {
      return YES;
    }
    return NO;
  }] take:1];
}

- (void)startStore:(SCDataStore *)store {
  if ([store conformsToProtocol:@protocol(SCDataStoreLifeCycle)]) {
    if (store.status == SC_DATASTORE_RUNNING) {
      return;
    }

    [[[((id<SCDataStoreLifeCycle>)store)start] sample:self.timer]
        subscribeNext:^(id x) {
          [self.storeEventSubject
              sendNext:[SCStoreStatusEvent
                            fromEvent:SC_DATASTORE_EVT_DOWNLOADPROGRESS
                           andStoreId:store.storeId]];
        }
        error:^(NSError *error) {
          [self.storeEventSubject
              sendNext:[SCStoreStatusEvent
                            fromEvent:SC_DATASTORE_EVT_STARTFAILED
                           andStoreId:store.storeId]];
        }
        completed:^{
          [_hasStores sendNext:@(YES)];
          [self.storeEventSubject
              sendNext:[SCStoreStatusEvent fromEvent:SC_DATASTORE_EVT_STARTED
                                          andStoreId:store.storeId]];
        }];

  } else {
    DDLogWarn(
        @"%@",
        [NSString stringWithFormat:@"Store %@ with key:%@ id:%@ "
                                   @"was not started. Make sure the store "
                                   @"conforms to the SCDataStoreLifeCycle",
                                   store.name, store.key, store.storeId]);
  }
}

- (void)stopStore:(SCDataStore *)store {
  if ([store conformsToProtocol:@protocol(SCDataStoreLifeCycle)]) {
    [((id<SCDataStoreLifeCycle>)store)stop];
    [_hasStores sendNext:@([[self stores] count] > 0)];
    [self.storeEventSubject
        sendNext:[SCStoreStatusEvent fromEvent:SC_DATASTORE_EVT_STOPPED
                                    andStoreId:store.storeId]];
  } else {
    DDLogWarn(
        @"%@",
        [NSString stringWithFormat:@"Store %@ with key:%@ id:%@ "
                                   @"was not stopped. Make sure the store "
                                   @"conforms to the SCDataStoreLifeCycle",
                                   store.name, store.key, store.storeId]);
  }
}

- (void)destroyStore:(SCDataStore *)store {
  if ([store conformsToProtocol:@protocol(SCDataStoreLifeCycle)]) {
    [((id<SCDataStoreLifeCycle>)store)destroy];
    [_hasStores sendNext:@([[self stores] count] > 0)];
    [self.storeEventSubject
        sendNext:[SCStoreStatusEvent fromEvent:SC_DATASTORE_EVT_REMOVED
                                    andStoreId:store.storeId]];
  } else {
    DDLogWarn(
        @"%@",
        [NSString stringWithFormat:@"Store %@ with key:%@ id:%@ "
                                   @"was not destroyed. Make sure the store "
                                   @"conforms to the SCDataStoreLifeCycle",
                                   store.name, store.key, store.storeId]);
  }
}

- (void)pauseRemoteStores {
  [self.stores enumerateKeysAndObjectsUsingBlock:^(
                   NSString *key, SCDataStore *ds, BOOL *stop) {
    id<SCDataStoreLifeCycle> sl = (id<SCDataStoreLifeCycle>)ds;
    if ([ds isKindOfClass:[SCRemoteDataStore class]] &&
        ds.status == SC_DATASTORE_RUNNING) {
      [sl pause];
      [self.storeEventSubject
          sendNext:[SCStoreStatusEvent fromEvent:SC_DATASTORE_EVT_PAUSED
                                      andStoreId:ds.storeId]];
    }
  }];
}

- (void)resumeRemoteStores {
  [self.stores enumerateKeysAndObjectsUsingBlock:^(
                   NSString *key, SCDataStore *ds, BOOL *stop) {
    id<SCDataStoreLifeCycle> sl = (id<SCDataStoreLifeCycle>)ds;
    if ([ds isKindOfClass:[SCRemoteDataStore class]] &&
        ds.status == SC_DATASTORE_PAUSED) {
      [sl resume];
      [self.storeEventSubject
          sendNext:[SCStoreStatusEvent fromEvent:SC_DATASTORE_EVT_RESUMED
                                      andStoreId:ds.storeId]];
    }
  }];
}

- (void)setupSubscriptions {
  [[[[SpatialConnect sharedInstance] sensorService] isConnected]
      subscribeNext:^(NSNumber *conn) {
        BOOL connected = conn.boolValue;
        if (connected) {
          [self resumeRemoteStores];
        } else {
          [self pauseRemoteStores];
        }
      }];
}

- (RACSignal *)start {
  [super start];
  [self startAllStores];
  [self setupSubscriptions];
  return [RACSignal empty];
}

- (void)stop {
  [super stop];
  [self stopAllStores];
  self.stores = [NSMutableDictionary new];
  self.storesStarted = NO;
  [_hasStores sendNext:@(NO)];
}

- (void)registerAndStartStoreByConfig:(SCStoreConfig *)cfg {
  if ([self registerStoreByConfig:cfg]) {
    id<SCDataStoreLifeCycle> store = [self.stores objectForKey:cfg.uniqueid];
    [self startStore:store];
  }
}

/**
 * Stores can be registered automatically here through the use of configuration
 * files. If the service is already running, it will start newly registered
 *stores.
 **/
- (BOOL)registerStore:(SCDataStore *)store {
  if (!store.storeId) {
    NSCAssert(store.storeId, @"Store Id not set");
    return NO;
  } else if ([self.stores objectForKey:store.storeId]) {
    DDLogWarn(@"STORE %@ ALREADY EXISTS", store.storeId);
    return NO;
  } else {
    [self.stores setObject:store forKey:store.storeId];
    return YES;
  }
}

- (BOOL)registerStoreByConfig:(SCStoreConfig *)c {
  NSCAssert(c.uniqueid, @"Store Id not set");
  Class store =
      [self supportedStoreByKey:[NSString stringWithFormat:@"%@.%@", c.type,
                                                           c.version]];
  SCDataStore *gmStore = [[store alloc] initWithStoreConfig:c];
  if (!store) {
    DDLogWarn(@"The store you tried to start:%@.%@ doesn't have a support "
              @"implementation.\n Here is a list of supported stores:\n%@",
              c.type, c.version, [self.supportedStoreImpls.allKeys
                                     componentsJoinedByString:@",\n"]);
    return NO;
  } else {
    return [self registerStore:gmStore];
  }
}

- (void)unregisterStore:(SCDataStore *)store {
  [self.stores removeObjectForKey:store.storeId];
  if (store.status == SC_DATASTORE_RUNNING) {
    [self stopStore:store];
    [self destroyStore:store];
  }
}

- (void)updateStore:(SCDataStore *)store {
  [self stopStore:store];
  [self.stores setObject:store forKey:store.storeId];
  [self startStore:store];
}

- (BOOL)updateStoreByConfig:(SCStoreConfig *)c {
  NSCAssert(c.uniqueid, @"Store Id not set");
  Class store =
      [self supportedStoreByKey:[NSString stringWithFormat:@"%@.%@", c.type,
                                                           c.version]];
  SCDataStore *gmStore = [[store alloc] initWithStoreConfig:c];
  if (!store) {
    DDLogWarn(@"The store you tried to start:%@.%@ doesn't have a support "
              @"implementation.\n Here is a list of supported stores:\n%@",
              c.type, c.version, [self.supportedStoreImpls.allKeys
                                     componentsJoinedByString:@",\n"]);
    return NO;
  } else if (![self.stores objectForKey:gmStore.storeId]) {
    DDLogWarn(@"STORE %@ DOES NOT EXIST", gmStore.storeId);
    return NO;
  } else {
    [self updateStore:gmStore];
    return YES;
  }
}

- (Class)supportedStoreByKey:(NSString *)key {
  return (Class)[self.supportedStoreImpls objectForKey:key];
}

#pragma mark -
#pragma Store Accessor Methods

- (NSArray *)storeList {
  return self.stores.allValues;
}

- (NSArray *)storeListDictionary {
  NSMutableArray *arr = [[NSMutableArray alloc] init];
  [[self storeList] enumerateObjectsUsingBlock:^(SCDataStore *ds,
                                                 NSUInteger idx, BOOL *stop) {
    [arr addObject:[self storeAsDictionary:ds]];
  }];
  return [NSArray arrayWithArray:arr];
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
    [arr addObject:[self storeAsDictionary:ds]];
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

- (NSDictionary *)storeAsDictionary:(SCDataStore *)ds {
  NSMutableDictionary *store = [[NSMutableDictionary alloc] init];
  [store setObject:ds.storeId forKey:@"storeId"];
  [store setObject:ds.name forKey:@"name"];
  [store setObject:kSERVICENAME forKey:@"service"];
  [store setObject:ds.storeType forKey:@"type"];
  [store setObject:[NSNumber numberWithInteger:ds.status] forKey:@"status"];
  [store setObject:ds.downloadProgress forKey:@"downloadProgress"];
  if ([ds conformsToProtocol:@protocol(SCSpatialStore)]) {
    id<SCSpatialStore> ss = (id<SCSpatialStore>)ds;
    if (ss.vectorLayers != nil) {
      [store setObject:ss.vectorLayers forKey:@"vectorLayers"];
    }
  }
  if ([ds conformsToProtocol:@protocol(SCRasterStore)]) {
    id<SCRasterStore> rs = (id<SCRasterStore>)ds;
    if (rs.rasterLayers != nil) {
      [store setObject:rs.rasterLayers forKey:@"rasterLayers"];
    }
  }
  return store;
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
  if (arr.count == 0) {
    return [RACSignal empty];
  }
  return [self queryStores:arr filter:filter];
}

- (RACSignal *)queryStores:(NSArray *)stores filter:(SCQueryFilter *)filter {
  return [[[stores rac_sequence] signal]
      flattenMap:^RACStream *(id<SCSpatialStore> store) {
        return [store query:filter];
      }];
}

- (RACSignal *)queryStoresByIds:(NSArray *)storeIds
                     withFilter:(SCQueryFilter *)filter {
  NSArray *stores = [self storesByProtocol:@protocol(SCSpatialStore)];
  NSArray *filtered =
      [[[[stores rac_sequence] signal] filter:^BOOL(SCDataStore *store) {
        return [storeIds containsObject:store.storeId];
      }] toArray];
  return [self queryStores:filtered filter:filter];
}

- (RACSignal *)queryStoreById:(NSString *)storeId
                   withFilter:(SCQueryFilter *)filter {
  id<SCSpatialStore> store =
      (id<SCSpatialStore>)[self.stores objectForKey:storeId];
  return [store query:filter];
}

+ (NSString *)serviceId {
  return kSERVICENAME;
}

@end
