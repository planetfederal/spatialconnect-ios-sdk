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
        return [[SCGpkgTileSource alloc] initWithPool:self.pool andContent:c];
      }] toArray];
}

- (NSArray *)featureContents {
  SCGpkgContentsTable *tc =
      [[SCGpkgContentsTable alloc] initWithPool:self.pool];
  return [[tc.vectors.rac_sequence.signal
      map:^SCGpkgFeatureSource *(SCGpkgContent *c) {
        return [[SCGpkgFeatureSource alloc] initWithPool:self.pool
                                                 content:c
                                               isIndexed:YES];
      }] toArray];
}

- (NSArray *)unSent {
  NSArray *fs = [[[[[self featureContents] rac_sequence] signal]
          flattenMap:^RACStream *(SCGpkgFeatureSource *fs) {
            return [fs unSent];
          }] toArray];
  return fs;
}

- (void)addFeatureSource:(NSString *)name withTypes:(NSDictionary *)types {
  [self.pool inDatabase:^(FMDatabase *db) {
    if ([db tableExists:name]) {
      FMResultSet *rs = [db getTableSchema:name];
      NSMutableArray *existingCols = [NSMutableArray new];
      while ([rs next]) {
        NSString *colName = [rs stringForColumn:@"name"];
        [existingCols addObject:colName];
      }
      [rs close];
      NSMutableDictionary *newSchemaCols =
          [NSMutableDictionary dictionaryWithDictionary:types];

      [existingCols enumerateObjectsUsingBlock:^(NSString *str, NSUInteger idx,
                                                 BOOL *stop) {
        [newSchemaCols removeObjectForKey:str];
      }];

      if ([newSchemaCols count] == 0) {
        return;
      }

      [db beginTransaction];
      NSMutableString *stmts = [NSMutableString new];
      [newSchemaCols enumerateKeysAndObjectsUsingBlock:^(
                         NSString *key, NSString *type, BOOL *stop) {
        NSString *sql =
            [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ %@;",
                                       name, key, type];
        [stmts appendString:sql];
      }];
      BOOL success = [db executeStatements:stmts];
      if (success) {
        [db commit];
      } else {
        [db rollback];
      }
      [db commit];
    } else {
      [db beginTransaction];
      NSMutableString *createSql = [NSMutableString
          stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id INTEGER "
                           @"PRIMARY KEY AUTOINCREMENT",
                           name];

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
        DDLogError(@"Error:%@", db.lastError.description);
        [db rollback];
        return;
      }
      NSString *addColSql =
          [NSString stringWithFormat:@"SELECT "
                                     @"AddGeometryColumn('%@','geom','"
                                     @"Geometry',4326)",
                                     name];
      BOOL geomAdded = [db executeStatements:addColSql];
      if (!geomAdded) {
        DDLogError(@"Error:%@", db.lastError.description);
        [db rollback];
        return;
      }
      NSString *addGpkgContentsSql =
          [NSString stringWithFormat:
                        @"INSERT INTO gpkg_contents "
                        @"(table_name,data_type,identifier,description,min_x,"
                        @"min_y,max_x,max_y,srs_id) VALUES "
                        @"('%@','features','%@','%@',0,0,0,0,4326)",
                        name, name, name];
      success = [db executeStatements:addGpkgContentsSql];
      if (!success) {
        DDLogError(@"Error:%@", db.lastError.description);
        [db rollback];
        return;
      }
      //add audit table
      NSString *auditTableName = [NSString stringWithFormat:@"%@_audit", name];
      NSMutableString *createAuditSql = [NSMutableString
                                    stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id INTEGER "
                                    @"PRIMARY KEY AUTOINCREMENT",
                                    auditTableName];
      
      NSMutableDictionary *auditTypes = [types mutableCopy];
      [auditTypes setObject:@"DATETIME" forKey:@"sent"];
      [auditTypes setObject:@"DATETIME" forKey:@"received"];
      
      [auditTypes enumerateKeysAndObjectsUsingBlock:^(NSString *k, NSString *t,
                                                      BOOL *stop) {
        NSString *key = [k lowercaseString];
        NSString *type = [t lowercaseString];
        if (![key isEqualToString:@"geom"]) {
          [createAuditSql appendFormat:@",%@ %@", key, type];
        }
      }];
      [createAuditSql appendString:@")"];
      success = [db executeStatements:createAuditSql];
      if (!success) {
        DDLogError(@"Error:%@", db.lastError.description);
        [db rollback];
        return;
      }
      NSString *addGeomSql =
      [NSString stringWithFormat:@"SELECT "
       @"AddGeometryColumn('%@','geom','"
       @"Geometry',4326)",
       auditTableName];
      success = [db executeStatements:addGeomSql];
      if (!success) {
        DDLogError(@"Error:%@", db.lastError.description);
        [db rollback];
        return;
      }
      NSString *triggerName = [NSString stringWithFormat:@"%@_insert", auditTableName];
      NSString *cols = [[auditTypes allKeys] componentsJoinedByString:@","];
      NSString *vals = [[[[[[auditTypes allKeys] rac_sequence] signal]
                          map:^NSString *(NSString *value) {
                            if ([value isEqualToString:@"sent"] ||
                                [value isEqualToString:@"received"]) {
                              return @"NULL";
                            }
                            return [NSString stringWithFormat:@"NEW.'%@'", value];
                          }] toArray] componentsJoinedByString:@","];
      
      NSMutableString *triggerSql = [NSMutableString stringWithFormat:
                                     @"CREATE TRIGGER %@ AFTER INSERT ON %@ BEGIN "
                                     @"INSERT INTO %@ (id, geom, %@) VALUES (NEW.id, NEW.geom, %@); END", triggerName, name, auditTableName, cols, vals];
      
      success = [db executeStatements:triggerSql];
      if (success) {
        [db commit];
      } else {
        [db rollback];
      }
    }
  }];
}


- (void)removeFeatureSource:(NSString *)name {
  [self.pool inDatabase:^(FMDatabase *db) {
    NSString *dropSql = [NSString stringWithFormat:@"DROP TABLE %@", name];
    BOOL success = [db executeStatements:dropSql];
    if (!success) {
      DDLogError(@"Error Dropping Table %@", name);
    }
  }];
}

- (RACSignal *)query:(SCQueryFilter *)filter {
  return [[[[self featureContents] rac_sequence] signal]
      flattenMap:^RACStream *(SCGpkgFeatureSource *fs) {
        return [fs queryWithFilter:filter];
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

- (SCGpkgTileSource *)tileSource:(NSString *)name {
  __block SCGpkgTileSource *tileSource = nil;
  [[self tileContents] enumerateObjectsUsingBlock:^(
                           SCGpkgTileSource *ts, NSUInteger idx, BOOL *stop) {
    if ([ts.name isEqualToString:name]) {
      tileSource = ts;
      *stop = YES;
    }
  }];
  return tileSource;
}

- (RACSignal *)kvpSource:(NSString *)name {
  return nil;
}

@end
