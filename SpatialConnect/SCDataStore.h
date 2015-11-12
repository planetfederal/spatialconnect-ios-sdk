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
#import "SCStyle.h"
#import "SCStoreConfig.h"
#import "SCQueryFilter.h"
#import "SCSpatialFeature.h"
#import "SCDataStoreLifeCycle.h"

typedef NS_ENUM(NSInteger, SCDataStoreStatus) {
  SC_DATASTORE_STARTED,
  SC_DATASTORE_RUNNING,
  SC_DATASTORE_PAUSED,
  SC_DATASTORE_STOPPED,
  SC_DATASTORE_STARTFAILED
};

@interface SCDataStore : NSObject

@property(readonly) NSString *storeId;
@property(readonly, nonatomic) NSArray *layerList;
@property(nonatomic) NSString *name;
@property(nonatomic, strong) SCStyle *style;
@property(readonly) NSInteger version;
@property(readonly) NSString *type;
@property(readonly) NSString *key;
@property(nonatomic) NSString *defaultLayerName;
@property SCDataStoreStatus status;

- (id)initWithStoreConfig:(SCStoreConfig *)config;
- (id)initWithStoreConfig:(SCStoreConfig *)config withStyle:(SCStyle *)style;

- (NSDictionary *)dictionary;
+ (NSString *)versionKey;

@end
