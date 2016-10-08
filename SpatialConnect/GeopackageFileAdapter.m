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
#import "SCHttpUtils.h"
#import "SCFileUtils.h"
#import "SCGeometry+GPKG.h"
#import "SCGeopackage.h"
#import "SCGpkgTileSource.h"
#import "SCKeyTuple.h"
#import "SCPoint.h"
#import "SCTileOverlay.h"

@interface GeopackageFileAdapter ()

@end

@interface GeopackageFileAdapter ()
@property(readwrite, nonatomic, strong) NSString *uri;
@property(readwrite, nonatomic, strong) NSString *filepath;
@property(readwrite, nonatomic, strong) SCGeopackage *gpkg;
@end

@implementation GeopackageFileAdapter

@synthesize uri = _uri;
@synthesize filepath = _filepath;
@synthesize gpkg;
@synthesize parentStore;

- (id)initWithFileName:(NSString *)dbname andURI:(NSString *)u {
  if (self = [super init]) {
    _filepath = [NSString stringWithFormat:@"%@.gpkg", dbname];
    _uri = u;
  }
  return self;
}

- (NSString *)path {
  NSString *path = nil;
  BOOL saveToDocsDir = ![SCFileUtils isTesting];
  if (saveToDocsDir) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    path = [documentsDirectory stringByAppendingPathComponent:self.filepath];
  } else {
    path = [SCFileUtils filePathFromNSHomeDirectory:self.filepath];
  }
  return path;
}

- (RACSignal *)connect {
  if (self.gpkg) { // The Store is already connected and may have been
                   // initialized as the default
    return [RACSignal empty];
  }
  // The Database's name on disk is its store ID. This is to guaruntee
  // uniqueness
  // when being stored on disk.
  NSString *path = [self path];
  BOOL b = [[NSFileManager defaultManager] fileExistsAtPath:path];

  if (b) {
    self.gpkg = [[SCGeopackage alloc] initWithFilename:path];
    return [RACSignal empty];
  } else if ([self.uri.lowercaseString containsString:@"http"]) {
    self.parentStore.status = SC_DATASTORE_DOWNLOADINGDATA;
    NSURL *url = [[NSURL alloc] initWithString:self.uri];
    return
        [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
          [[SCHttpUtils getRequestURLAsData:url] subscribeNext:^(NSData *data) {
            NSLog(@"Saving GPKG to %@", path);
            [data writeToFile:path atomically:YES];
            self.gpkg = [[SCGeopackage alloc] initWithFilename:path];
            [subscriber sendCompleted];
          }
              error:^(NSError *error) {
                [subscriber sendError:error];
              }];
          return nil;
        }];
  } else if ([path containsString:@"DEFAULT_STORE"]) {
    // initialize empty geopackage
    self.gpkg = [[SCGeopackage alloc] initEmptyGeopackageWithFilename:path];
    return [RACSignal empty];
  }
  NSError *err = [NSError errorWithDomain:SCGeopackageErrorDomain
                                     code:SC_GEOPACKAGE_FILENOTFOUND
                                 userInfo:nil];
  return [RACSignal error:err];
}

- (void)connectBlocking {
  NSString *path = [self path];
  self.gpkg = [[SCGeopackage alloc] initEmptyGeopackageWithFilename:path];
}

- (void)disconnect {
  if (self.gpkg) {
    [self.gpkg close];
  }
}

- (NSString *)defaultLayerName {
  SCGpkgFeatureSource *fs =
      (SCGpkgFeatureSource *)[self.gpkg.featureContents firstObject];
  return fs.name;
}

- (void)addLayer:(NSString *)name typeDefs:(NSDictionary *)t {
  [self.gpkg addFeatureSource:name withTypes:t];
}

- (void)removeLayer:(NSString *)name {
  [self.gpkg removeFeatureSource:name];
}

- (NSString *)defaultRasterName {
  SCGpkgTileSource *ts =
      (SCGpkgTileSource *)[self.gpkg.tileContents firstObject];
  return ts.name;
}

#pragma mark -
- (NSArray *)vectorLayers {
  return self.gpkg.featureContents;
}

- (NSArray *)rasterLayers {
  return self.gpkg.tileContents;
}

- (MKTileOverlay *)overlayFromLayer:(NSString *)layer
                            mapview:(MKMapView *)mapView {
  __block MKTileOverlay *overlay = nil;
  SCGpkgTileSource *ts = [self.gpkg tileSource:layer];
  overlay = [[SCTileOverlay alloc] initWithRasterSource:ts];
  overlay.canReplaceMapContent = false;
  [mapView addOverlay:overlay];
  return overlay;
}

- (SCPolygon *)coverage:(NSString *)layer {
  SCGpkgTileSource *ts = [self.gpkg tileSource:layer];
  return [ts coveragePolygon];
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

- (RACSignal *)queryById:(SCKeyTuple *)key {
  return [[self.gpkg featureSource:key.layerId] findById:key.featureId];
}

- (RACSignal *)queryByLayerId:(NSString *)layerId
                   withFilter:(SCQueryFilter *)filter {
  return [[self.gpkg featureSource:layerId] queryWithFilter:filter];
}

@end
