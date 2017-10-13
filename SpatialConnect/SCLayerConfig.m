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

#import "SCLayerConfig.h"
#import "JSONKit.h"

static NSString *const IDENT = @"id";
static NSString *const LAYER_KEY = @"layer_key";
static NSString *const LAYER_LABEL = @"layer_label";
static NSString *const VERSION = @"version";
static NSString *const SCHEMA = @"schema";
static NSString *const FIELDS = @"fields";

@implementation SCLayerConfig

@synthesize key, label, version, fields, identifier;

- (id)initWithDict:(NSDictionary *)dict {
  self = [super init];
  if (self) {
    self.identifier = dict[IDENT];
    self.key = dict[LAYER_KEY];
    self.label = dict[LAYER_LABEL];
    self.version = [dict[VERSION] integerValue];
    if (![dict[SCHEMA] isKindOfClass:[NSNull class]]) {
      self.fields = dict[SCHEMA][FIELDS];
    }
    if (![self isValid]) {
      return nil;
    }
  }
  return self;
}

/**
 Validates form fields as valid
 
 @return BOOL YES if valid, NO if not
 */
- (BOOL)isValid {
  __block BOOL isValid = YES;
  if (!self.identifier || self.identifier.length <= 0) {
    DDLogError(@"Identifier is invalid:%@", self.identifier);
    isValid = NO;
  }
  if (!self.key || self.key.length <= 0) {
    DDLogError(@"form_key is an empty string");
    isValid = NO;
  }
  if (!self.label || self.label.length <= 0) {
    DDLogError(@"form_label is an empty string");
    isValid = NO;
  }
  if (!self.version || self.version <= 0) {
    DDLogError(@"Invalid Version number");
    isValid = NO;
  }
  
  if (self.fields.count == 0) {
    DDLogError(@"No Fields Present");
    isValid = NO;
  }
  
  [self.fields enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx,
                                            BOOL *stop) {
    NSString *fieldKey = obj[@"field_key"];
    NSString *fieldLabel = obj[@"field_label"];
    
    if (!fieldKey || fieldKey.length == 0) {
      DDLogError(@"field_key is invalid for form:%@", key);
      isValid = NO;
    }
    
    if (!fieldLabel || fieldLabel.length == 0) {
      NSLog(@"field_label is invalid for form:%@", key);
      isValid = NO;
    }
  }];
  return isValid;
}

/**
 T-Comb type to SCFormItemType
 
 @param s
 @return NSInteger as SCFormItemType
 */
- (SCFormItemType)strToFormType:(NSString *)s {
  if ([s containsString:@"string"]) {
    return SCFORM_TYPE_STRING;
  } else if ([s containsString:@"number"]) {
    return SCFORM_TYPE_NUMBER;
  } else if ([s containsString:@"boolean"]) {
    return SCFORM_TYPE_BOOLEAN;
  } else if ([s containsString:@"integer"]) {
    return SCFORM_TYPE_INTEGER;
  } else if ([s containsString:@"date"]) {
    return SCFORM_TYPE_DATE;
  } else if ([s containsString:@"slider"]) {
    return SCFORM_TYPE_SLIDER;
  } else if ([s containsString:@"photo"]) {
    return SCFORM_TYPE_PHOTO;
  } else if ([s containsString:@"counter"]) {
    return SCFORM_TYPE_COUNTER;
  } else if ([s containsString:@"select"]) {
    return SCFORM_TYPE_SELECT;
  }
  return -1;
}

/**
 @(SCFormItemType) to T-Comb
 
 @param n SCFormItemType
 @return T-Comb type
 */
- (NSString *)formTypeToStr:(NSNumber *)n {
  SCFormItemType t = [n integerValue];
  if (t == SCFORM_TYPE_STRING) {
    return @"string";
  } else if (t == SCFORM_TYPE_NUMBER) {
    return @"number";
  } else if (t == SCFORM_TYPE_BOOLEAN) {
    return @"boolean";
  } else if (t == SCFORM_TYPE_INTEGER) {
    return @"integer";
  } else if (t == SCFORM_TYPE_DATE) {
    return @"date";
  } else if (t == SCFORM_TYPE_SLIDER) {
    return @"slider";
  } else if (t == SCFORM_TYPE_PHOTO) {
    return @"photo";
  } else if (t == SCFORM_TYPE_COUNTER) {
    return @"counter";
  } else if (t == SCFORM_TYPE_SELECT) {
    return @"select";
  }
  return nil;
}

/**
 SCFormItemType to SQLType
 
 @param t SCFormItemType
 @return NSString of SQL column type
 */
- (NSString *)formTypeToSQLType:(SCFormItemType)t {
  if (t == SCFORM_TYPE_STRING) {
    return @"TEXT";
  } else if (t == SCFORM_TYPE_NUMBER) {
    return @"REAL";
  } else if (t == SCFORM_TYPE_BOOLEAN) {
    return @"INTEGER";
  } else if (t == SCFORM_TYPE_INTEGER) {
    return @"INTEGER";
  } else if (t == SCFORM_TYPE_DATE) {
    return @"DATETIME";
  } else if (t == SCFORM_TYPE_SLIDER) {
    return @"REAL";
  } else if (t == SCFORM_TYPE_PHOTO) {
    return @"TEXT";
  } else if (t == SCFORM_TYPE_COUNTER) {
    return @"INTEGER";
  } else if (t == SCFORM_TYPE_SELECT) {
    return @"TEXT";
  }
  return @"NULL";
}

/**
 Maps a t-comb type to a SQL Type
 
 @param t T-Comb type
 @return SQL Column Type
 */
- (NSString *)stringToSQLType:(NSString *)t {
  if ([t isEqualToString:@"string"]) {
    return @"TEXT";
  } else if ([t isEqualToString:@"number"]) {
    return @"REAL";
  } else if ([t isEqualToString:@"boolean"]) {
    return @"INTEGER";
  } else if ([t isEqualToString:@"date"]) {
    return @"DATETIME";
  } else if ([t isEqualToString:@"slider"]) {
    return @"REAL";
  } else if ([t isEqualToString:@"photo"]) {
    return @"TEXT";
  } else if ([t isEqualToString:@"counter"]) {
    return @"INTEGER";
  } else if ([t isEqualToString:@"select"]) {
    return @"TEXT";
  }
  return @"NULL";
}

/**
 Maps over fields and creates a Dictionary of <field_key,SQL Type>
 
 @return NSDictionary of <field key,type>
 */
- (NSDictionary *)sqlTypes {
  NSMutableDictionary *t = [NSMutableDictionary new];
  [self.fields enumerateObjectsUsingBlock:^(NSDictionary *d, NSUInteger idx,
                                            BOOL *stop) {
    NSString *fieldKey = [NSString stringWithString:d[@"field_key"]];
    NSString *type = d[@"type"];
    [t setValue:[self stringToSQLType:type] forKey:fieldKey];
  }];
  return [NSDictionary dictionaryWithDictionary:t];
}

- (NSDictionary *)dictionary {
  return @{
           LAYER_KEY : self.key,
           LAYER_LABEL : self.label,
           VERSION : @(self.version),
           SCHEMA: @{ FIELDS: self.fields },
           IDENT : self.identifier
           };
}

- (NSDictionary *)JSONDict {
  return self.dictionary;
}

- (NSString *)description {
  return self.dictionary.JSONString;
}

@end
