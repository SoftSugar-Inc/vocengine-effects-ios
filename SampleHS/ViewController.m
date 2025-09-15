//
//  ViewController.m
//  SampleHS
//
//  Created by 郭振全 on 2025/3/31.
//
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

#import "ViewController.h"
#import "PushViewController.h"
#import "PullViewController.h"

@interface ViewController () 
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self requestAuthorization];
    
    UIButton *beautyOpenBtn = [[UIButton alloc] initWithFrame:CGRectMake(15, 150, (self.view.bounds.size.width - 45) / 2.0, 30)];
    [beautyOpenBtn setTitle:@"推流" forState:UIControlStateNormal];
    [beautyOpenBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [beautyOpenBtn addTarget:self action:@selector(pushStream:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:beautyOpenBtn];
        
//    UIButton *beautyOffBtn = [[UIButton alloc] initWithFrame:CGRectMake(30 + (self.view.bounds.size.width - 45) / 2.0, 150, (self.view.bounds.size.width - 45) / 2.0, 30)];
//    [beautyOffBtn setTitle:@"拉流" forState:UIControlStateNormal];
//    [beautyOffBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
//    [beautyOffBtn addTarget:self action:@selector(pullStream:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:beautyOffBtn];
    
}

- (void)pushStream:(UIButton *)sender {
    PushViewController *push = [[PushViewController alloc] init];
    push.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:push animated:YES completion:nil];
}

- (void)pullStream:(UIButton *)sender {
    PullViewController *pull = [[PullViewController alloc] init];
    pull.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:pull animated:YES completion:nil];
}

- (void)requestAuthorization {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (authStatus != AVAuthorizationStatusAuthorized) {
        [[AVAudioSession sharedInstance] performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
          if (granted) {
            NSLog(@"授权成功！");
          }
          else {
            NSLog(@"授权失败！");
          }
        }];
    }
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status != AVAuthorizationStatusAuthorized) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
              NSLog(@"授权成功！");
            }
            else {
              NSLog(@"授权失败！");
            }
        }];
    }

}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
//    [self pushStream:nil];
    NSLog(@"@mahaomeng+, %s-%d", __PRETTY_FUNCTION__, __LINE__);
}

@end
