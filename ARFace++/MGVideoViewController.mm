//
//  MGVideoViewController.m
//  Test
//
//  Created by 张英堂 on 16/4/20.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import "MGVideoViewController.h"
#import "MGOpenGLView.h"
#import "MGOpenGLRenderer.h"
#import "MGFaceModelArray.h"
#import <CoreMotion/CoreMotion.h>
#import <MGBaseKit/MGImage.h>
#import "MGDetectRectInfo.h"
#import <AssetsLibrary/ALAssetsLibrary.h>
#import "ColorViewCell.h"

#define RETAINED_BUFFER_COUNT 6

@interface MGVideoViewController ()<MGVideoDelegate, UICollectionViewDelegate, UICollectionViewDataSource>
{
    dispatch_queue_t _detectImageQueue;
    dispatch_queue_t _drawFaceQueue;
    dispatch_queue_t _compareQueue;
}

@property (nonatomic, strong) MGOpenGLView *previewView;
@property (nonatomic, assign) BOOL hasVideoFormatDescription;
@property (nonatomic, strong) MGOpenGLRenderer *renderer;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, assign) int orientation;
@property (nonatomic, assign) BOOL showFaceCompareVC;
@property (nonatomic, assign) BOOL isCompareing;
@property (nonatomic, assign) NSInteger currentFaceCount;
@property (nonatomic, strong) ARView *arView;
@property (nonatomic, strong) NSArray *colorArray;

//@property (nonatomic, assign) double allTime;
//@property (nonatomic, assign) NSInteger count;

//@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
//@property (nonatomic, strong) GPUImageUIElement *faceView;
//@property (nonatomic, strong) GPUImageView *filterView;
//@property (nonatomic, strong) GPUImageAddBlendFilter *blendFilter;

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, assign) NSInteger selectIndex;
@property (nonatomic, strong) UIButton *closeBeautyBtn;
@property (nonatomic, assign) BOOL isOpenBeauty;
@property (nonatomic, strong) UILabel *beautyL;

@end

@implementation MGVideoViewController

- (void)dealloc
{
    self.previewView = nil;
    self.renderer = nil;
    self.arView = nil;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.pointsNum = 106;
        self.orientation = 90;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self creatView];
    self.selectIndex = 0;
    _isOpenBeauty = YES;
    
// 美颜
//    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
//    self.videoCamera.delegate = self;
//    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
//    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
//    self.filterView = [[GPUImageView alloc] initWithFrame:self.view.frame];
//    self.filterView.center = self.view.center;
//    [self.view addSubview:self.filterView];
//    [self.videoCamera startCameraCapture];
//    GPUImageBeautifyFilter *beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
//    [self.videoCamera addTarget:beautifyFilter];
//    self.blendFilter = [[GPUImageAddBlendFilter alloc] init];
//    [beautifyFilter addTarget:self.blendFilter];
//    [self.faceView addTarget:self.blendFilter];
//    [beautifyFilter addTarget:self.filterView];
//    [self.blendFilter addTarget:_movieWriter];
    
    //测肤
    _detectImageQueue = dispatch_queue_create("com.megvii.image.detect", DISPATCH_QUEUE_SERIAL);
    _drawFaceQueue = dispatch_queue_create("com.megvii.image.drawFace", DISPATCH_QUEUE_SERIAL);
    _compareQueue = dispatch_queue_create("com.megvii.faceCompare", DISPATCH_QUEUE_SERIAL);

    self.renderer = [[MGOpenGLRenderer alloc] init];
    if (self.videoManager.videoDelegate != self) {
        self.videoManager.videoDelegate = self;
    }

    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = 0.3f;
    
    AVCaptureDevicePosition devicePosition = [self.videoManager devicePosition];
    NSOperationQueue *motionQueue = [[NSOperationQueue alloc] init];
    [motionQueue setName:@"com.megvii.gryo"];
    [self.motionManager startAccelerometerUpdatesToQueue:motionQueue withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error) {
         if (fabs(accelerometerData.acceleration.z) > 0.7) {
             self.orientation = 90;
         } else {
             if (AVCaptureDevicePositionBack == devicePosition) {
                 if (fabs(accelerometerData.acceleration.x) < 0.4) {
                     self.orientation = 90;
                 }else if (accelerometerData.acceleration.x > 0.4){
                     self.orientation = 180;
                 }else if (accelerometerData.acceleration.x < -0.4){
                     self.orientation = 0;
                 }
             } else {
                 if (fabs(accelerometerData.acceleration.x) < 0.4) {
                     self.orientation = 90;
                 }else if (accelerometerData.acceleration.x > 0.4){
                     self.orientation = 0;
                 }else if (accelerometerData.acceleration.x < -0.4){
                     self.orientation = 180;
                 }
             }
             if (accelerometerData.acceleration.y > 0.6) {
                 self.orientation = 270;
             }
         }
     }];
    [self.videoManager startRecording];
    [self setUpCameraLayer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!_isOpenGL) {
        [self.view addSubview:self.arView];
    }
    [self.view addSubview:self.slider];
    [self.view addSubview:self.closeBeautyBtn];
    [self.view addSubview:self.beautyL];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.motionManager stopAccelerometerUpdates];
    [self.videoManager stopRunning];
}

