//
//  ViewController.swift
//  newPhotos
//
//  Created by musa on 3.08.2019.
//  Copyright © 2019 musa. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var images = [PHAsset]()
    var selectedImage:UIImage!
    @IBOutlet weak var photosCollectionView: UICollectionView!
    var action = 1 // 1: camera roll 2: take picture,  back button kullanıldığında yapılacak eylemi belirliyorum
    var pickedImage = false

    // open photo library
    @IBAction func btnLibrary(_ sender: Any) {
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = UIImagePickerControllerSourceType.photoLibrary
        imagePickerController.allowsEditing = false
        self.present(imagePickerController, animated: true, completion: nil)
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()

       // getImages()
        
        
         let status = PHPhotoLibrary.authorizationStatus()
         
         if (status == PHAuthorizationStatus.authorized) {
         self.getImages()
         }
         
         else if (status == PHAuthorizationStatus.denied) {
         // Access has been denied.
         }
         
         else if (status == PHAuthorizationStatus.notDetermined) {
         
         // Access has not been determined.
         PHPhotoLibrary.requestAuthorization({ (newStatus) in
         
         if (newStatus == PHAuthorizationStatus.authorized) {
         self.getImages()
         
         }
         
         else {
         
         }
         })
         }
         
         else if (status == PHAuthorizationStatus.restricted) {
         // Restricted access - normally won't happen.
         }
 

        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // photos tan fotoğrafları çekip phAsset e koyuyoruz
    func getImages() {
        let assets = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: nil)
        assets.enumerateObjects({ (object, count, stop) in
            self.images.append(object)
        })
        
        //In order to get latest image first, we just reverse the array
        self.images.reverse()
        
        // To show photos, I have taken a UICollectionView
        self.photosCollectionView.reloadData()
    }
    //
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isSynchronous = true
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath)
        let asset = images[indexPath.row]
        let manager = PHImageManager.default()
        let imageView = cell.viewWithTag(1) as? UIImageView
        
        if cell.tag != 1 {
            manager.cancelImageRequest(PHImageRequestID(cell.tag))
        }
        cell.tag = Int(manager.requestImage(for: asset,
                                            targetSize: CGSize(width: 120, height: 120),
                                            contentMode: .aspectFill,
                                            options: options) { (result, _) in
                                                imageView?.image = result
        })
       

       /// bir satırda kaç hücre olacak?
       let numberOfCellsPerRow: CGFloat = 3
        if let flowLayout = photosCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            
            let horizontalSpacing = flowLayout.scrollDirection == .vertical ? flowLayout.minimumInteritemSpacing : flowLayout.minimumLineSpacing
            let cellWidth = ((view.frame.width - 10) - max(0, numberOfCellsPerRow - 1)*horizontalSpacing)/numberOfCellsPerRow
            flowLayout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        }
        
     
        return cell
    }
   
    
// seçilen image i phasset library den alma
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
       
        // resmi orijinal boyutta almak için options gerekli
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isSynchronous = true
        
        PHImageManager.default().requestImage(for: images[indexPath.row], targetSize: PHImageManagerMaximumSize, contentMode: .default, options: options, resultHandler: { (image, info) in
            self.selectedImage = image
        })
        
        // perform segue
        if self.selectedImage != nil {
            self.performSegue(withIdentifier: "goToSecondVC", sender: self)
            
        }
    }
    
    // pass data to another controller view
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToSecondVC" {
            let svc = segue.destination as! AudioViewController
            if self.selectedImage != nil{
            svc.passedImage = self.selectedImage
        }
        }
    }
    
    
    // kamera butonu tıklandığında
    
    @IBAction func btnCamera(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self;
            imagePickerController.sourceType = .camera
            self.present(imagePickerController, animated: true, completion: nil)
            pickedImage = true
            print("camera kullanıldı")
            
        }
        else {
            let alertController = UIAlertController(title: "kamera yok", message: "Simple alertView demo with Ok.", preferredStyle: UIAlertControllerStyle.alert) //Replace UIAlertControllerStyle.Alert by UIAlertControllerStyle.alert
            
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
                (result : UIAlertAction) -> Void in
                print("OK")
               
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        

        self.dismiss(animated: true, completion: {
            self.selectedImage = image?.fixOrientation()

            self.performSegue(withIdentifier: "goToSecondVC", sender: self)
        })

    }
    
}

// this extension is necessary to prevent unexpected rotation of images saved by camera
extension UIImage {
    func fixOrientation() -> UIImage {
        if self.imageOrientation == UIImageOrientation.up {
            return self
        }
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        if let normalizedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return normalizedImage
        } else {
            return self
        }
    }
}

