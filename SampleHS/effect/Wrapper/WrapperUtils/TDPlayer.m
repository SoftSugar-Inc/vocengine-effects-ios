//
//  TDPlayer.m
//  TaoliDance
//
//  Created by 马浩萌 on 2023/1/3.
//

#import "TDPlayer.h"


@interface TDPlayer () <AVPlayerItemOutputPullDelegate>

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItemVideoOutput *playerItemVideoOutput;
@property (nonatomic, assign) TDPlayerStatus status;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic) dispatch_queue_t bufferQueue;

@property (nonatomic) id playToEndObserver;

@end

@implementation TDPlayer

#pragma mark - public functions
- (instancetype)initWithVideoUrl:(NSURL *)videoUrl {
    self = [super init];
    if (self) {
        self.videoUrl = videoUrl;
    }
    return self;
}

-(void)play {
    [self.player play];
}

-(void)pause {
    [self.player pause];
}

-(void)stop {
    [self.player pause];
}

#pragma mark - inner functions
-(void)configPlayer:(AVPlayer *)player andLayer:(CALayer *)layer {
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.frame = layer.bounds;
    [layer addSublayer:playerLayer];
}

//-(AVPlayerItem *)generatePlayerItemWith:(NSURL *)url {
//    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:url];
//    return playerItem;
//}

#pragma mark - AVPlayerItemOutputPullDelegate
- (void)outputMediaDataWillChange:(AVPlayerItemOutput *)sender {
    NSLog(@"%s", __func__);
    self.displayLink.paused = NO;
    CGFloat duration = CMTimeGetSeconds(self.player.currentItem.duration);
    NSLog(@"@mahaomeng %f", duration);
}

#pragma mark - displayLink function
-(void)onDisplayLinkPerform:(CADisplayLink *)sender {
    CMTime outputItemTime = kCMTimeInvalid;
//    NSLog(@"%f-%f", sender.timestamp, sender.duration);
    CFTimeInterval nextVSync = sender.timestamp + sender.duration;
    outputItemTime = [self.playerItemVideoOutput itemTimeForHostTime:nextVSync];
//    NSLog(@"%f", CMTimeGetSeconds(outputItemTime));
    if ([self.playerItemVideoOutput hasNewPixelBufferForItemTime:outputItemTime]) {
        CVPixelBufferRef videoPixelbuffer = [self.playerItemVideoOutput copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];
        CVPixelBufferLockBaseAddress(videoPixelbuffer, 0);
        if (self.delegate && [self.delegate respondsToSelector:@selector(player:didOutput:withTime:)]) {
            [self.delegate player:self didOutput:videoPixelbuffer withTime:outputItemTime];
        }
        CVPixelBufferUnlockBaseAddress(videoPixelbuffer, 0);
        CVPixelBufferRelease(videoPixelbuffer);
    }
}

#pragma mark - properties
-(AVPlayer *)player {
    if (!_player) {
        _player = [[AVPlayer alloc] init];
    }
    return _player;
}

-(AVPlayerItemVideoOutput *)playerItemVideoOutput {
    if (!_playerItemVideoOutput) {
        NSDictionary *pixelBufferAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
        _playerItemVideoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixelBufferAttributes];
        [_playerItemVideoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:0.04];
        [_playerItemVideoOutput setDelegate:self queue:self.bufferQueue];
    }
    return _playerItemVideoOutput;
}

- (void)getVideoRotate{
    AVAsset *asset = [AVAsset assetWithURL:self.videoUrl];
    NSArray<AVAssetTrack *> *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    CGSize videoSize = videoTracks[0].naturalSize;
    int _width = videoSize.width;
    int _height = videoSize.height;
    
    
    CGFloat width = _width, height = _height;
    CGAffineTransform transform = videoTracks[0].preferredTransform;
    CGFloat videoAngleInDegree = atan2(transform.b, transform.a) * 180 / M_PI;
    if (videoAngleInDegree == 0.0) {
        _rotateType = ST_CLOCKWISE_ROTATE_0;
        _tranform = CGAffineTransformIdentity;
    } else if (videoAngleInDegree == 90.0) {
        _rotateType = ST_CLOCKWISE_ROTATE_90;
        _tranform = CGAffineTransformMakeRotation(M_PI / 2);
        width = _height;
        height = _width;
    } else if (videoAngleInDegree == -90.0) {
        _rotateType = ST_CLOCKWISE_ROTATE_270;
        _tranform = CGAffineTransformMakeRotation(-M_PI / 2);
        width = _height;
        height = _width;
    } else {
        _rotateType = ST_CLOCKWISE_ROTATE_180;
        _tranform = CGAffineTransformMakeRotation(M_PI);
    }

    _videoSize = CGSizeMake(width, height);
}


-(dispatch_queue_t)bufferQueue {
    if (!_bufferQueue) {
        _bufferQueue = dispatch_queue_create("com.taolidance.videooutput", NULL);
    }
    return _bufferQueue;
}

-(CADisplayLink *)displayLink {
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onDisplayLinkPerform:)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        _displayLink.paused = YES;
    }
    return _displayLink;
}

-(TDPlayerStatus)status {
    float rate = self.player.rate;
    if (rate == 0) {
        return TDPlayerStatusPause;
    } else if (rate > 0) {
        return TDPlayerStatusPlaying;
    } else {
        return TDPlayerStatusFinished;
    }
}

-(void)setVideoUrl:(NSURL *)videoUrl {
    _videoUrl = videoUrl;
    
    [self.player pause];
    AVAsset *asset = [AVAsset assetWithURL:videoUrl];
    [asset loadValuesAsynchronouslyForKeys:@[@"duration"] completionHandler:^{
        AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
        [playerItem addOutput:self.playerItemVideoOutput];
        [self getVideoRotate];
        [self.player replaceCurrentItemWithPlayerItem:playerItem];
        self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        
        // CMTimeMake(a, b)就是a/b秒之后调用一下block
        //    __block id observer = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 2) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        //        CGFloat value = CMTimeGetSeconds(time);
        //        NSLog(@"@mahaomeng %f", value);
        //    }];
        if (self.playToEndObserver) {
            [[NSNotificationCenter defaultCenter] removeObserver:self.playToEndObserver];
        }
        self.playToEndObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:playerItem queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *sender) {
            //    //        [[weakSelf.avPlayer currentItem] seekToTime:kCMTimeZero];
            //            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(didPlayToEnd)]) {
            //                [weakSelf.delegate didPlayToEnd];
            //            }
            [self.player pause];
            //            self.displayLink.paused = YES;
            //        [self.player removeTimeObserver:observer];
            //        observer = nil;
        }];
    }];
}

@end
