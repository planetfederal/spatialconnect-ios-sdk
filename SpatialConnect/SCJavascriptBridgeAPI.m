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

#import "Commands.h"
#import "SCFileUtils.h"
#import "SCGeoJSONExtensions.h"
#import "SCHttpUtils.h"
#import "SCHttpUtils.h"
#import "SCJavascriptBridge.h"
#import "SCJavascriptBridgeAPI.h"
#import "SCJavascriptCommands.h"
#import "SCNotification.h"
#import "SCSpatialStore.h"
#import "SpatialConnect.h"

@implementation SCJavascriptBridgeAPI

- (id)init {
  self = [super init];
  if (self) {
    [self setupBridge];
  }
  return self;
}

- (void)setupBridge {
}

- (RACSignal *)parseJSAction:(id)action {
  return [RACSignal createSignal:^RACDisposable *(
                        id<RACSubscriber> subscriber) {
    if (!action) {
      [subscriber sendCompleted];
      return nil;
    }
    NSInteger actionType = [action[@"type"] integerValue];
    switch (actionType) {
    case DATASERVICE_ACTIVESTORESLIST:
      [self activeStoreList:subscriber];
      break;
    case DATASERVICE_ACTIVESTOREBYID:
      [self activeStoreById:action[@"payload"] responseSubscriber:subscriber];
      break;
    case DATASERVICE_SPATIALQUERY:
      [self queryStoresByIds:action[@"payload"] responseSubscriber:subscriber];
      break;
    case DATASERVICE_SPATIALQUERYALL:
      [self queryAllStores:action[@"payload"] responseSubscriber:subscriber];
      break;
    case DATASERVICE_GEOSPATIALQUERY:
      [self queryGeoStoresByIds:action[@"payload"] responseSubscriber:subscriber];
      break;
    case DATASERVICE_GEOSPATIALQUERYALL:
      [self queryAllGeoStores:action[@"payload"] responseSubscriber:subscriber];
      break;
    case DATASERVICE_CREATEFEATURE:
      [self createFeature:action[@"payload"] responseSubscriber:subscriber];
      break;
    case DATASERVICE_UPDATEFEATURE:
      [self updateFeature:action[@"payload"] responseSubscriber:subscriber];
      break;
    case DATASERVICE_DELETEFEATURE:
      [self deleteFeature:action[@"payload"] responseSubscriber:subscriber];
      break;
    case DATASERVICE_FORMLIST:
      [self formList:subscriber];
      break;
    case SENSORSERVICE_GPS:
      [self spatialConnectGPS:action[@"payload"] responseSubscriber:subscriber];
      break;
    case AUTHSERVICE_AUTHENTICATE:
      [self authenticate:action[@"payload"] responseSubscriber:subscriber];
      break;
    case AUTHSERVICE_LOGOUT:
      [self logout:subscriber];
      break;
    case AUTHSERVICE_ACCESS_TOKEN:
      [self authXAccessToken:subscriber];
      break;
    case AUTHSERVICE_LOGIN_STATUS:
      [self loginStatus:subscriber];
      break;
    case NOTIFICATIONS:
      [self listenForNotifications:subscriber];
      break;
    case NETWORKSERVICE_GET_REQUEST:
      [self getRequest:action[@"payload"] responseSubscriber:subscriber];
      break;
    case NETWORKSERVICE_POST_REQUEST:
      [self postRequest:action[@"payload"] responseSubscriber:subscriber];
      break;
    default:
      NSLog(@"break");
      break;
    }
    return nil;
  }];
}

- (void)activeStoreList:(id<RACSubscriber>)subscriber {
  NSArray *arr =
      [[[SpatialConnect sharedInstance] dataService] activeStoreListDictionary];
  [subscriber sendNext:@{ @"stores" : arr }];
  [subscriber sendCompleted];
}

- (void)formList:(id<RACSubscriber>)subscriber {
  NSArray *arr = [[[[SpatialConnect sharedInstance] dataService] formStore]
      formsDictionary];
  [subscriber sendNext:@{ @"forms" : arr }];
  [subscriber sendCompleted];
}

- (void)activeStoreById:(NSDictionary *)value
     responseSubscriber:(id<RACSubscriber>)subscriber {
  NSDictionary *dict = [[[SpatialConnect sharedInstance] dataService]
      storeByIdAsDictionary:value[@"storeId"]];
  [subscriber sendNext:@{ @"store" : dict }];
  [subscriber sendCompleted];
}

- (void)queryAllStores:(NSDictionary *)value
    responseSubscriber:(id<RACSubscriber>)subscriber {
  SCQueryFilter *filter = [SCQueryFilter filterFromDictionary:value[@"filter"]];
  NSMutableArray *arr = [[NSMutableArray alloc] init];
  [[[[[SpatialConnect sharedInstance] dataService]
      queryAllStoresOfProtocol:@protocol(SCSpatialStore)
                        filter:filter]
      map:^NSDictionary *(SCSpatialFeature *value) {
        return [value JSONDict];
      }] subscribeNext:^(NSDictionary *d) {
        [arr addObject:d];
      } completed:^{
        [subscriber sendNext:arr];
        [subscriber sendCompleted];
      }];
}

