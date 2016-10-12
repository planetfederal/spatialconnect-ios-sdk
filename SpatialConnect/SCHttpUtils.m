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
  return [[SCHttpUtils
      getRequestURLAsData:url] flattenMap:^RACSignal *(NSData *d) {
    NSError *err;
    NSDictionary *dict = [[JSONDecoder decoder] objectWithData:d error:&err];
    if (err) {
      return [RACSignal error:err];
    }
    return [RACSignal return:dict];
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
  NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
  return [[NSURLConnection rac_sendAsynchronousRequest:request]
      reduceEach:^id(NSURLResponse *response, NSData *data) {
        return data;
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

@end
