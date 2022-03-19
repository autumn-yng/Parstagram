//
//  CameraViewController.swift
//  Parstagram
//
//  Created by Autumn Y Ngoc on 3/7/22.
//

import UIKit
import AlamofireImage
import Parse

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // remember to check the box "User interaction enabled" for this image
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var textField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func onSubmitButton(_ sender: Any) {
        // Create a PFObject, or a table, in the Parse server
        let post = PFObject(className: "Posts")
        
        // Create columns for the table
        post["caption"] = textField.text!
        // the author is the current user logged in
        post["author"] = PFUser.current()
        
        // save the files of the images in a separate place
        let imageData = imageView.image!.pngData()
        let file = PFFileObject(name: "image.png", data: imageData!)
        
        // this "image" column stores "file", which is the URL to the image -> Binary type
        post["image"] = file
        
        post.saveInBackground { success, error in
            if success {
                self.dismiss(animated: true, completion: nil)
                print("Saved.")
            } else {
                print("Error.")
            }
        }
    }
    
    // This function is executed when the camera image is tapped
    @IBAction func onCameraButton(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        //  check to see if the camera is available
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            // go to camera
            picker.sourceType = .camera
        // otherwise, go to photo library
        } else {
            picker.sourceType = .photoLibrary
        }
        
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.editedImage] as! UIImage
        let size = CGSize(width: 300, height: 300)
        let scaledImage = image.af.imageAspectScaled(toFill: size)
        
        imageView.image = scaledImage
        dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
