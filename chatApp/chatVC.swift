import UIKit
import Firebase

class chatVC: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Message", style: .plain, target: self, action: #selector(handleNewMessage))
//        let tapgesture = UITapGestureRecognizer(target: self, action: #selector(showchatVC))
   
    }
    
    override func viewDidAppear(_ animated: Bool) {
        fetchdata()

        
    }
    
    @objc func showchatVC() {
        print("123")
    }
    
    @objc func handleNewMessage() {
        let newMessageController = NewMessageVC()
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController, animated: true, completion: nil)
    }
    
    func fetchdata() {
        let uid = Auth.auth().currentUser?.uid
        print(uid!)
        Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value) { (snapshot) in

            if let dictionary = snapshot.value as? [String: AnyObject] {
                self.navigationItem.title = dictionary["name"] as? String
            }
        }
    }



    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }



}
