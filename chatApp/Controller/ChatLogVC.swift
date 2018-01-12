import UIKit
import Firebase
import AVFoundation
import MobileCoreServices

class ChatLogVC: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
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
                self.messages.append(message)
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                    let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath , at: .bottom, animated: true)
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(handlekeyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handlekeyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handlekeyboardDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handlekeyboardDidShow() {
        if messages.count > 0 {
            let indexPath = IndexPath(item: messages.count - 1, section: 0)
            collectionView?.scrollToItem(at: indexPath, at: .top, animated: true)
        }
    }
    
    @objc func handlekeyboardWillShow(notification: NSNotification) {
        let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue
        let keyboardHeight = keyboardFrame?.cgRectValue.height
        containerViewBottomAnchor?.constant = -CGFloat(keyboardHeight!)
        let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double
        UIView.animate(withDuration: duration!) {
            self.view.layoutIfNeeded()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    @objc func handlekeyboardWillHide(notification: NSNotification) {
        containerViewBottomAnchor?.constant = 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        cell.ChatLogVC = self
        
        let message = messages[indexPath.item]
        cell.message = message
        cell.textView.text = message.text
        
        setupCell(cell: cell, message: message)
        
        if let text = message.text {
            cell.bubbleWidthAnchor?.constant = estimateFrameforText(text: text).width + 30
            cell.textView.isHidden = false
        } else if message.imageUrl != nil {
            cell.bubbleWidthAnchor?.constant = 200
            cell.textView.isHidden = true
        }
        cell.playButton.isHidden = message.videoUrl == nil
        
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
        
        if let messageImageUrl = message.imageUrl {
            cell.messageImageView.loadImageWithUrl(urlString: messageImageUrl)
//            cell.messageImageView.transform.rotated(by: CGFloat.pi / 2)
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = UIColor.clear
        } else {
            cell.messageImageView.isHidden = true
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80
        let message = messages[indexPath.item]
        if let text = message.text {
            height = estimateFrameforText(text: text).height + 20
        } else if let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue {
            height = CGFloat(imageHeight / imageWidth * 200)
            
        }
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: height)
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
        
        let uploadImageView = UIImageView()
        uploadImageView.isUserInteractionEnabled = true
        uploadImageView.image = UIImage(named: "photo-camera")
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleUploadTap)))
        containerview.addSubview(uploadImageView)
        //x,y,w,h
        uploadImageView.leftAnchor.constraint(equalTo: containerview.leftAnchor).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: containerview.centerYAnchor).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        
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
        inputTextfield.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor, constant: 8).isActive = true
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
    
    @objc func handleUploadTap() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? URL {
            
            handleVideoSelectedForUrl(url: videoUrl)

        } else {
            
            handleImageSelectedForInfo(info: info)
        }

        dismiss(animated: true, completion: nil)
    }
    
    private func handleVideoSelectedForUrl(url: URL) {
        let filename = NSUUID().uuidString
        let uploadTask = Storage.storage().reference().child("message_movies").child(filename).putFile(from: url, metadata: nil
            , completion: { (metadata, error) in
                if error != nil {
                    print("fail to upload video")
                }
                if let videoUrl = metadata?.downloadURL()?.absoluteString {
                    print(videoUrl)
                    
                    if let thumbnailImage = self.thumbnailImageForFileUrl(fileurl: url) {
                        
                        self.uploadtoFirebaseStorageUsingImage(image: thumbnailImage, competion: { (imageUrl) in
                            let ref = Database.database().reference().child("messages")
                            let childRef = ref.childByAutoId()
                            let toId = self.user?.id
                            let fromId = Auth.auth().currentUser!.uid
                            let timestamp = Int(Date().timeIntervalSince1970)
                            
                            let values = ["toId": toId!, "fromId": fromId, "timestamp": timestamp, "imageUrl": imageUrl, "imageWidth": thumbnailImage.size.width, "imageHeight": thumbnailImage.size.height, "videoUrl": videoUrl] as [String : Any]
                            
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
                        })
                    }
                }
        })
        uploadTask.observe(.progress) { (snapshot) in
            if let completedUnitCount = snapshot.progress?.completedUnitCount {
                self.navigationItem.title = String(completedUnitCount)
            }
        }
        
        uploadTask.observe(.success) { (snapshot) in
            self.navigationItem.title = self.user?.name
        }
        
    }
    
    private func thumbnailImageForFileUrl(fileurl: URL) -> UIImage? {
        let asset = AVAsset(url: fileurl)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        do {            
            let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(1, 60), actualTime: nil)
            return UIImage(cgImage: thumbnailCGImage)
            
        } catch let err {
            print(err)
        }
        return nil
    }
    
    private func handleImageSelectedForInfo(info: [String: Any]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let orinalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = orinalImage
        }
        if let selectedImage = selectedImageFromPicker {
            uploadtoFirebaseStorageUsingImage(image: selectedImage, competion: { (imageUrl) in
                self.sendMessageWithImageUrl(imageUrl: imageUrl, image: selectedImage)
                
            })
        }
        
    }
    
    private func uploadtoFirebaseStorageUsingImage(image: UIImage, competion: @escaping (_ imageUrl: String) -> ()) {
        let imageName = NSUUID().uuidString
        let ref = Storage.storage().reference().child("message_images").child(imageName)
        
        if let uploaData = UIImageJPEGRepresentation(image, 0.2) {
            ref.putData(uploaData, metadata: nil
                , completion: { (metadata, error) in
                    
                    if error != nil {
                        print("fail to upload image", error!)
                        return
                    }
                    
                    if let imageUrl = metadata?.downloadURL()?.absoluteString {
                        competion(imageUrl)
                    }
                    
            })
        }
    }
    
    private func sendMessageWithImageUrl(imageUrl: String, image: UIImage) {
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let toId = user?.id
        let fromId = Auth.auth().currentUser!.uid
        let timestamp = Int(Date().timeIntervalSince1970)
        
        let values = ["toId": toId!, "fromId": fromId, "timestamp": timestamp, "imageUrl": imageUrl, "imageWidth": image.size.width, "imageHeight": image.size.height] as [String : Any]
        
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
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
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
    
    var startingFrame: CGRect?
    var blackBackgroundView: UIView?
    var startingImageView: UIImageView?
    
    func performZoomInForStartingImageView(startingImageView: UIImageView) {
        self.startingImageView = startingImageView
        self.startingImageView?.isHidden = true
        
        startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
        let zoomingImageView = UIImageView(frame: startingFrame!)
        zoomingImageView.image = startingImageView.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
        
        if let keywindow = UIApplication.shared.keyWindow {
            blackBackgroundView = UIView(frame: keywindow.frame)
            blackBackgroundView?.backgroundColor = UIColor.black
            blackBackgroundView?.alpha = 0
            
            keywindow.addSubview(blackBackgroundView!)
            keywindow.addSubview(zoomingImageView)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.blackBackgroundView?.alpha = 1
                self.inputTextfield.alpha = 0
                
                let height = self.startingFrame!.height / self.startingFrame!.width * keywindow.frame.width
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keywindow.frame.width, height: height)
                zoomingImageView.center = keywindow.center
            }, completion: { (completed: Bool) in
                
            })
        }
    }
    
    @objc func handleZoomOut(tapgesture: UITapGestureRecognizer) {
        if let zoomOutImageView = tapgesture.view {
            zoomOutImageView.layer.cornerRadius = 16
            zoomOutImageView.clipsToBounds = true
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                zoomOutImageView.frame = self.startingFrame!
                self.blackBackgroundView?.alpha = 0
            }, completion: { (completed: Bool) in
                zoomOutImageView.removeFromSuperview()
                self.startingImageView?.isHidden = false
            })
        }
    }


}
