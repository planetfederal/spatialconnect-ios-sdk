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

#import "SCRemoteConfig.h"
#import <Foundation/Foundation.h>

/*!
 *  @brief This is a mapping from the json config file to
 *  what the mobile architecture speak
 */
@interface SCConfig : NSObject {
  NSMutableArray *dataServiceStores;
  NSMutableArray *forms;
  SCRemoteConfig *r;
}

- (id)initWithDictionary:(NSDictionary *)d;
- (NSArray *)forms;
- (NSArray *)dataServiceStores;
- (SCRemoteConfig *)remote;

@end
