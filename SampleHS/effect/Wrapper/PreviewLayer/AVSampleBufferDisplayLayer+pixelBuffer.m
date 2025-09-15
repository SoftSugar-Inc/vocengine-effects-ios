//
//  AVSampleBufferDisplayLayer+pixelBuffer.m
//  EffectsWrapperTest
//
//  Created by 马浩萌 on 2023/3/31.
//

#import "AVSampleBufferDisplayLayer+pixelBuffer.h"

CMSampleBufferRef pixelBuffer_createSampleBufferFromPixelBuffer(CVPixelBufferRef pixelBuffer) {
    CMSampleBufferRef outputSampleBuffer = NULL;
    CFRetain(pixelBuffer);
    CMSampleTimingInfo timing = {kCMTimeInvalid, kCMTimeInvalid, kCMTimeInvalid};
    CMVideoFormatDescriptionRef videoInfo = NULL;
    OSStatus result = CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);
    result = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, true, NULL, NULL, videoInfo, &timing, &outputSampleBuffer);
    CFRelease(pixelBuffer);
    CFRelease(videoInfo);
    
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(outputSampleBuffer, YES);
    CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
    CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
    return outputSampleBuffer;
}

@implementation AVSampleBufferDisplayLayer (pixelBuffer)

- (void)enqueuePixelBuffer:(CVPixelBufferRef)pixelBuffer {
    CMSampleBufferRef outputSampleBuffer = pixelBuffer_createSampleBufferFromPixelBuffer(pixelBuffer);
    if (self.status == AVQueuedSampleBufferRenderingStatusFailed) {
        [self flush];
    }
    if (outputSampleBuffer != NULL) {
        [self enqueueSampleBuffer:outputSampleBuffer];
        CFRelease(outputSampleBuffer);
    }
}

@end
