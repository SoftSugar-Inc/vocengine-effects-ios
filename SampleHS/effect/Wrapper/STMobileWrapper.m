//
//  STMobileWrapper.m
//  SenseMeEffects
//
//  Created by 马浩萌 on 2023/3/22.
//  Copyright © 2023 SoftSugar. All rights reserved.
//

#import "STMobileWrapper.h"
@import OpenGLES;
@import VideoToolbox;
#import "STMobileConfigurations.h"
#import "EffectsAudioPlayerManager.h"
#import "STMobileWrapper+gan.h"
#import "MHMGLHelper.h"
#import "SenseMeEffectsShaderTypes.h"
#import "st_mobile_color_convert.h"

@interface STMobileWrapper ()

@property (nonatomic, strong) EffectsProcess *effectsProcess;
@property (nonatomic, strong) EAGLContext *glContext;

@property(nonatomic, assign) CVOpenGLESTextureCacheRef textureCache;

@property (nonatomic, strong) MTKView *metalView;
@property (nonatomic) id<MTLDevice> metalDevice;
@property (nonatomic) id<MTLCommandQueue> commandQueue;
@property (nonatomic) id<MTLRenderPipelineState> renderPipelineState;
@property (nonatomic) id<MTLTexture> texture;
@property (nonatomic) st_handle_t colorConvertHandle;

@end

@interface STMobileWrapper () <MTKViewDelegate>

-(void)processGanImage:(st_effect_module_info_t *)p_module_info_origin;

@end

@implementation STMobileWrapper
{
    GLuint _outTexture;
    CVPixelBufferRef _outputPixelBuffer;
    CVOpenGLESTextureRef _outputCVTexture;
    
    int _width, _height;
}

-(instancetype)initWithConfig:(NSDictionary *)config context:(nullable EAGLContext *)context error:(NSError **)error {
    NSString *license = config[@"license"];
    NSArray *models = config[@"models"];
    STMobileWrapperConfig configType = [(NSNumber *)config[@"config"] intValue];
    
    if (EffectsProcess.hasAuthorized) {
        
    } else if ([EffectsProcess authorizeWithLicensePath:license]) {
        
    } else {
        return nil;
    }
    _glContext = context;
    self = [super init];
    if (self) {
        self.effectsProcess  = [[EffectsProcess alloc] initWithType:(EffectsType)configType glContext:self.glContext];
        if (configType == STMobileWrapperConfigPreviewItsMe) {
            self.effectsProcess.configMode = EFDetectConfigModeItsMe;
        }
        for (NSString *model in models) {
            [self.effectsProcess addSubModel:model];
        }
        [self addCallbackNotification];
    }
    return self;
}

#if METAL_FLAG
-(instancetype)initMetalWrapperWithConfig:(NSDictionary *)config error:(NSError **)error {
    NSString *license = config[@"license"];
    NSArray *models = config[@"models"];
    STMobileWrapperConfig configType = [(NSNumber *)config[@"config"] intValue];
    
    if (EffectsProcess.hasAuthorized) {
        
    } else if ([EffectsProcess authorizeWithLicensePath:license]) {
        
    } else {
        return nil;
    }
    self = [super init];
    if (self) {
        [self prepareMetalEnv];
        self.effectsProcess  = [[EffectsProcess alloc] initWithType:(EffectsType)configType cmdQueue:self.commandQueue];
        if (configType == STMobileWrapperConfigPreviewItsMe) {
            self.effectsProcess.configMode = EFDetectConfigModeItsMe;
        }
        for (NSString *model in models) {
            [self.effectsProcess addSubModel:model];
        }
        [self addCallbackNotification];
    }
    return self;
}
#endif

-(EffectsGLPreview *)configRenderPreview:(CGRect)frame {
    self.renderPreview = [[EffectsGLPreview alloc] initWithFrame:frame context:self.glContext];
    return self.renderPreview;
}

#pragma mark - human
-(void)addSubModel:(NSString *)path error:(NSError **)error {
    st_result_t ret = [self.effectsProcess addSubModel:path];
    wpThrowError(ret, error);
}

-(void)resetHumanActionError:(NSError **)error {
    st_result_t ret = [self.effectsProcess resetHumanAction];
    wpThrowError(ret, error);
}

#pragma mark -

#pragma mark - effect
-(void)setEffectsParam:(st_effect_param_t)param value:(CGFloat)value error:(NSError **)error {
    st_result_t ret = [self.effectsProcess setEffectParam:param andValue:value];
    wpThrowError(ret, error);
}

