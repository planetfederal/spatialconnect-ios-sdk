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
#import "SCConfigService.h"
#import "Actions.h"
#import "JSONKit.h"
#import "SCConfig.h"
#import "SCDataService.h"
#import "SCFileUtils.h"
#import "SCServerAuthMethod.h"
#import "SCNoAuthMethod.h"
#import "SCLayerConfig.h"
#import "SpatialConnect.h"

static NSString *const kSERVICENAME = @"SC_CONFIG_SERVICE";

@implementation SCConfigService

- (id)init {
  self = [super init];
  if (self) {
    configPaths = [NSMutableArray new];
  }
  return self;
}

- (BOOL)start:(NSDictionary<NSString *, id<SCServiceLifecycle>> *)deps {
  dataService = [deps objectForKey:[SCDataService serviceId]];
  BOOL success = [super start:nil];
  [self loadConfigs];
  return success;
}

- (BOOL)stop {
  [self clearConfigs];
  return [super stop];
}

- (NSArray *)requires {
  return @[ [SCDataService serviceId] ];
}

- (void)addConfigFilepath:(NSString *)fp {
  [configPaths addObject:fp];
}

- (void)addConfigFilepaths:(NSArray *)fps {
  [configPaths addObjectsFromArray:fps];
}

- (void)sweepDataDirectory {
  NSString *path = [NSSearchPathForDirectoriesInDomains(
      NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  NSArray *dirs =
      [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path
                                                          error:NULL];

  [dirs enumerateObjectsUsingBlock:^(NSString *filename, NSUInteger idx,
                                     BOOL *stop) {
    if ([filename.pathExtension.lowercaseString isEqualToString:@"scfg"]) {
      [configPaths
          addObject:[NSString stringWithFormat:@"%@/%@", path, filename]];
    }
  }];
}

- (void)loadConfigs {
  [configPaths enumerateObjectsUsingBlock:^(NSString *fp, NSUInteger idx,
                                            BOOL *_Nonnull stop) {
    NSError *error;
    NSMutableDictionary *cfg = [NSMutableDictionary
        dictionaryWithDictionary:[SCFileUtils jsonFileToDict:fp error:&error]];
    if (error) {
      DDLogError(@"%@", error.description);
    }
    if (cfg.count > 0) {
      SCConfig *s = [[SCConfig alloc] initWithDictionary:cfg];
      [self loadConfig:s];
    }
  }];
}

- (void)clearConfigs {
  if (configPaths.count > 0) {
    [configPaths removeAllObjects];
  }
}

- (void)loadConfig:(SCConfig *)c {
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  [c.layers enumerateObjectsUsingBlock:^(SCLayerConfig *lc, NSUInteger idx,
                                         BOOL *stop) {
    [dataService.formStore registerFormByConfig:lc];
  }];
  [c.stores enumerateObjectsUsingBlock:^(SCStoreConfig *scfg, NSUInteger idx,
                                         BOOL *stop) {
    [dataService registerAndStartStoreByConfig:scfg];
  }];
  if (c.remote) {
    if ([c.remote.auth isEqualToString:@"no-auth"]) {
      [sc connectAuth:[[SCNoAuthMethod alloc] init]];
    } else {
      [sc connectAuth:[[SCServerAuthMethod alloc] initWithDictionary:@{
                                                                       @"server_url" : c.remote.httpUri
                                                                       }]];
    }
    [sc connectBackend:c.remote];
  }
}

+ (NSString *)serviceId {
  return kSERVICENAME;
}

- (void)addForm:(SCLayerConfig *)c {
  [dataService.formStore registerFormByConfig:c];
}

- (void)removeForm:(SCLayerConfig *)c {
  [dataService.formStore unregisterFormByConfig:c];
}

- (void)addStore:(SCStoreConfig *)c {
  [dataService registerAndStartStoreByConfig:c];
}

- (void)removeStore:(SCStoreConfig *)c {
  [dataService unregisterStore:[dataService storeByIdentifier:c.uniqueid]];
}

- (void)setCachedConfig:(SCConfig *)cfg {
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  [sc.cache setValue:cfg.dictionary
              forKey:@"spatialconnect.config.remote.cached"];
}

- (SCConfig *)cachedConfig {
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  NSDictionary *d = (NSDictionary *)[sc.cache
      valueForKey:@"spatialconnect.config.remote.cached"];
  return [[SCConfig alloc] initWithDictionary:d];
}

@end
