//
//  STMobileWrapper.h
//  SenseMeEffects
//
//  Created by 马浩萌 on 2023/3/22.
//  Copyright © 2023 SoftSugar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EffectsProcess.h" // 临时

@import AVFoundation;
@import MetalKit;

#import "STMobileWrapperObject.h"
#import "EffectsGLPreview.h"

NS_ASSUME_NONNULL_BEGIN

@interface STMobileWrapper : NSObject

@property (nonatomic, strong, readonly) EffectsProcess *effectsProcess; // 临时
@property (nonatomic, assign, readonly) BOOL authrized;
@property (nonatomic, strong) EffectsGLPreview *renderPreview;
@property (nonatomic, strong, readonly) MTKView *metalView;

/// 创建wrapper
/// - Parameters:
///   - config:字典，各字段如下
///   @{
///     @"license": licensePath, // license路径
///     @"config": @(STMobileWrapperConfigPreview), // STMobileWrapperConfigPreview预览、STMobileWrapperConfigImage图片、STMobileWrapperConfigVideo视频
///     @"models": @[modelPathOf106] // 模型路径
///    }
///   - context: 外部glcontext，若传nil则内部创建维护glcontext
///   - error: 错误信息
-(instancetype)initWithConfig:(NSDictionary *)config context:(nullable EAGLContext *)context error:(NSError **)error NS_DESIGNATED_INITIALIZER;
#if METAL_FLAG
-(instancetype)initMetalWrapperWithConfig:(NSDictionary *)config error:(NSError **)error NS_DESIGNATED_INITIALIZER;
#endif

/// 若使用wrapper渲染上屏，需要配置预览view的frame，并将其添加到父视图中
/// - Parameter frame: frame
-(EffectsGLPreview *)configRenderPreview:(CGRect)frame;

#pragma mark - human
/// 添加检测模型
/// - Parameters:
///   - path: 模型路径
///   - error: 错误信息
-(void)addSubModel:(NSString *)path error:(NSError **)error;
/// 重置检测
/// - Parameter error: 错误信息
-(void)resetHumanActionError:(NSError **)error;

#pragma mark - effect
/// 设置特效参数
/// - Parameters:
///   - param: 参数类型
///   - value: 参数数值，具体范围参考参数类型说明
///   - error: 错误信息
-(void)setEffectsParam:(st_effect_param_t)param value:(CGFloat)value error:(NSError **)error;

#pragma mark - 贴纸、风格
/// 添加素材包
/// - Parameters:
///   - packagePath: 待添加的素材包文件路径
///   - error: 错误信息
///   - return: 素材包ID
-(int)addPackage:(NSString *)packagePath error:(NSError **)error;

/// 更换缓存中的素材包 (删除已有的素材包)
/// - Parameters:
///   - packagePath: 待更换的素材包文件路径
///   - error: 错误信息
///   - return: 素材包ID
-(int)changePackage:(NSString *)packagePath error:(NSError **)error;

/// 替换缓存中的素材包 (删除package id的素材包)
/// - Parameters:
///   - oldPackageId: 将被替换的素材包package id
///   - packagePath: 待更换的素材包文件路径
///   - error: 错误信息
///   - return: 素材包ID
-(int)replacePackage:(int)oldPackageId packagePath:(NSString *)packagePath error:(NSError **)error;

/// 删除指定素材包
/// - Parameters:
///   - packageId: 待删除的素材包ID
///   - error: 错误信息
-(void)removePackage:(int)packageId error:(NSError **)error;

/// 清空所有素材包
///   - error: 错误信息
-(void)clearPackagesError:(NSError **)error;

/// 设置贴纸素材包内部美颜组合的强度，强度范围[0.0, 1.0]
/// - Parameters:
///   - packageId: 素材包ID
///   - type: 美颜组合类型
///   - strength: 强度值
///   - error: 错误信息
-(void)setPackageBeautyGroup:(int)packageId type:(st_effect_beauty_group_t)type strength:(CGFloat)strength error:(NSError **)error;

