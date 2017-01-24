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

#import "SCFormConfig.h"
#import "SCRemoteConfig.h"
#import "SCStoreConfig.h"
#import <Foundation/Foundation.h>

/*!
 *  @brief This is a mapping from the json config file to
 *  what the mobile architecture speak
 */
@interface SCConfig : NSObject {
  NSMutableArray *stores;
  NSMutableArray *forms;
  SCRemoteConfig *r;
}

- (id)initWithDictionary:(NSDictionary *)d;
- (NSDictionary *)dictionary;
- (NSArray *)forms;
- (NSArray *)stores;
- (SCRemoteConfig *)remote;
- (void)addStore:(SCStoreConfig *)sc;
- (void)updateStore:(SCStoreConfig *)sc;
- (void)removeStore:(NSString *)uniqueid;
- (void)addForm:(SCFormConfig *)fc;
- (void)updateForm:(SCFormConfig *)fc;
- (void)removeForm:(NSString *)identifier;

@end
