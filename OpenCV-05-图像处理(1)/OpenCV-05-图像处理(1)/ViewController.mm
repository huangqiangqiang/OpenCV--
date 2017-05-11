//
//  ViewController.m
//  OpenCV-05-图像处理(1)
//
//  Created by 黄强强 on 17/5/11.
//  Copyright © 2017年 黄强强. All rights reserved.
//

#import "ViewController.h"
#import <opencv2/opencv.hpp>
#import "HQQCVTool.hpp"

@interface ViewController()
@property (weak) IBOutlet NSImageView *originImage;
@property (weak) IBOutlet NSImageView *filteredimage;
@property (weak) IBOutlet NSSlider *slider;
@property (weak) IBOutlet NSSegmentedControl *segmentControl;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSImage *originImage = [NSImage imageNamed:@"test3.jpg"];
    self.originImage.image = originImage;
    
    self.slider.continuous = YES;
    self.slider.allowsTickMarkValuesOnly = YES;
    [self.slider setTarget:self];
    [self.slider setAction:@selector(onSlider)];
    
    [self segmentChanged:self.segmentControl];
}

- (IBAction)segmentChanged:(NSSegmentedControl *)control {
    if (control.selectedSegment == 0) {
        self.slider.minValue = 1.0;
        self.slider.maxValue = 29.0;
        self.slider.numberOfTickMarks = self.slider.maxValue;
        [self blur];
    }
    else if (control.selectedSegment == 1) {
        self.slider.minValue = 1.0;
        self.slider.maxValue = 29.0;
        self.slider.numberOfTickMarks = self.slider.maxValue;
        [self median];
    }
    else if (control.selectedSegment == 2) {
        self.slider.minValue = 1.0;
        self.slider.maxValue = 29.0;
        self.slider.numberOfTickMarks = self.slider.maxValue;
        [self gaussian];
    }
    else if (control.selectedSegment == 3) {
        self.slider.minValue = 1.0;
        self.slider.maxValue = 100.0;
        self.slider.numberOfTickMarks = self.slider.maxValue;
        [self bilateral];
    }
    else if (control.selectedSegment == 4) {
        self.slider.minValue = 1.0;
        self.slider.maxValue = 3.0;
        self.slider.numberOfTickMarks = self.slider.maxValue;
        [self blurNoScale];
    }
}

- (void)onSlider
{
    [self refreshImage];
}

- (void)refreshImage
{
    [self segmentChanged:self.segmentControl];
}


////////////////////////////////////////////////////////////
// 简单模糊 : 计算value = p1 * p2的值，对每个像素的value邻域求和，并做缩放 1 / (p1 * p2)
////////////////////////////////////////////////////////////

- (void)blur
{
    int param = self.slider.intValue;
    NSLog(@"blur:param - %d",param);
    
    NSImage *originImage = self.originImage.image;
    IplImage *src = [HQQCVTool NSImageToIplImage:originImage];
    IplImage *dest = cvCreateImage(cvGetSize(src), src->depth, src->nChannels);
    
    cvSmooth(src, dest, CV_BLUR, param, param);
    
    NSImage *destImage = [HQQCVTool IplImageToNSImage:dest];
    
    cvReleaseImage(&dest);
    cvReleaseImage(&src);
    
    self.filteredimage.image = destImage;
}

////////////////////////////////////////////////////////////
// 中值模糊 : 对图像进行核大小为p1 * p1的中值滤波
////////////////////////////////////////////////////////////

- (void)median
{
    int param = [self getKernelParam];
    NSLog(@"median:param - %d",param);
    
    NSImage *originImage = self.originImage.image;
    IplImage *src = [HQQCVTool NSImageToIplImage:originImage];
    IplImage *dest = cvCreateImage(cvGetSize(src), src->depth, src->nChannels);
    
    cvSmooth(src, dest, CV_MEDIAN, param);
    
    NSImage *destImage = [HQQCVTool IplImageToNSImage:dest];
    
    cvReleaseImage(&dest);
    cvReleaseImage(&src);
    
    self.filteredimage.image = destImage;
}

////////////////////////////////////////////////////////////
// 高斯模糊 : 对图像进行核大小为p1 * p2的高斯卷积
////////////////////////////////////////////////////////////

- (void)gaussian
{
    int param = [self getKernelParam];
    NSLog(@"gaussian:param - %d",param);
    
    NSImage *originImage = self.originImage.image;
    IplImage *src = [HQQCVTool NSImageToIplImage:originImage];
    IplImage *dest = cvCreateImage(cvGetSize(src), src->depth, src->nChannels);
    
    cvSmooth(src, dest, CV_GAUSSIAN, param);
    
    NSImage *destImage = [HQQCVTool IplImageToNSImage:dest];
    
    cvReleaseImage(&dest);
    cvReleaseImage(&src);
    
    self.filteredimage.image = destImage;
}

////////////////////////////////////////////////////////////
// 双边滤波 : 应用双线性3 * 3滤波。颜色sigma = p1，空间sigma = p2
// 双边滤波能提供一种不会将边缘平滑掉的方法，旦作为代价，需要更多的处理时间
////////////////////////////////////////////////////////////

- (void)bilateral
{
    int param = self.slider.intValue;
    NSLog(@"bilateral:param - %d",param);
    
    NSImage *originImage = self.originImage.image;
    IplImage *src = [HQQCVTool NSImageToIplImage:originImage];
    IplImage *dest = cvCreateImage(cvGetSize(src), src->depth, src->nChannels);
    
    cvSmooth(src, dest, CV_BILATERAL, 15, 15, param, param);
    
    NSImage *destImage = [HQQCVTool IplImageToNSImage:dest];
    
    cvReleaseImage(&dest);
    cvReleaseImage(&src);
    
    self.filteredimage.image = destImage;
}

////////////////////////////////////////////////////////////
// 简单无缩放变换的模糊 : 仅支持单通道图像，支持8位到16位的转换(与cvSobel和cvaplace相似)和32位浮点数到32位浮点数的变换格式。
// 计算value = p1 * p2的值，对每个像素的value邻域求和。
////////////////////////////////////////////////////////////

- (void)blurNoScale
{
    int param = self.slider.intValue;
    NSLog(@"blurNoScale:param - %d",param);
    
    NSImage *originImage = self.originImage.image;
    IplImage *src = [HQQCVTool NSImageToIplImage:originImage];
    NSImage *grayImage = [HQQCVTool IplImageToNSImageWithGray:src];
    //    self.originImage.image = grayImage;
    
    IplImage *src_r = cvCreateImage(cvGetSize(src), IPL_DEPTH_8U, 1);
    cvSplit(src, src_r, NULL, NULL, NULL);
    
    IplImage *dest = cvCreateImage(cvGetSize(src_r), IPL_DEPTH_16U, src->nChannels);
    
    cvSmooth(src, dest, CV_BLUR_NO_SCALE, param, param);
    
    NSImage *destImage = [HQQCVTool IplImageToNSImageWithGray:dest];
    
    cvReleaseImage(&dest);
    cvReleaseImage(&src);
    cvReleaseImage(&src_r);
    
    self.filteredimage.image = destImage;
}


- (int)getKernelParam
{
    int param = self.slider.intValue;
    // 核只能是奇数
    if (param % 2 == 0) {
        if (param == 0) {
            param = 1;
        }
        else{
            param -= 1;
        }
    }
    return param;
}



@end
