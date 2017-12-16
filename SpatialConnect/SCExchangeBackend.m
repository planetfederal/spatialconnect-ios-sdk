/**
 * Copyright 2016 Boundless http://boundlessgeo.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License
 */

#import "SCExchangeBackend.h"
#import "SCConfig.h"
#import "SCHttpUtils.h"
#import "SpatialConnect.h"
#import "WFSTParser.h"
#import <Foundation/Foundation.h>

NSString *const LOCAL_FEATURE_ID_COL = @"_fid_";
NSInteger *const AUDIT_OP_CREATE = 1;
NSInteger *const AUDIT_OP_UPDATE = 2;
NSInteger *const AUDIT_OP_DELETE = 3;

@implementation SCExchangeBackend

- (id)initWithRemoteConfig:(SCRemoteConfig *)cfg {
  self = [super init];
  if (self) {
    remoteConfig = cfg;
    stores = [NSMutableArray new];
    forms = [NSMutableArray new];
  }
  return self;
}

- (BOOL)start:(NSDictionary<NSString *, id<SCServiceLifecycle>> *)svcs {
  sensorService = [svcs objectForKey:[SCSensorService serviceId]];
  authService = [svcs objectForKey:[SCAuthService serviceId]];
  configService = [svcs objectForKey:[SCConfigService serviceId]];
  dataService = [svcs objectForKey:[SCDataService serviceId]];

  // load the config from cache if any is present
  [self loadCachedConfig];

  // load config from backend
  [self loadConfig];

  // listen for sync events from data service
  [self listenForSyncEvents];

  return YES;
}

- (BOOL)stop {
  return YES;
}

- (NSString *)backendUri {
  return remoteConfig.httpUri;
}

- (RACSignal *)isConnected {
  return sensorService.isConnected;
}

- (void)loadConfig {

  [[authService loginStatus] subscribeNext:^(NSNumber *n) {
    SCAuthStatus s = [n integerValue];
    if (s == SCAUTH_AUTHENTICATED) {
      NSMutableArray *layers = [self fetchLayerNames];
      [layers enumerateObjectsUsingBlock:^(NSString *layer, NSUInteger idx,
                                           BOOL *stop) {
        SCFormConfig *formConfig = [self buildSCFormConfig:layer];
        [forms addObject:formConfig.dictionary];
      }];

      NSDictionary *cfgDict = @{
        @"stores" : stores,
        @"forms" : forms,
        @"remote" : remoteConfig.dictionary
      };

      SCConfig *cfg = [[SCConfig alloc] initWithDictionary:cfgDict];
      [configService setCachedConfig:cfg];
      [configService loadConfig:cfg];

      SpatialConnect *sc = [SpatialConnect sharedInstance];
      [sc.backendService.configReceived sendNext:@(YES)];
    }
  }];
}

- (void)loadCachedConfig {
  SCConfig *config = [configService cachedConfig];
  SpatialConnect *sc = [SpatialConnect sharedInstance];

  if (config) {
    [configService loadConfig:config];
    [sc.backendService.configReceived sendNext:@(YES)];
  }
}

- (NSMutableArray *)fetchLayerNames {
  NSMutableArray *layerNames = [NSMutableArray new];
  NSURL *url =
      [NSURL URLWithString:[NSString stringWithFormat:@"%@/gs/acls",
                                                      remoteConfig.httpUri]];

  NSString *authHeader =
      [NSString stringWithFormat:@"Bearer %@", [authService xAccessToken]];
  NSDictionary *res =
      [SCHttpUtils getRequestURLAsDictBLOCKING:url auth:authHeader];
  [layerNames addObjectsFromArray:res[@"rw"]];

  return layerNames;
}

- (SCFormConfig *)buildSCFormConfig:(NSString *)layerName {

  NSURL *url =
      [NSURL URLWithString:[NSString stringWithFormat:@"%@/layers/%@/get",
                                                      remoteConfig.httpUri,
                                                      layerName]];
  NSString *authHeader =
      [NSString stringWithFormat:@"Bearer %@", [authService xAccessToken]];

  NSDictionary *res =
      [SCHttpUtils getRequestURLAsDictBLOCKING:url auth:authHeader];

  NSMutableArray *attributes = res[@"attributes"];
  NSArray *fields = [[[[attributes rac_sequence] signal]
      map:^NSDictionary *(NSDictionary *attribute) {
        NSString *t = attribute[@"attribute_type"];
        BOOL *visible = [attribute[@"visible"] boolValue];
        if ([t containsString:@"gml"]) {
          visible = NO;
        }

        NSDictionary *fieldDict = @{
          @"field_key" : attribute[@"attribute"],
          @"field_label" : attribute[@"attribute"],
          @"field_visible" : [NSNumber numberWithBool:visible],
          @"type" : [self fieldType:attribute],
          @"position" : attribute[@"display_order"]
        };
        return fieldDict;
      }] toArray];

  // TODO: TBD at this moment on how to indentiy featuers
  //  NSDictionary *fieldDict = @{
  //    @"field_key" : LOCAL_FEATURE_ID_COL,
  //    @"field_label" : LOCAL_FEATURE_ID_COL,
  //    @"field_visible" : [NSNumber numberWithBool:NO],
  //    @"type" : @"string"
  //  };
  //  [fields addObject:fieldDict];

  NSDictionary *d = @{
    @"form_key" : layerName,
    @"form_label" : res[@"title"],
    @"version" : [NSNumber numberWithInteger:1],
    @"id" : [NSNumber
        numberWithInteger:[self randomNumberBetween:1 maxNumber:100000]],
    @"fields" : fields
  };

  return [[SCFormConfig alloc] initWithDict:d];
  ;
}

