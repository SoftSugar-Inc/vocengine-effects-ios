//
//  STMobileWrapper+itsMe.h
//  SenseMeEffects
//
//  Created by 马浩萌 on 2023/8/16.
//  Copyright © 2023 SoftSugar. All rights reserved.
//

#import "STMobileWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@protocol STMobileWrapperItsMeDelegate <NSObject>

-(void)confirmWithFaceCount:(NSInteger)faceCount;

@end

@interface STMobileWrapper (itsMe)

@property (nonatomic, weak) id<STMobileWrapperItsMeDelegate> itsMeDelegate;

@property (nonatomic, assign) BOOL isCaptureVerifyOriginImage;
@property (nonatomic, assign) int capturedFaceId;

@end

NS_ASSUME_NONNULL_END
