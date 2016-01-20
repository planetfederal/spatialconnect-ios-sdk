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
#import "GeopackageFileAdapter.h"
#import "GeopackageStore.h"
#import "SCFileUtils.h"
#import "SCGeometry+GPKG.h"
#import "SCKeyTuple.h"
#import "SCPoint.h"
#import <geopackage-ios/GPKGOverlayFactory.h>
#import <geopackage-ios/GPKGProjectionConstants.h>
#import <geopackage-ios/GPKGProjectionTransform.h>
#import <geopackage-ios/GPKGSpatialReferenceSystemDao.h>
#import <geopackage-ios/GPKGTileBoundingBoxUtils.h>

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
@synthesize parentStore;

- (id)initWithStoreConfig:(SCStoreConfig *)cfg {
  if (self = [super init]) {
    _uri = cfg.uri;
    _storeId = cfg.uniqueid;
    _filepath = nil;
  }
  return self;
}

- (RACSignal *)connect {
  BOOL saveToDocsDir = ![SCFileUtils isTesting];
  // The Database's name on disk is its store ID. This is to guaruntee
  // uniqueness
  // when being stored on disk.
  NSString *dbName = [NSString stringWithFormat:@"%@.db", self.storeId];
  NSString *path;
  if (saveToDocsDir) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    path = [documentsDirectory stringByAppendingPathComponent:dbName];
  } else {
    path = [SCFileUtils filePathFromNSHomeDirectory:dbName];
  }
  BOOL b = [[NSFileManager defaultManager] fileExistsAtPath:path];

  if (b) {
    self.gpkg = [self openConnection:path];
    return [RACSignal empty];
  } else if ([self.uri.lowercaseString containsString:@"http"]) {
    self.parentStore.status = SC_DATASTORE_DOWNLOADINGDATA;
    NSURL *url = [[NSURL alloc] initWithString:self.uri];
    return
        [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
          [[self attemptFileDownload:url] subscribeNext:^(NSData *data) {
            NSLog(@"Saving GPKG to %@", path);
            [data writeToFile:path atomically:YES];
            self.gpkg = [self openConnection:path];
            [subscriber sendCompleted];
          }
              error:^(NSError *error) {
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

- (GPKGGeoPackage *)openConnection:(NSString *)path {
  GPKGConnection *connection =
      [[GPKGConnection alloc] initWithDatabaseFilename:path];
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

- (NSString *)defaultRasterName {
  return (NSString *)self.gpkg.tileTables[0];
}

#pragma mark -
#pragma mark SCAdapterKeyValue
- (NSString *)filepathKey {
  return [NSString stringWithFormat:@"%@.%@", self.storeId, @"filepath"];
}

- (void)setFilepathPreference:(NSString *)dbPath {
  NSString *key = self.filepathKey;
  [[NSUserDefaults standardUserDefaults] setObject:dbPath forKey:key];
}

- (NSString *)dbFilepath {
  return [[NSUserDefaults standardUserDefaults] stringForKey:self.filepathKey];
}

- (NSArray *)layerList {
  return self.gpkg.featureTables;
}

- (NSArray *)rasterList {
  return self.gpkg.tileTables;
}

- (MKTileOverlay *)overlayFromLayer:(NSString *)layer
                            mapview:(MKMapView *)mapView {
  __block MKTileOverlay *overlay = nil;
  NSArray *arr = [self.gpkg tileTables];

  @weakify(self);
  [arr enumerateObjectsUsingBlock:^(NSString *table, NSUInteger idx,
                                    BOOL *_Nonnull stop) {
    if ([layer isEqualToString:table]) {
      @strongify(self);
      GPKGTileDao *tileDao = [self.gpkg getTileDaoWithTableName:layer];
      overlay = [GPKGOverlayFactory getTileOverlayWithTileDao:tileDao];
      overlay.canReplaceMapContent = false;

      GPKGTileMatrixSet *tileMatrixSet = tileDao.tileMatrixSet;
      GPKGContents *contents =
          [[self.gpkg getTileMatrixSetDao] getContents:tileMatrixSet];
      GPKGContentsDao *contentsDao = [self.gpkg contentsDao];
      GPKGProjection *projection = [contentsDao getProjection:contents];

      GPKGProjectionTransform *transformToWebMercator =
          [[GPKGProjectionTransform alloc]
              initWithFromProjection:projection
                           andToEpsg:PROJ_EPSG_WEB_MERCATOR];

      GPKGBoundingBox *contentsBoundingBox = [contents getBoundingBox];
      if ([projection.epsg intValue] == PROJ_EPSG_WORLD_GEODETIC_SYSTEM) {
        contentsBoundingBox = [GPKGTileBoundingBoxUtils
            boundWgs84BoundingBoxWithWebMercatorLimits:contentsBoundingBox];
      }

      GPKGBoundingBox *webMercatorBoundingBox =
          [transformToWebMercator transformWithBoundingBox:contentsBoundingBox];
      GPKGProjectionTransform *transform = [[GPKGProjectionTransform alloc]
          initWithFromEpsg:PROJ_EPSG_WEB_MERCATOR
                 andToEpsg:PROJ_EPSG_WORLD_GEODETIC_SYSTEM];
      GPKGBoundingBox *boundingBox =
          [transform transformWithBoundingBox:webMercatorBoundingBox];

      [mapView addOverlay:overlay];
    }
  }];

  return overlay;
}

- (GPKGFeatureRow *)toFeatureRow:(SCSpatialFeature *)feature {
  GPKGFeatureDao *fDao = [self.gpkg getFeatureDaoWithTableName:feature.layerId];
  GPKGFeatureRow *row =
      (GPKGFeatureRow *)[fDao queryForIdObject:feature.identifier];
  if (!row) {
    row = [fDao newRow];
  }

  [feature.properties enumerateKeysAndObjectsUsingBlock:^(
                          NSString *key, NSObject *obj, BOOL *stop) {
    NSArray *cols = fDao.getFeatureTable.columnNames;
    if ([cols containsObject:key]) {
      if (![key isEqualToString:@"id"]) {
        [row setValueWithColumnName:key andValue:obj];
      }
    } else {
      [fDao createIfNotExists:nil];
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
        [feature.properties enumerateKeysAndObjectsUsingBlock:^(
                                NSString *key, NSObject *obj, BOOL *stop) {
          [featureDao.table.columnNames
              enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx,
                                           BOOL *stop) {
                if ([name isEqualToString:key]) {
                  [newRow setValue:obj forKey:key];
                }
              }];
        }];

        if ([newRow.getColumnNames containsObject:@"featureid"]) {
          [newRow setValueWithColumnName:@"featureid"
                                andValue:feature.identifier];
        }

        long newId = [featureDao create:newRow];
        [feature setIdentifier:[[NSNumber numberWithLong:newId] stringValue]];
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
        NSNumber *n = [NSNumber numberWithLong:[tuple.featureId integerValue]];
        if ([fDao deleteById:n] == 1) {
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

- (RACSignal *)query:(SCQueryFilter *)filter {
  __block int limit = 0;
  return
      [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSArray *arr = self.gpkg.featureTables;
        NSMutableSet *featureTableSet = [NSMutableSet setWithArray:arr];
        NSSet *layerQuerySet = [NSSet setWithArray:filter.layerIds];
        // Use set intersection to make sure layers are valid feature table
        // names.
        [featureTableSet intersectSet:layerQuerySet];
        NSArray *queryLayers = featureTableSet.allObjects.count > 0
                                   ? featureTableSet.allObjects
                                   : arr;
        __block GPKGResultSet *rs;
        int filterLimit = filter == nil ? 100 : (int)filter.limit;
        __block int perLayer;
        [queryLayers enumerateObjectsUsingBlock:^(NSString *tableName,
                                                  NSUInteger idx, BOOL *stop) {
          perLayer = filterLimit / queryLayers.count;
          GPKGFeatureDao *dao =
              [self.gpkg getFeatureDaoWithTableName:tableName];
          rs = [dao queryForAll];
          int layerCount = 0;
          while (limit < filterLimit && rs != nil && [rs moveToNext] &&
                 layerCount < perLayer) {
            SCSpatialFeature *f =
                [self createSCSpatialFeature:[dao getFeatureRow:rs]];

            if ([f isKindOfClass:[SCGeometry class]] && filter != nil) {
              BOOL check = [filter testValue:f];
              if (check) {
                limit++;
                layerCount++;
                [subscriber sendNext:f];
              }
            } else {
              limit++;
              layerCount++;
              [subscriber sendNext:f];
            }
          }
          [rs close]; // Must Close connection before disposing of Observable
        }];
        [subscriber sendCompleted];
        return nil;
      }] subscribeOn:[RACScheduler
                         schedulerWithPriority:RACSchedulerPriorityBackground]];
}

- (RACSignal *)queryById:(SCKeyTuple *)key {
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSString *layerId = key.layerId;
        GPKGFeatureDao *fDao = [self.gpkg getFeatureDaoWithTableName:layerId];
        NSString *featureId = key.featureId;
        GPKGResultSet *rs = [fDao queryForId:featureId];
        if (rs.moveToFirst) {
          SCSpatialFeature *feature =
              [self createSCSpatialFeature:[fDao getFeatureRow:rs]];
          [subscriber sendNext:feature];
        }
        [rs close]; // Must Close connection before disposing of Observable
        [subscriber sendCompleted];
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
        [rs close]; // Must Close connection before disposing of Observable
        [subscriber sendCompleted];
        return nil;
      }];
}

- (SCSpatialFeature *)createSCSpatialFeature:(GPKGFeatureRow *)row {
  SCSpatialFeature *scSpatialFeature;
  // set the geometry's geometry
  GPKGGeometryData *geometryData = [row getGeometry];
  if (geometryData != nil) {
    scSpatialFeature = [SCGeometry fromGeometryData:geometryData];
  } else {
    scSpatialFeature = [[SCSpatialFeature alloc] init];
  }
  scSpatialFeature.storeId = self.storeId;
  scSpatialFeature.layerId = row.table.tableName;
  scSpatialFeature.identifier = [NSString stringWithFormat:@"%@", row.getId];

  [row.getColumnNames enumerateObjectsUsingBlock:^(
                          NSString *name, NSUInteger idx, BOOL *_Nonnull stop) {
    NSObject *obj = [row getValueWithColumnName:name];
    if (obj) {
      [scSpatialFeature.properties setObject:[row getValueWithColumnName:name]
                                      forKey:name];
    } else {
      [scSpatialFeature.properties setObject:[NSNull null] forKey:name];
    }
  }];

  return scSpatialFeature;
}

@end
