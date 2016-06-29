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

#import "SCFileUtils.h"
#import "SCGeoJSONExtensions.h"
#import "SCJavascriptBridge.h"
#import "SCJavascriptCommands.h"
#import "SCSpatialStore.h"
#import "SpatialConnect.h"
#import "WebViewJavascriptBridge.h"
#import "SCJavascriptBridgeAPI.h"

NSString *const SCJavascriptBridgeErrorDomain =
    @"SCJavascriptBridgeErrorDomain";

@interface SCJavascriptBridge ()
@property SpatialConnect *spatialConnect;
- (void)setupBridge;
@end

@implementation SCJavascriptBridge

@synthesize webview;
/**
 * This initialization should be called from the UI's
 * viewDidLoad lifecycle. The _bridge will be bound to
 * the UI
 **/
- (id)initWithWebView:(UIWebView *)wv
             delegate:(id<UIWebViewDelegate>)del
                   sc:(SpatialConnect *)sc {
  if (self = [super init]) {
    commands = [NSMutableDictionary new];
    self.webview = wv;
    self.webViewDelegate = del;
    self.spatialConnect = sc;
    self.jsbridge = [[SCJavascriptBridgeAPI alloc] init];
    [self setupBridge];
  }
  return self;
}

#pragma mark -
#pragma mark Private Methods

- (void)setupBridge {
    self.bridge = [WebViewJavascriptBridge
        bridgeForWebView:self.webview
        webViewDelegate:self.webViewDelegate
        handler:^(id data, WVJBResponseCallback responseCallback) {
           [[self.jsbridge parseJSCommand:data] subscribeNext:^(NSDictionary *responseData) {
               NSLog(@"Response");
               NSLog(@"%@", responseData);
               [_bridge callHandler:responseData[@"action"] data:responseData[@"payload"]];
           }];
        }];

    [self.spatialConnect.sensorService enableGPS];
    [self.spatialConnect.sensorService.lastKnown subscribeNext:^(CLLocation *loc) {
        CLLocationDistance alt = loc.altitude;
        float lat = loc.coordinate.latitude;
        float lon = loc.coordinate.longitude;
        [_bridge callHandler:@"lastKnownLocation" data:@{
            @"latitude": [NSNumber numberWithFloat:lat],
            @"longitude": [NSNumber numberWithFloat:lon],
            @"altitude": [NSNumber numberWithFloat:alt]
        }];
    }];
}

@end