- (UIButton *)closeBeautyBtn
{
    if (!_closeBeautyBtn) {
        self.closeBeautyBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _closeBeautyBtn.frame = CGRectMake(SCREEN_WIDTH - 80, 70, 80, 50);
        [_closeBeautyBtn setImage:[UIImage imageNamed:@"beautyOpen"] forState:UIControlStateNormal];
        [_closeBeautyBtn addTarget:self action:@selector(closeBeautyAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBeautyBtn;
}

- (NSArray *)colorArray
{
    if (!_colorArray) {
        self.colorArray = @[@"#ff0000", @"#990a0a", @"#e71167", @"#d80e93", @"#fd1874", @"#730774", @"#a74707"];
    }
    return _colorArray;
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *flowlayout = [[UICollectionViewFlowLayout alloc] init];
        flowlayout.itemSize = CGSizeMake(70, 70);
        flowlayout.sectionInset = UIEdgeInsetsMake(0, 20, 0, 20);                        // 设置分区内边距
        flowlayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;          // 水平方向滑动
        self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - 100, SCREEN_WIDTH, 100) collectionViewLayout:flowlayout];
        _collectionView.backgroundColor = [self colorFromHexRGB:@"#f0f0f0" alpha:1];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.showsHorizontalScrollIndicator = NO;
        [_collectionView registerClass:[ColorViewCell class] forCellWithReuseIdentifier:@"ColorViewCell"];
    }
    return _collectionView;
}

- (UISlider *)slider
{
    if (!_slider) {
        self.slider = [[UISlider alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 150 , (SCREEN_HEIGHT - 250 - 100 - 64) / 2 + 164, 250, 30)];
        _slider.maximumValue = 0.50;
        _slider.minimumValue = 0.01;
        _slider.value = 0.2;
        _slider.thumbTintColor = [UIColor redColor];
//        [_slider setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];
        _slider.minimumTrackTintColor = [UIColor whiteColor];
        _slider.transform = CGAffineTransformMakeRotation(-1.57079633);
        [_slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _slider;
}

- (UILabel *)beautyL
{
    if (!_beautyL) {
        self.beautyL = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 60, CGRectGetMaxY(_closeBeautyBtn.frame), 40, 20)];
        _beautyL.text = @"美颜";
        _beautyL.alpha = 0.8;
        _beautyL.textColor = [UIColor whiteColor];
        _beautyL.textAlignment = NSTextAlignmentCenter;
        _beautyL.backgroundColor = [self colorFromHexRGB:@"#5B646B" alpha:1];
        _beautyL.font = [UIFont systemFontOfSize:13];
        _beautyL.layer.masksToBounds = YES;
        _beautyL.layer.cornerRadius = 10;
    }
    return _beautyL;
}

- (void)sliderValueChanged:(UISlider *)slider
{
    if (_isOpenGL) {
        _renderer.beautyAlphe = slider.value;
    } else {
        _arView.arAlphe = slider.value;
    }
}


