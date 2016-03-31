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

#import <Foundation/Foundation.h>

@interface SCGpkgExtension : NSObject

@property(strong, nonatomic, readonly) NSString *tableName;
@property(strong, nonatomic, readonly) NSString *columnName;
@property(strong, nonatomic, readonly) NSString *extensionName;
@property(strong, nonatomic, readonly) NSString *definition;
@property(strong, nonatomic, readonly) NSString *scope;

- (id)initWithResultSet:(FMResultSet *)rs;

@end
