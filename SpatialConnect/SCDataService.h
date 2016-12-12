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
#import "SCDataStore.h"
#import "SCDefaultStore.h"
#import "SCFormConfig.h"
#import "SCFormStore.h"
#import "SCLocationStore.h"
#import "SCQueryFilter.h"
#import "SCService.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface SCDataService : SCService <SCServiceLifecycle> {
  RACSignal *addStore;
  RACSignal *updateStore;
  RACSignal *removeStore;
  SCFormStore *formStore;
  SCLocationStore *locationStore;
  SCDefaultStore *defaultStore;
}

@property(readonly, nonatomic) SCServiceStatus status;
@property(nonatomic) RACMulticastConnection *storeEvents;
@property(readonly) RACBehaviorSubject *hasStores;

- (BOOL)registerStore:(SCDataStore *)store;
- (void)unregisterStore:(SCDataStore *)store;
- (void)updateStore:(SCDataStore *)store;
- (BOOL)updateStoreByConfig:(SCStoreConfig *)c;
- (BOOL)registerStoreByConfig:(SCStoreConfig *)c;
- (void)registerAndStartStoreByConfig:(SCStoreConfig *)cfg;

- (SCDefaultStore *)defaultStore;
- (SCFormStore *)formStore;
- (SCLocationStore *)locationStore;

- (SCDataStore *)storeByIdentifier:(NSString *)identifier;
- (Class)supportedStoreByKey:(NSString *)key;
- (NSArray *)storeList;
- (NSArray *)storeListDictionary;
- (NSArray *)activeStoreList;
- (NSArray *)activeStoreListDictionary;
- (NSDictionary *)storeByIdAsDictionary:(NSString *)storeId;
- (NSDictionary *)storeAsDictionary:(SCDataStore *)ds;
- (NSArray *)storesByProtocol:(Protocol *)protocol;
- (NSArray *)storesByProtocol:(Protocol *)protocol onlyRunning:(BOOL)running;
- (NSArray *)storesRaster;
- (RACSignal *)storeStarted:(NSString *)storeId;

- (RACSignal *)queryAllStoresOfProtocol:(Protocol *)protocol
                                 filter:(SCQueryFilter *)filter;
- (RACSignal *)send:(SEL *)selector
         ofProtocol:(Protocol *)protocol
             filter:(SCQueryFilter *)filter;
- (RACSignal *)queryAllStores:(SCQueryFilter *)filter;
- (RACSignal *)queryStoreById:(NSString *)storeId
                       filter:(SCQueryFilter *)filter;
- (RACSignal *)queryStoresById:(NSArray *)storeIds
                        filter:(SCQueryFilter *)filter;

@end
