//
//  MZCroppableView.m
//  MZCroppableView
//
//  Created by macbook on 30/10/2013.
//  Copyright (c) 2013 macbook. All rights reserved.
//

#import "MZCroppableView.h"
#import "UIBezierPath-MZPoints.h"

@implementation MZCroppableView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}
- (id)initWithImageView:(UIImageView *)imageView
{
    self = [super initWithFrame:imageView.frame];
    if (self) {
        self.lineWidth = 5.0f;
        [self setBackgroundColor:[UIColor clearColor]];
        [self setClipsToBounds:YES];
        [self setUserInteractionEnabled:YES];
        self.croppingPath = [[UIBezierPath alloc] init];
        [self.croppingPath setLineWidth:self.lineWidth];
        self.lineColor = [UIColor redColor];
    }
    return self;
}
#pragma mark - My Methods -
+ (CGRect)scaleRespectAspectFromRect1:(CGRect)rect1 toRect2:(CGRect)rect2
{
    CGSize scaledSize = rect2.size;
    
    float scaleFactor = 1.0;
    
    CGFloat widthFactor  = rect2.size.width / rect1.size.width;
    CGFloat heightFactor = rect2.size.height / rect1.size.width;
    
    if (widthFactor < heightFactor)
        scaleFactor = widthFactor;
    else
        scaleFactor = heightFactor;
    
    scaledSize.height = rect1.size.height *scaleFactor;
    scaledSize.width  = rect1.size.width  *scaleFactor;
    
    float y = (rect2.size.height - scaledSize.height)/2;
    
    return CGRectMake(0, y, scaledSize.width, scaledSize.height);
}
+ (CGPoint)convertCGPoint:(CGPoint)point1 fromRect1:(CGSize)rect1 toRect2:(CGSize)rect2
{
    point1.y = rect1.height - point1.y;
    CGPoint result = CGPointMake((point1.x*rect2.width)/rect1.width, (point1.y*rect2.height)/rect1.height);
    return result;
}
+ (CGPoint)convertPoint:(CGPoint)point1 fromRect1:(CGSize)rect1 toRect2:(CGSize)rect2
{
    CGPoint result = CGPointMake((point1.x*rect2.width)/rect1.width, (point1.y*rect2.height)/rect1.height);
    return result;
}
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    [self.lineColor setStroke];
    [self.croppingPath strokeWithBlendMode:kCGBlendModeNormal alpha:1.0f];
}

- (UIBezierPath*) cropPath:(UIImageView*)image
{
    NSArray *points = [self.croppingPath points];
    
    CGRect rect = CGRectZero;
    rect.size = image.image.size;
    
    UIBezierPath *aPath;
    aPath = [UIBezierPath bezierPath];
     //   CGRect pathRect = CGPathGetPathBoundingBox(path);
        // Set the starting point of the shape.
        CGPoint p1 = [MZCroppableView convertCGPoint:[[points objectAtIndex:0] CGPointValue] fromRect1:image.frame.size toRect2:image.image.size];
        [aPath moveToPoint:CGPointMake(p1.x, p1.y)];
        
        for (uint i=1; i<points.count; i++)
        {
            CGPoint p = [MZCroppableView convertCGPoint:[[points objectAtIndex:i] CGPointValue] fromRect1:image.frame.size toRect2:image.image.size];
            [aPath addLineToPoint:CGPointMake(p.x, p.y)];
        }
   
    return aPath;
}


- (UIImage *)croppedImageInRect:(CGRect)rect
{
    double (^rad)(double) = ^(double deg) {
        return deg / 180.0 * M_PI;
    };
    
    CGAffineTransform rectTransform;
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(90)), 0, -self.size.height);
            break;
        case UIImageOrientationRight:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-90)), -self.size.width, 0);
            break;
        case UIImageOrientationDown:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-180)), -self.size.width, -self.size.height);
            break;
        default:
            rectTransform = CGAffineTransformIdentity;
    };
    rectTransform = CGAffineTransformScale(rectTransform, self.scale, self.scale);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], CGRectApplyAffineTransform(rect, rectTransform));
    UIImage *result = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    
    return result;
}

