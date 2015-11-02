source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'

link_with 'SpatialConnect','SpatialConnectTests'

pod 'ReactiveCocoa', '2.5'
pod 'zipzap','8.0.6'
pod 'geopackage-ios', :git => 'https://github.com/boundlessgeo/geopackage-ios.git'
pod 'geopackage-wkb-ios', :git => 'https://github.com/boundlessgeo/geopackage-wkb-ios.git'

target :'SpatialConnectTests', :exclusive => true do
  pod 'spatialconnect', :path => '.'
end
