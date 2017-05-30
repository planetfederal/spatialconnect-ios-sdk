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

#import "JSONKit.h"
#import "Reachability.h"
#import "SCFormFeature.h"
#import "SCGeopackageHelper.h"
#import "SCNotification.h"
#import "SCPoint+GeoJSON.h"
#import "Scmessage.pbobjc.h"
#import "SpatialConnect.h"
#import "SpatialConnectHelper.h"
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@interface SCMQTTTest : XCTestCase
@end

@implementation SCMQTTTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testMQTTConfig {
  XCTestExpectation *expect =
      [self expectationWithDescription:@"MQTTConfigTest"];

  SpatialConnect *sc = [SpatialConnect sharedInstance];

  [[[[[sc serviceRunning:[SCBackendService serviceId]]
      flattenMap:^RACStream *(id value) {
        return sc.backendService.configReceived;
      }] filter:^BOOL(NSNumber *n) {
    return [n boolValue] == YES;
  }] take:1] subscribeNext:^(id x) {
    [expect fulfill];
  }];
  [self waitForExpectationsWithTimeout:100.0
                               handler:^(NSError *err) {
                                 DDLogError(@"Error:%@", err.description);
                               }];
}

- (void)testMQTTPing {
  XCTestExpectation *expect = [self expectationWithDescription:@"MQTTPingTest"];

  SpatialConnect *sc = [SpatialConnect sharedInstance];

  [[[[[sc serviceRunning:[SCBackendService serviceId]]
      flattenMap:^RACStream *(id value) {
        return sc.backendService.configReceived;
      }] filter:^BOOL(NSNumber *n) {
    return [n boolValue] == YES;
  }] take:1] subscribeNext:^(id x) {
    Msg *msg = [[Msg alloc] init];
    msg.action = 456;
    [[sc.backendService publishReplyTo:msg onTopic:@"/ping"]
        subscribeNext:^(id x) {
          [expect fulfill];
        }
        error:^(NSError *error) {
          [expect fulfill];
        }
        completed:^{
          [expect fulfill];
        }];
  }];
  [self waitForExpectationsWithTimeout:100.0
                               handler:^(NSError *err) {
                                 DDLogError(@"Error:%@", err.description);
                               }];
}

- (void)testLocation {
  XCTestExpectation *expect = [self expectationWithDescription:@"Location"];

  SpatialConnect *sc = [SpatialConnect sharedInstance];

  SCPoint *p =
      [[SCPoint alloc] initWithCoordinateArray:@[ @(-32), @(arc4random()) ]];
  [[[[[sc serviceRunning:[SCBackendService serviceId]]
      flattenMap:^RACStream *(id value) {
        return sc.backendService.configReceived;
      }] filter:^BOOL(NSNumber *cr) {
    return [cr boolValue];
  }] take:1] subscribeNext:^(id x) {
    SCLocationStore *lStore = sc.dataService.locationStore;
    [p.properties setObject:@([[NSDate new] timeIntervalSince1970])
                     forKey:@"timestamp"];
    [p.properties setObject:@"GPS" forKey:@"accuracy"];
    [[lStore create:p] subscribeCompleted:^{
      [expect fulfill];
    }];
  }];
  [self waitForExpectationsWithTimeout:100.0 handler:nil];
}

