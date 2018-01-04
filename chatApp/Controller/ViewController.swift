import UIKit
import Firebase

class ViewController: UIViewController {

    @IBOutlet weak var tfname: UITextField!
    @IBOutlet weak var tfemail: UITextField!
    @IBOutlet weak var tfpassword: UITextField!
    @IBOutlet weak var LoginRegisterBt: UIButton!
    
    @IBOutlet weak var LoginRegisterSeg: UISegmentedControl!
    var ref: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        LoginRegisterSeg.selectedSegmentIndex = 0
        setButtom()
    }
    
    @IBAction func LoginRegister(_ sender: Any) {
        setButtom()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func setButtom() {
        let selectedIndex = LoginRegisterSeg.selectedSegmentIndex
        if selectedIndex == 0 {
            LoginRegisterBt.setTitle("Login", for: .normal)
            tfname.isHidden = true
        } else if selectedIndex == 1 {
            LoginRegisterBt.setTitle("Register", for: .normal)
            tfname.isHidden = false
        }
    }

    @IBAction func Register(_ sender: Any) {
        
        if LoginRegisterSeg.selectedSegmentIndex == 0 {
            Login()
        } else if LoginRegisterSeg.selectedSegmentIndex == 1 {
            register()
        }
        
    }
    
    func Login() {
        
        let emailin = tfemail.text!
        let passwordin = tfpassword.text!

        Auth.auth().signIn(withEmail: emailin, password: passwordin) { (user, error) in
            
            if error != nil {
                print(error!)
                return
            }            
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
    func register() {
        let emailin = tfemail.text!
        let passwordin = tfpassword.text!
        let namein = tfname.text!
        
        Auth.auth().createUser(withEmail: emailin, password: passwordin) { (user, error) in
            
            if error != nil{
                print(error!)
                return
            }
            
            guard let uid = user?.uid else {
                return
            }
            let ref = Database.database().reference(fromURL: "https://chatapp-681e6.firebaseio.com/")
            let userReference = ref.child("users").child(uid)
            let values = ["name": namein, "email": emailin]
            userReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
                
                if err != nil {
                    print(err!)
                    return
                }
                self.dismiss(animated: true, completion: nil)
            })
            
        }
        
        
    }
    


}

