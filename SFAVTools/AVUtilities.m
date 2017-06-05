//
//  AudioMerge.m
//  TestForVideoCreatSwift
//
//  Created by 孙凡 on 16/11/9.
//  Copyright © 2016年 personal. All rights reserved.
//

#import "AVUtilities.h"
#import <AVFoundation/AVFoundation.h>

@interface AVUtilities()

@property (strong, nonatomic) AVAsset *asset;
@property (strong, nonatomic) AVAssetReader *reader;
@property (strong, nonatomic) AVAssetWriter *writer;

@end

@implementation AVUtilities

- (void)assetByReversingVideo:(AVAsset *)asset outputURL:(NSURL *)outputURL complete:(ReverseComplete)callback {
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        self.asset = asset;
        
        NSError *error;
        
        // Initialize the reader
        self.reader = [[AVAssetReader alloc] initWithAsset:self.asset error:&error];
        AVAssetTrack *videoTrack = [[self.asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        
        if (videoTrack == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    callback(NO, error);
                }else {
                    callback(NO, [NSError errorWithDomain:@"倒转视频获取视频轨道失败" code:66666 userInfo:nil]);
                }
            });
            return ;
        }
        
        NSDictionary *readerOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange], kCVPixelBufferPixelFormatTypeKey, nil];
        AVAssetReaderTrackOutput* readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack
                                                                                            outputSettings:readerOutputSettings];
        if (readerOutput == nil || self.reader == nil || error != nil) {
            if (callback != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        callback(NO, error);
                    }else {
                        callback(NO, [NSError errorWithDomain:@"初始化视频倒转失败" code:66666 userInfo:nil]);
                    }
                });
            }
            return ;
        }
        [self.reader addOutput:readerOutput];
        [self.reader startReading];
        
        // read in the samples
        NSMutableArray *samples = [[NSMutableArray alloc] init];
        
        CMSampleBufferRef sample;
        while((sample = [readerOutput copyNextSampleBuffer])) {
            [samples addObject:(__bridge id)sample];
            CFRelease(sample);
        }
        
        // Initialize the writer
        self.writer = [[AVAssetWriter alloc] initWithURL:outputURL
                                                          fileType:AVFileTypeQuickTimeMovie
                                                             error:&error];
        NSDictionary *videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                               @(videoTrack.estimatedDataRate), AVVideoAverageBitRateKey,
                                               nil];
        NSDictionary *writerOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              AVVideoCodecH264, AVVideoCodecKey,
                                              [NSNumber numberWithInt:videoTrack.naturalSize.width], AVVideoWidthKey,
                                              [NSNumber numberWithInt:videoTrack.naturalSize.height], AVVideoHeightKey,
                                              videoCompressionProps, AVVideoCompressionPropertiesKey,
                                              nil];
        AVAssetWriterInput *writerInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                                                         outputSettings:writerOutputSettings
                                                                       sourceFormatHint:(__bridge CMFormatDescriptionRef)[videoTrack.formatDescriptions lastObject]];
        [writerInput setExpectsMediaDataInRealTime:NO];
        
        // Initialize an input adaptor so that we can append PixelBuffer
        AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];
        
        [self.writer addInput:writerInput];
        
        [self.writer startWriting];
        [self.writer startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp((__bridge CMSampleBufferRef)samples[0])];
        
        // Append the frames to the output.
        // Notice we append the frames from the tail end, using the timing of the frames from the front.
        for(NSInteger i = 0; i < samples.count; i++) {
            // Get the presentation time for the frame
            CMTime presentationTime = CMSampleBufferGetPresentationTimeStamp((__bridge CMSampleBufferRef)samples[i]);
            
            // take the image/pixel buffer from tail end of the array
            CVPixelBufferRef imageBufferRef = CMSampleBufferGetImageBuffer((__bridge CMSampleBufferRef)samples[samples.count - i - 1]);
            
            while (!writerInput.readyForMoreMediaData) {
                [NSThread sleepForTimeInterval:0.1];
            }
            
            if (self.writer.status == AVAssetWriterStatusWriting) {
               [pixelBufferAdaptor appendPixelBuffer:imageBufferRef withPresentationTime:presentationTime];   
            }
            
        }
        
        [self.writer finishWritingWithCompletionHandler:^{
        }];
        //    [writer finishWriting];
        
        //        AVAsset *finalAsset = [AVAsset assetWithURL:outputURL];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            if (error) {
                if (callback != nil) {
                    callback(NO, error);
                }
            }else {
                if (callback != nil) {
                    callback(YES, error);
                }
            }
        });
        
    });
}

- (void)dealloc{
    self.asset = nil;
    self.reader = nil;
    self.writer = nil;
    NSLog(@"死掉了");
}

@end
