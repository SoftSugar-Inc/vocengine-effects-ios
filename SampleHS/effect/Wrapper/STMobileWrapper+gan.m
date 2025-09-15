//
//  STMobileWrapper+gan.m
//  SenseMeEffects
//
//  Created by 马浩萌 on 2023/4/25.
//  Copyright © 2023 SoftSugar. All rights reserved.
//

#import "STMobileWrapper+gan.h"
#import "EFGlobalSingleton.h"
#import "EFMotionManager.h"
#import "AFNetworking.h"
#import "NSData+meterialAes.h"
#import "EffectsImageUtils.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <objc/runtime.h>

@implementation STMobileWrapper (gan)

-(id<STMobileWrapperGanDelegate>)ganDelegate {
    return objc_getAssociatedObject(self, @selector(ganDelegate));
}

-(void)setGanDelegate:(id<STMobileWrapperGanDelegate>)ganDelegate {
    objc_setAssociatedObject(self, @selector(ganDelegate), ganDelegate, OBJC_ASSOCIATION_ASSIGN);
}

// MARK: GAN特效
-(void)processGanImage:(st_effect_module_info_t *)p_module_info_origin {
    st_effect_module_type_t type = p_module_info_origin->type; ///< 贴纸的类型
    int module_id = p_module_info_origin->module_id; ///< 贴纸的ID
    int package_id = p_module_info_origin->package_id; ///< 贴纸所属素材包的ID
    float strength = p_module_info_origin->strength; ///< 贴纸的强度
    int instance_id = p_module_info_origin->instance_id; ///< 贴纸对应的position id, 即st_mobile_human_action_t结果中不同类型结果中的id
    st_effect_module_state_t state = p_module_info_origin->state; ///< 贴纸的播放状态
    int current_frame = p_module_info_origin->current_frame; ///< 当前播放的帧数
    uint64_t position_type = p_module_info_origin->position_type; ///< 贴纸对应的position种类, 见st_mobile_human_action_t中的动作类型
    st_effect_reserved_t rsv_type = p_module_info_origin->rsv_type; ///< 额外数据（reserved）的类型，在特定case下需要强转为特定类型，参考st_effect_reserved_type定义
    
    if ([EFGlobalSingleton sharedInstance].isPortraitOnly) {
        if ([self getDeviceOrientation1: [EFMotionManager sharedInstance].motionManager.accelerometerData] != UIDeviceOrientationPortrait) {
            if (self.ganDelegate && [self.ganDelegate respondsToSelector:@selector(ganNeedReplayWithError:)]) {
                [self.ganDelegate ganNeedReplayWithError:@"此特效不支持屏幕翻转"];
            }
            return;
        }
    }
    
    AFNetworkReachabilityManager *reachabilityManager = [AFNetworkReachabilityManager sharedManager];
    AFNetworkReachabilityStatus networkStatus = reachabilityManager.networkReachabilityStatus;
    if (networkStatus == AFNetworkReachabilityStatusNotReachable) {
        if (self.ganDelegate && [self.ganDelegate respondsToSelector:@selector(ganWithError:)]) {
            [self.ganDelegate ganWithError:@"当前无网络请点击重试"];
        }
        //        [self showHUDOfContent:@"当前无网络请点击重试"];
        st_effect_module_info_t p_module_info_copy = {
            .type = type,
            .module_id = module_id,
            .package_id = package_id,
            .strength = strength,
            .instance_id = instance_id,
            .state = state,
            .current_frame = current_frame,
            .position_type = position_type,
            .rsv_type= rsv_type
        };
        
        st_effect_module_info_t *p_module_info = &p_module_info_copy;
        
        p_module_info->reserved = NULL;
        [self.effectsProcess setModuleInfo:p_module_info];
        return;
    }
    
    st_gan_request_t *gan_request = (st_gan_request_t *)(p_module_info_origin->reserved);
    if (gan_request->in_image == NULL) {
        if (self.ganDelegate && [self.ganDelegate respondsToSelector:@selector(ganNeedReplayWithError:)]) {
            [self.ganDelegate ganNeedReplayWithError:@"请拍摄清晰人脸照片"];
        }
        return;
    }
    st_image_t *st_image = gan_request->in_image;
    CGImageRef imageRef = convertBufferToImage(st_image);
    //    CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef) image);
    
    NSDictionary *properties;
    // create the new output data
    CFMutableDataRef newImageData = CFDataCreateMutable(NULL, 0);
    // my code assumes JPEG type since the input is from the iOS device camera
    CFStringRef typex = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef) @"image/jpg", kUTTypeImage);
    // create the destination
    CGImageDestinationRef destination = CGImageDestinationCreateWithData(newImageData, typex, 1, NULL);
    // add the image to the destination
    CGImageDestinationAddImage(destination, imageRef, (__bridge CFDictionaryRef) properties);
    // finalize the write
    CGImageDestinationFinalize(destination);
    
    // memory cleanup
    //    CGDataProviderRelease(imgDataProvider);
    CGImageRelease(imageRef);
    CFRelease(typex);
    CFRelease(destination);
    
    NSData *imageData = (__bridge_transfer NSData *)newImageData;
    
    __block NSString *functionId = [NSString stringWithFormat:@"%s", gan_request->function];
    NSArray *functionIds = [functionId componentsSeparatedByString:@"|"];
    if (functionIds.count > 1) { // 属性检测-性别
        [self.effectsProcess detectAttribute:st_image->data pixelFormat:st_image->pixel_format imageWidth:st_image->width imageHeight:st_image->height detectResult:*gan_request->p_human withGenderCallback:^(BOOL isMale) {
            if (!isMale) {
                functionId = functionIds[0];
            } else {
                functionId = functionIds[1];
            }
        }];
    }
    
    NSData *aesImageData = [imageData aesProcessBy:@"sN1DEJAVZNf3OdM3" iv:@"GDHgt7hbKpsIR4b4" andOperation:kCCEncrypt];
    NSString *base64AesImageData = [aesImageData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    NSDictionary *parameters = @{
        @"functionId": functionId,
        @"payload": @[@{
            @"data": base64AesImageData
        }]
    };
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    manager.securityPolicy.allowInvalidCertificates = YES;
    [manager.securityPolicy setValidatesDomainName:NO];
    [manager POST:@"https://sf.softsugar.com:30380/alg-dispatcher/task/v1/gan" parameters:parameters headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [manager invalidateSessionCancelingTasks:YES resetSession:YES];
        NSData *ganImageData = [[NSData alloc] initWithBase64EncodedString:responseObject[@"data"][0][@"data"][@"image"] options:NSDataBase64DecodingIgnoreUnknownCharacters];
        CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef)(ganImageData));
        CGImageRef ganCGImage = CGImageCreateWithJPEGDataProvider(imgDataProvider, NULL, true, kCGRenderingIntentDefault);
        size_t width =  CGImageGetWidth(ganCGImage);
        size_t height = CGImageGetHeight(ganCGImage);
        size_t dataSize = width * height * 4;
        unsigned char * pBGRAImageIn = (unsigned char * )malloc(dataSize);
        [EffectsImageUtils convertCGImage:ganCGImage toBGRABytes:pBGRAImageIn];
        
        st_image_t out_image = { .data = pBGRAImageIn, .pixel_format = ST_PIX_FMT_RGBA8888, .width = (int)width, .height = (int)height, .stride = (int)width * 4, .time_stamp = 0.0 };
        st_gan_return_t gan_out = { .out_image = &out_image };
        
        st_effect_module_info_t p_module_info_copy = {
            .type = type,
            .module_id = module_id,
            .package_id = package_id,
            .strength = strength,
            .instance_id = instance_id,
            .state = state,
            .current_frame = current_frame,
            .position_type = position_type,
            .rsv_type= rsv_type
        };
        
        st_effect_module_info_t *p_module_info = &p_module_info_copy;
        
        p_module_info->reserved = &gan_out;
        [self.effectsProcess setModuleInfo:p_module_info];
        free(pBGRAImageIn);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSDictionary *json;
        if (error && error.userInfo && [error.userInfo.allKeys containsObject:AFNetworkingOperationFailingURLResponseDataErrorKey]) {
            json = [NSJSONSerialization JSONObjectWithData:error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] options:0 error:nil];
            NSLog(@"@mahaomeng %@", json[@"message"]);
        }
        NSLog(@"%@", error.localizedDescription);
        [manager invalidateSessionCancelingTasks:YES resetSession:YES];
        st_effect_module_info_t p_module_info_copy = {
            .type = type,
            .module_id = module_id,
            .package_id = package_id,
            .strength = strength,
            .instance_id = instance_id,
            .state = state,
            .current_frame = current_frame,
            .position_type = position_type,
            .rsv_type= rsv_type
        };
        st_effect_module_info_t *p_module_info = &p_module_info_copy;
        p_module_info->reserved = NULL;
        [self.effectsProcess setModuleInfo:p_module_info];
        if (error.code == -1001) {
            if (self.ganDelegate && [self.ganDelegate respondsToSelector:@selector(ganWithError:)]) {
                [self.ganDelegate ganWithError:@"网络状态不佳，请点击重试"];
            }
        } else {
            if (self.ganDelegate && json && [self.ganDelegate respondsToSelector:@selector(ganWithError:)]) {
                [self.ganDelegate ganWithError:json[@"message"]];
            }
        }
    }];
}

