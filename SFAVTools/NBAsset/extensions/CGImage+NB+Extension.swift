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
        
        let context: CGContext? = CGContext.init(data: pxdata, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pxbuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        assert(context != nil, "context is nil")
        
        context?.concatenate(CGAffineTransform.identity)
        
        let rect: CGRect = CGRect(x: 0 + (size.width - CGFloat(width)) * 0.5,
                                  y: (size.height - CGFloat(height)) * 0.5,
                                  width: CGFloat(width),
                                  height: CGFloat(height))
        context?.draw(self, in: rect)
        
        CVPixelBufferUnlockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pxbuffer
    }
    
    func pixelBufferCreate(fromCGImage image: CGImage, size: CGSize) -> CVPixelBuffer? {
        
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
        
        let context: CGContext? = CGContext.init(data: pxdata, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pxbuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        assert(context != nil, "context is nil")
        
        context?.concatenate(CGAffineTransform.identity)
        
        let rect: CGRect = CGRect(x: 0 + (size.width - CGFloat(image.width)) * 0.5,
                                  y: (size.height - CGFloat(image.height)) * 0.5,
                                  width: CGFloat(image.width),
                                  height: CGFloat(image.height))
        context?.draw(image, in: rect)
        
        CVPixelBufferUnlockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pxbuffer
    }
}
