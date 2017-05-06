//
//  ViewController.m
//  OpenCV-03-摄像头
//
//  Created by 黄强强 on 17/5/6.
//  Copyright © 2017年 黄强强. All rights reserved.
//

#import "ViewController.h"
#import <opencv2/opencv.hpp>
#import "HQQCVTool.hpp"

@interface ViewController ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) CvCapture *capture;
@property (nonatomic, strong) CADisplayLink *displayLink;

@property (weak, nonatomic) IBOutlet UIButton *canny;
@property (weak, nonatomic) IBOutlet UISlider *sliderBar;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // cvCreateCameraCapture会尝试打开iPhone上的相机，从相机中实时获取摄像头图片数据
    // 参数-1表示随机选取一个摄像头
    self.capture = cvCreateCameraCapture(-1);
    
    if (self.capture == NULL) {
        return;
    }
    
    // 创建定时器
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateFrame)];
    self.displayLink.preferredFramesPerSecond = 15;
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    // 创建UIImageView
    int width = cvGetCaptureProperty(self.capture, CV_CAP_PROP_FRAME_WIDTH);
    int height = cvGetCaptureProperty(self.capture, CV_CAP_PROP_FRAME_HEIGHT);
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, height, width)];
    self.imageView.contentMode = UIViewContentModeCenter;
    [self.view addSubview:self.imageView];
    
    self.sliderBar.minimumValue = 10.f;
    self.sliderBar.maximumValue = 100.f;
}


/**
 一秒调用24次
 */
- (void)updateFrame
{
    IplImage *frame;
    
    // cvQueryFrame会将下一帧视频文件载入内存，返回当前帧的指针。
    // cvQueryFrame使用已经在CvCapture结构体中分配好的内存来保存当前帧，没必要通过cvReleaseImage来释放每一帧。
    // 当CvCapture被释放后，每一帧图片对应的内存空间将一起被释放。
    frame = cvQueryFrame(self.capture);
    if (frame == NULL) {
        // 播放结束
        cvReleaseCapture(&_capture);
        self.displayLink.paused = YES;
        [self.displayLink invalidate];
        self.displayLink = nil;
        return;
    }
    
    // 缩小图片为原来的一半
    IplImage *outFrame = doPyrDown(frame);
    // 边缘检测
    if (self.canny.isSelected) {
        outFrame = doCanny(outFrame, 10, self.sliderBar.value, 3);
    }
    
    // 显示到界面上
    UIImage *img = IplImageWithGrayToUIImage(outFrame?outFrame:frame);
    self.imageView.image = img;
    
    if (outFrame) {
        cvReleaseImage(&outFrame);
    }
}


/**
 图像尺寸缩小为原来的1/2

 @param inImg 输入图像
 @param filter <#filter description#>
 */
IplImage* doPyrDown(IplImage *inImg, int filter = CV_GAUSSIAN_5x5)
{
    assert(inImg->width % 2 == 0 && inImg->height % 2 == 0);
    IplImage *outImg = cvCreateImage(
                                     cvSize(inImg->width / 2,
                                            inImg->height / 2),
                                     inImg->depth,
                                     inImg->nChannels
                                     );
    cvPyrDown(inImg, outImg);
    return outImg;
}


/**
 边缘检测

 @param inImg 输入图像
 @param lowThresh <#lowThresh description#>
 @param highThresh <#highThresh description#>
 @param aperture <#aperture description#>
 @return <#return value description#>
 */
IplImage* doCanny(IplImage *inImg, double lowThresh, double highThresh, double aperture)
{
    IplImage *outImg = cvCreateImage(
                                     cvGetSize(inImg),
                                     IPL_DEPTH_8U,
                                     1
                                     );
    
    if (inImg->nChannels != 1) {
        // canny only handlers gray scale image
        cvCvtColor(inImg, outImg, CV_BGR2GRAY);
    }
    
    if (outImg == NULL) {
        cvCanny(inImg, outImg, lowThresh, highThresh);
    }else{
        cvCanny(outImg, outImg, lowThresh, highThresh);
    }
    
    cvReleaseImage(&inImg);
    return outImg;
}

- (IBAction)canny:(id)sender {
    self.canny.selected = !self.canny.isSelected;
}


@end
