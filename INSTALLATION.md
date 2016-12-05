# Installation

SpatialConnect uses Carthage. To install SpatialConnect in an iOS application, add a Cartfile to the root of your project with the following dependency:

`github "boundlessgeo/spatialconnect-ios-sdk" "master"`

Next, run the following command to fetch and build SpatialConnect and all dependencies:

`carthage update --platform iOS`

From the Carthage/Build/iOS folder, drag the following frameworks into the General -> Embedded Binaries section of your project file in Xcode:

- CocoaLumberjack.framework
- JWT_iOS_Framework.framework
- libgpkgios.framework
- MQTTFramework.framework
- ReactiveCocoa.framework
- SpatialConnect.framework
- wkb_ios.framework
- ZipZap.framework

Next, go to Build Settings for your project and add a Header Search Path value for the following path, and select recursive:

`$(SRCROOT)/Carthage/Checkouts/spatialconnect-ios-sdk/include`

Finally, import the SpatialConnect header:

`#import <SpatialConnect/SpatialConnect.h>`