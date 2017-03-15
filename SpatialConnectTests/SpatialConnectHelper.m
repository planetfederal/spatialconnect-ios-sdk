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

NSString *wfsStore = @"71522e9b-3ec6-48c3-8d5c-57c8d14baf6a";
NSString *geojsonStore = @"a5d93796-5026-46f7-a2ff-e5dec85d116c";
NSString *gpkgStore = @"f6dcc750-1349-46b9-a324-0223764d46d1";

+ (SpatialConnect *)loadLocalConfig {
  [self moveTestBundleToDocsDir];
  NSString *filePath =
      [[NSBundle bundleForClass:[self class]] pathForResource:@"tests"
                                                       ofType:@"scfg"];
  BOOL b = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
  DDLogVerbose(@"LocalConfigPath:", filePath);
  if (!b) {
    DDLogError(@"No config at:%@", filePath);
  }
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  [sc.configService addConfigFilepath:filePath];
  NSURL *URL = [NSURL URLWithString:@"https://portal.opengeospatial.org"];

  [NSURLRequest
          .class performSelector:NSSelectorFromString(
                                     @"setAllowsAnyHTTPSCertificate:forHost:")
                      withObject:NSNull.null // Just need to pass non-nil here
                                             // to appear as a BOOL YES, using
                                             // the NSNull.null singleton is
                                             // pretty safe
                      withObject:[URL host]];

  NSURL *URL2 = [NSURL URLWithString:@"https://s3.amazonaws.com"];

  [NSURLRequest
          .class performSelector:NSSelectorFromString(
                                     @"setAllowsAnyHTTPSCertificate:forHost:")
                      withObject:NSNull.null // Just need to pass non-nil here
                      // to appear as a BOOL YES, using
                      // the NSNull.null singleton is
                      // pretty safe
                      withObject:[URL2 host]];

  return sc;
}

+ (SpatialConnect *)loadConfigAndStartServices {
  SpatialConnect *sc = [SpatialConnectHelper loadLocalConfig];
  [sc startAllServices];
  return sc;
}

+ (SpatialConnect *)loadRemoteConfig {
  [self moveTestBundleToDocsDir];
  NSString *filePath =
      [[NSBundle bundleForClass:[self class]] pathForResource:@"remote"
                                                       ofType:@"scfg"];
  DDLogInfo(@"RemoteConfigPath:%@", filePath);
  SpatialConnect *sc = [[SpatialConnect alloc] init];
  [sc.configService addConfigFilepath:filePath];
  NSURL *URL = [NSURL URLWithString:@"https://portal.opengeospatial.org"];

  [NSURLRequest
          .class performSelector:NSSelectorFromString(
                                     @"setAllowsAnyHTTPSCertificate:forHost:")
                      withObject:NSNull.null // Just need to pass non-nil here
                      // to appear as a BOOL YES, using
                      // the NSNull.null singleton is
                      // pretty safe
                      withObject:[URL host]];

  NSURL *URL2 = [NSURL URLWithString:@"https://s3.amazonaws.com"];

  [NSURLRequest
          .class performSelector:NSSelectorFromString(
                                     @"setAllowsAnyHTTPSCertificate:forHost:")
                      withObject:NSNull.null // Just need to pass non-nil here
                      // to appear as a BOOL YES, using
                      // the NSNull.null singleton is
                      // pretty safe
                      withObject:[URL2 host]];

  return sc;
}

+ (RACSignal *)loadWFSGDataStore:(SpatialConnect *)sc {
  return [[sc.dataService storeStarted:wfsStore]
      map:^SCDataStore *(SCStoreStatusEvent *evt) {
        return [sc.dataService storeByIdentifier:wfsStore];
      }];
}

+ (RACSignal *)loadGeojsonDataStore:(SpatialConnect *)sc {
  return [[sc.dataService storeStarted:geojsonStore]
      map:^SCDataStore *(SCStoreStatusEvent *evt) {
        return [sc.dataService storeByIdentifier:geojsonStore];
      }];
}

+ (RACSignal *)loadFormStore:(SpatialConnect *)sc {
  return [[sc.dataService storeStarted:@"FORM_STORE"]
          map:^SCDataStore *(SCStoreStatusEvent *evt) {
            return [sc.dataService storeByIdentifier:@"FORM_STORE"];
          }];
}

+ (RACSignal *)loadGeopackageStore:(SpatialConnect *)sc {
  return [[sc.dataService storeStarted:gpkgStore]
          map:^SCDataStore *(SCStoreStatusEvent *evt) {
            return [sc.dataService storeByIdentifier:gpkgStore];
          }];
}

+ (SpatialConnect *)loadRemoteConfigAndStartServices {
  SpatialConnect *sc = [SpatialConnectHelper loadRemoteConfig];
  return sc;
}

+ (void)moveTestBundleToDocsDir {
  NSString *path = [[NSBundle bundleForClass:[self class]] resourcePath];
  NSFileManager *fm = [NSFileManager defaultManager];
  NSError *error = nil;
  NSArray *directoryAndFileNames =
      [fm contentsOfDirectoryAtPath:path error:&error];

  NSURL *documentsPath = [[[NSFileManager defaultManager]
      URLsForDirectory:NSDocumentDirectory
             inDomains:NSUserDomainMask] lastObject];

  [directoryAndFileNames enumerateObjectsUsingBlock:^(
                             NSString *fileName, NSUInteger idx, BOOL *stop) {
    if ([fileName containsString:@"scfg"] ||
        [fileName containsString:@"json"] ||
        [fileName containsString:@"geojson"] ||
        [fileName containsString:@"gpkg"]) {
      NSString *item = [NSString stringWithFormat:@"%@/%@", path, fileName];
      NSString *to =
          [NSString stringWithFormat:@"%@/%@", [documentsPath path], fileName];
      NSError *error;
      [fm copyItemAtPath:item toPath:to error:&error];
      if (error) {
        if (error.code != 516) {
          DDLogError(@"Error: %@", error.description);
        }
      }
    }
  }];
}

+ (NSString *)filePathFromSelfBundle:(NSString *)fileName {
  NSArray *strs = [fileName componentsSeparatedByString:@"."];
  NSString *filePrefix;
  if (strs.count == 2) {
    filePrefix = strs.firstObject;
  } else {
    filePrefix = [[strs
        objectsAtIndexes:[NSIndexSet
                             indexSetWithIndexesInRange:NSMakeRange(
                                                            0, strs.count - 2)]]
        componentsJoinedByString:@"."];
  }
  NSString *extension = [strs lastObject];
  NSString *filePath =
      [[NSBundle bundleForClass:[self class]] pathForResource:filePrefix
                                                       ofType:extension];
  return filePath;
}

- (void)startServicesAndAuth:(SpatialConnect *)sc {
  [sc.authService authenticate:@"admin@something.com" password:@"admin"];
}

@end
