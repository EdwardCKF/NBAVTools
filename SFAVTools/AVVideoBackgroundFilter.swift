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
        
        var mutableComposition = AVMutableComposition()
        
        
        var assetVideoTrack: AVAssetTrack?
        var assetAudioTrack: AVAssetTrack?
        
        if asset.tracks(withMediaType: AVMediaTypeVideo).count > 0 {
            assetVideoTrack = asset.tracks(withMediaType: AVMediaTypeVideo).first
        }
        
        if asset.tracks(withMediaType: AVMediaTypeAudio).count > 0 {
            assetAudioTrack = asset.tracks(withMediaType: AVMediaTypeAudio).first
        }
        
        guard let _assetVideoTrack = assetVideoTrack else {
            throw NSError(domain: "video asset no videoTrack", code: 0000, userInfo: nil)
        }
        let compositionVideoTrack = mutableComposition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            let timeRange = CMTimeRange(start: kCMTimeZero, duration: asset.duration)
            try compositionVideoTrack.insertTimeRange(timeRange, of: _assetVideoTrack, at: kCMTimeZero)
        } catch {
            throw error
        }
        
        if let _assetAudioTrack = assetAudioTrack {
            let compositionAudioTrack = mutableComposition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                let timeRange = CMTimeRange(start: kCMTimeZero, duration: asset.duration)
                try compositionAudioTrack.insertTimeRange(timeRange, of: _assetAudioTrack, at: kCMTimeZero)
            } catch {
                throw error
            }
        }
        
        //size and transform processing
        let naturalSize = _assetVideoTrack.naturalSize
        let renderH = naturalSize.width / UIScreen.main.bounds.width * UIScreen.main.bounds.height
        let renderSize: CGSize = CGSize(width: naturalSize.width, height: renderH)
        
        var videoTransform = asset.preferredTransform
        print(videoTransform)
        let ty = (renderH - naturalSize.height) * 0.5
        videoTransform.ty = ty
        
        //加水印

        let parentLayer = CALayer()
        parentLayer.backgroundColor = UIColor.blue.cgColor
        let videoLayer = CALayer()
        parentLayer.frame = CGRect(x: 0, y: 0, width: renderSize.width, height: renderSize.height)
        videoLayer.frame = CGRect(x: 0, y: 0, width: renderSize.width, height: renderSize.height)
        videoLayer.backgroundColor = UIColor.yellow.cgColor
        let shapeLayer = CAShapeLayer()
        
        let aPath = UIBezierPath(rect: CGRect(origin: CGPoint(x: 0, y: ty), size: naturalSize))
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
