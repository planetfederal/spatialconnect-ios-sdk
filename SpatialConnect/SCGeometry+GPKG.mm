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

#import "SCGeometry+GPKG.h"
#import "SCLineString+GPKG.h"
#import "SCMultiLineString+GPKG.h"
#import "SCMultiPoint+GPKG.h"
#import "SCMultiPolygon+GPKG.h"
#import "SCPoint+GPKG.h"
#import "SCPolygon+GPKG.h"
#import "SCBoundingBox.h"
#import "WKBGeometryTypes.h"

#import <wkb-ios/wkb_ios.h>
#import <wkb-ios/WKBByteReader.h>
#import <wkb-ios/WKBByteWriter.h>
#import <wkb-ios/WKBGeometryReader.h>
#import <wkb-ios/WKBGeometryWriter.h>
#import <wkb-ios/WKBGeometryEnvelope.h>

extern "C" {
  #import <libgpkgios/binstream.h>
  #import <libgpkgios/spatialdb.h>
  #import <libgpkgios/gpkg_geom.h>
  #import <libgpkgios/wkb.h>
}
#import <libgpkgios/boost_geom_io.hpp>

NSString * const GPKG_GEO_PACKAGE_GEOMETRY_MAGIC_NUMBER = @"GP";
NSInteger const GPKG_GEO_PACKAGE_GEOMETRY_VERSION_1 = 0;

@implementation SCGeometry (GPKG)

- (NSData *)wkb {
  NSAssert(NO, @"This is an abstract method and should be overridden");
  return nil;
}

- (WKBGeometry *)wkGeometry {
  NSAssert(NO, @"This is an abstract method and should be overridden");
  return nil;
}

+ (SCGeometry*)fromGeometryBinary:(NSData *)bytes {
  WKBByteReader * reader = [[WKBByteReader alloc] initWithData:bytes];
  BOOL empty = true;
  // Get 2 bytes as the magic number and validate
  NSString * magic = [reader readString:2];
  if(![magic isEqualToString:GPKG_GEO_PACKAGE_GEOMETRY_MAGIC_NUMBER]){
    [NSException raise:@"Invalid Magic Number" format:@"Unexpected GeoPackage Geometry magic number: %@, Expected: %@", magic, GPKG_GEO_PACKAGE_GEOMETRY_MAGIC_NUMBER];
  }

  NSNumber * version = [reader readByte];
  if([version intValue] != GPKG_GEO_PACKAGE_GEOMETRY_VERSION_1){
    [NSException raise:@"Invalid Version" format:@"Unexpected GeoPackage Geometry version: %@, Expected: %ld", version, (long)GPKG_GEO_PACKAGE_GEOMETRY_VERSION_1];
  }

  NSNumber * flags = [reader readByte];
  int flagsInt = [flags intValue];

  int reserved7 = (flagsInt >> 7) & 1;
  int reserved6 = (flagsInt >> 6) & 1;
  if (reserved7 != 0 || reserved6 != 0) {
    [NSException raise:@"GPKGGeometry Flags" format:@"Unexpected GeoPackage Geometry flags. Flag bit 7 and 6 should both be 0, 7=%d, 6=%d", reserved7, reserved6];
  }

  int emptyValue = (flagsInt >> 4) & 1;
  empty = emptyValue == 1;

  // Get the envelope contents indicator code (3-bit unsigned integer from
  // bits 3, 2, and 1)
  int envelopeIndicator = (flagsInt >> 1) & 7;
  if (envelopeIndicator > 4) {
    [NSException raise:@"Geometry Flags" format:@"Unexpected GeoPackage Geometry flags. Envelope contents indicator must be between 0 and 4. Actual: %d", envelopeIndicator];
  }

  // Get the byte order from bit 0, 0 for Big Endian and 1 for Little
  // Endian
  int byteOrderValue = flagsInt & 1;
  CFByteOrder byteOrder = byteOrderValue == 0 ? CFByteOrderBigEndian
  : CFByteOrderLittleEndian;

  [reader setByteOrder:byteOrder];

  // Read the 5th - 8th bytes as the srs id
  NSNumber *srsId = [reader readInt];

  // Read the envelope
  WKBGeometryEnvelope * envelope = nil;

  if(envelopeIndicator > 0){

    // Read x and y values and create envelope
    NSDecimalNumber * minX = [reader readDouble];
    NSDecimalNumber * maxX = [reader readDouble];
    NSDecimalNumber * minY = [reader readDouble];
    NSDecimalNumber * maxY = [reader readDouble];

    BOOL hasZ = false;
    NSDecimalNumber *  minZ = nil;
    NSDecimalNumber *  maxZ = nil;

    BOOL hasM = false;
    NSDecimalNumber *  minM = nil;
    NSDecimalNumber *  maxM = nil;

    // Read z values
    if (envelopeIndicator == 2 || envelopeIndicator == 4) {
      hasZ = true;
      minZ = [reader readDouble];
      maxZ = [reader readDouble];
    }

    // Read m values
    if (envelopeIndicator == 3 || envelopeIndicator == 4) {
      hasM = true;
      minM = [reader readDouble];
      maxM = [reader readDouble];
    }

    envelope = [[WKBGeometryEnvelope alloc] initWithHasZ:hasZ andHasM:hasM];

    [envelope setMinX:minX];
    [envelope setMaxX:maxX];
    [envelope setMinY:minY];
    [envelope setMaxY:maxY];

    if (hasZ) {
      [envelope setMinZ:minZ];
      [envelope setMaxZ:maxZ];
    }

    if (hasM) {
      [envelope setMinM:minM];
      [envelope setMaxM:maxM];
    }

  }

  // Read the Well-Known Binary Geometry if not marked as empty
  WKBGeometry *geometry = nil;
  if(!empty){
    geometry = [WKBGeometryReader readGeometryWithReader:reader];
  }

  SCGeometry *g;
  WKBGeometry *wkb = geometry;
  switch (wkb.geometryType) {
    case WKB_POINT:
      g = [[SCPoint alloc] initWithWKB:(WKBPoint *)wkb];
      break;
    case WKB_MULTIPOINT:
      g = [[SCMultiPoint alloc] initWithWKB:(WKBMultiPoint *)wkb];
      break;
    case WKB_LINESTRING:
      g = [[SCLineString alloc] initWithWKB:(WKBLineString *)wkb];
      break;
    case WKB_MULTILINESTRING:
      g = [[SCMultiLineString alloc] initWithWKB:(WKBMultiLineString *)wkb];
      break;
    case WKB_POLYGON:
      g = [[SCPolygon alloc] initWithWKB:(WKBPolygon *)wkb];
      break;
    case WKB_MULTIPOLYGON:
      g = [[SCMultiPolygon alloc] initWithWKB:(WKBMultiPolygon *)wkb];
      break;
    default:
      break;
  }

  if (g) {
    g.srsId = srsId;
  }

  return g;
}

