//
//  AudioViewController.swift
//  newPhotos
//
//  Created by musa on 6.08.2019.
//  Copyright © 2019 musa. All rights reserved.
//

import UIKit
//import AudioToolbox // 30 sn'den kısa sesleri oynatmak için / avfoundation dan daha verimli fakat stop yapamıyorsun

import AVFoundation
import AudioToolbox
import Photos


class AudioViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AVAudioPlayerDelegate, AVAudioRecorderDelegate
{
    
    
    var passedSound = String() // selected sound
    var passedImage:UIImage! // selected image
    @IBOutlet weak var selectedImg: UIImageView! // imageiew for selected image
    @IBOutlet weak var audioList: UITableView!
    var player: AVAudioPlayer?
    
    
    // set video variables
    var outputSize = CGSize(width: 1920, height: 1920)
    let imagesPerSecond: TimeInterval = 1 //each image will be stay for 3 secs
    var selectedPhotosArray = UIImage() // image to be rendered in the build video function
    var imageArrayToVideoURL = NSURL() // created video url
    var asset: AVAsset!
    var mergeAudioURL = NSURL() // selected audio url
    
    
    // set audio recorder
    var audioRecorder:AVAudioRecorder!
    var isRecording = false
    // add existing audio to an array
    let filename = ["birds", "rain", "rainThunder", "river", "night", "beach", "seashore", "water", "windSmooth", "wind", "windy", "rain", "rainThunder" ]
    let ext = "wav"
    
    
    // BUTTONS
    
    // create video with selected audio from silent video button
    // this button also shares thevideo to instagram in mergeMutableVideoWithAudio function
    
    @IBOutlet weak var outletBtnCreate: UIButton!
    @IBAction func btnCreate(_ sender: Any) {
        
        // self.mergeAudioURL = Bundle.main.url(forResource: passedSound, withExtension: "wav")! as NSURL
        print(self.mergeAudioURL)
        mergeMutableVideoWithAudio(videoUrl: self.imageArrayToVideoURL, audioUrl: self.mergeAudioURL)
        print(self.mergeAudioURL)
    }
    
    // go to previous controller
    @IBAction func btnBack(_ sender: Any) {
        player?.stop()
        self.performSegue(withIdentifier: "goToFirstVC", sender: self)
    }

