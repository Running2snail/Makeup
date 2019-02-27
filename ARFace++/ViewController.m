//
//  ViewController.m
//  ARFace++
//
//  Created by wanglonglong on 2018/10/22.
//  Copyright © 2018年 . All rights reserved.
//

#import "ViewController.h"
#import "MGFaceLicenseHandle.h"
#import "MGFacepp.h"
#import "MGVideoViewController.h"

@interface ViewController ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *startBtn;
@property (nonatomic, strong) MGFacepp *markManager;
@property (nonatomic, strong) UIButton *viewSelectBtn;
@property (nonatomic, strong) UIButton *openGLSelectBtn;
@property (nonatomic, assign) BOOL isOpenGL;
@property (nonatomic, strong) UILabel *viewLabel;
@property (nonatomic, strong) UILabel *openGLLabel;

@end

@implementation ViewController

- (UIImageView *)imageView
{
    if (!_imageView) {
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        _imageView.image = [UIImage imageNamed:@"backImage"];
        _imageView.userInteractionEnabled = YES;
    }
    return _imageView;
}

- (UIButton *)startBtn
{
    if (!_startBtn) {
        self.startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _startBtn.frame = CGRectMake((SCREEN_WIDTH - 100) / 2, SCREEN_HEIGHT - 105, 120, 50);
        _startBtn.backgroundColor = [UIColor whiteColor];
        [_startBtn setTitle:@"开启试妆" forState:UIControlStateNormal];
        [_startBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_startBtn addTarget:self action:@selector(startBtnAction) forControlEvents:UIControlEventTouchUpInside];
        _startBtn.layer.cornerRadius = 25;
    }
    return _startBtn;
}

- (UIButton *)viewSelectBtn
{
    if (!_viewSelectBtn) {
        self.viewSelectBtn = [[UIButton alloc] initWithFrame:CGRectMake((SCREEN_WIDTH - 100) / 2, SCREEN_HEIGHT - 190, 36, 36)];
        [_viewSelectBtn setImage:[UIImage imageNamed:@"selected"] forState:UIControlStateNormal];
        [_viewSelectBtn addTarget:self action:@selector(viewSelectBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _viewSelectBtn;
}

- (UIButton *)openGLSelectBtn
{
    if (!_openGLSelectBtn) {
        self.openGLSelectBtn = [[UIButton alloc] initWithFrame:CGRectMake((SCREEN_WIDTH - 100) / 2, CGRectGetMaxY(_viewSelectBtn.frame) + 5, 36, 36)];
        [_openGLSelectBtn setImage:[UIImage imageNamed:@"unSelect"] forState:UIControlStateNormal];
        [_openGLSelectBtn addTarget:self action:@selector(openGLSelectBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _openGLSelectBtn;
}

- (UILabel *)viewLabel
{
    if (!_viewLabel) {
        self.viewLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_viewSelectBtn.frame) + 5, CGRectGetMinY(_viewSelectBtn.frame), 50, 36)];
        _viewLabel.text = @"方案一";
        _viewLabel.textColor = [UIColor whiteColor];
        _viewLabel.textAlignment = NSTextAlignmentLeft;
        _viewLabel.font = [UIFont systemFontOfSize:15];
        _viewLabel.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewSelectBtnAction)];
        [_viewLabel addGestureRecognizer:tap];
    }
    return _viewLabel;
}

- (UILabel *)openGLLabel
{
    if (!_openGLLabel) {
        self.openGLLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_openGLSelectBtn.frame) + 5, CGRectGetMinY(_openGLSelectBtn.frame), 50, 36)];
        _openGLLabel.text = @"方案二";
        _openGLLabel.textColor = [UIColor whiteColor];
        _openGLLabel.textAlignment = NSTextAlignmentLeft;
        _openGLLabel.font = [UIFont systemFontOfSize:15];
        _openGLLabel.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openGLSelectBtnAction)];
        [_openGLLabel addGestureRecognizer:tap];
    }
    return _openGLLabel;
}


