//
//  SCGpkgAuditedTables.m
//  SpatialConnect
//
//  Created by Frank Rowe on 3/6/17.
//  Copyright © 2017 Boundless Spatial. All rights reserved.
//

#import "SCGpkgAuditedTables.h"
#import "SCGpkgAuditTable.h"
#import "SCGpkgDataColumnsTable.h"
#import "SCGpkgDataColumn.h"

NSString *const kCTTableName = @"geogig_audited_tables";
NSString *const kCTAuditTableNameColName = @"audit_table";

@implementation SCGpkgAuditedTables

- (id)initWithPool:(FMDatabasePool *)q {
  return [super initWithPool:q tableName:kCTTableName];
}

- (RACSignal *)all {
  NSString *sql = [self allQueryString];
  @weakify(self);
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
