//
//  ARView.m
//  ARFace++
//
//  Created by wanglonglong on 2018/11/7.
//  Copyright © 2018年 . All rights reserved.
//

#import "ARView.h"
#import "MGFaceModelArray.h"

@interface ARView()

@property (nonatomic, strong) UIBezierPath* path;
@property (nonatomic, assign) CGFloat dx;
@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@property (nonatomic, assign) BOOL hasDate;
@property (nonatomic, assign) BOOL isFirst;

@end

@implementation ARView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.isFirst = YES;
    }
    return self;
}


- (void)drawWithPointArr:(MGFaceModelArray *)faces
{
    [self removeDrawWithPointArr:faces];
    if (!faces || faces.count == 0) return;
//    if (_isFirst) {
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            _isFirst = NO;
//            [self drawDetailWithPointArr:faces];
//        });
//    } else {
//        dispatch_async(dispatch_get_main_queue(), ^{
            [self drawDetailWithPointArr:faces];
//        });
//    }
}


- (void)removeDrawWithPointArr:(MGFaceModelArray *)faces
{
    if (_path) {
        NSArray *layers = [self.layer.sublayers mutableCopy];
        for (CAShapeLayer *layer in layers) {
            [layer removeFromSuperlayer];
        }
        [_path removeAllPoints];
        _path = nil;
        _shapeLayer = nil;
        if (_hasDate && (!faces || faces.count == 0)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _hasDate = NO;
                [self setNeedsDisplay];
            });
        }
    }
}

- (void)drawDetailWithPointArr:(MGFaceModelArray *)faces
{
    self.hasDate = YES;
    for (int i =0; i < faces.count; i++) {
        MGFaceInfo *model = [faces modelWithIndex:i];
        [self drawFacePointer:model.points];
    }
}

- (void)drawFacePointer:(NSArray *)pointArr
{
    self.shapeLayer = [CAShapeLayer layer];
    _shapeLayer.frame = self.bounds;
    _shapeLayer.path = _path.CGPath;
    self.path = [[UIBezierPath alloc] init];
    [self drawPathWithPointer:pointArr path:_path];
    [self.layer addSublayer:_shapeLayer];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setNeedsDisplay];
    });
    
}