#pragma mark -

#pragma mark - 贴纸、风格
-(int)changePackage:(NSString *)packagePath error:(NSError **)error {
    int packageId;
    st_result_t ret = [self.effectsProcess changePackage:packagePath packageId:&packageId];
    wpThrowError(ret, error);
    return packageId;
}

-(int)addPackage:(NSString *)packagePath error:(NSError **)error {
    int packageId;
    st_result_t ret = [self.effectsProcess addPackage:packagePath packageId:&packageId];
    wpThrowError(ret, error);
    return packageId;
}

-(int)replacePackage:(int)oldPackageId packagePath:(NSString *)packagePath error:(NSError **)error {
    int packageId;
    st_result_t ret = [self.effectsProcess replacePackage:oldPackageId packagePath:packagePath packageId:&packageId];
    wpThrowError(ret, error);
    return packageId;
}

-(void)removePackage:(int)packageId error:(NSError **)error {
    st_result_t ret = [self.effectsProcess removeSticker:packageId];
//    NSLog(@"@mahaomeng removeSticker %d", ret);
    wpThrowError(ret, error);
}

-(void)clearPackagesError:(NSError **)error {
    st_result_t ret = [self.effectsProcess cleareStickers];
    wpThrowError(ret, error);
}

-(void)setPackageBeautyGroup:(int)packageId type:(st_effect_beauty_group_t)type strength:(CGFloat)strength error:(NSError **)error {
    st_result_t ret = [self.effectsProcess setPackageId:packageId groupType:type strength:strength];
    wpThrowError(ret, error);
}

-(void)replayPackage:(int)packageId error:(NSError **)error {
    st_result_t ret = [self.effectsProcess replayStickerWithPackage:packageId];
    wpThrowError(ret, error);
}

-(uint64_t)getDetectConfigError:(NSError *__autoreleasing  _Nullable *)error {
    uint64_t config;
    st_result_t ret = [self.effectsProcess getDetectConfig:&config];
    wpThrowError(ret, error);
    return config;
}

-(uint64_t)getTriggerActions:(NSError **)error {
    return [self.effectsProcess getTriggerActions];
}

-(uint64_t)getCustomEventConfig:(NSError *__autoreleasing  _Nullable *)error {
    uint64_t config;
    st_result_t ret = [self.effectsProcess getCustomEventConfig:&config];
    wpThrowError(ret, error);
    return config;
}

#pragma mark -

#pragma mark - 美妆、美颜、滤镜
// 设置美颜素材包路径 - st_mobile_effect_set_beauty
-(void)setBeautyPath:(st_effect_beauty_type_t)type path:(NSString *)path error:(NSError **)error {
    if ([EAGLContext currentContext] != self.glContext) { [EAGLContext setCurrentContext:self.glContext]; }
    st_result_t ret = [self.effectsProcess setEffectType:type path:path];
    wpThrowError(ret, error);
    if (type == EFFECT_BEAUTY_3D_MICRO_PLASTIC) {
        if ([EAGLContext currentContext] != self.glContext) [EAGLContext setCurrentContext:self.glContext];
        [self.effectsProcess getMeshList];
    }
}

// 设置美颜mode - st_mobile_effect_set_beauty_mode
-(void)setBeautyMode:(st_effect_beauty_type_t)type mode:(int)mode error:(NSError **)error {
    st_result_t ret = [self.effectsProcess setEffectType:type mode:mode];
    wpThrowError(ret, error);
}

// 获取美颜mode - st_mobile_effect_get_beauty_mode
-(int)getBeautyMode:(st_effect_beauty_type_t)type error:(NSError **)error {
    int mode = -1;
    st_result_t ret = [self.effectsProcess getEffectType:type mode:&mode];
    wpThrowError(ret, error);
    return mode;
}

// 设置美颜强度 - st_mobile_effect_set_beauty_strength
-(void)setBeautyStrength:(st_effect_beauty_type_t)type strength:(CGFloat)strength error:(NSError **)error {
    st_result_t ret = [self.effectsProcess setEffectType:type value:strength];
    wpThrowError(ret, error);
}

-(void)setBeautyParam:(st_effect_beauty_param_t)type value:(CGFloat)value error:(NSError **)error {
    st_result_t ret = [self.effectsProcess setBeautyParam:type andVal:value];
    wpThrowError(ret, error);
}

