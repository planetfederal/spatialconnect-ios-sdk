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
#import "SCGeopackage.h"
#import "SCGpkgTileSource.h"

@interface GeopackageFileAdapter ()
- (RACSignal *)attemptFileDownload:(NSURL*)fileUrl;
@end

@interface GeopackageFileAdapter ()
@property(readwrite, nonatomic, strong) NSString *uri;
@property(readwrite, nonatomic, strong) NSString *filepath;
@property(readwrite, nonatomic, strong) NSString *storeId;
@property(readwrite, nonatomic, strong) SCGeopackage *gpkg;
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
    self.gpkg = [[SCGeopackage alloc] initWithFilename:path];
    return [RACSignal empty];
  } else if ([self.uri.lowercaseString containsString:@"http"]) {
    self.parentStore.status = SC_DATASTORE_DOWNLOADINGDATA;
    NSURL *url = [[NSURL alloc] initWithString:self.uri];
    return
        [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
          [[self attemptFileDownload:url] subscribeNext:^(NSData *data) {
            NSLog(@"Saving GPKG to %@", path);
            [data writeToFile:path atomically:YES];
            self.gpkg = [[SCGeopackage alloc] initWithFilename:path];
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

- (RACSignal *)attemptFileDownload:(NSURL *)fileUrl {
  NSURLRequest *request = [[NSURLRequest alloc] initWithURL:fileUrl];
  return [[NSURLConnection rac_sendAsynchronousRequest:request]
      reduceEach:^id(NSURLResponse *response, NSData *data) {
        return data;
      }];
}

- (NSString *)defaultLayerName {
  SCGpkgFeatureSource *fs = (SCGpkgFeatureSource*)[self.gpkg.featureContents firstObject];
  return fs.name;
}

- (NSString *)defaultRasterName {
  SCGpkgTileSource *ts = (SCGpkgTileSource *)[self.gpkg.tileContents firstObject];
  return ts.name;
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
  return self.gpkg.featureContents;
}

- (NSArray *)rasterList {
  return self.gpkg.tileContents;
}

- (MKTileOverlay *)overlayFromLayer:(NSString *)layer
                            mapview:(MKMapView *)mapView {
//  __block MKTileOverlay *overlay = nil;
//  NSArray *arr = self.gpkg.tileContents;

//  @weakify(self);
//  [arr enumerateObjectsUsingBlock:^(NSString *table, NSUInteger idx,
//                                    BOOL *_Nonnull stop) {
//    if ([layer isEqualToString:table]) {
//      @strongify(self);
//      GPKGTileDao *tileDao = [self.gpkg getTileDaoWithTableName:layer];
//      overlay = [GPKGOverlayFactory getTileOverlayWithTileDao:tileDao];
//      overlay.canReplaceMapContent = false;
//
//      GPKGTileMatrixSet *tileMatrixSet = tileDao.tileMatrixSet;
//      GPKGContents *contents =
//          [[self.gpkg getTileMatrixSetDao] getContents:tileMatrixSet];
//      GPKGContentsDao *contentsDao = [self.gpkg contentsDao];
//      GPKGProjection *projection = [contentsDao getProjection:contents];
//
//      GPKGProjectionTransform *transformToWebMercator =
//          [[GPKGProjectionTransform alloc]
//              initWithFromProjection:projection
//                           andToEpsg:PROJ_EPSG_WEB_MERCATOR];
//
//      GPKGBoundingBox *contentsBoundingBox = [contents getBoundingBox];
//      if ([projection.epsg intValue] == PROJ_EPSG_WORLD_GEODETIC_SYSTEM) {
//        contentsBoundingBox = [GPKGTileBoundingBoxUtils
//            boundWgs84BoundingBoxWithWebMercatorLimits:contentsBoundingBox];
//      }
//
//      GPKGBoundingBox *webMercatorBoundingBox =
//          [transformToWebMercator transformWithBoundingBox:contentsBoundingBox];
//      GPKGProjectionTransform *transform = [[GPKGProjectionTransform alloc]
//          initWithFromEpsg:PROJ_EPSG_WEB_MERCATOR
//                 andToEpsg:PROJ_EPSG_WORLD_GEODETIC_SYSTEM];
//      GPKGBoundingBox *boundingBox =
//          [transform transformWithBoundingBox:webMercatorBoundingBox];
//
//      [mapView addOverlay:overlay];
//    }
//  }];

  return nil;
}


- (RACSignal *)createFeature:(SCSpatialFeature *)feature {
  return [[self.gpkg featureSource:feature.layerId] create:feature];
}

/**
 *  Deletes feature using the compound Id key
 *
 *  @param compoundId <store>.<layer>.<feature>
 *
 *  @return RACSignal for completion of deletion
 */
- (RACSignal *)deleteFeature:(SCKeyTuple *)tuple {
  return [[self.gpkg featureSource:tuple.layerId] remove:tuple];
}

- (RACSignal *)updateFeature:(SCSpatialFeature *)feature {
  return [[self.gpkg featureSource:feature.layerId] update:feature];
}

- (RACSignal *)query:(SCQueryFilter *)filter {
  return [self.gpkg query:filter];
}

- (RACSignal*)queryById:(SCKeyTuple *)key {
  return [[self.gpkg featureSource:key.layerId] findById:key.featureId];
}

- (RACSignal *)queryByLayerId:(NSString *)layerId
                   withFilter:(SCQueryFilter *)filter {
  return [[self.gpkg featureSource:layerId] queryWithFilter:filter];
}

@end
