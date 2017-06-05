//
//  Constants.swift
//  SFAVTools
//
//  Created by 孙凡 on 2017/5/19.
//  Copyright © 2017年 Edward. All rights reserved.
//

import UIKit

let SCREEN_WIDTH = UIScreen.main.bounds.width
let SCREEN_HEIGHT = UIScreen.main.bounds.height

let WIDTH_SCALE = UIScreen.main.bounds.size.width/375
let HEIGHT_SCALE = UIScreen.main.bounds.size.height/667

func Degree(_ degree: Double) -> CGFloat {
    return CGFloat(degree / 180 * Double.pi)
}
