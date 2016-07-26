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
#import "SCQueryFilter.h"
#import "SCService.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

extern NSString *const kSERVICENAME;

typedef NS_ENUM(NSUInteger, SCActionDataService) {
  SCACTION_DATASERVICE_ADDSTORE = 0,
  SCACTION_DATASERVICE_REMOVESTORE = 1,
  SCACTION_DATASERVICE_UPDATESTORE = 2,
  SCACTION_DATASERVICE_ADDFORM = 3,
  SCACTION_DATASERVICE_UPDATEFORM = 4,
  SCACTION_DATASERVICE_REMOVEFORM = 5
};

@interface SCDataService : SCService <SCServiceLifecycle> {
  RACSignal *addStore;
  RACSignal *updateStore;
  RACSignal *removeStore;
  NSMutableDictionary *defaultStoreForms;
}

@property(readonly, nonatomic) SCDefaultStore *defaultStore;

@property(readonly, nonatomic) SCServiceStatus status;
@property(nonatomic) RACMulticastConnection *storeEvents;

- (void)registerStore:(SCDataStore *)store;
- (void)unregisterStore:(SCDataStore *)store;
- (void)registerStoreByConfig:(SCStoreConfig *)c;
- (void)registerFormByConfig:(SCFormConfig *)f;
- (NSArray *)defaultStoreLayers;
- (NSDictionary *)defaultStoreForms;

- (SCDataStore *)storeByIdentifier:(NSString *)identifier;
- (Class)supportedStoreByKey:(NSString *)key;
- (NSArray *)storeList;
- (NSArray *)activeStoreList;
- (NSArray *)activeStoreListDictionary;
- (NSArray *)defaultStoreFormsDictionary;
- (NSDictionary *)storeByIdAsDictionary:(NSString *)storeId;
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
                   withFilter:(SCQueryFilter *)filter;
@end
