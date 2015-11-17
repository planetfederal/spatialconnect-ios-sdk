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

#import "SCJavascriptBridge.h"
#import "WebViewJavascriptBridge.h"
#import "SpatialConnect.h"
#import "SCJavascriptCommands.h"
#import "SCGeoJSONExtensions.h"
#import "SCSpatialStore.h"

NSString *const SCJavascriptBridgeErrorDomain =
    @"SCJavascriptBridgeErrorDomain";

@interface SCJavascriptBridge ()
@property SpatialConnect *spatialConnect;
- (RACSignal *)parseJSCommand:(id)data;
- (void)setupBridge;
@end

@implementation SCJavascriptBridge

@synthesize webview;
/**
 * This initialization should be called from the UI's
 * viewDidLoad lifecycle. The _bridge will be bound to
 * the UI
 **/
- (id)initWithWebView:(UIWebView *)wv
             delegate:(id<UIWebViewDelegate>)del
                   sc:(SpatialConnect *)sc {
  if (self = [super init]) {
    commands = [NSMutableDictionary new];
    self.webview = wv;
    self.webViewDelegate = del;
    self.spatialConnect = sc;
    [self setupBridge];
  }
  return self;
}

#pragma mark -
#pragma mark Private Methods

- (void)setupBridge {
  self.bridge = [WebViewJavascriptBridge
      bridgeForWebView:self.webview
       webViewDelegate:self.webViewDelegate
               handler:^(id data, WVJBResponseCallback responseCallback) {
                 [[self parseJSCommand:data]
                     subscribeNext:^(NSDictionary *responseData) {
                       NSLog(@"Response");
                       NSLog(@"%@", responseData);
                       responseCallback(responseData);
                     }];
               }];

  [self.spatialConnect.manager.sensorService enableGPS];
  [self.spatialConnect.manager.sensorService.lastKnown
      subscribeNext:^(CLLocation *loc) {
        CLLocationDistance alt = loc.altitude;
        float lat = loc.coordinate.latitude;
        float lon = loc.coordinate.longitude;
        NSLog(@"%f", lat);
        [_bridge callHandler:@"lastKnownLocation"
                        data:@{
                          @"latitude" : [NSNumber numberWithFloat:lat],
                          @"longitude" : [NSNumber numberWithFloat:lon],
                          @"altitude" : [NSNumber numberWithFloat:alt]
                        }];
      }];
}

/**
 @param data A JSON Object containing the keys action and value
 @param responseCallback This is the second argument in the following
  Javascript: _bridge.send({action:'doFoo',value:dataObj},responseCallback);
 */
- (RACSignal *)parseJSCommand:(id)data {
  return [RACSignal createSignal:^RACDisposable *(
                                     id<RACSubscriber> subscriber) {
    NSDictionary *command = (NSDictionary *)data;
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
      [self activeStoreById:command[@"value"] responseSubscriber:subscriber];
      break;
    case DATASERVICE_SPATIALQUERY:
      [self queryStoreById:command[@"value"] responseSubcriber:subscriber];
      break;
    case DATASERVICE_SPATIALQUERYALL:
      [self queryAllStores:command[@"value"] responseSubscriber:subscriber];
      break;
    case DATASERVICE_GEOSPATIALQUERY:
      [self queryAllGeoStores:command[@"value"] responseSubscriber:subscriber];
      break;
    case DATASERVICE_GEOSPATIALQUERYALL:
      [self queryGeoStoreById:command[@"value"] responseSubscriber:subscriber];
      break;
    case DATASERVICE_CREATEFEATURE:
      [self createFeature:command[@"value"] responseSubscriber:subscriber];
      break;
    case DATASERVICE_UPDATEFEATURE:
      [self updateFeature:command[@"value"] responseSubscriber:subscriber];
      break;
    case DATASERVICE_DELETEFEATURE:
      [self deleteFeature:command[@"value"] responseSubscriber:subscriber];
      break;
    case SENSORSERVICE_GPS:
      [self spatialConnectGPS:command[@"value"]];
      [subscriber sendCompleted];
      break;
    default:
      break;
    }
    return nil;
  }];
}

- (void)activeStoreList:(id<RACSubscriber>)subscriber {
  NSArray *arr =
      [self.spatialConnect.manager.dataService activeStoreListDictionary];
  [subscriber sendCompleted];
  [self.bridge callHandler:@"storesList" data:@{ @"stores" : arr }];
}

- (void)activeStoreById:(NSDictionary *)value
     responseSubscriber:(id<RACSubscriber>)subscriber {
  NSDictionary *dict = [self.spatialConnect.manager.dataService
      storeByIdAsDictionary:value[@"storeId"]];
  [subscriber sendCompleted];
  [self.bridge callHandler:@"store" data:@{ @"store" : dict }];
}

