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
#import "SCWebAppZipLoader.h"

@interface SCLocalWebApp ()
@property SCJavascriptBridge *bridge;
- (void)loadEntryPage;
@end

@implementation SCLocalWebApp

- (id)initWithWebView:(UIWebView *)wv
             delegate:(id<UIWebViewDelegate>)d
       spatialConnect:(SpatialConnect *)scon
          andFilepath:(NSString *)fp {
  if (self = [super init]) {
    webview = wv;
    webviewDelegate = d;
    sc = scon;
    filepath = fp;
  }
  return self;
}

- (id)initWithWebView:(UIWebView *)wv
             delegate:(id<UIWebViewDelegate>)d
       spatialConnect:(SpatialConnect *)scon
           andZipFile:(NSString *)fp {

  if (self = [super init]) {
    webview = wv;
    webviewDelegate = d;
    sc = scon;
    filepath = [self zipPathToFilepath:fp];
  }
  return self;
}

- (NSString *)zipPathToFilepath:(NSString *)fp {
  return [SCWebAppZipLoader unzipFile:fp];
}

- (void)load {
  if (_bridge) {
    return;
  }
  _bridge = [[SCJavascriptBridge alloc] initWithWebView:webview
                                               delegate:webviewDelegate
                                                     sc:sc];

  [self loadEntryPage];
}

- (void)loadEntryPage {
  [webview loadRequest:[NSURLRequest
                           requestWithURL:[NSURL fileURLWithPath:filepath]]];
}

- (BOOL)webView:(UIWebView *)webView
    shouldStartLoadWithRequest:(NSURLRequest *)request
                navigationType:(UIWebViewNavigationType)navigationType {
  if ([webviewDelegate respondsToSelector:@selector
                       (webView:shouldStartLoadWithRequest:navigationType:)]) {
    return [webviewDelegate webView:webView
         shouldStartLoadWithRequest:request
                     navigationType:navigationType];
  }
  return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
  if ([webviewDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
    [webviewDelegate webViewDidStartLoad:webview];
  }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  if ([webviewDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
    [webviewDelegate webViewDidStartLoad:webview];
  }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  if ([webviewDelegate
          respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
    [webviewDelegate webView:webView didFailLoadWithError:error];
  }
}

@end
