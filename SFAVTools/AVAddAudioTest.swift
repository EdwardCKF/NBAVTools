//
//  AVAddAudioTest.swift
//  SFAVTools
//
//  Created by 孙凡 on 2017/7/3.
//  Copyright © 2017年 Edward. All rights reserved.
//

import AVFoundation

class AVAddAudioTest {

    
    class func videoReverse(videoAsset asset: AVAsset, outputURL: URL, fileType: String?, finished: (()->())?) throws {
        
        let audioURL: URL = Bundle.main.url(forResource: "login_back_music", withExtension: "mp3")!
        let audioAsset: AVAsset = AVAsset(url: audioURL)
        
        var reader: AVAssetReader?
        var writer: AVAssetWriter?
        
        do {
            reader = try AVAssetReader(asset: asset)
        } catch {
            throw error
        }
        
        guard let videoTrack = asset.tracks(withMediaType: AVMediaTypeVideo).first else {
            throw NSError(domain: "No video track", code: 00003, userInfo: nil)
        }
        
        let readerOutputSettings: [String : Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        let readerVideoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
        
        reader?.add(readerVideoOutput)
        reader?.startReading()
        
        var videoSamples = [CMSampleBuffer]()
        
        while true {
            
            var sample = readerVideoOutput.copyNextSampleBuffer()
            
            
            
            if sample != nil {
                
                if let descripe = CMSampleBufferGetFormatDescription(sample!) {
                    let type = CMFormatDescriptionGetMediaType(descripe)
                    switch type {
                    case kCMMediaType_Video:
                        print("======type:Video")
                    case kCMMediaType_Audio:
                        print("======type:Audio")
                    default:
                        
                        print("=====type:\(type)")
                    }
                }
                
                videoSamples.append(sample!)
            } else {
                break
            }
            sample = nil
        }
        /////////////////////////////////////
        do {
            
            let _fileType = fileType ?? AVFileTypeQuickTimeMovie
            try writer = AVAssetWriter(outputURL: outputURL, fileType: _fileType)
        } catch {
            throw error
        }
        
        let videoCompressionSetting: [String : Any] = [AVVideoAverageBitRateKey:videoTrack.estimatedDataRate]
        
        let writerOutputSetting: [String : Any] = [AVVideoCodecKey: AVVideoCodecH264, AVVideoWidthKey: videoTrack.naturalSize.width, AVVideoHeightKey: videoTrack.naturalSize.height, AVVideoCompressionPropertiesKey: videoCompressionSetting]
        
        let formatDescription: CMFormatDescription = videoTrack.formatDescriptions.last as! CMFormatDescription
        
        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: writerOutputSetting, sourceFormatHint: formatDescription)
        
        videoWriterInput.expectsMediaDataInRealTime = false
        
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: nil)
        
        
        
        
        
        let writerAudioInput: AVAssetWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: nil)
        writerAudioInput.expectsMediaDataInRealTime = true
        
        writer?.add(writerAudioInput)
        writer?.add(videoWriterInput)
        
        writer?.startWriting()
        
        
        
        guard let firstSample = videoSamples.first else {
            throw NSError(domain: "can out get first sample", code: 00003, userInfo: nil)
        }
        let sourceTime = CMSampleBufferGetPresentationTimeStamp(firstSample)
        writer?.startSession(atSourceTime: sourceTime)
        
        for i in 0..<videoSamples.count {
            
            autoreleasepool{
                let presentationTime = CMSampleBufferGetPresentationTimeStamp(videoSamples[i])
                
                if let imageBufferRef: CVPixelBuffer = CMSampleBufferGetImageBuffer(videoSamples[i]) {
                    
                    while videoWriterInput.isReadyForMoreMediaData == false {
                        Thread.sleep(forTimeInterval: 0.1)
                        debugPrint("writerInput isReadyForMoreMediaData == false, sleep for 0.1 second")
                    }
                    pixelBufferAdaptor.append(imageBufferRef, withPresentationTime: presentationTime)
                }
            }
        }
        
        _ = try? NBAssetCMBufferReader.read(asset: audioAsset, mediaType: AVMediaTypeAudio) { (buffer, _, _) in
            while writerAudioInput.isReadyForMoreMediaData == false {
                Thread.sleep(forTimeInterval: 0.1)
                debugPrint("writerAudioInput isReadyForMoreMediaData == false, sleep for 0.1 second")
            }
            
            writerAudioInput.append(buffer)
        }

        videoWriterInput.markAsFinished()
        writerAudioInput.markAsFinished()
        
        writer?.finishWriting {
            DispatchQueue.main.async {
                finished?()
            }
        }
    }
}
