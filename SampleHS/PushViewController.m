//
//  PushViewController.m
//  SampleHS
//
//  Created by 郭振全 on 2025/5/19.
//

#import "PushViewController.h"
#import <TTSDKFramework/VeLivePusher.h>
#import "STMobileWrapper.h"
#import "PushConfig.h"

#define USING_TEXTURE 0

#define AIPushURL @"rtmp://www.softsugar.com/live/push?volcTime=1751266781&volcSecret=9dc255cbee79e56422af879d433b06cf"

@interface PushViewController () <VeLiveVideoFrameFilter, VeLivePusherObserver>
@property (nonatomic, strong) VeLivePusher *livePusher;

@property (nonatomic, strong) STMobileWrapper *stWrapper;
/// 美颜开关是否打开
@property (nonatomic, assign) BOOL beautyIsOn;
@end

@implementation PushViewController

- (void)closeBtn:(UIButton *)sender {
    NSLog(@"@mahaomeng, %s-%d", __PRETTY_FUNCTION__, __LINE__);
    /// 退出停止推流
//    [self.livePusher stopPush];
//    NSLog(@"@mahaomeng, %s-%d", __PRETTY_FUNCTION__, __LINE__);
    /// 移除帧回调监听
    [self.livePusher setVideoFrameFilter:nil];
    NSLog(@"@mahaomeng, %s-%d", __PRETTY_FUNCTION__, __LINE__);
    
    /// 销毁推流
    [self.livePusher destroy];
    NSLog(@"@mahaomeng, %s-%d", __PRETTY_FUNCTION__, __LINE__);
    self.livePusher = nil;
    NSLog(@"@mahaomeng, %s-%d", __PRETTY_FUNCTION__, __LINE__);
    self.stWrapper = nil;
    NSLog(@"@mahaomeng, %s-%d", __PRETTY_FUNCTION__, __LINE__);
    
    [self dismissViewControllerAnimated:YES completion:^{
    }];
    NSLog(@"@mahaomeng, %s-%d", __PRETTY_FUNCTION__, __LINE__);
}

- (void)dealloc {
    NSLog(@"@mahaomeng, %s-%d", __PRETTY_FUNCTION__, __LINE__);
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    
    NSLog(@"@mahaomeng, %s-%d", __PRETTY_FUNCTION__, __LINE__);

    [self setupPush];
    
    [self setupBeautyView];
}

- (void)setupPush {
    
    self.livePusher = [[VeLivePusher alloc] initWithConfig:[PushConfig getLivePushConfig]];

    /// 配置预览视图
    [self.livePusher setRenderView:self.view];
    /// 设置推流状态监听
    [self.livePusher setObserver:self];
    
    /// 设置自定义视频帧回调
    /// 设置美颜数据获取重要回调
    [self.livePusher setVideoFrameFilter:self];
    
    /// 配置本地预览填充模式
    [self.livePusher setRenderFillMode:VeLivePusherRenderModeHidden];
    /// 采集镜像
    [self.livePusher setVideoMirror:(VeLiveVideoMirrorCapture) enable:YES];
    /// 本地预览镜像
    [self.livePusher setVideoMirror:(VeLiveVideoMirrorPreview) enable:YES];
    /// 推流镜像
    [self.livePusher setVideoMirror:(VeLiveVideoMirrorPushStream) enable:YES];
    
    // 开启前置摄像头采集
    [self.livePusher startVideoCapture:(VeLiveVideoCaptureFrontCamera)];
//    
    // 开启麦克风采集
    [self.livePusher startAudioCapture:(VeLiveAudioCaptureMicrophone)];
        
    // 配置编码参数
    [self.livePusher setVideoEncoderConfiguration:[PushConfig getPushVideoEncoderConfiguration]];
    
    // 配置音频编码参数
    [self.livePusher setAudioEncoderConfiguration:[PushConfig getPushAudioEncoderConfiguration]];
    
//    [[self.livePusher getCameraDevice] setParameter:@{
//        @"pixelFormat" : @4,
//        @"bufferType" : @3,
//    }];
    
    // 设置设备方向
    [self.livePusher setOrientation:(UIInterfaceOrientationPortrait)];
    
//    [self.livePusher startPush:AIPushURL];
}

