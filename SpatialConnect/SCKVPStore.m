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
  SCKVP_REAL
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

- (NSError*)open {
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

- (NSError*)openDatabase {
  [database open];
  NSString *createTable = @"CREATE TABLE IF NOT EXISTS kvp ( _id INTEGER NOT NULL PRIMARY KEY "
  @"AUTOINCREMENT, key STRING UNIQUE NOT NULL, value "
  @"BLOB NOT NULL, value_type INT NOT NULL);";
  NSString *createIndex = @"CREATE UNIQUE INDEX IF NOT EXISTS kIdx ON kvp(key);";
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

- (void)putValue:(NSObject*)value forKey:(NSString*)key {
  NSString *sql = [NSString stringWithFormat:@"INSERT OR REPLACE INTO %@ (key,value,value_type) VALUES (?,?,?)",tableName];
  NSError *error;
  NSInteger type;

  NSData *data;
  if ([value isKindOfClass:[NSNumber class]]) {
    type = SCKVP_REAL;
    data = [NSKeyedArchiver archivedDataWithRootObject:value];
  } else if ([value isKindOfClass:[NSData class]]) {
    type = SCKVP_BLOB;
    data = (NSData*)value;
  } else if ([value isKindOfClass:[NSString class]]) {
    type = SCKVP_TEXT;
    data = [NSKeyedArchiver archivedDataWithRootObject:value];
  }

  BOOL success = [database executeUpdate:sql withArgumentsInArray:@[key,data,@(type)]];
  if (!success) {
    error = database.lastError;
    NSLog(@"%@",error.description);
  }
}

- (void)putDictionary:(NSDictionary*)dict {
  NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ (key,value,value_type) VALUES (?,?,?)",tableName];
  [database beginTransaction];
  [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSObject *value, BOOL *stop) {
    NSInteger type;
    if ([value isKindOfClass:[NSNumber class]]) {
      type = SCKVP_REAL;
    } else if ([value isKindOfClass:[NSData class]]) {
      type = SCKVP_BLOB;
    } else if ([value isKindOfClass:[NSString class]]) {
      type = SCKVP_TEXT;
    }
    BOOL success = [database executeUpdate:sql withArgumentsInArray:@[key,value,@(type)]];
    if (success) {
      *stop = YES;
      [database rollback];
    }
  }];
  [database commit];
}

- (NSObject*)valueForKey:(NSString*)key {
  NSString *sql = [NSString stringWithFormat:@"SELECT value,value_type FROM %@ WHERE key = ?",tableName];
  FMResultSet *rs = [database executeQuery:sql withArgumentsInArray:@[key]];
  NSObject *obj = nil;
  if ([rs next]) {
    NSInteger t = [rs intForColumn:@"value_type"];
    switch (t) {
      case SCKVP_BLOB:
        obj = [rs dataForColumn:@"value"];
        break;
      case SCKVP_REAL:
        obj = [NSKeyedUnarchiver unarchiveObjectWithData:[rs dataForColumn:@"value"]];
        break;
      case SCKVP_TEXT:
        obj = [NSKeyedUnarchiver unarchiveObjectWithData:[rs dataForColumn:@"value"]];
      default:
        break;
    }
  }
  [rs close];
  return obj;
}

- (NSDictionary*)valuesForKeyPrefix:(NSString*)prefixKey {
  NSString *sql = [NSString stringWithFormat:@"SELECT key,value FROM %@ WHERE key LIKE ?",tableName];
  FMResultSet *rs = [database executeQuery:sql withArgumentsInArray:@[prefixKey]];
  NSDictionary *dict = [NSDictionary new];
  while ([rs next]) {
    NSObject *value = [rs objectForColumnName:@"value"];
    NSString *key = [rs stringForColumn:@"key"];
    [dict setValue:value forKey:key];
  }
  [rs close];
  return dict;
}

@end
