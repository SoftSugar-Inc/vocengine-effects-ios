//
//  STMobileWrapper+gan.h
//  SenseMeEffects
//
//  Created by 马浩萌 on 2023/4/25.
//  Copyright © 2023 SoftSugar. All rights reserved.
//

#import "STMobileWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@protocol STMobileWrapperGanDelegate <NSObject>

-(void)ganWithError:(NSString *)errorDescription;
-(void)ganNeedReplayWithError:(NSString *)errorDescription;

@end

@interface STMobileWrapper (gan)

@property (nonatomic, weak) id<STMobileWrapperGanDelegate> ganDelegate;

@end

NS_ASSUME_NONNULL_END
