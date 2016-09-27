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
#import "SCStoreConfig.h"

@implementation SCConfig

- (id)initWithDictionary:(NSDictionary *)d {
  self = [super init];
  if (self) {
    dataServiceStores = [NSMutableArray new];
    NSArray *storeDicts = d[@"stores"];
    [storeDicts enumerateObjectsUsingBlock:^(NSDictionary *d, NSUInteger idx,
                                             BOOL *stop) {
      [dataServiceStores
          addObject:[[SCStoreConfig alloc] initWithDictionary:d]];
    }];
    forms = [NSMutableArray new];
    NSArray *formDicts = d[@"forms"];
    [formDicts enumerateObjectsUsingBlock:^(NSDictionary *d, NSUInteger idx,
                                            BOOL *stop) {
      SCFormConfig *f = [[SCFormConfig alloc] initWithDict:d];
      if (f) {
        [forms addObject:f];
      }
    }];
    NSDictionary *rd = d[@"remote"];
    if (rd) {
      r = [[SCRemoteConfig alloc] initWithDict:rd];
    }
  }
  return self;
}

- (NSArray *)forms {
  return forms;
}

- (NSArray *)dataServiceStores {
  return dataServiceStores;
}

- (SCRemoteConfig *)remote {
  return r;
}

@end