- (CGRect) cropRect:(UIImageView*)image
{
    NSArray *points = [self.croppingPath points];
    
    CGRect rect = CGRectZero;
    rect.size = image.image.size;
    
    UIBezierPath *aPath;
    aPath = [UIBezierPath bezierPath];
    //   CGRect pathRect = CGPathGetPathBoundingBox(path);
    // Set the starting point of the shape.
    CGPoint p1 = [MZCroppableView convertCGPoint:[[points objectAtIndex:0] CGPointValue] fromRect1:image.frame.size toRect2:image.image.size];
    [aPath moveToPoint:CGPointMake(p1.x, p1.y)];
    
    for (uint i=1; i<points.count; i++)
    {
        CGPoint p = [MZCroppableView convertCGPoint:[[points objectAtIndex:i] CGPointValue] fromRect1:image.frame.size toRect2:image.image.size];
        [aPath addLineToPoint:CGPointMake(p.x, p.y)];
    }
    CGRect croppedRect = aPath.bounds;
    croppedRect.origin.y = rect.size.height - CGRectGetMaxY(aPath.bounds);//This because mask become inverse of the actual image;
    return croppedRect;
}

- (UIImage*) buildMaskImage:(UIImageView*)image
{
    NSArray *points = [self.croppingPath points];
    
    CGRect rect = CGRectZero;
    rect.size = image.image.size;
    
    UIBezierPath *aPath;
    UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0);
    {
        [[UIColor blackColor] setFill];
        UIRectFill(rect);
        [[UIColor whiteColor] setFill];
        
        aPath = [UIBezierPath bezierPath];
        
        // Set the starting point of the shape.
        CGPoint p1 = [MZCroppableView convertCGPoint:[[points objectAtIndex:0] CGPointValue] fromRect1:image.frame.size toRect2:image.image.size];
        [aPath moveToPoint:CGPointMake(p1.x, p1.y)];
        
        for (uint i=1; i<points.count; i++)
        {
            CGPoint p = [MZCroppableView convertCGPoint:[[points objectAtIndex:i] CGPointValue] fromRect1:image.frame.size toRect2:image.image.size];
            [aPath addLineToPoint:CGPointMake(p.x, p.y)];
        }
        [aPath closePath];
        [aPath fill];
    }
    
    UIImage *mask = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    
    {
        CGContextClipToMask(UIGraphicsGetCurrentContext(), rect, mask.CGImage);
        [image.image drawAtPoint:CGPointZero];
    }
    
    UIImage *maskedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return maskedImage;
}
- (UIImage *)deleteBackgroundOfImage:(UIImageView *)image
{
    NSArray *points = [self.croppingPath points];
    
    CGRect rect = CGRectZero;
    rect.size = image.image.size;
    
    
    UIBezierPath *aPath;
    UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0);
    {
        [[UIColor blackColor] setFill];
        UIRectFill(rect);
        [[UIColor whiteColor] setFill];
        
        aPath = [UIBezierPath bezierPath];
        
        // Set the starting point of the shape.
        CGPoint p1 = [MZCroppableView convertCGPoint:[[points objectAtIndex:0] CGPointValue] fromRect1:image.frame.size toRect2:image.image.size];
        [aPath moveToPoint:CGPointMake(p1.x, p1.y)];
        
        for (uint i=1; i<points.count; i++)
        {
            CGPoint p = [MZCroppableView convertCGPoint:[[points objectAtIndex:i] CGPointValue] fromRect1:image.frame.size toRect2:image.image.size];
            [aPath addLineToPoint:CGPointMake(p.x, p.y)];
        }
        [aPath closePath];
        [aPath fill];
    }
    
    UIImage *mask = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    
    {
        CGContextClipToMask(UIGraphicsGetCurrentContext(), rect, mask.CGImage);
        [image.image drawAtPoint:CGPointZero];
    }
    
    UIImage *maskedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGRect croppedRect = aPath.bounds;
    croppedRect.origin.y = rect.size.height - CGRectGetMaxY(aPath.bounds);//This because mask become inverse of the actual image;
    
    croppedRect.origin.x = croppedRect.origin.x*2;
    croppedRect.origin.y = croppedRect.origin.y*2;
    croppedRect.size.width = croppedRect.size.width*2;
    croppedRect.size.height = croppedRect.size.height*2;
    
    CGImageRef imageRef = CGImageCreateWithImageInRect(maskedImage.CGImage, croppedRect);
    
    maskedImage = [UIImage imageWithCGImage:imageRef];
    
    // Release the imageRef to prevent a memory leak. CG classes don't use ARC
    CGImageRelease(imageRef);
    imageRef = NULL;
    
    return maskedImage;
}
#pragma mark - Touch Methods -
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *mytouch=[[touches allObjects] objectAtIndex:0];
    [self.croppingPath moveToPoint:[mytouch locationInView:self]];
    
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *mytouch=[[touches allObjects] objectAtIndex:0];
    [self.croppingPath addLineToPoint:[mytouch locationInView:self]];
    
    [self setNeedsDisplay];
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    
}
@end
