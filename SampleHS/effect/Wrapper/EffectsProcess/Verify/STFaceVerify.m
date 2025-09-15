//
//  STFaceVerify.m
//  SenseME_HumanAction
//
//  Created by Sunshine on 2019/8/23.
//  Copyright © 2019 SoftSugar. All rights reserved.
//

#import "STFaceVerify.h"
#import "ModelsHeader.h"

@interface STFaceVerify ()

@property (nonatomic) st_handle_t faceVerifyHandle;
@property (nonatomic) st_handle_t humanActionHandle;

@end

@implementation STFaceVerify

- (void)dealloc {
    if (_faceVerifyHandle) {
        st_mobile_verify_destroy(_faceVerifyHandle);
        _faceVerifyHandle = NULL;
    }
    if (_humanActionHandle) {
        st_mobile_human_action_destroy(_humanActionHandle);
        _humanActionHandle = NULL;
    }
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        
        NSString *faceCmpModelPath = [[NSBundle mainBundle] pathForResource:M_SenseME_Verify ofType:@"model"];
        
        st_result_t iRet = st_mobile_verify_create(faceCmpModelPath.UTF8String, &_faceVerifyHandle);
        if (iRet != ST_OK) {
            NSLog(@"st mobile verify create failed: %d", iRet);
            return nil;
        }
        
        //需要比对的图片使用图片config
        NSString *faceModelPath = [[NSBundle mainBundle] pathForResource:@"model" ofType:@"bundle"];
        faceModelPath = [[NSBundle bundleWithPath:faceModelPath] pathForResource:M_SenseME_Face_Video_Template ofType:@"model"];
        iRet = st_mobile_human_action_create(faceModelPath.UTF8String, ST_MOBILE_DETECT_MODE_IMAGE, &_humanActionHandle);
        if (iRet != ST_OK) {
            NSLog(@"human action handle create failed: %d", iRet);
            return nil;
        }
    }
    return self;
}

#pragma mark - score

- (float)verifyImage:(UIImage *)image another:(UIImage *)otherImage {
    
    st_mobile_human_action_t detectResult1 = [self humanActionDetect:image];
    st_mobile_human_action_t detectResult2 = [self humanActionDetect:otherImage];
    
    st_image_t image1 = [self getSTImage:image];
    st_image_t image2 = [self getSTImage:otherImage];
    
    STFeature *feature1 = [self getImageFeature:image1 byDetectResult:detectResult1];
    STFeature *feature2 = [self getImageFeature:image2 byDetectResult:detectResult2];
    
    if (image2.data) {
        free(image2.data);
        image2.data = NULL;
    }
    if (image1.data) {
        free(image1.data);
        image1.data = NULL;
    }
    
    float res = [self verifyFeature:feature1 anotherFeature:feature2];
    
    return res;
}

- (float)verifySTImage:(st_image_t)image another:(st_image_t)otherImage {
    
    //rotation按照0处理
    st_mobile_human_action_t detectResult1 = [self humanActionDetect:image.data width:image.width height:image.height bytesPerRow:(image.width) * 4 format:ST_PIX_FMT_BGRA8888 rotation:ST_CLOCKWISE_ROTATE_0];
    
    st_mobile_human_action_t detectResult2 = [self humanActionDetect:otherImage.data width:otherImage.width height:otherImage.height bytesPerRow:(otherImage.width) * 4 format:ST_PIX_FMT_BGRA8888 rotation:ST_CLOCKWISE_ROTATE_0];
    
    STFeature *feature1 = [self getImageFeature:image byDetectResult:detectResult1];
    STFeature *feature2 = [self getImageFeature:otherImage byDetectResult:detectResult2];
    
    
    //TODO: when release image.data?
    if (image.data) {
        free(image.data);
        image.data = NULL;
    }
    if (image.data) {
        free(image.data);
        image.data = NULL;
    }
    
    return [self verifyFeature:feature1 anotherFeature:feature2];
}

- (float)verifyFeature:(STFeature *)feature anotherImage:(UIImage *)anotherImage {
    st_mobile_human_action_t detectResult2 = [self humanActionDetect:anotherImage];
    st_image_t image2 = [self getSTImage:anotherImage];
    STFeature *feature2 = [self getImageFeature:image2 byDetectResult:detectResult2];
    if (image2.data) {
        free(image2.data);
        image2.data = NULL;
    }
    return [self verifyFeature:feature anotherFeature:feature2];
}

