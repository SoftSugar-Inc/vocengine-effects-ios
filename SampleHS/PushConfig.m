//
//  PushConfig.m
//  SampleHS
//
//  Created by 郭振全 on 2025/5/19.
//

#import <TTSDKFramework/VeLivePusher.h>
#import "PushConfig.h"

@implementation PushConfig

+ (VeLivePusherConfiguration *)getLivePushConfig {
    /// 视频采集配置
    // Do any additional setup after loading the view.
    VeLiveVideoCaptureConfiguration *videoCaptureConfig = [[VeLiveVideoCaptureConfiguration alloc] init];
    // 视频采集宽度，单位为 px，默认值为 720。
    videoCaptureConfig.width = 720;
    // 视频采集高度，单位为 px，默认值为 1280。
    videoCaptureConfig.height = 1280;
    // 视频采集帧率，单位为 fps，默认值为 15。
    videoCaptureConfig.fps = 15;
    videoCaptureConfig.pixelFormat = kCVPixelFormatType_32BGRA;
        
    VeLiveAudioCaptureConfiguration *audioCaptureConfig = [[VeLiveAudioCaptureConfiguration alloc] init];
    // 音频采样率，默认值为 `VeLiveAudioSampleRate44100`
    audioCaptureConfig.sampleRate = VeLiveAudioSampleRate44100;
    // 音频采集声道数，默认值为 `VeLiveAudioChannelStereo`
    audioCaptureConfig.channel = VeLiveAudioChannelStereo;

    /// 推流配置
    VeLivePusherConfiguration *config = [[VeLivePusherConfiguration alloc] init];
    // 推流失败后，尝试重连的次数。默认值为 3。
    config.reconnectCount = 3;
    // 推流失败后，尝试重连的时间间隔。单位为 s，默认值为 5。
    config.reconnectIntervalSeconds = 5;
    // 视频采集参数设置
    config.videoCaptureConfig = videoCaptureConfig;
    // 音频采集参数设置
    config.audioCaptureConfig = audioCaptureConfig;
    return config;
}

+ (VeLiveVideoEncoderConfiguration *)getPushVideoEncoderConfiguration {
    VeLiveVideoEncoderConfiguration *videoEncoderConfig = [[VeLiveVideoEncoderConfiguration alloc] initWithResolution:(VeLiveVideoResolution720P)];
    // 推流视频编码格式，默认值为 VeLiveVideoCodecH264
    videoEncoderConfig.codec = VeLiveVideoCodecH264;
    // 视频目标编码码率，单位为 kbps，默认值为 1200。
    videoEncoderConfig.bitrate = 1200;
    // 视频最小编码码率，单位为 kbps，默认值为 800；如果开启自适应码率，推流 SDK 根据网络情况，进行编码码率自适应的最小码率。
    videoEncoderConfig.minBitrate = 800;
    // 视频最大编码码率，单位为 kbps，默认值为 1900；如果开启自适应码率，推流 SDK 根据网络情况，进行编码码率自适应的最大码率。
    videoEncoderConfig.maxBitrate = 1900;
    // 视频 GOP 大小，单位为 s，默认值为 2。
    videoEncoderConfig.gopSize = 2;
    // 视频编码帧率，单位为 fps，默认值为 15。
    videoEncoderConfig.fps = 15;
    // 是否启用 B 帧，默认值为 NO
    videoEncoderConfig.enableBFrame = NO;
    // 是否开启硬件编码，默认值为 YES
    videoEncoderConfig.enableAccelerate = YES;
    return videoEncoderConfig;
}

+ (VeLiveAudioEncoderConfiguration *)getPushAudioEncoderConfiguration {
    VeLiveAudioEncoderConfiguration *audioEncoderConfig = [[VeLiveAudioEncoderConfiguration alloc] init];
    // 音频编码码率，单位为 kbps，默认值为 64。
    audioEncoderConfig.bitrate = 64;
    // 音频编码采样率，默认值为 VeLiveAudioSampleRate44100
    audioEncoderConfig.sampleRate = VeLiveAudioSampleRate44100;
    // 音频声道数，默认值为 VeLiveAudioChannelStereo
    audioEncoderConfig.channel = VeLiveAudioChannelStereo;
    // AAC 编码类型，默认值为 VeLiveAudioAACProfileLC
    audioEncoderConfig.profile = VeLiveAudioAACProfileLC;
    return audioEncoderConfig;
}

@end
