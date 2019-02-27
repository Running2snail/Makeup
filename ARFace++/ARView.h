//
//  ARView.h
//  ARFace++
//
//  Created by wanglonglong on 2018/11/7.
//  Copyright © 2018年 . All rights reserved.
//

#import <UIKit/UIKit.h>
#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)

@class MGFaceModelArray;
@interface ARView : UIView

@property (nonatomic, strong) NSString *arColorRGB;
@property (nonatomic, assign) CGFloat arAlphe;

- (void)drawWithPointArr:(MGFaceModelArray *)faces;

@end
