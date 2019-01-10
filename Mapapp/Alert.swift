//
//  Alert.swift
//  Mapapp
//
//  Created by Leonardo Bilia on 1/9/19.
//  Copyright © 2019 Leonardo Bilia. All rights reserved.
//

import UIKit

struct Alert {
    private static func showBasicAlertOn(_ vc: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        DispatchQueue.main.async { vc.present(alert, animated: true, completion: nil) }
    }
    
    private static func showAlertWithCompletionOn(_ vc: UIViewController, title: String, message: String, btnTitle: String, style: UIAlertAction.Style, completion: @escaping ()->()) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: btnTitle, style: style, handler: { (action) in
            completion()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        DispatchQueue.main.async { vc.present(alert, animated: true, completion: nil) }
    }
}

extension Alert {
    
    static func showErrorWithLocalizedDescription(on vc: UIViewController, description: String?) {
        showBasicAlertOn(vc, title: "Ooops!", message: description ?? "Something went wrong while processing your request.")
    }
    
    static func showLocationServicesNotEnabled(on vc: UIViewController) {
        showAlertWithCompletionOn(vc, title: "Ooops!", message: "Your location service is disabled! Please, turn on the location services in your device setting.", btnTitle: "Device Settings", style: .default) {
            UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
        }
    }
    
    static func showLocationServicesRestricted(on vc: UIViewController) {
        showBasicAlertOn(vc, title: "Ooops!", message: "Your location service is current restricted.")
    }
    
    static func showCurrentLocationNotAvailable(on vc: UIViewController) {
        showBasicAlertOn(vc, title: "Ooops!", message: "Your current location is not available.")
    }
    
    static func showClearRouteAlert(on vc: UIViewController, completion: @escaping () -> ()) {
        showAlertWithCompletionOn(vc, title: "Clear Route", message: "Would you like to clear the route to the destination point?", btnTitle: "Clear", style: .destructive) {
            completion()
        }
    }
}