- (void)testReachability {
  XCTestExpectation *expect = [self expectationWithDescription:@"Reachability"];

  SpatialConnect *sc = [SpatialConnect sharedInstance];

  [[sc serviceRunning:[SCSensorService serviceId]] subscribeNext:^(id value) {
    [sc.sensorService.isConnectedViaWifi subscribeNext:^(NSNumber *n) {
      XCTAssertNotNil(n);
      XCTAssertTrue([n boolValue]);
    }];
    [sc.sensorService.isConnectedViaWAN subscribeNext:^(NSNumber *x) {
      XCTAssertNotNil(x);
      XCTAssertFalse([x boolValue]);
      [expect fulfill];
    }];
  }];
  [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testGetRequest {
  XCTestExpectation *expect =
      [self expectationWithDescription:@"HTTP Ping Server"];
  SpatialConnect *sc = [SpatialConnect sharedInstance];

  NSString *url =
      [NSString stringWithFormat:@"%@/ping", sc.backendService.backendUri];
  [[[SCHttpUtils getRequestURLAsData:[NSURL URLWithString:url]] take:1]
      subscribeNext:^(NSData *d) {
        XCTAssertNotNil(d);
        [expect fulfill];
      }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (RACSignal *)formFromBackend {
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  return [[[[[[[sc serviceRunning:[SCBackendService serviceId]] materialize]
      filter:^BOOL(RACEvent *e) {
        return e.eventType == RACEventTypeCompleted;
      }] flattenMap:^RACStream *(id value) {
    return sc.backendService.configReceived;
  }] filter:^BOOL(NSNumber *cfgRec) {
    return cfgRec.boolValue;
  }] flattenMap:^RACStream *(id value) {
    return sc.dataService.formStore.hasForms;
  }] filter:^BOOL(NSNumber *hasForms) {
    return hasForms.boolValue;
  }];
}

- (void)testFormSubmission {
  XCTestExpectation *expect = [self expectationWithDescription:@"FormSubmit"];

  SpatialConnect *sc = [SpatialConnect sharedInstance];

  NSArray *arr = [sc.dataService.formStore layers];
  XCTAssertNotNil(arr);
  SCPoint *p = [[SCPoint alloc] initWithCoordinateArray:@[
    @(-22.3 + arc4random()), @(56.2 + arc4random())
  ]];

  [[[[self formFromBackend] take:1] flattenMap:^RACStream *(id value) {
    SpatialConnect *sc = [SpatialConnect sharedInstance];
    NSString *at = [NSString
        stringWithFormat:@"Token %@", [[sc authService] xAccessToken]];
    NSString *buri = [[sc backendService] backendUri];
    SCDataStore *ds = sc.dataService.formStore;
    NSNumber *fid = [sc.dataService.formStore formIdForLayer:ds.layers[0]];
    NSString *req =
        [NSString stringWithFormat:@"%@/api/form/%@/sample", buri, fid];
    NSURL *url = [NSURL URLWithString:req];
    return [SCHttpUtils getRequestURLAsDict:url
                                    headers:@{
                                      @"Authorization" : at
                                    }];
  }] subscribeNext:^(NSDictionary *dict) {
    NSLog(@"%@", dict);
    SCPoint *p = (SCPoint *)[SCGeoJSON parseDict:dict[@"result"][@"feature"]];
    SCFormFeature *f = [[SCFormFeature alloc] init];
    SCFormStore *ds = sc.dataService.formStore;
    f.layerId = ds.layers[0];
    f.storeId = ds.storeId;
    f.geometry = p;
    f.properties = p.properties;
    [[sc.dataService.formStore create:f] subscribeNext:^(id x) {
      [expect fulfill];
    }
        error:^(NSError *error) {
          DDLogError(@"%@", error.description);
          [expect fulfill];
        }
        completed:^{
          XCTAssert(YES);
          [expect fulfill];
        }];
  }];
  [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)testFormToDict {
  XCTestExpectation *expect = [self expectationWithDescription:@"Form ToDict"];

  SpatialConnect *sc = [SpatialConnect sharedInstance];

  [[[[[sc serviceRunning:[SCBackendService serviceId]]
      flattenMap:^RACStream *(id value) {
        return sc.dataService.formStore.hasForms;
      }] filter:^BOOL(NSNumber *o) {
    return [o boolValue];
  }] take:1] subscribeNext:^(id x) {
    NSArray *a = [sc.dataService.formStore formsDictionaryArray];

    XCTAssertNotNil(a);
    XCTAssertGreaterThan(a.count, 0);
    [a enumerateObjectsUsingBlock:^(NSDictionary *d, NSUInteger idx,
                                    BOOL *_Nonnull stop) {
      XCTAssertNotNil(d[@"form_key"]);
      XCTAssertNotNil(d[@"form_label"]);
      XCTAssertNotNil(d[@"version"]);
      XCTAssertNotNil(d[@"fields"]);
    }];

    [expect fulfill];
  }];
  [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

@end