- (void)drawPathWithPointer:(NSArray *)pointArr path:(UIBezierPath*)path
{
    CGPoint pointer0 = [self changePointWithOriginPoint:[pointArr[84] CGPointValue]];
    [_path moveToPoint:pointer0];
    
    [self getControlPoint0:[self changePointWithOriginPoint:[pointArr[84] CGPointValue]] point1:[self changePointWithOriginPoint:[pointArr[85] CGPointValue]] point2:[self changePointWithOriginPoint:[pointArr[86] CGPointValue]] point3:[self changePointWithOriginPoint:[pointArr[87] CGPointValue]] path:_path];
    
    [self getControlPoint0:[self changePointWithOriginPoint:[pointArr[85] CGPointValue]] point1:[self changePointWithOriginPoint:[pointArr[86] CGPointValue]] point2:[self changePointWithOriginPoint:[pointArr[87] CGPointValue]] point3:[self changePointWithOriginPoint:[pointArr[88] CGPointValue]] path:_path];
    
    [self getControlPoint0:[self changePointWithOriginPoint:[pointArr[86] CGPointValue]] point1:[self changePointWithOriginPoint:[pointArr[87] CGPointValue]] point2:[self changePointWithOriginPoint:[pointArr[88] CGPointValue]] point3:[self changePointWithOriginPoint:[pointArr[89] CGPointValue]] path:_path];
    
    [self getControlPoint0:[self changePointWithOriginPoint:[pointArr[87] CGPointValue]] point1:[self changePointWithOriginPoint:[pointArr[88] CGPointValue]] point2:[self changePointWithOriginPoint:[pointArr[89] CGPointValue]] point3:[self changePointWithOriginPoint:[pointArr[90] CGPointValue]] path:_path];
    
    [self getControlPoint0:[self changePointWithOriginPoint:[pointArr[88] CGPointValue]] point1:[self changePointWithOriginPoint:[pointArr[89] CGPointValue]] point2:[self changePointWithOriginPoint:[pointArr[90] CGPointValue]] point3:[self changePointWithOriginPoint:[pointArr[100] CGPointValue]] path:_path];
    [self getControlPoint0:[self changePointWithOriginPoint:[pointArr[89] CGPointValue]] point1:[self changePointWithOriginPoint:[pointArr[90] CGPointValue]] point2:[self changePointWithOriginPoint:[pointArr[100] CGPointValue]] point3:[self changePointWithOriginPoint:[pointArr[99] CGPointValue]] path:_path];
    
    [self getControlPoint0:[self changePointWithOriginPoint:[pointArr[90] CGPointValue]] point1:[self changePointWithOriginPoint:[pointArr[100] CGPointValue]] point2:[self changePointWithOriginPoint:[pointArr[99] CGPointValue]] point3:[self changePointWithOriginPoint:[pointArr[98] CGPointValue]] path:_path];
    
    [self getControlPoint0:[self changePointWithOriginPoint:[pointArr[100] CGPointValue]] point1:[self changePointWithOriginPoint:[pointArr[99] CGPointValue]] point2:[self changePointWithOriginPoint:[pointArr[98] CGPointValue]] point3:[self changePointWithOriginPoint:[pointArr[97] CGPointValue]] path:_path];
    [self getControlPoint0:[self changePointWithOriginPoint:[pointArr[99] CGPointValue]] point1:[self changePointWithOriginPoint:[pointArr[98] CGPointValue]] point2:[self changePointWithOriginPoint:[pointArr[97] CGPointValue]] point3:[self changePointWithOriginPoint:[pointArr[96] CGPointValue]] path:_path];
    [self getControlPoint0:[self changePointWithOriginPoint:[pointArr[98] CGPointValue]] point1:[self changePointWithOriginPoint:[pointArr[97] CGPointValue]] point2:[self changePointWithOriginPoint:[pointArr[96] CGPointValue]] point3:[self changePointWithOriginPoint:[pointArr[84] CGPointValue]] path:_path];
    [self getControlPoint0:[self changePointWithOriginPoint:[pointArr[97] CGPointValue]] point1:[self changePointWithOriginPoint:[pointArr[96] CGPointValue]] point2:[self changePointWithOriginPoint:[pointArr[84] CGPointValue]] point3:[self changePointWithOriginPoint:[pointArr[85] CGPointValue]] path:_path];
    
    [self getControlPoint0:[self changePointWithOriginPoint:[pointArr[84] CGPointValue]] point1:[self changePointWithOriginPoint:[pointArr[96] CGPointValue]] point2:[self changePointWithOriginPoint:[pointArr[103] CGPointValue]] point3:[self changePointWithOriginPoint:[pointArr[102] CGPointValue]] path:_path];
    [self getControlPoint0:[self changePointWithOriginPoint:[pointArr[96] CGPointValue]] point1:[self changePointWithOriginPoint:[pointArr[103] CGPointValue]] point2:[self changePointWithOriginPoint:[pointArr[102] CGPointValue]] point3:[self changePointWithOriginPoint:[pointArr[101] CGPointValue]] path:_path];
    [self getControlPoint0:[self changePointWithOriginPoint:[pointArr[103] CGPointValue]] point1:[self changePointWithOriginPoint:[pointArr[102] CGPointValue]] point2:[self changePointWithOriginPoint:[pointArr[101] CGPointValue]] point3:[self changePointWithOriginPoint:[pointArr[100] CGPointValue]] path:_path];
    [self getControlPoint0:[self changePointWithOriginPoint:[pointArr[102] CGPointValue]] point1:[self changePointWithOriginPoint:[pointArr[101] CGPointValue]] point2:[self changePointWithOriginPoint:[pointArr[100] CGPointValue]] point3:[self changePointWithOriginPoint:[pointArr[90] CGPointValue]] path:_path];
    [self getControlPoint0:[self changePointWithOriginPoint:[pointArr[101] CGPointValue]] point1:[self changePointWithOriginPoint:[pointArr[100] CGPointValue]] point2:[self changePointWithOriginPoint:[pointArr[90] CGPointValue]] point3:[self changePointWithOriginPoint:[pointArr[91] CGPointValue]] path:_path];
    [self getControlPoint0:[self changePointWithOriginPoint:[pointArr[100] CGPointValue]] point1:[self changePointWithOriginPoint:[pointArr[90] CGPointValue]] point2:[self changePointWithOriginPoint:[pointArr[91] CGPointValue]] point3:[self changePointWithOriginPoint:[pointArr[92] CGPointValue]] path:_path];
    [self getControlPoint0:[self changePointWithOriginPoint:[pointArr[90] CGPointValue]] point1:[self changePointWithOriginPoint:[pointArr[91] CGPointValue]] point2:[self changePointWithOriginPoint:[pointArr[92] CGPointValue]] point3:[self changePointWithOriginPoint:[pointArr[93] CGPointValue]] path:_path];
    [self getControlPoint0:[self changePointWithOriginPoint:[pointArr[91] CGPointValue]] point1:[self changePointWithOriginPoint:[pointArr[92] CGPointValue]] point2:[self changePointWithOriginPoint:[pointArr[93] CGPointValue]] point3:[self changePointWithOriginPoint:[pointArr[94] CGPointValue]] path:_path];
    [self getControlPoint0:[self changePointWithOriginPoint:[pointArr[92] CGPointValue]] point1:[self changePointWithOriginPoint:[pointArr[93] CGPointValue]] point2:[self changePointWithOriginPoint:[pointArr[94] CGPointValue]] point3:[self changePointWithOriginPoint:[pointArr[95] CGPointValue]] path:_path];
    [self getControlPoint0:[self changePointWithOriginPoint:[pointArr[93] CGPointValue]] point1:[self changePointWithOriginPoint:[pointArr[94] CGPointValue]] point2:[self changePointWithOriginPoint:[pointArr[95] CGPointValue]] point3:[self changePointWithOriginPoint:[pointArr[84] CGPointValue]] path:_path];
    [self getControlPoint0:[self changePointWithOriginPoint:[pointArr[94] CGPointValue]] point1:[self changePointWithOriginPoint:[pointArr[95] CGPointValue]] point2:[self changePointWithOriginPoint:[pointArr[84] CGPointValue]] point3:[self changePointWithOriginPoint:[pointArr[96] CGPointValue]] path:_path];
}


