//
//  AVVideoReverse.swift
//  SFAVTools
//
//  Created by 孙凡 on 17/5/5.
//  Copyright © 2017年 Edward. All rights reserved.
//

import AVFoundation

class AVVideoReverse {
    
    fileprivate var reader: AVAssetReader?
    fileprivate var writer: AVAssetWriter?
    
    func videoReverse(videoAsset asset: AVAsset, outputURL: URL, fileType: String?, finished: (()->())?) throws {
        
        do {
            reader = try AVAssetReader(asset: asset)
        } catch {
            throw error
        }
        
        guard let videoTrack = asset.tracks(withMediaType: AVMediaTypeVideo).first else {
            throw NSError(domain: "No video track", code: 00003, userInfo: nil)
        }
        
        let readerOutputSettings: [String : Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
        
        reader?.add(readerOutput)
        reader?.startReading()
        
        var samples = [CMSampleBuffer]()
        
        while true {
            
            var sample = readerOutput.copyNextSampleBuffer()
            if sample != nil {
                samples.append(sample!)
            } else {
                break
            }
            sample = nil
        }

        do {
        
            let _fileType = fileType ?? AVFileTypeQuickTimeMovie
            try writer = AVAssetWriter(outputURL: outputURL, fileType: _fileType)
        } catch {
            throw error
        }
        
        let videoCompressionSetting: [String : Any] = [AVVideoAverageBitRateKey:videoTrack.estimatedDataRate]
        
        let writerOutputSetting: [String : Any] = [AVVideoCodecKey: AVVideoCodecH264, AVVideoWidthKey: videoTrack.naturalSize.width, AVVideoHeightKey: videoTrack.naturalSize.height, AVVideoCompressionPropertiesKey: videoCompressionSetting]
        
        let formatDescription: CMFormatDescription = videoTrack.formatDescriptions.last as! CMFormatDescription
        
        let writerInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: writerOutputSetting, sourceFormatHint: formatDescription)
        
        writerInput.expectsMediaDataInRealTime = false
        
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: nil)
        
        writer?.add(writerInput)
        writer?.startWriting()
        
        guard let firstSample = samples.first else {
            throw NSError(domain: "can out get first sample", code: 00003, userInfo: nil)
        }
        let sourceTime = CMSampleBufferGetPresentationTimeStamp(firstSample)
        writer?.startSession(atSourceTime: sourceTime)
        
        for i in 0..<samples.count {
            
            autoreleasepool{
                let presentationTime = CMSampleBufferGetPresentationTimeStamp(samples[i])
                
                if let imageBufferRef: CVPixelBuffer = CMSampleBufferGetImageBuffer(samples[samples.count-i-1]) {
                    
                    while writerInput.isReadyForMoreMediaData == false {
                        Thread.sleep(forTimeInterval: 0.1)
                        debugPrint("writerInput isReadyForMoreMediaData == false, sleep for 0.1 second")
                    }
                    pixelBufferAdaptor.append(imageBufferRef, withPresentationTime: presentationTime)
                }
            }
        }
        
        writer?.finishWriting {
            DispatchQueue.main.async {
                finished?()
            }
        }
    }

}
