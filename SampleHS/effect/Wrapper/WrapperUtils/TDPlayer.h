//
//  TDPlayer.h
//  TaoliDance
//
//  Created by 马浩萌 on 2023/1/3.
//

#import <Foundation/Foundation.h>
#import "st_mobile_common.h"

@import AVFoundation;

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    TDPlayerStatusPlaying = 1,
    TDPlayerStatusPause,
    TDPlayerStatusFinished,
} TDPlayerStatus;

@class TDPlayer;

@protocol TDPlayerDelegate <NSObject>

-(void)player:(TDPlayer *)player didOutput:(CVPixelBufferRef)pixelBuffer withTime:(CMTime)outputTime;

@end

@interface TDPlayer : NSObject
@property (nonatomic, assign) CGSize videoSize;

- (instancetype)initWithVideoUrl:(NSURL *)videoUrl NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong) NSURL *videoUrl;
@property (nonatomic) CGAffineTransform tranform;
@property (nonatomic, assign) st_rotate_type rotateType;
@property (nonatomic, assign, readonly) TDPlayerStatus status;
@property (nonatomic, weak) id<TDPlayerDelegate> delegate;
@property (nonatomic, readonly) dispatch_queue_t bufferQueue;

-(void)play;
-(void)pause;

@end

NS_ASSUME_NONNULL_END
