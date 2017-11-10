//
//  AVVideoBackgroundFilter.swift
//  SFAVTools
//
//  Created by 孙凡 on 2017/5/18.
//  Copyright © 2017年 Edward. All rights reserved.
//

import AVFoundation
import UIKit

class AVVideoBackgroundFilter {
    
    class func videoProcess(videoAsset asset: AVAsset, image: CGImage) throws -> (AVMutableComposition,AVMutableVideoComposition) {
        
        let mutableComposition = AVMutableComposition()
        
        var assetVideoTrack: AVAssetTrack?
        var assetAudioTrack: AVAssetTrack?
        
        if asset.tracks(withMediaType: AVMediaType.video).count > 0 {
            assetVideoTrack = asset.tracks(withMediaType: AVMediaType.video).first
        }
        
        if asset.tracks(withMediaType: AVMediaType.audio).count > 0 {
            assetAudioTrack = asset.tracks(withMediaType: AVMediaType.audio).first
        }
        
        guard let _assetVideoTrack = assetVideoTrack else {
            throw NSError(domain: "video asset no videoTrack", code: 0000, userInfo: nil)
        }
        let compositionVideoTrack = mutableComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            let timeRange = CMTimeRange(start: kCMTimeZero, duration: asset.duration)
            try compositionVideoTrack?.insertTimeRange(timeRange, of: _assetVideoTrack, at: kCMTimeZero)
        } catch {
            throw error
        }
        
        if let _assetAudioTrack = assetAudioTrack {
            let compositionAudioTrack = mutableComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                let timeRange = CMTimeRange(start: kCMTimeZero, duration: asset.duration)
                try compositionAudioTrack?.insertTimeRange(timeRange, of: _assetAudioTrack, at: kCMTimeZero)
            } catch {
                throw error
            }
        }
        
        //size and transform processing
        let applyTransfromSize = _assetVideoTrack.naturalSize.applying(asset.preferredTransform)
        let absWidth = CGFloat(fabs(Double(applyTransfromSize.width)))
        let absHeight = CGFloat(fabs(Double(applyTransfromSize.height)))
        let naturalSize = CGSize(width: absWidth, height: absHeight)
        
        let renderW: CGFloat
        let renderH: CGFloat
        if (naturalSize.width/naturalSize.height) >= (SCREEN_WIDTH/SCREEN_HEIGHT) {
            renderW = naturalSize.width
            renderH = naturalSize.width / SCREEN_WIDTH * SCREEN_HEIGHT
        } else {
            renderH = naturalSize.height
            renderW = naturalSize.height / SCREEN_HEIGHT * SCREEN_WIDTH
        }
     
        let renderSize: CGSize = CGSize(width: renderW, height: renderH)
        
        var videoTransform = asset.preferredTransform
        let tx = (renderW - naturalSize.width) * 0.5
        let ty = (renderH - naturalSize.height) * 0.5
        videoTransform.tx = tx
        videoTransform.ty = ty
        
        //Add background watermark.
        let parentLayer = CALayer()
        parentLayer.backgroundColor = UIColor.blue.cgColor
        let videoLayer = CALayer()
        parentLayer.frame = CGRect(x: 0, y: 0, width: renderSize.width, height: renderSize.height)
        videoLayer.frame = CGRect(x: 0, y: 0, width: renderSize.width, height: renderSize.height)
        videoLayer.backgroundColor = UIColor.yellow.cgColor
        let shapeLayer = CAShapeLayer()
        
        let aPath = UIBezierPath(rect: CGRect(origin: CGPoint(x: tx, y: ty), size: naturalSize))
        shapeLayer.path = aPath.cgPath
        videoLayer.mask = shapeLayer
        
        videoLayer.setNeedsDisplay()
        let imageLayer = createLayer(parentLayer.frame.size, image: image)
        parentLayer.addSublayer(imageLayer)
        parentLayer.addSublayer(videoLayer)
        
        
        //add rensize and transform
        let mutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition.renderSize = renderSize
        mutableVideoComposition.frameDuration = _assetVideoTrack.minFrameDuration
        mutableVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
    

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: mutableComposition.tracks.first!)
        layerInstruction.setTransform(videoTransform, at: kCMTimeZero)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: kCMTimeZero, duration: mutableComposition.duration)
        instruction.backgroundColor = UIColor.red.cgColor
        instruction.layerInstructions = [layerInstruction]
        
        mutableVideoComposition.instructions = [instruction]
        
        return (mutableComposition,mutableVideoComposition)
    }
    
    class func createLayer(_ size: CGSize, image: CGImage) -> CALayer {
        let imageLayer = CALayer()
        imageLayer.frame = CGRect(origin: CGPoint.zero, size: size)
        imageLayer.contents = image
        
        return imageLayer
    }

}
