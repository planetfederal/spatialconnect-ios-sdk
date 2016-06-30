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


#import "SCJavascriptBridgeAPI.h"
#import "SCFileUtils.h"
#import "SCGeoJSONExtensions.h"
#import "SCJavascriptBridge.h"
#import "SCJavascriptCommands.h"
#import "SCSpatialStore.h"
#import "SpatialConnect.h"

@implementation SCJavascriptBridgeAPI


- (RACSignal *)parseJSCommand:(id)data {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSDictionary *command = (NSDictionary *)data[@"data"];
        NSLog(@"%@", command);
        if (!command) {
            [subscriber sendCompleted];
            return nil;
        }
        NSInteger action = [command[@"action"] integerValue];
        switch (action) {
            case DATASERVICE_ACTIVESTORESLIST:
                [self activeStoreList:subscriber];
                break;
            case DATASERVICE_ACTIVESTOREBYID:
                [self activeStoreById:command[@"payload"] responseSubscriber:subscriber];
                break;
            case DATASERVICE_SPATIALQUERY:
                [self queryStoreById:command[@"payload"] responseSubscriber:subscriber];
                break;
            case DATASERVICE_SPATIALQUERYALL:
                [self queryAllStores:command[@"payload"] responseSubscriber:subscriber];
                break;
            case DATASERVICE_GEOSPATIALQUERY:
                [self queryGeoStoreById:command[@"payload"] responseSubscriber:subscriber];
                break;
            case DATASERVICE_GEOSPATIALQUERYALL:
                [self queryAllGeoStores:command[@"payload"] responseSubscriber:subscriber];
                break;
            case DATASERVICE_CREATEFEATURE:
                [self createFeature:command[@"payload"] responseSubscriber:subscriber];
                break;
            case DATASERVICE_UPDATEFEATURE:
                [self updateFeature:command[@"payload"] responseSubscriber:subscriber];
                break;
            case DATASERVICE_DELETEFEATURE:
                [self deleteFeature:command[@"payload"] responseSubscriber:subscriber];
                break;
            case DATASERVICE_FORMLIST:
                [self formList:subscriber];
                break;
            case SENSORSERVICE_GPS:
                [self spatialConnectGPS:command[@"payload"] responseSubscriber:subscriber];
                break;
            default:
                NSLog(@"break");
                break;
        }
        return nil;
    }];
}

- (void)activeStoreList:(id<RACSubscriber>)subscriber {
    NSArray *arr = [[[SpatialConnect sharedInstance] dataService] activeStoreListDictionary];
    [subscriber sendNext:@{ @"action": @"storesList", @"payload": @{@"stores":arr} }];
    [subscriber sendCompleted];
}

- (void)formList:(id<RACSubscriber>)subscriber {
    NSArray *arr = [[[SpatialConnect sharedInstance] dataService] defaultStoreForms];
    NSMutableArray *forms = [NSMutableArray array];
    for (id formConfig in arr) {
        [forms addObject:[formConfig JSONDict]];
    }
    [subscriber sendNext:@{ @"action": @"formsList", @"payload": @{@"forms":forms} }];
    [subscriber sendCompleted];
}

- (void)activeStoreById:(NSDictionary *)value responseSubscriber:(id<RACSubscriber>)subscriber {
    NSDictionary *dict = [[[SpatialConnect sharedInstance] dataService] storeByIdAsDictionary:value[@"storeId"]];
    [subscriber sendNext:@{ @"action": @"store", @"payload": @{@"store":dict} }];
    [subscriber sendCompleted];
}

- (void)queryAllStores:(NSDictionary *)value responseSubscriber:(id<RACSubscriber>)subscriber {
    SCQueryFilter *filter =
    [SCQueryFilter filterFromDictionary:value[@"filters"]];
    [[[[[[[[SpatialConnect sharedInstance] dataService] queryAllStores:filter] map:^NSDictionary*(SCSpatialFeature* value) {
        return [value JSONDict];
    }] toArray] rac_sequence] signal] subscribeNext:^(NSArray *arr) {
        [subscriber sendNext:@{ @"action": @"spatialQuery", @"payload": arr }];
        [subscriber sendCompleted];
    }];
}

- (void)queryStoreById:(NSDictionary *)value responseSubscriber:(id<RACSubscriber>)subscriber {
    [[[[SpatialConnect sharedInstance] dataService] queryStoreById:[value[@"storeId"] stringValue] withFilter:nil]
     subscribeNext:^(SCGeometry *g) {
         [subscriber sendNext:@{ @"action": @"spatialQuery", @"payload": [g JSONDict] }];
         [subscriber sendCompleted];
     }];
}

- (void)queryAllGeoStores:(NSDictionary *)value responseSubscriber:(id<RACSubscriber>)subscriber {
    SCQueryFilter *filter = [SCQueryFilter filterFromDictionary:value[@"filter"]];
    [[[[[SpatialConnect sharedInstance] dataService] queryAllStoresOfProtocol:@protocol(SCSpatialStore) filter:filter] map:^NSDictionary*(SCGeometry* value) {
        return [value JSONDict];
    }] subscribeNext:^(NSArray *arr) {;
        [subscriber sendNext:@{ @"action": @"spatialQuery", @"payload": arr }];
    }];
}

