//
//  ViewController.swift
//  TestMapKit
//
//  Created by Владислав Сизонов on 07.11.2021.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {
    
    let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        return mapView
    }()
    
    let addAdressButton: UIButton = {
        let button = UIButton()
        button.setTitle("Add adress", for: .normal)
        button.backgroundColor = .gray
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let routeButton: UIButton = {
        let button = UIButton()
        button.setTitle("Route", for: .normal)
        button.backgroundColor = .gray
        button.layer.cornerRadius = 8
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let resetButton: UIButton = {
        let button = UIButton()
        button.setTitle("Reset", for: .normal)
        button.backgroundColor = .gray
        button.layer.cornerRadius = 8
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var annotationArray = [MKPointAnnotation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupConstraints()
        mapView.delegate = self
        
        addAdressButton.addTarget(self, action: #selector(addAdressButtonTapped), for: .touchUpInside)
        routeButton.addTarget(self, action: #selector(routeButtonTapped), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
    }
    
    @objc func addAdressButtonTapped() {
        showAlert(title: "Add adress", placeHolder: "Enter adress") { text in
            self.setupPlacemark(adress: text)
        }
    }
    
    @objc func routeButtonTapped() {
        for index in 0...annotationArray.count - 2 {
            createDirectionRequest(startCoordinate: annotationArray[index].coordinate, destinationCoordinate: annotationArray[index + 1].coordinate)
        }
        mapView.showAnnotations(annotationArray, animated: true  )
    }
    
    @objc func resetButtonTapped() {
        
    }
    
    private func setupPlacemark(adress: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(adress) { [self] (placemarks, error) in
            if let error = error {
                print(error)
                errorAlert(title: "Error", message: "Enter adress one more time")
                return
            }
            
            guard let placemarks = placemarks else { return }
            let placemark = placemarks.first
            
            let annotation = MKPointAnnotation()
            annotation.title = adress
            
            guard let placemarkLocation = placemark?.location else { return }
            annotation.coordinate = placemarkLocation.coordinate
            
            annotationArray.append(annotation)
            
            if annotationArray.count > 2 {
                routeButton.isHidden = false
                resetButton.isHidden = false
            }
            
            mapView.addAnnotations(annotationArray)
        }
    }
    
    private func createDirectionRequest(startCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) {
        
        let startLocation = MKPlacemark(coordinate: startCoordinate)
        let destinationLocation = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startLocation)
        request.destination = MKMapItem(placemark: destinationLocation)
        request.transportType = .walking
        request.requestsAlternateRoutes = true
        
        let direction = MKDirections(request: request)
        direction.calculate { (response, error) in
            if let error = error {
                print(error)
                return
            }
            
            guard let response = response else {
                self.errorAlert(title: "Error", message: "Route is not available")
                return
            }
            
            var minRoute = response.routes[0]
            for route in response.routes {
                minRoute = (route.distance < minRoute.distance) ? route : minRoute
            }
            self.mapView.addOverlay(minRoute.polyline)
            
        }
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .gray
        return renderer
    }
}

extension ViewController {
    
    func setupConstraints() {
    
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
        ])
        
        mapView.addSubview(addAdressButton)
        NSLayoutConstraint.activate([
            addAdressButton.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 50),
            addAdressButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -20),
            addAdressButton.heightAnchor.constraint(equalToConstant: 36),
            addAdressButton.widthAnchor.constraint(equalToConstant: 100)
        ])
        
        mapView.addSubview(routeButton)
        NSLayoutConstraint.activate([
            routeButton.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 20),
            routeButton.bottomAnchor.constraint(equalTo: mapView.bottomAnchor , constant: -30),
            routeButton.heightAnchor.constraint(equalToConstant: 36),
            routeButton.widthAnchor.constraint(equalToConstant: 100)
        ])
        
        mapView.addSubview(resetButton)
        NSLayoutConstraint.activate([
            resetButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -20),
            resetButton.bottomAnchor.constraint(equalTo: mapView.bottomAnchor , constant: -30),
            resetButton.heightAnchor.constraint(equalToConstant: 36),
            resetButton.widthAnchor.constraint(equalToConstant: 100)
        ])
    }
}

extension ViewController {
    
    func showAlert(title: String, placeHolder: String, completion: @escaping (String) -> Void) {
        
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            let tfText = alert.textFields?.first
            guard let text = tfText?.text, tfText?.text != "" else { return }
            completion(text)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addTextField { (tf) in
            tf.placeholder = placeHolder
        }
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    func errorAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}
