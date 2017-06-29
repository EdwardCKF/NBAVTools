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
    
    var startButton: UIButton?
    var endButton: UIButton?
    var cancelButton: UIButton?
    var progressLabel: UILabel?
    
    var videoMaker: NBImageVideoMaker?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }

    private func setupUI() {
        let buttonHeight: CGFloat = 50
        let buttonWidth: CGFloat = 100
        let buttonX: CGFloat = (SCREEN_WIDTH - buttonWidth) * 0.5
        
        startButton = UIButton()
        startButton?.frame = CGRect(x: buttonX, y: 150, width: buttonWidth, height: buttonHeight)
        startButton?.setTitle("Start", for: .normal)
        startButton?.backgroundColor = UIColor.red
        startButton?.addTarget(self, action: #selector(ViewController.startButtonDidClick(_:)), for: .touchUpInside)
        view.addSubview(startButton!)
        
        endButton = UIButton()
        endButton?.frame = CGRect(x: buttonX, y: 250, width: buttonWidth, height: buttonHeight)
        endButton?.setTitle("End", for: .normal)
        endButton?.backgroundColor = UIColor.yellow
        endButton?.addTarget(self, action: #selector(ViewController.endButtonDidClick(_:)), for: .touchUpInside)
        view.addSubview(endButton!)
        
        cancelButton = UIButton()
        cancelButton?.frame = CGRect(x: buttonX, y: 350, width: buttonWidth, height: buttonHeight)
        cancelButton?.setTitle("Cancel", for: .normal)
        cancelButton?.backgroundColor = UIColor.blue
        cancelButton?.addTarget(self, action: #selector(ViewController.cancelButtonDidClick(_:)), for: .touchUpInside)
        view.addSubview(cancelButton!)
        
        progressLabel = UILabel()
        progressLabel?.frame = CGRect(x: 0, y: 64, width: SCREEN_WIDTH, height: 50)
        progressLabel?.textColor = UIColor.black
        progressLabel?.textAlignment = .center
        progressLabel?.backgroundColor = UIColor.gray
        view.addSubview(progressLabel!)
    }
    
    func startButtonDidClick(_ sender: UIButton) {
        
        //        demoForNB()
        demoForCreateVideoFromImages()
    }
    
    func endButtonDidClick(_ sender: UIButton) {
        videoMaker?.end()
    }
    
    func cancelButtonDidClick(_ sender: UIButton) {
        videoMaker?.cancel()
    }

}

//MARK: Demo
extension ViewController {
    
    func demoForCreateVideoFromImages() {
        
        let tempPath: String = Tools.getTempVideoPath()
        let tempURL: URL = URL(fileURLWithPath: tempPath)
        
        let videoSize: CGSize = CGSize(width: 720, height: 1280)
        
        self.videoMaker = NBImageVideoMaker(outputURL: tempURL)
        videoMaker?.size = videoSize
        videoMaker?.delegate = self
        videoMaker?.start()
        
        DispatchQueue.global().async {
            
            for i in 1...110 {
                
                let numStr: String = String(format: "%03d", i)
                let imageName: String = "login_back_images.bundle/\(numStr).jpg"
                if let image: CGImage = UIImage(named: imageName)?.cgImage {
                    //time是每一帧的时间点,不填默认跟随24fps.
                    let time: CMTime = CMTime(value: CMTimeValue((i-1) * 3), timescale: 30)
                    let nbImage: NBVideoImage = NBVideoImage(cgImage: image, time: time)
                    
                    self.videoMaker?.append(image: nbImage)
                }
            }
        }
        
        
    }
    
    func demoForNB() {
        
        guard let video1URL: URL = Bundle.main.url(forResource: "5_1", withExtension: "mp4") else {
            return
        }
        guard let video2URL: URL = Bundle.main.url(forResource: "5_2", withExtension: "mp4") else {
            return
        }
        
        let output: URL = Tools.getTempVideoURL()
        
        let asset1: AVAsset = AVAsset(url: video1URL)
        let asset2: AVAsset = AVAsset(url: video2URL)
        
        let _ = asset1.nb.startProcessVideo { (maker) in
            
            maker.add([asset2])
            .fps(30)
            .rotate(90)
            .resolutionMode(AVAssetExportPreset1280x720)
            .speed(1.5)
        }
        .exportProgress { (progress) in
            print("progress:\(progress)")
        }
        .exportVideo(output) {[weak self] (error) in
            
            if let err = error {
                debugPrint("导出错误:\(err)")
            } else {
                self?.alertForSaveVideo(videoPath: output.path)
            }
        }
    }
    
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

extension ViewController: NBImageVideoMakerDelegate {
    
    func imageVideoMaker(_ sender: NBImageVideoMaker, index: Int, currentTime: CMTime) {
        print("index:\(index)\ncurrentTime:\(currentTime)")
    }
    
    func imageVideoMakerFinished(_ sender: NBImageVideoMaker) {
        print("imageVideoMakerFinished")
    }
    
    func imageVideoMakerError(_ sender: NBImageVideoMaker, error: Error) {
        print("imageVideoMakerError:\(error)")
    }

}