- (UIDeviceOrientation)getDeviceOrientation1:(CMAccelerometerData *)accelerometerData {
    if (accelerometerData.acceleration.x >= 0.75) {
        return UIDeviceOrientationLandscapeRight;
    } else if (accelerometerData.acceleration.x <= -0.75) {
        return UIDeviceOrientationLandscapeLeft;
    } else if (accelerometerData.acceleration.y <= -0.75) {
        return UIDeviceOrientationPortrait;
    } else if (accelerometerData.acceleration.y >= 0.75) {
        return UIDeviceOrientationPortraitUpsideDown;
    } else {
        return UIDeviceOrientationPortrait;
    }
}

static CGImageRef convertBufferToImage(st_image_t *stImageBuffer) {
    int f_width = stImageBuffer->width;
    int f_height = stImageBuffer->height;
    CGColorSpaceRef f_colorSpace = CGColorSpaceCreateDeviceRGB();
    
    int f_iBytesPerPixel = 4;
    int f_iBitsPerRow = f_iBytesPerPixel * f_width;
    int f_iBitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(stImageBuffer->data,
                                                 f_width,
                                                 f_height,
                                                 f_iBitsPerComponent,
                                                 f_iBitsPerRow,
                                                 f_colorSpace,
                                                 kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast
                                                 );
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    CGColorSpaceRelease(f_colorSpace);
    return quartzImage;
}


@end
