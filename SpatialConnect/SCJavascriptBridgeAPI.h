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

#import <Foundation/Foundation.h>

@interface SCJavascriptBridgeAPI : NSObject

- (RACSignal *)parseJSAction:(NSDictionary *)action;
- (void)activeStoreList:(id<RACSubscriber>)subscriber;
- (void)formList:(id<RACSubscriber>)subscriber;
- (void)activeStoreById:(NSDictionary *)value
     responseSubscriber:(id<RACSubscriber>)subscriber;
- (void)queryAllStores:(NSDictionary *)value
    responseSubscriber:(id<RACSubscriber>)subscriber;
- (void)queryStoresByIds:(NSDictionary *)value
      responseSubscriber:(id<RACSubscriber>)subscriber;
- (void)queryAllGeoStores:(NSDictionary *)value
       responseSubscriber:(id<RACSubscriber>)subscriber;
- (void)queryGeoStoresByIds:(NSDictionary *)value
         responseSubscriber:(id<RACSubscriber>)subscriber;
- (void)createFeature:(NSDictionary *)value
    responseSubscriber:(id<RACSubscriber>)subscriber;
- (void)updateFeature:(NSDictionary *)value
    responseSubscriber:(id<RACSubscriber>)subscriber;
- (void)deleteFeature:(NSDictionary *)value
    responseSubscriber:(id<RACSubscriber>)subscriber;
- (void)spatialConnectGPS:(id)value
       responseSubscriber:(id<RACSubscriber>)subscriber;
- (void)authenticate:(NSDictionary *)value
    responseSubscriber:(id<RACSubscriber>)subscriber;
- (void)logout:(id<RACSubscriber>)subscriber;
- (void)authXAccessToken:(id<RACSubscriber>)subscriber;
- (void)loginStatus:(id<RACSubscriber>)subscriber;
- (void)getRequest:(NSDictionary *)value
    responseSubscriber:(id<RACSubscriber>)subscriber;
- (void)postRequest:(NSDictionary *)value
    responseSubscriber:(id<RACSubscriber>)subscribe;

@end
