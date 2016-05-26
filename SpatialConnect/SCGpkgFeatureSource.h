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

#import "SCQueryFilter.h"
#import "SCSpatialFeature.h"
#import <Foundation/Foundation.h>
#import "FMDB.h"

typedef NS_ENUM(NSInteger, SCGpkgColType) {
  NULL_COL,
  INTEGER,
  REAL,
  TEXT,
  BLOB,
  GEOMETRY
};

@interface SCGpkgFeatureSource : NSObject

@property(strong, readonly) NSString *name;
@property(strong, readonly) FMDatabasePool *pool;
@property(strong, readonly) NSString *pkColName;
@property(strong, readonly) NSString *geomColName;
@property(strong, readonly) NSDictionary *colsTypes;

- (id)initWithPool:(FMDatabasePool *)p andName:(NSString *)n;
- (id)initWithPool:(FMDatabasePool *)p
            andName:(NSString *)n
          isIndexed:(BOOL)i;
- (RACSignal *)queryWithFilter:(SCQueryFilter *)f;
- (RACSignal *)findById:(NSString *)identifier;
- (RACSignal *)remove:(SCKeyTuple *)f;
- (RACSignal *)update:(SCSpatialFeature *)f;
- (RACSignal *)create:(SCSpatialFeature *)f;

@end
