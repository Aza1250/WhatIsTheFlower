//
//  ViewController.swift
//  What'sThatFlower
//
//  Created by Aziz Zaynutdinov on 7/21/18.
//  Copyright © 2018 Aziz Zaynutdinov. All rights reserved.
//

import UIKit
import CoreML
import Vision
import SVProgressHUD
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet var flowerInfo: UITextView!
    @IBOutlet var cameraButton: UIBarButtonItem!
    @IBOutlet var flowerImage: UIImageView!
    let WIKI_URL: String = "https://en.wikipedia.org/w/api.php?"
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let flowerPicture = info[UIImagePickerControllerOriginalImage] as? UIImage else { return }
        
        
        guard let ciImage = CIImage(image: flowerPicture) else { return }
        imagePicker.dismiss(animated: true, completion: nil)
        SVProgressHUD.show()
        
        detect(image: ciImage)
    }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Please Select an Option", message: "Choose the Source of Your Images", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Camera", style: .default , handler:{ (UIAlertAction)in
            self.imagePicker.sourceType = .camera
            self.present(self.imagePicker, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default , handler:{ (UIAlertAction)in
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Saved Photos Album", style: .default , handler:{ (UIAlertAction)in
            self.imagePicker.sourceType = .savedPhotosAlbum
            self.present(self.imagePicker, animated: true, completion: nil)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    let imagePicker = UIImagePickerController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
    }
    
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else { return }
        let VisionRequest = VNCoreMLRequest(model: model) { (VNRequest, error) in
            guard let VNResults = VNRequest.results as? [VNClassificationObservation] else { return }
            guard let flowerName: String = VNResults.first?.identifier else { return }
            self.makeRequestFlowerInfo(flowerName: flowerName)
        }
        
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        do { try handler.perform([VisionRequest])
        } catch {
            print("\(error)")
        }
    }
    
    func makeRequestFlowerInfo(flowerName: String) {
        let parameters : [String:String] = [
            
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
            
        ]
        
        Alamofire.request(WIKI_URL, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                SVProgressHUD.dismiss()
                let json: JSON = JSON(response.result.value!) 
                let pageid = json["query"]["pageids"][0].stringValue
                let flowerImageURL = json["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                self.flowerImage.sd_setImage(with: URL(string: flowerImageURL))
                self.flowerInfo.text = json["query"]["pages"][pageid]["extract"].stringValue
                self.navigationItem.title = json["query"]["pages"][pageid]["title"].stringValue
            }
            else {
                print("Error getting the data from the server")
            }
        }
    }
    
}

