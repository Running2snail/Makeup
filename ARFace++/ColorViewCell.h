//
//  ColorViewCell.h
//  ARFace++
//
//  Created by wanglonglong on 2018/11/14.
//  Copyright © 2018年 . All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ColorViewCell : UICollectionViewCell

@property (nonatomic, strong) UIColor *color;

- (void)changeColorViewStyleWithState:(BOOL)select;

@end
