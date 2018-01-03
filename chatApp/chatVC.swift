import UIKit
import Firebase

class chatVC: UITableViewController {
    
    var messages = [Message]()
    
//    let timeLable: UILabel = {
//        let lable = UILabel()
//        lable.text = "hhhh"
//        lable.translatesAutoresizingMaskIntoConstraints = false
//        return lable
//    }()


    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Message", style: .plain, target: self, action: #selector(handleNewMessage))
        observeMessage()
    
    }
    
    func observeMessage() {
        let ref = Database.database().reference().child("messages")
        ref.observe(.childAdded, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String: Any] {
                let message = Message(dictionary: dictionary)
                self.messages.append(message)
                print(self.messages)
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
        }, withCancel: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        fetchdata()
    }
    
    @objc func showchatVCforUser(user: User) {
        let chatlog = ChatLogVC(collectionViewLayout: UICollectionViewFlowLayout())
        chatlog.user = user
        navigationController?.pushViewController(chatlog, animated: true)
    }
    
    @objc func handleNewMessage() {
        let newMessageController = NewMessageVC()
        newMessageController.chatvc = self
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController, animated: true, completion: nil)
    }
    
    func fetchdata() {
        let uid = Auth.auth().currentUser?.uid
        print(uid!)
        Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value) { (snapshot) in

            if let dictionary = snapshot.value as? [String: AnyObject] {
                self.navigationItem.title = dictionary["name"] as? String
                let buttom = UIButton(type: .custom)
                buttom.frame = CGRect(x: 0, y: 0, width: 80, height: 40)
                buttom.setTitle(dictionary["name"] as? String, for: .normal)
                buttom.setTitleColor(UIColor.black, for: .normal)
                buttom.addTarget(self, action: #selector(self.showchatVCforUser), for: .touchUpInside)
                self.navigationItem.titleView = buttom
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellId = "chatVCcell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId)
        let message = messages[indexPath.row]
        if let toId = message.toId {
            let ref = Database.database().reference().child("users").child(toId)
            ref.observe(.value, with: { (snapshot) in
                if let dictionary = snapshot.value as? [String: Any] {
                    cell?.textLabel?.text = dictionary["name"] as? String
                }
            }, withCancel: nil)
        }
        
        let timeLable = UILabel()
        timeLable.translatesAutoresizingMaskIntoConstraints = true
    
        cell?.contentView.addSubview(timeLable)
        timeLable.rightAnchor.constraint(equalTo: (cell?.rightAnchor)!).isActive = true
        timeLable.topAnchor.constraint(equalTo: (cell?.topAnchor)!).isActive = true
        timeLable.widthAnchor.constraint(equalToConstant: 100).isActive = true
        timeLable.heightAnchor.constraint(equalTo: (cell?.textLabel?.heightAnchor)!).isActive = true
        timeLable.backgroundColor = UIColor.red
        timeLable.text = "dddd"
        
        cell?.detailTextLabel?.text = message.text
        return cell!
        
    }



}