-(void)getControlPoint0:(CGPoint)point0 point1:(CGPoint)point1 point2:(CGPoint)point2 point3:(CGPoint)point3 path:(UIBezierPath*)path
{
    CGFloat smooth_value = 0.8;
    CGFloat ctrl1_x;
    CGFloat ctrl1_y;
    CGFloat ctrl2_x;
    CGFloat ctrl2_y;
    CGFloat xc1 = (point0.x + point1.x) /2.0;
    CGFloat yc1 = (point0.y + point1.y) /2.0;
    CGFloat xc2 = (point1.x + point2.x) /2.0;
    CGFloat yc2 = (point1.y + point2.y) /2.0;
    CGFloat xc3 = (point2.x + point3.x) /2.0;
    CGFloat yc3 = (point2.y + point3.y) /2.0;
    CGFloat len1 = sqrt((point1.x - point0.x) * (point1.x-point0.x) + (point1.y-point0.y) * (point1.y - point0.y));
    CGFloat len2 = sqrt((point2.x - point1.x) * (point2.x-point1.x) + (point2.y-point1.y) * (point2.y - point1.y));
    CGFloat len3 = sqrt((point3.x - point2.x) * (point3.x-point2.x) + (point3.y-point2.y) * (point3.y - point2.y));
    CGFloat k1 = len1 / (len1 + len2);
    CGFloat k2 = len2 / (len2 + len3);
    CGFloat xm1 = xc1 + (xc2 - xc1) * k1;
    CGFloat ym1 = yc1 + (yc2 - yc1) * k1;
    CGFloat xm2 = xc2 + (xc3 - xc2) * k2;
    CGFloat ym2 = yc2 + (yc3 - yc2) * k2;
    ctrl1_x = xm1 + (xc2 - xm1) * smooth_value + point1.x - xm1;
    ctrl1_y = ym1 + (yc2 - ym1) * smooth_value + point1.y - ym1;
    ctrl2_x = xm2 + (xc2 - xm2) * smooth_value + point2.x - xm2;
    ctrl2_y = ym2 + (yc2 - ym2) * smooth_value + point2.y - ym2;
    [path addCurveToPoint:CGPointMake(point2.x, point2.y) controlPoint1:CGPointMake(ctrl1_x, ctrl1_y)controlPoint2:CGPointMake(ctrl2_x, ctrl2_y)];
}

- (CGPoint)changePointWithOriginPoint:(CGPoint)originPoint
{
    CGPoint destPoint = CGPointMake(0, 0);
    float destX = (originPoint.y-33) * (SCREEN_WIDTH)  / 412;
    float destY = originPoint.x * (SCREEN_HEIGHT- 100) / 640;
    destPoint.x = destX;
    destPoint.y = destY;
    return destPoint;
}

- (void)drawRect:(CGRect)rect
{
    UIColor *strokeColor = [UIColor clearColor];
    [strokeColor set];
    [_path stroke];
    UIColor *fillColor = [self colorFromHexRGB:_arColorRGB alpha:_arAlphe];
    [fillColor set];
    [_path fill];
}


- (UIColor *)colorFromHexRGB:(NSString *)inColorString alpha:(float)a
{
    NSString *cString = [[inColorString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 or 8 characters
    if ([cString length] < 6) return [UIColor clearColor];
    
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"])
        cString = [cString substringFromIndex:2];
    if ([cString hasPrefix:@"#"])
        cString = [cString substringFromIndex:1];
    if ([cString length] != 6) return [UIColor clearColor];
    
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
