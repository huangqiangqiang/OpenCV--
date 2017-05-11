//
//  main.m
//  OpenCV-04-HighGUI模块
//
//  Created by 黄强强 on 17/5/10.
//  Copyright © 2017年 黄强强. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <opencv2/opencv.hpp>


void mouseEventExample();
void trackbarExample();
void videoExample();

#define windowName "box"

CvRect box;
bool drawing_box = false;

void on_mouse(int event, int x, int y, int flags, void* param);

void drawBox(IplImage *image, CvRect box)
{
    cvRectangle(image,
                cvPoint(box.x, box.y),
                cvPoint(box.x + box.width, box.y + box.height),
                cvScalar(0xff,0x00,0x00));
}

int main(int argc, const char * argv[]) {
    
    
    mouseEventExample();
    
//    trackbarExample();

//    videoExample();
    
    return 0;
}

void on_mouse(int event, int x, int y, int flags, void* param)
{
    IplImage *image = (IplImage *)param;
    switch (event) {
        case CV_EVENT_MOUSEMOVE:
        {
            if (drawing_box) {
                box.width = x - box.x;
                box.height = y - box.y;
            }
        }
            break;
            
        case CV_EVENT_LBUTTONDOWN:
        {
            drawing_box = true;
            box = cvRect(x, y, 0, 0);
        }
            break;
            
        case CV_EVENT_LBUTTONUP:
        {
            drawing_box = false;
            if (box.width < 0) {
                box.x += box.width;
                box.width *= -1;
            }
            if (box.height < 0) {
                box.y += box.height;
                box.height *= -1;
            }
            drawBox(image, box);
        }
            break;
            
        default:
            break;
    }
}



/**
 用鼠标来画框框，画好的框框在退出时保存成文件
 */
void mouseEventExample()
{
    box = cvRect(-1, -1, 0, 0);
    
    IplImage *image = cvCreateImage(cvSize(200, 200), IPL_DEPTH_8U, 3);
    cvZero(image);
    IplImage *temp = cvCloneImage(image);
    
    
    // 创建一个window
    cvNamedWindow(windowName, CV_WINDOW_NORMAL);
    void *handler = cvGetWindowHandle(windowName);
    const char *c = cvGetWindowName(handler);
    printf("windowName:%s\n",c);
    
    
    // 设置窗口的x，y坐标
    cvMoveWindow(windowName, 400, 300);
    
    
    // 设置鼠标事件的回调
    cvSetMouseCallback(windowName, on_mouse, (void *)image);
    
    
    while (1) {
        temp = cvCloneImage(image);
        if (drawing_box) {
            drawBox(temp, box);
        }
        cvShowImage(windowName, temp);
        if (cvWaitKey(15) == 27) {
            // 保存图像
            cvSaveImage("/Users/huangqiangqiang/Desktop/image.jpg", temp);
            break;
        }
    }
    
    cvReleaseImage(&temp);
    cvReleaseImage(&image);
    cvDestroyWindow(windowName);
}


#pragma mark - Trackbar Example

void switch_on_function()
{
    cvSetTrackbarPos("trackbar", windowName, 1);
}
void switch_off_function()
{
    cvSetTrackbarPos("trackbar", windowName, 0);
}

void switch_callback(int positon)
{
    if (positon == 0) {
        switch_on_function();
    }
    else{
        switch_off_function();
    }
}


/**
 Trackbar类似于进度条
 这里把Trackbar当按钮来用
 */
void trackbarExample()
{
    cvNamedWindow(windowName);
    
    
    int value = 0;
    // cvGetTrackbarPos(<#const char *trackbar_name#>, <#const char *window_name#>)
    // cvSetTrackbarPos(<#const char *trackbar_name#>, <#const char *window_name#>, <#int pos#>)
    cvCreateTrackbar("trackbar", windowName, &value, 1, NULL);
    
    while (1) {
        if (cvWaitKey(15) == 27) {
            break;
        }
    }
    
    cvDestroyWindow(windowName);
}

#pragma mark - Video Example

/**
 CvCapture和CvVideoWriter的使用
 
 cvGetCaptureProperty   获取CvCapture属性
 cvQueryFrame           从CvCapture中获取一帧图像数据
 cvReleaseCapture       释放
 
 cvCreateVideoWriter    创建一个视频写入结构体
 cvWriteFrame           写一帧图像
 cvReleaseVideoWriter   释放
 */
void videoExample()
{
    cvNamedWindow(windowName);
    
    // 获取摄像头
    CvCapture *capture = cvCreateCameraCapture(0);
    
    
    // 获取视频帧率
    double fps = cvGetCaptureProperty(capture, CV_CAP_PROP_FPS);
    double width = cvGetCaptureProperty(capture, CV_CAP_PROP_FRAME_WIDTH);
    double height = cvGetCaptureProperty(capture, CV_CAP_PROP_FRAME_HEIGHT);
    // 获取视频编码格式
    double f = cvGetCaptureProperty(capture, CV_CAP_PROP_FOURCC);
    char *fourcc = (char *)(&f);
    printf("%s",fourcc);
    
    // 这里不知道为什么，视频格式只能是.m4v，不然写不进去
    CvVideoWriter *videoWriter = cvCreateVideoWriter("/Users/huangqiangqiang/Desktop/video.m4v", CV_FOURCC('M', 'P', '4', '2'), fps, cvSize(width, height));
    
    IplImage *frame;
    while (1) {
        
        frame = cvQueryFrame(capture);
        
        if (frame != NULL) {
            cvShowImage(windowName, frame);
            // 写入到视频文件里
            cvWriteFrame(videoWriter, frame);
        }
        
        if (cvWaitKey(15) == 27) {
            break;
        }
    }
    
    cvReleaseVideoWriter(&videoWriter);
    cvReleaseCapture(&capture);
    cvDestroyWindow(windowName);
}
