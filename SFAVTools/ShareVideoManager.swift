//
//  ShareVideoManager.swift
//  SFAVTools
//
//  Created by 孙凡 on 2017/6/1.
//  Copyright © 2017年 Edward. All rights reserved.
//

import UIKit
import AVFoundation

class ShareVideoManager {
    
    fileprivate let asset: AVAsset
    fileprivate let reverseVideoPath: String
    
    var maxDuration: TimeInterval = 10
    var outputPath: String
    
    init(videoAsset: AVAsset) {
        asset = videoAsset
        let tempFolderPath = NSTemporaryDirectory()
        let tempFolderName = tempFolderPath + "\(Int(Date().timeIntervalSince1970))"
        outputPath = tempFolderName + "share" + ".mp4"
        reverseVideoPath = tempFolderName + "reverse" + ".mp4"
    }

    func exportShareVideo(rate: Double, audioAsset: AVAsset?, output: URL? = nil, finished: @escaping ((_ error: Error?)->())) {
        
        let repeatTime = getShareVideoRepeatTimes(asset, rate: rate, maxDuring: maxDuration)
        let reverseURL = URL(fileURLWithPath: reverseVideoPath)
        let watermark = getWatermarkLayer()
        let shareVideoURL = output ?? URL(fileURLWithPath: outputPath)
        
        reverse(avasset: asset, output: reverseURL) { (error) in
            
            if error != nil {
                finished(error)
            } else {
                
                let reverseAsset = AVAsset(url: reverseURL)
                var assets = self.getAssetsForMerge(asset: self.asset, reverseAsset: reverseAsset, repeatTime: repeatTime)
                assets.remove(at: 0)

                let asset = self.asset
                asset.nb.startProcessVideo({ (make) in
                    make
                        .add(assets)
                        .rotate(0)
                        .fps(30)
                        .watermarks([watermark])
                        .speed(rate)
                        
                    if let audio = audioAsset {
                        make.insert(audio)
                    }
                }).exportProgress({ (progress) in
                    debugPrint("拼接进度:\(progress)")
                }).exportVideo(shareVideoURL, handle: finished)
            }
        }
    }
    
    func getAssetsForMerge(asset: AVAsset, reverseAsset: AVAsset, repeatTime: Int) -> [AVAsset] {
    
        var assets = [AVAsset]()
        for _ in 0..<repeatTime {
            assets.append(asset)
            assets.append(reverseAsset)
        }
        
        return assets
    }
    
    func getShareVideoRepeatTimes(_ videoAsset: AVAsset, rate: Double, maxDuring: TimeInterval) -> Int {
        let singleVideoDuring = CMTimeGetSeconds(videoAsset.duration)
        let positiveAndNegativeVideoDuring = singleVideoDuring * 2
        let rateDuration = positiveAndNegativeVideoDuring / rate
        
        let tempRepeatTimes = Int(maxDuring / rateDuration)
        
        let repeatTimes = tempRepeatTimes < 1 ? 1 : tempRepeatTimes
        
        return repeatTimes
    }
    
    func reverse(avasset: AVAsset, output: URL, finished: @escaping ((_ error: Error?)->())) {
        do {
            try AVVideoReverse().videoReverse(videoAsset: avasset, outputURL: output, fileType: AVFileTypeMPEG4) {
                finished(nil)
            }
        } catch {
            finished(error)
        }
    }
    
    func getWatermarkLayer() -> CALayer {
        let watermark = CALayer()
        let image = UIImage(named: "watermark")
        let cgImage = image?.cgImage
        let videoBounds = asset.getVideoTrackBounds()
        let imageWidth = 110 / UIScreen.main.bounds.width * videoBounds.width
        let imageHeight = 40 / UIScreen.main.bounds.width * videoBounds.width
        let imageX = videoBounds.width - imageWidth
        let imageY = (videoBounds.height - videoBounds.width) * 0.5
        watermark.frame = CGRect(x: imageX, y: imageY, width: imageWidth, height: imageHeight)
        watermark.contents = cgImage
        return watermark
    }

}
