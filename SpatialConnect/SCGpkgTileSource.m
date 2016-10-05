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

#import "SCBoundingBox+GeoJSON.h"
#import "SCBoundingBox.h"
#import "SCGpkgTileSource.h"
#import "SCPoint.h"
#import "SCTileMatrixRow.h"
#import <float.h>

@interface SCGpkgTileSource ()
@property(strong, readwrite) FMDatabasePool *pool;
@property(strong, readwrite) NSString *name;
@property(strong, readwrite) SCBoundingBox *bbox;
@property(readwrite) NSInteger crs;
@property(strong, readwrite) NSDictionary *matrix;
@end

@implementation SCGpkgTileSource

#define METERS_AT_EQUATOR 6378137
#define TILE_WIDTH 256
double const MERCATOR_OFFSET = 20037508.342789244;

@synthesize name;

- (id)initWithPool:(FMDatabasePool *)p andContent:(SCGpkgContent *)c {
  self = [super init];
  if (self) {
    self.pool = p;
    self.name = c.tableName;
    self.bbox = c.bbox;
    self.crs = c.crs;
    [self defineTable];
  }
  return self;
}

- (void)defineTable {
  NSMutableDictionary *d = [NSMutableDictionary new];
  [self.pool inDatabase:^(FMDatabase *db) {
    NSString *sql =
        [NSString stringWithFormat:
                      @"SELECT * FROM gpkg_tile_matrix WHERE table_name = '%@'",
                      self.name];
    FMResultSet *rs = [db executeQuery:sql];
    while ([rs next]) {
      [d setObject:[[SCTileMatrixRow alloc] initWithResultSet:rs]
             forKey:[NSString
                        stringWithFormat:@"%d",
                                         [rs intForColumn:@"zoom_level"]]];
    }
    [rs close];
  }];
  self.matrix = [NSDictionary dictionaryWithDictionary:d];
}

- (SCPolygon *)coveragePolygon {
  return self.bbox.polygon;
}

- (NSURL *)tile {
  return nil;
}

double metersForTile(double tile, int zoom) {
  return tile * (2 * M_PI * METERS_AT_EQUATOR) / pow(2, zoom);
}

- (void)tileForPath:(MKTileOverlayPath)path
           tileSize:(CGSize)size
             result:(void (^)(NSData *, NSError *))result {

  int tilesPerSide = pow(2, path.z);
  double tileSizeMeters = (2 * MERCATOR_OFFSET) / tilesPerSide;
  double tileMinX = (-1 * MERCATOR_OFFSET) + (path.x * tileSizeMeters);
  double tileMaxY = MERCATOR_OFFSET - (path.y * tileSizeMeters);

  double metersPerPixelX = tileSizeMeters / size.width;

  __block double minDelta = MERCATOR_OFFSET * 2;
  __block int zoomRowMatch = -1;
  [self.matrix enumerateKeysAndObjectsUsingBlock:^(
                   NSString *key, SCTileMatrixRow *r, BOOL *stop) {
    double diff = fabs(metersPerPixelX - r.pixelXSize.doubleValue);
    if (diff < minDelta) {
      minDelta = diff;
      zoomRowMatch = [key intValue];
    }
  }];

  if (zoomRowMatch == -1) {
    result(nil, nil);
    return;
  }

  double coverageUpperLeftXMeters = self.bbox.lowerLeft.x;
  double coverageUpperLeftYMeters = self.bbox.upperRight.y;
  double coverageInsetXMeters = tileMinX - coverageUpperLeftXMeters;
  double coverageInsetYMeters = coverageUpperLeftYMeters - tileMaxY;

  if (coverageInsetXMeters < 0 || coverageInsetYMeters < 0) {
    result(nil, nil);
    return;
  }

  int tileRetrieveX = round(coverageInsetXMeters / tileSizeMeters);
  int tileRetrieveY = round(coverageInsetYMeters / tileSizeMeters);

  [self.pool inDatabase:^(FMDatabase *db) {
    NSString *sql = [NSString
        stringWithFormat:@"SELECT tile_data FROM %@ WHERE zoom_level = %ld AND "
                         @"tile_column = %d AND tile_row = %d",
                         self.name, (long)path.z, tileRetrieveX, tileRetrieveY];
    FMResultSet *rs = [db executeQuery:sql];
    if ([rs next]) {
      NSData *tile = [rs dataForColumn:@"tile_data"];
      result(tile, nil);
    } else {
      result(nil, nil);
    }
    [rs close];
  }];
}

@end
