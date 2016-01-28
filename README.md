# SpatialConnect iOS Library

# Overview

SpatialConnect is a collection of libraries that makes it easier for developers to write
apps that connect to multiple spatial data stores online and offline. It leverages [Github's ReactiveCocoa](http://github.com/reactivecocoa/reactivecocoa/) for communicating with the data stores using a common API across [iOS](https://github.com/boundlessgeo/spatialconnect-ios-sdk), [Android](https://github.com/boundlessgeo/spatialconnect-android-sdk), and [Javascript](https://github.com/boundlessgeo/spatialconnect-js) runtimes.
 
This library provides native APIs for iOS as well as a Javascript bridge to communicate to the native API from mobile browsers.   The SpatialConnect iOS SDK is packaged as a library and can be imported as a dependency to your iOS app.

## Core Concepts
All services and data stores in SpatialConnect provide an API that returns an [Observable](http://reactivex.io/documentation/observable.html) that emits data or events for subscribers to consume. 

### Services and the ServiceManager
SpatialConnect consists of a collection of services which each handle specific functionality.  For instance, the `SCDataService` handles reads and writes to data stores while the `SCSensorService` handles subscribing to and reciving GPS updates.  All services are managed by the `SCServiceManager` which is responsible for loading a configuration file that will initialize the services and data stores.

Currently there are 3 services, the `SCDataService`, the `SCNetworkService`, and the `SCSensorService`.  The `SCServiceManager` is responsible for managing the service lifecycle (registering them, starting/stopping them, etc).  When you create an instance of the `SCServiceManager`, it will enable all the services and read the configuration file to determine what to do next.  If data stores are defined, it will attempt to register each store with the `SCDataService`.


### Store Lifecycle

In the SCDataService there is an NSDictionary named 'supportedStores'. The this will contain a Class distinguished by key TYPE.VERSION (i.e. geojson.1). These can be added to the data service after SpatialConnect has been instantiated. When SCDataService starts, it will instantiate the appropriate version and type stored in the 'supportedStores' dictionary. 

### Web Bundles

Web Bundles zip files containing a webapp with the entry point being 'index.html'. A zip file placed in the Application's Documents directory will be scanned on load, check for zips containing an 'index.html', and will load that 'index.html' in a 'UIWebView'.

The data store needs an adapter to connect to the underlying data source (a GeoJson file, a GeoPackage database, a CSV file, etc), therefore you must also create a class that extends SCDataAdapter.  The adapter will manage connecting and disconecting to the data source as well as the actual I/O to the data source.  The adapter will use the uri defined in the config to connect to the data source.  If the uri is remote, then it will download from the location and store it locally (at least for a geopackage).  

### Store Configuration
The stores array will load the stores on start in no guaranteed order. The configuration files will have an extension of ".scfg". SpatialConnect can support multiple configs and will be loaded in no guaranteed order.

#### type ####
SpatialConnect will support geojson and geopackage
#### version ####
This is the version of adapter that SpatialConnect will use "geojson.1" will be the identifier for version 1 of the GeoJSONStore
#### uri ####
This is the filepath to the resource relative to the config file location.
#### id ####
This unique identifier can be generated online [here](https://guidgenerator.com) or using any other unique identifier. Identifiers are not required by SpatialConnect to be a hash. If there is a collision between identifiers, the last loaded store will overwrite all previously loaded stores with the same identifier. 

    {
      "stores":[
        {
            "type": "geojson",
            "version": "1",
            "uri": "simple.geojson",
            "id":"63602599-3ad3-439f-9c49-3c8a7579933b"
        },
        {
            "type": "geojson",
            "version": "1",
            "uri": "feature.geojson",
            "id":"276d2186-24f4-11e5-b345-feff819cdc9f"
        },   
		{
			"type":"gpkg",
			"version":"1",
			"name":"Haiti",
			"uri":"http://www.geopackage.org/data/haiti-vectors-split.gpkg",
			"id":"a5d93796-5026-46f7-a2ff-e5dec85heh6b"
		},
		{
			"type":"gpkg",
			"version":"1",
			"name":"Whitehorse Imagery",
			"uri":"https://portal.opengeospatial.org/files/63156",
			"id":"ba293796-5026-46f7-a2ff-e5dec85heh6b"
		}
      ]
    }


### Data Stores and the DataService
The `SCDataService` is responsible for interacting with the data stores.  All data stores must implement the `SCSpatialStore` interface which provides methods to interact with the data store.  Here's what it looks like:
```
- (RACSignal *)query:(SCQueryFilter *)filter;
- (RACSignal *)queryById:(SCKeyTuple *)key;
- (RACSignal *)create:(SCSpatialFeature *)feature;
- (RACSignal *)update:(SCSpatialFeature *)feature;
- (RACSignal *) delete:(SCKeyTuple *)key;
```
Implementations exist for GeoJSON (read only) and GeoPackage (read write) data stores but to 
create a new data store developers need to create a class that implements this interface and update a configuration file to let SpatialConnect know
that the store exists.

> Don't worry about SCQueryFilter, SCKeyTuple, or SCSpatialFeature for now...keep reading and you'll learn about them soon!
#### How to create a new data store
To create a new data store you need to create a class that extends `SCDataStore`.  Then you must update the config file `config.scfg` with the store's name, type, and an optional version for the store type (eg. when WMS is the store type, 1.1.0 is an example version).

Here's an example config file:

```
{
  "stores":[
    {
      "type": "geojson",
      "version": "1",
      "uri": "all.geojson",
      "isMainBundle":true,
      "id":"63602599-3ad3-439f-9c49-3c8a7579933b",
      "name":"Simple"
    },
    {
      "type":"gpkg",
      "version":"1",
      "name":"Haiti",
      "uri":"https://s3.amazonaws.com/test.spacon/haiti4mobile.gpkg",
      "id":"a5d93796-5026-46f7-a2ff-e5dec85heh6b"
    },
    {
      "type":"gpkg",
      "version":"1",
      "name":"Whitehorse",
      "uri":"https://s3.amazonaws.com/test.spacon/whitehorse.gpkg",
      "id":"ba293796-5026-46f7-a2ff-e5dec85heh6b"
    }
  ]
}
```
Config files end with the extension scfg.

### Querying for features

There are a few different ways to query for features but the main idea is to create an `SCQueryFilter` with `SCPredicate`s and pass it to a query function.  All data stores will have query functions and the the `SCDataService` provides convenience methods for querying across all the data stores.

Let's see how this works with an example.  Let's say you want to query for all features that exist within a specific bounding box.  You would first need to build an `SCQueryFilter` with an`SCPredicate` that uses a `SCBoundingBox` like this:

```
SCBoundingBox *bbox = [[SCBoundingBox alloc] init];
[bbox setUpperRight:[SCPoint pointFromCLLocationCoordinate2D:neCoord]];
[bbox setLowerLeft:[SCPoint pointFromCLLocationCoordinate2D:swCoord]];

SCGeoFilterContains *gfc = [[SCGeoFilterContains alloc] initWithBBOX:bbox];
SCPredicate *predicate = [[SCPredicate alloc] initWithFilter:gfc];
[filter addPredicate:predicate];
```

Now to query across all stores for features in that bounding box, we can use the data service like this:

```
AppDelegate *ad = [[UIApplication sharedApplication] delegate];
SpatialConnect *sc = [ad spatialConnectSharedInstance];
@weakify(self);
[[[[self.sc.manager.dataService queryAllStores:filter]
	map:^SCGeometry *(SCGeometry *geom) {
   		if ([geom isKindOfClass:SCGeometry.class]) {
   			geom.style = [styleDict objectForKey:geom.key.storeId];
   		}
   		return geom;
   	}] deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(SCGeometry *g) {
   		@strongify(self);
   		[g addToMap:self.mapView];
   	} completed:^{
   		self.buttonSearch.enabled = YES;
   	}
];
```
The `queryAllStores` method returns a Signal stream of `SCSpatialFeature`s that are added to the map as the subscriber receives them.

In addition to using `SCPredicate`s to query, you can also use the `SCKeyTuple` that is part of every `SCSpatialFeature`.  The `SCKeyTuple` is a tuple that contains the store id, the layer id, and the feature id.  Let's say you need to get a specific feature to perform some editing on it.  You can get the specific feature by first getting the data store and then querying by the feature id:

```
SCKeyTuple *t = [[SCKeyTuple alloc] initWithStoreId:storeId layerId:layerId featureId:featureId];
[[manager.dataService storeById:t.storeId] queryById:k] subscribeNext:^(SCGeometry *g) {
   		NSLog(@"%@",g.identifier);
}];
```
### SCSpatialFeature and Geometry Object Model

`SCSpatialFeature`s is the primary domain object of SpatialConnect.  It is a generic object that contains an id, some audit metadata, and a k/v map of properties.

> `SCSpatialFeature` is the parent class of all `SCGeometry`s. This allows the library to handle data types that do not contain a geometry.  A practical side effect of this design is that data containing no location attribute can still be stored, queried, and filtered with the functionality of the SpatialConnect.

The SpatialConnect provides a custom geometry object model using the `SCGeometry`.  One reason this
is necessary is b/c we need to identify objects by their ids (in case
they need to be edited) and the GeoJSON spec doesn’t require ids.  The
object model is a blend of the OGC Simple Feature Specification and the
GeoJSON spec but it doesn’t strictly follow either because it’s trying to be
a useful, developer-friendly abstraction.

As mentioned before, each `SCSpatialFeature` contains a `SCKeyTuple` containing the layer id, store id, and feature id.  When sending a `SCSpatialFeature` through the Javascript bridge, we Base64 encode each part of the tuple and use that for the GeoJSON Feature's id.  This will allow us to keep track of features even after they are edited by a Javascript maping client like OpenLayers. 

### Examples

See [https://github.com/boundlessgeo/spatialconnect-examples/](https://github.com/boundlessgeo/spatialconnect-examples/) for an example application using this SDK.

### Building

SpatialConnect uses CocoaPods locally. Here is the Podfile for the example app:
```
source 'https://github.com/CocoaPods/Specs.git'
xcodeproj 'SpatialConnectSample'
platform :ios, '8.0'

pod 'ReactiveCocoa', '2.5'
pod 'spatialconnect', :path => './../../spatialconnect-ios'
pod 'wkb-ios', :path => './../../geopackage-wkb-ios'
pod 'geopackage-ios', :path=> './../../geopackage-ios'
pod 'zipzap', '8.0.6'
pod 'AFNetworking','~> 2.1'
pod 'libextobjc','0.4.1'
pod 'ReactiveViewModel','0.3'
```

## Testing

To run the tests open XCode and run the test scheme.

## Dependencies

[ReactiveCocoa 2.5](https://github.com/ReactiveCocoa/ReactiveCocoa)  
[ZipZap 8.0.6](https://github.com/pixelglow/ZipZap)
[libextobjc 0.4.1](https://github.com/jspahrsummers/libextobjc)
[Geopackage-iOS](https://github.com/boundlessgeo/geopackage-ios)
[Geopackage-wkb-iOS](https://github.com/boundlessgeo/geopackage-wkb-ios)

## License

Apache 2.0

## Version Support
iOS 8+
