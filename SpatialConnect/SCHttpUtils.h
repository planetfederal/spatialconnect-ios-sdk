/*!
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

#import "JSONKit.h"
#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

static NSString *const XML = @"application/x-www-form-urlencoded";
static NSString *const JSON = @"application/json; charset=utf-8";

@interface SCHttpUtils : NSObject

/*!
 *  @brief returns NSDictionary on signal
 *
 *  @param url http/https resource with JSON Response
 *
 *  @return NSDictionary over RACSignal
 */
+ (RACSignal *)getRequestURLAsDict:(NSURL *)url;

+ (RACSignal *)getRequestURLAsDict:(NSURL *)url
                           headers:
                               (NSDictionary<NSString *, NSString *> *)header;

/*!
 *  @brief Blocking request to fetch an JSON Response
 *
 *  @param url http/https resource with JSON Response
 *  @param auth HTTP Basic Auth
 *  @return NSDictionary of a JSON Response
 */
+ (NSDictionary *)getRequestURLAsDictBLOCKING:(NSURL *)url auth:auth;

/*!
 *  @brief Blocking request to fetch an JSON Response
 *
 *  @param url http/https resource with JSON Response
 *
 *  @return NSDictionary of a JSON Response
 */
+ (NSDictionary *)getRequestURLAsDictBLOCKING:(NSURL *)url;

/*!
 *  @brief Blocking request to fetch data
 *
 *  @param url http/https resource
 *
 *  @return Response as NSData
 */
+ (NSData *)getRequestURLAsDataBLOCKING:(NSURL *)url;

/*!
 *  @brief returns NSData on signal
 *
 * @return NSData over RACSignal
 */
+ (RACSignal *)getRequestURLAsData:(NSURL *)url;

/*!
 HTTP Get Request

 @param url to GET request
 @param header KV of Headers
 @return NSData over RACSignal
 */
+ (RACSignal *)getRequestURLAsData:(NSURL *)url headers:(NSDictionary *)header;

/*!
 *  @brief returns NSDictionary on signal
 */
+ (RACSignal *)postRequestAsDict:(NSURL *)url body:(NSData *)data;

/*!
 *  @brief returns NSData on signal
 */
+ (RACSignal *)postRequestAsData:(NSURL *)url body:(NSData *)data;

/*!
 POST JSON Object as NSDictionary returns RACSignal with an NSDictionary

 @param url url to request
 @param dict HTTP Body JSON Params
 @return RACSignal emitting JSON Response as NSDictionary
 */
+ (RACSignal *)postDictRequestAsDict:(NSURL *)url body:(NSDictionary *)dict;

/*!
 POST JSON Object as NSDictionary returns an NSDictionary
 @warning BLOCKING request
 @param url url to request
 @param dict HTTP Body JSON Params
 @return JSON Response as NSDictionary
 */
+ (NSDictionary *)postDictRequestAsDictBLOCKING:(NSURL *)url
                                           body:(NSDictionary *)dict;

/*!
 POST request body as NSData returns an NSDictionary with Auth
 @warning BLOCKING request
 @param url url to request
 @param dict HTTP Body JSON Params
 @param auth HTTP Basic Auth
 @param contentType HTTP content-type
 @return JSON Response as NSDictionary
 */
+ (NSDictionary *)postDataRequestAsDictBLOCKING:(NSURL *)url
                                           body:(NSData *)dict
                                           auth:(NSString *)auth
                                    contentType:(NSString *)contentType;

/*!
 POST JSON Object as NSDictionary returns NSData
 @warning BLOCKING request
 @param url url to request
 @param dict HTTP Body JSON Params
 @return NSData
 */
+ (NSData *)postDictRequestBLOCKING:(NSURL *)url
                               body:(NSDictionary *)dict
                               auth:(NSString *)auth;

/*!
 POST request body as NSData returns NSData
 @warning BLOCKING request
 @param url url to request
 @param dict HTTP Body JSON Params
 @return NSData
 */
+ (NSData *)postDataRequestBLOCKING:(NSURL *)url
                               body:(NSData *)dict
                               auth:(NSString *)auth
                        contentType:(NSString *)contentType;

@end
