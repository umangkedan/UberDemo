//
//  MapObject.swift
//  Uber
//
//  Created by Umang Kedan on 13/02/24.
//

import UIKit
import CoreLocation
import MapKit
import CoreData

var routeCoordinates: [CLLocationCoordinate2D] = []
let appDelegate = UIApplication.shared.delegate as? AppDelegate
let persistentContainer = appDelegate?.persistentContainer
let context = appDelegate?.persistentContainer.viewContext

class MapObject: NSObject  {
    
    func getLocationfromAddress(address: String? , completionhandler : @escaping(_ is_Succeding : Bool , _ placemark : CLLocationCoordinate2D? , _ error : String? ) -> ()) {
        let geoCoder = CLGeocoder()
        
        geoCoder.geocodeAddressString(address ?? "") { placemark, error in
            guard let placemark = placemark ,
                  let location = placemark.first?.location else {
                print("No location Found")
                return
            }
            if error == nil {
                completionhandler(true , location.coordinate , nil)
            } else {
                completionhandler(false , nil , nil)
            }
        }
    }
    
    func drawRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, on mapView: MKMapView) {
        
        let sourceAnnotation = MKPointAnnotation()
        sourceAnnotation.coordinate = source
        sourceAnnotation.title = "Source"
        mapView.addAnnotation(sourceAnnotation)
        
        let destinationAnnotation = MKPointAnnotation()
        destinationAnnotation.coordinate = destination
        destinationAnnotation.title = "Destination"
        mapView.addAnnotation(destinationAnnotation)
        
        let sourcePlacemark = MKPlacemark(coordinate: source)
        let destinationPlacemark = MKPlacemark(coordinate: destination)
        
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) in
            guard let response = response else {
                if let error = error {
                    print("Error getting directions: \(error.localizedDescription)")
                }
                return
            }
            // Get the first route from the response
            let route = response.routes[0]
            
            // Draw the route on the map with custom colors
            let routeRenderer = MKPolylineRenderer(polyline: route.polyline)
            routeRenderer.strokeColor = .red // Customize color for the route
            routeRenderer.lineWidth = 5
            mapView.addOverlay(route.polyline)
            
            // Fit the map to the route
            let rect = route.polyline.boundingMapRect
            mapView.setRegion(MKCoordinateRegion(rect), animated: true)
        }
    }
    
    func calculateDistanceAndTimeOfTravel(from sourceCoordinate: CLLocationCoordinate2D, to destinationCoordinate: CLLocationCoordinate2D, completion: @escaping (String?, String?) -> Void) {
        let sourceLocation = CLLocation(latitude: sourceCoordinate.latitude, longitude: sourceCoordinate.longitude)
        let destinationLocation = CLLocation(latitude: destinationCoordinate.latitude, longitude: destinationCoordinate.longitude)
        
        let distance = sourceLocation.distance(from: destinationLocation) / 1000 // in kilometers
        
        // Calculate time in hours
        let averageSpeedKmh: Double = 50
        let timeHours = distance / averageSpeedKmh
        let timeStr = formatTimeFromHours(timeHours) // Format time as hours and minutes
        let distanceStr = String(format: "%.2f km", distance) // Format distance
        
        completion(distanceStr, timeStr)
    }
    
    func formatTimeFromHours(_ timeHours: TimeInterval) -> String {
        let hours = Int(timeHours)
        let minutes = Int((timeHours - TimeInterval(hours)) * 60)
        var timeStr = ""
        if hours > 0 {
            timeStr += "\(hours) hr"
            if hours > 1 {
                timeStr += "s"
            }
            timeStr += " "
        }
        if minutes > 0 {
            timeStr += "\(minutes) min"
        }
        return timeStr
    }
    
    func saveLocation(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, name: String , path: [CLLocationCoordinate2D]) {
        guard let saveContext = context else {
            print("Context not found")
            return
        }
        
        let locationEntity = Location(context: saveContext)
        locationEntity.fromCoordinates = "\(source.latitude), \(source.longitude)" as NSObject
        locationEntity.toCoordinates = "\(destination.latitude), \(destination.longitude)" as NSObject
        locationEntity.name = name
        
        // Convert path coordinates to a format that can be stored in Core Data
        if let pathData = try? NSKeyedArchiver.archivedData(withRootObject: path, requiringSecureCoding: false) {
               locationEntity.path = pathData as NSObject
           } else {
               print("Failed to convert path coordinates to Data")
           }

        do {
            try saveContext.save()
            print("Location saved successfully")
        } catch let error as NSError {
            print("Failed to save location: \(error.localizedDescription)")
        }
    }
    
    func getLocalSearch(searchCompletion:MKLocalSearchCompletion ,completionHandler: @escaping (CLLocationCoordinate2D?, Error?) -> ()) {
            let searchRequest = MKLocalSearch.Request(completion: searchCompletion)
            let search = MKLocalSearch(request: searchRequest)
            search.start { (response, error) in
                if let error = error {
                    completionHandler(nil, error)
                    return
                } else {
                    let coordinate = response!.mapItems[0].placemark.coordinate
                    completionHandler(coordinate, nil)
                }
            }
        }
    }