- (void)queryGeoStoreById:(NSDictionary *)value responseSubscriber:(id<RACSubscriber>)subscriber {
    SCQueryFilter *filter = [SCQueryFilter filterFromDictionary:value[@"filter"]];
    [[[[SpatialConnect sharedInstance] dataService] queryAllStoresOfProtocol:@protocol(SCSpatialStore)
      filter:filter] subscribeNext:^(SCGeometry *g) {
        [subscriber sendNext:@{ @"action": @"spatialQuery", @"payload": [g JSONDict] }];
        [subscriber sendCompleted];
    }];
}

- (void)spatialConnectGPS:(NSNumber *)value responseSubscriber:(id<RACSubscriber>)subscriber {
    BOOL enable = [value boolValue];
    if (enable) {
        [[[SpatialConnect sharedInstance] sensorService] enableGPS];
        [[[[SpatialConnect sharedInstance] sensorService] lastKnown] subscribeNext:^(CLLocation *loc) {
            CLLocationDistance alt = loc.altitude;
            float lat = loc.coordinate.latitude;
            float lon = loc.coordinate.longitude;
            [subscriber sendNext:@{ @"action": @"lastKnownLocation", @"payload": @{
                @"latitude": [NSNumber numberWithFloat:lat],
                @"longitude": [NSNumber numberWithFloat:lon],
                @"altitude": [NSNumber numberWithFloat:alt]
            }}];
        }];
    } else {
        [[[SpatialConnect sharedInstance] sensorService] disableGPS];
    }
}

- (void)createFeature:(NSDictionary *)value responseSubscriber:(id<RACSubscriber>)subscriber {
    NSDictionary *geoJsonDict = [value objectForKey:@"feature"];
    NSString *storeId = [geoJsonDict objectForKey:@"storeId"];
    NSString *layerId = [geoJsonDict objectForKey:@"layerId"];
    SCDataStore *store = [[[SpatialConnect sharedInstance] dataService] storeByIdentifier:storeId];
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
        } completed:^{
            [subscriber sendNext:@{ @"action": @"createFeature", @"payload": [feat JSONDict] }];
        }];
        
    } else {
        NSError *err = [NSError errorWithDomain:SCJavascriptBridgeErrorDomain code:-57 userInfo:nil];
        [subscriber sendError:err];
    }
}

- (void)updateFeature:(NSDictionary *)value responseSubscriber:(id<RACSubscriber>)subscriber {
    NSDictionary *geoJsonDict = [value objectForKey:@"feature"];
    NSString *featureId = [geoJsonDict objectForKey:@"id"];
    SCKeyTuple *key = [SCKeyTuple tupleFromEncodedCompositeKey:featureId];
    SCDataStore *store = [[[SpatialConnect sharedInstance] dataService] storeByIdentifier:key.storeId];
    if (store == nil) {
        store = [[[SpatialConnect sharedInstance] dataService] defaultStore];
    }
    if ([store conformsToProtocol:@protocol(SCSpatialStore)]) {
        id<SCSpatialStore> s = (id<SCSpatialStore>)store;
        SCSpatialFeature *feat = [SCGeoJSON parseDict:geoJsonDict];
        feat.layerId = key.layerId;
        [[s update:feat] subscribeError:^(NSError *error) {
            NSError *err = [NSError errorWithDomain:SCJavascriptBridgeErrorDomain  code:SCJSERROR_DATASERVICE_UPDATEFEATURE userInfo:nil];
            [subscriber sendError:err];
        } completed:^{
            [subscriber sendNext:@{ @"action": @"createFeature", @"payload": [feat JSONDict] }];
            [subscriber sendCompleted];
        }];
    } else {
        NSError *err = [NSError errorWithDomain:SCJavascriptBridgeErrorDomain code:SCJSERROR_DATASERVICE_UPDATEFEATURE userInfo:nil];
        [subscriber sendError:err];
    }
}

- (void)deleteFeature:(NSString *)value responseSubscriber:(id<RACSubscriber>)subscriber {
    SCKeyTuple *key = [SCKeyTuple tupleFromEncodedCompositeKey:value];
    SCDataStore *store = [[[SpatialConnect sharedInstance] dataService] storeByIdentifier:key.storeId];
    if (store == nil) {
        store = [[[SpatialConnect sharedInstance] dataService] defaultStore];
    }
    if ([store conformsToProtocol:@protocol(SCSpatialStore)]) {
        id<SCSpatialStore> s = (id<SCSpatialStore>)store;
        [[s delete:key] subscribeError:^(NSError *error) {
            NSError *err = [NSError errorWithDomain:SCJavascriptBridgeErrorDomain code:SCJSERROR_DATASERVICE_DELETEFEATURE userInfo:nil];
            [subscriber sendError:err];
        } completed:^{
            [subscriber sendCompleted];
        }];
    } else {
        NSError *err = [NSError errorWithDomain:SCJavascriptBridgeErrorDomain code:SCJSERROR_DATASERVICE_DELETEFEATURE userInfo:nil];
        [subscriber sendError:err];
    }
}

@end