- (void)closeBeautyAction
{
    _isOpenBeauty = !_isOpenBeauty;
    [_renderer dealWithBeautyWithType:_isOpenBeauty];
    __unsafe_unretained MGVideoViewController *weakSelf = self;
    [UIView animateKeyframesWithDuration:0.5 delay:0 options:0 animations: ^{
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:1 / 3.0 animations: ^{
            weakSelf.closeBeautyBtn.transform = CGAffineTransformMakeScale(1.3, 1.3);
        }];
        [UIView addKeyframeWithRelativeStartTime:1/3.0 relativeDuration:1/3.0 animations: ^{
            weakSelf.closeBeautyBtn.transform = CGAffineTransformMakeScale(0.9, 0.9);
        }];
        [UIView addKeyframeWithRelativeStartTime:2/3.0 relativeDuration:1/3.0 animations: ^{
            weakSelf.closeBeautyBtn.transform = CGAffineTransformMakeScale(1.0, 1.0);
        }];
    } completion:^(BOOL finished) {
        if (weakSelf.isOpenBeauty) {
            [weakSelf.closeBeautyBtn setImage:[UIImage imageNamed:@"beautyOpen"] forState:UIControlStateNormal];
        } else {
            [weakSelf.closeBeautyBtn setImage:[UIImage imageNamed:@"beautyClose"] forState:UIControlStateNormal];
        }
    }];
}

- (void)stopDetect
{
    [self.motionManager stopAccelerometerUpdates];
    NSString *videoPath = [self.videoManager stopRceording];
    NSLog(@"video Path: %@", videoPath);
    
    [self.videoManager stopRunning];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)creatView
{
    [self.view setBackgroundColor:[UIColor blackColor]];
    self.title = @"AR试妆";
    UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    leftBtn.frame = CGRectMake(-10, 0, 44, 44);
    [leftBtn setImage:[UIImage imageNamed:@"NavBar_backImg"] forState:UIControlStateNormal];
    [leftBtn addTarget:self action:@selector(stopDetect) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *cancenItem = [[UIBarButtonItem alloc] initWithCustomView:leftBtn];
    [self.navigationItem setLeftBarButtonItem:cancenItem];
    [self.view addSubview:self.collectionView];
}

//加载图层预览
- (void)setUpCameraLayer
{
    [self.view insertSubview:self.previewView atIndex:0];
}

- (ARView *)arView
{
    if (!_arView) {
        self.arView = [[ARView alloc] initWithFrame:_previewView.frame];
        _arView.backgroundColor = [UIColor clearColor];
        _arView.arAlphe = 0.2;
        _arView.arColorRGB = self.colorArray[0];
    }
    return _arView;
}

- (MGOpenGLView *)previewView
{
    if (!_previewView) {
        self.previewView = [[MGOpenGLView alloc] initWithFrame:CGRectZero];
        self.previewView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        // Front camera preview should be mirrored
        UIInterfaceOrientation currentInterfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
        CGAffineTransform transform =  [self.videoManager transformFromVideoBufferOrientationToOrientation:(AVCaptureVideoOrientation)currentInterfaceOrientation withAutoMirroring:YES];
        self.previewView.transform = transform;
        _previewView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 100);
    }
    return _previewView;
}


/** 根据人脸信息绘制，并且显示 */
- (void)displayWithfaceModel:(MGFaceModelArray *)modelArray SampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    @autoreleasepool {
        __unsafe_unretained MGVideoViewController *weakSelf = self;
        dispatch_async(_drawFaceQueue, ^{
            if (modelArray) {
                CVPixelBufferRef renderedPixelBuffer = [weakSelf.renderer drawPixelBuffer:sampleBuffer custumDrawing:^{
                    if (!weakSelf.faceCompare) {
                        if (weakSelf.isOpenGL) {
                            [weakSelf.renderer drawFaceLandMark:modelArray];
                        } else {
                            [weakSelf.arView drawWithPointArr:modelArray];
                        }
                    }
                    if (!CGRectIsNull(modelArray.detectRect)) {
                        [weakSelf.renderer drawFaceWithRect:modelArray.detectRect];
                    }
                }];
                if (renderedPixelBuffer) {
                    [weakSelf.previewView displayPixelBuffer:renderedPixelBuffer];
                    CFRelease(sampleBuffer);
                    CVBufferRelease(renderedPixelBuffer);
                }
            }
        });
    }
}


