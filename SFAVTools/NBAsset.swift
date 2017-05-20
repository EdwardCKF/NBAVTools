//
//  NBAsset.swift
//  SFAVTools
//
//  Created by 孙凡 on 2017/5/19.
//  Copyright © 2017年 Edward. All rights reserved.
//

import UIKit
import AVFoundation

public class NBAsset {
    
    fileprivate let asset: AVAsset
    fileprivate var mutableComposition: AVMutableComposition
    fileprivate var mutableVideoComposition: AVMutableVideoComposition
    fileprivate var videoTransform: CGAffineTransform = .identity
    fileprivate var videoRenderSize: CGSize = CGSize.zero
    fileprivate var resolutionModel: String = AVAssetExportPreset1280x720
    fileprivate var exportSession: AVAssetExportSession?
    fileprivate var videoAudioMix: AVMutableAudioMix?
    fileprivate var videoMode: String = AVFileTypeMPEG4
    
    init(_ avAsset: AVAsset) {
        asset = avAsset
        mutableComposition = AVMutableComposition()
        mutableVideoComposition = AVMutableVideoComposition()
        initProperties()
    }
    
    private func initProperties() {
        
        mutableComposition = getMutableComposition(asset)
        videoTransform = getDefultTransform()
        videoRenderSize = getDefultRenderSize()
    }
    
    func startProcessVideo(_ closure: ((_ make: NBAsset)->())) -> NBAsset {
    
        closure(self)
        
        processMutableVideoComposition()
        
        return self
    }
    
    func videoMode(_ mode: String) -> NBAsset {
        
        videoMode = mode
        
        return self
    }
    
    @discardableResult func rotate(_ angle: Double) -> NBAsset {
        
        _rotate(angle)
        
        return self
    }
    
    func trim(progressRange range: Range<Double>) -> NBAsset {
    
        _trim(progressRange: range)
        
        return self
    }
    
    func stretchRender(_ size: CGSize) -> NBAsset {
        
        _stretch(renderSize: videoRenderSize, toSize: size)
    
        return self
    }
    
    func background(_ image: CGImage) -> NBAsset {
        
        _background(image)
        
        return self
    }
    
    func exportVideo(_ url: URL, handle: ((_ error: Error?)->())?) {
        exportSession = AVAssetExportSession(asset: mutableComposition, presetName: resolutionModel)
        exportSession?.videoComposition = mutableVideoComposition
        exportSession?.audioMix = videoAudioMix
        exportSession?.outputFileType = videoMode
        exportSession?.outputURL = url
        exportSession?.exportAsynchronously {
            guard let state = self.exportSession?.status else {
                return
            }
            DispatchQueue.main.async {
                switch state {
                case .completed:
                    handle?(nil)
                case .failed:
                    handle?(self.exportSession?.error)
                case .cancelled:
                    let error = NSError(domain: "cancel", code: 00001, userInfo: nil)
                    handle?(error)
                default:
                    let error = NSError(domain: "Unusual error", code: 00002, userInfo: nil)
                    handle?(error)
                }
            }
        }
    }
    
    fileprivate func getMutableComposition(_ asset: AVAsset, timeRange: CMTimeRange? = nil) -> AVMutableComposition {
        var videoTrack: AVMutableCompositionTrack?
        var audioTrack: AVMutableCompositionTrack?
        
        let mixComposition = AVMutableComposition()

        let _timeRange = timeRange ?? CMTimeRangeMake(kCMTimeZero, asset.duration)
        
        for assetVideoTrack in asset.tracks(withMediaType: AVMediaTypeVideo) {
            
            if videoTrack == nil {
                videoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
            }
            
            do {
                try videoTrack?.insertTimeRange(_timeRange, of: assetVideoTrack, at: kCMTimeZero)
            } catch {
                
            }
        }
        
        for assetAudioTrack in asset.tracks(withMediaType: AVMediaTypeAudio) {
            
            if audioTrack == nil {
                audioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
            }
            
            do {
                try audioTrack?.insertTimeRange(_timeRange, of: assetAudioTrack, at: kCMTimeZero)
            } catch {
                
            }
        }

        return mixComposition
    }

    private func getDefultRenderSize() -> CGSize {
        guard let videoTrack = asset.tracks(withMediaType: AVMediaTypeVideo).first else {
            return CGSize.zero
        }
        return videoTrack.naturalSize
    }
    
    private func getDefultTransform() -> CGAffineTransform {
        guard let videoTrack = asset.tracks(withMediaType: AVMediaTypeVideo).first else {
            return CGAffineTransform.identity
        }
        return videoTrack.preferredTransform
    }
}

extension NBAsset {
    
