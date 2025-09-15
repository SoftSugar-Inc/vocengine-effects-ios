//
//  STMobileWrapper+mediaBackground.h
//  SenseMeEffects
//
//  Created by 马浩萌 on 2023/3/31.
//  Copyright © 2023 SoftSugar. All rights reserved.
//

#import "STMobileWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface STMobileWrapper (mediaBackground)

#pragma mark - 图片/视频背景
-(void)setImageBackground:(UIImage *)image forPackgeId:(int)packageId;
-(void)setVideoBackground:(NSURL *)videoUrl forPackgeId:(int)packageId;

@end

NS_ASSUME_NONNULL_END
