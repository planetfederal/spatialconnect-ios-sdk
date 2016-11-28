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
#import "SCFileUtils.h"
#import "SCGeometry+GPKG.h"
#import "SCGeopackage.h"
#import "SCGpkgTileSource.h"
#import "SCHttpUtils.h"
#import "SCKeyTuple.h"
#import "SCPoint.h"
#import "SCTileOverlay.h"

NSString *const SCGeopackageErrorDomain = @"SCGeopackageErrorDomain";

@interface GeopackageStore ()
@property(readwrite, nonatomic, strong) NSString *uri;
@property(readwrite, nonatomic, strong) NSString *filepath;
@property(readwrite, nonatomic, strong) SCGeopackage *gpkg;
@end

@implementation GeopackageStore

#define STORE_NAME @"Geopackage"
#define TYPE @"gpkg"
#define VERSION @"1"

#pragma mark -
#pragma mark Init Methods

@synthesize storeType = _storeType;
@synthesize storeVersion = _storeVersion;

- (id)initWithStoreConfig:(SCStoreConfig *)config {
  self = [super initWithStoreConfig:config];
  if (!self) {
    return nil;
  }
  self.name = config.name;
  self.permission = SC_DATASTORE_READWRITE;
    self.filepath = [NSString stringWithFormat:@"%@.gpkg", config.uniqueid];
    self.uri = config.uri;
  _storeType = TYPE;
  _storeVersion = VERSION;


  return self;
}

- (id)initWithStoreConfig:(SCStoreConfig *)config withStyle:(SCStyle *)style {
  self = [self initWithStoreConfig:config];
  if (!self) {
    return nil;
  }
  self.style = style;
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

- (void)connectBlocking {
    NSString *path = [self path];
    self.gpkg = [[SCGeopackage alloc] initEmptyGeopackageWithFilename:path];
    self.status = SC_DATASTORE_RUNNING;
}

#pragma mark -
#pragma mark SCDataStoreLifeCycle

- (RACSignal *)start {
  self.status = SC_DATASTORE_STARTED;
    
    if (self.gpkg) { // The Store is already connected and may have been
        // initialized as the default
        self.status = SC_DATASTORE_RUNNING;
        return [RACSignal empty];
    }
    // The Database's name on disk is its store ID. This is to guaruntee
    // uniqueness
    // when being stored on disk.
    NSString *path = [self path];
    BOOL b = [[NSFileManager defaultManager] fileExistsAtPath:path];
    
    if (b) {
        self.gpkg = [[SCGeopackage alloc] initWithFilename:path];
        self.status = SC_DATASTORE_RUNNING;
        return [RACSignal empty];
    } else if ([self.uri.lowercaseString containsString:@"http"]) {
        self.status = SC_DATASTORE_DOWNLOADINGDATA;
        NSURL *url = [[NSURL alloc] initWithString:self.uri];
        RACSignal *dload$ = [super download:url];
        __block NSMutableData *data = nil;
        [dload$ subscribeNext:^(RACTuple *t) {
            data = t.first;
            self.downloadProgress = t.second;
        }
                        error:^(NSError *error) {
                            self.status = SC_DATASTORE_DOWNLOADFAIL;
                        }
                    completed:^{
                        DDLogInfo(@"Saving GPKG to %@", path);
                        [data writeToFile:path atomically:YES];
                        self.gpkg = [[SCGeopackage alloc] initWithFilename:path];
                        self.downloadProgress = @(1.0f);
                        self.status = SC_DATASTORE_RUNNING;
                    }];
        return dload$;
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

- (void)stop {
  self.status = SC_DATASTORE_STOPPED;
}

- (void)resume {
}

- (void)pause {
}

- (NSString *)defaultLayerName {
    SCGpkgFeatureSource *fs =
    (SCGpkgFeatureSource *)[self.gpkg.featureContents firstObject];
    return fs.name;
}

- (void)addLayer:(NSString *)name withDef:(NSDictionary *)def {
  [self.gpkg addFeatureSource:name withTypes:def];
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
#pragma mark SCRasterStore
- (MKTileOverlay *)overlayFromLayer:(NSString *)layer
                            mapview:(MKMapView *)mapView {
    
    __block MKTileOverlay *overlay = nil;
    SCGpkgTileSource *ts = [self.gpkg tileSource:layer];
    overlay = [[SCTileOverlay alloc] initWithRasterSource:ts];
    overlay.canReplaceMapContent = false;
    [mapView addOverlay:overlay];
    return overlay;
}

#pragma mark -
#pragma mark SCSpatialStore
- (RACSignal *)query:(SCQueryFilter *)filter {
  return [[self.gpkg query:filter]
      map:^SCSpatialFeature *(SCSpatialFeature *f) {
        f.storeId = self.storeId;
        return f;
      }];
}

- (RACSignal *)queryById:(SCKeyTuple *)key {
    return [[self.gpkg featureSource:key.layerId] findById:key.featureId];
}

- (RACSignal *)create:(SCSpatialFeature *)feature {
  if (feature.storeId == nil) {
    feature.storeId = self.storeId;
  }
  if (feature.layerId == nil) {
    feature.layerId = self.defaultLayerName;
  }
    return [[self.gpkg featureSource:feature.layerId] create:feature];
}

- (RACSignal *)update:(SCSpatialFeature *)feature {
    return [[self.gpkg featureSource:feature.layerId] update:feature];
}

- (RACSignal *) delete:(SCKeyTuple *)tuple {
  NSParameterAssert(tuple);
    return [[self.gpkg featureSource:tuple.layerId] remove:tuple];
}

- (NSArray *)layers {
  return [self.vectorLayers arrayByAddingObjectsFromArray:self.rasterLayers];
}

- (NSArray *)vectorLayers {
  return [[[[self.gpkg.featureContents rac_sequence] signal]
      map:^NSString *(SCGpkgFeatureSource *f) {
        return f.name;
      }] toArray];
}

- (NSArray *)rasterLayers {
  return [[[[self.gpkg.tileContents rac_sequence] signal]
      map:^NSString *(SCGpkgFeatureSource *f) {
        return f.name;
      }] toArray];
}

- (SCPolygon *)coverage:(NSString *)layer {
    SCGpkgTileSource *ts = [self.gpkg tileSource:layer];
    return [ts coveragePolygon];
}

#pragma mark -
#pragma mark Override Parent
- (NSString *)key {
  NSString *str =
      [NSString stringWithFormat:@"%@.%@", _storeType, _storeVersion];
  return str;
}

+ (NSString *)versionKey {
  return [NSString stringWithFormat:@"%@.%@", TYPE, VERSION];
}

@end