-(NSArray<NSDictionary *> *)getOverlappedBeautyInfo {
    int count = 0;
    st_effect_beauty_info_t * beauty_info = [self.effectsProcess getOverlapInfo:&count];
    if (!beauty_info) return nil;
    NSMutableArray * result = [NSMutableArray array];
    for (NSInteger i = 0; i < count; i ++) {
        st_effect_beauty_info_t item = beauty_info[i];
        NSDictionary * info = @{
            @"name": [NSString stringWithFormat:@"%s", item.name],
            @"type": @(item.type),
            @"strength": @(item.strength),
            @"mode": @(item.mode)
        };
        [result addObject:info];
    }
    free(beauty_info);
    return result;
}

-(void)setDelay:(float)delay {
    [self.effectsProcess setHumanActionParam:ST_HUMAN_ACTION_PARAM_DELAY_FRAME andValue:delay];
    [self.effectsProcess setEffectParam:EFFECT_PARAM_RENDER_DELAY_FRAME andValue:delay];
}

#pragma mark -

#pragma mark - 3D微整形
// 获取当前3D微整形信息 st_moobile_effect_get_3d_beauty_parts_count+st_mobile_effect_get_3d_beauty_parts
-(NSArray<STMobileEffect3DBeautyPartInfo *> *)get3dBeautyPartsError:(NSError **)error {
    int partsSize;
    st_result_t ret = [self.effectsProcess get3dBeautyPartsSize:&partsSize];
    wpThrowError(ret, error);
    if (ret != ST_OK) return nil;
    st_effect_3D_beauty_part_info_t parts[partsSize];
    ret = [self.effectsProcess get3dBeautyParts:parts fromSize:partsSize];
    wpThrowError(ret, error);
    if (ret != ST_OK) return nil;
    NSMutableArray<STMobileEffect3DBeautyPartInfo *> *result = [NSMutableArray array];
    for (int i = 0; i < partsSize; i ++) {
        st_effect_3D_beauty_part_info_t part = parts[i];
        STMobileEffect3DBeautyPartInfo *partModel = [[STMobileEffect3DBeautyPartInfo alloc] init];
        partModel.name = [NSString stringWithUTF8String:part.name];
        partModel.partId = part.part_id;
        partModel.strength = part.strength;
        partModel.minStrength = part.strength_min;
        partModel.maxStrength = part.strength_max;
        partModel.index = i;
        [result addObject:partModel];
    }
    return result.copy;
}

// 设置3D微整形强度 - st_mobile_effect_set_3d_beauty_parts_strength
-(void)set3dBeautyPartsStrength:(NSArray<STMobileEffect3DBeautyPartInfo *> *)parts error:(NSError **)error {
    
}

-(void)set3dBeautyPartStrength:(STMobileEffect3DBeautyPartInfo *)part error:(NSError **)error {
    int partsSize = 0;
    st_result_t ret = [self.effectsProcess get3dBeautyPartsSize:&partsSize];
    wpThrowError(ret, error);
    if (ret != ST_OK || partsSize <= 0) return;
    st_effect_3D_beauty_part_info_t parts[partsSize];
    ret = [self.effectsProcess get3dBeautyParts:parts fromSize:partsSize];
    wpThrowError(ret, error);
    
    parts[part.index].strength = part.strength;
    
    ret = [self.effectsProcess set3dBeautyPartsStrength:parts andVal:partsSize];
    wpThrowError(ret, error);
}
#pragma mark -

