//
//  ViewController.swift
//  SFAVTools
//
//  Created by 孙凡 on 17/5/5.
//  Copyright © 2017年 Edward. All rights reserved.
//

import UIKit
import Photos
import AVFoundation

class ViewController: UIViewController {
    
    var avCommand: AVExportCommand?
    var avReverse: AVVideoReverse?
    var testView: UIView?
    var asset: AVAsset?

    override func viewDidLoad() {
        super.viewDidLoad()

        let blurImage = UIImage(named: "Snip20170518_3")!.applyBlur(20)
        let cgImage = blurImage.cgImage!
        let iamgeLayer = AVVideoBackgroundFilter.createLayer(view.frame.size, image: cgImage)
        view.layer.addSublayer(iamgeLayer)
        
        setupUI()
    }
    
    func setupUI() {
        testView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 200))
        testView?.center = view.center
        testView?.backgroundColor = UIColor.red
        view.addSubview(testView!)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

    }

}

//MARK: Demo
extension ViewController {
    
    
    func testForSaveVideoToAlbum() {
        let videoURL = Bundle.main.url(forResource: "5_1", withExtension: "mp4")!
        UISaveVideoAtPathToSavedPhotosAlbum(videoURL.path, nil, nil, nil)
        PHPhotoLibrary.shared().performChanges({
            
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            
        }) { (b, err) in
            print(b)
        }
        
    }

}

//MARK: Private Action
extension ViewController {
    
    func alertForSaveVideo(videoPath path: String) {
        let alert = UIAlertController(title: "是否存入相册", message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "否", style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: "是", style: .default) { (action) in
            UISaveVideoAtPathToSavedPhotosAlbum(path, nil, nil, nil)
        }
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
    func loadData() -> [AVAsset] {
        
        let url1 = Bundle.main.url(forResource: "1", withExtension: "m4v")!
        let url2 = Bundle.main.url(forResource: "2", withExtension: "m4v")!
        let url3 = Bundle.main.url(forResource: "3", withExtension: "m4v")!
        let url4 = Bundle.main.url(forResource: "4", withExtension: "m4v")!
        
        let asset1 = AVAsset(url: url1)
        let asset2 = AVAsset(url: url2)
        let asset3 = AVAsset(url: url3)
        let asset4 = AVAsset(url: url4)
        
        return [asset1,asset2,asset3,asset4]
    }

}

