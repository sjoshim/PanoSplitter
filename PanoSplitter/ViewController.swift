//
//  ViewController.swift
//  PanoSplitter
//
//  Created by Yogesh Hande on 12/20/19.
//  Copyright © 2019 Yogesh Hande. All rights reserved.
//

import UIKit
import Photos

 class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
            
    @IBOutlet weak var sliderCollectionView: UICollectionView!
    var imagesListArray = [UIImage]()
    var isPhotoSaved = false
    var timer = Timer();
    var counter = 0
    let dispatchGroup = DispatchGroup()

    @IBOutlet weak var selectImageButton: UIButton!
    @IBOutlet weak var uploadImageButton: UIButton!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.sliderCollectionView.showsHorizontalScrollIndicator = false
        if PHPhotoLibrary.authorizationStatus() != PHAuthorizationStatus.authorized {
            PHPhotoLibrary.requestAuthorization(requestAuthorizationHandler)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        uploadImageButton.isHidden = true
    }
    
    func requestAuthorizationHandler(status: PHAuthorizationStatus)
    {
        //TODO: check if this is required
        DispatchQueue.main.async
        {
            if status != PHAuthorizationStatus.authorized
            {
                //TODO: show error and ask the user to go and update the settings to give access to photos
                let alertController = UIAlertController(title: "Reminder!", message: "Please allow access to photo library from settings!", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Launch Settings", style: .default, handler: self.launchSettings))
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func launchSettings(alert: UIAlertAction!)
    {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }
   
    @IBAction func selectImageButtonClicked(_ sender: Any)
    {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
       
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func launchInstagramClicked(_ sender: Any)
    {
        if(isPhotoSaved)
        {
            self.launchInstagram()
            return
        }
        
        self.saveImages(photosToSave: self.imagesListArray)
    }
    
    //This method lets user pick an image from his camera roll
    //Then the algoritm will split the image into x photos
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        var selectedImageFromPicker: UIImage?
        if let editedImage = info[.editedImage] as? UIImage
        {
            selectedImageFromPicker = editedImage
        }
        else if let originalImage = info[.originalImage] as? UIImage
        {
            selectedImageFromPicker = originalImage
        }
    
        let numberOfPieces = ceil(selectedImageFromPicker!.size.width/selectedImageFromPicker!.size.height);
       
        let finalWidth = selectedImageFromPicker!.size.width/numberOfPieces
        let finalHeight = selectedImageFromPicker!.size.height;
        var initialX : CGFloat = 0;
        self.imagesListArray.removeAll()
        self.sliderCollectionView.reloadData();
        var i = 0;
        while i < Int(numberOfPieces) {
        
            let currentRectangle = CGRect(x: CGFloat(initialX), y:0, width: CGFloat(finalWidth), height: CGFloat(finalHeight));
            let croppedImage = selectedImageFromPicker!.cgImage?.cropping(to: currentRectangle)
            imagesListArray.append(UIImage(cgImage: croppedImage!));
            i = i+1;
            initialX = CGFloat(i) * (CGFloat(finalWidth));
        }
        uploadImageButton.isHidden = false
        isPhotoSaved = false
        dismiss(animated: true, completion: nil)
    }
    
    //This saves the cropped images to Photos.
    //Images are saved one by one
    //Dispatch group is used to hold the UI thread and keep it busy
    func saveImages(photosToSave: [UIImage])
    {
        dispatchGroup.enter()
        UIImageWriteToSavedPhotosAlbum(UIImage(named: "end")!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        
        for i in 0 ..< photosToSave.count
        {
            dispatchGroup.enter()
            UIImageWriteToSavedPhotosAlbum(photosToSave[photosToSave.count-1 - i], self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
        
        dispatchGroup.enter()
               UIImageWriteToSavedPhotosAlbum(UIImage(named: "start")!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
               
        dispatchGroup.notify(queue: DispatchQueue.main)
        {
            self.isPhotoSaved = true
            self.launchInstagram()
        }
    }
 
    func launchInstagram()
    {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        if let lastAsset = fetchResult.firstObject
        {
            let url = URL(string: "instagram://library?LocalIdentifier=\(lastAsset.localIdentifier)")!
            if UIApplication.shared.canOpenURL(url)
            {
                UIApplication.shared.open(url)
            }
            else
            {
                let alertController = UIAlertController(title: "Error", message: "Instagram is not installed", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                      self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    @objc func changeImage()
    {
        if counter < imagesListArray.count
        {
            let index = IndexPath.init(item: counter, section: 0)
            self.sliderCollectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: true)
            counter += 1
        }
        else
        {
            counter = 0
            let index = IndexPath.init(item: counter, section: 0)
            self.sliderCollectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: false)
            counter = 1
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer)
    {
        dispatchGroup.leave();
        DispatchQueue.main.async
        {
               if error != nil
               {
                    let alertController = UIAlertController(title: "Error!", message: "Something went wrong, we could not save split photos! Please try again", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
        }
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesListArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        if let vc = cell.viewWithTag(111) as? UIImageView {
            vc.image = imagesListArray[indexPath.row]
        }
        return cell
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = sliderCollectionView.frame.size
        return CGSize(width: size.width, height: size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
}

