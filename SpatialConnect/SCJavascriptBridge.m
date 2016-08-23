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

#import "Commands.h"
#import "SCFileUtils.h"
#import "SCGeoJSONExtensions.h"
#import "SCJavascriptBridge.h"
#import "SCJavascriptBridgeAPI.h"
#import "SCJavascriptCommands.h"
#import "SCNotification.h"
#import "SCSpatialStore.h"
#import "SpatialConnect.h"
#import "WebViewJavascriptBridge.h"

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
               handler:^(id action, WVJBResponseCallback responseCallback) {
                 [[self.jsbridge parseJSAction:action]
                     subscribeNext:^(NSDictionary *payload) {
                       NSLog(@"Response");
                       NSLog(@"%@", payload);
                       NSDictionary *newAction = @{
                         @"type" : action[@"type"],
                         @"payload" : payload
                       };
                       [_bridge callHandler:action[@"type"] data:newAction];
                     }];
               }];

  [self.spatialConnect.sensorService enableGPS];
  [self.spatialConnect.sensorService.lastKnown
      subscribeNext:^(CLLocation *loc) {
        CLLocationDistance alt = loc.altitude;
        float lat = loc.coordinate.latitude;
        float lon = loc.coordinate.longitude;
        NSDictionary *action = @{
          @"type" : @"lastKnownLocation",
          @"payload" : @{
            @"latitude" : [NSNumber numberWithFloat:lat],
            @"longitude" : [NSNumber numberWithFloat:lon],
            @"altitude" : [NSNumber numberWithFloat:alt]
          }
        };
        [_bridge callHandler:@"lastKnownLocation" data:action];
      }];
  [[self.spatialConnect.authService loginStatus] subscribeNext:^(
                                                     NSNumber *authStatus) {
    NSDictionary *action = @{
      @"type" : [@(AUTHSERVICE_LOGIN_STATUS) stringValue],
      @"payload" : authStatus
    };
    [_bridge callHandler:[@(AUTHSERVICE_LOGIN_STATUS) stringValue] data:action];
  }];

  [[self.spatialConnect.backendService notifications]
      subscribeNext:^(SCMessage *msg) {
        SCNotification *notif = [[SCNotification alloc] initWithMessage:msg];
        [_bridge callHandler:@"notification" data:[notif dictionary]];
      }];
}

@end
