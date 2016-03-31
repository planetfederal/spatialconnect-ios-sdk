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

#import "SCBoundingBox.h"
#import "SCGeometry+GPKG.h"
#import "SCGpkgFeatureSource.h"
#import "SCPoint+GPKG.h"
#import <libgpkgios/sqlite3.h>
#import "SCGeoFilterContains.h"

@interface SCGpkgFeatureSource ()
@property(strong, readwrite) NSString *name;
@property(strong, readwrite) FMDatabaseQueue *queue;
@property(strong, readwrite) NSString *pkColName;
@property(strong, readwrite) NSDictionary *colsTypes;
@property(strong, readwrite) NSString *geomColName;

- (SCSpatialFeature *)featureFromResultSet:(FMResultSet *)rs; // Category
- (void)defineTable;
@end

@implementation SCGpkgFeatureSource

@synthesize name, pkColName, colsTypes;

- (id)initWithQueue:(FMDatabaseQueue *)q andName:(NSString *)n {
  self = [super init];
  if (self) {
    self.name = n;
    self.queue = q;
    [self defineTable];
  }
  return self;
}

- (id)initWithQueue:(FMDatabaseQueue *)q
            andName:(NSString *)n
          isIndexed:(BOOL)i {
  self = [self initWithQueue:q andName:n];
  if (self) {
    if (i) {
      [self indexTable];
    }
  }
  return self;
}

- (void)indexTable {
  [self.queue inDatabase:^(FMDatabase *db) {

    NSString *sql = [NSString stringWithFormat:@"SELECT CreateSpatialIndex('%@','%@','%@')",self.name,self.geomColName,self.pkColName];
    int res = [db executeStatements:sql];
    if (res != SQLITE_OK) {
      NSError *err = [db lastError];
      NSLog(@"%@",err.description);
    }
  }];
}

- (void)defineTable {

  [self.queue inDatabase:^(FMDatabase *db) {
    FMResultSet *rs = [db getTableSchema:self.name];
    NSMutableDictionary *cols = [NSMutableDictionary new];
    while ([rs next]) {
      NSString *colName = [rs stringForColumn:@"name"];
      if ([rs intForColumn:@"pk"]) {
        self.pkColName = [rs stringForColumn:@"name"];
      }
      NSString *t = [rs stringForColumn:@"type"];
      if ([t containsString:@"Geometry"]) {
        self.geomColName = [rs stringForColumn:@"name"];
        [cols setObject:@(GEOMETRY) forKey:colName];
      } else if ([t containsString:@"INTEGER"]) {
        [cols setObject:@(INTEGER) forKey:colName];
      } else if ([t containsString:@"REAL"]) {
        [cols setObject:@(REAL) forKey:colName];
      } else if ([t containsString:@"TEXT"]) {
        [cols setObject:@(TEXT) forKey:colName];
      } else if ([t containsString:@"BLOB"]) {
        [cols setObject:@(BLOB) forKey:colName];
      } else {
        [cols setObject:@(NULL_COL) forKey:colName];
      }
    }
    self.colsTypes = [NSDictionary dictionaryWithDictionary:cols];
    [rs close];
  }];
}

- (RACSignal *)queryWithFilter:(SCQueryFilter *)f {
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSMutableString *sql =
        [NSMutableString stringWithFormat:@"SELECT "];
        [sql appendString:[NSString stringWithFormat:@"%@,",self.pkColName]];
        [sql appendString:[[self.colsTypes allKeys] componentsJoinedByString:@","]];
        [sql appendString:[NSString stringWithFormat:@",%@",self.geomColName]];
        [sql appendString:[NSString stringWithFormat:@" FROM %@", name]];
        if (f) {
          [sql appendString:@" WHERE "];
          NSString *q = [f buildWhereClause];
          [sql appendString:q];

          [[f geometryFilters] enumerateObjectsUsingBlock:^(SCPredicate *p, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([p.filter isKindOfClass:[SCGeoFilterContains class]]) {
              NSMutableString *bbox = [NSMutableString new];
              SCGeoFilterContains *fc = (SCGeoFilterContains*)p.filter;
              SCBoundingBox *b = fc.bbox;
              [bbox appendString:
               [NSString stringWithFormat:@"SELECT %@ FROM rtree_%@_%@ WHERE ",
                self.pkColName,self.name,self.geomColName]];
              [bbox appendString:[NSString stringWithFormat:@" minx > %f",b.lowerLeft.x]];
              [bbox appendString:@" AND "];
              [bbox appendString:[NSString stringWithFormat:@" maxx < %f",b.upperRight.x]];
              [bbox appendString:@" AND "];
              [bbox appendString:[NSString stringWithFormat:@" miny > %f",b.lowerLeft.y]];
              [bbox appendString:@" AND "];
              [bbox appendString:[NSString stringWithFormat:@" maxy < %f",b.upperRight.y]];

              [sql appendString:[NSString stringWithFormat:@" %@ IN (%@) ",self.pkColName,bbox]];
            }
          }];

        }
        [sql appendString:[NSString stringWithFormat:@" LIMIT %ld",f.limit == 0? 100 : (long)f.limit]];
        [self query:sql toSubscriber:subscriber];
        return nil;
      }];
}

- (void)query:(NSString *)sql toSubscriber:(id<RACSubscriber>)subscriber {
  [self.queue inDatabase:^(FMDatabase *db) {
    FMResultSet *rs = [db executeQuery:sql];
    while ([rs next]) {
      SCSpatialFeature *f = [self featureFromResultSet:rs];
      [subscriber sendNext:f];
    }
    [rs close];
    dispatch_async(
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          [subscriber sendCompleted];
        });
  }];
}

