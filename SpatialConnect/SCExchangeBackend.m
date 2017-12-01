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

static NSString *const LOCAL_FEATURE_ID_COL = @"_fid_";

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

- (RACSignal *)notifications {
  return nil;
}

- (void)updateDeviceToken:(NSString *)token {
}

- (RACBehaviorSubject *)isConnected {
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

  NSMutableArray *rw = res[@"rw"];
  [rw enumerateObjectsUsingBlock:^(NSString *l, NSUInteger idx, BOOL *stop) {
    [layerNames addObject:l];
  }];

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
  NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
  [d setObject:layerName forKey:@"form_key"];
  [d setObject:res[@"title"] forKey:@"form_label"];
  [d setObject:[NSNumber numberWithInteger:1] forKey:@"version"];
  [d setObject:[NSNumber numberWithInteger:[self randomNumberBetween:1
                                                           maxNumber:100000]]
         forKey:@"id"];

  NSMutableArray *fields = [NSMutableArray new];
  [attributes enumerateObjectsUsingBlock:^(NSDictionary *attribute,
                                           NSUInteger idx, BOOL *stop) {

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
    [fields addObject:fieldDict];
  }];

  // add id to indentify feature
  NSDictionary *fieldDict = @{
    @"field_key" : LOCAL_FEATURE_ID_COL,
    @"field_label" : LOCAL_FEATURE_ID_COL,
    @"field_visible" : [NSNumber numberWithBool:NO],
    @"type" : @"string"
  };
  [fields addObject:fieldDict];

  [d setObject:fields forKey:@"fields"];

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
  return [ss.unSent flattenMap:^RACSignal *(SCSpatialFeature *f) {
    return [self send:f];
  }];
}

- (RACSignal *)send:(SCSpatialFeature *)feature {

  return [[[self isConnected] take:1] flattenMap:^RACStream *(NSNumber *n) {
    if (n.boolValue) {

      NSURL *url = [NSURL
          URLWithString:[NSString stringWithFormat:@"%@/geoserver/wfs",
                                                   remoteConfig.httpUri]];
      NSString *wfsInsert = [self buildWFSTInsertPayload:feature];
      NSData *wfsInsertBody =
          [wfsInsert dataUsingEncoding:NSUTF8StringEncoding];
      NSString *authHeader =
          [NSString stringWithFormat:@"Bearer %@", [authService xAccessToken]];

      NSData *res = [SCHttpUtils postDataRequestBLOCKING:url
                                                    body:wfsInsertBody
                                                    auth:authHeader
                                             contentType:XML];

      WFSTParser *wfstParser = [[WFSTParser alloc] initWithData:res];

      NSString *responseString =
          [[NSString alloc] initWithData:res encoding:NSUTF8StringEncoding];
      // TODO: Need to re-work the way we get the unsent items from the audit
      // table to include the
      // audit operation, only save the featureId if its a create audit_op = 1
      SCDataStore *store = [dataService storeByIdentifier:[feature storeId]];
      id<SCSpatialStore> gkpgStore = (id<SCSpatialStore>)store;
      NSMutableDictionary *featureIdDict = [[NSMutableDictionary alloc] init];
      [featureIdDict setObject:wfstParser.featureId
                        forKey:LOCAL_FEATURE_ID_COL];

      feature.properties = featureIdDict;
      [[gkpgStore update:feature] subscribeError:^(NSError *error) {
        DDLogError(@"Error Updating featureId error %@",
                   error.localizedFailureReason);
      }
          completed:^{
            DDLogInfo(@"Updating featureId succesfully from exchange");
          }];

      id<SCSyncableStore> ss = (id<SCSyncableStore>)store;
      if (wfstParser.success) {
        return [ss updateAuditTable:feature];
      } else {
        return [RACSignal empty];
      }

    } else {
      return [RACSignal empty];
    }
  }];
}

- (NSString *)buildWFSTInsertPayload:(SCSpatialFeature *)feature {

  NSString *featureTypeUrl = [NSString
      stringWithFormat:@"%@/geoserver/wfs/DescribeFeatureType?typename=%@:%@",
                       remoteConfig.httpUri, @"geonode", feature.layerId];

  return [NSString stringWithFormat:wfstInsertTemplate, featureTypeUrl,
                                    feature.layerId,
                                    [self buildPropertiesXml:feature],
                                    [self buildGeometryXml:feature]];
}

- (NSString *)buildPropertiesXml:(SCSpatialFeature *)feature {
  NSMutableString *properties = [NSMutableString new];
  [feature.properties enumerateKeysAndObjectsUsingBlock:^(
                          NSString *key, NSObject *obj, BOOL *stop) {
    if (![obj isEqual:[NSNull null]]) {
      [properties appendString:[NSString stringWithFormat:@"<%1$@>%2$@</%1$@>",
                                                          key, obj]];
    }

  }];
  return properties;
}

- (NSString *)buildGeometryXml:(SCSpatialFeature *)feature {
  NSDictionary *geoJson = feature.JSONDict;
  NSDictionary *geometry = [geoJson objectForKey:@"geometry"];
  NSArray *coordinate = [geometry objectForKey:@"coordinates"];
  NSString *geometryXml;

  if (![geometry isEqual:[NSNull null]]) {
    // need to find geometry property instead of hard coding it
    NSString *geomColumn = @"wkb_geometry";
    geometryXml =
        [NSString stringWithFormat:wfstPointTemplate, geomColumn,
                                   [[coordinate objectAtIndex:0] doubleValue],
                                   [[coordinate objectAtIndex:1] doubleValue]];
  } else {
    geometryXml = @"";
  }

  return geometryXml;
}

static NSString *wfstInsertTemplate =
    @"<wfs:Transaction service=\"WFS\" version=\"1.0.0\"\n"
     "xmlns:wfs=\"http://www.opengis.net/wfs\"\n"
     "xmlns:gml=\"http://www.opengis.net/gml\"\n"
     "xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n"
     "xsi:schemaLocation=\"http://www.opengis.net/wfs "
     "http://schemas.opengis.net/wfs/1.0.0/WFS-transaction.xsd %1$@\">\n"
     "<wfs:Insert>\n"
     "<%2$@>\n"
     "%3$@"
     "%4$@"
     "</%2$@>\n"
     "</wfs:Insert>\n"
     "</wfs:Transaction>";

static NSString *wfstPointTemplate =
    @"<%1$@>\n"
     "<gml:Point srsName=\"http://www.opengis.net/gml/srs/epsg.xml#4326\">\n"
     "<gml:coordinates decimal=\".\" cs=\",\" ts=\" "
     "\">%2$f,%3$f</gml:coordinates>\n"
     "</gml:Point>\n"
     "</%1$@>\n";

static NSString *wfstDeleteTemplate = @"";

static NSString *wfstUpdateTemplate = @"";

@end