#pragma mark - try on
// 获取试妆信息 - st_mobile_effect_get_tryon_param
-(STMobileEffectTryonInfo *)getTryonParam:(st_effect_beauty_type_t)type error:(NSError **)error {
    st_effect_tryon_info_t *tryonInfo = malloc(sizeof(st_effect_tryon_info_t));
    if (tryonInfo) {
        memset(tryonInfo, 0, sizeof(st_effect_tryon_info_t));
    }
    st_result_t ret = [self.effectsProcess getTryon:tryonInfo andTryonType:type];
    wpThrowError(ret, error);
    
    if (ret == ST_OK) {
        STMobileColor *color = [[STMobileColor alloc] init];
        color.r = tryonInfo->color.r;
        color.g = tryonInfo->color.g;
        color.b = tryonInfo->color.b;
        color.a = tryonInfo->color.a;
        
        NSMutableArray<STMobileEffectTryonRegionInfo *> *reginsInfo = [NSMutableArray array];
        for (int i = 0; i < tryonInfo->region_count; i ++) {
            st_effect_tryon_region_info_t regionInfo = tryonInfo->region_info[i];
            STMobileEffectTryonRegionInfo *regionInfoModel = [[STMobileEffectTryonRegionInfo alloc] init];
            STMobileColor *regionColor = [[STMobileColor alloc] init];
            regionColor.r = regionInfo.color.r;
            regionColor.g = regionInfo.color.g;
            regionColor.b = regionInfo.color.b;
            regionColor.a = regionInfo.color.a;
            regionInfoModel.color = regionColor;
            regionInfoModel.regionId = regionInfo.region_id;
            regionInfoModel.strength = regionInfo.strength;
            [reginsInfo addObject:regionInfoModel];
        }
        
        STMobileEffectTryonInfo *tryonModel = [[STMobileEffectTryonInfo alloc] init];
        tryonModel.color = color;
        tryonModel.strength = tryonInfo->strength;
        tryonModel.lineWidthRatio = tryonInfo->line_width_ratio;
        tryonModel.midtone = tryonInfo->midtone;
        tryonModel.highlight = tryonInfo->highlight;
        tryonModel.lipFinishType = tryonInfo->lip_finish_type;
        tryonModel.regionInfo = reginsInfo.copy;
        
        free(tryonInfo);
        return tryonModel;
    } else {
        return nil;
    }
}

// 设置试妆信息 - st_mobile_effect_set_tryon_param
-(void)setTryon:(st_effect_beauty_type_t)type param:(STMobileEffectTryonInfo *)param error:(NSError **)error {
    int regionCount = (int)param.regionInfo.count;
    st_effect_tryon_region_info_t reginsInfo[regionCount];
    for (int i = 0; i < regionCount; i ++) {
        STMobileEffectTryonRegionInfo *regionInfoModel = param.regionInfo[i];
        STMobileColor *regionColor = regionInfoModel.color;
        st_color_t color = { regionColor.r, regionColor.g, regionColor.b, regionColor.a };
        reginsInfo[i].color = color;
        reginsInfo[i].strength = regionInfoModel.strength;
        reginsInfo[i].region_id = (int)regionInfoModel.regionId;
    }
    
    STMobileColor *tryonColor = param.color;
    st_color_t color = { tryonColor.r, tryonColor.g, tryonColor.b, tryonColor.a };
    st_effect_tryon_info_t tryonInfo = { color, param.strength, param.lineWidthRatio, param.midtone, param.highlight, param.lipFinishType, regionCount, *reginsInfo };
    st_result_t ret = [self.effectsProcess setTryon:&tryonInfo andTryonType:type];
    wpThrowError(ret, error);
}
#pragma mark -

-(CVPixelBufferRef)processGetBufferByPixelBuffer:(CVPixelBufferRef)pixelBuffer rotate:(st_rotate_type)rotate captureDevicePosition:(AVCaptureDevicePosition)position  renderOrigin:(BOOL)renderOrigin error:(NSError **)error {
    [self _processPixelBuffer:pixelBuffer rotate:rotate captureDevicePosition:position inputTexture:NULL renderOrigin:renderOrigin error:error];
    return _outputPixelBuffer;
}

-(CVPixelBufferRef)processGetBufferByPixelBuffer:(CVPixelBufferRef)pixelBuffer rotate:(st_rotate_type)rotate captureDevicePosition:(AVCaptureDevicePosition)position originPixelBuffer:(CVPixelBufferRef *)originPixelBuffer error:(NSError **)error {
    [self _processPixelBuffer:pixelBuffer rotate:rotate captureDevicePosition:position inputPixelBuffer:originPixelBuffer error:error];
    return _outputPixelBuffer;
}

-(GLuint)processGetTextureByPixelBuffer:(CVPixelBufferRef)pixelBuffer rotate:(st_rotate_type)rotate captureDevicePosition:(AVCaptureDevicePosition)position inputTexture:(GLuint *)inputTexture error:(NSError **)error {
    [self _processPixelBuffer:pixelBuffer rotate:rotate captureDevicePosition:position inputTexture:inputTexture renderOrigin:false error:error];
    return _outTexture;
}

