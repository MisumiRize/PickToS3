import UIKit
import RealmSwift
import Photos
import AWSS3
import Social

class ViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let activityIndicatorView = UIActivityIndicatorView()
    let realm = try! Realm()
    var logs = Array(try! Realm().objects(UploadLog.self))

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.contentInset = UIEdgeInsetsMake(20.0, 0.0, 0.0, 0.0)
        // Do any additional setup after loading the view, typically from a nib.
        try! NSFileManager.defaultManager().createDirectoryAtURL(
            NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("upload"),
            withIntermediateDirectories: true,
            attributes: nil)

        activityIndicatorView.frame = CGRectMake(0, 50, 0, 0)
        activityIndicatorView.center = view.center
        activityIndicatorView.activityIndicatorViewStyle = .Gray
        view.addSubview(activityIndicatorView)
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logs.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("cell")
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "cell")
        }

        let log = logs[indexPath.row]
        cell!.textLabel!.text = log.fileName

        let asset = PHAsset.fetchAssetsWithALAssetURLs([NSURL(string: log.fromURL)!], options: nil).firstObject as! PHAsset
        let options = PHImageRequestOptions()
        options.synchronous = true
        PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: CGSize(width: 100.0, height: 100.0), contentMode: .AspectFit, options: options, resultHandler: { result, info in
            cell!.imageView!.image = result
        })

        return cell!
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let compose = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
        let url = NSURL(string: BaseURL + logs[indexPath.row].fileName)!
        compose.addURL(url)
        presentViewController(compose, animated: true, completion: nil)
    }

    @IBAction func newButtonClicked() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .PhotoLibrary
        imagePicker.delegate = self
        presentViewController(imagePicker, animated: true, completion: nil)
    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        dismissViewControllerAnimated(true, completion: nil)
        view.userInteractionEnabled = false
        activityIndicatorView.startAnimating()

        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let fromURL = info[UIImagePickerControllerReferenceURL] as! NSURL
            let fileName = NSProcessInfo.processInfo().globallyUniqueString.stringByAppendingString(".jpg")
            let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("upload").URLByAppendingPathComponent(fileName)
            let filePath = fileURL.path!
            let imageData = UIImageJPEGRepresentation(image, 0.8)
            imageData!.writeToFile(filePath, atomically: true)

            let req = AWSS3TransferManagerUploadRequest()
            req.bucket = S3BucketName
            req.key = fileName
            req.body = fileURL
            req.contentType = "image/jpeg"
            req.ACL = .PublicRead

            AWSS3TransferManager.defaultS3TransferManager()
                .upload(req)
                .continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { task in
                    if let error = task.error {
                        print(error)
                    } else {
                        let log = UploadLog()
                        log.fromURL = fromURL.absoluteString
                        log.fileName = fileName

                        try! self.realm.write {
                            self.realm.add(log)
                        }

                        self.logs.append(log)
                        self.tableView.reloadData()
                    }

                    self.view.userInteractionEnabled = true
                    self.activityIndicatorView.stopAnimating()
                    return nil
                })
        } else {
            view.userInteractionEnabled = true
            activityIndicatorView.stopAnimating()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
