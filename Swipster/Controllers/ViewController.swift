//
//  ViewController.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 22/03/2018.
//  Copyright © 2018 Swipster Inc. All rights reserved.
//

import UIKit
import FacebookLogin
import FacebookCore
import FirebaseAuth
import Firebase
import FirebaseDatabase
import SafariServices
import SwiftEntryKit
import AuthenticationServices
#if canImport(CryptoKit)
import CryptoKit
#endif

class ViewController: UIViewController {
    
    @IBOutlet private weak var connectionButton: UIButton!
    @IBOutlet private weak var privacy: UIButton!
    let loginSpaceStack = CGFloat(10)
    
    @IBAction func privacyButton(_ sender: Any) {
        let svc = SFSafariViewController(url: URL(string: "https://www.swipster.io/privacy")!)
        present(svc, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        privacy.underline()
        connectionButton.layer.borderWidth = 1
        connectionButton.layer.borderColor = UIColor(white: 1, alpha: 1).cgColor
        
        if #available(iOS 13, *) {
            addSignInWithApple()
        }
        
    }
    
    @available(iOS 13, *)
    func addSignInWithApple() {
        let authorizationButton = ASAuthorizationAppleIDButton(type: .signIn, style: .white)
        authorizationButton.addTarget(self, action: #selector(handleAuthorizationAppleIDButtonPress), for: .touchUpInside)
        let label = UILabel()
        label.text = "- OU -"
        label.textAlignment = .center
        label.font = .italicSystemFont(ofSize: 14)
        label.textColor = .white
        let signInStackView = UIStackView(arrangedSubviews: [authorizationButton, label])
        signInStackView.spacing = loginSpaceStack
        signInStackView.axis = .vertical
        view.addSubview(signInStackView)
        signInStackView.translatesAutoresizingMaskIntoConstraints = false
        authorizationButton.widthAnchor.constraint(equalToConstant: 280).isActive = true
        authorizationButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        signInStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signInStackView.bottomAnchor.constraint(equalTo: connectionButton.topAnchor, constant: -loginSpaceStack).isActive = true
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if length == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    fileprivate var currentNonce: String?
    
    @available(iOS 13, *)
    @objc func handleAuthorizationAppleIDButtonPress() {
        
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
        #if canImport(CryptoKit)
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        return hashString
        #endif
        return ""
    }
    
    func showAlertPopup(){
        showPopupMessage(title: "Impossible..", buttonTitle: "Compris !", description: "Une erreur est survenu, veuillez réessayer plus tard !", image: #imageLiteral(resourceName: "ic_error_all_light_48pt")) {
            SwiftEntryKit.dismiss()
        }
        SwiftEntryKit.dismiss(.enqueued)
    }

    @IBAction func facebookLogin(sender: UIButton) {
        let loginManager = LoginManager()
        loginManager.logIn(permissions: [.publicProfile, .email, .userGender, .userBirthday], viewController: self) { [weak self] (result) in
            self?.didReceiveFacebookLoginResult(result)
        }
//        retrieveUserInfoMissing()
    }
    
    func retrieveUserInfoMissing() {
        let query = Database.database().reference().child("users")
        query.observeSingleEvent(of: .value) { (snapshot) in
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                guard let dict = child.value as? [String: Any] else { return }

                let user = User(dictionary: dict)

                if user.first_name == "" {
                    print("\(child.key) missing first name")
                    query.child(child.key).removeValue()
                }

                if user.minAge == "" {
                    print("\(child.key) missing min age")
                    query.child(child.key).updateChildValues(["minAge":"18"])
                }

                if user.maxAge == "" {
                    print("\(child.key) missing max age")
                    query.child(child.key).updateChildValues(["maxAge":"18"])
                }

                if user.lookingFor == "" {
                    print("\(child.key) missing looking for")
                    let values = user.gender == "male" ? ["lookingFor":"female"] : ["lookingFor":"male"]
                    query.child(child.key).updateChildValues(values)
                }

                if user.pictureURL == "" {
                   print("\(child.key) missing pic url")
                    query.child(child.key).updateChildValues(["pictureURL":"https://graph.facebook.com/\(user.uid)/picture?height=500&?width=500"])
                }

                if user.lookingDist == "" {
                    print("\(child.key) missing looking dist")
                    query.child(child.key).updateChildValues(["lookingDistance":"26"])
                }

                if user.active == "" {
                    print("\(child.key) missing active")
                    query.child(child.key).updateChildValues(["public":"true"])
                }
            }
        }
    }
    
    private func didReceiveFacebookLoginResult(_ result: LoginResult) {
        switch result {
        case .success(let grantedPermission, _, let accessToken):
            showLoadingView(text: "Veuillez patienter...")
            print(grantedPermission)
            didLoginWithFacebook(with: accessToken)
        case .cancelled:
            print("cancel")
        case .failed(let error):
            print("Login failed with error \(error)")
            showAlertPopup()
            break
        }
    }
    
    fileprivate func didLoginWithFacebook(with accessToken: AccessToken) {
        let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
        Auth.auth().signIn(with: credential, completion: { [weak self] (authResult, error) in
            if error != nil {
                guard let errorCode = AuthErrorCode(rawValue: error!._code) else { return }
                switch errorCode {
                case .accountExistsWithDifferentCredential:
                    showPopupMessage(title: "Oops..", buttonTitle: "J'ai compris !", description: "Votre adresse email est déjà associée à un compte Apple. Veuillez utiliser celui ci afin de vous connecter. Merci", image: #imageLiteral(resourceName: "ic_error_all_light_48pt")) { [weak self] in
                        SwiftEntryKit.dismiss(.all)
                        if #available(iOS 13, *) {
                            self?.handleAuthorizationAppleIDButtonPress()
                        }
                    }
                    break
                default:
                    print(error!.localizedDescription)
                    return
                }
            } else {
                guard let uid = authResult?.user.uid else { return }
                self?.checkIfUserExist(uid: uid) { [weak self] (result) in
                    if !result {
                        self?.fbGraphRequest(uid: uid)
                    }
                }
            }
        })
    }

