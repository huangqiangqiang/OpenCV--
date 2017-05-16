//
//  ViewController.m
//  ttttt
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
    
    NSImage *originImage = [NSImage imageNamed:@"test2.jpg"];
    self.originImage.image = originImage;
    
    self.slider.minValue = 1.0;
    self.slider.maxValue = 10.0;
    self.slider.numberOfTickMarks = self.slider.maxValue;
    self.slider.continuous = YES;
    self.slider.allowsTickMarkValuesOnly = YES;
    [self.slider setTarget:self];
    [self.slider setAction:@selector(onSlider)];
    
    NSArray *lists = @[@"膨胀",@"腐蚀",@"开运算",@"闭运算",@"梯度",@"礼帽",@"黑帽"];
    self.segmentControl.segmentCount = lists.count;
    for (int i = 0; i < lists.count; i++) {
        [self.segmentControl setLabel:lists[i] forSegment:i];
    }
    self.segmentControl.selectedSegment = 0;
    [self segmentChanged:self.segmentControl];
}

- (IBAction)segmentChanged:(NSSegmentedControl *)control {
    if (control.selectedSegment == 0) {
        [self dilate];
    }
    else if (control.selectedSegment == 1) {
        [self erode];
    }
    else if (control.selectedSegment == 2) {
        [self open];
    }
    else if (control.selectedSegment == 3) {
        [self close];
    }
    else if (control.selectedSegment == 4) {
        [self gradient];
    }
    else if (control.selectedSegment == 5) {
        [self tophat];
    }
    else if (control.selectedSegment == 6) {
        [self blackhat];
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
// 膨胀
// 膨胀是求局部最大值的操作，核与图像进行卷积，即计算核覆盖的区域的像素点最大值，并把这个最大值赋给指定的像素，这样就会使图像中的高亮区域逐渐增长，这样的增长就是‘膨胀操作’的初衷。
////////////////////////////////////////////////////////////

- (void)dilate
{
    int param = self.slider.intValue;
    IplConvKernel *kernel = [self getKernel];
    NSLog(@"dilate:param - %d",param);
    
    NSImage *originImage = self.originImage.image;
    IplImage *src = [HQQCVTool NSImageToIplImage:originImage];
    IplImage *dst = cvCreateImage(cvGetSize(src), src->depth, src->nChannels);
    
    cvDilate(src, dst, kernel, param);
    
    NSImage *dstImage = [HQQCVTool IplImageToNSImage:dst];
    
    cvReleaseImage(&dst);
    cvReleaseImage(&src);
    
    self.filteredimage.image = dstImage;
}

////////////////////////////////////////////////////////////
// 腐蚀
// 腐蚀是膨胀的反操作，腐蚀操作要计算核区域的最小值。
////////////////////////////////////////////////////////////

- (void)erode
{
    int param = self.slider.intValue;
    IplConvKernel *kernel = [self getKernel];
    NSLog(@"erode:param - %d",param);
    
    NSImage *originImage = self.originImage.image;
    IplImage *src = [HQQCVTool NSImageToIplImage:originImage];
    IplImage *dst = cvCreateImage(cvGetSize(src), src->depth, src->nChannels);
    
    cvErode(src, dst, kernel, param);
    
    NSImage *dstImage = [HQQCVTool IplImageToNSImage:dst];
    
    cvReleaseImage(&dst);
    cvReleaseImage(&src);
    
    self.filteredimage.image = dstImage;
}

////////////////////////////////////////////////////////////
// 开运算
// 先腐蚀再膨胀，消除高于其临近点的孤立点
////////////////////////////////////////////////////////////

- (void)open
{
    int param = self.slider.intValue;
    IplConvKernel *kernel = [self getKernel];
    NSLog(@"open:param - %d",param);
    
    NSImage *originImage = self.originImage.image;
    IplImage *src = [HQQCVTool NSImageToIplImage:originImage];
    IplImage *dst = cvCreateImage(cvGetSize(src), src->depth, src->nChannels);
    
    /*
     
     CVAPI(void)  cvMorphologyEx( 
         const CvArr* src,                  原图像
         CvArr* dst,                        处理后的图像
         CvArr* temp, 
         IplConvKernel* element,            核
         int operation,                     处理类型
         int iterations CV_DEFAULT(1)       迭代的次数
     );
     */
    cvMorphologyEx(src, dst, NULL, kernel, CV_MOP_OPEN, param);
    
    NSImage *dstImage = [HQQCVTool IplImageToNSImage:dst];
    
    cvReleaseImage(&dst);
    cvReleaseImage(&src);
    
    self.filteredimage.image = dstImage;
}

////////////////////////////////////////////////////////////
// 闭运算
// 先膨胀再腐蚀，闭运算消除了低于其临近点的孤立点
////////////////////////////////////////////////////////////

- (void)close
{
    int param = self.slider.intValue;
    IplConvKernel *kernel = [self getKernel];
    NSLog(@"close:param - %d",param);
    
    NSImage *originImage = self.originImage.image;
    IplImage *src = [HQQCVTool NSImageToIplImage:originImage];
    IplImage *dst = cvCreateImage(cvGetSize(src), src->depth, src->nChannels);
    
    cvMorphologyEx(src, dst, NULL, kernel, CV_MOP_CLOSE, param);
    
    NSImage *dstImage = [HQQCVTool IplImageToNSImage:dst];
    
    cvReleaseImage(&dst);
    cvReleaseImage(&src);
    
    self.filteredimage.image = dstImage;
}

////////////////////////////////////////////////////////////
// 梯度 : dilate(src) - erode(src)
// 膨胀后的图像减去腐蚀的图像，对二值图像进行这个操作可以将团块的边缘突出出来。
// 形态学梯度能描述图像亮度变化的剧烈程度。
////////////////////////////////////////////////////////////

- (void)gradient
{
    int param = self.slider.intValue;
    IplConvKernel *kernel = [self getKernel];
    NSLog(@"gradient:param - %d",param);
    
    NSImage *originImage = self.originImage.image;
    IplImage *src = [HQQCVTool NSImageToIplImage:originImage];
    IplImage *dst = cvCreateImage(cvGetSize(src), src->depth, src->nChannels);
    
    cvMorphologyEx(src, dst, NULL, kernel, CV_MOP_GRADIENT, param);
    
    NSImage *dstImage = [HQQCVTool IplImageToNSImage:dst];
    
    cvReleaseImage(&dst);
    cvReleaseImage(&src);
    
    self.filteredimage.image = dstImage;
}

////////////////////////////////////////////////////////////
// 礼帽 : src - open(src)
// 可以突出比原图周围的区域更明亮的区域。
////////////////////////////////////////////////////////////

- (void)tophat
{
    int param = self.slider.intValue;
    IplConvKernel *kernel = [self getKernel];
    NSLog(@"tophat:param - %d",param);
    
    NSImage *originImage = self.originImage.image;
    IplImage *src = [HQQCVTool NSImageToIplImage:originImage];
    IplImage *dst = cvCreateImage(cvGetSize(src), src->depth, src->nChannels);
    
    cvMorphologyEx(src, dst, NULL, kernel, CV_MOP_TOPHAT, param);
    
    NSImage *dstImage = [HQQCVTool IplImageToNSImage:dst];
    
    cvReleaseImage(&dst);
    cvReleaseImage(&src);
    
    self.filteredimage.image = dstImage;
}

////////////////////////////////////////////////////////////
// 黑帽 : close(src) - src
// 可以突出比原图周围的区域黑暗的区域。
////////////////////////////////////////////////////////////

- (void)blackhat
{
    int param = self.slider.intValue;
    IplConvKernel *kernel = [self getKernel];
    NSLog(@"blackhat:param - %d",param);
    
    NSImage *originImage = self.originImage.image;
    IplImage *src = [HQQCVTool NSImageToIplImage:originImage];
    IplImage *dst = cvCreateImage(cvGetSize(src), src->depth, src->nChannels);
    
    cvMorphologyEx(src, dst, NULL, kernel, CV_MOP_BLACKHAT, param);
    
    NSImage *dstImage = [HQQCVTool IplImageToNSImage:dst];
    
    cvReleaseImage(&dst);
    cvReleaseImage(&src);
    
    self.filteredimage.image = dstImage;
}

- (IplConvKernel *)getKernel
{
    int cols,rows;
    cols = rows = 3;
    /*
     创建形态核
     
     形态核与卷积核不同，不需要指定核里面的数值。当核在图像上移动时，核的元素只需简单标明在哪个范围里计算最大值和最小值。
     
     cvCreateStructuringElementEx(
         int cols,          核矩形的高宽
         int  rows,         核矩形的高宽
         int  anchor_x,     核矩形内参考点的横纵坐标
         int  anchor_y,     核矩形内参考点的横纵坐标
         int shape,         核的形状 CV_SHAPE_*
         int* values CV_DEFAULT(NULL)   shape为CV_SHAPE_CUSTOM时，value表示封闭矩形内核的形状
     );
     
     */
    IplConvKernel *kernel = cvCreateStructuringElementEx(cols, rows, (int)(cols/2) , (int)(rows/2), CV_SHAPE_RECT);
    return kernel;
}

@end
