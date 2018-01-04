import UIKit
import Firebase

class ChatLogVC: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout{
    
    var user: User? {
        didSet {
            navigationItem.title = user?.name
            observeMessages()
        }
    }
    var messages = [Message]()
    
    func observeMessages() {
        guard let uid = Auth.auth().currentUser?.uid, let toId = user?.id else {
            return
        }
        let UserMessagesRef = Database.database().reference().child("user-message").child(uid).child(toId)
        UserMessagesRef.observe(.childAdded, with: { (snapshot) in
            
            let messageId = snapshot.key
            let messageRef = Database.database().reference().child("messages").child(messageId)
            messageRef.observeSingleEvent(of: .value, with: { (snapshot) in

                guard let dictionary = snapshot.value as? [String: AnyObject] else {
                    return
                }
                let message = Message(dictionary: dictionary)
                
                if message.chatPartnerId() == self.user?.id {
                    self.messages.append(message)
                    DispatchQueue.main.async {
                        self.collectionView?.reloadData()
                    }
                }
            }, withCancel: nil)
        }, withCancel: nil)
    }
    
    
    lazy var inputTextfield: UITextField = {
        let Textfield = UITextField()
        Textfield.placeholder = "Enter message..."
        Textfield.translatesAutoresizingMaskIntoConstraints = false
        Textfield.delegate = self
        return Textfield
    }()

    var cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.contentInset = UIEdgeInsetsMake(8, 0, 58, 0)
        collectionView?.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 58, 0)
        collectionView?.alwaysBounceVertical = true
        collectionView?.backgroundColor = UIColor.white
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        
        collectionView?.keyboardDismissMode = .interactive
        
        setupInputsComponents()
        setupkeyboardObservers()

    }
    
    func setupkeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleketboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleketboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleketboardWillShow(notification: NSNotification) {
        let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue
        let keyboardHeight = keyboardFrame?.cgRectValue.height
        containerViewBottomAnchor?.constant = -CGFloat(keyboardHeight!)
    }
    
    @objc func handleketboardWillHide(notification: NSNotification) {
        containerViewBottomAnchor?.constant = 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        
        let message = messages[indexPath.item]
        cell.textView.text = message.text
        
        setupCell(cell: cell, message: message)
        
//        cell.bubbleWidthAnchor?.constant = estimateFrameforText(text: message.text!).width + 200
        
        return cell
    }
    
    private func setupCell(cell: ChatMessageCell, message: Message) {
        
        if message.fromId == Auth.auth().currentUser?.uid {
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = UIColor.white
            cell.bubbleRightAnchor?.isActive = true
            cell.bubbleLeftAnchor?.isActive = false
        } else {
            cell.bubbleView.backgroundColor = UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1)
            cell.textView.textColor = UIColor.black
            
            cell.bubbleRightAnchor?.isActive = false
            cell.bubbleLeftAnchor?.isActive = true
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80
        if let text = messages[indexPath.item].text {
            height = estimateFrameforText(text: text).height + 20
        }
        return CGSize(width: view.frame.width, height: height)
    }
    
    private func estimateFrameforText(text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        return NSString(string: text).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: [.font : UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    var containerViewBottomAnchor: NSLayoutConstraint?
    
    func setupInputsComponents() {
        let containerview = UIView()
        containerview.backgroundColor = UIColor.white
        containerview.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(containerview)
        
        containerview.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        
        containerViewBottomAnchor = containerview.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        containerViewBottomAnchor?.isActive = true
        
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
        let fromId = Auth.auth().currentUser!.uid
        let timestamp = Int(Date().timeIntervalSince1970)
        let values = ["text": inputTextfield.text!, "toId": toId!, "fromId": fromId, "timestamp": timestamp] as [String : Any]
        
        childRef.updateChildValues(values) { (error, ref) in
            if error != nil {
                print(error!)
                return
            }
            self.inputTextfield.text = nil
            
            let userMessageRef = Database.database().reference().child("user-message").child(fromId).child(toId!)
            let messageId = childRef.key
            userMessageRef.updateChildValues([messageId: 1])
            
            let recipientUserMessagesRef = Database.database().reference().child("user-message").child(toId!).child(fromId)
            recipientUserMessagesRef.updateChildValues([messageId: 1])
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }

}
