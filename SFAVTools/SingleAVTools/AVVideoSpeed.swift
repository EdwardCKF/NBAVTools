//
//  AVVideoSpeed.swift
//  SFAVTools
//
//  Created by 孙凡 on 17/5/5.
//  Copyright © 2017年 Edward. All rights reserved.
//

import AVFoundation

class AVVideoSpeed {

    class func videoSpeedChange(videoAsset asset: AVAsset, speedMultiple: Double) throws -> AVMutableComposition {
    
        
        let mixComposition = AVMutableComposition()
        
        let videoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        
        let timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration)
        let scaleTimeValue = Double(asset.duration.value)/speedMultiple
        let scaleTime = CMTime(value: CMTimeValue(scaleTimeValue), timescale: asset.duration.timescale)
        
        for assetVideoTrack in asset.tracks(withMediaType: AVMediaTypeVideo) {
            
            do {
                try videoTrack.insertTimeRange(timeRange, of: assetVideoTrack, at: kCMTimeZero)
                videoTrack.scaleTimeRange(timeRange, toDuration: scaleTime)
            } catch {
                throw error
            }
        }
        
        for assetAudioTrack in asset.tracks(withMediaType: AVMediaTypeAudio) {
            
            do {
                try audioTrack.insertTimeRange(timeRange, of: assetAudioTrack, at: kCMTimeZero)
                audioTrack.scaleTimeRange(timeRange, toDuration: scaleTime)
            } catch {
                throw error
            }
        }

        return mixComposition
    }
}