-(void)processByPixelBuffer:(CVPixelBufferRef)pixelBuffer rotate:(st_rotate_type)rotate captureDevicePosition:(AVCaptureDevicePosition)position outputPixelBuffer:(CVPixelBufferRef *)outputPixelBuffer error:(NSError **)error {
    [self.effectsProcess setCurrentEAGLContext:self.glContext];
    GLuint outputTexture = 0;
    CVOpenGLESTextureRef ouputCVTexture = NULL;
    BOOL bSuccess = [self.effectsProcess getTextureWithPixelBuffer:*outputPixelBuffer
                                                           texture:&outputTexture
                                                         cvTexture:&ouputCVTexture
                                                         withCache:self.textureCache];
    if (ouputCVTexture) {
        CFRelease(ouputCVTexture);
        ouputCVTexture = NULL;
    }
    if (!bSuccess) {
        NSLog(@"get origin textrue error");
        return;
    }
    
    st_mobile_human_action_t detectResult;
    memset(&detectResult, 0, sizeof(st_mobile_human_action_t));
    st_mobile_animal_result_t animalResult;
    memset(&animalResult, 0, sizeof(st_mobile_animal_result_t));
    
    st_result_t result = [self.effectsProcess detectWithPixelBuffer:pixelBuffer rotate:rotate cameraPosition:position humanAction:&detectResult animalResult:&animalResult];
    wpThrowError(result, error);
    result = [self.effectsProcess processPixelBuffer:pixelBuffer rotate:rotate cameraPosition:position outTexture:outputTexture outPixelFormat:ST_PIX_FMT_BGRA8888 outData:nil];
    wpThrowError(result, error);
}

-(void)_processPixelBuffer:(CVPixelBufferRef)pixelBuffer rotate:(st_rotate_type)rotate captureDevicePosition:(AVCaptureDevicePosition)position inputTexture:(GLuint *)inputTexture renderOrigin:(BOOL)renderOrigin error:(NSError **)error {
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
#if METAL_FLAG
    if(!self.texture || _width != width || _height != height) {
        _width = width; _height = height;
//        self.texture = [self createMetalTextureWithDevice:self.metalDevice width:width height:height];
        id<MTLTexture> tempTexture = nil;
        [self createSharedCVPixelBufferWithDevice:self.metalDevice width:width height:height pixelBufferRef:&_outputPixelBuffer metalTexture:&tempTexture];
        self.texture = tempTexture;
    }
    [self.effectsProcess processPixelBuffer:pixelBuffer rotate:rotate withDevice:self.metalDevice andCmdBuffer:self.commandQueue.commandBuffer isRenderOrigin:renderOrigin outputMetalTexture:self.texture];
    [self.metalView draw];
#else
    glCheckError();
    if(!_outTexture || _width != width || _height != height){
        _width = width; _height = height;
        if(_outTexture) {
            CVPixelBufferRelease(_outputPixelBuffer);
            _outputPixelBuffer = NULL;
            if (_outputCVTexture) CFRelease(_outputCVTexture);
            _outputCVTexture = 0;
        }
        [self.effectsProcess createGLObjectWith:width
                                         height:height
                                        texture:&_outTexture
                                    pixelBuffer:&_outputPixelBuffer
                                      cvTexture:&_outputCVTexture];
    }
    glCheckError();
    st_result_t result = [self.effectsProcess processPixelBuffer:pixelBuffer rotate:rotate cameraPosition:position outTexture:_outTexture outPixelFormat:ST_PIX_FMT_BGRA8888 outData:nil inputTexture:inputTexture];
    wpThrowError(result, error);
    glCheckError();
    [self.renderPreview renderTexture:renderOrigin? self.effectsProcess.inputTexture : _outTexture rotate:rotate];
    glCheckError();
#endif
}

-(void)_processPixelBuffer:(CVPixelBufferRef)pixelBuffer rotate:(st_rotate_type)rotate captureDevicePosition:(AVCaptureDevicePosition)position inputPixelBuffer:(CVPixelBufferRef *)inputPixelBuffer error:(NSError **)error {
    NSLog(@"@mahaomeng STMobileWrapper line %d",  __LINE__);
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int heigh = (int)CVPixelBufferGetHeight(pixelBuffer);
    if(!_outTexture || _width != width || _height != heigh){
        _width = width; _height = heigh;
        if(_outTexture) {
            CVPixelBufferRelease(_outputPixelBuffer);
            _outputPixelBuffer = NULL;
            if (_outputCVTexture) CFRelease(_outputCVTexture);
            _outputCVTexture = 0;
        }
        [self.effectsProcess createGLObjectWith:width
                                         height:heigh
                                        texture:&_outTexture
                                    pixelBuffer:&_outputPixelBuffer
                                      cvTexture:&_outputCVTexture];
        [self.effectsProcess.pointsPainter createMetalTextureWithWidth:width height:heigh andPixelBuffer:_outputPixelBuffer];
    }
    
    NSLog(@"@mahaomeng STMobileWrapper line %d",  __LINE__);
    st_result_t result = [self.effectsProcess processPixelBuffer:pixelBuffer rotate:rotate cameraPosition:position outTexture:_outTexture outPixelFormat:ST_PIX_FMT_BGRA8888 outData:nil inputPixelBuffer:inputPixelBuffer];
    wpThrowError(result, error);
}

