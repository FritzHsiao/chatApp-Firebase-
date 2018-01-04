import UIKit
import Firebase

class chatVC: UITableViewController {
    
    var messages = [Message]()
    var messageDictionary = [String: Message]()
    
    //    let timeLable: UILabel = {
    //        let lable = UILabel()
    //        lable.text = "hhhh"
    //        lable.translatesAutoresizingMaskIntoConstraints = false
    //        return lable
    //    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messages.removeAll()
        messageDictionary.removeAll()
        tableView.reloadData()
        
        observeUserMessages()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Message", style: .plain, target: self, action: #selector(handleNewMessage))
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        messages.removeAll()
        messageDictionary.removeAll()
        tableView.reloadData()
        
        observeUserMessages()
    }
    
    func observeUserMessages() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference().child("user-message").child(uid)
        ref.observe(.childAdded, with: { (snapshot) in
            
            let userId = snapshot.key
            Database.database().reference().child("user-message").child(uid).child(userId).observe(.childAdded, with: { (snapshot) in
                let messageId = snapshot.key
                let messagesRef = Database.database().reference().child("messages").child(messageId)
                messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                    
                    if let dictionary = snapshot.value as? [String: Any] {
                        let message = Message(dictionary: dictionary)
                        
                        if let chatPartnerId = message.chatPartnerId() {
                            self.messageDictionary[chatPartnerId] = message
                            self.messages = Array(self.messageDictionary.values)
                            self.messages.sort(by: { (message1, message2) -> Bool in
                                return message1.timestamp!.intValue > message2.timestamp!.intValue
                            })
                        }
                        self.timer?.invalidate()
                        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
                        
                    }
                }, withCancel: nil)
                
            }, withCancel: nil)
            
        }, withCancel: nil)
    }
    
    var timer: Timer?
    @objc func handleReloadTable() {
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
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
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value) { (snapshot) in
            
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
        let chatPartnerId: String?
        if message.fromId == Auth.auth().currentUser?.uid {
            chatPartnerId = message.toId
        } else {
            chatPartnerId = message.fromId
        }
        if let Id = chatPartnerId {
            let ref = Database.database().reference().child("users").child(Id)
            ref.observe(.value, with: { (snapshot) in
                if let dictionary = snapshot.value as? [String: Any] {
                    cell?.textLabel?.text = dictionary["name"] as? String
                }
            }, withCancel: nil)
        }
        
        //        let timeLable = UILabel()
        //        timeLable.translatesAutoresizingMaskIntoConstraints = true
        //
        //        cell?.contentView.addSubview(timeLable)
        //        timeLable.rightAnchor.constraint(equalTo: (cell?.rightAnchor)!).isActive = true
        //        timeLable.topAnchor.constraint(equalTo: (cell?.topAnchor)!).isActive = true
        //        timeLable.widthAnchor.constraint(equalToConstant: 100).isActive = true
        //        timeLable.heightAnchor.constraint(equalTo: (cell?.textLabel?.heightAnchor)!).isActive = true
        //        timeLable.backgroundColor = UIColor.red
        //        let time = Date(timeIntervalSince1970: message.timestamp as! TimeInterval)
        //        let formatter = DateFormatter()
        //        formatter.dateFormat = "hh:mm:ss a"
        //        timeLable.text = formatter.string(from: time)
        
        cell?.detailTextLabel?.text = message.text
        return cell!
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        guard let chatPartnerId = message.chatPartnerId() else {
            return
        }
        
        let ref = Database.database().reference().child("users").child(chatPartnerId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            print(snapshot)
            guard let dictionary = snapshot.value as? [String: AnyObject] else {
                return
            }
            let user = User(dictionary: dictionary)
            user.id = chatPartnerId
            self.showchatVCforUser(user: user)
            
        }, withCancel: nil)
        
    }
    
    
    
}
