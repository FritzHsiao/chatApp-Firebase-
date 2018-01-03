import UIKit
import Firebase

class ChatLogVC: UICollectionViewController, UITextFieldDelegate{
    
    var user: User? {
        didSet {
            navigationItem.title = user?.name
            
        }
    }
    
    
    lazy var inputTextfield: UITextField = {
        let Textfield = UITextField()
        Textfield.placeholder = "Enter message..."
        Textfield.translatesAutoresizingMaskIntoConstraints = false
        Textfield.delegate = self
        return Textfield
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.backgroundColor = UIColor.white
        setupInputsComponents()

    }
    
    func setupInputsComponents() {
        let containerview = UIView()
        containerview.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(containerview)
        
        containerview.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        containerview.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        containerview.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        containerview.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let sendBut = UIButton(type: .system)
        sendBut.setTitle("Send", for: .normal)
        sendBut.translatesAutoresizingMaskIntoConstraints = false
        sendBut.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        containerview.addSubview(sendBut)
        sendBut.rightAnchor.constraint(equalTo: containerview.rightAnchor).isActive = true
        sendBut.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendBut.heightAnchor.constraint(equalTo: containerview.heightAnchor).isActive = true
        sendBut.centerYAnchor.constraint(equalTo: containerview.centerYAnchor).isActive = true
        

        containerview.addSubview(inputTextfield)
        inputTextfield.leftAnchor.constraint(equalTo: containerview.leftAnchor, constant: 8).isActive = true
        inputTextfield.centerYAnchor.constraint(equalTo: containerview.centerYAnchor).isActive = true
        inputTextfield.rightAnchor.constraint(equalTo: sendBut.leftAnchor).isActive = true
        inputTextfield.heightAnchor.constraint(equalTo: containerview.heightAnchor).isActive = true
        
        let separatorLine = UIView()
        separatorLine.backgroundColor = UIColor.gray
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        containerview.addSubview(separatorLine)
        separatorLine.leftAnchor.constraint(equalTo: containerview.leftAnchor).isActive = true
        separatorLine.topAnchor.constraint(equalTo: containerview.topAnchor).isActive = true
        separatorLine.widthAnchor.constraint(equalTo: containerview.widthAnchor).isActive = true
        separatorLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
    
    @objc func handleSend() {
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let toId = user?.id
        let fromId = Auth.auth().currentUser?.uid
        let timestamp = Int(Date().timeIntervalSince1970)
        let values = ["text": inputTextfield.text!, "toId": toId!, "fromId": fromId, "timestamp": timestamp] as [String : Any]
        childRef.updateChildValues(values)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }

}