- (RACSignal *)findById:(NSString *)identifier {
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSString *sql =
            [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?",
                                       self.name, self.pkColName];
        [self.queue inDatabase:^(FMDatabase *db) {
          NSError *err;

          FMResultSet *rs = [db executeQuery:sql
                                      values:@[ @([identifier longLongValue]) ]
                                       error:&err];
          if (err) {
            NSLog(@"%@", err.description);
          }
          
          dispatch_async(
              dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                if ([rs next]) {
                  SCSpatialFeature *sf = [self featureFromResultSet:rs];
                  [subscriber sendNext:sf];
                }
                [rs close];
                [subscriber sendCompleted];
              });
        }];
        return nil;
      }];
}

- (RACSignal *)remove:(SCKeyTuple *)f {

  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSString *sql = [NSString
            stringWithFormat:@"DELETE FROM %@ WHERE %@ = %lld", self.name,
                             self.pkColName, [f.featureId longLongValue]];
        [self.queue inDatabase:^(FMDatabase *db) {
          BOOL success = [db executeStatements:sql];
          if (success) {
            dispatch_async(
                dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                ^{
                  [subscriber sendCompleted];
                });
          } else {
            [subscriber sendError:db.lastError];
          }
        }];
        return nil;
      }];
}

- (RACSignal *)update:(SCSpatialFeature *)f {
  return [RACSignal createSignal:^RACDisposable *(
                        id<RACSubscriber> subscriber) {
    NSMutableString *sql = [NSMutableString new];
    [sql appendString:[NSString stringWithFormat:@"UPDATE %@ SET ", self.name]];
    NSMutableArray *vals = [NSMutableArray new];
    if ([f isKindOfClass:[SCGeometry class]]) {
      SCGeometry *g = (SCGeometry *)f;
      [sql appendString:[NSString stringWithFormat:@"%@ = ?", self.geomColName]];
      [vals addObject:g.bytes];
    }
    __block NSMutableString *set = nil;
    __block int count = 0;
    [f.properties enumerateKeysAndObjectsUsingBlock:^(
                      NSString *key, NSObject *obj, BOOL *stop) {
      if (![obj isKindOfClass:[NSNull class]]) {
        if (set) {
          [set appendString:@","];
        } else {
          set = [NSMutableString new];
        }
        [set appendString:[NSString stringWithFormat:@"%@ = ?", key]];
        [vals addObject:obj];
        count++;
        if (count == [vals count]) {
          NSLog(@"Yo");
        }

      }
    }];

    if (set && [f isKindOfClass:[SCGeometry class]]) {
      [sql appendString:@","];
    }
    [sql appendString:set];
    [sql appendString:[NSString stringWithFormat:@" WHERE %@ = %lld",
                                                 self.pkColName,
                                                 [f.identifier longLongValue]]];

    [self.queue inDatabase:^(FMDatabase *db) {
      int count = [f.properties count];
      BOOL success = [db executeUpdate:sql withArgumentsInArray:vals];
      if (success) {
        dispatch_async(
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
              [subscriber sendCompleted];
            });
      } else {
        [subscriber sendError:db.lastError];
      }
    }];
    return nil;
  }];
}

- (RACSignal *)create:(SCSpatialFeature *)f {
  return [RACSignal createSignal:^RACDisposable *(
                        id<RACSubscriber> subscriber) {
    NSMutableString *colsSql = nil;
    NSMutableArray *vals = [NSMutableArray new];
    if ([f isKindOfClass:[SCGeometry class]]) {
      colsSql = [NSMutableString new];
      SCGeometry *g = (SCGeometry *)f;
      [colsSql appendFormat:@"%@", self.geomColName];
      [vals addObject:[g bytes]];
    }
    [f.properties enumerateKeysAndObjectsUsingBlock:^(
                      NSString *key, NSObject *obj, BOOL *stop) {
      if (colsSql) {
        [colsSql appendString:@","];
      }
      [colsSql appendString:key];
      [vals addObject:obj];
    }];
//    NSMutableSet *remCols = [NSMutableSet setWithArray:colsTypes.allKeys];
//    NSSet *allProps = [NSSet setWithArray:f.properties.allKeys];
//    [remCols minusSet:allProps];
//    [remCols enumerateObjectsUsingBlock:^(NSString *key, BOOL * _Nonnull stop) {
//      [f.properties setObject:[NSNull new] forKey:key];
//    }];

    NSString *sql = [NSString
        stringWithFormat:@"INSERT INTO %@ (%@) VALUES (?)", self.name, colsSql];

    [self.queue inDatabase:^(FMDatabase *db) {
      NSError *err;
      BOOL success = [db executeUpdate:sql values:vals error:&err];
      if (err) {
        NSLog(@"%@", err.description);
        [subscriber sendError:err];
      }
      if (success) {
        f.identifier =
            [NSString stringWithFormat:@"%lld", [db lastInsertRowId]];
        dispatch_async(
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
              [subscriber sendCompleted];
            });
      } else {
        [subscriber sendError:db.lastError];
      }
    }];
    return nil;
  }];
}

- (SCSpatialFeature *)featureFromResultSet:(FMResultSet *)rs {
  // check if geometry
  SCSpatialFeature *f;
  long long ident = [rs longLongIntForColumn:self.pkColName];
  if (self.geomColName) {
    f = [SCGeometry fromGeometryBinary:[rs dataForColumn:self.geomColName]];
  } else {
    f = [[SCSpatialFeature alloc] init];
  }
  f.identifier = [NSString
      stringWithFormat:@"%lld", ident];
  NSMutableDictionary *dict = [[rs resultDictionary] mutableCopy];
  [dict removeObjectForKey:self.pkColName];
  [dict removeObjectForKey:self.geomColName];
  f.properties = dict;
  f.layerId = self.name;
  return f;
}
@end
