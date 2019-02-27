//
//  ColorViewCell.m
//  ARFace++
//
//  Created by wanglonglong on 2018/11/14.
//  Copyright © 2018年  All rights reserved.
//

#import "ColorViewCell.h"

@interface ColorViewCell()

@property (nonatomic, strong) UIView *colorView;

@end
@implementation ColorViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self configColorView];
    }
    return self;
}


- (UIView *)colorView
{
    if (!_colorView) {
        self.colorView = [[UIView alloc] initWithFrame:CGRectMake(5, 5, 60, 60)];
        _colorView.layer.cornerRadius = 30;
    }
    return _colorView;
}

- (void)setColor:(UIColor *)color
{
    _color = color;
    self.colorView.backgroundColor = color;
}

- (void)configColorView
{
    [self.contentView addSubview:self.colorView];
}

- (void)changeColorViewStyleWithState:(BOOL)select
{
    if (select) {
        [UIView animateWithDuration:0.15f delay:  0.f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _colorView.transform = CGAffineTransformMakeScale(1.2f, 1.2f);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.15f delay:0.f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                _colorView.transform = CGAffineTransformIdentity;
                _colorView.frame = CGRectMake(0, 0, 70, 70);
                _colorView.layer.cornerRadius = 35;
                _colorView.layer.borderWidth = 5;
                _colorView.layer.borderColor = [UIColor whiteColor].CGColor;
            } completion:nil];
        }];
    } else {
        _colorView.frame = CGRectMake(5, 5, 60, 60);
        _colorView.layer.cornerRadius = 30;
        _colorView.layer.borderWidth = 0;
        _colorView.layer.borderColor = [UIColor clearColor].CGColor;
    }
}


@end
