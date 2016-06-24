//
//  ViewController.swift
//  PickToS3
//
//  Created by hoaxster on 2016/06/23.
//  Copyright © 2016年 Rize MISUMI. All rights reserved.
//

import UIKit
import Photos
import AWSS3

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(
                NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("upload"),
                withIntermediateDirectories: true,
                attributes: nil)
        } catch {
            print("Creating 'upload' directory failed. Error: \(error)")
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .PhotoLibrary
        imagePicker.delegate = self
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        self.dismissViewControllerAnimated(true, completion: nil)
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let fileName = NSProcessInfo.processInfo().globallyUniqueString.stringByAppendingString(".jpg")
            let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("upload").URLByAppendingPathComponent(fileName)
            let filePath = fileURL.path!
            let imageData = UIImageJPEGRepresentation(image, 0.8)
            imageData!.writeToFile(filePath, atomically: true)
            let req = AWSS3TransferManagerUploadRequest()
            req.bucket = S3BucketName
            req.key = fileName
            req.body = fileURL
            AWSS3TransferManager.defaultS3TransferManager()
                .upload(req)
                .continueWithBlock({ task in
                    print(task.error)
                    print("finished")
                    return nil
                })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

