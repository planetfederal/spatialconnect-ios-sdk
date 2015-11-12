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
#import "GeopackageStore.h"
#import "GeopackageFileAdapter.h"
#import "SCKeyTuple.h"
#import "SCFileUtils.h"
#import "SCGeometry+GPKG.h"

@interface GeopackageFileAdapter (private)
- (BOOL)checkFile;
- (RACSignal *)attemptFileDownload;
- (GPKGGeoPackage *)openConnection;
@end

@interface GeopackageFileAdapter ()
@property(readwrite, nonatomic, strong) NSString *uri;
@property(readwrite, nonatomic, strong) NSString *filepath;
@property(readwrite, nonatomic, strong) NSString *storeId;
@property(readwrite, nonatomic, strong) GPKGGeoPackage *gpkg;
@end

@implementation GeopackageFileAdapter

@synthesize uri = _uri;
@synthesize filepath = _filepath;
@synthesize storeId = _storeId;
@synthesize gpkg;

- (id)initWithStoreConfig:(SCStoreConfig *)cfg {
  if (self = [super init]) {
    _uri = cfg.uri;
    _storeId = cfg.uniqueid;
    _filepath = nil;
  }
  return self;
}

- (RACSignal *)connect {
  NSString *dbName = self.storeId;
  NSString *fp = self.dbFilepath;

  if ([[NSFileManager defaultManager] fileExistsAtPath:fp]) {
    self.gpkg = self.openConnection;
    return [RACSignal empty];
  } else if ([self.uri.lowercaseString containsString:@"http"]) {
    NSURL *url = [[NSURL alloc] initWithString:self.uri];
    return
        [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
          [[self attemptFileDownload:url] subscribeNext:^(NSData *data) {
            NSString *dbPath =
                [SCFileUtils filePathFromDocumentsDirectory:dbName];
            [data writeToFile:dbPath atomically:YES];
            [self setFilepathPreference:dbPath];
            self.gpkg = self.openConnection;
            [subscriber sendCompleted];
          } error:^(NSError *error) {
            NSLog(@"%@", error.description);
            [subscriber sendError:error];
          }];
          return nil;
        }];
  }
  NSError *err = [NSError errorWithDomain:SCGeopackageErrorDomain
                                     code:SC_GEOPACKAGE_FILENOTFOUND
                                 userInfo:nil];
  return [RACSignal error:err];
}

- (GPKGGeoPackage *)openConnection {
  GPKGConnection *connection =
      [[GPKGConnection alloc] initWithDatabaseFilename:self.dbFilepath];
  GPKGGeoPackage *g =
      [[GPKGGeoPackage alloc] initWithConnection:connection andWritable:YES];
  return g;
}

- (RACSignal *)attemptFileDownload:(NSURL *)fileUrl {
  NSURLRequest *request = [[NSURLRequest alloc] initWithURL:fileUrl];
  return [[NSURLConnection rac_sendAsynchronousRequest:request]
      reduceEach:^id(NSURLResponse *response, NSData *data) {
        return data;
      }];
}

- (NSString *)defaultLayerName {
  return (NSString *)self.gpkg.featureTables[0];
}

#pragma mark -
#pragma mark SCAdapterKeyValue
- (NSString *)filepathKey {
  return [NSString stringWithFormat:@"%@.%@", self.storeId, @"filepath"];
}

- (void)setFilepathPreference:(NSString *)dbPath {
  [[NSUserDefaults standardUserDefaults] setObject:dbPath
                                            forKey:self.filepathKey];
}

- (NSString *)dbFilepath {
  return [[NSUserDefaults standardUserDefaults] stringForKey:self.filepathKey];
}

- (NSArray *)layerList {
  return self.gpkg.featureTables;
}

- (GPKGFeatureRow *)toFeatureRow:(SCSpatialFeature *)feature {
  GPKGFeatureDao *fDao = [self.gpkg getFeatureDaoWithTableName:feature.layerId];
  GPKGFeatureRow *row =
      (GPKGFeatureRow *)[fDao queryForIdObject:feature.identifier];
  if (!row) {
    row = [fDao newRow];
  }

  [feature.properties
      enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSObject *obj,
                                          BOOL *stop) {
        if ([fDao.getFeatureTable.columnNames containsObject:key]) {
          [row setValue:obj forKey:key];
        }
      }];

  if ([feature isKindOfClass:SCGeometry.class]) {
    SCGeometry *g = (SCGeometry *)feature;
    [row setGeometry:g.wkb];
  }

  return row;
}

