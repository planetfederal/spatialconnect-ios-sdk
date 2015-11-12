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

#import "SpatialConnectHelper.h"

@implementation SpatialConnectHelper

+ (SpatialConnect *)loadConfig {
  [SpatialConnectHelper moveTestBundleToDocsDir];
  NSString *filePath =
      [[NSBundle bundleForClass:[self class]] pathForResource:@"tests"
                                                       ofType:@"scfg"];
  SpatialConnect *sc = [[SpatialConnect alloc] initWithFilepath:filePath];
  return sc;
}

+ (SpatialConnect *)loadConfigAndStartServices {
  SpatialConnect *sc = [SpatialConnectHelper loadConfig];
  [sc startAllServices];
  return sc;
}

+ (void)moveTestBundleToDocsDir {
  NSString *path = [[NSBundle bundleForClass:[self class]] resourcePath];
  NSFileManager *fm = [NSFileManager defaultManager];
  NSError *error = nil;
  NSArray *directoryAndFileNames =
      [fm contentsOfDirectoryAtPath:path error:&error];

  NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(
      NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  [directoryAndFileNames enumerateObjectsUsingBlock:^(NSString *fileName,
                                                      NSUInteger idx,
                                                      BOOL *stop) {
    if ([fileName containsString:@"scfg"] ||
        [fileName containsString:@"json"] ||
        [fileName containsString:@"geojson"]) {
      NSError *error;
      [fm copyItemAtPath:[NSString stringWithFormat:@"%@/%@", path, fileName]
                  toPath:[NSString
                             stringWithFormat:@"%@/%@", documentsPath, fileName]
                   error:&error];
    }
  }];
}

@end
