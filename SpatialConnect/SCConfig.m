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
    stores = [NSMutableArray new];
    NSArray *storeDicts = d[@"stores"];
    [storeDicts enumerateObjectsUsingBlock:^(NSDictionary *d, NSUInteger idx,
                                             BOOL *stop) {
      [stores addObject:[[SCStoreConfig alloc] initWithDictionary:d]];
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

- (NSDictionary *)dictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  NSArray *fs =
      [[forms.rac_sequence.signal map:^NSDictionary *(SCFormConfig *fc) {
        return fc.dictionary;
      }] toArray];
  if (fs) {
    dict[@"forms"] = fs;
  }
  NSArray *ss =
      [[stores.rac_sequence.signal map:^NSDictionary *(SCStoreConfig *sc) {
        return sc.dictionary;
      }] toArray];
  if (ss) {
    dict[@"stores"] = ss;
  }
  if (r) {
    dict[@"remote"] = r.dictionary;
  }
  return [NSDictionary dictionaryWithDictionary:dict];
}

- (NSArray *)forms {
  return [NSArray arrayWithArray:forms];
}

- (NSArray *)stores {
  return [NSArray arrayWithArray:stores];
}

- (SCRemoteConfig *)remote {
  return r;
}

- (void)addForm:(SCFormConfig *)fc {
  [forms addObject:fc];
}

- (void)updateForm:(SCFormConfig *)fc {
  [forms enumerateObjectsUsingBlock:^(SCFormConfig *c, NSUInteger idx,
                                      BOOL *stop) {
    if (c.identifier == fc.identifier) {
      [forms setObject:fc atIndexedSubscript:idx];
      *stop = YES;
    }
  }];
}

- (void)removeForm:(NSString *)key {
  [forms enumerateObjectsUsingBlock:^(SCFormConfig *c, NSUInteger idx,
                                      BOOL *stop) {
    if (c.key == key) {
      [forms removeObjectAtIndex:idx];
      *stop = YES;
    }
  }];
}

- (void)addStore:(SCStoreConfig *)sc {
  [stores addObject:sc];
}

- (void)updateStore:(SCStoreConfig *)sc {
  [stores enumerateObjectsUsingBlock:^(SCStoreConfig *c, NSUInteger idx,
                                       BOOL *_Nonnull stop) {
    if ([c.uniqueid isEqualToString:sc.uniqueid]) {
      [stores setObject:sc atIndexedSubscript:idx];
      *stop = YES;
    }
  }];
}

- (void)removeStore:(NSString *)uniqueid {
  [stores enumerateObjectsUsingBlock:^(SCStoreConfig *c, NSUInteger idx,
                                       BOOL *_Nonnull stop) {
    if ([c.uniqueid isEqualToString:uniqueid]) {
      [stores removeObjectAtIndex:idx];
      *stop = YES;
    }
  }];
}

@end