-(GLuint)processGetTextureByTexture:(GLint)texture width:(uint32_t)width height:(uint32_t)height rotate:(st_rotate_type)rotate captureDevicePosition:(AVCaptureDevicePosition)position error:(NSError **)error {
    int size = width * height * 3 / 2;
    unsigned char *nv12Buffer = (unsigned char *)malloc(size);
    st_result_t result = st_mobile_rgba_tex_to_nv12_buffer(self.colorConvertHandle, texture, width, height, nv12Buffer);
    wpThrowError(result, error);
    if (result != ST_OK) {
        NSLog(@"st_mobile_rgba_tex_to_nv12_buffer failed %d", result);
    }
    
    if(!_outTexture || _width != width || _height != height){
        _width = width; _height = height;
        if(_outTexture) {
            CVPixelBufferRelease(_outputPixelBuffer);
            _outputPixelBuffer = NULL;
            if (_outputCVTexture) CFRelease(_outputCVTexture);
            _outputCVTexture = 0;
        }
        [self.effectsProcess createGLObjectWith:width
                                         height:height
                                        texture:&_outTexture
                                    pixelBuffer:&_outputPixelBuffer
                                      cvTexture:&_outputCVTexture];
        [self.effectsProcess.pointsPainter createMetalTextureWithWidth:width height:height andPixelBuffer:_outputPixelBuffer];
    }
    
    result = [self.effectsProcess processData:nv12Buffer size:size width:width height:height stride:width rotate:rotate pixelFormat:ST_PIX_FMT_NV12 inputTexture:texture outTexture:_outTexture outPixelFormat:ST_PIX_FMT_BGRA8888 outData:nil];
    wpThrowError(result, error);
    free(nv12Buffer);
    if (result != ST_OK) {
        NSLog(@"processData failed %d", result);
    }
    
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    return _outTexture;
}

- (void)processPixelBuffer:(CVPixelBufferRef)pixelBuffer rotate:(st_rotate_type)rotate cameraPosition:(AVCaptureDevicePosition)position outPixelFormat:(st_pixel_format)fmt_out outData:(unsigned char *)img_out error:(NSError **)error {
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    glCheckError();
    if(!_outTexture || _width != width || _height != height){
        _width = width; _height = height;
        if(_outTexture) {
            CVPixelBufferRelease(_outputPixelBuffer);
            _outputPixelBuffer = NULL;
            if (_outputCVTexture) CFRelease(_outputCVTexture);
            _outputCVTexture = 0;
        }
        [self.effectsProcess createGLObjectWith:width
                                         height:height
                                        texture:&_outTexture
                                    pixelBuffer:&_outputPixelBuffer
                                      cvTexture:&_outputCVTexture];
    }
    glCheckError();
    st_result_t result = [self.effectsProcess processPixelBuffer:pixelBuffer rotate:rotate cameraPosition:position outTexture:_outTexture outPixelFormat:fmt_out outData:img_out inputTexture:NULL];
    wpThrowError(result, error);
    glCheckError();
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [EAGLContext setCurrentContext:self.glContext];
    if (_outTexture) glDeleteTextures(1, &_outTexture);
    if (_outputPixelBuffer) CVPixelBufferRelease(_outputPixelBuffer);
    if (_outputCVTexture) CFRelease(_outputCVTexture);
    if (_textureCache) {
        CVOpenGLESTextureCacheFlush(_textureCache, 0);
        CFRelease(_textureCache);
        _textureCache = NULL;
    }
    if (self.texture) {
        self.texture = nil;
    }
    
    if ([self respondsToSelector:@selector(releaseMediaBackground)]) {
        [self releaseMediaBackground];
    }
    
    if (_colorConvertHandle) {
        st_mobile_color_convert_destroy(_colorConvertHandle);
        _colorConvertHandle = NULL;
    }
}

