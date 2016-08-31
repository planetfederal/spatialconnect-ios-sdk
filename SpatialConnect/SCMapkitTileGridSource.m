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

#import "SCMapkitTileGridSource.h"

@implementation SCMapkitTileGridSource

- (id)init {
  if (self = [super initWithCoverageBBOX:[SCBoundingBox worldBounds]]) {
    self.key = [[NSUUID UUID] UUIDString];
  }
  return self;
}

- (void)tileForPath:(MKTileOverlayPath)path
           tileSize:(CGSize)size
             result:(void (^)(NSData *, NSError *))result {
  NSLog(@"MKGS:Tile:%lu,%lu,%lu", (unsigned long)path.x, (unsigned long)path.y,
        (unsigned long)path.z);

  CGSize sz = CGSizeMake(256, 256);
  CGRect rect = CGRectMake(0, 0, sz.width, sz.height);

  UIGraphicsBeginImageContext(sz);
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  [[UIColor blackColor] setStroke];
  CGContextSetLineWidth(ctx, 1.0);
  CGContextStrokeRect(ctx, CGRectMake(0, 0, sz.width, sz.height));
  NSString *text =
      [NSString stringWithFormat:@"X=%lu\nY=%lu\nZ=%lu", (unsigned long)path.x,
                                 (unsigned long)path.y, (unsigned long)path.z];
  [text drawInRect:rect
      withAttributes:@{
        NSFontAttributeName : [UIFont systemFontOfSize:20.0],
        NSForegroundColorAttributeName : [UIColor blackColor]
      }];
  UIImage *tileImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  NSData *tileData = UIImagePNGRepresentation(tileImage);
  result(tileData, nil);
}

@end
