//
//  AVSampleBufferDisplayLayer+pixelBuffer.h
//  EffectsWrapperTest
//
//  Created by 马浩萌 on 2023/3/31.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVSampleBufferDisplayLayer (pixelBuffer)

- (void)enqueuePixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
