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

#import "JSONKit.h"
#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface SCHttpUtils : NSObject

/*!
 *  @brief returns NSDictionary on signal
 *
 *  @param url http/https resource with JSON Response
 *
 *  @return NSDictionary over RACSignal
 */
+ (RACSignal *)getRequestURLAsDict:(NSURL *)url;

+ (NSDictionary *)getRequestURLAsDictBLOCKING:(NSURL *)url;

+ (NSData *)getRequestURLAsDataBLOCKING:(NSURL *)url;

/*!
 *  @brief returns NSData on signal
 *
 * @return NSData over RACSignal
 */
+ (RACSignal *)getRequestURLAsData:(NSURL *)url;

/*!
 *  @brief returns NSDictionary on signal
 */
+ (RACSignal *)postRequestAsDict:(NSURL *)url body:(NSData *)data;

/*!
 *  @brief returns NSData on signal
 */
+ (RACSignal *)postRequestAsData:(NSURL *)url body:(NSData *)data;

+ (RACSignal *)postDictRequestAsDict:(NSURL *)url body:(NSDictionary *)dict;

+ (NSDictionary *)postDictRequestAsDictBLOCKING:(NSURL *)url
                                           body:(NSDictionary *)dict;

+ (NSData *)postDictRequestBLOCKING:(NSURL *)url body:(NSDictionary *)dict;

@end
