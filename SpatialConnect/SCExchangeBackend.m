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
#import <Foundation/Foundation.h>

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

- (void)listenForSyncEvents {
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
    NSDictionary *fieldDict = @{
      @"field_key" : attribute[@"attribute"],
      @"field_label" : attribute[@"attribute"],
      @"type" : [self fieldType:attribute],
      @"position" : attribute[@"display_order"]
    };
    [fields addObject:fieldDict];
  }];
  [d setObject:fields forKey:@"fields"];

  return [[SCFormConfig alloc] initWithDict:d];
  ;
}

- (NSInteger)randomNumberBetween:(NSInteger)min maxNumber:(NSInteger)max {
  return min + arc4random_uniform((uint32_t)(max - min + 1));
}

- (NSString *)fieldType:(NSDictionary *)attribute {

  if ([attribute[@"attribute"] isEqualToString:@"photo"]) {
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
  } else {
    return @"string";
  }
}

@end
