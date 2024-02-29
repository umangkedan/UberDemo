//
//  SavedLocationControllerViewController.swift
//  Uber
//
//  Created by Umang Kedan on 21/02/24.
//

import UIKit
import CoreData
import CoreLocation

protocol SavedLocationDelegate: AnyObject {
    func didSelectLocation(fromCoordinates: CLLocationCoordinate2D, toCoordinates: CLLocationCoordinate2D)
}

class SavedLocationControllerViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    weak var delegate : SavedLocationDelegate?
    var savedLocations : [Location] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "LocationsCell", bundle: .main), forCellReuseIdentifier: "userCell")
        fetchSavedLocations()
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    func fetchSavedLocations() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
        
        do {
            savedLocations = try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch locations: \(error.localizedDescription)")
        }
    }
    
}
extension SavedLocationControllerViewController : UITableViewDelegate , UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        savedLocations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as? LocationsCell else {
          return  UITableViewCell()
        }
        
        let location = savedLocations[indexPath.row]
        cell.setLocationData(name: location.name ?? "", from: "\(location.fromCoordinates!) ", to: "\(location.toCoordinates!)")
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let location = savedLocations[indexPath.row]
        
        if let fromCoordinates = location.fromCoordinates as? CLLocationCoordinate2D,
           let toCoordinates = location.toCoordinates as? CLLocationCoordinate2D {
        print(fromCoordinates)
        print(toCoordinates)
            // Call the delegate method to pass the selected coordinates
            delegate?.didSelectLocation(fromCoordinates: fromCoordinates, toCoordinates: toCoordinates)
            navigationController?.popViewController(animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 95
    }
    
}
