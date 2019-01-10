//
//  MapViewController.swift
//  Mapapp
//
//  Created by Leonardo Bilia on 1/9/19.
//  Copyright © 2019 Leonardo Bilia. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    private lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(clearRouteHandler)))
        mapView.translatesAutoresizingMaskIntoConstraints = false
        return mapView
    }()
    
    private let searchController = UISearchController(searchResultsController: nil)
    private lazy var locationManager = CLLocationManager()

    //MARK: views
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Mapapp"
        setupBarButtonItens()
        setupSearchController()
        currentLocationHandler()
        layoutHandler()
        
        checkLocationServices()
        mapView.delegate = self
    }
    
    //MARK: actions
    @objc fileprivate func mapSettingsHandler(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Map Settings", message: "Select a map type below", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Standard", style: .default, handler: { (alertAction) in
            self.mapView.mapType = MKMapType.standard
        }))
        alertController.addAction(UIAlertAction(title: "Satellite", style: .default, handler: { (alertAction) in
            self.mapView.mapType = MKMapType.satellite
        }))
        alertController.addAction(UIAlertAction(title: "Hybrid", style: .default, handler: { (alertAction) in
            self.mapView.mapType = MKMapType.hybrid
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        DispatchQueue.main.async {
            alertController.modalPresentationStyle = .popover
            self.present(alertController, animated: true, completion: nil)
            alertController.popoverPresentationController?.barButtonItem = sender
        }
    }

    @objc fileprivate func currentLocationHandler() {
        locationManager.startUpdatingLocation()
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: 2000, longitudinalMeters: 2000)
            mapView.setRegion(region, animated: true)
            locationManager.stopUpdatingLocation()
        }
    }
    
    @objc fileprivate func clearRouteHandler() {
        if mapView.overlays.count != 0 {
            Alert.showClearRouteAlert(on: self) {
                self.mapView.removeOverlays(self.mapView.overlays)
            }
        }
    }
    
    //MARK: functions
    fileprivate func presentDirections(type: MKDirectionsTransportType, annotation: MKAnnotation) {
        guard let currentLocation = locationManager.location?.coordinate else {
            Alert.showCurrentLocationNotAvailable(on: self)
            return
        }
        
        let startingLocation = MKPlacemark(coordinate: currentLocation)
        let destinationLocation = MKPlacemark(coordinate: CLLocationCoordinate2DMake(annotation.coordinate.latitude, annotation.coordinate.longitude))
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destinationLocation)
        request.transportType = type
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)
        mapView.removeOverlays(mapView.overlays)
        
        directions.calculate { (response, error) in
            if error != nil {
                Alert.showErrorWithLocalizedDescription(on: self, description: error?.localizedDescription)
                return
            }
            guard let response = response else { return }
            for route in response.routes {
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 80, left: 16, bottom: 32, right: 16), animated: true)
                
                //calculate distance to destination if needed
                let hours = Int(route.expectedTravelTime) / 3600
                let minutes = Int(route.expectedTravelTime) / 60 % 60
                let seconds = Int(route.expectedTravelTime) % 60
                print("Time to Destination: \(String(format:"%02i:%02i:%02i", hours, minutes, seconds))")
            }
        }
    }
    
    fileprivate func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    fileprivate func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
        } else {
            Alert.showLocationServicesNotEnabled(on: self)
        }
    }
    
    fileprivate func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined: locationManager.requestWhenInUseAuthorization()
        case .restricted: Alert.showLocationServicesRestricted(on: self)
        case .denied: Alert.showLocationServicesNotEnabled(on: self)
        case .authorizedAlways: break
        case .authorizedWhenInUse: mapView.showsUserLocation = true
        }
    }
    
    fileprivate func setupSearchController() {
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    fileprivate func setupBarButtonItens() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_location"), style: .plain, target: self, action: #selector(currentLocationHandler))
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_info"), style: .plain, target: self, action: #selector(mapSettingsHandler))
    }
    
    fileprivate func layoutHandler() {
        view.backgroundColor = UIColor.white
        
        view.addSubview(mapView)
        mapView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
}


//MARK: search controller
extension MapViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else { return }
        searchController.isActive = false
        mapView.removeOverlays(mapView.overlays)
        
        if mapView.annotations.count != 0 {
            for item in mapView.annotations {
                mapView.removeAnnotation(item)
            }
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else {
                Alert.showErrorWithLocalizedDescription(on: self, description: error?.localizedDescription)
                return
            }
            
            for item in response.mapItems {
                let pointAnnotation = MKPointAnnotation()
                pointAnnotation.title = item.placemark.name
                pointAnnotation.subtitle = item.placemark.title
                pointAnnotation.coordinate = CLLocationCoordinate2D(latitude: item.placemark.coordinate.latitude, longitude: item.placemark.coordinate.longitude)

                let pinAnnotationView = MKPinAnnotationView(annotation: pointAnnotation, reuseIdentifier: nil)
                guard let annotation = pinAnnotationView.annotation else { return }
                self.mapView.centerCoordinate = annotation.coordinate
                self.mapView.addAnnotation(annotation)
                
                let region = MKCoordinateRegion.init(center: annotation.coordinate, latitudinalMeters: 6000, longitudinalMeters: 6000)
                self.mapView.setRegion(region, animated: true)
            }
        }
    }
}


//MARK: location delegate
extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion.init(center: center, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
}


//MARK: map view delegate
extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 4
        return renderer
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation as?  MKPointAnnotation else { return }

        let alertController = UIAlertController(title: annotation.title, message: annotation.subtitle, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Walking", style: .default, handler: { (alertAction) in
            self.presentDirections(type: .walking, annotation: annotation)
        }))
        alertController.addAction(UIAlertAction(title: "Driving", style: .default, handler: { (alertAction) in
            self.presentDirections(type: .automobile, annotation: annotation)
        }))
        alertController.addAction(UIAlertAction(title: "Open on Apple Maps", style: .default, handler: { (alertAction) in
            let coordinate = CLLocationCoordinate2DMake(annotation.coordinate.latitude, annotation.coordinate.longitude)
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))
            mapItem.name = annotation.title
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
        }))
        alertController.addAction(UIAlertAction(title: "Open on Google Maps", style: .default, handler: { (alertAction) in
            guard let location = self.locationManager.location?.coordinate else { return }
            let googleURL = NSURL(string: "comgooglemaps://?q=")
            if UIApplication.shared.canOpenURL(googleURL! as URL) {
                UIApplication.shared.open(URL(string:"comgooglemaps://?saddr=\(location.latitude),\(location.longitude)&daddr=\(annotation.coordinate.latitude),\(annotation.coordinate.longitude)&directionsmode=driving")!, options: [:], completionHandler: nil)
            } else {
                Alert.showErrorWithLocalizedDescription(on: self, description: "The operation couldn’t be completed")
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        DispatchQueue.main.async {
            alertController.modalPresentationStyle = .popover
            self.present(alertController, animated: true, completion: nil)
            alertController.popoverPresentationController?.sourceView = view
            alertController.popoverPresentationController?.sourceRect = view.bounds
        }
    }
}
