//
//  AudioMerge.h
//  TestForVideoCreatSwift
//
//  Created by 孙凡 on 16/11/9.
//  Copyright © 2016年 personal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AVAsset;

typedef void(^ReverseComplete)(BOOL success, NSError *error);

@interface AVUtilities : NSObject

- (void)assetByReversingVideo:(AVAsset *)asset outputURL:(NSURL *)outputURL complete:(ReverseComplete)callback;

@end
