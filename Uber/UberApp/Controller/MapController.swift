//
//  MapController.swift
//  Uber
//
//  Created by Umang Kedan on 11/02/24.
//

import UIKit
import MapKit
import CoreData

class MapController: UIViewController {
    
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var toSearchBar: UISearchBar!
    @IBOutlet weak var fromSearchBar: UISearchBar!
    @IBOutlet weak var historyButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var cutButton: UIButton!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    var fromLocationCoordinate: CLLocationCoordinate2D?
    var toLocationCoordinate: CLLocationCoordinate2D?
    var routeCoordinates: [CLLocationCoordinate2D] = []
    let mapObj = MapObject()
    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()
    var activeSearchBar:UISearchBar?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setLocationManager()
        mapView.overrideUserInterfaceStyle = .dark
        fromSearchBar.delegate = self
        toSearchBar.delegate = self
        timeLabel.isHidden = true
        distanceLabel.isHidden = true
        animateFreewayLocation()
        searchCompleter.delegate = self
        fromSearchBar.overrideUserInterfaceStyle = .dark
        toSearchBar.overrideUserInterfaceStyle = .dark
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        
    }
    
    func setLocationManager(){
        locationManager.activityType = .automotiveNavigation
        locationManager.distanceFilter = 20
        locationManager.desiredAccuracy = 100
        mapView.showsUserLocation = true
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        locationManager.requestWhenInUseAuthorization()
        
    }
    
    func getAddress(location : CLLocation){
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(location) { placemarks, error in
            guard (placemarks?.first) != nil else {
                print("No address found for the given location")
                return
            }
        }
    }

    @IBAction func locationButtonAction(_ sender: Any) {
        if let location = locationManager.location{
            searchButton.isSelected = false
            getAddress(location: location)
        }
    }
    
    @IBAction func cutButtonAction(_ sender: Any) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        mapView.mapType = .standard
        fromSearchBar.text = ""
        toSearchBar.text = ""
        toSearchBar.isHidden = false
        fromSearchBar.isHidden = false
        searchButton.isHidden = false
        routeCoordinates.removeAll()
        distanceLabel.isHidden = true
        timeLabel.isHidden = true
        tableView.alpha = 0
      
    }
    
    @IBAction func searchButtonAction(_ sender: Any) {

        let idk:Bool = false
        if idk == true {
            guard let fromText = fromSearchBar.text, !fromText.isEmpty,
                  let toText = toSearchBar.text, !toText.isEmpty else {
                print("Both source and destination are required.")
                return
            }
            
            mapObj.getLocationfromAddress(address: fromText) { isSuccess, placemark, error in
                if isSuccess, let coordinate = placemark {
                    print("Location found for 'from' address: \(coordinate)")
                    self.fromLocationCoordinate = coordinate
                } else {
                    if let error = error {
                        print("Geocoding error for 'from' address: \(error)")
                    } else {
                        print("No location found for the 'from' address.")
                    }
                }
                self.cutButton.isHidden = false
            }
            
            mapObj.getLocationfromAddress(address: toText) { isSuccess, placemark, error in
                if isSuccess, let coordinate = placemark {
                    print("Location found for 'to' address: \(coordinate)")
                    self.toLocationCoordinate = coordinate
                } else {
                    if let error = error {
                        print("Geocoding error for 'to' address: \(error)")
                    } else {
                        print("No location found for the 'to' address.")
                    }
                }
                
                self.drawRouteIfPossible()
            }
        } else  {
            self.drawRouteIfPossible()
        }
    }
    
    func drawRouteIfPossible() {
        guard let fromCoordinate = fromLocationCoordinate, let toCoordinate = toLocationCoordinate else {
            print("Coordinates not available.")
            return
        }
        
        let names = "\(fromSearchBar.text ?? "") , \(toSearchBar.text ?? "")"
        mapObj.drawRoute(from: fromCoordinate, to: toCoordinate, on: mapView)
        print(fromCoordinate)
        print(toCoordinate)
        
        mapObj.calculateDistanceAndTimeOfTravel(from: fromCoordinate, to: toCoordinate) { distanceStr, timeStr in
            DispatchQueue.main.async {
                if let distanceStr = distanceStr, let timeStr = timeStr {
                    print("Distance: \(distanceStr)")
                    print("Approximate time of travel: \(timeStr)")
                    self.distanceLabel.isHidden = false
                    self.timeLabel.isHidden = false
                    self.distanceLabel.text = " Distance - \(distanceStr) "
                    self.timeLabel.text = "Time - \(timeStr)"
                    self.mapObj.saveLocation(from: fromCoordinate, to: toCoordinate, name: names, path: self.routeCoordinates)
                } else {
                    print("Failed to calculate distance and time of travel")
                }
            }
        }
    }
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect(x: fromSearchBar.frame.origin.x, y: fromSearchBar.frame.origin.y + fromSearchBar.frame.size.height + 10, width: fromSearchBar.frame.size.width, height: 100))
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    func showSuggestionsDropdown(tableViewShow: Bool) {
        if tableViewShow {
            view.addSubview(tableView)
        } else {
            tableView.removeFromSuperview()
        }
    }
    
    func setDynamicTableView(cgrect:CGRect) {
        tableView.frame = cgrect
        tableView.alpha = 1
    }
    
    @IBAction func historyButtonAction(_ sender: Any) {
        guard let savedLocation = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(identifier: "savedLocation") as? SavedLocationControllerViewController else { return  }
        savedLocation.delegate = self
        self.navigationController?.pushViewController(savedLocation, animated: true)
    }
    
}

