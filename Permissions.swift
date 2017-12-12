// Permissions.swift
//
// Copyright (c) 2017 Alex Bofu
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import UIKit
import Photos
import Contacts
import UserNotifications
import CoreLocation
import EventKit
import AVFoundation
import CoreBluetooth
import LocalAuthentication
import HealthKit

enum PermissionType: String {
    case contacts       = "Contacts"
    case camera         = "Camera"
    case photos         = "Photos"
    case location       = "Location"
    case notifications  = "Notifications"
    case calendar       = "Calendar"
    case microphone     = "Microphone"
    case bluetooth      = "Bluetooth"
    case biometry       = "Biometry"
    case health         = "Health"
}

extension PermissionType {
    var errorDescription : String {
        return "You must grant access to \(self.rawValue) in order to use this feature"
    }
    
}

enum PermissionStatus: String {
    case authorized    = "Authorized"
    case denied        = "Denied"
    case disabled      = "Disabled"
    case notDetermined = "Not Determined"
}

extension PermissionStatus: CustomStringConvertible {
    public var description: String { return rawValue }
}

protocol Permissions {}

extension Permissions {
    typealias Callback = (PermissionStatus) -> Void
}

//MARk - contacts
extension Permissions {
    var contactsStatus: PermissionStatus {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        
        switch status {
        case .authorized:          return .authorized
        case .restricted, .denied: return .denied
        case .notDetermined:       return .notDetermined
        }
    }
    
    func requestContacts(_ callback: Callback?) {
        CNContactStore().requestAccess(for: .contacts) { _, _ in
            callback?(self.contactsStatus)
        }
    }
}

//MARK: - camera
extension Permissions {
    var cameraStatus: PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:          return .authorized
        case .restricted, .denied: return .denied
        case .notDetermined:       return .notDetermined
        }
    }
    
    func requestCamera(_ callback: @escaping Callback) {
        AVCaptureDevice.requestAccess(for: .video) { _ in
            callback(self.cameraStatus)
        }
    }
}

//MARK: - library
extension Permissions {
    var photosStatus: PermissionStatus {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized:          return .authorized
        case .denied, .restricted: return .denied
        case .notDetermined:       return .notDetermined
        }
    }
    
    func requestPhotos(_ callback: @escaping Callback) {
        PHPhotoLibrary.requestAuthorization { _ in
            callback(self.photosStatus)
        }
    }
}

//MARK: - location
extension Permissions where Self: UIViewController {
    var locationManager: CLLocationManager {
        let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }
    
    var locationStatus: PermissionStatus {
        let status = CLLocationManager.authorizationStatus()
        
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:          return .authorized
        case .denied, .restricted:                             return .denied
        case .notDetermined:                                   return .notDetermined
        }
    }
    
    func requestWhenInUseLocation(_ callback: @escaping Callback) {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestAlwaysLocation(_ callback: @escaping Callback) {
        locationManager.requestAlwaysAuthorization()
    }
}

extension UIViewController: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
    }
}

//MARK: - notifications
extension Permissions {
    var notificationStatus: PermissionStatus {
        let status = UIApplication.shared.isRegisteredForRemoteNotifications
        
        switch status {
        case true:                                          return .authorized
        case false:                                         return .denied
        }
    }
    
    func requestNotification(_ callback: @escaping Callback) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
            callback(granted ? .authorized : .denied)
        }
    }
}

//MARK: - calendar
extension Permissions {
    var calendarStatus: PermissionStatus {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .authorized:                                      return .authorized
        case .denied, .restricted:                             return .denied
        case .notDetermined:                                   return .notDetermined
        }
    }
    
    func requestCalendar(_ callback: @escaping Callback) {
        EKEventStore().requestAccess(to: .event) { (granted, error) in
            callback(error == nil ? (granted ? .authorized : .denied) : .notDetermined)
        }
    }
}

//MARK: - microphone
extension Permissions {
    var microphoneStatus: PermissionStatus {
        let status = AVAudioSession.sharedInstance().recordPermission()
        
        switch status {
        case .granted:                                         return .authorized
        case .denied:                                          return .denied
        case .undetermined:                                    return .notDetermined
        }
    }
    
    func requestMicrophone(_ callback: @escaping Callback) {
        AVAudioSession.sharedInstance().requestRecordPermission { (granted) in
            callback(granted ? .authorized : .denied)
        }
    }
}

//MARK: - bluetooth
extension Permissions {
    var bluetoothStatus: PermissionStatus {
        let status = CBPeripheralManager.authorizationStatus()
        
        switch status {
        case .authorized:                                      return .authorized
        case .denied, .restricted:                             return .denied
        case .notDetermined:                                   return .notDetermined
        }
    }
    
    func requestBluetooth(_ callback: @escaping Callback) {
        
    }
}

//MARK: - biometry
extension Permissions {
    var biometryStatus: PermissionStatus {
        var authError: NSError?
        let status = LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError)
        
        switch status {
        case true:                                          return .authorized
        case false:                                         return .denied
        }
    }
    
    func requestBiometry(for reason: String, _ callback: @escaping Callback) {
        LAContext().evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { (granted, error) in
            callback(error == nil ? (granted ? .authorized : .denied) : .notDetermined)
        }
    }
}

//MARK: - health
extension Permissions {
    var healthStatus: PermissionStatus {
        let status = HKHealthStore.isHealthDataAvailable()
        
        switch status {
        case true:                                          return .authorized
        case false:                                         return .denied
        }
    }
    
    func requestHealth(_ callback: @escaping Callback) {
        HKHealthStore().requestAuthorization(toShare: [], read: []) { (granted, error) in
            callback(error == nil ? (granted ? .authorized : .denied) : .notDetermined)
        }
    }
}

//MARK: - generic alert
extension Permissions where Self: UIViewController {
    func showAlert(for type: PermissionType) {
        DispatchQueue.main.async { [weak self] in
            guard self?.isViewLoaded == true else { return }
            guard self?.view.window != nil else { return }
            
            let alertController = UIAlertController(title: type.rawValue, message: type.errorDescription, preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: { (alert) in
                guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else { return }
                UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
            }))
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ _ in }))
            
            self?.present(alertController, animated: true, completion: nil)
        }
    }
}

