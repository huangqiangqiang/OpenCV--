//
//  ViewController.m
//  OpenCV-07-图像处理(3)
//
//  Created by 黄强强 on 17/5/16.
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
    
    NSImage *originImage = [NSImage imageNamed:@"test4.jpg"];
    self.originImage.image = originImage;
    
    self.slider.minValue = 1.0;
    self.slider.maxValue = 255.0;
    self.slider.numberOfTickMarks = self.slider.maxValue;
    self.slider.continuous = YES;
    self.slider.allowsTickMarkValuesOnly = YES;
    [self.slider setTarget:self];
    [self.slider setAction:@selector(onSlider)];
    
    NSArray *lists = @[@"阈值",@"自适应阈值"];
    self.segmentControl.segmentCount = lists.count;
    for (int i = 0; i < lists.count; i++) {
        [self.segmentControl setLabel:lists[i] forSegment:i];
    }
    self.segmentControl.selectedSegment = 0;
    [self segmentChanged:self.segmentControl];
}

- (IBAction)segmentChanged:(NSSegmentedControl *)control {
    if (control.selectedSegment == 0) {
        [self threshold];
    }
    else if (control.selectedSegment == 1) {
        [self adaptiveThreshold];
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
// 阈值
////////////////////////////////////////////////////////////

- (void)threshold
{
    int param = self.slider.intValue;
    NSLog(@"threshold:param - %d",param);
    
    NSImage *originImage = self.originImage.image;
    IplImage *src = [HQQCVTool NSImageToIplImage:originImage];
    IplImage *dst = cvCreateImage(cvGetSize(src), src->depth, src->nChannels);
    
    /*
     CVAPI(double)  cvThreshold( 
         const CvArr*  src,         源图像
         CvArr*  dst,               目标图像
         double  threshold,         参考下列公式
         double  max_value,         参考下列公式
         int threshold_type         参考下列公式
     );
     
     
     CV_THRESH_BINARY      =0,   value = value > threshold ? max_value : 0
     CV_THRESH_BINARY_INV  =1,   value = value > threshold ? 0 : max_value
     CV_THRESH_TRUNC       =2,   value = value > threshold ? threshold : value
     CV_THRESH_TOZERO      =3,   value = value > threshold ? value : 0
     CV_THRESH_TOZERO_INV  =4,   value = value > threshold ? 0 : value
     */
    cvThreshold(src, dst, param, 255, CV_THRESH_BINARY);
    
    NSImage *dstImage = [HQQCVTool IplImageToNSImage:dst];
    
    cvReleaseImage(&dst);
    cvReleaseImage(&src);
    
    self.filteredimage.image = dstImage;
}


////////////////////////////////////////////////////////////
// 自适应阈值
////////////////////////////////////////////////////////////

- (void)adaptiveThreshold
{
    int param = self.slider.intValue;
    NSLog(@"adaptiveThreshold:param - %d",param);
    
    NSImage *originImage = self.originImage.image;
    IplImage *src = [HQQCVTool NSImageToIplImage:originImage];
    IplImage *dst = cvCreateImage(cvGetSize(src), IPL_DEPTH_8U, 1);
    IplImage *gray = cvCreateImage(cvGetSize(src), IPL_DEPTH_8U, 1);
    cvCvtColor(src, gray, CV_BGR2GRAY);
    /*
     cvAdaptiveThreshold 只能处理单通道8位图像，源图像和目标图像不能使用同一图像
     
     CVAPI(void)  cvAdaptiveThreshold( 
     const CvArr* src,              源图像
     CvArr* dst,                    目标图像
     double max_value,
     int adaptive_method CV_DEFAULT(CV_ADAPTIVE_THRESH_MEAN_C),
     int threshold_type CV_DEFAULT(CV_THRESH_BINARY),
     int block_size CV_DEFAULT(3),
     double param1 CV_DEFAULT(5));
     
     CV_ADAPTIVE_THRESH_MEAN_C : 表示对block_size * block_size矩形区域内的像素平均加权，然后减去一个常数param1，为中心像素点的值
     CV_ADAPTIVE_THRESH_GAUSSIAN_C : 表示对block_size * block_size矩形区域内的像素高斯加权，然后减去一个常数param1，为中心像素点的值
     */
    cvAdaptiveThreshold(gray, dst, 255, CV_ADAPTIVE_THRESH_MEAN_C, CV_THRESH_BINARY);
    
    NSImage *dstImage = [HQQCVTool IplImageToNSImageWithGray:dst];
    
    cvReleaseImage(&dst);
    cvReleaseImage(&src);
    cvReleaseImage(&gray);
    
    self.filteredimage.image = dstImage;
}

@end
