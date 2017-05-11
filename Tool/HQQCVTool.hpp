//
//  HQQCVTool.h
//  OpenVC-05-图像处理
//
//  Created by 黄强强 on 17/5/10.
//  Copyright © 2017年 黄强强. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <opencv2/opencv.hpp>

@interface HQQCVTool : NSObject

+ (NSImage *)IplImageToNSImage:(IplImage *)image;
+ (NSImage *)IplImageToNSImageWithGray:(IplImage *)image;

+ (IplImage *)NSImageToIplImage:(NSImage *)image;

@end
