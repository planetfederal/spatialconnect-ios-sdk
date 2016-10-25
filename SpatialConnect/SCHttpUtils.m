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

#import "SCHttpUtils.h"

@implementation SCHttpUtils

+ (RACSignal *)getRequestURLAsDict:(NSURL *)url {
  // TODO FIX
  __block NSMutableData *data = nil;
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [[SCHttpUtils getRequestURLAsData:url] subscribeNext:^(RACTuple *t) {
          [data appendData:t.first];
        }
            error:^(NSError *error) {
              [subscriber sendError:error];
            }
            completed:^{
              NSError *err;
              NSDictionary *dict =
                  [[JSONDecoder decoder] objectWithData:data error:&err];
              if (err) {
                [subscriber sendError:err];
              }
              [subscriber sendNext:dict];
              [subscriber sendCompleted];
            }];
        return nil;
      }];
}

+ (NSDictionary *)getRequestURLAsDictBLOCKING:(NSURL *)url {
  NSData *data = [self getRequestURLAsDataBLOCKING:url];
  NSDictionary *dict = [[JSONDecoder decoder] objectWithData:data];
  return dict;
}

+ (NSData *)getRequestURLAsDataBLOCKING:(NSURL *)url {
  NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
  NSURLResponse *response = nil;
  NSError *error = nil;
  NSData *data = [NSURLConnection sendSynchronousRequest:request
                                       returningResponse:&response
                                                   error:&error];
  if (error) {
    return nil;
  }
  return data;
}

+ (RACSignal *)getRequestURLAsData:(NSURL *)url {
  return [RACSignal createSignal:^(id<RACSubscriber> subscriber) {
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    NSObject<NSURLConnectionDataDelegate> *dataDelegate =
        (NSObject<NSURLConnectionDataDelegate> *)[[NSObject alloc] init];
    __block NSMutableData *data = nil;
    __block NSNumber *expectedLength = nil;
    Protocol *protocol = @protocol(NSURLConnectionDataDelegate);

    RACCompoundDisposable *disposable =
        [RACCompoundDisposable compoundDisposable];
    [disposable
        addDisposable:[[dataDelegate
                          rac_signalForSelector:@selector(connection:
                                                    didReceiveResponse:)
                                   fromProtocol:protocol]
                          subscribeNext:^(RACTuple *arguments) {
                            expectedLength = [NSNumber
                                numberWithFloat:[arguments.second
                                                        expectedContentLength]];
                            data = [NSMutableData data];
                          }]];

    [disposable
        addDisposable:[[dataDelegate
                          rac_signalForSelector:@selector(connection:
                                                      didReceiveData:)
                                   fromProtocol:protocol]
                          subscribeNext:^(RACTuple *arguments) {

                            [data appendData:arguments.second];
                            NSNumber *progress = [NSNumber
                                numberWithFloat:(float)[data length] /
                                                [expectedLength floatValue]];
                            //                                    NSDictionary
                            //                                    *d = @{
                            //                                                        @"progress": progress,
                            //                                                        @"data": data
                            //                                                        };
                            [subscriber sendNext:RACTuplePack(data, progress)];
                          }]];

    [disposable addDisposable:[[dataDelegate
                                  rac_signalForSelector:@selector(connection:
                                                            didFailWithError:)
                                           fromProtocol:protocol]
                                  subscribeNext:^(RACTuple *arguments) {
                                    [subscriber sendError:arguments.second];
                                  }]];

    [disposable
        addDisposable:[[dataDelegate
                          rac_signalForSelector:@selector(
                                                    connectionDidFinishLoading:)
                                   fromProtocol:protocol]
                          subscribeNext:^(id x) {
                            //[subscriber sendNext:data];
                            [subscriber sendCompleted];
                          }]];

    NSURLConnection *connection =
        [[NSURLConnection alloc] initWithRequest:request delegate:dataDelegate];
    [disposable addDisposable:[RACDisposable disposableWithBlock:^{
                  [connection cancel];
                }]];
    [connection start];

    return disposable;
  }];
}

+ (RACSignal *)postRequestAsDict:(NSURL *)url body:(NSData *)data {
  return [[self postRequestAsData:url
                             body:data] flattenMap:^RACStream *(NSData *data) {
    NSError *err;
    NSDictionary *dict = [[JSONDecoder decoder] objectWithData:data error:&err];
    if (err) {
      return [RACSignal error:err];
    } else {
      return [RACSignal return:dict];
    }
  }];
}

+ (RACSignal *)postRequestAsData:(NSURL *)url body:(NSData *)data {
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
  request.HTTPMethod = @"POST";
  request.HTTPBody = data;
  return [[NSURLConnection rac_sendAsynchronousRequest:request]
      reduceEach:^id(NSURLResponse *response, NSData *data) {
        return data;
      }];
}

+ (RACSignal *)postDictRequestAsDict:(NSURL *)url body:(NSDictionary *)dict {
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
  request.HTTPMethod = @"POST";
  [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  NSError *error;
  request.HTTPBody = dict.JSONData;
  if (error) {
    DDLogError(@"%@", error.description);
    return [RACSignal error:error];
  }

  return [[NSURLConnection rac_sendAsynchronousRequest:request]
      reduceEach:^id(NSURLResponse *response, NSData *data) {
        return data;
      }];
}

+ (NSData *)postDictRequestBLOCKING:(NSURL *)url body:(NSDictionary *)dict {
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
  request.HTTPMethod = @"POST";
  [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  NSError *err;
  NSURLResponse *response;
  request.HTTPBody = dict.JSONData;
  NSData *data = [NSURLConnection sendSynchronousRequest:request
                                       returningResponse:&response
                                                   error:&err];
  if (err) {
    DDLogError(@"%@", [err description]);
    return nil;
  }
  return data;
}

+ (NSDictionary *)postDictRequestAsDictBLOCKING:(NSURL *)url
                                           body:(NSDictionary *)dict {
  NSDictionary *result = nil;
  NSData *data = [self postDictRequestBLOCKING:url body:dict];
  if (data) {
    result = [[JSONDecoder decoder] objectWithData:data];
  }
  return result;
}

//- (void)download:(NSURL *)url {
//
//}
//
//
//+ (void) connection:(NSURLConnection *)connection
// didReceiveResponse:(NSURLResponse *)response {
//  [receivedData setLength:0];
//  _expectedBytes = [NSNumber numberWithFloat:[response
//  expectedContentLength]];
//}
//
//+ (void) connection:(NSURLConnection *)connection didReceiveData:(NSData
//*)data {
//  [_receivedData appendData:data];
//  float progress = [_receivedData length] /[_expectedBytes floatValue];
//  NSLog(@"dloadprogress %f", progress);
//}
//
//+ (void) connection:(NSURLConnection *)connection didFailWithError:(NSError
//*)error {
//
//}
//
//+ (NSCachedURLResponse *) connection:(NSURLConnection *)connection
// willCacheResponse:    (NSCachedURLResponse *)cachedResponse {
//  return nil;
//}
//
//+ (void) connectionDidFinishLoading:(NSURLConnection *)connection {
//
//}

@end
