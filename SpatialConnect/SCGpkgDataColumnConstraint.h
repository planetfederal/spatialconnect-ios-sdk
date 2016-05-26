

#import <Foundation/Foundation.h>
#import "FMResultSet.h"

@interface SCGpkgDataColumnConstraint : NSObject

@property(strong, nonatomic, readonly) NSString *constraintName;
@property(strong, nonatomic, readonly) NSString *constraintType;
@property(strong, nonatomic, readonly) NSString *value;
@property(strong, nonatomic, readonly) NSNumber *min;
@property(readonly) NSInteger minIsInclusive;
@property(readonly) NSNumber *max;
@property(readonly) NSInteger maxIsInclusive;
@property(strong, readonly) NSString *desc;

- (id)initWithResultSet:(FMResultSet *)rs;

@end