- (NSInteger)randomNumberBetween:(NSInteger)min maxNumber:(NSInteger)max {
  return min + arc4random_uniform((uint32_t)(max - min + 1));
}

- (NSString *)fieldType:(NSDictionary *)attribute {

  if ([attribute[@"attribute"] isEqualToString:@"photos"]) {
    return @"photo";
  }
  NSString *t = attribute[@"attribute_type"];
  if ([t isEqualToString:@"xsd:string"]) {
    return @"string";
  } else if ([t isEqualToString:@"xsd:int"] ||
             [t isEqualToString:@"xsd:float"] ||
             [t isEqualToString:@"xsd:double"]) {
    return @"number";
  } else if ([t isEqualToString:@"xsd:dateTime"] ||
             [t isEqualToString:@"xsd:date"]) {
    return @"date";
  } else if ([t containsString:@"gml"]) {
    return @"geometry";
  } else {
    return @"string";
  }
}

- (void)listenForSyncEvents {

  RACSignal *syncableStores =
      [dataService storesByProtocol:@protocol(SCSyncableStore) onlyRunning:YES];

  RACSignal *storeEditSync =
      [[syncableStores flattenMap:^RACSignal *(SCDataStore *ds) {
        id<SCSyncableStore> ss = (id<SCSyncableStore>)ds;
        RACMulticastConnection *rmcc = [ss storeEdited];
        [rmcc connect];
        return rmcc.signal;
      }] flattenMap:^RACSignal *(SCSpatialFeature *f) {
        SCDataStore *store = [dataService storeByIdentifier:[f storeId]];
        return [self syncStore:store];
      }];

  RACSignal *onlineSync = [[[self isConnected] filter:^BOOL(NSNumber *v) {
    return v.boolValue;
  }] flattenMap:^RACSignal *(id value) {
    return [self syncStores];
  }];

  RACSignal *sync = [RACSignal merge:@[ storeEditSync, onlineSync ]];

  [[sync subscribeOn:[RACScheduler
                         schedulerWithPriority:RACSchedulerPriorityBackground]]
      subscribeError:^(NSError *error) {
        DDLogError(@"Store syncing error %@", error.localizedFailureReason);
      }
      completed:^{
        DDLogInfo(@"Store syncing complete");
      }];
}

- (RACSignal *)syncStores {
  RACSignal *syncableStores =
      [dataService storesByProtocol:@protocol(SCSyncableStore) onlyRunning:YES];
  return [syncableStores flattenMap:^RACSignal *(id<SCSyncableStore> store) {
    return [self syncStore:store];
  }];
}

- (RACSignal *)syncStore:(SCDataStore *)ds {
  id<SCSyncableStore> ss = (id<SCSyncableStore>)ds;
  return [ss.unSent flattenMap:^RACSignal *(SyncItem *syncItem) {
    return [self send:syncItem];
  }];
}

- (RACSignal *)send:(SyncItem *)syncItem {
  return [[[self isConnected] take:1] flattenMap:^RACStream *(NSNumber *n) {
    if (n.boolValue) {
      NSURL *url = [NSURL
          URLWithString:[NSString stringWithFormat:@"%@/geoserver/wfs",
                                                   remoteConfig.httpUri]];
      NSString *authHeader =
          [NSString stringWithFormat:@"Bearer %@", [authService xAccessToken]];
      NSString *wfsPayload;
      if (syncItem.operation == AUDIT_OP_CREATE) {
        wfsPayload = [WFSTUtils buildWFSTInsertPayload:syncItem.feature
                                                   url:remoteConfig.httpUri];
      } else if (syncItem.operation == AUDIT_OP_UPDATE) {
        wfsPayload = [WFSTUtils buildWFSTUpdatePayload:syncItem.feature
                                                   url:remoteConfig.httpUri];
      } else if (syncItem.operation == AUDIT_OP_DELETE) {
        wfsPayload = [WFSTUtils buildWFSTDeletePayload:syncItem.feature
                                                   url:remoteConfig.httpUri];
      }

      NSData *wfsPayloadBody =
          [wfsPayload dataUsingEncoding:NSUTF8StringEncoding];
      NSData *res = [SCHttpUtils postDataRequestBLOCKING:url
                                                    body:wfsPayloadBody
                                                    auth:authHeader
                                             contentType:XML];

      WFSTParser *wfstParser = [[WFSTParser alloc] initWithData:res];
      NSString *responseString =
          [[NSString alloc] initWithData:res encoding:NSUTF8StringEncoding];

      SCDataStore *store =
          [dataService storeByIdentifier:[syncItem.feature storeId]];
      id<SCSpatialStore> gkpgStore = (id<SCSpatialStore>)store;
      NSMutableDictionary *featureIdDict = [[NSMutableDictionary alloc] init];
      [featureIdDict setObject:wfstParser.featureId
                        forKey:LOCAL_FEATURE_ID_COL];

      syncItem.feature.properties = featureIdDict;
      // TODO: updating the feature's unique ID from the WFST request is TBD at
      // this time
      //      [[gkpgStore update:syncItem.feature] subscribeError:^(NSError
      //      *error) {
      //        DDLogError(@"Error Updating featureId error %@",
      //                   error.localizedFailureReason);
      //      }
      //          completed:^{
      //            DDLogInfo(@"Updating featureId succesfully from exchange");
      //          }];

      id<SCSyncableStore> ss = (id<SCSyncableStore>)store;
      if (wfstParser.success) {
        return [ss updateAuditTable:syncItem.feature];
      } else {
        return [RACSignal empty];
      }

    } else {
      return [RACSignal empty];
    }
  }];
}
@end