/// 重新播放制定素材包中的素材
/// - Parameters:
///   - packageId: 素材包ID
///   - error: 错误信息
-(void)replayPackage:(int)packageId error:(NSError **)error;

#pragma mark - config
/// 获取需要的检测配置选项
/// - Parameter error:  错误信息
/// - return: 返回检测配置选项, 每一位分别代表该位对应检测选项, 对应状态详见st_mobile_human_action.h中, 如ST_MOBILE_FACE_DETECT等
-(uint64_t)getDetectConfigError:(NSError **)error;

/// 获取需要的自定义事件选项
/// - Parameter error:  错误信息
/// - return: 返回自定义事件选项
-(uint64_t)getCustomEventConfig:(NSError **)error;

/// 获取特定检测config对应的触发Action，目前主要是手势检测存在不同Action
/// - Parameter error:  错误信息
/// - return: 返回当前贴纸需要的触发动作, 每一位分别代表该位对应动作选项, 对应状态详见st_mobile_human_action.h中, 如ST_HAND_ACTION_TYPE_OK等
-(uint64_t)getTriggerActions:(NSError **)error;

#pragma mark - 美妆、美颜、滤镜
/// 加载美颜素材，可以通过将path参数置为nullptr，清空之前类型设置的对应素材（如美颜、美妆、滤镜素材）
/// - Parameters:
///   - type: 美颜类型
///   - path: 待添加的素材文件路径
///   - error: 错误信息
-(void)setBeautyPath:(st_effect_beauty_type_t)type path:(nullable NSString *)path error:(NSError **)error;

/// 设置美颜的模式, 目前仅对磨皮、美白、背景虚化有效，具体支持的模式参考前面枚举值定义
/// - Parameters:
///   - type: 美颜类型, 目前支持磨皮、美白、背景虚化
///   - mode: 模式，目前可选择 st_effect_smooth_mode, st_effect_whiten_mode, st_effect_bokeh_mode
///   - error: 错误信息
-(void)setBeautyMode:(st_effect_beauty_type_t)type mode:(int)mode error:(NSError **)error;

/// 获取美颜的模式, 目前仅对磨皮和美白有效
/// - Parameters:
///   - type: 美颜类型
///   - error: 错误信息
///   - return: 模式
-(int)getBeautyMode:(st_effect_beauty_type_t)type error:(NSError **)error;

/// 设置美颜的强度
/// - Parameters:
///   - type: 美颜类型
///   - strength: 强度
///   - error: 错误信息
-(void)setBeautyStrength:(st_effect_beauty_type_t)type strength:(CGFloat)strength error:(NSError **)error;

/// 设置美颜相关配置项
/// - Parameters:
///   - type: 配置项类型
///   - value: 配置项参数值，具体范围参考配置项说明
///   - error: 错误信息
-(void)setBeautyParam:(st_effect_beauty_param_t)type value:(CGFloat)value error:(NSError **)error;

/// 获取覆盖生效的美颜的信息, 需要在st_mobile_effect_render接口后调用，因为overlap信息是在render之后更新的
///   - return: 覆盖生效的美颜的信息
-(NSArray<NSDictionary *> *)getOverlappedBeautyInfo;

/// 设置延迟帧
/// - Parameter delay: 延迟帧数
-(void)setDelay:(float)delay;

#pragma mark - 3D微整形
/// 在调用st_mobile_effect_set_beauty函数加载了3D微整形素材包之后调用。获取到素材包中所有的blendshape名称、index和当前强度[0, 1]
/// - Parameter error: 错误信息
///   - return: 3D微整形信息
-(NSArray<STMobileEffect3DBeautyPartInfo *> *)get3dBeautyPartsError:(NSError **)error;