- (void)queryStoresByIds:(NSDictionary *)value
        responseSubscriber:(id<RACSubscriber>)subscriber {
  SCQueryFilter *filter = [SCQueryFilter filterFromDictionary:value[@"filter"]];
  NSMutableArray *arr = [[NSMutableArray alloc] init];
  [[[[SpatialConnect sharedInstance] dataService]
    queryStoresByIds:value[@"storeId"]
    withFilter:filter] subscribeNext:^(SCGeometry *g) {
    [arr addObject:[g JSONDict]];
  } completed:^{
    [subscriber sendNext:arr];
    [subscriber sendCompleted];
  }];
}

- (void)queryAllGeoStores:(NSDictionary *)value
       responseSubscriber:(id<RACSubscriber>)subscriber {
  SCQueryFilter *filter = [SCQueryFilter filterFromDictionary:value[@"filter"]];
  NSMutableArray *arr = [[NSMutableArray alloc] init];
  [[[[[SpatialConnect sharedInstance] dataService] queryAllStores:filter]
      map:^NSDictionary *(SCSpatialFeature *value) {
        return [value JSONDict];
      }] subscribeNext:^(NSDictionary *d) {
        [arr addObject:d];
      } completed:^{
        [subscriber sendNext:arr];
        [subscriber sendCompleted];
   }];
}

- (void)queryGeoStoresByIds:(NSDictionary *)value
       responseSubscriber:(id<RACSubscriber>)subscriber {
  SCQueryFilter *filter = [SCQueryFilter filterFromDictionary:value[@"filter"]];
  NSMutableArray *arr = [[NSMutableArray alloc] init];
  [[[[SpatialConnect sharedInstance] dataService]
    queryStoresByIds:value[@"storeId"]
    withFilter:filter] subscribeNext:^(SCGeometry *g) {
    [arr addObject:[g JSONDict]];
  } completed:^{
    [subscriber sendNext:arr];
    [subscriber sendCompleted];
  }];
}

- (void)spatialConnectGPS:(NSNumber *)value
       responseSubscriber:(id<RACSubscriber>)subscriber {
  BOOL enable = [value boolValue];
  if (enable) {
    [[[SpatialConnect sharedInstance] sensorService] enableGPS];
    [[[[SpatialConnect sharedInstance] sensorService] lastKnown]
        subscribeNext:^(CLLocation *loc) {
          CLLocationDistance alt = loc.altitude;
          float lat = loc.coordinate.latitude;
          float lon = loc.coordinate.longitude;
          [subscriber sendNext:@{
            @"latitude" : [NSNumber numberWithFloat:lat],
            @"longitude" : [NSNumber numberWithFloat:lon],
            @"altitude" : [NSNumber numberWithFloat:alt]
          }];
        }];
  } else {
    [[[SpatialConnect sharedInstance] sensorService] disableGPS];
  }
}

- (void)createFeature:(NSDictionary *)value
   responseSubscriber:(id<RACSubscriber>)subscriber {
  NSDictionary *geoJsonDict = [value objectForKey:@"feature"];
  NSString *storeId = [geoJsonDict objectForKey:@"storeId"];
  NSString *layerId = [geoJsonDict objectForKey:@"layerId"];
  SCDataStore *store =
      [[[SpatialConnect sharedInstance] dataService] storeByIdentifier:storeId];
  if (store == nil) {
    store = [[[SpatialConnect sharedInstance] dataService] defaultStore];
  }
  if ([store conformsToProtocol:@protocol(SCSpatialStore)]) {
    id<SCSpatialStore> s = (id<SCSpatialStore>)store;
    NSError *err;
    if (err) {
      NSLog(@"%@", err.description);
    }
    SCSpatialFeature *feat = [SCGeoJSON parseDict:geoJsonDict];
    feat.layerId = layerId;
    [[s create:feat] subscribeError:^(NSError *error) {
      NSLog(@"Error creating Feature");
    }
        completed:^{
          [subscriber sendNext:[feat JSONDict]];
        }];

  } else {
    NSError *err = [NSError errorWithDomain:SCJavascriptBridgeErrorDomain
                                       code:-57
                                   userInfo:nil];
    [subscriber sendError:err];
  }
}

