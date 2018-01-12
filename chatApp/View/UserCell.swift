import UIKit
import Firebase

class Usercell: UITableViewCell {
    
    let timeLable: UILabel = {
        let lable = UILabel()
        lable.font = UIFont.systemFont(ofSize: 13)
        lable.textColor = UIColor.gray
        lable.translatesAutoresizingMaskIntoConstraints = false
        return lable
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        textLabel?.frame = CGRect(x: textLabel!.frame.origin.x, y: textLabel!.frame.origin.y - 2, width: textLabel!.frame.width, height: textLabel!.frame.height)
        
        detailTextLabel?.frame = CGRect(x: detailTextLabel!.frame.origin.x, y: detailTextLabel!.frame.origin.y + 2, width: detailTextLabel!.frame.width, height: detailTextLabel!.frame.height)
    }
    
    override func awakeFromNib() {
        
        addSubview(timeLable)
        
        timeLable.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        timeLable.topAnchor.constraint(equalTo: self.topAnchor, constant: 18).isActive = true
        timeLable.widthAnchor.constraint(equalToConstant: 100).isActive = true
        timeLable.heightAnchor.constraint(equalTo: (textLabel?.heightAnchor)!).isActive = true
    }

}
