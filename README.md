# SpatialConnect iOS Library

## License

Apache 2.0

## Version Supported

iOS 8+

## Dependencies

[ReactiveCocoa 2.5](https://github.com/ReactiveCocoa/ReactiveCocoa)  
[ZipZap 8.0.6](https://github.com/pixelglow/ZipZap)
[libextobjc 0.4.1](https://github.com/jspahrsummers/libextobjc)
[Geopackage-iOS](https://github.com/boundlessgeo/geopackage-ios)
[Geopackage-wkb-iOS](https://github.com/boundlessgeo/geopackage-wkb-ios)

## Store Configuration
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

## Store Lifecycle

In the SCDataService there is an NSDictionary named 'supportedStores'. The this will contain a Class distinguished by key TYPE.VERSION (i.e. geojson.1). These can be added to the data service after SpatialConnect has been instantiated. When SCDataService starts, it will instantiate the appropriate version and type stored in the 'supportedStores' dictionary. 

## Web Bundles

Web Bundles zip files containing a webapp with the entry point being 'index.html'. A zip file placed in the Application's Documents directory will be scanned on load, check for zips containing an 'index.html', and will load that 'index.html' in a 'UIWebView'.

The data store needs an adapter to connect to the underlying data source (a GeoJson file, a GeoPackage database, a CSV file, etc), therefore you must also create a class that extends SCDataAdapter.  The adapter will manage connecting and disconecting to the data source as well as the actual I/O to the data source.  The adapter will use the uri defined in the config to connect to the data source.  If the uri is remote, then it will download from the location and store it locally (at least for a geopackage).  

### Testing

To run the tests open XCode and run the test scheme.

### Version Support
iOS 8+