#pragma mark - properties
-(EAGLContext *)glContext {
    if (!_glContext) {
        _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    }
    return _glContext;
}

-(CVOpenGLESTextureCacheRef)textureCache {
    if (!_textureCache) {
        CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.glContext, NULL, &_textureCache);
    }
    return _textureCache;
}

-(BOOL)authrized {
    return EffectsProcess.hasAuthorized;
}

#pragma mark -

#pragma mark - api callback
-(void)addCallbackNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onApiCallback:) name:@"st_wrapper_onApiCallback" object:nil];
}

-(void)onApiCallback:(NSNotification *)notification {
    STMobileEffectModuleInfoWrapper *wrapper = (STMobileEffectModuleInfoWrapper *)(notification.object);
    st_effect_module_type_t type = wrapper.moduleInfo->type;
    if (type == EFFECT_MODULE_GAN_IMAGE) { // GAN
        if (wrapper.moduleInfo->state == EFFECT_MODULE_LOADED) {
            [self processGanImage:wrapper.moduleInfo];
        }
    } else if (type == EFFECT_MODULE_SEGMENT) { // 绿幕分割
        if (wrapper.moduleInfo->rsv_type == EFFECT_RESERVED_SEGMENT_BASECOLOR) {
            uint32_t *reserved = wrapper.moduleInfo->reserved;
            [self.effectsProcess setHumanActionParam:ST_HUMAN_ACTION_PARAM_GREEN_SEGMENT_COLOR andValue:*reserved];
        }
    }
    else {
        _audio_modul_state_change_callback(NULL, wrapper.moduleInfo);
    }
}
#pragma mark -

#pragma mark - metal
-(void)prepareMetalEnv {
    self.commandQueue = [self.metalDevice newCommandQueue];
    
    // shader
    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    id<MTLLibrary> library = [self.metalDevice newDefaultLibrary];
    id<MTLFunction> vertexFunction = [library newFunctionWithName:@"vertexShader"];
    id<MTLFunction> textureFunction = [library newFunctionWithName:@"samplingShader"];
    renderPipelineDescriptor.vertexFunction = vertexFunction;
    renderPipelineDescriptor.fragmentFunction = textureFunction;
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = self.metalView.colorPixelFormat;
    self.renderPipelineState = [self.metalDevice newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:nil];
}

#pragma mark - properties
-(MTKView *)metalView {
    if (!_metalView) {
        _metalView = [[MTKView alloc] initWithFrame:CGRectZero];
        [_metalView setContentMode:UIViewContentModeScaleAspectFit];
        _metalView.device = self.metalDevice;
        _metalView.delegate = self;
        _metalView.clearColor = MTLClearColorMake(0, 1, 1, 1);
        _metalView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
        _metalView.framebufferOnly = NO;
        _metalView.enableSetNeedsDisplay = YES;
        _metalView.paused = YES;  // 暂停自动刷新
        _metalView.preferredFramesPerSecond = 0;
        _metalView.autoResizeDrawable = NO;
    }
    return _metalView;
}

-(id<MTLDevice>)metalDevice {
    if (!_metalDevice) {
        _metalDevice = MTLCreateSystemDefaultDevice();
    }
    return _metalDevice;
}

-(GLuint)createGLTextureWidth:(GLsizei)width height:(GLsizei)height pixels:(const GLvoid*)pixels {
    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
    glBindTexture(GL_TEXTURE_2D, 0);
    return texture;
}

