//
//  STFaceVerify.h
//  SenseME_HumanAction
//
//  Created by Sunshine on 2019/8/23.
//  Copyright © 2019 SoftSugar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "st_mobile_verify.h"
#import "st_mobile_human_action.h"

//typedef struct {
//    const char * _Nullable feature;
//    unsigned int featureSize;
//} STFeature;

typedef NSString STFeature;

NS_ASSUME_NONNULL_BEGIN

@interface STFaceVerify : NSObject

@property (nonatomic, assign) int faceCount;
@property (nonatomic) st_rect_t faceRect;

- (float)verifyFeature:(STFeature *)feature anotherFeature:(STFeature *)otherFeature;

- (STFeature *)getUIImageFeature:(UIImage *)image;

- (STFeature *)getFeature:(unsigned char *)image width:(int)width height:(int)height humanAction:(st_mobile_human_action_t)detectResult;
- (STFeature *)getFeature:(unsigned char *)image width:(int)width height:(int)height stride:(int)stride faceKeyPoints:(st_pointf_t *)faceKeyPoints;
- (STFeature *)getFeature:(unsigned char *)image width:(int)width height:(int)height faceKeyPoints:(st_pointf_t *)faceKeyPoints;

@end

NS_ASSUME_NONNULL_END
