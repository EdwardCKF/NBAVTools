//
//  AVCommand.swift
//  SFAVTools
//
//  Created by 孙凡 on 17/5/5.
//  Copyright © 2017年 Edward. All rights reserved.
//

import UIKit
import AVFoundation

class AVExportCommand {
    
    var videoComposition: AVMutableVideoComposition?
    var videoAudioMix: AVMutableAudioMix?
    var outputFileType: String?
    var videoPresetName: String?
    
    var exportSession: AVAssetExportSession?
    
    func exportVideo(asset: AVAsset, outputURL: URL,
                     handle: ((_ error: Error? )->())?)
        -> AVAssetExportSession? {
            
            let _videoPresetName = videoPresetName ?? AVAssetExportPreset1280x720
            let _outputFileType = outputFileType ?? AVFileTypeMPEG4
            
            exportSession = AVAssetExportSession(asset: asset, presetName: _videoPresetName)
            
            exportSession?.videoComposition = videoComposition
            exportSession?.audioMix = videoAudioMix
            exportSession?.outputFileType = _outputFileType
            exportSession?.outputURL = outputURL
            
            exportSession?.exportAsynchronously { [weak self] in
                
                guard let state = self?.exportSession?.status else {
                    return
                }
                
                DispatchQueue.main.async {
                    
                    switch state {
                    case .completed:
                        handle?(nil)
                    case .failed:
                        handle?(self?.exportSession?.error)
                    case .cancelled:
                        let error = NSError(domain: "cancel", code: 00001, userInfo: nil)
                        handle?(error)
                    default:
                        let error = NSError(domain: "Unusual error", code: 00002, userInfo: nil)
                        handle?(error)
                    }
                    
                }
                
            }
            
            return exportSession
    }
}
