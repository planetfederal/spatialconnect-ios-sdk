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

#import "SCTileMatrixRow.h"

@interface SCTileMatrixRow ()
@property(nonatomic, readwrite) NSString *tableName;
@property(nonatomic, readwrite) NSInteger zoomLevel;
@property(nonatomic, readwrite) NSInteger matrixWidth;
@property(nonatomic, readwrite) NSInteger matrixHeight;
@property(nonatomic, readwrite) NSInteger tileWidth;
@property(nonatomic, readwrite) NSInteger tileHeight;
@property(nonatomic, readwrite) NSNumber *pixelXSize;
@property(nonatomic, readwrite) NSNumber *pixelYSize;
@end

@implementation SCTileMatrixRow

- (id)initWithResultSet:(FMResultSet *)rs {
  self = [super init];
  if (self) {
    self.tableName = [rs stringForColumn:@"table_name"];
    self.zoomLevel = [rs intForColumn:@"zoom_level"];
    self.matrixWidth = [rs intForColumn:@"matrix_width"];
    self.matrixHeight = [rs intForColumn:@"matrix_height"];
    self.tileWidth = [rs intForColumn:@"tile_width"];
    self.tileHeight = [rs intForColumn:@"tile_height"];
    self.pixelXSize =
        [NSNumber numberWithDouble:[rs doubleForColumn:@"pixel_x_size"]];
    self.pixelYSize =
        [NSNumber numberWithDouble:[rs doubleForColumn:@"pixel_y_size"]];
  }
  return self;
}

@end
