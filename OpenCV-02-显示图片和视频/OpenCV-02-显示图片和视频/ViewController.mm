//
//  ViewController.m
//  OpenCV-02-显示图片和视频
//
//  Created by 黄强强 on 17/5/5.
//  Copyright © 2017年 黄强强. All rights reserved.
//

#import "ViewController.h"
#import <opencv2/opencv.hpp>
#import "HQQCVTool.hpp"

@interface ViewController ()
@property (nonatomic, strong) UIImageView *iv;
@property (nonatomic, assign) CvCapture *capture;
@property (nonatomic, strong) CADisplayLink *displayLink;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 显示图片
//    [self showImage];
    
    // 播放视频
    [self showVideo];
}

////////////////////////////////////////////////////////////
// 1.显示图片
////////////////////////////////////////////////////////////

- (void)showImage
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test.jpg" ofType:nil];
    IplImage *pImg = cvLoadImage([path UTF8String]);
    
    UIImage *img = IplImageToUIImage(pImg);
    
    self.iv = [[UIImageView alloc] initWithImage:img];
    [self.view addSubview:self.iv];
    
    cvReleaseImage(&pImg);
}

////////////////////////////////////////////////////////////
// 2.播放视频
////////////////////////////////////////////////////////////

- (void)showVideo
{
    self.iv = [[UIImageView alloc] initWithFrame:CGRectMake(20, 20, 300, 200)];
    [self.view addSubview:self.iv];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test.mp4" ofType:nil];
    // cvCreateFileCapture通过参数确定要读入的视频信息，函数返回一个CvCapture结构的指针，CvCapture结构体包含视频文件的所有信息
    self.capture = cvCreateFileCapture([path UTF8String]);
    
    if (self.capture != NULL) {
        
        // 获取视频总帧数，有些视频的编码格式不支持获取总帧数
        int frames = cvGetCaptureProperty(self.capture, CV_CAP_PROP_FRAME_COUNT);
        
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateFrame)];
        self.displayLink.preferredFramesPerSecond = 24;
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
    else{
        NSLog(@"创建capture失败");
        return;
    }
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
    
    // 创建一个IplImage结构体，每个像素点为8u类型，通道总数为3
    IplImage *outFrame = cvCreateImage(cvGetSize(frame), IPL_DEPTH_8U, 3);
    // 模糊效果
    cvSmooth(frame,outFrame,CV_BLUR,10,10,0,0);
    
    UIImage *img = IplImageToUIImage(outFrame);
    self.iv.image = img;
    
    cvReleaseImage(&outFrame);
    
    /*
     
     获取视频信息的属性, CV_CAP_PROP_POS_FRAMES表示以帧数来设置读入位置
     // 设置播放进度从第5帧开始播放
     cvSetCaptureProperty(self.capture, CV_CAP_PROP_POS_FRAMES, 5.0);
     
     */
}


@end