- (void)viewDidLoad
{
    self.navigationController.navigationBarHidden = YES;
    [super viewDidLoad];
    [MGFaceLicenseHandle licenseForNetwokrFinish:^(bool License, NSDate *sdkDate) {
        if (!License) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"联网授权失败！！！！" message:nil preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            [alertController addAction:action];
            [self presentViewController:alertController animated:YES completion:nil];
            NSLog(@"联网授权失败！！！！");
        } else {
            NSLog(@"联网授权成功！！！！");
        }
    }];
    
    _isOpenGL = NO;
    [self.view addSubview:self.imageView];
    [self.view addSubview:self.startBtn];
    [self.view addSubview:self.viewSelectBtn];
    [self.view addSubview:self.openGLSelectBtn];
    [self.view addSubview:self.viewLabel];
    [self.view addSubview:self.openGLLabel];
//    NSString *modelPath = [[NSBundle mainBundle] pathForResource:KMGFACEMODELNAME ofType:@""];
//    NSData *modelData = [NSData dataWithContentsOfFile:modelPath];
//
//    MGFacepp *markManager = [[MGFacepp alloc] initWithModel:modelData
//                                              faceppSetting:^(MGFaceppConfig *config) {
//                                                  config.orientation = 0;
//                                                  config.detectionMode = MGFppDetectionModeTrackingRobust;
////                                                  config.orientation = 90;
//                                              }];
//    self.markManager = markManager;
    
}


- (void)viewSelectBtnAction
{
    _isOpenGL = NO;
    [_viewSelectBtn setImage:[UIImage imageNamed:@"selected"] forState:UIControlStateNormal];
    [_openGLSelectBtn setImage:[UIImage imageNamed:@"unSelect"] forState:UIControlStateNormal];
}

- (void)openGLSelectBtnAction
{
    _isOpenGL = YES;
    [_openGLSelectBtn setImage:[UIImage imageNamed:@"selected"] forState:UIControlStateNormal];
    [_viewSelectBtn setImage:[UIImage imageNamed:@"unSelect"] forState:UIControlStateNormal];
}

- (void)startBtnAction
{
    AVAuthorizationStatus authStatus =  [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied) {
        [self showAVAuthorizationStatusDeniedAlert];
    } else if (authStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (granted) {
                    [self showDetectViewController];
                } else {
                    [self showAVAuthorizationStatusDeniedAlert];
                }
            });
        }];
    } else {
        [self showDetectViewController];
    }
}

- (void)showAVAuthorizationStatusDeniedAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"alert_title_camera",nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"alert_action_ok",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertController addAction:action];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showDetectViewController
{
    // 测肤
    int pointCount = 106;
    MGDetectROI detectROI = MGDetectROIMake(0, 0, 0, 0);
    CGRect detectRect = CGRectNull;
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:KMGFACEMODELNAME ofType:@""];
    NSData *modelData = [NSData dataWithContentsOfFile:modelPath];
    
    int maxFaceCount = 1;
    MGFacepp *markManager = [[MGFacepp alloc] initWithModel:modelData
                                               maxFaceCount:maxFaceCount
                                              faceppSetting:^(MGFaceppConfig *config) {
                                                  config.orientation = 90;
                                                config.detectionMode = MGFppDetectionModeTrackingRobust;
                                                  config.detectROI = detectROI;
                                                  config.pixelFormatType = PixelFormatTypeRGBA;
                                              }];
    AVCaptureDevicePosition device = AVCaptureDevicePositionFront;
    MGVideoManager *videoManager = [MGVideoManager videoPreset:AVCaptureSessionPreset640x480
                                                devicePosition:device
                                                   videoRecord:NO
                                                    videoSound:NO];
  
    MGVideoViewController *videoController = [[MGVideoViewController alloc] init];
    videoController.detectRect = detectRect;
    videoController.videoSize = CGSizeMake(480, 640);
    videoController.videoManager = videoManager;
    videoController.markManager = markManager;
    videoController.debug =  NO;
    videoController.pointsNum = pointCount;
    videoController.faceInfo = NO;
    videoController.faceCompare = NO;
    videoController.isOpenGL = _isOpenGL;
    videoController.detectMode = MGFppDetectionModeTrackingRobust;
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:videoController];
    [self.navigationController presentViewController:navi animated:YES completion:nil];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
