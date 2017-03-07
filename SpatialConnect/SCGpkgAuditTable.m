//
//  SCGpkgAuditTable.m
//  SpatialConnect
//
//  Created by Frank Rowe on 3/6/17.
//  Copyright © 2017 Boundless Spatial. All rights reserved.
//

#import "SCGpkgAuditTable.h"
#import "SCGpkgContent.h"
#import "SCGpkgAuditedTables.h"

@interface SCGpkgAuditTable ()

@property(strong, readwrite) NSString *auditTableName;

@end

@implementation SCGpkgAuditTable

@synthesize auditTableName;

- (id)initWithResultSet:(FMResultSet *)rs {
  self = [super init];
  if (self) {
    self.auditTableName = [rs stringForColumn:kCTAuditTableNameColName];
  }
  return self;
}

- (RACSignal *)unsynced {
  NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@", self.auditTableName];
  return
  [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    @strongify(self);
    [self.queue inDatabase:^(FMDatabase *db) {
      FMResultSet *resultSet = [db executeQuery:sql];
      while ([resultSet next]) {
        SCGpkgAuditTable *e =
        [[SCGpkgAuditTable alloc] initWithResultSet:resultSet];
        [subscriber sendNext:e];
      }
      [resultSet close];
      [subscriber sendCompleted];
    }];
    return nil;
  }];
}

@end
