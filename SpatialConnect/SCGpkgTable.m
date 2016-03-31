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

#import "SCGpkgTable.h"

@interface SCGpkgTable ()
@property(strong, readwrite) FMDatabaseQueue *queue;
@end

@implementation SCGpkgTable

- (id)initWithQueue:(FMDatabaseQueue *)q tableName:(NSString *)t {
  self = [super init];
  if (self) {
    self.queue = q;
    tableName = t;
  }
  return self;
}

- (id)initWithQueue:(FMDatabaseQueue *)q {
  return nil;
}

- (RACSignal *)all {
  return [RACSignal empty];
}

- (NSString *)allQueryString {
  return [NSString stringWithFormat:@"SELECT * FROM %@", tableName];
}

@end
