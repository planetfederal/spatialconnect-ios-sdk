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
  [self moveTestBundleToDocsDir];
  NSString *filePath =
      [[NSBundle bundleForClass:[self class]] pathForResource:@"tests"
                                                       ofType:@"scfg"];
  BOOL b = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
  NSLog(@"LocalConfigPath:%@", filePath);
  if (!b) {
    NSLog(@"No config at:%@", filePath);
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
  SpatialConnect *sc = [SpatialConnectHelper loadConfig];
  [sc startAllServices];
  return sc;
}

+ (SpatialConnect *)loadRemoteConfig {
  [self moveTestBundleToDocsDir];
  NSString *filePath =
      [[NSBundle bundleForClass:[self class]] pathForResource:@"remote"
                                                       ofType:@"scfg"];
  NSLog(@"RemoteConfigPath:%@", filePath);
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

+ (RACSignal *)loadWFSGDataStore:(SpatialConnect *)sc
                         storeId:(NSString *)storeId {
  return [[sc.dataService storeStarted:storeId]
      map:^SCDataStore *(SCStoreStatusEvent *evt) {
        SCDataStore *ds = [sc.dataService storeByIdentifier:storeId];
        return ds;
      }];
}

+ (SpatialConnect *)loadRemoteConfigAndStartServices {
  SpatialConnect *sc = [SpatialConnectHelper loadRemoteConfig];
  [sc startAllServices];
  return sc;
}

+ (void)moveTestBundleToDocsDir {
  NSString *path = [[NSBundle bundleForClass:[self class]] resourcePath];
  NSFileManager *fm = [NSFileManager defaultManager];
  NSError *error = nil;
  NSArray *directoryAndFileNames =
      [fm contentsOfDirectoryAtPath:path error:&error];

  NSString *documentsPath = NSHomeDirectory();
  [directoryAndFileNames enumerateObjectsUsingBlock:^(
                             NSString *fileName, NSUInteger idx, BOOL *stop) {
    if ([fileName containsString:@"scfg"] ||
        [fileName containsString:@"json"] ||
        [fileName containsString:@"geojson"]) {
      NSString *item = [NSString stringWithFormat:@"%@/%@", path, fileName];
      NSString *to =
          [NSString stringWithFormat:@"%@/%@", documentsPath, fileName];
      NSError *error;
      [fm copyItemAtPath:item toPath:to error:&error];
      if (error) {
        if (error.code != 516) {
          NSLog(@"Error: %@", error.description);
        }
      }
    }
  }];
}

- (void)startServicesAndAuth:(SpatialConnect *)sc {
  [sc startAllServices];
  [sc.authService authenticate:@"admin@something.com" password:@"admin"];
}

@end