/// 在调用st_mobile_effect_set_beauty函数加载了3D微整形素材包之后调用。在获取blendshape数组之后，可以依据起信息修改权重[0, 1]，设置给渲染引擎产生效果。
/// - Parameters:
///   - part: 需要设置强度的 3D微整形信息
///   - error: 错误信息
-(void)set3dBeautyPartStrength:(STMobileEffect3DBeautyPartInfo *)part error:(NSError **)error;

#pragma mark - try on
/// 获取试妆相关参数
/// - Parameters:
///   - type: 试妆类型
///   - error: 错误信息
///   - return: 需要返回的试妆信息
-(STMobileEffectTryonInfo *)getTryonParam:(st_effect_beauty_type_t)type error:(NSError **)error;

/// 设置试妆相关参数
/// - Parameters:
///   - type: 试妆类型
///   - param: 需要设置的试妆信息
///   - error: 错误信息
-(void)setTryon:(st_effect_beauty_type_t)type param:(STMobileEffectTryonInfo *)param error:(NSError **)error;

#pragma mark - process
-(void)processByPixelBuffer:(CVPixelBufferRef)pixelBuffer rotate:(st_rotate_type)rotate captureDevicePosition:(AVCaptureDevicePosition)position outputPixelBuffer:(CVPixelBufferRef *)outputPixelBuffer error:(NSError **)error;

/// processGetBufferByPixelBuffer
/// - Parameters:
///   - pixelBuffer: 输入的原始图像pixel buffer
///   - rotate: 输入图像的旋转角度
///   - position: 前后摄像头
///   - renderOrigin: renderPreview上渲染原始图像/sdk process后的图像（对比功能）
///   - error: error info
-(CVPixelBufferRef)processGetBufferByPixelBuffer:(CVPixelBufferRef)pixelBuffer rotate:(st_rotate_type)rotate captureDevicePosition:(AVCaptureDevicePosition)position renderOrigin:(BOOL)renderOrigin error:(NSError **)error;

-(CVPixelBufferRef)processGetBufferByPixelBuffer:(CVPixelBufferRef)pixelBuffer rotate:(st_rotate_type)rotate captureDevicePosition:(AVCaptureDevicePosition)position originPixelBuffer:(CVPixelBufferRef *)originPixelBuffer error:(NSError **)error;

-(GLuint)processGetTextureByPixelBuffer:(CVPixelBufferRef)pixelBuffer rotate:(st_rotate_type)rotate captureDevicePosition:(AVCaptureDevicePosition)position inputTexture:(GLuint *)inputTexture error:(NSError **)error;

/// 图像检测、特效渲染
/// @param pixelBuffer 视频数据
/// @param rotate 当前buffer旋转方向
/// @param position 当前手机摄像头前后
/// @param outTexture 目标纹理, 仅支持RGBA纹理
/// @param fmt_out 输出图片的类型,支持NV21,BGR,BGRA,NV12,RGBA,YUV420P格式
/// @param img_out 输出图像数据数组,需要用户分配内存,如果是null, 不输出buffer
- (void)processPixelBuffer:(CVPixelBufferRef)pixelBuffer rotate:(st_rotate_type)rotate cameraPosition:(AVCaptureDevicePosition)position outPixelFormat:(st_pixel_format)fmt_out outData:(unsigned char *)img_out error:(NSError **)error;

/// 图像检测、特效渲染
/// @param texture 输入纹理
/// @param width 纹理宽度
/// @param height 纹理高度
/// @param rotate 纹理旋转方向
/// @param position 当前手机摄像头前后
/// @param error 错误信息
-(GLuint)processGetTextureByTexture:(GLint)texture width:(uint32_t)width height:(uint32_t)height rotate:(st_rotate_type)rotate captureDevicePosition:(AVCaptureDevicePosition)position error:(NSError **)error;

-(instancetype)init NS_UNAVAILABLE;

-(void)releaseMediaBackground;

@end

NS_ASSUME_NONNULL_END