/** 绘制人脸框 */
- (void)drawRects:(NSArray *)rects atSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    @autoreleasepool {
        __unsafe_unretained MGVideoViewController *weakSelf = self;
        dispatch_async(_drawFaceQueue, ^{
            if (rects) {
                CVPixelBufferRef renderedPixelBuffer = [weakSelf.renderer drawPixelBuffer:sampleBuffer custumDrawing:^{
                    for (MGDetectRectInfo *rectInfo in rects) {
                        [weakSelf.renderer drawRect:rectInfo.rect];
                    }
                }];
                
                // 显示图像
                if (renderedPixelBuffer) {
                    [weakSelf.previewView displayPixelBuffer:renderedPixelBuffer];
                    
                    CFRelease(sampleBuffer);
                    CVBufferRelease(renderedPixelBuffer);
                }
            }
        });
    }
}


/** 旋转并且，并且显示 */
- (void)rotateAndDetectSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (self.markManager.status != MGMarkWorking) {
        CMSampleBufferRef detectSampleBufferRef = NULL;
        CMSampleBufferCreateCopy(kCFAllocatorDefault, sampleBuffer, &detectSampleBufferRef);
        /* 进入检测人脸专用线程 */
        dispatch_async(_detectImageQueue, ^{
            @autoreleasepool {
                if ([self.markManager getFaceppConfig].orientation != self.orientation) {
                    [self.markManager updateFaceppSetting:^(MGFaceppConfig *config) {
                        config.orientation = self.orientation;
                    }];
                }
                if (self.detectMode == MGFppDetectionModeDetectRect) {
                    [self detectRectWithSampleBuffer:detectSampleBufferRef];
                } else if (self.detectMode == MGFppDetectionModeTrackingRect) {
                    [self trackRectWithSampleBuffer:detectSampleBufferRef];
                } else {
                    [self trackSampleBuffer:detectSampleBufferRef];
                }
            }
        });
    }
}

- (void)trackSampleBuffer:(CMSampleBufferRef)detectSampleBufferRef
{
    MGImageData *imageData = [[MGImageData alloc] initWithSampleBuffer:detectSampleBufferRef];
    [self.markManager beginDetectionFrame];
    
    NSDate *date1, *date2, *date3;
    date1 = [NSDate date];
    
    NSArray *tempArray = [self.markManager detectWithImageData:imageData];
    date2 = [NSDate date];
    double timeUsed = [date2 timeIntervalSinceDate:date1] * 1000;
    
//    _allTime += timeUsed;
//    _count ++;
//    NSLog(@"time = %f, 平均：%f, count = %ld",timeUsed, _allTime/_count, _count);
    
    MGFaceModelArray *faceModelArray = [[MGFaceModelArray alloc] init];
    faceModelArray.getFaceInfo = self.faceInfo;
    faceModelArray.faceArray = [NSMutableArray arrayWithArray:tempArray];
    faceModelArray.timeUsed = timeUsed;
    faceModelArray.getFaceInfo = self.faceInfo;
    [faceModelArray setDetectRect:self.detectRect];
    
    _currentFaceCount = faceModelArray.count;
    for (int i = 0; i < faceModelArray.count; i ++) {
        MGFaceInfo *faceInfo = faceModelArray.faceArray[i];
        [self.markManager GetGetLandmark:faceInfo isSmooth:YES pointsNumber:self.pointsNum];
        
        if (self.faceInfo && self.debug) {
            [self.markManager GetAttributeAgeGenderStatus:faceInfo];
            [self.markManager GetAttributeMouseStatus:faceInfo];
            [self.markManager GetAttributeEyeStatus:faceInfo];
            [self.markManager GetMinorityStatus:faceInfo];
            [self.markManager GetBlurnessStatus:faceInfo];
        }
    }
    date3 = [NSDate date];
    double timeUsed3D = [date3 timeIntervalSinceDate:date2] * 1000;
    faceModelArray.AttributeTimeUsed = timeUsed3D;
    
    [self.markManager endDetectionFrame];
    [self displayWithfaceModel:faceModelArray SampleBuffer:detectSampleBufferRef];
}

- (void)trackRectWithSampleBuffer:(CMSampleBufferRef)detectSampleBufferRef
{
    MGImageData *imageData = [[MGImageData alloc] initWithSampleBuffer:detectSampleBufferRef];
    [self.markManager beginDetectionFrame];
    
    NSDate *date1;
    date1 = [NSDate date];
    
    NSArray *tempArray = [self.markManager detectWithImageData:imageData];
    
//    NSDate *date2;
//    date2 = [NSDate date];
//    double timeUsed = [date2 timeIntervalSinceDate:date1] * 1000;
    
//    _allTime += timeUsed;
//    _count ++;
//    NSLog(@"time = %f, 平均：%f, count = %ld",timeUsed, _allTime/_count, _count);
    
    NSMutableArray *mutableArr = [NSMutableArray array];
    for (int i = 0; i < tempArray.count; i ++) {
        MGDetectRectInfo *detectRect = [self.markManager GetRectAtIndex:i isSmooth:YES];
        if (detectRect) {
            [mutableArr addObject:detectRect];
        }
    }
    
    [self.markManager endDetectionFrame];
    [self drawRects:mutableArr atSampleBuffer:detectSampleBufferRef];
}

