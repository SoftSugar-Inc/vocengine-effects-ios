//
//  STMobileWrapper+commonObject.h
//  SenseMeEffects
//
//  Created by 马浩萌 on 2023/4/14.
//  Copyright © 2023 SoftSugar. All rights reserved.
//

#import "STMobileWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@protocol STMobileObjectTrackerDelegate <NSObject>

-(void)objectTrackerRectUpdated:(STMobileRect *)rect;

@end

@interface STMobileWrapper (commonObject)

@property (nonatomic, weak) id<STMobileObjectTrackerDelegate> objctTrackerDelegate;

#pragma mark - 通用物体跟踪
-(void)setObjectTrackerRect:(STMobileRect *)rect error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
