/*****************************************************************************
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 ******************************************************************************/

import Foundation

@objc(SCReactBridge)
public class SCReactBridge: NSObject {
    
    var sc: SpatialConnect!
    
    let SCJavascriptBridgeErrorDomain = "SCJavascriptBridgeErrorDomain"
    
    override init() {
        self.sc = SpatialConnect.sharedInstance() as! SpatialConnect
        super.init()
    }
    
    @objc public func handler(data: NSDictionary, responseCallback: ((data: AnyObject) -> Void)? = nil) -> Void {
        self.parseJSCommand(data).subscribeNext {(responseData:AnyObject!) -> () in
            responseCallback!(data: responseData);
        }
    }
    
    func parseJSCommand(data: NSDictionary) -> RACSignal {
        NSLog("JS Command: %@", data);
        return RACSignal.createSignal { (subscriber) -> RACDisposable! in
            let command = data["data"] as! NSDictionary
            let _action = command["action"] as! Int
            let action = SCJavascriptCommand(rawValue: _action)!
            switch action {
            case .DATASERVICE_ACTIVESTORESLIST:
                self.activeStoreList(subscriber)
            case .DATASERVICE_ACTIVESTOREBYID:
                self.activeStoreById(command["payload"] as! NSDictionary, responseSubscriber: subscriber)
            case .DATASERVICE_SPATIALQUERY:
                self.queryStoreById(command["payload"] as! NSDictionary, responseSubcriber: subscriber)
            case .DATASERVICE_SPATIALQUERYALL:
                self.queryAllStores(command["payload"] as! NSDictionary, responseSubscriber: subscriber)
            case .DATASERVICE_GEOSPATIALQUERY:
                self.queryGeoStoreById(command["payload"] as! NSDictionary, responseSubscriber: subscriber)
            case .DATASERVICE_GEOSPATIALQUERYALL:
                self.queryAllGeoStores(command["payload"] as! NSDictionary, responseSubscriber: subscriber)
            case .DATASERVICE_CREATEFEATURE:
                self.createFeature(command["payload"] as! NSDictionary, responseSubscriber: subscriber)
            case .DATASERVICE_UPDATEFEATURE:
                self.updateFeature(command["payload"] as! NSDictionary, responseSubscriber: subscriber)
            case .DATASERVICE_DELETEFEATURE:
                self.deleteFeature(command["payload"] as! String, responseSubscriber: subscriber)
            case .DATASERVICE_FORMLIST:
                self.formList(subscriber)
            case .SENSORSERVICE_GPS:
                self.spatialConnectGPS(command["payload"] as! Int, responseSubscriber: subscriber)
            default:
                break
            }
            return nil
        }
    }
    
    func activeStoreList(subscriber: RACSubscriber) {
        let arr: [AnyObject] = self.sc.dataService.activeStoreListDictionary()
        subscriber.sendNext(["key": "storesList", "body":["stores": arr]])
        subscriber.sendCompleted()
    }
    
    func formList(subscriber: RACSubscriber) {
        let arr: [AnyObject] = self.sc.dataService.defaultStoreForms().map {
            (formConfig) -> NSDictionary in return formConfig.JSONDict()
        }
        subscriber.sendNext(["key": "formsList", "body":["forms": arr]])
        subscriber.sendCompleted()
    }
    
    
    func activeStoreById(value: NSDictionary, responseSubscriber subscriber: RACSubscriber) {
        let dict = self.sc.dataService.storeByIdAsDictionary(value["storeId"] as! String)
        subscriber.sendNext(["key": "store", "body":["store": dict]])
        subscriber.sendCompleted()
    }
    
    func queryAllStores(value: NSDictionary, responseSubscriber subscriber: RACSubscriber) {
        let filter: SCQueryFilter = SCQueryFilter(fromDictionary: value["filters"] as! [NSObject : AnyObject])
        self.sc.dataService.queryAllStores(filter).subscribeNext {(next:AnyObject!) -> () in
            let g = next as! SCGeometry
            subscriber.sendNext(["key": "spatialQuery", "body":g.JSONDict()])
            subscriber.sendCompleted()
        }
    }
    
    func queryStoreById(value: NSDictionary, responseSubcriber subscriber: RACSubscriber) {
        self.sc.dataService.queryStoreById(String(value["storeId"]), withFilter: nil).subscribeNext {(next:AnyObject!) -> () in
            let g = next as! SCGeometry
            subscriber.sendNext(["key": "spatialQuery", "body":g.JSONDict()])
            subscriber.sendCompleted()
        }
    }
    
    func queryAllGeoStores(value: NSDictionary, responseSubscriber subscriber: RACSubscriber) {
        let filter: SCQueryFilter = SCQueryFilter(fromDictionary: value as [NSObject : AnyObject])
        self.sc.dataService.queryAllStoresOfProtocol(SCSpatialStore.self, filter: filter).subscribeNext {(next:AnyObject!) -> () in
            let g = next as! SCGeometry
            subscriber.sendNext(["key": "spatialQuery", "body":g.JSONDict()])
            subscriber.sendCompleted()
        }
    }
    
