//
//  AppUpdater.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 27/01/2020.
//  Copyright © 2020 Swipster Inc. All rights reserved.
//

import UIKit

enum VersionError: Error {
    case invalidBundleInfo, invalidResponse
}

class LookupResult: Decodable {
    var results: [AppInfo]
}

class AppInfo: Decodable {
    var version: String
}

class AppUpdater: NSObject {

    private override init() {}
    static let shared = AppUpdater()

    func showUpdate(withConfirmation: Bool) {
        DispatchQueue.global().async {
            self.checkVersion(force : !withConfirmation)
        }
    }

    private  func checkVersion(force: Bool) {
        let info = Bundle.main.infoDictionary
        if let currentVersion = info?["CFBundleShortVersionString"] as? String {
            _ = getAppInfo { (info, error) in
                if let appStoreAppVersion = info?.version{
                    guard let appStoreIntVersion = Int(appStoreAppVersion.replacingOccurrences(of: ".", with: "")) else { return }
                    guard let currentIntVersion = Int(currentVersion.replacingOccurrences(of: ".", with: "")) else { return }
                    if error == nil {
                        if appStoreIntVersion > currentIntVersion {
                            print("Needs update: AppStore Version: \(appStoreAppVersion) > Current version: ",currentVersion)
                            DispatchQueue.main.async {
                                let topController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!
                                topController.showAppUpdateAlert(version: (info?.version)!, force: force)
                            }
                        } else if appStoreIntVersion < currentIntVersion {
                            print("Running Beta Version of © Swipster")
                        } else {
                            print("Already on the last app version: ",currentVersion)
                        }
                    } else {
                        print(error?.localizedDescription ?? "error not found")
                    }
                }
            }
        }
    }

    private func getAppInfo(completion: @escaping (AppInfo?, Error?) -> Void) -> URLSessionDataTask? {
        guard let identifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String,
            let url = URL(string: "http://itunes.apple.com/lookup?bundleId=\(identifier)") else {
                DispatchQueue.main.async {
                    completion(nil, VersionError.invalidBundleInfo)
                }
                return nil
        }
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            do {
                if let error = error { throw error }
                guard let data = data else { throw VersionError.invalidResponse }
                let result = try JSONDecoder().decode(LookupResult.self, from: data)
                guard let info = result.results.first else { throw VersionError.invalidResponse }

                completion(info, nil)
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
        return task
    }
}

extension UIViewController {
    fileprivate func showAppUpdateAlert(version : String, force: Bool) {
        
        let appUrlString = "https://itunes.apple.com/fr/app/swipster/id1444964003?mt=8"

        let alertTitle = "Nouvelle version disponible"
        let alertMessage = "Veuillez mettre l'application à jour afin de profiter des dernières nouveautés"

        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)

        if !force {
            let notNowButton = UIAlertAction(title: "Plus tard", style: .default)
            alertController.addAction(notNowButton)
        }
        
        let updateButton = UIAlertAction(title: "Mettre à jour", style: .default) { (action:UIAlertAction) in
            guard let url = URL(string: appUrlString) else {
                return
            }
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
        alertController.addAction(updateButton)
        
        present(alertController, animated: true, completion: nil)
    }
}
