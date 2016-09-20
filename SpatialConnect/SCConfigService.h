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

#import "SCConfig.h"
#import "SCFormConfig.h"
#import "SCService.h"
#import "SCStoreConfig.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

typedef NS_ENUM(NSInteger, SCConfigEvent) {
  SC_CONFIG_SERVICE_ADDED,
  SC_CONFIG_SERVICE_REMOVED,
  SC_CONFIG_DATASERVICE_STORE_ADDED,
  SC_CONFIG_DATASERVICE_STORE_REMOVED
};

@interface SCConfigService : SCService {
  NSMutableArray *configPaths;
}

- (id)init;
- (void)addConfigFilepath:(NSString *)p;
- (void)loadConfig:(SCConfig *)c;
- (void)addStore:(SCStoreConfig *)c;
- (void)removeStore:(SCStoreConfig *)c;
- (void)addForm:(SCFormConfig *)c;
- (void)removeForm:(SCFormConfig *)c;

@end