    func queryGeoStoreById(value: NSDictionary, responseSubscriber subscriber: RACSubscriber) {
        let filter: SCQueryFilter = SCQueryFilter(fromDictionary: value as [NSObject : AnyObject])
        self.sc.dataService.queryStoreById(String(value["storeId"]), withFilter: filter).subscribeNext {(next:AnyObject!) -> () in
            let g = next as! SCGeometry
            subscriber.sendNext(["key": "spatialQuery", "body":g.JSONDict()])
            subscriber.sendCompleted()
        }
    }
    
    func spatialConnectGPS(value: AnyObject, responseSubscriber subscriber: RACSubscriber) {
        let enable = value as! Bool
        if enable {
            self.sc.sensorService.enableGPS()
            self.sc.sensorService.lastKnown.subscribeNext {(next:AnyObject!) -> () in
                if let loc = next as? CLLocation {
                    let lat:Double = loc.coordinate.latitude
                    let lon:Double = loc.coordinate.longitude
                    subscriber.sendNext(["key": "lastKnownLocation", "body":[ "lat": lat, "lon": lon ]])
                }
            }
        }
        else {
            self.sc.sensorService.disableGPS()
        }
    }
    
    func createFeature(value: NSDictionary, responseSubscriber subscriber: RACSubscriber) {
        let geoJsonDict = (value["feature"] as! [NSObject : AnyObject])
        let storeId: String = (geoJsonDict["storeId"] as! String)
        let layerId: String = (geoJsonDict["layerId"] as! String)
        var store: SCDataStore? = self.sc.dataService.storeByIdentifier(storeId)
        if (store == nil) {
            store = self.sc.dataService.defaultStore
        }
        if store!.conformsToProtocol(SCSpatialStore.self) {
            let s: GeopackageStore = (store as! GeopackageStore)
            do {
                let feat: SCSpatialFeature = SCGeoJSON.parseDict(geoJsonDict)
                feat.layerId = layerId
                s.create(feat).subscribeError({(error:NSError!) -> Void in
                    NSLog("Error creating Feature %@", error);
                    }, completed: {() -> Void in
                        subscriber.sendNext(["key": "createFeature", "body":feat.JSONDict()])
                })
            } catch {
                let err: NSError = NSError(domain: SCJavascriptBridgeErrorDomain, code: -57, userInfo: nil)
                subscriber.sendError(err)
            }
        }
        else {
            let err: NSError = NSError(domain: SCJavascriptBridgeErrorDomain, code: -57, userInfo: nil)
            subscriber.sendError(err)
        }
    }
    
    func updateFeature(value: NSDictionary, responseSubscriber subscriber: RACSubscriber) {
        let jsonStr = String(value["feature"])
        do {
            let geoJsonDict: [NSObject : AnyObject] = try SCFileUtils.jsonStringToDict(jsonStr)
            let geom: SCGeometry = SCGeoJSON.parseDict(geoJsonDict)
            let t: SCKeyTuple = SCKeyTuple(fromEncodedCompositeKey: geom.identifier)
            geom.storeId = t.storeId
            geom.layerId = t.layerId
            geom.identifier = t.featureId
            let store: SCDataStore = self.sc.dataService.storeByIdentifier(geom.storeId)
            if store.conformsToProtocol(SCSpatialStore.self) {
                let s: SCSpatialStore = (store as! SCSpatialStore)
                s.update(geom).subscribeError({(error:NSError!) -> Void in
                    let err: NSError = NSError(domain: self.SCJavascriptBridgeErrorDomain, code: SCJavascriptError.SCJSERROR_DATASERVICE_UPDATEFEATURE.rawValue, userInfo: nil)
                    subscriber.sendError(err)
                    }, completed: {() -> Void in
                        subscriber.sendCompleted()
                })
            } else {
                let err: NSError = NSError(domain: self.SCJavascriptBridgeErrorDomain, code: SCJavascriptError.SCJSERROR_DATASERVICE_UPDATEFEATURE.rawValue, userInfo: nil)
                subscriber.sendError(err)
            }
        } catch {
            let err: NSError = NSError(domain: self.SCJavascriptBridgeErrorDomain, code: SCJavascriptError.SCJSERROR_DATASERVICE_UPDATEFEATURE.rawValue, userInfo: nil)
            subscriber.sendError(err)
        }
    }
    
    func deleteFeature(value: String, responseSubscriber subscriber: RACSubscriber) {
        let key: SCKeyTuple = SCKeyTuple(fromEncodedCompositeKey: value)
        let store: SCDataStore = self.sc.dataService.storeByIdentifier(key.storeId)
        if store.conformsToProtocol(SCSpatialStore.self) {
            let s: SCSpatialStore = (store as! SCSpatialStore)
            s.delete(key).subscribeError({(error:NSError!) -> Void in
                let err: NSError = NSError(domain: self.SCJavascriptBridgeErrorDomain, code: SCJavascriptError.SCJSERROR_DATASERVICE_DELETEFEATURE.rawValue, userInfo: nil)
                subscriber.sendError(err)
                }, completed: {() -> Void in
                    subscriber.sendCompleted()
            })
        }
        else {
            let err: NSError = NSError(domain: self.SCJavascriptBridgeErrorDomain, code: SCJavascriptError.SCJSERROR_DATASERVICE_DELETEFEATURE.rawValue, userInfo: nil)
            subscriber.sendError(err)
        }
    }
    
}