    func checkIfUserExist(uid: String, completion: @escaping (_ available:Bool)->()){
        let ref = Database.database().reference().child("users").child(uid)
        ref.observeSingleEvent(of: .value) { [weak self] (snapshot) in
            if snapshot.exists() {
                guard let dict = snapshot.value as? [String: Any] else { return }
                let me = User(dictionary: dict)
                if me.first_name == "" {
                    completion(false)
                } else {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "swipe")
                    vc.modalPresentationStyle = .fullScreen
                    self?.present(vc, animated: true, completion: {
                        SwiftEntryKit.dismiss()
                    })
                    completion(true)
                }
                
                return
            } else {
                completion(false)
            }
        }
    }
    
    func fbGraphRequest(uid: String) {
        
        let myGraphRequest = GraphRequest(graphPath: "/me", parameters: ["fields": "id, first_name, email, birthday, gender, picture"], tokenString: AccessToken.current?.tokenString, version: Settings.defaultGraphAPIVersion, httpMethod: .get)
        myGraphRequest.start(completionHandler: { [weak self] (connection, result, error) in
            guard let self = self else { return }
            if error != nil {
                self.showAlertPopup()
            } else {
                let values = result as! [String : Any]
                guard let id = values["id"] else { return }
                let lookingFor = values["gender"] as! String == "male" ? "female" : "male"
                
                let moreInfos = ["pictureURL": "https://graph.facebook.com/\(id)/picture?height=500&?width=500", "lookingFor": lookingFor, "lookingDistance": "26", "minAge":"18", "maxAge":"26", "public": "true"]
                
                let mergevalues = values.merging(moreInfos as [String : AnyObject], uniquingKeysWith: { (_, last) in last })

                createUser(uid: uid, values: mergevalues, completion: { [weak self] in
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "swipe")
                    vc.modalPresentationStyle = .fullScreen
                    self?.present(vc, animated: true, completion: {
                        SwiftEntryKit.dismiss()
                    })
                })
            }
        })
    }
}

@available(iOS 13.0, *)
extension ViewController: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        showLoadingView(text: "Veuillez patientez...")
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }

            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
        
            Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                if let fb = AccessToken.current?.tokenString {
                    let fbCredential = FacebookAuthProvider.credential(withAccessToken: fb)
                    Auth.auth().currentUser?.link(with: fbCredential, completion: { (_, err) in
                        print("user successful linked")
                    })
                }
                
                guard let uid = authResult?.user.uid else { return }
                self?.checkIfUserExist(uid: uid) { (result) in
                    if !result {
                        SwiftEntryKit.dismiss(.all)
                        let storyboard = UIStoryboard(name: "MoreInfos", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "moreInfos") as! MoreInfosViewController
                        vc.first_name = appleIDCredential.fullName?.givenName
                        vc.email = appleIDCredential.email
                        self?.present(vc, animated: true)
                    }
                }
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple errored: \(error)")
    }

}

extension ViewController: ASAuthorizationControllerPresentationContextProviding {
    @available(iOS 13.0, *)
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