    fileprivate func processMutableVideoComposition() {
        
        guard let videoTrack = mutableComposition.tracks(withMediaType: AVMediaTypeVideo).first else {
            return
        }
        
        var instruction: AVMutableVideoCompositionInstruction
        var layerInstruction: AVMutableVideoCompositionLayerInstruction
        instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: kCMTimeZero, duration: mutableComposition.duration)
        layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        layerInstruction.setTransform(videoTransform, at: kCMTimeZero)
        instruction.layerInstructions = [layerInstruction]
        
        mutableVideoComposition.renderSize = videoRenderSize
        mutableVideoComposition.frameDuration = videoTrack.minFrameDuration
        mutableVideoComposition.instructions = [instruction]
    }
    
    fileprivate func _rotate(_ angle: Double) {
        
        let degree = Degree(angle)
        
        //transform processing
        videoTransform = videoTransform.rotated(by: CGFloat(degree))
        let applySize = videoRenderSize.applying(videoTransform)
        let absWidth = CGFloat(fabs(Double(applySize.width)))
        let absHeight = CGFloat(fabs(Double(applySize.height)))
        let tx = applySize.width >= 0 ? 0 : absWidth
        let ty = applySize.height >= 0 ? 0 : absHeight
        videoTransform.tx = tx
        videoTransform.ty = ty
        videoRenderSize = CGSize(width: absWidth, height: absHeight)
        
//        processMutableVideoComposition()
    }
    
    fileprivate func _stretch(renderSize fromSize : CGSize, toSize: CGSize) {

        let renderW: CGFloat
        let renderH: CGFloat
        if (fromSize.width/fromSize.height) >= (SCREEN_WIDTH/SCREEN_HEIGHT) {
            renderW = fromSize.width
            renderH = fromSize.width / toSize.width * toSize.height
        } else {
            renderH = fromSize.height
            renderW = fromSize.height / toSize.height * toSize.width
        }
        
        
        let tx = (renderW - fromSize.width) * 0.5
        let ty = (renderH - fromSize.height) * 0.5

        videoTransform.tx = tx + videoTransform.tx
        videoTransform.ty = ty + videoTransform.ty
        
        videoRenderSize = CGSize(width: renderW, height: renderH)
        
//        processMutableVideoComposition()
    }
    
    fileprivate func _background(_ image: CGImage) {
        
        guard let videoTrack = mutableComposition.tracks(withMediaType: AVMediaTypeVideo).first else {
            return
        }
        
        let applySize = videoTrack.naturalSize.applying(videoTransform)
        let absWidth = CGFloat(fabs(Double(applySize.width)))
        let absHeight = CGFloat(fabs(Double(applySize.height)))
        
        //Get parm
        let naturalSize = CGSize(width: absWidth, height: absHeight)
        let renderSize = videoRenderSize
        let maskX: CGFloat = (renderSize.width - absWidth) * 0.5
        let maskY: CGFloat = (renderSize.height - absHeight) * 0.5
        let maskPoint = CGPoint(x: maskX, y: maskY)
    
        //Set layers
        let parentLayer = CALayer()
        parentLayer.frame = CGRect(x: 0, y: 0, width: renderSize.width, height: renderSize.height)
        parentLayer.backgroundColor = UIColor.blue.cgColor
        
        let imageLayer = CALayer()
        imageLayer.frame = parentLayer.bounds
        imageLayer.contents = image
        
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(x: 0, y: 0, width: renderSize.width, height: renderSize.height)
        videoLayer.backgroundColor = UIColor.yellow.cgColor
        
        let shapeLayer = CAShapeLayer()
        let aPath = UIBezierPath(rect: CGRect(origin: maskPoint, size: naturalSize))
        shapeLayer.path = aPath.cgPath
        videoLayer.mask = shapeLayer
        
        videoLayer.setNeedsDisplay()
        
        parentLayer.addSublayer(imageLayer)
        parentLayer.addSublayer(videoLayer)
        
        mutableVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
//        processMutableVideoComposition()
    }
    
    fileprivate func _trim(progressRange range: Range<Double>) {
        
        let rangeStart = range.lowerBound <= 0 ? 0 : range.lowerBound
        let rangeEnd = range.upperBound >= 1 ? 1 : range.upperBound
        
        if rangeStart >= rangeEnd {
            assertionFailure("NBAsset:_trim(progressRange range: Range<Double>): trim range during can not small than 0.")
            return
        }
        
        let videoDuring = CMTimeGetSeconds(asset.duration)
        let timeScale = asset.duration.timescale
        
        let startIntervel = videoDuring * rangeStart
        let endIntervel = videoDuring * rangeEnd
        
        let startTime = CMTime(seconds: startIntervel, preferredTimescale: timeScale)
        let endTime = CMTime(seconds: endIntervel, preferredTimescale: timeScale)
        
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        
        mutableComposition = getMutableComposition(mutableComposition, timeRange: timeRange)
    }
}











