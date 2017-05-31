//
//  ViewController.swift
//  SFAVTools
//
//  Created by 孙凡 on 17/5/5.
//  Copyright © 2017年 Edward. All rights reserved.
//

import UIKit
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
//        testForNBAll()
        demoForSpeed()
    }
    
    func testForNBAll() {
    
        let destinationPath = Tools.getTempVideoPath()
        let destinationURL = URL(fileURLWithPath: destinationPath)
        let videoURL = Bundle.main.url(forResource: "5", withExtension: "m4v")!
        asset = AVAsset(url: videoURL)
        let cgImage = try? asset?.getImage(fromTime: 0.1).applyBlur(20).cgImage
        
        asset?.nb.startProcessVideo { (make) in
            
            make.trim(progressRange: Range(uncheckedBounds: (lower: 0.5, upper: 2)))
            make.rotate(90)
            make.stretchRender(view.frame.size)
            make.background(cgImage!!)
            
        }.exportVideo(destinationURL) {[weak self] (error) in
            if let err = error {
                debugPrint("error: \(err)")
            } else {
                self?.alertForSaveVideo(videoPath: destinationPath)
            }
        }
    }
    
    
    func demoForBackgroundFilter() {
        let destinationPath = Tools.getTempVideoPath()
        let destinationURL = URL(fileURLWithPath: destinationPath)
        let videoURL = Bundle.main.url(forResource: "heng", withExtension: "MOV")!
        let videoAsset = AVAsset(url: videoURL)
        
        do {
            let image = try videoAsset.getImage(fromTime: 0.1)
            let cgImage = image.applyBlur(20).cgImage!
            let videoComposition = try AVVideoBackgroundFilter.videoProcess(videoAsset: videoAsset, image: cgImage)
            avCommand = AVExportCommand()
            avCommand?.videoComposition = videoComposition.1
            _ = avCommand?.exportVideo(asset: videoComposition.0, outputURL: destinationURL, handle: {[weak self] (error) in
                if let err = error {
                    debugPrint(err)
                } else {
                    self?.alertForSaveVideo(videoPath: destinationPath)
                }
                self?.avCommand = nil
            })
        } catch {
            debugPrint("添加背景失败:\(error)")
        }
    }
    
    
    var index: Int = 0
    func testForTransform() {
        
        func degree(_ degree: Double) -> CGFloat {
            return CGFloat(degree / 180 * Double.pi)
        }
        
        let t1 = CGAffineTransform.identity
        let t2 = t1.rotated(by: degree(90))
        let t3 = t1.rotated(by: degree(180))
        let t4 = t1.rotated(by: degree(270))
        let t5 = t1.rotated(by: degree(360))
        let t6 = t1.rotated(by: degree(450))
        let t7 = t1.rotated(by: degree(540))
        
        let ts = [t1,t2,t3,t4,t5,t6,t7]
        
        if index >= ts.count {
            index = 0
        }
        let currnetTransform = ts[index]
        print("currentIndex: \(index)")
        print("currnetTransform:\(currnetTransform)")
        let size = CGSize(width: 100, height: 200)
        print(size.applying(currnetTransform))
        testView?.transform = currnetTransform
        index += 1
        
        let t10 = t1.rotated(by: degree(90))
        let b = t10 == currnetTransform
        print(b)
    
    }
    
    func testForAllFoundation() {
        
        func reverse(_ path: String ) {
            let destinationPath = Tools.getTempVideoPath()
            let destinationURL = URL(fileURLWithPath: destinationPath)
            let asset = AVAsset(url: URL(fileURLWithPath: path))
            
            avReverse = AVVideoReverse()
            try? avReverse?.videoReverse(videoAsset: asset, outputURL: destinationURL, fileType: nil, finished: { [weak self] in
                self?.alertForSaveVideo(videoPath: destinationPath)
            })
        }
        
        let destinationPath = Tools.getTempVideoPath()
        let destinationURL = URL(fileURLWithPath: destinationPath)
        
        do {
            let mergeAsset = try AVVideoMerge.videoMerge(videoAsset: loadData())
            let speedAsset = try AVVideoSpeed.videoSpeedChange(videoAsset: mergeAsset, speedMultiple: 3)
            let rotateAssetTuple = try AVVideoRotate.videoRotate(videoAsset: speedAsset, rotationAngle: 90)
            avCommand = AVExportCommand()
            avCommand?.videoComposition = rotateAssetTuple.1
            _ = avCommand?.exportVideo(asset: rotateAssetTuple.0, outputURL: destinationURL, handle: { (error) in
                if let err = error {
                    debugPrint(err)
                } else {
                    reverse(destinationPath)
                }
            })
        } catch {
        }
    }
    
    func demoForRotate() {
        let destinationPath = Tools.getTempVideoPath()
        let destinationURL = URL(fileURLWithPath: destinationPath)
        let videoURL = Bundle.main.url(forResource: "5", withExtension: "m4v")!
        let videoAsset = AVAsset(url: videoURL)
        
        do {
            let videoComposition = try AVVideoRotate.videoRotate(videoAsset: videoAsset, rotationAngle: 90)
            avCommand = AVExportCommand()
            avCommand?.videoComposition = videoComposition.1
            _ = avCommand?.exportVideo(asset: videoComposition.0, outputURL: destinationURL, handle: {[weak self] (error) in
                if let err = error {
                    debugPrint(err)
                } else {
                    self?.alertForSaveVideo(videoPath: destinationPath)
                }
                self?.avCommand = nil
            })
        } catch {
            debugPrint("转换方向失败:\(error)")
        }
    }
    
    func demoForSpeed() {
        let destinationPath = Tools.getTempVideoPath()
        let destinationURL = URL(fileURLWithPath: destinationPath)
        let videoURL = Bundle.main.url(forResource: "121", withExtension: "MP4")!
        let videoAsset = AVAsset(url: videoURL)
        do {
            let asset = try AVVideoSpeed.videoSpeedChange(videoAsset: videoAsset, speedMultiple: 10)
            avCommand = AVExportCommand()
            _ = avCommand?.exportVideo(asset: asset, outputURL: destinationURL, handle: {[weak self] (error) in
                if let err = error {
                    debugPrint(err)
                } else {
                    self?.alertForSaveVideo(videoPath: destinationPath)
                }
            })
        } catch {
            debugPrint(error)
        }

    }
    
    func demoForMerge() {
        let destinationPath = Tools.getTempVideoPath()
        let destinationURL = URL(fileURLWithPath: destinationPath)
        
        do {
            let asset = try AVVideoMerge.videoMerge(videoAsset: loadData())
            avCommand = AVExportCommand()
            _ = avCommand?.exportVideo(asset: asset, outputURL: destinationURL, handle: {[weak self] (error) in
                if let err = error {
                    debugPrint(err)
                } else {
                    self?.alertForSaveVideo(videoPath: destinationPath)
                }
            })
        } catch {
        }
        
    }
    
    func demoForReverse() {
        
        let destinationPath = Tools.getTempVideoPath()
        let destinationURL = URL(fileURLWithPath: destinationPath)
        let videoURL = Bundle.main.url(forResource: "5", withExtension: "m4v")!
        let videoAsset = AVAsset(url: videoURL)
        
        do {
            avReverse = AVVideoReverse()
            try avReverse?.videoReverse(videoAsset: videoAsset, outputURL: destinationURL, fileType: nil) { [weak self] in
                self?.alertForSaveVideo(videoPath: destinationPath)
            }
        } catch {
            debugPrint(error)
        }
    }
    
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

