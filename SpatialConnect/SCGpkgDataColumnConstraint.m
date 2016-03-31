

#import "SCGpkgDataColumnConstraint.h"
#import "SCGpkgDataColumnConstraintsTable.h"

@interface SCGpkgDataColumnConstraint ()

@property(strong, nonatomic, readwrite) NSString *constraintName;
@property(strong, nonatomic, readwrite) NSString *constraintType;
@property(strong, nonatomic, readwrite) NSString *value;
@property(strong, nonatomic, readwrite) NSNumber *min;
@property(nonatomic, readwrite) NSInteger minIsInclusive;
@property(strong, nonatomic, readwrite) NSNumber *max;
@property(nonatomic, readwrite) NSInteger maxIsInclusive;
@property(strong, nonatomic, readwrite) NSString *desc;

@end

@implementation SCGpkgDataColumnConstraint

- (id)initWithResultSet:(FMResultSet *)rs {
  self = [super init];
  if (self) {
    self.constraintName = [rs stringForColumn:kDCCConstraintNameColName];
    self.constraintType = [rs stringForColumn:kDCCConstraintTypeColName];
    self.value = [rs stringForColumn:kDCCValueColName];
    self.min = [NSNumber numberWithInt:[rs intForColumn:kDCCMinColName]];
    self.minIsInclusive = [rs intForColumn:kDCCMinIsInclusiveColName];
    self.max = [NSNumber numberWithInt:[rs intForColumn:kDCCMaxColName]];
    self.maxIsInclusive = [rs intForColumn:kDCCMaxIsInclusiveColName];
  }
  return self;
}

@end
