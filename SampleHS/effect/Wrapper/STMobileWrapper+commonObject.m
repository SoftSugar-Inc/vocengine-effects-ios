//
//  STMobileWrapper+commonObject.m
//  SenseMeEffects
//
//  Created by 马浩萌 on 2023/4/14.
//  Copyright © 2023 SoftSugar. All rights reserved.
//

#import "STMobileWrapper+commonObject.h"
#import <objc/runtime.h>

@interface STMobileWrapper () <EFEffectsProcessCommonObjectDelegate>

@end

@implementation STMobileWrapper (commonObject)

-(void)setObjectTrackerRect:(STMobileRect *)rect error:(NSError **)error {
    st_rect_t rect_t = { (int)rect.left, (int)rect.top, (int)rect.right, (int)rect.bottom };
    [self.effectsProcess setObjectTrackRect:rect_t];
    if (!self.effectsProcess.commonObjectDelegate || self.effectsProcess.commonObjectDelegate != self) {
        self.effectsProcess.commonObjectDelegate = self;
    }
}

-(void)setObjctTrackerDelegate:(id<STMobileObjectTrackerDelegate>)objctTrackerDelegate {
    objc_setAssociatedObject(self, @selector(objctTrackerDelegate), objctTrackerDelegate, OBJC_ASSOCIATION_ASSIGN);
}

-(id<STMobileObjectTrackerDelegate>)objctTrackerDelegate {
    return objc_getAssociatedObject(self, @selector(objctTrackerDelegate));
}

#pragma mark - EFEffectsProcessCommonObjectDelegate
- (void)updateCommonObjectPosition:(st_rect_t)rect {
    if (self.objctTrackerDelegate && [self.objctTrackerDelegate respondsToSelector:@selector(objectTrackerRectUpdated:)]) {
        [self.objctTrackerDelegate objectTrackerRectUpdated:[STMobileRect rectWithLeft:rect.left top:rect.top right:rect.right bottom:rect.bottom]];
    }
}
#pragma mark -

@end
