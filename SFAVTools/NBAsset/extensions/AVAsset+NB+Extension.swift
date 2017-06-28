//
//  AVAsset+Extension.swift
//  SFAVTools
//
//  Created by 孙凡 on 2017/5/19.
//  Copyright © 2017年 Edward. All rights reserved.
//

import AVFoundation

public extension AVAsset {
    
    public var nb: NBAsset {
        return NBAsset(self)
    }
    
    func getVideoTrackBounds() -> CGRect {
        
        guard let videoTrack = self.tracks(withMediaType: AVMediaTypeVideo).first else {
            return CGRect.zero
        }
        
        let applySize = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
        let absWidth = CGFloat(fabs(Double(applySize.width)))
        let absHeight = CGFloat(fabs(Double(applySize.height)))

        let naturalSize = CGSize(width: absWidth, height: absHeight)
        return CGRect(origin: CGPoint.zero, size: naturalSize)
    }
}
