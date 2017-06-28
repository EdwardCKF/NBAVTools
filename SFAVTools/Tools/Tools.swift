//
//  Tools.swift
//  SFAVTools
//
//  Created by 孙凡 on 17/5/5.
//  Copyright © 2017年 Edward. All rights reserved.
//

import UIKit
import AVFoundation

class Tools {
    
    class func getTempVideoURL() -> URL {
        return URL(fileURLWithPath: getTempVideoPath())
    }
    
    class func getTempVideoPath() -> String {
        let tempFP = NSTemporaryDirectory()
        let time = "\(Int(Date().timeIntervalSince1970))"
        let path = tempFP + time + ".mp4"
        return path
    }
}
