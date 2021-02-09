//
//  MapViewController.swift
//
//  Created by Giancarlo Pacheco on 5/14/20.
//
//  See the LICENSE file at the project root for license information.
//

import UIKit
import MapKit
import CashCore

private let kAtmAnnotationViewReusableIdentifier = "kAtmAnnotationViewReusableIdentifier"
private let kLocationDistance: Double = 1300000
private let kHoustonLocation = CLLocation(latitude: 31.3915, longitude: -99.1707)

// TODO: Localize strings
class MapViewController: UIViewController, ATMListFilter {

    public let mapATMs = MKMapView()
    private var timestamp: Double = 0.0

    lazy var locationManager: CLLocationManager = {
        var _locationManager = CLLocationManager()
        _locationManager.delegate = self
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        return _locationManager
    }()

    var atmAnnotations: Array<AtmAnnotation> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        addSubviews()
        setupMapView()
        mapATMs.centerToLocation(kHoustonLocation, regionRadius: kLocationDistance)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkLocationAuthorizationStatus()
        addConstraints()
        
        let parent = self.parent as! AtmLocationsViewController
        parent.searchBackgroundView.backgroundColor = .clear
        parent.myLocationButton.isHidden = false
    }
    
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapATMs.showsUserLocation = true
        }
    }
    
    func addSubviews() {
        view.backgroundColor = .clear
        view.addSubview(mapATMs)
    }

    func addConstraints() {
        let parent = self.parent as! AtmLocationsViewController
        view.constrain([
            view.topAnchor.constraint(equalTo: parent.containerView.topAnchor, constant: 0),
            view.leadingAnchor.constraint(equalTo: parent.containerView.leadingAnchor, constant: 0),
            view.trailingAnchor.constraint(equalTo: parent.containerView.trailingAnchor, constant: 0),
            view.bottomAnchor.constraint(equalTo: parent.containerView.bottomAnchor, constant: 0.0)
        ])
        mapATMs.constrain([
            mapATMs.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            mapATMs.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            mapATMs.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            mapATMs.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0.0)
        ])

    }
    
    func setupMapView() {
        mapATMs.isScrollEnabled = true
        mapATMs.isZoomEnabled = true

        mapATMs.showsScale = true
        mapATMs.showsCompass = true
        
        mapATMs.register(AtmAnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapATMs.delegate = self
    }
    
    @objc func containerViewTapped(_ sender: Any) {
        view.endEditing(true)
        let parent = self.parent as! AtmLocationsViewController
        parent.searchBar.resignFirstResponder()
    }
    
    public func locationButtonTapped(_ sender: UIButton) {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
}

// MARK: Map Filtering
extension MapViewController {
    func update(_ atms: [AtmMachine]?) {
        self.mapATMs.removeAnnotations(self.atmAnnotations)
        self.atmAnnotations.removeAll()
        
        if let items = atms {
            for atmMachine in items {
                let annotation = AtmAnnotation.init(atm: atmMachine)
                self.atmAnnotations.append(annotation)
            }
        }
        self.mapATMs.addAnnotations(self.atmAnnotations)
    }
}

extension MapViewController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        mapATMs.centerToLocation(manager.location!, regionRadius: kLocationDistance)
        
        let parent = self.parent as! AtmLocationsViewController
        parent.myLocationButton.isSelected = true
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        let parent = self.parent as! AtmLocationsViewController
        parent.myLocationButton.isSelected = false
    }
    
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation { return nil }
        
        var annotationView = mapATMs.dequeueReusableAnnotationView(withIdentifier: kAtmAnnotationViewReusableIdentifier)
        let annot = annotation as! AtmAnnotation
        
        if annotationView == nil {
            annotationView = AtmAnnotationView(annotation: annotation, reuseIdentifier: kAtmAnnotationViewReusableIdentifier)
            
            (annotationView as! AtmAnnotationView).atmMarkerAnnotationViewDelegate = self
        } else {
            annotationView!.annotation = annot
        }
        
        if annotation.isKind(of: MKUserLocation.self) {
            annotationView?.isUserInteractionEnabled = false
        }
        
        if annot.atm.redemption!.boolValue {
            annotationView?.image = UIImage(named: "atmWhite", in: .module, compatibleWith: nil)
        }
        else {
            annotationView?.image = UIImage(named: "atmGrey", in: .module, compatibleWith: nil)
        }
        
        return annotationView
    }
    
    func center(on atm: CashCore.AtmMachine, regionRadius: CLLocationDistance? = kLocationDistance, shouldOffset: Bool? = false) {
        guard let latitude = atm.latitude, let longitude = atm.longitude else {
            return
        }
        let lat = Double(latitude)
        let long = Double(longitude)
        let coordinate = CLLocationCoordinate2D(latitude: lat!, longitude: long!)
        mapATMs.setCenter(coordinate, animated: true)
//        mapATMs.centerToLocation(location, regionRadius: regionRadius!)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let ts = CFAbsoluteTimeGetCurrent()
        if fabs(timestamp - ts) < 1.0 {
            mapATMs.selectedAnnotations.removeAll()
            return
        }
        if let annotation = view.annotation, annotation.isKind(of: MKUserLocation.self) {
            // No op
            return
        }

        let annotationView = view as! AtmAnnotationView
        guard let atm = annotationView.customCalloutView?.atm else { return }
//        center(on: atm, regionRadius: 500, shouldOffset: true)
        center(on: atm)
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        let ts = CFAbsoluteTimeGetCurrent()
        timestamp = ts
    }
    
//    func centerAnnotationInRect(annotation: MKAnnotation, rect: CGRect) {
//
//        let visibleCenter = CGPointMake(rect.midX, CGRectGetMidY(rect))
//
//        let annotationCenter = mapATMs.convert(annotation.coordinate, toPointTo: view)
//
//        let distanceX: CGFloat = visibleCenter.x - annotationCenter.x
//        let distanceY = visibleCenter.y - annotationCenter.y

//        mapATMs.scrollWithOffset(CGPoint(x: distanceX, y: distanceY), animated: true)
//    }
}

extension MapViewController: AtmInfoViewDelegate {
    func detailsRequestedForAtm(atm: AtmMachine) {
//        center(on: atm, regionRadius: 500, shouldOffset: true)
        let parent = self.parent as! AtmLocationsViewController
        parent.sendVerificationVC?.setAtmInfo(atm)
        parent.verifyCashCodeVC?.atmMachineTitleLabel.text = atm.addressDesc
        parent.sendVerificationVC?.showView()
        parent.searchBar.resignFirstResponder()

        parent.verifyCashCodeVC!.atm = atm
    }
}
