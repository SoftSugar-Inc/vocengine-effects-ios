//
//  EffectsMotionManager.m
//  SenseMeEffects
//
//  Created by 马浩萌 on 2025/1/8.
//  Copyright © 2025 SoftSugar. All rights reserved.
//

#import "EffectsMotionManager.h"

@interface EffectsMotionManager ()
{
    BOOL _begin;
}

@end

@implementation EffectsMotionManager

+ (instancetype)sharedInstance{
    static EffectsMotionManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EffectsMotionManager alloc] init];
    });
    return manager;
}

#pragma mark - getter/setter
- (CMMotionManager *)motionManager{
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
        _motionManager.accelerometerUpdateInterval = 0.5;
        _motionManager.deviceMotionUpdateInterval = 1 / 25.0;
    }
    return _motionManager;
}

- (void)start{
    if(_begin) return;
    _begin = YES;
    if ([self.motionManager isAccelerometerAvailable]) {
        [self.motionManager startAccelerometerUpdates];
    }
    if ([self.motionManager isDeviceMotionAvailable]) {
        [self.motionManager startDeviceMotionUpdates];
    }
}

- (void)stop{
    _begin = NO;
    [self.motionManager stopAccelerometerUpdates];
    [self.motionManager stopDeviceMotionUpdates];
}

@end