/** 检测人脸框 */
- (void)detectRectWithSampleBuffer:(CMSampleBufferRef)detectSampleBufferRef
{
    
    MGImageData *imageData = [[MGImageData alloc] initWithSampleBuffer:detectSampleBufferRef];
    [self.markManager beginDetectionFrame];
    
    NSDate *date1;
    date1 = [NSDate date];
    
    NSInteger faceCount = [self.markManager getFaceNumberWithImageData:imageData];
//    NSDate *date2;
//    date2 = [NSDate date];
//    double timeUsed = [date2 timeIntervalSinceDate:date1] * 1000;
    
//    _allTime += timeUsed;
//    _count ++;
//    NSLog(@"time = %f, 平均：%f, count = %ld",timeUsed, _allTime/_count, _count);
    
    NSMutableArray *mutableArr = [NSMutableArray array];
    for (int i = 0; i < faceCount; i ++) {
        MGDetectRectInfo *detectRect = [self.markManager GetRectAtIndex:i isSmooth:NO];
        if (detectRect) {
            [mutableArr addObject:detectRect];
        }
    }
    
    [self.markManager endDetectionFrame];
    [self drawRects:mutableArr atSampleBuffer:detectSampleBufferRef];
}


#pragma mark - video delegate
-(void)MGCaptureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    @synchronized(self) {
        if (self.hasVideoFormatDescription == NO) {
            [self setupVideoPipelineWithInputFormatDescription:[self.videoManager formatDescription]];
        }
        [self rotateAndDetectSampleBuffer:sampleBuffer];
    }
}

- (void)MGCaptureOutput:(AVCaptureOutput *)captureOutput error:(NSError *)error
{
    UIAlertController *alertViewController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"alert_title_resolution", nil)
                                                                                 message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"alert_action_ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [alertViewController addAction:action];
    [self presentViewController:alertViewController animated:YES completion:nil];
}

#pragma mark-
- (void)setupVideoPipelineWithInputFormatDescription:(CMFormatDescriptionRef)inputFormatDescription
{
    MGLog( @"-[%@ %@] called", NSStringFromClass([self class]), NSStringFromSelector(_cmd) );
    self.hasVideoFormatDescription = YES;
    
    [_renderer prepareForInputWithFormatDescription:inputFormatDescription
                      outputRetainedBufferCountHint:RETAINED_BUFFER_COUNT];
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.colorArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ColorViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ColorViewCell" forIndexPath:indexPath];
    cell.color = [self colorFromHexRGB:_colorArray[indexPath.row] alpha:0.6];
    if (indexPath.row == _selectIndex) {
        [cell changeColorViewStyleWithState:YES];
    } else {
        [cell changeColorViewStyleWithState:NO];
    }
    return cell;
}


#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_isOpenGL) {
        _renderer.beautyIndex = indexPath.row;
    } else {
      _arView.arColorRGB = _colorArray[indexPath.row];
    }
    NSIndexPath *index = [NSIndexPath indexPathForRow:_selectIndex inSection:0];
    ColorViewCell *lastCell = (ColorViewCell *)[collectionView cellForItemAtIndexPath:index];
    [lastCell changeColorViewStyleWithState:NO];
    _selectIndex = indexPath.row;
    ColorViewCell *cell = (ColorViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell changeColorViewStyleWithState:YES];
}



- (UIColor *)colorFromHexRGB:(NSString *)inColorString alpha:(float)a
{
    NSString *cString = [[inColorString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 or 8 characters
    if ([cString length] < 6) return [UIColor blackColor];
    
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"])
        cString = [cString substringFromIndex:2];
    if ([cString hasPrefix:@"#"])
        cString = [cString substringFromIndex:1];
    if ([cString length] != 6) return [UIColor blackColor];
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:a];
}


@end
