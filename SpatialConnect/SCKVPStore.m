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

#import "SCKVPStore.h"
#import <libgpkgios/sqlite3.h>

const NSString *tableName = @"kvp";

typedef NS_ENUM(NSUInteger, KVPValueType) {
  SCKVP_TEXT,
  SCKVP_BLOB,
  SCKVP_REAL,
  SCKVP_DICT
};

@implementation SCKVPStore

- (id)init {
  self = [super init];
  if (self) {
    if ([self createDatabase]) {
    }
  }
  return self;
}

- (NSError *)open {
  return [self openDatabase];
}

- (void)close {
  [self closeDatabase];
}

- (BOOL)createDatabase {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *path = [documentsDirectory stringByAppendingString:@"/kvp.db"];
  database = [[FMDatabase alloc] initWithPath:path];
  if (database) {
    return YES;
  } else {
    return NO;
  }
}

- (NSError *)openDatabase {
  [database open];
  NSString *createTable =
      @"CREATE TABLE IF NOT EXISTS kvp ( _id INTEGER NOT NULL PRIMARY KEY "
      @"AUTOINCREMENT, key STRING UNIQUE NOT NULL, value "
      @"BLOB NOT NULL, value_type INT NOT NULL);";
  NSString *createIndex =
      @"CREATE UNIQUE INDEX IF NOT EXISTS kIdx ON kvp(key);";
  int res = [database
      executeStatements:[NSString stringWithFormat:@"%@%@", createTable,
                                                   createIndex]];
  if (res == SQLITE_OK) {
    return nil;
  } else {
    return database.lastError;
  }
}

- (void)closeDatabase {
  if (database) {
    [database close];
  }
}

- (void)putValue:(NSObject *)value forKey:(NSString *)key {
  NSError *err = nil;
  [self upsertRow:value forKey:key error:err];
  if (err) {
    NSLog(@"%@", err.description);
  }
}

- (void)upsertRow:(NSObject *)value
           forKey:(NSString *)key
            error:(NSError *)err {
  NSString *sql = [NSString
      stringWithFormat:
          @"INSERT OR REPLACE INTO %@ (key,value,value_type) VALUES (?,?,?)",
          tableName];
  NSInteger type;

  NSData *data;
  if ([value isKindOfClass:[NSNumber class]]) {
    type = SCKVP_REAL;
    data = [NSKeyedArchiver archivedDataWithRootObject:value];
  } else if ([value isKindOfClass:[NSData class]]) {
    type = SCKVP_BLOB;
    data = (NSData *)value;
  } else if ([value isKindOfClass:[NSString class]]) {
    type = SCKVP_TEXT;
    data = [NSKeyedArchiver archivedDataWithRootObject:value];
  }
  BOOL success =
      [database executeUpdate:sql withArgumentsInArray:@[ key, data, @(type) ]];
  if (!success) {
    err = database.lastError;
    NSLog(@"%@", err.description);
  }
}

- (void)putDictionary:(NSDictionary *)dict forKey:(NSString *)key {
  [database beginTransaction];
  BOOL success = [self recurPutDictionary:dict forKey:key];
  if (success) {
    [database commit];
  } else {
    [database rollback];
  }
}

- (BOOL)recurPutDictionary:dict forKey:(NSString *)key {
  __block BOOL success = YES;
  [dict enumerateKeysAndObjectsUsingBlock:^(NSString *k, NSObject *value,
                                            BOOL *stop) {
    NSString *compositeKey = [NSString stringWithFormat:@"%@.%@", key, k];
    if ([value isKindOfClass:[NSDictionary class]]) {
      if (![self recurPutDictionary:(NSDictionary *)value
                             forKey:compositeKey]) {
        *stop = YES;
        success = NO;
      };
    } else {
      NSError *err = nil;
      [self upsertRow:value forKey:compositeKey error:err];
      if (err) {
        *stop = YES;
        success = NO;
      }
    }
  }];
  return success;
}