- (void)setupBeautyView {
    UIButton *closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(15, self.view.bounds.size.height - 100, (self.view.bounds.size.width - 45) / 2.0, 30)];
    [closeBtn setTitle:@"退出" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closeBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeBtn];

    UIButton *beautyBtn = [[UIButton alloc] initWithFrame:CGRectMake(30 + (self.view.bounds.size.width - 45) / 2.0, self.view.bounds.size.height - 100, (self.view.bounds.size.width - 45) / 2.0, 30)];
    [beautyBtn setTitle:@"开启美颜" forState:UIControlStateNormal];
    [beautyBtn setTitle:@"关闭美颜" forState:UIControlStateSelected];
    [beautyBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [beautyBtn setTitleColor:[UIColor blueColor] forState:UIControlStateSelected];
    [beautyBtn addTarget:self action:@selector(beautyEffectsSwitch:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:beautyBtn];
}

#pragma mark - VeLiveVideoFrameFilter
- (int)onVideoProcess:(nonnull VeLiveVideoFrame *)srcFrame dstFrame:(nonnull VeLiveVideoFrame *)dstFrame {
    NSLog(@"@mahao, %s-%d", __PRETTY_FUNCTION__, __LINE__);
    if (!_stWrapper) {
        // 1. 初始化wrapper
//        EAGLContext *context = [self.livePusher getEGLContext]; // 获取火山SDK内部context ⚠️buffer传递参数不需要传递context进行维护 传递nil即可
        NSString *modelPathOf106 = [[NSBundle mainBundle] pathForResource:@"M_SenseME_Face_Video_Template_p_4.0.0" ofType:@"model"]; // 所需的检测模型路径
        NSString *licensePath = [[NSBundle mainBundle] pathForResource:@"SENSEME" ofType:@"lic"]; // license路径
        self.stWrapper = [[STMobileWrapper alloc] initWithConfig:@{
            @"license": licensePath,
            @"config": @(STMobileWrapperConfigPreview),
            @"models": @[modelPathOf106]
        } context:nil error:nil];
        NSLog(@"@mahao, %s-%d", __PRETTY_FUNCTION__, __LINE__);
    }
    if (_beautyIsOn) { // 开启美颜，buffer传入并重新赋值
        CVPixelBufferRef pixelBuffer = [self.stWrapper processGetBufferByPixelBuffer:srcFrame.pixelBuffer rotate:ST_CLOCKWISE_ROTATE_0 captureDevicePosition:AVCaptureDevicePositionFront renderOrigin:NO error:nil];
        dstFrame.pixelBuffer = pixelBuffer;
        NSLog(@"@mahao, %s-%d", __PRETTY_FUNCTION__, __LINE__);
    }else { // 关闭美颜使用原始数据
        dstFrame.pixelBuffer = srcFrame.pixelBuffer;
        NSLog(@"@mahao, %s-%d", __PRETTY_FUNCTION__, __LINE__);
    }
    NSLog(@"@mahao, %s-%d", __PRETTY_FUNCTION__, __LINE__);
    return 0;
}

#pragma mark - VeLivePusherObserver
- (void)onError:(int)code subcode:(int)subcode message:(nullable NSString *)msg {
    NSLog(@"error = code:%d, subcode:%d, msg:%@", code, subcode, msg);
}

- (void)onStatusChange:(VeLivePushStatus)status {
    NSLog(@"status = status:%d", status);
}

- (void)onFirstVideoFrame:(VeLiveFirstFrameType)type timestampMs:(int64_t)timestampMs {
    NSLog(@"FirstVideoFrame = type:%d", type);
}

#pragma mark - beauty
- (void)beautyEffectsSwitch:(UIButton *)sender {
    if (sender.selected) {
        _beautyIsOn = NO;
        sender.selected = !sender.selected;
        return;
    }
    // 2. 设置特效
    
    // 1.基础美颜功能
    // 美白:zip包和mode方式各一个，美白4，mode3（默认开启美白4）
    NSString *whitenPath = [[NSBundle mainBundle] pathForResource:@"whiten4" ofType:@"zip"];
    [self.stWrapper setBeautyPath:EFFECT_BEAUTY_BASE_WHITTEN path:whitenPath error:nil];
    [self.stWrapper setBeautyMode:EFFECT_BEAUTY_BASE_WHITTEN mode:EFFECT_WHITEN_3 error:nil];
    [self.stWrapper setBeautyStrength:EFFECT_BEAUTY_BASE_WHITTEN strength:0.8 error:nil];

    // 磨皮：mode4
    [self.stWrapper setBeautyMode:EFFECT_BEAUTY_BASE_FACE_SMOOTH mode:EFFECT_SMOOTH_FACE_EVEN error:nil];
    [self.stWrapper setBeautyStrength:EFFECT_BEAUTY_BASE_FACE_SMOOTH strength:0.8 error:nil];
    
    // 红润
    [self.stWrapper setBeautyStrength:EFFECT_BEAUTY_BASE_REDDEN strength:0.8 error:nil];

    // 2.美型
    // 瘦脸、小脸、窄脸、圆眼、大眼
    [self.stWrapper setBeautyStrength:EFFECT_BEAUTY_RESHAPE_SHRINK_FACE strength:0.8 error:nil];
    [self.stWrapper setBeautyStrength:EFFECT_BEAUTY_RESHAPE_ENLARGE_EYE strength:0.8 error:nil];
    [self.stWrapper setBeautyStrength:EFFECT_BEAUTY_RESHAPE_SHRINK_JAW strength:0.8 error:nil];
    [self.stWrapper setBeautyStrength:EFFECT_BEAUTY_RESHAPE_NARROW_FACE strength:0.8 error:nil];
    [self.stWrapper setBeautyStrength:EFFECT_BEAUTY_RESHAPE_ROUND_EYE strength:0.8 error:nil];
    
    // 3.微整形
    // 小头，下巴
    [self.stWrapper setBeautyStrength:EFFECT_BEAUTY_PLASTIC_THINNER_HEAD strength:0.8 error:nil];
    [self.stWrapper setBeautyStrength:EFFECT_BEAUTY_PLASTIC_CHIN_LENGTH strength:0.8 error:nil];
    
    // 4.滤镜（babypink）
    NSString *filterPath = [[NSBundle mainBundle] pathForResource:@"filter_style_babypink" ofType:@"model"];
    [self.stWrapper setBeautyPath:EFFECT_BEAUTY_FILTER path:filterPath error:nil];
    [self.stWrapper setBeautyStrength:EFFECT_BEAUTY_FILTER strength:0.8 error:nil];
    
    // 5.风格妆
    NSString *stylePath = [[NSBundle mainBundle] pathForResource:@"oumei" ofType:@"zip"];
    int stickerId = [self.stWrapper changePackage:stylePath error:nil];
    [self.stWrapper setPackageBeautyGroup:stickerId type:EFFECT_BEAUTY_GROUP_FILTER strength:0.8 error:nil];
    [self.stWrapper setPackageBeautyGroup:stickerId type:EFFECT_BEAUTY_GROUP_MAKEUP strength:0.8 error:nil];
    
    // 6.单妆（口红）
    NSString *lipstickPath = [[NSBundle mainBundle] pathForResource:@"1自然" ofType:@"zip"];
    [self.stWrapper setBeautyPath:EFFECT_BEAUTY_MAKEUP_LIP path:lipstickPath error:nil];
    [self.stWrapper setBeautyStrength:EFFECT_BEAUTY_MAKEUP_LIP strength:0.8 error:nil];

    // 7.2D脸部贴纸
    NSString *araleStickerPath = [[NSBundle mainBundle] pathForResource:@"bunny" ofType:@"zip"];
    int stickerPackageId = [self.stWrapper changePackage:araleStickerPath error:nil];
    
    _beautyIsOn = YES;
    sender.selected = !sender.selected;
}
@end