- (RACSignal *)createFeature:(SCSpatialFeature *)feature {
  GPKGFeatureRow *newRow = [self toFeatureRow:feature];
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        GPKGFeatureDao *featureDao =
            [self.gpkg getFeatureDaoWithTableName:feature.layerId];
        [feature.properties
            enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSObject *obj,
                                                BOOL *stop) {
              [featureDao.table.columnNames
                  enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx,
                                               BOOL *stop) {
                    if ([name isEqualToString:key]) {
                      [newRow setValue:obj forKey:key];
                    }
                  }];
            }];

        if ([feature isKindOfClass:SCGeometry.class]) {
          SCGeometry *g = (SCGeometry *)feature;
          if (g) {
            [newRow setGeometry:g.wkb];
          }
        }

        [featureDao create:newRow];
        [subscriber sendCompleted];
        return nil;
      }];
}

/**
 *  Deletes feature using the compound Id key
 *
 *  @param compoundId <store>.<layer>.<feature>
 *
 *  @return RACSignal for completion of deletion
 */
- (RACSignal *)deleteFeature:(SCKeyTuple *)tuple {
  GPKGFeatureDao *fDao = [self.gpkg getFeatureDaoWithTableName:tuple.layerId];
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        if ([fDao deleteById:tuple.featureId] == 1) {
          [subscriber sendCompleted];
        } else {
          [subscriber sendError:[NSError errorWithDomain:SCGeopackageErrorDomain
                                                    code:100
                                                userInfo:nil]];
        }
        return nil;
      }];
}

- (RACSignal *)updateFeature:(SCSpatialFeature *)feature {
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        GPKGFeatureDao *fDao =
            [self.gpkg getFeatureDaoWithTableName:feature.layerId];
        GPKGFeatureRow *row = [self toFeatureRow:feature];
        [fDao update:row];
        [subscriber sendCompleted];
        return nil;
      }];
}

- (RACSignal *)queryAllLayers:(SCQueryFilter *)filter {
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.gpkg.featureTables
            enumerateObjectsUsingBlock:^(NSString *tableName, NSUInteger idx,
                                         BOOL *stop) {
              GPKGFeatureDao *dao =
                  [self.gpkg getFeatureDaoWithTableName:tableName];
              GPKGResultSet *rs = [dao queryForAll];
              int limit = 0;
              while (limit < 100 && rs != nil && [rs moveToNext]) {
                limit++;
                SCSpatialFeature *feature =
                    [self createSCSpatialFeature:[dao getFeatureRow:rs]];
                [subscriber sendNext:feature];
              }
              [rs close];
              [subscriber sendCompleted];
            }];
        return nil;
      }];
}

- (RACSignal *)queryByLayerId:(NSString *)layerId
                   withFilter:(SCQueryFilter *)filter {
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        GPKGFeatureDao *fDao = [self.gpkg getFeatureDaoWithTableName:layerId];
        GPKGResultSet *rs = [fDao queryForAll];
        int limit = 0;
        while (limit < 100 && rs != nil && [rs moveToNext]) {
          limit++;

          SCSpatialFeature *feature =
              [self createSCSpatialFeature:[fDao getFeatureRow:rs]];
          [subscriber sendNext:feature];
        }
        [rs close];
        [subscriber sendCompleted];
        return nil;
      }];
}

- (SCSpatialFeature *)createSCSpatialFeature:(GPKGFeatureRow *)row {
  SCSpatialFeature *scSpatialFeature;
  // set the geometry's geometry
  GPKGGeometryData *geometryData = [row getGeometry];
  if (geometryData != nil) {
    scSpatialFeature = [[SCSpatialFeature alloc] init];
  } else {
    scSpatialFeature = [[SCSpatialFeature alloc] init];
  }
  [scSpatialFeature
      setIdentifier:[NSString stringWithFormat:@"%@.%@.%@", self.storeId,
                                               row.table.tableName, row.getId]];
  [row.getColumnNames enumerateObjectsUsingBlock:^(NSString *name,
                                                   NSUInteger idx,
                                                   BOOL *_Nonnull stop) {
    NSObject *obj = [row getValueWithColumnName:name];
    if (obj) {
      [scSpatialFeature.properties setObject:[row getValueWithColumnName:name]
                                      forKey:name];
    }
  }];

  return scSpatialFeature;
}

@end
