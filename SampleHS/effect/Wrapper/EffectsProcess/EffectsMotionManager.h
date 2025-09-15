//
//  EffectsMotionManager.h
//  SenseMeEffects
//
//  Created by 马浩萌 on 2025/1/8.
//  Copyright © 2025 SoftSugar. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreMotion;

NS_ASSUME_NONNULL_BEGIN

@interface EffectsMotionManager : NSObject
@property (nonatomic, strong) CMMotionManager *motionManager;

+ (instancetype)sharedInstance;
- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