- (float)verifyFeature:(STFeature *)feature anotherFeature:(STFeature *)otherFeature {
    
    if (!_faceVerifyHandle) {
        return 0;
    }
    
    float score = 0;
    
    st_result_t iRet  = st_mobile_verify_get_features_compare_score(_faceVerifyHandle, feature.UTF8String, (uint)feature.length, otherFeature.UTF8String, (uint)otherFeature.length, &score);
    if (iRet != ST_OK) {
        NSLog(@"st mobile verify get features compare score failed: %d", iRet);
    }
    return score;
}

#pragma mark - human action

- (st_mobile_human_action_t)humanActionDetect:(UIImage *)image {
    
    int width = image.size.width;
    int height = image.size.height;
    int bytesPerRow = width * 4;
    
    unsigned char * bgraImage = malloc(width * height * 4);
    
    [self convertUIImage:image toBGRABytes:bgraImage];
    
    
    st_mobile_human_action_t detectResult;
    memset(&detectResult, 0, sizeof(st_mobile_human_action_t));
    
    st_result_t iRet = ST_OK;
    
    iRet = st_mobile_human_action_detect(_humanActionHandle, bgraImage, ST_PIX_FMT_BGRA8888, width, height, bytesPerRow, ST_CLOCKWISE_ROTATE_0, ST_MOBILE_FACE_DETECT, &detectResult);
    
    if (bgraImage) {
        free(bgraImage);
        bgraImage = NULL;
    }
    
    if (iRet != ST_OK) {
        NSLog(@"human action detect failed: %d", iRet);
    }
    
    return detectResult;
    
}

- (st_mobile_human_action_t)humanActionDetect:(unsigned char *)image
                                        width:(int)width
                                       height:(int)height
                                  bytesPerRow:(int)bytePerRow
                                       format:(st_pixel_format)format
                                     rotation:(st_rotate_type)rotate {
    
    st_mobile_human_action_t detectResult;
    memset(&detectResult, 0, sizeof(st_mobile_human_action_t));
    
    st_result_t iRet = ST_OK;
    
    iRet = st_mobile_human_action_detect(_humanActionHandle, image, format, width, height, bytePerRow, rotate, ST_MOBILE_FACE_DETECT, &detectResult);
    
    if (iRet != ST_OK) {
        NSLog(@"human action detect failed: %d", iRet);
    }
    
    return detectResult;
}

#pragma mark - feature
- (STFeature *)getImageFeature:(st_image_t)image byFaceKeyPoints:(st_pointf_t *)faceKeyPoints {
    STFeature *stFeature;
    
    st_result_t iRet = ST_OK;
    
    char *feature = NULL;
    uint featureSize = 0;
    iRet = st_mobile_verify_get_feature(_faceVerifyHandle,
                                        &image,
                                        faceKeyPoints,
                                        106,
                                        &feature,
                                        &featureSize);
    if (iRet != ST_OK) {
        NSLog(@"verify get feature failed: %d", iRet);
    } else {
        
        char *featureCopy = malloc(featureSize * sizeof(unsigned char));
        memset(featureCopy, 0, featureSize);
        
        for (int i = 0; i < featureSize; ++i) {
            featureCopy[i] = feature[i];
        }
        
        if (featureCopy) {
            stFeature = [NSString stringWithUTF8String:featureCopy];
            free(featureCopy);
        }
    }
    return stFeature;
}

- (STFeature *)getImageFeature:(st_image_t)image byDetectResult:(st_mobile_human_action_t)detectResult {
    
    STFeature *stFeature;
    
    st_result_t iRet = ST_OK;
    
    char *feature = NULL;
    uint featureSize = 0;
    iRet = st_mobile_verify_get_feature(_faceVerifyHandle,
                                        &image,
                                        detectResult.p_faces[0].face106.points_array,
                                        106,
                                        &feature,
                                        &featureSize);
    if (iRet != ST_OK) {
        NSLog(@"verify get feature failed: %d", iRet);
    } else {
        
        char *featureCopy = malloc(featureSize * sizeof(unsigned char));
        memset(featureCopy, 0, featureSize);
        
        for (int i = 0; i < featureSize; ++i) {
            featureCopy[i] = feature[i];
        }
        
        if (featureCopy) {
            stFeature = [NSString stringWithUTF8String:featureCopy];
            free(featureCopy);
        }
    }
    return stFeature;
}

