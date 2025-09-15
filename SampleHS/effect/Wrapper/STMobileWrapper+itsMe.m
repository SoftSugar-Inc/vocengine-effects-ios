//
//  STMobileWrapper+itsMe.m
//  SenseMeEffects
//
//  Created by 马浩萌 on 2023/8/16.
//  Copyright © 2023 SoftSugar. All rights reserved.
//

#import "STMobileWrapper+itsMe.h"
#import <objc/runtime.h>

@interface STMobileWrapper () <EFEffectsProcessItsMeDelegate>

@end

@implementation STMobileWrapper (itsMe)

-(id<STMobileWrapperItsMeDelegate>)itsMeDelegate {
    return objc_getAssociatedObject(self, @selector(itsMeDelegate));
}

-(void)setItsMeDelegate:(id<STMobileWrapperItsMeDelegate>)itsMeDelegate {
    if (!self.effectsProcess.itsMeDelegate || self.effectsProcess.itsMeDelegate != self) {
        self.effectsProcess.itsMeDelegate = self;
    }
    objc_setAssociatedObject(self, @selector(itsMeDelegate), itsMeDelegate, OBJC_ASSOCIATION_ASSIGN);
}

-(void)setIsCaptureVerifyOriginImage:(BOOL)isCaptureVerifyOriginImage {
    self.effectsProcess.isCaptureVerifyOriginImage = isCaptureVerifyOriginImage;
}

-(BOOL)isCaptureVerifyOriginImage {
    return self.effectsProcess.isCaptureVerifyOriginImage;
}

-(void)setCapturedFaceId:(int)capturedFaceId {
    self.effectsProcess.capturedFaceId = capturedFaceId;
}

-(int)capturedFaceId {
    return self.effectsProcess.capturedFaceId;
}

#pragma mark - EFEffectsProcessItsMeDelegate
-(void)onItsMeUpdate {
    NSLog(@"@mahaomeng %s", __func__);
}

-(void)confirmWithFaceCount:(NSInteger)faceCount {
    if (self.itsMeDelegate && [self.itsMeDelegate respondsToSelector:@selector(confirmWithFaceCount:)]) {
        [self.itsMeDelegate confirmWithFaceCount:faceCount];
    }
    NSLog(@"@mahaomeng %s face count:%d", __func__, faceCount);
}

@end
