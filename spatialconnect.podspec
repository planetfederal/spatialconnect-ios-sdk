Pod::Spec.new do |s|
    s.name          = "spatialconnect"
    s.version       = "1.0.0"
    s.summary       = "SpatialConnect iOS library"
    s.description   = <<-DESC
                        SpatialConnect iOS Library
                        DESC
    s.homepage      = "http://github.com/boundlessgeo/spatialconnect-ios"
    s.license       = "Apache 2.0"
    s.author        = { "BoundlessGeo" => "wrichardet@boundlessgeo.com" }
    s.source        = { :git => "https://github.com/boundlessgeo/spatialconnect-ios", :tag => s.version.to_s }

    s.platform      = :ios, '8.0'
    s.ios.deployment_target = '8.0'
    s.requires_arc = true

    s.source_files = 'SpatialConnect/**/*.{h,m}'
    s.public_header_files = 'SpatialConnect/**/*.h'
    s.prefix_header_file = 'SpatialConnect/SpatialConnect-Prefix.h'
    non_arc_files = 'SpatialConnect/Vendor/JSONKit/JSONKit.m'
    s.subspec 'no-arc' do |sna|
        sna.requires_arc = false
        sna.source_files = non_arc_files
    end
    s.frameworks = 'Foundation'
end