- (STFeature *)getUIImageFeature:(UIImage *)image {
    int width = image.size.width;
    int height = image.size.height;
    int bytesPerRow = width * 4;
    
    unsigned char * bgraImage = malloc(width * height * 4);
    
    [self convertUIImage:image toBGRABytes:bgraImage];
    
    STFeature *feature;
    
    //human action detect
    st_mobile_human_action_t detectResult;
    memset(&detectResult, 0, sizeof(st_mobile_human_action_t));
    
    st_result_t iRet = ST_OK;
    
    iRet = st_mobile_human_action_detect(_humanActionHandle, bgraImage, ST_PIX_FMT_BGRA8888, width, height, bytesPerRow, ST_CLOCKWISE_ROTATE_0, ST_MOBILE_FACE_DETECT, &detectResult);

    if (detectResult.face_count == 0) {
        self.faceCount = detectResult.face_count;
        st_rect_t rect = {0};
        self.faceRect = rect;
        return nil;
    } else {
        self.faceCount = detectResult.face_count;
        self.faceRect = detectResult.p_faces[0].face106.rect;
    }
    
    st_image_t image_t;
    memset(&image_t, 0, sizeof(image_t));
    image_t.data = bgraImage;
    image_t.width = width;
    image_t.height = height;
    image_t.stride = width * 4;
    image_t.pixel_format = ST_PIX_FMT_BGRA8888;
    image_t.time_stamp = 0.;
    
    
    feature = [self getImageFeature:image_t byDetectResult:detectResult];
    
    if (bgraImage) {
        free(bgraImage);
        bgraImage = NULL;
    }
    
    return feature;
}

- (STFeature *)getFeature:(unsigned char *)image width:(int)width height:(int)height humanAction:(st_mobile_human_action_t)detectResult {
    st_image_t image_t;
    memset(&image_t, 0, sizeof(image_t));
    image_t.data = image;
    image_t.width = width;
    image_t.height = height;
    image_t.stride = width * 4;
    image_t.pixel_format = ST_PIX_FMT_BGRA8888;
    image_t.time_stamp = 0.;
    
    return [self getImageFeature:image_t byDetectResult:detectResult];
}

- (STFeature *)getFeature:(unsigned char *)image width:(int)width height:(int)height stride:(int)stride faceKeyPoints:(st_pointf_t *)faceKeyPoints {
    st_image_t image_t;
    memset(&image_t, 0, sizeof(image_t));
    image_t.data = image;
    image_t.width = width;
    image_t.height = height;
    image_t.stride = stride;
    image_t.pixel_format = ST_PIX_FMT_BGRA8888;
    image_t.time_stamp = 0.;
    
    return [self getImageFeature:image_t byFaceKeyPoints:faceKeyPoints];
}

- (STFeature *)getFeature:(unsigned char *)image width:(int)width height:(int)height faceKeyPoints:(st_pointf_t *)faceKeyPoints {
    return [self getFeature:image width:width height:height stride:width * 4 faceKeyPoints:faceKeyPoints];
}

#pragma mark - image process

- (void)convertUIImage:(UIImage *)uiImage toBGRABytes:(unsigned char *)pImage {
    
    CGImageRef cgImage = [uiImage CGImage];
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    
    int iWidth = uiImage.size.width;
    int iHeight = uiImage.size.height;
    int iBytesPerPixel = 4;
    int iBytesPerRow = iBytesPerPixel * iWidth;
    int iBitsPerComponent = 8;
    
    CGContextRef context = CGBitmapContextCreate(pImage,
                                                 iWidth,
                                                 iHeight,
                                                 iBitsPerComponent,
                                                 iBytesPerRow,
                                                 colorspace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst
                                                 );
    if (!context) {
        CGColorSpaceRelease(colorspace);
        return;
    }
    
    CGRect rect = CGRectMake(0 , 0 , iWidth , iHeight);
    CGContextDrawImage(context , rect ,cgImage);
    CGColorSpaceRelease(colorspace);
    CGContextRelease(context);
}


//返回st_image_t中的data数据需要调用方释放
- (st_image_t)getSTImage:(UIImage *)image {
    st_image_t image_t;
    memset(&image_t, 0, sizeof(st_image_t));
    
    unsigned char * bgraImage = malloc(image.size.width * 4 * image.size.height);
    
    [self convertUIImage:image toBGRABytes:bgraImage];
    
    image_t.width = image.size.width;
    image_t.height = image.size.height;
    image_t.pixel_format = ST_PIX_FMT_BGRA8888;
    image_t.stride = image.size.width * 4;
    image_t.time_stamp = 0.0;
    
    
    return image_t;
}

@end
