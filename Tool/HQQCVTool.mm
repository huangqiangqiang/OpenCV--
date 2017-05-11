//
//  HQQCVTool.m
//  OpenVC-05-图像处理
//
//  Created by 黄强强 on 17/5/10.
//  Copyright © 2017年 黄强强. All rights reserved.
//

#import "HQQCVTool.hpp"

@implementation HQQCVTool

+ (NSImage *)IplImageToNSImage:(IplImage *)image
{
    cvCvtColor(image, image, CV_BGR2RGB);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSData *data = [NSData dataWithBytes:image->imageData length:image->imageSize];
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
    CGImageRef imageRef = CGImageCreate(image->width, image->height,
                                        image->depth, image->depth * image->nChannels,
                                        image->widthStep, colorSpace,
                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault,
                                        provider, NULL, false,
                                        kCGRenderingIntentDefault);
    
    NSImage *result = [[NSImage alloc] initWithCGImage:imageRef size:NSMakeSize(image->width, image->height)];
    
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(imageRef);
    
    return result;
}

+ (NSImage *)IplImageToNSImageWithGray:(IplImage *)image
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    NSData *data = [NSData dataWithBytes:image->imageData length:image->imageSize];
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
    CGImageRef imageRef = CGImageCreate(image->width, image->height,
                                        image->depth, image->depth * image->nChannels,
                                        image->widthStep, colorSpace,
                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault,
                                        provider, NULL, false,
                                        kCGRenderingIntentDefault);
    
    NSImage *result = [[NSImage alloc] initWithCGImage:imageRef size:NSMakeSize(image->width, image->height)];
    
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(imageRef);
    
    return result;
}

+ (IplImage *)NSImageToIplImage:(NSImage *)image
{
    NSData *imageData = image.TIFFRepresentation;
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
    CGImageRef imageRef =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    IplImage *iplImage = cvCreateImage(cvSize(image.size.width, image.size.height), IPL_DEPTH_8U, 4);
    
    CGContextRef contextRef = CGBitmapContextCreate(iplImage->imageData, iplImage->width, iplImage->height, iplImage->depth, iplImage->widthStep, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, image.size.width, image.size.height), imageRef);
    IplImage *result = cvCreateImage(cvGetSize(iplImage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplImage, result, CV_RGB2BGR);
    
    CFRelease(source);
    CGImageRelease(imageRef);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    cvReleaseImage(&iplImage);
    
    return result;
}

@end
