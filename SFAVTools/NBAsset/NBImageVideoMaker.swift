//
//  NBImageVideoMaker.swift
//  CreateVideoFromImage
//
//  Created by 孙凡 on 2017/6/28.
//  Copyright © 2017年 Edward. All rights reserved.
//

import AVFoundation
import UIKit

protocol NBImageVideoMakerDelegate: class {
    func imageVideoMaker(_ sender: NBImageVideoMaker, index: Int, currentTime: CMTime)
    func imageVideoMakerFinished(_ sender: NBImageVideoMaker)
    func imageVideoMaker(_ sender: NBImageVideoMaker, error: Error)
}

class NBImageVideoMaker {
    
    weak var delegate: NBImageVideoMakerDelegate?
    
    var size: CGSize = CGSize(width: 720, height: 1280)
    var bitRate: Int = 1000000
    var output: URL
    var fps: Int = 24
    var index: Int = 0
    
    private var videoWriter: AVAssetWriter?
    private var writerInput: AVAssetWriterInput?
    private var adaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var buffer: CVPixelBuffer?
    private var presentTime: CMTime = CMTime()
    private var isStart: Bool = false
    
    //audio
    private var audioAsset: AVAsset?
    private var audioWriterInput: AVAssetWriterInput?
    
    init(outputURL: URL, audioAsset asset: AVAsset) {
        output = outputURL
        audioAsset = asset
    }
    
    init(outputURL: URL) {
        output = outputURL
    }
    
    deinit {
        debugPrint("NBImageVideoMaker  deinit")
    }
    
    func start() {
        
        let error = configerProperties()
        
        if error != nil {
            errorCallback(error!)
            return
        }
        isStart = true
        videoWriter?.startWriting()
        videoWriter?.startSession(atSourceTime: kCMTimeZero)
        
        if adaptor?.pixelBufferPool == nil {
            let error: NSError = NSError(domain: "Edward pixelBufferPool is NULL", code: 00002, userInfo: nil)
            errorCallback(error)
            return
        }
        
        CVPixelBufferPoolCreatePixelBuffer(nil, adaptor!.pixelBufferPool!, &buffer)
        
    }
    
    func end() {
        isStart = false
        
        if audioAsset != nil {
            processAudio()
        }
    
        writerInput?.markAsFinished()
        audioWriterInput?.markAsFinished()
        videoWriter?.finishWriting { [weak self] in
            self?.finishedCallback()
        }
    }
    
    func cancel() {
        isStart = false
        videoWriter?.cancelWriting()
        writerInput?.markAsFinished()
    }
    
    func append(image: NBVideoImage) {
        
        if !isStart {
            return
        }
        
        if let time = image.time {
            presentTime = time
        } else {
            let value: CMTimeValue = presentTime.value + 1
            let timeScale: CMTimeScale = presentTime.timescale
            presentTime = CMTimeMake(value, timeScale)
        }
        
        buffer = image.cgImage.getPixelBuffer(size: size)
        
        if buffer != nil {
            append(pixelBuffer: buffer!, inTime: presentTime)
        }
        
    }
    
    private func processAudio() {
        
        guard let asset = audioAsset else {
            return
        }
        do {

            let buffers = try? NBAssetCMBufferReader.read(asset: asset, mediaType: AVMediaTypeAudio)
            
            for buffer in buffers! {
                
                while true {
                    if audioWriterInput!.isReadyForMoreMediaData {
                        audioWriterInput?.append(buffer)
                        debugPrint("11111111111111111111")
                        break
                    } else {
                        debugPrint("audioWriterInput isReadyForMoreMediaData == false, sleep for 0.1 second")
                    }
                }
            }
        
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    private func append(audioBuffer: CMSampleBuffer) {
        if audioWriterInput == nil {
            return
        }
        
        while audioWriterInput!.isReadyForMoreMediaData == false {
            if isStart == false {
                break
            }
            Thread.sleep(forTimeInterval: 0.1)
            debugPrint("audioWriterInput isReadyForMoreMediaData == false, sleep for 0.1 second")
        }
        
        audioWriterInput?.append(audioBuffer)
    }
    
    private func append(pixelBuffer: CVPixelBuffer, inTime: CMTime) {
        
        if writerInput == nil {
            return
        }
        
        while writerInput!.isReadyForMoreMediaData == false {
            if isStart == false {
                break
            }
            Thread.sleep(forTimeInterval: 0.1)
            debugPrint("writerInput isReadyForMoreMediaData == false, sleep for 0.1 second")
        }
        
        if let appendSuccess: Bool = self.adaptor?.append(pixelBuffer, withPresentationTime: inTime) {
            
            if appendSuccess == false {
                return
            }
        }
        
        self.indexCallback(self.index, time: inTime)
        self.index += 1
        
    }
    
    private func configerProperties() -> Error? {
        
        do {
            videoWriter = try AVAssetWriter(url: output, fileType: AVFileTypeQuickTimeMovie)
        } catch {
            return error
        }
        
        let compressionProperties: [String: Any]
        compressionProperties = [AVVideoAverageBitRateKey: bitRate,
                                 AVVideoAllowFrameReorderingKey: false
        ]
        
        let videoSetting: [String: Any]
        videoSetting = [AVVideoCodecKey: AVVideoCodecH264,
                        AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill,
                        AVVideoWidthKey: size.width,
                        AVVideoHeightKey: size.height,
                        AVVideoCompressionPropertiesKey: compressionProperties
        ]
        
        writerInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSetting)
        
        adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput!, sourcePixelBufferAttributes: nil)
        
        videoWriter?.add(writerInput!)
        
        //audio
        if audioAsset != nil {
            audioWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: nil)
            audioWriterInput?.expectsMediaDataInRealTime = true
            videoWriter?.add(audioWriterInput!)
        }
        
        presentTime = CMTime(value: -1, timescale: CMTimeScale(fps))
        
        index = 0
        
        return nil
    }

    
    private func indexCallback(_ index: Int, time: CMTime) {
        DispatchQueue.main.async {
            self.delegate?.imageVideoMaker(self, index: index, currentTime: time)
        }
    }
    
    private func errorCallback(_ error: Error) {
        DispatchQueue.main.async {
            self.delegate?.imageVideoMaker(self, error: error)
        }
    }
    
    private func finishedCallback() {
        DispatchQueue.main.async {
            self.delegate?.imageVideoMakerFinished(self)
        }
    }

}
