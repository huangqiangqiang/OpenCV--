//
//  HQQCVTool.m
//  OpenCV-01-集成
//
//  Created by 黄强强 on 17/5/5.
//  Copyright © 2017年 黄强强. All rights reserved.
//

#import "HQQCVTool.hpp"

@implementation HQQCVTool

void UIImageToMat(const UIImage* image, cv::Mat& m, bool alphaExist)
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width, rows = image.size.height;
    CGContextRef contextRef;
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;
    if (CGColorSpaceGetModel(colorSpace) == 0)
    {
        m.create(rows, cols, CV_8UC1); // 8 bits per component, 1 channel
        bitmapInfo = kCGImageAlphaNone;
        if (!alphaExist)
            bitmapInfo = kCGImageAlphaNone;
        contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows, 8,
                                           m.step[0], colorSpace,
                                           bitmapInfo);
    }
    else
    {
        m.create(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
        if (!alphaExist)
            bitmapInfo = kCGImageAlphaNoneSkipLast |
            kCGBitmapByteOrderDefault;
        contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows, 8,
                                           m.step[0], colorSpace,
                                           bitmapInfo);
    }
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
}

UIImage* MatToUIImage(const cv::Mat& image)
{
    NSData *data = [NSData dataWithBytes:image.data length:image.elemSize()*image.total()];
    
    CGColorSpaceRef colorSpace;
    
    if (image.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Preserve alpha transparency, if exists
    bool alpha = image.channels() == 4;
    CGBitmapInfo bitmapInfo = (alpha ? kCGImageAlphaLast : kCGImageAlphaNone) | kCGBitmapByteOrderDefault;
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(image.cols,
                                        image.rows,
                                        8,
                                        8 * image.elemSize(),
                                        image.step.p[0],
                                        colorSpace,
                                        bitmapInfo,
                                        provider,
                                        NULL,
                                        false,
                                        kCGRenderingIntentDefault
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}


@end
