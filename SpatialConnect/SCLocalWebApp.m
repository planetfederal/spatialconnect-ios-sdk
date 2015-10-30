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

#import "SCLocalWebApp.h"
#import "SCJavascriptBridge.h"

@interface SCLocalWebApp ()
@property SCJavascriptBridge *bridge;
- (void)loadEntryPage;
@end

@implementation SCLocalWebApp

- (id)initWithWebView:(UIWebView *)wv
             delegate:(id<UIWebViewDelegate>)d
          andFilepath:(NSString *)fp {
  if (self = [super init]) {
    webview = wv;
    filepath = fp;
  }
  return self;
}

- (id)initWithWebView:(UIWebView *)wv
             delegate:(id<UIWebViewDelegate>)d
           andZipFile:(NSString *)fp {

  if (self = [super init]) {
    webview = wv;
    filepath = fp;
  }
  return self;
}

- (void)load {
  if (_bridge) {
    return;
  }
  _bridge = [[SCJavascriptBridge alloc]
      initWithWebView:webview
             delegate:self
                   sc:[SpatialConnect sharedInstance]];

  [self loadEntryPage];
}

- (void)loadEntryPage {
  [webview loadRequest:[NSURLRequest
                           requestWithURL:[NSURL fileURLWithPath:filepath]]];
}

- (BOOL)webView:(UIWebView *)webView
    shouldStartLoadWithRequest:(NSURLRequest *)request
                navigationType:(UIWebViewNavigationType)navigationType {
  if ([delegate respondsToSelector:@selector(webView:
                                       shouldStartLoadWithRequest:
                                                   navigationType:)]) {
    return [delegate webView:webView
        shouldStartLoadWithRequest:request
                    navigationType:navigationType];
  }
  return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
  if ([delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
    [delegate webViewDidStartLoad:webview];
  }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  if ([delegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
    [delegate webViewDidStartLoad:webview];
  }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  if ([delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
    [delegate webView:webView didFailLoadWithError:error];
  }
}

@end
