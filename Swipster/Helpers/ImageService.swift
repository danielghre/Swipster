//
//  ImageService.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 17/04/2018.
//  Copyright © 2018 Swipster Inc. All rights reserved.
//

import UIKit

class ImageService {
    
    static let cache = NSCache<NSString, UIImage>()
    static func downloadImage(withURL url: URL, completion: @escaping (_ image: UIImage?)->()) {
        let dataTask = URLSession.shared.dataTask(with: url) {data, responseURL, error in
            var downloadedImage: UIImage?
            if let data = data {
                downloadedImage = UIImage(data: data)
            }
            
            if (downloadedImage != nil) {
                cache.setObject(downloadedImage!, forKey: url.absoluteString as NSString)
            }
            DispatchQueue.main.async {
                completion(downloadedImage)
            }
        }
        dataTask.resume()
    }
    
    static func getImage(withURL url: URL?, completion: @escaping (_ image: UIImage?)->()) {
        guard let url = url else { return }
        if let image = cache.object(forKey: url.absoluteString as NSString) {
            completion(image)
        } else {
            downloadImage(withURL: url, completion: completion)
        }
    }
}
