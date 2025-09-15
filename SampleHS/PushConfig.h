//
//  PushConfig.h
//  SampleHS
//
//  Created by 郭振全 on 2025/5/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PushConfig : NSObject

+ (VeLivePusherConfiguration *)getLivePushConfig;

+ (VeLiveVideoEncoderConfiguration *)getPushVideoEncoderConfiguration;

+ (VeLiveAudioEncoderConfiguration *)getPushAudioEncoderConfiguration;
@end

NS_ASSUME_NONNULL_END
