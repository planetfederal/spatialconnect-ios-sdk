
#import "SCGpkgFeatureSourceTable.h"

@interface SCGpkgFeatureSourceTable ()
@property(strong, nonatomic, readwrite) SCGpkgGeometryColumn *geomCol;
@end

@implementation SCGpkgFeatureSourceTable

- (id)initWithDatabase:(FMDatabase *)database geomColumn:(SCGpkgGeometryColumn *)gC {
  return nil;
}

@end
