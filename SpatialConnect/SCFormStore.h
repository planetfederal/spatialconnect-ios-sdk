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

#import "GeopackageStore.h"
#import "SCFormConfig.h"
#import "SCSpatialStore.h"
#import <Foundation/Foundation.h>

@interface SCFormStore
    : GeopackageStore <SCDataStoreLifeCycle, SCSpatialStore> {
  NSMutableDictionary *formIds;
  NSMutableDictionary *storeForms;
}

@property(readonly, strong) RACBehaviorSubject *hasForms;

- (void)registerFormByConfig:(SCFormConfig *)f;
- (void)updateFormByConfig:(SCFormConfig *)f;
- (void)unregisterFormByConfig:(SCFormConfig *)f;
- (void)unregisterFormByKey:(NSString *)k;
- (NSArray *)formsDictionaryArray;

@end