-(NSData *)bytes
{
  WKBByteWriter * writer = [[WKBByteWriter alloc] init];

  // Write GP as the 2 byte magic number
  [writer writeString:GPKG_GEO_PACKAGE_GEOMETRY_MAGIC_NUMBER];

  // Write a byte as the version, value of 0 = version 1
  [writer writeByte:[NSNumber numberWithInteger:GPKG_GEO_PACKAGE_GEOMETRY_VERSION_1]];

  int flag = 0;

  // Add the binary type to bit 5, 0 for standard and 1 for extended
  BOOL extended = NO;
  int binaryType = extended ? 1 : 0;
  flag += (binaryType << 5);

  // Add the empty geometry flag to bit 4, 0 for non-empty and 1 for
  // empty
  BOOL empty = NO;
  int emptyValue = empty ? 1 : 0;
  flag += (emptyValue << 4);

  // Add the envelope contents indicator code (3-bit unsigned integer to
  // bits 3, 2, and 1)
  WKBGeometryEnvelope *envelope = nil;
  int envelopeIndicator = [self getIndicatorWithEnvelope:envelope];
  flag += (envelopeIndicator << 1);

  CFByteOrder byteOrder = CFByteOrderBigEndian;
  int byteOrderValue = (byteOrder == CFByteOrderBigEndian) ? 0 : 1;
  flag += byteOrderValue;

  NSNumber *flags = [NSNumber numberWithInt:flag];
  [writer writeByte:flags];
  [writer setByteOrder:byteOrder];

  // Write the 4 byte srs id int
  [writer writeInt:self.srsId];

  // Write the envelope
  if (envelope != nil) {

    // Write x and y values
    [writer writeDouble:envelope.minX];
    [writer writeDouble:envelope.maxX];
    [writer writeDouble:envelope.minY];
    [writer writeDouble:envelope.maxY];

    // Write z values
    if (envelope.hasZ) {
      [writer writeDouble:envelope.minZ];
      [writer writeDouble:envelope.maxZ];
    }

    // Write m values
    if (envelope.hasM) {
      [writer writeDouble:envelope.minM];
      [writer writeDouble:envelope.maxM];
    }
  }

  if (!empty) {
    [WKBGeometryWriter writeGeometry:[self wkGeometry] withWriter:writer];
  }
  NSData *bytes = [writer getData];
  [writer close];
  return bytes;
}

-(int) getIndicatorWithEnvelope: (WKBGeometryEnvelope *) envelope{
  int indicator = 1;
  if(envelope.hasZ){
    indicator++;
  }
  if(envelope.hasM){
    indicator += 2;
  }
  return indicator;
}

@end
