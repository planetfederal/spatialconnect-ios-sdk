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

#import "SCStyle.h"

@implementation SCStyle

@synthesize strokeColor = _strokeColor;
@synthesize strokeOpacity = _strokeOpacity;
@synthesize strokeWidth = _strokeWidth;
@synthesize fillColor = _fillColor;
@synthesize fillOpacity = _fillOpacity;
@synthesize iconColor = _iconColor;

- (id)initWithMapboxStyle:(NSArray *)mbstyle {
  self = [self init];
  if (!self) {
    return nil;
  }
  for (NSDictionary *s in mbstyle) {
    NSDictionary *paint = s[@"paint"];
    if (paint) {
      if (paint[@"line-color"])
        _strokeColor = paint[@"line-color"];
      if (paint[@"line-opacity"])
        _strokeOpacity = [paint[@"line-opacity"] floatValue];
      if (paint[@"fill-color"])
        _fillColor = paint[@"fill-color"];
      if (paint[@"fill-opacity"])
        _fillOpacity = [paint[@"fill-opacity"] floatValue];
      if (paint[@"icon-color"])
        _iconColor = paint[@"icon-color"];
    }
  }
  return self;
}

- (UIColor *)strokeColor {
  if (!_strokeColor) {
    return [UIColor redColor];
  }
  return _strokeColor;
}

- (int)strokeWidth {
  if (!_strokeWidth) {
    return 2;
  }
  return _strokeWidth;
}

- (float)strokeOpacity {
  if (!_strokeOpacity) {
    return 1;
  }
  return _strokeOpacity;
}

- (float)fillOpacity {
  if (!_fillOpacity) {
    return 0.5;
  }
  return _fillOpacity;
}

- (UIColor *)fillColor {
  if (!_fillColor) {
    return [UIColor redColor];
  }
  return _fillColor;
}

- (UIColor *)iconColor {
  if (!_iconColor) {
    return [UIColor redColor];
  }
  return _iconColor;
}

- (void)addMissing:(SCStyle *)style {
  if (!_strokeColor)
    self.strokeColor = style.strokeColor;
  if (!_strokeWidth)
    self.strokeWidth = style.strokeWidth;
  if (!_strokeOpacity)
    self.strokeOpacity = style.strokeOpacity;
  if (!_fillOpacity)
    self.fillOpacity = style.fillOpacity;
  if (!_fillColor)
    self.fillColor = style.fillColor;
  if (!_iconColor)
    self.iconColor = style.iconColor;
}

- (void)overwriteWith:(SCStyle *)style {
  if (style.strokeColor)
    self.strokeColor = style.strokeColor;
  if (style.strokeWidth)
    self.strokeWidth = style.strokeWidth;
  if (style.strokeOpacity)
    self.strokeOpacity = style.strokeOpacity;
  if (style.fillOpacity)
    self.fillOpacity = style.fillOpacity;
  if (style.fillColor)
    self.fillColor = style.fillColor;
  if (style.iconColor)
    self.iconColor = style.iconColor;
}

- (NSDictionary *)dictionary {
  return @{
    @"strokeColor" : self.strokeColor,
    @"strokeWidth" : [@(self.strokeWidth) stringValue],
    @"strokeOpacity" : [@(self.strokeOpacity) stringValue],
    @"fillOpacity" : [@(self.fillOpacity) stringValue],
    @"fillColor" : self.fillColor,
    @"iconColor" : self.iconColor
  };
}

@end
