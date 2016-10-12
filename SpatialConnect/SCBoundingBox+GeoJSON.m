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

@implementation SCBoundingBox (GeoJSON)

- (NSString *)geoJSONString {
  NSError *error;
  NSData *jsonData =
      [NSJSONSerialization dataWithJSONObject:[self JSONDict]
                                      options:NSJSONWritingPrettyPrinted
                                        error:&error];

  if (!jsonData) {
    DDLogError(@"GeoJSON string generation: error: %@", error.localizedDescription);
    return @"[]";
  } else {
    return
        [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  }
}

@end
