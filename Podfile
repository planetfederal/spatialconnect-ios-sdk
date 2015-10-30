source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'

link_with 'SpatialConnect','SpatialConnectTests'

inhibit_all_warnings!

pod 'ReactiveCocoa', '2.5'
pod 'zipzap','8.0.6'

target :"SpatialConnectTests", :exclusive => true do
  pod 'spatialconnect', :path => '.'
end
