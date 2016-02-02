/*****************************************************************************
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 ******************************************************************************/

#import "SCGeopackage.h"
#import "SCGpkgContentsTable.h"
#import "SCGpkgContent.h"
#import "SCGpkgExtensionsTable.h"
#import "SCGpkgTileSource.h"

@implementation SCGeopackage

@synthesize queue;

- (id)initWithFilename:(NSString *)filepath {
  self = [super init];
  if (self) {
    queue = [[FMDatabaseQueue alloc] initWithPath:filepath];
  }
  return self;
}

- (RACSignal *)contents {
  SCGpkgContentsTable *ct =
      [[SCGpkgContentsTable alloc] initWithQueue:self.queue];
  return [ct all];
}

- (RACSignal *)extensions {
  SCGpkgExtensionsTable *et =
      [[SCGpkgExtensionsTable alloc] initWithQueue:self.queue];
  return [et all];
}

- (NSArray *)tileContents {
  SCGpkgContentsTable *tc =
      [[SCGpkgContentsTable alloc] initWithQueue:self.queue];
  return [[tc.tiles.rac_sequence.signal map:^SCGpkgTileSource*(SCGpkgContent *c) {
    return [[SCGpkgTileSource alloc] init];
  }] toArray];
}

- (NSArray *)featureContents {
  SCGpkgContentsTable *tc =
      [[SCGpkgContentsTable alloc] initWithQueue:self.queue];
  return [[tc.vectors.rac_sequence.signal map:^SCGpkgFeatureSource*(SCGpkgContent *c) {
    return [[SCGpkgFeatureSource alloc] initWithQueue:self.queue andName:c.tableName isIndexed:YES];
  }] toArray];
}

- (SCGpkgFeatureSource *)featureSource:(NSString *)name {
  return [[SCGpkgFeatureSource alloc] initWithQueue:self.queue
                                            andName:name
                                          isIndexed:YES];
}

- (RACSignal*)query:(SCQueryFilter*)filter {
  return [[[[self featureContents] rac_sequence] signal] flattenMap:^RACStream *(SCGpkgFeatureSource *fs) {
    return [fs queryWithFilter:filter];
  }];
}

- (RACSignal *)tileSource:(NSString *)name {
  return nil;
}

- (RACSignal *)kvpSource:(NSString *)name {
  return nil;
}

@end