    // record new audio
    @IBOutlet weak var outletRecAud: UIBarButtonItem!
    @IBAction func btnRecordAudio(_ sender: Any) {
        
        if !isRecording {
            print("is recording \(isRecording)")
            outletRecAud.title = "stop and listen"
            let audioSession:AVAudioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            } catch let error as NSError {
                print("audioSession error: \(error.localizedDescription)")
            }
            
            let str =  getDirectory().appendingPathComponent("recordTest.caf")
            let url = NSURL.fileURL(withPath: str.absoluteString)
            let recordSettings = [AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue,
                                  AVEncoderBitRateKey: 16,
                                  AVNumberOfChannelsKey: 2,
                                  AVSampleRateKey: 44100.0] as [String : Any]
            
            print("url : \(url)")
            
            do {
                try audioRecorder = AVAudioRecorder(url: str, settings: recordSettings as [String : AnyObject])
                audioRecorder?.delegate = self
                audioRecorder?.record()
                isRecording = true
            } catch let error as NSError {
                print("audioSession error: \(error.localizedDescription)")
            }
        }
        else {
            print("is recording \(isRecording)")
            outletRecAud.title = "Record Again"
            
            print("it is recorded")
            audioRecorder.stop()
            // mergeMutableVideoWithAudio(videoUrl: self.imageArrayToVideoURL, audioUrl: self.mergeAudioURL)
            isRecording = false
            
        }
        
    }
    // get directory for recorded audio
    func getDirectory() -> URL
    {
        let fileManager = FileManager.default
        let directionPaths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let soundFileURL = directionPaths[0]
        return soundFileURL
    }
    
    // when recording finished
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("AudioRecorderDidFinishRecording")
        // mergeMutableVideoWithAudio(videoUrl: self.imageArrayToVideoURL, audioUrl: self.mergeAudioURL)
        let path = getDirectory().appendingPathComponent("recordTest.caf")
        do {
            player = try AVAudioPlayer(contentsOf:path)
            player?.play()
            //lblRecord.setImage(UIImage(named: "headphones"), for: .normal)
            self.mergeAudioURL = path as NSURL
            outletBtnCreate.isEnabled = true

            //self.mergeAudioURL = NSURL.fileURL(withPath: str.absoluteString) as NSURL
            
        } catch //let error as NSError
        {
            print("audioPlayer error: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        outletBtnCreate.isEnabled = false
        print("audioViewController loaded")
        outletRecAud.title = "Reacord Audio"
        
        selectedImg.image = passedImage
        
        // create video from selected image
        buildVideoFromImageArray()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // table view
    
    //list audio files
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filename.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = filename[indexPath.row]
        
        return cell
    }
    
    // playe selected audio
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        playSound(fileTitle: filename[indexPath.row])
        passedSound = filename[indexPath.row]
        self.mergeAudioURL = Bundle.main.url(forResource: passedSound, withExtension: "wav")! as NSURL
        outletBtnCreate.isEnabled = true

    }
    
    // play audio function
    func playSound(fileTitle:String) {
        let url = Bundle.main.url(forResource: fileTitle, withExtension: "wav")!
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            
            player.prepareToPlay()
            player.play()
        } catch let error as NSError {
            print(error.description)
        }
    }
    
    // create video from selected images
    func buildVideoFromImageArray() {
        print("passed image: \(passedImage.size)")
        
        if (self.passedImage.cgImage?.width)! > 1920 || (self.passedImage.cgImage?.height)! > 1920 {
            
            selectedPhotosArray = self.passedImage.resizeImageWith(newSize: CGSize(width: 1080, height: 1080))
            outputSize = CGSize(width: (selectedPhotosArray.cgImage?.width)!, height: (selectedPhotosArray.cgImage?.height)!)
            print("edited output: \(outputSize)")
        }
        else {
            selectedPhotosArray = self.passedImage
            outputSize = selectedPhotosArray.size //CGSize(width: (selectedPhotosArray.cgImage?.width)!, height: (selectedPhotosArray.cgImage?.height)!)
            print(outputSize)
        }
        
        //selectedPhotosArray = self.passedImage
        
        //outputSize = CGSize(width: 1920, height: 1080)
        
        
        imageArrayToVideoURL = NSURL(fileURLWithPath: NSHomeDirectory() + "/Documents/video1.MP4")
        removeFileAtURLIfExists(url: imageArrayToVideoURL)
        guard let videoWriter = try? AVAssetWriter(outputURL: imageArrayToVideoURL as URL, fileType: AVFileType.mp4) else {
            fatalError("AVAssetWriter error")
        }
        let outputSettings = [AVVideoCodecKey : AVVideoCodecH264, AVVideoWidthKey : NSNumber(value: Float(outputSize.width)), AVVideoHeightKey : NSNumber(value: Float(outputSize.height))] as [String : Any]
        guard videoWriter.canApply(outputSettings: outputSettings, forMediaType: AVMediaType.video) else {
            fatalError("Negative : Can't apply the Output settings...")
        }
        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
        let sourcePixelBufferAttributesDictionary = [kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32ARGB), kCVPixelBufferWidthKey as String: NSNumber(value: Float(outputSize.width)), kCVPixelBufferHeightKey as String: NSNumber(value: Float(outputSize.height))]
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
        }
        if videoWriter.startWriting() {
            
            let zeroTime = CMTimeMake(Int64(imagesPerSecond), Int32(1))
            videoWriter.startSession(atSourceTime: zeroTime)
            
            assert(pixelBufferAdaptor.pixelBufferPool != nil)
            let media_queue = DispatchQueue(label: "mediaInputQueue")
            videoWriterInput.requestMediaDataWhenReady(on: media_queue, using: { () -> Void in
                
                let fps: Int32 = 2
                let framePerSecond: Int64 = 10
                let frameDuration = CMTimeMake(1, fps)
                var frameCount: Int64 = 0
                var appendSucceeded = true
                while frameCount < 6 {
                    if (videoWriterInput.isReadyForMoreMediaData) {
                        let nextPhoto = self.selectedPhotosArray
                        //let nextPhoto = self.selectedPhotosArray.remove(at: 0)
                        let lastFrameTime = CMTimeMake(frameCount * framePerSecond, fps)
                        let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
                        
                        
                        var pixelBuffer: CVPixelBuffer? = nil
                        let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferAdaptor.pixelBufferPool!, &pixelBuffer)
                        if let pixelBuffer = pixelBuffer, status == 0 {
                            let managedPixelBuffer = pixelBuffer
                            CVPixelBufferLockBaseAddress(managedPixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
                            let data = CVPixelBufferGetBaseAddress(managedPixelBuffer)
                            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
                            let context = CGContext(data: data, width: Int(self.outputSize.width), height: Int(self.outputSize.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(managedPixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
                            context!.clear(CGRect(x: 0, y: 0, width: CGFloat(self.outputSize.width), height: CGFloat(self.outputSize.height)))
                            let horizontalRatio = CGFloat(self.outputSize.width) / nextPhoto.size.width
                            let verticalRatio = CGFloat(self.outputSize.height) / nextPhoto.size.height
                            let aspectRatio = max(horizontalRatio, verticalRatio) // ScaleAspectFit
                            let newSize: CGSize = CGSize(width: nextPhoto.size.width * aspectRatio, height: nextPhoto.size.height * aspectRatio)
                            let x = newSize.width < self.outputSize.width ? (self.outputSize.width - newSize.width) / 2 : 0
                            let y = newSize.height < self.outputSize.height ? (self.outputSize.height - newSize.height) / 2 : 0
                            context?.draw(nextPhoto.cgImage!, in: CGRect(x: x, y: y, width: newSize.width, height: newSize.height))
                            CVPixelBufferUnlockBaseAddress(managedPixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
                            appendSucceeded = pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                        } else {
                            print("Failed to allocate pixel buffer")
                            appendSucceeded = false
                        }
                    }
                    if !appendSucceeded {
                        break
                    }
                    frameCount += 1
                }
                videoWriterInput.markAsFinished()
                videoWriter.finishWriting { () -> Void in
                    print("-----video1 url = \(self.imageArrayToVideoURL)")
                    self.asset = AVAsset(url: self.imageArrayToVideoURL as URL)
                }
            })
        }
        
    }
    
    // create video with selected audio from silent video
    func mergeMutableVideoWithAudio(videoUrl:NSURL, audioUrl:NSURL){
        
        let mixComposition : AVMutableComposition = AVMutableComposition()
        var mutableCompositionVideoTrack : [AVMutableCompositionTrack] = []
        var mutableCompositionAudioTrack : [AVMutableCompositionTrack] = []
        let totalVideoCompositionInstruction : AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        //start merge
        let aVideoAsset : AVAsset = AVAsset(url: videoUrl as URL)
        let aAudioAsset : AVAsset = AVAsset(url: audioUrl as URL)
        mutableCompositionVideoTrack.append(mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        print("mutableCompositionVideoTrack \(mutableCompositionVideoTrack)")
        mutableCompositionAudioTrack.append( mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        let aVideoAssetTrack : AVAssetTrack = aVideoAsset.tracks(withMediaType: AVMediaType.video)[0]
        print("aVideoAssetTrack \(aVideoAssetTrack)") //null
        let aAudioAssetTrack : AVAssetTrack = aAudioAsset.tracks(withMediaType: AVMediaType.audio)[0]
        print("aAudioAssetTrack \(aAudioAssetTrack)") //null
        do{
            try mutableCompositionVideoTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero, aAudioAssetTrack.timeRange.duration), of: aVideoAssetTrack, at: kCMTimeZero)
            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero, aAudioAssetTrack.timeRange.duration), of: aAudioAssetTrack, at: kCMTimeZero)
        }catch{
            print("could not insert time range")
        }
        totalVideoCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero,aAudioAssetTrack.timeRange.duration)
        let mutableVideoComposition : AVMutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition.frameDuration = CMTimeMake(1, 30)
        mutableVideoComposition.renderSize = CGSize(width: self.outputSize.width, height: self.outputSize.height)
        let  mergedAudioVideoURl = NSURL(fileURLWithPath: NSHomeDirectory() + "/Documents/FinalVideo.mp4")
        let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)!
        assetExport.outputFileType = AVFileType.mp4
        assetExport.outputURL = mergedAudioVideoURl as URL
        removeFileAtURLIfExists(url: mergedAudioVideoURl)
        assetExport.shouldOptimizeForNetworkUse = true
        assetExport.exportAsynchronously { () -> Void in
            switch assetExport.status {
            case AVAssetExportSessionStatus.completed:
                print("-----Merge mutable video with trimmed audio exportation complete.\(mergedAudioVideoURl)")
                self.imageArrayToVideoURL = mergedAudioVideoURl
                self.shareStory()
            case  AVAssetExportSessionStatus.failed:
                print("it was failed \(String(describing: assetExport.error))")
            case AVAssetExportSessionStatus.cancelled:
                print("cancelled \(String(describing: assetExport.error))")
            default:
                print("complete")
            }
        }
        print("new \(mergedAudioVideoURl)")
        
    }
    
    // remove the  files with the same url
    func removeFileAtURLIfExists(url: NSURL) {
        if let filePath = url.path {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath) {
                do{
                    try fileManager.removeItem(atPath: filePath)
                } catch let error as NSError {
                    print("Couldn't remove existing destination file: \(error)")
                }
            }
        }
    }
    
    // share to instangram
    func shareStory() {
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.imageArrayToVideoURL as URL)
        }) { saved, error in
            if saved {
                self.player?.stop()
                let backgroundVideo = self.imageArrayToVideoURL.absoluteString
                let urlScheme = URL(string: "instagram-stories://share")
                
                
                if let urlScheme = urlScheme {
                    
                    DispatchQueue.main.async{
                        if UIApplication.shared.canOpenURL(urlScheme) {
                            let url = URL(string: ("instagram://library?AssetPath="+backgroundVideo!))
                            if UIApplication.shared.canOpenURL(url! as URL){
                                UIApplication.shared.open(url! as URL, options: [:], completionHandler:nil)
                            }
                            else {print("couldn't load")}
                        }
                        else {
                            print("instagram is not loaded")
                        }
                        
                    }
                }
                
            }
        }
        
    }
    
    // share to instagram with another method
    // self.shareBackgroundImage()
    /*  func shareBackgroundImage() {
     let image = UIImage(named: "arka.jpg")
     // let arkaresim = UIImage(named: "arka.jpg")
     do { let sharedVideoURL = try Data(contentsOf: self.imageArrayToVideoURL.absoluteURL!)
     
     if let pngImage = UIImagePNGRepresentation(image!){
     backgroundImage2(pngImage, bgVideo: sharedVideoURL)
     //backgroundImage(bgVideo: sharedVideoURL)
     }
     }
     catch {print("data couldn't retrieved")}
     
     
     }
     
     func backgroundImage2(_ backgroundImage: Data, bgVideo: Data) {
     // Verify app can open custom URL scheme, open if able
     
     guard let urlScheme = URL(string: "instagram-stories://share"),
     UIApplication.shared.canOpenURL(urlScheme) else {
     // Handle older app versions or app not installed case
     
     return
     }
     let pasteboardItems = [["com.instagram.sharedSticker.backgroundVideo": bgVideo,
     "com.instagram.sharedSticker.stickerImage": backgroundImage]]
     let pasteboardOptions: [UIPasteboardOption: Any] = [.expirationDate: Date().addingTimeInterval(60 * 5)]
     
     // This call is iOS 10+, can use 'setItems' depending on what versions you support
     UIPasteboard.general.setItems(pasteboardItems, options: pasteboardOptions)
     
     UIApplication.shared.open(urlScheme)
     }
     
     func backgroundImage(bgVideo: Data) {
     // Verify app can open custom URL scheme, open if able
     
     guard let urlScheme = URL(string: "instagram-stories://share"),
     UIApplication.shared.canOpenURL(urlScheme) else {
     // Handle older app versions or app not installed case
     
     return
     }
     let pasteboardItems = [["com.instagram.sharedSticker.backgroundVideo": bgVideo,
     "com.instagram.sharedSticker.backgroundBottomColor": "#5555"]]
     let pasteboardOptions: [UIPasteboardOption: Any] = [.expirationDate: Date().addingTimeInterval(60 * 5)]
     
     // This call is iOS 10+, can use 'setItems' depending on what versions you support
     UIPasteboard.general.setItems(pasteboardItems, options: pasteboardOptions)
     
     UIApplication.shared.open(urlScheme)
     }
     
     */
    
}

// resize image before creating video
extension UIImage{
    
    func resizeImageWith(newSize: CGSize) -> UIImage {
        print("size width = \(size.width)")
        print("size height = \(size.height)")
        
        let horizontalRatio = newSize.width / size.width
        let verticalRatio = newSize.height / size.height
        
        let ratio = min(horizontalRatio, verticalRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        print("new size \(newSize)")
        UIGraphicsBeginImageContextWithOptions(newSize, true, 1)
        draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        print("created img: \(String(describing: newImage?.cgImage?.width)) and \(String(describing: newImage?.cgImage?.height))")
        return newImage!
    }
    
    
}
