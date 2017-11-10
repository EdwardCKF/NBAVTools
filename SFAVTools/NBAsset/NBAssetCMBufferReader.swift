//
//  NBAudioCMBufferFilter.swift
//  SFAVTools
//
//  Created by 孙凡 on 2017/7/3.
//  Copyright © 2017年 Edward. All rights reserved.
//

import AVFoundation


class NBAssetCMBufferReader {
    
    class func read(asset: AVAsset, mediaType: AVMediaType) throws -> [CMSampleBuffer] {
        
        let reader: AVAssetReader
        var index: Int = 0
        var buffers: [CMSampleBuffer] = [CMSampleBuffer]()
        
        do {
            reader = try AVAssetReader(asset: asset)
        } catch {
            throw error
        }
        
        let tracks = asset.tracks(withMediaType: mediaType)
        
        if tracks.count <= 0 {
            let error: NSError = NSError(domain: "Edward: This asset has no track at \(mediaType)", code: 0002, userInfo: nil)
            throw error
        }
        
        let readerOutput: AVAssetReaderTrackOutput = AVAssetReaderTrackOutput(track: tracks.first!, outputSettings: nil)
        
        if reader.canAdd(readerOutput) {
            reader.add(readerOutput)
        } else {
            assertionFailure("Reader can not add this output")
        }
        
        reader.startReading()
        
        while let sample = readerOutput.copyNextSampleBuffer() {
            
            let time = CMSampleBufferGetPresentationTimeStamp(sample)
            buffers.append(sample)
            index += 1
            
        }
        
        return buffers
    }
    
    class func read(asset: AVAsset, mediaType: AVMediaType, bufferHandle: ((_ buffer: CMSampleBuffer, _ index: Int, _ time: CMTime)->())) throws -> AVAssetReader {
    
        let reader: AVAssetReader
        var index: Int = 0
        
        do {
            reader = try AVAssetReader(asset: asset)
        } catch {
            throw error
        }
        
        let tracks = asset.tracks(withMediaType: mediaType)
        
        if tracks.count <= 0 {
            let error: NSError = NSError(domain: "Edward: This asset has no track at \(mediaType)", code: 0002, userInfo: nil)
            throw error
        }
        
        let readerOutput: AVAssetReaderTrackOutput = AVAssetReaderTrackOutput(track: tracks.first!, outputSettings: nil)
        
        if reader.canAdd(readerOutput) {
            reader.add(readerOutput)
        } else {
            assertionFailure("Reader can not add this output")
        }
        
        reader.startReading()
        
        while let sample = readerOutput.copyNextSampleBuffer() {

            let time = CMSampleBufferGetPresentationTimeStamp(sample)
            bufferHandle(sample, index, time)
            index += 1
        }

        return reader
    }
}
