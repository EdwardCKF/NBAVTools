//
//  VideoCompression.swift
//  VideoCompression
//
//  Created by 孙凡 on 2017/7/25.
//  Copyright © 2017年 Edward. All rights reserved.
//

import AVFoundation

protocol VideoCompressionDelegate: class {
    func videoCompressionError(_ error: Error, sender: VideoCompression)
    func vidoeCompressionFinished(_ output: URL, sender: VideoCompression)
}

class VideoCompression {
    
    weak var delegate: VideoCompressionDelegate?
    var bitRate: Float = 0
    var width: Float = 0
    var height: Float = 0
    
    private let input: AVAsset
    private let output: URL
    
    private var isVideoFinished: Bool = false
    private var isAudioFinished: Bool = false
    
    private var videoTrack: AVAssetTrack?
    private var audioTrack: AVAssetTrack?
    
    private var reader: AVAssetReader?
    private var videoReaderOutput: AVAssetReaderTrackOutput?
    private var audioReaderOutput: AVAssetReaderTrackOutput?
    
    private var writer: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var audioWriterInput: AVAssetWriterInput?
    
    init(inputAsset: AVAsset, outputURL: URL) {
        input = inputAsset
        output = outputURL
        
        if let _videoTrack = input.tracks(withMediaType: AVMediaType.video).first {
            videoTrack = _videoTrack
            bitRate = _videoTrack.estimatedDataRate
            width = Float(_videoTrack.naturalSize.width)
            height = Float(_videoTrack.naturalSize.height)
        } else {
            assertionFailure("asset has no video track!!")
        }
        
        if let _audioTrack = input.tracks(withMediaType: AVMediaType.audio).first {
            audioTrack = _audioTrack
        }
    }
    
    func start() {
        
        setupParameters()
        reader?.startReading()
        
        writer?.startWriting()
        writer?.startSession(atSourceTime: kCMTimeZero)
        
        if videoTrack != nil {
            startVideo()
        }
        
        if audioTrack != nil {
            startAudio()
        }
    }
    
    func cancel() {
        reader?.cancelReading()
        writer?.cancelWriting()
    }
    
    private func finishedhandle() {
        
        func handle() {
            
            writer?.finishWriting {
                DispatchQueue.main.async {
                    self.delegate?.vidoeCompressionFinished(self.output, sender: self)
                }
            }
        }
        
        if audioTrack != nil && videoTrack != nil {
            
            if isAudioFinished && isVideoFinished {
                handle()
            }
            
        } else if audioTrack == nil && videoTrack != nil {
            
            if isVideoFinished {
                handle()
            }
        } else {
            
            writer?.cancelWriting()
        }
        
    }
    
    private func setupParameters() {
        setReader()
        setWriter()
    }
    
    private func setReader() {
        
        func setVideoReader(videoTrack: AVAssetTrack) {
            let readerOutputSettings: [String : Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
            videoReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
        }
        
        func setAudioReader(audioTrack: AVAssetTrack) {
            audioReaderOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: nil)
        }
        
        do {
            reader = try AVAssetReader(asset: input)
        } catch {
            delegate?.videoCompressionError(error, sender: self)
        }
        
        if videoTrack != nil {
            setVideoReader(videoTrack: videoTrack!)
            reader?.add(videoReaderOutput!)
        }
        
        if audioTrack != nil {
            setAudioReader(audioTrack: audioTrack!)
            reader?.add(audioReaderOutput!)
        }
    }
    
    private func setWriter() {
        do {
            try writer = AVAssetWriter(outputURL: output, fileType: .mov)
        } catch {
            delegate?.videoCompressionError(error, sender: self)
        }
        
        func setVideoWriterInput() {
            
            let videoCompressionSetting: [String : Any] = [AVVideoAverageBitRateKey: bitRate]
            
            let writerOutputSetting: [String : Any] = [AVVideoCodecKey: AVVideoCodecH264, AVVideoWidthKey: width, AVVideoHeightKey: height, AVVideoCompressionPropertiesKey: videoCompressionSetting]
            
            videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: writerOutputSetting, sourceFormatHint: nil)
            
            videoWriterInput?.expectsMediaDataInRealTime = true
            
            pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput!, sourcePixelBufferAttributes: nil)
        }
        
        func setAudioWriterInput() {
            audioWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: nil)
            audioWriterInput?.expectsMediaDataInRealTime = true
        }
        
        if videoTrack != nil {
            setVideoWriterInput()
            writer?.add(videoWriterInput!)
        }
        
        if audioTrack != nil {
            setAudioWriterInput()
            writer?.add(audioWriterInput!)
        }
    }
    
    private func startVideo() {
        
        while true {
            
            if let videoCMBuffer = videoReaderOutput?.copyNextSampleBuffer() {
                
                
                let time = CMSampleBufferGetPresentationTimeStamp(videoCMBuffer)
                guard let cvBuffer = CMSampleBufferGetImageBuffer(videoCMBuffer) else {
                    return
                }
                
                while videoWriterInput?.isReadyForMoreMediaData == false {
                    Thread.sleep(forTimeInterval: 0.1)
                    debugPrint("writerInput isReadyForMoreMediaData == false, sleep for 0.1 second")
                }
                
                pixelBufferAdaptor?.append(cvBuffer, withPresentationTime: time)
                
            } else {
                videoWriterInput?.markAsFinished()
                isVideoFinished = true
                finishedhandle()
                break
            }
            
        }
    }
    
    private func startAudio() {
        
        while true {
            
            if let audioCMBuffer = audioReaderOutput?.copyNextSampleBuffer() {
                
                while audioWriterInput?.isReadyForMoreMediaData == false {
                    Thread.sleep(forTimeInterval: 0.9)
                    debugPrint("audioWriterInput isReadyForMoreMediaData == false, sleep for 0.9 second")
                }
                
                audioWriterInput?.append(audioCMBuffer)
            } else {
                
                audioWriterInput?.markAsFinished()
                isAudioFinished = true
                finishedhandle()
                break
            }
        }
        
    }
    
}
