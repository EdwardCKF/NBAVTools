//
//  AVAsset+Extension.swift
//  SFAVTools
//
//  Created by 孙凡 on 2017/5/18.
//  Copyright © 2017年 Edward. All rights reserved.
//

import UIKit
import AVFoundation

extension AVAsset {
    
    func getImage(fromTime second: TimeInterval) throws -> UIImage {
        
        guard let _ = tracks(withMediaType: AVMediaTypeVideo).first else {
            throw NSError(domain: "This asset do not have video track", code: 0000, userInfo: nil)
        }
        
        let timeScale = duration.timescale
        
        let generator = AVAssetImageGenerator(asset: self)
        
        generator.appliesPreferredTrackTransform = true
        let allowTimeMargin = CMTime(value: 5, timescale: timeScale)
        generator.requestedTimeToleranceBefore = allowTimeMargin
        generator.requestedTimeToleranceAfter = allowTimeMargin
        
        let time = CMTime(seconds: Double(second), preferredTimescale: timeScale)
        
        var image: UIImage?
        
        var errIndex: Int = 0
        while image == nil {
            
            do {
                var realTime: CMTime = CMTime()
                let cgImage = try generator.copyCGImage(at: time, actualTime: &realTime)
                image = UIImage(cgImage: cgImage)
                
                if let _image = image {
                    return _image
                }
                
            } catch {
                errIndex += 1
                debugPrint("生成图片失败:\(error)")
                if errIndex == 10 {
                    throw error
                }
            }
            
        }
        
        return UIImage()
    }
}