- (void)queryAllStores:(NSDictionary *)value
    responseSubscriber:(id<RACSubscriber>)subscriber {
  SCQueryFilter *filter =
      [SCQueryFilter filterFromDictionary:value[@"filters"]];
  [[self.spatialConnect.manager.dataService queryAllStores:filter]
      subscribeNext:^(SCGeometry *g) {
        [self.bridge callHandler:@"spatialQuery" data:g.geoJSONDict];
        [subscriber sendCompleted];
      }];
}

- (void)queryStoreById:(NSDictionary *)value
     responseSubcriber:(id<RACSubscriber>)subscriber {
  [[self.spatialConnect.manager.dataService
      queryStoreById:[value[@"id"] stringValue]
          withFilter:nil] subscribeNext:^(SCGeometry *g) {
    NSDictionary *gj = g.geoJSONDict;
    [subscriber sendCompleted];
    [self.bridge callHandler:@"spatialQuery" data:gj];
  }];
}

- (void)queryAllGeoStores:(NSDictionary *)value
       responseSubscriber:(id<RACSubscriber>)subscriber {
  SCQueryFilter *filter = [SCQueryFilter filterFromDictionary:value];
  [[self.spatialConnect.manager.dataService
      queryAllStoresOfProtocol:@protocol(SCSpatialStore)
                        filter:filter] subscribeNext:^(SCGeometry *g) {
    NSDictionary *gj = g.geoJSONDict;
    [subscriber sendCompleted];
    [self.bridge callHandler:@"spatialQuery" data:gj];
  }];
}

- (void)queryGeoStoreById:(NSDictionary *)value
       responseSubscriber:(id<RACSubscriber>)subscriber {
  SCQueryFilter *filter = [SCQueryFilter filterFromDictionary:value];
  [[self.spatialConnect.manager.dataService
      queryAllStoresOfProtocol:@protocol(SCSpatialStore)
                        filter:filter] subscribeNext:^(SCGeometry *g) {
    NSDictionary *gj = g.geoJSONDict;
    [subscriber sendCompleted];
    [self.bridge callHandler:@"spatialQuery" data:gj];
  }];
}

- (void)spatialConnectGPS:(id)value {
  BOOL enable = [value boolValue];
  if (enable) {
    [self.spatialConnect.manager.sensorService enableGPS];
  } else {
    [self.spatialConnect.manager.sensorService disableGPS];
  }
}

- (void)createFeature:(NSDictionary *)value
   responseSubscriber:(id<RACSubscriber>)subscriber {
  SCDataStore *store = [self.spatialConnect.manager.dataService
      storeByIdentifier:[value[@"storeId"] stringValue]];
  if ([store conformsToProtocol:@protocol(SCSpatialStore)]) {
    id<SCSpatialStore> s = (id<SCSpatialStore>)store;
    SCSpatialFeature *feat = [SCGeoJSON parseDict:value];
    [s create:feat];
  } else {
    NSError *err = [NSError errorWithDomain:SCJavascriptBridgeErrorDomain
                                       code:-57
                                   userInfo:nil];
    [subscriber sendError:err];
  }
}

- (void)updateFeature:(NSDictionary *)value
   responseSubscriber:(id<RACSubscriber>)subscriber {
  SCDataStore *store = [self.spatialConnect.manager.dataService
      storeByIdentifier:[value[@"storeId"] stringValue]];
  if ([store conformsToProtocol:@protocol(SCSpatialStore)]) {
    id<SCSpatialStore> s = (id<SCSpatialStore>)store;
    SCSpatialFeature *feat = [SCGeoJSON parseDict:value];
    [s update:feat];
  } else {
    NSError *err = [NSError errorWithDomain:SCJavascriptBridgeErrorDomain
                                       code:SCJSERROR_DATASERVICE_UPDATEFEATURE
                                   userInfo:nil];
    [subscriber sendError:err];
  }
}

- (void)deleteFeature:(NSDictionary *)value
   responseSubscriber:(id<RACSubscriber>)subscriber {
  SCDataStore *store = [self.spatialConnect.manager.dataService
      storeByIdentifier:[value[@"storeId"] stringValue]];
  if ([store conformsToProtocol:@protocol(SCSpatialStore)]) {
    id<SCSpatialStore> s = (id<SCSpatialStore>)store;
    SCKeyTuple *key =
        [SCKeyTuple tupleFromEncodedCompositeKey:[value[@"id"] stringValue]];
    [s delete:key];
  } else {
    NSError *err = [NSError errorWithDomain:SCJavascriptBridgeErrorDomain
                                       code:SCJSERROR_DATASERVICE_DELETEFEATURE
                                   userInfo:nil];
    [subscriber sendError:err];
  }
}

@end
