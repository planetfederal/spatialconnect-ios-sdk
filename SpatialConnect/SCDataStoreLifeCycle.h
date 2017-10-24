/*!***************************************************************************
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
#import <ReactiveCocoa/ReactiveCocoa.h>

@protocol SCDataStoreLifeCycle <NSObject>

@required

/*!
 Starts a store

 @return Returns a RACSignal that emits when the store starts successfully
 */
- (RACSignal *)start;

/*!
 Stops a started store
 */
- (void)stop;

/*!
 @description Stops the Data Store and cleans resources on the file system
 */
- (void)destroy;

@optional

/*!
 Starts a paused store
 */
- (void)resume;

/*!
 Pauses a started store
 */
- (void)pause;

@end
