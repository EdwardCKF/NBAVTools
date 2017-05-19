//
//  AVVideoMerge.swift
//  SFAVTools
//
//  Created by 孙凡 on 17/5/5.
//  Copyright © 2017年 Edward. All rights reserved.
//

import UIKit
import AVFoundation

class AVVideoMerge {
    
    class func videoMerge(videoAsset assets: [AVAsset]) throws -> AVMutableComposition {
    
        let mixComposition = AVMutableComposition()
        
        var videoTrack: AVMutableCompositionTrack? //= mixComposition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        var audioTrack: AVMutableCompositionTrack? //= mixComposition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
//        let videoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
//        let audioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        var totalDuration: CMTime = kCMTimeZero
        
        for asset in assets {
            
            let timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration)
            
            for assetVideoTrack in asset.tracks(withMediaType: AVMediaTypeVideo) {
                
                if videoTrack == nil {
                    videoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
                }
                
                do {
                    try videoTrack?.insertTimeRange(timeRange, of: assetVideoTrack, at: totalDuration)
                } catch {
                    throw error
                }
            }
            
            for assetAudioTrack in asset.tracks(withMediaType: AVMediaTypeAudio) {
                
                if audioTrack == nil {
                    audioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
                }
                
                do {
                    try audioTrack?.insertTimeRange(timeRange, of: assetAudioTrack, at: totalDuration)
                } catch {
                    throw error
                }
            }

            totalDuration = CMTimeAdd(totalDuration, asset.duration)
        }
     
        return mixComposition
    }

}