extension MapController : MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            
            let render = MKGradientPolylineRenderer(polyline: polyline)
            render.setColors([.green, .blue, .red], locations: [0, 0.5, 1])
            render.lineCap = .round
            render.lineWidth = 4
            
            return render
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func resetMap(){
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        mapView.mapType = .standard
    }
    
    func handleSearchResults() {
        UIView.animate(withDuration: 0.3, animations: {
            self.tableView.alpha = 1
            self.tableView.alpha = 1
        })
        // Reload the table view
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func animateFreewayLocation() {
        guard !routeCoordinates.isEmpty else { return }
        // Iterate through the route coordinates
        for (index, coordinate) in routeCoordinates.enumerated() {
            // Create an animation to move to the next coordinate
            UIView.animate(withDuration: 2.0, delay: 2.0 * Double(index), options: .curveLinear, animations: {
                self.mapView.setCenter(coordinate, animated: true)
            }, completion: nil)
        }
    }
}

extension MapController : CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.first else { return }
        
        //  Center the map on the user's current location
        let viewRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 200, longitudinalMeters: 200)
        mapView.setRegion(viewRegion, animated: true)
        
        
    }
}

extension MapController : MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        tableView.reloadData()
    }
}

extension MapController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard let text = searchBar.text else { return }
        searchCompleter.queryFragment = text
        self.handleSearchResults()
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        activeSearchBar = searchBar
        
        showSuggestionsDropdown(tableViewShow: true)
        let cgrect = CGRect(x: searchBar.frame.origin.x + 30 , y: searchBar.frame.origin.y + 100, width: searchBar.frame.width, height: searchBar.frame.height + 20)
        setDynamicTableView(cgrect: cgrect)
        return true
    }
}
    
extension MapController : UITableViewDelegate , UITableViewDataSource{

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let searchResult = searchResults[indexPath.row]
        
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        if tableView == self.tableView {
            cell.textLabel?.text = searchResult.title
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let searchResult = searchResults[indexPath.row]
        mapObj.getLocalSearch(searchCompletion: searchResult) { activeMKLocalSearchCoordinate, error in
            if error == nil {
                if self.activeSearchBar == self.fromSearchBar {
                    self.fromLocationCoordinate = activeMKLocalSearchCoordinate
                } else if self.activeSearchBar == self.toSearchBar {
                    self.toLocationCoordinate = activeMKLocalSearchCoordinate
                }
            }
        }

        if activeSearchBar != nil {
            activeSearchBar?.text = searchResult.title
        }
        if tableView == self.tableView {
            if fromSearchBar.isFirstResponder {
                fromSearchBar.text = searchResult.title
            } else if toSearchBar.isFirstResponder {
                toSearchBar.text = searchResult.title
            }
            showSuggestionsDropdown(tableViewShow: false)
        }
    }
}

extension MapController: SavedLocationDelegate {
    func didSelectLocation(fromCoordinates: CLLocationCoordinate2D, toCoordinates: CLLocationCoordinate2D) {
        // Call drawRoute method with the selected coordinates
        self.fromLocationCoordinate = fromCoordinates
        self.toLocationCoordinate = toCoordinates
        self.drawRouteIfPossible()
    }
}

