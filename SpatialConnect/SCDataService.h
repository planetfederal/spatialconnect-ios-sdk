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

/**
 The stateful status of the Data Service
 */
@property(readonly, nonatomic) SCServiceStatus status;

/**
 RACSignal stream that sends events the stores emit
 */
@property(nonatomic) RACMulticastConnection *storeEvents;

/**
 BOOL value is emitted on this observable if there are stores
 loaded in the Data Service. The default value is NO and will
 emit YES when the first store gets loaded given the all clear
 to start querying for data. This will emit a status onSubscribe
 */
@property(readonly) RACBehaviorSubject *hasStores;

/**
 @description This is how you add an SCDataStore to be managed by the
 DataService. Stores can be registered automatically here through the use of
 configuration files. If the service is already running, it will start newly
 registered stores

 @brief Registers a store with the Data Service

 @param store store you want to be added to the data service
 @return BOOL for success
 */
- (BOOL)registerStore:(SCDataStore *)store;

/**
 @description Removes store from the data services

 @brief Removes store from the Data Service

 @param store to be removed
 */
- (void)unregisterStore:(SCDataStore *)store;

/**
 @brief Replaces the store with a new instance.

 @param store new store to replace the existing by id
 */
- (void)updateStore:(SCDataStore *)store;

/**
 @brief Replaces the store with a new instance using the config

 @param c Config used to instantiate a new store and replace the old by id
 */
- (BOOL)updateStoreByConfig:(SCStoreConfig *)c;

/**
 @description This is how you add an SCDataStore to be managed by the
 DataService. Stores can be registered automatically here through the use of
 configuration files. If the service is already running, it will start newly
 registered stores

 @brief Registers a store with the Data Service using a Store Config

 @param c store config you want to be added to the data service
 @return BOOL for success
 */
- (BOOL)registerStoreByConfig:(SCStoreConfig *)c;

/**
 @brief Registers a store with a config and then starts it

 @param cfg used to instantiate the store
 */
- (void)registerAndStartStoreByConfig:(SCStoreConfig *)cfg;

/**
 @discussion this is the store where all forms get persisted

 @return a reference to the form store
 */
- (SCFormStore *)formStore;

/**
 @discussion this is the store where all device locations get persisted

 @return a reference to the location store
 */
- (SCLocationStore *)locationStore;

/**
 Retrieves a store by the store instance's unique identifier

 @param identifier The store's unique id
 @return The reference to the store
 */
- (SCDataStore *)storeByIdentifier:(NSString *)identifier;

/**
 Retrieves an array of all the stores in the data service

 @return NSArray of the store references
 */
- (NSArray *)storeList;

/**
 Retrieves an array of all the stores in the data service as a dictionary

 @brief Gets an array of store dictionaries

 @return NSArray of the store references as an NSDictionary
 */
- (NSArray *)storeListDictionary;

/**
 Retrieves an array of all the stores in the data service that are currently
 running

 @brief Gets an array of running stores

 @return NSArray of running stores
 */
- (NSArray *)activeStoreList;

/**
 Retrieves an array of all the stores in the data service that are currently
 running as a dictionary

 @brief Gets an array of running stores as NSDictionary

 @return NSArray of running stores
 */
- (NSArray<NSDictionary *> *)activeStoreListDictionary;

/**
 Retrieves a dictionary representation of the store

 @param storeId The unique identifier of the store
 @return NSDictionary representing data about the store
 */
- (NSDictionary *)storeByIdAsDictionary:(NSString *)storeId;

/**
 Retrieves a dictionary representation of the store

 @param ds The store you want to retrieve a dictionary representation of
 @return NSDictionary representing data about the store
 */
- (NSDictionary *)storeAsDictionary:(SCDataStore *)ds;

/**
 Stores that implements a specific protocol

 @param protocol The protocol to filter for. (i.e. SCSpatialStore)
 @return Returns an NSArray of store references that implement the protocol
 */
- (NSArray<Protocol *> *)storesByProtocol:(Protocol *)protocol;

/**
 Stores that implements a specific protocol and are running

 @param protocol The protocol to filter for. (i.e. SCSpatialStore)
 @return Returns an NSArray of store references that implement the protocol and
 are running
 */
- (NSArray<Protocol *> *)storesByProtocol:(Protocol *)protocol
                              onlyRunning:(BOOL)running;

/**
 Stores that implement SCRasterStore

 @return Returns an NSArray of store references that implement the SCRasterStore
 */
- (NSArray *)storesRaster;

/**
 Returns an observable

 @param storeId The store's unique identifier
 @return RACSignal that emits when the specified store starts
 */
- (RACSignal *)storeStarted:(NSString *)storeId;

/**
 Calls the query method on all stores of a defined Protocol

 @discussion Default count is limited to 100. filter.limit = <int>
 @param protocol The Protocol the store must implement to be included in the
 query
 @param filter Filter object passed to limit the query
 @return A RACSignal of SCSpatialFeature
 */
- (RACSignal *)queryAllStoresOfProtocol:(Protocol *)protocol
                                 filter:(SCQueryFilter *)filter;

/**
 Sends an @selector to stores that implement a defined protocol

 @discussion Default count is limited to 100. filter.limit = <int>

 @param selector Objective-C message to send to the objects
 @param protocol The Protocol the store must implement to be included in the
 selector message call

 @param filter Filter object passed to the query.
 @return RACSignal returning SCSpatialFeatures
 */
- (RACSignal *)send:(SEL *)selector
         ofProtocol:(Protocol *)protocol
             filter:(SCQueryFilter *)filter;

/**
 Queries all active stores with the SCQueryFilter

 @discussion Default count is limited to 100. filter.limit = <int>

 @param filter Filter object passed to the query.
 @return RACSignal returning SCSpatialFeatures
 */
- (RACSignal *)queryAllStores:(SCQueryFilter *)filter;

/**
 Queries a single store with the SCQueryFilter

 @discussion Default count is limited to 100. filter.limit = <int>

 @param filter Filter object passed to the query.
 @return RACSignal returning SCSpatialFeatures
 */
- (RACSignal *)queryStoreById:(NSString *)storeId
                       filter:(SCQueryFilter *)filter;

/**
 Queries a list of stores by id with the SCQueryFilter

 @discussion Default count is limited to 100. filter.limit = <int>

 @param filter Filter object passed to the query.
 @return RACSignal returning SCSpatialFeatures
 */
- (RACSignal *)queryStoresByIds:(NSArray *)storeIds
                         filter:(SCQueryFilter *)filter;

/**
 Queries a list of stores by instance with the SCQueryFilter

 @discussion Default count is limited to 100. filter.limit = <int>

 @param filter Filter object passed to the query.
 @return RACSignal returning SCSpatialFeatures
 */
- (RACSignal *)queryStores:(NSArray *)stores filter:(SCQueryFilter *)filter;

@end
