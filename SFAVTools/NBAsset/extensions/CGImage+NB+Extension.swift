//
//  CGImage+Extension.swift
//  CreateVideoFromImage
//
//  Created by 孙凡 on 2017/6/28.
//  Copyright © 2017年 Edward. All rights reserved.
//

import AVFoundation

extension CGImage {
    
    func getPixelBuffer(size: CGSize) -> CVPixelBuffer? {
    
        let options: NSDictionary
        options = [kCVPixelBufferCGImageCompatibilityKey: true,
                   kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        
        var pxbuffer: CVPixelBuffer? = nil
        
        let status: CVReturn = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, options, &pxbuffer)
        
        assert(status == kCVReturnSuccess && pxbuffer != nil, "CVPixelBufferCreate faild")
        CVPixelBufferLockBaseAddress(pxbuffer!, CVPixelBufferLockFlags())
        
        let pxdata = CVPixelBufferGetBaseAddress(pxbuffer!)
        assert(pxdata != nil)
        
        let rgbColorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerRow: Int = CVPixelBufferGetBytesPerRow(pxbuffer!)
 
        let context: CGContext? = CGContext.init(data: pxdata, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        assert(context != nil, "context is nil")
        
        context?.concatenate(CGAffineTransform.identity)

        let rect: CGRect = CGRect(x: 0,
                                  y: 0,
                                  width: CGFloat(width),
                                  height: CGFloat(height))
        
        context?.scaleBy(x: (size.width / CGFloat(width)), y: (size.height / CGFloat(height)))
        
        context?.draw(self, in: rect)
        
        CVPixelBufferUnlockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pxbuffer
    }
}
