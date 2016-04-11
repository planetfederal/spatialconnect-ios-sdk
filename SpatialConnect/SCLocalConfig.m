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
 * See the License for the specific language governing permissions and limitations under the License
 */

#import "SCLocalConfig.h"
#import "SCDataServiceStoreConfig.h"

@implementation SCLocalConfig

- (id)initWithDictionary:(NSDictionary *)d {
  self = [super init];
  if (self) {
    dataServiceStores = [NSMutableArray new];
    NSArray *storeDicts = d[@"stores"];
    [storeDicts enumerateObjectsUsingBlock:^(NSDictionary *d, NSUInteger idx, BOOL *stop) {
      [dataServiceStores addObject:[[SCDataServiceStoreConfig alloc] initWithDictionary:d]];
    }];
  }
  return self;
}

- (NSArray*)messages {
  NSMutableArray *ms = [NSMutableArray new];
  [dataServiceStores enumerateObjectsUsingBlock:^(SCDataServiceStoreConfig *cfg, NSUInteger idx, BOOL *stop) {
    [ms addObject:[cfg message]];
  }];
  return [NSArray arrayWithArray:ms];
}

@end