- (void)drawInMTKView:(MTKView *)view {
    // creating command encoder
    if (_texture && view.currentDrawable) {
        NSInteger width = _texture.width;
        NSInteger height = _texture.height;
        view.drawableSize = CGSizeMake(width, height);
        
        SenseMeVertex verties[] = {
            { {-width/2, height/2}, {}, {0.f, 0.f} },
            { {width/2, height/2}, {}, {1.f, 0.f} },
            { {width/2, -height/2}, {}, {1.f, 1.f} },
            
            { {width/2, -height/2}, {}, {1.f, 1.f} },
            { {-width/2, -height/2}, {}, {0.f, 1.f} },
            { {-width/2, height/2}, {}, {0.f, 0.f} }
        };
        
        id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
        
        id<MTLRenderCommandEncoder> renderCommandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:view.currentRenderPassDescriptor];
        
        if (renderCommandEncoder) {
            vector_uint2 viewPortSize = {view.drawableSize.width, view.drawableSize.height};
            [renderCommandEncoder setVertexBytes:&verties length:sizeof(verties) atIndex:SenseMeVertexInputIndexVertices];
            [renderCommandEncoder setVertexBytes:&viewPortSize length:sizeof(viewPortSize) atIndex:SenseMeVertexInputIndexViewportSize];
            [renderCommandEncoder setFragmentTexture:self.texture atIndex:SenseMeTextureInputIndexBaseColor];
            [renderCommandEncoder setRenderPipelineState:self.renderPipelineState];
            [renderCommandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:sizeof(verties)/sizeof(SenseMeVertex)];
            
            [renderCommandEncoder endEncoding];
        }
        
        // committing the drawing
        [commandBuffer presentDrawable:view.currentDrawable];
        [commandBuffer commit];
    }
}

-(void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

//-(id<MTLTexture>)createMetalTextureWithDevice:(id<MTLDevice>)metalDevice width:(NSUInteger)width height:(NSUInteger)height {
//    MTLTextureDescriptor *texDes = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:width height:height mipmapped:NO];
//    texDes.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
//    id<MTLTexture> texture = [metalDevice newTextureWithDescriptor:texDes];
//    return texture;
//}

- (void)createSharedCVPixelBufferWithDevice:(id<MTLDevice>)metalDevice
                                      width:(size_t)width
                                     height:(size_t)height
                             pixelBufferRef:(CVPixelBufferRef *)pixelBufferRef
                                metalTexture:(id<MTLTexture> *)metalTexture
{
    NSDictionary *pixelBufferAttributes = @{
        (id)kCVPixelBufferMetalCompatibilityKey : @YES,  // 确保 PixelBuffer 与 Metal 兼容
        (id)kCVPixelBufferWidthKey : @(width),
        (id)kCVPixelBufferHeightKey : @(height),
        (id)kCVPixelBufferBytesPerRowAlignmentKey : @(width * 4),  // 4 字节对齐（对应 RGBA 或 BGRA）
        (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) // BGRA 格式
    };
    
    // 创建 CVPixelBuffer，确保其与 Metal 兼容
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          width,
                                          height,
                                          kCVPixelFormatType_32BGRA,
                                          (__bridge CFDictionaryRef)pixelBufferAttributes,
                                          pixelBufferRef);
    
    if (status != kCVReturnSuccess) {
        NSLog(@"Error: Failed to create CVPixelBuffer. Status: %d", status);
        return;
    }
    
    // 创建 CVMetalTextureCache
    CVMetalTextureCacheRef textureCache = NULL;
    CVReturn cacheStatus = CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, metalDevice, NULL, &textureCache);
    if (cacheStatus != kCVReturnSuccess) {
        NSLog(@"Error: Failed to create CVMetalTextureCache. Status: %d", cacheStatus);
        CVPixelBufferRelease(*pixelBufferRef);
        return;
    }
    
    // 从 PixelBuffer 创建 Metal 纹理
    CVMetalTextureRef metalTextureRef = NULL;
    cacheStatus = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                            textureCache,
                                                            *pixelBufferRef,
                                                            NULL,
                                                            MTLPixelFormatBGRA8Unorm,  // Metal 纹理格式
                                                            width,
                                                            height,
                                                            0,   // 纹理级别（mipmap）
                                                            &metalTextureRef);
    
    if (cacheStatus != kCVReturnSuccess) {
        NSLog(@"Error: Failed to create Metal texture from CVPixelBuffer. Status: %d", cacheStatus);
        CFRelease(textureCache);
        CVPixelBufferRelease(*pixelBufferRef);
        return;
    }
    
    // 获取与 CVPixelBuffer 共享内存的 Metal 纹理
    *metalTexture = CVMetalTextureGetTexture(metalTextureRef);
    
    // 释放 MetalTextureRef 和 TextureCache
    CFRelease(metalTextureRef);
    CFRelease(textureCache);
}

-(st_handle_t)colorConvertHandle {
    if (!_colorConvertHandle) {
        st_result_t ret = st_mobile_color_convert_create(&_colorConvertHandle);
        if (ret != ST_OK) {
            NSLog(@"st_mobile_color_convert_create %d", ret);
        }
    }
    return _colorConvertHandle;
}

@end