- (void)updateFeature:(NSDictionary *)value
   responseSubscriber:(id<RACSubscriber>)subscriber {
  NSDictionary *geoJsonDict = [value objectForKey:@"feature"];
  NSDictionary *metadata = [geoJsonDict objectForKey:@"metadata"];
  NSString *storeId = [metadata objectForKey:@"storeId"];
  NSString *layerId = [metadata objectForKey:@"layerId"];
  SCDataStore *store =
      [[[SpatialConnect sharedInstance] dataService] storeByIdentifier:storeId];
  if (store == nil) {
    store = [[[SpatialConnect sharedInstance] dataService] defaultStore];
  }
  if ([store conformsToProtocol:@protocol(SCSpatialStore)]) {
    id<SCSpatialStore> s = (id<SCSpatialStore>)store;
    SCSpatialFeature *feat = [SCGeoJSON parseDict:geoJsonDict];
    feat.layerId = layerId;
    [[s update:feat] subscribeError:^(NSError *error) {
      NSError *err =
          [NSError errorWithDomain:SCJavascriptBridgeErrorDomain
                              code:SCJSERROR_DATASERVICE_UPDATEFEATURE
                          userInfo:nil];
      [subscriber sendError:err];
    }
        completed:^{
          [subscriber sendNext:[feat JSONDict]];
          [subscriber sendCompleted];
        }];
  } else {
    NSError *err = [NSError errorWithDomain:SCJavascriptBridgeErrorDomain
                                       code:SCJSERROR_DATASERVICE_UPDATEFEATURE
                                   userInfo:nil];
    [subscriber sendError:err];
  }
}

- (void)deleteFeature:(NSString *)value
   responseSubscriber:(id<RACSubscriber>)subscriber {
  SCKeyTuple *key = [SCKeyTuple tupleFromEncodedCompositeKey:value];
  SCDataStore *store = [[[SpatialConnect sharedInstance] dataService]
      storeByIdentifier:key.storeId];
  if (store == nil) {
    store = [[[SpatialConnect sharedInstance] dataService] defaultStore];
  }
  if ([store conformsToProtocol:@protocol(SCSpatialStore)]) {
    id<SCSpatialStore> s = (id<SCSpatialStore>)store;
    [[s delete:key] subscribeError:^(NSError *error) {
      NSError *err =
          [NSError errorWithDomain:SCJavascriptBridgeErrorDomain
                              code:SCJSERROR_DATASERVICE_DELETEFEATURE
                          userInfo:nil];
      [subscriber sendError:err];
    }
        completed:^{
          [subscriber sendCompleted];
        }];
  } else {
    NSError *err = [NSError errorWithDomain:SCJavascriptBridgeErrorDomain
                                       code:SCJSERROR_DATASERVICE_DELETEFEATURE
                                   userInfo:nil];
    [subscriber sendError:err];
  }
}

- (void)authenticate:(NSDictionary *)value
  responseSubscriber:(id<RACSubscriber>)subscriber {
  SCAuthService *as = [[SpatialConnect sharedInstance] authService];
  NSString *email = value[@"email"];
  NSString *password = value[@"password"];
  [as authenticate:email password:password];
  [subscriber sendCompleted];
}

- (void)logout:(id<RACSubscriber>)subscriber {
  SCAuthService *as = [[SpatialConnect sharedInstance] authService];
  [as logout];
  [subscriber sendCompleted];
}

- (void)authXAccessToken:(id<RACSubscriber>)subscriber {
  SCAuthService *as = [[SpatialConnect sharedInstance] authService];
  NSString *s = [as xAccessToken];
  if (s) {
    [subscriber sendNext:s];
    [subscriber sendCompleted];
  }
  [subscriber sendCompleted];
}

- (void)loginStatus:(id<RACSubscriber>)subscriber {
  SCAuthService *as = [[SpatialConnect sharedInstance] authService];
  [[as loginStatus] subscribeNext:^(NSNumber *status) {
    [subscriber sendNext:status];
  }];
}

- (void)listenForNotifications:(id<RACSubscriber>)subscriber {
  SCBackendService *bs = [[SpatialConnect sharedInstance] backendService];
  [[bs notifications] subscribeNext:^(SCMessage *m) {
    [subscriber sendNext:m.payload];
  }];
}

- (void)getRequest:(NSDictionary *)value
responseSubscriber:(id<RACSubscriber>)subscriber {
  NSString *url = value[@"url"];
  [[SCHttpUtils getRequestURLAsDict:[NSURL URLWithString:url]]
      subscribeNext:^(NSDictionary *d) {
        [subscriber sendNext:d];
      }
      error:^(NSError *error) {
        [subscriber sendError:error];
      }
      completed:^{
        [subscriber sendCompleted];
      }];
}

- (void)postRequest:(NSDictionary *)value
 responseSubscriber:(id<RACSubscriber>)subscriber {
  NSString *url = value[@"url"];
  NSDictionary *body = value[@"body"];
  [[SCHttpUtils postDictRequestAsDict:[NSURL URLWithString:url] body:body]
      subscribeNext:^(NSDictionary *d) {
        [subscriber sendNext:d];
      }
      error:^(NSError *error) {
        [subscriber sendError:error];
      }
      completed:^{
        [subscriber sendCompleted];
      }];
}

@end
