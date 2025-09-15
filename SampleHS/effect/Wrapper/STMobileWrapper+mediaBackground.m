//
//  STMobileWrapper+mediaBackground.m
//  SenseMeEffects
//
//  Created by 马浩萌 on 2023/3/31.
//  Copyright © 2023 SoftSugar. All rights reserved.
//

#import "STMobileWrapper+mediaBackground.h"
#import "EffectsImageUtils.h"
@import VideoToolbox;
#import <objc/runtime.h>
#import "TDPlayer.h"

@interface STMobileWrapper () <TDPlayerDelegate>

@property (nonatomic, assign) int packageId;
@property (nonatomic, strong) TDPlayer *player;

@end

@implementation STMobileWrapper (mediaBackground)

-(void)setImageBackground:(UIImage *)image forPackgeId:(int)packageId {
    [self stopVideo];
    if (packageId == -1) {
//        DLog(@"未设置贴纸素材");
        return;
    }
    
    if (image.imageOrientation != UIImageOrientationUp) { // 将图片转正
        UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
        [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    st_effect_module_info_t *module_info = malloc(sizeof(st_effect_module_info_t));
    [self.effectsProcess getModulesInPackage:packageId modules:module_info];
    
    int maxSize = 1080 * 1920;
    
    int iWidth = image.size.width;
    int iHeight = image.size.height;
    
    if (iWidth * iHeight > maxSize) {
        int multiple = 1;
        if (iWidth > 1080) {
            multiple = (int)ceil(iWidth / 1080);
        } else if (iHeight > 1920) {
            multiple = (int)ceil(iHeight / 1920);
        }
        iWidth /= multiple;
        iHeight /= multiple;
    }
    
    int iBytesPerRow = iWidth * 4;
    int dataSize = iWidth * iHeight * 4;
    unsigned char * pBGRAImageIn = (unsigned char * )malloc(dataSize);
    [EffectsImageUtils convertUIImage:image toBGRABytes:pBGRAImageIn];
    
    st_image_t st_image = {pBGRAImageIn, ST_PIX_FMT_RGBA8888, iWidth, iHeight, iBytesPerRow, 0.0};
    module_info->rsv_type = EFFECT_RESERVED_IMAGE;
    module_info->reserved = &st_image;
    
    [self.effectsProcess setModuleInfo:module_info];
    
    free(pBGRAImageIn);
    free(module_info);
}

-(void)setVideoBackground:(NSURL *)videoUrl forPackgeId:(int)packageId {
    self.packageId = packageId;
    if (self.player) {
        self.player.videoUrl = videoUrl;
    } else {
        self.player = [[TDPlayer alloc] initWithVideoUrl:videoUrl];
        self.player.delegate = self;
    }
    [self.player play];
}

-(void)stopVideo {
    if (self.player) {
        [self.player pause];
    }
}

#pragma mark - TDPlayerDelegate
-(void)player:(TDPlayer *)player didOutput:(CVPixelBufferRef)videoPixelbuffer withTime:(CMTime)outputTime {
    if (self.packageId == -1) {
//        DLog(@"未设置贴纸素材");
    } else {
        CVPixelBufferRef pixelBuffer = [self rotatePixelBuffer:videoPixelbuffer];
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        int iWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
        int iHeight = (int)CVPixelBufferGetHeight(pixelBuffer);

//        imageData = [self solvePaddingImage:imageData width:iWidth height:iHeight bytesPerRow:&iBytesPerRow];

        CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
        
//        int iBytesPerPixel = 4;
//        int iBytesPerRow = iBytesPerPixel * iWidth;
        int iBitsPerComponent = 8;
        int dataSize = iWidth * iHeight * 4;
        unsigned char *pBGRAImageIn = (unsigned char * )malloc(dataSize);
        CGContextRef context = CGBitmapContextCreate(pBGRAImageIn,
                                                     iWidth,
                                                     iHeight,
                                                     iBitsPerComponent,
                                                     iWidth*4,
                                                     colorspace,
                                                     kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast
                                                     );
        
        CGContextSetInterpolationQuality(context, kCGInterpolationNone);

        if (!context) {
            CGColorSpaceRelease(colorspace);
            return;
        }
        
        CGRect rect = CGRectMake(0 , 0 , iWidth , iHeight);
        CGImageRef image;
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, NULL, &image);
        CGContextDrawImage(context, rect, image);
        CGImageRelease(image);
        CGColorSpaceRelease(colorspace);
        CGContextRelease(context);
        
        st_effect_module_info_t *module_info = malloc(sizeof(st_effect_module_info_t));
        [self.effectsProcess getModulesInPackage:self.packageId modules:module_info];
        
        st_image_t st_image = {pBGRAImageIn, ST_PIX_FMT_RGBA8888, iWidth, iHeight, iWidth*4, 0.0};
        module_info->rsv_type = EFFECT_RESERVED_IMAGE;
        module_info->reserved = &st_image;
        
        [self.effectsProcess setModuleInfo:module_info];
        free(pBGRAImageIn);
        free(module_info);
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        if (pixelBuffer) {
            CFRelease(pixelBuffer);
        }
    }
}

- (CVPixelBufferRef)rotatePixelBuffer:(CVPixelBufferRef)pixelBuffer{
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    int rotate = 0;
    switch (self.player.rotateType) {
         case ST_CLOCKWISE_ROTATE_0:
            rotate = kCGImagePropertyOrientationUp;
            break;
        case ST_CLOCKWISE_ROTATE_90:
            rotate = kCGImagePropertyOrientationRight;
           break;
        case ST_CLOCKWISE_ROTATE_180:
            rotate = kCGImagePropertyOrientationDown;
           break;
        case ST_CLOCKWISE_ROTATE_270:
            rotate = kCGImagePropertyOrientationLeft;
           break;

        default:
            break;
    }
    ciImage = [ciImage imageByApplyingOrientation:rotate];
    CVPixelBufferRef videoPixelBuffer = NULL;
    int width = (self.player.rotateType == ST_CLOCKWISE_ROTATE_0)?(int)CVPixelBufferGetWidth(pixelBuffer):(int)CVPixelBufferGetHeight(pixelBuffer);
    int height = (self.player.rotateType == ST_CLOCKWISE_ROTATE_0)?(int)CVPixelBufferGetHeight(pixelBuffer):(int)CVPixelBufferGetWidth(pixelBuffer);
    CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault,
                                               NULL,
                                               NULL,
                                               0,
                                               &kCFTypeDictionaryKeyCallBacks,
                                               &kCFTypeDictionaryValueCallBacks);
    CFMutableDictionaryRef attrs = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                                             1,
                                                             &kCFTypeDictionaryKeyCallBacks,
                                                             &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    
    CVPixelBufferCreate(kCFAllocatorDefault, width, height, CVPixelBufferGetPixelFormatType(pixelBuffer), attrs, &videoPixelBuffer);
    CFRelease(attrs);
    CFRelease(empty);
    [[CIContext context] render:ciImage toCVPixelBuffer:videoPixelBuffer];
    return videoPixelBuffer;
}

#pragma mark -

#pragma mark - properties
-(void)setPackageId:(int)packageId {
    objc_setAssociatedObject(self, @selector(packageId), @(packageId), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(int)packageId {
    return [(NSNumber *)objc_getAssociatedObject(self, @selector(packageId)) intValue];
}

-(void)setPlayer:(TDPlayer *)player {
    objc_setAssociatedObject(self, @selector(player), player, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(TDPlayer *)player {
    return objc_getAssociatedObject(self, @selector(player));
}

#pragma mark -
-(void)releaseMediaBackground {
    [self.player pause];
    self.player = nil;
}

@end
