/*!
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

/*!
 Add a new config to be loaded into SpatialConnect on Start

 @param p Full path to file
 */
- (void)addConfigFilepath:(NSString *)p;

/*!
 Load config in a running Config Service

 @param c Config object to be loaded
 */
- (void)loadConfig:(SCConfig *)c;

/*!
 Add store to SpatialConnect using a Store Config object

 @param c Instance of Store Config
 */
- (void)addStore:(SCStoreConfig *)c;

/*!
 Remove store from SpatialConnect using a config

 @param c Instance of Store Config
 */
- (void)removeStore:(SCStoreConfig *)c;

/*!
 Add form to SpatialConnect using a Form Config object

 @param c Instance of Form Config
 */
- (void)addForm:(SCFormConfig *)c;

/*!
 Remove form from SpatialConnect using a config

 @param c Instance of Form Config
 */
- (void)removeForm:(SCFormConfig *)c;

/*!
 This will overwrite the current cached config and will be used to configure the
 system if the Backend Service is unable to fetch a config from the server.

 @param c Instance of Config
 */
- (void)setCachedConfig:(SCConfig *)c;

/*!
 Retrieves the last cached config. This is used when the Backend Service is not
 able to fetch a config from the SpatialConnect server

 @return SCConfig
 */
- (SCConfig *)cachedConfig;
@end
