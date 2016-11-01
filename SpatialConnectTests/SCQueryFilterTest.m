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

#import "SCPredicate.h"
#import "SCQueryFilter.h"
#import "SpatialConnectHelper.h"
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@interface SCQueryFilterTest : XCTestCase {
  SpatialConnect *sc;
}

@end

@implementation SCQueryFilterTest

- (void)setUp {
  [super setUp];
  sc = [SpatialConnectHelper loadConfigAndStartServices];
}

- (void)tearDown {
  [super tearDown];
  [sc stopAllServices];
}

- (void)testQueryAllStores {
  XCTestExpectation *expect = [self expectationWithDescription:@"QueryAll"];
  NSMutableArray *arr = [NSMutableArray new];
  [[[sc.dataService.hasStores filter:^BOOL(NSNumber *n) {
    return n.boolValue;
  }] take:1] subscribeNext:^(SCStoreStatusEvent *e) {
    RACSignal *result = [sc.dataService queryAllStores:nil];
    [result subscribeNext:^(SCSpatialFeature *geom) {
      [arr addObject:geom];
    }
        error:^(NSError *error) {
          XCTFail(@"Error Querying stores");
        }
        completed:^(void) {
          XCTAssert(arr.count > 0, @"Pass");
          [expect fulfill];
        }];
  }];
  [self waitForExpectationsWithTimeout:12.0 handler:nil];
}

@end
