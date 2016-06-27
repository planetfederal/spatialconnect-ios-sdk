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
#import "SCGpkgContent.h"
#import "SCGpkgContentsTable.h"
#import "SCGpkgExtensionsTable.h"
#import "SCGpkgTileSource.h"

@implementation SCGeopackage

@synthesize pool;

- (id)initWithFilename:(NSString *)filepath {
  self = [super init];
  if (self) {
    pool = [[FMDatabasePool alloc] initWithPath:filepath];
  }
  return self;
}

- (id)initEmptyGeopackageWithFilename:(NSString *)filepath {
  self = [super init];
  if (self) {
    pool = [[FMDatabasePool alloc] initWithPath:filepath];
    [pool inDatabase:^(FMDatabase *db) {
      BOOL b = [db executeStatements:@"SELECT InitSpatialMetaData()"];
      if (!b) {
        @throw [db lastError];
      }
    }];
  }
  return self;
}

- (void)close {
  if (pool) {
    [pool releaseAllDatabases];
  }
}

- (RACSignal *)contents {
  SCGpkgContentsTable *ct =
      [[SCGpkgContentsTable alloc] initWithPool:self.pool];
  return [ct all];
}

- (RACSignal *)extensions {
  SCGpkgExtensionsTable *et =
      [[SCGpkgExtensionsTable alloc] initWithPool:self.pool];
  return [et all];
}

- (NSArray *)tileContents {
  SCGpkgContentsTable *tc =
      [[SCGpkgContentsTable alloc] initWithPool:self.pool];
  return
      [[tc.tiles.rac_sequence.signal map:^SCGpkgTileSource *(SCGpkgContent *c) {
        return [[SCGpkgTileSource alloc] init];
      }] toArray];
}

- (NSArray *)featureContents {
  SCGpkgContentsTable *tc =
      [[SCGpkgContentsTable alloc] initWithPool:self.pool];
  return [[tc.vectors.rac_sequence.signal
      map:^SCGpkgFeatureSource *(SCGpkgContent *c) {
        return [[SCGpkgFeatureSource alloc] initWithPool:self.pool
                                                 andName:c.tableName
                                               isIndexed:YES];
      }] toArray];
}

- (void)addFeatureSource:(NSString *)name withTypes:(NSDictionary *)types {
  [self.pool inDatabase:^(FMDatabase *db) {
    NSString *formattedName = [[name lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    if ([db tableExists:formattedName]) {
      return;
    }
    [db beginTransaction];
    NSMutableString *createSql = [NSMutableString
        stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id INTEGER "
                         @"PRIMARY KEY AUTOINCREMENT",
                         formattedName];

    [types enumerateKeysAndObjectsUsingBlock:^(NSString *k, NSString *t,
                                               BOOL *stop) {
      NSString *key = [k lowercaseString];
      NSString *type = [t lowercaseString];
      if (![key isEqualToString:@"geom"]) {
        [createSql appendFormat:@",%@ %@", key, type];
      }
    }];
    [createSql appendString:@")"];
    BOOL success = [db executeStatements:createSql];
    if (!success) {
      NSLog(@"Error:%@", db.lastError.description);
      [db rollback];
      return;
    }
    NSString *addColSql =
        [NSString stringWithFormat:@"SELECT "
                                   @"AddGeometryColumn('%@','geom','"
                                   @"Geometry',4326)",
                                   formattedName];
    BOOL geomAdded = [db executeStatements:addColSql];
    if (!geomAdded) {
      NSLog(@"Error:%@", db.lastError.description);
      [db rollback];
      return;
    }
    NSString *addGpkgContentsSql = [NSString
        stringWithFormat:@"INSERT INTO gpkg_contents "
                         @"(table_name,data_type,identifier,description,min_x,"
                         @"min_y,max_x,max_y,srs_id) VALUES "
                         @"('%@','features','%@','%@',0,0,0,0,4326)",
                         formattedName, formattedName, name];
    success = [db executeStatements:addGpkgContentsSql];
    if (success) {
      [db commit];
    } else {
      [db rollback];
    }
  }];
}

- (void)removeFeatureSource:(NSString *)name {
  [self.pool inDatabase:^(FMDatabase *db) {
    NSString *dropSql = [NSString stringWithFormat:@"DROP TABLE %@", name];
    BOOL success = [db executeStatements:dropSql];
    if (!success) {
      NSLog(@"Error Dropping Table %@", name);
    }
  }];
}

- (SCGpkgFeatureSource *)featureSource:(NSString *)name {
  __block SCGpkgFeatureSource *featureSource = nil;
  [[self featureContents]
      enumerateObjectsUsingBlock:^(SCGpkgFeatureSource *fs, NSUInteger idx,
                                   BOOL *_Nonnull stop) {
        if ([fs.name isEqualToString:name]) {
          featureSource = fs;
          *stop = YES;
        }
      }];
  return featureSource;
}

- (RACSignal *)query:(SCQueryFilter *)filter {
  return [[[[self featureContents] rac_sequence] signal]
      flattenMap:^RACStream *(SCGpkgFeatureSource *fs) {
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
