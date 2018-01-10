import UIKit

let imageCache = NSCache<AnyObject, AnyObject>()

extension UIImageView {
    
    func loadImageWithUrl(urlString: String) {
        self.image = nil
        if let cacheImage = imageCache.object(forKey: urlString as AnyObject) as? UIImage {
            self.image = cacheImage
            return
        }
        
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!) { (data, response, error) in
            if error != nil {
                print("fail to load image")
                return
            }
            
            DispatchQueue.main.async {
                if let downlaodedimage = UIImage(data: data!) {
                    imageCache.setObject(downlaodedimage, forKey: urlString as AnyObject)
                    self.image = downlaodedimage
                }
            }
        }.resume()
        
    }
}
