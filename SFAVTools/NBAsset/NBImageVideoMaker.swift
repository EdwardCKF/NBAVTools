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
    
    enum ProcessState {
        case normal
        case start
        case process
        case end
        case cancel
        case faild
    }
    
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
    private var audioDuration: Double = 0
    private var audioState: ProcessState = .normal
    
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
        
        if let isSuccess = videoWriter?.startWriting() {
            
            if isSuccess == false {
                let error = NSError(domain: "start videoWriter failed", code: 0, userInfo: nil)
                errorCallback(error)
                return
            }
        
        }
        
        videoWriter?.startSession(atSourceTime: kCMTimeZero)
        
        isStart = true
        
        if adaptor?.pixelBufferPool == nil {
            let error: NSError = NSError(domain: "Edward pixelBufferPool is NULL", code: 00002, userInfo: nil)
            errorCallback(error)
            return
        }
        
        CVPixelBufferPoolCreatePixelBuffer(nil, adaptor!.pixelBufferPool!, &buffer)
        
        startProcessAudio()
    }
    
    func end() {
        isStart = false
        
        while audioState == .process {
            Thread.sleep(forTimeInterval: 0.1)
            debugPrint("Edward wait for audio process for 0.1 second")
        }
        
        writerInput?.markAsFinished()
        
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
    
    
    private func startProcessAudio() {
        
        audioState = .start
        
        guard let asset = audioAsset else {
            return
        }
        let queue = DispatchQueue(label: "audioInputQueue")
        
        audioWriterInput?.requestMediaDataWhenReady(on: queue, using: {
            
            if self.audioState == .process {
                return
            }
            
            if self.audioWriterInput == nil {
                return
            }
            
            guard let buffers = try? NBAssetCMBufferReader.read(asset: asset, mediaType: AVMediaTypeAudio) else {
                return
            }
            
            self.audioState = .process
            
            for buffer in buffers {
                
                while !self.audioWriterInput!.isReadyForMoreMediaData {
                    Thread.sleep(forTimeInterval: 0.5)
                    debugPrint("sleep 0.5 audio")
                }
                self.audioWriterInput?.append(buffer)
            }
            
            self.audioWriterInput?.markAsFinished()
            self.audioState = .end
        })
        
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
        
        writerInput?.expectsMediaDataInRealTime = true
        
        adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput!, sourcePixelBufferAttributes: nil)
        
        videoWriter?.add(writerInput!)
        
        //audio
        if audioAsset != nil {
            audioDuration = CMTimeGetSeconds(audioAsset!.duration)
            audioWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: nil)
            audioWriterInput?.expectsMediaDataInRealTime = false
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
