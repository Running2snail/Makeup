//
//  MGVideoViewController.h
//  Test
//
//  Created by 张英堂 on 16/4/20.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGFacepp.h"
#import <MGBaseKit/MGVideoManager.h>
#import "ARView.h"

/**
 *  视频流检测---OpenGLES 版本
 */
@interface MGVideoViewController : UIViewController

@property (nonatomic, strong) MGFacepp *markManager;
@property (nonatomic, assign) CGRect detectRect;
@property (nonatomic, assign) CGSize videoSize;
@property (nonatomic, assign) BOOL faceInfo;
@property (nonatomic, assign) BOOL debug;
@property (nonatomic, assign) BOOL faceCompare;
@property (nonatomic, strong) MGVideoManager *videoManager;
@property (nonatomic, assign) MGFppDetectionMode detectMode;
@property (nonatomic, assign) BOOL isOpenGL;
@property (nonatomic, assign) int pointsNum;

@end
