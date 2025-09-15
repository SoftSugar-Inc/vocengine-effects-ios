//
//  AppDelegate.m
//  SampleHS
//
//  Created by 郭振全 on 2025/3/31.
//

#import "AppDelegate.h"
#import <TTSDKFramework/TTSDKManager.h>
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    if (@available(iOS 13.0, *)) {
        // iOS 13+ 使用 SceneDelegate 管理 window
    } else {
        self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        UIViewController *rootVC = [ViewController new];
        self.window.rootViewController = rootVC;
        [self.window makeKeyAndVisible];
    }
    [self setupSDKWithAppID];
    return YES;
}

- (void)setupSDKWithAppID {
    // 使用申请到的 APPID 创建 TTSDKConfiguration
    TTSDKConfiguration *cfg = [TTSDKConfiguration defaultConfigurationWithAppID:@"766549"];
    cfg.licenseFilePath = [NSBundle.mainBundle pathForResource:@"path/ttsdk" ofType:nil];
    //  通道配置，一般传分发类型，内测、公测、线上等
    cfg.channel = @"AppStore";;
    //  App 名称
    cfg.appName = @"beautya";
    // Bundle ID
    cfg.bundleID = NSBundle.mainBundle.bundleIdentifier;
    //  版本号
    cfg.appVersion = [NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleShortVersionString"];
    //  是否默认内部初始化 AppLog
    cfg.shouldInitAppLog = YES;
    //  配置服务区域，默认CN
    cfg.appRegion = TTSDKServiceVendorCN;
    //  配置当前用户的唯一ID，一般传业务侧用户ID，如果在初始的时候获取不到，可以在获取到用户ID时配置
    [TTSDKManager setCurrentUserUniqueID:@"VeLiveQuickStartDemo"];
    //  是否上报埋点日志
//    [VeLiveCommon enableReportApplog:YES];
    
//    //  日志自定义字段，用于故障排查
//    [VeLiveCommon setAppLogCustomData:@{
//        @"CustomKey" : @"CustomValue"
//    }];
    //  启动 TTSDK
    [TTSDKManager startWithConfiguration:cfg];

    
}

#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
