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

#import "SCFileUtils.h"
#import "SCGeopackageHelper.h"
#import "SpatialConnect.h"
#import "SpatialConnectHelper.h"
#import <XCTest/XCTest.h>

@interface SCCacheTest : XCTestCase
@property(nonatomic) SpatialConnect *sc;
@end

@implementation SCCacheTest

@synthesize sc;

- (void)setUp {
  [super setUp];
  self.sc = [SpatialConnect sharedInstance];
}

- (void)tearDown {
  [super tearDown];
  [self.sc stopAllServices];
}

- (void)testCache {
  NSString *path = [SpatialConnectHelper filePathFromSelfBundle:@"tests.scfg"];
  NSError *error;
  NSMutableDictionary *cfg = [NSMutableDictionary
      dictionaryWithDictionary:[SCFileUtils jsonFileToDict:path error:&error]];
  if (error) {
    DDLogError(@"%@", error.description);
  }

  if (cfg.count > 0) {
    SCConfig *s = [[SCConfig alloc] initWithDictionary:cfg];
    [sc.configService setCachedConfig:s];
    SCConfig *config2 = [sc.configService cachedConfig];
    XCTAssertEqual(s.stores.count, config2.stores.count);
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{
      @"id" : @"foo",
      @"name" : @"fooname",
      @"version" : @"1.0",
      @"store_type" : @"gpkg",
      @"uri" : @"http://foo.com"
    }];
    [config2 addStore:[[SCStoreConfig alloc] initWithDictionary:dict]];
    [sc.configService setCachedConfig:config2];
    SCConfig *config3 = [sc.configService cachedConfig];
    XCTAssertEqual(config3.stores.count, s.stores.count + 1);
    dict[@"name"] = @"foochange";
    [config3 updateStore:[[SCStoreConfig alloc] initWithDictionary:dict]];
    [sc.configService setCachedConfig:config3];
    SCConfig *config4 = [sc.configService cachedConfig];
    __block BOOL found = NO;
    [config4.stores enumerateObjectsUsingBlock:^(
                        SCStoreConfig *f, NSUInteger idx, BOOL *_Nonnull stop) {
      if ([f.name isEqualToString:@"foochange"]) {
        found = YES;
        *stop = YES;
      }
    }];
    XCTAssertTrue(found);
    [config4 removeStore:@"foo"];
    [sc.configService setCachedConfig:config4];
    SCConfig *config5 = [sc.configService cachedConfig];
    __block BOOL notFound = YES;
    [config5.stores
        enumerateObjectsUsingBlock:^(SCStoreConfig *obj, NSUInteger idx,
                                     BOOL *_Nonnull stop) {
          if ([obj.uniqueid isEqualToString:@"foo"]) {
            notFound = NO;
            *stop = YES;
          }
        }];
    XCTAssertTrue(notFound);
  }
}

@end
