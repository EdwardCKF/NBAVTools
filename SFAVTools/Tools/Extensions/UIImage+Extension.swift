//
//  UIImage+Extension.swift
//  SFAVTools
//
//  Created by 孙凡 on 2017/5/18.
//  Copyright © 2017年 Edward. All rights reserved.
//

import UIKit

extension UIImage {
    
    func applyBlur(_ blur: CGFloat) -> UIImage {
        
        let blurImage = UIImageEffects.imageByApplyingBlur(to: self, withRadius: blur, tintColor: nil, saturationDeltaFactor: 1, maskImage: nil)
        return blurImage ?? self
    }
    
    func coreBlur(_ blur: CGFloat) -> UIImage {
        
        let context = CIContext()
        guard let _cgImage = cgImage else {
            return self
        }
        let inputImage = CIImage(cgImage: _cgImage)
        
        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setValue(inputImage, forKey: kCIInputImageKey)
        blurFilter?.setValue(blur, forKey: "inputRadius")
        
        guard let result: CIImage = blurFilter?.value(forKey: kCIOutputImageKey) as? CIImage else {
            return self
        }
        guard let outImage = context.createCGImage(result, from: result.extent) else {
            return self
        }
        
        let blurImage = UIImage(cgImage: outImage)
        
        return blurImage
    }
}
