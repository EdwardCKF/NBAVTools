//
//  NBImageVideoMaker.swift
//  CreateVideoFromImage
//
//  Created by 孙凡 on 2017/6/28.
//  Copyright © 2017年 Edward. All rights reserved.
//

import AVFoundation
import UIKit

class NBImageVideoMaker {
    
    
    class func createVideo(fromImages images: [NBVideoImage], destination: String, videoSize: CGSize, finishHandle: (()->())?) throws {
        
        let videoWriter: AVAssetWriter
        
        let videoURL: URL = URL(fileURLWithPath: destination)
        do {
            videoWriter = try AVAssetWriter(url: videoURL, fileType: AVFileTypeMPEG4)
        } catch {
            throw error
        }
        
        let videoSetting: [String: Any]
        videoSetting = [AVVideoCodecKey: AVVideoCodecH264,
                        AVVideoWidthKey: videoSize.width,
                        AVVideoHeightKey: videoSize.height
        ]
        
        let writerInput: AVAssetWriterInput
        writerInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSetting)
        
        let adaptor: AVAssetWriterInputPixelBufferAdaptor
        adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: nil)
        
        
        videoWriter.add(writerInput)
        
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: kCMTimeZero)
        
        var buffer: CVPixelBuffer?
        if adaptor.pixelBufferPool == nil {
            throw NSError(domain: "Edward pixelBufferPool is NULL", code: 00002, userInfo: nil)
        }
        
        CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &buffer)
        
        let defaultFPS: CMTimeScale = 24
        var presentTime: CMTime = CMTime(value: -1, timescale: defaultFPS)
        
        for i in 0..<images.count {
            
            autoreleasepool{
                
                while writerInput.isReadyForMoreMediaData == false {
                    Thread.sleep(forTimeInterval: 0.1)
                    debugPrint("writerInput isReadyForMoreMediaData == false, sleep for 0.1 second")
                }
                
                let image: NBVideoImage = images[i]
                
                if let time = image.time {
                    presentTime = time
                } else {
                    presentTime = CMTimeMake((presentTime.value + 1), presentTime.timescale)
                }
                
                if i > images.count {
                    buffer = nil
                } else {
                    
                    buffer = images[i].cgImage.getPixelBuffer(size: videoSize)
                    
                    if buffer == nil {
                        return
                    }
                    
                    let appendSuccess: Bool = adaptor.append(buffer!, withPresentationTime: presentTime)
                    assert(appendSuccess, "Failed to append")
                }
                
            }
            
        }
        
        writerInput.markAsFinished()
        
        videoWriter.finishWriting {
            finishHandle?()
        }
        
    }

}
