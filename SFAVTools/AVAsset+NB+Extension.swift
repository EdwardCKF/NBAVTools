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
}
