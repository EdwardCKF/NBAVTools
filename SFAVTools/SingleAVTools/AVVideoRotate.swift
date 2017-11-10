//
//  AVVideoRotate.swift
//  SFAVTools
//
//  Created by 孙凡 on 2017/5/17.
//  Copyright © 2017年 Edward. All rights reserved.
//

import AVFoundation

class AVVideoRotate {
    
    class func videoRotate(videoAsset asset: AVAsset, rotationAngle: Double) throws -> (AVMutableComposition,AVMutableVideoComposition) {
        
        let degree = Degree(rotationAngle)
        
        var instruction: AVMutableVideoCompositionInstruction
        var layerInstruction: AVMutableVideoCompositionLayerInstruction
        
        var assetVideoTrack: AVAssetTrack?
        var assetAudioTrack: AVAssetTrack?
        
        if asset.tracks(withMediaType: AVMediaType.video).count > 0 {
            assetVideoTrack = asset.tracks(withMediaType: AVMediaType.video).first
        }
        
        if asset.tracks(withMediaType: AVMediaType.audio).count > 0 {
            assetAudioTrack = asset.tracks(withMediaType: AVMediaType.audio).first
        }
        
        let mutableComposition = AVMutableComposition()
        
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
        

        //transform processing
        let naturalSize = _assetVideoTrack.naturalSize
        let originTransform = asset.preferredTransform
        var videoTransform = originTransform.rotated(by: CGFloat(degree))
        let applySize = naturalSize.applying(videoTransform)
        let absWidth = CGFloat(fabs(Double(applySize.width)))
        let absHeight = CGFloat(fabs(Double(applySize.height)))
        let tx = applySize.width >= 0 ? 0 : absWidth
        let ty = applySize.height >= 0 ? 0 : absHeight
        videoTransform.tx = tx
        videoTransform.ty = ty
        let renderSize: CGSize = CGSize(width: absWidth, height: absHeight)

        
        //add rensize and transform
        let mutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition.renderSize = renderSize
        mutableVideoComposition.frameDuration = _assetVideoTrack.minFrameDuration
        
        instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: kCMTimeZero, duration: mutableComposition.duration)
        layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: mutableComposition.tracks.first!)
        layerInstruction.setTransform(videoTransform, at: kCMTimeZero)
        
        
        instruction.layerInstructions = [layerInstruction]
        mutableVideoComposition.instructions = [instruction]
        
        return (mutableComposition,mutableVideoComposition)
    
    }

}
