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

#import <Foundation/Foundation.h>
#import "WebViewJavascriptBridge.h"
#import "SCJavascriptBridgeAPI.h"
#import "SpatialConnect.h"

/// The domain for errors originating within `SCJavascriptBridge`.
extern NSString *const SCJavascriptBridgeErrorDomain;

@interface SCJavascriptBridge : NSObject {
  NSMutableDictionary *commands;
}

@property(strong, nonatomic) UIWebView *webview;
@property(strong, nonatomic) NSObject<UIWebViewDelegate> *webViewDelegate;
@property(strong, nonatomic) WebViewJavascriptBridge *bridge;
@property(nonatomic) SCJavascriptBridgeAPI *jsbridge;

- (id)initWithWebView:(UIWebView *)wv
             delegate:(id<UIWebViewDelegate>)del
                   sc:(SpatialConnect *)sc;

@end
