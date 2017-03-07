//
//  SCSyncableStore.h
//  SpatialConnect
//
//  Created by Frank Rowe on 2/28/17.
//  Copyright © 2017 Boundless Spatial. All rights reserved.
//

@protocol SCSyncableStore <NSObject>

@required

/*!
 RACSignal stream that sends events when a store is edited
 */
@property(nonatomic) RACMulticastConnection *storeEdited;

- (RACSignal *)push:(SCSpatialFeature *)feature;
- (RACSignal *)pushComplete:(SCSpatialFeature *)feature;
- (RACSignal *)unSynced;
- (RACSignal *)sync;
- (NSString *)syncChannel;

@end
