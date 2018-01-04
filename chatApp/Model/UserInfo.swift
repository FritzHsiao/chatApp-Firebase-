import Foundation

class User: NSObject {
    var id: String?
    var name: String?
    var email: String?
    
    
    init(dictionary: [String: AnyObject]) {
        self.id = dictionary["id"] as? String
        self.name = dictionary["name"] as? String
        self.email = dictionary["email"] as? String

    }
}