- (NSDictionary *)dictionaryForKey:(NSString *)k {
  NSString *sql = [NSString
      stringWithFormat:
          @"SELECT key,value,value_type FROM %@ WHERE key LIKE '%@.%%'",
          tableName, k];
  FMResultSet *rs = [database executeQuery:sql];
  NSMutableDictionary *returnDictionary = [NSMutableDictionary new];
  while ([rs next]) {
    NSString *key = [rs stringForColumn:@"key"];
    NSString *prefix = [NSString stringWithFormat:@"%@.", k];
    NSString *suffix = [key copy];
    if ([key hasPrefix:prefix]) {
      suffix = [key substringFromIndex:[prefix length]];
    }
    NSObject *obj = [self rowValueToObject:rs];
    [self pushKeyPath:[suffix componentsSeparatedByString:@"."]
                value:obj
         inDictionary:returnDictionary];
  }
  return [NSDictionary dictionaryWithDictionary:returnDictionary];
}

- (void)pushKeyPath:(NSArray *)keys
              value:(NSObject *)v
       inDictionary:(NSMutableDictionary *)d {
  if (keys.count == 1) {
    [d setObject:v forKey:keys.firstObject];
    return;
  } else {
    NSObject *obj = [d objectForKey:keys.firstObject];
    if (!obj) {
      NSMutableDictionary *newDict = [NSMutableDictionary new];
      [self pushKeyPath:[keys subarrayWithRange:NSMakeRange(1, keys.count - 1)]
                  value:v
           inDictionary:newDict];
      [d setObject:newDict forKey:keys.firstObject];
    } else {
      NSMutableDictionary *dict = [d objectForKey:keys.firstObject];
      [self pushKeyPath:[keys subarrayWithRange:NSMakeRange(1, keys.count - 1)]
                  value:v
           inDictionary:dict];
    }
  }
}

/**
 * Returns the NSObject in the value column
 **/
- (NSObject *)valueForKey:(NSString *)key {
  NSString *sql = [NSString
      stringWithFormat:@"SELECT value,value_type FROM %@ WHERE key = ?",
                       tableName];
  FMResultSet *rs = [database executeQuery:sql withArgumentsInArray:@[ key ]];
  NSObject *obj = nil;
  if ([rs next]) {
    obj = [self rowValueToObject:rs];
  }
  [rs close];
  return obj;
}

- (NSObject *)rowValueToObject:(FMResultSet *)rs {
  NSInteger type = [rs intForColumn:@"value_type"];
  NSObject *obj = nil;
  switch (type) {
  case SCKVP_BLOB:
    obj = [rs dataForColumn:@"value"];
    break;
  case SCKVP_REAL:
    obj =
        [NSKeyedUnarchiver unarchiveObjectWithData:[rs dataForColumn:@"value"]];
    break;
  case SCKVP_TEXT:
    obj =
        [NSKeyedUnarchiver unarchiveObjectWithData:[rs dataForColumn:@"value"]];
  default:
    break;
  }
  return obj;
}

/**
 * Returns a dictionary of keys as the key column value and values as the value
 *column
 * @{
 *   @"foo.bar" : NSObject
 * };
 **/
- (NSDictionary *)valuesForKeyPrefix:(NSString *)prefixKey {
  NSString *sql = [NSString
      stringWithFormat:
          @"SELECT key,value,value_type FROM %@ WHERE key LIKE '%@.%%'",
          tableName, prefixKey];
  FMResultSet *rs = [database executeQuery:sql];
  NSMutableDictionary *dict = [NSMutableDictionary new];
  while ([rs next]) {
    NSObject *obj = [self rowValueToObject:rs];
    NSString *key = [rs stringForColumn:@"key"];
    [dict setValue:obj forKey:key];
  }
  [rs close];
  return [NSDictionary dictionaryWithDictionary:dict];
}

@end
